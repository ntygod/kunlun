extends VBoxContainer
## Stable inputs; the chapter resolver owns validation, progress and proof.
signal input_submitted(action: Dictionary)
signal close_requested
const Board = preload("res://scripts/ui/chapter_seven_formation_board.gd")
const COLUMNS := ["supply","wet","fodder"]
const PEOPLE := ["npc_zhao_shan","npc_wang_ke","npc_hu_san"]
const DIR_NAMES := {"N":"北↑","E":"东→","S":"南↓","W":"西←"}
var _view: Dictionary = {}
var _built_id := ""
var _labels: Dictionary = {}
var _selects: Dictionary = {}
var _fields: Dictionary = {}
var _buttons: Dictionary = {}
var _board: Control
var _timer: Timer
var _selected := 0
var _busy := false

func render(view: Dictionary) -> void:
	_view=view.duplicate(true)
	var id := str(view.get("puzzle_id",""))
	if id!=_built_id:
		for child in get_children():
			remove_child(child)
			child.queue_free()
		_labels.clear(); _selects.clear(); _fields.clear(); _buttons.clear()
		_board=null; _timer=null; _selected=0; _built_id=id
		_build()
	_refresh()

func _row(parent: Node) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",4)
	parent.add_child(row)
	return row

func _label(key: String, text: String, parent: Node) -> Label:
	var label := Label.new()
	label.text=text
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	parent.add_child(label)
	_labels[key]=label
	return label

func _button(key: String, title: String, parent: Node, action: Dictionary = {}, callback: Callable = Callable()) -> Button:
	var button := Button.new()
	button.text=title
	button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	button.set_meta("puzzle_focus","ch07:"+key)
	parent.add_child(button)
	_buttons[key]=button
	if callback.is_valid(): button.pressed.connect(callback)
	else: button.pressed.connect(func(): _send(action))
	return button

func _select(key: String, options: Array, parent: Node) -> OptionButton:
	var select := OptionButton.new()
	select.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	for option in options: select.add_item(str(option))
	select.set_meta("puzzle_focus","ch07:"+key)
	parent.add_child(select)
	_selects[key]=select
	return select

func _field(key: String, placeholder: String, parent: Node) -> LineEdit:
	var field := LineEdit.new()
	field.placeholder_text=placeholder
	field.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	field.custom_minimum_size.x=70
	field.set_meta("puzzle_focus","ch07:"+key)
	parent.add_child(field)
	_fields[key]=field
	return field

func _send(action: Dictionary) -> void:
	if _busy: return
	input_submitted.emit(action)

func _build() -> void:
	add_theme_constant_override("separation",3)
	var inherited_font := get_theme_default_font()
	theme=Theme.new()
	theme.default_font_size=14
	theme.default_font=inherited_font
	for state_name in ["normal","hover","pressed","disabled","focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color=Color("46534c") if state_name in ["hover","focus"] else Color("25363b")
		style.content_margin_left=6
		style.content_margin_right=6
		style.content_margin_top=2
		style.content_margin_bottom=2
		theme.set_stylebox(state_name,"Button",style)
	_label("title",str(_view.get("title","")),self)
	match _built_id:
		"grain_ch07_accounts": _build_grain()
		"letters_ch07_l03": _build_letters()
		"formation_ch07_drill","formation_ch07_regroup": _build_formation()
	_label("message","",self)
	var footer := _row(self)
	_button("finish","确认收束",footer,{"type":"finish"})
	_button("hint","提示",footer,{"type":"hint"})
	_button("assist","协助一步",footer,{"type":"assist_step_v1"})
	_button("retry","重试",footer,{"type":"retry"})
	_button("close","暂歇",footer,{},func(): close_requested.emit())
	_label("hint","",self)

func _build_grain() -> void:
	_label("rules","运出40,000，交粮36,300石；给养x、雨湿y、饲料z。\nx=2y；z=y+500；x+y+z=总差。只收非负整数石。",self)
	var paper := _row(self)
	_select("paper",["给养簿：x=2y","湿袋：雨湿为y","饲料簿：z=y+500"],paper)
	_select("column",["给养栏x","雨湿栏y","饲料栏z"],paper)
	_button("paper","放纸据",paper,{},func():_send({"type":"place_paper","paper":COLUMNS[_selects.paper.selected],"column":COLUMNS[_selects.column.selected]}))
	var difference := _row(self)
	_select("difference",["40000−36300 = 3700","40000+36300 = 76300","36300−40000 = −3700"],difference)
	_button("difference","核差额",difference,{},func():_send({"type":"difference","value":[3700,76300,-3700][_selects.difference.selected]}))
	var equation := _row(self)
	_select("equation",["4y+500=3700","3y+500=3700","4y-500=3700"],equation)
	_button("equation","合关系",equation,{},func():_send({"type":"equation","value":["4y+500=3700","3y+500=3700","4y-500=3700"][_selects.equation.selected]}))
	var values := _row(self)
	_select("value_column",["给养x","雨湿y","饲料z"],values)
	_field("value","输入整数石",values)
	_button("value","记入此栏",values,{},func():_send({"type":"value","column":COLUMNS[_selects.value_column.selected],"value":_fields.value.text}))
	_label("progress","",self)

func _build_letters() -> void:
	_label("rules","逐人选取信文，再落笔、封蜡、将信袋交回本人待寄。\n信袋是各人私物；三封交回后才可收束。",self)
	var choices := _row(self)
	_select("person",["赵山","王可","胡三"],choices).item_selected.connect(func(_i):_refresh_letter_preview())
	_select("content",["报喜：只报平安，宽慰家人","实情：如实写军旅处境，也报平安"],choices).item_selected.connect(func(_i):_refresh_letter_preview())
	_label("letter_preview","",self)
	var row := _row(self)
	_button("write","按所选信文落笔",row,{},func():_send({"type":"write_letter","person":PEOPLE[_selects.person.selected],"content":(["joy","truth"][_selects.content.selected])+":"+PEOPLE[_selects.person.selected]}))
	_button("seal","封蜡",row,{},func():_send({"type":"seal_letter","person":PEOPLE[_selects.person.selected]}))
	_button("return","交回本人",row,{},func():_send({"type":"return_letter","person":PEOPLE[_selects.person.selected]}))
	_label("progress","",self)

func _build_formation() -> void:
	var row := _row(self)
	_board=Board.new()
	row.add_child(_board)
	_board.cell_chosen.connect(_choose_cell)
	var side := VBoxContainer.new()
	side.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	side.add_theme_constant_override("separation",3)
	row.add_child(side)
	_label("wave","",side)
	_label("rules","点人→空格，自动逐格走；北在上。\n前排面敌，其余面空隙；禁箭。\n浅框字=目标位，金十字=中心。",side)
	var turning := _row(side)
	_select("unit",["梁","土","囊","李","杨","王"],turning).item_selected.connect(func(index):_selected=index;_refresh_board())
	for direction in ["N","E","S","W"]:
		var d: String=direction
		_button("turn_"+d,DIR_NAMES[d],turning,{},func():_send({"type":"turn","unit":_selected,"direction":d}))
	_label("selected","",side)
	var commands := _row(side)
	_button("undo","撤回移动",commands,{"type":"undo_move"})
	_button("horn","鸣号验阵",commands,{"type":"horn"})
	_timer=Timer.new()
	_timer.wait_time=0.09
	_timer.timeout.connect(_step_animation)
	add_child(_timer)

func _choose_cell(x: int, y: int) -> void:
	if _busy: return
	var positions: Array=_view.get("state",{}).get("positions",[])
	for i in range(positions.size()):
		if positions[i]==[x,y]:
			_selected=i
			_selects.unit.select(i)
			_refresh_board()
			return
	_send({"type":"move","unit":_selected,"x":x,"y":y})

func _step_animation() -> void:
	# Hidden/closed modal and SceneTree pause cannot advance an unseen transaction.
	if not is_visible_in_tree() or get_tree().paused: return
	if not _busy:
		_timer.stop()
		return
	input_submitted.emit({"type":"step_move"})

func _refresh_letter_preview() -> void:
	var name: String=["赵山","王可","胡三"][_selects.person.selected]
	var method: String=["joy","truth"][_selects.content.selected]
	var texts: Dictionary=_view.get("letter_texts",{})
	var excerpt: String=str(texts.get(method,{}).get(PEOPLE[_selects.person.selected],"信文尚未载入。"))
	_labels.letter_preview.text="%s信文：%s\n此前约定口吻：%s。" % [name,excerpt,"报喜" if _view.get("state",{}).get("method","joy")=="joy" else "实情"]

func _refresh_board() -> void:
	if not is_instance_valid(_board): return
	_board.render(_view,_selected,_busy)
	var state: Dictionary=_view.get("state",{})
	var positions: Array=state.get("positions",[])
	var directions: Array=state.get("directions",[])
	if _selected<positions.size() and _selected<directions.size():
		_labels.selected.text="%s %s 面%s%s" % [["梁","土","囊","李","杨","王"][_selected],str(positions[_selected]),DIR_NAMES.get(directions[_selected],"?")," · 行进中" if _busy else ""]

func _assist_preview() -> String:
	var action: Dictionary=_view.get("next_action",{})
	match str(action.get("type","")):
		"place_paper": return "将%s纸据归入对应栏。" % {"supply":"给养","wet":"雨湿","fodder":"饲料"}.get(action.get("paper",""),"")
		"difference": return "填写总差3700石。"
		"equation": return "合并为4y+500=3700。"
		"value": return "填写%s=%s。" % [action.get("column",""),action.get("value","")]
		"plan_formation": return "先规划本波合法四邻移动路线。"
		"move": return "移动%s至(%s,%s)，逐格验证。" % [["梁","土","囊","李","杨","王"][int(action.get("unit",0))],action.get("x",0),action.get("y",0)]
		"turn": return "将%s转向%s。" % [["梁","土","囊","李","杨","王"][int(action.get("unit",0))],DIR_NAMES.get(action.get("direction","N"),"")]
		"horn": return "鸣号检验本波全阵。"
		"write_letter": return "为%s按已选口吻落笔。" % {"npc_zhao_shan":"赵山","npc_wang_ke":"王可","npc_hu_san":"胡三"}.get(action.get("person",""),"")
		"seal_letter": return "为%s的信袋封蜡。" % {"npc_zhao_shan":"赵山","npc_wang_ke":"王可","npc_hu_san":"胡三"}.get(action.get("person",""),"")
		"return_letter": return "把信袋交回%s本人。" % {"npc_zhao_shan":"赵山","npc_wang_ke":"王可","npc_hu_san":"胡三"}.get(action.get("person",""),"")
		"finish": return "检验并收束本题。"
	return "继续当前合法步骤。"

func _refresh() -> void:
	var state: Dictionary=_view.get("state",{})
	_busy=not state.get("moving",{}).is_empty()
	var complete: bool=state.get("complete",false)
	_buttons.finish.visible=not _built_id.begins_with("formation")
	for key in _buttons:
		_buttons[key].disabled=(_busy or complete) and key!="close"
	for control in _selects.values(): control.disabled=_busy or complete
	for field in _fields.values(): field.editable=not _busy and not complete
	_labels.message.text=str(_view.get("message",""))
	_labels.hint.text=str(_view.get("hint_text",""))
	if int(state.get("hint",0))>=3 and not complete:
		_labels.hint.text+="\n协助下一步："+_assist_preview()
	_labels.hint.visible=not _labels.hint.text.is_empty()
	_buttons.hint.text="提示 %d/3" % int(state.get("hint",0))
	_buttons.assist.disabled=_busy or complete or int(state.get("hint",0))<3
	_buttons.assist.tooltip_text=_assist_preview()
	match _built_id:
		"grain_ch07_accounts":
			var papers: Dictionary=state.get("papers",{})
			var values: Dictionary=state.get("values",{})
			_labels.progress.text="纸据%d/3 差额%s 关系%s｜给养%s / 雨湿%s / 饲料%s 石" % [papers.size(),"✓" if state.get("difference",false) else "未核","✓" if state.get("equation",false) else "未合",str(values.get("supply","—")),str(values.get("wet","—")),str(values.get("fodder","—"))]
		"letters_ch07_l03":
			_refresh_letter_preview()
			var statuses: Array=[]
			var letters: Dictionary=state.get("letters",{})
			for i in range(3):
				var letter: Dictionary=letters.get(PEOPLE[i],{})
				statuses.append("%s：%s" % [["赵","王","胡"][i],"已交回" if letter.get("returned",false) else ("已封" if letter.get("sealed",false) else ("已写" if letter.get("written",false) else "未写"))])
			_labels.progress.text=" / ".join(statuses)
		"formation_ch07_drill","formation_ch07_regroup":
			var spec: Dictionary=_view.get("wave_spec",{})
			_labels.wave.text="第%d/3波 · %s阵，阵朝%s\n骑军从%s来；%s留隙" % [mini(3,int(state.get("wave",0))+1),"圆" if spec.get("shape","R")=="R" else "方",DIR_NAMES.get(spec.get("orientation","E"),"?"),DIR_NAMES.get(spec.get("enemy","W"),"?"),DIR_NAMES.get(spec.get("gap","E"),"?")]
			_buttons.undo.disabled=_busy or complete or not state.get("undo_available",false)
			_refresh_board()
			if _busy and _timer.is_stopped(): _timer.start()
			elif not _busy: _timer.stop()
