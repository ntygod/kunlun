extends SceneTree
## Produces a command-generated chapter11 terminal, never a natural GUI save.
const Campaign=preload("res://scripts/campaign/campaign_state.gd")
const Flow=preload("res://tests/chapter_eleven_campaign_driver.gd")
func _initialize()->void:call_deferred("run")
func run()->void:
 var source:String=OS.get_environment("CH11_SOURCE")
 var destination:String=OS.get_environment("CH12_SOURCE_OUTPUT")
 if source.is_empty() or destination.is_empty():push_error("CH11_SOURCE and CH12_SOURCE_OUTPUT required");quit(1);return
 var raw:String=FileAccess.get_file_as_string(source)
 var c=Campaign.new(JSON.parse_string(FileAccess.get_file_as_string("res://data/prologue.json")))
 var error:String=c.restore_persisted(JSON.parse_string(raw))
 if error!="" or c.active_chapter!=10 or not c.state.finished:push_error("Invalid formal chapter10 source: "+error);quit(1);return
 if not c.enter_registered_chapter(11):push_error("Chapter11 entry rejected");quit(1);return
 var side:bool=OS.get_environment("CH12_SOURCE_R04") in ["a","b"]
 var branch:int=1 if OS.get_environment("CH12_SOURCE_R04")=="b" else 0
 for i in range(180):
  if c.state.finished:break
  if not Flow.advance(c,branch,side):push_error("Actual chapter11 command failed: "+c.current_token());quit(1);return
 if not c.state.finished:push_error("Chapter11 command budget exhausted");quit(1);return
 var prepared:Dictionary=c.prepare_persisted_save()
 if prepared.error!="":push_error(prepared.error);quit(1);return
 var restored=Campaign.new(JSON.parse_string(FileAccess.get_file_as_string("res://data/prologue.json")))
 error=restored.restore_persisted(prepared.payload)
 if error!="":push_error("Terminal restoration failed: "+error);quit(1);return
 var output:String=JSON.stringify(prepared.payload)
 var file=FileAccess.open(destination,FileAccess.WRITE)
 if file==null:push_error("Cannot write explicit output: "+destination);quit(1);return
 file.store_string(output);file.close()
 var manifest:Dictionary={"provenance":"automated legal chapter10-to-11 commands; not natural GUI play","input":source,"input_sha256":raw.sha256_text(),"output":destination,"output_sha256":output.sha256_text(),"r04":"b" if branch==1 else ("a" if side else "none"),"terminal_xp":c.state.xp,"terminal_coins":c.state.coins}
 var report=FileAccess.open(destination+".manifest.json",FileAccess.WRITE)
 if report==null:push_error("Cannot write provenance manifest");quit(1);return
 report.store_string(JSON.stringify(manifest,"  "));report.close();print(JSON.stringify(manifest));quit(0)
