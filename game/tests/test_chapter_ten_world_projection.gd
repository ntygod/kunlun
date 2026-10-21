extends SceneTree
const World=preload("res://scripts/world.gd")
const Model=preload("res://scripts/world_actions/chapter_ten_world_actions.gd")
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
  var w=World.new();root.add_child(w)
  w.configure({"id":"projection","map_id":mid,"cast":["梁萧","阿雪"]},Vector2(INF,INF),{"items":{},"world_objects":{}})
  check(not w.layout.is_empty(),"registered "+mid)
  var model=Model.new();model.layout=maps[mid]
  for y in range(64,289,16):
   for x in range(32,449,16):check(model.is_walkable(Vector2(x,y))==w.player.is_walkable(Vector2(x,y)),"physical collision "+mid+str(Vector2(x,y)))
  for id in maps[mid].sessions:
   var c:Dictionary=maps[mid].sessions[id]
   var context:Dictionary={"chapter":10,"revision":1,"current_token":"projection:"+id,"objective_id":id,"map_id":mid,"scene_id":c.scene_id,"phase":c.scene_id,"control_actor_id":c.control_actor_id,"world_objects":{}}
   check(model.begin(id,"projection",context),"begin "+id)
   w.sync_controlled_view(model.get_view())
   check(w.player.actor_id==c.control_actor_id,"actual controlled actor")
   check(w.player.position==model._p(model.state.position),"actual projected feet")
   await process_frame
  w.queue_free();await process_frame
 print("Chapter ten projection: ",checks," checks, ",failures," failures");quit(1 if failures else 0)
