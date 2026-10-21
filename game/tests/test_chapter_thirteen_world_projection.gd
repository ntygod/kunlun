extends SceneTree
const World=preload("res://scripts/world.gd")
const Model=preload("res://scripts/world_actions/chapter_thirteen_world_actions.gd")
const Presentation=preload("res://scripts/chapter_thirteen_world_presentation.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func _initialize()->void:call_deferred("run")
func run()->void:
 for action in ["move_left","move_right","move_up","move_down"]:
  if not InputMap.has_action(action):InputMap.add_action(action)
 var maps:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(Model.MAP_PATH)).maps
 for mid in maps:
  var map:Dictionary=maps[mid];var w=World.new();root.add_child(w)
  var actors:Array=[]
  for actor in map.actors:actors.append(actor.id)
  w.configure({"id":"projection","map_id":mid,"cast":[]},Vector2(64,256),{"present_actor_ids":actors,"dead_actor_ids":[],"items":{},"world_objects":{}})
  check(not w.layout.is_empty(),"actual map registered "+mid)
  var m=Model.new();m.layout=map
  var parity:=true
  for point in map.anchors.values():parity=parity and m.is_walkable(Vector2(point[0],point[1]))==w.player.is_walkable(Vector2(point[0],point[1]))
  for point in [Vector2(16,64),Vector2(464,320),Vector2(64,64),Vector2(240,256)]:parity=parity and m.is_walkable(point)==w.player.is_walkable(point)
  check(parity,"model and actual foot collision agree "+mid)
  for id in map.sessions:
   var c:Dictionary=map.sessions[id]
   var context:Dictionary={"chapter":13,"revision":1,"current_token":"projection:"+id,"objective_id":id,"map_id":mid,"scene_id":c.scene_id,"phase":c.scene_id,"control_actor_id":c.control_actor_id,"world_objects":{}}
   check(m.begin(id,"projection",context),"begin "+id)
   w.scene_data.id=c.scene_id;w.sync_controlled_view(m.get_view());await process_frame
   check(w.player.actor_id==c.control_actor_id and w.player.position==m._p(m.state.position),"live state binds correct controller and feet "+id)
   var feet:=Vector2(80,256);w.player.position=feet;w.player.actor_id="char_hua_xiaoshuang"
   Presentation.project(w,{"world_objects":{"ch13_spatial_state":m.get_view().world_state}})
   check(w.player.position==feet and w.player.actor_id=="char_hua_xiaoshuang","history never overwrites restored navigation/controller "+id)
   w.runtime_context.dead_actor_ids=["animal_kuaixue","npc_wu_changqing","char_axue"]
   w.runtime_context.departed_actor_ids=["char_liu_yingying"]
   w.sync_controlled_view(m.get_view())
   var hidden:=true
   for actor in w.runtime_context.dead_actor_ids+w.runtime_context.departed_actor_ids:
    if w.cast_actors.has(actor):hidden=hidden and not w.cast_actors[actor].visible
   check(hidden,"explicit visible list cannot revive dead/departed "+id)
   w.runtime_context.dead_actor_ids=[];w.runtime_context.departed_actor_ids=[]
  w.queue_redraw();await process_frame
  w.queue_free();await process_frame
 print("Chapter thirteen world projection: ",checks," checks, ",failures," failures");quit(1 if failures else 0)
