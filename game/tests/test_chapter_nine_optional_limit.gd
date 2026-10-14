extends SceneTree
const Campaign=preload("res://scripts/campaign/campaign_state.gd")
const Flow=preload("res://tests/chapter_nine_campaign_driver.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func _initialize()->void:call_deferred("run")
func run()->void:
 var c=Campaign.new(JSON.parse_string(FileAccess.get_file_as_string("res://data/prologue.json")))
 check(c.restore_persisted(JSON.parse_string(FileAccess.get_file_as_string("res://../output/cache/chapter_eight_gui/manual_natural_final.json")))=="","source")
 check(c.enter_registered_chapter(9),"chapter9")
 for i in range(100):
  if c.current_event().get("id")=="side_ch09_l05":break
  check(Flow.advance(c,false),"reach side window")
 var rt:RefCounted=c.current_chapter_runtime();check(rt.open_sidequest("L05"),"open optional")
 var token:String=c.current_token();var model:RefCounted=rt.make_puzzle()
 check(rt.puzzle_input(token,{"type":"interact"}).ok,"actual accept")
 for i in range(4095):
  check(rt.puzzle_input(token,{"type":"move","dx":1 if i%2==0 else -1,"dy":0}).ok,"real effective step")
  if i%512==0:print("LIMIT_STEP ",i)
 check(model.input_log.size()==4096,"actual model budget reached")
 check(not rt.puzzle_input(token,{"type":"move","dx":-1,"dy":0}).ok,"documented effective-action cap")
 check(rt.pause_sidequest(),"full optional log still permits pause")
 check(rt.close_window(c.current_token()),"main window still continues")
 for i in range(90):
  if c.state.finished:break
  check(Flow.advance(c,false),"main after capped optional")
 check(c.state.finished,"main completes despite capped optional")
 check(c.state.xp==20495 and c.state.coins==3050,"mandatory totals unchanged")
 check(c.state.optional.L05.status=="missed" and not c.items.has("item_ch09_physician_key") and not c.reward_ledger.has("reward_ch09_l05"),"no fake optional rewards")
 var saved:Dictionary=c.prepare_persisted_save();check(saved.error=="","capped optional ends in valid bounded archive")
 print("Chapter nine optional effective limit: ",checks," checks, ",failures," failures");quit(1 if failures else 0)
