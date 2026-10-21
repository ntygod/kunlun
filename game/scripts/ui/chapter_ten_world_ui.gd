extends RefCounted
## Chapter-ten input/presentation only. Time comes from focused visible frames;
## accepted replay commands alone do not prove a human's wall-clock playthrough.
const PERIOD := 0.25
const DIRECTIONS := {KEY_LEFT:Vector2i.LEFT, KEY_A:Vector2i.LEFT, KEY_RIGHT:Vector2i.RIGHT, KEY_D:Vector2i.RIGHT, KEY_UP:Vector2i.UP, KEY_W:Vector2i.UP, KEY_DOWN:Vector2i.DOWN, KEY_S:Vector2i.DOWN}
var _owner: WeakRef
var _token := ""
var _epoch := 0
var _view: Dictionary = {}
var _held: Dictionary = {}
var _mouse_action := ""
var _elapsed := 0.0
var _focused := true
var _selected_key := ""

func reset() -> void:
	_held.clear(); _mouse_action=""; _elapsed=0.0; _token=""; _epoch+=1
	var main = _owner.get_ref() if _owner != null else null
	if is_instance_valid(main):
		for control in [main.header,main.objective,main.notice,main.speaker]:
			if is_instance_valid(control): control.show()
	_view={}

func set_focused(value: bool) -> void:
	_focused=value
	_held.clear(); _mouse_action=""; _elapsed=0.0

func _valid(main: Node) -> bool:
	return is_instance_valid(main) and main.is_inside_tree() and main.is_visible_in_tree() and main.story.active_chapter==10 and main.mode=="world_puzzle" and main.dialogue_panel.is_visible_in_tree() and main.story.current_token()==_token

func _mode() -> String:
	if _view.get("direct_hold",false): return "farewell"
	if _view.get("timed_walk",false): return "shore_walk"
	if _view.get("recollection",false): return "recollection"
	return str(_view.get("timed_mode",""))

func _semantic(action: Dictionary) -> String:
	var names:Array=action.keys(); names.sort()
	var pairs:Array=[]
	for key in names: pairs.append([key,action[key]])
	return JSON.stringify(pairs)

func _dispatch(main: Node, action: Dictionary, born: int) -> void:
	if _focused and born==_epoch and _valid(main): main._world_puzzle_input(action)

func _button(main: Node, text: String, action: Dictionary, born: int) -> Button:
	var button:Button=main._button(text,func(): _dispatch(main,action,born),main.actions)
	button.custom_minimum_size=Vector2(64,34)
	button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	return button

func _hold_button(main: Node, text: String, held_action: String, born: int) -> Button:
	var button:Button=main._button(text,func(): pass,main.actions)
	button.custom_minimum_size=Vector2(68,34)
	button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	button.button_down.connect(func():
		if born==_epoch and _valid(main) and _focused: _mouse_action=held_action; _elapsed=0.0)
	button.button_up.connect(func():
		# Old controls may emit release after a legitimate timer rerender.
		if _mouse_action==held_action: _mouse_action=""; _elapsed=0.0)
	return button

func render(main: Node, view: Dictionary) -> bool:
	if main.story.active_chapter!=10: return false
	var token:String=main.story.current_token()
	if _owner==null or _owner.get_ref()!=main or _token!=token:
		reset(); _owner=weakref(main); _token=token; _selected_key=""
	_view=view.duplicate(true); _epoch+=1
	var born:=_epoch
	var quiet:bool=bool(view.get("silent",false))
	main.header.visible=not quiet; main.objective.visible=not quiet; main.notice.visible=not quiet
	main.speaker.visible=not quiet
	main.speaker.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	main.speaker.text=str(view.get("title",""))
	main.dialogue_text.text=str(view.get("body",""))
	if quiet:
		match _mode():
			"farewell": main.dialogue_text.text="方向键／WASD 靠近 · 按住 E／空格或下方按钮"
			"shore_walk": main.dialogue_text.text="按住方向键／WASD 或箭头行走 · E 继续行路"
			_: main.dialogue_text.text="E／空格 轻轻放下"
	main._clear(main.actions)
	match _mode():
		"farewell":
			var stage:int=int(view.get("state",{}).get("stage",0))
			_hold_button(main,"扶稳阿雪 · 按住" if stage==0 else "替她挡雨 · 按住","hold",born)
		"shore_walk":
			for pair in [["←","left"],["↑","up"],["↓","down"],["→","right"]]:
				_hold_button(main,pair[0],pair[1],born)
			var leave:Button=_button(main,"走向前路",{"type":"interact"},born)
			leave.disabled=view.get("options",[]).is_empty()
		"recollection":
			_button(main,"继续行路",{"type":"leave"},born)
		_:
			var options:Array=view.get("options",[])
			if options.size()==1:
				_button(main,str(options[0].label),options[0].action,born)
			elif not options.is_empty():
				var picker:=OptionButton.new()
				picker.custom_minimum_size=Vector2(140,34)
				picker.size_flags_horizontal=Control.SIZE_EXPAND_FILL
				picker.fit_to_longest_item=false; picker.clip_text=true
				picker.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
				var selected:=0
				for index in range(options.size()):
					picker.add_item(str(options[index].label))
					if _semantic(options[index].action)==_selected_key: selected=index
				picker.select(selected); _selected_key=_semantic(options[selected].action)
				picker.item_selected.connect(func(index:int):
					if born==_epoch and _valid(main): _selected_key=_semantic(options[index].action))
				main.actions.add_child(picker)
				var execute:Button=main._button("执行",func():
					for option in options:
						if _semantic(option.action)==_selected_key: _dispatch(main,option.action,born); return,main.actions)
				execute.custom_minimum_size=Vector2(68,34)
			if quiet: _button(main,"轻轻放下",{"type":"interact"},born)
	var pause:Button=main._button("暂歇",func():
		if born==_epoch and _valid(main): main._show_menu(),main.actions)
	pause.custom_minimum_size=Vector2(64,34)
	main.get_viewport().gui_release_focus()
	return true

func handle_input(main: Node, event: InputEvent) -> bool:
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and not event.pressed:
		_mouse_action=""; _elapsed=0.0
		return false
	if not event is InputEventKey: return false
	var key:int=event.physical_keycode if event.physical_keycode!=0 else event.keycode
	if event.keycode in [KEY_LEFT,KEY_RIGHT,KEY_UP,KEY_DOWN]: key=event.keycode
	if key in [KEY_ESCAPE,KEY_F5,KEY_F9]:
		_held.clear(); _mouse_action=""; _elapsed=0.0
		return false
	if not _valid(main) or not _focused: return false
	if not event.pressed:
		_held.erase(key); _elapsed=0.0
		return _mode() in ["farewell","shore_walk"] and (DIRECTIONS.has(key) or key in [KEY_E,KEY_SPACE])
	if event.echo: return _mode() in ["farewell","shore_walk"]
	for child in main.actions.get_children():
		if child is OptionButton and child.get_popup().visible: return false
	if _mode()=="farewell":
		if key in [KEY_E,KEY_SPACE]: _held[key]=true; return true
		if DIRECTIONS.has(key): _dispatch(main,{"type":"move","dx":DIRECTIONS[key].x,"dy":DIRECTIONS[key].y},_epoch); return true
	if _mode()=="shore_walk":
		if DIRECTIONS.has(key): _held[key]=true; return true
		if key in [KEY_E,KEY_SPACE,KEY_ENTER]: _dispatch(main,{"type":"interact"},_epoch); return true
	if _mode()=="recollection" and key in [KEY_E,KEY_SPACE,KEY_ENTER]:
		_dispatch(main,{"type":"leave"},_epoch); return true
	return false

func tick(main: Node, delta: float) -> void:
	if not _focused or not _valid(main) or main.get_tree().paused:
		_held.clear(); _mouse_action=""; _elapsed=0.0; return
	var action:Dictionary={}
	match _mode():
		"farewell":
			if _view.get("world_state",{}).get("at_target",false) and (_held.has(KEY_E) or _held.has(KEY_SPACE) or _mouse_action=="hold"): action={"type":"hold","milliseconds":250}
		"shore_walk":
			var direction:=Vector2i.ZERO
			for key in _held:
				if DIRECTIONS.has(key): direction+=DIRECTIONS[key]
			var mouse_dirs:Dictionary={"left":Vector2i.LEFT,"right":Vector2i.RIGHT,"up":Vector2i.UP,"down":Vector2i.DOWN}
			if mouse_dirs.has(_mouse_action): direction=mouse_dirs[_mouse_action]
			if direction.x!=0: direction=Vector2i(signi(direction.x),0)
			elif direction.y!=0: direction=Vector2i(0,signi(direction.y))
			if direction!=Vector2i.ZERO: action={"type":"walk","dx":direction.x,"dy":direction.y,"milliseconds":250}
		"recollection":
			if _held.is_empty() and _view.get("world_state",{}).get("at_target",false) and not _view.get("world_state",{}).get("recollection",false): action={"type":"linger","milliseconds":250}
	if action.is_empty(): _elapsed=0.0; return
	# Never redeem stalled, hidden or unfocused time. At most one quarter-second
	# command per rendered frame; fractional remainder is discarded on dispatch.
	_elapsed+=minf(maxf(delta,0.0),0.1)
	if _elapsed+0.000001<PERIOD: return
	_elapsed=0.0
	_dispatch(main,action,_epoch)
