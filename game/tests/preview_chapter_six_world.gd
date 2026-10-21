extends Control
## Independent development preview. No campaign save or reward writes.
const W = preload("res://scripts/world.gd")
const Driver = preload("res://tests/chapter_six_world_driver.gd")
const C = preload("res://scripts/world_actions/chapter_six_world_actions.gd")
var world: KunlunWorld
var session
var text: Label
var maps: Array = []
var index := 0
var mode := -1
var saved := {}
func _ready() -> void:
	for action in ["move_left","move_right","move_up","move_down"]:
		if not InputMap.has_action(action): InputMap.add_action(action)
	maps = JSON.parse_string(FileAccess.get_file_as_string(C.MAP_PATH)).maps.keys()
	var viewport := SubViewport.new(); viewport.size = Vector2i(320,180); viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var container := SubViewportContainer.new(); container.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST; container.scale = Vector2(3,3); container.position = Vector2(160,0)
	add_child(container); container.add_child(viewport)
	world = W.new(); viewport.add_child(world)
	text = Label.new(); text.position = Vector2(24,546); text.size = Vector2(1232,164); text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; text.add_theme_font_size_override("font_size",18)
	if ResourceLoader.exists("res://assets/fonts/kunlun_ui.ttf"): text.add_theme_font_override("font",load("res://assets/fonts/kunlun_ui.ttf"))
	add_child(text); _load_map()
func _load_map() -> void:
	session = null; mode = -1
	world.configure({"id":"ch06_preview","map_id":maps[index],"cast":["梁萧","阿雪"]},Vector2.INF,{"actor_appearances":{"char_liang_xiao":"youth_age_18","char_axue":"youth_age_16"},"present_actor_ids":["char_axue"]})
	_update_text()
func _load_objective() -> void:
	mode = (mode+1)%C.IDS.size(); session = C.new(); session.begin(C.IDS[mode],"preview",Driver.preview_context(C.IDS[mode]))
	index = maps.find(session.map_id)
	world.configure({"id":session.scene_id,"map_id":session.map_id,"cast":["梁萧","阿雪"]},Vector2.INF,{"actor_appearances":{"char_liang_xiao":"youth_age_18","char_axue":"youth_age_16"}})
	world.player.enabled = false; world.sync_controlled_view(session.get_view()); _update_text()
func _update_text() -> void:
	text.text = "华山故居9图 · 开发占位预览（非最终美术）　[ / ] 换图　Tab下一空间目标\nWASD/方向行走　E操作　O观察　Space等候　R重试　F5/F9内存快照\n"
	text.text += session.get_view().body if session else str(world.layout.get("name",maps[index]))+"　自由探索；浅水半速，深水/墙不可通行。"
func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	var key: int = event.physical_keycode
	if key in [KEY_BRACKETLEFT,KEY_BRACKETRIGHT]: index = posmod(index + (1 if key==KEY_BRACKETRIGHT else -1),maps.size()); _load_map(); return
	if key == KEY_TAB: _load_objective(); return
	var d := {KEY_W:Vector2.UP,KEY_UP:Vector2.UP,KEY_S:Vector2.DOWN,KEY_DOWN:Vector2.DOWN,KEY_A:Vector2.LEFT,KEY_LEFT:Vector2.LEFT,KEY_D:Vector2.RIGHT,KEY_RIGHT:Vector2.RIGHT}
	if session:
		var action := {}
		if d.has(key): action = {"type":"move","dx":int(d[key].x),"dy":int(d[key].y)}
		elif key == KEY_E: action = {"type":"interact"}
		elif key == KEY_O: action = {"type":"inspect"}
		elif key == KEY_G: action = {"type":"guard"}
		elif key == KEY_SPACE: action = {"type":"wait"}
		elif key == KEY_R: action = {"type":"retry"}
		elif key == KEY_F5: saved = session.snapshot()
		elif key == KEY_F9 and not saved.is_empty(): session.restore(saved,session.context)
		if not action.is_empty(): session.apply_input(action)
		world.sync_controlled_view(session.get_view()); _update_text()
	else:
		# Preview binds real InputMap actions for free movement; releases handled below.
		pass
func _input(event: InputEvent) -> void:
	if not event is InputEventKey: return
	var bindings := {KEY_W:"move_up",KEY_UP:"move_up",KEY_S:"move_down",KEY_DOWN:"move_down",KEY_A:"move_left",KEY_LEFT:"move_left",KEY_D:"move_right",KEY_RIGHT:"move_right"}
	if bindings.has(event.physical_keycode):
		if event.pressed: Input.action_press(bindings[event.physical_keycode])
		else: Input.action_release(bindings[event.physical_keycode])
