extends VBoxContainer
## Stable controls: updates replace label text, never delete the focused input.
signal input_submitted(action: Dictionary)
signal close_requested
var _view: Dictionary = {}
var _labels: Dictionary = {}
var _selectors: Dictionary = {}
var _numbers: Dictionary = {}
var _built_id := ""
var _demo: Button
var _submit: Button
var _hint_button: Button

func render(view: Dictionary) -> void:
	_view = view.duplicate(true)
	if _built_id != view.puzzle_id:
		for c in get_children(): remove_child(c); c.queue_free()
		_labels.clear(); _selectors.clear(); _numbers.clear()
		_built_id = view.puzzle_id
		_build()
	_refresh()

func _label(key: String, text: String = "") -> void:
	var label := Label.new(); label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(label); _labels[key] = label

func _button(text: String, callback: Callable) -> Button:
	var b := Button.new(); b.text = text; b.custom_minimum_size.y = 32
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(b); b.pressed.connect(callback); return b

func _send(a: Dictionary) -> void:
	input_submitted.emit(a)

func _select(key: String, title: String, n: int, prefix: String) -> void:
	_label(key+"_title",title)
	var select := OptionButton.new()
	for i in range(n): select.add_item(prefix + str(i+1),i)
	select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	select.set_meta("puzzle_focus","ch03:"+key)
	add_child(select); _selectors[key] = select

func _number(key: String, title: String, initial: int) -> void:
	var row := HBoxContainer.new(); add_child(row)
	var l := Label.new(); l.text = title; l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL; row.add_child(l)
	var s := SpinBox.new(); s.min_value = -1000000; s.max_value = 1000000; s.step = 1; s.value = initial
	s.custom_minimum_size.x = 110; s.update_on_text_changed = false; s.set_meta("puzzle_focus","ch03:"+key)
	row.add_child(s); _numbers[key] = s

func _selected(key: String) -> int:
	return _selectors[key].selected

func _value(key: String) -> int:
	return int(_numbers[key].value)

func _build() -> void:
	add_theme_constant_override("separation",7)
	_label("title",_view.title)
	_label("instruction",_view.instruction)
	_label("keys","鼠标选择；Tab切换，方向键调整，Enter确认。题面竖向滚动；收起后进度保留。")
	var id: String = _view.puzzle_id
	if id == "interaction_ch03_tea":
		_label("tea")
		for i in range(3):
			_button("第%d盏：放入一份" % (i+1),_send.bind({"type":"tea_transfer","cup":i,"amount":1}))
			_button("第%d盏：取回一份" % (i+1),_send.bind({"type":"tea_transfer","cup":i,"amount":-1}))
	elif id == "trial_ch03_qingyuan":
		_label("cue")
		_button("观察袖掌转斜",_send.bind({"type":"observe_transition"}))
		_button("守住门户，退让半步",_send.bind({"type":"guard_then_retreat"}))
		_button("认输收势，退回阶下",_send.bind({"type":"yield_and_withdraw"}))
	else:
		var n: int = _view.size
		_label("stage")
		_label("symbols")
		_select("symbol","① 选一个未知符号",n,"x")
		_select("column","放到哪一列？（每符号只能占一列）",n,"第")
		_button("把所选符号放入所选列",func(): _send({"type":"assign_symbol_to_column","symbol":_selected("symbol"),"column":_selected("column")}))
		_label("equation_title","② 当前等价方程（零项省略；按已分配列序显示）")
		for i in range(n): _label("equation_%d" % i)
		_label("example","如何消元：若第5行 x5+x6=11，第6行 x6=6，令第5行减第6行的1倍，便得到 x5=5。先从最末行向上做即可。")
		_select("row","要改变哪一行？",n,"第")
		_select("source","减去哪一行？／交换的另一行",n,"第")
		_number("factor_n","倍数分子（整数）",1)
		_number("factor_d","倍数分母（非零整数）",1)
		_button("目标行 − 来源行 × 倍数（两侧同时）",func(): _send({"type":"subtract_known_row","row":_selected("row"),"source":_selected("source"),"numerator":_value("factor_n"),"denominator":_value("factor_d")}))
		_button("交换这两行",func(): _send({"type":"swap_rows","row":_selected("row"),"source":_selected("source")}))
		_button("目标行两侧同乘倍数",func(): _send({"type":"scale_row","row":_selected("row"),"numerator":_value("factor_n"),"denominator":_value("factor_d")}))
		_label("values")
		_select("value_symbol","③ 每行只剩一个未知数后，选要填的符号",n,"x")
		_number("value_n","数值分子",0)
		_number("value_d","数值分母",1)
		_button("记录这个未知数的值",func(): _send({"type":"enter_value","symbol":_selected("value_symbol"),"numerator":_value("value_n"),"denominator":_value("value_d")}))
		_label("original_title","④ 回到原题逐式验算（改变任何填值需重新验）")
		for i in range(n):
			_label("original_%d" % i)
			_button("把填值代回第%d原式" % (i+1),_send.bind({"type":"substitute_back","row":i}))
	_submit = _button("检查全部过程，完成本题",_send.bind({"type":"submit"}))
	_button("撤回上一步（提示和协助标记保留）",_send.bind({"type":"undo"}))
	_button("重新开始本题（不扣生命或经验）",_send.bind({"type":"reset"}))
	_hint_button = _button("提示 0/3",_send.bind({"type":"hint"}))
	_label("hint")
	_label("operation")
	_label("preview")
	_demo = _button("同意协助：执行上面这一小步",_send.bind({"type":"demo_next_explained"}))
	_label("message")
	_button("收起题板，回到现场",func(): close_requested.emit())

func _refresh() -> void:
	var s: Dictionary = _view.state
	_labels.message.text = _view.message
	_labels.operation.text = _view.get("last_row_change","")
	_labels.operation.visible = not _labels.operation.text.is_empty()
	_labels.hint.text = _view.hint_text
	_hint_button.text = "提示 %d/3" % s.hint
	_demo.visible = s.hint >= 3 and not s.complete
	_labels.preview.visible = _demo.visible
	_labels.preview.text = "下一步预览：" + _view.next_demo
	_submit.disabled = s.complete or _view.puzzle_id == "trial_ch03_qingyuan"
	if _view.puzzle_id == "interaction_ch03_tea":
		_labels.tea.text = "茶盘剩余%d份；第一盏%d份，第二盏%d份，第三盏%d份。" % [s.tray,s.cups[0],s.cups[1],s.cups[2]]
	elif _view.puzzle_id == "trial_ch03_qingyuan":
		_labels.cue.text = ["当前：袖掌由正转斜，先读招势。","当前：虚招露隙，宜守退。","当前：招路被克，应收势认输。","已退回阶下，恢复梁萧视角。"][s.step]
	else:
		var n: int = _view.size
		_labels.stage.text = "已做%d次行相减，原式代回%d/%d；%s" % [s.eliminations,s.substitutions.size(),n,"已记录协助" if s.assisted else "自主推演"]
		var columns: Array[String] = []; var values: Array[String] = []
		for i in range(n):
			columns.append("第%d列：%s" % [i+1,"未分配" if s.columns[i] < 0 else "x%d" % (s.columns[i]+1)])
			values.append("x%d=%s" % [i+1,ChapterThreePuzzleResolver.text_fraction(s.values[i])])
			_labels["equation_%d" % i].text = _view.equations[i]
			var original := "x%d+x%d=%d" % [i+1,i+2,2*i+3] if i < n-1 else "x%d=%d" % [n,n]
			_labels["original_%d" % i].text = "第%d原式：%s %s" % [i+1,original,"✓ 已代回" if i in s.substitutions else "待代回"]
		_labels.symbols.text = "\n".join(columns)
		_labels.values.text = "已填值：\n" + "，".join(values)
