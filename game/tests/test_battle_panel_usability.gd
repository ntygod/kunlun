extends SceneTree
## Scene-tree UI regressions; not an OS keyboard/mouse or full-campaign playthrough.
const BattleView = preload("res://scripts/ui/battle_panel.gd")
var checks := 0
var failures := 0
var captured: Array = []

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, note: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(note)

func fixture() -> Dictionary:
	return {"round":1,"revision":7,"outcome":"","events":[],"commands":{},"intents":[],
		"actors":[
			{"id":"a","name":"甲","team":"party","defeated":false,"hp":50,"max_hp":50,"mp":20,"max_mp":20,"ready":{},"skills":["normal_attack","observe","self_guard","guard_ally","unsupported"]},
			{"id":"b","name":"乙","team":"party","defeated":false,"hp":50,"max_hp":50,"mp":20,"max_mp":20,"ready":{},"skills":["normal_attack","observe","self_guard","guard_ally"]},
			{"id":"enemy_one","name":"敌甲","team":"enemy","defeated":false,"hp":50,"max_hp":50,"mp":0,"max_mp":0},
			{"id":"enemy_two","name":"敌乙","team":"enemy","defeated":false,"hp":50,"max_hp":50,"mp":0,"max_mp":0}],
		"skill_costs":{"a":{"observe":4},"b":{"observe":4}}}

func skill_fixture() -> Dictionary:
	return {"normal_attack":{"target":"enemy"},
		"observe":{"name":"观势察机","target":"enemy"},
		"self_guard":{"target":"self"},"guard_ally":{"target":"ally"},
		"unsupported":{"name":"未接入目标","target":"unsupported"}}

func button_named(panel: Control, text: String) -> Button:
	for child in panel.get_children():
		if child is Button and child.text == text: return child
	return null

func skill_button(panel: Control, text: String) -> Button:
	for child in panel.get_children():
		if child is Button and text in child.text: return child
	return null

func labels(panel: Control) -> String:
	var result := ""
	for child in panel.get_children():
		if child is Label: result += child.text+"\n"
	return result

func target(panel) -> String:
	if not is_instance_valid(panel.target_menu) or panel.target_menu.selected < 0: return ""
	return str(panel.target_menu.get_item_metadata(panel.target_menu.selected))

func choose_target(panel, index: int) -> void:
	panel.target_menu.select(index)
	panel.target_menu.item_selected.emit(index)

func choose_actor(panel, index: int) -> void:
	for child in panel.get_children():
		if child is OptionButton and child != panel.target_menu:
			child.select(index)
			child.item_selected.emit(index)
			return
	check(false,"actor selector exists")

func run() -> void:
	var panel := BattleView.new()
	root.add_child(panel)
	panel.command_requested.connect(func(actor,skill,target_id,revision): captured.append([actor,skill,target_id,revision]))
	var snapshot := fixture()
	var skills := skill_fixture()
	var original_snapshot := JSON.stringify(snapshot)
	var original_skills := JSON.stringify(skills)
	panel.render(snapshot,skills,false)
	check(skill_button(panel,"观势察机") != null,"skill name is read from runtime data")
	check(skill_button(panel,"普通攻击") != null,"legacy basic skill has its Chinese fallback")
	check(panel.target_menu.item_count == 2,"both living enemies are selectable")
	choose_target(panel,1)
	panel._select_skill("observe")
	check(target(panel) == "enemy_two","unsubmitted enemy choice survives skill redraw")
	check(captured.is_empty(),"local selection never sends a combat command")
	panel._submit("a")
	check(captured == [["a","observe","enemy_two",7]],"submit uses visible target and current revision")
	captured.clear()
	panel._select_skill("self_guard")
	check(target(panel) == "a" and panel.target_menu.item_count == 1,"self guard has only self as target")
	panel._select_skill("observe")
	check(target(panel) == "enemy_two","returning from self guard restores the enemy preference")
	panel._select_skill("guard_ally")
	check(target(panel) == "b" and panel.target_menu.item_count == 1,"ally guard excludes self")
	panel._select_skill("observe")
	check(target(panel) == "enemy_two","ally choice does not overwrite enemy preference")
	choose_actor(panel,1)
	check(panel.selected_actor == "b","actor menu really switches actor")
	choose_target(panel,0)
	choose_actor(panel,0)
	check(target(panel) == "enemy_two","actors keep separate target preferences")
	var old_menu: OptionButton = panel.target_menu
	panel._select_skill("observe")
	old_menu.item_selected.emit(0)
	check(target(panel) == "enemy_two","removed menu cannot alter the current selection")
	check(JSON.stringify(snapshot) == original_snapshot,"selection leaves the supplied snapshot untouched")
	check(JSON.stringify(skills) == original_skills,"render leaves skill definitions untouched")
	check(captured.is_empty(),"actor and skill changes do not silently submit")

	var observe := skill_button(panel,"观势察机")
	check(observe != null,"data-named skill can receive keyboard focus")
	if observe != null:
		observe.grab_focus()
		check(root.gui_get_focus_owner() == observe,"focus test has a real focused control")
		observe.pressed.emit()
		var focused: Control = root.gui_get_focus_owner()
		check(focused != null and focused != observe and focused is Button and "观势察机" in (focused as Button).text,"keyboard focus moves to the replacement skill button")
	var outside := Button.new()
	root.add_child(outside)
	outside.grab_focus()
	panel._select_skill("normal_attack")
	check(root.gui_get_focus_owner() == outside,"programmatic redraw does not steal unrelated focus")
	outside.queue_free()

	snapshot.actors[3].defeated = true
	snapshot.revision = 8
	panel.render(snapshot,skills,false)
	check(target(panel) == "enemy_one","defeated preferred target falls back to a living target")
	panel._submit("a")
	check(captured == [["a","normal_attack","enemy_one",8]],"updated snapshot revision accompanies the command")
	captured.clear()
	panel._submit("b")
	check(captured.is_empty(),"stale actor callback cannot submit for the current actor")
	panel.target_menu.select(-1)
	panel._submit("a")
	check(captured.is_empty(),"deselected target does not access metadata at minus one")

	snapshot = fixture()
	snapshot.actors[0].mp = 0
	panel.render(snapshot,skills,false)
	panel._select_skill("observe")
	check(button_named(panel,"编排此行动").disabled,"insufficient mana disables submit")
	panel._submit("a")
	check(captured.is_empty(),"direct unavailable-skill callback emits nothing")
	snapshot.actors[0].mp = 20
	snapshot.actors[0].ready = {"observe":3}
	panel.render(snapshot,skills,false)
	check(button_named(panel,"编排此行动").disabled,"cooldown disables submit")
	panel._submit("a")
	check(captured.is_empty(),"cooldown is respected by the callback too")
	snapshot.round = 3
	panel.render(snapshot,skills,false)
	check(not button_named(panel,"编排此行动").disabled,"skill becomes available on its ready round")
	panel._submit("a")
	check(captured.size() == 1,"ready skill submits normally")
	captured.clear()
	panel._select_skill("unsupported")
	check(panel.target_menu.item_count == 0,"unknown target kind fails closed rather than targeting self")
	check(button_named(panel,"编排此行动").disabled,"unknown target kind disables submit")
	panel._submit("a")
	check(captured.is_empty(),"unknown target kind emits no command")

	snapshot = fixture()
	snapshot.actors[2].defeated = true
	snapshot.actors[3].defeated = true
	panel.render(snapshot,skills,false)
	panel._select_skill("normal_attack")
	check(panel.target_menu.item_count == 0,"no dead enemy is offered as a target")
	panel._submit("a")
	check(captured.is_empty(),"no-target callback is harmless")
	for outcome in ["victory","defeat"]:
		snapshot = fixture()
		snapshot.outcome = outcome
		panel.render(snapshot,skills,false)
		panel._submit("a")
		check(captured.is_empty(),"finished combat does not emit commands: "+outcome)
		var expected := "收招，继续剧情" if outcome == "victory" else "从战前重试"
		check(button_named(panel,expected) != null,"outcome keeps its proper continuation: "+outcome)

	snapshot = fixture()
	snapshot.actors[0].skills = []
	panel.render(snapshot,skills,false)
	check(button_named(panel,"返回菜单（保留战前进度）") != null,"empty skill list retains a safe exit")
	panel._submit("a")
	check(captured.is_empty(),"empty skill list cannot submit")
	snapshot = fixture()
	snapshot.commands = {"a":{"skill_id":"observe","target_id":"enemy_one"}}
	snapshot.events = [{"type":"break"},{"type":"induced"},{"type":"counter"}]
	panel.render(snapshot,skills,false)
	var text := labels(panel)
	check("已编排：观势察机 → 敌甲" in text,"queued command uses the data-defined skill name")
	for pair in [["break","破招"],["induced","诱导成功"],["counter","反击"]]:
		check(pair[1] in text and not pair[0] in text,"combat event is localized: "+pair[0])
	skills.normal_attack.name = "试验剑法"
	panel.render(snapshot,skills,false)
	check(skill_button(panel,"试验剑法") != null,"data names take precedence over legacy fallback names")
	skills.normal_attack.name = ""
	panel.render(snapshot,skills,false)
	check(skill_button(panel,"普通攻击") != null,"empty data name still uses a readable basic fallback")
	panel.queue_free()
	await process_frame
	print("Battle panel usability: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
