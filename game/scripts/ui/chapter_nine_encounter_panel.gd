class_name ChapterNineEncounterPanel
extends "res://scripts/ui/objective_battle_panel.gd"
## Compact scene controls. Targets are stable IDs, never widget indices.
const HERO := "char_liang_xiao"
var slots: Dictionary = {}
func render(snapshot: Dictionary, _skill_data: Dictionary, can_resolve: bool) -> void:
 for child in get_children():
  remove_child(child); child.queue_free()
 slots.clear(); view=snapshot.duplicate(true)
 add_theme_constant_override("separation",2)
 var small := get_viewport_rect().size.y <= 440
 var o: Dictionary=view.objective
 var hero: Dictionary=view.actors[0] if not view.actors.is_empty() else {}
 _line("heading","血井止兵 · 第%d拍 · 威胁%d/2" % [view.round,o.pressure],small)
 _line("resources","梁萧 %d/%d血 · %d/%d气；场景行动均0气" % [hero.get("hp",0),hero.get("max_hp",0),hero.get("mp",0),hero.get("max_mp",0)],small)
 _line("intent",str(view.intents[0].name) if not view.intents.is_empty() else ("两兵已卸刃离场" if view.outcome=="victory" else "已退回；可从原入口重试"),small)
 for soldier in o.soldiers:
  var status := "已退场  →→→出口" if soldier.retired else ("当前威胁" if soldier.id==o.current_target else "尚未上前")
  if o.observed==soldier.id: status+=" · 已观察"
  _line(soldier.id,"%s：%s" % [soldier.name,status],small)
 var row := HBoxContainer.new(); row.name="scene_actions"; add_child(row)
 var target: String=o.current_target
 for action in ["observe","disarm","wait"]:
  _control(row,action,{"observe":"察兵刃","disarm":"架刃推离","wait":"等一拍"}[action],_act.bind(action,target),view.outcome!="",small)
 var pending: Dictionary=o.pending
 if not pending.is_empty():
  _line("pending","已编排：%s → %s；确认执行此一行动" % [{"observe":"察兵刃","disarm":"架刃推离","wait":"等一拍"}.get(pending.action_id,pending.action_id), "乱兵一" if pending.value=="well_soldier_1" else "乱兵二"],small)
  _control(self,"resolve","执行已编排",func():resolve_requested.emit(),not can_resolve,small)
 _line("rule","奇数拍察刃 → 偶数拍推离，逐兵两拍。错过落刀会受伤并清除观察；不授技能、不回气。",small)
 var last := ""
 for event in view.events:
  if event.type=="damage":last="第%d拍承伤%d；可再观察，或原资源重试。" % [event.round,event.amount]
  elif event.type=="nonlethal_retirement":last="已卸刃推离一兵；取消该次落刀，没有击杀或物品。"
 if view.get("input_error","")!="": last="操作未执行："+str({"retired_target":"该兵已退场","invalid_revision":"局面已更新，请按当前公开轮序操作","scene_actions_only":"这里只使用场景行动"}.get(view.input_error,view.input_error))
 if last!="":_line("feedback",last,small)
 var footer := HBoxContainer.new(); footer.name="footer"; add_child(footer)
 _control(footer,"retry","原入口重试",func():retry_requested.emit(),view.outcome=="victory",small)
 _control(footer,"continue","继续剧情",func():continue_requested.emit(),view.outcome!="victory",small)
 _control(footer,"leave","暂歇",func():leave_requested.emit(),false,small)
func _act(action: String,target: String) -> void:
 input_submitted.emit({"actor_id":HERO,"action_id":action,"value":target,"revision":int(view.revision),"execute":true})
func _line(id: String,text: String,small: bool) -> void:
 var label:=Label.new();label.name=id;label.text=text;label.tooltip_text=text
 label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 label.add_theme_font_size_override("font_size",12 if small else 17)
 label.add_theme_constant_override("line_spacing",0)
 add_child(label);slots[id]=label
func _control(parent: Node,id: String,text: String,callback: Callable,disabled: bool,small: bool) -> void:
 var button:=Button.new();button.name=id;button.text=text;button.disabled=disabled
 button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 button.add_theme_font_size_override("font_size",12 if small else 17)
 button.custom_minimum_size.y=24 if small else 34
 button.pressed.connect(callback);parent.add_child(button);slots[id]=button
