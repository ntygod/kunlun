extends "res://scripts/main.gd"
## Presentation-only shell. All campaign, input, save and combat transactions
## remain in main.gd. Keep this inheritance seam small and independently tested.
const InkTheme = preload("res://scripts/ui/ink_theme.gd")
const InkBackdrop = preload("res://scripts/ui/ink_backdrop.gd")
const InkJournal = preload("res://scripts/ui/ink_journal.gd")
const InkVitals = preload("res://scripts/ui/ink_vitals.gd")
var ink_backdrop: Control
var ink_shade: ColorRect
var ink_hud: Panel
var ink_prompt_plate: Panel
var ink_logo: Label
var ink_tagline: Label
var ink_keys: Label
var ink_footer: Label
var ink_menu_initial := true
var ink_reduced_motion := false
var ink_high_contrast := false
var ink_skin_pending := false
var ink_skinning := false
var ink_last_compact := false
var ink_open_tween: Tween
var ink_journal_view: Control

func _compact() -> bool:
	return size.x < 900 or size.y < 500

func _ready() -> void:
	super._ready()
	get_tree().node_added.connect(_queue_ink_skin)
	_queue_ink_skin()

func _setup_theme() -> void:
	super._setup_theme()
	var preferences := ConfigFile.new()
	if preferences.load("user://ui_preferences.cfg") == OK:
		ink_reduced_motion = bool(preferences.get_value("interface", "reduced_motion", false))
		ink_high_contrast = bool(preferences.get_value("interface", "high_contrast", false))
	ink_last_compact = _compact()
	theme = InkTheme.build(title_font, ink_last_compact, ink_high_contrast)

func _build_ui() -> void:
	super._build_ui()
	ink_backdrop = InkBackdrop.new()
	ink_backdrop.name = "InkTitleBackdrop"
	ink_backdrop.z_index = 1
	add_child(ink_backdrop)
	ink_hud = Panel.new()
	ink_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ink_hud.add_theme_stylebox_override("panel", InkTheme.box(Color("13282de8"), InkTheme.EDGE, 0))
	ink_hud.z_index = 1
	add_child(ink_hud)
	ink_prompt_plate = Panel.new()
	ink_prompt_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ink_prompt_plate.add_theme_stylebox_override("panel", InkTheme.box(Color("101f25e8"), InkTheme.EDGE, 0))
	ink_prompt_plate.z_index = 1
	add_child(ink_prompt_plate)
	for label in [header, objective, prompt]: label.z_index = 2
	notice.z_index = 20
	ink_shade = ColorRect.new()
	ink_shade.name = "InkModalShade"
	ink_shade.color = Color(0.015, 0.035, 0.04, 0.68)
	ink_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ink_shade.z_index = 3
	add_child(ink_shade)
	ink_logo = _ink_label("昆 仑", InkTheme.TEXT)
	ink_tagline = _ink_label("山 河 漫 卷  ·  江 湖 行 旅", InkTheme.GOLD)
	ink_keys = _ink_label("WASD 行走 · E 交互\nJ 记事 · Esc 暂歇", InkTheme.MUTED)
	ink_footer = _ink_label("开发版 · 像素资源与演出制作中", InkTheme.MUTED)
	ink_footer.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_panel.z_index = 4
	modal.z_index = 5
	var column := dialogue_panel.get_child(0) as VBoxContainer
	var footer := speaker.get_parent() as HBoxContainer
	speaker.reparent(column)
	column.move_child(speaker, 0)
	footer.alignment = BoxContainer.ALIGNMENT_END
	actions.alignment = BoxContainer.ALIGNMENT_END
	actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 4)
	dialogue_text.add_theme_color_override("font_color", InkTheme.INK)
	speaker.add_theme_color_override("font_color", Color("705b36"))
	dialogue_scroll.custom_minimum_size.y = 48
	_apply_ink_surfaces()

func _ink_label(value: String, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.z_index = 2
	add_child(label)
	return label

func _apply_ink_surfaces() -> void:
	if not is_instance_valid(dialogue_panel): return
	var paper := theme.get_stylebox("panel", "PaperPanel").duplicate() as StyleBoxFlat
	paper.content_margin_top = 8 if _compact() else 16
	paper.content_margin_bottom = 8 if _compact() else 16
	dialogue_panel.add_theme_stylebox_override("panel", paper)
	modal.add_theme_stylebox_override("panel", InkTheme.panel(_compact()))
	save_hotkey_feedback.add_theme_stylebox_override("panel", InkTheme.box(InkTheme.INK, InkTheme.GOLD, 12))

func _layout() -> void:
	super._layout()
	if not is_instance_valid(ink_backdrop): return
	var compact := _compact()
	modal_content.add_theme_constant_override("separation", 6 if compact else 12)
	if compact != ink_last_compact:
		ink_last_compact = compact
		theme = InkTheme.build(title_font, compact, ink_high_contrast)
		_apply_ink_surfaces()
		_queue_ink_skin()
	ink_backdrop.size = size
	ink_shade.size = size
	var left := display.position.x
	var top := display.position.y
	var margin := 12.0 if compact else 24.0
	var hud_width := minf(display.size.x-margin*2, 730.0)
	ink_hud.position = Vector2(left+margin, top+margin)
	ink_hud.size = Vector2(hud_width, 61 if compact else 83)
	header.position = ink_hud.position+Vector2(12, 7 if compact else 10)
	header.size.x = hud_width-24
	header.add_theme_font_size_override("font_size", 17 if compact else 25)
	objective.position = ink_hud.position+Vector2(12, 34 if compact else 48)
	objective.size.x = hud_width-24
	objective.add_theme_font_size_override("font_size", 13 if compact else 16)
	prompt.add_theme_font_size_override("font_size", 12 if compact else 15)
	prompt.position = Vector2(left+margin+12, top+display.size.y-54)
	prompt.size.x = display.size.x-margin*2-24
	ink_prompt_plate.position = prompt.position-Vector2(12, 6)
	ink_prompt_plate.size = Vector2(display.size.x-margin*2, 32 if compact else 38)
	notice.add_theme_font_size_override("font_size", 12 if compact else 14)
	dialogue_panel.size = Vector2(minf(size.x-24, 1120), 144 if compact else 192)
	dialogue_panel.position = Vector2((size.x-dialogue_panel.size.x)/2, size.y-dialogue_panel.size.y-12)
	speaker.add_theme_font_size_override("font_size", 14 if compact else 20)
	dialogue_text.add_theme_font_size_override("font_size", 14 if compact else 20)
	if mode == "menu" and ink_menu_initial:
		var width := minf(400, size.x*0.46)
		var height := minf(520, size.y-40 if compact else size.y-100)
		modal.position = Vector2(size.x-width-(20 if compact else 64), (size.y-height)/2)
		modal.size = Vector2(width, height)
	else:
		var wide := mode in ["chapter_battle", "chapter_puzzle", "chapter_glyph", "journal"]
		var width := minf(1080 if wide else 820, size.x-40)
		var height := minf(610 if wide else 540, size.y-40)
		modal.position = Vector2((size.x-width)/2, (size.y-height)/2)
		modal.size = Vector2(width, height)
	if is_instance_valid(registered_puzzle_panel) and story != null and story.chapter_capability("compact_puzzle_panel"):
		registered_puzzle_panel.custom_minimum_size.y = maxf(284, minf(size.y-72, modal.size.y-32))
	ink_logo.add_theme_font_size_override("font_size", 46 if compact else 88)
	ink_logo.position = Vector2(size.x*0.075, size.y*0.34)
	ink_logo.size = Vector2(size.x*0.45, 120)
	ink_tagline.add_theme_font_size_override("font_size", 10 if compact else 15)
	ink_tagline.position = Vector2(size.x*0.08, size.y*0.27)
	ink_keys.add_theme_font_size_override("font_size", 12 if compact else 16)
	ink_keys.position = Vector2(size.x*0.08, size.y*0.60)
	ink_footer.add_theme_font_size_override("font_size", 10 if compact else 13)
	ink_footer.position = Vector2(size.x*0.08, size.y-65)
	ink_footer.size = Vector2(size.x*0.42, 42)
	_update_ink_visibility()

func _process(delta: float) -> void:
	super._process(delta)
	_update_ink_visibility()

func _update_ink_visibility() -> void:
	if not is_instance_valid(ink_backdrop): return
	var title_screen := mode == "menu" and ink_menu_initial
	ink_backdrop.visible = title_screen
	for node in [ink_logo, ink_tagline, ink_keys, ink_footer]: node.visible = title_screen
	ink_shade.visible = modal.visible and not title_screen
	ink_hud.visible = not modal.visible and not dialogue_panel.visible
	ink_prompt_plate.visible = ink_hud.visible and not prompt.text.is_empty()
	header.visible = not modal.visible and not dialogue_panel.visible
	objective.visible = ink_hud.visible
	prompt.visible = ink_prompt_plate.visible

func _button(text_value: String, callback: Callable, parent: Node) -> Button:
	var button := super._button(text_value, callback, parent)
	button.tooltip_text = text_value
	if parent == actions:
		button.theme_type_variation = "PaperButton"
		button.custom_minimum_size.x = 96
		button.add_theme_font_size_override("font_size", 12 if _compact() else 16)
	else:
		button.theme_type_variation = _ink_button_role(text_value)
		if parent is VBoxContainer:
			button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	return button

func _ink_button_role(text: String) -> StringName:
	if text.begins_with("确认重新") or text.begins_with("确认放弃"): return &"DangerButton"
	if text.begins_with("开始行旅") or text.begins_with("返回行旅") or text.begins_with("继续") or text.begins_with("结算") or text.begins_with("确认校准"):
		return &"PrimaryButton"
	if text.begins_with("返回") or text.begins_with("取消") or text.begins_with("暂") or text.begins_with("退出") or text.begins_with("重新开始"):
		return &"QuietButton"
	return &"Button"

func _modal_title(title: String, body: String) -> void:
	var was_visible := modal.visible
	super._modal_title(title, body)
	if modal_content.get_child_count() >= 2:
		var heading := modal_content.get_child(0) as Label
		heading.name = "InkPageHeading"
		heading.add_theme_font_size_override("font_size", 23 if _compact() else 32)
		heading.add_theme_color_override("font_color", InkTheme.GOLD)
		heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var description := modal_content.get_child(1) as Label
		description.name = "InkPageDescription"
		description.add_theme_font_size_override("font_size", 13 if _compact() else 17)
		description.add_theme_color_override("font_color", InkTheme.MUTED)
	if not was_visible and not ink_reduced_motion and is_instance_valid(ink_backdrop):
		if is_instance_valid(ink_open_tween): ink_open_tween.kill()
		modal.modulate.a = 0.3
		ink_open_tween = create_tween()
		ink_open_tween.tween_property(modal, "modulate:a", 1.0, 0.14)
	else:
		modal.modulate.a = 1.0
	_layout()
	_queue_ink_skin()

func _show_line() -> void:
	super._show_line()
	_layout()
	_queue_ink_skin()

func _show_menu(initial: bool = false) -> void:
	ink_menu_initial = initial
	super._show_menu(initial)
	# A failed checkpoint deliberately leaves the existing battle/puzzle visible.
	if mode != "menu" or modal_content.get_child_count() < 2: return
	var heading := modal_content.get_child(0) as Label
	var description := modal_content.get_child(1) as Label
	heading.text = "启 程" if initial else "暂歇片刻"
	description.text = "一卷山河，几度离合。\n从此处走进昆仑。" if initial else str(story.scene().title)+"\n整理行囊，再赴前路。"
	var settings := _button("界面设置", _show_ink_settings, modal_content)
	modal_content.move_child(settings, maxi(3, modal_content.get_child_count()-3))
	if not initial:
		var journal := _button("行囊 · 武学 · 记事", _show_journal, modal_content)
		modal_content.move_child(journal, 4)
	_layout()

func _show_ink_settings() -> void:
	mode = "ui_settings"
	_modal_title("界面设置", "仅调整显示与界面动效，不影响战斗、剧情或存档。")
	for entry in [["reduced_motion", "减少界面动效", ink_reduced_motion], ["high_contrast", "增强文字对比", ink_high_contrast]]:
		var toggle := CheckButton.new()
		toggle.text = entry[1]
		toggle.button_pressed = entry[2]
		toggle.toggled.connect(_set_ink_preference.bind(str(entry[0])))
		modal_content.add_child(toggle)
	var note := Label.new()
	note.text = "文字与世界像素独立显示。\n所有列表支持滚动；Tab 切换焦点，Enter 确认。\n当前为开发版，地图与人物终稿仍需逐项制作。"
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.theme_type_variation = "MutedLabel"
	modal_content.add_child(note)
	_button("返回行旅菜单", _show_menu.bind(ink_menu_initial), modal_content)

func _set_ink_preference(enabled: bool, key: String) -> void:
	if key == "reduced_motion":
		ink_reduced_motion = enabled
		if enabled and is_instance_valid(ink_open_tween): ink_open_tween.kill()
		modal.modulate.a = 1.0
	elif key == "high_contrast":
		ink_high_contrast = enabled
		theme = InkTheme.build(title_font, _compact(), ink_high_contrast)
		_apply_ink_surfaces()
	var preferences := ConfigFile.new()
	preferences.set_value("interface", "reduced_motion", ink_reduced_motion)
	preferences.set_value("interface", "high_contrast", ink_high_contrast)
	if preferences.save("user://ui_preferences.cfg") != OK:
		notice.text = "界面设置本次已生效，但未能保存设置。"

func _show_journal() -> void:
	super._show_journal()
	if story.active_chapter == 0: _format_ink_journal()

func _show_campaign_journal() -> void:
	super._show_campaign_journal()
	_format_ink_journal()

func _format_ink_journal() -> void:
	if modal_content.get_child_count() < 2: return
	# Later chapters insert the empty-seat memorial before the description.
	# Bind the semantic heading created by _modal_title, not a fragile index.
	var source := modal_content.get_node_or_null("InkPageDescription") as Label
	if source == null: return
	source.hide()
	ink_journal_view = InkJournal.new()
	ink_journal_view.name = "InkJournal"
	modal_content.add_child(ink_journal_view)
	modal_content.move_child(ink_journal_view, 2)
	ink_journal_view.build(source.text, story, _compact())
	_layout()

func _show_chapter_battle() -> void:
	super._show_chapter_battle()
	# Dense chapter panels already own status: do not duplicate it above commands.
	_queue_ink_skin()
	_layout()

func _queue_ink_skin(node: Node = null) -> void:
	if ink_skin_pending or ink_skinning or not is_inside_tree(): return
	if node != null:
		if not is_ancestor_of(node): return
		if is_instance_valid(world) and (node == world or world.is_ancestor_of(node)): return
	ink_skin_pending = true
	call_deferred("_finish_ink_skin")

func _finish_ink_skin() -> void:
	ink_skin_pending = false
	if not is_inside_tree() or not is_instance_valid(modal): return
	ink_skinning = true
	_skin_ink_tree(modal_content)
	_skin_ink_tree(actions)
	ink_skinning = false
	_update_ink_visibility()

func _skin_ink_tree(node: Node) -> void:
	if node is Button and not node is OptionButton and not node is CheckButton:
		if node.theme_type_variation == &"": node.theme_type_variation = _ink_button_role(node.text)
		if node.tooltip_text.is_empty(): node.tooltip_text = node.text
		if node.get_parent() is VBoxContainer: node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if node is OptionButton:
		node.fit_to_longest_item = false
		node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if node is ScrollContainer:
		node.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	for child in node.get_children(): _skin_ink_tree(child)
