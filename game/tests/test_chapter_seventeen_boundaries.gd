extends SceneTree
const Campaign=preload("res://scripts/campaign/campaign_state.gd")
const Driver=preload("res://tests/chapter_seventeen_driver.gd")
const Same=preload("res://scripts/campaign/encounter_session.gd")
const Transactions=preload("res://scripts/campaign/chapter_seventeen_transactions.gd")
var checks=0
var failures=0
func _initialize()->void:call_deferred("run")
func check(ok:bool,label:String)->bool:
 checks+=1
 if not ok:failures+=1;push_error(label)
 return ok
func run()->void:
 var source:=OS.get_environment("CH17_SOURCE")
 if source=="" or not FileAccess.file_exists(source):push_error("CH17_SOURCE required");quit(2);return
 var base:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/prologue.json"))
 var c=Campaign.new(base)
 if not check(c.restore_persisted(JSON.parse_string(FileAccess.get_file_as_string(source)))=="" and c.enter_registered_chapter(17),"bounded test entry"):quit(1);return
 for n in range(50):
  if c.current_event().get("puzzle_id")=="pz_ch17_roof":break
  if not check(Driver.advance(c,0,true),"reach roof bounded case"):quit(1);return
 var rt:RefCounted=c.current_chapter_runtime();var token:String=c.current_token()
 var p:RefCounted=rt.make_puzzle()
 if not check(p!=null,"roof resolver acquired"):quit(1);return
 check(rt.puzzle_input(token,{"type":"hint"}).ok,"retained hint")
 for n in range(511):
  if not rt.puzzle_input(token,{"type":"place","actor":Driver.F,"part":"reeds"}).ok:check(false,"fill real incorrect inputs");break
 check(p.history.size()==512,"attempt history bounded")
 check(not rt.puzzle_input(token,Driver.puzzle_action(p)).ok,"cap does not silently drop input")
 var stale:int=p.state.revision
 var before:Dictionary=c.prepare_persisted_save()
 check(before.error=="","full attempt can be persisted")
 check(rt.puzzle_input(token,{"type":"reset","revision":stale}).ok,"legal reset after cap")
 check(rt.make_puzzle().state.hint_level==1 and rt.make_puzzle().history.size()==1,"reset preserves hints without unbounded resolver log")
 var after:Dictionary=rt.make_puzzle().snapshot()
 check(not rt.puzzle_input(token,{"type":"place","actor":Driver.L,"part":"beam","revision":stale}).ok,"previous epoch cannot place roof")
 check(Same.equivalent(rt.make_puzzle().snapshot(),after),"stale operation atomic")
 var saved:Dictionary=c.prepare_persisted_save();check(saved.error=="","reset campaign save encodes")
 var clone=Campaign.new(base)
 check(clone.restore_persisted(saved.payload)=="","bounded reset replay restores")
 check(Same.equivalent(clone.current_chapter_runtime().make_puzzle().snapshot(),after),"reset replay exact")
 var actors:Dictionary=c.actors.duplicate(true);var items:Dictionary=c.items.duplicate(true);var state:Dictionary=c.state.duplicate(true);var world:Dictionary=c.world_objects.duplicate(true)
 var untouched:Array=[actors.duplicate(true),items.duplicate(true),state.duplicate(true),world.duplicate(true)]
 check(not Transactions.apply("departure_typo",actors,items,state,world),"unknown semantic event rejected")
 check(Same.equivalent(untouched,[actors,items,state,world]),"failed semantic event does not partially commit")
 var font:Font=load("res://assets/fonts/kunlun_ui.ttf")
 var missing:Dictionary={}
 for path in ["res://data/chapter_seventeen.json","res://scripts/campaign/chapter_seventeen_runtime.gd","res://scripts/combat/chapter_seventeen_engine.gd","res://scripts/puzzles/chapter_seventeen_puzzle_resolver.gd","res://scripts/ui/chapter_seventeen_battle_panel.gd","res://scripts/ui/chapter_seventeen_puzzle_panel.gd","res://scripts/ui/chapter_seventeen_puzzle_board.gd"]:
  var text:=FileAccess.get_file_as_string(path)
  for i in range(text.length()):
   var code:int=text.unicode_at(i)
   if code>=0x4e00 and code<=0x9fff and not font.has_char(code):missing[char(code)]=true
 check(missing.is_empty(),"bundled Chinese glyph coverage: "+str(missing.keys()))
 print("Chapter seventeen boundaries: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
