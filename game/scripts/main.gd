extends Control
const ChapterTenRecollection = preload("res://scripts/ui/chapter_ten_recollection.gd")
var chapter_ten_recollection = ChapterTenRecollection.new()
const ChapterElevenWorldUI = preload("res://scripts/ui/chapter_eleven_world_ui.gd")
var chapter_eleven_world_ui = ChapterElevenWorldUI.new()
const ChapterTenWorldUI = preload("res://scripts/ui/chapter_ten_world_ui.gd")
var chapter_ten_world_ui = ChapterTenWorldUI.new()
const Story = preload("res://scripts/campaign/campaign_state.gd")
const Encounter = preload("res://scripts/campaign/encounter_session.gd")
const Trial = preload("res://scripts/campaign/three_move_trial.gd")
const CombatPanel = preload("res://scripts/ui/battle_panel.gd")
const WritingBoard = preload("res://scripts/ui/glyph_board.gd")
const Saves = preload("res://scripts/save_store.gd")
const World = preload("res://scripts/world.gd")
const Battle = preload("res://scripts/training_battle.gd")
var story: CampaignState
var encounter_session: RefCounted
var three_move_trial: ThreeMoveTrial
var chapter_token := ""
var work_counts: Dictionary = {}
var battle_error := ""
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
var physical_navigation_keys: Dictionary = {}
var menu_save_allowed := false
var save_hotkey_feedback: Panel
var save_hotkey_feedback_text: Label
var menu_save_feedback: Label
var lines: Array = []
var line_index := 0
var active_scene_id := ""
var registered_puzzle_panel: Control
var registered_puzzle_epoch := 0
var choice_pending := -1
var battle: TrainingBattle
var tension := 5
var elevation := 1
var engine_index := 0
var title_font: Font
var content: Dictionary
var rules: Dictionary

var ch11_application_focused := true
var ch11_window_focused := true
var ch11_last_application_focus := "initial"
var ch11_last_window_focus := "initial"

func _ready() -> void:
	var host := get_window()
	host.focus_entered.connect(_chapter_eleven_window_focus.bind(true,"signal:focus_entered"))
	host.focus_exited.connect(_chapter_eleven_window_focus.bind(false,"signal:focus_exited"))
	# Headless has no desktop focus. Tests exercise notification/signal caches only.
	ch11_window_focused = DisplayServer.get_name() == "headless" or host.has_focus()
	chapter_eleven_world_ui.set_focused(ch11_application_focused and ch11_window_focused)
	# Keep the application ID (and existing user:// saves) stable across chapters.
	get_window().title = "昆仑（开发版）"
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
			if key in [KEY_LEFT,KEY_RIGHT,KEY_UP,KEY_DOWN]: event.keycode = key
			else: event.physical_keycode = key
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
	dialogue_scroll.custom_minimum_size.y = 48
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
	# Non-modal feedback remains above dialogue/choice panels without taking focus.
	save_hotkey_feedback = Panel.new()
	save_hotkey_feedback.add_theme_stylebox_override("panel",theme.get_stylebox("panel","PanelContainer").duplicate())
	save_hotkey_feedback.name = "SaveHotkeyFeedback"
	save_hotkey_feedback.z_index = 30
	save_hotkey_feedback.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(save_hotkey_feedback)
	save_hotkey_feedback_text = Label.new()
	save_hotkey_feedback_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	save_hotkey_feedback_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	save_hotkey_feedback_text.add_theme_font_size_override("font_size",16)
	save_hotkey_feedback_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	save_hotkey_feedback.add_child(save_hotkey_feedback_text)
	save_hotkey_feedback.hide()

func _label(value: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size",font_size)
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	add_child(label)
	return label

func _layout() -> void:
	if display == null:
		return
	if is_instance_valid(save_hotkey_feedback):
		var feedback_width := minf(560,size.x-48)
		save_hotkey_feedback.position = Vector2((size.x-feedback_width)/2,8)
		save_hotkey_feedback.size = Vector2(feedback_width,64)
		save_hotkey_feedback_text.position = Vector2(12,8)
		save_hotkey_feedback_text.size = Vector2(feedback_width-24,48)
	var scale_integer := maxi(1,int(minf(size.x/320.0,size.y/180.0)))
	display.size = Vector2(320,180)*scale_integer
	display.position = ((size-display.size)/2.0).floor()
	var left := display.position.x
	var top := display.position.y
	header.position = Vector2(left+24,top+15)
	objective.position = Vector2(left+24,top+50)
	prompt.position = Vector2(left+24,top+display.size.y-51)
	notice.position = Vector2(left+24,top+display.size.y-26)
	for label in [header,objective,prompt,notice]: label.size.x = maxf(1,display.size.x-48)
	header.add_theme_font_size_override("font_size",24 if scale_integer>=2 else 18)
	objective.add_theme_font_size_override("font_size",18 if scale_integer>=2 else 14)
	# Chinese UI is independent of integer-scaled pixels: 639×359 must not
	# collapse the entire dialogue body into a 48px strip with only buttons.
	var dialogue_width := minf(size.x-24,maxf(display.size.x,600))
	var dialogue_height := maxf(128,48*scale_integer)
	dialogue_panel.position = Vector2((size.x-dialogue_width)/2,minf(top+display.size.y,size.y-12)-dialogue_height)
	dialogue_panel.size = Vector2(dialogue_width,dialogue_height)
	modal.position = Vector2(maxf(20,(size.x-850)/2),maxf(20,(size.y-510)/2))
	modal.size = Vector2(minf(850,size.x-40),minf(510,size.y-40))
	if is_instance_valid(registered_puzzle_panel) and story != null and story.chapter_capability("compact_puzzle_panel"):
		registered_puzzle_panel.custom_minimum_size.y=maxf(284,minf(size.y-72,modal.size.y-32))
	var ui_font_size := 18 if size.x >= 1000 else 14
	dialogue_text.add_theme_font_size_override("font_size",ui_font_size)

func _load_scene() -> void:
	if is_instance_valid(save_hotkey_feedback): save_hotkey_feedback.hide()
	chapter_ten_recollection.reset(self,true)
	_cancel_physical_navigation()
	chapter_eleven_world_ui.reset()
	chapter_ten_world_ui.reset()
	_stop_registered_puzzle_demonstration()
	if story.active_chapter >= 1:
		_load_chapter_scene()
		return
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

func _process(delta: float) -> void:
	if world == null or world.player == null:
		return
	_tick_horse_wait(delta)
	chapter_ten_world_ui.tick(self,delta)
	chapter_ten_recollection.tick(self,delta)
	chapter_eleven_world_ui.tick(self,delta)
	if mode == "explore":
		if story.active_chapter >= 1:
			var event := story.current_event()
			if event.get("kind", "") == "route":
				var progress: Dictionary = world.get_path_progress(event.id)
				story.state.path_progress[event.id] = int(progress.index)
				if story.chapter_capability("route_guidance"):
					var geometry: Dictionary = world.get_objective_geometry(event.id)
					var points: Array = geometry.get("waypoints",[])
					var next := int(progress.index)
					if next < points.size():
						var offset: Vector2 = points[next]-world.player.position
						var direction := ("左" if offset.x < -12 else ("右" if offset.x > 12 else ""))+("上" if offset.y < -12 else ("下" if offset.y > 12 else ""))
						objective.text = event.name+" · 路点%d/%d：向%s方" % [next+1,points.size(),direction if direction!="" else "前"]
					else: objective.text = event.name+" · 路线已走完，靠近目标后按E"
			elif story.chapter_capability("route_guidance") and event.get("op", "") in ["action", "puzzle", "world_puzzle"]:
				var geometry: Dictionary = world.get_objective_geometry(event.get("entry_id",event.get("id","")))
				if not geometry.is_empty():
					var offset: Vector2 = geometry.position-world.player.position
					var direction := ("左" if offset.x < -12 else ("右" if offset.x > 12 else ""))+("上" if offset.y < -12 else ("下" if offset.y > 12 else ""))
					objective.text = str(event.get("name",story.scene().objective))+(" · 目标在"+direction+"方" if offset.length()>float(geometry.radius) else " · 按E交互")
		var point := world.nearest()
		prompt.text = "WASD / 方向键 行走    E 交互    J 记事    Esc 菜单" if point.is_empty() else "E · " + point.name
	else:
		prompt.text = ""

func _cancel_physical_navigation() -> void:
	for key in physical_navigation_keys:
		var release := InputEventKey.new()
		release.keycode = key
		release.pressed = false
		Input.parse_input_event(release)
	physical_navigation_keys.clear()

func _input(event: InputEvent) -> void:
	# Dismiss on the next ordinary input, not a timer or a story transaction.
	if is_instance_valid(save_hotkey_feedback) and ((event is InputEventKey and event.pressed and not event.is_action_pressed("save_game")) or (event is InputEventMouseButton and event.pressed)):
		save_hotkey_feedback.hide()
	if event is InputEventKey and event.pressed and not event.echo and event.is_action_pressed("save_game") and not _save_hotkey_supported():
		_show_save_hotkey_feedback("本次未保存。请返回行走界面，或在可保存的机关、战斗阶段按 F5。")
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and story != null and story.active_chapter == 11:
		_chapter_eleven_focus_trace("key_down",event)
	# Native/logical arrows use keycode; keep physical-only remote navigation
	# compatible without sending a second move into controlled world sessions.
	if event is InputEventKey and event.keycode == 0 and event.physical_keycode in [KEY_LEFT,KEY_RIGHT,KEY_UP,KEY_DOWN]:
		if mode in ["explore","chapter_recollection"] or (not event.pressed and physical_navigation_keys.has(event.physical_keycode)):
			var normalized := event.duplicate() as InputEventKey
			normalized.keycode = event.physical_keycode
			normalized.physical_keycode = 0
			if event.pressed: physical_navigation_keys[event.physical_keycode] = true
			else: physical_navigation_keys.erase(event.physical_keycode)
			get_viewport().set_input_as_handled()
			Input.parse_input_event(normalized)
			return
	if mode == "menu" and event is InputEventKey and event.pressed and not event.echo and event.is_action_pressed("load_game"):
		get_viewport().set_input_as_handled()
		_load("manual")
		return
	if mode == "menu" and event is InputEventKey and event.pressed and not event.echo and event.is_action_pressed("save_game"):
		get_viewport().set_input_as_handled()
		if menu_save_allowed: _save()
		else:
			notice.text = "开始行旅或读取存档后才能保存。"
			_show_menu_save_feedback()
		return
	if horse_waiting and event is InputEventKey and event.pressed:_stop_horse_wait()
	# The archive screen has no unsettled transaction; use the same strict save
	# entry as its visible button, even when a modal button owns keyboard focus.
	if mode == "ending" and story.state.finished and event is InputEventKey and event.pressed and not event.echo and event.is_action_pressed("save_game"):
		get_viewport().set_input_as_handled()
		_save()
		return
	if chapter_ten_recollection.handle_input(self,event):
		get_viewport().set_input_as_handled()
		return
	if chapter_eleven_world_ui.handle_input(self,event):
		get_viewport().set_input_as_handled()
		return
	if chapter_ten_world_ui.handle_input(self,event):
		get_viewport().set_input_as_handled()
		return
	if not story.chapter_capability("checkpoint_inputs") or mode not in ["world_puzzle","chapter_puzzle","chapter_battle"] or not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.is_action_pressed("save_game") or event.is_action_pressed("load_game"):
		get_viewport().set_input_as_handled()
		if event.is_action_pressed("save_game"): _save()
		else: _load("manual")
		return
	if mode != "world_puzzle": return
	# Chapter 11 owns gameplay input even when its controls are unfocused.
	if story.active_chapter == 11: return
	# A deliberately opened picker keeps normal arrow navigation; otherwise the
	# controlled world owns arrows even if a button retained keyboard focus.
	for child in actions.get_children():
		if child is OptionButton and child.get_popup().visible: return
	var key: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
	# Layout/remote input may report an unrelated physical code for an arrow.
	# Keep physical WASD semantics, but honor the logical navigation key.
	if event.keycode in [KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN]: key = event.keycode
	if story.chapter_capability("controlled_wait_retry") and key in [KEY_SPACE, KEY_R]:
		var focus := get_viewport().gui_get_focus_owner()
		if focus is LineEdit or focus is TextEdit: return
		get_viewport().set_input_as_handled()
		_world_puzzle_input({"type":"wait" if key == KEY_SPACE else "retry"})
		return
	if story.chapter_capability("auto_world_entry") and event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		_world_puzzle_input({"type":"interact"})
		return
	var movement := {KEY_LEFT:[-1,0],KEY_A:[-1,0],KEY_RIGHT:[1,0],KEY_D:[1,0],KEY_UP:[0,-1],KEY_W:[0,-1],KEY_DOWN:[0,1],KEY_S:[0,1]}
	if movement.has(key):
		get_viewport().set_input_as_handled()
		_world_puzzle_input({"type":"move","dx":movement[key][0],"dy":movement[key][1]})

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo:
		return
	if event.is_action_pressed("ui_cancel"):
		if story.active_chapter >= 1:
			if mode in ["menu","journal"]: _advance_chapter()
			elif mode not in ["chapter_action","ending"]: _show_menu()
			return
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
	if mode == "world_puzzle":
		var movement := {"move_left":[-1,0],"move_right":[1,0],"move_up":[0,-1],"move_down":[0,1]}
		for action in movement:
			if event.is_action_pressed(action):
				_world_puzzle_input({"type":"move","dx":movement[action][0],"dy":movement[action][1]})
				get_viewport().set_input_as_handled()
				return
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
	elif mode in ["dialogue", "chapter_dialogue"] and event.is_action_pressed("interact"):
		_next_line()

func _interact() -> void:
	if story.active_chapter >= 1:
		_chapter_interact()
		return
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
	if mode not in ["dialogue", "chapter_dialogue"]:
		return
	line_index += 1
	if line_index >= lines.size():
		_finish_lines()
	else:
		_show_line()

func _finish_lines() -> void:
	if mode == "chapter_dialogue":
		_chapter_completed(story.finish_dialogue(chapter_token))
		return
	if mode not in ["dialogue", "chapter_dialogue"]:
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
	if story.active_chapter >= 1:
		_advance_chapter()
		return
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

func _save_hotkey_supported() -> bool:
	if mode in ["menu","explore","chapter_recollection"]: return true
	if mode == "ending" and story.state.finished: return true
	return story.chapter_capability("checkpoint_inputs") and mode in ["world_puzzle","chapter_puzzle","chapter_battle"]

func _show_save_hotkey_feedback(message: String) -> void:
	save_hotkey_feedback_text.text = message
	save_hotkey_feedback.show()
	_layout()

func _save() -> void:
	chapter_ten_recollection.elapsed = 0.0
	chapter_eleven_world_ui.cancel_input()
	chapter_ten_world_ui.set_focused(false)
	chapter_ten_world_ui.set_focused(true)
	var save_position: Vector2 = chapter_ten_recollection.saved_position(world.player.position)
	story.state.position = [save_position.x,save_position.y]
	var error := saves.save_game(story)
	notice.text = "已保存到手动槽位" if error.is_empty() else error
	_show_save_hotkey_feedback("上次手动保存 "+Time.get_time_string_from_system()+"："+notice.text if error.is_empty() else notice.text)
	_show_menu_save_feedback()

func _show_menu_save_feedback() -> void:
	if mode == "menu" and is_instance_valid(menu_save_feedback):
		menu_save_feedback.text = notice.text
		menu_save_feedback.show()

func _load(slot: String) -> void:
	chapter_eleven_world_ui.cancel_input()
	chapter_ten_world_ui.set_focused(false)
	chapter_ten_world_ui.set_focused(true)
	_stop_registered_puzzle_demonstration()
	_stop_horse_wait()
	var error := saves.load_game(story,slot)
	if error.is_empty():
		_load_scene()
		notice.text = "已读取存档"
	else:
		notice.text = error
		_show_menu_save_feedback()

func _show_menu(initial: bool = false) -> void:
	chapter_ten_recollection.reset(self)
	_cancel_physical_navigation()
	chapter_eleven_world_ui.cancel_input()
	chapter_ten_world_ui.set_focused(false)
	chapter_ten_world_ui.set_focused(true)
	_stop_registered_puzzle_demonstration()
	_stop_horse_wait()
	if story.chapter_capability("checkpoint_inputs") and mode in ["world_puzzle","chapter_puzzle","chapter_battle"]:
		if not _checkpoint_auto(): return
	if mode == "world_puzzle": _sync_controlled_world({})
	chapter_eleven_world_ui.reset()
	chapter_ten_world_ui.reset()
	mode = "menu"
	menu_save_allowed = not initial
	_modal_title("昆 仑", "钓鱼烽火 · 孤云出岫 · 天机求学 · 灵台惊变 · 江南花柳 · 纯阳之秘\n原生 Godot RPG · 逐章开发版\n手工像素占位 / 无配音音乐 / 章节演出仍在制作\nWASD 或方向键行走，E 调查，J 记事，F5 保存，F9 读档。")
	menu_save_feedback = Label.new()
	menu_save_feedback.name = "menu_save_feedback"
	menu_save_feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	menu_save_feedback.hide()
	modal_content.add_child(menu_save_feedback)
	_button("开始行旅" if initial else "返回行旅",_cancel_choice,modal_content)
	_button("读取手动存档",_load.bind("manual"),modal_content)
	_button("读取章节自动存档",_load.bind("auto"),modal_content)
	if not initial:
		_button("保存当前行旅",_save,modal_content)
		if (story.active_chapter == 2 or story.chapter_capability("optional_window_view")) and story.state.scope != "main" and story.current_event().get("op")!="objective_battle":
			_button("暂缓这段约定，回到主线",_pause_optional,modal_content)
	if not initial and story.chapter_capability("leader_selection"):
		for id in story.current_chapter_runtime().available_leaders():
			if id!=story.state.leader_id:_button("改由"+story.actors[id].get("name",{"char_liang_xiao":"梁萧","char_liu_yingying":"柳莺莺","char_axue":"阿雪"}.get(id,id))+"领路",_switch_leader.bind(id),modal_content)
	_button("重新开始…",_confirm_restart,modal_content)
	_button("退出",get_tree().quit,modal_content)

func _switch_leader(id: String) -> void:
	if story.current_chapter_runtime().switch_leader(id):
		var error:=saves.save_game(story,"auto")
		_advance_chapter()
		if error!="":notice.text=error

func _confirm_restart() -> void:
	mode = "confirm"
	_modal_title("重新开始？","当前未保存进度将丢失。手动存档仍保留，后续场次自动保存会更新自动槽。")
	_button("确认重新开始",_restart,modal_content)
	_button("取消",_show_menu,modal_content)

func _restart() -> void:
	story.reset()
	_load_scene()

func _show_journal() -> void:
	if story.active_chapter >= 1:
		_show_campaign_journal()
		return
	mode = "journal"
	var body := "主线 MQ-00 · %s\n%s\n完成场次 %d / %d\n行囊：%s\n相处记事：\n" % [story.state.quest_phase,story.scene().objective,story.state.completed.size(),content.scenes.size(),"、".join(story.state.inventory)]
	for id in story.state.completed:
		for entry in content.scenes:
			if entry.id == id:
				body += "• " + entry.title + "：" + entry.choices[int(story.state.choices[id])].text + "\n"
	_modal_title("行旅记事",body)
	_button("返回 [Esc]",_cancel_choice,modal_content)

func _show_ending() -> void:
	if story.chapter_capability("ending_title","")!="":
		mode = "ending"
		_modal_title(story.chapter_capability("ending_title"),story.chapter_capability("ending_body"))
		var next:int=story.chapter_capability("next_chapter",0)
		if next>0:_button("继续第%02d章"%next,_enter_registered_chapter.bind(next),modal_content)
		_button("保存行旅",_save,modal_content)
		_button("查看记事",_show_journal,modal_content)
		_button("返回标题",_show_menu.bind(true),modal_content)
		return
	if story.active_chapter == 2:
		mode = "ending"
		_modal_title("可恃唯我", "九算已通，第十算仍留一道空白。梁萧收好清心砚，带着猴犬迎向清晨。\n第02章行旅已归档，可继续药王茶叙与灵台惊变。")
		_button("继续第03章 · 灵台惊变",_enter_chapter_three,modal_content)
		_button("保存行旅",_save,modal_content)
		_button("查看记事",_show_journal,modal_content)
		_button("返回标题",_show_menu.bind(true),modal_content)
		return
	if story.active_chapter == 1:
		mode = "ending"
		_modal_title("孤云出岫", "梁萧抱着幼犬向东方走去。父亲留在荒岗，母亲仍在北方。\n梁文残碑上，第三个字仍然空着。\n\n第01章流程已归档。可继续进入第02章天机求学。")
		_button("继续第02章 · 天机求学",_enter_chapter_two,modal_content)
		_button("保存行旅",_save,modal_content)
		_button("查看记事",_show_journal,modal_content)
		_button("返回标题",_show_menu.bind(true),modal_content)
		return
	mode = "ending"
	_modal_title("江雾初敛", "文靖留下九龙玉令，与玉翎泛舟东下。\n记事已归档：放下胡汉成见，结庐相守。\n\n序章流程收束。可继续进入十年后的第01章《孤云出岫》。\n这里不是全游戏通关；当前也未达到策划45分钟的序章内容与成品演出标准。")
	_button("十年后 · 继续第01章",_enter_chapter_one,modal_content)
	_button("保存行旅",_save,modal_content)
	_button("查看记事",_show_journal,modal_content)
	_button("返回标题",_show_menu.bind(true),modal_content)

# Chapter event presentation. Only the campaign/controller can settle these steps.
func _enter_registered_chapter(id: int) -> void:
	if not story.enter_registered_chapter(id):return
	var error:=saves.save_game(story,"auto")
	_load_scene()
	if error!="":notice.text=error

func _enter_chapter_one() -> void:
	if not story.enter_chapter_one(): return
	var error := saves.save_game(story,"auto")
	_load_scene()
	notice.text = "十年后 · 白水湾" if error == "" else error

func _load_chapter_scene() -> void:
	var p: Array = story.state.position
	var spawn := Vector2(p[0],p[1]) if float(p[0]) >= 0 else Vector2.INF
	var context := story.world_context()
	context["path_progress"] = context.get("path_progress",story.state.path_progress).duplicate()
	world.configure(story.scene(),spawn,context)
	header.text = "昆仑 / 第%02d章 · " % story.active_chapter + story.scene().title
	objective.text = story.scene().objective
	_advance_chapter()

func _advance_chapter() -> void:
	chapter_ten_recollection.reset(self)
	chapter_eleven_world_ui.reset()
	chapter_ten_world_ui.reset()
	_stop_horse_wait()
	if story.chapter_capability("controlled_world"): _sync_controlled_world({})
	if story.state.finished:
		_show_ending()
		return
	dialogue_panel.hide()
	modal.hide()
	world.player.enabled = false
	world.set_runtime_context(story.world_context())
	var event := story.current_event()
	chapter_token = story.current_token()
	objective.text = event.get("name",story.scene().objective)
	if chapter_ten_recollection.offer(self,event):return
	match event.op:
		"dialogue", "stage", "branch_feedback", "conditional_echoes", "chapter_echo":
			lines = story.dialogue_lines()
			line_index = 0
			active_scene_id = story.scene().id
			mode = "chapter_dialogue"
			dialogue_panel.show()
			_show_line()
		"action":
			mode = "explore"
			world.player.enabled = true
		"choice": _show_chapter_choices()
		"quest_window": _show_optional_window()
		"puzzle":
			mode = "explore"
			world.player.enabled = true
		"world_puzzle":
			if story.chapter_capability("auto_world_entry") or story.state.puzzle_records.has(chapter_token): _show_world_puzzle()
			else:
				mode = "explore"
				world.player.enabled = true
		"branch_practice": _show_registered_puzzle()
		"objective_battle":
			encounter_session = story.current_chapter_runtime().make_objective_encounter()
			battle_error = ""
			_show_chapter_battle()
		"battle":
			encounter_session = story.make_encounter()
			battle_error = ""
			_show_chapter_battle()
		"trial":
			three_move_trial = Trial.new()
			_show_three_moves()

func _chapter_completed(ok: bool) -> void:
	if not ok:
		notice.text = "此行动还未满足当前步骤，进度未改变。"
		return
	if world.scene_data.id == story.scene().id:
		story.state.position = [world.player.position.x,world.player.position.y]
	var error := saves.save_game(story,"auto")
	if error != "": notice.text = error
	if world.scene_data.id != story.scene().id: _load_chapter_scene()
	else: _advance_chapter()

func _chapter_interact() -> void:
	var event := story.current_event()
	if story.active_chapter >= 2 and event.get("op","") in ["puzzle","branch_practice","world_puzzle"]:
		var geometry := world.get_objective_geometry(event.get("entry_id",event.get("id","")))
		if story.current_chapter_runtime().puzzle_definition().id == "shadow_practice" or (not geometry.is_empty() and world.player.position.distance_to(geometry.position) <= float(geometry.radius)):
			if event.op == "world_puzzle": _show_world_puzzle()
			else: _show_registered_puzzle()
		return
	if event.get("op","") != "action": return
	var point := world.nearest()
	if point.is_empty() or point.get("action_id","") != event.id: return
	var geometry := world.get_objective_geometry(event.id)
	if geometry.is_empty() or world.player.position.distance_to(geometry.position) > float(geometry.radius): return
	if story.active_chapter==8 and event.id=="ch08_passive_loadout":
		_show_ch08_loadout()
		return
	match event.kind:
		"glyph":
			mode = "chapter_glyph"
			var help := "按顺序写下这一字。鼠标依次点绿色起点、金色终点；或用方向键移动笔尖、Enter起落笔。"
			if story.scene().id == "ch01_unfinished_tombstone": help += "\n梁萧记得梁、文的笔画，第三字仍然想不起来。"
			_modal_title(event.name,help)
			var board := WritingBoard.new()
			board.setup(event.glyph)
			modal_content.add_child(board)
			board.completed.connect(_glyph_completed.bind(chapter_token,str(event.id)))
			_button("暂歇，返回菜单",_show_menu,modal_content)
			board.grab_focus()
		"work":
			work_counts[chapter_token] = int(work_counts.get(chapter_token,0))+1
			notice.text = "捧土 %d / %d" % [work_counts[chapter_token],event.count]
			if int(work_counts[chapter_token]) >= int(event.count):
				_chapter_completed(story.complete_action(chapter_token,event.id,{"count":int(event.count)}))
		"route":
			var proof := world.get_path_progress(event.id)
			proof.merge(_world_action_proof())
			if proof.complete: _chapter_completed(story.complete_action(chapter_token,event.id,proof))
			else: notice.text = "沿路前行，尚有一段没有走到。"
		"projectile": _perform_bean(chapter_token,event.id,geometry.position)
		_: _chapter_completed(story.complete_action(chapter_token,event.id,_world_action_proof()))

func _glyph_completed(proof: Dictionary, token: String, id: String) -> void:
	_chapter_completed(story.complete_action(token,id,proof))
func _perform_bean(token: String, id: String, target: Vector2) -> void:
	mode = "chapter_action"
	world.player.enabled = false
	var bead := ColorRect.new()
	bead.color = Color("d7ba75")
	bead.size = Vector2(2,2)
	bead.position = world.player.position+Vector2(0,-19)
	bead.z_index = 20
	world.add_child(bead)
	var tween := create_tween()
	tween.tween_property(bead,"position",target+Vector2(0,-8),0.3)
	await tween.finished
	bead.queue_free()
	_chapter_completed(story.complete_action(token,id))

func _show_chapter_choices() -> void:
	mode = "chapter_choice"
	_modal_title("此刻的回应","选择会被记住，后续回响只使用实际取得的物品。")
	for choice in story.available_choices():
		_button(choice.get("text",choice.get("label","抉择")),_chapter_choose.bind(str(choice.id),chapter_token),modal_content)
	_button("暂且想想，返回菜单",_show_menu,modal_content)
func _chapter_choose(id: String, token: String) -> void:
	if mode != "chapter_choice" or token != story.current_token(): return
	for choice in story.available_choices():
		if choice.id == id:
			mode = "chapter_feedback"
			_modal_title("余音",choice.get("feedback", "这一念留在行旅中。"))
			_button("继续",_commit_chapter_choice.bind(token,id),modal_content)
			return
func _commit_chapter_choice(token: String,id: String) -> void:
	_chapter_completed(story.choose(token,id))

func _show_chapter_battle() -> void:
	mode = "chapter_battle"
	_modal_title(encounter_session.encounter.name,str(encounter_session.encounter.get("description","观察公开意图，编排行动。浑天仪借力需亲自走到把手、对齐铜环，再把握蓄力窗口。"))+ ("\n"+battle_error if battle_error != "" else ""))
	var panel = load("res://scripts/ui/objective_battle_panel.gd").new() if story.active_chapter >= 2 else CombatPanel.new()
	if story.chapter_capability("compact_battle_panel","") != "":
		# The registered panel owns its compact heading/status; avoid duplicate modal chrome at 640×360.
		_clear(modal_content)
		panel.free()
		panel = load(story.chapter_capability("compact_battle_panel","")).new()
	modal_content.add_child(panel)
	var view: Dictionary = encounter_session.get_view()
	if story.chapter_capability("battle_world_presentation"):
		var background:Dictionary=story.current_chapter_runtime().battle_presentation(view)
		if not background.is_empty() and world.scene_data.id!=background.id:
			# Presentation follows the validated session; neither navigation nor battle state is advanced.
			world.configure(background,world.player.position,story.world_context())
			world.player.enabled=false
		if story.active_chapter in [7,8,9,10,11] and view.get("world_state") is Dictionary:
			world.sync_controlled_view(view)
	view["input_error"] = battle_error
	view["save_policy"] = "每轮结算/暂歇自动保存；编排中可F5保存、F9读档。"
	var skill_data: Dictionary = view.get("skill_data",story.combat.skills)
	view["skill_costs"] = {}
	for actor in view.actors:
		if actor.team != "party": continue
		view.skill_costs[actor.id] = {}
		for skill in actor.skills:
			view.skill_costs[actor.id][skill] = encounter_session.engine.skill_cost(actor,skill_data[skill])
	panel.render(view,skill_data,encounter_session.can_resolve())
	if story.active_chapter in [9,10,11]:
		# Removed battle panels must not control a newly loaded/retried scene.
		var born_session:RefCounted=encounter_session
		var born_token:String=story.current_token()
		var current_panel:Callable=func()->bool:return is_instance_valid(panel) and panel.is_inside_tree() and panel.is_visible_in_tree() and mode=="chapter_battle" and encounter_session==born_session and story.current_token()==born_token
		panel.command_requested.connect(func(actor:String,skill:String,target:String,revision:int):
			if current_panel.call():_chapter_command(actor,skill,target,revision))
		panel.resolve_requested.connect(func():
			if current_panel.call():_chapter_resolve())
		panel.retry_requested.connect(func():
			if current_panel.call():_chapter_retry())
		panel.continue_requested.connect(func():
			if current_panel.call():_chapter_battle_finish())
		panel.leave_requested.connect(func():
			if current_panel.call():_show_menu())
		panel.input_submitted.connect(func(action:Dictionary):
			if current_panel.call():_objective_input(action))
	else:
		panel.command_requested.connect(_chapter_command)
		panel.resolve_requested.connect(_chapter_resolve)
		panel.retry_requested.connect(_chapter_retry)
		panel.continue_requested.connect(_chapter_battle_finish)
		panel.leave_requested.connect(_show_menu)
		if story.active_chapter >= 2: panel.input_submitted.connect(_objective_input)
func _chapter_command(actor: String,skill: String,target: String,revision: int) -> void:
	if mode != "chapter_battle": return
	var error: String = encounter_session.set_command(actor,skill,target,revision)
	_persist_objective_checkpoint()
	battle_error = {"cooldown":"此招仍在调息。","insufficient_mp":"真气不足，可用普攻或自守回气。","stale_revision":"局面已经改变，请重新编排行动。"}.get(error,error)
	_show_chapter_battle()
func _chapter_resolve() -> void:
	if mode != "chapter_battle" or not encounter_session.resolve_round(): return
	_persist_objective_checkpoint(true)
	battle_error = ""
	_show_chapter_battle()
func _chapter_retry() -> void:
	if mode != "chapter_battle": return
	encounter_session.retry()
	_persist_objective_checkpoint(true)
	_show_chapter_battle()
func _chapter_battle_finish() -> void:
	if mode != "chapter_battle": return
	_chapter_completed(story.current_chapter_runtime().accept_objective(chapter_token,encounter_session.receipt()) if story.active_chapter >= 2 else story.finish_encounter(chapter_token,encounter_session))

func _show_three_moves() -> void:
	mode = "chapter_trial"
	var phase := mini(three_move_trial.moves,2)
	var body := "文靖固定 Lv.15，三招只争圈线，不以击空气血取胜。\n先看肩肘虚实，再选进步方向。"
	if three_move_trial.observed: body += "\n"+str(Trial.CLUES[phase].text)
	if three_move_trial.direction != "": body += "\n已选步位："+{"west":"左侧","east":"右侧","north":"中路"}[three_move_trial.direction]
	_modal_title("画地三招 · 第 %d 招" % [phase+1],body)
	if three_move_trial.failed:
		var failed := Label.new()
		failed.text = "步位失当，掌风将文靖逼退。重试回到交锋之前。"
		failed.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		modal_content.add_child(failed)
		_button("重新审势",_retry_three_moves,modal_content)
	else:
		_button("观其肩肘",_trial_observe,modal_content)
		for direction in ["west","east","north"]:
			_button({"west":"踏向左侧","east":"踏向右侧","north":"中路进半步"}[direction],_trial_step.bind(direction),modal_content)
		var strike := _button("出掌引势",_trial_strike,modal_content)
		strike.disabled = not three_move_trial.observed or three_move_trial.direction == ""
	_button("暂歇，返回菜单",_show_menu,modal_content)
func _trial_observe() -> void:
	three_move_trial.observe()
	_show_three_moves()
func _trial_step(direction: String) -> void:
	three_move_trial.step(direction)
	_show_three_moves()
func _trial_strike() -> void:
	three_move_trial.strike()
	if not three_move_trial.receipt().is_empty(): _chapter_completed(story.finish_trial(chapter_token,three_move_trial))
	else: _show_three_moves()
func _retry_three_moves() -> void:
	three_move_trial = Trial.new()
	_show_three_moves()

func _show_campaign_journal() -> void:
	mode = "journal"
	var actor: Dictionary = story.current_chapter_runtime().actor_panel("char_liang_xiao") if story.chapter_capability("effective_party_panels") else story.actors.char_liang_xiao
	var body := "第%02d章 · %s\n梁萧 Lv.%d  经验 %d / 下一等级 %d\n气血 %d / %d\n\n同行与离散\n" % [story.active_chapter,story.scene().title,actor.level,actor.xp,Progression.threshold(mini(actor.level+1,80)),actor.hp,actor.max_hp]
	var statuses := {"present":"同行","taken_north":"被带往北方，仍在人世","dead":"已故","follower":"跟随（不参战）","not_adopted":"尚未相伴","sheltered_with_xiaoshuang":"留守晓霜身边（不参战）"}
	for id in ["char_liang_wenjing","char_xiao_yuling","follower_baichier"]:
		body += {"char_liang_wenjing":"梁文靖","char_xiao_yuling":"萧玉翎","follower_baichier":"白痴儿"}[id]+"："+statuses.get(story.actors[id].status,story.actors[id].status)+"\n"
	if story.active_chapter >= 2:
		body += "花晓霜："+{"story_support":"剧情同行（不参战）","absent_safe":"已安全离开石阵","visits_restricted":"被隔离，仍在人世","sheltered":"藏身古树洞","separated_not_dead":"失散牵挂，仍在人世"}.get(story.actors.char_hua_xiaoshuang.status,story.actors.char_hua_xiaoshuang.status)+"\n"
		body += "金灵儿："+statuses.get(story.actors.follower_jinlinger.status,story.actors.follower_jinlinger.status)+"\n"
		if story.chapter_capability("leader_selection") and story.actors.has("char_liu_yingying"):
			body += "\n"+("当前同行年岁" if story.actors.char_liu_yingying.status=="active" else "核心角色年岁")+"：梁萧%d / 柳莺莺%d  铜钱%d\n" % [story.state.liang_age,story.actors.char_liu_yingying.age,story.state.coins]
			body += "牵挂记事：花晓霜%d岁，未在当前队伍中。\n" % story.state.xiaoshuang_age
		else:
			body += "\n年岁：梁萧%d / 晓霜%d  铜钱%d\n" % [story.state.liang_age,story.state.xiaoshuang_age,story.state.coins]
		body += "观势察机 Lv.%d；九算天资：%s\n" % [actor.skill_ranks.LX_A01,"已领悟" if "LX_P01" in actor.passives else "未领悟"]
		for quest in story.current_chapter_runtime().content.side_quests:
			body += quest.title+"："+{"undiscovered":"未发现","accepted":"已接取","investigating":"勘查中","choice_recorded":"已记方法","executing":"执行中","aftermath":"余波","archived":"已归档","missed":"已错过"}.get(story.state.optional[quest.id].status,story.state.optional[quest.id].status)+"\n"
	if story.chapter_capability("leader_selection") and story.actors.has("char_liu_yingying"):
		var liu:Dictionary=story.actors.char_liu_yingying
		body+="\n柳莺莺 Lv.%d · 经验%d · 年岁%d\n气血%d/%d · 真气%d/%d\n"%[liu.level,liu.xp,liu.age,liu.hp,liu.max_hp,liu.mp,liu.max_mp]
	if story.chapter_capability("effective_party_panels"):
		body += story.current_chapter_runtime().party_journal_text()
	if story.chapter_capability("leader_selection"):
		var purse:Dictionary=story.items.get("item_ch04_pouch",{})
		body+="钱袋托管%d铜 · %s；取自原余额，交还不新增财物。\n"%[int(purse.get("escrow",0)),{"liang":"梁萧持有","liu":"柳莺莺暂持","returned":"已归还"}.get(purse.get("custody",""),"尚未托管")]
	body += "\n行囊\n"
	for id in story.items:
		if story.items[id].state != "carried": continue
		var title: String = "巴蜀山川行记" if id == "item_bashu_journal" else id
		for item in story.current_content().item_registry:
			if item.id == id: title = "包布长剑" if id == "item_ch01_xuanyuan_sword" else item.name
		if story.items[id].get("form","") == "broken_fragment": title = "染血残砚（同一清心砚残角）"
		body += "• "+title+"\n"
	body += "\n相处记事\n"
	# Chapters ten/eleven store choices by semantic keys, not scene IDs.
	# Display only committed memories; opening the journal never grants a tag.
	if story.active_chapter in [10,11]:
		for group_id in story.current_content().get("choice_groups",{}):
			var group: Dictionary = story.current_content().choice_groups[group_id]
			var choice_key: String = str(group.get("choice_key",group_id))
			if group_id == "choice_ch11_r04_method": choice_key = "r04_method"
			for option in group.options:
				if story.state.choices.get(choice_key,"") == option.id:
					body += "• "+str(group.title)+"："+str(option.label)+"\n"
		var memory_labels := {
			"MEM_MQ10_AXUE_ETERNAL":"阿雪长忆：旧物长留，身旁再无人回应。",
			"MEM_MQ10_QIANTANG_FAREWELL":"魂断钱塘，怒潮卷浪。",
			"MEM_MQ10_TIDE_SURVIVED":"死战待潮：撑过伯颜六轮攻势，借潮离去。",
			"MEM_MQ10_STONE_REBIRTH":"三月破器出新：三石悟势，苦练后初成乘风蹈海。",
			"MEM_MQ10_LAOSHAN_DEPARTURE":"携老北行：与老人启程前往崂山寻医。",
			"MEM_MQ11_HERBAL_REUNION":"杏林重逢：晓霜归来，旧伤与多年牵挂都未被抹去。",
			"MEM_MQ11_QINGXING_LEGACY":"青杏托孤：承接吴常青的医道与青杏卷。",
			"MEM_MQ11_XIAOSHUANG_BOTTOMLINE":"医者止戈：不以折磨偿还折磨，守住不杀的底线。",
			"MEM_R04_TRIAGE_ORDER":"危症先救：辨明轻重缓急，救治院内三位病人。",
			"MEM_MQ11_THREE_COMPANIONS":"古渡同行：梁萧、晓霜与花生相约彼此照应。"
		}
		for tag in memory_labels:
			if tag in story.state.memories: body += "• "+memory_labels[tag]+"\n"
	for entry in story.current_content().scenes:
		for key in story.state.choices:
			if key != entry.id and not str(key).begins_with(entry.id+":"): continue
			for choice in entry.choices+entry.get("additional_choices",[]):
				if choice.id == story.state.choices[key]: body += "• "+entry.title+"："+choice.get("text",choice.get("label",""))+"\n"
	if story.chapter_capability("inherited_optional_journal"):
		body += "\n前章约定\n"
		for id in story.state.inherited_optional:
			body += ("未合算册" if id == "ch02_r01" else "重差测天")+"："+("已归档，奖励只记在前章" if story.state.inherited_optional[id].status == "archived" else "前章未完成")+"\n"
		var abacus: Dictionary = story.items.get("item_ch03_copper_abacus",{})
		if not abacus.is_empty(): body += "铜算盘："+("借用未还" if abacus.state == "carried" else "换质时损毁，借用记录保留")+"\n"
	_modal_title("行旅记事",body)
	if story.active_chapter in [10,11] and story.actors.get("char_axue",{}).get("status","") == "dead":
		var empty_seat := PanelContainer.new()
		empty_seat.name = "axue_empty_seat"
		var frame := StyleBoxFlat.new()
		frame.bg_color = Color("e8e5dc")
		frame.content_margin_left = 14
		frame.content_margin_top = 8
		frame.content_margin_bottom = 8
		empty_seat.add_theme_stylebox_override("panel",frame)
		var memory := Label.new()
		memory.text = "阿雪  ·  空席\n旧针线包还在，身旁已无人回应。"
		memory.add_theme_color_override("font_color",Color("383b3a"))
		memory.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty_seat.add_child(memory)
		modal_content.add_child(empty_seat)
		modal_content.move_child(empty_seat,1)
	_button("返回",_cancel_choice,modal_content)

func _enter_chapter_two() -> void:
	if not story.enter_chapter_two(): return
	var error := saves.save_game(story,"auto")
	_load_scene()
	notice.text = "天机求学 · 庐州城外" if error == "" else error
func _objective_input(action: Dictionary) -> void:
	if mode != "chapter_battle" or story.active_chapter < 2: return
	var result: Dictionary = encounter_session.apply_input(action)
	_persist_objective_checkpoint(story.active_chapter==9 and result.get("accepted",false) and action.get("execute",false))
	battle_error = str(result.get("error",""))
	_show_chapter_battle()
func _show_optional_window() -> void:
	mode = "chapter_window"
	var unfinished := false
	for quest in story.state.optional.values():
		if quest.status != "archived": unfinished = true
	var body := "夜里的错稿与晴日的晷影，未尽的约定还来得及探寻。\n这些约定可暂缓或放下。继续下一段岁月后，未完成的约定不会重新开放。" if unfinished else "算册与测影都已完成，所学与记事已经留下。可以继续下一段岁月了。"
	var window:Dictionary=story.current_chapter_runtime().optional_window_view() if story.chapter_capability("optional_window_view") else {}
	_modal_title(window.get("title","寒窗初年"), window.get("body",body))
	for quest in story.current_chapter_runtime().content.side_quests:
		var status: Dictionary = story.state.optional[quest.id]
		var label := Label.new()
		label.text = quest.title+" · "+{"completed":"已归档","open":"尚未探寻","active":"进行中","deferred":"暂缓","declined":"放下","missed":"已错过"}.get(status.disposition,status.disposition)
		modal_content.add_child(label)
		if status.status != "archived":
			_button("前往 · "+quest.title,_open_optional.bind(quest.id),modal_content)
			_button("暂缓 · "+quest.title,_optional_disposition.bind(quest.id,"deferred"),modal_content)
			_button("放下 · "+quest.title,_optional_disposition.bind(quest.id,"declined"),modal_content)
	_button(window.get("continue","继续下一段岁月…"),_confirm_window_closure,modal_content)
	if story.chapter_capability("reconsider_departure") and story.current_chapter_runtime().can_reconsider_departure():
		_button("返回村中，重看托付",_reconsider_registered_departure,modal_content)

func _reconsider_registered_departure() -> void:
	var rt:RefCounted=story.current_chapter_runtime()
	if rt.reconsider_departure([world.player.position.x,world.player.position.y]):
		var error:=saves.save_game(story,"auto")
		_load_chapter_scene()
		if error!="":notice.text=error

func _open_optional(id: String) -> void:
	story.state.position = [world.player.position.x,world.player.position.y]
	if story.current_chapter_runtime().open_sidequest(id):
		var error := saves.save_game(story,"auto")
		_load_chapter_scene()
		if error != "": notice.text = error
func _optional_disposition(id: String, value: String) -> void:
	if story.current_chapter_runtime().disposition(id,value):
		saves.save_game(story,"auto")
		_show_optional_window()
func _confirm_window_closure() -> void:
	var unfinished := false
	for quest in story.state.optional.values():
		if quest.status != "archived": unfinished = true
	var body := "晓霜不久便不能再来。继续后，尚未完成的算册与测影将记为错过，不影响前路，也不会获得它们的奖励。" if unfinished else "算册与测影都已完成，所学与记事已经留下。准备继续下一段岁月吗？"
	var window:Dictionary=story.current_chapter_runtime().optional_window_view() if story.chapter_capability("optional_window_view") else {}
	_modal_title(window.get("title","灯影将远"), window.get("confirmation",body))
	_button("再留一会儿",_show_optional_window,modal_content)
	_button("继续行旅" if not window.is_empty() else ("记下遗憾，继续行旅" if unfinished else "继续下一段岁月"),func(): _chapter_completed(story.current_chapter_runtime().close_window(chapter_token)),modal_content)
func _pause_optional() -> void:
	_stop_registered_puzzle_demonstration()
	story.state.position = [world.player.position.x,world.player.position.y]
	if story.current_chapter_runtime().pause_sidequest():
		var error := saves.save_game(story,"auto")
		_load_chapter_scene()
		if error != "": notice.text = error
func _show_registered_puzzle() -> void:
	_stop_registered_puzzle_demonstration()
	var session: RefCounted = story.current_chapter_runtime().make_puzzle()
	if session == null:
		notice.text = "这个机关尚未登记，进度未改变。"
		return
	mode = "chapter_puzzle"
	registered_puzzle_epoch += 1
	registered_puzzle_panel = null
	var definition: Dictionary = story.current_chapter_runtime().puzzle_definition()
	var view: Dictionary = session.get_view()
	if story.active_chapter in [9,10,11] and view.get("world_state") is Dictionary:world.sync_controlled_view(view)
	_modal_title(story.current_event().get("name","演练所学"),"观察实物，再动手验证。"+(" 完成/暂歇自动保存；中途F5保存、F9读档。" if story.chapter_capability("checkpoint_inputs") else ""))
	if story.chapter_capability("compact_puzzle_panel"):_clear(modal_content)
	if definition.guided:
		if definition.id in ["jing_writing","name_practice"]:
			var label := Label.new()
			label.text = "本页 · "+view.glyph+"（第%d字）" % [int(view.state.index)+1]
			modal_content.add_child(label)
			var board := WritingBoard.new()
			board.setup(view.glyph)
			modal_content.add_child(board)
			board.completed.connect(func(proof: Dictionary):
				proof["type"] = "glyph"
				_registered_puzzle_input(proof))
			board.grab_focus()
		else:
			var prompts: Array = ["石影先抬肘","第二道影旋腕","第三道影弓步"] if definition.id in ["shadow_practice","step_practice"] else (["先吸气","守住静息","缓缓呼气"] if definition.id == "breath_practice" else ["只选本题散页，信物留下","将散页投入火盆","饮下晓霜的参汤"])
			var label := Label.new()
			label.text = prompts[int(view.state.index)] if view.state.observed else "先观察这一拍的变化。"
			modal_content.add_child(label)
			_button("细看这一拍",_registered_puzzle_input.bind({"type":"observe"}),modal_content)
			var values: Array = ["抬肘","旋腕","弓步"] if definition.id in ["shadow_practice","step_practice"] else (["吸气","静息","呼气"] if definition.id == "breath_practice" else ["选取本题散页","投入火盆","饮下参汤"])
			for value in values:
				var button := _button(value,_guided_perform.bind(value),modal_content)
				button.disabled = not view.state.observed
			if definition.id == "shadow_practice": _button("返回石阵，走到亮起的脚印",_return_to_shadow,modal_content)
	else:
		var panel = load(story.chapter_capability("puzzle_panel","res://scripts/ui/puzzle_panel.gd")).new()
		registered_puzzle_panel = panel
		modal_content.add_child(panel)
		panel.custom_minimum_size.y = maxf(180,minf(380,size.y-180))
		if story.chapter_capability("compact_puzzle_panel"):
			panel.custom_minimum_size.y=maxf(284,minf(size.y-72,modal.size.y-32))
		panel.render(view)
		panel.input_submitted.connect(_registered_panel_input.bind(story.current_token(),registered_puzzle_epoch))
		if panel.has_signal("close_requested"):panel.close_requested.connect(_return_from_puzzle)
	if not story.chapter_capability("compact_puzzle_panel"):
		_button("暂歇，返回行旅",_return_from_puzzle,modal_content)
		if story.state.scope != "main": _button("先回主线，稍后再做",_pause_optional,modal_content)
func _guided_perform(value: String) -> void:
	_registered_puzzle_input({"type":"perform","value":value,"position":[world.player.position.x,world.player.position.y]})
func _return_to_shadow() -> void:
	modal.hide()
	mode = "explore"
	world.player.enabled = true
	var context: Dictionary = story.world_context()
	context["shadow_phase"] = int(story.current_chapter_runtime().make_puzzle().get_view().state.index)
	world.set_runtime_context(context)
func _return_from_puzzle() -> void:
	_stop_registered_puzzle_demonstration()
	if story.chapter_capability("checkpoint_inputs") and not _checkpoint_auto(): return
	if story.current_event().get("op","") == "branch_practice": _show_menu()
	else: _return_to_shadow() if story.current_chapter_runtime().puzzle_definition().id == "shadow_practice" else _advance_chapter()
func _stop_registered_puzzle_demonstration() -> void:
	if is_instance_valid(registered_puzzle_panel) and registered_puzzle_panel.has_method("stop_demonstration"):
		registered_puzzle_panel.stop_demonstration()

func _registered_panel_input(action: Dictionary, token: String, epoch: int) -> void:
	if not is_instance_valid(registered_puzzle_panel) or not registered_puzzle_panel.is_visible_in_tree(): return
	if mode != "chapter_puzzle" or epoch != registered_puzzle_epoch or token != story.current_token(): return
	_registered_puzzle_input(action)

func _registered_puzzle_input(action: Dictionary) -> void:
	var token: String = story.current_token()
	var result: Dictionary = story.current_chapter_runtime().puzzle_input(token,action)
	if story.current_token() != token:
		_chapter_completed(true)
	else:
		var error := "" if story.chapter_capability("checkpoint_inputs") else saves.save_game(story,"auto")
		if is_instance_valid(registered_puzzle_panel) and registered_puzzle_panel.is_inside_tree() and not story.current_chapter_runtime().puzzle_definition().guided:
			var live_view:Dictionary=story.current_chapter_runtime().make_puzzle().get_view()
			registered_puzzle_panel.render(live_view)
			if story.active_chapter in [9,10,11] and live_view.get("world_state") is Dictionary:world.sync_controlled_view(live_view)
		else:
			_show_registered_puzzle()
		notice.text = error if error != "" else str(result.get("message","步骤已记下" if result.get("ok",false) else "再看看当前位置与笔画"))

func _world_action_proof() -> Dictionary:
	return {"map_id":story.scene().map_id,"position":[world.player.position.x,world.player.position.y]} if story.active_chapter >= 2 else {}


func _enter_chapter_three() -> void:
	if not story.enter_chapter_three(): return
	var error := saves.save_game(story,"auto")
	_load_scene()
	notice.text = "灵台惊变 · 药王亭" if error == "" else error

func _persist_objective_checkpoint(write_disk: bool = false) -> void:
	if not story.chapter_capability("battle_snapshot") or encounter_session == null: return
	if story.current_chapter_runtime().save_objective_checkpoint(encounter_session) and write_disk:
		_checkpoint_auto()

func _checkpoint_auto() -> bool:
	var error := saves.save_game(story,"auto")
	if error != "": notice.text = error
	return error == ""

func _world_milestone() -> Dictionary:
	var current: Dictionary = story.current_chapter_runtime().make_puzzle().get_view().world_state
	var marker := {}
	for key in ["stage","observed","corrections","feints","carrying","rests","sheltered","cloak_state","decoy_seen","crossed_fork","animals_safe","captured"]:
		marker[key] = current.get(key)
	return marker.duplicate(true)

var horse_waiting:=false
var horse_wait_elapsed:=0.0
var horse_wait_token:=""
var horse_wait_dispatch:=false
var horse_wait_button:Button
func _stop_horse_wait() -> void:
	horse_waiting=false;horse_wait_elapsed=0.0;horse_wait_token=""
	if is_instance_valid(horse_wait_button):horse_wait_button.text="等胭脂靠近"
func _horse_wait_available() -> bool:
	if mode!="world_puzzle" or not story.chapter_capability("auto_world_entry") or story.current_event().get("id")!="horse_call_and_arrival":return false
	var session:RefCounted=story.current_chapter_runtime().make_puzzle()
	if session==null:return false
	var state:Dictionary=session.get_view().world_state
	return state.get("horse_called",false) and not state.get("horse_arrived",false) and not state.get("complete",false)
func _toggle_horse_wait() -> void:
	if horse_waiting:_stop_horse_wait()
	elif _horse_wait_available():
		horse_waiting=true;horse_wait_elapsed=0.0;horse_wait_token=story.current_token()
	_show_world_puzzle()
func _cancel_horse_wait() -> void:
	_stop_horse_wait()
	_show_world_puzzle()
func _tick_horse_wait(delta: float) -> void:
	if not horse_waiting:return
	if horse_wait_token!=story.current_token() or not _horse_wait_available():_stop_horse_wait();return
	horse_wait_elapsed+=delta
	if horse_wait_elapsed<0.2:return
	# At most one existing legal wait input per frame, never catch up offscreen.
	horse_wait_elapsed=0.0;horse_wait_dispatch=true
	_world_puzzle_input({"type":"wait"})
	horse_wait_dispatch=false
	if not _horse_wait_available():_stop_horse_wait()
func _chapter_eleven_focus_trace(reason: String, event: InputEventKey = null) -> void:
	if OS.get_environment("KUNLUN_FOCUS_TRACE") != "1" or not is_inside_tree(): return
	var host := get_window()
	if host == null: return
	print("KUNLUN_FOCUS_TRACE ",JSON.stringify({"utc":Time.get_datetime_string_from_system(true),"ticks_ms":Time.get_ticks_msec(),"reason":reason,"display_backend":DisplayServer.get_name(),"window_id":host.get_window_id(),"window_has_focus":host.has_focus(),"display_window_is_focused":DisplayServer.window_is_focused(host.get_window_id()),"helper_focused":chapter_eleven_world_ui._focused,"application_focused_cache":ch11_application_focused,"window_focused_cache":ch11_window_focused,"last_application_notification":ch11_last_application_focus,"last_window_notification":ch11_last_window_focus,"keycode":event.keycode if event != null else 0,"physical_keycode":event.physical_keycode if event != null else 0}))

func _chapter_eleven_window_focus(value: bool, source: String) -> void:
	ch11_window_focused = value
	ch11_last_window_focus = source
	chapter_eleven_world_ui.set_focused(ch11_application_focused and ch11_window_focused)
	_chapter_eleven_focus_trace(source)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		_chapter_eleven_window_focus(false,"notification:WM_WINDOW_FOCUS_OUT")
	if what == NOTIFICATION_WM_WINDOW_FOCUS_IN:
		_chapter_eleven_window_focus(true,"notification:WM_WINDOW_FOCUS_IN")
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT:
		chapter_ten_recollection.set_focused(false)
		_cancel_physical_navigation()
		_stop_horse_wait()
		ch11_application_focused = false
		ch11_last_application_focus = "notification:APPLICATION_FOCUS_OUT"
		chapter_eleven_world_ui.set_focused(false)
		_chapter_eleven_focus_trace(ch11_last_application_focus)
		chapter_ten_world_ui.set_focused(false)
	if what==NOTIFICATION_APPLICATION_FOCUS_IN:
		chapter_ten_recollection.set_focused(true)
		chapter_ten_world_ui.set_focused(true)
		ch11_application_focused = true
		ch11_last_application_focus = "notification:APPLICATION_FOCUS_IN"
		chapter_eleven_world_ui.set_focused(ch11_window_focused)
		_chapter_eleven_focus_trace(ch11_last_application_focus)
func _exit_tree() -> void:
	chapter_eleven_world_ui.reset()
	chapter_ten_world_ui.reset()
	_stop_horse_wait()

var world_action_index := 0
func _show_world_puzzle() -> void:
	var session: RefCounted = story.current_chapter_runtime().make_puzzle()
	if session == null:
		notice.text = "这段场景机关尚未登记，进度未改变。"
		return
	mode = "world_puzzle"
	modal.hide()
	dialogue_panel.show()
	world.player.enabled = false
	var view: Dictionary = session.get_view()
	_sync_controlled_world(view)
	if chapter_ten_world_ui.render(self,view):return
	if chapter_eleven_world_ui.render(self,view):return
	speaker.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if story.active_chapter==9 else TextServer.AUTOWRAP_OFF
	speaker.text = view.title
	dialogue_text.text = view.body+"\n阶段达成/暂歇时自动保存；任意步可F5保存、F9读档。"
	_clear(actions)
	var picker := OptionButton.new()
	picker.custom_minimum_size.x = 140
	if story.active_chapter==9:
		picker.fit_to_longest_item=false
		picker.clip_text=true
		picker.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	picker.add_theme_font_size_override("font_size",14)
	for option in view.options: picker.add_item(option.label)
	world_action_index = clampi(world_action_index,0,view.options.size()-1)
	picker.select(world_action_index)
	picker.item_selected.connect(func(index: int): world_action_index = index;_stop_horse_wait())
	actions.add_child(picker)
	_button("执行",func(): _world_puzzle_input(view.options[world_action_index].action),actions)
	if _horse_wait_available():
		horse_wait_button=_button("停止等候" if horse_waiting else "等胭脂靠近",_cancel_horse_wait if horse_waiting else _toggle_horse_wait,actions)
		horse_wait_button.custom_minimum_size.x=130
		horse_wait_button.tooltip_text="每0.2秒推进一相，可随时停止；抵达后仍须亲自交互上马。"
	_button("暂歇",_show_menu,actions)
	get_viewport().gui_release_focus()

func _world_puzzle_input(action: Dictionary) -> void:
	if mode != "world_puzzle": return
	if not horse_wait_dispatch:_stop_horse_wait()
	var token: String = story.current_token()
	var milestone := _world_milestone()
	var session:RefCounted=story.current_chapter_runtime().make_puzzle()
	var result: Dictionary = story.current_chapter_runtime().puzzle_input(token,action)
	if story.current_token() != token:
		if story.chapter_capability("auto_world_entry"):_sync_controlled_world(session.get_view())
		_sync_controlled_world({})
		_chapter_completed(true)
	else:
		var error := saves.save_game(story,"auto") if milestone != _world_milestone() else ""
		_show_world_puzzle()
		notice.text = error if error != "" else str(result.get("message","已记录场景行动"))

func _sync_controlled_world(view: Dictionary) -> void:
	world.call(story.chapter_capability("world_sync_method","sync_escape_view"),view)

# Chapter eight introduces an explicit, capped two-slot choice without altering old saves.
func _show_ch08_loadout() -> void:
	mode="chapter_loadout"
	var actor:Dictionary=story.actors.char_liang_xiao
	_modal_title("格物致知 · 两个被动槽","已学与已装配分开。格物致知只在装配后生效；本章独自作战，护短不因难民或工兵触发。战役中场不能换装。\n当前："+str(actor.equipped_passives))
	var learned:Array=actor.learned_passives
	for i in range(learned.size()):
		for j in range(i+1,learned.size()):
			var names:Dictionary={"LX_P01":"初窥门径","LX_P02":"护短","LX_P03":"格物致知"}
			_button(str(names.get(learned[i],learned[i]))+" ＋ "+str(names.get(learned[j],learned[j])),_ch08_loadout_apply.bind([learned[i],learned[j]]),modal_content)
	_button("保留当前两槽，继续",_ch08_loadout_finish,modal_content)
	_button("暂不确认，返回菜单",_show_menu,modal_content)
func _ch08_loadout_apply(ids:Array) -> void:
	if story.active_chapter!=8 or not story.current_chapter_runtime().set_passive_loadout(ids):return
	_ch08_loadout_finish()
func _ch08_loadout_finish() -> void:
	_chapter_completed(story.complete_action(story.current_token(),"ch08_passive_loadout",_world_action_proof()))
