extends "res://tests/test_chapter_nine_encounter.gd"
func run():
 setup()
 var path="user://chapter_nine_encounter_replay.json"
 if OS.get_environment("CH09_REPLAY_MODE")=="write":
  var s=session(party(1200,7));var cases:Array=[]
  s.apply_input({"actor_id":H,"action_id":"wait","value":"well_soldier_1"})
  cases.append({"name":"partial_preparation","snapshot":s.snapshot()});s.resolve_round()
  Driver.step(s,"wait","well_soldier_1")
  cases.append({"name":"mistake_damage","snapshot":s.snapshot()})
  Driver.step(s,"observe","well_soldier_1");Driver.step(s,"disarm","well_soldier_1")
  cases.append({"name":"first_soldier_retired","snapshot":s.snapshot()})
  Driver.step(s,"observe","well_soldier_2");Driver.step(s,"disarm","well_soldier_2")
  check(s.engine.state.outcome=="victory","writer reaches true victory")
  var f=FileAccess.open(path,FileAccess.WRITE);f.store_string(JSON.stringify({"cases":cases,"expected":s.snapshot(),"receipt":s.receipt()}));f.close()
 else:
  var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(path))
  for case in data.cases:
   var s=session(party(1200,7))
   check(s.restore(case.snapshot),"fresh process restore "+case.name)
   check(Compare.equivalent(s.snapshot(),case.snapshot),"exact partial state "+case.name)
   check(Session._replay(s,data.expected.history.slice(case.snapshot.history.size())),"continue real commands "+case.name)
   check(Compare.equivalent(s.snapshot(),data.expected) and Compare.equivalent(s.receipt(),data.receipt),"exact final and receipt "+case.name)
   var forged=case.snapshot.duplicate(true);forged.state.actors[0].mp=150
   var before=s.snapshot()
   check(not s.restore(forged) and Compare.equivalent(before,s.snapshot()),"forged refill atomic "+case.name)
 print("Chapter nine encounter process %s: %d checks, %d failures" % [OS.get_environment("CH09_REPLAY_MODE"),checks,failures]);quit(1 if failures else 0)
