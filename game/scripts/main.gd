extends Control
const Story = preload("res://scripts/story_state.gd")
const Saves = preload("res://scripts/save_store.gd")
const World = preload("res://scripts/world.gd")
const Battle = preload("res://scripts/training_battle.gd")
var story: StoryState
var saves := Saves.new()
var world: KunlunWorld
var viewport: SubViewport
var display: TextureRect
var header: Label
var objective: Label
var prompt: Label
var notice: Label
var dialogue_panel: PanelContainer
var speaker: Label
var dialogue_text: Label
var dialogue_scroll: ScrollContainer
var actions: HBoxContainer
var modal: PanelContainer
var modal_content: VBoxContainer
var mode := "menu"
var lines: Array = []
var line_index := 0
var active_scene_id := ""
var choice_pending := -1
var battle: TrainingBattle
var tension := 5
var elevation := 1
var engine_index := 0
var title_font: Font
var content: Dictionary
var rules: Dictionary

func _ready() -> void:
	content = JSON.parse_string(FileAccess.get_file_as_string("res://data/prologue.json"))
	rules = JSON.parse_string(FileAccess.get_file_as_string("res://data/combat_rules.json"))
	story = Story.new(content)
	_setup_inputs()
	_setup_theme()
	_build_ui()
	_load_scene()
	_show_menu(true)
	resized.connect(_layout)
	_layout()

func _setup_inputs() -> void:
	var bindings := {"move_left":[KEY_A,KEY_LEFT],"move_right":[KEY_D,KEY_RIGHT],"move_up":[KEY_W,KEY_UP],"move_down":[KEY_S,KEY_DOWN],"interact":[KEY_E,KEY_SPACE],"journal":[KEY_J],"save_game":[KEY_F5],"load_game":[KEY_F9]}
	for action in bindings:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key in bindings[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action,event)

func _setup_theme() -> void:
	var theme_resource := Theme.new()
	if ResourceLoader.exists("res://assets/fonts/kunlun_ui.ttf"):
		title_font = load("res://assets/fonts/kunlun_ui.ttf")
	else:
		var fallback := SystemFont.new()
		fallback.font_names = PackedStringArray(["Noto Sans CJK SC","Microsoft YaHei","PingFang SC"])
		title_font = fallback
	theme_resource.default_font = title_font
	theme_resource.default_font_size = 20
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color("101c23")
	panel.border_color = Color("8e8664")
	panel.set_border_width_all(1)
	panel.content_margin_left = 24
	panel.content_margin_right = 24
	panel.content_margin_top = 16
	panel.content_margin_bottom = 16
	theme_resource.set_stylebox("panel","PanelContainer",panel)
	var button := panel.duplicate() as StyleBoxFlat
	button.bg_color = Color("25363b")
	button.content_margin_top = 6
	button.content_margin_bottom = 6
	theme_resource.set_stylebox("normal","Button",button)
	var hover := button.duplicate() as StyleBoxFlat
	hover.bg_color = Color("46534c")
	theme_resource.set_stylebox("hover","Button",hover)
	theme_resource.set_stylebox("focus","Button",hover)
	theme_resource.set_color("font_color","Label",Color("e0ded0"))
	theme = theme_resource

func _build_ui() -> void:
	viewport = SubViewport.new()
	viewport.size = Vector2i(320,180)
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	add_child(viewport)
	world = World.new()
	viewport.add_child(world)
	display = TextureRect.new()
	display.texture = viewport.get_texture()
	display.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	display.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(display)
	header = _label("",24)
	objective = _label("",18)
	prompt = _label("",19)
	notice = _label("",16)
	notice.modulate = Color("dfc793")
	dialogue_panel = PanelContainer.new()
	add_child(dialogue_panel)
	var dialogue_style := theme.get_stylebox("panel", "PanelContainer").duplicate() as StyleBoxFlat
	dialogue_style.content_margin_top = 8
	dialogue_style.content_margin_bottom = 8
	dialogue_panel.add_theme_stylebox_override("panel", dialogue_style)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",4)
	dialogue_panel.add_child(column)
	speaker = Label.new()
	speaker.add_theme_font_size_override("font_size",16)
	speaker.add_theme_color_override("font_color",Color("d9b978"))
	dialogue_scroll = ScrollContainer.new()
	dialogue_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	dialogue_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dialogue_scroll.focus_mode = Control.FOCUS_ALL
	column.add_child(dialogue_scroll)
	dialogue_text = Label.new()
	dialogue_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dialogue_scroll.add_child(dialogue_text)
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation",8)
	column.add_child(footer)
	speaker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(speaker)
	actions = HBoxContainer.new()
	actions.add_theme_constant_override("separation",8)
	footer.add_child(actions)
	modal = PanelContainer.new()
	add_child(modal)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	modal.add_child(scroll)
	modal_content = VBoxContainer.new()
	modal_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	modal_content.add_theme_constant_override("separation",12)
	scroll.add_child(modal_content)

func _label(value: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size",font_size)
	add_child(label)
	return label

func _layout() -> void:
	if display == null:
		return
	var scale_integer := maxi(1,int(minf(size.x/320.0,size.y/180.0)))
	display.size = Vector2(320,180)*scale_integer
	display.position = ((size-display.size)/2.0).floor()
	var left := display.position.x
	var top := display.position.y
	header.position = Vector2(left+24,top+15)
	objective.position = Vector2(left+24,top+50)
	prompt.position = Vector2(left+24,top+display.size.y-51)
	notice.position = Vector2(left+24,top+display.size.y-26)
	dialogue_panel.position = Vector2(left,top+display.size.y-48*scale_integer)
	dialogue_panel.size = Vector2(display.size.x,48*scale_integer)
	modal.position = Vector2(maxf(20,(size.x-850)/2),maxf(20,(size.y-510)/2))
	modal.size = Vector2(minf(850,size.x-40),minf(510,size.y-40))
	var ui_font_size := 18 if size.x >= 1000 else 14
	dialogue_text.add_theme_font_size_override("font_size",ui_font_size)

func _load_scene() -> void:
	world.configure(story.scene(),Vector2(story.state.position[0],story.state.position[1]))
	header.text = "昆仑  /  " + story.scene().title
	objective.text = story.scene().objective
	world.player.enabled = false
	dialogue_panel.hide()
	modal.hide()
	mode = "explore"
	world.player.enabled = not story.state.finished
	if story.state.finished:
		_show_ending()

func _process(_delta: float) -> void:
	if world == null or world.player == null:
		return
	if mode == "explore":
		var point := world.nearest()
		prompt.text = "WASD / 方向键 行走    E 交互    J 记事    Esc 菜单" if point.is_empty() else "E · " + point.name
	else:
		prompt.text = ""

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo:
		return
	if event.is_action_pressed("ui_cancel"):
		if mode in ["menu","journal"]:
			modal.hide()
			mode = "explore"
			world.player.enabled = not story.state.finished
			if story.state.finished:
				_show_ending()
		elif mode == "explore":
			_show_menu()
		elif mode == "dialogue":
			# Cancel is a safe interruption. No branch is chosen or item granted.
			dialogue_panel.hide()
			mode = "explore"
			world.player.enabled = true
		return
	if mode == "explore":
		if event.is_action_pressed("interact"):
			_interact()
		elif event.is_action_pressed("journal"):
			_show_journal()
		elif event.is_action_pressed("save_game"):
			_save()
		elif event.is_action_pressed("load_game"):
			_load("manual")
	elif mode == "dialogue" and event.is_action_pressed("interact"):
		_next_line()

func _interact() -> void:
	var point := world.nearest()
	if point.is_empty():
		return
	if not point.main:
		story.observe(point.id)
		_start_lines([{"speaker":point.name,"text":point.text}],false)
		return
	if not story.begin_dialogue():
		notice.text = "先查看未干墨画、父亲旧弓与雨夜脚印。"
		return
	active_scene_id = story.scene().id
	_start_lines(story.scene().dialogue,true)

func _start_lines(new_lines: Array, main: bool) -> void:
	lines = new_lines
	line_index = 0
	if not main:
		active_scene_id = ""
	mode = "dialogue"
	world.player.enabled = false
	dialogue_panel.show()
	_show_line()

func _clear(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()

func _button(text_value: String, callback: Callable, parent: Node) -> Button:
	var button := Button.new()
	button.text = text_value
	if parent is VBoxContainer:
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	else:
		button.add_theme_font_size_override("font_size",16)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _show_line() -> void:
	_clear(actions)
	speaker.text = lines[line_index].speaker + "    %d / %d" % [line_index+1,lines.size()]
	dialogue_text.text = lines[line_index].text
	dialogue_scroll.scroll_vertical = 0
	_button("继续  [E]",_next_line,actions)
	if active_scene_id != "":
		_button("略过对白至抉择",_finish_lines,actions)

func _next_line() -> void:
	if mode != "dialogue":
		return
	line_index += 1
	if line_index >= lines.size():
		_finish_lines()
	else:
		_show_line()

func _finish_lines() -> void:
	if mode != "dialogue":
		return
	if active_scene_id == "":
		dialogue_panel.hide()
		mode = "explore"
		world.player.enabled = true
	elif story.scene().get("mode","") == "lesson" and not story.state.puzzles.get(active_scene_id,false):
		battle = Battle.new(rules)
		_show_battle()
	elif story.scene().get("mode","") == "calibration" and not story.state.puzzles.get(active_scene_id,false):
		tension = 5
		elevation = 1
		engine_index = 0
		_show_calibration()
	else:
		_show_choices()

func _modal_title(title: String, body: String) -> void:
	_clear(modal_content)
	dialogue_panel.hide()
	modal.show()
	world.player.enabled = false
	var title_label := Label.new()
	title_label.text = title
	title_label.add_theme_font_size_override("font_size",30)
	modal_content.add_child(title_label)
	var body_label := Label.new()
	body_label.text = body
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	modal_content.add_child(body_label)

func _show_choices() -> void:
	mode = "choice"
	_modal_title("一念之间", "选择改变相处记事与后续回响，不改变既定命运。")
	var scene_id: String = story.scene().id
	for i in range(story.scene().choices.size()):
		_button(story.scene().choices[i].text,_choose.bind(scene_id,i),modal_content)
	_button("暂且想想，返回场景",_cancel_choice,modal_content)

func _cancel_choice() -> void:
	if story.state.finished:
		_show_ending()
		return
	modal.hide()
	mode = "explore"
	world.player.enabled = true

func _choose(scene_id: String,index: int) -> void:
	if mode != "choice" or scene_id != story.scene().id:
		return
	choice_pending = index
	mode = "feedback"
	_modal_title("余音",story.scene().choices[index].feedback)
	_button("继续前行",_commit.bind(scene_id,index),modal_content)

func _commit(scene_id: String,index: int) -> void:
	if mode != "feedback" or not story.commit_choice(scene_id,index):
		return
	var error := saves.save_game(story,"auto")
	_load_scene()
	notice.text = "已自动保存 · " + story.scene().source_scene if error.is_empty() else error

func _show_battle() -> void:
	mode = "battle"
	_modal_title("镜心观势 · 回合 %d" % battle.round_number,
		"梁文靖 Lv.15   气血 %d / 520   真气 %d / 80\n对手意图：单体点名 → 梁文靖。准备姿态先于速度生效。\n%s\n教学参数，尚非完整战斗系统。" % [battle.hp,battle.mp,battle.log_text])
	if battle.finished:
		story.solve_puzzle("lesson")
		_button("收招，记下所悟",_show_choices,modal_content)
	elif battle.hp <= 0:
		_button("重新练习（不扣物品）",_restart_battle,modal_content)
	else:
		var mirror := _button("三才归元·镜心   %d MP" % battle.mirror_cost(),_battle_action.bind("mirror"),modal_content)
		mirror.disabled = battle.round_number < battle.mirror_ready_round or battle.mp < battle.mirror_cost()
		_button("自守 · 护体回气",_battle_action.bind("guard"),modal_content)
		_button("普通攻击 · 试探",_battle_action.bind("attack"),modal_content)
		_button("退出练习，返回场景",_cancel_choice,modal_content)

func _restart_battle() -> void:
	battle = Battle.new(rules)
	_show_battle()

func _battle_action(action: String) -> void:
	if mode == "battle" and battle.act(action):
		_show_battle()

func _show_calibration() -> void:
	mode = "calibration"
	_modal_title("破山弩 · 第 %d / 3 架" % [engine_index+1],
		"江面风旗向内斜倒，中军帅帐距城三百步。\n刻在弩座的校准记号：张力八成、仰角三格。\n当前：张力 %d 成  /  仰角 %d 格" % [tension,elevation])
	var row := HBoxContainer.new()
	modal_content.add_child(row)
	_button("张力 −",_adjust.bind(-1,0),row)
	_button("张力 ＋",_adjust.bind(1,0),row)
	_button("仰角 −",_adjust.bind(0,-1),row)
	_button("仰角 ＋",_adjust.bind(0,1),row)
	_button("确认校准",_calibrate,modal_content)
	_button("离开机关，稍后重试",_cancel_choice,modal_content)

func _adjust(a: int,b: int) -> void:
	tension = clampi(tension+a,1,10)
	elevation = clampi(elevation+b,1,5)
	_show_calibration()

func _calibrate() -> void:
	if mode != "calibration":
		return
	if tension != 8 or elevation != 3:
		notice.text = "望山与绞盘未合记号，先别发机。"
		return
	engine_index += 1
	if engine_index == 3:
		story.solve_puzzle("calibration")
		_show_choices()
	else:
		tension = 5
		elevation = 1
		_show_calibration()

func _save() -> void:
	story.state.position = [world.player.position.x,world.player.position.y]
	var error := saves.save_game(story)
	notice.text = "已保存到手动槽位" if error.is_empty() else error

func _load(slot: String) -> void:
	var error := saves.load_game(story,slot)
	if error.is_empty():
		_load_scene()
		notice.text = "已读取存档"
	else:
		notice.text = error

func _show_menu(initial: bool = false) -> void:
	mode = "menu"
	_modal_title("昆 仑", "钓鱼烽火\n原生 Godot 基础工程 · 序章开发版\n手工像素占位 / 无配音音乐 / 章节演出仍在制作\nWASD 或方向键行走，E 调查，J 记事，F5 保存，F9 读档。")
	_button("开始行旅" if initial else "返回行旅",_cancel_choice,modal_content)
	_button("读取手动存档",_load.bind("manual"),modal_content)
	_button("读取章节自动存档",_load.bind("auto"),modal_content)
	if not initial:
		_button("保存当前行旅",_save,modal_content)
	_button("重新开始…",_confirm_restart,modal_content)
	_button("退出",get_tree().quit,modal_content)

func _confirm_restart() -> void:
	mode = "confirm"
	_modal_title("重新开始？","当前未保存进度将丢失。手动存档仍保留，后续场次自动保存会更新自动槽。")
	_button("确认重新开始",_restart,modal_content)
	_button("取消",_show_menu,modal_content)

func _restart() -> void:
	story.reset()
	_load_scene()

func _show_journal() -> void:
	mode = "journal"
	var body := "主线 MQ-00 · %s\n%s\n完成场次 %d / %d\n行囊：%s\n相处记事：\n" % [story.state.quest_phase,story.scene().objective,story.state.completed.size(),content.scenes.size(),"、".join(story.state.inventory)]
	for id in story.state.completed:
		for entry in content.scenes:
			if entry.id == id:
				body += "• " + entry.title + "：" + entry.choices[int(story.state.choices[id])].text + "\n"
	_modal_title("行旅记事",body)
	_button("返回 [Esc]",_cancel_choice,modal_content)

func _show_ending() -> void:
	mode = "ending"
	_modal_title("江雾初敛", "文靖留下九龙玉令，与玉翎泛舟东下。\n记事已归档：放下胡汉成见，结庐相守。\n\n本开发版的序章流程到此收束。第01章及后续尚未制作。\n这里不是全游戏通关；当前也未达到策划45分钟的序章内容与成品演出标准。")
	_button("保存行旅",_save,modal_content)
	_button("查看记事",_show_journal,modal_content)
	_button("返回标题",_show_menu.bind(true),modal_content)
