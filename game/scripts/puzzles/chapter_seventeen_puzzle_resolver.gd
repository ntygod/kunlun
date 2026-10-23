class_name ChapterSeventeenPuzzleResolver
extends RefCounted
## Evidence ownership is supplied by campaign receipts; UI cannot manufacture clues.
const Same=preload("res://scripts/campaign/encounter_session.gd")
const IDS=["pz_ch17_evidence","pz_ch17_roof"]
const MAX_INPUTS=512
const EVIDENCE=["howls","disguise","wounds","callus","case","zhuque"]
const LABELS={"howls":"① 东西双谷狼哨","disguise":"② 狼皮与铁爪","wounds":"③ 商队指力伤","callus":"④ 硬皮与哨蜡","case":"⑤ 剑匣指印","zhuque":"⑥ 朱雀同源伤"}
const HINTS={
 "pz_ch17_evidence":["先分清两个问题：谁是假狼，谁灭口了商队？","同时的狼哨与狼皮铁爪证明替身；指力伤、狼哨蜡和同源手法指向阿莫。","先连①②到替身；再连③④⑥到阿莫。剑匣指印⑤也可替代⑥作交叉印证，但六证都须亲自取得。"],
 "pz_ch17_roof":["按柳莺莺选定的方案分工，不要同时抢动承重结构。","先由村主稳住承重，再由梁萧校正；风怜最后补栓和保暖。","榫卯：莺莺抬梁→梁萧合榫→风怜打栓→风怜铺苇。土墙：莺莺夯墙→梁萧设撑→风怜铺苇。"]}
var puzzle_id=""
var attempt_id=""
var context:Dictionary={}
var state:Dictionary={}
var history:Array=[]
func begin(id:String,attempt:String,ctx:Dictionary)->bool:
 if id not in IDS or attempt.is_empty() or ctx.get("chapter")!=17 or ctx.get("current_token")!=attempt:return false
 if not whole(ctx.get("attempt_generation",0),0,10000):return false
 if id=="pz_ch17_evidence":
  if ctx.get("control_actor_id")!="char_liang_xiao" or not ctx.get("evidence") is Array:return false
  if ctx.evidence.size()!=6:return false
  for key in EVIDENCE:
   if key not in ctx.evidence:return false
 else:
  if ctx.get("control_actor_id")!="char_liu_yingying" or ctx.get("roof_method") not in ["r07_method_joinery","r07_method_wall"]:return false
 puzzle_id=id;attempt_id=attempt;context=ctx.duplicate(true);history=[]
 state={"complete":false,"revision":1+int(ctx.get("attempt_generation",0))*1024,"hint_level":0,"message":"先观察，再动手。","attempts":0}
 if id=="pz_ch17_evidence":state.merge({"selected":[],"links":[],"claim":"double"})
 else:state.merge({"method":ctx.roof_method,"stage":0,"work":[]})
 return true
static func whole(value:Variant,lo:int,hi:int)->bool:
 return (value is int or value is float) and is_finite(float(value)) and value==floor(value) and value>=lo and value<=hi
static func keys(value:Dictionary,wanted:Array)->bool:
 if value.size()!=wanted.size():return false
 for k in wanted:
  if not value.has(k):return false
 return true
func apply_input(value:Variant)->Dictionary:
 if not value is Dictionary or not value.get("type") is String:return {"ok":false,"message":"无效操作"}
 var action:Dictionary=value.duplicate(true)
 if action.has("revision"):
  if not whole(action.revision,1,11000000) or int(action.revision)!=int(state.revision):return {"ok":false,"message":"操作已过期"}
  action.erase("revision")
 if state.get("complete",false):return {"ok":false,"message":"本次操作已经结束"}
 if history.size()>=MAX_INPUTS:return {"ok":false,"message":"本次尝试记录已满，请重置本机关；提示保留。"}
 var before:Dictionary=state.duplicate(true)
 if not _apply(action):
  state=before
  return {"ok":false,"message":"操作不适用于当前局面"}
 if Same.equivalent(state,before):return {"ok":false,"message":"局面没有改变"}
 state.revision+=1;history.append(action)
 return {"ok":true,"accepted":true,"message":state.message}
func _apply(a:Dictionary)->bool:
 if a.type=="hint" and keys(a,["type"]):
  if state.hint_level>=3:return false
  state.hint_level+=1;state.message=HINTS[puzzle_id][state.hint_level-1];return true
 if a.type=="reset" and keys(a,["type"]):
  var level:int=state.hint_level;var revision:int=state.revision;var attempts:int=state.attempts+1
  var prior_history:Array=history.duplicate(true)
  begin(puzzle_id,attempt_id,context)
  state.hint_level=level;state.revision=revision;state.attempts=attempts;state.message="已重置本机关，提示记录保留。";history=prior_history
  return true
 return _evidence(a) if puzzle_id=="pz_ch17_evidence" else _roof(a)
func _evidence(a:Dictionary)->bool:
 if a.type=="toggle":
  if not keys(a,["type","clue"]) or not a.clue is String or a.clue not in context.evidence:return false
  if a.clue in state.selected:state.selected.erase(a.clue)
  else:state.selected.append(a.clue)
  state.message="将已选线索连向当前推论。";return true
 if a.type!="connect" or not keys(a,["type","claim"]) or a.claim!=state.claim:return false
 state.attempts+=1
 var selected:Array=state.selected.duplicate();selected.sort()
 var expected:Array=["howls","disguise"] if state.claim=="double" else ["wounds","callus","zhuque"]
 expected.sort();var alternative:Array=["wounds","callus","case"];alternative.sort()
 if selected!=expected and not (state.claim=="amo" and selected==alternative):
  state.message="这些线索尚不能相互印证。保留现场记录，重新连线。";return true
 state.links.append({"claim":state.claim,"clues":selected});state.selected=[]
 if state.claim=="double":state.claim="amo";state.message="替身成立。再查谁以指力灭口，并控制狼群。"
 else:state.complete=true;state.message="两条证据链成立：狼皮是替身，真凶是阿莫。"
 return true
func roof_steps()->Array:
 return [{"actor":"char_liu_yingying","part":"beam"},{"actor":"char_liang_xiao","part":"joint"},{"actor":"char_feng_lian","part":"wedge"},{"actor":"char_feng_lian","part":"reeds"}] if state.method=="r07_method_joinery" else [{"actor":"char_liu_yingying","part":"wall"},{"actor":"char_liang_xiao","part":"brace"},{"actor":"char_feng_lian","part":"reeds"}]
func _roof(a:Dictionary)->bool:
 if a.type!="place" or not keys(a,["type","actor","part"]):return false
 if a.actor not in ["char_liu_yingying","char_liang_xiao","char_feng_lian"] or a.part not in ["beam","joint","wedge","reeds","wall","brace"]:return false
 state.attempts+=1
 var order:=roof_steps();var wanted:Dictionary=order[int(state.stage)]
 if a.actor!=wanted.actor or a.part!=wanted.part:state.message="承重尚未稳妥，不能越过分工。材料没有扣除。";return true
 state.work.append(wanted.duplicate());state.stage+=1;state.complete=state.stage==order.size()
 state.message="屋顶与保暖层已经稳固，三人各尽其力。" if state.complete else "这一步已稳住，按分工继续。"
 return true
func snapshot()->Dictionary:
 return {"version":1,"puzzle_id":puzzle_id,"attempt_id":attempt_id,"context":context.duplicate(true),"history":history.duplicate(true),"state":state.duplicate(true)}
func restore(value:Variant,expected_context:Dictionary)->bool:
 if not value is Dictionary or not keys(value,["version","puzzle_id","attempt_id","context","history","state"]):return false
 if not whole(value.version,1,1) or not value.puzzle_id is String or not value.attempt_id is String or not value.history is Array or value.history.size()>MAX_INPUTS:return false
 if not Same.equivalent(value.context,expected_context):return false
 var fresh:=ChapterSeventeenPuzzleResolver.new()
 if not fresh.begin(value.puzzle_id,value.attempt_id,expected_context):return false
 for action in value.history:
  if not action is Dictionary or action.has("revision") or not fresh.apply_input(action).ok:return false
 if not Same.equivalent(fresh.snapshot(),value):return false
 puzzle_id=fresh.puzzle_id;attempt_id=fresh.attempt_id;context=fresh.context;history=fresh.history;state=fresh.state
 return true
func get_receipts()->Array:
 return [puzzle_id+":completed"] if state.get("complete",false) else []
func get_view()->Dictionary:
 var result:Dictionary={"puzzle_id":puzzle_id,"attempt_id":attempt_id,"revision":state.revision,"state":state.duplicate(true),"title":"双狼血案 · 六证勘查" if puzzle_id=="pz_ch17_evidence" else "小禽新屋 · 三人协作","hint":HINTS[puzzle_id][state.hint_level-1] if state.hint_level>0 else "提示分三层，不会代替你的操作。"}
 if puzzle_id=="pz_ch17_evidence":result.evidence=EVIDENCE.duplicate();result.labels=LABELS.duplicate()
 else:result.steps=roof_steps()
 return result
