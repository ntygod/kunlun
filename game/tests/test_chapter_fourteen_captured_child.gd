extends SceneTree
const Campaign=preload("res://scripts/campaign/campaign_state.gd")
const Flow=preload("res://tests/chapter_fourteen_campaign_driver.gd")
const World=preload("res://scripts/world.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func _initialize()->void:call_deferred("run")
func projection(c:RefCounted,hidden:bool,label:String)->void:
 var rt:RefCounted=c.current_chapter_runtime();var context:Dictionary=rt.world_context()
 check(("npc_zhao_bing" in context.departed_actor_ids)==hidden,label+" context reflects existing story")
 var w=World.new();root.add_child(w)
 w.configure({"id":"ch14_temple_gate","map_id":"map_ch14_temple_gate","cast":[]},Vector2(64,256),context)
 check(w.cast_actors.has("npc_zhao_bing"),"authored child exists")
 w.sync_controlled_view({"world_state":{"map_id":"map_ch14_temple_gate","control_actor_id":"char_huasheng","visible_actor_ids":["npc_zhao_bing","char_huasheng"],"actor_positions":{"npc_zhao_bing":[336,160]}}})
 check(w.cast_actors.npc_zhao_bing.visible==not hidden,label+" live visible list cannot override captivity")
 w.configure({"id":"ch14_temple_gate","map_id":"map_ch14_temple_gate","cast":[]},Vector2(64,256),rt.world_context())
 w.sync_controlled_view({"world_state":{"map_id":"map_ch14_temple_gate","visible_actor_ids":["npc_zhao_bing"]}})
 check(w.cast_actors.npc_zhao_bing.visible==not hidden,label+" reconfigure preserves projection")
 w.queue_free();await process_frame
func run()->void:
 var path:=OS.get_environment("CH14_SOURCE")
 if not FileAccess.file_exists(path):push_error("CH14_SOURCE required");quit(1);return
 for action in ["move_left","move_right","move_up","move_down"]:
  if not InputMap.has_action(action):InputMap.add_action(action)
 var c=Campaign.new(JSON.parse_string(FileAccess.get_file_as_string("res://data/prologue.json")))
 check(c.restore_persisted(JSON.parse_string(FileAccess.get_file_as_string(path)))=="" and c.enter_registered_chapter(14),"formal13 enters14")
 await projection(c,false,"before abduction")
 var captured:=false;var released:=false
 for i in range(1000):
  var status:String=c.world_objects.get("ch14_abduction",{}).get("child","")
  if status=="captured" and not captured:
   captured=true;await projection(c,true,"after abduction")
  if c.current_event().id=="world_ch14_stone_lion":
   var rt:RefCounted=c.current_chapter_runtime();var model:RefCounted=rt.make_puzzle()
   check(rt.puzzle_input(c.current_token(),model.next_demo_action()).get("ok",false),"real lion partial input")
   var saved:Dictionary=c.prepare_persisted_save();check(saved.error=="" and c.restore_persisted(saved.payload)=="","partial strict replay")
   await projection(c,true,"restored lion partial")
  if status=="released_to_jiuru":
   released=true;await projection(c,false,"released to Jiuru")
   var saved:Dictionary=c.prepare_persisted_save();check(saved.error=="" and c.restore_persisted(saved.payload)=="","released state strict replay")
   await projection(c,false,"restored release");break
  if not Flow.advance(c):check(false,"normal story advance "+str(c.current_event()));break
 check(captured and released,"actual abduction and release transactions observed")
 print("Chapter14 captured child projection: ",checks," checks, ",failures," failures");quit(1 if failures else 0)
