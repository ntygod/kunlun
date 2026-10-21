extends SceneTree
const Campaign=preload("res://scripts/campaign/campaign_state.gd")
const Flow=preload("res://tests/chapter_twelve_campaign_driver.gd")
const Same=preload("res://scripts/campaign/encounter_session.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func _initialize()->void:call_deferred("run")
func run()->void:
 var path:String=OS.get_environment("CH12_SOURCE")
 if path.is_empty():push_error("CH12_SOURCE required");quit(1);return
 var source:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(path));var base:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/prologue.json"))
 for plan in [["keep","keep","hook"],["counter","healing","rescue"],["recommended","recommended","hook"],["keep","recommended","rescue"],["counter","keep","rescue"],["recommended","healing","hook"]]:
  var c=Campaign.new(base);check(c.restore_persisted(source)=="" and c.enter_registered_chapter(12),"legal source "+str(plan))
  var x_initial:Array=c.actors.char_hua_xiaoshuang.equipped_active_skills.duplicate()
  for i in range(160):
   var rt:RefCounted=c.current_chapter_runtime();var e:Dictionary=c.current_event()
   if e.id=="evt_ch12_b09_won":break
   if e.op=="choice" and e.get("choice_key","") in ["b08_loadout","b09_loadout","liuying_loadout"]:
    var index:int=["b08_loadout","b09_loadout","liuying_loadout"].find(e.choice_key)
    var prefix:String=["ch12_b08_loadout_","ch12_b09_loadout_","ch12_liuying_loadout_"][index]
    var before:Dictionary=c.actors.duplicate(true)
    check(c.choose(c.current_token(),prefix+plan[index]),"explicit choice "+prefix+plan[index])
    check(Same.equivalent(before,c.actors),"choice receipt before equipment transaction")
    continue
   if e.id=="evt_ch12_han_challenge" and plan[0]=="keep":check(c.actors.char_hua_xiaoshuang.equipped_active_skills==x_initial,"inherited X four slots remain")
   if not Flow.advance(c,0,false):check(false,"actual loadout path "+str(plan)+" "+c.current_token());break
  check(c.current_event().id=="evt_ch12_b09_won","actual four battle victories "+str(plan))
  if c.current_event().id!="evt_ch12_b09_won":continue
  var prepared:Dictionary=c.prepare_persisted_save();check(prepared.error=="","partial postcombat loadout persists")
  var rebuilt=Campaign.new(base);check(rebuilt.restore_persisted(prepared.payload)=="","exact choices/skills/battle replay")
  check(Same.equivalent(c.actors,rebuilt.actors),"loadout and real resources stable")
 print("CH12 LOADOUTS ",checks," checks ",failures," failures");quit(0 if failures==0 else 1)
