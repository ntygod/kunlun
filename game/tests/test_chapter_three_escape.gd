extends SceneTree
const Escape = preload("res://scripts/world_actions/shadow_escape.gd")
var checks := 0
var failed := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failed += 1
		printerr("FAIL ",label)
func go(s, x: int, y: int) -> void:
	var guard := 0
	while s.state.position != [x,y] and guard < 100:
		guard += 1
		var dx := signi(x-int(s.state.position[0])); var dy := signi(y-int(s.state.position[1])) if dx == 0 else 0
		var r: Dictionary = s.apply_input({"type":"move","dx":dx,"dy":dy})
		if not r.ok:
			printerr("MOVE ",[x,y]," ",s.state.position," ",r.message)
			break
func feint(s, target: String) -> void:
	while s.state.phase != 1: s.apply_input({"type":"wait"})
	check(s.apply_input({"type":"feint","target":target}).ok,"feint "+target+" "+str(s.state))
func shadow(padding: String):
	var s = Escape.new()
	check(s.begin(Escape.SHADOW,"test",{"padding":padding}),"begin")
	go(s,144,208)
	check(s.apply_input({"type":"inspect","target":"yurang"}).ok,"inspect")
	for i in range(2): check(s.apply_input({"type":"correct_step","index":i}).ok,"correct")
	go(s,224,208);feint(s,"zhuhai")
	go(s,272,208);check(s.apply_input({"type":"carry"}).ok,"carry")
	if padding == "abacus":
		go(s,352,208);go(s,352,112);go(s,304,112)
		for i in range(8): s.apply_input({"type":"rest"})
		check(s.state.rests.size()==1,"first hidden rest "+str(s.state))
		go(s,352,112);go(s,352,208)
	go(s,368,208);feint(s,"wuyang")
	go(s,416,208)
	if padding == "abacus":
		go(s,496,208);go(s,496,112);go(s,448,112)
		for i in range(8): s.apply_input({"type":"rest"})
		check(s.state.rests.size()==2,"second hidden rest "+str(s.state))
		go(s,496,112);go(s,496,208);go(s,416,208)
	go(s,496,208);go(s,560,208)
	check(not s.receipt().is_empty(),"shadow complete "+padding+" "+str(s.state))
	var replay = Escape.new()
	check(replay.restore(s.snapshot(),{"padding":padding}),"restore")
	check(replay.receipt()==s.receipt(),"receipt replay equal")
	return s
func decoy():
	var s = Escape.new()
	check(s.begin(Escape.DECOY,"decoy",{}),"decoy begin")
	check(not s.apply_input({"type":"place_cloak"}).ok,"no remote cloak")
	go(s,144,208)
	check(s.apply_input({"type":"inspect","target":"blood_trail"}).ok,"blood")
	go(s,304,208);go(s,304,112);go(s,224,112)
	check(s.apply_input({"type":"shelter"}).ok,"hollow occluded")
	check(s.apply_input({"type":"take_cloak"}).ok,"unique cloak")
	check(not s.apply_input({"type":"take_cloak"}).ok,"no cloak duplication")
	go(s,256,112);check(s.apply_input({"type":"guard_animals"}).ok,"animals stay")
	go(s,304,112);go(s,304,208);go(s,352,208)
	check(s.apply_input({"type":"place_cloak"}).ok,"cloak placed")
	check(s.receipt().is_empty(),"placement not success")
	go(s,448,208);go(s,560,208)
	for i in range(80):
		if not s.receipt().is_empty(): break
		s.apply_input({"type":"wait"})
	check(not s.receipt().is_empty(),"ming actually crosses fork "+str(s.state))
	var replay = Escape.new()
	check(replay.restore(s.snapshot(),{}),"decoy replay")
	check(replay.receipt()==s.receipt(),"decoy receipt equal")
	var saved: Dictionary = s.snapshot()
	saved.state_hash = "forged"
	check(not replay.restore(saved,{}),"forged snapshot denied")
	check(s.apply_input({"type":"retry"}).ok,"retry")
	check(s.state.cloak_state=="xiaoshuang" and s.state.position==[80,208] and not s.state.sheltered,"retry restores ownership and bodies")
	check(s.receipt().is_empty(),"retry no stale receipt")
	return s

func boundaries() -> void:
	var s = Escape.new()
	check(not s.begin("unknown","bad",{}),"unknown controller rejected")
	check(not s.begin(Escape.SHADOW,"bad",{"map_id":"map_ch03_forest_road"}),"wrong map rejected")
	s.begin(Escape.SHADOW,"bounds",{})
	for bad in [{"type":"move","dx":100,"dy":0},{"type":"move","dx":1,"dy":1},{"type":"move","dx":0.5,"dy":0.5},{"type":"move","dx":1,"dy":0,"position":[560,208]},{"type":"submit","won":true}]:
		check(not s.apply_input(bad).get("ok",false),"invalid input rejected")
	check(s.state.position==[80,208] and s.receipt().is_empty(),"invalid inputs cannot teleport or win")
	check(not s.apply_input({"type":"feint","target":"zhuhai"}).ok,"remote feint rejected")
	go(s,144,208);s.apply_input({"type":"inspect","target":"yurang"})
	check(not s.apply_input({"type":"correct_step","index":1}).ok,"correction order")
	s.apply_input({"type":"correct_step","index":0});s.apply_input({"type":"correct_step","index":1})
	go(s,224,208)
	while s.state.phase==1:s.apply_input({"type":"wait"})
	check(not s.apply_input({"type":"feint","target":"zhuhai"}).ok,"wrong phase rejected")
	var saved: Dictionary = JSON.parse_string(JSON.stringify(s.snapshot()))
	var replay = Escape.new()
	check(replay.restore(saved,{}),"JSON roundtrip replay")
	saved.frozen_config_hash="wrong"
	check(not replay.restore(saved,{}),"changed geometry denied")
	for i in range(100):
		if s.state.captured:break
		s.apply_input({"type":"wait"})
	check(s.state.captured and s.receipt().is_empty(),"pursuer can capture at last seen position")
	s.apply_input({"type":"retry"})
	check(not s.state.captured and s.state.position==[80,208] and s.state.feints.is_empty(),"capture retry resets attempt")
	var ctx := {"world_objects":{"ch03_hidden_hollow":{"state":"concealed","occupants":["char_hua_xiaoshuang","follower_baichier","follower_jinlinger"]}}}
	s.begin(Escape.DECOY,"checkpoint",ctx)
	check(s.state.position==[224,112] and s.state.sheltered and not s.state.carrying,"trusted shelter checkpoint stays sheltered")
	s.apply_input({"type":"take_cloak"})
	go(s,304,112);go(s,304,208);go(s,352,208);s.apply_input({"type":"place_cloak"})
	s.apply_input({"type":"retry"})
	check(s.state.position==[224,112] and s.state.cloak_state=="xiaoshuang" and s.state.cloak_position.is_empty(),"checkpoint retry no duplicated cloak")
	check(replay.restore(JSON.parse_string(JSON.stringify(s.snapshot())),ctx),"shelter retry JSON replay")

func occupied_swap_boundary() -> void:
	var s = Escape.new()
	s.begin(Escape.DECOY,"swap",{})
	go(s,144,208);s.apply_input({"type":"inspect","target":"blood_trail"})
	go(s,304,208);go(s,304,112);go(s,224,112)
	s.apply_input({"type":"shelter"});s.apply_input({"type":"take_cloak"})
	go(s,256,112);s.apply_input({"type":"guard_animals"})
	go(s,304,112);go(s,304,208);go(s,352,208);s.apply_input({"type":"place_cloak"})
	go(s,320,208);go(s,320,240)
	for i in range(80):
		if s.state.ming[0]>=304 or s.state.captured:break
		s.apply_input({"type":"wait"})
	s.apply_input({"type":"wait"})
	check(s.state.tick==72 and s.state.position==[320,240] and s.state.ming==[304,240],"pure-input swap boundary reached")
	s.apply_input({"type":"move","dx":-1,"dy":0})
	check(s.state.captured,"entering occupied cell captures before pursuer vacates")
	check(not s.state.crossed_fork and s.receipt().is_empty(),"capture tick cannot credit fork crossing")
	var replay = Escape.new()
	check(replay.restore(JSON.parse_string(JSON.stringify(s.snapshot())),{}),"captured swept collision replays")
	s.apply_input({"type":"retry"})
	check(not s.state.captured and s.state.cloak_state=="xiaoshuang","swap retry restores unique cloak")

func capacity_retry() -> void:
	var s = Escape.new()
	s.begin(Escape.SHADOW,"capacity",{})
	for i in range(8192):s.apply_input({"type":"inspect","target":"yurang"})
	check(s.input_log.size()==8192,"capacity reached with real invalid inputs")
	check(not s.apply_input({"type":"wait"}).ok,"capacity blocks further ordinary inputs")
	check(s.apply_input({"type":"retry"}).ok,"capacity still permits safe retry")
	check(s.input_log.size()==1 and s.state.position==[80,208] and s.receipt().is_empty(),"capacity retry starts clean uncommitted attempt")
	var replay = Escape.new()
	check(replay.restore(JSON.parse_string(JSON.stringify(s.snapshot())),{}),"capacity retry snapshot replays")
	check(s.apply_input({"type":"move","dx":1,"dy":0}).ok,"play resumes after capacity retry")

func _init() -> void:
	shadow("inkstone")
	shadow("abacus")
	decoy()
	boundaries()
	occupied_swap_boundary()
	capacity_retry()
	print("Chapter 3 escape: ",checks," checks, ",failed," failures")
	quit(1 if failed else 0)
