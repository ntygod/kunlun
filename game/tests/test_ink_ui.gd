extends SceneTree
## Isolated structural/behaviour checks, not a natural campaign playthrough.
const UIStyle = preload("res://scripts/ui/ink_theme.gd")
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
func snapshot(app) -> String:
	return JSON.stringify([app.story.state, app.story.actors, app.story.items])
func run() -> void:
	var app = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	await process_frame
	var before := snapshot(app)
	for resolution in [Vector2i(640,360), Vector2i(1280,720), Vector2i(1366,768)]:
		root.size = resolution
		await process_frame
		await process_frame
		app._layout()
		check(app.viewport.size == Vector2i(320,180), "world canvas remains 320x180")
		var factor: float = float(app.display.size.x)/320.0
		check(factor == floor(factor), "world integer scale")
		check(app.display.position == ((app.size-app.display.size)/2.0).floor(), "world centered")
		app._show_menu(true)
		await process_frame
		check(app.ink_backdrop.visible and not app.ink_shade.visible, "dedicated title backdrop")
		check(app.modal.position.x >= 0 and app.modal.position.x+app.modal.size.x <= app.size.x+1, "title horizontal bounds")
		check(app.modal.position.y >= 0 and app.modal.position.y+app.modal.size.y <= app.size.y+1, "title vertical bounds")
		var start: Button
		for node in descendants(app.modal_content):
			if node is Button and node.text == "开始行旅": start = node
		check(start != null and start.theme_type_variation == &"PrimaryButton", "primary start action")
		app._cancel_choice()
		app._process(0.0)
		check(not app.ink_backdrop.visible and app.ink_hud.visible, "exploration restores world")
		app._start_lines(app.story.scene().dialogue, true)
		await process_frame
		check(app.dialogue_panel.visible and not app.modal.visible, "independent dialogue")
		check(app.speaker.get_parent() == app.dialogue_panel.get_child(0), "speaker above body")
		check(app.dialogue_panel.position.y+app.dialogue_panel.size.y <= app.size.y+1, "dialogue height")
		check(app.dialogue_text.get_theme_color("font_color") == UIStyle.INK, "dark text on paper")
		for node in descendants(app.actions):
			if node is Button: check(node.theme_type_variation == &"PaperButton", "paper buttons")
		app._show_choices()
		await process_frame
		check(app.ink_shade.visible and app.ink_shade.mouse_filter == Control.MOUSE_FILTER_IGNORE, "non-intercepting modal shade")
		app._show_journal()
		await process_frame
		var journal = app.ink_journal_view
		check(is_instance_valid(journal) and journal.tabs.tab_count == 4, "four journal pages")
		for page in range(4):
			journal.tabs.current_tab = page
			await process_frame
			check(journal.page_content.get_child_count() >= 2, "journal page content")
		check(snapshot(app) == before, "journal is read only")
		app._show_menu(false)
		check(not app.ink_backdrop.visible, "pause preserves world")
		app._show_ink_settings()
		check(app.mode == "ui_settings", "separate settings mode")
		app._set_ink_preference(true, "reduced_motion")
		check(app.ink_reduced_motion and app.modal.modulate.a == 1.0, "reduced motion immediate")
		app._set_ink_preference(true, "high_contrast")
		check(app.ink_high_contrast, "contrast preference applied")
		check(snapshot(app) == before, "preferences never mutate campaign")
		for type in ["Button", "OptionButton", "PopupMenu", "LineEdit", "ProgressBar", "VScrollBar", "TabBar"]:
			check(type in app.theme.get_type_list(), "theme covers "+type)
		app._set_ink_preference(false, "high_contrast")
		app._show_menu(true)
	var sample := "昆仑山河漫卷江湖行旅启程一卷山河几度离合从此处走进昆仑暂歇片刻整理行囊再赴前路界面设置减少动效增强文字对比仅调整显示不影响战斗剧情或存档此刻行旅随身旧物已学武学相处记事回响只读查阅不会改变进度开发版像素资源与演出制作中"
	var missing := ""
	for character in sample:
		if not app.title_font.has_char(character.unicode_at(0)) and character not in missing: missing += character
	check(missing.is_empty(), "bundled font UI coverage: "+missing)
	app.queue_free()
	await process_frame
	await process_frame
	print("Ink UI: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
