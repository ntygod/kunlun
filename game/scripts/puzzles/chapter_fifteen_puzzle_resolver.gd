class_name ChapterFifteenPuzzleResolver
extends RefCounted
## Finite playable diagrams; never mutates campaign resources or grants skills.
const VERSION:=1
const MAX_LOG:=1024
const IDS:=["pz_ch15_r06_clinic_plan"]
const SCENES:=["side_ch15_r06"]
const OBJECTIVES:=["r06_clinic_plan_verified"]
const TITLES:=["留给来人的灯 · 草庐备办"]
const CARD_FAMILIES:=[0,1,2,1,2,0,2,0,1]
const Safe=preload("res://scripts/puzzles/chapter_eight_puzzle_resolver.gd")
var puzzle_id:=""
var attempt_id:=""
var context:Dictionary={}
var state:Dictionary={}
var input_log:Array=[]
var message:=""
static func _bounded_tree(v:Variant)->bool:return Safe._bounded_tree(v)
static func _normalize(v:Variant)->Variant:return Safe._normalize(v)
static func _integer(v:Variant)->bool:return Safe._integer(v)
static func _hash(v:Variant)->String:return Safe._hash(v)
func begin(id:String,attempt:String="",trusted_context:Dictionary={}) -> bool:
 if id not in IDS or attempt.length()>256 or not _bounded_tree(trusted_context):return false
 var c:Dictionary=_normalize(trusted_context)
 if not _integer(c.get("chapter")) or c.chapter!=15 or not c.get("current_token") is String or c.current_token.is_empty() or c.get("scene_id")!=SCENES[IDS.find(id)] or not c.get("actors") is Dictionary:return false
 if c.get("r06_method") not in ["a","b"]:return false
 var active:Array=["char_hua_xiaoshuang","char_huasheng"]
 for who in active:
  var actor:Variant=c.actors.get(who)
  if not actor is Dictionary or not _integer(actor.get("hp")) or actor.hp<=0:return false
  if actor.has("id") and actor.id!=who:return false
 if c.get("assistance_status","manual") not in ["manual","assisted","unknown"]:return false
 puzzle_id=id;attempt_id=attempt if not attempt.is_empty() else id+":attempt";context=c;input_log=[];state=_fresh();message="晓霜先勘查草庐，再让幼帝与阿福亲手整理；未辨明的事留待请教。";return true
func _fresh()->Dictionary:
 return {"hint":0,"complete":false,"history_status":context.get("assistance_status","manual"),"assisted":context.get("assistance_status","manual")=="assisted","observed":[],"stage":0,"cards":{},"atlas_checked":false,"jars":[],"tools":[],"method_ready":false,"teaching":"","wrong_answers":0}
func _safe(a:Dictionary)->bool:
 var schemas:Dictionary={"observe":{"target":"s"},"file_card":{"card":"i","family":"i"},"check_atlas":{},"store_jar":{"jar":"i","seal":"s"},"put_tool":{"tool":"s","place":"s"},"check_store":{},"teach":{"rule":"s"},"finish":{},"retry":{},"hint":{},"assist_step_v1":{},"reset_after_limit":{"hint":"i","assisted":"i"}}
 if not _bounded_tree(a) or not a.get("type") is String or not schemas.has(a.type) or a.size()!=schemas[a.type].size()+1:return false
 for key in schemas[a.type]:
  if not a.has(key) or (schemas[a.type][key]=="i" and not _integer(a[key])) or (schemas[a.type][key]=="s" and not a[key] is String):return false
 return true
func apply_input(action:Dictionary)->Dictionary:
 if action.get("type")=="reset_after_limit":return {"ok":false,"message":"内部记录不是玩家命令。"}
 if not puzzle_id.is_empty() and not state.complete and action=={"type":"retry"} and input_log.size()>=MAX_LOG-1:
  var hint:int=state.hint;var assisted:int=1 if assistance_status()=="assisted" else 0
  var id:String=puzzle_id;var attempt:String=attempt_id;var c:Dictionary=context.duplicate(true)
  if not begin(id,attempt,c):return {"ok":false,"message":"入口无效。"}
  return _apply({"type":"reset_after_limit","hint":hint,"assisted":assisted})
 return _apply(action)
func _apply(raw:Dictionary)->Dictionary:
 if puzzle_id.is_empty() or not _bounded_tree(raw):return {"ok":false,"message":"无效操作，状态未改。"}
 var a:Dictionary=_normalize(raw)
 if not _safe(a) or input_log.size()>=MAX_LOG:return {"ok":false,"message":"无效操作或记录已满；重试保留协助标记。"}
 var before:Dictionary=state.duplicate(true)
 if not _operate(a):state=before;return {"ok":false,"message":message}
 input_log.append(a.duplicate(true));return {"ok":true,"message":message,"view":get_view(),"receipt":receipt(),"receipts":get_receipts()}
func _reject(text:String)->bool:message=text;return false
func _operate(a:Dictionary)->bool:
 if state.complete:return _reject("已完成，收起机关继续。")
 if a.type=="reset_after_limit":
  if not input_log.is_empty() or a.hint<0 or a.hint>3 or a.assisted not in [0,1]:return false
  state.hint=a.hint;state.assisted=state.assisted or a.assisted==1;state.history_status="assisted" if state.assisted else "unknown";return true
 if a.type=="retry":
  var old:Dictionary=state;state=_fresh();state.hint=old.hint;state.assisted=old.assisted;state.history_status=old.history_status;message="重置局部摆设，人物资源不变。";return true
 if a.type=="hint":state.hint=mini(3,state.hint+1);message=_hint();return true
 if a.type=="assist_step_v1":
  if state.hint<3:return _reject("展开三层提示后才可明确请求协助。")
  var step:Dictionary=next_demo_action()
  if step.is_empty():return false
  state.assisted=true;state.history_status="assisted";return _operate(step)
 if a.type=="observe":
  if not observations().has(a.target):return false
  if a.target not in state.observed:state.observed.append(a.target)
  message=observations()[a.target];return true
 if state.observed.size()!=observations().size():return _reject("先观察全部线索，再实际操作。")
 var accepted:=_clinic(a)
 if accepted:state.stage+=1
 return accepted
func observations()->Dictionary:
 return {"shelter":"两间土屋还能遮雨，留下图录或封好的储备，远比匆匆留一句话可靠。修门、清井、挂灯将在随后亲手完成。","well":"井边泥水混杂。先把清水、储物分开安排；有疑问须请医者，不拿不明材料冒险。这里不教授现实治病方法。","afu":"阿福认得少许字。图册以圆、三角、方三种符号分甲、乙、丙栏，九页的符号已画在左侧；储备必须盖紧有标记，教具与针匣各归其位。"}
func _clinic(a:Dictionary)->bool:
 if a.type=="file_card":
  if context.r06_method!="a" or state.method_ready or a.card<0 or a.card>8 or a.family<0 or a.family>2:return false
  state.cards[str(a.card)]=a.family;message="第%d页放进%s栏，可核对图例后调整。"%[a.card+1,["甲·圆","乙·三角","丙·方"][a.family]];return true
 if a.type=="check_atlas":
  if context.r06_method!="a" or state.method_ready:return false
  if state.cards.size()!=9:return _reject("九页图录还未全部归栏。")
  for i in range(9):
   if state.cards.get(str(i),-1)!=CARD_FAMILIES[i]:
    state.wrong_answers+=1;message="第%d页的符号与栏签不符，阿福指着图例请你再看。"%(i+1);return true
  state.atlas_checked=true;state.method_ready=true;message="九页图录顺序清楚，幼帝把图例描在墙上。还须留下遇疑求助的叮嘱。";return true
 if a.type=="store_jar":
  if context.r06_method!="b" or state.method_ready or a.jar<0 or a.jar>2 or a.seal not in ["open","closed_unmarked","closed_marked"]:return false
  if a.jar in state.jars:return _reject("这坛已盖好标明，不重复计数。")
  if a.seal!="closed_marked":state.wrong_answers+=1;message="阿福摇头：开口怕污，未标记易混，须盖紧并留下标记。";return true
  state.jars.append(a.jar);message="第%d坛已盖好标明。虚构储备不提供配方，使用须请医者。"%(a.jar+1);return true
 if a.type=="put_tool":
  if context.r06_method!="b" or state.method_ready or a.tool not in ["record","model","needle_case"] or a.place not in ["shelf","desk","closed_case"]:return false
  if a.tool in state.tools:return _reject("这件已妥当收好。")
  if a.place!={"record":"shelf","model":"desk","needle_case":"closed_case"}[a.tool]:state.wrong_answers+=1;message="图录上架、木人置案、针匣封存，不能混在储备坛中。";return true
  state.tools.append(a.tool);message="教具已归位%d/3。"%state.tools.size();return true
 if a.type=="check_store":
  if context.r06_method!="b" or state.method_ready:return false
  if state.jars.size()!=3 or state.tools.size()!=3:return _reject("三坛与三件教具都要逐项安放，不能少一项。")
  state.method_ready=true;message="花生把盖好标明的储备移入干燥处，阿福收妥教具。还有一句要紧的叮嘱。";return true
 if a.type=="teach":
  if not state.method_ready or a.rule not in ["guess","status","ask"]:return false
  if a.rule!="ask":state.wrong_answers+=1;message="晓霜轻声纠正：不可凭猜测，也不能分贵贱；不明之处应及时求助医者。";return true
  state.teaching="ask";message="阿福复述：病人不分贵贱；不明之处先求教，不能拿性命试错。";return true
 if a.type=="finish":
  if not state.method_ready or state.teaching!="ask":return _reject("备办未齐，或尚未确认阿福理解叮嘱。")
  state.complete=true;message="图录与储备交代明白。接着与花生、幼帝修整草庐，点亮檐下的灯。";return true
 return false
func assistance_status()->String:return "assisted" if state.get("assisted",false) else str(state.get("history_status","unknown"))
func next_demo_action()->Dictionary:
 if state.is_empty() or state.complete:return {}
 for target in observations():
  if target not in state.observed:return {"type":"observe","target":target}
 if not state.method_ready:
  if context.r06_method=="a":
   for i in range(9):
    if state.cards.get(str(i),-1)!=CARD_FAMILIES[i]:return {"type":"file_card","card":i,"family":CARD_FAMILIES[i]}
   return {"type":"check_atlas"}
  for i in range(3):
   if i not in state.jars:return {"type":"store_jar","jar":i,"seal":"closed_marked"}
  for tool in ["record","model","needle_case"]:
   if tool not in state.tools:return {"type":"put_tool","tool":tool,"place":{"record":"shelf","model":"desk","needle_case":"closed_case"}[tool]}
  return {"type":"check_store"}
 if state.teaching!="ask":return {"type":"teach","rule":"ask"}
 return {"type":"finish"}
func _hint()->String:
 if state.hint==0:return ""
 if state.hint==1:return "先勘查棚屋、井口与阿福。观察左侧图例或核对储物标记。"
 if state.hint==2:return "甲圆、乙三角、丙方。储备须盖紧标明；图录上架、木人置案、针匣封存。最后确认遇疑求助，不凭猜测。"
 return "下一合法操作："+command_label(next_demo_action())+"。明确协助会留标记。"
func command_label(a:Dictionary)->String:
 return {"observe":"阅读勘查线索","file_card":"按符号把图页归栏","check_atlas":"检查九页图录","store_jar":"盖紧并标明一坛","put_tool":"整理一件教具","check_store":"核对储备清单","teach":"确认遇疑求助的叮嘱","finish":"完成备办，去修整草庐"}.get(a.get("type",""),"已完成")
func get_view()->Dictionary:
 if state.is_empty():return {}
 var actions:Array=[]
 for target in observations():actions.append({"label":"勘查 · "+{"shelter":"棚屋","well":"井口","afu":"阿福"}[target],"command":{"type":"observe","target":target}})
 return {"puzzle_id":puzzle_id,"attempt_id":attempt_id,"token":context.current_token,"title":TITLES[0],"method":context.r06_method,"state":state.duplicate(true),"message":message,"hint_text":_hint(),"assistance_status":assistance_status(),"next_action":next_demo_action(),"actions":actions,"observations":observations(),"instruction":"逐项整理，再核对清单。此处是虚构图册与储物示意，不提供现实诊疗指引；人物资源不变。"}
func view()->Dictionary:return get_view()
func snapshot()->Dictionary:return {"version":VERSION,"puzzle_id":puzzle_id,"attempt_id":attempt_id,"context_hash":_hash(context),"input_log":input_log.duplicate(true),"state":state.duplicate(true)}
func restore(saved:Dictionary,trusted_context:Dictionary={}) -> bool:
 if not _bounded_tree(saved):return false
 var data:Dictionary=_normalize(saved)
 if data.size()!=6 or not _integer(data.get("version")) or data.version!=VERSION or not data.get("puzzle_id") is String or not data.get("attempt_id") is String or not data.get("input_log") is Array or not data.get("state") is Dictionary or not data.get("context_hash") is String or data.input_log.size()>MAX_LOG:return false
 var r:=ChapterFifteenPuzzleResolver.new()
 if not r.begin(data.puzzle_id,data.attempt_id,trusted_context) or data.get("context_hash")!=_hash(r.context):return false
 for command in data.input_log:
  if not command is Dictionary or not r._apply(command).ok:return false
 if r.state!=data.state:return false
 puzzle_id=r.puzzle_id;attempt_id=r.attempt_id;context=r.context;state=r.state;input_log=r.input_log;message=r.message;return true
func set_context(c:Dictionary)->bool:return _bounded_tree(c) and _normalize(c)==context
func receipt()->Dictionary:
 if state.is_empty() or not state.complete:return {}
 return {"resolver_version":VERSION,"puzzle_id":puzzle_id,"problem_id":puzzle_id,"attempt_id":attempt_id,"scene_id":context.scene_id,"objective_id":OBJECTIVES[IDS.find(puzzle_id)],"context_hash":_hash(context),"input_log":input_log.duplicate(true),"final_state":state.duplicate(true),"assistance_status":assistance_status(),"assisted":assistance_status()!="manual","manual_process_verified":assistance_status()=="manual","validation_results":{"complete_process":true,"no_xp":true}}
func proof()->Dictionary:return receipt()
func get_receipts()->Array:return [receipt()] if not receipt().is_empty() else []
static func replay_receipt(proof:Dictionary,id:String,attempt:String,trusted_context:Dictionary={}) -> bool:
 if not _bounded_tree(proof):return false
 var p:Dictionary=_normalize(proof)
 if not p.get("puzzle_id") is String or not p.get("attempt_id") is String or p.get("puzzle_id")!=id or p.get("attempt_id")!=attempt:return false
 var r:=ChapterFifteenPuzzleResolver.new()
 if not r.restore({"version":VERSION,"puzzle_id":id,"attempt_id":attempt,"context_hash":p.get("context_hash",""),"input_log":p.get("input_log",[]),"state":p.get("final_state",{})},trusted_context):return false
 return not r.receipt().is_empty() and r.receipt()==p
