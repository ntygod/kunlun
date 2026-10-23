class_name ChapterSixteenSummary
extends RefCounted
## Bounded terminal outcomes, not a claim that the completed chapter inputs are still retained.
const Same=preload("res://scripts/campaign/encounter_session.gd")
const IDS=["char_liang_xiao","char_liu_yingying","char_axue","char_hua_xiaoshuang","char_huasheng"]
const KEYS=["chapter","summary_version","choices","milestones","semantic_commits","boundary_vitals","puzzle_hints"]
static func pack(c:RefCounted)->Dictionary:
 if c.active_chapter!=16 or not c.state.finished:return {}
 var milestones:Array=[];var vitals:Dictionary={}
 for scene in c.current_content().scenes:
  milestones.append("scene:"+scene.id)
  for id in scene.completion_gate.all_of:milestones.append(scene.id+":"+id)
 for id in IDS:vitals[id]={"hp":c.actors[id].hp,"mp":c.actors[id].mp}
 return JSON.parse_string(JSON.stringify({"chapter":16,"summary_version":1,"choices":c.state.choices.duplicate(true),"milestones":milestones,"semantic_commits":c.state.semantic_commits.duplicate(),"boundary_vitals":vitals,"puzzle_hints":c.state.puzzle_hints.duplicate(true)}))
static func keys(value:Variant,wanted:Array)->bool:
 if not value is Dictionary or value.size()!=wanted.size():return false
 for key in wanted:
  if not value.has(key):return false
 return true
static func whole(value:Variant)->bool:return (value is int or value is float) and is_finite(float(value)) and value==floor(value)
static func apply(c:RefCounted,entry:Dictionary)->String:
 if not keys(entry,KEYS) or not whole(entry.chapter) or entry.chapter!=16 or not whole(entry.summary_version) or entry.summary_version!=1:return "章16摘要版本无效"
 if not entry.choices is Dictionary or entry.choices.size()!=8 or not entry.milestones is Array or entry.milestones.size()>128 or not entry.semantic_commits is Array or entry.semantic_commits.size()>40:return "章16摘要容器无效"
 for key in entry.choices:
  if not key is String or not entry.choices[key] is String:return "章16选择类型无效"
 for values in [entry.milestones,entry.semantic_commits]:
  for id in values:
   if not id is String or id.length()>160:return "章16里程碑类型无效"
 if not keys(entry.puzzle_hints,["pz_ch16_river","pz_ch16_scale","pz_ch16_study"]):return "章16机关记录无效"
 for n in entry.puzzle_hints.values():
  if not whole(n) or n<0 or n>3:return "章16提示层级无效"
 if not keys(entry.boundary_vitals,IDS):return "章16边界成员无效"
 for value in entry.boundary_vitals.values():
  if not keys(value,["hp","mp"]) or not whole(value.hp) or not whole(value.mp):return "章16资源类型无效"
 if c.active_chapter!=15 or not c.state.finished:return "章16摘要必须接续章15"
 var previous:bool=c._restoring_summary;c._restoring_summary=true
 var error:=reduce(c,entry)
 c._restoring_summary=previous
 return error
static func reduce(c:RefCounted,entry:Dictionary)->String:
 if not c.enter_registered_chapter(16):return "章16入口无效"
 var rt:RefCounted=c.current_chapter_runtime();var upper:Dictionary=c.actors.duplicate(true)
 for count in range(128):
  if rt.state.finished:break
  var e:Dictionary=rt.current_event();var proof:Dictionary={}
  if e.op=="choice":
   var permitted:=false;var chosen:Variant=entry.choices.get(rt._choice_key(e))
   for choice in rt.available_choices():
    if choice.id==chosen:permitted=true
   if not permitted:return "章16选择无效"
   proof={"choice_id":chosen}
  if e.op=="objective_battle":
   # Only Liang participates. Other actors' HP/MP must remain their inherited value plus growth.
   c.actors.char_liang_xiao.hp=1;c.actors.char_liang_xiao.mp=0
   upper.char_liang_xiao.hp=c.actors.char_liang_xiao.max_hp;upper.char_liang_xiao.mp=c.actors.char_liang_xiao.max_mp
  if e.op=="puzzle":rt.state.puzzle_hints[e.puzzle_id]=entry.puzzle_hints[e.puzzle_id]
  var before:Dictionary=c.actors.duplicate(true)
  if not rt.commit_archived_result(proof):return "章16归档事务无效："+str(e.id)
  for id in IDS:
   var hp:int=upper[id].hp;var mp:int=upper[id].mp
   if int(c.actors[id].get("xp",0))>int(before[id].get("xp",0)):hp+=int(c.actors[id].max_hp)-int(before[id].max_hp)
   upper[id]=c.actors[id].duplicate(true);upper[id].hp=mini(hp,int(upper[id].max_hp));upper[id].mp=mini(mp,int(upper[id].max_mp))
 if not rt.state.finished:return "章16摘要未结束"
 for id in IDS:
  for key in ["hp","mp"]:
   var value:int=entry.boundary_vitals[id][key]
   if value<int(c.actors[id][key]) or value>int(upper[id][key]):return "章16资源超出成长与战斗边界"
   c.actors[id][key]=value
 rt.state.chronology=[];rt.state.puzzle_records={};rt.state.puzzle_snapshot={};rt.state.frozen_contexts={}
 if not Same.equivalent(pack(c),entry):return "章16摘要内部不一致"
 return ""
