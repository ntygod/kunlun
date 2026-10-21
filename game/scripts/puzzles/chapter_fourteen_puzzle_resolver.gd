class_name ChapterFourteenPuzzleResolver
extends RefCounted
## Finite playable diagrams; never mutates campaign resources or grants skills.
const VERSION:=1
const MAX_LOG:=1024
const IDS:=["pz_ch14_calendar","pz_ch14_buddhist_debate"]
const SCENES:=["ch14_calendar","ch14_dharma"]
const OBJECTIVES:=["calendar_verified","buddhist_debate_verified"]
const TITLES:=["景符定影 · 授时校历","水汽莲华 · 一归何处"]
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
 if not _integer(c.get("chapter")) or c.chapter!=14 or not c.get("current_token") is String or c.current_token.is_empty() or c.get("scene_id")!=SCENES[IDS.find(id)] or not c.get("actors") is Dictionary:return false
 var active:Array=["char_liang_xiao"]
 for who in active:
  var actor:Variant=c.actors.get(who)
  if not actor is Dictionary or not _integer(actor.get("hp")) or actor.hp<=0:return false
  if actor.has("id") and actor.id!=who:return false
 if c.get("assistance_status","manual") not in ["manual","assisted","unknown"]:return false
 puzzle_id=id;attempt_id=attempt if not attempt.is_empty() else id+":attempt";context=c;input_log=[];state=_fresh();message="先看图与观察说明，再调整；暂停期间不自动推进。";return true
func _fresh()->Dictionary:
 return {"hint":0,"complete":false,"history_status":context.get("assistance_status","manual"),"assisted":context.get("assistance_status","manual")=="assisted","observed":[],"stage":0,"position":1400,"beam":3,"locked":false,"groups":[],"third_difference":0,"interpolated":false,"days":365,"fraction":0,"debate_stage":0,"wrong_answers":0,"answers":[]}
func _safe(a:Dictionary)->bool:
 var schemas:Dictionary={"observe":{"target":"s"},"aim":{"position":"i","beam":"i"},"lock":{},"station_group":{"group":"i"},"difference":{"third":"i"},"interpolate":{},"year":{"days":"i","fraction":"i"},"finalize":{},"answer":{"id":"s"},"retry":{},"hint":{},"assist_step_v1":{},"reset_after_limit":{"hint":"i","assisted":"i"}}
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
 var accepted:=_calendar(a) if puzzle_id==IDS[0] else _debate(a)
 if accepted:state.stage+=1
 return accepted
func observations()->Dictionary:
 if puzzle_id==IDS[0]:
  return {"pinhole":"四十尺高表边影模糊。移动景符到1462寸，再使横梁黑线从亮斑中心穿过（偏移0），才可锁定。","stations":"全国二十七所资料分三束，每束九所；须逐束登记。这里用整数差数示意招差术，不冒充历史原始观测。","differences":"示意相邻量为-1、0、1、8，一差为1、1、7，二差为0、6，三差为6。先校差数，再录入郭先生给出的岁实365.2425日。"}
 return {"lotus":"国师以水汽凝莲，问：万法归一，何苦逆天？力量能散一时水汽，却答不了生命为何受苦。","beads":"九如的佛珠微温：以退为进，反问其本源。先问一归何处，再问归一是否容得苍生。","child":"辩难只为救人，不为羞辱对手。幼帝待在柱边，最终须以佛礼请求放还孩子。"}
func _calendar(a:Dictionary)->bool:
 if a.type=="aim":
  if state.locked or a.position<1400 or a.position>1500 or a.beam<0 or a.beam>6:return _reject("读数已锁定或超出图示刻度。")
  state.position=a.position;state.beam=a.beam;message="景符%d寸，亮斑偏移%d格。"%[state.position,state.beam-3];return true
 if a.type=="lock":
  if state.locked:return _reject("此读数已锁定。")
  if state.position!=1462 or state.beam!=3:return _reject("亮斑尚未被横梁黑线平分；景符取1462寸，偏移取0。")
  state.locked=true;message="清晰读数锁定：1462寸。接着核三束测影简。";return true
 if not state.locked:return _reject("先移动景符并锁定清晰读数。")
 if a.type=="station_group":
  if a.group not in [0,1,2] or a.group in state.groups:return _reject("这一束已记下，不能重复充作新测所。")
  state.groups.append(a.group);message="已登记%d/27所测影资料。"%(state.groups.size()*9);return true
 if state.groups.size()!=3:return _reject("先核齐三束、二十七所资料。")
 if a.type=="difference":
  if state.interpolated or a.third<0 or a.third>9:return false
  state.third_difference=a.third;message="三差已设为%d，需确认校勘。"%a.third;return true
 if a.type=="interpolate":
  if state.interpolated:return _reject("差数已校勘。")
  if state.third_difference!=6:return _reject("逐层相减：一差1/1/7，二差0/6，因此三差6。")
  state.interpolated=true;message="差数示意校勘完成。请录入岁实整数与万分位。";return true
 if not state.interpolated:return _reject("先校勘差数，不能直接定稿。")
 if a.type=="year":
  if a.days<364 or a.days>366 or a.fraction<0 or a.fraction>9999:return false
  state.days=a.days;state.fraction=a.fraction;message="岁实候选：%d.%04d日。"%[a.days,a.fraction];return true
 if a.type=="finalize":
  if state.days!=365 or state.fraction!=2425:return _reject("岁实尚未合郭先生给出的365.2425日，重新核读再定稿。")
  state.complete=true;message="景符读数、二十七所与差数已核，《授时历》定稿。";return true
 return false
func _debate(a:Dictionary)->bool:
 if a.type!="answer" or a.id not in ["force","unity","where","compassion","release"]:return false
 var expected:Array=["where","compassion","release"]
 if a.id!=expected[state.debate_stage]:
  state.wrong_answers+=1;message="佛珠微温："+["莫以力压人，反问归一的去处。","若归一只剩白骨，苍生何辜？","收起争胜之心，以佛礼迎回孩子。"][state.debate_stage];return true
 state.answers.append(a.id);state.debate_stage+=1;state.complete=state.debate_stage==3
 message=["一归何处？国师水汽所凝金莲微微一晃。","若归一的代价是无辜生命，何以称慈悲？国师默然。","国师合十，依约释放幼帝；此辩不伤一人。"][state.debate_stage-1];return true
func assistance_status()->String:return "assisted" if state.get("assisted",false) else str(state.get("history_status","unknown"))
func next_demo_action()->Dictionary:
 if state.is_empty() or state.complete:return {}
 for target in observations():
  if target not in state.observed:return {"type":"observe","target":target}
 if puzzle_id==IDS[1]:return {"type":"answer","id":["where","compassion","release"][state.debate_stage]}
 if state.position!=1462 or state.beam!=3:return {"type":"aim","position":1462,"beam":3}
 if not state.locked:return {"type":"lock"}
 for group in range(3):
  if group not in state.groups:return {"type":"station_group","group":group}
 if state.third_difference!=6:return {"type":"difference","third":6}
 if not state.interpolated:return {"type":"interpolate"}
 if state.days!=365 or state.fraction!=2425:return {"type":"year","days":365,"fraction":2425}
 return {"type":"finalize"}
func _hint()->String:
 if state.hint==0:return ""
 if state.hint==1:return "先读观察点。"+("景符亮斑应被横梁黑线平分。" if puzzle_id==IDS[0] else "九如的佛珠提醒：以退为进。")
 if state.hint==2:return "景符1462寸、偏移0；核三束资料；一差1/1/7，二差0/6，三差6；岁实365.2425。" if puzzle_id==IDS[0] else "反问一归何处，关照苍生，再请放还幼帝。"
 return "下一合法操作："+command_label(next_demo_action())+"。明确协助会留标记。"
func command_label(a:Dictionary)->String:
 return {"observe":"阅读观察线索","aim":"景符1462寸、偏移0","lock":"锁定清晰读数","station_group":"登记一束九所资料","difference":"设三差6","interpolate":"确认差数校勘","year":"录入365日2425万分位","finalize":"确认历书定稿","answer":"依序反问本源、关照苍生、请还幼帝"}.get(a.get("type",""),"已完成")
func get_view()->Dictionary:
 if state.is_empty():return {}
 var actions:Array=[]
 for target in observations():actions.append({"label":"观察 · "+{"pinhole":"景符","stations":"二十七所","differences":"差数示意","lotus":"水汽金莲","beads":"九如佛珠","child":"幼帝"}[target],"command":{"type":"observe","target":target}})
 return {"puzzle_id":puzzle_id,"attempt_id":attempt_id,"token":context.current_token,"title":TITLES[IDS.find(puzzle_id)],"state":state.duplicate(true),"message":message,"hint_text":_hint(),"assistance_status":assistance_status(),"next_action":next_demo_action(),"actions":actions,"observations":observations(),"instruction":"观察、调整再确认。图示为剧情有限模型，非历史实测；不自动扣时或改变角色资源。"}
func view()->Dictionary:return get_view()
func snapshot()->Dictionary:return {"version":VERSION,"puzzle_id":puzzle_id,"attempt_id":attempt_id,"context_hash":_hash(context),"input_log":input_log.duplicate(true),"state":state.duplicate(true)}
func restore(saved:Dictionary,trusted_context:Dictionary={}) -> bool:
 if not _bounded_tree(saved):return false
 var data:Dictionary=_normalize(saved)
 if data.size()!=6 or not _integer(data.get("version")) or data.version!=VERSION or not data.get("puzzle_id") is String or not data.get("attempt_id") is String or not data.get("input_log") is Array or not data.get("state") is Dictionary or not data.get("context_hash") is String or data.input_log.size()>MAX_LOG:return false
 var r:=ChapterFourteenPuzzleResolver.new()
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
 var r:=ChapterFourteenPuzzleResolver.new()
 if not r.restore({"version":VERSION,"puzzle_id":id,"attempt_id":attempt,"context_hash":p.get("context_hash",""),"input_log":p.get("input_log",[]),"state":p.get("final_state",{})},trusted_context):return false
 return not r.receipt().is_empty() and r.receipt()==p
