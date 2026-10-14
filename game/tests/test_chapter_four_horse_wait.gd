extends "res://tests/test_chapter_four.gd"
func run() -> void:
 base=JSON.parse_string(FileAccess.get_file_as_string("res://data/prologue.json"))
 var c:=Campaign.new(base)
 var fixture:="res://../output/cache/chapter_three_gui/manual_natural_final.json"
 if FileAccess.file_exists(fixture):check(c.restore_persisted(JSON.parse_string(FileAccess.get_file_as_string(fixture)))=="","actual prior fixture")
 else:
  c=chapter_two_ending(true);c.enter_chapter_three()
  while not c.state.finished:act_three(c,16)
 c.enter_registered_chapter(4)
 while c.current_token()!="ch04_window_escape:02":
  if not intro(c):check(false,"reach real horse call");quit(1);return
 var app=load("res://scenes/main.tscn").instantiate();root.add_child(app);await process_frame
 app.story=c;app.saves=SaveStore.new("user://horse_wait_test");app._load_chapter_scene()
 var rt:=c.current_chapter_runtime();var session:=rt.make_puzzle()
 var token:String=c.current_token();var rewards:Dictionary=c.reward_ledger.duplicate(true)
 check(Proof.equivalent(session.get_view().world_state.horse_position,[48,240]),"horse inherits real window starting position")
 app._toggle_horse_wait();check(not app.horse_waiting,"cannot wait automatically before calling horse")
 app._world_puzzle_input({"type":"interact"})
 check(session.state.horse_called and session.state.horse_position==[64,240],"call advances first real phase")
 app._toggle_horse_wait();check(app.horse_waiting,"explicit wait starts")
 app.horse_wait_button.grab_focus()
 var accept:=InputEventKey.new();accept.keycode=KEY_ENTER;accept.physical_keycode=KEY_ENTER;accept.pressed=true
 Input.parse_input_event(accept);await process_frame
 accept.pressed=false;Input.parse_input_event(accept);await process_frame
 check(not app.horse_waiting,"focused Enter cancels without restarting")
 app._toggle_horse_wait()
 var count:int=session.input_log.size()
 app._tick_horse_wait(0.19);check(session.input_log.size()==count,"short interval does not advance")
 app._tick_horse_wait(0.01);check(session.input_log.size()==count+1,"interval appends one wait")
 app._tick_horse_wait(10.0);check(session.input_log.size()==count+2,"no hidden catch-up batch")
 app._toggle_horse_wait();count=session.input_log.size();app._tick_horse_wait(10.0)
 check(not app.horse_waiting and session.input_log.size()==count,"explicit cancel stops")
 app._save()
 var snapshot:Dictionary=session.snapshot()
 app._toggle_horse_wait();app._show_menu()
 check(not app.horse_waiting,"menu stops waiting before save")
 app._tick_horse_wait(10.0);app._cancel_choice()
 check(Proof.equivalent(snapshot,c.current_chapter_runtime().make_puzzle().snapshot()),"menu cannot advance background phases")
 app._toggle_horse_wait();app._tick_horse_wait(0.2);app._load("manual")
 check(not app.horse_waiting,"read stops waiting")
 check(Proof.equivalent(snapshot,c.current_chapter_runtime().make_puzzle().snapshot()),"manual restores exact wait input prefix")
 app._toggle_horse_wait();app._advance_chapter();check(not app.horse_waiting,"reactivation stops ephemeral timer")
 app._toggle_horse_wait();app._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
 check(not app.horse_waiting,"focus loss stops unseen waiting")
 app._toggle_horse_wait()
 for i in range(20):
  if not app.horse_waiting:break
  app._tick_horse_wait(0.2)
 session=c.current_chapter_runtime().make_puzzle()
 check(not app.horse_waiting and session.state.horse_arrived,"arrival automatically stops wait")
 check(session.state.horse_position==[144,240],"six actual phases reach landing")
 check(not session.state.complete and session.receipt().is_empty() and c.current_token()==token,"wait never auto jumps or mounts")
 for i in range(1,session.input_log.size()):check(session.input_log[i].type=="wait","auto log contains only legal wait inputs")
 check(session.input_log.size()==6,"one call and five waits, no skipped phases")
 check(Proof.equivalent(rewards,c.reward_ledger),"waiting cannot grant rewards")
 app._world_puzzle_input({"type":"interact"})
 check(c.current_token()!=token,"player explicitly mounts after arrival")
 check(Proof.equivalent(c.state.position,[144,240]),"final boarding position saved exactly")
 app.queue_free();await process_frame;await process_frame
 print("Chapter four horse wait: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
