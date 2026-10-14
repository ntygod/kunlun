extends SceneTree
const BattleView = preload("res://scripts/ui/battle_panel.gd")
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, note: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(note)
func buttons(node: Node) -> Array:
	var found: Array = []
	for child in node.get_children():
		if child is Button: found.append(child)
	return found
func run() -> void:
	var panel := BattleView.new()
	root.add_child(panel)
	var view := {"round":1,"revision":7,"outcome":"","events":[],"commands":{},"intents":[],
		"actors":[{"id":"a","name":"甲","team":"party","defeated":false,"hp":50,"max_hp":50,"mp":0,"max_mp":20,"ready":{},"skills":["normal_attack","sancai_counter","guard_ally"]},
		{"id":"b","name":"乙","team":"party","defeated":false,"hp":50,"max_hp":50,"mp":20,"max_mp":20,"ready":{},"skills":["normal_attack","sancai_counter"]},
		{"id":"enemy","name":"敌","team":"enemy","defeated":false,"hp":50,"max_hp":50,"mp":0,"max_mp":0}],
		"skill_costs":{"a":{"sancai_counter":8},"b":{"sancai_counter":8}}}
	var skills := {"normal_attack":{"target":"enemy"},"sancai_counter":{"target":"enemy"},"guard_ally":{"target":"ally"}}
	panel.render(view,skills,false)
	for button in buttons(panel):
		if "三才归元掌" in button.text: check(button.disabled and "真气不足" in button.text,"MP cost explained and unavailable skill disabled")
		if button.text == "结算本回合": check(button.disabled,"no premature resolution")
	panel._select_skill("guard_ally")
	check(panel.target_menu.item_count == 2,"ally skill offers living party targets")
	panel.selected_actor = "b"
	panel._select_skill("sancai_counter")
	check(panel.selected_actor == "b","second actor remains selectable")
	var captured: Array = []
	panel.command_requested.connect(func(actor,skill,target,revision): captured.append([actor,skill,target,revision]))
	panel._submit("b")
	check(captured == [["b","sancai_counter","enemy",7]],"button sends command intent with actor/target/revision")
	check(view.commands.is_empty() and view.actors[0].mp == 0,"presentation never mutates supplied state")
	view.outcome = "defeat"
	panel.render(view,skills,false)
	var retry := false
	var continue_present := false
	for button in buttons(panel):
		if button.text == "从战前重试": retry = true
		if button.text == "收招，继续剧情": continue_present = true
	check(retry and not continue_present,"defeat offers retry, never success continuation")
	panel.queue_free()
	await process_frame
	print("Battle panel: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
