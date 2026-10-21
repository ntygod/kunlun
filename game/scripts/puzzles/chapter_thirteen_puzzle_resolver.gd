class_name ChapterThirteenPuzzleResolver
extends RefCounted
## Finite playable diagrams; never mutates campaign resources or grants skills.
const VERSION:=1
const MAX_LOG:=1024
const IDS:=["pz_ch13_water_watch","pz_ch13_whale_breath","pz_ch13_decoy_ship","pz_ch13_star_navigation"]
const SCENES:=["ch13_water_council","ch13_thirteen_breaths","ch13_hidden_ship","ch13_star_navigation"]
const OBJECTIVES:=["water_watch_verified","whale_breath_verified","decoy_ship_verified","star_navigation_verified"]
const TITLES:=["孤舟分水 · 三夜守望","十三段鲸息 · 随浪吐纳","明伪暗真 · 四日造船","昼晷夜星 · 校准归航"]
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
 if not _integer(c.get("chapter")) or c.chapter!=13 or not c.get("current_token") is String or c.current_token.is_empty() or c.get("scene_id")!=SCENES[IDS.find(id)] or not c.get("actors") is Dictionary:return false
 var active:Array=["char_liu_yingying","char_hua_xiaoshuang","char_huasheng"] if id==IDS[0] else ["char_liang_xiao"]
 for who in active:
  var actor:Variant=c.actors.get(who)
  if not actor is Dictionary or not _integer(actor.get("hp")) or actor.hp<=0:return false
  if actor.has("id") and actor.id!=who:return false
 if c.get("water_method","a") not in ["a","b"] or c.get("assistance_status","manual") not in ["manual","assisted","unknown"]:return false
 puzzle_id=id;attempt_id=attempt if not attempt.is_empty() else id+":attempt";context=c;input_log=[];state=_fresh();message="先看图与观察说明，再调整；暂停期间不自动推进。";return true
func _fresh()->Dictionary:
 return {"hint":0,"complete":false,"history_status":context.get("assistance_status","manual"),"assisted":context.get("assistance_status","manual")=="assisted","observed":[],"stage":0,"water":2,"served":[],"night":0,"watch":-1,"segment":0,"phase":0,"breaths":[],"day":0,"timber_fake":0,"timber_real":10,"jobs":{},"tide":0,"wheel_front":0,"wheel_rear":0,"bulkheads":[],"pin_removed":false,"workdays":[],"shadow_morning":0,"shadow_evening":0,"north":2,"star":0,"calibrated":false,"heading":2}
func _safe(a:Dictionary)->bool:
 var schemas:Dictionary={"observe":{"target":"s"},"serve":{"target":"s"},"watch":{"post":"i"},"night":{},"breath":{"length":"i"},"timber":{"fake":"i"},"assign":{"actor":"s","job":"s"},"tide":{"phase":"i"},"wheel":{"front":"i","rear":"i"},"bulkhead":{"slot":"i"},"pin":{},"workday":{},"shadow":{"morning":"i","evening":"i"},"north":{"bearing":"i"},"star":{"fingers":"i"},"calibrate":{},"heading":{"bearing":"i"},"sail":{},"retry":{},"hint":{},"assist_step_v1":{},"reset_after_limit":{"hint":"i","assisted":"i"}}
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
 var accepted:=false
 match puzzle_id:
  IDS[0]:accepted=_water(a)
  IDS[1]:accepted=_breath(a)
  IDS[2]:accepted=_ship(a)
  IDS[3]:accepted=_navigation(a)
 if accepted:state.stage+=1
 return accepted
func observations()->Dictionary:
 match puzzle_id:
  IDS[0]:return {"water":"淡水只余两筒。"+("先分幼帝与伤者哈里斯，二女以雨水润唇。" if context.get("water_method","a")=="a" else "先分撑船花生与体弱晓霜；花生会把自己的水让给孩子。"),"watch":"三夜依次守前舱、后舱、中舱：看住逼近者、护住幼帝、检查断桅。夜晚不会在菜单或失焦时自动流逝。"}
  IDS[1]:return {"song":"鲸歌十三段，吸息长度每段按1、2、3循环；停1拍，吐息比吸息多1拍。这里只是虚构武学图谱，不是真实呼吸指导。","wave":"跟随图上的浪峰：先吸、再停、后吐。一段三步齐全才计入；错误不会伤人，也不会跳过下一段。"}
  IDS[2]:return {"timber":"共10份木材：3份朽木给明滩假船，7份铁力木留暗谷；材料只能分配一次，不会凭空增加。","jobs":"柳莺莺在明滩敲空木；梁萧设计机括；花生转水轮；晓霜调脂封舱。四人各有职事。","tide":"每个工作日都要等待潮声最盛的第2档再开工，掩护暗谷施工。第1日立架、第2日调轮2:1、第3日依0→4封五舱并抽假船暗销、第4日检验登船。"}
  _:return {"sun":"昼测晷影：晨影3格向西、夕影3格向东；两影等长，东西轴确定，正北在0号刻线。","star":"夜举牵星板：北极星对齐4指高度，先完成指北校准。","course":"惠州归航取北向0，昼夜证据都齐才可扬帆。此为剧情简化图，非现实航海指引。"}
func _water(a:Dictionary)->bool:
 if a.type=="serve":
  var expected:Array=["child","harris"] if context.get("water_method","a")=="a" else ["huasheng","xiaoshuang"]
  if a.target not in expected:return _reject("这次商议的分水对象不符，水没有扣除。")
  if a.target in state.served or state.water<=0:return _reject("已分过或水已用尽，不能重复取水。")
  state.served.append(a.target);state.water-=1;message="已分一筒；余%d筒。"%state.water;return true
 if state.water!=0:return _reject("先按商议分完两筒淡水。")
 if a.type=="watch":
  if a.post not in [0,1,2]:return false
  state.watch=a.post;message="已选守望位置，确认后才推进这一夜。";return true
 if a.type=="night":
  if state.watch!=[0,2,1][state.night]:return _reject("守望位置不合本夜险情：第一夜前舱、第二夜后舱、第三夜中舱。")
  state.night+=1;state.watch=-1;state.complete=state.night==3;message="守过%d/3夜，幼帝与同伴安全。"%state.night;return true
 return false
func _breath(a:Dictionary)->bool:
 if a.type!="breath" or a.length<1 or a.length>4:return false
 var inhale:int=1+state.segment%3
 var expected:Array=[inhale,1,inhale+1]
 if a.length!=expected[state.phase]:return _reject("这一拍未合鲸歌，保留已完成段落；请看浪形与吸停吐图。")
 state.breaths.append(a.length);state.phase+=1
 if state.phase==3:state.phase=0;state.segment+=1
 state.complete=state.segment==13;message="已合%d/13段鲸歌。"%state.segment;return true
func _ship(a:Dictionary)->bool:
 if a.type=="assign":
  if a.actor not in ["liang","liu","xiaoshuang","huasheng"] or a.job not in ["design","noise","seal","wheel"]:return false
  state.jobs[a.actor]=a.job;message="已调整职责；开工前检查是否各司其职。";return true
 if a.type=="timber":
  if state.day!=0 or a.fake<0 or a.fake>10:return _reject("立架后木料已经使用，不能回收重分。")
  state.timber_fake=a.fake;state.timber_real=10-a.fake;return true
 if a.type=="tide":
  if a.phase not in [0,1,2]:return false
  state.tide=a.phase;return true
 if a.type=="wheel":
  if state.day!=1 or a.front<0 or a.front>3 or a.rear<0 or a.rear>3:return false
  state.wheel_front=a.front;state.wheel_rear=a.rear;return true
 if a.type=="bulkhead":
  if state.day!=2 or a.slot<0 or a.slot>4:return false
  if a.slot!=state.bulkheads.size():return _reject("水密隔舱须从船首0号依次封到船尾4号。")
  state.bulkheads.append(a.slot);return true
 if a.type=="pin":
  if state.day!=2 or state.bulkheads.size()!=5 or state.pin_removed:return _reject("真船五舱封好后才能抽去伪船暗销。")
  state.pin_removed=true;return true
 if a.type!="workday":return false
 if state.jobs!={"liang":"design","liu":"noise","xiaoshuang":"seal","huasheng":"wheel"}:return _reject("四人职责不齐：梁设计、柳造声、霜封舱、生转轮。")
 if state.timber_fake!=3 or state.timber_real!=7:return _reject("木料未按三成伪船、七成真船分配。")
 if state.tide!=2:return _reject("暗谷声响易露，等潮声第2档掩护再开工。")
 if state.day>=1 and (state.wheel_front!=2 or state.wheel_rear!=1):return _reject("轮轴仍未配成2:1，先校轮再合架。")
 if state.day>=2 and (state.bulkheads.size()!=5 or not state.pin_removed):return _reject("五舱或假船暗销尚未完成。")
 state.workdays.append(state.day+1);state.day+=1;state.tide=0;state.complete=state.day==4;message="第%d工作日已完，材料与工序写入图板。"%state.day;return true
func _navigation(a:Dictionary)->bool:
 if a.type=="shadow":
  if a.morning<0 or a.morning>5 or a.evening<0 or a.evening>5 or state.calibrated:return false
  state.shadow_morning=a.morning;state.shadow_evening=a.evening;return true
 if a.type=="north":
  if a.bearing<0 or a.bearing>7 or state.calibrated:return false
  state.north=a.bearing;return true
 if a.type=="star":
  if a.fingers<0 or a.fingers>5 or state.calibrated:return false
  state.star=a.fingers;return true
 if a.type=="calibrate":
  if state.shadow_morning!=3 or state.shadow_evening!=3 or state.north!=0 or state.star!=4:return _reject("昼影3/3、北线0、牵星4指同时吻合才可校准。")
  state.calibrated=true;return true
 if a.type=="heading":
  if a.bearing<0 or a.bearing>7:return false
  state.heading=a.bearing;return true
 if a.type=="sail":
  if not state.calibrated or state.heading!=0:return _reject("先校准昼晷夜星，再取北向0返航。")
  state.complete=true;message="昼夜互校，北向归航。";return true
 return false
func assistance_status()->String:return "assisted" if state.get("assisted",false) else str(state.get("history_status","unknown"))
func next_demo_action()->Dictionary:
 if state.is_empty() or state.complete:return {}
 for target in observations():
  if target not in state.observed:return {"type":"observe","target":target}
 match puzzle_id:
  IDS[0]:
   for target in (["child","harris"] if context.get("water_method","a")=="a" else ["huasheng","xiaoshuang"]):
    if target not in state.served:return {"type":"serve","target":target}
   var post:int=[0,2,1][state.night]
   return {"type":"watch","post":post} if state.watch!=post else {"type":"night"}
  IDS[1]:return {"type":"breath","length":[1+state.segment%3,1,2+state.segment%3][state.phase]}
  IDS[2]:
   for actor in ["liang","liu","xiaoshuang","huasheng"]:
    var job:String={"liang":"design","liu":"noise","xiaoshuang":"seal","huasheng":"wheel"}[actor]
    if state.jobs.get(actor)!=job:return {"type":"assign","actor":actor,"job":job}
   if state.timber_fake!=3:return {"type":"timber","fake":3}
   if state.day==1 and (state.wheel_front!=2 or state.wheel_rear!=1):return {"type":"wheel","front":2,"rear":1}
   if state.day==2:
    if state.bulkheads.size()<5:return {"type":"bulkhead","slot":state.bulkheads.size()}
    if not state.pin_removed:return {"type":"pin"}
   if state.tide!=2:return {"type":"tide","phase":2}
   return {"type":"workday"}
  IDS[3]:
   if state.shadow_morning!=3 or state.shadow_evening!=3:return {"type":"shadow","morning":3,"evening":3}
   if state.north!=0:return {"type":"north","bearing":0}
   if state.star!=4:return {"type":"star","fingers":4}
   if not state.calibrated:return {"type":"calibrate"}
   if state.heading!=0:return {"type":"heading","bearing":0}
   return {"type":"sail"}
 return {}
func _hint()->String:
 if state.hint==0:return ""
 if state.hint==1:return "图示给出物资、浪形或刻度；先读每个观察点。"
 if state.hint==2:return ["两筒按商议分完；守前、后、中三处三夜。","每段吸1/2/3循环、停1、吐比吸多1；共十三段。","伪船3真船7；梁设计柳造声霜封舱生转轮；潮声2，轮2:1，五舱0至4。","晨夕影3/3，北0，星4；校准后取北航向0。"][IDS.find(puzzle_id)]
 return "下一合法操作："+command_label(next_demo_action())+"。明确协助会留标记。"
func command_label(a:Dictionary)->String:
 match a.get("type",""):
  "observe":return "观察对应线索"
  "serve":return "分水给"+{"child":"幼帝","harris":"哈里斯","huasheng":"花生","xiaoshuang":"晓霜"}.get(a.target,"")
  "watch":return "守望"+["前舱","中舱","后舱"][a.post]
  "night":return "确认本夜守望"
  "breath":return "按%d拍完成当前吸停吐步骤"%a.length
  "assign":return "按分工线索安排一人职责"
  "timber":return "伪船分3份，真船留7份"
  "wheel":return "轮轴前2后1"
  "bulkhead":return "封第%d号水密舱"%a.slot
  "pin":return "抽去伪船暗销"
  "tide":return "等潮声第2档"
  "workday":return "完成本日工作"
  "shadow":return "晷影晨3夕3"
  "north":return "指北刻线0"
  "star":return "牵星4指"
  "calibrate":return "昼夜互校"
  "heading":return "归航刻线0"
  "sail":return "确认扬帆"
 return "已完成"
func get_view()->Dictionary:
 if state.is_empty():return {}
 var actions:Array=[]
 for target in observations():actions.append({"label":"观察 · "+{"water":"淡水","watch":"守夜","song":"鲸歌","wave":"浪形","timber":"木料","jobs":"分工","tide":"潮声","sun":"晷影","star":"牵星","course":"归航"}[target],"command":{"type":"observe","target":target}})
 return {"puzzle_id":puzzle_id,"attempt_id":attempt_id,"token":context.current_token,"title":TITLES[IDS.find(puzzle_id)],"state":state.duplicate(true),"message":message,"hint_text":_hint(),"assistance_status":assistance_status(),"next_action":next_demo_action(),"actions":actions,"observations":observations(),"instruction":"调整图中数值与位置，再确认实际工序；不会自动扣时或改变角色资源。"}
func view()->Dictionary:return get_view()
func snapshot()->Dictionary:return {"version":VERSION,"puzzle_id":puzzle_id,"attempt_id":attempt_id,"context_hash":_hash(context),"input_log":input_log.duplicate(true),"state":state.duplicate(true)}
func restore(saved:Dictionary,trusted_context:Dictionary={}) -> bool:
 if not _bounded_tree(saved):return false
 var data:Dictionary=_normalize(saved)
 if data.size()!=6 or not _integer(data.get("version")) or data.version!=VERSION or not data.get("puzzle_id") is String or not data.get("attempt_id") is String or not data.get("input_log") is Array or not data.get("state") is Dictionary or not data.get("context_hash") is String or data.input_log.size()>MAX_LOG:return false
 var r:=ChapterThirteenPuzzleResolver.new()
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
 var r:=ChapterThirteenPuzzleResolver.new()
 if not r.restore({"version":VERSION,"puzzle_id":id,"attempt_id":attempt,"context_hash":p.get("context_hash",""),"input_log":p.get("input_log",[]),"state":p.get("final_state",{})},trusted_context):return false
 return not r.receipt().is_empty() and r.receipt()==p
