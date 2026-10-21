extends SceneTree
const Helper=preload("res://scripts/ui/chapter_ten_world_ui.gd")
var checks:=0
var failures:=0
class FakeStory extends RefCounted:
	var active_chapter:=10
	var token:="chapter10:test:0"
	func current_token()->String:return token
class FakeMain extends Control:
	var story=FakeStory.new()
	var mode:="world_puzzle"
	var header:=Label.new()
	var objective:=Label.new()
	var notice:=Label.new()
	var speaker:=Label.new()
	var dialogue_text:=Label.new()
	var dialogue_panel:=PanelContainer.new()
	var actions:=HBoxContainer.new()
	var submitted:Array=[]
	var helper=Helper.new()
	var current_view:Dictionary={}
	func _ready()->void:
		add_child(header);add_child(objective);add_child(notice)
		add_child(dialogue_panel);dialogue_panel.position=Vector2(12,100);dialogue_panel.size=Vector2(616,130)
		var column:=VBoxContainer.new();dialogue_panel.add_child(column)
		column.add_child(speaker);column.add_child(dialogue_text);column.add_child(actions)
		dialogue_text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	func _clear(node:Node)->void:
		for c in node.get_children():node.remove_child(c);c.queue_free()
	func _button(text:String,callback:Callable,parent:Node)->Button:
		var b:=Button.new();b.text=text;b.pressed.connect(callback);parent.add_child(b);return b
	func _world_puzzle_input(action:Dictionary)->void:
		submitted.append(action.duplicate(true));helper.render(self,current_view)
	func _show_menu()->void:mode="menu"
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func key(code:int,pressed:bool=true,echo:bool=false)->InputEventKey:
	var e:=InputEventKey.new();e.keycode=code;e.pressed=pressed;e.echo=echo;return e
func set_view(m:FakeMain,kind:String)->void:
	m.current_view={"title":"scene","body":"narrative","options":[],"state":{"stage":0},"world_state":{"at_target":true,"recollection":false},"silent":kind in ["farewell","shore_walk"],"timed_mode":kind}
	m.helper.render(m,m.current_view)
func frames(m:FakeMain,count:int)->void:
	for i in range(count):m.helper.tick(m,0.05)
func _initialize()->void:call_deferred("run")
func run()->void:
	root.size=Vector2i(640,360)
	var m:=FakeMain.new();root.add_child(m);await process_frame
	set_view(m,"farewell")
	check(not m.header.visible and not m.objective.visible and not m.notice.visible,"farewell hides status chrome")
	check(m.actions.get_child_count()==2,"farewell physical hold and pause only")
	check(m.helper.handle_input(m,key(KEY_E)),"farewell owns E")
	frames(m,4);check(m.submitted.is_empty(),"press and subperiod do not complete time")
	frames(m,1);check(m.submitted.size()==1 and m.submitted[0]=={"type":"hold","milliseconds":250},"focused quarter second submits real hold")
	frames(m,5);check(m.submitted.size()==2,"hold survives legitimate same-token rerender")
	m.helper.handle_input(m,key(KEY_E,false));frames(m,20);check(m.submitted.size()==2,"release stops hold")
	m.helper.handle_input(m,key(KEY_E));m.helper.tick(m,60);check(m.submitted.size()==2,"stall cannot redeem elapsed minute")
	m.helper.set_focused(false);frames(m,20);check(m.submitted.size()==2,"focus loss gates elapsed time")
	m.helper.set_focused(true);frames(m,20);check(m.submitted.size()==2,"focus return requires new hold")
	m.helper.handle_input(m,key(KEY_E));m.mode="menu";frames(m,20);m.mode="world_puzzle";frames(m,20);check(m.submitted.size()==2,"menu clears held input no resumption")
	m.helper.handle_input(m,key(KEY_E));m.dialogue_panel.hide();frames(m,20);m.dialogue_panel.show();frames(m,20);check(m.submitted.size()==2,"hidden panel cannot advance")
	m.helper.handle_input(m,key(KEY_E));m.helper.handle_input(m,key(KEY_F9));frames(m,20);check(m.submitted.size()==2,"load key stops held time before loader")
	var old_button:Button=m.actions.get_child(0);m.story.token="chapter10:test:1";set_view(m,"farewell");old_button.button_down.emit();frames(m,20);check(m.submitted.size()==2,"stale token mouse callback rejected")
	var hold:Button=m.actions.get_child(0);hold.button_down.emit();frames(m,5);check(m.submitted.size()==3,"mouse physical hold advances")
	var release:=InputEventMouseButton.new();release.button_index=MOUSE_BUTTON_LEFT;release.pressed=false;m.helper.handle_input(m,release);frames(m,10);check(m.submitted.size()==3,"global mouse release survives control recreation")
	m.helper.reset();check(m.header.visible and m.notice.visible,"reset restores chrome")
	m.story.token="chapter10:shore:0";set_view(m,"shore_walk")
	check(m.actions.get_child(4).disabled,"shore exit unavailable until model offers exit")
	m.helper.handle_input(m,key(KEY_RIGHT));frames(m,5)
	check(m.submitted.back()=={"type":"walk","dx":1,"dy":0,"milliseconds":250},"shore held direction produces one actual pixel tick")
	var before:=m.submitted.size();m.helper.handle_input(m,key(KEY_LEFT));frames(m,10);check(m.submitted.size()==before,"opposite directions earn no walking time")
	m.helper.handle_input(m,key(KEY_LEFT,false));m.helper.handle_input(m,key(KEY_RIGHT,false));m.helper.handle_input(m,key(KEY_ENTER));check(m.submitted.back()=={"type":"interact"},"shore requires explicit exit interaction")
	await process_frame;await process_frame
	for control in m.actions.get_children():check(Rect2(Vector2.ZERO,Vector2(640,360)).encloses(control.get_global_rect()),"640 shore controls visible")
	m.helper.reset();m.story.token="chapter10:stove:0";set_view(m,"recollection");frames(m,5);check(m.submitted.back()=={"type":"linger","milliseconds":250},"hearth stillness recorded")
	m.current_view.world_state.at_target=false;m.helper.render(m,m.current_view);before=m.submitted.size();frames(m,20);check(m.submitted.size()==before,"distant hearth gives no recollection time")
	m.helper.handle_input(m,key(KEY_E));check(m.submitted.back()=={"type":"leave"},"recollection can be skipped immediately")
	m.story.token="chapter10:regular:0";set_view(m,"")
	m.current_view.options=[{"label":"observe","action":{"type":"interact","target":"A"}},{"label":"escort","action":{"type":"interact","target":"B"}}];m.helper.render(m,m.current_view)
	var picker:OptionButton=m.actions.get_child(0);picker.item_selected.emit(1)
	m.current_view.options.reverse();m.helper.render(m,m.current_view)
	picker=m.actions.get_child(0);check(picker.selected==0,"semantic identity retained across reordered options")
	var execute:Button=m.actions.get_child(1);execute.pressed.emit();check(m.submitted.back().target=="B","execute uses semantic selected action")
	before=m.submitted.size();execute.pressed.emit();check(m.submitted.size()==before,"detached prior epoch button cannot submit twice")
	await process_frame;await process_frame
	for control in m.actions.get_children():check(Rect2(Vector2.ZERO,Vector2(640,360)).encloses(control.get_global_rect()),"640 footer control visible")
	m.helper.reset();m.queue_free();await process_frame
	print("Chapter ten timed world UI: ",checks," checks, ",failures," failures")
	quit(1 if failures else 0)
