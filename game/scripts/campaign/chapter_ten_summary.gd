class_name ChapterTenSummary
extends RefCounted
## Bounded terminal outcome, never a replacement for live input replay.
const Canonical=preload("res://scripts/campaign/encounter_session.gd")
const Party=preload("res://scripts/campaign/party_progression.gd")
const IDS=["char_liang_xiao","char_liu_yingying","char_axue"]
const KEYS=["chapter","summary_version","choices","milestones","semantic_commits","boundary_vitals","leader_id"]
static func pack(campaign:RefCounted) -> Dictionary:
 if campaign.active_chapter!=10 or not campaign.state.finished:return {}
 var milestones:Array=[];var vitals:Dictionary={}
 for scene in campaign.current_content().scenes:
  milestones.append("scene:"+scene.id)
  for id in scene.completion_gate.all_of:milestones.append(scene.id+":"+id)
 for id in IDS:vitals[id]={"hp":campaign.actors[id].hp,"mp":campaign.actors[id].mp}
 return JSON.parse_string(JSON.stringify({"chapter":10,"summary_version":1,"choices":campaign.state.choices.duplicate(true),"milestones":milestones,"semantic_commits":campaign.state.semantic_commits.duplicate(),"boundary_vitals":vitals,"leader_id":campaign.state.leader_id}))
static func keys(value:Variant,expected:Array) -> bool:
 if not value is Dictionary or value.size()!=expected.size():return false
 for key in expected:
  if not value.has(key):return false
 return true
static func integer(value:Variant) -> bool:return (value is int or value is float) and is_finite(float(value)) and float(value)==floor(float(value))
static func apply(campaign:RefCounted,entry:Dictionary) -> String:
 if not keys(entry,KEYS) or not integer(entry.chapter) or int(entry.chapter)!=10 or not integer(entry.summary_version) or int(entry.summary_version)!=1:return "章10摘要版本无效"
 if not entry.choices is Dictionary or entry.choices.size()>4 or not entry.milestones is Array or entry.milestones.size()>160 or not entry.semantic_commits is Array or entry.semantic_commits.size()>30:return "章10摘要容器无效"
 for id in entry.choices:
  if not id is String or not entry.choices[id] is String:return "章10选择类型无效"
 for list in [entry.milestones,entry.semantic_commits]:
  for id in list:
   if not id is String or id.length()>120:return "章10里程碑类型无效"
 if not keys(entry.boundary_vitals,IDS) or entry.leader_id!=Party.HERO:return "章10边界成员无效"
 for id in IDS:
  if not keys(entry.boundary_vitals[id],["hp","mp"]):return "章10气血字段无效"
  for field in ["hp","mp"]:
   if not integer(entry.boundary_vitals[id][field]):return "章10气血类型无效"
 if campaign.active_chapter!=9 or not campaign.state.finished:return "章10摘要必须承接章9"
 var previous:bool=campaign._restoring_summary;campaign._restoring_summary=true
 var error:=reduce(campaign,entry)
 campaign._restoring_summary=previous
 return error
static func reduce(campaign:RefCounted,entry:Dictionary) -> String:
 if not campaign.enter_registered_chapter(10):return "章10入口无效"
 var rt:RefCounted=campaign.current_chapter_runtime();var upper:Dictionary=campaign.actors.duplicate(true);var ledger:Dictionary={};var count:=0
 while not rt.state.finished:
  count+=1
  if count>160:return "章10摘要步骤超限"
  var event:Dictionary=rt.current_event();var proof:Dictionary={}
  if event.op=="choice":
   var choice:Variant=entry.choices.get(rt._choice_key(event));var permitted:=false
   for option in rt.available_choices():
    if option.id==choice:permitted=true
   if not permitted:return "章10选择无效"
   proof={"choice_id":choice}
  if event.op=="objective_battle":
   # One actual battle: damage/MP consumption are bounded; MP is filled only at entry.
   campaign.actors[Party.HERO].hp=1;campaign.actors[Party.HERO].mp=0
   upper[Party.HERO].mp=upper[Party.HERO].max_mp
  var xp:int=campaign.actors[Party.HERO].xp
  if not rt.commit_archived_result(proof):return "章10归档事务无效："+str(event.id)
  var growth:int=campaign.actors[Party.HERO].xp-xp
  if growth>0:Party.award(upper,ledger,"bounds:"+str(count),growth)
  for effect in event.get("effects",[]):
   if effect.get("id")=="evt_ch10_prepare_escape":upper[Party.HERO].hp=upper[Party.HERO].max_hp
  if rt.state.semantic_commits.size()>entry.semantic_commits.size():return "章10事务序列无效"
  for i in range(rt.state.semantic_commits.size()):
   if rt.state.semantic_commits[i]!=entry.semantic_commits[i]:return "章10事务顺序无效"
 for id in IDS:
  for field in ["hp","mp"]:
   var value:int=entry.boundary_vitals[id][field]
   if value<int(campaign.actors[id][field]) or value>int(upper[id][field]):return "章10资源违反成长与战斗边界："+id+"."+field
   campaign.actors[id][field]=value
 rt.state.chronology=[];rt.state.puzzle_records={};rt.state.puzzle_snapshot={};rt.state.frozen_contexts={};rt.state.world_receipts={}
 if not Canonical.equivalent(pack(campaign),entry):return "章10摘要内部不一致"
 return ""
