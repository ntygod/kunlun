extends "res://tests/test_chapter_six_combat.gd"
const BattleUI=preload("res://scripts/ui/chapter_six_battle_panel.gd")
func run():
	var c=Campaign.new(JSON.parse_string(FileAccess.get_file_as_string("res://data/prologue.json")))
	check(c.restore_persisted(JSON.parse_string(FileAccess.get_file_as_string("res://../output/cache/chapter_five_gui/manual_natural_final.json")))=="","natural UI fixture")
	natural_party=c.current_chapter_runtime().combat_party()
	for window in [Vector2i(1280,720),Vector2i(640,360),Vector2i(639,359)]:
		root.size=window
		await process_frame
		for kind in ["white_plum","tutuha_spar","basket_guard"]:
			var host=PanelContainer.new();host.position=Vector2(20,20);host.size=Vector2(minf(850,window.x-40),minf(510,window.y-40))
			var theme=Theme.new();theme.default_font=load("res://assets/fonts/kunlun_ui.ttf");theme.default_font_size=20;host.theme=theme
			root.add_child(host)
			var scroll=ScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;host.add_child(scroll)
			var panel=BattleUI.new();panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(panel)
			var session=make(kind);var before=session.snapshot()
			panel.render(session.get_view(),runtime.skills,session.can_resolve())
			for i in range(4):await process_frame
			check(Compare.equivalent(before,session.snapshot()),"render read-only")
			var rects={}
			for key in panel.slots:
				var slot: Control=panel.slots[key];rects[key]=slot.get_global_rect()
				check(scroll.get_global_rect().encloses(slot.get_global_rect()),"fixed controls visible "+str(window)+" "+kind+" "+key)
			var commands=[];var actions=[]
			panel.command_requested.connect(func(a,b,t,r):commands.append([a,b,t,r]))
			panel.input_submitted.connect(func(a):actions.append(a))
			var select: OptionButton=panel.slots[H+"_skills"]
			if select.item_count>1:select.item_selected.emit(1)
			check(commands.is_empty() and actions.is_empty() and Compare.equivalent(before,session.snapshot()),"selection never rewrites compiled command")
			panel.slots[H+"_input"].pressed.emit()
			check(actions.size()==1 and actions[0].revision==before.state.revision,"explicit scene command revisioned")
			if actions.size()==1:check(session.apply_input(actions[0]).accepted,"visible scene action legal")
			panel.render(session.get_view(),runtime.skills,session.can_resolve())
			for i in range(3):await process_frame
			for key in rects:check(rects[key]==panel.slots[key].get_global_rect(),"fixed hitbox "+key)
			panel.show_details();await process_frame
			check(panel.details.visible and panel.details.size.x<=window.x and panel.details.size.y<=window.y,"details fits viewport")
			panel.details.hide();await process_frame
			var ref=weakref(panel.details);host.queue_free();await process_frame
			check(ref.get_ref()==null,"owned popup freed")
	print("CH06 panel ",checks," checks ",failures," failures")
	quit(1 if failures else 0)
