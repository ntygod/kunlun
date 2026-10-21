class_name ChapterTenBattlePanel
extends "res://scripts/ui/objective_battle_panel.gd"
## Stable direct choices and scrollable public intentions; no hidden roll/QTE.
const HERO := "char_liang_xiao"
const BOSS := "bayan"
var slots: Dictionary={}
var render_epoch:=0
func render(snapshot: Dictionary,_skill_data: Dictionary,ready: bool) -> void:
 render_epoch+=1
 for child in get_children():remove_child(child);child.queue_free()
 slots.clear();view=snapshot.duplicate(true)
 add_theme_constant_override("separation",2)
 var small:=get_viewport_rect().size.y<=440
 var hero: Dictionary=view.actors[0] if not view.actors.is_empty() else {}
 _line(self,"heading","钱塘伯颜 · 坚守%d/6轮"%view.objective.get("survived_rounds",0),small)
 _line(self,"resources","梁萧 %d/%d血 · %d/%d气 · 第%d轮"%[hero.get("hp",0),hero.get("max_hp",0),hero.get("mp",0),hero.get("max_mp",0),view.round],small)
 var scroll:=ScrollContainer.new();scroll.name="details_scroll";scroll.custom_minimum_size.y=65 if small else 135;scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;add_child(scroll);slots[scroll.name]=scroll
 var details:=VBoxContainer.new();details.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(details)
 for i in range(view.intents.size()):_line(details,"intent_%d"%i,str(view.intents[i].name),small)
 _line(details,"rules","第4轮潮起；借潮只避潮压，不能挡箭。破招保护期不重复取消动作。伯颜最低1血仍继续交锋，活到第6轮末才过关。",small)
 if view.round<=2:_line(details,"grief","大恸：前两轮攻击+20%、招式耗气-25%，不新增或占用心性槽。",small)
 if view.commands.has(HERO):
  var skill:String=view.commands[HERO].skill_id
  _line(self,"pending","已编排："+str(view.skill_data.get(skill,{}).get("name",{"normal_attack":"普通攻击","self_guard":"自守"}.get(skill,skill))),small)
 var actions:=GridContainer.new();actions.name="actions";actions.columns=3;add_child(actions)
 for skill in ["normal_attack","self_guard","observe","sancai_counter","LX_A03","ch10_borrow_tide"]:
  var target:String=HERO if skill in ["self_guard","ch10_borrow_tide"] else BOSS
  var legal:bool={"skill_id":skill,"target_id":target} in view.get("legal_commands",{}).get(HERO,[])
  var names:Dictionary={"normal_attack":"普通攻击","self_guard":"自守","observe":"观势察机","sancai_counter":"三才归元掌","LX_A03":"飞星九宫剑","ch10_borrow_tide":"借潮引势"}
  var cost:int=view.get("skill_costs",{}).get(HERO,{}).get(skill,0)
  _control(actions,skill,"%s · %d气"%[names[skill],cost],_command.bind(skill,target),not legal,small)
 var feedback:=""
 for event in view.events:
  if event.type=="damage" and event.target==HERO:feedback="最近承伤%d；可自守或原资源重试。"%event.amount
  elif event.type=="bow_interrupted":feedback="弓弦已被打断，下一轮箭势取消。"
  elif event.type=="tide_avoided":feedback="已借浪头避开本次潮压。"
 if view.get("input_error","")!="":feedback="未执行："+str(view.input_error)
 if feedback!="":_line(self,"feedback",feedback,small)
 var footer:=HBoxContainer.new();footer.name="footer";add_child(footer)
 _control(footer,"resolve","结算回合",func():resolve_requested.emit(),not ready,small)
 _control(footer,"retry","原资源重试",func():retry_requested.emit(),view.outcome=="victory",small)
 _control(footer,"continue","继续剧情",func():continue_requested.emit(),view.outcome!="victory",small)
 _control(footer,"leave","暂歇",func():leave_requested.emit(),false,small)
func _command(skill:String,target:String)->void:command_requested.emit(HERO,skill,target,int(view.revision))
func _line(parent:Node,id:String,text:String,small:bool)->void:
 var l:=Label.new();l.name=id;l.text=text;l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;l.add_theme_font_size_override("font_size",12 if small else 17);l.add_theme_constant_override("line_spacing",0);parent.add_child(l);slots[id]=l
func _control(parent:Node,id:String,text:String,callback:Callable,disabled:bool,small:bool)->void:
 var b:=Button.new();b.name=id;b.text=text;b.disabled=disabled;b.size_flags_horizontal=Control.SIZE_EXPAND_FILL;b.custom_minimum_size.y=24 if small else 34;b.add_theme_font_size_override("font_size",12 if small else 17)
 var epoch:=render_epoch
 b.pressed.connect(func():
  if epoch!=render_epoch or not is_inside_tree() or not is_visible_in_tree() or not b.is_inside_tree() or not b.is_visible_in_tree() or b.disabled:return
  callback.call())
 parent.add_child(b);slots[id]=b
