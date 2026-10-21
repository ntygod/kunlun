class_name ChapterSixTransactions
extends RefCounted
const Party=preload("res://scripts/campaign/party_progression.gd")
const Growth=preload("res://scripts/campaign/progression.gd")
const H=Party.HERO
const L=Party.LIU
const A="char_axue"
const SWORD="item_ch01_xuanyuan_sword"
const BOOK="item_ch06_father_book"
const RUBBINGS="item_ch05_twelve_rubbings"
const GEAR={"max_hp":100,"max_mp":15,"atk":25,"def":16,"spd":3}
static func grant(items:Dictionary,id:String,quantity:int=1,owner_id:String="ch06_workbench") -> bool:
 if items.has(id):return false
 items[id]={"owner":owner_id,"state":"available","quantity":quantity,"form":id.trim_prefix("item_ch06_"),"location":"workbench"}
 return true
static func consume(items:Dictionary,amounts:Dictionary) -> bool:
 for id in amounts:
  if not items.get(id) is Dictionary:return false
  var item:Dictionary=items[id]
  if item.get("state")!="available" or item.get("owner") not in [H,A,"ch06_workbench"] or not item.get("quantity") is int and not item.get("quantity") is float:return false
  if float(item.quantity)!=floor(float(item.quantity)) or int(item.quantity)<int(amounts[id]):return false
 for id in amounts:
  items[id].quantity=int(items[id].quantity)-int(amounts[id])
  if items[id].quantity==0:items[id].state="consumed"
 return true
static func apply(id:String,actors:Dictionary,items:Dictionary,state:Dictionary,world:Dictionary) -> bool:
 var a:=actors.duplicate(true);var i:=items.duplicate(true);var s:=state.duplicate(true);var w:=world.duplicate(true)
 if not _apply(id,a,i,s,w):return false
 actors.clear();actors.merge(a);items.clear();items.merge(i);state.clear();state.merge(s);world.clear();world.merge(w)
 return true
static func _apply(id:String,actors:Dictionary,items:Dictionary,state:Dictionary,world:Dictionary) -> bool:
 if not actors.has(H) or not actors.has(A) or id in state.get("semantic_commits",[]):return false
 match id:
  "dlg_ch06_refuge":
   state.liang_age=18;actors[H].age=18
  "father_book_three":
   if items.has(BOOK):return false
   items[BOOK]={"owner":H,"state":"carried","form":"father_annotations"}
  "stars_ch06_sword":
   if "LX_A03" not in actors[H].skills:actors[H].skills.append("LX_A03")
   actors[H].skill_ranks.LX_A03=maxi(1,int(actors[H].skill_ranks.get("LX_A03",0)))
   if "tianxing_sword_created" not in state.knowledge:state.knowledge.append("tianxing_sword_created")
  "dlg_ch06_sword_rock":
   if items.get(SWORD,{}).get("owner")!=H:return false
   items[SWORD].owner="ch06_plum_rock";items[SWORD].state="lodged";items[SWORD].location="plum_rock"
  "dlg_ch06_crisis":
   for ball in ["item_ch05_yin_ball","item_ch05_yang_ball"]:
    if items.get(ball,{}).get("owner")!=H or items[ball].get("state")!="carried":return false
   if int(actors[H].hp)<=0 or int(actors[A].hp)<=0 or items.get(RUBBINGS,{}).get("owner")!=H:return false
   for ball in ["item_ch05_yin_ball","item_ch05_yang_ball"]:
    items[ball].state="destroyed";items[ball].form="shattered_during_borrowed_body"
   items[RUBBINGS].owner=A;state.story_restriction="borrowed_body";state.leader_id=A
  "borrowed_body_recovery":
   if state.story_restriction!="borrowed_body" or items.get(RUBBINGS,{}).get("owner")!=A or int(actors[H].hp)<=0:return false
   items[RUBBINGS].owner=H;state.story_restriction="";state.leader_id=H
   state.knowledge.append("zifuyuan_read_first_two_only")
  "array_ch06_steps":state.knowledge.append("ten_directions_verified")
  "sword_reclaimed_ch06":
   if items.get(SWORD,{}).get("owner")!="ch06_plum_rock" or items[SWORD].get("state")!="lodged":return false
   items[SWORD].owner=H;items[SWORD].state="carried";items[SWORD].erase("location")
  "old_home_three_objects_verified":
   for pair in [["item_ch06_old_bowl","hearth"],["item_ch06_old_plane","workbench"]]:
    if items.has(pair[0]):return false
   items.item_ch06_old_bowl={"owner":"ch06_home","state":"placed","location":"hearth","form":"chipped"}
   items.item_ch06_old_plane={"owner":"ch06_home","state":"placed","location":"workbench","form":"worn"}
   grant(items,"item_ch06_roof_thatch",3);grant(items,"item_ch06_bucket_staves",4)
  "home_roof_repaired":
   if not consume(items,{"item_ch06_roof_thatch":3}):return false
   world.ch06_roof={"state":"repaired"}
  "home_bucket_made":
   if not consume(items,{"item_ch06_bucket_staves":4}):return false
   if items.has("item_ch06_bucket"):return false
   items.item_ch06_bucket={"owner":"ch06_home","state":"placed","location":"well","form":"watertight"}
  "gear_refit_ch06":
   if actors[H].get("equipment_stage")=="chapter_six":return false
   var hp:int=actors[H].hp;var mp:int=actors[H].mp
   actors[H].merge(Growth.actor_panel(H,int(actors[H].xp),GEAR),true)
   actors[H].hp=mini(hp,int(actors[H].max_hp));actors[H].mp=mini(mp,int(actors[H].max_mp));actors[H].equipment_stage="chapter_six"
  "bamboo_gathered_verified":
   if not grant(items,"item_ch06_bamboo",2):return false
  "basket_ch06_weave":
   if items.has("item_ch06_trade_basket") or not consume(items,{"item_ch06_bamboo":2}):return false
   items.item_ch06_trade_basket={"owner":H,"state":"carried","form":"woven"}
  "basket_goods_exchanged":
   if items.get("item_ch06_trade_basket",{}).get("owner")!=H:return false
   items.item_ch06_trade_basket.owner="npc_neighbours";items.item_ch06_trade_basket.state="exchanged"
   items.item_ch06_grain_salt={"owner":"ch06_home","state":"stored","location":"hearth","form":"millet_oil_salt"}
  "axue_hearth_verified":
   if not items.has("item_ch06_old_bowl"):return false
   world.ch06_hearth={"fire":"lit","bowl":"item_ch06_old_bowl","tended_by":A}
  "safe_home_rest":
   if "basket_goods_exchanged" not in state.semantic_commits:return false
   for who in [H,A]:
    if actors[who].get("status","present") not in ["active","present"] or int(actors[who].hp)<=0:return false
   for who in [H,A]:
    actors[who].hp=mini(int(actors[who].max_hp),int(actors[who].hp)+int(actors[who].max_hp)/2)
    actors[who].mp=mini(int(actors[who].max_mp),int(actors[who].mp)+int(actors[who].max_mp)/4)
   state.season="early_autumn"
  "ordinary_bamboo_horse":
   if items.has("item_ch06_ordinary_bamboo_horse"):return false
   items.item_ch06_ordinary_bamboo_horse={"owner":A,"state":"carried","form":"ordinary_horse"}
  "r03_fine_strips_collected":
   if not grant(items,"item_ch06_fine_strips",1):return false
  "r03":
   if not consume(items,{"item_ch06_fine_strips":1}):return false
   var bird:bool=state.choices.get("r03_method")=="ch06_r03_method_bird"
   var product:String="item_ch06_wind_bird" if bird else "item_ch06_letter_box"
   if items.has(product):return false
   items[product]={"owner":"ch06_home" if bird else "npc_zhao_shan","state":"placed" if bird else "delivered","location":"eaves" if bird else "family_letter","form":"wind_bird" if bird else "red_thread_box"}
  "l02_collect_pine":
   if not grant(items,"item_ch06_dry_pine",2):return false
  "l02_collect_reused_sleeve":
   if not grant(items,"item_ch06_reused_sleeve",1):return false
  "l02_collect_willow_pin":
   if not grant(items,"item_ch06_willow_pin",1):return false
  "l02_collect_resin":
   if not grant(items,"item_ch06_pine_resin",3):return false
  "l02_borrowed_materials_verified":
   if items.has("item_ch06_iron_hoop") or items.has("item_ch06_rawhide"):return false
   grant(items,"item_ch06_iron_hoop",1);grant(items,"item_ch06_rawhide",1)
  "l02":
   if not consume(items,{"item_ch06_dry_pine":2,"item_ch06_reused_sleeve":1,"item_ch06_willow_pin":1,"item_ch06_iron_hoop":1,"item_ch06_rawhide":1,"item_ch06_pine_resin":3}):return false
   world.ch06_three_repairs={"waterwheel":"repaired","cart":"repaired","plough_handles":2,"first":"waterwheel" if state.choices.get("l02_method")=="ch06_l02_method_waterwheel" else "cart"}
  "R03_archived":
   if not grant(items,"item_ch06_hot_soup",2,H):return false
   items.item_ch06_hot_soup.state="carried"
   state.knowledge.append("lx_a04_early_refinement_eligible")
  "L02_archived":
   if not grant(items,"item_ch06_corn_cake",1,H):return false
   items.item_ch06_corn_cake.state="carried";state.knowledge.append("trait_axe_in_season")
  "consoling_aunt":
   items.item_ch06_aunt_shoes={"owner":H,"state":"carried","form":"thick_soled"}
   state.memories.append("MEM_MQ06_SISEN_SHOES")
  "checking_baggage":state.knowledge.append("caizhou_scout_map_promised")
  "dlg_ch06_settlement":
   if state.currency_ledger.has("reward_mq06_coins_once"):return false
   state.currency_ledger.reward_mq06_coins_once=450;state.coins=int(state.coins)+450
  "departure_confirmed":
   if not state.currency_ledger.has("reward_mq06_coins_once") or items.get(BOOK,{}).get("owner")!=H:return false
   if state.choices.get("entrust")=="ch06_entrust_coins":
    if items.has("item_ch06_entrusted_coins"):return false
    items.item_ch06_entrusted_coins={"owner":A,"state":"entrusted","quantity":int(state.coins),"location":"ch06_home"}
    state.coins=0
   elif state.choices.get("entrust")=="ch06_entrust_book":items[BOOK].owner=A;items[BOOK].state="entrusted";items[BOOK].location="ch06_home"
   else:return false
   if items.get(SWORD,{}).get("owner")!=H:return false
   actors[A].status="staying_huashan";state.leader_id=H;actors[H].skill_ranks.LX_A02=maxi(3,int(actors[H].skill_ranks.get("LX_A02",1)))
 return true
