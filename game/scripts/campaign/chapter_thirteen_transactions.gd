class_name ChapterThirteenTransactions
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
static func _passive(actor:Dictionary,id:String)->void:
 _skill(actor,id)
 if not actor.has("learned_passives"):actor.learned_passives=actor.get("passives",[]).duplicate()
 if id not in actor.learned_passives:actor.learned_passives.append(id)
static func _apply(id:String,actors:Dictionary,items:Dictionary,state:Dictionary,world:Dictionary)->bool:
 if id not in state.get("allowed_transactions",[]) or id in state.get("semantic_commits",[]) or actors.get(A,{}).get("status")!="dead":return false
 match id:
  "evt_ch13_huasheng_rejoined":
   if actors[S].get("status")!="staying_with_patients":return false
   actors[S].status="active";world.ch13_party={"members":[H,L,X,S],"state":"yashan_child_rescue","numeric_heal":false}
  "evt_ch13_child_protected":
   if not _proof(state,"world_ch13_yashan_rescue"):return false
   world.ch13_child={"id":"npc_zhao_bing","state":"rescued_child","restoration_campaign":false}
   _skill(actors[L],"LYY_A06")
  "evt_ch13_yun_alliance":world.ch13_yun={"alliance":"temporary_child_rescue","permanent_party_member":false}
  "evt_ch13_liang_overboard":
   if world.get("ch13_child",{}).get("state")!="rescued_child":return false
   actors[H].status="missing_at_sea";world.ch13_separation={"liang":"alive_on_whale","boat_belief":"missing_feared_dead","controller":L}
  "evt_ch13_stern_secured":
   if not _proof(state,"world_ch13_storm_rigging"):return false
   world.ch13_stern={"state":"secured","controller":L};_skill(actors[L],"LYY_A07");_passive(actors[L],"LYY_P03")
  "evt_ch13_huasheng_braced":
   if not _proof(state,"world_ch13_huasheng_brace"):return false
   world.ch13_brace={"state":"held_despite_fear","numeric_heal":false};_skill(actors[S],"HS_A04");_passive(actors[S],"HS_P02")
  "evt_ch13_healer_exchange":
   if not _proof(state,"world_ch13_cabin_treatment"):return false
   world.ch13_healer_exchange={"haris":"treated_without_approving_violence","child":"protected","water_received":3}
  "evt_ch13_whale_breath_learned":
   if not _proof(state,"pz_ch13_whale_breath"):return false
   if not Party.equip_core_internal(actors,H,"LX_N02"):return false
   world.ch13_whale={"breathing_sections":13,"liang_alive":true}
  "evt_ch13_water_shared":
   if not _proof(state,"pz_ch13_water_watch") or state.choices.get("water_priority","") not in ["ch13_water_vulnerable","ch13_water_workers"]:return false
   world.ch13_water={"priority":state.choices.water_priority,"limited_supply":true,"numeric_heal":false}
  "evt_ch13_sisters_reconciled":
   if "evt_ch13_water_shared" not in state.semantic_commits:return false
   if not Party.equip_core_internal(actors,L,"LYY_N02"):return false
   if "CO_03" not in state.knowledge:state.knowledge.append("CO_03")
   _memory(state,"MEM_MQ13_SISTERS_IN_STORM");world.ch13_sisters={"reconciled":true,"combo_authorization":"CO_03"}
  "evt_ch13_calf_freed":
   if not _proof(state,"world_ch13_whale_harpoon"):return false
   world.ch13_whale.calf_harpoon_removed=true
  "evt_ch13_brother_oath":
   if "evt_ch13_calf_freed" not in state.semantic_commits:return false
   actors[H].status="active";world.ch13_separation.liang="returned_to_boat";world.ch13_brothers={"liang":H,"huasheng":S,"oath":true}
  "evt_ch13_kuaixue_drowned":
   if not _proof(state,"world_ch13_sinking_rescue") or not actors.has("animal_kuaixue"):return false
   actors.animal_kuaixue.status="dead";world.ch13_kuaixue={"state":"drowned_in_sinking","revivable":false}
   world.ch13_atan={"status":"dead","cause":"hetuoluo"};world.ch13_party.state="island_survivors"
  "evt_ch13_tide_palm_learned":
   if "evt_ch13_whale_breath_learned" not in state.semantic_commits:return false
   _skill(actors[H],"LX_A05");world.ch13_tide={"named_by":L,"base_rank":1}
  "evt_ch13_child_declines_throne":
   world.ch13_child.state="refuses_restoration";world.ch13_child.feigned_illness_to_prevent_war=true
  "evt_ch13_ship_materials_ready":
   if not _proof(state,"world_ch13_ship_materials"):return false
   world.ch13_ship={"state":"materials_ready"}
  "evt_ch13_secret_ship_completed":
   if not _proof(state,"pz_ch13_decoy_ship") or world.get("ch13_ship",{}).get("state")!="materials_ready":return false
   world.ch13_ship={"state":"secret_five_hold_ship_ready","decoy_sabotaged":true,"days":4}
  "evt_ch13_loadout_committed":
   var chosen:String=state.choices.get("departure_loadout","");var active:Array=[]
   match chosen:
    "ch13_departure_loadout_keep":active=actors[H].get("equipped_active_skills",[]).duplicate()
    "ch13_departure_loadout_recommended":active=["LX_A01","LX_A02","LX_A04","LX_A05"]
    "ch13_departure_loadout_alternate":active=["LX_A02","LX_A03","LX_A04","LX_A05"]
    _:return false
   if active.size()!=4:return false
   var seen:Array=[]
   for skill in active:
    if skill not in actors[H].skills or skill in seen:return false
    seen.append(skill)
   actors[H].equipped_active_skills=active;world.ch13_preparation={"selection":chosen,"active_slots":active.duplicate(),"numeric_heal":false}
  "evt_ch13_b10_survived":
   if not _proof(state,"enc_ch13_island_departure"):return false
   world.ch13_ship.state="departed_safely";world.ch13_b10={"liang_survived":true,"yun_alive":true,"hetuoluo_alive":true}
  "evt_ch13_navigation_completed":
   if not _proof(state,"pz_ch13_star_navigation"):return false
   world.ch13_navigation={"state":"arrived_guangdong","method":"gnomon_and_stars"}
  "evt_ch13_child_chooses_medicine":
   world.ch13_child.state="chooses_medicine";world.ch13_child.restoration_campaign=false
  "evt_ch13_departure_warning_seen":world.ch13_farewell_warning={"liu_will_leave":true,"prior_optional_locked":true}
  "evt_ch13_liu_departed":
   if not _proof(state,"world_ch13_chaoyun_farewell") or not world.get("ch13_farewell_warning",{}).get("liu_will_leave",false):return false
   actors[L].status="departed_chaoyun";_passive(actors[L],"LYY_P04")
   world.ch13_liu_departure={"voluntary":true,"alive":true,"can_rejoin_later":true,"permanent_event":true,"rides":"animal_yanzhi"}
   if actors.has("animal_yanzhi"):actors.animal_yanzhi.status="with_liuying"
   _memory(state,"MEM_MQ13_CHAOYUN_WILLOW_HAT")
  "evt_ch13_white_head_vow":
   if actors[L].status!="departed_chaoyun":return false
   world.ch13_vow={"liang":H,"xiaoshuang":X,"white_head_promise":true}
  "evt_ch13_chapter_complete":
   if "evt_ch13_white_head_vow" not in state.semantic_commits or state.currency_ledger.has("currency_mq13_once"):return false
   state.currency_ledger.currency_mq13_once=800;state.coins=int(state.coins)+800
   _skill(actors[X],"HXS_A03",3);_skill(actors[X],"HXS_A07",2);_skill(actors[S],"HS_A02",2)
   world.ch13_party={"members":[H,X,S],"state":"northbound","liuying":"departed_alive"}
  _:return false
 return true
