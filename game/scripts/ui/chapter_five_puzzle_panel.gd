extends VBoxContainer
## Stable controls live across renders. The campaign owns all validation and state.
signal input_submitted(action: Dictionary)
signal close_requested
const Diagram = preload("res://scripts/puzzles/chapter_five_geometry.gd")
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
	if revision!=_render_revision or not is_inside_tree(): return
	# A one-shot node-bound callback is disconnected on free; unlike a suspended
	# coroutine it cannot strand the focus WeakRef when the panel closes.
	get_tree().process_frame.connect(_finish_restore_anchor.bind(revision,reference,y,old_scroll),CONNECT_ONE_SHOT)
func _finish_restore_anchor(revision: int, reference: WeakRef, y: float, old_scroll: int) -> void:
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
	b.set_meta("puzzle_focus","ch05:"+key); add_child(b); _buttons[key] = b
	if callback.is_valid(): b.pressed.connect(callback)
	else: b.pressed.connect(func(): input_submitted.emit(action))
	return b
func _select(key: String, title: String, options: Array) -> void:
	_label(key+"_label",title)
	var s := OptionButton.new(); s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for option in options: s.add_item(str(option))
	s.set_meta("puzzle_focus","ch05:"+key); add_child(s); _selects[key] = s
func _number(key: String, title: String, initial: int) -> void:
	var h := HBoxContainer.new(); add_child(h)
	var l := Label.new(); l.text=title; l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; l.size_flags_horizontal=Control.SIZE_EXPAND_FILL; h.add_child(l)
	var s := SpinBox.new(); s.min_value=0; s.max_value=1000000; s.value=initial; s.step=1; s.custom_minimum_size.x=110
	s.set_meta("puzzle_focus","ch05:"+key); h.add_child(s); _numbers[key]=s
func _sel(key: String) -> int: return _selects[key].selected
func _num(key: String) -> int: return int(_numbers[key].value)
func _send(action: Dictionary) -> void: input_submitted.emit(action)
func _build() -> void:
	add_theme_constant_override("separation",6)
	_label("title",_view.title); _label("instruction",_view.instruction)
	_label("keys","Tab换焦点，方向键选值，Enter操作。题面可纵向滚动；收起保留同一会话。")
	_label("status")
	if _built_id in ["chain_ch05_linkage","bagua_ch05_reverse","box_ch05_light"]:
		_diagram=Diagram.new(); add_child(_diagram)
	else: _diagram=null
	match _built_id:
		"chain_ch05_linkage":
			_button("observe","① 观察传动图和接口",{"type":"inspect_chain"})
			_select("source","② 哪个机构的输出？",["0 踏板","1 翻板","2 锁闩","3 配重"])
			_select("target","接到哪个接收端？",["0 踏板","1 翻板","2 锁闩","3 配重","4 出口"])
			_button("connect","接好这一条传动",{},func(): _send({"type":"connect_link","source":_sel("source"),"target":_sel("target")}))
			_button("test","③ 实际送力，查看逐节点传动",{"type":"test_chain"})
			_label("feedback_chain")
			_button("third","④ 二连环实测通过后安装第三联配重",{"type":"install_third"})
			_label("upgrade","加装后将2号输出改接3号，3号接4号，再实际试动一次。")
		"lock_ch05_six":
			_label("lock_cue")
			_button("observe","① 观察当前外锁齿深与转向",{},func(): _send({"type":"inspect_lock","lock":_view.state.lock}))
			_label("feedback_lock")
			_select("depth","② 探针伸入深度",["1格","2格","3格"])
			_select("direction","旋转方向",["顺时针","逆时针"])
			_button("probe","配好探针和转向",{},func(): _send({"type":"set_probe","depth":_sel("depth")+1,"direction":1 if _sel("direction")==0 else -1}))
			_button("turn","③ 试转这道外锁",{"type":"turn_lock"})
		"bagua_ch05_reverse":
			_button("light","① 观察入射光与盘缘落点",{"type":"observe_bagua_light"})
			_label("feedback_light")
			_select("anchor","② 光斑在盘心的哪一边？以此定0位",["北","东","南","西"])
			_button("anchor","按光斑确定参照方向",{},func(): _send({"type":"set_bagua_anchor","direction":["north","east","south","west"][_sel("anchor")]}))
			_button("sequence","③ 从该参照读正序纹样",{"type":"inspect_bagua_sequence"})
			_label("bagua_sequence")
			_select("slot","④ 反向盘上位置（西沿0，顺时针编号）",[0,1,2,3,4,5,6,7])
			_select("trigram","移哪枚唯一卦牌？",["0 乾","1 兑","2 离","3 震","4 巽","5 坎","6 艮","7 坤"])
			_button("place","将这枚牌移到所选位",{},func(): _send({"type":"place_trigram","slot":_sel("slot"),"trigram":_sel("trigram")}))
			_button("pair","⑤ 核对所选位与正序的反向编号",{},func(): _send({"type":"verify_reverse_pair","slot":_sel("slot")}))
			_label("feedback_pair")
			_button("cabinet","⑥ 八处核对后试开暗柜闩",{"type":"test_cabinet"})
		"oranges_ch05_hundred":
			_button("warm_price","① 核读温柑：每只7文",{"type":"inspect_price","fruit":0})
			_button("green_price","核读绿桔：每只3文",{"type":"inspect_price","fruit":1})
			_button("flat_price","核读匾桔：每3只1文",{"type":"inspect_price","fruit":2})
			_number("warm","② 温柑只数 x",0); _number("green","绿桔只数 y",0); _number("flat","匾桔只数 z",0)
			_button("counts","记录这组三种数量",{},func(): _send({"type":"set_oranges","warm":_num("warm"),"green":_num("green"),"flat":_num("flat")}))
			_button("quantity","③ 核对 x＋y＋z 是否等于100",{"type":"check_orange_count"})
			_label("feedback_quantity")
			_button("cost","④ 核对21x＋9y＋z是否等于300",{"type":"check_orange_cost"})
			_label("feedback_cost")
			_button("submit","⑤ 两项验过，再核对整题",{"type":"submit"})
		"box_ch05_light":
			_button("dark","① 吹灭明烛，辨读微光",{"type":"extinguish_candle"})
			_button("observe","② 观察顶光、三镜座、原盒孔位",{"type":"inspect_light_room"})
			_select("mirror","③ 选择原铜镜",["1 东镜 (160,64)","2 西镜 (64,64)","3 下层镜 (64,128)"])
			_button("mount","把所选铜镜固定在原座",{},func(): _send({"type":"mount_mirror","mirror":_sel("mirror")}))
			_button("minus","所选镜切线角 −15°",{},func(): _send({"type":"rotate_mirror","mirror":_sel("mirror"),"step":-1}))
			_button("plus","所选镜切线角 ＋15°",{},func(): _send({"type":"rotate_mirror","mirror":_sel("mirror"),"step":1}))
			_label("mirror_angles")
			_button("ring_minus","④ 原盒铜环 −45°（孔/字模一起转）",{"type":"rotate_box_ring","step":-1})
			_button("ring_plus","原盒铜环 ＋45°（孔/字模一起转）",{"type":"rotate_box_ring","step":1})
			_button("trace","⑤ 实际追光，检查三镜/双孔/字影",{"type":"trace_light"})
			_label("feedback_ray")
			_label("ray_details")
			_button("open","⑥ 正立四字后检查原盒暗簧",{"type":"open_original_box"})
		"box_ch05_reseal":
			_label("custody")
			_select("page","① 选择原盒板/对应经文（1—12）",[1,2,3,4,5,6,7,8,9,10,11,12])
			_button("remove","拆下所选原板，置于操作台",{},func(): _send({"type":"remove_panel","page":_sel("page")}))
			_button("rub","逐篇拓印所选原板",{},func(): _send({"type":"rub_page","page":_sel("page")}))
			_button("refit","④ 把所选原板装回原盒（两石入盒后）",{},func(): _send({"type":"refit_panel","page":_sel("page")}))
			_label("feedback_rub")
			_button("yin","② 从原盒取出阴球",{"type":"take_ball","ball":"yin"})
			_button("yang","从原盒取出阳球",{"type":"take_ball","ball":"yang"})
			_select("stone","③ 选择现场鹅卵石",["第1块","第2块"])
			_button("stone","实际拾取这块石头",{},func(): _send({"type":"collect_stone","stone":_sel("stone")}))
			_button("load","把所选石头装入同一原盒",{},func(): _send({"type":"load_stone","stone":_sel("stone")}))
			_label("feedback_stone")
			_button("seal","⑤ 清点双球/12拓本/2石/原板，复封同盒",{"type":"seal_original_box"})
	_label("feedback_result")
	_button("undo","撤回上一步（协助标记保留）",{"type":"undo"})
	_button("retry","重试本题（恢复同一操作台，不复制物件）",{"type":"retry"})
	_button("hint","提示 0/3",{"type":"hint"}); _label("hint"); _label("preview")
	_button("assist","主动同意：执行预览这一步",{"type":"assist_step_v1"})
	_label("feedback_assist")
	_button("close","收起题板，保留本会话进度",{},func(): close_requested.emit())
func _yes(value: bool) -> String: return "已验" if value else "待操作"
func _refresh() -> void:
	var s: Dictionary=_view.state
	for key in _labels:
		if key.begins_with("feedback_"): _labels[key].text="最近操作："+_view.message
	_labels.hint.text=_view.hint_text; _buttons.hint.text="提示 %d/3" % s.hint
	_labels.preview.text="下一步预览："+_view.next_demo
	_labels.preview.visible=s.hint>=3 and not s.complete; _buttons.assist.visible=_labels.preview.visible
	for key in _buttons:
		if key!="close": _buttons[key].disabled=s.complete
	var status := ""
	match _built_id:
		"chain_ch05_linkage": status="二连环%s；配重%s；实际传动%s。" % [_yes(s.double_tested),_yes(s.third_installed),str(s.trace)]
		"lock_ch05_six":
			status="已开%d/6道外锁；原盒未开。" % s.lock
			_labels.lock_cue.text="当前第%d锁；探针深%d格，方向%s。" % [mini(s.lock+1,6),s.probe,"顺时针" if s.direction==1 else ("逆时针" if s.direction==-1 else "未配")]
		"bagua_ch05_reverse":
			status="光斑%s；西沿参照%s；反向对应已验%d/8。" % [str(s.light_point),_yes(s.anchor=="west"),s.checks.size()]
			_labels.bagua_sequence.text="从西沿0顺时针正序：乾兑离震巽坎艮坤；反向编号＝(8−i)余8。" if s.observed else "先以光斑定参照，才能读正序。"
		"oranges_ch05_hundred": status="温%d、绿%d、匾%d；总只数%d（%s）；三倍总价%d（%s）。" % [s.counts[0],s.counts[1],s.counts[2],s.quantity_sum,_yes(s.count_check),s.triple_cost,_yes(s.cost_check)]
		"box_ch05_light":
			status="熄烛%s；三镜归座%s；铜环%d°；正立四字%s。" % [_yes(s.candle_out),str(s.mounted),s.ring*45,_yes(s.projected)]
			_labels.mirror_angles.text="切线角：东镜%d°／西镜%d°／下层镜%d°（均按15°步进）。" % s.angles
			_labels.ray_details.text="尚未试光。" if s.ray.is_empty() else "真实镜序%s；孔序%s；投影结果%s。" % [str(s.ray.mirrors),str(s.ray.holes),"正立" if s.ray.projected else "偏移、遮挡或倒字"]
		"box_ch05_reseal":
			status="已拓%d/12篇；双球%d/2；石入原盒%d/2；原板回装%d/12。" % [s.copies.size(),s.taken_balls.size(),s.loaded_stones.size(),s.refitted_panels.size()]
			_labels.custody.text="唯一原盒：盒内球%d、原板%d、石%d；台上球%d、原板%d、石%d、拓本%d。" % [s.box_contents.balls.size(),s.box_contents.panels.size(),s.box_contents.stones.size(),s.table_contents.balls.size(),s.table_contents.panels.size(),s.table_contents.stones.size(),s.table_contents.copies.size()]
	_labels.status.text=("已完成：" if s.complete else "当前进度：")+status+("（已记录协助）" if s.assisted else "")
	if is_instance_valid(_diagram): _diagram.render(_view)
