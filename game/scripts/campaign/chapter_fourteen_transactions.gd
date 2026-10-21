class_name ChapterFourteenTransactions
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
 if id not in state.get("allowed_transactions",[]) or id in state.get("semantic_commits",[]) or actors.get(A,{}).get("status")!="dead" or actors.get(L,{}).get("status")!="departed_chaoyun":return false
 match id:
  "evt_ch14_dadu_settled":world.ch14_party={"members":[H,X,S],"state":"dadu_guest","liu":"departed_alive","child":"protected"}
  "evt_ch14_clinic_completed":
   if not _proof(state,"world_ch14_alley_clinic"):return false
   world.ch14_clinic={"completed":true,"numeric_heal":false}
  "evt_ch14_mother_recognized":world.ch14_child={"mother_recognized":true,"mother":"npc_quan_taihou","not_restoration":true}
  "evt_ch14_festival_cleared":
   if not _proof(state,"world_ch14_festival_cover"):return false
   world.ch14_festival={"bystanders_safe":true}
  "evt_ch14_jiuru_injured":
   if not _proof(state,"world_ch14_nunnery_rescue"):return false
   world.ch14_jiuru={"status":"injured","protected_soldier":true,"not_battle_party":true}
  "evt_ch14_father_truth_revealed":
   if actors.get(M,{}).get("status")!="present":return false
   world.ch14_truth={"wenjing":"qianjue_hidden_strike","yuling_learns_now":true}
  "evt_ch14_duel_converged":
   if not _proof(state,"world_ch14_zizhu_duel"):return false
   world.ch14_duel={"two_palms":true,"no_battle_reward":true}
  "evt_ch14_mother_struck":
   if not world.get("ch14_duel",{}).get("two_palms",false) or actors.get(M,{}).get("status")!="present":return false
   world.ch14_mother={"state":"dying","cause":"both_palms","original_identity":M}
  "evt_ch14_southbound_ready":
   if not world.get("ch14_dawn",{}).get("vow",false):return false
   world.ch14_southbound={"coffin_ready":true,"burial_completed":false}
  "evt_ch14_calendar_completed":
   if not _proof(state,"pz_ch14_calendar"):return false
   _passive(actors[H],"LX_P03",3);world.ch14_calendar={"state":"verified","year_length":"365.2425","stations":27,"numeric_heal":false}
  "evt_ch14_xiaoshuang_abducted":
   if not _proof(state,"world_ch14_nunnery_rescue"):return false
   actors[X].status="abducted";world.ch14_abduction={"xiaoshuang":"captured","child":"captured","jiuru":"injured_protecting_soldier"}
  "evt_ch14_stone_lion_mastered":
   if not _proof(state,"world_ch14_stone_lion") or actors[X].status!="abducted":return false
   _skill(actors[S],"HS_A05");world.ch14_temple={"stone_lion_moved":true,"innocents_safe":true,"nonlethal_rule":true}
  "evt_ch14_temple_loadout_committed":
   var chosen:String=state.choices.get("temple_loadout","")
   var loadouts:Dictionary={}
   match chosen:
    "ch14_temple_loadout_recommended":loadouts={H:["LX_A01","LX_A03","LX_A04","LX_A05"],S:["HS_A02","HS_A04","HS_A03","HS_A05"]}
    "ch14_temple_loadout_alternate":loadouts={H:["LX_A02","LX_A03","LX_A04","LX_A05"],S:["HS_A02","HS_A04","HS_A03","HS_A05"]}
    _:return false
   for who in [H,S]:
    if loadouts[who].size()!=4:return false
    var seen:Array=[]
    for skill in loadouts[who]:
     if skill not in actors[who].skills or skill in seen:return false
     seen.append(skill)
   for who in [H,S]:actors[who].equipped_active_skills=loadouts[who].duplicate()
   world.ch14_preparation={"selection":chosen,"active_slots":loadouts.duplicate(true),"numeric_heal":false}
  "evt_ch14_b11_completed":
   if not _proof(state,"enc_ch14_datianwang_temple"):return false
   if "CO_05" not in state.knowledge:state.knowledge.append("CO_05")
   _skill(actors[H],"CO_05");_skill(actors[S],"CO_05")
   world.ch14_b11={"nonlethal":true,"innocents_safe":true,"trial_became_permanent":true,"wheels_destroyed":4}
  "evt_ch14_dharma_answered":
   if not _proof(state,"pz_ch14_buddhist_debate"):return false
   world.ch14_dharma={"answered":"一归何处","numeric_heal":false}
  "evt_ch14_emperor_released":
   if "evt_ch14_dharma_answered" not in state.semantic_commits:return false
   world.ch14_abduction.child="released_to_jiuru";actors[S].status="escorting_child"
  "evt_ch14_liang_captured":
   if not _proof(state,"world_ch14_wheel_capture"):return false
   world.ch14_capture={"liang":"exhausted_captive","numeric_heal":false,"controller":H}
  "evt_ch14_mother_reunited":
   if not actors.has(M) or actors[M].get("status")=="dead":return false
   actors[M].status="present";world.ch14_mother={"state":"reunited","original_identity":M}
  "evt_ch14_xiaoshuang_freed":
   if actors[X].status!="abducted" or actors[M].status!="present":return false
   actors[X].status="active";world.ch14_abduction.xiaoshuang="freed_by_yuling"
  "evt_ch14_mother_died":
   if not _proof(state,"world_ch14_zizhu_duel") or actors[M].status!="present" or actors[X].status!="active":return false
   _memory(state,"MEM_MQ14_MOTHER_VOW");world.ch14_mother_vow={"no_revenge":true,"no_loot_screen":true}
   actors[M].status="dead";world.ch14_mother={"state":"dead","original_identity":M,"cause":"both_palms","revivable":false,"burial":"awaiting_southbound"}
  "evt_ch14_xiao_leng_died":
   if actors[M].status!="dead":return false
   world.ch14_xiao_leng={"status":"dead","revivable":false,"no_reward":true}
  "evt_ch14_qianjue_departed":
   if not _proof(state,"world_ch14_break_blade"):return false
   world.ch14_qianjue={"status":"departed","alive":true};world.ch14_capture.liang="protected_by_xiaoshuang"
   _passive(actors[X],"HXS_P03")
  "evt_ch14_dawn_vow":
   if not _proof(state,"world_ch14_dawn_vigil") or not world.get("ch14_mother_vow",{}).get("no_revenge",false):return false
   world.ch14_dawn={"vow":true,"alive_for_others":true,"numeric_heal":false};_memory(state,"MEM_MQ14_ZIZHULIN_DAWN")
   actors[S].status="active";state.leader_id=X
  "evt_ch14_chapter_complete":
   if "evt_ch14_dawn_vow" not in state.semantic_commits or state.currency_ledger.has("currency_mq14_once"):return false
   state.currency_ledger.currency_mq14_once=850;state.coins=int(state.coins)+850
   _skill(actors[X],"HXS_A05",3);_skill(actors[X],"HXS_A04",2);_skill(actors[S],"HS_A03",2)
   state.leader_id=X;world.ch14_party={"members":[H,X,S],"state":"preparing_southbound_with_coffin","burial_completed":false}
  _:return false
 return true
