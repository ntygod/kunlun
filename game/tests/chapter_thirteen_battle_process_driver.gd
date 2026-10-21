extends SceneTree
const Session=preload("res://scripts/combat/chapter_thirteen_encounter.gd")
const Core=preload("res://scripts/combat/chapter_thirteen_engine.gd")
const Fixture=preload("res://tests/test_chapter_thirteen_combat.gd")
const Driver=preload("res://tests/chapter_thirteen_encounter_driver.gd")
func _initialize()->void:
 var rules:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/combat_rules.json"));var runtime:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/combat_runtime.json"))
 var path:="user://b10-partial.json"
 print("B10 process ",OS.get_process_id()," mode ",OS.get_environment("CH13_BATTLE_MODE"))
 if OS.get_environment("CH13_BATTLE_MODE")=="reader":
  var hash:=FileAccess.get_sha256(path)
  var s=Session.from_snapshot(JSON.parse_string(FileAccess.get_file_as_string(path)),rules,runtime)
  if s==null or s.get_view().round!=4 or not s.get_view().commands.has(Core.HERO):push_error("new process did not restore pending phase2 command");quit(1);return
  if not Driver.run(s) or FileAccess.get_sha256(path)!=hash:push_error("new process continuation or source bytes failed");quit(1);return
  print("B10 process reader: 2 checks, 0 failures")
 else:
  var config:=Core.encounter_config();config.context={"chapter":13,"current_token":"process_b10"}
  var s=Session.new(rules,runtime,config,Fixture.party_fixture(),"process_b10")
  for i in range(3):
   for c in Driver.commands(s):
    if s.set_command(c[0],c[1],c[2])!="":push_error("writer command failed");quit(1);return
   if not s.resolve_round():push_error("writer round failed");quit(1);return
  for c in Driver.commands(s):
   if s.set_command(c[0],c[1],c[2])!="":push_error("pending command failed");quit(1);return
  var f:=FileAccess.open(path,FileAccess.WRITE);f.store_string(JSON.stringify(s.snapshot()));f.close()
  print("B10 process writer: 1 checks, 0 failures")
 quit(0)
