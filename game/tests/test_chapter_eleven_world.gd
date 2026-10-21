extends SceneTree
const Model=preload("res://scripts/world_actions/chapter_eleven_world_actions.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func fixture(id:String)->Dictionary:
 var maps:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(Model.MAP_PATH)).maps
 for mid in maps:
  if maps[mid].sessions.has(id):
   var c:Dictionary=maps[mid].sessions[id]
   return {"chapter":11,"revision":1,"current_token":"ch11-test:"+id,"objective_id":id,"map_id":mid,"control_actor_id":c.control_actor_id,"scene_id":c.scene_id,"phase":c.scene_id,"world_objects":{},"actors":{},"items":{},"choices":{},"inherited_choices":{},"knowledge":[]}
 return {}
func _initialize()->void:
 for id in Model.IDS:
  var c:=fixture(id);var model=Model.new();check(model.begin(id,"attempt",c),"begin "+id)
  var old:Dictionary=model.snapshot()
  for action in [{"type":"move","dx":true,"dy":0},{"type":"move","dx":2,"dy":0},{"type":"complete"},{"type":"interact","success":true},{"type":"wait","skip":true}]:
   check(not model.apply_input(action).ok,"bad command");check(Model._encoded(old)==Model._encoded(model.snapshot()),"bad input atomic")
  var wrong:Dictionary=c.duplicate(true);wrong.control_actor_id="char_axue"
  check(not model.begin(id,"bad",wrong),"dead actor denied");check(Model._encoded(old)==Model._encoded(model.snapshot()),"begin atomic")
  check(not model.apply_input({"type":"interact"}).ok,"no remote completion")
  for i in range(500):
   if model.state.complete:break
   var action:Dictionary=model.next_demo_action();check(not action.is_empty(),"route exists "+id)
   if action.is_empty():break
   check(model.apply_input(action).ok,"legal path "+id+str(action))
   check(model.is_walkable(model._p(model.state.position)),"safe feet")
   if i%11==0:
    var saved:Dictionary=JSON.parse_string(JSON.stringify(model.snapshot()));var restored=Model.new()
    check(restored.restore(saved,c),"JSON partial replay")
    var bad:Dictionary=saved.duplicate(true);bad.state.position=[999,999]
    check(not restored.restore(bad,c),"cannot warp saved feet")
  check(model.state.complete,"complete "+id)
  check(not Model.replay_receipt(JSON.parse_string(JSON.stringify(model.receipt())),c).is_empty(),"receipt replays")
  check(not model.apply_input({"type":"interact"}).ok,"duplicate denied")
  check("char_axue" not in model.state.visible_actor_ids,"no deceased actor")
  match id:
   "world_ch11_town_truce":check(model.state.disarmed.size()==2 and model.state.civilian_safe,"nonlethal protection");check(model.state.actor_paths.npc_ch11_townsfolk.size()>1,"civilians walked")
   "world_ch11_reunion_observe":check(model.state.doctor_observed and model.state.dog_recognized,"doctor before dog");check(model.state.actor_paths[Model.DOG].size()>1,"old dog ran actual path")
   "world_ch11_sunrise_ascent":check(model.state.rest_count==2 and model.state.carrying_actor_id.is_empty(),"rest and release");check(model.state.actor_paths[Model.X].size()>1,"actual carrying path")
   "world_ch11_cave_escape":check(model.state.actor_paths[Model.X].size()>1 and model.state.carrying_actor_id.is_empty(),"carried to cave")
   "world_ch11_plum_practice":check(model.state.control_actor_id==Model.X and model.state.visited.size()==4,"X learns actual footwork")
   "world_ch11_river_boulder":check(model.state.push_count==3 and model.state.civilian_safe,"two actors three pushes protect villagers");check(model.state.actor_paths.npc_ch11_riverfolk.size()>1,"villagers move")
 print("Chapter eleven world: ",checks," checks, ",failures," failures");quit(1 if failures else 0)
