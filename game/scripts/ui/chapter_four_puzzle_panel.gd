extends VBoxContainer
## Stable controls live across renders. The campaign owns all validation and state.
signal input_submitted(action: Dictionary)
signal close_requested
const Diagram = preload("res://scripts/puzzles/chapter_four_geometry.gd")
var _view: Dictionary = {}
var _built_id := ""
var _labels: Dictionary = {}
var _selects: Dictionary = {}
var _numbers: Dictionary = {}
var _buttons: Dictionary = {}
var _diagram: Control
var _render_revision := 0
func render(view: Dictionary) -> void:
	_render_revision += 1
	var scroll := _scroll_container()
	var focused: Control = get_viewport().gui_get_focus_owner() if is_inside_tree() else null
	var anchor: Control = focused if is_instance_valid(focused) and is_ancestor_of(focused) and _built_id==view.puzzle_id else null
	var anchor_y: float = anchor.global_position.y if is_instance_valid(anchor) else 0.0
	var old_scroll: int = scroll.scroll_vertical if is_instance_valid(scroll) and _built_id==view.puzzle_id else 0
	if is_instance_valid(scroll): scroll.follow_focus=false
	_view = view.duplicate(true)
	if _built_id != view.puzzle_id:
		for c in get_children(): remove_child(c); c.queue_free()
		_labels.clear(); _selects.clear(); _numbers.clear(); _buttons.clear()
		_built_id = view.puzzle_id; _build()
	_refresh()
	_restore_anchor.call_deferred(_render_revision,weakref(anchor) if is_instance_valid(anchor) else null,anchor_y,old_scroll)
func _scroll_container() -> ScrollContainer:
	var node: Node = get_parent()
	while node!=null:
		if node is ScrollContainer: return node
		node=node.get_parent()
	return null
func _restore_anchor(revision: int, reference: WeakRef, y: float, old_scroll: int) -> void:
	if not is_inside_tree(): return
	await get_tree().process_frame
	if revision!=_render_revision or not is_inside_tree(): return
	var scroll := _scroll_container()
	if not is_instance_valid(scroll): return
	var anchor: Control = reference.get_ref() if reference!=null else null
	if is_instance_valid(anchor) and anchor.is_visible_in_tree():
		scroll.scroll_vertical += int(round(anchor.global_position.y-y))
	else: scroll.scroll_vertical=old_scroll
	scroll.follow_focus=true
func _label(key: String, text: String = "") -> void:
	var l := Label.new(); l.text = text; l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL; add_child(l); _labels[key] = l
func _button(key: String, title: String, action: Dictionary = {}, callback: Callable = Callable()) -> Button:
	var b := Button.new(); b.text = title; b.custom_minimum_size.y = 32
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.set_meta("puzzle_focus","ch04:"+key); add_child(b); _buttons[key] = b
	if callback.is_valid(): b.pressed.connect(callback)
	else: b.pressed.connect(func(): input_submitted.emit(action))
	return b
func _select(key: String, title: String, options: Array) -> void:
	_label(key+"_label",title)
	var s := OptionButton.new(); s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for option in options: s.add_item(str(option))
	s.set_meta("puzzle_focus","ch04:"+key); add_child(s); _selects[key] = s
func _number(key: String, title: String, initial: int) -> void:
	var h := HBoxContainer.new(); add_child(h)
	var l := Label.new(); l.text=title; l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; l.size_flags_horizontal=Control.SIZE_EXPAND_FILL; h.add_child(l)
	var s := SpinBox.new(); s.min_value=0; s.max_value=1000000; s.value=initial; s.step=1; s.custom_minimum_size.x=110
	s.set_meta("puzzle_focus","ch04:"+key); h.add_child(s); _numbers[key]=s
func _sel(key: String) -> int: return _selects[key].selected
func _num(key: String) -> int: return int(_numbers[key].value)
func _send(action: Dictionary) -> void: input_submitted.emit(action)
func _build() -> void:
	add_theme_constant_override("separation",6)
	_label("title",_view.title); _label("instruction",_view.instruction)
	_label("keys","Tab换焦点，方向键选值，Enter操作。正文可纵向滚动；收起保留进度。")
	_label("status"); _label("message")
	if _built_id not in ["board_ch04_wood","ledger_ch04_r02"]:
		_diagram=Diagram.new(); add_child(_diagram)
	else: _diagram=null
	match _built_id:
		"tile_ch04_intercept":
			_button("observe","① 观察水流浮标与缆索",{"type":"observe_current"})
			_select("vx","② 每跳横向推力",["1格","2格","3格"])
			_select("dy","每跳纵移",["−1格","0格","＋1格"])
			_selects.vx.select(1); _selects.dy.select(1)
			_button("set","设置参数",{},func(): _send({"type":"set_launch","vx":_sel("vx")+1,"dy":_sel("dy")-1}))
			_button("launch","③ 投瓦，显示三跳实际接触点",{"type":"launch"})
			_label("feedback_trajectory")
			_button("tick","④ 推进水流一拍，观察断缆后转船",{"type":"current_tick"})
			_select("landing","⑤ 选择落脚位置",["横转后船尾 (9,6)","原船头 (10,5)","河道水面 (7,5)"])
			_button("land","在所选位置落脚",{},func():
				var p: Array = [[9,6],[10,5],[7,5]][_sel("landing")]; _send({"type":"land","x":p[0],"y":p[1]}))
		"board_ch04_wood":
			_label("rows")
			_button("observe","① 观察下一次三分剑招",{},func(): _send({"type":"observe_cut","cut":_view.state.rows.size()+1}))
			for i in range(3): _button("group%d"%i,"② 将当前全部木柴分入第%d子组"%(i+1),{"type":"split_group","group":i})
			_number("prior","③ 上一行数量",1); _number("factor","分成几份",3); _number("result","本行结果",3)
			_button("multiply","记录本行乘算",{},func(): _send({"type":"multiply_row","prior":_num("prior"),"factor":_num("factor"),"result":_num("result")}))
			_label("feedback_math")
			_button("submit","④ 六招六行全部核对",{"type":"submit"})
		"trial_ch04_staff":
			_label("trace")
			_select("batch","① 选择一组五根，9组共45根",["1：0—4","2：5—9","3：10—14","4：15—19","5：20—24","6：25—29","7：30—34","8：35—39","9：40—44"])
			_button("place","放入这组五根棍位",{},func(): _send({"type":"place_batch","batch":_sel("batch")}))
			_button("check","逐一检查45处支撑",{"type":"check_supports"})
			_button("rules","② 读清捉住/双脚落地的赌约",{"type":"read_rules"})
			_button("consent","听柳莺莺明确同意以马为注",{"type":"owner_consent"})
			_button("intent","③ 看海雨本轮追逐意图",{"type":"read_intent"})
			_label("staff_intent_local")
			_select("direction","沿环方向（只走相邻连边）",["顺时针 ＋1","逆时针 −1"])
			_select("stride","本轮走几根",["1根","2根","3根"])
			_button("move","走棍，并逐根显示海雨追逐",{},func(): _send({"type":"move_posts","direction":1 if _sel("direction")==0 else -1,"stride":_sel("stride")+1}))
			_label("staff_move_local")
			_button("collapse","④ 观察棍毁后的地面与海雨",{"type":"observe_collapse"})
			_button("hands","双手撑住标记地面，双脚悬空",{"type":"support_landing","ground":"marked_ground","support":"hands"})
			_button("feet","双脚落在标记地面（赌约禁脚落地）",{"type":"support_landing","ground":"marked_ground","support":"feet"})
			_button("submit","⑤ 由裁判按完整轨迹与姿态核对",{"type":"submit"})
		"r02":
			_select("material","① 取哪一段现场柳条？",["柳条1（槽1/2）","柳条2（槽3/4）","柳条3（槽5/6）"])
			_button("collect","取该段柳条",{},func(): _send({"type":"collect_willow","material":_sel("material")}))
			_select("slot","② 选择原笠破沿的槽位",[1,2,3,4,5,6]); _select("pattern","穿织方向",["上穿","下穿"])
			_button("weave","将柳条织入这个槽",{},func(): _send({"type":"weave_slot","slot":_sel("slot"),"pattern":"over" if _sel("pattern")==0 else "under"}))
			_label("feedback_weave")
			_button("check","③ 检查六槽交替和三段柳条",{"type":"check_weave"})
			_button("rain","④ 逐槽试雨，检查缺口",{"type":"rain_test"})
		"l01":
			_button("stores","① 从老周现场料堆取三板三份填料",{"type":"collect_stores"})
			_button("unload","将已选优先货物卸到岸上指定处",{"type":"transfer_priority"})
			_select("slot","② 选择船底板槽",["船首","中段","船尾"]); _select("board","选择木板",["A（船首榫）","B（中段榫）","C（船尾榫）"])
			_button("seat","将所选板嵌入所选槽",{},func(): _send({"type":"seat_board","slot":_sel("slot"),"board":_sel("board")}))
			_button("fill","一份填料封住所选槽缝",{},func(): _send({"type":"fill_seam","slot":_sel("slot")}))
			_label("feedback_boards")
			_button("anchor","③ 绞索挂牢码头柳树",{"type":"attach_winch","anchor":"dock_willow"})
			_button("level","用绞索扶正船身",{"type":"level_hull"})
			_button("release","扶正后松索，观察自行浮稳",{"type":"release_winch"})
			_button("tide","④ 观察一个潮汐拍（共三拍）",{"type":"tide_tick"})
		"ledger_ch04_r02":
			_label("ledger_numbers","示例凭据：本金10文／议定利息2文／掌柜索款15文。")
			_button("principal","① 核读本金凭据：10文",{"type":"inspect_account","field":"principal"})
			_button("interest","核读约定利息：2文",{"type":"inspect_account","field":"interest"})
			_button("demand","核读实际索款：15文",{"type":"inspect_account","field":"demand"})
			_number("legal","② 10＋2＝应还多少文？",0)
			_button("sum","记录应还总数",{},func(): _send({"type":"sum_account","principal":10,"interest":2,"total":_num("legal")}))
			_label("feedback_sum")
			_number("excess","③ 15－应还数＝多索多少文？",0)
			_button("difference","将实际索款和应还数对读",{},func(): _send({"type":"compare_account","demand":15,"legal":_num("legal"),"excess":_num("excess")}))
			_button("submit","④ 核对账目证据，回现场继续对质",{"type":"submit"})
	_label("feedback_result")
	_button("undo","撤回上一步（已验阶段不能撤销）",{"type":"undo"})
	_button("retry","重试本题（提示和协助保留）",{"type":"retry"})
	_button("hint","提示 0/3",{"type":"hint"}); _label("hint"); _label("preview")
	_button("assist","主动同意：按上面预览协助本阶段",{"type":"assist_stage_v2"})
	_label("feedback_assist")
	_button("close","收起题板，回到现场",{},func(): close_requested.emit())
func _yes(value: bool) -> String: return "已完成" if value else "待操作"
func _refresh() -> void:
	var s: Dictionary = _view.state
	_labels.message.text = _view.message
	for key in _labels:
		if key.begins_with("feedback_"): _labels[key].text="最近操作："+_view.message
	if _built_id=="trial_ch04_staff":
		var clockwise := posmod(int(s.rival)-int(s.player),45)
		_labels.staff_intent_local.text = "你在%d号，海雨在%d号；到海雨顺时针%d根／逆时针%d根。他在你移动后追4根，宜先向远离他的方向走。%s" % [s.player,s.rival,clockwise,45-clockwise,"本轮已观察，可走棍。" if s.intent else "请先按上方观察意图。"]
		if s.captured or s.feet_ground:
			_labels.staff_intent_local.text = "本轮已失败，请向下点“重试本题”；没有失马或奖励结算。"
		elif s.collapsed:
			_labels.staff_intent_local.text = "三轮已过，45棍均毁；不能再走棍。向下观察折棍后地面，再选择支撑部位，守住双脚不落地的赌约。"
		_labels.staff_move_local.text = "本轮反馈："+_view.message
		if not s.trace.is_empty():
			var last: Dictionary = s.trace.back()
			_labels.staff_move_local.text += "\n第%d轮实际经过：梁%s；海雨%s。" % [last.round,str(last.player_path),str(last.rival_path)]
	_labels.hint.text = _view.hint_text
	_labels.preview.text = "协助预览："+_view.next_demo+("；然后完成当前行所余观察/分组三次/乘算（最多五个合法操作）。" if _built_id=="board_ch04_wood" else "。")
	_labels.preview.visible = s.hint>=3 and not s.complete
	_buttons.assist.visible = _labels.preview.visible
	_buttons.hint.text = "提示 %d/3" % s.hint
	for key in _buttons:
		if key!="close": _buttons[key].disabled = s.complete
	var status := ""
	match _built_id:
		"tile_ch04_intercept": status = "已观水流：%s；接触点：%s；船角度%d；落脚%s" % [_yes(s.observed),str(s.contacts),s.boat_angle,"已站稳" if s.landing!="" else "尚未落脚"]
		"board_ch04_wood":
			status = "六招已观察%d/6；六行完成%d/6；本行三子组%d/3。" % [s.observations.size(),s.rows.size(),s.groups.size()]
			var rows: Array[String] = []
			for row in s.rows: rows.append("第%d招：%d × %d = %d" % [row.cut,row.prior,row.factor,row.result])
			_labels.rows.text = "\n".join(rows) if not rows.is_empty() else "初始原木：1（取木一剑不计六招）"
		"trial_ch04_staff":
			status = "棍位%d/45；验撑%s；赌约%s；马主同意%s；三轮%d/3。" % [45 if s.collapsed else s.posts.size(),_yes(s.checked),_yes(s.rules),_yes(s.consent),s.round]
			var lines: Array[String] = []
			for step in s.trace: lines.append("第%d轮 梁%s → 海雨%s%s" % [step.round,str(step.player_path),str(step.rival_path),"（捉住）" if step.captured else "（避开）"])
			_labels.trace.text = "\n".join(lines)
		"ledger_ch04_r02": status = "已核读%d/3项；应还%d文（%s）；多索%d文（%s）。" % [s.observations.size(),s.legal_total,_yes(s.sum_checked),s.excess,_yes(s.difference_checked)]
		"r02":
			var slots: Array[String] = []
			for slot in s.slots: slots.append("上" if slot=="over" else ("下" if slot=="under" else "空"))
			status = "已取%d/3段；六槽%s；检查%s；试雨%d/6槽。" % [s.materials.size()," / ".join(slots),_yes(s.woven),s.rain.size()]
		"l01":
			var boards: Array[String] = []; var filler: Array[String] = []
			for i in range(3):
				boards.append("已放" if s.boards[i]!="" else "空槽")
				filler.append("已封" if s.filler[i] else "未封")
			status = "首/中/尾三板：%s；三缝：%s；载重%d；潮汐%d/3；进水%d。" % [" / ".join(boards)," / ".join(filler),s.load,s.ticks,s.water]
	_labels.status.text = ("已完整验收。" if s.complete else "当前进度：")+status+("（已记录协助）" if s.assisted else "")
	if is_instance_valid(_diagram): _diagram.render(_view)
