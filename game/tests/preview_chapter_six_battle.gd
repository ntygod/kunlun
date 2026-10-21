extends SceneTree
const Campaign=preload("res://scripts/campaign/campaign_state.gd")
const Session=preload("res://scripts/combat/chapter_six_encounter.gd")
const BattleUI=preload("res://scripts/ui/chapter_six_battle_panel.gd")
var session: RefCounted
var panel: VBoxContainer
func _initialize():call_deferred("run")
func render():panel.render(session.get_view(),session.runtime.skills,session.can_resolve())
func run():
	root.size=Vector2i(640,360)
	var c=Campaign.new(JSON.parse_string(FileAccess.get_file_as_string("res://data/prologue.json")))
	var source=JSON.parse_string(FileAccess.get_file_as_string("res://../output/cache/chapter_five_gui/manual_natural_final.json"))
	if c.restore_persisted(source)!="":quit(2);return
	var args=OS.get_cmdline_user_args();var kind=args[0] if args.size()>0 else "white_plum"
	var party=c.current_chapter_runtime().combat_party()
	if kind!="basket_guard":party=party.filter(func(a):return a.id=="char_liang_xiao")
	var data=JSON.parse_string(FileAccess.get_file_as_string("res://data/chapter_six_encounters.json"))
	session=Session.new(c.rules,c.combat,data.encounters["enc_ch06_"+kind],party,"preview_only")
	var host=PanelContainer.new();host.position=Vector2(12,12);host.size=Vector2(616,336)
	var theme=Theme.new();theme.default_font=load("res://assets/fonts/kunlun_ui.ttf");theme.default_font_size=16;host.theme=theme;root.add_child(host)
	var scroll=ScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;host.add_child(scroll)
	panel=BattleUI.new();panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(panel)
	panel.input_submitted.connect(func(a):session.apply_input(a);render())
	panel.command_requested.connect(func(a,s,t,r):session.set_command(a,s,t,r);render())
	panel.resolve_requested.connect(func():session.resolve_round();render())
	panel.retry_requested.connect(func():session.retry();render())
	panel.continue_requested.connect(func():quit())
	panel.leave_requested.connect(func():quit())
	render()
	if "--screenshot" in args:
		for i in range(6):await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/ch06_"+kind+"_640.png")
		quit()
