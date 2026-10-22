extends GridContainer
## Optional desktop summary. The chapter's existing command panel remains authoritative.
const Skin = preload("res://scripts/ui/ink_theme.gd")
const NAMES := {"char_liang_xiao":"梁萧", "liang_xiao":"梁萧", "char_liang_wenjing":"梁文靖", "liang_wenjing":"梁文靖", "char_hua_xiaoshuang":"花晓霜", "char_liu_yingying":"柳莺莺", "char_huasheng":"花生", "char_axue":"阿雪"}
func render(snapshot: Dictionary) -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var party: Array = []
	for actor in snapshot.get("actors", []):
		if actor.get("team") == "party" and actor.get("controllable", true): party.append(actor)
	columns = maxi(1, mini(3, party.size()))
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for actor in party:
		var card := PanelContainer.new()
		card.theme_type_variation = "CardPanel"
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		add_child(card)
		var stack := VBoxContainer.new()
		stack.add_theme_constant_override("separation", 4)
		card.add_child(stack)
		var heading := Label.new()
		var id := str(actor.get("id", ""))
		heading.text = str(actor.get("name", NAMES.get(id, id)))+(" · 气竭" if actor.get("defeated", false) else "")
		heading.add_theme_color_override("font_color", Skin.GOLD)
		heading.add_theme_font_size_override("font_size", 18)
		stack.add_child(heading)
		for stat in ["hp", "mp"]:
			var current := int(actor.get(stat, 0))
			var maximum := int(actor.get("max_"+stat, 0))
			var label := Label.new()
			label.text = ("气血" if stat == "hp" else "真气")+"  %d / %d" % [current, maximum]
			label.add_theme_font_size_override("font_size", 14)
			stack.add_child(label)
			var bar := ProgressBar.new()
			bar.theme_type_variation = "ManaBar" if stat == "mp" else ("WoundBar" if current*4 < maximum else "HealthBar")
			bar.max_value = maxi(1, maximum)
			bar.value = current
			bar.show_percentage = false
			bar.custom_minimum_size.y = 6
			bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
			stack.add_child(bar)
