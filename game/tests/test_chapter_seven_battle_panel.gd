extends "res://tests/test_chapter_seven_combat_boundaries.gd"
const BattleUI=preload("res://scripts/ui/chapter_seven_battle_panel.gd")
func run():
 setup()
 var holder=Control.new();root.add_child(holder)
 var panel=BattleUI.new();holder.add_child(panel)
 var s=session();var d=Driver.new(check)
 for size in [Vector2i(1280,720),Vector2i(640,360)]:
  root.size=size
  panel.render(s.get_view(),runtime.skills,s.can_resolve())
  await process_frame
  check(panel.slots.has(H+"_skills") and not panel.slots.has(A+"_skills"),"captured snow no command slot")
  check(panel.slots.public_intents is ScrollContainer,"public tells scrollable")
  panel.show_details();await process_frame
  check(panel.details.visible,"rules/log popup")
  panel.details.hide()
 phase_two(s)
 for size in [Vector2i(1280,720),Vector2i(640,360)]:
  root.size=size;panel.render(s.get_view(),runtime.skills,s.can_resolve());await process_frame
  check(panel.slots.has(A+"_skills"),"rescued snow slot")
  var received:Array=[]
  var capture=func(action:Dictionary):received.append(action)
  panel.input_submitted.connect(capture)
  var opts:OptionButton=panel.slots[H+"_actions"]
  for i in range(opts.item_count):
   var action:Dictionary=opts.get_item_metadata(i)
   if action.action_id=="calibrate" and action.value=="A" and action.mark=="left_beam":opts.select(i);opts.item_selected.emit(i);break
  panel.slots[H+"_input"].pressed.emit()
  check(received.size()==1 and received[0].revision==s.engine.state.revision,"real scene button carries current revision")
  panel.input_submitted.disconnect(capture)
 var ox=session("fire_ox");panel.render(ox.get_view(),runtime.skills,false);await process_frame
 check(panel.slots[H+"_command"].disabled,"hazard no combat shortcut")
 holder.queue_free();await process_frame;await process_frame
 print("CH07 battle panel: ",checks," checks, ",failures," failures")
 quit(1 if failures else 0)
