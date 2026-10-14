class_name ChapterNineTransactions
extends RefCounted
const Party=preload("res://scripts/campaign/party_progression.gd")
const H=Party.HERO
const A="char_axue"
const HAMMER="item_ch09_wang_hammer"
const SLIPS="item_ch09_shadow_slips"
const DIAMOND="item_ch09_serpent_diamond"
const KEY="item_ch09_physician_key"
const COURT=["item_ch09_general_seal","item_ch09_court_robe","item_ch09_merit_armor","item_ch09_award_chest"]
static func apply(id:String,actors:Dictionary,items:Dictionary,state:Dictionary,world:Dictionary) -> bool:
 var a:=actors.duplicate(true);var i:=items.duplicate(true);var s:=state.duplicate(true);var w:=world.duplicate(true)
 if not _apply(id,a,i,s,w):return false
 actors.clear();actors.merge(a);items.clear();items.merge(i);state.clear();state.merge(s);world.clear();world.merge(w)
 return true
static func _unique(items:Dictionary,id:String,owner:String=H) -> bool:
 if items.has(id):return false
 items[id]={"owner":owner,"state":"carried","quantity":1,"sellable":false,"numeric_buff":false}
 return true
static func _memory(state:Dictionary,id:String) -> void:
 if id not in state.memories:state.memories.append(id)
static func _apply(id:String,actors:Dictionary,items:Dictionary,state:Dictionary,world:Dictionary) -> bool:
 if not actors.get(H) is Dictionary or not actors.get(A) is Dictionary or id in state.get("semantic_commits",[]):return false
 if id not in state.get("allowed_transactions",[]):return false
 match id:
  "evt_ch09_guo_show_bronze_gnomon":world.ch09_bronze_gnomon={"owner":"npc_guo_shoujing","state":"displayed_not_given"}
  "evt_ch09_guo_give_shadow_slips":
   if not _unique(items,SLIPS):return false
  "evt_ch09_pine_proof_complete":
   if not state.get("verified_puzzles",{}).get("pine",false):return false
   _memory(state,"MEM_MQ09_PINE_FORMATION")
  "evt_ch09_pine_prayer_recorded":
   if state.choices.get("choice_ch09_pine_prayer") not in ["ch09_prayer_life","ch09_prayer_repay"]:return false
   _memory(state,"MEM_MQ09_PINE_PRAYER")
  "evt_ch09_pine_harvest_authorized":
   if world.has("ch09_pine_materials") or "evt_ch09_pine_prayer_recorded" not in state.semantic_commits:return false
   world.ch09_pine_materials={"id":id,"source":"living_pine_after_prayer","owner":"scene","quantity":1,"parts":["body","left_wing","right_wing","tail","frame","linkage"],"prayer":state.choices.choice_ch09_pine_prayer}
  "evt_ch09_wood_bird_assembled":
   if not state.verified_puzzles.get("wood_prepared",false):return false
   world.ch09_wood_bird={"id":"pz_ch09_wood_bird","state":"prepared","owner":"scene","portable":false}
  "evt_ch09_dual_crank_ready","evt_ch09_release_mooring","evt_ch09_launch_rail_traversed","evt_ch09_fixed_stall","evt_ch09_he_palm_lift","evt_ch09_cloud_exit_reached","evt_ch09_water_landing","evt_ch09_wood_bird_drifted":
   if not state.verified_puzzles.get("wood_drifted",false) or id not in state.get("wood_stage_receipts",[]):return false
   var stages={"evt_ch09_dual_crank_ready":"cranking","evt_ch09_release_mooring":"mooring_released","evt_ch09_launch_rail_traversed":"rail_moving","evt_ch09_fixed_stall":"stalled","evt_ch09_he_palm_lift":"palm_lifted","evt_ch09_cloud_exit_reached":"cloud_exit","evt_ch09_water_landing":"water_landed","evt_ch09_wood_bird_drifted":"drifted"}
   world.ch09_wood_bird.state=stages[id]
  "evt_ch09_wood_bird_proof_complete":
   if world.get("ch09_wood_bird",{}).get("state")!="drifted" or not state.verified_puzzles.get("wood_drifted",false):return false
   world.ch09_wood_bird.state="completed";world.ch09_wood_bird.location="river_drifted_away"
   _memory(state,"MEM_MQ09_WOOD_BIRD_ESCAPE")
  "evt_ch09_wang_ke_death_news":
   if not world.get("ch07_six_friends") is Dictionary:return false
   world.ch07_six_friends.npc_wang_ke="dead"
   _memory(state,"MEM_MQ09_WANG_KE")
  "evt_ch09_liting_shows_charred_tag":world.ch09_charred_tag={"owner":"npc_liting","state":"shown_then_kept"}
  "evt_ch09_l03_stone_echo":world.ch09_wang_stone={"owner":"camp","location":"jingkou_empty_tent","echo":state.inherited_ch07_optional.get("L03",{}).get("status")=="archived"}
  "evt_ch09_liting_gives_wang_hammer":
   if world.get("ch07_six_friends",{}).get("npc_wang_ke")!="dead" or not _unique(items,HAMMER):return false
  "evt_ch09_stop_shooting_yun":world.ch09_yun_shu={"state":"retreated_alive","arrows":"stopped"}
  "evt_ch09_physician_treats_prisoners":world.ch09_prisoners={"treated":true,"released":false}
  "evt_ch09_prisoners_released":
   if not world.get("ch09_prisoners",{}).get("treated",false):return false
   world.ch09_prisoners.released=true;_memory(state,"MEM_MQ09_PRISONERS_RELEASED")
  "evt_ch09_blood_well_rest":
   if int(actors[H].hp)<=0 or actors[H].get("status") not in ["active","present"]:return false
   actors[H].hp=actors[H].max_hp;state.rest_receipts.append(id)
  "evt_ch09_well_disarm_complete":
   if not state.verified_puzzles.get("well_disarmed",false):return false
   world.ch09_well_soldiers={"well_soldier_1":"disarmed_departed","well_soldier_2":"disarmed_departed","lethal_kills":0}
  "evt_ch09_well_fixed_loss":
   if state.choices.get("choice_ch09_well_response") not in ["ch09_well_reach","ch09_well_still"]:return false
   world.ch09_well_loss={"state":"fixed_death","choice":state.choices.choice_ch09_well_response,"replay_death":false}
  "evt_ch09_discard_general_cloak":world.ch09_general_cloak={"owner":"world","state":"discarded","location":"changzhou_blood_mud"}
  "evt_ch09_l05_window_closed":
   if "confirm_ch09_enter_command_tent" not in state.receipts.get("ch09_bayan_rupture",[]):return false
   if state.optional.L05.status!="archived":state.optional.L05={"status":"missed","disposition":"declined" if state.optional.L05.disposition=="declined" else "missed"}
   state.l05_closed=true
  "evt_ch09_bayan_story_wound":
   world.ch09_bayan_wound={"story_wound":true,"numeric_hp_loss":0,"permanent_panel_loss":0};_memory(state,"MEM_MQ09_BAYAN_RUPTURE")
  "evt_ch09_take_serpent_diamond":
   if not _unique(items,DIAMOND):return false
   items[DIAMOND].form="intact";items[DIAMOND].court_reward=false;_memory(state,"MEM_MQ09_SERPENT_DIAMOND")
  "evt_ch09_western_campaign_order":
   for item in COURT:
    if not _unique(items,item,"court"):return false
    items[item].state="displayed";items[item].location="linan_tent";items[item].court_reward=true
  "evt_ch09_pack_priority_recorded":
   for item in [HAMMER,SLIPS]:
    if items.get(item,{}).get("owner")!=H or items[item].get("quantity")!=1:return false
   if state.choices.get("choice_ch09_pack_priority") not in ["ch09_pack_hammer","ch09_pack_slips"]:return false
   var selected:String=HAMMER if state.choices.choice_ch09_pack_priority=="ch09_pack_hammer" else SLIPS
   world.ch09_pack_priority={"item_id":selected,"trait":"craft_structure_hint" if selected==HAMMER else "star_direction_hint","numeric_buff":false}
   state.exploration_unlocks.append(world.ch09_pack_priority.trait);_memory(state,"MEM_MQ09_PACK_PRIORITY")
  "evt_ch09_leave_court_rewards":
   for item in COURT:
    if not items.has(item) or items[item].get("owner")!="court":return false
    items[item].owner="camp";items[item].state="left_on_rack";items[item].location="linan_tent_rack"
  "evt_ch09_hang_seal_and_armor":
   for item in COURT:
    if items.get(item,{}).get("location")!="linan_tent_rack":return false
   world.ch09_abandoned_office={"state":"seal_and_armor_hung","location":"linan_tent_rack"}
  "evt_ch09_axue_travels_with_liang":actors[A].status="travelling_with_liang"
  "evt_ch09_leave_linan_gate":_memory(state,"MEM_MQ09_LEAVE_LINAN")
  "evt_ch09_archive_mq09":
   if state.currency_ledger.has("currency_mq09_once"):return false
   state.currency_ledger.currency_mq09_once=600;state.coins=int(state.coins)+600
   # Ordinary skills acquired in chapter four reach their +5 milestone here.
   # Later chapter-five skills have not yet reached +5; P03 is chapter fourteen.
   if actors.has(Party.LIU):
    for skill in ["LYY_A01","LYY_A02","LYY_N01","LYY_P01"]:
     if skill in actors[Party.LIU].skills:actors[Party.LIU].skill_ranks[skill]=maxi(3,int(actors[Party.LIU].skill_ranks.get(skill,1)))
   _memory(state,"MEM_MQ09_ABANDON_GENERAL_SEAL")
  "L05_archived":
   if state.l05_closed or state.choices.get("l05_method") not in ["A","B"] or not state.verified_puzzles.get("l05",false) or not _unique(items,KEY):return false
   var method:String=state.choices.l05_method
   world.ch09_l05={"method":method,"physician_found":method=="A","medicine_owner":"npc_zhang_physician" if method=="A" else "npc_xixizi","medicine_slots":24,"herbal_book_owner":"npc_zhang_physician" if method=="A" else "npc_xixizi","raiders":"three_disarmed_departed","complete":true}
   state.exploration_unlocks.append("herb_taste_exploration_hint");_memory(state,"MEM_L05")
 return true
