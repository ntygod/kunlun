class_name ChapterSevenSummary
extends RefCounted
## Bounded declared results for completed chapter seven; unfinished inputs still replay.
const Canonical=preload("res://scripts/campaign/encounter_session.gd")
const Party=preload("res://scripts/campaign/party_progression.gd")
const Transactions=preload("res://scripts/campaign/chapter_seven_transactions.gd")
const IDS=["char_liang_xiao","char_liu_yingying","char_axue"]
const KEYS=["chapter","summary_version","choices","milestones","semantic_commits","optional_dispositions","boundary_vitals","leader_id"]
static func pack(campaign:RefCounted) -> Dictionary:
 if campaign.active_chapter!=7 or not campaign.state.finished:return {}
 var milestones:Array=[]
 for scene in campaign.current_content().scenes:
  milestones.append("scene:"+scene.id)
  for id in scene.completion_gate.all_of:milestones.append(scene.id+":"+id)
 var vitals:Dictionary={};var dispositions:Dictionary={}
 for id in IDS:vitals[id]={"hp":campaign.actors[id].hp,"mp":campaign.actors[id].mp}
 for side in ["L03"]:dispositions[side]=campaign.state.optional[side].disposition
 return JSON.parse_string(JSON.stringify({"chapter":7,"summary_version":1,"choices":campaign.state.choices.duplicate(true),"milestones":milestones,"semantic_commits":campaign.state.semantic_commits.duplicate(),"optional_dispositions":dispositions,"boundary_vitals":vitals,"leader_id":campaign.state.leader_id}))
static func keys(v:Variant,expected:Array) -> bool:
 if not v is Dictionary or v.size()!=expected.size():return false
 for key in expected:
  if not v.has(key):return false
 return true
static func integer(v:Variant) -> bool:return (v is int or v is float) and is_finite(float(v)) and float(v)==floor(float(v))
static func apply(campaign:RefCounted,entry:Dictionary) -> String:
 if not keys(entry,KEYS) or not integer(entry.chapter) or int(entry.chapter)!=7 or not integer(entry.summary_version) or int(entry.summary_version)!=1:return "章7摘要版本无效"
 if not entry.choices is Dictionary or entry.choices.size()>12 or not entry.milestones is Array or entry.milestones.size()>256 or not entry.semantic_commits is Array or entry.semantic_commits.size()>160:return "章7摘要容器无效"
 for id in entry.choices:
  if not id is String or not entry.choices[id] is String:return "章7选择类型无效"
 for list in [entry.milestones,entry.semantic_commits]:
  for id in list:
   if not id is String or id.length()>120:return "章7里程碑类型无效"
 if not keys(entry.optional_dispositions,["L03"]) or not keys(entry.boundary_vitals,IDS) or not entry.leader_id is String or entry.leader_id!=Party.HERO:return "章7边界成员无效"
 for side in ["L03"]:
  if not entry.optional_dispositions[side] is String or entry.optional_dispositions[side] not in ["completed","declined","missed"]:return "章7支线结局无效"
 for id in IDS:
  if not keys(entry.boundary_vitals[id],["hp","mp"]):return "章7气血字段无效"
  for field in ["hp","mp"]:
   if not integer(entry.boundary_vitals[id][field]):return "章7气血类型无效"
 if campaign.active_chapter!=6 or not campaign.state.finished:return "章7摘要必须承接章6"
 var previous:bool=campaign._restoring_summary;campaign._restoring_summary=true
 var error:=reduce(campaign,entry)
 campaign._restoring_summary=previous
 return error
static func commit(campaign:RefCounted,entry:Dictionary,upper:Dictionary,ledger:Dictionary,count:int) -> bool:
 var rt:RefCounted=campaign.current_chapter_runtime()
 var event:Dictionary=rt.current_event();var proof:Dictionary={}
 if event.op=="choice":
  var id:Variant=entry.choices.get(rt._choice_key(event));var permitted:=false
  for option in rt.available_choices():
   if option.id==id:permitted=true
  if not permitted:return false
  proof={"choice_id":id}
 if event.op=="objective_battle":
  for actor in rt.combat_party():
   # Historical damage is not proven; legal entry and later growth/rest still bound resources.
   campaign.actors[actor.id].hp=1;campaign.actors[actor.id].mp=0
   upper[actor.id].hp=upper[actor.id].max_hp;upper[actor.id].mp=upper[actor.id].max_mp
 var upper_items:Dictionary=campaign.items.duplicate(true);var upper_state:Dictionary=rt.state.duplicate(true);var upper_world:Dictionary=campaign.world_objects.duplicate(true)
 for effect in event.get("effects",[]):
  if effect.op=="chapter_seven_event" and not Transactions.apply(effect.id,upper,upper_items,upper_state,upper_world):return false
 var xp:int=campaign.actors[Party.HERO].xp
 if not rt.commit_archived_result(proof):return false
 var growth:int=campaign.actors[Party.HERO].xp-xp
 if growth>0:Party.award(upper,ledger,"bounds:"+str(count),growth)
 if rt.state.semantic_commits.size()>entry.semantic_commits.size():return false
 for i in range(rt.state.semantic_commits.size()):
  if rt.state.semantic_commits[i]!=entry.semantic_commits[i]:return false
 return true
static func reduce(campaign:RefCounted,entry:Dictionary) -> String:
 if not campaign.enter_registered_chapter(7):return "章7入口无效"
 var rt:RefCounted=campaign.current_chapter_runtime()
 var upper:Dictionary=campaign.actors.duplicate(true);var ledger:Dictionary={};var count:=0
 while not rt.state.finished:
  count+=1
  if count>256:return "章7摘要步骤超限"
  var event:Dictionary=rt.current_event()
  if event.op=="quest_window":
   while rt.state.semantic_commits.size()<entry.semantic_commits.size():
    var next:String=entry.semantic_commits[rt.state.semantic_commits.size()]
    if next==event.id:break
    var side:=""
    for candidate in ["L03"]:
     for candidate_event in rt.runtime.side_quests[candidate]:
      if candidate_event.id==next:side=candidate
    if side.is_empty() or not rt.open_sidequest(side):return "章7侧线顺序无效"
    count+=1
    if count>256 or not commit(campaign,entry,upper,ledger,count):return "章7侧线事务无效"
    if rt.state.scope!="main" and not rt.pause_sidequest():return "章7侧线暂停无效"
   if event.get("deadline",false):
    for side in ["L03"]:
     if rt.state.optional[side].status!="archived" and entry.optional_dispositions[side]=="declined":rt.state.optional[side].disposition="declined"
  if not commit(campaign,entry,upper,ledger,count):return "章7归档事件或选择无效"
 for id in IDS:
  for field in ["hp","mp"]:
   var value:int=entry.boundary_vitals[id][field]
   if value<int(campaign.actors[id][field]) or value>int(upper[id][field]):return "章7资源违反恢复成长边界"
   campaign.actors[id][field]=value
 rt.state.chronology=[];rt.state.puzzle_records={};rt.state.puzzle_snapshot={};rt.state.frozen_contexts={};rt.state.world_receipts={}
 if not Canonical.equivalent(pack(campaign),entry):return "章7摘要内部不一致"
 return ""
