extends SceneTree
const Model=preload("res://scripts/world_actions/chapter_twelve_world_actions.gd")
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
   return {"chapter":12,"revision":1,"current_token":"ch12-test:"+id,"objective_id":id,"map_id":mid,"control_actor_id":c.control_actor_id,"scene_id":c.scene_id,"phase":c.scene_id,"world_objects":{},"actors":{},"items":{},"choices":{},"inherited_choices":{},"knowledge":[]}
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
   "world_ch12_bamboo_disarm":check(model.state.restraint_heeded and model.state.weapons_released and model.state.tethered_weapons.is_empty(),"restrained nonhumiliation release")
   "world_ch12_freed_escort":check(model.state.actor_paths[Model.L].size()>1,"same Liu actual walking")
   "world_ch12_herb_gather":check(model.state.prescription and model.state.herbs.size()==3 and model.state.local_objects.get("herbs_delivered",false),"doctor prescribed gathered delivered")
   "world_ch12_healer_safety":
    check(model.state.care_order==["seal_poison_bag","bandage_liuying","guide_liang"],"exact medical safety order")
    for patient in [Model.H,Model.L,Model.LU]:check(model.state.actor_paths[patient].size()==1,"incapacitated patient not moving")
   "world_ch12_three_oath":check(model.state.oaths==[Model.LU,Model.L,Model.H] and model.state.local_objects.get("no_harm_oath",false),"three commitments")
   "world_ch12_medical_departure":check(model.state.books_packed and model.state.actor_paths[Model.L].size()>1 and model.state.actor_paths[Model.H].size()>1,"books and real travelling")
   "world_ch12_r05_road_repair":check(model.state.road_stones==["stone_1","stone_2","stone_3"] and model.state.carried_object.is_empty(),"three physical stone deliveries");check(model.state.actor_paths[Model.H].size()>1 and model.state.actor_postures.npc_ch12_carter=="bandaged","Liang helped Xiaoshuang treated")

 print("Chapter twelve world: ",checks," checks, ",failures," failures");quit(1 if failures else 0)
