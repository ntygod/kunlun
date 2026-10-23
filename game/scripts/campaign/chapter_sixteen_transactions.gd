class_name ChapterSixteenTransactions
extends RefCounted
const H="char_liang_xiao"
const X="char_hua_xiaoshuang"
const F="char_feng_lian"
const R="npc_ranya"
const IDS=["west_arrival","official_restrained","granary_opened","river_saved","home_remembrance","home_echo","learn_river","feng_rescued","horse_tamed","horse_given","civilians_sheltered","west_loadout","raid_resolved","orphans_sheltered","sword_refused","leave_feng","ranya_reunited","life_equal","study_completed","leave_ranya","statue_remembered","seven_years","eastbound"]
static func apply(id:String,actors:Dictionary,items:Dictionary,state:Dictionary,world:Dictionary)->bool:
 var a:=actors.duplicate(true);var i:=items.duplicate(true);var st:=state.duplicate(true);var w:=world.duplicate(true)
 if not _apply(id,a,i,st,w):return false
 actors.clear();actors.merge(a);items.clear();items.merge(i);state.clear();state.merge(st);world.clear();world.merge(w)
 return true
static func _apply(id:String,actors:Dictionary,items:Dictionary,state:Dictionary,world:Dictionary)->bool:
 if id not in IDS or id in state.semantic_commits or not actors.has(H):return false
 var h:Dictionary=actors[H]
 match id:
  "west_arrival":
   if h.get("status")!="departed_west":return false
   h.status="active";state.leader_id=H
   world.ch16_journey={"years":0,"stage":"yellow_river","hero_knowledge":"xiaoshuang_left_at_tianji; eastline outcome not known"}
   for item in ["item_ch16_firestarter","item_ch16_counting_rods"]:
    if items.has(item):return false
    items[item]={"owner":H,"state":"carried","source":"MQ16 travel necessities, no combat use"}
  "official_restrained":world.ch16_official={"status":"restrained","nonlethal":true}
  "granary_opened":
   if world.get("ch16_official",{}).get("status")!="restrained":return false
   world.ch16_granary={"opened":true,"custodian":"flood_survivors","hero_money":0}
  "river_saved":
   if not state.verified_puzzles.get("pz_ch16_river",false):return false
   world.ch16_river={"gates":[4,4,1],"overflow":1,"flow":10,"complete":true}
  "home_remembrance":
   if state.choices.get("home_first")=="home_first_stool":items.item_ch16_bamboo_strip={"owner":H,"state":"carried","source":"MQ16 abandoned home"}
   elif state.choices.get("home_first")!="home_first_stove":return false
   world.ch16_home={"visited":true,"first":state.choices.home_first,"axue_status":"dead"}
  "home_echo":world.ch16_home["echo_seen"]=true
  "learn_river":
   if not world.get("ch16_river",{}).get("complete",false):return false
   for key in ["ch16_source_west","ch16_source_middle","ch16_source_east"]:
    if key not in state.receipts.get("ch16_source",[]):return false
   if h.skill_ranks.has("LX_A06"):return false
   h.skill_ranks.LX_A06=1
   if "LX_A06" not in h.skills:h.skills.append("LX_A06")
   if not h.has("learned_active_skills"):h.learned_active_skills=[]
   h.learned_active_skills.append("LX_A06");state.knowledge.append("LX_A06")
  "feng_rescued":
   if actors.has(F):return false
   actors[F]={"name":"风怜","status":"exploration_companion","kind":"exploration_only","joined_at":"MQ16","combat_authorized":false}
   world.ch16_feng={"rescued":true,"location":"jingjue"}
  "horse_tamed":world.ch16_fire_meteor={"status":"tamed","custodian":H,"combat":false}
  "horse_given":
   if not actors.has(F) or world.get("ch16_fire_meteor",{}).get("status")!="tamed":return false
   world.ch16_fire_meteor.custodian=F;world.ch16_fire_meteor.status="gifted"
  "civilians_sheltered":world.ch16_refuge={"safe":true,"location":"stone_house"}
  "west_loadout":
   var selection:String=state.choices.get("west_loadout","")
   var slots:Array=["LX_A06","LX_A01","LX_A02","LX_A03"] if selection=="west_loadout_river" else ["LX_A06","LX_A01","LX_A04","LX_A05"]
   if selection not in ["west_loadout_river","west_loadout_tide"]:return false
   for skill in slots:
    if not h.skill_ranks.has(skill):return false
   h.equipped_active_skills=slots
  "raid_resolved":
   if not state.verified_puzzles.get("ch16_night_raid",false) or not world.get("ch16_refuge",{}).get("safe",false):return false
   world.ch16_raid={"complete":true,"arutai":"dead","alias":"花斑豹","civilian_refuge":"safe"}
  "orphans_sheltered":
   if not world.get("ch16_raid",{}).get("complete",false):return false
   world.ch16_orphans={"custodian":"surviving_kin","burial":true}
  "sword_refused":world.ch16_sword={"accepted":false,"marriage_promised":false,"tianfa":"unfinished_blade; not awarded"}
  "leave_feng":
   if state.choices.get("farewell")=="farewell_tools":
    for item in ["item_ch16_firestarter","item_ch16_counting_rods"]:
     if items.get(item,{}).get("owner")!=H or items[item].state!="carried":return false
     items[item].owner=F;items[item].state="given"
   elif state.choices.get("farewell")!="farewell_quiet":return false
   actors[F].status="stayed_sword_valley";world.ch16_feng.location="sword_valley"
  "ranya_reunited":
   world.ch16_ranya={"status":"present","location":"malaga","father":"deceased"}
  "life_equal":
   if not state.verified_puzzles.get("pz_ch16_scale",false):return false
   world.ch16_vault={"open":true,"method":"two_equal_lives","left":H,"right":R}
   _memory(state,"MEM_MQ16_EQUALITY_OF_LIFE")
  "study_completed":
   if not state.verified_puzzles.get("pz_ch16_study",false) or not world.get("ch16_vault",{}).get("open",false):return false
   var focus:String=state.choices.get("study_focus","")
   if focus not in ["study_focus_geometry","study_focus_hydraulics"]:return false
   items.item_ch16_scholar_notes={"owner":H,"state":"carried","focus":focus,"seasons":12}
   world.ch16_scholar={"focus":focus,"first_book":state.choices.get("first_book",""),"endgame_modifier_status":"not_implemented_no_numeric_contract"}
   _age(actors,state,3);world.ch16_journey.years=3;_memory(state,"MEM_MQ16_MALAGA_SCHOLAR")
  "leave_ranya":world.ch16_ranya.status="stayed_malaga";world.ch16_journey.stage="mediterranean"
  "statue_remembered":
   if state.choices.get("statue_echo")=="statue_echo_bamboo" and items.get("item_ch16_bamboo_strip",{}).get("state")!="carried":return false
   world.ch16_statue={"location":"egypt","choice":state.choices.get("statue_echo",""),"axue_status":"dead"}
  "seven_years":
   if world.get("ch16_journey",{}).get("years")!=3:return false
   _age(actors,state,7);world.ch16_journey.years=10;world.ch16_journey.stage="athens"
  "eastbound":world.ch16_journey.stage="eastbound";_memory(state,"MEM_MQ16_EQUALITY_OF_LIFE")
 state.semantic_commits.append(id)
 return true
static func _memory(state:Dictionary,id:String)->void:
 if id not in state.memories:state.memories.append(id)
static func _age(actors:Dictionary,state:Dictionary,years:int)->void:
 state.liang_age+=years;state.xiaoshuang_age+=years
 for id in actors:
  if actors[id].get("status")!="dead" and actors[id].has("age"):actors[id].age+=years
 actors[H].age=state.liang_age
 if actors.has(X):actors[X].age=state.xiaoshuang_age
