extends "res://tests/test_chapter_eleven_minimum.gd"
const TwelveFlow=preload("res://tests/chapter_twelve_campaign_driver.gd")
func after_source(c:RefCounted)->void:
 super.after_source(c)
 check(c.state.finished and c.state.xp==24225 and c.state.coins==3000,"actual minimum0–11 inherited")
 var source_output:String=OS.get_environment("CH12_MINIMUM_SOURCE_OUTPUT")
 if not source_output.is_empty():
  var prepared:Dictionary=c.prepare_persisted_save()
  if prepared.error!="":check(false,"minimum11 source archive");return
  var source_file=FileAccess.open(source_output,FileAccess.WRITE);source_file.store_string(JSON.stringify(prepared.payload));source_file.close()
 var dead:Dictionary=c.actors.char_axue.duplicate(true)
 check(c.enter_registered_chapter(12),"minimum12 entry")
 for i in range(240):
  if c.state.finished:break
  print("MIN12 ",c.current_token()," ",c.current_event().id)
  if c.current_event().op=="objective_battle":
   var boundary:String=OS.get_environment("CH12_MINIMUM_BOUNDARY")
   if boundary==c.current_event().id:
    var battle:RefCounted=c.current_chapter_runtime().make_objective_encounter()
    if battle==null:check(false,"minimum canonical boundary");return
    var file=FileAccess.open(OS.get_environment("CH12_BOUNDARY_OUTPUT"),FileAccess.WRITE)
    file.store_string(JSON.stringify({"rules":c.rules,"runtime":c.combat,"cfg":battle.encounter,"party":battle.initial_party,"attempt":battle.attempt_id,"live_save":c.export_save()}));file.close()
    print("MIN12 BOUNDARY ONLY ",boundary);return
   print("MIN12_BATTLE_ENTRY ",JSON.stringify({"id":c.current_event().id,"xp":c.state.xp,"party":c.current_chapter_runtime().combat_party()}))
   if c.current_event().id=="enc_ch12_han_duel":check(c.state.xp==25970,"actual minimum first B08 gate")
   if c.current_event().id=="enc_ch12_chiyou_medicine":check(c.state.xp==29640,"actual minimum B09 gate")
  if not TwelveFlow.advance(c,0,false):check(false,"minimum12 advance "+c.current_token());return
 check(c.state.finished and c.state.xp==31565 and c.state.coins==3750,"minimum12 exact7340XP750coins")
 check(c.actors.char_axue==dead,"story dead unchanged")
 var final:Dictionary=c.prepare_persisted_save();check(final.error=="","minimum12 bounded "+str(final.error))
 if final.error!="":return
 var restored=Campaign.new(base);check(restored.restore_persisted(final.payload)=="","minimum12 restore")
 var output:String=OS.get_environment("CH12_MINIMUM_OUTPUT")
 if not output.is_empty():
  var file=FileAccess.open(output,FileAccess.WRITE);file.store_string(JSON.stringify(final.payload));file.close()
 print("CH12 FULL MINIMUM ",c.state.xp," XP / ",c.state.coins," copper")
