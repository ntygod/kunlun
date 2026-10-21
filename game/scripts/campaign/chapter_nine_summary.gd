class_name ChapterNineSummary
extends RefCounted
## Rule-checked bounded completed outcome. This is not a fabricated input history.
## Live chapter nine still replays every command against its validated chapter-eight entry.
const Canonical=preload("res://scripts/campaign/encounter_session.gd")
const Party=preload("res://scripts/campaign/party_progression.gd")
const Transactions=preload("res://scripts/campaign/chapter_nine_transactions.gd")
const IDS=["char_liang_xiao","char_liu_yingying","char_axue"]
const KEYS=["chapter","summary_version","choices","milestones","semantic_commits","optional_dispositions","boundary_vitals","leader_id","l05_archive_window"]
static func pack(campaign:RefCounted) -> Dictionary:
 if campaign.active_chapter!=9 or not campaign.state.finished:return {}
 var milestones:Array=[];var vitals:Dictionary={}
 for scene in campaign.current_content().scenes:
  milestones.append("scene:"+scene.id)
  for id in scene.completion_gate.all_of:milestones.append(scene.id+":"+id)
 for id in IDS:vitals[id]={"hp":campaign.actors[id].hp,"mp":campaign.actors[id].mp}
 return JSON.parse_string(JSON.stringify({"chapter":9,"summary_version":1,"choices":campaign.state.choices.duplicate(true),"milestones":milestones,"semantic_commits":campaign.state.semantic_commits.duplicate(),"optional_dispositions":{"L05":campaign.state.optional.L05.disposition},"boundary_vitals":vitals,"leader_id":campaign.state.leader_id,"l05_archive_window":campaign.state.l05_archive_window}))
static func keys(v:Variant,expected:Array) -> bool:
 if not v is Dictionary or v.size()!=expected.size():return false
 for key in expected:
  if not v.has(key):return false
 return true
static func integer(v:Variant) -> bool:return (v is int or v is float) and is_finite(float(v)) and float(v)==floor(float(v))
static func apply(campaign:RefCounted,entry:Dictionary) -> String:
 if not keys(entry,KEYS) or not integer(entry.chapter) or int(entry.chapter)!=9 or not integer(entry.summary_version) or int(entry.summary_version)!=1:return "章9摘要版本无效"
 if not entry.choices is Dictionary or entry.choices.size()>8 or not entry.milestones is Array or entry.milestones.size()>160 or not entry.semantic_commits is Array or entry.semantic_commits.size()>120:return "章9摘要容器无效"
 for id in entry.choices:
  if not id is String or not entry.choices[id] is String:return "章9选择类型无效"
 for list in [entry.milestones,entry.semantic_commits]:
  for id in list:
   if not id is String or id.length()>120:return "章9里程碑类型无效"
 if not keys(entry.optional_dispositions,["L05"]) or not keys(entry.boundary_vitals,IDS) or not entry.leader_id is String or entry.leader_id!=Party.HERO or not entry.l05_archive_window is String:return "章9边界成员无效"
 var done:bool=entry.optional_dispositions.L05=="completed"
 if entry.optional_dispositions.L05 not in ["completed","declined","missed"]:return "章9支线结局无效"
 if done and entry.l05_archive_window not in ["ch09_west_temple_window:01","ch09_bayan_rupture:00"]:return "章9支线归档窗口无效"
 if not done and (entry.l05_archive_window!="" or entry.choices.has("l05_method")):return "章9未完支线不得声明归档"
 for id in IDS:
  if not keys(entry.boundary_vitals[id],["hp","mp"]):return "章9气血字段无效"
  for field in ["hp","mp"]:
   if not integer(entry.boundary_vitals[id][field]):return "章9气血类型无效"
 if campaign.active_chapter!=8 or not campaign.state.finished:return "章9摘要必须承接章8"
 var previous:bool=campaign._restoring_summary;campaign._restoring_summary=true
 var error:=reduce(campaign,entry)
 campaign._restoring_summary=previous
 return error
static func commit(campaign:RefCounted,entry:Dictionary,upper:Dictionary,ledger:Dictionary,count:int) -> bool:
 var rt:RefCounted=campaign.current_chapter_runtime();var event:Dictionary=rt.current_event();var proof:Dictionary={}
 if event.op=="choice":
  var id:Variant=entry.choices.get(rt._choice_key(event));var permitted:=false
  for option in rt.available_choices():
   if option.id==id:permitted=true
  if not permitted:return false
  proof={"choice_id":id}
 if event.id=="rescue_ch09_l05":
  if entry.choices.get("l05_method") not in ["A","B"]:return false
  rt.state.choices.l05_method=entry.choices.l05_method
 if event.op=="objective_battle":
  # Scene commands never consume/recover MP. Only uncertain historical damage is bounded.
  campaign.actors[Party.HERO].hp=1
 # Snapshot validation preconditions are declared only by this bounded finished reducer.
 # The runtime method is gated on campaign._restoring_summary.
 var xp:int=campaign.actors[Party.HERO].xp
 if not rt.commit_archived_result(proof):return false
 var growth:int=campaign.actors[Party.HERO].xp-xp
 if growth>0:Party.award(upper,ledger,"bounds:"+str(count),growth)
 if event.id=="evt_ch09_blood_well_rest":upper[Party.HERO].hp=upper[Party.HERO].max_hp
 if event.id=="evt_ch09_axue_travels_with_liang":upper[Transactions.A].status="travelling_with_liang"
 if rt.state.semantic_commits.size()>entry.semantic_commits.size():return false
 for i in range(rt.state.semantic_commits.size()):
  if rt.state.semantic_commits[i]!=entry.semantic_commits[i]:return false
 return true
static func reduce(campaign:RefCounted,entry:Dictionary) -> String:
 if not campaign.enter_registered_chapter(9):return "章9入口无效"
 var rt:RefCounted=campaign.current_chapter_runtime();var upper:Dictionary=campaign.actors.duplicate(true);var ledger:Dictionary={};var count:=0
 while not rt.state.finished:
  count+=1
  if count>160:return "章9摘要步骤超限"
  var event:Dictionary=rt.current_event()
  if event.op=="quest_window":
   if rt.current_token()==entry.l05_archive_window:
    if not rt.open_sidequest("L05"):return "章9侧线窗口无效"
    count+=1
    if not commit(campaign,entry,upper,ledger,count):return "章9侧线事务无效"
    if rt.state.scope!="main":return "章9侧线未归档"
   if event.get("deadline",false) and rt.state.optional.L05.status!="archived" and entry.optional_dispositions.L05=="declined":rt.state.optional.L05.disposition="declined"
  if not commit(campaign,entry,upper,ledger,count):return "章9归档事件或选择无效："+str(event.id)
 for id in IDS:
  for field in ["hp","mp"]:
   var value:int=entry.boundary_vitals[id][field]
   if value<int(campaign.actors[id][field]) or value>int(upper[id][field]):return "章9资源违反恢复成长边界：%s.%s=%d，允许%d..%d"%[id,field,value,int(campaign.actors[id][field]),int(upper[id][field])]
   campaign.actors[id][field]=value
 rt.state.chronology=[];rt.state.puzzle_records={};rt.state.puzzle_snapshot={};rt.state.frozen_contexts={};rt.state.world_receipts={}
 if not Canonical.equivalent(pack(campaign),entry):return "章9摘要内部不一致"
 return ""
