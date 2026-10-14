extends SceneTree
## Standalone synthetic context only; never touches real campaign inventory/saves.
const Resolver=preload("res://scripts/puzzles/chapter_five_puzzle_resolver.gd")
const PuzzleUI=preload("res://scripts/ui/chapter_five_puzzle_panel.gd")
var model: RefCounted
var panel: VBoxContainer
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size=Vector2i(640,360)
	var args:=OS.get_cmdline_user_args(); var id: String=args[0] if args.size()>0 else "box_ch05_light"
	var fixture: Dictionary={"box_instance":Resolver.BOX,"items":{Resolver.BOX:{"owner":"char_liang_xiao","form":"opened" if id=="box_ch05_reseal" else "sealed"}},"scene_id":"preview_only"}
	model=Resolver.new(); if not model.begin(id,"preview",fixture): push_error("Invalid preview ID/context"); quit(1); return
	var shell:=PanelContainer.new(); shell.position=Vector2(12,12); shell.size=Vector2(616,336)
	var theme:=Theme.new(); theme.default_font=load("res://assets/fonts/kunlun_ui.ttf"); theme.default_font_size=16; shell.theme=theme; root.add_child(shell)
	var scroll:=ScrollContainer.new(); scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED; scroll.follow_focus=true; shell.add_child(scroll)
	panel=PuzzleUI.new(); panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL; scroll.add_child(panel)
	panel.input_submitted.connect(func(a:Dictionary):
		print("Chapter5 preview input ",JSON.stringify(a))
		var result: Dictionary=model.apply_input(a); print("Result ",result.ok)
		panel.render(model.get_view()))
	panel.close_requested.connect(func(): print("Preview close_requested"); quit())
	panel.render(model.get_view())
