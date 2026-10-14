extends "res://tests/test_chapter_nine_encounter.gd"
const UI=preload("res://scripts/ui/chapter_nine_encounter_panel.gd")
var holder: Control
var panel: Control
var live: RefCounted
func draw_panel():
 if panel!=null:holder.remove_child(panel);panel.queue_free()
 panel=UI.new();holder.add_child(panel);panel.position=Vector2(24,16);panel.size=holder.size-Vector2(48,32)
 panel.render(live.get_view(),{},live.can_resolve())
 panel.input_submitted.connect(func(action):
  check(live.apply_input(action).accepted,"one click formal input accepted");draw_panel())
 panel.resolve_requested.connect(func():check(live.resolve_round(),"explicit queued resolve");draw_panel())
func run():
 setup();holder=Control.new();root.add_child(holder)
 var theme=Theme.new();theme.default_font=load("res://assets/fonts/kunlun_ui.ttf");holder.theme=theme
 for dimensions in [Vector2i(1280,720),Vector2i(640,360)]:
  root.size=dimensions;holder.size=Vector2(mini(850,dimensions.x-40),mini(510,dimensions.y-40))
  live=session();draw_panel()
  for action in ["observe","disarm","observe","disarm"]:
   for frame in range(3):await process_frame
   for id in ["heading","resources","intent","well_soldier_1","well_soldier_2","observe","disarm","wait","retry","continue","leave"]:
    var control:Control=panel.slots[id]
    check(Rect2(Vector2.ZERO,holder.size).grow(1).encloses(control.get_global_rect()),"headless bounds %s/%s" % [dimensions,id])
   panel.slots[action].pressed.emit()
  check(live.get_view().outcome=="victory" and live.get_view().round==5,"exact four UI clicks")
  check(live.final_party()[0].mp==0 and live.final_party()[0].hp==1200,"UI zero MP no damage")
  check(panel.slots.well_soldier_1.text.contains("已退场") and panel.slots.well_soldier_2.text.contains("已退场"),"retirement text visible")
 live=session();live.apply_input({"actor_id":H,"action_id":"observe","value":"well_soldier_1"});draw_panel()
 for frame in range(3):await process_frame
 for id in panel.slots:
  var control:Control=panel.slots[id]
  check(Rect2(Vector2.ZERO,holder.size).grow(1).encloses(control.get_global_rect()),"partial preparation 640 bounds "+str(id))
 var s=session();s.apply_input({"actor_id":H,"action_id":"observe","value":"well_soldier_1"})
 var before=s.snapshot()
 check(not s.apply_input({"actor_id":H,"action_id":"wait","value":"well_soldier_1","revision":0,"execute":true}).accepted and Compare.equivalent(before,s.snapshot()),"stale one-click cannot execute pending")
 for bad in [0,1,1.0,"true",null,[],{}]:
  check(not s.apply_input({"actor_id":H,"action_id":"wait","value":"well_soldier_1","execute":bad}).accepted and Compare.equivalent(before,s.snapshot()),"execute boolean strict atomic")
 var probe=UI.new();holder.add_child(probe)
 var signals={"input":0,"retry":0,"leave":0,"continue":0,"resolve":0}
 probe.input_submitted.connect(func(_action):signals.input+=1)
 probe.retry_requested.connect(func():signals.retry+=1)
 probe.leave_requested.connect(func():signals.leave+=1)
 probe.continue_requested.connect(func():signals["continue"]+=1)
 probe.resolve_requested.connect(func():signals.resolve+=1)
 probe.render(s.get_view(),{},s.can_resolve())
 var obsolete:Array=[]
 for id in ["observe","disarm","wait","resolve","retry","continue","leave"]:obsolete.append(probe.slots[id])
 probe.render(s.get_view(),{},s.can_resolve())
 for button in obsolete:button.pressed.emit()
 check(signals.values()==[0,0,0,0,0],"all old-render callbacks reject")
 # Reattach an old button before deferred deletion: epoch must reject even
 # when both the panel and button are again visible in the active tree.
 var old_button:Button=obsolete[0]
 old_button.get_parent().remove_child(old_button);probe.add_child(old_button)
 old_button.pressed.emit()
 check(signals.input==0,"visible reattached obsolete button rejects by render epoch")
 old_button.queue_free()
 probe.hide();probe.slots.observe.pressed.emit()
 check(signals.input==0,"hidden panel rejects current callback")
 probe.show();holder.remove_child(probe);probe.slots.observe.pressed.emit()
 check(signals.input==0,"detached panel rejects current callback")
 holder.add_child(probe);probe.slots["continue"].pressed.emit()
 check(signals["continue"]==0,"disabled current callback rejects")
 probe.slots.observe.pressed.emit()
 check(signals.input==1,"current visible enabled callback remains functional")
 probe.queue_free()
 holder.queue_free();await process_frame
 print("Chapter nine panel headless: %d checks, %d failures" % [checks,failures]);quit(1 if failures else 0)
