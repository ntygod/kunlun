extends SceneTree
const Campaign=preload("res://scripts/campaign/campaign_state.gd")
const Transactions=preload("res://scripts/campaign/chapter_nine_transactions.gd")
const Canonical=preload("res://scripts/campaign/encounter_session.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func _initialize()->void:call_deferred("run")
func run()->void:
 var base:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/prologue.json"))
 var paths:Array=["res://../output/cache/chapter_eight_gui/manual_natural_final.json",OS.get_environment("CH09_MIN_SOURCE")]
 for path in paths:
  if str(path).is_empty():check(false,"supply actual generated minimum source");continue
  var raw:String=FileAccess.get_file_as_string(path);var c=Campaign.new(base)
  check(c.restore_persisted(JSON.parse_string(raw))=="","real eighth source")
  var old:Dictionary=c.actors.duplicate(true);var legacy:Dictionary=c.export_save()
  check(c.enter_registered_chapter(9),"enter9 keeps old skill values")
  check(Canonical.equivalent(old,c.actors),"entry does not retroactively change chapter8")
  for missing in [false,true]:
   var actors:Dictionary=c.actors.duplicate(true);var items:Dictionary=c.items.duplicate(true);var state:Dictionary=c.state.duplicate(true);var world:Dictionary=c.world_objects.duplicate(true)
   if missing:
    for who in ["char_liang_xiao","char_liu_yingying"]:
     for skill in actors[who].skills.duplicate():
      if "_A" in str(skill):actors[who].skills.erase(skill);actors[who].skill_ranks.erase(skill)
   var skills:Dictionary={}
   for who in ["char_liang_xiao","char_liu_yingying"]:skills[who]=actors[who].skills.duplicate()
   check(Transactions.apply("evt_ch09_archive_mq09",actors,items,state,world),"archive transaction")
   for who in skills:
    check(actors[who].skills==skills[who],"never grant missing skill")
    check(actors[who].hp==old[who].hp and actors[who].mp==old[who].mp,"rank does not restore resources")
    for skill in old[who].skill_ranks:
     if "_N" in str(skill) or "_P" in str(skill):check(actors[who].skill_ranks[skill]==old[who].skill_ranks[skill],"N/P unchanged")
   if not missing:
    var rank:int=3 if state.inherited_ch04_optional.get("R02",{}).get("status")=="archived" else 2
    check(actors.char_liu_yingying.skill_ranks.LYY_A03==rank,"A03 source-aware rank")
    for skill in ["LYY_A04","LYY_A05"]:check(actors.char_liu_yingying.skill_ranks[skill]==2,"chapter5+2 active")
   var before:Dictionary={"actors":actors.duplicate(true),"items":items.duplicate(true),"state":state.duplicate(true),"world":world.duplicate(true)}
   check(not Transactions.apply("evt_ch09_archive_mq09",actors,items,state,world),"duplicate archive rejected")
   check(Canonical.equivalent(before,{"actors":actors,"items":items,"state":state,"world":world}),"duplicate atomic")
  check(FileAccess.get_file_as_string(path)==raw,"original source bytes untouched")
 print("Chapter nine skill milestones: ",checks," checks, ",failures," failures");quit(1 if failures else 0)
