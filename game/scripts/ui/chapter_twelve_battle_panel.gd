class_name ChapterTwelveBattlePanel
extends "res://scripts/ui/objective_battle_panel.gd"
const HERO="char_liang_xiao"
const X="char_hua_xiaoshuang"
var slots:Dictionary={}
var epoch:=0
func render(snapshot:Dictionary,_skills:Dictionary,ready:bool)->void:
 epoch+=1
 for child in get_children():remove_child(child);child.queue_free()
 slots.clear();view=snapshot.duplicate(true)
 var small:=get_viewport_rect().size.y<=440
 add_theme_constant_override("separation",2)
 _text(self,"heading","天香与蚩尤 · 第%d轮 · 协力%d/3 预留%d"%[view.round,view.objective.synergy,view.objective.reserved],small)
 _text(self,"objective",view.objective.summary,small)
 var scroll:=ScrollContainer.new();scroll.name="intent_scroll";scroll.custom_minimum_size.y=58 if small else 130;scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;add_child(scroll);slots.intent_scroll=scroll
 var details:=VBoxContainer.new();details.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(details)
 for a in view.actors:
  if a.team=="enemy" and not a.defeated:_text(details,a.id+"_hp","%s：%d/%d血%s"%[a.name,a.hp,a.max_hp," · 韧性保护" if a.protected_through>=view.round else ""],small)
 for i in view.intents:_text(details,i.intent_id,str(i.name)+( "（已取消）" if i.cancelled else ""),small)
 for prediction in view.objective.get("forecast",[]):_text(details,"forecast"+str(details.get_child_count()),prediction,small)
 _text(details,"guide","看清公开意图再编排。医术可对气竭同伴使用复苏；投药占晓霜一轮行动。",small)
 var columns:=HBoxContainer.new();columns.add_theme_constant_override("separation",8);add_child(columns)
 for member in view.actors:
  if member.team!="party":continue
  var id:String=member.id
  var actor:Dictionary={}
  for a in view.actors:
   if a.id==id:actor=a
  var column:=VBoxContainer.new();column.size_flags_horizontal=Control.SIZE_EXPAND_FILL;columns.add_child(column)
  _text(column,id+"_vitals","%s %d/%d血 %d/%d气"%[str(actor.get("name",id)),actor.hp,actor.max_hp,actor.mp,actor.max_mp],small)
  var skills:=OptionButton.new();skills.name=id+"_skills";skills.size_flags_horizontal=Control.SIZE_EXPAND_FILL;skills.fit_to_longest_item=false;skills.add_theme_font_size_override("font_size",12 if small else 16);column.add_child(skills);slots[skills.name]=skills
  for skill in actor.skills:
   if skill in ["CO_01","CO_02"]:continue
   var n:String=view.skill_data[skill].get("name",SKILL_NAMES.get(skill,skill))
   skills.add_item(n+" · %d气"%int(view.skill_costs[id][skill]));skills.set_item_metadata(skills.item_count-1,skill)
  var target:=OptionButton.new();target.name=id+"_target";target.fit_to_longest_item=false;target.add_theme_font_size_override("font_size",12 if small else 16);column.add_child(target);slots[target.name]=target
  var confirm:=_control(column,id+"_confirm","编排此招",func():
   if skills.selected>=0 and target.selected>=0:command_requested.emit(id,str(skills.get_item_metadata(skills.selected)),str(target.get_item_metadata(target.selected)),int(view.revision)),false,small)
  var change:Callable=func(_index:int):
   target.clear()
   var skill:String=str(skills.get_item_metadata(skills.selected))
   for legal in view.legal_commands[id]:
    if legal.skill_id!=skill:continue
    target.add_item(_actor_name(legal.target_id));target.set_item_metadata(target.item_count-1,legal.target_id)
   confirm.disabled=target.item_count==0 or view.outcome!=""
  skills.item_selected.connect(change)
  if view.commands.has(id):
   for i in range(skills.item_count):
    if skills.get_item_metadata(i)==view.commands[id].skill_id:skills.select(i)
  change.call(skills.selected)
  _text(column,id+"_pending","已选："+str(view.skill_data[view.commands[id].skill_id].get("name",SKILL_NAMES.get(view.commands[id].skill_id,view.commands[id].skill_id))) if view.commands.has(id) else "尚未编排",small)
 if view.encounter.kind=="medicine":
  var inspect:=_control(self,"inspect_herbs","观察三味药与鼎纹（不占行动）",func():
   var label:Label=slots.get("herb_observation")
   if is_instance_valid(label):label.visible=not label.visible,false,small)
  inspect.tooltip_text="青纹·风声→青叶；白纹·凝露→白花；赤纹·暖光→赤萼。仅为虚构游戏配对。"
  _text(details,"herb_observation","；".join(view.objective.herb_clues),small)
  slots.herb_observation.visible=false
 var footer:=HBoxContainer.new();add_child(footer)
 var combo_target:=""
 for legal in view.legal_commands.get(HERO,[]):
  if legal.skill_id=="CO_02":combo_target=legal.target_id;break
 _control(footer,"combo","合招·2格",func():command_requested.emit(HERO,"CO_02",combo_target,int(view.revision)),combo_target.is_empty(),small)
 var first_target:=""
 for legal in view.legal_commands.get(HERO,[]):
  if legal.skill_id=="CO_01":first_target=legal.target_id;break
 _control(footer,"combo_01","梁柳·2格",func():command_requested.emit(HERO,"CO_01",first_target,int(view.revision)),first_target.is_empty(),small)
 _control(footer,"resolve","结算",func():resolve_requested.emit(),not ready,small)
 _control(footer,"retry","重试",func():retry_requested.emit(),view.outcome=="victory",small)
 _control(footer,"continue","继续",func():continue_requested.emit(),view.outcome!="victory",small)
 _control(footer,"leave","暂歇",func():leave_requested.emit(),false,small)
 if view.get("input_error","")!="":_text(details,"error","未执行："+str(view.input_error),small)
 for i in range(maxi(0,view.events.size()-4),view.events.size()):
  var e:Dictionary=view.events[i]
  if e.type in ["damage","heal","poison_tick","shell_mana_drain","combo_executed","phase_changed"]:_text(details,"feedback"+str(i),{"damage":"承伤","heal":"治疗","poison_tick":"毒发","shell_mana_drain":"罡罩震气","combo_executed":"合招兑现","phase_changed":"阶段转换"}[e.type]+" · "+_actor_name(e.target)+" "+str(e.amount),small)
func _text(parent:Node,id:String,text:String,small:bool)->void:
 var label:=Label.new();label.name=id;label.text=text;label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;label.add_theme_font_size_override("font_size",12 if small else 16);parent.add_child(label);slots[id]=label
func _control(parent:Node,id:String,text:String,callback:Callable,disabled:bool,small:bool)->Button:
 var b:=Button.new();b.name=id;b.text=text;b.disabled=disabled;b.size_flags_horizontal=Control.SIZE_EXPAND_FILL;b.custom_minimum_size.y=24 if small else 34;b.add_theme_font_size_override("font_size",12 if small else 16);parent.add_child(b);slots[id]=b
 var born:=epoch
 b.pressed.connect(func():
  if born==epoch and is_inside_tree() and is_visible_in_tree() and b.is_inside_tree() and b.is_visible_in_tree() and not b.disabled:callback.call())
 return b
