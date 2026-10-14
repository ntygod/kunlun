extends "res://tests/test_chapter_three_combat.gd"
## UI-only geometry/signal/lifecycle regression. Uses unchanged real B01 session.
func run() -> void:
	rules = JSON.parse_string(FileAccess.get_file_as_string("res://data/combat_rules.json"))
	runtime = JSON.parse_string(FileAccess.get_file_as_string("res://data/combat_runtime.json"))
	encounter = JSON.parse_string(FileAccess.get_file_as_string("res://data/chapter_three_encounters.json")).encounters.enc_ch03_lingtai_ming_sanqiu
	for window_size in [Vector2i(1280,720),Vector2i(640,360)]:
		root.size = window_size
		await process_frame
		var host := PanelContainer.new()
		host.position = Vector2(maxf(20,(window_size.x-850)/2.0),maxf(20,(window_size.y-510)/2.0))
		host.size = Vector2(minf(850,window_size.x-40),minf(510,window_size.y-40))
		var theme_resource := Theme.new()
		theme_resource.default_font = load("res://assets/fonts/kunlun_ui.ttf")
		theme_resource.default_font_size = 20
		var style := StyleBoxFlat.new()
		style.content_margin_left = 24
		style.content_margin_right = 24
		style.content_margin_top = 16
		style.content_margin_bottom = 16
		theme_resource.set_stylebox("panel","PanelContainer",style)
		host.theme = theme_resource
		root.add_child(host)
		var scroll := ScrollContainer.new()
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		host.add_child(scroll)
		var column := VBoxContainer.new()
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll.add_child(column)
		var panel := BattleView.new()
		column.add_child(panel)
		var s := session()
		panel.render(s.get_view(),runtime.skills,s.can_resolve())
		for i in range(4): await process_frame
		var before := s.snapshot()
		var positions := {}
		for id in panel.slots:
			var slot: Button = panel.slots[id]
			positions[id] = slot.get_global_rect()
			check(scroll.get_global_rect().encloses(slot.get_global_rect()),"all fixed controls visible without scrolling at %s: %s" % [window_size,id])
			check(slot.focus_mode == Control.FOCUS_ALL,"all fixed controls keyboard accessible")
		check(panel.slots.move_center.disabled and not panel.slots.move_left.disabled and not panel.slots.move_right.disabled,"current handle disabled in fixed slot")
		check(panel.slots.retry.disabled and panel.slots.continue.disabled,"outcome slots present but disabled during battle")
		check(s.snapshot() == before,"fixed panel is read-only")
		var captured: Array = []
		panel.input_submitted.connect(func(action): captured.append(action))
		var mouse := InputEventMouseButton.new()
		mouse.button_index = MOUSE_BUTTON_LEFT
		mouse.position = panel.slots.move_left.get_global_rect().get_center()
		mouse.global_position = mouse.position
		mouse.pressed = true
		root.push_input(mouse,true)
		mouse = mouse.duplicate()
		mouse.pressed = false
		root.push_input(mouse,true)
		await process_frame
		check(captured.size() == 1 and captured[0].destination == "left" and captured[0].revision == s.engine.state.revision,"fixed position slot submits original revisioned input")
		s.apply_input(captured[0])
		panel.render(s.get_view(),runtime.skills,s.can_resolve())
		for i in range(4): await process_frame
		check(panel.slots.move_left.disabled and panel.slots.move_right.disabled and not panel.slots.move_center.disabled,"unreachable and current slots disabled, never removed")
		for id in positions: check(panel.slots[id].get_global_rect() == positions[id],"movement never shifts button hitbox: "+id)
		var command_signals: Array = []
		panel.command_requested.connect(func(actor,skill,target,revision): command_signals.append([actor,skill,target,revision]))
		panel.slots.observe.grab_focus()
		var key := InputEventKey.new()
		key.keycode = KEY_ENTER
		key.pressed = true
		root.push_input(key,true)
		key = key.duplicate()
		key.pressed = false
		root.push_input(key,true)
		await process_frame
		check(command_signals[0] == [H,"observe",B,int(s.engine.state.revision)],"skill slot submits unchanged command contract")
		s.set_command(H,"observe",B,int(s.engine.state.revision))
		panel.render(s.get_view(),runtime.skills,s.can_resolve())
		for i in range(4): await process_frame
		for id in positions: check(panel.slots[id].get_global_rect() == positions[id],"pending text never shifts button hitbox: "+id)
		check(not panel.slots.resolve.disabled,"resolve remains fixed and enabled after command")
		check(root.gui_get_focus_owner() == panel.slots.observe,"keyboard focus survives render at same slot")
		var error_view := s.get_view()
		error_view.input_error = "真气不足，可用普攻或自守回气。"
		error_view.save_policy = "每轮结算/暂歇自动保存；编排中可F5保存、F9读档。"
		error_view.actors[0].ready.sancai_counter = int(error_view.round)+3
		panel.render(error_view,runtime.skills,s.can_resolve())
		for i in range(4): await process_frame
		check(panel.slots.sancai_counter.disabled,"cooldown skill remains in disabled fixed slot")
		check(panel.get_node("feedback").text == error_view.input_error,"input error stays visible in fixed feedback row")
		check("F5存/F9读" in panel.pending_label.text and error_view.save_policy in panel.details_text.text,"save policy stays visible in fixed pending row and complete in details")
		for id in positions: check(panel.slots[id].get_global_rect() == positions[id],"cooldown/error never move any slot: "+id)
		panel._show_details()
		await process_frame
		check(panel.details.visible and panel.details.get_parent() == panel,"long rules/log popup owned by panel")
		var popup_style := panel.details.get_theme_stylebox("panel") as StyleBoxFlat
		check(popup_style != null and popup_style.draw_center and is_equal_approx(popup_style.bg_color.a,1.0),"rules/log popup explicitly paints an opaque center")
		check(panel.details.size.x <= window_size.x and panel.details.size.y <= window_size.y,"details popup also fits minimum window")
		var escape := InputEventKey.new()
		escape.keycode = KEY_ESCAPE
		escape.pressed = true
		panel.details.push_input(escape,true)
		await process_frame
		check(not panel.details.visible,"Escape closes owned details without altering battle")
		for outcome in ["defeat","victory"]:
			var result_view := s.get_view()
			result_view.outcome = outcome
			result_view.objective.failure = "liang_exhausted" if outcome == "defeat" else ""
			panel.render(result_view,runtime.skills,false)
			for i in range(4): await process_frame
			check(panel.slots.size() == 15,"outcome still preserves all fifteen slots")
			check(panel.slots.retry.disabled == (outcome != "defeat") and panel.slots.continue.disabled == (outcome != "victory"),"only correct outcome action enabled")
			for id in positions: check(panel.slots[id].get_global_rect() == positions[id],"outcome never shifts buttons: "+id)
		var popup_ref: WeakRef = weakref(panel.details)
		column.remove_child(panel)
		panel.queue_free()
		await process_frame
		check(popup_ref.get_ref() == null,"menu/read rebuild frees popup with panel; no orphan input surface")
		host.queue_free()
		await process_frame
	print("CHAPTER THREE BATTLE PANEL %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
