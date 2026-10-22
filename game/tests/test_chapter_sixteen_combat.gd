extends SceneTree
## Unit fixtures exercise rule boundaries; they are not a natural playthrough.
const Core=preload("res://scripts/combat/chapter_sixteen_engine.gd")
const Session=preload("res://scripts/combat/chapter_sixteen_encounter.gd")
const Driver=preload("res://tests/chapter_sixteen_driver.gd")
const Growth=preload("res://scripts/campaign/progression.gd")
const Party=preload("res://scripts/campaign/party_progression.gd")
const Same=preload("res://scripts/campaign/encounter_session.gd")
var checks=0
var failures=0
var rules:Dictionary
var runtime:Dictionary
func _initialize()->void:call_deferred("run")
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error(label)
static func party_fixture()->Array:
 var a:Dictionary=Growth.actor_panel(Core.HERO,40970,Party.CH11_GEAR[Core.HERO])
 var active:Array=["LX_A06","LX_A03","LX_A05","LX_A02"]
 a.merge({"id":Core.HERO,"name":"梁萧","status":"active","team":"party","hp":a.max_hp,"mp":20,"fixed_level":a.level,"skills":["normal_attack","self_guard","guard_ally","LX_A06","LX_A03","LX_A05","sancai_counter"],"equipped_active_skills":active,"skill_ranks":{"LX_A06":1,"LX_A03":2,"LX_A05":2,"LX_A02":2},"passives":[],"learned_passives":[],"internal_skill":""},true)
 return [a]
func make_session(party:Array=[])->RefCounted:
 var cfg:Dictionary=Core.encounter_config();cfg.context={"chapter":16,"current_token":"combat_fixture"}
 return Session.new(rules,runtime,cfg,party if not party.is_empty() else party_fixture(),"combat_fixture")
func count_events(s:RefCounted,type:String,round_number:int=1)->Array:
 return s.engine.state.events.filter(func(e):return e.type==type and int(e.round)==round_number)
func run()->void:
 rules=JSON.parse_string(FileAccess.get_file_as_string("res://data/combat_rules.json"));runtime=JSON.parse_string(FileAccess.get_file_as_string("res://data/combat_runtime.json"))
 var s:=make_session();check(s.engine.entry_error=="","canonical ordinary solo encounter")
 check(s.engine.state.actors.size()==2,"Arutai and Flowered Leopard are one person")
 check(s.engine.actor_by_id(Core.HERO).hp==party_fixture()[0].hp,"no free entry HP")
 check(s.engine.actor_by_id(Core.HERO).mp==party_fixture()[0].max_mp,"independent battle fullMP follows shared rule")
 for args in [[true,"LX_A06",Core.HERO],[Core.HERO,true,Core.HERO],[Core.HERO,"LX_A06",Core.ARUTAI],[Core.HERO,"LX_A07",Core.ARUTAI]]:
  var before:Dictionary=s.snapshot();check(s.set_command(args[0],args[1],args[2])!="","bad/locked command refused");check(Same.equivalent(before,s.snapshot()),"invalid command atomic")
 check(s.set_command(Core.HERO,"LX_A06",Core.HERO,int(s.get_view().revision)-1)!="","stale revision refused")
 var cost:int=s.engine.skill_cost(s.engine.actor_by_id(Core.HERO),s.engine.content.skills.LX_A06)
 check(cost==maxi(18,int(ceil(party_fixture()[0].max_mp*.14))),"rank1 floor18 or14percentMP")
 check(s.set_command(Core.HERO,"LX_A06",Core.HERO)=="","self stance accepted")
 var pending:Dictionary=s.snapshot();check(Session.from_snapshot(JSON.parse_string(JSON.stringify(pending)),rules,runtime)!=null,"pending stance strict replay")
 check(s.resolve_round(),"three segment round resolves")
 var echoes:=count_events(s,"river_counter");check(echoes.size()==1,"exactly one retaliation")
 if not echoes.is_empty():
  check(echoes[0].amount==3 and is_equal_approx(echoes[0].detail.multiplier,2.2),"three layers =>2.2 multiplier")
  var losses:=0;var hits:=0;var last_hit:=-1;var counter_at:=-1
  for i in range(s.engine.state.events.size()):
   var e:Dictionary=s.engine.state.events[i]
   if e.round!=1:continue
   if e.type=="damage" and e.target==Core.HERO:losses+=e.amount;hits+=1;last_hit=i
   if e.type=="river_counter":counter_at=i
  check(hits==3 and counter_at>last_hit,"all three original hits occur before retaliation")
  check(losses==echoes[0].detail.hp_loss_before_counter and losses>0,"paid damage is not rolled back by unload")
  check(int(s.engine.actor_by_id(Core.HERO).hp)==int(party_fixture()[0].hp)-losses,"HP matches actual segment losses")
 check(count_events(s,"action").is_empty(),"stance does not grant a second normal action")
 check(s.engine.validate_command(Core.HERO,"LX_A06",Core.HERO)=="cooldown","stance enters cooldown")
 check(Session.from_snapshot(JSON.parse_string(JSON.stringify(s.snapshot())),rules,runtime)!=null,"resolved stance strictly replays")
 var forged:Dictionary=s.snapshot();forged.state.actors[0].hp+=1
 var safe:Dictionary=s.snapshot();check(not s.restore(forged),"forgedHP rejected");check(Same.equivalent(safe,s.snapshot()),"failed restoration atomic")
 s.retry();check(s.history.is_empty() and s.engine.actor_by_id(Core.HERO).hp==party_fixture()[0].hp,"retry from initial entry, not outcome")
 # Explicit unit-only adversarial fixture: extend one enemy action to five hits
 # and mark it protected. No canonical campaign encounter is changed.
 var protected_session:=make_session()
 protected_session.engine.actor_by_id(Core.ARUTAI).protected_through=99
 protected_session.engine.state.intents[0].hits=[.4,.4,.4,.4,.4]
 protected_session.set_command(Core.HERO,"LX_A06",Core.HERO);protected_session.resolve_round()
 var capped:=count_events(protected_session,"river_counter")
 check(capped.size()==1 and capped[0].amount==3,"five segments still cap at three layers")
 check(count_events(protected_session,"break").is_empty() and not capped[0].detail.unloaded,"protected enemy is not unloaded")
 check(count_events(protected_session,"mana").filter(func(e):return e.detail.get("reason")=="break").is_empty(),"protection gives no break reward")
 var twice:=make_session();var extra:Dictionary=twice.engine.state.intents[0].duplicate(true);extra.intent_id="unit_only_second_action";twice.engine.state.intents.append(extra)
 twice.set_command(Core.HERO,"LX_A06",Core.HERO);twice.resolve_round()
 check(count_events(twice,"enemy_action").size()==2 and count_events(twice,"river_counter").size()==1,"second enemy action still damages but cannot create extra counter")
 var dying:Array=party_fixture();dying[0].hp=1
 var death:=make_session(dying);death.set_command(Core.HERO,"LX_A06",Core.HERO);death.resolve_round()
 check(death.get_view().outcome=="defeat" and count_events(death,"river_counter").is_empty(),"defeated defender does not retaliate")
 death.retry();check(death.engine.actor_by_id(Core.HERO).hp==1,"defeat retry does not heal lowHP entry")
 for change in ["rank","unlearned","slots","ally","number"]:
  var bad:Array=party_fixture()
  match change:
   "rank":bad[0].skill_ranks.LX_A06=2
   "unlearned":bad[0].skill_ranks.erase("LX_A06")
   "slots":bad[0].skills.append("LX_A04");bad[0].equipped_active_skills.append("LX_A04");bad[0].skill_ranks.LX_A04=1
   "ally":bad.append(bad[0].duplicate(true))
   "number":bad[0].hp=true
  check(make_session(bad).engine.entry_error!="","invalid entry "+change)
 for i in range(20):
  if s.get_view().outcome!="":break
  var cmd:Dictionary=Driver.command(s)
  check(not cmd.is_empty() and s.set_command(cmd.actor,cmd.skill,cmd.target)=="","legal round command")
  check(s.resolve_round(),"actual round")
  check(Session.from_snapshot(JSON.parse_string(JSON.stringify(s.snapshot())),rules,runtime)!=null,"each round strict replay")
 check(s.get_view().outcome=="victory","solo encounter winnable with valid loadout")
 var proof:Dictionary=s.receipt()
 check(not Session.replay_receipt(proof,rules,runtime,s.encounter,s.initial_party).is_empty(),"actual result verifies")
 if not proof.is_empty():
  proof.final_actors[0].hp+=1;check(Session.replay_receipt(proof,rules,runtime,s.encounter,s.initial_party).is_empty(),"receipt cannot mintHP")
 check(s.engine.state.events.filter(func(e):return e.type=="postbattle_heal").is_empty(),"no inherited unearned chapter13 postbattle heal")
 var victory:Dictionary=s.snapshot();s.engine._check_outcome();check(Same.equivalent(victory,s.snapshot()),"settled victory idempotent")
 print("Chapter sixteen combat: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
