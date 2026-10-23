extends "res://scripts/ui/objective_battle_panel.gd"
## Compact three-person commands. All legal options come from the verified engine view.
var slots:Dictionary={}
var epoch=0
func _text(parent:Node,key:String,text:String,small:bool)->Label:
 var label:=Label.new();label.name=key;label.text=text;label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;label.add_theme_font_size_override("font_size",12 if small else 17);parent.add_child(label);slots[key]=label;return label
func _control(parent:Node,key:String,text:String,callback:Callable,disabled:bool,small:bool)->Button:
 var b:=Button.new();b.name=key;b.text=text;b.disabled=disabled;b.custom_minimum_size.y=24 if small else 34;b.size_flags_horizontal=Control.SIZE_EXPAND_FILL;b.add_theme_font_size_override("font_size",12 if small else 16);parent.add_child(b);slots[key]=b
 var born:int=epoch
 b.pressed.connect(func():
  if born==epoch and is_inside_tree() and is_visible_in_tree() and b.is_inside_tree() and not b.disabled:callback.call())
 return b
func render(snapshot:Dictionary,skills:Dictionary,ready:bool)->void:
 var old_scroll:int=slots.details_scroll.scroll_vertical if slots.has("details_scroll") else 0
 epoch+=1
 for child in get_children():remove_child(child);child.queue_free()
 slots.clear();view=snapshot.duplicate(true)
 var small:=get_viewport_rect().size.y<=440;add_theme_constant_override("separation",3 if small else 8)
 _text(self,"heading",view.encounter.name+" · 第%d轮"%view.round,small)
 _text(self,"objective",view.objective.summary,small)
 var scroll:=ScrollContainer.new();scroll.name="details_scroll";scroll.custom_minimum_size.y=52 if small else 124;scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;add_child(scroll);slots.details_scroll=scroll
 var details:=VBoxContainer.new();details.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(details);scroll.set_deferred("scroll_vertical",old_scroll)
 for a in view.actors:
  if a.team=="enemy" and not a.defeated:_text(details,a.id,"%s · 气血%d/%d%s"%[a.name,a.hp,a.max_hp," · 韧性保护" if int(a.protected_through)>=int(view.round) else ""],small)
 for intent in view.intents:
  if not intent.executed:_text(details,intent.intent_id,"意图 · "+intent.name,small)
 if view.get("input_error","")!="":_text(details,"error",str(view.input_error),small)
 for n in range(maxi(0,view.events.size()-6),view.events.size()):
  var e:Dictionary=view.events[n]
  if e.type in ["feng_rescued","wolf_control_broken","feint_miss","advice","wolves_scatter"]:_text(details,"log"+str(n),{"feng_rescued":"风怜已脱险","wolf_control_broken":"群狼失控，转噬持哨者","feint_miss":"虚实诱导令敌招落空","advice":"风怜直言提醒，梁萧稳住心神","wolves_scatter":"替身倒下，狼群散去"}[e.type],small)
 var columns:=HBoxContainer.new();columns.add_theme_constant_override("separation",8);add_child(columns)
 for a in view.actors:
  if a.team!="party":continue
  var column:=VBoxContainer.new();column.size_flags_horizontal=Control.SIZE_EXPAND_FILL;columns.add_child(column)
  _text(column,a.id+"_vitals","%s%s\n血%d/%d · 气%d/%d"%[a.name," · 气竭" if a.defeated else "",a.hp,a.max_hp,a.mp,a.max_mp],small)
  var picker:=OptionButton.new();picker.name=a.id+"_skills";picker.fit_to_longest_item=false;picker.size_flags_horizontal=Control.SIZE_EXPAND_FILL;picker.add_theme_font_size_override("font_size",12 if small else 16);column.add_child(picker);slots[picker.name]=picker
  for skill_id in a.skills:
   picker.add_item(str(skills[skill_id].get("name",SKILL_NAMES.get(skill_id,skill_id)))+" · %d气"%int(view.skill_costs[a.id][skill_id]));picker.set_item_metadata(picker.item_count-1,skill_id)
  var target:=OptionButton.new();target.name=a.id+"_target";target.fit_to_longest_item=false;target.size_flags_horizontal=Control.SIZE_EXPAND_FILL;target.add_theme_font_size_override("font_size",12 if small else 16);column.add_child(target);slots[target.name]=target
  var actor_id:String=a.id;var born:int=epoch
  var confirm:=_control(column,a.id+"_confirm","编排此招",func():
   if picker.selected>=0 and target.selected>=0:command_requested.emit(actor_id,str(picker.get_item_metadata(picker.selected)),str(target.get_item_metadata(target.selected)),int(view.revision)),false,small)
  var update_targets:Callable=func(_index:int):
   if born!=epoch or not picker.is_inside_tree():return
   target.clear()
   if picker.selected<0:return
   for legal in view.legal_commands.get(actor_id,[]):
    if legal.skill_id==picker.get_item_metadata(picker.selected):target.add_item(_actor_name(legal.target_id));target.set_item_metadata(target.item_count-1,legal.target_id)
   confirm.disabled=target.item_count==0 or view.outcome!=""
  picker.item_selected.connect(update_targets)
  if view.commands.has(a.id):
   for n in range(picker.item_count):
    if picker.get_item_metadata(n)==view.commands[a.id].skill_id:picker.select(n)
  update_targets.call(picker.selected)
  if view.commands.has(a.id):
   for n in range(target.item_count):
    if target.get_item_metadata(n)==view.commands[a.id].target_id:target.select(n)
  _text(column,a.id+"_pending","已编排" if view.commands.has(a.id) else "尚未编排",small)
 var footer:=HBoxContainer.new();add_child(footer)
 _control(footer,"resolve","结算本回合",func():resolve_requested.emit(),not ready,small)
 _control(footer,"retry","战前重试",func():retry_requested.emit(),view.outcome=="victory",small)
 _control(footer,"continue","收招继续",func():continue_requested.emit(),view.outcome!="victory",small)
 _control(footer,"leave","暂歇",func():leave_requested.emit(),false,small)
