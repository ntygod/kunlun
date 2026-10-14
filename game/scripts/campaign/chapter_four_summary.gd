class_name ChapterFourSummary
extends RefCounted
## Declared chapter-four outcomes; never substitutes for unfinished input replay.
const Canonical=preload("res://scripts/campaign/encounter_session.gd")
const IDS=["char_liang_xiao","char_liu_yingying"]
const KEYS=["chapter","summary_version","choices","milestones","semantic_commits","optional_dispositions","boundary_vitals","leader_id"]
static func pack(campaign: RefCounted) -> Dictionary:
 if campaign.active_chapter!=4 or not campaign.state.finished:return {}
 var milestones:Array=[]
 for scene in campaign.current_content().scenes:
  milestones.append("scene:"+scene.id)
  for id in scene.completion_gate.all_of:milestones.append(scene.id+":"+id)
 var vitals:Dictionary={}
 for id in IDS:
  if not campaign.actors.has(id):return {}
  vitals[id]={"hp":campaign.actors[id].hp,"mp":campaign.actors[id].mp}
 var dispositions:Dictionary={}
 for id in ["R02","L01"]:dispositions[id]=campaign.state.optional[id].disposition
 return JSON.parse_string(JSON.stringify({"chapter":4,"summary_version":1,"choices":campaign.state.choices.duplicate(true),"milestones":milestones,"semantic_commits":campaign.state.semantic_commits.duplicate(),"optional_dispositions":dispositions,"boundary_vitals":vitals,"leader_id":campaign.state.leader_id}))
static func _keys(value: Variant,keys: Array) -> bool:
 if not value is Dictionary or value.size()!=keys.size():return false
 for key in keys:
  if not value.has(key):return false
 return true
static func _int(value: Variant) -> bool:return (value is int or value is float) and is_finite(float(value)) and float(value)==floor(float(value))
static func apply(campaign: RefCounted,entry: Dictionary) -> String:
 if not _keys(entry,KEYS) or not _int(entry.chapter) or int(entry.chapter)!=4 or not _int(entry.summary_version) or int(entry.summary_version)!=1:return "章4摘要字段或版本无效"
 if not entry.choices is Dictionary or entry.choices.size()>16 or not entry.milestones is Array or entry.milestones.size()>256 or not entry.semantic_commits is Array or entry.semantic_commits.size()>128:return "章4摘要容器无效"
 for id in entry.choices:
  if not id is String or not entry.choices[id] is String:return "章4选择类型无效"
 for id in entry.semantic_commits:
  if not id is String or id.length()>80:return "章4语义事务类型无效"
 if not _keys(entry.optional_dispositions,["R02","L01"]) or not _keys(entry.boundary_vitals,IDS) or entry.leader_id not in IDS:return "章4边界成员无效"
 for id in ["R02","L01"]:
  if entry.optional_dispositions[id] not in ["completed","declined","missed"]:return "章4支线结局无效"
 for id in IDS:
  if not _keys(entry.boundary_vitals[id],["hp","mp"]):return "章4气血字段无效"
  for field in ["hp","mp"]:
   if not _int(entry.boundary_vitals[id][field]):return "章4气血类型无效"
 if campaign.active_chapter!=3 or not campaign.state.finished:return "章4摘要必须承接已归档章3"
 var previous:bool=campaign._restoring_summary
 campaign._restoring_summary=true
 var error:=_reduce(campaign,entry)
 campaign._restoring_summary=previous
 return error
static func _commit(rt: RefCounted,entry: Dictionary) -> bool:
 var event:Dictionary=rt.current_event()
 var proof:Dictionary={}
 if event.op=="choice":
  var id:Variant=entry.choices.get(rt._choice_key(event))
  var permitted:=false
  for option in rt.available_choices():
   if option.id==id:permitted=true
  if not permitted:return false
  proof={"choice_id":id}
 return rt.commit_archived_result(proof)
static func _reduce(campaign: RefCounted,entry: Dictionary) -> String:
 if not campaign.enter_registered_chapter(4):return "章4摘要前置未满足"
 var rt:RefCounted=campaign.current_chapter_runtime()
 var count:=0
 while not rt.state.finished:
  count+=1
  if count>256:return "章4摘要超出有限步骤"
  var event:Dictionary=rt.current_event()
  if event.op=="quest_window":
   # Replay only bounded, irreversible side transactions in their actual
   # interleaving order. Pure input edits are intentionally no longer claimed.
   while rt.state.semantic_commits.size()<entry.semantic_commits.size():
    var next:String=entry.semantic_commits[rt.state.semantic_commits.size()]
    if next==event.id:break
    var side:String="R02" if next.to_lower().begins_with("r02_") else ("L01" if next.to_lower().begins_with("l01_") else "")
    if side=="":return "章4支线语义顺序无效"
    if rt.state.scope=="main":
     if not rt.open_sidequest(side):return "章4支线语义顺序无效"
    elif rt.state.scope!=side:return "章4未结束遭遇不能跨支线"
    var target_count:int=rt.state.semantic_commits.size()+1
    var side_guard:=0
    while rt.state.scope!="main" and rt.state.semantic_commits.size()<target_count:
     side_guard+=1
     if side_guard>40 or not _commit(rt,entry):return "章4支线语义缺少合法前置"
    if rt.state.semantic_commits.size()!=target_count or rt.state.semantic_commits[-1]!=next:return "章4支线语义不一致"
    if rt.state.scope!="main" and rt.current_event().op!="objective_battle" and not rt.pause_sidequest():return "章4支线暂停边界无效"
   if event.get("deadline",false):
    for side in ["R02","L01"]:
     if rt.state.optional[side].status!="archived" and entry.optional_dispositions[side]=="declined":rt.state.optional[side].disposition="declined"
  if not _commit(rt,entry):return "章4归档事件或选择无效"
  if rt.state.semantic_commits.size()>entry.semantic_commits.size():return "章4语义事务缺失"
  for i in range(rt.state.semantic_commits.size()):
   if rt.state.semantic_commits[i]!=entry.semantic_commits[i]:return "章4语义事务顺序无效"
 for id in IDS:
  var actor:Dictionary=campaign.actors[id]
  var before:Dictionary=rt.state.last_battle_panels.get(id,{})
  if before.is_empty():return "章4缺少双人遭遇里程碑"
  var hp:int=entry.boundary_vitals[id].hp;var mp:int=entry.boundary_vitals[id].mp
  if hp<int(actor.max_hp)-int(before.max_hp)+1 or hp>int(actor.max_hp) or mp<0 or mp>int(before.max_mp):return "章4气血真气违反成长边界"
  actor.hp=hp;actor.mp=mp
 rt.state.leader_id=entry.leader_id
 rt.state.chronology=[];rt.state.puzzle_records={};rt.state.puzzle_snapshot={};rt.state.frozen_contexts={};rt.state.world_receipts={}
 if not Canonical.equivalent(pack(campaign),entry):return "章4摘要结果内部不一致"
 return ""
