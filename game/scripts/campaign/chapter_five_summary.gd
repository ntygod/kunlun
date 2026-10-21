class_name ChapterFiveSummary
extends RefCounted
const Canonical=preload("res://scripts/campaign/encounter_session.gd")
const Transactions=preload("res://scripts/campaign/chapter_five_transactions.gd")
const Party=preload("res://scripts/campaign/party_progression.gd")
const IDS=["char_liang_xiao","char_liu_yingying","char_axue"]
const KEYS=["chapter","summary_version","choices","milestones","semantic_commits","boundary_vitals","leader_id"]
static func pack(campaign:RefCounted) -> Dictionary:
 if campaign.active_chapter!=5 or not campaign.state.finished:return {}
 var milestones:Array=[]
 for scene in campaign.current_content().scenes:
  milestones.append("scene:"+scene.id)
  for id in scene.completion_gate.all_of:milestones.append(scene.id+":"+id)
 var vitals:Dictionary={}
 for id in IDS:
  if not campaign.actors.has(id):return {}
  vitals[id]={"hp":campaign.actors[id].hp,"mp":campaign.actors[id].mp}
 return JSON.parse_string(JSON.stringify({"chapter":5,"summary_version":1,"choices":campaign.state.choices.duplicate(true),"milestones":milestones,"semantic_commits":campaign.state.semantic_commits.duplicate(),"boundary_vitals":vitals,"leader_id":campaign.state.leader_id}))
static func keys(v:Variant,expected:Array) -> bool:
 if not v is Dictionary or v.size()!=expected.size():return false
 for k in expected:
  if not v.has(k):return false
 return true
static func integer(v:Variant) -> bool:return (v is int or v is float) and is_finite(float(v)) and float(v)==floor(float(v))
static func apply(campaign:RefCounted,entry:Dictionary) -> String:
 if not keys(entry,KEYS) or not integer(entry.chapter) or int(entry.chapter)!=5 or not integer(entry.summary_version) or int(entry.summary_version)!=1:return "章5摘要版本/字段无效"
 if not entry.choices is Dictionary or entry.choices.size()!=1 or not entry.milestones is Array or entry.milestones.size()>256 or not entry.semantic_commits is Array or entry.semantic_commits.size()>128:return "章5摘要容器无效"
 if not keys(entry.boundary_vitals,IDS) or entry.leader_id!="char_liang_xiao":return "章5摘要角色无效"
 for id in IDS:
  if not keys(entry.boundary_vitals[id],["hp","mp"]):return "章5气血字段无效"
  for field in ["hp","mp"]:
   if not integer(entry.boundary_vitals[id][field]):return "章5气血类型无效"
 for values in [entry.milestones,entry.semantic_commits]:
  for value in values:
   if not value is String or value.length()>120:return "章5摘要里程碑类型无效"
 if campaign.active_chapter!=4 or not campaign.state.finished:return "章5摘要需要完整章4基线"
 var previous:bool=campaign._restoring_summary
 campaign._restoring_summary=true
 var error:=reduce(campaign,entry)
 campaign._restoring_summary=previous
 return error
static func reduce(campaign:RefCounted,entry:Dictionary) -> String:
 if not campaign.enter_registered_chapter(5):return "章5摘要前置未满足"
 var rt:RefCounted=campaign.current_chapter_runtime()
 var count:=0
 var upper:Dictionary={}
 var upper_rewards:Dictionary={}
 while not rt.state.finished:
  count+=1
  if count>128:return "章5摘要步骤超限"
  var event:Dictionary=rt.current_event();var proof:Dictionary={}
  if event.op=="choice":
   var id:Variant=entry.choices.get(rt._choice_key(event));var permitted:=false
   for option in rt.available_choices():
    if option.id==id:permitted=true
   if not permitted:return "章5摘要选择无效"
   proof={"choice_id":id}
  var old_xp:int=campaign.actors[Party.HERO].xp
  if not upper.is_empty():
   var upper_items:Dictionary=campaign.items.duplicate(true)
   var upper_state:Dictionary=rt.state.duplicate(true)
   var upper_world:Dictionary=campaign.world_objects.duplicate(true)
   for effect in event.get("effects",[]):
    if effect.op=="chapter_five_event" and not Transactions.apply(effect.id,upper,upper_items,upper_state,upper_world):return "章5资源边界归约前置无效"
  if not rt.commit_archived_result(proof):return "章5摘要事务缺少合法前置"
  if not upper.is_empty():
   var growth:int=campaign.actors[Party.HERO].xp-old_xp
   if growth>0:Party.award(upper,upper_rewards,"range:"+str(count),growth)
   Transactions.clamp_resources(upper,rt.state)
  if event.get("id")=="enc_ch05_leigong_escape":
   # Completed battle damage is no longer proven, but mandatory later growth
   # and one-time recovery still impose a deterministic lower resource bound.
   upper=campaign.actors.duplicate(true)
   for actor_id in [Party.HERO,Party.LIU]:
    var effective:Dictionary=rt.actor_panel(actor_id)
    upper[actor_id].hp=effective.max_hp;upper[actor_id].mp=effective.max_mp
    campaign.actors[actor_id].hp=1;campaign.actors[actor_id].mp=0
 for id in IDS:
  var actor:Dictionary=campaign.actors[id];var hp:int=entry.boundary_vitals[id].hp;var mp:int=entry.boundary_vitals[id].mp
  if hp<int(actor.hp) or hp>int(upper[id].hp) or mp<int(actor.mp) or mp>int(upper[id].mp):return "章5气血超范围"
  if id=="char_axue" and (hp!=240 or mp!=35):return "章5限定阿雪初始资源无效"
  actor.hp=hp;actor.mp=mp
 rt.state.leader_id=entry.leader_id
 rt.state.chronology=[];rt.state.puzzle_records={};rt.state.puzzle_snapshot={};rt.state.frozen_contexts={};rt.state.world_receipts={}
 if not Canonical.equivalent(pack(campaign),entry):return "章5摘要结果内部不一致"
 return ""
