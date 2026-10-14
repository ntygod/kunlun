class_name ChapterSevenTransactions
extends RefCounted
const Party=preload("res://scripts/campaign/party_progression.gd")
const H=Party.HERO
const A="char_axue"
const RING="item_ch05_bayan_jade_ring"
const BOW="item_ch07_broken_iron_bow"
const BAG="item_ch07_zhao_grain_bag"
const LETTER="item_ch07_zhao_blood_letter"
static func apply(id:String,actors:Dictionary,items:Dictionary,state:Dictionary,world:Dictionary) -> bool:
 var a:=actors.duplicate(true);var i:=items.duplicate(true);var s:=state.duplicate(true);var w:=world.duplicate(true)
 if not _apply(id,a,i,s,w):return false
 actors.clear();actors.merge(a);items.clear();items.merge(i);state.clear();state.merge(s);world.clear();world.merge(w)
 return true
static func _apply(id:String,actors:Dictionary,items:Dictionary,state:Dictionary,world:Dictionary) -> bool:
 if not actors.has(H) or not actors.has(A) or id in state.get("semantic_commits",[]):return false
 match id:
  "ch07_roll_call_verified":
   if actors[A].get("status")!="staying_huashan" or int(actors[A].hp)<=0:return false
   actors[A].status="present_disguised"
   # Custody is physical, not inferred from the nominal owner's new location.
   for key in ["item_ch06_entrusted_coins","item_ch06_father_book"]:
    if items.get(key,{}).get("state")=="entrusted":
     if items[key].get("location")!="ch06_home":return false
     items[key].custodian="npc_sishen"
   world.ch07_six_friends={"npc_zhao_shan":"alive","npc_wang_ke":"alive","npc_li_ting":"alive","npc_yang_que":"alive","npc_tutuha":"alive","npc_nang_gudai":"alive"}
  "grain_dispatch_verified","grain_rations_verified","grain_loss_verified":
   if id not in state.knowledge:state.knowledge.append(id)
  "dlg_ch07_haiya":
   if "caizhou_scout_map_promised" in state.knowledge:
    if items.has("item_ch07_scout_map"):return false
    items.item_ch07_scout_map={"owner":H,"state":"carried","form":"promised_scout_map"}
  "rest_ch07_camp_once":
   if actors[A].get("status")!="present_disguised":return false
   for who in [H,A]:
    if int(actors[who].hp)<=0:return false
   for who in [H,A]:actors[who].hp=actors[who].max_hp
   state.season="late_autumn"
  "ch07_departure_confirmed":
   if "rest_ch07_camp_once" not in state.semantic_commits:return false
  "enc_ch07_fire_ox_ambush":
   if actors[A].get("status")!="present_disguised" or world.get("ch07_six_friends",{}).get("npc_zhao_shan")!="alive":return false
   actors[A].status="captured_unavailable"
   world.ch07_six_friends.npc_zhao_shan="dead";world.ch07_six_friends.npc_wang_ke="wounded"
   world.ch07_captives={"char_axue":"bound","npc_haiya":"bound"}
   world.ch07_convoy={"state":"burnt","zhao_cause":"fixed_sword_wound"}
   if items.has(BAG):return false
   items[BAG]={"owner":H,"state":"carried","form":"bloodstained_grain_bag","previous_owner":"npc_zhao_shan"}
  "ch07_ring_delivered":
   if items.get(RING,{}).get("owner")!=H or items[RING].get("state")!="carried":return false
   items[RING].owner="npc_nang_gudai";items[RING].state="delivered";items[RING].location="reinforcement_route"
  "enc_ch07_chasm_rescue":
   if actors[A].get("status")!="captured_unavailable" or int(actors[A].hp)<=0 or int(actors[H].hp)<=0:return false
   actors[A].status="rescued_active"
   world.ch07_captives={"char_axue":"safe_bank","npc_haiya":"safe_bank"}
   world.ch07_bridge={"state":"broken","supports":["A","B","C"],"safe_bank":"west","return_crossing":false}
   world.ch07_jin_fei={"status":"retreated_alive"}
  "ch07_broken_bow_action":
   if world.get("ch07_bridge",{}).get("state")!="broken" or items.has(BOW):return false
   items[BOW]={"owner":H,"state":"carried","form":"two_halves","origin":"captured_iron_bow"}
   if "LX_P02" not in actors[H].passives:actors[H].passives.append("LX_P02")
   if "LX_P02" not in actors[H].skills:actors[H].skills.append("LX_P02")
   actors[H].skill_ranks.LX_P02=1
   state.memories.append("MEM_MQ07_BROKEN_BOW_Oath")
  "dlg_ch07_drill":
   if world.ch07_six_friends.npc_zhao_shan!="dead":return false
   world.ch07_six_friends.npc_wang_ke="recovering_mobile"
   actors[A].status="recovering_in_camp"
  "dlg_ch07_trap":world.ch07_commanders={"first":"dead","second":"dead","third":"dead"}
  "dlg_ch07_command":world.ch07_command={"leader":H,"established_after":"regroup_withdrawal"}
  "letters_ch07_l03":
   if not state.choices.get("l03_tone") in ["ch07_l03_tone_joy","ch07_l03_tone_truth"]:return false
   world.ch07_letters={"npc_zhao_shan":"sealed_held_by_sender","npc_wang_ke":"sealed_held_by_sender","npc_hu_san":"sealed_held_by_sender","tone":state.choices.l03_tone}
  "L03_archived":
   if not world.has("ch07_letters") or items.has("item_ch07_dried_date"):return false
   items.item_ch07_dried_date={"owner":H,"state":"carried","quantity":1,"form":"dried_date","numeric_buff":false}
   state.knowledge.append("same_camp_same_fate_memory_only")
  "dlg_ch07_relics":
   if items.has(LETTER):return false
   var written:bool=world.has("ch07_letters")
   items[LETTER]={"owner":H,"state":"carried","form":"bloodstained_letter","history":"sealed_in_l03_never_sent" if written else "newly_gathered_unsent_words"}
   if items.get("item_ch06_letter_box",{}).get("owner")=="npc_zhao_shan" and state.inherited_ch06_optional.get("R03",{}).get("status")=="archived":
    items.item_ch06_letter_box.owner=H;items.item_ch06_letter_box.state="carried";items.item_ch06_letter_box.location="zhao_relics"
  "ch07_letter_disposed":
   if items.get(LETTER,{}).get("owner")!=H:return false
   if state.choices.get("fallen_letter")=="ch07_letter_send":
    items[LETTER].owner="zhao_family";items[LETTER].state="sent";items[LETTER].form="blood_letter_completed_with_peace_words"
   elif state.choices.get("fallen_letter")=="ch07_letter_keep":items[LETTER].form="blood_letter_wrapped_original"
   else:return false
   state.memories.append("MEM_MQ07_ZHAOSHAN_LETTER")
  "ch07_settlement":
   if state.currency_ledger.has("reward_mq07_coins_once") or actors[A].get("status")!="recovering_in_camp":return false
   state.currency_ledger.reward_mq07_coins_once=500;state.coins=int(state.coins)+500
   for skill in ["AX_S01","AX_S02"]:actors[A].skill_ranks[skill]=2
 return true
