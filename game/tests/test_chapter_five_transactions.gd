extends SceneTree
const T=preload("res://scripts/campaign/chapter_five_transactions.gd")
const P=preload("res://scripts/campaign/party_progression.gd")
const G=preload("res://scripts/campaign/progression.gd")
var checks:=0
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(ok:bool,label:String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func commit(id:String,actors:Dictionary,items:Dictionary,state:Dictionary,world:Dictionary) -> bool:
 if not T.apply(id,actors,items,state,world):return false
 state.semantic_commits.append(id);return true
func run() -> void:
 for hp in [1,2,3,17,224,723]:
  var hero:Dictionary=G.actor_panel(P.HERO,6540,P.CH04_GEAR[P.HERO])
  hero.merge({"hp":mini(hp,int(hero.max_hp)),"mp":90,"skills":[],"skill_ranks":{},"passives":[]})
  var actors:Dictionary={P.HERO:hero}
  P.recruit_liu(actors)
  var state:Dictionary={"injury":{},"semantic_commits":[],"knowledge":[],"memories":[],"currency_ledger":{},"coins":0,"axue_thorn":false}
  var items:Dictionary={};var world:Dictionary={}
  var original:Dictionary=hero.duplicate(true)
  check(commit("qi_depleted",actors,items,state,world),"depletion once")
  check(hero.hp==maxi(1,int(original.hp)/2) and hero.mp==0,"floor odd HP once and MP0")
  for k in ["max_hp","max_mp","atk","def","spd","bare","equipment"]:check(hero[k]==original[k],"permanent base preserved "+k)
  var snapshot:String=JSON.stringify(actors)
  check(not commit("qi_depleted",actors,items,state,world) and JSON.stringify(actors)==snapshot,"repeat depletion no second half")
  var before:int=hero.hp
  check(commit("porridge_delivered_verified",actors,items,state,world),"porridge consent event")
  check(hero.hp==mini(before+30,int(T.effective(hero,state.injury).max_hp)),"precise porridge cap")
  items.item_ch05_yin_ball={};items.item_ch05_yang_ball={}
  check(commit("yin_yang_breath_verified",actors,items,state,world),"verified breathing")
  check(T.effective(hero,state.injury).max_mp==int(hero.max_mp)/4,"recovering effective MP quarter")
  check(commit("cave_recovery",actors,items,state,world),"once cave recovery")
  check(T.effective(hero,state.injury).max_hp==hero.max_hp,"base restored through overlay removal")
  check(commit("axue_rescued",actors,items,state,world),"limited Axue joins once")
  var axue:String=JSON.stringify(actors[T.A])
  actors[P.LIU].status="temporarily_absent"
  var old_xp:int=actors[P.LIU].xp
  var ledger:Dictionary={}
  check(P.award(actors,ledger,"postjoin",100),"core shared reward")
  check(actors[P.LIU].xp==old_xp+100 and JSON.stringify(actors[T.A])==axue,"absent Liu grows; limited Axue fixed")
  check(not P.award(actors,ledger,"postjoin",100),"no duplicate XP")
  check(not commit("axue_rescued",actors,items,state,world) and JSON.stringify(actors[T.A])==axue,"no repeated recruit refill")
 for coins in [0,1,2,550]:
  var actors:Dictionary={P.HERO:{},P.LIU:{}}
  var state:Dictionary={"injury":{},"semantic_commits":[],"currency_ledger":{},"coins":coins}
  var items:Dictionary={};var world:Dictionary={}
  check(commit("chapter_five_exit",actors,items,state,world),"explicit chapter copper settlement")
  check(state.coins==coins+400,"copper additive at boundary "+str(coins))
  check(not commit("chapter_five_exit",actors,items,state,world) and state.coins==coins+400,"copper idempotent")
 print("Chapter five transactions: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
