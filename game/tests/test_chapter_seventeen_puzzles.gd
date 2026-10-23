extends SceneTree
const Resolver=preload("res://scripts/puzzles/chapter_seventeen_puzzle_resolver.gd")
const Same=preload("res://scripts/campaign/encounter_session.gd")
var checks=0
var failures=0
func _initialize()->void:call_deferred("run")
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func ctx(roof:bool=false,method:String="r07_method_joinery")->Dictionary:
 return {"chapter":17,"current_token":"test_puzzle","control_actor_id":"char_liu_yingying" if roof else "char_liang_xiao","attempt_generation":0,"evidence":Resolver.EVIDENCE.duplicate(),"roof_method":method}
func step(p:RefCounted,action:Dictionary)->void:
 check(p.apply_input(action).get("ok",false),"legal input "+str(action))
 var copy:=Resolver.new();check(copy.restore(JSON.parse_string(JSON.stringify(p.snapshot())),p.context),"every input strict JSON replay")
 check(Same.equivalent(copy.snapshot(),p.snapshot()),"same partial state")
func run()->void:
 var p:=Resolver.new();var invalid:=ctx();invalid.evidence.pop_back()
 check(not p.begin("pz_ch17_evidence","test_puzzle",invalid),"missing actual sixth clue blocks entry")
 invalid=ctx();invalid.evidence[5]="howls"
 check(not p.begin("pz_ch17_evidence","test_puzzle",invalid),"duplicate clue cannot replace sixth")
 for alternate in [false,true]:
  p=Resolver.new();check(p.begin("pz_ch17_evidence","test_puzzle",ctx()),"evidence entry")
  var initial:=p.snapshot()
  for value in [{"success":true},{"type":"toggle","clue":"invented"},{"type":"connect","claim":"amo"},{"type":"toggle","clue":"howls","revision":0},{"type":"hint","extra":1}]:
   check(not p.apply_input(value).get("ok",false),"reject fabricated input");check(Same.equivalent(initial,p.snapshot()),"invalid input atomic")
  step(p,{"type":"toggle","clue":"howls"});step(p,{"type":"connect","claim":"double"})
  check(not p.state.complete and p.state.links.is_empty(),"one clue never suffices")
  step(p,{"type":"toggle","clue":"disguise"});step(p,{"type":"connect","claim":"double"})
  for key in ["wounds","callus","case" if alternate else "zhuque"]:step(p,{"type":"toggle","clue":key})
  step(p,{"type":"connect","claim":"amo"});check(p.state.complete and p.get_receipts().size()==1,"both source-supported evidence chains")
  var bad:Dictionary=p.snapshot();bad.state.links=[];var copy:=Resolver.new()
  check(not copy.restore(bad,p.context),"edited success state cannot replay")
  check(not p.apply_input({"type":"connect","claim":"amo"}).ok,"terminal inputs rejected")
 for method in ["r07_method_joinery","r07_method_wall"]:
  p=Resolver.new();check(p.begin("pz_ch17_roof","test_puzzle",ctx(true,method)),"roof method entry")
  step(p,{"type":"place","actor":"char_feng_lian","part":"reeds"})
  check(p.state.stage==0 and not p.state.complete,"cannot skip structural cooperation")
  for item in p.roof_steps():step(p,{"type":"place","actor":item.actor,"part":item.part})
  check(p.state.complete,"three people actual ordered work")
 p=Resolver.new();p.begin("pz_ch17_evidence","test_puzzle",ctx())
 for n in range(512):check(p.apply_input({"type":"toggle","clue":"howls"}).ok,"bounded real input")
 var full:=p.snapshot();check(not p.apply_input({"type":"toggle","clue":"howls"}).ok,"cap rejects without mutation");check(Same.equivalent(full,p.snapshot()),"cap state unchanged")
 print("Chapter seventeen puzzles: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
