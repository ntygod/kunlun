extends SceneTree
const Campaign=preload("res://scripts/campaign/campaign_state.gd")
const T=preload("res://scripts/campaign/chapter_six_transactions.gd")
const Proof=preload("res://scripts/campaign/encounter_session.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var c=Campaign.new(JSON.parse_string(FileAccess.get_file_as_string("res://data/prologue.json")))
 check(c.restore_persisted(JSON.parse_string(FileAccess.get_file_as_string("res://../output/cache/chapter_five_gui/manual_natural_final.json")))=="","real natural chapter5 load")
 var s:Dictionary={"semantic_commits":[],"knowledge":[],"memories":[],"choices":{},"story_restriction":"","currency_ledger":{},"coins":950,"leader_id":T.H}
 var a:Dictionary=c.actors.duplicate(true);var items:Dictionary=c.items.duplicate(true);var world:Dictionary={}
 check(a[T.A].hp==240 and a[T.A].mp==35,"limited actual resource inherited")
 var original:Dictionary=a.duplicate(true)
 s.semantic_commits.append("basket_goods_exchanged")
 check(T.apply("safe_home_rest",a,items,s,world),"once explicit rest")
 check(a[T.A].hp==480 and a[T.A].mp==53,"limited exact 50 percent and floor25 percent")
 check(Proof.equivalent(a[T.L],original[T.L]),"absent Liu not remotely healed")
 check(a[T.H].hp==796 and a[T.H].mp==78,"hero capped hp plus floor mp")
 s.semantic_commits.append("safe_home_rest")
 var before:Dictionary=a.duplicate(true)
 check(not T.apply("safe_home_rest",a,items,s,world) and Proof.equivalent(a,before),"repeat rest rejected atomic")
 for who in [T.H,T.A]:
  var dead:Dictionary=original.duplicate(true);dead[who].hp=0
  var st:Dictionary=s.duplicate(true);st.semantic_commits.erase("safe_home_rest")
  var old:Dictionary=dead.duplicate(true)
  check(not T.apply("safe_home_rest",dead,items,st,world) and Proof.equivalent(dead,old),"rest never resurrects "+who)
 for coins in [0,1,2,950]:
  for method in ["coins","book"]:
   var st:Dictionary=s.duplicate(true);st.coins=coins;st.currency_ledger={};st.semantic_commits=[];st.choices={"entrust":"ch06_entrust_"+method}
   var it:Dictionary=items.duplicate(true);it[T.BOOK]={"owner":T.H,"state":"carried"}
   check(T.apply("dlg_ch06_settlement",a,it,st,world),"settlement")
   check(st.coins==coins+450,"settlement additive")
   check(not T.apply("dlg_ch06_settlement",a,it,st,world),"settlement unique ledger")
   check(T.apply("departure_confirmed",a,it,st,world),"transfer real purse/book")
   check(st.coins==(0 if method=="coins" else coins+450),"purse boundary")
   check(int(it.item_ch06_entrusted_coins.quantity)==coins+450 if method=="coins" else it[T.BOOK].owner==T.A,"exact ownership")
 var b:Dictionary=original.duplicate(true);var st:Dictionary=s.duplicate(true);st.semantic_commits=[]
 check(T.apply("gear_refit_ch06",b,items,st,world),"chapter6 gear replaces")
 check(b[T.H].hp==original[T.H].hp and b[T.H].mp==original[T.H].mp,"refit no secret healing")
 check(b[T.H].equipment==T.GEAR,"refit exact source bonus")
 var it:Dictionary=c.items.duplicate(true);var old_actor:Dictionary=b.duplicate(true)
 check(T.apply("dlg_ch06_crisis",b,it,st,world),"real balls crisis")
 check(Proof.equivalent(b,old_actor),"crisis doesn't mutate permanent stats/resources")
 check(it.item_ch05_yin_ball.state=="destroyed" and it.item_ch05_yang_ball.state=="destroyed","both unique balls destroyed")
 check(T.apply("borrowed_body_recovery",b,it,st,world) and it[T.RUBBINGS].owner==T.H,"same rubbings returned")
 check(Proof.equivalent(b,old_actor),"recovery no invented healing")
 print("Chapter six transactions: ",checks," checks, ",failures," failures")
 quit(1 if failures else 0)
