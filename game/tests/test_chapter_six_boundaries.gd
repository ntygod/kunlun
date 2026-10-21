extends "res://tests/test_chapter_six.gd"
const Flow=preload("res://tests/chapter_six_campaign_driver.gd")
func run() -> void:
 var base:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/prologue.json"))
 var c=Campaign.new(base)
 check(c.restore_persisted(JSON.parse_string(FileAccess.get_file_as_string("res://../output/cache/chapter_five_gui/manual_natural_final.json")))=="","actual5")
 check(c.enter_registered_chapter(6),"enter6")
 for i in range(200):
  if c.current_event().get("id")=="departure_confirmed":break
  if not Flow.advance(c,0,1):check(false,"advance to preview");quit(2);return
 var rt:RefCounted=c.current_chapter_runtime()
 check(c.state.coins==1400,"450 already settled once")
 check(c.items.item_ch06_father_book.owner=="char_liang_xiao" and not c.items.has("item_ch06_entrusted_coins"),"preview no transfer")
 check(c.actors.char_axue.status=="active" and c.state.optional.R03.status!="missed" and c.state.optional.L02.status!="missed","preview no irreversible closure")
 var before:Dictionary=c.export_save();var old_token:String=c.current_token()
 check(not rt.complete(old_token,{"closure_acknowledged":1}),"typed final confirmation required")
 check(Proof.equivalent(before,c.export_save()),"bad confirm atomic")
 check(rt.reconsider_departure(c.state.position),"return from bridge")
 check(c.state.coins==1400 and c.current_event().id=="ch06_departure_window","return keeps money and live window")
 check(rt.open_sidequest("R03"),"side remains available")
 for i in range(8):
  if c.current_event().id=="r03":break
  check(Flow.advance(c,0,0),"partial side setup")
 var session=rt.make_puzzle();check(session!=null,"partial craft session")
 check(rt.puzzle_input(c.current_token(),session.next_demo_action()).get("ok",false),"partial craft input")
 var partial:Dictionary=session.snapshot()
 check(rt.pause_sidequest(),"pause side")
 var saved:Dictionary=c.export_save();var restored=Campaign.new(base)
 check(restored.restore_persisted(JSON.parse_string(JSON.stringify(saved)))=="","return and partial disk-shape replay")
 c=restored;rt=c.current_chapter_runtime()
 check(rt.open_sidequest("R03"),"reenter partial side")
 check(Proof.equivalent(partial,rt.make_puzzle().snapshot()),"same unfinished inputs")
 check(rt.pause_sidequest(),"pause again")
 for i in range(20):
  if c.current_event().id=="departure_confirmed":break
  if c.current_event().id=="chapter_six_exit":
   var total:int=rt.maps[c.scene().map_id].paths.chapter_six_exit.size()
   check(c.state.path_progress.get("chapter_six_exit",0)==total,"already verified bridge route restored without walking twice")
   var route_save:Dictionary=c.export_save();var route_copy=Campaign.new(base)
   check(route_copy.restore_persisted(JSON.parse_string(JSON.stringify(route_save)))=="","reconsidered complete route survives read")
   check(route_copy.state.path_progress.get("chapter_six_exit",0)==total,"loaded route retains verified completion")
   var far_proof:Dictionary={"map_id":c.scene().map_id,"position":[80,240],"complete":true,"index":total,"total":total}
   check(not c.complete_action(c.current_token(),"chapter_six_exit",far_proof),"old route cannot permit remote endpoint E")
  check(Flow.advance(c,0,0),"change to coins and reach confirmation")
 check(c.state.choices.entrust=="ch06_entrust_coins" and c.state.coins==1400,"changed preview still no transfer")
 check(c.items.item_ch06_father_book.owner=="char_liang_xiao","old book preview left no stale ownership")
 var endpoint:Array=c.state.position.duplicate()
 c.state.position=[80,240]
 var away:Dictionary=c.export_save()
 check(not rt.close_window(c.current_token()),"cannot remotely confirm from village after old route completion")
 check(Proof.equivalent(away,c.export_save()),"remote confirmation preserves all assets")
 c.state.position=endpoint
 check(rt.close_window(c.current_token()),"final irreversible confirmation")
 check(c.state.finished and c.state.coins==0 and c.items.item_ch06_entrusted_coins.quantity==1400,"all transfer exactly once")
 check(c.state.optional.R03.status=="missed" and c.state.optional.L02.status=="missed","unfinished sides close only now")
 check(c.state.xp==10875,"partial side no XP")
 check(c.items.item_ch06_fine_strips.quantity==1 and c.items.item_ch06_fine_strips.state=="available","unfinished material not silently consumed")
 var candidate:Dictionary=c.prepare_persisted_save();check(candidate.error=="","changed preview and partial side compact "+str(candidate.error))
 if candidate.error!="":quit(1);return
 var bad_values:Array=[null,true,false,[],{},"invalid",1.5,-1,999999]
 for key in ["chapter","summary_version","choices","milestones","semantic_commits","optional_dispositions","boundary_vitals","leader_id"]:
  for value in bad_values:
   var bad:Dictionary=candidate.payload.duplicate(true);bad.archive[-1][key]=value
   var before_bad:Dictionary=c.export_save()
   check(c.restore_persisted(bad)!="","reject malformed summary "+key+str(value))
   check(Proof.equivalent(before_bad,c.export_save()),"malformed summary preserves live instance")
 for side in ["R03","L02"]:
  for value in [true,false,null,1,[],{}]:
   var bad:Dictionary=candidate.payload.duplicate(true);bad.archive[-1].optional_dispositions[side]=value
   check(c.restore_persisted(bad)!="","enum type before comparison")
 print("Chapter six boundaries: ",checks," checks, ",failures," failures")
 quit(1 if failures else 0)
