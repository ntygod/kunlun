class_name PuzzlePanel
extends PanelContainer
## Presentation only. All actions travel back to the campaign-owned resolver.
const ChapterFivePanel = preload("res://scripts/ui/chapter_five_puzzle_panel.gd")
var _chapter_five_panel: VBoxContainer
const ChapterFourPanel = preload("res://scripts/ui/chapter_four_puzzle_panel.gd")
var _chapter_four_panel: VBoxContainer
const ChapterThreePanel = preload("res://scripts/ui/chapter_three_puzzle_panel.gd")
var _chapter_three_panel: VBoxContainer
const Diagram = preload("res://scripts/puzzles/geometry_guide.gd")
signal input_submitted(action: Dictionary)
signal close_requested
var _view: Dictionary = {}
var _body: VBoxContainer
var _scroll: ScrollContainer
var _selection := 0
var _piece := 0
var _built := false
var _focus_key := ""
var _render_revision := 0

func _ready() -> void:
	_build()
	if not _view.is_empty(): render(_view)

func _build() -> void:
	if _built: return
	_built = true
	custom_minimum_size = Vector2(280,180)
	var margin := MarginContainer.new()
	for side in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,8)
	add_child(margin)
	_scroll = ScrollContainer.new()
	_scroll.follow_focus = true
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(_scroll)
	_body = VBoxContainer.new()
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_theme_constant_override("separation",6)
	_scroll.add_child(_body)
	add_theme_font_size_override("font_size",16)

func render(view: Dictionary) -> void:
	_view = view.duplicate(true)
	_build()
	if view.get("kind", "") == "chapter_five":
		if not is_instance_valid(_chapter_five_panel):
			for child in _body.get_children():
				_body.remove_child(child)
				child.queue_free()
			_chapter_three_panel = null
			_chapter_four_panel = null
			_chapter_five_panel = ChapterFivePanel.new()
			_body.add_child(_chapter_five_panel)
			_chapter_five_panel.input_submitted.connect(func(action: Dictionary): input_submitted.emit(action))
			_chapter_five_panel.close_requested.connect(func(): close_requested.emit())
		_chapter_five_panel.render(view)
		return
	_chapter_five_panel = null
	if view.get("kind", "") == "chapter_four":
		if not is_instance_valid(_chapter_four_panel):
			for child in _body.get_children():
				_body.remove_child(child)
				child.queue_free()
			_chapter_three_panel = null
			_chapter_four_panel = ChapterFourPanel.new()
			_body.add_child(_chapter_four_panel)
			_chapter_four_panel.input_submitted.connect(func(action: Dictionary): input_submitted.emit(action))
			_chapter_four_panel.close_requested.connect(func(): close_requested.emit())
		_chapter_four_panel.render(view)
		return
	_chapter_four_panel = null
	if view.get("kind", "") == "chapter_three":
		if not is_instance_valid(_chapter_three_panel):
			for child in _body.get_children():
				_body.remove_child(child)
				child.queue_free()
			_chapter_three_panel = ChapterThreePanel.new()
			_body.add_child(_chapter_three_panel)
			_chapter_three_panel.input_submitted.connect(func(action: Dictionary): input_submitted.emit(action))
			_chapter_three_panel.close_requested.connect(func(): close_requested.emit())
		_chapter_three_panel.render(view)
		return
	_chapter_three_panel = null
	_render_revision += 1
	var previous_scroll := _scroll.scroll_vertical
	# Rebuilding temporarily removes the focused control. Never let follow_focus
	# scroll to an unrelated replacement before container layout has settled.
	_scroll.follow_focus = false
	var focused := get_viewport().gui_get_focus_owner() if is_inside_tree() else null
	_focus_key = ""
	if focused != null:
		_focus_key = str(focused.get_meta("puzzle_focus", ""))
		if _focus_key.is_empty() and focused.get_parent() != null: _focus_key = str(focused.get_parent().get_meta("puzzle_focus", ""))
	for child in _body.get_children():
		_body.remove_child(child)
		child.queue_free()
	_label(str(view.get("title","算筹")),20)
	_label(str(view.get("instruction","")))
	_label("鼠标点击；Tab切换焦点，方向键调数，Enter确认。关闭可回现场，筹位会保留。",14)
	var state: Dictionary = view.get("state",{})
	var id: String = view.get("puzzle_id","")
	var values: Array = state.get("values",[])
	var highlight: int = int(view.get("reflection_highlight",-1))
	if highlight >= 0: _label("试错反三：✓标出的第%d个构件确实正确，其余仍需验算。" % (highlight+1))
	if view.get("geometry_guides",false) and id in ["pz01_problem_06","pz01_problem_08"]:
		var diagram := Diagram.new()
		diagram.method = "volume" if id == "pz01_problem_06" else "scale"
		_body.add_child(diagram)
	match id:
		"pz01_problem_01":
			_label("先选格位，再点下方筹数（中宫五不可移）。")
			var grid := GridContainer.new(); grid.columns = 3; _body.add_child(grid)
			for i in range(9):
				var b := _button("[%s] %s" % [("✓" if i == highlight else "")+("●" if i == _selection else str(i+1)),str(values[i]) if values[i] else "空"],{},grid)
				b.set_meta("puzzle_focus","cell:%d" % i)
				b.disabled = i == 4
				b.pressed.connect(_select_cell.bind(i))
			var rods := GridContainer.new(); rods.columns = 5; _body.add_child(rods)
			for n in range(1,10):
				var rod := _button(str(n),{"type":"set","index":_selection,"value":n},rods)
				rod.disabled = n == 5
		"pz01_problem_02":
			_label("左盘：%d筹    右盘：%d筹" % values)
			_button("左 → 右　移一筹",{"type":"transfer","amount":1})
			_button("右 → 左　移一筹",{"type":"transfer","amount":-1})
		"pz01_problem_04":
			_label("本组目标：%d" % view.target)
			var bits := GridContainer.new(); bits.columns = 5; _body.add_child(bits)
			for i in range(10): _button("%s%d\n%s" % ["✓" if i == highlight else "",view.weights[i],"伸 1" if values[i] else "屈 0"],{"type":"toggle","index":i},bits)
		"pz01_problem_05":
			_label("已观测宿位：" + str(state.observations))
			_button("转七宿，记录落点",{"type":"advance","steps":7})
		"pz01_tenth":
			_label("关系层：%d　未知星轨：%d（有界演示）" % [state.extensions,state.tracks])
			_button("拨一筹，延展关系",{"type":"extend"})
			if state.overload:
				if view.get("authorize_acceptance",false): _button("歇手，听晓霜的话",{"type":"stop"})
				else: _label("暂且离开筹盘，听完晓霜的劝慰。")
		"r01": _render_pages(state,view)
		"k01": _render_geometry(state,view)
		_:
			var labels: Array = []
			match id:
				"pz01_problem_03": labels = ["a列筹数","b列筹数"]
				"pz01_problem_06": labels = ["模型长（尺）","模型宽（尺）","模型深（尺）","体积（立方尺）"]
				"pz01_problem_07": labels = ["第一层筹数","第二层筹数","第三层筹数","第四层筹数","全部筹数"]
				"pz01_problem_08": labels = ["每度（里）","一周360度（里）"]
				"pz01_problem_09": labels = ["a","b","c","d","e"]
			for i in range(labels.size()): _number(labels[i],i,values[i])
	if id != "pz01_tenth" and not state.get("complete",false): _button("逐项验算 / 检查拼页",{"type":"submit"})
	if not state.get("complete",false):
		if id != "pz01_tenth": _button("重新排筹（不扣经验或生命）",{"type":"reset"})
		_button("提示 %d/3" % int(state.get("hint",0)),{"type":"hint"})
		if state.get("hint",0) >= 3 and id.begins_with("pz01_problem_"):
			_button("同意协助：演示下一步（会标记协助）",{"type":"demo_next"})
	if not str(view.get("hint_text","")).is_empty(): _label(view.hint_text)
	_label(str(view.get("message","")))
	var close_button := _button("收起筹盘，回到现场",{})
	close_button.pressed.connect(func(): close_requested.emit())
	_restore_presentation.call_deferred(_render_revision,previous_scroll,_focus_key)

func _render_pages(state: Dictionary, view: Dictionary) -> void:
	_label("所持残片：" + str(view.piece_labels[_piece]))
	var pieces := GridContainer.new(); pieces.columns = 3; _body.add_child(pieces)
	for i in range(9):
		var b := _button(view.piece_labels[i],{},pieces)
		b.set_meta("puzzle_focus","piece:%d" % i)
		b.pressed.connect(_select_piece.bind(i))
	_label("按槽放置（同一残片只能在一处）：")
	var slots := GridContainer.new(); slots.columns = 3; _body.add_child(slots)
	for i in range(9):
		var content := "空" if state.values[i] < 0 else str(view.piece_labels[int(state.values[i])])
		var prefix := "✓" if state.correct_highlight == i else ""
		_button("%s%d页%d段\n%s" % [prefix,i/3+1,i%3+1,content],{"type":"place_piece","slot":i,"piece":_piece},slots)
	if state.matched and state.segment.is_empty():
		_label("第三页哪段尚有可用之理？")
		_button("题号",{"type":"select_segment","segment":"heading"})
		_button("中段：借阴补阳",{"type":"select_segment","segment":"borrow_yin_to_balance_yang"})
		_button("错处结论",{"type":"select_segment","segment":"wrong_conclusion"})
	if not state.segment.is_empty() and state.method.is_empty():
		_button("连同初学错页，全册留存",{"type":"method","value":"keep_all"})
		_button("后半册装订，首张由晓霜代存",{"type":"method","value":"keep_later"})
	if not state.method.is_empty() and state.binding.size() < 3:
		var steps := ["paste_cover","thread","title"]
		var names := ["糊封面","穿线","题名：未合的算册"]
		_button(names[state.binding.size()],{"type":"bind","step":steps[state.binding.size()]})

func _render_geometry(state: Dictionary, view: Dictionary) -> void:
	_label("现场记录 %d/7（需收起筹盘到测点观察）" % state.observed.size())
	for key in state.observed: _label("%s：%d尺" % [view.measure_labels[key],state.observed[key]],14)
	if state.observed.size() < 7: return
	_button("采用两表重差术",{"type":"method","value":"double_difference"})
	_button("采用模型相似三角形",{"type":"method","value":"similar_triangles"})
	if state.method.is_empty(): return
	if state.hint > 0 or view.get("geometry_guides",false):
		var diagram := Diagram.new()
		diagram.method = state.method
		_body.add_child(diagram)
	var labels := ["100步换算为几尺","近表高（尺）","远表高（尺）","近表退距（尺）","远表退距（尺）","模型杆影（尺）","模型峰影（尺）","一丈等于几尺","峰高（尺）","峰高＝80丈又几尺"]
	for i in range(labels.size()): _number(labels[i],i,state.values[i])
	_label("选等式：")
	_button("H＝表高＋表高×间距÷(后退距−前退距)",{"type":"formula","value":"rod_plus_baseline_over_difference"})
	_button("H÷峰影＝表高÷杆影",{"type":"formula","value":"shadow_ratio"})
	_button("H＝间距÷(后退距＋前退距)",{"type":"formula","value":"baseline_over_sum"})
	if state.complete: _button("再验另一法",{"type":"submit"})

func _select_cell(index: int) -> void:
	_selection = index
	render(_view)

func _select_piece(index: int) -> void:
	_piece = index
	render(_view)

func _number(text: String, index: int, value: float) -> void:
	var row := HBoxContainer.new(); _body.add_child(row)
	var label := Label.new(); label.text = ("✓ " if _view.get("reflection_highlight",-1) == index else "")+text; label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; row.add_child(label)
	var number := SpinBox.new(); number.min_value = 0; number.max_value = 100000; number.step = 1
	number.value = value; number.custom_minimum_size.x = 100; number.update_on_text_changed = false
	number.set_meta("puzzle_focus","number:%d" % index)
	row.add_child(number)
	number.value_changed.connect(func(v: float): input_submitted.emit({"type":"set","index":index,"value":int(v)}))

func _label(text: String, font_size: int = 16) -> void:
	var label := Label.new(); label.text = text; label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size",font_size); _body.add_child(label)

func _button(text: String, action: Dictionary, parent: Node = null) -> Button:
	var button := Button.new(); button.text = text
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.custom_minimum_size.y = 30; button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	(parent if parent != null else _body).add_child(button)
	button.set_meta("puzzle_focus", "action:"+JSON.stringify(action) if not action.is_empty() else "button:"+text)
	if not action.is_empty(): button.pressed.connect(func(): input_submitted.emit(action.duplicate(true)))
	return button

func _restore_focus(key: String) -> void:
	var pending: Array[Node] = [_body]
	while not pending.is_empty():
		var node: Node = pending.pop_back()
		if node.get_meta("puzzle_focus", "") == key:
			if node is SpinBox: node.get_line_edit().grab_focus()
			elif node is Control: node.grab_focus()
			return
		for child in node.get_children(): pending.append(child)

func _restore_presentation(revision: int, scroll_y: int, focus_key: String) -> void:
	if not is_inside_tree(): return
	# Container minimum-size and scrollbar range updates are deferred by Godot.
	await get_tree().process_frame
	if revision != _render_revision or not is_inside_tree(): return
	if not focus_key.is_empty(): _restore_focus(focus_key)
	_scroll.scroll_vertical = scroll_y
	_scroll.follow_focus = true
