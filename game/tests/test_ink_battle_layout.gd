extends SceneTree
const BattleView = preload("res://scripts/ui/battle_panel.gd")
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
func descendants(node: Node) -> Array:
	var result: Array = [node]
	for child in node.get_children(): result.append_array(descendants(child))
	return result
func run() -> void:
	root.size = Vector2i(1280,720)
	var app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	var campaign_before := JSON.stringify([app.story.state,app.story.actors,app.story.items])
	app.mode = "chapter_battle"
	app._modal_title("交锋", "只读排版检查")
	var panel := BattleView.new()
	app.modal_content.add_child(panel)
	var state := {"round":1,"revision":7,"outcome":"","commands":{},"events":[],"intents":[],"skill_costs":{"a":{"observe":4}},"actors":[
		{"id":"a","name":"甲","team":"party","defeated":false,"hp":50,"max_hp":50,"mp":20,"max_mp":20,"ready":{},"skills":["normal_attack","observe","self_guard"]},
		{"id":"b","name":"敌甲","team":"enemy","defeated":false,"hp":50,"max_hp":50,"mp":0,"max_mp":0},
		{"id":"c","name":"敌乙","team":"enemy","defeated":false,"hp":50,"max_hp":50,"mp":0,"max_mp":0}]}
	var original := JSON.stringify(state)
	var skills := {"normal_attack":{"target":"enemy"},"observe":{"name":"观势察机","target":"enemy"},"self_guard":{"target":"self"}}
	panel.render(state,skills,false)
	await process_frame
	await process_frame
	check(panel.has_node("InkBattleColumns"), "legacy battle has grouped layout")
	check(panel.get_node("InkBattleColumns").columns == 2, "wide battle uses two columns")
	check(panel.target_menu.item_count == 2, "target picker preserved")
	panel.target_menu.select(1)
	panel.target_menu.item_selected.emit(1)
	var observe_button: Button
	for child in descendants(panel):
		if child is Button and child.get_meta("skill_id","") == "observe": observe_button = child
	check(observe_button != null, "skill button survives reparenting")
	observe_button.grab_focus()
	panel._select_skill("observe")
	await process_frame
	await process_frame
	check(panel.selected_target == "c", "unsubmitted target survives grouped redraw")
	var focus := root.gui_get_focus_owner()
	check(focus != null and focus.get_meta("skill_id","") == "observe", "focus survives grouped redraw")
	var captured: Array = []
	panel.command_requested.connect(func(actor,skill,target,revision): captured.append([actor,skill,target,revision]))
	panel._submit("a")
	check(captured == [["a","observe","c",7]], "original command signal contract")
	check(JSON.stringify(state) == original, "layout does not mutate battle snapshot")
	root.size = Vector2i(640,360)
	await process_frame
	await process_frame
	check(panel.get_node("InkBattleColumns").columns == 1, "compact layout remains scrollable")
	check(panel.target_menu.get_item_metadata(panel.target_menu.selected) == "c", "resize retains target")
	panel._select_skill("self_guard")
	await process_frame
	await process_frame
	check(panel.target_menu.item_count == 1 and panel.target_menu.get_item_metadata(0) == "a", "self target remains legal")
	panel._select_skill("observe")
	await process_frame
	await process_frame
	check(panel.selected_target == "c", "enemy preference survives self stance")
	check(JSON.stringify([app.story.state,app.story.actors,app.story.items]) == campaign_before, "layout never advances campaign")
	app.queue_free()
	await process_frame
	await process_frame
	print("Ink battle layout: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
