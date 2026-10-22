extends VBoxContainer
## Read-only folio: granted skills/items and existing journal text only.
static var display_names: Dictionary = {}
var pages: Array[String] = []
var compact := false
var page_content: VBoxContainer
var tabs: TabBar
func build(original: String, campaign, small: bool) -> void:
	compact = small
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_load_names()
	var overview := original
	var bag := "行囊中尚无可列出的物品。"
	var memories := "行旅方始，往事仍待写下。"
	if "\n行囊\n" in original:
		var parts := original.split("\n行囊\n", true, 1)
		overview = parts[0]
		var remaining := parts[1].split("\n相处记事\n", true, 1)
		bag = remaining[0].strip_edges()
		if remaining.size() > 1: memories = remaining[1].strip_edges()
	elif "行囊：" in original:
		var parts := original.split("行囊：", true, 1)
		overview = parts[0].strip_edges()
		var remaining := parts[1].split("相处记事：", true, 1)
		bag = remaining[0].strip_edges()
		if remaining.size() > 1: memories = remaining[1].strip_edges()
	if bag.is_empty(): bag = "行囊中尚无可列出的物品。"
	if memories.is_empty(): memories = "行旅方始，往事仍待写下。"
	pages = [_readable(overview), _readable(bag), _learned_skills(campaign), _readable(memories)]
	tabs = TabBar.new()
	tabs.name = "JournalTabs"
	tabs.tab_alignment = TabBar.ALIGNMENT_LEFT
	for title in ["行旅", "行囊", "武学", "回响"]: tabs.add_tab(title)
	add_child(tabs)
	page_content = VBoxContainer.new()
	page_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(page_content)
	tabs.tab_changed.connect(show_page)
	show_page(0)
func show_page(index: int) -> void:
	if index < 0 or index >= pages.size(): return
	for child in page_content.get_children():
		page_content.remove_child(child)
		child.queue_free()
	var titles := ["此刻行旅", "随身旧物", "已学武学", "相处记事"]
	var heading := Label.new()
	heading.text = titles[index]
	heading.theme_type_variation = "SectionTitle"
	page_content.add_child(heading)
	for section in pages[index].split("\n\n", false):
		if section.strip_edges().is_empty(): continue
		var card := PanelContainer.new()
		card.theme_type_variation = "CardPanel"
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		page_content.add_child(card)
		var text := Label.new()
		text.text = section.strip_edges()
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text.add_theme_font_size_override("font_size", 14 if compact else 18)
		card.add_child(text)
	var note := Label.new()
	note.theme_type_variation = "MutedLabel"
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.text = "只读记事 · 查阅不会改变行旅进度。"
	if index == 2: note.text = "仅列已学内容；真气消耗与冷却，以交锋时的实际面板为准。整备仍在原有剧情入口进行。"
	page_content.add_child(note)
static func _load_names() -> void:
	if not display_names.is_empty(): return
	display_names = {"normal_attack":"普通攻击", "self_guard":"自守回气", "guard_ally":"援护同伴", "observe":"观势察机", "sancai_counter":"三才归元掌", "mirror_counter":"镜心反制", "item_bashu_journal":"巴蜀山川行记", "char_liang_xiao":"梁萧", "char_liang_wenjing":"梁文靖", "char_liu_yingying":"柳莺莺", "char_hua_xiaoshuang":"花晓霜", "char_huasheng":"花生", "char_axue":"阿雪", "LX_A01":"观势察机", "LX_A02":"三才归元掌", "LX_A05":"碧海惊涛掌", "HS_A01":"金刚护持", "HS_A02":"金刚破器掌", "HS_A03":"巨力推山撼", "HS_A04":"罗汉解脱身", "HS_A05":"伏魔大金刚震"}
	# Runtime JSON only. Do not bind ambiguous MAP/ACT identifiers from design docs.
	for filename in DirAccess.get_files_at("res://data"):
		if filename.ends_with(".json"):
			var value: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/"+filename))
			_index_names(value)
static func _index_names(value: Variant) -> void:
	if value is Dictionary:
		if value.get("name") is String:
			for key in ["id", "source_id"]:
				if value.get(key) is String: display_names[value[key]] = value.name
		for key in value:
			if value[key] is Dictionary and value[key].get("name") is String: display_names[str(key)] = value[key].name
			_index_names(value[key])
	elif value is Array:
		for item in value: _index_names(item)
static func _readable(text: String) -> String:
	var tokens := RegEx.new()
	tokens.compile("[A-Za-z][A-Za-z0-9_]*")
	var phases := {"UNDISCOVERED":"尚未开启", "ACCEPTED":"已经接取", "INVESTIGATING":"寻访之中", "LOCAL_CHOICE":"一念抉择", "COOP_EXECUTING":"携手同行", "AFTERMATH_TALK":"事后余音", "ARCHIVED_ECHO":"已成往事", "active":"同行", "present":"在场", "dead":"已故", "left_permanently":"永久离队", "story_support":"剧情同行", "absent":"暂不在队", "incapacitated":"受伤失能"}
	var result := ""
	var cursor := 0
	for token_match in tokens.search_all(text):
		result += text.substr(cursor, token_match.get_start()-cursor)
		var token: String = token_match.get_string()
		result += str(display_names.get(token, phases.get(token, token)))
		cursor = token_match.get_end()
	return result+text.substr(cursor)
static func _learned_skills(campaign) -> String:
	var result := ""
	for id in campaign.actors:
		var actor: Dictionary = campaign.actors[id]
		if not actor.has("skills") or actor.get("status", "") not in ["active", "present"]: continue
		var known: Array = actor.get("skills", []).duplicate()
		for passive in actor.get("passives", []):
			if passive not in known: known.append(passive)
		var internal := str(actor.get("internal_skill", ""))
		if not internal.is_empty() and internal not in known: known.append(internal)
		if known.is_empty(): continue
		result += str(actor.get("name", display_names.get(id, id)))+"\n"
		for skill in known:
			var name := str(display_names.get(str(skill), str(skill)))
			var rank := int(actor.get("skill_ranks", {}).get(skill, 0))
			var equipped: Array = actor.get("equipped_active_skills", [])
			result += "· "+name+("  第%d重" % rank if rank > 0 else "")+("  · 已备" if skill in equipped else "")+"\n"
		result += "\n"
	return result.strip_edges() if not result.is_empty() else "当前尚无可查阅的已学武学记录。\n教学中的临时授权不作为永久领悟。"
