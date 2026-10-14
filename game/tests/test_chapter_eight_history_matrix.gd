extends "res://tests/test_chapter_five_history_matrix.gd"
const EightFlow=preload("res://tests/chapter_eight_campaign_driver.gd")
const SevenFlow=preload("res://tests/chapter_seven_campaign_driver.gd")
const SixFlow=preload("res://tests/chapter_six_campaign_driver.gd")
func run() -> void:
 base=JSON.parse_string(FileAccess.get_file_as_string("res://data/prologue.json"))
 var ink_branch:int=int(OS.get_environment("CH06_OLD_BRANCH")) if OS.has_environment("CH06_OLD_BRANCH") else 16
 for old_mask in range(4):
  var prior=chapter_two_subset(old_mask)
  check(prior.enter_chapter_three(),"enter3")
  for j in range(160):
   if prior.state.finished:break
   if not act_three(prior,ink_branch):check(false,"chapter3 path");quit(2);return
  var source=prior.prepare_persisted_save();check(source.error=="","archive3")
  for middle_mask in range(4):
   var c=Campaign.new(base);check(c.restore_persisted(source.payload)=="","clone3")
   check(c.enter_registered_chapter(4),"enter4")
   for j in range(250):
    if c.state.finished:break
    if not advance_four(c,middle_mask):check(false,"chapter4 path");quit(2);return
   check(c.enter_registered_chapter(5),"enter5")
   for j in range(160):
    if c.state.finished:break
    if not advance_whole_five(c):check(false,"chapter5 path");quit(2);return
   var old_xp:int=c.state.xp;var old_coins:int=c.state.coins
   var original_actors:Dictionary=c.actors.duplicate(true);var original_items:Dictionary=c.items.duplicate(true)
   check(c.enter_registered_chapter(6),"enter6")
   check(Proof.equivalent(c.actors,original_actors) and Proof.equivalent(c.items,original_items),"actual entry preserves resources and uniques")
   var side_mask:int=middle_mask;var branch:int=old_mask%2
   for j in range(200):
    if c.state.finished:break
    if not SixFlow.advance(c,side_mask,branch):check(false,"chapter6 path "+c.current_token());quit(2);return
   check(c.state.finished,"complete6")
   check(c.state.xp==old_xp+2525+(400 if side_mask&1 else 0)+(300 if side_mask&2 else 0),"exact main and optional XP")
   check(c.actors[Party.LIU].xp==c.state.xp and c.actors[Party.LIU].status=="temporarily_absent","away core growth")
   check(c.actors.char_axue.level==23 and c.actors.char_axue.xp==0 and c.actors.char_axue.status=="staying_huashan","limited fixed and left in village")
   check(c.items.item_ch01_xuanyuan_sword.owner==Party.HERO,"unique sword recovered")
   check(c.items.item_ch05_yin_ball.state=="destroyed" and c.items.item_ch05_yang_ball.state=="destroyed","balls destroyed")
   for item in ["item_ch02_qingxin_inkstone","item_ch04_small_willow_hat","item_ch05_bayan_jade_ring","item_ch05_pure_yang_box"]:check(Proof.equivalent(c.items[item],original_items[item]),"inherited unique "+item)
   check(c.state.coins==(old_coins+450 if branch else 0),"actual copper conserved")
   if branch:check(c.items.item_ch06_father_book.owner=="char_axue","same father book entrusted")
   else:check(c.items.item_ch06_entrusted_coins.quantity==old_coins+450,"all true coins entrusted")
   var saved=c.prepare_persisted_save();check(saved.error=="","compact6 "+str(saved.error))
   if saved.error!="":quit(2);return
   var restored=Campaign.new(base);check(restored.restore_persisted(saved.payload)=="","new campaign terminal restore")
   var ch6_xp:int=c.state.xp;var ch6_coins:int=c.state.coins
   var ch6_items:Dictionary=c.items.duplicate(true)
   check(c.enter_registered_chapter(7),"enter7 from real old history")
   var do_side:bool=old_mask%2==0
   for j in range(180):
    if c.state.finished:break
    if not SevenFlow.advance(c,do_side,branch):check(false,"chapter7 path "+c.current_token());quit(2);return
   check(c.state.finished and c.state.xp==ch6_xp+1695+(300 if do_side else 0),"exact chapter7 real ledger")
   check(c.state.coins==ch6_coins+500,"zero copper route and settlement")
   check(c.actors.char_axue.level==23 and c.actors.char_axue.status=="recovering_in_camp","limited ally retained")
   check(c.world_objects.ch07_six_friends.npc_zhao_shan=="dead","Zhao never revives")
   check(c.items.item_ch05_bayan_jade_ring.owner=="npc_nang_gudai","same ring delivered")
   for key in ["item_ch05_yin_ball","item_ch05_yang_ball","item_ch05_twelve_rubbings","item_ch01_xuanyuan_sword","item_ch04_small_willow_hat","item_ch05_pure_yang_box"]:check(Proof.equivalent(c.items[key],ch6_items[key]),"protected unique "+key)
   if ch6_items.has("item_ch06_entrusted_coins"):check(c.items.item_ch06_entrusted_coins.quantity==ch6_items.item_ch06_entrusted_coins.quantity and c.items.item_ch06_entrusted_coins.location=="ch06_home","custody never teleports")
   var final=c.prepare_persisted_save();check(final.error=="","bounded7 "+str(final.error))
   if final.error!="":quit(2);return
   var final_clone=Campaign.new(base);check(final_clone.restore_persisted(final.payload)=="","chapter7 independent reconstruction")
   var ch7_items:Dictionary=c.items.duplicate(true)
   var ch7_xp:int=c.state.xp;var ch7_coins:int=c.state.coins
   var snow:Dictionary=c.actors.char_axue.duplicate(true)
   check(c.enter_registered_chapter(8),"enter8 from validated historical branch")
   var side8:bool=middle_mask%2==1
   for j in range(150):
    if c.state.finished:break
    if not EightFlow.advance(c,side8,branch,"sand" if branch else "body"):
     check(false,"chapter8 history progression "+c.current_token());quit(2);return
   check(c.state.finished and c.state.xp==ch7_xp+3795+(300 if side8 else 0),"chapter8 exact historical XP")
   check(c.state.coins==ch7_coins+550,"chapter8 historical money")
   check(c.actors.char_axue.hp==snow.hp and c.actors.char_axue.mp==snow.mp,"chapter8 all historic snow resources")
   for key in ch7_items:check(Proof.equivalent(c.items[key],ch7_items[key]),"all old item custody retained "+key)
   var eight_save=c.prepare_persisted_save();check(eight_save.error=="","bounded8 history "+str(eight_save.error))
   var eight_clone=Campaign.new(base);check(eight_clone.restore_persisted(eight_save.payload)=="","independent8 archive")
   print("CH8 MASK ",ink_branch," ",old_mask,"/",middle_mask," XP ",old_xp," -> ",c.state.xp," coins ",c.state.coins," HPA ",c.actors.char_axue.hp,"/",c.actors.char_axue.mp)
 print("Chapter eight history matrix: ",checks," checks, ",failures," failures");quit(1 if failures else 0)
