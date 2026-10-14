extends SceneTree
## Explicit visual candidate harness; does not touch campaign saves or issue campaign rewards.
## Args: medicine / lingtai / shadow / abacus / decoy. Arrow keys single-step encounter.
const Escape = preload("res://scripts/world_actions/shadow_escape.gd")
var world: KunlunWorld
var session
var status: Label
var buttons: GridContainer
var mode := "shadow"
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var args := OS.get_cmdline_user_args()
	mode = args[0] if args.size() else "shadow"
	for action in ["move_left","move_right","move_up","move_down"]:
		if not InputMap.has_action(action): InputMap.add_action(action)
	var bindings := {"move_left":[KEY_LEFT,KEY_A],"move_right":[KEY_RIGHT,KEY_D],"move_up":[KEY_UP,KEY_W],"move_down":[KEY_DOWN,KEY_S]}
	for action in bindings:
		for key in bindings[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action,event)
	root.size = Vector2i(1280,900)
	root.title = "Kunlun chapter 3 candidate spatial QA — " + mode
	var viewport := SubViewport.new()
	viewport.size = Vector2i(320,180)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	world = KunlunWorld.new()
	viewport.add_child(world)
	var map_id: String = {"medicine":"map_ch03_medicine_pavilion","lingtai":"map_ch03_lingtai","shadow":"map_ch03_assassin_array","abacus":"map_ch03_assassin_array","decoy":"map_ch03_forest_road"}.get(mode,"map_ch03_assassin_array")
	world.configure({"id":"ch03_preview","map_id":map_id,"cast":[]},Vector2.INF,{"actor_appearances":{"char_liang_xiao":"youth_age_16","char_hua_xiaoshuang":"youth_age_15"},"controller_id":"char_liang_xiao","present_actor_ids":["char_hua_xiaoshuang","char_ming_gui","follower_baichier","follower_jinlinger"],"follower_actor_ids":[]})
	var screen := TextureRect.new()
	screen.texture = viewport.get_texture()
	screen.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	screen.position = Vector2(0,0)
	screen.size = Vector2(1280,720)
	root.add_child(screen)
	var panel := VBoxContainer.new()
	panel.position = Vector2(12,530)
	panel.size = Vector2(1256,360)
	var theme := Theme.new()
	theme.default_font = load("res://assets/fonts/kunlun_ui.ttf")
	theme.default_font_size = 18
	panel.theme = theme
	root.add_child(panel)
	status = Label.new()
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.custom_minimum_size = Vector2(1256,90)
	panel.add_child(status)
	buttons = GridContainer.new()
	buttons.columns = 6
	panel.add_child(buttons)
	if mode in ["shadow","abacus","decoy"]:
		session = Escape.new()
		session.begin(Escape.DECOY if mode == "decoy" else Escape.SHADOW,"preview",{"padding":"abacus" if mode == "abacus" else "inkstone"})
		refresh()
	else:
		status.text = "开发候选地图，非最终美术。方向键或WASD自由行走；Esc退出。"
	root.connect("window_input",on_input)
func on_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	if event.keycode == KEY_ESCAPE: quit(); return
	if session == null: return
	var directions := {KEY_LEFT:Vector2.LEFT,KEY_RIGHT:Vector2.RIGHT,KEY_UP:Vector2.UP,KEY_DOWN:Vector2.DOWN}
	if directions.has(event.keycode):
		var d: Vector2 = directions[event.keycode]
		send({"type":"move","dx":int(d.x),"dy":int(d.y)})
	elif event.keycode == KEY_SPACE: send({"type":"wait"})
func send(action: Dictionary) -> void:
	session.apply_input(action)
	refresh()
func refresh() -> void:
	var view: Dictionary = session.get_view()
	world.sync_escape_view(view)
	status.text = view.title + " · " + view.body
	for child in buttons.get_children():
		buttons.remove_child(child)
		child.queue_free()
	for entry in view.options:
		var button := Button.new()
		button.text = entry.label
		button.custom_minimum_size = Vector2(198,44)
		button.pressed.connect(send.bind(entry.action))
		buttons.add_child(button)
