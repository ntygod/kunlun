extends RefCounted
## Kunlun UI / ink-and-silk. Native high-resolution UI, NOT world pixel art.
## Tokens are centralized here; presentation must never write campaign state.
const INK := Color("101f25")
const DEEP := Color("0b151b")
const SURFACE := Color("172c32")
const RAISED := Color("203a3f")
const EDGE := Color("455953")
const PAPER := Color("eee6d5")
const TEXT := Color("eee8d9")
const MUTED := Color("b4beb3")
const GOLD := Color("d1b478")
const JADE := Color("8bc0aa")
const CINNABAR := Color("df9b88")

static func box(fill: Color, edge: Color, padding: float = 12.0, border: int = 1) -> StyleBoxFlat:
	var result := StyleBoxFlat.new()
	result.bg_color = fill
	result.border_color = edge
	result.set_border_width_all(border)
	result.set_corner_radius_all(3)
	result.content_margin_left = padding
	result.content_margin_right = padding
	result.content_margin_top = padding
	result.content_margin_bottom = padding
	return result

static func panel(compact: bool = false) -> StyleBoxFlat:
	var result := box(SURFACE, EDGE, 12 if compact else 24)
	result.border_width_top = 2
	result.shadow_color = Color(0.01, 0.025, 0.03, 0.45)
	result.shadow_size = 12 if compact else 24
	result.shadow_offset = Vector2(0, 6)
	return result

static func _button_styles(target: Theme, type: String, fill: Color, text: Color, compact: bool, accent: Color) -> void:
	var normal := box(fill, EDGE, 14)
	normal.content_margin_top = 5 if compact else 9
	normal.content_margin_bottom = 5 if compact else 9
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = fill.lightened(0.08)
	hover.border_color = accent
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = fill.lightened(0.13)
	pressed.border_color = accent
	pressed.border_width_left = 3
	var disabled := normal.duplicate() as StyleBoxFlat
	disabled.bg_color = fill.darkened(0.1)
	disabled.border_color = Color("33433f")
	var focus := box(Color.TRANSPARENT, GOLD, 0, 2)
	focus.set_expand_margin_all(2)
	for entry in [["normal", normal], ["hover", hover], ["pressed", pressed], ["disabled", disabled], ["focus", focus]]:
		target.set_stylebox(entry[0], type, entry[1])
	target.set_color("font_color", type, text)
	target.set_color("font_hover_color", type, text)
	target.set_color("font_pressed_color", type, text)
	target.set_color("font_focus_color", type, text)
	target.set_color("font_disabled_color", type, Color("8e9991"))
	target.set_constant("outline_size", type, 0)
	target.set_constant("h_separation", type, 8)

static func build(font: Font, compact: bool = false, high_contrast: bool = false) -> Theme:
	var result := Theme.new()
	result.default_font = font
	result.default_font_size = 14 if compact else 18
	result.set_stylebox("panel", "PanelContainer", panel(compact))
	result.set_stylebox("panel", "Panel", panel(compact))
	result.set_color("font_color", "Label", TEXT)
	result.set_color("default_color", "RichTextLabel", TEXT)
	result.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0.25))
	result.set_constant("line_spacing", "Label", 4 if compact else 7)
	result.set_constant("line_separation", "RichTextLabel", 6)
	for type in ["VBoxContainer", "HBoxContainer", "GridContainer"]:
		result.set_constant("separation", type, 6 if compact else 12)
		result.set_constant("h_separation", type, 8 if compact else 16)
		result.set_constant("v_separation", type, 6 if compact else 12)
	for type in ["Button", "OptionButton", "MenuButton", "CheckButton", "CheckBox"]:
		_button_styles(result, type, RAISED, TEXT, compact, GOLD)
	result.set_type_variation("PrimaryButton", "Button")
	_button_styles(result, "PrimaryButton", Color("34483e"), Color("fff0cb"), compact, GOLD)
	result.set_type_variation("QuietButton", "Button")
	_button_styles(result, "QuietButton", SURFACE, MUTED, compact, JADE)
	result.set_type_variation("DangerButton", "Button")
	_button_styles(result, "DangerButton", Color("402b2b"), Color("ffe0d3"), compact, CINNABAR)
	result.set_type_variation("PaperButton", "Button")
	_button_styles(result, "PaperButton", Color("e4dac5"), INK, compact, Color("8c7043"))
	result.set_type_variation("SectionTitle", "Label")
	result.set_font_size("font_size", "SectionTitle", 16 if compact else 22)
	result.set_color("font_color", "SectionTitle", GOLD)
	result.set_type_variation("MutedLabel", "Label")
	result.set_color("font_color", "MutedLabel", MUTED)
	result.set_font_size("font_size", "MutedLabel", 12 if compact else 15)
	result.set_type_variation("PaperPanel", "PanelContainer")
	var paper := box(PAPER, Color("b69f73"), 12 if compact else 22)
	paper.border_width_top = 3
	paper.shadow_size = 14
	paper.shadow_color = Color(0, 0, 0, 0.35)
	result.set_stylebox("panel", "PaperPanel", paper)
	result.set_type_variation("CardPanel", "PanelContainer")
	result.set_stylebox("panel", "CardPanel", box(INK, Color("334c4b"), 10 if compact else 16))
	var popup := box(INK, GOLD, 10)
	popup.shadow_size = 10
	result.set_stylebox("panel", "PopupMenu", popup)
	result.set_stylebox("hover", "PopupMenu", box(RAISED, JADE, 4))
	for key in ["font_color", "font_hover_color", "font_accelerator_color"]:
		result.set_color(key, "PopupMenu", TEXT)
	result.set_color("font_disabled_color", "PopupMenu", MUTED)
	result.set_font_size("font_size", "PopupMenu", 14 if compact else 18)
	result.set_constant("v_separation", "PopupMenu", 8)
	result.set_stylebox("panel", "TooltipPanel", box(PAPER, GOLD, 10))
	result.set_color("font_color", "TooltipLabel", INK)
	result.set_font_size("font_size", "TooltipLabel", 14)
	for type in ["LineEdit", "TextEdit"]:
		result.set_stylebox("normal", type, box(DEEP, EDGE, 8))
		result.set_stylebox("read_only", type, box(INK, EDGE, 8))
		result.set_stylebox("focus", type, box(Color.TRANSPARENT, GOLD, 0, 2))
		result.set_color("font_color", type, TEXT)
		result.set_color("caret_color", type, GOLD)
		result.set_color("selection_color", type, Color("496458"))
		result.set_color("font_selected_color", type, Color.WHITE)
	var track := box(DEEP, DEEP, 0, 0)
	track.content_margin_top = 4
	track.content_margin_bottom = 4
	result.set_stylebox("background", "ProgressBar", track)
	result.set_stylebox("fill", "ProgressBar", box(JADE, JADE, 0, 0))
	for entry in [["HealthBar", JADE], ["ManaBar", Color("86b1c0")], ["WoundBar", CINNABAR]]:
		result.set_type_variation(entry[0], "ProgressBar")
		result.set_stylebox("fill", entry[0], box(entry[1], entry[1], 0, 0))
	for type in ["HScrollBar", "VScrollBar"]:
		var rail := box(DEEP, DEEP, 0, 0)
		rail.content_margin_left = 4
		rail.content_margin_top = 4
		rail.content_margin_right = 4
		rail.content_margin_bottom = 4
		result.set_stylebox("scroll", type, rail)
		for key in ["grabber", "grabber_highlight", "grabber_pressed"]:
			result.set_stylebox(key, type, box(GOLD if key != "grabber" else EDGE, EDGE, 4, 0))
	for type in ["HSlider", "VSlider"]:
		result.set_stylebox("slider", type, box(DEEP, EDGE, 3))
		result.set_stylebox("grabber_area", type, box(JADE, JADE, 3, 0))
		result.set_stylebox("grabber_area_highlight", type, box(GOLD, GOLD, 3, 0))
	var divider := StyleBoxLine.new()
	divider.color = EDGE
	divider.thickness = 1
	result.set_stylebox("separator", "HSeparator", divider)
	result.set_stylebox("separator", "VSeparator", divider)
	for type in ["TabBar", "TabContainer"]:
		result.set_stylebox("tab_selected", type, box(RAISED, GOLD, 10))
		result.set_stylebox("tab_unselected", type, box(INK, EDGE, 10))
		result.set_color("font_selected_color", type, TEXT)
		result.set_color("font_unselected_color", type, MUTED)
	if high_contrast:
		result.set_color("font_color", "Label", Color.WHITE)
		result.set_color("font_color", "MutedLabel", Color("dce3d7"))
		for type in ["Button", "OptionButton", "MenuButton"]:
			result.set_color("font_color", type, Color.WHITE)
	return result
