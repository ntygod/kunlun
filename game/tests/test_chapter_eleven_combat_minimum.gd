extends "res://tests/test_chapter_eight_minimum.gd"
const NineFlow=preload("res://tests/chapter_nine_campaign_driver.gd")
const TenFlow=preload("res://tests/chapter_ten_campaign_driver.gd")
const ElevenCore=preload("res://scripts/combat/chapter_eleven_engine.gd")
const ElevenSession=preload("res://scripts/combat/chapter_eleven_encounter.gd")
const ElevenDriver=preload("res://tests/chapter_eleven_encounter_driver.gd")
func after_source(c:RefCounted)->void:
 super.after_source(c)
 check(c.enter_registered_chapter(9),"minimum chapter9")
 for i in range(500):
  if c.state.finished:break
  if not NineFlow.advance(c,false):check(false,"minimum9 progress");return
 check(c.state.xp==17845 and c.state.finished,"true no-side0–9 history")
 check(c.enter_registered_chapter(10),"minimum chapter10")
 for i in range(120):
  if c.state.finished:break
  if not TenFlow.advance(c):check(false,"minimum10 progress");return
 check(c.state.xp==20915 and c.state.finished,"actual minimum chapter10 endpoint")
 # Scoped boundary fixture, not a chapter11 save or its full event chronology.
 # Preserve all current wounds. Migration after first150XP matches scene2 join.
 var actors:Dictionary=c.actors.duplicate(true);var ledger:Dictionary={}
 check(Party.award(actors,ledger,"test_ch11_before_reunion",150),"real growth before reunion")
 check(Party.migrate_ch11_core(actors,ElevenCore.X),"historical Xiaoshuang migration")
 actors[ElevenCore.X].skills.append("HXS_A07");actors[ElevenCore.X].skill_ranks.HXS_A07=1
 check(Party.refit_ch11(actors,ElevenCore.HERO) and Party.refit_ch11(actors,ElevenCore.X),"standard gear no healing")
 check(Party.equip_xiaoshuang_n02(actors),"explicit cave internal switch no healing")
 check(Party.award(actors,ledger,"test_ch11_rest_of_pre_b07",1475),"remaining exact main budget")
 var party:Array=[]
 for id in [ElevenCore.HERO,ElevenCore.X]:
  var a:Dictionary=actors[id].duplicate(true);a.id=id;a.team="party";a.fixed_level=a.level;a.passives=a.equipped_passives.duplicate()
  a.skills=ElevenCore.H_SKILLS.duplicate() if id==ElevenCore.HERO else ["normal_attack","self_guard","guard_ally","HXS_A01","HXS_A02","HXS_A03","HXS_A07"]
  if id==ElevenCore.X:a.internal_stats_applied=true;a.equipped_active_skills=["HXS_A01","HXS_A02","HXS_A03","HXS_A07"]
  party.append(a)
 check(party[0].xp==22540 and party[0].level==50 and party[1].level==50,"exact minimum actual level50")
 check(party[0].get("internal_skill","")!="LX_N01" and not party[1].skill_ranks.has("HXS_A04"),"no optional N01/R04 shortcut")
 var cfg:=ElevenCore.encounter_config();cfg.context={"chapter":11,"current_token":"min_b07","combo_unlocked":true}
 var artifact=FileAccess.open("user://b07_boundary_fixture.json",FileAccess.WRITE);artifact.store_string(JSON.stringify({"rules":c.rules,"runtime":c.combat,"cfg":cfg,"party":party}));artifact.close()
 var s=ElevenSession.new(c.rules,c.combat,cfg,party,"min_b07")
 check(s.engine.entry_error=="","minimum genuine resource entry")
 print("B07_REAL_MIN_ENTRY ",party[0].hp,"/",party[0].max_hp," H; ",party[1].hp,"/",party[1].max_hp," X")
 check(ElevenDriver.run(s,true),"no-refill minimum resource win")
 check(not ElevenSession.replay_receipt(s.receipt(),c.rules,c.combat,cfg,party).is_empty(),"minimum exact receipt replay")
 print("B07_REAL_MIN_FINAL ",s.final_party()," round ",s.engine.state.round)
