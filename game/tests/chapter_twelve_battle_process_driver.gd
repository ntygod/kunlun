extends SceneTree
## Independent-process battle saves from an explicit, legally archived chapter11 source.
## Automated commands are not natural playthrough, wallclock or graphical acceptance.
const Campaign=preload("res://scripts/campaign/campaign_state.gd")
const Flow=preload("res://tests/chapter_twelve_campaign_driver.gd")
const Battle=preload("res://tests/chapter_twelve_encounter_driver.gd")
const Same=preload("res://scripts/campaign/encounter_session.gd")
const IDS:=["enc_ch12_han_duel","enc_ch12_lei_duel","enc_ch12_chu_duel","enc_ch12_chiyou_medicine"]
const DIRECTORY="user://chapter_twelve_battle_process"
const MANIFEST=DIRECTORY+"/manifest.json"
var checks:=0
var failures:=0
func check(ok:bool,label:String)->bool:
 checks+=1
 if not ok:failures+=1;push_error(label)
 return ok
func _initialize()->void:call_deferred("run")
func fresh()->RefCounted:return Campaign.new(JSON.parse_string(FileAccess.get_file_as_string("res://data/prologue.json")))
func write_file(path:String,raw:String)->bool:
 var file=FileAccess.open(path,FileAccess.WRITE)
 if not check(file!=null,"open output "+path):return false
 file.store_string(raw);file.close();return true
func write_cases()->void:
 var source:String=OS.get_environment("CH12_SOURCE")
 if not check(not source.is_empty() and FileAccess.file_exists(source),"explicit CH12_SOURCE exists"):return
 var raw:String=FileAccess.get_file_as_string(source)
 var original_hash:String=raw.sha256_text()
 var c:=fresh();var error:String=c.restore_persisted(JSON.parse_string(raw))
 if not check(error=="" and c.active_chapter==11 and c.state.finished,"formal chapter11 terminal: "+error):return
 if not check(c.enter_registered_chapter(12),"legal chapter12 entry"):return
 if not check(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIRECTORY))==OK,"dedicated user directory"):return
 if not write_file(MANIFEST,JSON.stringify({"incomplete":true,"writer_pid":OS.get_process_id()})):return
 var cases:Array=[]
 for step in range(240):
  if c.state.finished or cases.size()==IDS.size():break
  var e:Dictionary=c.current_event();var token:String=c.current_token()
  if e.op=="objective_battle":
   if not check(cases.size()<IDS.size() and e.id==IDS[cases.size()],"ordered genuine battle "+e.id):return
   var rt:RefCounted=c.current_chapter_runtime();var session:RefCounted=rt.make_objective_encounter()
   if not check(session!=null,"actual encounter "+e.id):return
   var actor:String=session.get_view().world_state.control_actor_id
   if not check(session.set_command(actor,"self_guard",actor)=="","one legal pending guard "+e.id):return
   if not check(rt.save_objective_checkpoint(session),"store real pending checkpoint "+e.id):return
   var snapshot:Dictionary=session.snapshot()
   var prepared:Dictionary=c.prepare_persisted_save()
   if not check(prepared.error=="","prepare persisted battle "+e.id+" "+str(prepared.error)):return
   var payload:String=JSON.stringify(prepared.payload)
   var filename:String=e.id+".json"
   if not write_file(DIRECTORY+"/"+filename,payload):return
   cases.append({"id":e.id,"filename":filename,"sha256":payload.sha256_text(),"bytes":payload.to_utf8_buffer().size(),"token":token,"scene_id":c.scene().id,"position":c.state.position.duplicate(),"snapshot":snapshot,"guard_actor":actor})
   print("CH12 BATTLE PROCESS CAPTURE ",e.id," ",payload.sha256_text()," ",token)
  if not check(Flow.advance(c,0,false),"legal chapter12 flow "+token):return
 if not check(cases.size()==4,"all four actual battle checkpoints"):return
 if not check(FileAccess.get_file_as_string(source).sha256_text()==original_hash,"source unchanged"):return
 var manifest:Dictionary={"version":1,"incomplete":false,"writer_pid":OS.get_process_id(),"source":source,"source_sha256":original_hash,"provenance":"actual automated chapter12 commands from explicit formal chapter11 terminal; not natural GUI evidence","cases":cases}
 write_file(MANIFEST,JSON.stringify(manifest))
func read_cases()->void:
 if not check(FileAccess.file_exists(MANIFEST),"writer manifest exists"):return
 var manifest:Variant=JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
 if not check(manifest is Dictionary and manifest.get("version")==1 and not manifest.get("incomplete",true),"complete manifest"):return
 if not check(int(manifest.writer_pid)!=OS.get_process_id(),"distinct reader process"):return
 if not check(manifest.get("cases") is Array and manifest.cases.size()==4,"four saved checkpoints"):return
 for index in range(IDS.size()):
  var record:Dictionary=manifest.cases[index]
  if not check(record.id==IDS[index] and record.filename==IDS[index]+".json","known case path"):return
  var raw:String=FileAccess.get_file_as_string(DIRECTORY+"/"+record.filename)
  if not check(raw.sha256_text()==record.sha256 and raw.to_utf8_buffer().size()==int(record.bytes),"saved bytes intact "+record.id):return
  var c:=fresh();var error:String=c.restore_persisted(JSON.parse_string(raw))
  if not check(error=="","new process restore "+record.id+" "+error):return
  if not check(c.active_chapter==12 and c.current_token()==record.token and c.scene().id==record.scene_id and Same.equivalent(c.state.position,record.position),"exact location/token "+record.id):return
  var rt:RefCounted=c.current_chapter_runtime();var session:RefCounted=rt.make_objective_encounter()
  if not check(session!=null,"restored live encounter "+record.id):return
  if not check(Same.equivalent(session.snapshot(),record.snapshot),"exact pending session "+record.id):return
  if not check(Battle.run(session),"legal resumed victory "+record.id):return
  if not check(rt.save_objective_checkpoint(session),"save resolved checkpoint "+record.id):return
  if not check(rt.accept_objective(record.token,session.receipt()),"accept actual battle proof "+record.id):return
  if not check(c.current_token()!=record.token,"battle advances exactly once "+record.id):return
  if not check(not rt.accept_objective(record.token,session.receipt()),"duplicate proof rejected "+record.id):return
  var prepared:Dictionary=c.prepare_persisted_save()
  if not check(prepared.error=="","post-victory persisted progression "+record.id+" "+str(prepared.error)):return
  print("CH12 BATTLE PROCESS RESUMED ",record.id," -> ",c.current_token())
func run()->void:
 var args:=OS.get_cmdline_user_args()
 if args.size()!=1 or args[0] not in ["write","read"]:push_error("Use -- write or -- read in separate Godot processes");quit(1);return
 if args[0]=="write":write_cases()
 else:read_cases()
 print("CH12 BATTLE PROCESS %s: %d checks, %d failures; PID %d"%[args[0],checks,failures,OS.get_process_id()]);quit(1 if failures else 0)
