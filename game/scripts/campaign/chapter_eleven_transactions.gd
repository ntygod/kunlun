class_name ChapterElevenTransactions
extends RefCounted
const Party=preload("res://scripts/campaign/party_progression.gd")
const H=Party.HERO
const X=Party.XIAOSHUANG
const S=Party.HUASHENG
const A="char_axue"
static func apply(id:String,actors:Dictionary,items:Dictionary,state:Dictionary,world:Dictionary)->bool:
 var a:=actors.duplicate(true);var i:=items.duplicate(true);var s:=state.duplicate(true);var w:=world.duplicate(true)
 if not _apply(id,a,i,s,w):return false
 actors.clear();actors.merge(a);items.clear();items.merge(i);state.clear();state.merge(s);world.clear();world.merge(w)
 return true
static func _memory(state:Dictionary,id:String)->void:
 if id not in state.memories:state.memories.append(id)
static func _proof(state:Dictionary,id:String)->bool:return state.get("verified_puzzles",{}).get(id,false)==true
static func _skill(actor:Dictionary,id:String,rank:int=1)->void:
 if id not in actor.skills:actor.skills.append(id)
 actor.skill_ranks[id]=maxi(int(actor.skill_ranks.get(id,0)),rank)
static func _apply(id:String,actors:Dictionary,items:Dictionary,state:Dictionary,world:Dictionary)->bool:
 if id not in state.get("allowed_transactions",[]) or id in state.get("semantic_commits",[]) or actors.get(A,{}).get("status")!="dead":return false
 match id:
  "evt_ch11_town_truce_resolved":
   if not _proof(state,"world_ch11_town_truce"):return false
   world.ch11_town={"state":"quarrel_stopped","nonlethal":true}
  "evt_ch11_xiaoshuang_rejoined":
   if not _proof(state,"world_ch11_reunion_observe") or not actors.has(X) or not Party.migrate_ch11_core(actors,X):return false
   world.ch11_reunion={"state":"same_person_rejoined","past_injury_preserved":true};_memory(state,"MEM_MQ11_HERBAL_REUNION")
   for follower in ["follower_baichier","follower_jinlinger"]:
    if actors.has(follower):actors[follower].status="with_xiaoshuang_noncombat"
  "evt_ch11_elder_identified":
   if world.get("ch10_elder",{}).get("state")!="travelling_for_wu_changqing":return false
   world.ch10_elder.identity_known_to_liang=true;world.ch10_elder.name="释天风";world.ch10_elder.state="visiting_wu_changqing"
  "evt_ch11_dragon_needle_removed":
   if not _proof(state,"pz_ch11_dragon_needle") or actors[X].get("kind")!="core":return false
   _skill(actors[X],"HXS_A07");world.ch11_dragon_needle={"state":"removed_by_xiaoshuang","numeric_heal":false}
  "evt_ch11_r04_window_closed":
   if state.r04_closed:return false
   if state.optional.R04.status!="archived":state.optional.R04={"status":"missed","disposition":"declined" if state.optional.R04.disposition=="declined" else "missed"}
   state.r04_closed=true
  "evt_ch11_meridians_understood":
   if not _proof(state,"pz_ch11_meridian_channels"):return false
   if "CO_02" not in state.knowledge:state.knowledge.append("CO_02")
   world.ch11_meridians={"state":"mutual_understanding","combo":"CO_02"}
  "evt_ch11_circulate_yin_yang":
   if "evt_ch11_meridians_understood" not in state.semantic_commits or not Party.equip_xiaoshuang_n02(actors):return false
   world.ch11_meridians.internal_equipped="HXS_N02"
  "evt_ch11_standard_supplies":
   if not Party.refit_ch11(actors,H) or not Party.refit_ch11(actors,X):return false
   world.ch11_supplies={"state":"issued","numeric_heal":false,"actors":[H,X]}
  "evt_ch11_b07_survived":
   if not _proof(state,"enc_ch11_laoshan_rescue"):return false
   world.ch11_rescue={"state":"two_phases_completed","changning":"disarmed","hetuoluo":"retreated","wu_changqing":"dying"}
  "evt_ch11_qingxing_inherited":
   if "evt_ch11_b07_survived" not in state.semantic_commits or items.has("item_ch11_qingxing_volumes"):return false
   items.item_ch11_qingxing_volumes={"owner":X,"state":"carried","quantity":10,"sellable":false,"plot_object":true}
   _skill(actors[X],"HXS_A03",2);_memory(state,"MEM_MQ11_QINGXING_LEGACY")
  "evt_ch11_wu_changqing_died":
   if "evt_ch11_qingxing_inherited" not in state.semantic_commits:return false
   world.ch11_rescue.wu_changqing="dead";world.ch11_wu_changqing={"status":"dead","legacy_owner":X}
  "evt_ch11_healer_boundary_respected":
   if world.get("ch11_wu_changqing",{}).get("status")!="dead":return false
   world.ch11_healer_boundary={"nonlethal":true,"numeric_buff":false};_memory(state,"MEM_MQ11_XIAOSHUANG_BOTTOMLINE")
  "evt_ch11_yaer_treated":
   if not _proof(state,"pz_ch11_yaer_treatment"):return false
   world.ch11_yaer={"state":"treated_by_xiaoshuang"}
  "evt_ch11_plum_apprenticeship_complete":
   if not _proof(state,"world_ch11_plum_practice") or "evt_ch11_yaer_treated" not in state.semantic_commits:return false
   _skill(actors[X],"HXS_A06");world.ch11_liaoqing={"state":"boxing_taught","student":X}
  "evt_ch11_kuaixue_received":
   if "evt_ch11_plum_apprenticeship_complete" not in state.semantic_commits or actors.has("animal_kuaixue"):return false
   actors.animal_kuaixue={"owner":X,"name":"快雪","status":"with_xiaoshuang_noncombat","kind":"noncombat_donkey"}
   world.ch11_kuaixue={"state":"accompanies_xiaoshuang","numeric_buff":false}
  "evt_ch11_gongyang_parting_resolved":
   if "evt_ch11_kuaixue_received" not in state.semantic_commits:return false
   world.ch11_gongyang={"state":"parting_resolved","kinship_known":true}
  "evt_ch11_river_people_saved":
   if not _proof(state,"world_ch11_river_boulder"):return false
   world.ch11_river={"state":"boulder_moved","people_safe":true}
  "evt_ch11_huasheng_joined":
   if "evt_ch11_river_people_saved" not in state.semantic_commits or not Party.migrate_ch11_core(actors,S):return false
   world.ch11_party={"members":[H,X,S],"state":"three_companions"}
  "evt_ch11_r04_completed":
   if state.r04_closed or state.choices.get("r04_method") not in ["r04_method_a","r04_method_b"] or not _proof(state,"pz_ch11_r04_triage") or not _proof(state,"pz_ch11_r04_medicine") or items.has("item_ch11_qingxing_pestle"):return false
   _skill(actors[X],"HXS_A04");_memory(state,"MEM_R04_TRIAGE_ORDER")
   items.item_ch11_qingxing_pestle={"owner":X,"state":"carried","quantity":1,"sellable":false,"numeric_buff":false}
   world.ch11_r04={"state":"completed","method":state.choices.r04_method,"patients_treated":3,"numeric_buff":false}
  "evt_ch11_chapter_archived":
   if actors.get(S,{}).get("kind")!="core" or state.currency_ledger.has("currency_mq11_once"):return false
   state.currency_ledger.currency_mq11_once=700;state.coins=int(state.coins)+700
   world.ch10_elder.state="departed_after_laoshan";world.ch10_elder.combat_party=false
   _memory(state,"MEM_MQ11_THREE_COMPANIONS")
  _:return false
 return true
