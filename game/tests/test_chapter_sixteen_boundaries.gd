extends SceneTree
const Campaign=preload("res://scripts/campaign/campaign_state.gd")
const Driver=preload("res://tests/chapter_sixteen_driver.gd")
const Same=preload("res://scripts/campaign/encounter_session.gd")
const Tx=preload("res://scripts/campaign/chapter_sixteen_transactions.gd")
var checks=0
var failures=0
func _initialize()->void:call_deferred("run")
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func run()->void:
 var path:=OS.get_environment("CH16_SOURCE")
 if path.is_empty() or not FileAccess.file_exists(path):push_error("CH16_SOURCE required");quit(2);return
 var base:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/prologue.json"))
 var c:=Campaign.new(base)
 check(c.restore_persisted(JSON.parse_string(FileAccess.get_file_as_string(path)))=="" and c.enter_registered_chapter(16),"real prior model entry")
 for i in range(20):
  if c.current_event().get("op")=="puzzle":break
  if not Driver.advance(c):check(false,"reach first puzzle");quit(1);return
 var rt:RefCounted=c.current_chapter_runtime();var token:String=c.current_token()
 rt.puzzle_input(token,{"type":"hint"});rt.puzzle_input(token,{"type":"survey"})
 var limit:int=load(rt.PUZZLE_SCRIPT).MAX_INPUTS
 for i in range(limit-2):
  if not rt.puzzle_input(token,{"type":"test"}).ok:check(false,"fill real input log");break
 var old:Dictionary=rt.make_puzzle().snapshot();check(old.history.size()==limit,"full bounded attempt")
 check(not rt.puzzle_input(token,{"type":"test"}).ok,"cap rejects new nonreset inputs")
 var records:int=c.state.chronology.size()
 check(rt.puzzle_input(token,{"type":"reset","revision":int(old.state.revision)}).ok,"reset still available at hard cap")
 check(rt.make_puzzle().history.size()==1 and rt.make_puzzle().state.hint_level==1,"new bounded attempt keeps only original hint level")
 check(c.state.chronology.size()==records+1,"restart itself remains in campaign proof")
 check(not rt.puzzle_input(token,{"type":"gate","channel":0,"value":4,"revision":int(old.state.revision)}).ok,"old epoch cannot act on new attempt")
 var persisted:Dictionary=c.prepare_persisted_save();check(persisted.error=="","capped retry checkpoint validates "+persisted.error)
 var clone:=Campaign.new(base);check(clone.restore_persisted(persisted.payload)=="","new attempt restores from full campaign evidence")
 check(Same.equivalent(rt.make_puzzle().snapshot(),clone.current_chapter_runtime().make_puzzle().snapshot()),"new attempt identity exact")
 check(Driver.advance(c),"new attempt can actually complete")
 # Transactions stage all writes. A late prerequisite error cannot give the first gift.
 var actors:Dictionary={"char_liang_xiao":{"status":"active"},"char_feng_lian":{"status":"exploration_companion"}}
 var items:Dictionary={"item_ch16_firestarter":{"owner":"char_liang_xiao","state":"carried"}}
 var state:Dictionary={"semantic_commits":[],"choices":{"farewell":"farewell_tools"}}
 var world:Dictionary={"ch16_feng":{"location":"jingjue"}}
 var before:Array=[actors.duplicate(true),items.duplicate(true),state.duplicate(true),world.duplicate(true)]
 check(not Tx.apply("leave_feng",actors,items,state,world),"missing second gift rejects entire transaction")
 check(Same.equivalent(before,[actors,items,state,world]),"failed gift never partially changes owner")
 var font:Font=load("res://assets/fonts/kunlun_ui.ttf")
 var texts:=""
 for filename in ["res://data/chapter_sixteen.json","res://data/chapter_sixteen_runtime.json","res://data/maps/chapter_sixteen_maps.json","res://scripts/campaign/chapter_sixteen_runtime.gd","res://scripts/puzzles/chapter_sixteen_puzzle_resolver.gd","res://scripts/ui/chapter_sixteen_puzzle_panel.gd","res://scripts/ui/chapter_sixteen_puzzle_board.gd","res://scripts/combat/chapter_sixteen_engine.gd"]:texts+=FileAccess.get_file_as_string(filename)
 var missing:Array=[]
 for character in texts:
  var code:int=character.unicode_at(0)
  if code>=0x3400 and code<=0x9fff and not font.has_char(code) and character not in missing:missing.append(character)
 check(missing.is_empty(),"bundled Chinese glyph coverage: "+str(missing))
 print("Chapter sixteen boundaries: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
