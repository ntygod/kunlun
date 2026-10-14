extends "res://tests/test_chapter_five_history_matrix.gd"
## Genuine no-side chapter 0–5 route. No actor edits or test max-HP party.
const SixSession=preload("res://scripts/combat/chapter_six_encounter.gd")
const SixDriver=preload("res://tests/chapter_six_battle_driver.gd")
func run() -> void:
 base=JSON.parse_string(FileAccess.get_file_as_string("res://data/prologue.json"))
 var c=chapter_two_subset(0)
 check(c.enter_chapter_three(),"minimum ch3 entry")
 for j in range(180):
  if c.state.finished:break
  if not act_three(c,16):check(false,"ch3 progress");quit(2);return
 check(c.enter_registered_chapter(4),"minimum ch4 entry")
 for j in range(260):
  if c.state.finished:break
  if not advance_four(c,0):check(false,"ch4 progress");quit(2);return
 check(c.enter_registered_chapter(5),"minimum ch5 entry")
 for j in range(220):
  if c.state.finished:break
  if not advance_whole_five(c):check(false,"ch5 progress");quit(2);return
 check(c.state.finished and c.state.xp==7000,"genuine no-side 7000XP terminal")
 var party=c.current_chapter_runtime().combat_party()
 var data=JSON.parse_string(FileAccess.get_file_as_string("res://data/chapter_six_encounters.json"))
 print("CH06 true minimum precursor ",JSON.stringify(party))
 for kind in ["white_plum","tutuha_spar","basket_guard"]:
  var p=party.duplicate(true)
  if kind!="basket_guard":p=p.filter(func(a):return a.id=="char_liang_xiao")
  var session=SixSession.new(c.rules,c.combat,data.encounters["enc_ch06_"+kind],p,"minimum_precursor")
  var driver=SixDriver.new(check);driver.run(session)
  check(session.engine.state.outcome=="victory","weaker genuine chapter5 minimum precursor "+kind)
  print("CH06 minimum ",kind," endHP ",session.engine.actor_by_id("char_liang_xiao").hp)
 print("CH06 genuine minimum ",checks," checks ",failures," failures")
 quit(1 if failures else 0)
