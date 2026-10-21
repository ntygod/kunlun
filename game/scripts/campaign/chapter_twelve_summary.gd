class_name ChapterTwelveSummary
extends RefCounted
## Bounded terminal outcome, never a replacement for live input replay.
const Canonical=preload("res://scripts/campaign/encounter_session.gd")
const Party=preload("res://scripts/campaign/party_progression.gd")
const IDS=["char_liang_xiao","char_liu_yingying","char_axue","char_hua_xiaoshuang","char_huasheng"]
const KEYS=["chapter","summary_version","choices","milestones","semantic_commits","boundary_vitals","leader_id","optional_dispositions","r05_archive_window","r05_progress"]
static func pack(campaign:RefCounted) -> Dictionary:
 if campaign.active_chapter!=12 or not campaign.state.finished:return {}
 var milestones:Array=[];var vitals:Dictionary={};var partial:Array=[]
 for id in ["pz_ch12_r05_rescue","world_ch12_r05_road_repair"]:
  if campaign.state.verified_puzzles.get(id,false):partial.append(id)
 for scene in campaign.current_content().scenes:
  milestones.append("scene:"+scene.id)
  for id in scene.completion_gate.all_of:milestones.append(scene.id+":"+id)
 for id in IDS:vitals[id]={"hp":campaign.actors[id].hp,"mp":campaign.actors[id].mp}
 return JSON.parse_string(JSON.stringify({"chapter":12,"summary_version":1,"choices":campaign.state.choices.duplicate(true),"milestones":milestones,"semantic_commits":campaign.state.semantic_commits.duplicate(),"boundary_vitals":vitals,"leader_id":campaign.state.leader_id,"optional_dispositions":{"R05":campaign.state.optional.R05.disposition},"r05_archive_window":campaign.state.r05_archive_window,"r05_progress":{"visit_window":campaign.state.r05_visit_window,"puzzles":partial}}))
static func keys(value:Variant,expected:Array) -> bool:
 if not value is Dictionary or value.size()!=expected.size():return false
 for key in expected:
  if not value.has(key):return false
 return true
static func integer(value:Variant) -> bool:return (value is int or value is float) and is_finite(float(value)) and float(value)==floor(float(value))
static func apply(campaign:RefCounted,entry:Dictionary) -> String:
 if not keys(entry,KEYS) or not integer(entry.chapter) or int(entry.chapter)!=12 or not integer(entry.summary_version) or int(entry.summary_version)!=1:return "章12摘要版本无效"
 if not entry.choices is Dictionary or entry.choices.size()>12 or not entry.milestones is Array or entry.milestones.size()>240 or not entry.semantic_commits is Array or entry.semantic_commits.size()>60:return "章12摘要容器无效"
 for id in entry.choices:
  if not id is String or not entry.choices[id] is String:return "章12选择类型无效"
 for list in [entry.milestones,entry.semantic_commits]:
  for id in list:
   if not id is String or id.length()>120:return "章12里程碑类型无效"
 if not keys(entry.optional_dispositions,["R05"]) or entry.optional_dispositions.R05 not in ["completed","missed","declined"] or not entry.r05_archive_window is String:return "章12支线结局无效"
 if entry.optional_dispositions.R05!="completed" and entry.r05_archive_window!="":return "章12未完成支线不得声明结果"
 if not keys(entry.r05_progress,["visit_window","puzzles"]) or not entry.r05_progress.visit_window is String or not entry.r05_progress.puzzles is Array:return "章12支线访问格式无效"
 if entry.r05_progress.puzzles not in [[],["pz_ch12_r05_rescue"],["pz_ch12_r05_rescue","world_ch12_r05_road_repair"]]:return "章12支线机关顺序无效"
 if entry.r05_progress.visit_window.is_empty() and (entry.choices.has("r05_method") or not entry.r05_progress.puzzles.is_empty()):return "章12无访问不得保留支线结果"
 if not entry.r05_progress.puzzles.is_empty() and not entry.choices.has("r05_method"):return "章12机关结果缺诊法"
 if not keys(entry.boundary_vitals,IDS) or entry.leader_id!=Party.HERO:return "章12边界成员无效"
 for id in IDS:
  if not keys(entry.boundary_vitals[id],["hp","mp"]):return "章12气血字段无效"
  for field in ["hp","mp"]:
   if not integer(entry.boundary_vitals[id][field]):return "章12气血类型无效"
 if campaign.active_chapter!=11 or not campaign.state.finished:return "章12摘要必须承接章11"
 var previous:bool=campaign._restoring_summary;campaign._restoring_summary=true
 var error:=reduce(campaign,entry)
 campaign._restoring_summary=previous
 return error
static func commit(campaign:RefCounted,entry:Dictionary,upper:Dictionary,ledger:Dictionary,count:int)->bool:
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
   # Each duel owns one resource boundary; B09 victory requires three survivors.
   campaign.actors[id].hp=1;campaign.actors[id].mp=0
   if Party.XIAOSHUANG in rt.battle_actor_ids() and "HXS_P01" in campaign.actors[Party.XIAOSHUANG].equipped_passives:campaign.actors[id].hp+=int(floor(float(campaign.actors[id].max_hp)*0.2))
   upper[id].mp=upper[id].max_mp;upper[id].hp=upper[id].max_hp
 var xp:int=campaign.actors[Party.HERO].xp
 if not rt.commit_archived_result(proof):return false
 var growth:int=campaign.actors[Party.HERO].xp-xp
 if growth>0:Party.award(upper,ledger,"bounds:"+str(count),growth)
 if rt.state.semantic_commits.size()>entry.semantic_commits.size():return false
 for i in range(rt.state.semantic_commits.size()):
  if rt.state.semantic_commits[i]!=entry.semantic_commits[i]:return false
 return true
static func reduce(campaign:RefCounted,entry:Dictionary) -> String:
 if not campaign.enter_registered_chapter(12):return "章12入口无效"
 var rt:RefCounted=campaign.current_chapter_runtime();var upper:Dictionary=campaign.actors.duplicate(true);var ledger:Dictionary={};var count:=0
 while not rt.state.finished:
  count+=1
  if count>240:return "章12摘要步骤超限"
  var event:Dictionary=rt.current_event()
  if event.op=="quest_window":
   if rt.current_token()==entry.r05_progress.visit_window and rt.current_token()!=entry.r05_archive_window:
    if not rt.open_sidequest("R05"):return "章12部分访问窗口无效"
    if entry.optional_dispositions.R05!="completed":
     while rt.state.scope!="main":
      var partial_event:Dictionary=rt.current_event()
      if partial_event.op=="choice" and not entry.choices.has("r05_method"):break
      if partial_event.op in ["puzzle","world_puzzle"] and partial_event.id not in entry.r05_progress.puzzles:break
      if partial_event.id=="evt_ch12_r05_completed":break
      count+=1
      if count>240 or not commit(campaign,entry,upper,ledger,count):return "章12部分支线事务无效"
    if not rt.pause_sidequest():return "章12部分支线暂停无效"
   if rt.current_token()==entry.r05_archive_window and entry.optional_dispositions.R05=="completed":
    if not rt.open_sidequest("R05"):return "章12支线窗口无效"
    while rt.state.scope!="main":
     count+=1
     if count>240 or not commit(campaign,entry,upper,ledger,count):return "章12支线事务无效"
   if event.get("deadline",false) and rt.state.optional.R05.status!="archived" and entry.optional_dispositions.R05=="declined":rt.state.optional.R05.disposition="declined"
  if not commit(campaign,entry,upper,ledger,count):return "章12归档事务无效："+str(event.id)
 for id in IDS:
  for field in ["hp","mp"]:
   var value:int=entry.boundary_vitals[id][field]
   if value<int(campaign.actors[id][field]) or value>int(upper[id][field]):return "章12资源违反成长与战斗边界："+id+"."+field
   campaign.actors[id][field]=value
 rt.state.chronology=[];rt.state.puzzle_records={};rt.state.puzzle_snapshot={};rt.state.frozen_contexts={};rt.state.world_receipts={}
 if not Canonical.equivalent(pack(campaign),entry):return "章12摘要内部不一致"
 return ""
