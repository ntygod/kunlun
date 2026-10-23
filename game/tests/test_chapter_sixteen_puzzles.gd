extends SceneTree
const Puzzle=preload("res://scripts/puzzles/chapter_sixteen_puzzle_resolver.gd")
const Driver=preload("res://tests/chapter_sixteen_driver.gd")
const Same=preload("res://scripts/campaign/encounter_session.gd")
var checks=0
var failures=0
func _initialize()->void:call_deferred("run")
func check(ok:bool,note:String)->void:
 checks+=1
 if not ok:failures+=1;push_error(note)
func context()->Dictionary:return {"chapter":16,"current_token":"fixture:00","control_actor_id":"char_liang_xiao","ranya_present":true,"vault_open":true}
func run()->void:
 for id in Puzzle.IDS:
  var p:=Puzzle.new();check(p.begin(id,"fixture:00",context()),"valid entry "+id)
  for bad in [null,{},true,{"type":"success","complete":true},{"type":"hint","revision":0},{"type":"hint","revision":true},{"type":"hint","extra":1}]:
   var before:=p.snapshot();check(not p.apply_input(bad).ok,"malformed input refused");check(Same.equivalent(before,p.snapshot()),"rejected input atomic")
  for n in range(3):check(p.apply_input({"type":"hint"}).ok,"three graduated hints")
  check(not p.apply_input({"type":"hint"}).ok,"hints capped")
  check(p.apply_input({"type":"reset"}).ok and p.state.hint_level==3,"reset retains hint evidence")
  var original:=p.snapshot()
  for n in range(70):
   if p.state.complete:break
   check(p.apply_input(Driver.puzzle_action(p)).ok,"real next operation")
   var clone:=Puzzle.new();check(clone.restore(JSON.parse_string(JSON.stringify(p.snapshot())),context()),"every partial snapshot replays")
   check(Same.equivalent(clone.snapshot(),p.snapshot()),"exact JSON roundtrip")
  check(p.state.complete and p.get_receipts()==[id+":completed"],"receipt needs actual completion")
  var terminal:=p.snapshot();check(not p.apply_input({"type":"reset"}).ok,"completed proof immutable")
  check(Same.equivalent(terminal,p.snapshot()),"post-completion no change")
  var forged:Dictionary=original.duplicate(true);forged.state.complete=true
  var untouched:=Puzzle.new();untouched.begin(id,"fixture:00",context());var safe:=untouched.snapshot()
  check(not untouched.restore(forged,context()),"forged completed state rejected")
  check(Same.equivalent(safe,untouched.snapshot()),"bad snapshot does not mutate session")
  var other:Dictionary=context();other.current_token="other"
  check(not untouched.restore(terminal,other),"proof bound to exact event")
 var river:=Puzzle.new();river.begin("pz_ch16_river","fixture:00",context())
 check(not river.apply_input({"type":"gate","channel":0,"value":4}).ok,"survey before gates")
 river.apply_input({"type":"survey"})
 for v in [true,-1,5,1.5,"4",NAN,INF]:
  var before:=river.snapshot();check(not river.apply_input({"type":"gate","channel":0,"value":v}).ok,"strict gate number");check(Same.equivalent(before,river.snapshot()),"bad number atomic")
 for i in range(3):river.apply_input({"type":"gate","channel":i,"value":[4,4,2][i]})
 check(river.apply_input({"type":"test"}).ok and not river.state.complete,"4/4/2 unsafe south canal")
 check(river.apply_input({"type":"dig","site":"old_channel"}).ok and not river.state.overflow,"cannot dig before correct distribution")
 river.apply_input({"type":"gate","channel":2,"value":1})
 check(river.apply_input({"type":"dig","site":"north_bank"}).ok and river.state.material==1,"bad site retains scarce material, no soft lock")
 river.apply_input({"type":"dig","site":"old_channel"});river.apply_input({"type":"test"})
 check(river.state.complete and river.state.flow==10,"correct conserved water flow")
 var scale:=Puzzle.new();scale.begin("pz_ch16_scale","fixture:00",context())
 for item in ["crown","manuscript","sword"]:check(scale.apply_input({"type":"place","object":item}).ok and not scale.state.complete,"dead objects cannot open vault")
 check(not scale.apply_input({"type":"stand","actor":"char_liang_xiao","side":"left"}).ok,"no standing before understanding")
 scale.apply_input({"type":"talk"})
 check(not scale.apply_input({"type":"stand","actor":"char_liang_xiao","side":"left"}).ok,"must clear dead objects")
 scale.apply_input({"type":"clear"});scale.apply_input({"type":"stand","actor":"char_liang_xiao","side":"left"})
 check(not scale.apply_input({"type":"stand","actor":"char_liang_xiao","side":"right"}).ok,"one life cannot occupy both pans")
 check(not scale.state.complete,"first person not enough")
 check(scale.apply_input({"type":"stand","actor":"npc_ranya","side":"right"}).ok and scale.state.complete,"two actual occupants open vault")
 print("Chapter sixteen puzzles: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
