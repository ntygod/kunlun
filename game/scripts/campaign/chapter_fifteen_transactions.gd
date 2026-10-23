class_name ChapterFifteenTransactions
extends RefCounted
const Party=preload("res://scripts/campaign/party_progression.gd")
const H=Party.HERO
const X=Party.XIAOSHUANG
const S=Party.HUASHENG
const L=Party.LIU
const A="char_axue"
const M="char_xiao_yuling"
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
static func _passive(actor:Dictionary,id:String,rank:int=1)->void:
 _skill(actor,id,rank)
 if not actor.has("learned_passives"):actor.learned_passives=actor.get("passives",[]).duplicate()
 if id not in actor.learned_passives:actor.learned_passives.append(id)
static func _apply(id:String,actors:Dictionary,items:Dictionary,state:Dictionary,world:Dictionary)->bool:
 if id not in state.get("allowed_transactions",[]) or id in state.get("semantic_commits",[]) or actors.get(A,{}).get("status")!="dead" or actors.get(M,{}).get("status")!="dead" or actors.get(L,{}).get("status")!="departed_chaoyun":return false
 if not world.has("ch15_actor_status"):world.ch15_actor_status={}
 match id:
  "evt_ch15_tongzhou_arrival":
   world.ch15_party={"members":[H,X,S],"state":"coffin_southbound","child":"protected"};world.ch15_actor_status.npc_jiuru="present"
  "evt_ch15_tongzhou_restrained":
   if not _proof(state,"world_ch15_tongzhou_restrain"):return false
   world.ch15_tongzhou={"restrained_nonlethally":true,"no_battle_reward":true}
  "evt_ch15_jiuru_yields":
   if not world.get("ch15_tongzhou",{}).get("restrained_nonlethally",false):return false
   world.ch15_tongzhou.jiuru_yielded=true;world.ch15_tongzhou.shitianfeng_reconciled=true
  "evt_ch15_huasheng_wutai":
   if not world.get("ch15_tongzhou",{}).get("jiuru_yielded",false):return false
   actors[S].status="visiting_wutai";world.ch15_actor_status.npc_jiuru="departed"
  "evt_ch15_burial_arrival":world.ch15_burial={"complete":false,"place":"xiangfan","father":"liang_wenjing","mother":M,"father_died_before_chapter_one":true}
  "evt_ch15_joint_burial_completed":
   if not _proof(state,"world_ch15_joint_burial"):return false
   world.ch15_burial.complete=true;world.ch15_burial.inscription="靖";world.ch14_mother.burial="joint_burial_xiangfan"
  "evt_ch15_mourning_completed":
   if not world.get("ch15_burial",{}).get("complete",false):return false
   world.ch15_burial.mourning_months=3;world.ch15_burial.numeric_heal=false
  "evt_ch15_proposal_prepared":world.ch15_proposal={"intent":"ask_for_marriage","liang_trusts_qingyuan":true,"numeric_heal":false}
  "evt_ch15_dragon_lock_captured":
   actors[H].status="captive_baizhang";world.ch15_capture={"dragon_lock":true,"ambush":true,"ordered_by":"hua_wuchi","no_free_control":true}
  "evt_ch15_trial_arrival":
   if actors[H].status!="captive_baizhang":return false
   world.ch15_trial={"started":true,"liang_restrained":true}
  "evt_ch15_trial_witnessed":
   if not _proof(state,"world_ch15_trial_witness"):return false
   world.ch15_trial.witnessed=true;world.ch15_trial.response=state.choices.get("trial_response","")
  "evt_ch15_friends_intervene":
   if not world.get("ch15_trial",{}).get("witnessed",false):return false
   world.ch15_trial.friends_intervened=["npc_ming_sanqiu","npc_qin_bofu","npc_jiuru",S]
  "evt_ch15_huasheng_returned":
   actors[S].status="active";world.ch15_actor_status.npc_jiuru="present";world.ch15_trial.huasheng_defeated_huchiyin=true;world.ch15_trial.gongyang_remains_superior=true
  "evt_ch15_divine_powder_released":
   if actors[H].status!="captive_baizhang":return false
   world.ch15_powder={"xiaoshuang":true,"changning_hidden":true,"fictional_story_medicine":true,"not_inventory_consumable":true}
  "evt_ch15_liang_unbound":
   if not world.get("ch15_powder",{}).get("xiaoshuang",false):return false
   actors[H].status="active";world.ch15_capture.dragon_lock=false
  "evt_ch15_baizhang_rescue_completed":
   if not _proof(state,"world_ch15_baizhang_rescue"):return false
   world.ch15_baizhang_mercy={"rescued_former_enemies":true,"gongyang_released_liang":true,"numeric_heal":false}
  "evt_ch15_liang_departed_west":
   if not world.get("ch15_baizhang_mercy",{}).get("gongyang_released_liang",false):return false
   actors[H].status="departed_west";world.ch15_liang_knowledge={"xiaoshuang_believed_at":"tianji_palace","heard_han_death_rumor":false,"heard_in_chapter":18};_memory(state,"MEM_MQ15_PARTING_AT_BAIZHANG")
  "evt_ch15_xiaoshuang_abducted":
   if actors[H].status!="departed_west":return false
   actors[X].status="abducted";world.ch15_actor_status.npc_han_ningzi="present";world.ch15_abduction={"by":"npc_han_ningzi","liang_absent":true}
  "evt_ch15_baichier_died":
   if actors[X].status!="abducted" or not actors.has("follower_baichier"):return false
   actors.follower_baichier.status="dead";world.ch15_baichier={"status":"dead","cause":"protecting_xiaoshuang","revivable":false,"no_reward":true}
   if actors.has("follower_jinlinger"):actors.follower_jinlinger.status="injured_alive"
  "evt_ch15_xiaoshuang_escaped":
   if not _proof(state,"world_ch15_cliff_escape") or actors[H].status!="departed_west":return false
   actors[X].status="active";world.ch15_abduction.escaped=true;world.ch15_abduction.method="zhuanyin_yiyang_story_only"
  "evt_ch15_han_died_false_news":
   if not world.get("ch15_abduction",{}).get("escaped",false):return false
   world.ch15_actor_status.npc_han_ningzi="dead";world.ch15_false_news={"speaker":"npc_han_ningzi","claim":"xiaoshuang_dead","truth":false,"audience":"tianji_palace","liang_received":false,"no_reward":true}
  "evt_ch15_xiaoshuang_recovered":
   if actors[X].status!="active" or actors[H].status!="departed_west":return false
   world.ch15_recovery={"narrative_recovered":true,"numeric_heal":false};state.leader_id=X
  "evt_ch15_eastline_rejoined":
   actors[S].status="active";world.ch15_actor_status.npc_xiao_qianjue="present";world.ch15_party={"members":[X,S],"child":"protected","state":"independent_eastline","liang_present":false}
  "evt_ch15_tomb_triage_completed":
   if not _proof(state,"world_ch15_tomb_triage"):return false
   world.ch15_triage={"complete":true,"r04_echo":"MEM_R04_TRIAGE_ORDER" in state.memories,"numeric_heal":false}
  "evt_ch15_five_treasures_poisoned":
   world.ch15_poison={"qianjue":"injured","five_treasures":"injured","huasheng":"threatened","fictional_story_only":true};world.ch15_actor_status.npc_xiao_qianjue="injured"
  "evt_ch15_luo_chang_died":
   world.ch15_actor_status.npc_luo_mingqi="dead";world.ch15_actor_status.npc_chang_ning="dead"
   world.ch15_poison.luo_cause="changning_poison_and_hetuoluo_strike";world.ch15_poison.changning_cause="five_elements_powder";world.ch15_poison.harris_alive=true
  "evt_ch15_mud_training_completed":
   if not _proof(state,"world_ch15_mud_training"):return false
   _skill(actors[S],"HS_A06")
   if not Party.equip_core_internal(actors,S,"HS_N02"):return false
   world.ch15_training={"source":"qianjue_mud_pellets","grant":"GRANT_HS06_BASE","before_b12":true,"numeric_heal":false}
  "evt_ch15_loadout_committed":
   var selected:String=state.choices.get("medical_loadout","");var loadouts:Dictionary={}
   match selected:
    "ch15_medical_loadout_recommended":loadouts={X:["HXS_A01","HXS_A02","HXS_A07","HXS_A04"],S:["HS_A01","HS_A06","HS_A02","HS_A04"]}
    "ch15_medical_loadout_alternate":loadouts={X:["HXS_A01","HXS_A02","HXS_A07","HXS_A03"],S:["HS_A01","HS_A06","HS_A02","HS_A05"]}
    "ch15_medical_loadout_keep":loadouts={X:actors[X].get("equipped_active_skills",[]).duplicate(),S:actors[S].get("equipped_active_skills",[]).duplicate()}
    _:return false
   for who in [X,S]:
    if loadouts[who].size()!=4:return false
    var seen:Array=[]
    for skill in loadouts[who]:
     if skill not in actors[who].skills or skill in seen:return false
     seen.append(skill)
   if "HXS_A01" not in loadouts[X] or "HXS_A07" not in loadouts[X] or "HS_A01" not in loadouts[S] or "HS_A06" not in loadouts[S]:return false
   for who in [X,S]:actors[who].equipped_active_skills=loadouts[who].duplicate()
   world.ch15_preparation={"selection":selected,"active_slots":loadouts.duplicate(true),"numeric_heal":false}
  "evt_ch15_b12_completed":
   if not _proof(state,"enc_ch15_medical_disarm"):return false
   if "CO_04" not in state.knowledge:state.knowledge.append("CO_04")
   _skill(actors[X],"CO_04");_skill(actors[S],"CO_04");_skill(actors[S],"HS_A07")
   world.ch15_b12={"nonlethal":true,"hetuoluo_alive":true,"harris_alive":true,"sealed_stages":2,"trial_became_permanent":true}
  "evt_ch15_father_son_spared":
   if not _proof(state,"world_ch15_mercy_guard") or not world.get("ch15_b12",{}).get("nonlethal",false):return false
   _passive(actors[S],"HS_P03")
   world.ch15_mercy={"decision":state.choices.get("mercy_response",""),"father":"npc_hetuoluo","son":"npc_harris","both_alive":true};_memory(state,"MEM_MQ15_EASTLINE_INDEPENDENCE")
  "evt_ch15_postbattle_care_completed":
   if not _proof(state,"world_ch15_postbattle_care"):return false
   world.ch15_poison.qianjue="treated";world.ch15_poison.five_treasures="treated";world.ch15_actor_status.npc_xiao_qianjue="present"
   world.ch15_care={"order":state.choices.get("care_order",""),"numeric_heal":false}
  "evt_ch15_r06_completed":
   if state.optional.R06.status in ["archived","missed"] or state.choices.get("r06_method") not in ["ch15_r06_method_a","ch15_r06_method_b"] or not _proof(state,"pz_ch15_r06_clinic_plan") or not _proof(state,"world_ch15_r06_clinic_repair") or items.has("item_ch15_r06_child_herb_sheet"):return false
   items.item_ch15_r06_child_herb_sheet={"owner":X,"state":"carried","quantity":1,"sellable":false,"plot_object":true};_memory(state,"MEM_R06_CLINIC_LANTERN")
   if "R06_CLINIC_LEGACY" not in state.knowledge:state.knowledge.append("R06_CLINIC_LEGACY")
   world.ch15_r06={"state":"completed","method":state.choices.r06_method,"child_aspiration":"physician","medicine_fixed_bonus":0.30,"same_type_max":0.50,"camp_supply_per_chapter":2,"camp_claimed_chapters":[],"numeric_heal":false}
  "evt_ch15_r06_window_closed":
   if state.optional.R06.status!="archived":state.optional.R06={"status":"missed","disposition":"declined" if state.optional.R06.disposition=="declined" else "missed"}
   world.ch15_r06_window={"closed":true,"disposition":state.optional.R06.disposition}
  "evt_ch15_eastline_oath":
   if not world.get("ch15_mercy",{}).get("both_alive",false):return false
   _skill(actors[X],"HXS_A08");_passive(actors[X],"HXS_P04")
   if not Party.equip_core_internal(actors,X,"HXS_N03"):return false
   state.leader_id=X;world.ch15_oath={"ten_year_eastline_begins":true,"liang_absent":true,"numeric_heal":false}
  "evt_ch15_eastline_departed":
   if not _proof(state,"world_ch15_eastline_departure") or not world.get("ch15_oath",{}).get("ten_year_eastline_begins",false) or state.currency_ledger.has("currency_mq15_once"):return false
   _skill(actors[H],"LX_A05",2)
   state.currency_ledger.currency_mq15_once=900;state.coins=int(state.coins)+900;state.leader_id=X
   world.ch15_party={"members":[X,S],"child":"protected","state":"ten_year_eastline_begins","liang_present":false,"qianjue":"protecting_from_distance"};world.ch15_actor_status.npc_xiao_qianjue="offscreen"
  _:return false
 return true
