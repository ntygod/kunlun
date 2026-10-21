class_name ChapterThirteenSummary
extends RefCounted
## Bounded terminal outcome; all live partials retain strict command replay.
const Canonical=preload("res://scripts/campaign/encounter_session.gd")
const Party=preload("res://scripts/campaign/party_progression.gd")
const IDS=["char_liang_xiao","char_liu_yingying","char_axue","char_hua_xiaoshuang","char_huasheng"]
const KEYS=["chapter","summary_version","choices","milestones","semantic_commits","boundary_vitals","leader_id"]
static func pack(campaign:RefCounted) -> Dictionary:
 if campaign.active_chapter!=13 or not campaign.state.finished:return {}
 var milestones:Array=[];var vitals:Dictionary={}
 for scene in campaign.current_content().scenes:
  milestones.append("scene:"+scene.id)
  for id in scene.completion_gate.all_of:milestones.append(scene.id+":"+id)
 for id in IDS:vitals[id]={"hp":campaign.actors[id].hp,"mp":campaign.actors[id].mp}
 return JSON.parse_string(JSON.stringify({"chapter":13,"summary_version":1,"choices":campaign.state.choices.duplicate(true),"milestones":milestones,"semantic_commits":campaign.state.semantic_commits.duplicate(),"boundary_vitals":vitals,"leader_id":campaign.state.leader_id}))
static func keys(value:Variant,expected:Array) -> bool:
 if not value is Dictionary or value.size()!=expected.size():return false
 for key in expected:
  if not value.has(key):return false
 return true
static func integer(value:Variant) -> bool:return (value is int or value is float) and is_finite(float(value)) and float(value)==floor(float(value))
static func apply(campaign:RefCounted,entry:Dictionary) -> String:
 if not keys(entry,KEYS) or not integer(entry.chapter) or int(entry.chapter)!=13 or not integer(entry.summary_version) or int(entry.summary_version)!=1:return "章13摘要版本无效"
 if not entry.choices is Dictionary or entry.choices.size()>12 or not entry.milestones is Array or entry.milestones.size()>280 or not entry.semantic_commits is Array or entry.semantic_commits.size()>60:return "章13摘要容器无效"
 for id in entry.choices:
  if not id is String or not entry.choices[id] is String:return "章13选择类型无效"
 for list in [entry.milestones,entry.semantic_commits]:
  for id in list:
   if not id is String or id.length()>120:return "章13里程碑类型无效"
 if not keys(entry.boundary_vitals,IDS) or entry.leader_id!=Party.HERO:return "章13边界成员无效"
 for id in IDS:
  if not keys(entry.boundary_vitals[id],["hp","mp"]):return "章13气血字段无效"
  for field in ["hp","mp"]:
   if not integer(entry.boundary_vitals[id][field]):return "章13气血类型无效"
 if campaign.active_chapter!=12 or not campaign.state.finished:return "章13摘要必须承接章12"
 var previous:bool=campaign._restoring_summary;campaign._restoring_summary=true
 var error:=reduce(campaign,entry)
 campaign._restoring_summary=previous
 return error
static func commit(campaign:RefCounted,entry:Dictionary,upper:Dictionary)->bool:
 var rt:RefCounted=campaign.current_chapter_runtime();var event:Dictionary=rt.current_event();var proof:Dictionary={}
 if event.op=="choice":
  var choice:Variant=entry.choices.get(rt._choice_key(event));var permitted:=false
  for option in rt.available_choices():
   if option.id==choice:permitted=true
  if not permitted:return false
  proof={"choice_id":choice}
 if event.op=="quest_window":proof={"closure_acknowledged":true}
 if event.op=="objective_battle":
  for id in rt.battle_actor_ids():
   campaign.actors[id].hp=1;campaign.actors[id].mp=0
   upper[id].hp=upper[id].max_hp;upper[id].mp=upper[id].max_mp
 var before:Dictionary=campaign.actors.duplicate(true)
 if not rt.commit_archived_result(proof):return false
 for id in IDS:
  # The same legal transactions derive stats; growth grants only its max-HP delta.
  # Equipping an internal does not heal or refill, including in the upper bound.
  var hp:int=upper[id].hp;var mp:int=upper[id].mp
  if int(campaign.actors[id].get("xp",0))>int(before[id].get("xp",0)):hp+=int(campaign.actors[id].max_hp)-int(before[id].max_hp)
  upper[id]=campaign.actors[id].duplicate(true)
  upper[id].hp=mini(hp,int(upper[id].max_hp));upper[id].mp=mini(mp,int(upper[id].max_mp))
 if rt.state.semantic_commits.size()>entry.semantic_commits.size():return false
 for i in range(rt.state.semantic_commits.size()):
  if rt.state.semantic_commits[i]!=entry.semantic_commits[i]:return false
 return true
static func reduce(campaign:RefCounted,entry:Dictionary) -> String:
 if not campaign.enter_registered_chapter(13):return "章13入口无效"
 var rt:RefCounted=campaign.current_chapter_runtime();var upper:Dictionary=campaign.actors.duplicate(true);var count:=0
 while not rt.state.finished:
  count+=1
  if count>280:return "章13摘要步骤超限"
  var event:Dictionary=rt.current_event()
  if not commit(campaign,entry,upper):return "章13归档事务无效："+str(event.id)
 for id in IDS:
  for field in ["hp","mp"]:
   var value:int=entry.boundary_vitals[id][field]
   if value<int(campaign.actors[id][field]) or value>int(upper[id][field]):return "章13资源违反成长与战斗边界："+id+"."+field
   campaign.actors[id][field]=value
 rt.state.chronology=[];rt.state.puzzle_records={};rt.state.puzzle_snapshot={};rt.state.frozen_contexts={};rt.state.world_receipts={}
 if not Canonical.equivalent(pack(campaign),entry):return "章13摘要内部不一致"
 return ""
