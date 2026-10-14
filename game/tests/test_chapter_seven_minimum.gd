extends "res://tests/test_chapter_five_history_matrix.gd"
const SevenFlow=preload("res://tests/chapter_seven_campaign_driver.gd")
const SixFlow=preload("res://tests/chapter_six_campaign_driver.gd")
func run() -> void:
 base=JSON.parse_string(FileAccess.get_file_as_string("res://data/prologue.json"))
 var c=chapter_two_subset(0)
 check(c.enter_chapter_three(),"minimum ch3 entry")
 for j in range(180):
  if c.state.finished:break
  if not act_three(c,16):check(false,"ch3 progress");quit(2);return
 check(c.enter_registered_chapter(4),"minimum ch4 entry")
 for j in range(260):
  if c.state.finished:break
  if not advance_four(c,0):check(false,"ch4 progress");quit(2);return
 check(c.enter_registered_chapter(5),"minimum ch5 entry")
 for j in range(220):
  if c.state.finished:break
  if not advance_whole_five(c):check(false,"ch5 progress");quit(2);return
 check(c.enter_registered_chapter(6),"minimum ch6 entry")
 for j in range(220):
  if c.state.finished:break
  if not SixFlow.advance(c,0,0):check(false,"ch6 progress");quit(2);return
 check(c.state.finished and c.state.xp==9525 and c.state.coins==0,"actual no-side zero-copper chapter6 end")
 var saved=c.prepare_persisted_save()
 check(saved.error=="","validate actual chapter6 terminal")
 var clone=Campaign.new(base)
 check(clone.restore_persisted(saved.payload)=="","restore actual terminal")
 var before:Dictionary=c.items.duplicate(true)
 check(c.enter_registered_chapter(7),"minimum chapter7 actual entry")
 for j in range(180):
  if c.state.finished:break
  if c.current_event().get("id")=="dlg_ch07_relics":
   var text:String=JSON.stringify(c.dialogue_lines())
   check("竹鸟" not in text and "隔水盒" not in text,"unmade R03 has no invented relic history")
  if not SevenFlow.advance(c,false,1):check(false,"chapter7 minimum progress "+c.current_token());quit(2);return
 check(c.state.finished and c.state.xp==11220 and c.state.coins==500,"9525+1695, no L03 and no copper cost")
 check(not c.items.has("item_ch07_dried_date") and not c.reward_ledger.has("reward_ch07_l03"),"no optional fabricated")
 check(c.items.item_ch06_entrusted_coins.quantity==before.item_ch06_entrusted_coins.quantity and c.items.item_ch06_entrusted_coins.location=="ch06_home","zero-copper trust conserved")
 check(c.actors.char_axue.level==23 and c.actors.char_liang_xiao.equipment_stage=="chapter_six","fixed equipment and level")
 var final=c.prepare_persisted_save();check(final.error=="","minimum bounded7 "+str(final.error))
 var restored=Campaign.new(base);check(restored.restore_persisted(final.payload)=="","minimum independently reconstructed")
 print("Chapter seven minimum: ",checks," checks, ",failures," failures")
 quit(1 if failures else 0)
