class_name ChapterEightTransactions
extends RefCounted
const Party=preload("res://scripts/campaign/party_progression.gd")
const Growth=preload("res://scripts/campaign/progression.gd")
const H=Party.HERO
const A="char_axue"
const GEAR={"max_hp":160,"max_mp":20,"atk":36,"def":24,"spd":4}
const BEADS="item_ch08_ranya_star_beads"
static func apply(id:String,actors:Dictionary,items:Dictionary,state:Dictionary,world:Dictionary) -> bool:
 var a:=actors.duplicate(true);var i:=items.duplicate(true);var s:=state.duplicate(true);var w:=world.duplicate(true)
 if not _apply(id,a,i,s,w):return false
 actors.clear();actors.merge(a);items.clear();items.merge(i);state.clear();state.merge(s);world.clear();world.merge(w)
 return true
static func _apply(id:String,actors:Dictionary,items:Dictionary,state:Dictionary,world:Dictionary) -> bool:
 if not actors.has(H) or not actors.has(A) or id in state.get("semantic_commits",[]):return false
 match id:
  "ch08_refit":
   if actors[H].get("equipment_stage")=="chapter_eight":return false
   var hp:int=actors[H].hp;var mp:int=actors[H].mp
   actors[H].merge(Growth.actor_panel(H,int(actors[H].xp),GEAR),true)
   actors[H].hp=mini(hp,int(actors[H].max_hp));actors[H].mp=mini(mp,int(actors[H].max_mp));actors[H].equipment_stage="chapter_eight"
  "rest_ch08_river_once","rest_ch08_siege_once":
   if int(actors[H].hp)<=0 or actors[H].get("status") not in ["active","present"]:return false
   actors[H].hp=actors[H].max_hp
   state.rest_receipts.append(id)
  "dlg_ch08_supply":
   if state.choices.get("ballista_shot") not in ["ch08_shot_yunshu","ch08_shot_supply"]:return false
   world.ch08_river_outcome={"yun_shu":"alive","zhang_shun":"dead" if state.choices.ballista_shot=="ch08_shot_yunshu" else "last_seen_with_retreating_fleet","supply_delivery":"succeeded"}
  "dlg_ch08_ranya_beads":
   if items.has(BEADS):return false
   items[BEADS]={"owner":"npc_ranya","state":"worn","form":"blue_sapphire_star_beads","numeric_buff":false}
  "dlg_ch08_ranya_promise":
   for item in ["item_ch08_medicine_recipe","item_ch08_white_ointment"]:
    if items.has(item):return false
    items[item]={"owner":H,"state":"carried","sellable":false,"restores_hp":false,"quantity":1}
   for field in ["skills","learned_passives"]:
    if "LX_P03" not in actors[H][field]:actors[H][field].append("LX_P03")
   actors[H].skill_ranks.LX_P03=1
   if "MEM_MQ08_RANYA_PROMISE" not in state.memories:state.memories.append("MEM_MQ08_RANYA_PROMISE")
  "dlg_ch08_medicine_after":
   if items.has("item_ch08_half_year_herbs"):return false
   items.item_ch08_half_year_herbs={"owner":H,"state":"carried","sellable":false,"restores_hp":false,"duration_months":6}
  "enc_ch08_ballista_objective":world.ch08_ballista={"state":"destroyed","city":"xiangyang","unique_structure":true}
  "L04_archived":
   if items.has("item_ch08_peace_charm") or state.choices.get("l04_method") not in ["A","B"]:return false
   world.ch08_rescue={"method":state.choices.l04_method,"story_injury":state.choices.l04_method=="A","neighbor_huts_protected":state.choices.l04_method=="B","looters":"both_disarmed_departed","sheltered":true,"talked":true}
   items.item_ch08_peace_charm={"owner":H,"state":"carried","quantity":1,"numeric_buff":false}
   world.ch08_grandparents={"grandmother":"safe_shelter","grandchild":"safe_shelter","chapter_fifteen_echo":true}
   if "civilian_risk_awareness" not in state.knowledge:state.knowledge.append("civilian_risk_awareness")
  "ch08_fire_confirmed":
   if world.get("ch08_ballista",{}).get("state")!="destroyed":return false
   state.fire_confirmation={"confirmed":true,"token":"ch08_fire_assault:00"}
   for side in state.optional:
    if state.optional[side].status!="archived":state.optional[side]={"status":"missed","disposition":"declined" if state.optional[side].disposition=="declined" else "missed"}
  "dlg_ch08_fire_disaster":
   if not state.fire_confirmation.get("confirmed",false):return false
   world.ch08_fire={"target":"military_arsenal","city":"xiangyang","spread":"uncontrolled_civilian_district","responsibility":"acknowledged"}
  "enc_ch08_civilian_escort":world.ch08_civilian_batches={"batch_1":"safe","batch_2":"safe","batch_3":"safe","lethal_kills":0}
  "ch08_ruins_lower_hand":state.memories.append("MEM_MQ08_RUINS_LOWERED_HAND")
  "dlg_ch08_punishment":world.ch08_punishment={"strokes":40,"numeric_hp_loss":0}
  "dlg_ch08_surrender":world.ch08_surrender={"promise":"arrow_broken","gate":"not_open_yet"}
  "dlg_ch08_yang":
   if items.has("item_ch08_unfinished_grasshopper"):return false
   world.ch07_six_friends.npc_yang_que="dead"
   items.item_ch08_unfinished_grasshopper={"owner":H,"previous_owner":"npc_yang_que","state":"carried","quantity":1,"numeric_buff":false}
  "dlg_ch08_departure":
   if items.get(BEADS,{}).get("owner")!="npc_ranya":return false
   items[BEADS].owner="world";items[BEADS].state="left_on_branch";items[BEADS].location="xiangyang_memorial_road"
   world.ch08_ranya_departure={"direction":"west","method":"land_caravan"}
  "dlg_ch08_archive":
   if state.choices.get("star_beads") not in ["ch08_beads_take","ch08_beads_leave"]:return false
   if state.choices.star_beads=="ch08_beads_take":items[BEADS].owner=A;items[BEADS].state="carried"
   if state.currency_ledger.has("reward_mq08_coins_once"):return false
   state.currency_ledger.reward_mq08_coins_once=550;state.coins=int(state.coins)+550
   actors[H].skill_ranks.LX_A03=2
   world.ch08_surrender.gate="formally_open"
 return true
