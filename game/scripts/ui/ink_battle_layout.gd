extends Node
## Layout adapter for the two legacy flat battle views only.
## Reparents existing controls, preserving callbacks, metadata and focus.
## Chapter-specific compact boards are intentionally not reinterpreted here.
var queued := false
var adapting := false
const SUPPORTED := ["res://scripts/ui/battle_panel.gd", "res://scripts/ui/objective_battle_panel.gd"]
func _ready() -> void:
	get_tree().node_added.connect(_node_added)
	get_viewport().size_changed.connect(_schedule)
	_schedule()
func _node_added(node: Node) -> void:
	if get_parent().is_ancestor_of(node): _schedule()
func _schedule() -> void:
	if queued or adapting or not is_inside_tree(): return
	queued = true
	call_deferred("_refresh")
func _refresh() -> void:
	queued = false
	if not is_inside_tree(): return
	var content = get_parent().get("modal_content")
	if not is_instance_valid(content): return
	adapting = true
	for child in content.get_children():
		if child.get_script() != null and child.get_script().resource_path in SUPPORTED:
			_layout_panel(child)
	adapting = false
func _layout_panel(panel: VBoxContainer) -> void:
	var compact := get_viewport().get_visible_rect().size.x < 900
	var existing := panel.get_node_or_null("InkBattleColumns") as GridContainer
	if existing != null:
		_apply_breakpoint(panel, existing, compact)
		return
	var original: Array = panel.get_children()
	if original.is_empty(): return
	var focused := get_viewport().gui_get_focus_owner()
	var restore := focused != null and panel.is_ancestor_of(focused)
	var columns := GridContainer.new()
	columns.name = "InkBattleColumns"
	columns.columns = 1 if compact else 2
	columns.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("h_separation", 18)
	columns.add_theme_constant_override("v_separation", 12)
	panel.add_child(columns)
	var tabs := TabBar.new()
	tabs.name = "InkBattleTabs"
	tabs.add_tab("行动")
	tabs.add_tab("战况")
	panel.add_child(tabs)
	panel.move_child(tabs, 0)
	tabs.tab_changed.connect(func(_index: int): _apply_breakpoint(panel, columns, get_viewport().get_visible_rect().size.x < 900))
	var information := _column(columns, "局势与交锋")
	var commands := _column(columns, "编排行动")
	var skill_grid := GridContainer.new()
	skill_grid.name = "InkSkillGrid"
	skill_grid.columns = 2
	skill_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var footer := HBoxContainer.new()
	footer.name = "InkBattleFooter"
	var command_section := false
	var log_section := false
	var is_base: bool = panel.get_script().resource_path == SUPPORTED[0]
	for control in original:
		if control is Label and control.text == "最近交锋": log_section = true
		if control is OptionButton: command_section = true
		if control is Button and not control is OptionButton:
			if control.has_meta("skill_id"):
				if skill_grid.get_parent() == null: commands.add_child(skill_grid)
				control.reparent(skill_grid)
				control.add_theme_font_size_override("font_size", 14 if compact else 16)
				control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				control.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				control.theme_type_variation = "PrimaryButton" if control.text.begins_with("已选") else "Button"
			elif control.text.begins_with("返回菜单") or control.text.begins_with("结算"):
				if footer.get_parent() == null: commands.add_child(footer)
				control.reparent(footer)
				control.add_theme_font_size_override("font_size", 14 if compact else 16)
				control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				control.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				control.theme_type_variation = "PrimaryButton" if control.text.begins_with("结算") else "QuietButton"
			else:
				control.reparent(commands)
				control.add_theme_font_size_override("font_size", 14 if compact else 16)
				control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				control.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				if control.text.begins_with("编排") or control.text.begins_with("收招"): control.theme_type_variation = "PrimaryButton"
		elif command_section and not log_section and is_base:
			if control is OptionButton:
				var label := Label.new()
				label.text = "施展对象" if control == panel.target_menu else "行动角色"
				label.theme_type_variation = "MutedLabel"
				label.set_meta("ink_auxiliary", true)
				commands.add_child(label)
			control.reparent(commands)
			if control is Label and control.text.begins_with("为 "): control.set_meta("ink_auxiliary", true)
		else:
			control.reparent(information)
	if footer.get_parent() != null: commands.move_child(footer, commands.get_child_count()-1)
	else: footer.free()
	if skill_grid.get_parent() == null: skill_grid.free()
	_apply_breakpoint(panel, columns, compact)
	if restore and is_instance_valid(focused) and focused.is_inside_tree(): focused.grab_focus()
func _column(parent: Node, title: String) -> VBoxContainer:
	var card := PanelContainer.new()
	card.theme_type_variation = "CardPanel"
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_FILL
	parent.add_child(card)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 8)
	card.add_child(column)
	var label := Label.new()
	label.text = title
	label.theme_type_variation = "SectionTitle"
	label.set_meta("ink_auxiliary", true)
	column.add_child(label)
	return column

func _apply_breakpoint(panel: VBoxContainer, columns: GridContainer, compact: bool) -> void:
	columns.columns = 1 if compact else 2
	var tabs := panel.get_node_or_null("InkBattleTabs") as TabBar
	if tabs == null: return
	tabs.visible = compact
	if columns.get_child_count() < 2: return
	columns.get_child(0).visible = not compact or tabs.current_tab == 1
	columns.get_child(1).visible = not compact or tabs.current_tab == 0

	var commands: VBoxContainer = columns.get_child(1).get_child(0)
	commands.add_theme_constant_override("separation", 4 if compact else 8)
	for control in commands.get_children():
		if control is Label and control.get_meta("ink_auxiliary", false): control.visible = not compact
	# The original encounter description stays readable in the battle-context tab.
	# It is only moved for compact legacy layouts; no objective/condition is removed.
	var description := panel.get_parent().get_node_or_null("InkPageDescription") as Label
	if description != null:
		description.visible = not compact
		var information: VBoxContainer = columns.get_child(0).get_child(0)
		var copy := information.get_node_or_null("InkCompactDescription") as Label
		if copy == null:
			copy = Label.new()
			copy.name = "InkCompactDescription"
			copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			copy.theme_type_variation = "MutedLabel"
			information.add_child(copy)
			information.move_child(copy, 1)
		copy.text = description.text
		copy.visible = compact
