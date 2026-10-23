extends "res://tests/test_chapter_twelve_minimum.gd"
## Model-driven minimum route, not a natural GUI save. Never edits a checkpoint.
func after_source(c:RefCounted)->void:
 super.after_source(c)
 if failures>0:return
 var out:String=OS.get_environment("KUNLUN_FIXTURE_DIR")
 if out.is_empty():check(false,"KUNLUN_FIXTURE_DIR must be explicit and isolated");return
 DirAccess.make_dir_recursive_absolute(out)
 var drivers={13:"thirteen",14:"fourteen",15:"fifteen"}
 for chapter in [12,13,14,15]:
  if chapter>12:
   check(c.enter_registered_chapter(chapter),"minimum registered entry "+str(chapter))
   if c.active_chapter!=chapter:return
   var flow=load("res://tests/chapter_"+drivers[chapter]+"_campaign_driver.gd")
   for step in range(400):
    if c.state.finished:break
    print("DEVELOP_SOURCE ",chapter," ",c.current_token())
    if not flow.advance(c,0,false):check(false,"minimum route "+str(chapter)+" "+c.current_token());return
  check(c.state.finished,"chapter finished "+str(chapter))
  if not c.state.finished:return
  var result:Dictionary=c.prepare_persisted_save()
  check(result.error=="","verified minimum boundary "+str(chapter)+" "+str(result.error))
  if result.error!="":return
  var clone=Campaign.new(base)
  check(clone.restore_persisted(result.payload)=="","independently restore boundary "+str(chapter))
  var path:=out+"/chapter_%02d_minimum.json"%chapter
  var f=FileAccess.open(path,FileAccess.WRITE)
  if f==null:check(false,"write boundary "+path);return
  f.store_string(JSON.stringify(result.payload));f.close()
  print("MODEL_FIXTURE ",path," xp=",c.state.xp," sha256=",FileAccess.get_sha256(path))
