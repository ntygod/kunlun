class_name BoundedSaveCodec
extends RefCounted
## Completed chapters are declared, rule-checked outcomes, never historical input proofs.
## Only the active unfinished chapter is replayed through the original controllers.
const Summary = preload("res://scripts/campaign/completed_chapter_summary.gd")
const Registry = preload("res://scripts/campaign/chapter_registry.gd")
const MAX_ARCHIVE := 21
const MAX_EVENTS := 10000

static func _keys(value: Variant, keys: Array) -> bool:
 if not value is Dictionary or value.size()!=keys.size(): return false
 for key in keys:
  if not value.has(key): return false
 return true

static func _integer(value: Variant) -> bool:
 return (value is int or value is float) and is_finite(float(value)) and float(value)==floor(float(value))

static func _canonical(value: Variant) -> Variant:
 if value is Dictionary:
  var result := {}
  # Dot assignment introduces StringName keys alongside JSON String keys.
  # Compare their textual names consistently; Variant ordering is not a total
  # order across these types on Godot 4.6.3. This changes no stored fields.
  var keys: Array=value.keys()
  keys.sort_custom(func(a: Variant,b: Variant)->bool: return str(a)<str(b))
  for key in keys: result[key]=_canonical(value[key])
  return result
 if value is Array:
  var result: Array=[]
  for entry in value: result.append(_canonical(entry))
  return result
 if value is float and is_finite(value) and value==floor(value): return int(value)
 return value

static func equivalent(a: Variant,b: Variant) -> bool:
 return JSON.stringify(_canonical(a))==JSON.stringify(_canonical(b))

static func _navigation(campaign: RefCounted) -> Dictionary:
 if campaign.active_chapter==0: return {"position":campaign.state.position.duplicate()}
 var result := {"position":campaign.state.position.duplicate(),"path_progress":campaign.state.path_progress.duplicate(true)}
 if campaign.active_chapter>=2: result["return_position"]=campaign.state.return_position.duplicate()
 if campaign.active_chapter>=3: result["objective_snapshot"]=campaign.state.objective_snapshot.duplicate(true)
 return result

static func _events(campaign: RefCounted) -> Array:
 if campaign.active_chapter==1: return campaign.progress.events.duplicate(true)
 var result: Array=[]
 var prior: Dictionary={}
 for record in campaign.state.chronology:
  # A real final puzzle input already commits this receipt during deterministic
  # replay. Keeping its second full input log is redundant, not additional proof.
  if record.get("kind")=="complete" and prior.get("kind")=="puzzle_input" and prior.get("token")==record.get("token"):
   prior=record
   continue
  result.append(record.duplicate(true))
  prior=record
 return result

static func encode(campaign: RefCounted) -> Dictionary:
 var archive: Array=campaign.bounded_archive.duplicate(true) if campaign.bounded_mode else []
 if not campaign.bounded_mode:
  var sources := {}
  var saved: Dictionary=campaign.export_legacy_save()
  if campaign.active_chapter==3:
   sources[2]=saved.prior_campaign
   saved=saved.prior_campaign
  if campaign.active_chapter>=2:
   sources[1]=saved.prior_campaign
   saved=saved.prior_campaign
  if campaign.active_chapter>=1: sources[0]=saved.prologue
  for chapter in range(campaign.active_chapter):
   var previous=campaign.codec_candidate()
   if previous.restore(sources[chapter])!="": return {}
   var entry: Dictionary=Summary.pack(previous,chapter)
   if entry.is_empty(): return {}
   archive.append(entry)
 if campaign.state.finished and archive.size()==campaign.active_chapter:
  var entry: Dictionary=Summary.pack(campaign,campaign.active_chapter)
  if entry.is_empty(): return {}
  archive.append(entry)
 var current: Dictionary
 if campaign.state.finished:
  current={"status":"archived","navigation":_navigation(campaign)}
 elif campaign.active_chapter==0:
  current={"status":"live","state":campaign.prologue.state.duplicate(true)}
 else:
  current={"status":"live","events":_events(campaign),"navigation":_navigation(campaign)}
 return {"version":4,"active_chapter":campaign.active_chapter,"archive":archive,"current":current}

static func restore_into(campaign: RefCounted, candidate: Dictionary) -> String:
 if not _keys(candidate,["version","active_chapter","archive","current"]): return "v4存档字段不完整或含未知字段"
 if not _integer(candidate.version) or int(candidate.version)!=4: return "v4版本无效"
 if not _integer(candidate.active_chapter) or (int(candidate.active_chapter)!=0 and not Registry.registered(int(candidate.active_chapter))): return "此章节尚未登记摘要规则"
 if not candidate.archive is Array or candidate.archive.size()>MAX_ARCHIVE or not candidate.current is Dictionary: return "归档摘要格式无效"
 var active:=int(candidate.active_chapter)
 var current: Dictionary=candidate.current
 if current.get("status") not in ["live","archived"]: return "当前章状态无效"
 var terminal: bool=current.status=="archived"
 if candidate.archive.size()!=active+(1 if terminal else 0): return "归档必须连续且恰在当前章之前"
 var temporary=campaign.codec_candidate()
 temporary.bounded_mode=true
 for chapter in range(candidate.archive.size()):
  var entry: Variant=candidate.archive[chapter]
  if not entry is Dictionary or not _integer(entry.get("chapter")) or int(entry.chapter)!=chapter: return "归档章节必须唯一连续有序"
  var error: String=Summary.apply(temporary,entry)
  if error!="": return "归档第%d章无效：%s"%[chapter,error]
  temporary.bounded_archive.append(entry.duplicate(true))
 if not terminal:
  if active==0:
   if not _keys(current,["status","state"]): return "序章当前状态字段无效"
   var error: String=temporary.prologue.restore(current.state)
   if error!="" or temporary.state.finished: return "序章当前状态无效："+error
  else:
   if not _keys(current,["status","events","navigation"]) or not current.events is Array or current.events.size()>MAX_EVENTS: return "当前章输入记录无效"
   var entered: bool=temporary.enter_registered_chapter(active)
   if not entered: return "当前章前置摘要未满足"
   for record in current.events:
    if active==1:
     if not _keys(record,["step_id","proof"]) or not record.step_id is String or not record.proof is Dictionary: return "当前章事件类型无效"
     if not temporary._replay_event(record): return "当前章事件顺序或证明无效"
    else:
     if not _keys(record,["kind","token","proof"]) or not record.kind is String or not record.token is String or not record.proof is Dictionary: return "当前章事件类型无效"
     if not temporary.current_chapter_runtime().replay(record): return "当前章事件顺序或证明无效"
   if temporary.state.finished: return "完成章节必须归档，不能伪装为当前未完成章"
 else:
  if not _keys(current,["status","navigation"]): return "归档导航字段无效"
  if not temporary.state.finished: return "缺少完成摘要"
 if not (active==0 and not terminal):
  var navigation_error:=_restore_navigation(temporary,current.navigation)
  if navigation_error!="": return navigation_error
 # Canonical roundtrip rejects omitted transitions, ignored values, and extra
 # fields, while derived gameplay tables are not accepted from the file at all.
 if not equivalent(encode(temporary),candidate): return "v4状态与摘要和当前章输入不一致"
 temporary.prior_campaign={}
 campaign._replace_with(temporary)
 return ""

static func _restore_navigation(campaign: RefCounted, navigation: Variant) -> String:
 var chapter: int=campaign.active_chapter
 var keys: Array=["position"] if chapter==0 else ["position","path_progress"]
 if chapter>=2: keys.append("return_position")
 if chapter>=3: keys.append("objective_snapshot")
 if not _keys(navigation,keys): return "导航字段无效"
 if chapter==0:
  var saved: Dictionary=campaign.prologue.state.duplicate(true)
  saved.position=navigation.position
  return campaign.prologue.restore(saved)
 if chapter>=2:
  return "" if campaign.current_chapter_runtime().restore_navigation(navigation) else "当前章导航或战斗检查点无效"
 if not campaign._position_valid(navigation.position) or not navigation.path_progress is Dictionary: return "当前章位置无效"
 var allowed := {}
 var sequence: Array=campaign.runtime.scenes[campaign.scene().id]
 for i in range(mini(int(campaign.progress.step)+1,sequence.size())):
  var event: Dictionary=sequence[i]
  if event.get("kind","")=="route": allowed[event.id]=campaign.maps[campaign.scene().map_id].paths.get(event.id,[]).size()
 for key in navigation.path_progress:
  if not key is String or not allowed.has(key) or not _integer(navigation.path_progress[key]) or int(navigation.path_progress[key])<0 or int(navigation.path_progress[key])>int(allowed[key]): return "当前章路径进度无效"
 campaign.progress.position=navigation.position.duplicate()
 campaign.progress.path_progress=navigation.path_progress.duplicate(true)
 return ""

static func compare_live(original: RefCounted, rebuilt: RefCounted) -> String:
 if original.active_chapter!=rebuilt.active_chapter or original.state.finished!=rebuilt.state.finished: return "保存候选章节状态不一致"
 for key in ["actors","items","reward_ledger","world_objects","codex"]:
  if not equivalent(original.get(key),rebuilt.get(key)): return "保存候选的"+key+"与已验证连续性不一致"
 var left: Dictionary=original.state.duplicate(true)
 var right: Dictionary=rebuilt.state.duplicate(true)
 if original.state.finished:
  # Completed click logs, last puzzle boards and abandoned measurement UI are
  # deliberately no longer an assertion about historical execution.
  for key in ["chronology","events","puzzle_records","puzzle_snapshot","escape_receipts","measurements","receipts","world_receipts","frozen_contexts"]:
   left.erase(key);right.erase(key)
 if original.state.finished and original.active_chapter>=4:
  for key in ["return_position","return_map_id"]:
   left.erase(key);right.erase(key)
 for key in ["memories","inventory","assists","knowledge"]:
  if left.get(key) is Array: left[key].sort()
  if right.get(key) is Array: right[key].sort()
 if not equivalent(left,right): return "保存候选的章节连续性与归档规则不一致"
 return ""
