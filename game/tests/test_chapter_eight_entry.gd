extends SceneTree
const Campaign=preload("res://scripts/campaign/campaign_state.gd")
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var c=Campaign.new(JSON.parse_string(FileAccess.get_file_as_string("res://data/prologue.json")))
 var payload:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://../output/cache/chapter_seven_gui/manual_natural_final.json"))
 var err:String=c.restore_persisted(payload)
 print("restore7=",err)
 if err!="":quit(1);return
 print("enter8=",c.enter_registered_chapter(8)," actors=",c.actors.char_liang_xiao.xp," token=",c.current_token())
 for i in range(3):
  var rt:RefCounted=c.current_chapter_runtime();var e:Dictionary=c.current_event();var ok:bool=false
  if e.op=="dialogue":ok=c.finish_dialogue(c.current_token())
  elif e.op=="action":ok=c.complete_action(c.current_token(),e.id,{"map_id":c.scene().map_id,"position":rt.maps[c.scene().map_id].actions[e.id].position})
  print("STEP ",e.id," ",ok)
  var saved:Dictionary=c.prepare_persisted_save();print("SAVE=",saved.error)
  if saved.error!="":quit(1);return
 print("ENTRY PASS")
 quit()
