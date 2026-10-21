class_name ChapterElevenWorldActions
extends RefCounted
## Replayable spatial inputs; resources, death and chapter rewards remain runtime transactions.
const SELF := "res://scripts/world_actions/chapter_eleven_world_actions.gd"
const MAP_PATH := "res://data/maps/chapter_eleven_maps.json"
const H := "char_liang_xiao"
const A := "char_axue"
const LIMIT := 4096
const X := "char_hua_xiaoshuang"
const DOG := "follower_baichier"
const IDS := ["world_ch11_town_truce","world_ch11_reunion_observe","world_ch11_sunrise_ascent","world_ch11_cave_escape","world_ch11_plum_practice","world_ch11_river_boulder"]
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
func _anchor(id:String)->Array:
 var at:Array=layout.anchors[id].duplicate()
 if puzzle_id=="world_ch11_river_boulder" and id=="brace" and not state.is_empty() and state.stage==2:at[0]+=state.push_count*16
 return at
func _near(id:String)->bool:return _p(state.position).distance_to(_p(_anchor(id)))<=2
func is_walkable(p:Vector2)->bool:
 var b:Array=layout.walk_bounds
 if p.x<b[0] or p.y<b[1] or p.x>b[0]+b[2] or p.y>b[1]+b[3]:return false
 if puzzle_id=="world_ch11_cave_escape" and p.distance_to(Vector2(288,128))<=32:return false
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
 if not _integer(c.get("chapter")) or c.chapter!=11:return false
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
 var prior:Variant=c.get("world_objects",{}).get("ch11_spatial_state",{})
 if not prior is Dictionary:return false
 if prior.get("map_id","")==map_id and prior.get("control_actor_id","")==config.control_actor_id:
  var previous:Variant=prior.get("player_position")
  if not previous is Array or previous.size()!=2:return false
  for n in previous:
   if not _integer(n):return false
  if not is_walkable(_p(previous)):return false
  if int(previous[0])%16!=0 or int(previous[1])%16!=0:return false
  start=previous.duplicate()
 state={"position":start,"map_id":map_id,"control_actor_id":config.control_actor_id,"stage":0,"tick":0,"complete":false,"actor_positions":{},"actor_postures":{},"visible_actor_ids":config.visible_actor_ids.duplicate(),"visited":[],"local_objects":{},"stage_receipts":[],"actor_paths":{},"carrying_actor_id":X if config.get("carrying",false) else "","rest_count":0,"push_count":0,"boulder_position":[272,224],"disarmed":[],"doctor_observed":false,"dog_recognized":false,"civilian_safe":false}
 for actor in layout.actors:
  state.actor_positions[actor.id]=actor.position.duplicate();state.actor_paths[actor.id]=[actor.position.duplicate()]
 state.actor_positions[config.control_actor_id]=start.duplicate()
 if config.get("carrying",false):state.actor_positions[X]=start.duplicate()

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
 engine_event_log.append({"type":type,"tick":state.tick,"position":state.position.duplicate()});state.stage_receipts.append(type)
func _complete()->void:state.complete=true;_event(puzzle_id+"_complete")
func apply_input(action:Dictionary)->Dictionary:
 if puzzle_id.is_empty() or state.complete:return {"ok":false}
 action=_canonical(action)
 var type:Variant=action.get("type")
 var fields:Dictionary={"move":["type","dx","dy"],"interact":["type"],"inspect":["type"],"wait":["type"]}
 if not type is String or not fields.has(type) or action.size()!=fields[type].size():return {"ok":false}
 for k in fields[type]:
  if not action.has(k):return {"ok":false}
 if type=="move" and (not _integer(action.dx) or not _integer(action.dy) or absf(action.dx)+absf(action.dy)!=1):return {"ok":false}
 if type=="inspect":return {"ok":true,"no_op":true,"view":get_view(),"receipt":receipt()}
 if input_log.size()>=LIMIT:return {"ok":false}
 if not _operate(action):return {"ok":false,"view":get_view(),"message":"沿安全路径走到标记处，照应同行者。"}
 state.tick+=1;state.actor_positions[state.control_actor_id]=state.position.duplicate()
 if not state.carrying_actor_id.is_empty():_follow_to(state.carrying_actor_id,_p(state.position),true)
 input_log.append(action.duplicate(true))
 return {"ok":true,"view":get_view(),"message":message,"receipt":receipt()}
func _operate(a:Dictionary)->bool:
 if a.type=="move":
  var next:=_p(state.position)+Vector2(a.dx,a.dy)*16
  if not is_walkable(next):return false
  state.position=_a(next);_companions_step();return true
 if a.type=="wait":
  if not _needs_follow():return false
  _companions_step();return true
 if a.type!="interact" or not _near(_target()):return false
 var step:Dictionary=config.steps[state.stage]
 match puzzle_id:
  "world_ch11_town_truce":
   if state.stage<2:
    var id:="npc_ch11_raider_left" if state.stage==0 else "npc_ch11_raider_right"
    state.disarmed.append(id);state.actor_postures[id]="disarmed"
   elif _distance("npc_ch11_townsfolk","refuge")>16:return false
   else:state.civilian_safe=true
  "world_ch11_reunion_observe":
   if state.stage==0:state.doctor_observed=true;state.actor_postures[X]="treating_patient"
   elif _p(state.actor_positions[DOG]).distance_to(_p(state.position))>16:return false
   else:state.dog_recognized=true;state.actor_postures[DOG]="recognizing"
  "world_ch11_sunrise_ascent":
   if state.stage==0:state.carrying_actor_id=X
   elif state.stage in [1,2]:state.rest_count+=1;state.actor_postures[H]="resting"
   elif state.stage==3:
    state.carrying_actor_id="";state.actor_positions[X]=_a(_p(state.position)+Vector2(16,0));state.actor_postures[H]="watching_sunrise";state.actor_postures[X]="watching_sunrise"
  "world_ch11_cave_escape":
   if state.stage==2:state.carrying_actor_id="";state.actor_positions[X]=_a(_p(state.position)+Vector2(16,0))
  "world_ch11_plum_practice":state.actor_postures[X]=step.verb
  "world_ch11_river_boulder":
   if state.stage==0:state.actor_postures[H]="bracing"
   if state.stage==1:state.actor_postures.char_huasheng="bracing"
   if state.stage==2:
    if state.actor_postures.get("char_huasheng","")!="bracing":return false
    state.push_count+=1;state.boulder_position[0]+=16;state.position[0]+=16
    _follow_to("char_huasheng",_p(state.actor_positions.char_huasheng)+Vector2(16,0),true)
    _event("push_together_"+str(state.push_count));message="巨石在两人的合力下缓缓移动。"
    if state.push_count<3:return true
   if state.stage==4:
    if _distance("npc_ch11_riverfolk","refuge")>16:return false
    state.civilian_safe=true
 state.visited.append(step.anchor);_event(step.verb);state.stage+=1;message=step.feedback
 if state.stage==config.steps.size():_complete()
 return true
func _distance(id:String,anchor:String)->float:return _p(state.actor_positions[id]).distance_to(_p(_anchor(anchor)))
func _follow_to(id:String,target:Vector2,carried:bool=false)->void:
 var old:=_p(state.actor_positions[id]);var next:=target if carried else _path_next(old,target)
 if next!=old:state.actor_positions[id]=_a(next);state.actor_paths[id].append(_a(next))
func _needs_follow()->bool:
 if puzzle_id=="world_ch11_town_truce" and state.stage>=2:return _distance("npc_ch11_townsfolk","refuge")>16
 if puzzle_id=="world_ch11_reunion_observe" and state.stage>=1:return _p(state.actor_positions[DOG]).distance_to(_p(state.position))>16
 if puzzle_id=="world_ch11_river_boulder" and state.stage>=4:return _distance("npc_ch11_riverfolk","refuge")>16
 return false
func _companions_step()->void:
 if puzzle_id=="world_ch11_town_truce" and state.stage>=2:_follow_to("npc_ch11_townsfolk",_p(state.position))
 if puzzle_id=="world_ch11_reunion_observe" and state.stage>=1:_follow_to(DOG,_p(state.position))
 if puzzle_id=="world_ch11_river_boulder" and state.stage>=3:_follow_to("npc_ch11_riverfolk",_p(state.position))
func _target()->String:return config.steps[mini(state.stage,config.steps.size()-1)].anchor
func _world_state()->Dictionary:
 var d:Dictionary=state.duplicate(true);d.erase("position");d.player_position=state.position.duplicate();d.objective_id=puzzle_id;d.target_anchor=_target();d.target_position=_anchor(_target()).duplicate();d.phase=scene_id;return d
func get_view()->Dictionary:
 var labels:Dictionary={"disarm_left":"侧身拨开左侧兵刃","disarm_right":"截住右侧攻势","secure_civilians":"确认街坊已安全","observe_doctor":"驻足看晓霜诊脉","recognize_old_dog":"俯身让白痴儿辨认","carry_xiaoshuang":"背稳晓霜","rest_first":"背风处调匀气息","rest_second":"扶稳晓霜，稍歇再行","sunrise_arrival":"轻轻放下晓霜","read_cover":"察看树后遮蔽","avoid_pursuit":"确认追者方位","reach_cave":"到洞口放下晓霜","root_stance":"沉肩立足","turn_stance":"侧转引势","open_stance":"顺步开势","close_stance":"收步护中","brace_boulder":"托稳巨石一侧","signal_huasheng":"招呼花生合力","push_boulder":"与花生一起推","guide_civilians":"招呼百姓沿堤走","river_safe":"确认百姓安全"}
 var verb:String=config.steps[mini(state.stage,config.steps.size()-1)].verb
 var options:Array=[{"id":"interact","label":labels[verb],"action":{"type":"interact"}}]
 if _needs_follow():options.append({"id":"wait","label":"稍候，让同伴跟上","action":{"type":"wait"}})
 return {"puzzle_id":puzzle_id,"title":config.label,"body":message,"instruction":"方向键沿路行走，走近后按 E 照应。","state":state.duplicate(true),"complete":state.complete,"paused_step_mode":true,"world_state":_world_state(),"options":options}
func view()->Dictionary:return get_view()
func next_demo_action()->Dictionary:
 if state.complete:return {}
 var target:=_p(_anchor(_target()));var current:=_p(state.position)
 if current!=target:
  var next:=_path_next(current,target)
  if next==current:return {}
  var dir:Vector2=(next-current)/16;return {"type":"move","dx":int(dir.x),"dy":int(dir.y)}
 if _needs_follow():return {"type":"wait"}
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
