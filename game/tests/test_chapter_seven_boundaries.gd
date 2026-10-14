extends SceneTree
const Campaign=preload("res://scripts/campaign/campaign_state.gd")
const Flow=preload("res://tests/chapter_seven_campaign_driver.gd")
const Proof=preload("res://scripts/campaign/encounter_session.gd")
var checks:=0
var failures:=0
var base:Dictionary
func check(ok:bool,label:String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func _initialize() -> void:call_deferred("run")
func source() -> RefCounted:
 var c=Campaign.new(base)
 check(c.restore_persisted(JSON.parse_string(FileAccess.get_file_as_string("res://../output/cache/chapter_six_gui/manual_natural_final.json")))=="","legal natural source")
 check(c.enter_registered_chapter(7),"real entry")
 return c
func until(c:RefCounted,id:String) -> bool:
 for n in range(180):
  if c.current_event().get("id")==id:return true
  if c.state.finished or not Flow.advance(c,false):return false
 return false
func run() -> void:
 base=JSON.parse_string(FileAccess.get_file_as_string("res://data/prologue.json"))
 for branch in range(3):
  var c=source();check(until(c,"ch07_campfire_window"),"campfire window")
  var rt:RefCounted=c.current_chapter_runtime()
  if branch>0:
   check(rt.open_sidequest("L03"),"open L03")
   check(Flow.advance(c),"notice actual")
   check(Flow.advance(c),"listen")
   check(Flow.advance(c,true,1),"truth tone")
   check(Flow.advance(c),"feedback")
   var session:RefCounted=rt.make_puzzle()
   var result:Dictionary=rt.puzzle_input(c.current_token(),session.next_demo_action())
   check(result.get("ok",false),"one real written line")
   var partial:Dictionary=rt.make_puzzle().snapshot()
   check(rt.pause_sidequest(),"pause letter in progress")
   var payload:Dictionary=c.export_save();var clone=Campaign.new(base)
   check(clone.restore_persisted(payload)=="","partial side save replay")
   check(rt.open_sidequest("L03"),"reopen same letter")
   check(Proof.equivalent(partial,rt.make_puzzle().snapshot()),"partial preserved exact")
   check(rt.pause_sidequest(),"return main again")
  check(rt.close_window(c.current_token()),"window doesn't close optional early")
  check(until(c,"ch07_departure_confirmed"),"explicit rest before departure")
  var hp:int=c.actors.char_liang_xiao.hp;var mp:int=c.actors.char_liang_xiao.mp
  check(hp==c.actors.char_liang_xiao.max_hp,"rest explicit full HP")
  var before:Dictionary=c.export_save()
  check(not rt.complete(c.current_token(),{}),"departure needs explicit confirmation")
  check(Proof.equivalent(before,c.export_save()),"cancel doesn't mutate or lock")
  if branch==2:
   check(rt.open_sidequest("L03"),"return to letters at last window")
   for n in range(30):
    if c.state.scope=="main":break
    check(Flow.advance(c,true,1),"finish letters after resumed rest")
   check(c.state.optional.L03.status=="archived","resumed L03 complete")
  else:check(rt.disposition("L03","declined"),"decline unfinished")
  check(rt.close_window(c.current_token()),"departure locks only on confirmation")
  check(not rt.open_sidequest("L03"),"window permanently closed")
  check(c.state.coins==1400,"no letter silver transfer")
  check(c.actors.char_liang_xiao.mp==mp,"rest/letters no hidden MP")
  check(c.reward_ledger.has("reward_ch07_l03")==bool(branch==2),"only archive rewards")
  check(c.items.has("item_ch07_dried_date")==bool(branch==2),"one date only for complete")
  var saved:Dictionary=c.prepare_persisted_save();check(saved.error=="","interrupted legal branch persists")
 var c=source();var original:Dictionary=c.export_save()
 for field in ["active_chapter","archive","current"]:
  for bad in [true,false,null,"wrong",{},[]]:
   var broken:Dictionary=original.duplicate(true);broken[field]=bad
   check(c.restore_persisted(broken)!="","bad outer save rejected")
   check(Proof.equivalent(original,c.export_save()),"bad save leaves active game unchanged")
 print("Chapter seven boundaries: ",checks," checks, ",failures," failures")
 quit(1 if failures else 0)
