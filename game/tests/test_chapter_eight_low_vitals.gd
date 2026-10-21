extends SceneTree
const Campaign=preload("res://scripts/campaign/campaign_state.gd")
const Flow=preload("res://tests/chapter_eight_campaign_driver.gd")
var failures:=0
var checks:=0
func check(ok:bool,label:String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var base:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/prologue.json"))
 var payload:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://../output/cache/chapter_seven_gui/manual_natural_final.json"))
 # These are validator-accepted declared archive boundaries, not a second claim
 # about the recorded natural playthrough or an invented spending history.
 var last:Dictionary=payload.archive[-1]
 last.boundary_vitals.char_liang_xiao.mp=0
 last.boundary_vitals.char_axue.hp=1;last.boundary_vitals.char_axue.mp=0
 var low:int=1;var high:int=604
 while low<high:
  var mid:int=(low+high)/2
  last.boundary_vitals.char_liang_xiao.hp=mid
  var probe=Campaign.new(base)
  if probe.restore_persisted(payload)=="":high=mid
  else:low=mid+1
 last.boundary_vitals.char_liang_xiao.hp=low
 var c=Campaign.new(base);check(c.restore_persisted(payload)=="","formal low-vitals source accepted")
 if failures:quit(1);return
 print("LOW_VITALS_DECLARED_SOURCE H ",c.actors.char_liang_xiao.hp,"/",c.actors.char_liang_xiao.mp," A ",c.actors.char_axue.hp,"/",c.actors.char_axue.mp)
 var old:Dictionary=c.actors.char_axue.duplicate(true)
 check(c.enter_registered_chapter(8),"low-vitals chapter8 entry")
 for i in range(100):
  if c.state.finished:break
  if not Flow.advance(c,false,1):check(false,"low-vitals flow "+c.current_token());quit(1);return
 check(c.state.finished and c.state.xp==17365,"low-vitals mandatory completion")
 check(c.actors.char_axue.hp==old.hp and c.actors.char_axue.mp==old.mp,"injured snow never healed or attacked")
 var saved:Dictionary=c.prepare_persisted_save();check(saved.error=="","low-vitals endpoint valid "+str(saved.error))
 print("CH08 LOW VITALS ",checks," checks, ",failures," failures");quit(1 if failures else 0)
