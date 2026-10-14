extends "res://tests/test_chapter_five_battle_entry.gd"
## Full current chapter with actual prior natural save; every event must replay.
func run() -> void:
 base=JSON.parse_string(FileAccess.get_file_as_string("res://data/prologue.json"))
 var c=Campaign.new(base)
 var fixture:="res://../output/cache/chapter_four_gui_v2/manual_natural_final.json"
 if not FileAccess.file_exists(fixture):print("BLOCKED natural fixture absent");quit(2);return
 check(c.restore_persisted(JSON.parse_string(FileAccess.get_file_as_string(fixture)))=="","actual chapter4 natural fixture")
 check(c.enter_registered_chapter(5),"chapter five entry")
 for index in range(150):
  if c.state.finished:break
  var token:String=c.current_token()
  print("STEP ",token)
  if c.current_event().op=="objective_battle":
   var session=c.current_chapter_runtime().make_objective_encounter()
   var driver=FiveDriver.new(check)
   if c.current_event().id=="enc_ch05_mechanism_yun_shu":driver.b02(session)
   else:driver.b03(session)
   check(c.current_chapter_runtime().complete(token,session.receipt()),"commit actual battle")
  elif c.current_event().get("kind")=="route":
   var event:Dictionary=c.current_event()
   var layout:Dictionary=c.current_chapter_runtime().maps[c.scene().map_id]
   var total:int=layout.paths[event.id].size()
   check(c.complete_action(token,event.id,{"map_id":c.scene().map_id,"position":layout.actions[event.id].position,"complete":true,"index":total,"total":total}),"route endpoint proof")
  else:
   if not advance_five(c):check(false,"advance "+token);break
  if c.current_token()==token and not c.state.finished:check(false,"stalled "+token);break
  var clone=Campaign.new(base)
  var error:String=clone.restore_persisted(JSON.parse_string(JSON.stringify(c.export_save())))
  check(error=="","real checkpoint replay "+token+" "+error)
  if not error.is_empty():break
 check(c.state.finished,"chapter five reaches end")
 if c.state.finished:
  check(c.state.coins==950,"inherited550 plus single400 copper settlement")
  check(c.state.xp==8350,"2535 exact chapter XP")
  check(c.actors[Party.HERO].xp==c.actors[Party.LIU].xp,"absent core still receives XP")
  check(c.actors.char_axue.xp==0 and c.actors.char_axue.level==23,"limited Axue excludes growth")
  var candidate:Dictionary=c.prepare_persisted_save()
  check(candidate.get("error","")=="","prepare final archive "+str(candidate.get("error","")))
  print("FINAL ",JSON.stringify(c.actors)," CANDIDATE KEYS ",candidate.keys())
 print("Chapter five integration ",checks," checks ",failures," failures")
 quit(1 if failures else 0)
