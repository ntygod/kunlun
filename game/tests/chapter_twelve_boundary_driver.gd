extends SceneTree
const Campaign=preload("res://scripts/campaign/campaign_state.gd")
const Flow=preload("res://tests/chapter_twelve_campaign_driver.gd")
func _initialize()->void:call_deferred("run")
func run()->void:
 var source:String=OS.get_environment("CH12_SOURCE");var destination:String=OS.get_environment("CH12_BOUNDARY_OUTPUT")
 if source.is_empty() or destination.is_empty():push_error("CH12_SOURCE/CH12_BOUNDARY_OUTPUT required");quit(1);return
 var c=Campaign.new(JSON.parse_string(FileAccess.get_file_as_string("res://data/prologue.json")))
 var error:String=c.restore_persisted(JSON.parse_string(FileAccess.get_file_as_string(source)))
 if error!="" or not c.enter_registered_chapter(12):push_error("Formal source/entry: "+error);quit(1);return
 var target:String=OS.get_environment("CH12_BOUNDARY_ID")
 if target.is_empty():target="enc_ch12_han_duel"
 for i in range(240):
  if c.current_event().id==target:
   var rt:RefCounted=c.current_chapter_runtime()
   var payload:Dictionary={"provenance":"legal command-generated boundary, not natural GUI","actors":c.actors.duplicate(true),"event_id":target,"xp":c.state.xp,"live_save":c.export_save()}
   if c.current_event().op=="objective_battle":
    var battle:RefCounted=rt.make_objective_encounter()
    if battle==null:push_error("Canonical battle rejected "+target+" party "+JSON.stringify(rt.combat_party()));quit(1);return
    payload.merge({"rules":c.rules,"runtime":c.combat,"cfg":battle.encounter,"party":battle.initial_party,"attempt":battle.attempt_id})
   var file=FileAccess.open(destination,FileAccess.WRITE)
   if file==null:push_error("Output unavailable");quit(1);return
   file.store_string(JSON.stringify(payload));file.close();print("BOUNDARY ",target," XP ",c.state.xp," ",destination);quit(0);return
  if c.state.finished or not Flow.advance(c,0,OS.get_environment("CH12_BOUNDARY_SIDE")=="1"):push_error("Boundary advance failed: "+c.current_token());quit(1);return
 push_error("Boundary limit");quit(1)
