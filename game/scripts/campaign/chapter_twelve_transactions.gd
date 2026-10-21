class_name ChapterTwelveTransactions
extends RefCounted
const Party=preload("res://scripts/campaign/party_progression.gd")
const H=Party.HERO
const X=Party.XIAOSHUANG
const S=Party.HUASHENG
const L=Party.LIU
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
static func _loadout(actors:Dictionary,state:Dictionary,world:Dictionary,stage:String)->bool:
 var selected:String=state.choices.get(stage+"_loadout","")
 var active:Array=actors[X].equipped_active_skills.duplicate()
 var configurations:Dictionary={"ch12_b08_loadout_recommended":["HXS_A01","HXS_A02","HXS_A03","HXS_A06"],"ch12_b08_loadout_counter":["HXS_A01","HXS_A02","HXS_A03","HXS_A07"],"ch12_b09_loadout_recommended":["HXS_A01","HXS_A02","HXS_A04","HXS_A05"],"ch12_b09_loadout_healing":["HXS_A02","HXS_A03","HXS_A04","HXS_A05"]}
 if selected!="ch12_"+stage+"_loadout_keep":
  if not configurations.has(selected) or not selected.begins_with("ch12_"+stage+"_"):return false
  active=configurations[selected].duplicate()
 if active.is_empty() or active.size()>4:return false
 var seen:Array=[]
 for skill in active:
  if skill not in actors[X].skills or skill in seen:return false
  seen.append(skill)
 if stage=="b09" and selected!="ch12_b09_loadout_keep":
  for passive in ["HXS_P01","HXS_P03"]:
   if passive not in actors[X].learned_passives:return false
  actors[X].equipped_passives=["HXS_P01","HXS_P03"]
 actors[X].equipped_active_skills=active
 world["ch12_"+stage+"_preparation"]={"selection":selected,"doctor_active_slots":active.duplicate(),"numeric_heal":false,"doctor_passives":actors[X].equipped_passives.duplicate()}
 return true
static func _apply(id:String,actors:Dictionary,items:Dictionary,state:Dictionary,world:Dictionary)->bool:
 if id not in state.get("allowed_transactions",[]) or id in state.get("semantic_commits",[]) or actors.get(A,{}).get("status")!="dead":return false
 match id:
  "evt_ch12_news_learned":world.ch12_news={"liuying_captive_known":true}
  "evt_ch12_r05_window_closed":
   if state.r05_closed:return false
   if state.optional.R05.status!="archived":state.optional.R05={"status":"missed","disposition":"declined" if state.optional.R05.disposition=="declined" else "missed"}
   state.r05_closed=true
  "evt_ch12_bamboo_disarmed":
   if not _proof(state,"world_ch12_bamboo_disarm"):return false
   world.ch12_bamboo={"state":"disarmed_nonlethally","chuyu_humiliation_stopped":true}
  "evt_ch12_duel_oath":world.ch12_duels={"han":"pending","lei":"pending","chu":"pending","nonlethal":true}
  "evt_ch12_b08_loadout_committed":return _loadout(actors,state,world,"b08")
  "evt_ch12_han_won":
   if not _proof(state,"enc_ch12_han_duel"):return false
   world.ch12_duels.han="won";_skill(actors[X],"HXS_A05")
  "evt_ch12_lei_prepared":
   if world.get("ch12_duels",{}).get("han")!="won":return false
   _skill(actors[S],"HS_A03");actors[S].equipped_active_skills=["HS_A01","HS_A02","HS_A03"]
  "evt_ch12_lei_draw":
   if not _proof(state,"enc_ch12_lei_duel"):return false
   world.ch12_duels.lei="draw"
  "evt_ch12_chu_draw":
   if not _proof(state,"enc_ch12_chu_duel"):return false
   world.ch12_duels.chu="draw"
  "evt_ch12_liuying_rejoined":
   if world.get("ch12_duels",{}).get("han")!="won" or world.ch12_duels.get("lei")!="draw" or world.ch12_duels.get("chu")!="draw" or actors[L].get("status")=="dead":return false
   actors[L].status="active"
   for skill in ["LYY_A03","LYY_A04","LYY_A05"]:
    if skill in actors[L].skills:_skill(actors[L],skill,3)
   _skill(actors[L],"LYY_P02")
   if not actors[L].has("learned_passives"):actors[L].learned_passives=actors[L].get("passives",[]).duplicate()
   if "LYY_P02" not in actors[L].learned_passives:actors[L].learned_passives.append("LYY_P02")
   world.ch12_reunion={"same_actor":true,"old_equipment_preserved":true,"numeric_heal":false}
  "evt_ch12_wrist_injury":world.ch12_injuries={"xiaoshuang_wrist":"broken_and_splinted","liuying":"injured_by_protective_strike","numeric_heal":false}
  "evt_ch12_care_completed":
   if not _proof(state,"pz_ch12_care_visits"):return false
   world.ch12_care={"state":"two_months_visits_completed","numeric_heal":false}
  "evt_ch12_wulong_truth":
   if "evt_ch12_care_completed" not in state.semantic_commits:return false
   world.ch12_truth={"wulong_rescue_known":true,"captivity_known":true}
  "evt_ch12_healer_work":
   if not _proof(state,"pz_ch12_clinic_supply"):return false
   world.ch12_clinic={"state":"patients_cared_for","numeric_heal":false}
  "evt_ch12_hxs04_ready":_skill(actors[X],"HXS_A04")
  "evt_ch12_huasheng_stays":
   actors[S].status="staying_with_patients";world.ch12_party={"forest_members":[H,X,L],"huasheng":"staying_with_patients"}
  "evt_ch12_forest_injuries":
   if not _proof(state,"world_ch12_herb_gather"):return false
   world.ch12_forest_injuries={"xiaoshuang":"dagger_wound","liuying":"snakebite","liang":"venom_taken_from_liuying","xiaoshuang_blood_drove_snakes":true}
   _skill(actors[X],"HXS_P03")
   if "HXS_P03" not in actors[X].learned_passives:actors[X].learned_passives.append("HXS_P03")
  "evt_ch12_reverse_five_phases":
   if not _proof(state,"pz_ch12_reverse_five_phases"):return false
   world.ch12_poison={"state":"level_poison_authorized","source":"luo_mingqi"}
  "evt_ch12_b09_loadout_committed":return _loadout(actors,state,world,"b09")
  "evt_ch12_liuying_loadout_committed":
   var selection:String=state.choices.get("liuying_loadout","")
   var active:Array=[]
   match selection:
    "ch12_liuying_loadout_keep":
     if not actors[L].has("equipped_active_skills"):return false
     active=actors[L].equipped_active_skills.duplicate()
    "ch12_liuying_loadout_hook":active=["LYY_A01","LYY_A02","LYY_A03","LYY_A04"]
    "ch12_liuying_loadout_rescue":active=["LYY_A01","LYY_A02","LYY_A03","LYY_A05"]
    _:return false
   if active.is_empty() or active.size()>4:return false
   var seen:Array=[]
   for skill in active:
    if skill not in actors[L].skills or skill in seen:return false
    seen.append(skill)
   actors[L].equipped_active_skills=active
   world.ch12_liuying_preparation={"selection":selection,"active_slots":active.duplicate(),"numeric_heal":false}
  "evt_ch12_b09_survived":
   if not _proof(state,"enc_ch12_chiyou_medicine"):return false
   world.ch12_poison.state="battle_resolved";world.ch12_patients={"liang":"temporarily_unable_to_act","liuying":"temporarily_unable_to_act","luo_mingqi":"temporarily_unable_to_act"}
  "evt_ch12_healer_control":
   if not _proof(state,"world_ch12_healer_safety"):return false
   world.ch12_patients={"liang":"guided_poison_out","liuying":"snakebite_bandaged","luo_mingqi":"poison_bag_sealed"};world.ch12_safety={"order":["seal_poison_bag","bandage_liuying","guide_liang"],"numeric_heal":false}
  "evt_ch12_three_patient_oath":
   if not _proof(state,"world_ch12_three_oath"):return false
   _memory(state,"MEM_MQ12_CHIYOU_OATH");world.ch12_oath={"mutual_nonharm":true}
  "evt_ch12_shennong_inherited":
   if "evt_ch12_three_patient_oath" not in state.semantic_commits or items.has("item_ch12_shennong_classic"):return false
   items.item_ch12_shennong_classic={"owner":X,"state":"carried","quantity":1,"sellable":false,"plot_object":true};_skill(actors[X],"HXS_A05",2)
  "evt_ch12_r05_completed":
   if state.r05_closed or state.choices.get("r05_method") not in ["r05_method_a","r05_method_b"] or not _proof(state,"pz_ch12_r05_rescue") or not _proof(state,"world_ch12_r05_road_repair") or items.has("item_ch12_r05_oil_lamp"):return false
   _skill(actors[S],"HS_A01",2);_memory(state,"MEM_R05_GENTLE_STRENGTH")
   items.item_ch12_r05_oil_lamp={"owner":S,"state":"carried","quantity":1,"sellable":false,"numeric_buff":false}
   world.ch12_r05={"state":"completed","method":state.choices.r05_method,"nonlethal":true}
  "evt_ch12_chapter_archived":
   if not _proof(state,"world_ch12_medical_departure") or state.currency_ledger.has("currency_mq12_once"):return false
   state.currency_ledger.currency_mq12_once=750;state.coins=int(state.coins)+750
   _skill(actors[H],"LX_A04",2)
   world.ch12_party={"members":[H,X,L],"huasheng":"staying_with_patients","state":"medical_journey"}
  _:return false
 return true
