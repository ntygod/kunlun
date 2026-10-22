class_name ChapterSixteenPuzzleResolver
extends RefCounted
## Replayable PZ-07 and the interactive study montage; never accepts a success flag.
const Same=preload("res://scripts/campaign/encounter_session.gd")
const IDS=["pz_ch16_river","pz_ch16_scale","pz_ch16_study"]
const MAX_INPUTS=512
const HINTS={
 "pz_ch16_river":["硬堵必决堤，先查各渠通水的上限。","来十，北四中四南一；还有一成须找旧河道。","先设北4、中4、南1，再挖中渠旁的旧河道，最后试水。"],
 "pz_ch16_scale":["金、书、剑都不动，托盘却宽得足可站人。","先听兰娅说先父的问题：什么能与一条性命等重？","清空器物，与兰娅谈过后，梁萧上左盘、兰娅上右盘。"],
 "pz_ch16_study":["每季先翻卷，再校铜仪，最后写下观察。","用窗边的刻度校准铜仪，记完一季才换下一页。","春2、夏3、秋2、冬1；按当前季节校准，依次完成十二季。"]}
var puzzle_id=""
var attempt_id=""
var context:Dictionary={}
var state:Dictionary={}
var history:Array=[]
func begin(id:String,attempt:String,ctx:Dictionary)->bool:
 if id not in IDS or attempt.is_empty() or ctx.get("chapter")!=16 or ctx.get("current_token")!=attempt:return false
 if ctx.get("control_actor_id")!="char_liang_xiao":return false
 if not whole(ctx.get("attempt_generation",0),0,10000):return false
 if id=="pz_ch16_scale" and not ctx.get("ranya_present",false):return false
 if id=="pz_ch16_study" and not ctx.get("vault_open",false):return false
 puzzle_id=id;attempt_id=attempt;context=ctx.duplicate(true);history=[]
 state={"complete":false,"revision":1+int(ctx.get("attempt_generation",0))*1024,"hint_level":0,"message":"先观察，再动手。","attempts":0}
 match id:
  "pz_ch16_river":state.merge({"gates":[0,0,0],"surveyed":false,"overflow":false,"material":1,"flow":0})
  "pz_ch16_scale":state.merge({"objects":[],"understood":false,"left":"","right":""})
  "pz_ch16_study":state.merge({"season_index":0,"page_read":false,"instrument":0,"observations":[]})
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
 match puzzle_id:
  "pz_ch16_river":return _river(a)
  "pz_ch16_scale":return _scale(a)
  "pz_ch16_study":return _study(a)
 return false
func _river(a:Dictionary)->bool:
 match a.type:
  "survey":
   if not keys(a,["type"]) or state.surveyed:return false
   state.surveyed=true;state.message="北4，中4，南淤塞后仅1；中渠旁有旧河道。";return true
  "gate":
   if not keys(a,["type","channel","value"]) or not whole(a.channel,0,2) or not whole(a.value,0,4) or not state.surveyed:return false
   if state.gates[int(a.channel)]==int(a.value):return false
   state.gates[int(a.channel)]=int(a.value);state.message="闸口已调，尚未放入洪峰。";return true
  "dig":
   if not keys(a,["type","site"]) or a.site not in ["old_channel","north_bank","south_bank"] or not state.surveyed:return false
   if state.overflow:return false
   if state.gates!=[4,4,1]:state.attempts+=1;state.message="先安顿三条支渠的流量，再定旁渠位置。";return true
   if a.site!="old_channel":state.attempts+=1;state.message="这里不能接去余水，备料未消耗；重新勘查旧河道。";return true
   state.overflow=true;state.material=0;state.message="旁渠连上旧河道，可分担最后一成。";return true
  "test":
   if not keys(a,["type"]) or not state.surveyed:return false
   state.attempts+=1
   if state.gates==[4,4,1] and state.overflow:
    state.complete=true;state.flow=10;state.message="十成来水各有归路，堤下百姓得保。"
   else:state.message="水势未平：查明承载上限和剩余的一成，尚未结算奖励。"
   return true
 return false
func _scale(a:Dictionary)->bool:
 match a.type:
  "place":
   if not keys(a,["type","object"]) or a.object not in ["crown","manuscript","sword"] or a.object in state.objects:return false
   if state.left!="" or state.right!="":return false
   state.objects.append(a.object);state.attempts+=1;state.message="铜梁不动。器物不能与性命等重。";return true
  "clear":
   if not keys(a,["type"]) or state.objects.is_empty():return false
   state.objects=[];state.message="两侧托盘已经清空。";return true
  "talk":
   if not keys(a,["type"]) or state.understood:return false
   state.understood=true;state.message="兰娅：父亲问的不是黄金有多重，而是谁的性命可以轻贱。";return true
  "stand":
   if not keys(a,["type","actor","side"]) or not state.understood or not state.objects.is_empty():return false
   if a.actor not in ["char_liang_xiao","npc_ranya"] or a.side not in ["left","right"]:return false
   if state[a.side]!="" or state.left==a.actor or state.right==a.actor:return false
   state[a.side]=a.actor;state.message="有人踏上托盘，另一侧仍待回应。"
   if state.left=="char_liang_xiao" and state.right=="npc_ranya":state.complete=true;state.message="双盘齐平。人命至重，石门开启。"
   elif state.left!="" and state.right!="":state.message="先按刻文的左右站位重来；石门尚未开启。"
   return true
 return false
func _study(a:Dictionary)->bool:
 var index:int=state.season_index
 if index>=12:return false
 match a.type:
  "read":
   if not keys(a,["type"]) or state.page_read:return false
   state.page_read=true;state.message="翻过此季书页，仍须亲自校准铜仪。";return true
  "align":
   if not keys(a,["type","value"]) or not state.page_read or not whole(a.value,0,4) or state.instrument==int(a.value):return false
   state.instrument=int(a.value);state.message="铜仪已转动，核对窗边刻线。";return true
  "record":
   if not keys(a,["type"]) or not state.page_read:return false
   state.attempts+=1
   if state.instrument!=[2,3,2,1][index%4]:state.message="铜仪与当季刻线未合，此页不计为完成。";return true
   state.observations.append({"season":index,"instrument":state.instrument})
   state.season_index+=1;state.page_read=false;state.instrument=0
   state.complete=state.season_index==12
   state.message="十二季的观察入册，三年研学完成。" if state.complete else "这一季已入册。窗外换了寒暖，下一页仍待亲手完成。"
   return true
 return false
func snapshot()->Dictionary:
 return {"version":1,"puzzle_id":puzzle_id,"attempt_id":attempt_id,"context":context.duplicate(true),"history":history.duplicate(true),"state":state.duplicate(true)}
func restore(value:Variant,expected_context:Dictionary)->bool:
 if not value is Dictionary or not keys(value,["version","puzzle_id","attempt_id","context","history","state"]):return false
 if not whole(value.version,1,1) or not value.puzzle_id is String or not value.attempt_id is String or not value.history is Array or value.history.size()>MAX_INPUTS:return false
 if not Same.equivalent(value.context,expected_context):return false
 var fresh:=ChapterSixteenPuzzleResolver.new()
 if not fresh.begin(value.puzzle_id,value.attempt_id,expected_context):return false
 for action in value.history:
  if not action is Dictionary or action.has("revision") or not fresh.apply_input(action).ok:return false
 if not Same.equivalent(fresh.snapshot(),value):return false
 puzzle_id=fresh.puzzle_id;attempt_id=fresh.attempt_id;context=fresh.context;history=fresh.history;state=fresh.state
 return true
func get_receipts()->Array:
 return [puzzle_id+":completed"] if state.get("complete",false) else []
func get_view()->Dictionary:
 var s:Dictionary=state.duplicate(true)
 return {"puzzle_id":puzzle_id,"attempt_id":attempt_id,"revision":state.revision,"state":s,
 "title":{"pz_ch16_river":"演段治水","pz_ch16_scale":"生命天平","pz_ch16_study":"三年书窗"}.get(puzzle_id,""),
 "hint":HINTS[puzzle_id][state.hint_level-1] if state.hint_level>0 else "提示分三层，不会自动完成操作。"}
