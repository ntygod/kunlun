class_name ChapterSeventeenSummary
extends RefCounted
## Bounded outcomes with two optional-visit windows and an explicit B13 resource boundary.
const Same=preload("res://scripts/campaign/encounter_session.gd")
const IDS=["char_liang_xiao","char_liu_yingying","char_axue","char_hua_xiaoshuang","char_huasheng","char_feng_lian"]
const PARTY=["char_liang_xiao","char_liu_yingying","char_feng_lian"]
const KEYS=["chapter","summary_version","choices","milestones","semantic_commits","boundary_vitals","puzzle_hints","b13_boundary","r07_windows","r07_disposition"]
static func pack(c:RefCounted)->Dictionary:
 if c.active_chapter!=17 or not c.state.finished:return {}
 var milestones:Array=[];var vitals:Dictionary={}
 for scene in c.current_content().scenes:
  milestones.append("scene:"+scene.id)
  for id in scene.completion_gate.all_of:milestones.append(scene.id+":"+id)
 for id in IDS:vitals[id]={"hp":c.actors[id].hp,"mp":c.actors[id].mp}
 return JSON.parse_string(JSON.stringify({"chapter":17,"summary_version":1,"choices":c.state.choices.duplicate(true),"milestones":milestones,"semantic_commits":c.state.semantic_commits.duplicate(),"boundary_vitals":vitals,"puzzle_hints":c.state.puzzle_hints.duplicate(true),"b13_boundary":c.world_objects.get("ch17_b13_boundary",{}).duplicate(true),"r07_windows":c.state.r07_windows.duplicate(true),"r07_disposition":c.state.optional.ch17_r07.disposition}))
static func keys(value:Variant,wanted:Array)->bool:
 if not value is Dictionary or value.size()!=wanted.size():return false
 for key in wanted:
  if not value.has(key):return false
 return true
static func whole(value:Variant)->bool:return (value is int or value is float) and is_finite(float(value)) and value==floor(value)
static func apply(c:RefCounted,entry:Dictionary)->String:
 if not keys(entry,KEYS) or not whole(entry.chapter) or entry.chapter!=17 or not whole(entry.summary_version) or entry.summary_version!=1:return "章17摘要版本无效"
 if not entry.choices is Dictionary or entry.choices.size() not in [6,7] or not entry.milestones is Array or entry.milestones.size()>160 or not entry.semantic_commits is Array or entry.semantic_commits.size()>64:return "章17摘要容器无效"
 for key in entry.choices:
  if not key is String or not entry.choices[key] is String:return "章17选择类型无效"
 for values in [entry.milestones,entry.semantic_commits]:
  for id in values:
   if not id is String or id.length()>160:return "章17里程碑类型无效"
 if not entry.puzzle_hints is Dictionary or not entry.puzzle_hints.has("pz_ch17_evidence") or entry.puzzle_hints.size()>2:return "章17机关记录无效"
 for key in entry.puzzle_hints:
  if key not in ["pz_ch17_evidence","pz_ch17_roof"] or not whole(entry.puzzle_hints[key]) or entry.puzzle_hints[key]<0 or entry.puzzle_hints[key]>3:return "章17提示无效"
 if not keys(entry.boundary_vitals,IDS) or not keys(entry.b13_boundary,PARTY):return "章17边界成员无效"
 for table in [entry.boundary_vitals,entry.b13_boundary]:
  for value in table.values():
   if not keys(value,["hp","mp"]) or not whole(value.hp) or not whole(value.mp):return "章17资源类型无效"
 if not entry.r07_windows is Dictionary or entry.r07_windows.size()>2 or entry.r07_disposition not in ["completed","missed","declined"]:return "章17支线记录无效"
 for key in entry.r07_windows:
  if key not in ["ch17_roof_offer:01","ch17_last_roof:00"] or not whole(entry.r07_windows[key]) or entry.r07_windows[key]<0 or entry.r07_windows[key]>7:return "章17支线窗口无效"
 if c.active_chapter!=16 or not c.state.finished:return "章17摘要必须接续章16"
 var previous:bool=c._restoring_summary;c._restoring_summary=true
 var error:=reduce(c,entry);c._restoring_summary=previous
 return error
static func commit(c:RefCounted,entry:Dictionary,upper:Dictionary)->bool:
 var rt:RefCounted=c.current_chapter_runtime();var e:Dictionary=rt.current_event();var proof:Dictionary={}
 if e.op=="choice":
  var chosen:Variant=entry.choices.get(rt._choice_key(e));var permitted:=false
  for option in rt.available_choices():
   if option.id==chosen:permitted=true
  if not permitted:return false
  proof={"choice_id":chosen}
 if e.op=="quest_window":proof={"closure_acknowledged":true}
 if e.op=="puzzle":
  if not entry.puzzle_hints.has(e.puzzle_id):return false
  rt.state.puzzle_hints[e.puzzle_id]=entry.puzzle_hints[e.puzzle_id]
 if e.op=="objective_battle":
  for id in rt.battle_actor_ids():
   if e.id=="ch17_wolf_double":
    var boundary:Dictionary=entry.b13_boundary[id]
    if boundary.hp<1 or boundary.hp>c.actors[id].max_hp or boundary.mp<0 or boundary.mp>c.actors[id].max_mp:return false
    c.actors[id].hp=int(boundary.hp);c.actors[id].mp=int(boundary.mp)
    upper[id]=c.actors[id].duplicate(true)
   else:
    c.actors[id].hp=1;c.actors[id].mp=0
    upper[id]=c.actors[id].duplicate(true);upper[id].hp=upper[id].max_hp;upper[id].mp=upper[id].max_mp
 var before:Dictionary=c.actors.duplicate(true)
 if not rt.commit_archived_result(proof):return false
 for id in IDS:
  if not c.actors[id].has("max_hp"):continue
  if not upper.get(id,{}).has("hp"):upper[id]=c.actors[id].duplicate(true);continue
  var hp:int=upper[id].hp;var mp:int=upper[id].mp
  if int(c.actors[id].get("xp",0))>int(before[id].get("xp",0)):hp+=int(c.actors[id].max_hp)-int(before[id].max_hp)
  upper[id]=c.actors[id].duplicate(true);upper[id].hp=mini(hp,int(upper[id].max_hp));upper[id].mp=mini(mp,int(upper[id].max_mp))
 return true
static func reduce(c:RefCounted,entry:Dictionary)->String:
 if not c.enter_registered_chapter(17):return "章17入口无效"
 var rt:RefCounted=c.current_chapter_runtime();var upper:Dictionary=c.actors.duplicate(true)
 for count in range(200):
  if rt.state.finished:break
  var e:Dictionary=rt.current_event()
  if e.op=="quest_window" and entry.r07_windows.has(rt.current_token()):
   var progress:int=entry.r07_windows[rt.current_token()]
   if not rt.open_sidequest("ch17_r07") or progress<int(rt.state.side_step):return "章17支线访问无效"
   for n in range(8):
    if rt.state.scope=="main" or int(rt.state.side_step)>=progress:break
    if not commit(c,entry,upper):return "章17支线事务无效"
   if rt.state.scope!="main" and not rt.pause_sidequest():return "章17支线暂停无效"
  if e.id=="ch17_close_roof" and entry.r07_disposition=="declined":rt.state.optional.ch17_r07.disposition="declined"
  if not commit(c,entry,upper):return "章17归档事务无效："+str(e.id)
 if not rt.state.finished:return "章17摘要未结束"
 for id in IDS:
  for key in ["hp","mp"]:
   var value:int=entry.boundary_vitals[id][key]
   if value<int(c.actors[id][key]) or value>int(upper[id][key]):return "章17资源超出成长与交锋边界："+id+"."+key
   c.actors[id][key]=value
 rt.state.chronology=[];rt.state.puzzle_records={};rt.state.puzzle_snapshot={};rt.state.frozen_contexts={}
 if not Same.equivalent(pack(c),entry):return "章17摘要内部不一致"
 return ""
