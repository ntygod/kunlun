extends SceneTree
const Model=preload("res://scripts/world_actions/chapter_thirteen_world_actions.gd")
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
   return {"chapter":13,"revision":1,"current_token":"ch13-test:"+id,"objective_id":id,"map_id":mid,"control_actor_id":c.control_actor_id,"scene_id":c.scene_id,"phase":c.scene_id,"world_objects":{},"actors":{},"items":{},"choices":{},"inherited_choices":{},"knowledge":[]}
 return {}
func _initialize()->void:
 for id in Model.IDS:
  var c:=fixture(id);var model=Model.new();check(model.begin(id,"attempt",c),"begin "+id)
  var baseline:Dictionary=model.snapshot()
  var rejected:=true
  for action in [{"type":"move","dx":true,"dy":0},{"type":"move","dx":2,"dy":0},{"type":"complete"},{"type":"interact","success":true},{"type":"wait","skip":true}]:rejected=rejected and not model.apply_input(action).ok and Model._encoded(baseline)==Model._encoded(model.snapshot())
  check(rejected,"malformed actions cannot mutate "+id)
  check(not model.apply_input({"type":"interact"}).ok,"cannot interact remotely "+id)
  var valid:=true;var partial_checked:=false
  for i in range(1000):
   if model.state.complete:break
   var action:Dictionary=model.next_demo_action()
   if action.is_empty() or not model.apply_input(action).ok or not model.is_walkable(model._p(model.state.position)):valid=false;break
   if model.state.stage>=1 and not partial_checked:
    var saved:Dictionary=JSON.parse_string(JSON.stringify(model.snapshot()));var restored=Model.new()
    check(restored.restore(saved,c),"partial JSON replay "+id)
    var forged:Dictionary=saved.duplicate(true);forged.state.position=[999,999]
    check(not restored.restore(forged,c),"forged navigation rejected "+id)
    partial_checked=true
  check(valid and model.state.complete,"complete real route with collisions "+id)
  check(not Model.replay_receipt(JSON.parse_string(JSON.stringify(model.receipt())),c).is_empty(),"receipt exact replay "+id)
  check(not model.apply_input({"type":"interact"}).ok,"no duplicate completion "+id)
  check("char_axue" not in model.state.visible_actor_ids and "npc_wu_changqing" not in model.state.visible_actor_ids,"deceased prior actors not revived "+id)
  match id:
   "world_ch13_yashan_rescue":check(model.state.child_safe and model.state.local_objects.fire_rope_cut,"child secured after fire rope cut")
   "world_ch13_storm_rigging":check(model.state.secured_ropes.size()==2 and model.state.local_objects.stern_door_barred and Model.H not in model.state.visible_actor_ids,"both riggings and rear cabin secured without Liang")
   "world_ch13_huasheng_brace":check(model.state.placed_beams==["plank_1","plank_2"] and model.state.local_objects.hull_braced and model.state.carried_object.is_empty(),"two beams physically carried and braced")
   "world_ch13_cabin_treatment":check(model.state.local_objects.child_protected and model.state.local_objects.harris_treated and model.state.local_objects.water_exchanged,"protection then fictional treatment exchanges water")
   "world_ch13_whale_harpoon":check(model.state.harpoon_removed and model.state.local_objects.safety_line,"secured before removing harpoon")
   "world_ch13_sinking_rescue":
    var all_aboard:bool=model.state.child_safe and model.state.local_objects.survivors_aboard and Model.K not in model.state.visible_actor_ids
    for who in [Model.X,Model.L,Model.S,Model.DOG,Model.M,Model.E]:all_aboard=all_aboard and model.state.actor_paths[who].size()>1 and model._p(model.state.actor_positions[who]).distance_to(model._p(model.layout.anchors.boat))<=32
    check(all_aboard,"child carried and survivors including pets physically board; donkey not revived")
   "world_ch13_ship_materials":check(model.state.local_objects.rotten_wood==3 and model.state.local_objects.iron_wood==7 and model.state.material_deliveries.size()==3,"exact segregated materials delivered")
   "world_ch13_chaoyun_farewell":check(model.state.local_objects.voluntary_departure and model.state.local_objects.letter_left and model.state.actor_paths[Model.E].size()>1,"Liu walks voluntarily with horse after letter")
 print("Chapter thirteen world: ",checks," checks, ",failures," failures");quit(1 if failures else 0)
