extends SceneTree
## Usage: godot --headless --path game --script res://tools/profile_bounded_saves.gd -- /absolute/legacy.json [...]
## Fixtures are local inputs; this tool never overwrites them or registers fake chapters.
const Campaign = preload("res://scripts/campaign/campaign_state.gd")
const Codec = preload("res://scripts/campaign/bounded_save_codec.gd")
func _initialize() -> void: call_deferred("run")
func median(samples: Array) -> float:
 samples.sort();return float(samples[samples.size()/2])
func run() -> void:
 var base: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/prologue.json"))
 for path in OS.get_cmdline_user_args():
  var original:=FileAccess.get_file_as_string(path)
  var parsed: Variant=JSON.parse_string(original)
  var campaign:=Campaign.new(base)
  var start:=Time.get_ticks_usec()
  var error:=campaign.restore_persisted(parsed)
  if error!="":push_error(path+": "+error);quit(1);return
  var migration_ms:=(Time.get_ticks_usec()-start)/1000.0
  var payload:=campaign.export_save()
  var old_times: Array=[];var new_times: Array=[]
  for iteration in range(5):
   var old:=Campaign.new(base);start=Time.get_ticks_usec();error=old.restore(parsed);old_times.append((Time.get_ticks_usec()-start)/1000.0)
   if error!="":push_error(error);quit(1);return
   var fresh:=Campaign.new(base);start=Time.get_ticks_usec();error=fresh.restore(JSON.parse_string(JSON.stringify(payload)));new_times.append((Time.get_ticks_usec()-start)/1000.0)
   if error!="" or Codec.compare_live(campaign,fresh)!="":push_error("v4 roundtrip failed");quit(1);return
  print(JSON.stringify({"fixture":path.get_file(),"old_bytes":original.to_utf8_buffer().size(),"v4_bytes":JSON.stringify(payload,"\t").to_utf8_buffer().size(),"migration_ms":migration_ms,"old_restore_ms":old_times,"v4_parse_restore_ms":new_times,"old_median_ms":median(old_times),"v4_median_ms":median(new_times)}))
  # Stress only the archive SHAPE with 21 repeated largest entries. No invented
  # plot, chapter registration, reward rules, or claim of 20 chapters played.
  if payload.archive.is_empty():continue
  var largest: Dictionary=payload.archive[0]
  for entry in payload.archive:
   if JSON.stringify(entry).length()>JSON.stringify(largest).length():largest=entry
  var synthetic: Array=[]
  for index in range(21):synthetic.append(largest.duplicate(true))
  var text:=JSON.stringify(synthetic,"\t")
  var stress_times: Array=[]
  for iteration in range(5):
   start=Time.get_ticks_usec()
   for repeat in range(100):
    var copy: Variant=JSON.parse_string(text)
    if not Codec.equivalent(copy,synthetic):push_error("shape roundtrip failed");quit(1);return
   stress_times.append((Time.get_ticks_usec()-start)/100000.0)
  print(JSON.stringify({"synthetic_only":"21 largest-entry copies, parse+canonical comparison, NOT gameplay validation","shape_bytes":text.to_utf8_buffer().size(),"milliseconds_per_roundtrip":stress_times}))
 quit()
