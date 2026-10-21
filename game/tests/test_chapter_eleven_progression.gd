extends SceneTree
const Campaign=preload("res://scripts/campaign/campaign_state.gd")
const Party=preload("res://scripts/campaign/party_progression.gd")
const Growth=preload("res://scripts/campaign/progression.gd")
const Same=preload("res://scripts/campaign/encounter_session.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func _initialize()->void:
 var c=Campaign.new(JSON.parse_string(FileAccess.get_file_as_string("res://data/prologue.json")))
 check(c.restore_persisted(JSON.parse_string(FileAccess.get_file_as_string("res://../output/cache/chapter_nine_gui/manual_natural_final.json")))=="","unchanged chapter9 summary compatibility")
 var actors:Dictionary=c.actors.duplicate(true);var old:Dictionary=actors.duplicate(true)
 check(Party.migrate_ch11_core(actors,Party.XIAOSHUANG),"same historical identity migrated")
 var x:Dictionary=actors[Party.XIAOSHUANG]
 check(x.age==old[Party.XIAOSHUANG].age and x.story_injury==old[Party.XIAOSHUANG].story_injury,"historical age/injury retained")
 check(x.kind=="core" and x.xp==actors[Party.HERO].xp and x.hp==x.max_hp and x.mp==x.max_mp,"explicit first numeric panel at current XP")
 check(x.max_mp==int(floor(float(Growth.actor_panel(Party.XIAOSHUANG,x.xp,x.equipment).max_mp)*1.20)),"N01 source maxMP20percent")
 var hero_hp:int=actors[Party.HERO].hp;var hero_mp:int=actors[Party.HERO].mp
 check(Party.refit_ch11(actors,Party.HERO) and actors[Party.HERO].hp==hero_hp and actors[Party.HERO].mp==hero_mp,"historical hero withoutkind refit nohealing")
 check(x.initial_numeric_panel.hp_initialized and x.initial_numeric_panel.equipment_initialized,"inaugural resources distinguished from healing")
 check(x.skill_ranks.HXS_A01==3 and x.skill_ranks.HXS_A02==3 and x.skill_ranks.HXS_A03==1 and not x.skills.has("HXS_A07"),"acquisition ordering")
 var before:Dictionary=actors.duplicate(true)
 check(not Party.migrate_ch11_core(actors,Party.XIAOSHUANG) and Same.equivalent(before,actors),"migration duplicate atomic")
 var hp:int=x.hp;var mp:int=x.mp
 check(Party.equip_xiaoshuang_n02(actors),"explicit N02 switch")
 check(x.hp==hp and x.mp==mini(mp,int(x.max_mp)) and x.panel_internal_skill=="HXS_N02","N02 does not heal")
 hp=x.hp;mp=x.mp
 check(Party.refit_ch11(actors,Party.XIAOSHUANG) and x.hp==hp and x.mp==mp,"standard supplies do not heal")
 var expected:Dictionary=Growth.actor_panel(Party.XIAOSHUANG,x.xp,x.equipment)
 check(x.max_hp==int(floor(expected.max_hp*1.2)) and x.def==int(floor(expected.def*1.15)),"N02 effective panel exactly once")
 var ledger:Dictionary={};var max_before:int=x.max_hp;hp=x.hp;mp=x.mp
 check(Party.award(actors,ledger,"test_growth",1000),"shared fourcore growth")
 check(x.hp==hp+x.max_hp-max_before and x.mp==mp,"growth only effective maximum delta")
 check(Same.equivalent(old.char_axue,actors.char_axue),"limited Axue never awarded")
 check(not actors.has(Party.HUASHENG),"no implicit future recruit")
 var finite:Dictionary=old.duplicate(true)
 finite[Party.XIAOSHUANG].hp=7;finite[Party.XIAOSHUANG].mp=2;finite[Party.XIAOSHUANG].equipment={"max_hp":1,"max_mp":1,"atk":1,"def":1,"spd":1}
 check(Party.migrate_ch11_core(finite,Party.XIAOSHUANG) and finite[Party.XIAOSHUANG].hp==7 and finite[Party.XIAOSHUANG].mp==2 and finite[Party.XIAOSHUANG].equipment.max_hp==1,"existing numerical injury/gear retained")
 check(Party.migrate_ch11_core(actors,Party.HUASHENG),"first Huasheng core panel")
 var hs:Dictionary=actors[Party.HUASHENG];expected=Growth.actor_panel(Party.HUASHENG,hs.xp,hs.equipment)
 check(hs.max_hp==int(floor(expected.max_hp*1.25)) and hs.def==int(floor(expected.def*1.2)),"HS N01 once")
 check(hs.skill_ranks.HS_P02==1 and not hs.skills.has("HS_A03") and not hs.skills.has("HS_P04"),"pushstone documented awards only")
 var golden:Dictionary=Growth.actor_panel(Party.XIAOSHUANG,22540,Party.CH11_GEAR[Party.XIAOSHUANG])
 check([golden.max_hp,golden.max_mp,golden.atk,golden.def,golden.spd]==[1245,198,181,130,44],"authoritative Lv50 Xiaoshuang gear panel")
 golden=Growth.actor_panel(Party.HUASHENG,22540,Party.CH11_GEAR[Party.HUASHENG])
 check([golden.max_hp,golden.max_mp,golden.atk,golden.def,golden.spd]==[2148,122,249,206,32],"authoritative Lv50 Huasheng gear panel")
 print("Chapter eleven progression: ",checks," checks, ",failures," failures")
 quit(1 if failures else 0)
