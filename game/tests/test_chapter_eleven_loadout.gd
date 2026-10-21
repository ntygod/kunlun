extends SceneTree
const Campaign=preload("res://scripts/campaign/campaign_state.gd")
const Flow=preload("res://tests/chapter_eleven_campaign_driver.gd")
const Battle=preload("res://tests/chapter_eleven_encounter_driver.gd")
const Same=preload("res://scripts/campaign/encounter_session.gd")
const X="char_hua_xiaoshuang"
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func _initialize()->void:call_deferred("run")
func run()->void:
 var path:String=OS.get_environment("CH11_SOURCE")
 if path.is_empty():push_error("Set CH11_SOURCE to a verified automated10 terminal");quit(1);return
 var source:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(path));var base:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/prologue.json"))
 for side in [false,true]:
  var c=Campaign.new(base);check(c.restore_persisted(source)=="","source");check(c.enter_registered_chapter(11),"enter")
  for i in range(100):
   if c.current_event().get("group")=="choice_ch11_xiaoshuang_loadout":break
   if not Flow.advance(c,0,side):check(false,"preparation trajectory");quit(1);return
  var options:Array=c.available_choices();check(options.size()==(5 if side else 1),"only learned replacements offered")
  var before:Dictionary=c.export_save();var hp:int=c.actors[X].hp;var mp:int=c.actors[X].mp
  check(not c.choose(c.current_token(),"ch11_loadout_replace_a06") and Same.equivalent(before,c.export_save()),"unavailable replacement atomic")
  for option in options:
   var selected:String=OS.get_environment("CH11_LOADOUT_FILTER")
   if not selected.is_empty() and option.id!=selected:continue
   var copy=Campaign.new(base);check(copy.restore_persisted(before)=="","prechoice replay")
   check(copy.choose(copy.current_token(),option.id),"explicit choice "+option.id)
   check(copy.finish_dialogue(copy.current_token()),"commit named loadout")
   var slots:Array=copy.actors[X].equipped_active_skills
   check(slots.size()==4 and slots.count("HXS_A04")==int(option.id!="ch11_loadout_default"),"exactly four active slots")
   check(copy.actors[X].hp==hp and copy.actors[X].mp==mp,"free preparation never refills")
   var stored:Dictionary=copy.prepare_persisted_save();check(stored.error=="","loadout canonical "+str(stored.error))
   for i in range(5):
    if copy.current_event().op=="objective_battle":break
    check(Flow.advance(copy,0,side),"advance to B07")
   var rt:RefCounted=copy.current_chapter_runtime();var battle:RefCounted=rt.make_objective_encounter();check(battle!=null,"equipped battle legal")
   if battle==null:continue
   var commands:Array=rt.combat_party()[1].skills.duplicate()
   for standard in ["normal_attack","self_guard","guard_ally"]:commands.erase(standard)
   check(Same.equivalent(commands,slots),"engine commands match explicit slots")
   if option.id=="ch11_loadout_replace_a03" and not OS.get_environment("CH11_BATTLE_EXPORT").is_empty():
    var file=FileAccess.open(OS.get_environment("CH11_BATTLE_EXPORT"),FileAccess.WRITE)
    file.store_string(JSON.stringify({"rules":copy.rules,"runtime":copy.combat,"cfg":battle.encounter,"party":battle.initial_party,"attempt":battle.attempt_id}));file.close()
   check(Battle.run(battle),"real battle with "+option.id)
 print("Chapter eleven loadout: ",checks," checks, ",failures," failures")
 quit(1 if failures else 0)
