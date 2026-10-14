extends VBoxContainer
## Stable controls live across renders. The campaign owns all validation and state.
signal input_submitted(action: Dictionary)
signal close_requested
const Diagram = preload("res://scripts/puzzles/chapter_six_geometry.gd")
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
	b.set_meta("puzzle_focus","ch06:"+key); add_child(b); _buttons[key] = b
	if callback.is_valid(): b.pressed.connect(callback)
	else: b.pressed.connect(func(): input_submitted.emit(action))
	return b
func _select(key: String, title: String, options: Array) -> void:
	_label(key+"_label",title)
	var s := OptionButton.new(); s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for option in options: s.add_item(str(option))
	s.set_meta("puzzle_focus","ch06:"+key); add_child(s); _selects[key] = s
func _number(key: String, title: String, initial: int) -> void:
	var h := HBoxContainer.new(); add_child(h)
	var l := Label.new(); l.text=title; l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; l.size_flags_horizontal=Control.SIZE_EXPAND_FILL; h.add_child(l)
	var s := SpinBox.new(); s.min_value=-100; s.max_value=1000; s.value=initial; s.step=1; s.custom_minimum_size.x=110
	s.set_meta("puzzle_focus","ch06:"+key); h.add_child(s); _numbers[key]=s
func _sel(key: String) -> int: return _selects[key].selected
func _num(key: String) -> int: return int(_numbers[key].value)
func _send(action: Dictionary) -> void: input_submitted.emit(action)
func _compact_row(controls:Array) -> void:
	var row:=HBoxContainer.new()
	row.add_theme_constant_override("separation",8)
	add_child(row)
	for control in controls:
		control.reparent(row)
		control.size_flags_horizontal=Control.SIZE_EXPAND_FILL
func _build() -> void:
	add_theme_constant_override("separation",6)
	_label("title",_view.title)
	_button("rules","展开／收起完整原理说明",{},func(): _labels.instruction.visible=not _labels.instruction.visible)
	_label("instruction",_view.instruction);_labels.instruction.visible=false
	_label("status")
	_diagram=Diagram.new();add_child(_diagram)
	if _built_id!="stars_ch06_sword":_button("principle","① 阅读本题原理",{"type":"read_principle"})
	match _built_id:
		"stars_ch06_sword":
			_select("note","父书三处启发（逐处读）",["变易有序","万变有常","顺势而行"])
			_button("note","读所选旧批启发",{},func():_send({"type":"read_note","note":_sel("note")}))
			_label("feedback_note")
			_button("observe","观察当前一拍星位",{},func():_send({"type":"observe_star","time":_view.state.sword_vectors.size()}))
			_label("star_rule")
			_number("x","坐标／向量 x（右正）",0);_number("y","坐标／向量 y（上正）",0)
			_button("predict","验证下一拍星位 (x,y)",{},func():_send({"type":"predict_star","x":_num("x"),"y":_num("y")}))
			_button("vector","验证当前星位的切向剑路 (x,y)",{},func():_send({"type":"sword_vector","x":_num("x"),"y":_num("y")}))
			_label("feedback_star")
		"array_ch06_steps":
			_select("line","当前验线（编号与图一致）",["0 第1行","1 第2行","2 第3行","3 第4行","4 第1列","5 第2列","6 第3列","7 第4列","8 主对角","9 副对角"])
			_button("observe","观察本线",{},func():_send({"type":"observe_line","line":_sel("line")}))
			_compact_row([_selects.line,_buttons.observe])
			_label("line_rule");_labels.line_rule.custom_minimum_size.y=54
			_number("sum","四数总和",0)
			_button("verify","验和",{},func():_send({"type":"verify_line","line":_sel("line"),"sum":_num("sum")}))
			_compact_row([_numbers.sum.get_parent(),_buttons.verify])
			_number("endpoint","末格（0—15）",0)
			_button("step","踏到末格",{},func():_send({"type":"step_line","line":_sel("line"),"endpoint":_num("endpoint")}))
			_compact_row([_numbers.endpoint.get_parent(),_buttons.step])
			_label("feedback_line");_labels.feedback_line.custom_minimum_size.y=54
			_selects.line.item_selected.connect(func(_i):_refresh_local())
		"basket_ch06_weave","r03":
			if _built_id=="basket_ch06_weave":
				_select("bamboo","选择一根实际竹材",["第1根","第2根"])
				_button("split","把所选竹材破成三篾",{},func():_send({"type":"split_bamboo","bamboo":_sel("bamboo")}))
			else:_button("split","把唯一一份细篾分为六条",{"type":"split_fine"})
			_select("strip","选择台上篾条（1—6）",[1,2,3,4,5,6])
			_select("pattern","六经交错穿法",["上下上下上下","下上下上下上"])
			_button("weave","穿入所选篾，完成当前一行",{},func():_send({"type":"weave_row","strip":_sel("strip"),"pattern":21 if _sel("pattern")==0 else 42}))
			_label("feedback_weave")
			if _built_id=="basket_ch06_weave":
				_button("rim","折回原篾尾收口",{"type":"bind_rim"});_button("test","放入试重，观察筐沿一次",{"type":"load_test"})
			else:
				_select("heat","烤形火力",["停火","小火","旺火"])
				_button("heat","设置所选火力",{},func():_send({"type":"set_heat","level":_sel("heat")}))
				_button("bake","以当前火力定形一拍",{"type":"bake_tick"})
				_label("feedback_bake")
				_select("part","用预留篾尾完成的结构",["风簧","悬环"] if _view.state.method=="bird" else ["内层","收边密封"])
				_button("part","装配所选结构",{},func():_send({"type":"fit_part","part":(["reed","hanger"] if _view.state.method=="bird" else ["inner","seal"])[_sel("part")]}))
				_button("test","试风一次" if _view.state.method=="bird" else "试水一次",{"type":"test_product"})
			_label("feedback_test")
		"l02":
			_select("reuse","现场复用旧件",["水车旧套管","推车柳木穿销"])
			for pair in [["inspect","检查裂口与可用段","inspect_reuse"],["recover","从原位拆取到台上","recover_reuse"],["repair","修整该旧件端面","repair_reuse"]]:
				var action_type:String=pair[2]
				_button(pair[0],pair[1],{},func():_send({"type":action_type,"part":"sleeve" if _sel("reuse")==0 else "pin"}))
			_label("feedback_reuse")
			_select("pine","两根干松木（各长4单位）",["第1根","第2根"])
			_number("cut","锯切位置（长度单位）",0)
			_button("cut","按所选位置锯开这一根",{},func():_send({"type":"cut_pine","log":_sel("pine"),"length":_num("cut")}))
			_label("feedback_cut")
			_select("job","当前要修的器具",["水车","推车","两副犁柄"])
			_number("fit","接合规格：套深／销深／柄件数",0)
			_button("join","按所选规格接合此器具",{},func():_send({"type":"join","job":_job_name(),"fit":_num("fit")}))
			_button("resin","给此器具接缝涂松脂",{},func():_send({"type":"resin","job":_job_name()}))
			_button("lift","请李庭共同抬装此器具",{},func():_send({"type":"lift","job":_job_name(),"partner":"li_ting"}))
			_button("test","带负载实测此器具一次",{},func():_send({"type":"test_repair","job":_job_name()}))
			_label("feedback_job")
	_button("finish","全部检验完成后收束本题",{"type":"finish"});_label("feedback_finish")
	_button("undo","撤回一步（提示/协助记录保留）",{"type":"undo"})
	_button("retry","重试本题（恢复同批未交付材料）",{"type":"retry"})
	_button("hint","提示 0/3",{"type":"hint"});_label("hint");_label("preview")
	_button("assist","主动同意：执行预览这一步",{"type":"assist_step_v1"});_label("feedback_assist")
	_button("close","收起，保留当前进度",{},func():close_requested.emit())
func _job_name() -> String:return ["waterwheel","cart","plough"][_sel("job")]
func _refresh_local() -> void:
	if _built_id=="array_ch06_steps":
		var r=preload("res://scripts/puzzles/chapter_six_puzzle_resolver.gd")
		var line:int=_sel("line");var cells:Array=r.LINES[line];var values:Array=[]
		for cell in cells:values.append(r.SQUARE[cell])
		_labels.line_rule.text="选中线%d：格%s，数%s，末格%d。当前要踏线%d。" % [line,str(cells),str(values),cells[3],_view.state.steps.size()]
func _refresh() -> void:
	var s:Dictionary=_view.state
	for key in _labels:
		if key.begins_with("feedback_"):_labels[key].text="最近操作："+_view.message
	_labels.hint.text=_view.hint_text;_buttons.hint.text="提示 %d/3" % s.hint
	_labels.preview.text="下一步预览："+_view.next_demo;_labels.preview.visible=s.hint>=3 and not s.complete;_buttons.assist.visible=_labels.preview.visible
	for key in _buttons:
		if key not in ["close","rules"]:_buttons[key].disabled=s.complete
	var status:=""
	match _built_id:
		"stars_ch06_sword":
			status="父批%d/3，星位观察%d/3，剑路%d/3。" % [s.notes.size(),s.observed.size(),s.sword_vectors.size()]
			var i:int=mini(2,s.sword_vectors.size())
			_labels.star_rule.text="第%d拍，当前星位%s；规则：逆时针(x,y)→(-y,x)，剑路取同向切线。" % [i+1,str(preload("res://scripts/puzzles/chapter_six_puzzle_resolver.gd").STARS[i])]
		"array_ch06_steps":status="已观察%d/10，验和%d/10，踏线%d/10。" % [s.observed.size(),s.verified.size(),s.steps.size()]
		"basket_ch06_weave":status="原竹%d，台上篾%d，编入%d/6，收口%s，承重%d/3。" % [s.raw.size(),s.loose.size(),s.woven.size(),"已做" if s.rim else "未做",s.load_ticks]
		"r03":status="所选%s；原捆%d，台上篾%d，编入%d/6，烤形%d/3，装配%d/2，实测%d/3。" % ["鸟" if s.method=="bird" else "盒",s.bundle,s.loose.size(),s.woven.size(),s.bake,s.parts.size(),s.test_ticks]
		"l02":status="先修%s；原松木%d，台上柄料%d，已装柄料%d；旧件取回%d/2、修整%d/2；三户已修%d/3。" % ["水车" if s.method=="waterwheel" else "推车",s.raw.size(),s.pieces.size(),s.installed_pieces.size(),s.recovered.size(),s.repaired.size(),s.completed_jobs.size()]
	_labels.status.text=("已完成：" if s.complete else "当前进度：")+status+("（已记录协助）" if s.assisted else "")+("（旧尝试记录已清理，不能核验此前提示/协助）" if s.history_reset else "")
	_refresh_local()
	if is_instance_valid(_diagram):_diagram.render(_view)
