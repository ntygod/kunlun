extends "res://tests/test_chapter_five.gd"
## Promoted from the independent state review; genuine 16 prior-side combinations.
func advance_four(c:CampaignState,mask:int) -> bool:
 if c.current_event().op=="quest_window" and not c.current_event().get("deadline",false):
  for i in range(2):
   var side:String=["R02","L01"][i]
   if mask & (1<<i) and c.state.optional[side].status!="archived":return c.current_chapter_runtime().open_sidequest(side)
 if c.current_event().op=="objective_battle" and c.state.scope=="main":
  var s=c.current_chapter_runtime().make_objective_encounter();var d=BattleDriver.new(check);d.low_route(s)
  return c.current_chapter_runtime().complete(c.current_token(),s.receipt())
 return intro(c)
func advance_whole_five(c:CampaignState) -> bool:
 var rt=c.current_chapter_runtime();var e=c.current_event();var t=c.current_token()
 if e.op=="objective_battle":
  var s=rt.make_objective_encounter();var d=FiveDriver.new(check)
  if e.id=="enc_ch05_mechanism_yun_shu":d.b02(s)
  else:d.b03(s)
  return rt.complete(t,s.receipt())
 if e.get("kind")=="route":
  var layout=rt.maps[c.scene().map_id];var n=layout.paths[e.id].size()
  return c.complete_action(t,e.id,{"map_id":c.scene().map_id,"position":layout.actions[e.id].position,"complete":true,"index":n,"total":n})
 return advance_five(c)
func run() -> void:
 base=JSON.parse_string(FileAccess.get_file_as_string("res://data/prologue.json"))
 var inherited_branch:int=int(OS.get_environment("CH05_OLD_BRANCH")) if OS.has_environment("CH05_OLD_BRANCH") else 16
 for old_mask in range(4):
  var prior=chapter_two_subset(old_mask)
  check(prior.state.finished,"ch2 generated subset")
  check(prior.enter_chapter_three(),"ch3 enter")
  for j in range(160):
   if prior.state.finished:break
   if not act_three(prior,inherited_branch):check(false,"ch3 progress");quit(2);return
  check(prior.state.finished,"ch3 generated complete")
  var source=prior.prepare_persisted_save()
  check(source.error=="","ch3 archive valid")
  for new_mask in range(4):
   var c=Campaign.new(base)
   check(c.restore_persisted(source.payload)=="","ch3 clone")
   check(c.enter_registered_chapter(4),"ch4 entry")
   for j in range(250):
    if c.state.finished:break
    if not advance_four(c,new_mask):check(false,"ch4 progress "+c.current_token());quit(2);return
   check(c.state.finished,"ch4 generated complete")
   var old_xp:int=c.state.xp;var old_coins:int=c.state.coins;var old_actors=c.actors.duplicate(true);var old_items=c.items.duplicate(true)
   var expected=4465+(400 if old_mask&1 else 0)+(250 if old_mask&2 else 0)+(400 if new_mask&1 else 0)+(300 if new_mask&2 else 0)
   check(old_xp==expected,"ch4 subset expected XP")
   check(c.enter_registered_chapter(5),"ch5 entry")
   check(c.actors==old_actors and c.items==old_items,"entry HPMP XP items untouched")
   for j in range(160):
    if c.state.finished:break
    if not advance_whole_five(c):check(false,"ch5 progress "+c.current_token());quit(2);return
   check(c.state.finished,"ch5 generated complete")
   check(c.state.xp==expected+2535,"exact subset final XP")
   check(c.state.coins==old_coins+400,"only400 coins")
   check(c.actors[Party.LIU].xp==c.state.xp,"absent Liu growth")
   check(c.actors.char_axue.xp==0 and c.actors.char_axue.hp==240 and c.actors.char_axue.mp==35,"fixed Axue")
   check(c.items.item_ch04_small_willow_hat.owner==Party.LIU,"hat ownership")
   check(Proof.equivalent(c.items.item_ch02_qingxin_inkstone,old_items.item_ch02_qingxin_inkstone),"exact inherited whole or broken inkstone retained")
   check(c.prepare_persisted_save().error=="","final bounded save")
   print("MASK ",old_mask,"/",new_mask," XP ",old_xp," -> ",c.state.xp," HPMP ",c.actors[Party.HERO].hp,"/",c.actors[Party.HERO].mp)
 print("Chapter five history matrix branch ",inherited_branch," ",checks," checks ",failures," failures");quit(1 if failures else 0)
