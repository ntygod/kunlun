extends SceneTree
const R=preload("res://scripts/puzzles/chapter_eight_puzzle_resolver.gd")
var checks:=0
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(ok:bool,label:String) -> void:
	checks+=1
	if not ok:failures+=1;push_error(label)
static func fixture(id:String) -> Dictionary:
	return {"chapter":8,"current_token":"ch08:"+id,"revision":1,"scene_id":"ch08_submerged_dam" if id==R.IDS[1] else id,"actors":{"char_liang_xiao":{"id":"char_liang_xiao","hp":10},"npc_ranya":{"id":"npc_ranya","kind":"scene_support","status":"alive"},"npc_guo_shoujing":{"id":"npc_guo_shoujing","kind":"scene_support","status":"alive"}}}
func act(r:RefCounted,a:Dictionary,expected:bool=true) -> void:
	check(r.apply_input(a).ok==expected,"action "+str(a))
	var copy:=R.new();check(copy.restore(JSON.parse_string(JSON.stringify(r.snapshot())),r.context),"partial JSON replay")
	check(copy.state==r.state,"partial exact state")
func finish(r:RefCounted,assisted:bool=false) -> void:
	for i in range(90):
		if r.state.complete:break
		act(r,{"type":"assist_step_v1"} if assisted else r.next_demo_action())
	check(r.state.complete,"reachable "+r.puzzle_id)
	check(R.replay_receipt(r.receipt(),r.puzzle_id,r.attempt_id,r.context),"proof replay "+r.puzzle_id)
func run() -> void:
	for malformed in [[],{},true,1.5,"bad"]:
		for field in ["chapter","current_token","scene_id","actors"]:
			var bad_context:Dictionary=fixture(R.IDS[1]);bad_context[field]=malformed
			check(R.new().begin(R.IDS[1],"bad",bad_context)==(malformed is String and field in ["current_token","scene_id"]),"context type "+field)
		for field in ["id","kind","status"]:
			var bad_actor:Dictionary=fixture(R.IDS[1]);bad_actor.actors.npc_ranya[field]=malformed
			check(not R.new().begin(R.IDS[1],"bad",bad_actor),"NPC type "+field)
	check(R.shot_range("light",6,45)==22,"rational 660/30 exactly 22")
	check(R.shot_range("heavy",8,35)==12,"rational 240/20 exactly 12")
	check(R.shot_range("heavy",8,45)==17,"heavy 45 overshoots from 10")
	for id in R.IDS:
		var r:=R.new();check(r.begin(id,"attempt",fixture(id)),"begin")
		for bad in [{},{"type":[]},{"type":"day","value":true},{"type":"day","value":1.5},{"type":"assign","actor":{},"x":0,"y":0},{"type":"finish","success":true},{"type":"ratio","value":7},{"type":"boat","boat":"left","x":null,"y":0}]:
			var before:Dictionary=r.snapshot();check(not r.apply_input(bad).ok,"malformed reject");check(before==r.snapshot(),"malformed atomic")
		act(r,{"type":"finish"},false);act(r,{"type":"assist_step_v1"},false)
		finish(r)
		var proof:Dictionary=r.receipt();proof.assisted=not proof.assisted
		check(not R.replay_receipt(proof,id,"attempt",r.context),"tampered assist denied")
		var wrong:Dictionary=r.context.duplicate(true);wrong.current_token="new token"
		check(not R.replay_receipt(r.receipt(),id,"attempt",wrong),"old token denied")
		var copy:=R.new();check(copy.begin(id,"assisted",fixture(id)),"assisted begin")
		for i in range(3):act(copy,{"type":"hint"})
		finish(copy,true);check(copy.state.assisted,"assisted marked")
	var n:=R.new();n.begin(R.IDS[0],"nonshortest",fixture(R.IDS[0]))
	act(n,{"type":"day","value":0});act(n,{"type":"finish"},false)
	act(n,{"type":"day","value":6});act(n,{"type":"finish"},false)
	act(n,{"type":"day","value":12});act(n,{"type":"finish"})
	act(n,{"type":"transfer","from":0,"to":2},false)
	act(n,{"type":"transfer","from":0,"to":1});act(n,{"type":"transfer","from":1,"to":0})
	for edge in [[0,1],[0,1],[1,2],[1,2]]:act(n,{"type":"transfer","from":edge[0],"to":edge[1]})
	act(n,{"type":"finish"});act(n,{"type":"leg","value":3});act(n,{"type":"finish"},false)
	act(n,{"type":"leg","value":5});act(n,{"type":"finish"},false);finish(n)
	var d:=R.new();d.begin(R.IDS[1],"spatial",fixture(R.IDS[1]))
	act(d,{"type":"sink"},false);act(d,{"type":"open_gate"},false)
	act(d,{"type":"assign","actor":"npc_ranya","x":-2,"y":1},false)
	act(d,{"type":"assign","actor":"npc_ranya","x":0,"y":0},false)
	act(d,{"type":"boat","boat":"left","x":0,"y":2},false)
	for who in R.ACTORS:act(d,{"type":"assign","actor":who,"x":R.STATIONS[who][0],"y":R.STATIONS[who][1]})
	act(d,{"type":"beat"});check(d._events[-1].parallel_edges.size()==3,"three actual concurrent edges")
	act(d,{"type":"beat"});check(d.state.actors==R.STATIONS,"stations actual paths")
	act(d,{"type":"boat","boat":"wide","x":3,"y":2},false)
	for boat in ["left","middle","wide"]:act(d,{"type":"boat","boat":boat,"x":R.BOAT_TARGETS[boat][0],"y":2})
	act(d,{"type":"beat"});act(d,{"type":"sink"},false);act(d,{"type":"beat"})
	act(d,{"type":"sink"});check(d.get_view().width==4 and d.get_view().velocity==6,"three distinct boats 8 to 4 and 3 to 6")
	act(d,{"type":"open_gate"},false);act(d,{"type":"ratio","value":"5:5"});act(d,{"type":"open_gate"},false)
	act(d,{"type":"ratio","value":"3:7"});act(d,{"type":"open_gate"});check(not d.state.complete,"gate no instant bridge success")
	for i in range(5):act(d,{"type":"beat"})
	check(d.state.complete and d.state.bridge_destroyed and d.state.wood==[4,5],"wood real continuous path")
	var c:=R.new();c.begin(R.IDS[2],"trial",fixture(R.IDS[2]))
	act(c,{"type":"weight","value":6});act(c,{"type":"angle","value":45});act(c,{"type":"finish"},false)
	act(c,{"type":"trial"});act(c,{"type":"weight","value":4});act(c,{"type":"finish"},false)
	finish(c);check(not c.state.plans[0].actual_fire and not c.state.plans[1].actual_fire,"no firing authorization")
	# Exhaust a later segment: replayed completed prefix and assistance cannot fall.
	var h:=R.new();h.begin(R.IDS[0],"history",fixture(R.IDS[0]))
	for i in range(3):h.apply_input({"type":"hint"})
	h.apply_input({"type":"assist_step_v1"});h.apply_input({"type":"assist_step_v1"});h.apply_input({"type":"assist_step_v1"})
	check(h.state.problem==1 and h.state.assisted,"verified first prefix")
	for i in range(R.SEGMENT_LIMIT):h.apply_input({"type":"finish"})
	act(h,{"type":"retry"});check(h.state.problem==1 and h.state.passed.size()==1 and h.state.assisted,"limit preserves prefix and assist")
	var forged:Dictionary=h.snapshot();forged.input_log[-1].assisted=0;forged.state.assisted=false
	check(not R.new().restore(forged,h.context),"cannot lower prefix assisted in compaction")
	finish(h)
	# Unverified discarded history is explicitly unknown, never claimed manual.
	var unknown:=R.new();unknown.begin(R.IDS[0],"unknown",fixture(R.IDS[0]))
	unknown.apply_input({"type":"day","value":12});unknown.apply_input({"type":"finish"})
	for i in range(3):unknown.apply_input({"type":"hint"})
	unknown.apply_input({"type":"assist_step_v1"})
	for i in range(R.SEGMENT_LIMIT):unknown.apply_input({"type":"finish"})
	unknown.apply_input({"type":"retry"})
	check(unknown.assistance_status()=="unknown","unverified summary flag alone cannot establish assistance")
	var unverified:Dictionary=unknown.snapshot();unverified.input_log[-1].assisted=0;unverified.state.assisted=false
	var restored:=R.new();check(restored.restore(unverified,unknown.context),"discarded summary is not falsely authenticated")
	check(restored.assistance_status()=="unknown" and restored.get_view().previous_attempt_history_unverified,"unknown history explicit in view")
	finish(restored)
	check(restored.receipt().assisted and not restored.receipt().manual_process_verified and restored.receipt().assistance_status=="unknown","legacy assisted conservative, unknown never manual")
	var fake_manual:Dictionary=restored.receipt();fake_manual.assisted=false;fake_manual.assistance_status="manual";fake_manual.manual_process_verified=true
	check(not R.replay_receipt(fake_manual,restored.puzzle_id,restored.attempt_id,restored.context),"unknown cannot forge manual receipt")
	print("Chapter eight puzzles: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
