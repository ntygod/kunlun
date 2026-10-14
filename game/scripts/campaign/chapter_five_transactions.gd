class_name ChapterFiveTransactions
extends RefCounted
## Chapter-only injury overlays and unique objects. Permanent panels stay intact.
const Party=preload("res://scripts/campaign/party_progression.gd")
const H=Party.HERO
const L=Party.LIU
const A="char_axue"
const BOX="item_ch05_pure_yang_box"
const HAT="item_ch04_small_willow_hat"
const SWORD="item_ch01_xuanyuan_sword"
static func effective(actor:Dictionary,injury:Dictionary={}) -> Dictionary:
 var out:=actor.duplicate(true)
 var stage:String=injury.get("stage","none")
 var percent:int=50 if stage=="depleted" else (75 if stage=="recovering" else 100)
 for key in ["max_hp","atk","def","spd"]:out[key]=maxi(1,int(actor[key])*percent/100)
 out.max_mp=0 if stage=="depleted" else (int(actor.max_mp)/4 if stage=="recovering" else int(actor.max_mp))
 out.hp=mini(int(actor.hp),int(out.max_hp));out.mp=mini(int(actor.mp),int(out.max_mp))
 return out
static func clamp_resources(actors:Dictionary,state:Dictionary) -> void:
 if not actors.has(H):return
 var panel:=effective(actors[H],state.get("injury",{}))
 actors[H].hp=panel.hp;actors[H].mp=panel.mp
static func grant(actor:Dictionary,id:String) -> void:
 if id not in actor.skills:actor.skills.append(id)
 actor.skill_ranks[id]=maxi(1,int(actor.skill_ranks.get(id,0)))
 if id.begins_with("LYY_P") and id not in actor.passives:actor.passives.append(id)
static func _heal(actors:Dictionary,state:Dictionary,hp:int,mp:int) -> void:
 var p:=effective(actors[H],state.get("injury",{}))
 actors[H].hp=mini(int(p.max_hp),int(actors[H].hp)+hp)
 actors[H].mp=mini(int(p.max_mp),int(actors[H].mp)+mp)
static func apply(id:String,actors:Dictionary,items:Dictionary,state:Dictionary,world:Dictionary) -> bool:
 if not actors.has(H) or not actors.has(L):return false
 if id in state.get("semantic_commits",[]):return false
 match id:
  "safe_cabin_rest","safe_north_bank_rest":
   if not state.injury.is_empty():return false
   for actor_id in [H,L]:
    if int(actors[actor_id].hp)<=0:return false
   for actor_id in [H,L]:actors[actor_id].hp=int(actors[actor_id].max_hp)
  "a03_baseline_granted":grant(actors[L],"LYY_A03")
  "combo_formalized":
   state.combo_unlocked=true
   if "CO_01_unlocked" not in state.knowledge:state.knowledge.append("CO_01_unlocked")
  "bayan_ring_received":
   if items.has("item_ch05_bayan_jade_ring"):return false
   items.item_ch05_bayan_jade_ring={"owner":H,"state":"carried","form":"bayan_token"}
   if "MEM_MQ05_BAYAN_RING" not in state.memories:state.memories.append("MEM_MQ05_BAYAN_RING")
  "sealed_box_acquired":
   if items.has(BOX):return false
   items[BOX]={"owner":L,"state":"carried","form":"sealed","contents":"yin_yang_balls_and_plates"}
  "qi_depleted":
   if not state.injury.is_empty() or int(actors[H].hp)<=0:return false
   state.injury={"stage":"depleted","base_at_entry":{},"before_vitals":{"hp":actors[H].hp,"mp":actors[H].mp}}
   for key in ["max_hp","max_mp","atk","def","spd"]:state.injury.base_at_entry[key]=actors[H][key]
   actors[H].hp=maxi(1,int(actors[H].hp)/2);actors[H].mp=0;clamp_resources(actors,state)
   grant(actors[L],"LYY_A04")
  "wulong_hide_verified":state.leader_id=L
  "liu_wounded_search_verified":
   state.liu_wounded=true;grant(actors[L],"LYY_A05");grant(actors[L],"LYY_P02")
  "dlg_ch05_half_heard":
   if "MEM_MQ05_WULONG_MISTAKE" not in state.memories:state.memories.append("MEM_MQ05_WULONG_MISTAKE")
  "small_hat_dropped_verified":
   if items.get(HAT,{}).get("owner")!=H or items[HAT].state!="carried":return false
   items[HAT].owner="ch05_thorn_hat";items[HAT].state="placed";items[HAT].form="torn_bloodstained";items[HAT].location="map_ch05_tree_hollow";items[HAT].position=[352,240]
  "small_hat_recovered_verified":
   if items.get(HAT,{}).get("owner")!="ch05_thorn_hat" or items[HAT].state!="placed":return false
   items[HAT].owner=L;items[HAT].state="carried";items[HAT].erase("location");items[HAT].erase("position")
  "box_seized_by_han":
   if items.get(BOX,{}).get("owner")!=L or items[BOX].form!="sealed":return false
   items[BOX].owner="npc_han_ningzi";items[BOX].state="held_by_npc"
   if items.get(SWORD,{}).get("owner")!=H:return false
   items[SWORD].owner="ch05_seized_weapon_rack";items[SWORD].state="confiscated"
   actors[L].status="temporarily_absent";state.leader_id=H
  "porridge_delivered_verified":
   if state.injury.get("stage")!="depleted":return false
   _heal(actors,state,30,0)
  "box_on_workbench":
   if items.get(BOX,{}).get("owner")!="npc_han_ningzi" or items[BOX].form!="sealed":return false
   items[BOX].state="workbench"
  "box_ch05_light":
   if items.get(BOX,{}).get("state")!="workbench" or items[BOX].form!="sealed":return false
   items[BOX].form="opened"
  "box_ch05_reseal":
   if items.get(BOX,{}).get("form")!="opened":return false
   for item_id in ["item_ch05_yin_ball","item_ch05_yang_ball","item_ch05_twelve_rubbings"]:
    if items.has(item_id):return false
   items.item_ch05_yin_ball={"owner":H,"state":"carried","form":"hidden_yin"}
   items.item_ch05_yang_ball={"owner":H,"state":"carried","form":"hidden_yang"}
   items.item_ch05_twelve_rubbings={"owner":H,"state":"carried","form":"twelve_verified_pages"}
   items[BOX].form="resealed_with_two_stones";items[BOX].contents="twelve_original_plates_and_two_stones";items[BOX].state="returned"
  "yin_yang_breath_verified":
   if state.injury.get("stage")!="depleted" or not items.has("item_ch05_yin_ball") or not items.has("item_ch05_yang_ball"):return false
   state.injury.stage="recovering"
   _heal(actors,state,int(actors[H].max_hp)*15/100,int(actors[H].max_mp)/4)
  "axue_thorn_installed":state.axue_thorn=true
  "sword_reclaimed_verified":
   if items.get(SWORD,{}).get("owner")!="ch05_seized_weapon_rack":return false
   items[SWORD].owner=H;items[SWORD].state="carried"
  "seven_swords_admonition":state.seven_swords_vow=true
  "axue_thorn_removed":
   if not state.axue_thorn:return false
   state.axue_thorn=false
  "cave_recovery":
   if state.axue_thorn or state.injury.get("stage")!="recovering":return false
   state.injury.stage="recovered"
   _heal(actors,state,int(actors[H].max_hp)/4,int(actors[H].max_mp)/4)
  "chapter_five_exit":
   if state.currency_ledger.has("reward_mq05_coins_once"):return false
   state.currency_ledger["reward_mq05_coins_once"]=400;state.coins+=400
  "axue_rescued":
   if actors.has(A) or state.axue_thorn or state.injury.get("stage")!="recovered":return false
   actors[A]={"id":A,"name":"阿雪","kind":"limited","status":"active","level":23,"xp":0,"max_hp":480,"max_mp":75,"hp":240,"mp":35,"atk":55,"def":40,"spd":28,"skills":["normal_attack","guard_ally","AX_S01","AX_S02"],"passives":["AX_P01"],"skill_ranks":{"AX_S01":1,"AX_S02":1},"equipment":{},"earned_rewards":{}}
 world["ch05_injury_stage"]=state.injury.get("stage","none")
 return true
