extends SceneTree
## Synthetic trusted context, never a real campaign save.
const R=preload("res://scripts/puzzles/chapter_six_puzzle_resolver.gd")
const UI=preload("res://scripts/ui/chapter_six_puzzle_panel.gd")
var model:RefCounted
func _initialize() -> void:call_deferred("run")
static func fixture(id:String,method:String="") -> Dictionary:
	var c:Dictionary={"scene_id":"preview_ch06","items":{},"authorizations":R.AUTH.get(id,[]).duplicate(),"method":method}
	for item in R.MATERIALS.get(id,{}):c.items[item]={"owner":"ch06_workbench","state":"available","quantity":R.MATERIALS[id][item],"form":"preview_material"}
	if c.method.is_empty():c.method="bird" if id=="r03" else "waterwheel"
	return c
func run() -> void:
	root.size=Vector2i(640,360)
	var args:=OS.get_cmdline_user_args();var id:String=args[0] if args.size()>0 else R.IDS[0]
	var method:String=args[1] if args.size()>1 else ""
	model=R.new()
	if not model.begin(id,"preview",fixture(id,method)):push_error("Invalid preview");quit(1);return
	# Reconstruct a legal first-line checkpoint; no state injection or real save.
	if id=="array_ch06_steps" and "--array-checkpoint" in args:
		for action in [{"type":"read_principle"},{"type":"observe_line","line":0},{"type":"verify_line","line":0,"sum":34},{"type":"step_line","line":0,"endpoint":3}]:
			if not model.apply_input(action).ok:push_error("Legal checkpoint failed");quit(1);return
		if not model.restore(JSON.parse_string(JSON.stringify(model.snapshot())),model.context):push_error("Checkpoint replay failed");quit(1);return
		print("Legal line-0 checkpoint restored")
	var shell:=PanelContainer.new();shell.position=Vector2(12,12);shell.size=Vector2(616,336)
	var theme:=Theme.new();theme.default_font=load("res://assets/fonts/kunlun_ui.ttf");theme.default_font_size=16;shell.theme=theme;root.add_child(shell)
	var scroll:=ScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.follow_focus=true;shell.add_child(scroll)
	var panel:=UI.new();panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(panel)
	panel.input_submitted.connect(func(a:Dictionary):print(JSON.stringify(a));var result:Dictionary=model.apply_input(a);print(result.ok);panel.render(model.get_view()))
	panel.close_requested.connect(func():quit())
	panel.render(model.get_view())
