extends "res://tests/test_chapter_seven_combat_boundaries.gd"
const BattleUI=preload("res://scripts/ui/chapter_seven_battle_panel.gd")
func run():
 setup()
 var holder=Control.new();root.add_child(holder)
 var panel=BattleUI.new();holder.add_child(panel)
 for screen in [Vector2i(1280,720),Vector2i(640,360)]:
  print("Funiu UI size ",screen)
  root.size=screen;panel.custom_minimum_size.x=screen.x-100
  var ox=session("fire_ox")
  var delivered:Array=[]
  var forward=func(action:Dictionary):
   delivered.append(action.duplicate(true))
   check(ox.apply_input(action).accepted,"button emits legal current-revision input")
  panel.input_submitted.connect(forward)
  panel.render(ox.get_view(),runtime.skills,ox.can_resolve());await process_frame;await process_frame
  check(panel.slots.has("funiu_route_board"),"in-panel location/target board exists")
  check(panel.slots.hazard_coordinates.text.contains("(128,240)"),"exact first safe target visible")
  check(panel.get_combined_minimum_size().y<=screen.y-72,"hazard panel fits available height")
  check(panel.get_combined_minimum_size().x<=screen.x-100,"hazard panel fits available width")
  # Reach the left boundary. Every click remains one real 16px movement.
  for i in range(2):
   var before:Dictionary=ox.engine.snapshot()
   panel.slots.hazard_move_left.pressed.emit()
   check(ox.engine.state.objective.position[0]==160-(i+1)*16,"one click one left step")
   check(ox.engine.state.round==before.round and ox.engine.state.objective.covered.is_empty(),"move neither resolves nor completes hazard")
   panel.render(ox.get_view(),runtime.skills,ox.can_resolve());await process_frame
  check(panel.slots.hazard_move_left.disabled,"left boundary disables same fixed button")
  check(not panel.slots.hazard_move_right.disabled,"right stays right at left boundary")
  # Original GUI failure: first right leaves boundary; left becomes legal again.
  for i in range(2):
   panel.slots.hazard_move_right.pressed.emit()
   check(ox.engine.state.objective.position[0]==128+(i+1)*16,"right never changes identity when left reappears")
   panel.render(ox.get_view(),runtime.skills,ox.can_resolve());await process_frame
   check(not panel.slots.hazard_move_left.disabled,"left button reappears in same fixed slot")
  check(delivered.size()==4,"four clicks four moves, no auto-batch")
  # Use actual controls for a full no-error route (not synthetic success).
  for target in [128,352,448]:
   print("Funiu UI walking target ",target)
   for step in range(40):
    var x:int=ox.engine.state.objective.position[0]
    if x==target:break
    panel.slots["hazard_move_right" if x<target else "hazard_move_left"].pressed.emit()
    panel.render(ox.get_view(),runtime.skills,ox.can_resolve());await process_frame
   check(panel.slots.hazard_guidance.text.contains("已到避险位"),"arrival feedback before cover")
   var count:int=ox.engine.state.objective.covered.size()
   panel.slots.hazard_cover.pressed.emit()
   check(ox.engine.state.objective.covered.size()==count,"cover selection does not fake completion")
   panel.render(ox.get_view(),runtime.skills,ox.can_resolve());await process_frame
   check(not panel.slots.resolve.disabled,"explicit resolve enabled only after cover")
   var resolve=func():check(ox.resolve_round(),"explicit cover resolve")
   panel.resolve_requested.connect(resolve);panel.slots.resolve.pressed.emit();panel.resolve_requested.disconnect(resolve)
   panel.render(ox.get_view(),runtime.skills,ox.can_resolve());await process_frame
   check(ox.engine.state.objective.covered.size()==count+1,"real resolved cover advances exactly one")
  check(ox.engine.state.outcome=="victory","full route through new buttons")
  check(panel.slots.hazard_feedback.text=="掩护完成，继续剧情。","terminal feedback matches completed objective")
  check(panel.slots.resolve.disabled and not panel.slots["continue"].disabled,"terminal offers continue rather than executing cover again")
  check(not Session.replay_receipt(ox.receipt(),rules,runtime,ox.encounter,party()).is_empty(),"new panel command proof unchanged/replayable")
  panel.input_submitted.disconnect(forward)
 # Stable menu action identity also holds for B04 after options reorder/shrink.
 print("Funiu UI semantic selection checks")
 var s=session();phase_two(s)
 var original:Dictionary=s.get_view()
 panel.render(original,runtime.skills,false);await process_frame
 var options:OptionButton=panel.slots[H+"_actions"]
 var chosen:Dictionary={}
 for i in range(options.item_count):
  var action:Dictionary=options.get_item_metadata(i)
  if action.action_id=="calibrate" and action.value=="C" and action.mark=="right_winch":
   options.select(i);options.item_selected.emit(i);chosen=action;break
 check(not chosen.is_empty(),"selected exact support and mark")
 var changed:=original.duplicate(true)
 changed.objective.available_actions.reverse()
 changed.objective.available_actions=changed.objective.available_actions.filter(func(o):return o.input.action_id!="fire")
 panel.render(changed,runtime.skills,false);await process_frame
 options=panel.slots[H+"_actions"]
 check(options.get_item_metadata(options.selected)==chosen,"semantic action key survives reorder and removed options")
 # If choice is no longer offered, default selection is safe and submits nothing.
 changed.objective.available_actions=changed.objective.available_actions.filter(func(o):return o.input.get("value","")!="C")
 var received:Array=[];var capture=func(action:Dictionary):received.append(action)
 panel.input_submitted.connect(capture);panel.render(changed,runtime.skills,false);await process_frame
 check(received.is_empty(),"missing former action never auto-submits substitute")
 panel.input_submitted.disconnect(capture)
 holder.queue_free();await process_frame;await process_frame
 print("CH07 Funiu panel: ",checks," checks, ",failures," failures")
 quit(1 if failures else 0)
