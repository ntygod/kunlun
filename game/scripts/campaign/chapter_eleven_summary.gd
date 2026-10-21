class_name ChapterElevenSummary
extends RefCounted
## Bounded terminal outcome, never a replacement for live input replay.
const Canonical=preload("res://scripts/campaign/encounter_session.gd")
const Party=preload("res://scripts/campaign/party_progression.gd")
const IDS=["char_liang_xiao","char_liu_yingying","char_axue","char_hua_xiaoshuang","char_huasheng"]
const KEYS=["chapter","summary_version","choices","milestones","semantic_commits","boundary_vitals","leader_id","optional_dispositions","r04_archive_window","r04_progress"]
static func pack(campaign:RefCounted) -> Dictionary:
 if campaign.active_chapter!=11 or not campaign.state.finished:return {}
 var milestones:Array=[];var vitals:Dictionary={};var partial:Array=[]
 for id in ["pz_ch11_r04_triage","pz_ch11_r04_medicine"]:
  if campaign.state.verified_puzzles.get(id,false):partial.append(id)
 for scene in campaign.current_content().scenes:
  milestones.append("scene:"+scene.id)
  for id in scene.completion_gate.all_of:milestones.append(scene.id+":"+id)
 for id in IDS:vitals[id]={"hp":campaign.actors[id].hp,"mp":campaign.actors[id].mp}
 return JSON.parse_string(JSON.stringify({"chapter":11,"summary_version":1,"choices":campaign.state.choices.duplicate(true),"milestones":milestones,"semantic_commits":campaign.state.semantic_commits.duplicate(),"boundary_vitals":vitals,"leader_id":campaign.state.leader_id,"optional_dispositions":{"R04":campaign.state.optional.R04.disposition},"r04_archive_window":campaign.state.r04_archive_window,"r04_progress":{"visit_window":campaign.state.r04_visit_window,"puzzles":partial}}))
static func keys(value:Variant,expected:Array) -> bool:
 if not value is Dictionary or value.size()!=expected.size():return false
 for key in expected:
  if not value.has(key):return false
 return true
static func integer(value:Variant) -> bool:return (value is int or value is float) and is_finite(float(value)) and float(value)==floor(float(value))
static func apply(campaign:RefCounted,entry:Dictionary) -> String:
 if not keys(entry,KEYS) or not integer(entry.chapter) or int(entry.chapter)!=11 or not integer(entry.summary_version) or int(entry.summary_version)!=1:return "章11摘要版本无效"
 if not entry.choices is Dictionary or entry.choices.size()>8 or not entry.milestones is Array or entry.milestones.size()>160 or not entry.semantic_commits is Array or entry.semantic_commits.size()>40:return "章11摘要容器无效"
 for id in entry.choices:
  if not id is String or not entry.choices[id] is String:return "章11选择类型无效"
 for list in [entry.milestones,entry.semantic_commits]:
  for id in list:
   if not id is String or id.length()>120:return "章11里程碑类型无效"
 if not keys(entry.optional_dispositions,["R04"]) or entry.optional_dispositions.R04 not in ["completed","missed","declined"] or not entry.r04_archive_window is String:return "章11支线结局无效"
 if entry.optional_dispositions.R04!="completed" and entry.r04_archive_window!="":return "章11未完成支线不得声明结果"
 if not keys(entry.r04_progress,["visit_window","puzzles"]) or not entry.r04_progress.visit_window is String or not entry.r04_progress.puzzles is Array:return "章11支线访问格式无效"
 if entry.r04_progress.puzzles not in [[],["pz_ch11_r04_triage"],["pz_ch11_r04_triage","pz_ch11_r04_medicine"]]:return "章11支线机关顺序无效"
 if entry.r04_progress.visit_window.is_empty() and (entry.choices.has("r04_method") or not entry.r04_progress.puzzles.is_empty()):return "章11无访问不得保留支线结果"
 if not entry.r04_progress.puzzles.is_empty() and not entry.choices.has("r04_method"):return "章11机关结果缺诊法"
 if not keys(entry.boundary_vitals,IDS) or entry.leader_id!=Party.HERO:return "章11边界成员无效"
 for id in IDS:
  if not keys(entry.boundary_vitals[id],["hp","mp"]):return "章11气血字段无效"
  for field in ["hp","mp"]:
   if not integer(entry.boundary_vitals[id][field]):return "章11气血类型无效"
 if campaign.active_chapter!=10 or not campaign.state.finished:return "章11摘要必须承接章10"
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
  for id in [Party.HERO,Party.XIAOSHUANG]:
   # Rescue requires both alive; P01 is an exactly-once engine reward.
   campaign.actors[id].hp=1
   if "HXS_P01" in campaign.actors[Party.XIAOSHUANG].equipped_passives:campaign.actors[id].hp+=int(floor(float(campaign.actors[id].max_hp)*0.20))
   campaign.actors[id].mp=0;upper[id].mp=upper[id].max_mp;upper[id].hp=upper[id].max_hp
 var xp:int=campaign.actors[Party.HERO].xp
 if not rt.commit_archived_result(proof):return false
 for effect in event.get("effects",[]):
  match effect.get("id",""):
   "evt_ch11_xiaoshuang_rejoined":upper[Party.XIAOSHUANG]=campaign.actors[Party.XIAOSHUANG].duplicate(true)
   "evt_ch11_huasheng_joined":upper[Party.HUASHENG]=campaign.actors[Party.HUASHENG].duplicate(true)
   "evt_ch11_circulate_yin_yang":
    if not Party.equip_xiaoshuang_n02(upper):return false
   "evt_ch11_standard_supplies":
    if not Party.refit_ch11(upper,Party.HERO) or not Party.refit_ch11(upper,Party.XIAOSHUANG):return false
 var growth:int=campaign.actors[Party.HERO].xp-xp
 if growth>0:Party.award(upper,ledger,"bounds:"+str(count),growth)
 if rt.state.semantic_commits.size()>entry.semantic_commits.size():return false
 for i in range(rt.state.semantic_commits.size()):
  if rt.state.semantic_commits[i]!=entry.semantic_commits[i]:return false
 return true
static func reduce(campaign:RefCounted,entry:Dictionary) -> String:
 if not campaign.enter_registered_chapter(11):return "章11入口无效"
 var rt:RefCounted=campaign.current_chapter_runtime();var upper:Dictionary=campaign.actors.duplicate(true);var ledger:Dictionary={};var count:=0
 while not rt.state.finished:
  count+=1
  if count>160:return "章11摘要步骤超限"
  var event:Dictionary=rt.current_event()
  if event.op=="quest_window":
   if rt.current_token()==entry.r04_progress.visit_window and rt.current_token()!=entry.r04_archive_window:
    if not rt.open_sidequest("R04"):return "章11部分访问窗口无效"
    if entry.optional_dispositions.R04!="completed":
     while rt.state.scope!="main":
      var partial_event:Dictionary=rt.current_event()
      if partial_event.op=="choice" and not entry.choices.has("r04_method"):break
      if partial_event.op=="puzzle" and partial_event.id not in entry.r04_progress.puzzles:break
      if partial_event.id=="evt_ch11_r04_completed":break
      count+=1
      if count>160 or not commit(campaign,entry,upper,ledger,count):return "章11部分支线事务无效"
    if not rt.pause_sidequest():return "章11部分支线暂停无效"
   if rt.current_token()==entry.r04_archive_window and entry.optional_dispositions.R04=="completed":
    if not rt.open_sidequest("R04"):return "章11支线窗口无效"
    while rt.state.scope!="main":
     count+=1
     if count>160 or not commit(campaign,entry,upper,ledger,count):return "章11支线事务无效"
   if event.get("deadline",false) and rt.state.optional.R04.status!="archived" and entry.optional_dispositions.R04=="declined":rt.state.optional.R04.disposition="declined"
  if not commit(campaign,entry,upper,ledger,count):return "章11归档事务无效："+str(event.id)
 for id in IDS:
  for field in ["hp","mp"]:
   var value:int=entry.boundary_vitals[id][field]
   if value<int(campaign.actors[id][field]) or value>int(upper[id][field]):return "章11资源违反成长与战斗边界："+id+"."+field
   campaign.actors[id][field]=value
 rt.state.chronology=[];rt.state.puzzle_records={};rt.state.puzzle_snapshot={};rt.state.frozen_contexts={};rt.state.world_receipts={}
 if not Canonical.equivalent(pack(campaign),entry):return "章11摘要内部不一致"
 return ""
