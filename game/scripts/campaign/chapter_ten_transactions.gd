class_name ChapterTenTransactions
extends RefCounted
## Atomic once-only plot transactions. Proof flags are set only by the live replay validator.
const Party=preload("res://scripts/campaign/party_progression.gd")
const H=Party.HERO
const A="char_axue"
const KIT="item_ch10_axue_sewing_kit"
static func apply(id:String,actors:Dictionary,items:Dictionary,state:Dictionary,world:Dictionary) -> bool:
 var a:=actors.duplicate(true);var i:=items.duplicate(true);var s:=state.duplicate(true);var w:=world.duplicate(true)
 if not _apply(id,a,i,s,w):return false
 actors.clear();actors.merge(a);items.clear();items.merge(i);state.clear();state.merge(s);world.clear();world.merge(w)
 return true
static func _memory(state:Dictionary,id:String) -> void:
 if id not in state.memories:state.memories.append(id)
static func _proven(state:Dictionary,id:String) -> bool:return state.get("verified_puzzles",{}).get(id,false)==true
static func _apply(id:String,actors:Dictionary,items:Dictionary,state:Dictionary,world:Dictionary) -> bool:
 if not actors.get(H) is Dictionary or not actors.get(A) is Dictionary or id in state.get("semantic_commits",[]) or id not in state.get("allowed_transactions",[]):return false
 match id:
  "evt_ch10_children_entrusted":
   if not _proven(state,"pz_ch10_wooden_ox") or not _proven(state,"world_ch10_escort_children"):return false
   world.ch10_children={"state":"escorted_to_safety","guardian":"npc_chu_wan","destination":"tianji_palace","ox_owner":"escort","player_owned":false}
  "evt_ch10_friends_hidden":
   if not _proven(state,"world_ch10_friends"):return false
   world.ch10_five_friends={"state":"hidden_alive","location":"forest_tree_canopy","combat_party":false}
  "evt_ch10_prepare_escape":
   if not world.get("ch10_children",{}).get("state")=="escorted_to_safety" or not world.get("ch10_five_friends",{}).get("state")=="hidden_alive":return false
   if int(actors[H].hp)<=0 or actors[A].get("status")!="travelling_with_liang":return false
   actors[H].hp=actors[H].max_hp;state.rest_receipts.append(id)
   world.ch10_escape_preparation={"source":"shelter_task_bandages","hero_hp_only":true,"once":true}
  "evt_ch10_axue_sent_west":
   if "evt_ch10_prepare_escape" not in state.semantic_commits or actors[A].get("status")!="travelling_with_liang":return false
   actors[A].status="sent_to_western_safety";world.ch10_axue_route={"state":"sent_west","return_voluntary":false}
  "evt_ch10_axue_return_resolved":
   if not _proven(state,"world_ch10_axue_return") or actors[A].get("status")!="sent_to_western_safety":return false
   actors[A].status="returned_to_shield_liang";world.ch10_axue_route={"state":"returned","return_voluntary":true}
  "evt_ch10_axue_died":
   if not _proven(state,"world_ch10_farewell") or actors[A].get("status")!="returned_to_shield_liang" or items.has(KIT):return false
   actors[A].status="dead";actors[A].unavailable_reason="qiantang_farewell"
   # Historical fixed-panel HP/MP remain recorded, never interpreted as an available actor.
   items[KIT]={"owner":H,"state":"carried","quantity":1,"sellable":false,"numeric_buff":false,"permanent":true}
   var held:String=""
   for relic in ["item_ch06_wind_bird","item_ch06_letter_box"]:
    if items.get(relic,{}).get("owner") in [H,A] and items[relic].get("state") in ["carried","held"]:held=relic
   world.ch10_farewell={"state":"axue_dead","held_relic":held,"r03_memory_only":held.is_empty() and (items.has("item_ch06_wind_bird") or items.has("item_ch06_letter_box")),"silent":true}
   _memory(state,"MEM_MQ10_AXUE_ETERNAL");_memory(state,"MEM_MQ10_QIANTANG_FAREWELL")
  "evt_ch10_river_release":
   if actors[A].get("status")!="dead" or not _proven(state,"world_ch10_river_release"):return false
   world.ch10_farewell.state="released_into_river";world.ch10_farewell.boat=false
  "evt_ch10_sever_oath":
   if world.get("ch10_farewell",{}).get("state")!="released_into_river":return false
   world.ch10_old_comrades={"state":"parted_alive","intent":"protect_from_implication"}
  "evt_ch10_bayan_survived":
   if not _proven(state,"enc_ch10_bayan_tide"):return false
   world.ch10_bayan={"state":"six_rounds_survived","bayan_alive":true,"tide_departure":true};_memory(state,"MEM_MQ10_TIDE_SURVIVED")
  "evt_ch10_elder_clears_clot":
   if not _proven(state,"world_ch10_shore_walk"):return false
   world.ch10_elder={"state":"unknown_elder_helped","identity_known_to_liang":false,"combat_party":false}
  "evt_ch10_stone_training_complete":
   if not _proven(state,"pz_ch10_stone_array"):return false
   world.ch10_stone_lesson={"state":"three_stones_redirected","numeric_buff":false}
  "evt_ch10_three_months_training":
   if not world.get("ch10_stone_lesson",{}).get("state")=="three_stones_redirected" or "LX_A04" in actors[H].skills:return false
   actors[H].skills.append("LX_A04");actors[H].skill_ranks.LX_A04=1
   if "chengfeng_daohai" not in state.knowledge:state.knowledge.append("chengfeng_daohai")
   _memory(state,"MEM_MQ10_STONE_REBIRTH")
   world.ch10_stone_lesson.months=3
  "evt_ch10_depart_laoshan":
   if "evt_ch10_three_months_training" not in state.semantic_commits or actors[A].get("status")!="dead" or state.currency_ledger.has("currency_mq10_once"):return false
   state.currency_ledger.currency_mq10_once=650;state.coins=int(state.coins)+650
   world.ch10_elder.state="travelling_for_wu_changqing";world.ch10_elder.destination="laoshan";world.ch10_elder.identity_known_to_liang=false
   _memory(state,"MEM_MQ10_LAOSHAN_DEPARTURE")
  _:return false
 return true
