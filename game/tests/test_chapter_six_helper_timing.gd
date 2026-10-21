extends SceneTree
const C=preload("res://scripts/world_actions/chapter_six_world_actions.gd")
const D=preload("res://tests/chapter_six_world_driver.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String) -> void:
 checks+=1
 if not ok:failures+=1;printerr("FAIL "+label)
func p(v:Array) -> Vector2:return Vector2(v[0],v[1])
func _initialize() -> void:
 for id in ["home_roof_repaired","home_bucket_made"]:
  var c=C.new();check(c.begin(id,"timing",{}),id+" begin")
  var initial:Vector2=p(c.state.actor_positions.char_axue)
  while c.state.stage==0:
   var before:Vector2=p(c.state.actor_positions.char_axue)
   var action:Dictionary=D.next_input(c.get_view())
   check(c.apply_input(action).ok,"legal material approach")
   if action.type=="move":check(p(c.state.actor_positions.char_axue)==before,"not dispatched before material")
  check(c.state.helper_active,"material dispatches helper")
  check(p(c.state.actor_positions.char_axue).distance_to(initial)==16,"first move exactly one cell")
  var stationary:Vector2=p(c.state.actor_positions.char_axue)
  var snap:Dictionary=c.snapshot()
  check(not c.apply_input({"type":"move","dx":2,"dy":0}).ok,"invalid step rejected")
  check(C._encoded(c.snapshot())==C._encoded(snap),"invalid step atomic")
  check(not c.apply_input({"type":"interact"}).ok,"premature wrong-position E rejected")
  check(p(c.state.actor_positions.char_axue)==stationary,"failed E does not move helper")
  var waits:=0
  for i in range(100):
   if c.state.complete:break
   var before:Vector2=p(c.state.actor_positions.char_axue)
   var action:Dictionary=D.next_input(c.get_view())
   if action.type=="wait":waits+=1
   check(c.apply_input(action).ok,"valid remaining actual input")
   var after:Vector2=p(c.state.actor_positions.char_axue)
   check(before.distance_to(after)<=16,"never skips cells")
   check(c.is_walkable(after),"helper respects collision")
   var restored=C.new()
   check(restored.restore(JSON.parse_string(JSON.stringify(c.snapshot())),{}),"each helper step JSON restores")
   check(C._encoded(restored.snapshot())==C._encoded(c.snapshot()),"exact replayed helper position")
  check(c.state.complete,"actual operation completed")
  check(waits==3,"parallel work leaves exactly three waits")
  check(p(c.state.actor_positions.char_axue)==p(c.layout.anchors.axue_chore),"final helper actually at chore")
  check(not C.replay_receipt(c.receipt(),{}).is_empty(),"final receipt replays")
 print("CH06 HELPER TIMING: %d checks / %d failures"%[checks,failures]);quit(1 if failures else 0)
