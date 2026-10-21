extends SceneTree
const Model=preload("res://scripts/world_actions/chapter_fourteen_world_actions.gd")
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
   return {"chapter":14,"revision":1,"current_token":"ch14-test:"+id,"objective_id":id,"map_id":mid,"control_actor_id":c.control_actor_id,"scene_id":c.scene_id,"phase":c.scene_id,"world_objects":{},"actors":{},"items":{},"choices":{},"inherited_choices":{},"knowledge":[]}
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
   "world_ch14_alley_clinic":check(model.state.local_objects.arrange_followup and model.state.carried_object.is_empty(),"fictional care ends in followup")
   "world_ch14_festival_cover":check(model.state.local_objects.disarm_guard and model.state.actor_postures[Model.C]=="sheltered","child protected before retreat")
   "world_ch14_nunnery_rescue":check(model.state.local_objects.abduction_discovered and Model.X not in model.state.visible_actor_ids and Model.C not in model.state.visible_actor_ids and model.state.carrying_actor_id.is_empty(),"soldier rescued and abducted actors leave")
   "world_ch14_stone_lion":check(model.state.local_objects.gate_open and model.state.local_objects.lion_lowered and model.state.carried_object.is_empty(),"safe route cleared, lion physically carried and lowered")
   "world_ch14_wheel_capture":check(model.state.local_objects.captured and Model.S not in model.state.visible_actor_ids and Model.C not in model.state.visible_actor_ids,"child sent away before capture")
   "world_ch14_zizhu_duel":check(model.state.local_objects.palms_committed and not model.state.local_objects.has("reward"),"scripted conflict has no fabricated battle prize")
   "world_ch14_break_blade":check(model.state.local_objects.blade_secured and "npc_xiao_qianjue" not in model.state.visible_actor_ids,"rescue secures blade then rebukes departing elder")
   "world_ch14_dawn_vigil":check(model.state.local_objects.hands_held and model.state.local_objects.responded,"safe companionship permits response")
 print("Chapter fourteen world: ",checks," checks, ",failures," failures");quit(1 if failures else 0)
