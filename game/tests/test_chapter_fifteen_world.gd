extends SceneTree
const Model=preload("res://scripts/world_actions/chapter_fifteen_world_actions.gd")
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
   return {"chapter":15,"revision":1,"current_token":"ch15-test:"+id,"objective_id":id,"map_id":mid,"control_actor_id":c.control_actor_id,"scene_id":c.scene_id,"phase":c.scene_id,"world_objects":{},"actors":{},"items":{},"choices":{},"inherited_choices":{},"knowledge":[]}
 return {}
func _initialize()->void:
 for id in Model.IDS:
  var c:=fixture(id);var model=Model.new();check(model.begin(id,"attempt",c),"begin "+id)
  var baseline:Dictionary=model.snapshot()
  var rejected:=true
  for action in [{"type":"move","dx":true,"dy":0},{"type":"move","dx":2,"dy":0},{"type":"complete"},{"type":"interact","success":true},{"type":"wait","skip":true}]:rejected=rejected and not model.apply_input(action).ok and Model._encoded(baseline)==Model._encoded(model.snapshot())
  check(rejected,"malformed actions cannot mutate "+id)
  if model.config.get("constrained",false):
   check(not model.apply_input({"type":"move","dx":1,"dy":0}).ok,"captive cannot walk off trial platform")
  else:check(not model.apply_input({"type":"interact"}).ok,"cannot interact remotely "+id)
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
   "world_ch15_tongzhou_restrain":check(model.state.local_objects.nonlethal_hold and model.state.local_objects.hold_released,"restrain then release without false injury rewards")
   "world_ch15_joint_burial":check(model.state.local_objects.jing_inscribed and model.state.local_objects.parents_rest_together and model.state.carried_object.is_empty(),"coffin laid and Jing inscribed")
   "world_ch15_trial_witness":check(model.state.position==model.layout.anchors.prison and model.state.local_objects.ming_intercedes,"captive observes without navigation bypass")
   "world_ch15_baizhang_rescue":check(model.state.local_objects.enemy_saved and model.state.local_objects.safe_departure,"leave foes alive after rescue")
   "world_ch15_cliff_escape":check(model.state.local_objects.monkey_alive and Model.DOG not in model.state.visible_actor_ids and Model.H not in model.state.visible_actor_ids,"dog absent, monkey survives, Liang never sees cliff")
   "world_ch15_tomb_triage":check(model.state.local_objects.child_sheltered and Model.H not in model.state.visible_actor_ids,"independent eastern controller")
   "world_ch15_mud_training":check(model.state.local_objects.lesson_applied and model.state.carried_object.is_empty(),"mud lesson requires observation and release")
   "world_ch15_mercy_guard":check(model.state.local_objects.father_and_son_spared and "npc_hetuoluo" not in model.state.visible_actor_ids and Model.R not in model.state.visible_actor_ids,"He and Harris leave alive")
   "world_ch15_postbattle_care":check(model.state.local_objects.followup_arranged and model.state.carried_object.is_empty(),"all care delivered without numeric healing")
   "world_ch15_eastline_departure":check(model.state.local_objects.independent_eastline and not model._needs_follow() and model.state.actor_paths[Model.C].size()>1 and model.state.actor_paths[Model.S].size()>1,"child and bearer physically follow to exit")
   "world_ch15_r06_clinic_repair":check(model.state.local_objects.well_cleaned and model.state.local_objects.door_repaired and model.state.local_objects.floor_dry and model.state.local_objects.lantern_hung,"clinic repair contains each spatial handoff")
  var hidden_context:Dictionary=c.duplicate(true)
  hidden_context.dead_actor_ids=model.config.visible_actor_ids.duplicate()
  hidden_context.departed_actor_ids=[]
  var hidden=Model.new();check(hidden.begin(id,"hidden",hidden_context) and hidden.state.visible_actor_ids.is_empty(),"dead projection wins explicit authored cast")
 var care_context:Dictionary=fixture("world_ch15_postbattle_care")
 care_context.choices.care_order="ch15_care_equal"
 var care=Model.new();check(care.begin("world_ch15_postbattle_care","care",care_context),"alternate care begins")
 check(care.config.steps[1].verb=="care_elder","care choice controls actual visit order")
 for i in range(300):
  if care.state.complete:break
  if not care.apply_input(care.next_demo_action()).ok:check(false,"alternate care route");break
 check(care.state.complete and care.state.actor_postures.npc_xiao_qianjue=="resting" and care.state.actor_postures.npc_ch15_wubao=="resting","both patients cared for with reordered steps")
 check(not Model.replay_receipt(care.receipt(),care_context).is_empty(),"alternate care exact replay")
 print("Chapter fifteen world: ",checks," checks, ",failures," failures");quit(1 if failures else 0)
