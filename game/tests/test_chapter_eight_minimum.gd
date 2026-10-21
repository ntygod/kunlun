extends "res://tests/chapter_seven_minimum_source.gd"
const SevenFlow=preload("res://tests/chapter_seven_campaign_driver.gd")
const EightFlow=preload("res://tests/chapter_eight_campaign_driver.gd")
func after_source(c:RefCounted) -> void:
 check(c.enter_registered_chapter(7),"minimum ch7 entry")
 for j in range(400):
  if c.state.finished:break
  if not SevenFlow.advance(c,false,1):check(false,"ch7 progress");return
 check(c.state.finished and c.state.xp==11220 and c.state.coins==500,"real 0-7 minimum11220/500")
 var saved=c.prepare_persisted_save();check(saved.error=="","formal minimum chapter7 save")
 var source_path:String="user://chapter_eight_minimum_source.json"
 var file:=FileAccess.open(source_path,FileAccess.WRITE);file.store_string(JSON.stringify(saved.payload));file.close()
 var old_items:Dictionary=c.items.duplicate(true)
 var a:Dictionary=c.actors.char_axue.duplicate(true)
 check(c.enter_registered_chapter(8),"minimum ch8 entry")
 for j in range(150):
  if c.state.finished:break
  print("MIN8 ",c.current_token())
  if not EightFlow.advance(c,false,1):check(false,"minimum8 advance "+c.current_token());return
 check(c.state.finished and c.state.xp==15015 and c.state.coins==1050,"minimum full8 exact3795/550")
 check(c.actors.char_liang_xiao.level==40,"minimum level40")
 check(c.actors.char_axue.hp==a.hp and c.actors.char_axue.mp==a.mp,"snow exact resources preserved")
 check(not c.items.has("item_ch08_peace_charm") and not c.reward_ledger.has("reward_ch08_l04"),"skipped L04 no reward")
 for id in old_items:check(c.items[id]==old_items[id],"legacy item unchanged "+id)
 var final=c.prepare_persisted_save();check(final.error=="","minimum8 final bounded "+str(final.error))
 var restored=Campaign.new(base);check(restored.restore_persisted(final.payload)=="","minimum8 restored")
 print("CH08 FULL MINIMUM ",c.state.xp," XP ",c.state.coins," copper ",c.actors.char_liang_xiao.hp,"HP ",c.actors.char_liang_xiao.mp,"MP")
