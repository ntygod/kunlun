extends "res://tests/test_chapter_eight_minimum.gd"
const NineFlow=preload("res://tests/chapter_nine_campaign_driver.gd")
const TenFlow=preload("res://tests/chapter_ten_campaign_driver.gd")
func after_source(c:RefCounted) -> void:
 super.after_source(c)
 check(c.enter_registered_chapter(9),"minimum chapter9 entry")
 for i in range(160):
  if c.state.finished:break
  if not NineFlow.advance(c,false,1):check(false,"minimum chapter9 progress");return
 check(c.state.finished and c.state.xp==17845 and c.state.coins==1650,"real no-side chapter9")
 var old_items:Dictionary=c.items.duplicate(true);var snow:Dictionary=c.actors.char_axue.duplicate(true)
 check(c.enter_registered_chapter(10),"minimum chapter10 entry")
 for i in range(100):
  if c.state.finished:break
  print("MIN10 ",c.current_token())
  if c.current_event().id=="enc_ch10_bayan_tide":
   check(c.state.xp==19350 and c.actors.char_liang_xiao.level==46,"actual first seven scene awards yield19350/46")
   check(c.state.rest_receipts==["evt_ch10_prepare_escape"] and c.actors.char_liang_xiao.hp==c.actors.char_liang_xiao.max_hp,"actual once-only bandaging")
   check(c.actors.char_liang_xiao.get("internal_skill","")!="LX_N01" and "LX_A04" not in c.actors.char_liang_xiao.skills,"no optional internal or future active skill")
  if not TenFlow.advance(c,1):check(false,"minimum chapter10 progress "+c.current_token());return
 check(c.state.finished and c.state.xp==20915 and c.state.coins==2300,"minimum terminal exact3070XP650coins")
 check(c.actors.char_axue.hp==snow.hp and c.actors.char_axue.mp==snow.mp and c.actors.char_axue.status=="dead","fixed historical resources")
 for id in old_items:check(c.items[id]==old_items[id],"minimum inherited item "+id)
 check(not c.items.has("item_ch06_wind_bird") and not c.items.has("item_ch06_letter_box") and c.world_objects.ch10_farewell.held_relic=="","no phantom R03 item")
 var saved:Dictionary=c.prepare_persisted_save();check(saved.error=="","minimum terminal bounded save "+str(saved.error))
 var restored=Campaign.new(base);check(restored.restore_persisted(saved.payload)=="","minimum terminal restored")
 print("CH10 FULL MINIMUM ",c.state.xp," XP ",c.state.coins," copper ",c.actors.char_liang_xiao.hp," HP / ",c.actors.char_liang_xiao.mp," MP")
