extends "res://tests/test_chapter_eight_minimum.gd"
const NineFlow=preload("res://tests/chapter_nine_campaign_driver.gd")
const TenCore=preload("res://scripts/combat/chapter_ten_engine.gd")
const TenSession=preload("res://scripts/combat/chapter_ten_encounter.gd")
func after_source(c:RefCounted)->void:
 super.after_source(c)
 check(c.enter_registered_chapter(9),"minimum ch9 entry")
 for i in range(500):
  if c.state.finished:break
  if not NineFlow.advance(c,false):check(false,"minimum ch9 progress");return
 check(c.state.finished and c.state.xp==17845,"real no-side minimum chapter9")
 # Scoped combat boundary fixture: exact documented pre-B06 budget, using real
 # growth transaction; explicit shelter healing is implemented by campaign agent.
 var ledger:Dictionary={}
 check(Party.award(c.actors,ledger,"test_pre_b06_main_budget",1505),"documented1505 main XP transaction")
 var h:Dictionary=c.actors.char_liang_xiao.duplicate(true)
 check(h.level==46 and h.xp==19350,"minimum true level46 growth")
 check(h.get("internal_skill","")!="LX_N01" and not h.skill_ranks.has("LX_A04"),"no optional N01 or future A04")
 h.hp=h.max_hp # Explicit pre-battle Axue bandage boundary, never a save edit.
 h.id=TenCore.HERO;h.team="party";h.skills=["normal_attack","self_guard","observe","sancai_counter","LX_A03"];h.passives=h.get("equipped_passives",[]).duplicate()
 for guard_only in [false,true]:
  var cfg:=TenCore.encounter_config();cfg.context={"chapter":10,"current_token":"minimum_b06"}
  var s=TenSession.new(c.rules,c.combat,cfg,[h],"minimum_b06")
  check(s.engine.entry_error=="","minimum entry")
  for r in range(1,7):
   var skill:String="self_guard" if guard_only else {1:"LX_A03",2:"observe",3:"sancai_counter",4:"ch10_borrow_tide",5:"LX_A03",6:"self_guard"}[r]
   check(s.set_command(TenCore.HERO,skill,TenCore.HERO if skill in ["self_guard","ch10_borrow_tide"] else TenCore.BOSS)=="","minimum command "+str(r))
   check(s.resolve_round(),"minimum round "+str(r))
   print("B06_MIN ",guard_only," round",r," HP",s.engine.actor_by_id(TenCore.HERO).hp," MP",s.engine.actor_by_id(TenCore.HERO).mp)
  check(s.engine.state.outcome=="victory","minimum survival guard="+str(guard_only))
  check(not TenSession.replay_receipt(s.receipt(),c.rules,c.combat,cfg,[h]).is_empty(),"minimum replay")
 print("B06 minimum fixture stats ",h)
