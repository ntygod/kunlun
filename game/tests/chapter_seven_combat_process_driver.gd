extends "res://tests/test_chapter_seven_combat_boundaries.gd"
func run():
 setup()
 var p=party();p[1].mp=35
 var file="user://chapter_seven_phase_snapshot.json"
 if OS.get_environment("CH07_REPLAY_MODE")=="write":
  var s=session("b04",p);var d=Driver.new(check);var cases:Array=[]
  for n in range(20):
   if s.engine.state.objective.jin_repelled:break
   d.command(s,H,"LX_A03" if s.engine.validate_command(H,"LX_A03","jin_fei")=="" else "normal_attack","jin_fei");d.resolve(s)
  d.input(s,"free_axue");cases.append({"name":"free_snow_queued_not_executed","snapshot":s.snapshot()});d.resolve(s)
  check(s.engine.state.objective.snow_freed and not s.engine.state.objective.haiya_handed,"real rescue intermediate")
  cases.append({"name":"snow_freed_haiya_still_locked","snapshot":s.snapshot()})
  d.input(s,"handoff_haiya");cases.append({"name":"handoff_queued","snapshot":s.snapshot()});d.resolve(s)
  cases.append({"name":"phase2_actual_checkpoint","snapshot":s.snapshot()})
  d.input(s,"calibrate","A","left_beam");cases.append({"name":"half_commands_calibration_only","snapshot":s.snapshot()})
  d.command(s,A,"self_guard",A);d.resolve(s)
  cases.append({"name":"calibrated_not_fired","snapshot":s.snapshot()})
  d.input(s,"fire","A");d.command(s,A,"AX_S01",A)
  cases.append({"name":"fire_and_ax_queued","snapshot":s.snapshot()});d.resolve(s)
  for support in ["B","C"]:
   d.input(s,"calibrate",support,{"B":"crossbeam","C":"right_winch"}[support]);d.command(s,A,"self_guard",A);d.resolve(s)
   d.input(s,"fire",support);d.command(s,A,"self_guard",A);d.resolve(s)
  check(s.engine.state.outcome=="victory","writer victory")
  var f=FileAccess.open(file,FileAccess.WRITE);f.store_string(JSON.stringify({"cases":cases,"expected":s.snapshot()}));f.close()
 else:
  var saved:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(file))
  for case in saved.cases:
   var s=session("b04",p)
   check(s.restore(case.snapshot),"fresh process restores "+case.name)
   check(Session._replay_history(s,saved.expected.history.slice(case.snapshot.history.size())),"remaining real actions replay "+case.name)
   check(Compare.equivalent(s.snapshot(),saved.expected),"separate process exact result "+case.name)
   var forged=case.snapshot.duplicate(true);forged.state.actors[0].mp=999
   var before=s.snapshot();check(not s.restore(forged),"forged refill rejected")
   check(Compare.equivalent(before,s.snapshot()),"bad load leaves active state unchanged")
 print("CH07 combat process ",OS.get_environment("CH07_REPLAY_MODE"),": ",checks," checks, ",failures," failures")
 quit(1 if failures else 0)
