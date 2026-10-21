class_name ChapterTenWorldActions
extends RefCounted
## Replayable spatial inputs; resources, death and chapter rewards remain runtime transactions.
const SELF := "res://scripts/world_actions/chapter_ten_world_actions.gd"
const MAP_PATH := "res://data/maps/chapter_ten_maps.json"
const H := "char_liang_xiao"
const A := "char_axue"
const LIMIT := 4096
const IDS := ["world_ch10_rescue","world_ch10_escort_children","world_ch10_friends","world_ch10_decoy","world_ch10_axue_return","world_ch10_farewell","world_ch10_river_release","world_ch10_shore_walk","world_ch10_recollection"]
var puzzle_id := ""
var attempt_id := ""
var scene_id := ""
var map_id := ""
var context: Dictionary = {}
var layout: Dictionary = {}
var config: Dictionary = {}
var state: Dictionary = {}
var input_log: Array = []
var engine_event_log: Array = []
var frozen_hash := ""
var initial_hash := ""
var message := ""
static func _canonical(v: Variant) -> Variant:
 if v is StringName:return String(v)
 if v is float and is_finite(v) and v==floor(v):return int(v)
 if v is Array:
  var a:Array=[]
  for x in v:a.append(_canonical(x))
  return a
 if v is Dictionary:
  var d:Dictionary={}
  for k in v:d[String(k) if k is StringName else k]=_canonical(v[k])
  return d
 return v
static func _encoded(v: Variant) -> String:return JSON.stringify(_canonical(v))
static func _integer(v: Variant) -> bool:return (v is int or v is float) and is_finite(float(v)) and float(v)==floor(float(v))
func _p(a:Array)->Vector2:return Vector2(a[0],a[1])
func _a(p:Vector2)->Array:return [int(p.x),int(p.y)]
func _anchor(id:String)->Array:return layout.anchors[id]
func _near(id:String)->bool:return _p(state.position).distance_to(_p(_anchor(id)))<=2
func is_walkable(p:Vector2)->bool:
 var b:Array=layout.walk_bounds
 if p.x<b[0] or p.y<b[1] or p.x>b[0]+b[2] or p.y>b[1]+b[3]:return false
 if puzzle_id=="world_ch10_axue_return" and p.distance_to(Vector2(352,128))<=16:return false
 for r in layout.solids+layout.get("deep_water_rects",[]):
  if Rect2(r[0]-7,r[1]-3,r[2]+14,r[3]+6).has_point(p):return false
 return true
func begin(id:String,attempt:String="",trusted_context:Dictionary={})->bool:
 var candidate=load(SELF).new()
 if not candidate._begin(id,attempt,_canonical(trusted_context)):return false
 _copy(candidate);return true
func _copy(other:RefCounted)->void:
 for key in ["puzzle_id","attempt_id","scene_id","map_id","context","layout","config","state","input_log","engine_event_log","frozen_hash","initial_hash","message"]:
  var v:Variant=other.get(key);set(key,v.duplicate(true) if v is Array or v is Dictionary else v)
func _begin(id:String,attempt:String,c:Dictionary)->bool:
 if id not in IDS or attempt.is_empty():return false
 var data:Variant=JSON.parse_string(FileAccess.get_file_as_string(MAP_PATH))
 if not data is Dictionary:return false
 for mid in data.maps:
  if data.maps[mid].sessions.has(id):map_id=mid;layout=data.maps[mid];config=layout.sessions[id];break
 if layout.is_empty():return false
 if not _integer(c.get("chapter")) or c.chapter!=10:return false
 if not _integer(c.get("revision")) or c.revision<1:return false
 if not c.get("current_token") is String or c.current_token.is_empty():return false
 for pair in [["objective_id",id],["map_id",map_id],["control_actor_id",config.control_actor_id],["scene_id",config.scene_id],["phase",config.scene_id]]:
  if not c.get(pair[0]) is String or c[pair[0]]!=pair[1]:return false
 for key in ["world_objects","actors","items","choices","inherited_choices"]:
  if not c.get(key,{}) is Dictionary:return false
 if not c.get("knowledge",[]) is Array:return false
 puzzle_id=id;attempt_id=attempt;scene_id=config.scene_id;context=c.duplicate(true)
 frozen_hash=_encoded({"layout":layout,"context":context}).sha256_text()
 var start:Array=_anchor(config.get("entry_anchor","entry")).duplicate()
 var prior:Variant=c.get("world_objects",{}).get("ch10_spatial_state",{})
 if not prior is Dictionary:return false
 if prior.get("map_id","")==map_id and prior.get("control_actor_id","")==config.control_actor_id:
  var previous:Variant=prior.get("player_position")
  if not previous is Array or previous.size()!=2:return false
  for n in previous:
   if not _integer(n):return false
  if not is_walkable(_p(previous)):return false
  if id!="world_ch10_shore_walk" and (int(previous[0])%16!=0 or int(previous[1])%16!=0):return false
  start=previous.duplicate()
 state={"position":start,"map_id":map_id,"control_actor_id":config.control_actor_id,"stage":0,"tick":0,"complete":false,"actor_positions":{},"actor_postures":{},"visible_actor_ids":config.visible_actor_ids.duplicate(),"visited":[],"local_objects":{},"active_ms":0,"held_ms":0,"clues":[],"safe_friends":[],"stage_receipts":[],"actor_paths":{},"carrying_actor_id":"","silent":id in ["world_ch10_farewell","world_ch10_shore_walk","world_ch10_river_release"],"recollection":false}
 for actor in layout.actors:
  state.actor_positions[actor.id]=actor.position.duplicate();state.actor_paths[actor.id]=[actor.position.duplicate()]
 state.actor_positions[config.control_actor_id]=start.duplicate()
 if id=="world_ch10_farewell":state.actor_postures[A]="wounded"
 if id=="world_ch10_river_release":state.carrying_actor_id=A;state.actor_postures[A]="resting"
 initial_hash=_encoded(state).sha256_text();message="沿脚下可行的小径前行。";return true
func snapshot()->Dictionary:return {"version":1,"puzzle_id":puzzle_id,"attempt_id":attempt_id,"map_hash":frozen_hash,"input_log":input_log.duplicate(true),"state":state.duplicate(true),"events":engine_event_log.duplicate(true)}
func restore(saved:Dictionary,trusted_context:Dictionary={})->bool:
 var replay=load(SELF).new()
 if not replay.begin(str(saved.get("puzzle_id","")),str(saved.get("attempt_id","")),trusted_context):return false
 if not saved.get("input_log") is Array or saved.input_log.size()>LIMIT:return false
 for action in saved.input_log:
  if not action is Dictionary or not replay.apply_input(action).get("ok",false):return false
 if _encoded(saved)!=_encoded(replay.snapshot()):return false
 _copy(replay);return true
func receipt()->Dictionary:
 if not state.get("complete",false):return {}
 return {"version":1,"puzzle_id":puzzle_id,"objective_id":puzzle_id,"attempt_id":attempt_id,"scene_id":scene_id,"map_id":map_id,"map_hash":frozen_hash,"before_state_hash":initial_hash,"after_state_hash":_encoded(state).sha256_text(),"inputs":input_log.duplicate(true),"engine_events":engine_event_log.duplicate(true),"world_state":_world_state()}
func get_receipts()->Array:return [receipt()] if state.get("complete",false) else []
static func replay_receipt(proof:Dictionary,trusted_context:Dictionary={})->Dictionary:
 var replay=load(SELF).new()
 if not replay.begin(str(proof.get("puzzle_id","")),str(proof.get("attempt_id","")),trusted_context):return {}
 if not proof.get("inputs") is Array or proof.inputs.size()>LIMIT:return {}
 for action in proof.inputs:
  if not action is Dictionary or not replay.apply_input(action).get("ok",false):return {}
 return replay.receipt() if _encoded(replay.receipt())==_encoded(proof) else {}
func _event(type:String)->void:
 engine_event_log.append({"type":type,"tick":state.tick,"position":state.position.duplicate()})
 state.stage_receipts.append(type)
func _complete()->void:state.complete=true;_event(puzzle_id+"_complete")
func apply_input(action:Dictionary)->Dictionary:
 if puzzle_id.is_empty() or state.complete:return {"ok":false}
 action=_canonical(action)
 var type:Variant=action.get("type")
 if not type is String:return {"ok":false}
 var fields:Dictionary={"move":["type","dx","dy"],"walk":["type","dx","dy","milliseconds"],"interact":["type"],"inspect":["type"],"hold":["type","milliseconds"],"linger":["type","milliseconds"],"leave":["type"],"wait":["type"]}
 if not fields.has(type) or action.size()!=fields[type].size():return {"ok":false}
 for key in fields[type]:
  if not action.has(key):return {"ok":false}
 if type in ["move","walk"]:
  if not _integer(action.dx) or not _integer(action.dy) or absf(action.dx)+absf(action.dy)!=1:return {"ok":false}
 if type in ["walk","hold","linger"]:
  if not _integer(action.milliseconds) or action.milliseconds<1 or action.milliseconds>250:return {"ok":false}
 if type=="inspect":return {"ok":true,"no_op":true,"view":get_view(),"message":_instructions(),"receipt":receipt()}
 if input_log.size()>=LIMIT:return {"ok":false,"message":"本段记录已满，请读取较早存档；未修改任何物品或奖励。"}
 if not _operate(action):return {"ok":false,"message":message,"view":get_view()}
 state.tick+=1;state.actor_positions[state.control_actor_id]=state.position.duplicate();input_log.append(action.duplicate(true))
 return {"ok":true,"view":get_view(),"message":message,"receipt":receipt()}
func _operate(a:Dictionary)->bool:
 if a.type=="move":
  if puzzle_id=="world_ch10_shore_walk":return false
  var next:=_p(state.position)+Vector2(a.dx,a.dy)*16
  if not is_walkable(next):message="断木与乱石挡住去路，沿浅色泥径绕行。";return false
  state.position=_a(next);state.held_ms=0
  if puzzle_id=="world_ch10_escort_children":_escort_step()
  return true
 if a.type=="wait":
  if puzzle_id!="world_ch10_escort_children" or _escort_ready():return false
  _escort_step();return true
 if a.type=="walk":
  if puzzle_id!="world_ch10_shore_walk" or a.milliseconds!=250:return false
  var next:=_p(state.position)+Vector2(a.dx,a.dy)
  if not is_walkable(next):return false
  state.position=_a(next);state.active_ms+=a.milliseconds;return true
 if a.type=="hold":
  if puzzle_id!="world_ch10_farewell" or not _near("shelter"):return false
  state.held_ms+=a.milliseconds
  if state.held_ms>=1500:
   state.held_ms=0;state.stage+=1
   _event("steady_axue" if state.stage==1 else "shelter_axue_from_rain")
   state.actor_postures[H]="resting"
   if state.stage>=2:_complete()
  message="";return true
 if a.type=="linger":
  if puzzle_id!="world_ch10_recollection" or state.recollection or not _near("hearth"):return false
  state.held_ms+=a.milliseconds
  if state.held_ms>=3000:state.recollection=true;state.actor_postures[H]="remembering";_event("remember_axue_at_hearth")
  message="";return true
 if a.type=="leave":
  if puzzle_id!="world_ch10_recollection":return false
  _complete();return true
 if a.type!="interact":return false
 if puzzle_id=="world_ch10_farewell":return false
 if puzzle_id=="world_ch10_recollection":return false
 if puzzle_id=="world_ch10_shore_walk":
  if state.active_ms<60000 or not _near("exit"):return false
  _complete();message="";return true
 if puzzle_id=="world_ch10_river_release":
  if not _near("water_edge"):return false
  state.carrying_actor_id="";state.visible_actor_ids.erase(A);state.actor_positions.erase(A);_event("release_axue_to_river");_complete();message="";return true
 if puzzle_id=="world_ch10_escort_children" and not _escort_ready():
  message="楚婉与幼童尚未跟上，在原地稍候。";return false
 var step:Dictionary=config.steps[state.stage]
 if not _near(step.anchor):message="须亲自走到眼前的足迹或同伴身旁。";return false
 state.visited.append(step.anchor);_event(step.verb);state.stage+=1
 if puzzle_id=="world_ch10_axue_return" and step.anchor!="exit":state.clues.append(step.anchor)
 if puzzle_id=="world_ch10_friends":
  state.safe_friends.append(step.anchor)
  var id:="npc_ch10_friend_"+str(state.stage);state.actor_postures[id]="concealed";state.visible_actor_ids.erase(id)
 if state.stage==config.steps.size():_complete()
 message=step.feedback;return true
func _target()->String:
 if state.complete:return config.get("completion_anchor","exit")
 match puzzle_id:
  "world_ch10_farewell":return "shelter"
  "world_ch10_river_release":return "water_edge"
  "world_ch10_shore_walk":return "exit"
  "world_ch10_recollection":return "hearth"
 return config.steps[state.stage].anchor
func _instructions()->String:
 match puzzle_id:
  "world_ch10_farewell":return ""
  "world_ch10_shore_walk":return ""
  "world_ch10_river_release":return ""
  "world_ch10_axue_return":return "阿雪独自辨路：折苇、马蹄泥印、布条，依次看清，再沿南侧泥径绕开追骑。"
  "world_ch10_friends":return "先安置五位同伴，轻点穴道护其性命；引兵另在树外完成。"
  "world_ch10_recollection":return ""
 return "沿浅色路面走近，再按交互键。"
func _world_state()->Dictionary:
 var d:Dictionary=state.duplicate(true);d.erase("position");d.player_position=state.position.duplicate();d.objective_id=puzzle_id;d.target_anchor=_target();d.target_position=_anchor(_target()).duplicate();d.phase=scene_id;d.hold_ms=state.held_ms;d.at_target=_near(_target());return d
func get_view()->Dictionary:
 var options:Array=[]
 if puzzle_id=="world_ch10_recollection":options.append({"id":"leave","label":"继续行路","action":{"type":"leave"}})
 if puzzle_id=="world_ch10_shore_walk" and state.active_ms>=60000 and _near("exit"):options.append({"id":"interact","label":"继续行路","action":{"type":"interact"}})
 if puzzle_id=="world_ch10_escort_children":options.append({"id":"wait","label":"等伤者跟上","action":{"type":"wait"}})
 if not state.silent and puzzle_id!="world_ch10_recollection":options.append({"id":"interact","label":"E 观察／照应","action":{"type":"interact"}})
 return {"puzzle_id":puzzle_id,"title":"" if state.silent else config.label,"body":"" if state.silent else _instructions()+"\n"+message,"instruction":_instructions(),"state":state.duplicate(true),"complete":state.complete,"paused_step_mode":true,"world_state":_world_state(),"options":options,"silent":state.silent,"direct_hold":puzzle_id=="world_ch10_farewell","timed_walk":puzzle_id=="world_ch10_shore_walk","timed_mode":{"world_ch10_farewell":"farewell","world_ch10_shore_walk":"shore_walk","world_ch10_recollection":"recollection"}.get(puzzle_id,""),"recollection":puzzle_id=="world_ch10_recollection"}
func view()->Dictionary:return get_view()
func next_demo_action()->Dictionary:
 ## Test driver only; no assistance is exposed for irrevocable farewell or timed shore.
 if state.complete:return {}
 var target:=_p(_anchor(_target()));var current:=_p(state.position)
 if puzzle_id=="world_ch10_shore_walk":
  if _near("exit") and state.active_ms>=60000:return {"type":"interact"}
  var direction:Vector2=Vector2.RIGHT if current.x<target.x else Vector2.LEFT
  return {"type":"walk","dx":int(direction.x),"dy":0,"milliseconds":250}
 if current!=target:
  var queue:Array=[current];var previous:Dictionary={current:current};var cursor:=0
  while cursor<queue.size():
   var at:Vector2=queue[cursor];cursor+=1
   if at==target:
    while previous[at]!=current:at=previous[at]
    var direction:Vector2=(at-current)/16
    return {"type":"move","dx":int(direction.x),"dy":int(direction.y)}
   for direction in [Vector2.RIGHT,Vector2.DOWN,Vector2.LEFT,Vector2.UP]:
    var next:Vector2=at+direction*16
    if not previous.has(next) and is_walkable(next):previous[next]=at;queue.append(next)
  return {}
 if puzzle_id=="world_ch10_escort_children" and not _escort_ready():return {"type":"wait"}
 if puzzle_id=="world_ch10_farewell":return {"type":"hold","milliseconds":250}
 if puzzle_id=="world_ch10_recollection":return {"type":"leave"} if state.recollection else {"type":"linger","milliseconds":250}
 return {"type":"interact"}

func _path_next(start:Vector2,target:Vector2)->Vector2:
 if start==target:return start
 var queue:Array=[start];var parents:Dictionary={start:start};var i:=0
 while i<queue.size():
  var at:Vector2=queue[i];i+=1
  if at==target:
   while parents[at]!=start:at=parents[at]
   return at
  for direction in [Vector2.RIGHT,Vector2.DOWN,Vector2.LEFT,Vector2.UP]:
   var next:Vector2=at+direction*16
   if not parents.has(next) and is_walkable(next):parents[next]=at;queue.append(next)
 return start
func _escort_step()->void:
 var targets:Dictionary={"npc_chu_wan":state.position.duplicate(),"npc_zhao_shi":state.actor_positions.npc_chu_wan.duplicate()}
 for id in targets:
  var next:Array=_a(_path_next(_p(state.actor_positions[id]),_p(targets[id])))
  if next!=state.actor_positions[id]:state.actor_paths[id].append(next.duplicate())
  state.actor_positions[id]=next
 state.actor_positions.npc_zhao_bing=state.actor_positions.npc_chu_wan.duplicate()
func _escort_ready()->bool:
 return _p(state.actor_positions.npc_chu_wan).distance_to(_p(_anchor("gate")))<=16 and _p(state.actor_positions.npc_zhao_shi).distance_to(_p(_anchor("gate")))<=32
