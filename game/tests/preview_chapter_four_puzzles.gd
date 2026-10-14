extends SceneTree
## Standalone visual QA, no campaign writes or reward state.
const Resolver = preload("res://scripts/puzzles/chapter_four_puzzle_resolver.gd")
const PuzzleUI = preload("res://scripts/ui/puzzle_panel.gd")
var panel: PanelContainer
var resolver: RefCounted
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size=Vector2i(640,360)
	panel=PuzzleUI.new(); panel.position=Vector2(12,12); panel.size=Vector2(616,336)
	var theme := Theme.new(); theme.default_font=load("res://assets/fonts/kunlun_ui.ttf"); theme.default_font_size=16; panel.theme=theme
	root.add_child(panel)
	var args := OS.get_cmdline_user_args()
	resolver=Resolver.new(args[0] if args.size()>0 else "trial_ch04_staff")
	panel.input_submitted.connect(func(a: Dictionary):
		print("Puzzle UI input: ",JSON.stringify(a))
		var result: Dictionary = resolver.apply_input(a)
		print("Puzzle UI result: ",result.ok)
		panel.render(resolver.get_view()))
	panel.close_requested.connect(func(): print("Puzzle preview close_requested"); quit())
	panel.render(resolver.get_view())
	if "--capture" in args:
		for i in range(9): resolver.apply_input({"type":"place_batch","batch":i})
		panel.render(resolver.get_view())
		await process_frame; await process_frame
		panel._scroll.scroll_vertical=180
		await process_frame; await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/kunlun_ch04_puzzle_640.png")
		quit()
