class_name ChapterSeventeenTransactions
extends RefCounted
## All changes are staged, including item custody and late-game recruitment.
const Party=preload("res://scripts/campaign/party_progression.gd")
const H="char_liang_xiao"
const L="char_liu_yingying"
const F="char_feng_lian"
const EVIDENCE=["howls","disguise","wounds","callus","case","zhuque"]
const GEAR={H:{"max_hp":400,"max_mp":40,"atk":90,"def":54,"spd":8},L:{"max_hp":340,"max_mp":35,"atk":82,"def":42,"spd":10}}
static func apply(id:String,actors:Dictionary,items:Dictionary,state:Dictionary,world:Dictionary)->bool:
 var a:=actors.duplicate(true);var i:=items.duplicate(true);var st:=state.duplicate(true);var w:=world.duplicate(true)
 if not _apply(id,a,i,st,w):return false
 actors.clear();actors.merge(a);items.clear();items.merge(i);state.clear();state.merge(st);world.clear();world.merge(w)
 return true
static func _apply(id:String,a:Dictionary,i:Dictionary,s:Dictionary,w:Dictionary)->bool:
 if id in s.semantic_commits or not a.has_all([H,L,F]):return false
 if id.begins_with("evidence_"):
  var key:=id.trim_prefix("evidence_")
  if key not in EVIDENCE or not w.get("ch17_double",{}).get("defeated",false):return false
  if not w.has("ch17_evidence"):w.ch17_evidence={}
  w.ch17_evidence[key]=true
 else:
  match id:
   "arrival":
    if w.get("ch16_journey",{}).get("stage")!="eastbound" or a[H].hp<=0:return false
    w.ch17_journey={"stage":"caravan","eastline_known":false};s.leader_id=H
   "merchants_saved":w.ch17_merchants={"status":"rescued","amo":"travelling_disguised"}
   "feng_returns":
    if a[F].get("status")!="stayed_sword_valley":return false
    # Fixed limited-actor panel: Lv70 linear placement within the V3 Lv66–76 range.
    # It is initialized once, not converted by core-character XP or equipment formulas.
    a[F].merge({"id":F,"name":"风怜","kind":"limited","status":"story_companion","level":70,"fixed_level":70,"max_hp":1816,"max_mp":162,"hp":1816,"mp":162,"atk":262,"def":158,"spd":56,"combat_authorized":true,"skills":["FL_S01","FL_S02","FL_P01"],"skill_ranks":{"FL_S01":1,"FL_S02":1},"equipped_active_skills":["FL_S01","FL_S02"],"learned_active_skills":["FL_S01","FL_S02"],"passives":["FL_P01"],"equipped_passives":["FL_P01"],"learned_passives":["FL_P01"],"internal_skill":"","panel_internal_skill":"","apprentice":false},true)
    w.ch17_feng={"search_years":6,"location":"caravan","apprentice":false}
   "sword_custody":
    if i.has("item_ch17_tianfa") or not a[F].get("combat_authorized",false):return false
    i.item_ch17_tianfa={"owner":F,"state":"carried","form":"sealed_case","source":"MQ17; custody only, LX_A08 not granted"}
    w.ch17_sword={"custodian":F,"drawn":false}
   "road_safe":
    if not s.verified_puzzles.get("ch17_road_wolves",false):return false
    w.ch17_road={"safe":true}
   "birds_fallen":w.ch17_birds={"crow":"dead","kingfisher":"dead"}
   "zhuque_fallen":w.ch17_zhuque={"status":"dead"}
   "liu_rejoins":
    if a[L].get("status")=="dead":return false
    # Existing XP and surviving resources persist; reunion does not mint catch-up XP or healing.
    a[L].status="active";_learn(a[L],"LYY_A08",1);_learn(a[L],"LYY_N03",1)
    a[L].internal_skill="LYY_N03"
    for actor_id in [H,L]:
     var member:Dictionary=a[actor_id];var hp:int=member.hp;var mp:int=member.mp
     member.merge(Party.newcore_panel(actor_id,int(member.xp),GEAR[actor_id],member.internal_skill),true)
     member.hp=mini(hp,int(member.max_hp));member.mp=mini(mp,int(member.max_mp));member.equipment_stage="chapter_seventeen"
    a[L].equipped_active_skills=["LYY_A01","LYY_A03","LYY_A05","LYY_A08"]
    for skill in a[L].equipped_active_skills:
     if not a[L].skill_ranks.has(skill):return false
    # Stronger ranks are only used when actually learned by the earlier campaign.
    a[L].equipped_passives=["LYY_P01","LYY_P03"]
    for skill in a[L].equipped_passives:
     if skill not in a[L].get("learned_passives",[]):return false
    a[L].passives=a[L].equipped_passives.duplicate();w.ch17_liu={"chief":true,"reunited":true,"decision":"undecided"}
   "chief_wall_seen":w.ch17_wall={"surveyed":true}
   "chief_fuel_seen":w.ch17_fuel={"surveyed":true}
   "chief_decided":
    if not w.get("ch17_wall",{}).get("surveyed",false) or not w.get("ch17_fuel",{}).get("surveyed",false):return false
    if s.choices.get("chief_priority") not in ["chief_priority_wall","chief_priority_warmth"]:return false
    w.ch17_liu.priority=s.choices.chief_priority;w.ch17_village={"wall_secured":true,"orphans_warm":true}
   "battle_ready":
    if s.choices.get("loadout") not in ["loadout_river","loadout_tide"] or not w.get("ch17_village",{}).get("wall_secured",false):return false
    var slots:Array=["LX_A01","LX_A02","LX_A03","LX_A06"] if s.choices.loadout=="loadout_river" else ["LX_A01","LX_A03","LX_A04","LX_A05"]
    for skill in slots:
     if not a[H].skill_ranks.has(skill):return false
    a[H].equipped_active_skills=slots;w.ch17_prepared={"ready":true}
   "double_defeated":
    if not s.verified_puzzles.get("ch17_wolf_double",false):return false
    w.ch17_double={"defeated":true,"identity":"wolf_skin_double"}
    # Save exact phase boundary mana; the second part of B13 is not a new full-MP encounter.
    w.ch17_b13_boundary={}
    for member in [H,L,F]:w.ch17_b13_boundary[member]={"hp":a[member].hp,"mp":a[member].mp}
   "caravan_fallen":w.ch17_merchants.status="dead";w.ch17_merchants.amo="only_survivor"
   "amo_exposed":
    if not s.verified_puzzles.get("pz_ch17_evidence",false):return false
    for key in EVIDENCE:
     if not w.get("ch17_evidence",{}).get(key,false):return false
    w.ch17_amo={"exposed":true,"status":"hostile"}
   "amo_defeated":
    if not s.verified_puzzles.get("ch17_amo",false) or i.get("item_ch17_tianfa",{}).get("owner")!=F:return false
    w.ch17_amo.status="dead";w.ch17_feng.rescued=true
    i.item_ch17_tianfa.owner=H;i.item_ch17_tianfa.form="unsheathed_blade";w.ch17_sword={"custodian":H,"drawn":true}
   "burial":
    if w.get("ch17_amo",{}).get("status")!="dead":return false
    w.ch17_burial={"completed":true,"loot":false}
   "roof_built":
    if not s.verified_puzzles.get("pz_ch17_roof",false) or s.choices.get("r07_method") not in ["r07_method_joinery","r07_method_wall"]:return false
    w.ch17_roof={"built":true,"method":s.choices.r07_method,"owner":"villagers"}
   "roof_memory":
    if not w.get("ch17_roof",{}).get("built",false) or i.has("item_ch17_red_pine"):return false
    i.item_ch17_red_pine={"owner":H,"state":"carried","source":"R07 completed house"}
    _memory(s,"MEM_R07_NEW_ROOF_TIANSHAN")
    w.ch17_roof.support={"id":"shelter_one_region","numeric_effect":"unresolved_source_contract"}
   "close_optional":
    if s.optional.ch17_r07.status!="archived":s.optional.ch17_r07={"status":"missed","disposition":"declined" if s.optional.ch17_r07.disposition=="declined" else "missed"}
   "shaved":
    if not w.get("ch17_burial",{}).get("completed",false):return false
    w.ch17_lake={"shaved":true};_learn(a[L],"LYY_P04",1)
    if "LYY_P04" not in a[L].learned_passives:a[L].learned_passives.append("LYY_P04")
   "lake_memory":
    if not w.get("ch17_lake",{}).get("shaved",false):return false
    w.ch17_liu.decision="stays_by_own_choice";_memory(s,"MEM_MQ17_TIANSHAN_FAREWELL")
   "apprentice":
    if not w.get("ch17_feng",{}).get("rescued",false):return false
    a[F].apprentice=true;a[F].status="limited_party";w.ch17_feng.apprentice=true;_memory(s,"MEM_MQ17_FENGLIAN_APPRENTICE")
   "depart":
    if w.get("ch17_liu",{}).get("decision")!="stays_by_own_choice" or not a[F].apprentice:return false
    if s.choices.get("parting")=="parting_map":
     i.item_ch17_star_map={"owner":L,"state":"given","source":"Liang Xiao hand-drawn travel chart"}
    elif s.choices.get("parting")!="parting_bow":return false
    a[L].status="stays_tianshan";w.ch17_journey.stage="eastbound_with_feng";w.ch17_feng.location="eastbound"
   _:return false
 s.semantic_commits.append(id);return true
static func _learn(a:Dictionary,id:String,rank:int)->void:
 a.skill_ranks[id]=maxi(int(a.skill_ranks.get(id,0)),rank)
 if id not in a.skills:a.skills.append(id)
 var key:="learned_internals" if "_N" in id else "learned_active_skills"
 if not a.has(key):a[key]=[]
 if not "_P" in id and id not in a[key]:a[key].append(id)
static func _memory(s:Dictionary,id:String)->void:
 if id not in s.memories:s.memories.append(id)
