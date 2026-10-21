extends SceneTree
const Core=preload("res://scripts/combat/chapter_eleven_engine.gd")
const Session=preload("res://scripts/combat/chapter_eleven_encounter.gd")
const Driver=preload("res://tests/chapter_eleven_encounter_driver.gd")
const Party=preload("res://scripts/campaign/party_progression.gd")
const Growth=preload("res://scripts/campaign/progression.gd")
const Same=preload("res://scripts/campaign/encounter_session.gd")
const BattlePanel=preload("res://scripts/ui/chapter_eleven_battle_panel.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error(label)
static func party_fixture()->Array:
 var h:Dictionary=Growth.actor_panel(Core.HERO,22540,Party.CH11_GEAR[Core.HERO]);h.merge({"id":Core.HERO,"name":"梁萧","team":"party","hp":h.max_hp,"mp":80,"fixed_level":50,"skills":Core.H_SKILLS.duplicate(),"skill_ranks":{"LX_A01":3,"LX_A02":3,"LX_A03":2,"LX_A04":1},"passives":["LX_P01","LX_P03"],"learned_passives":["LX_P01","LX_P02","LX_P03"],"internal_skill":""})
 var x:Dictionary=Party.newcore_panel(Core.X,22540,Party.CH11_GEAR[Core.X],"HXS_N02");x.merge({"id":Core.X,"name":"花晓霜","team":"party","hp":1050,"mp":90,"fixed_level":50,"skills":["normal_attack","self_guard","guard_ally","HXS_A01","HXS_A02","HXS_A03","HXS_A07"],"skill_ranks":{"HXS_A01":3,"HXS_A02":3,"HXS_A03":1,"HXS_A07":1,"HXS_N02":1},"passives":["HXS_P01"],"learned_passives":["HXS_P01"],"internal_skill":"HXS_N02","internal_stats_applied":true})
 return [h,x]
func _initialize()->void:call_deferred("run")
func run()->void:
 var rules:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/combat_rules.json"));var runtime:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/combat_runtime.json"))
 var cfg:=Core.encounter_config();cfg.context={"chapter":11,"current_token":"test_b07","combo_unlocked":true}
 var party:=party_fixture();var s=Session.new(rules,runtime,cfg,party,"test_b07")
 check(s.engine.entry_error=="","canonical two actors")
 var too_many:=party.duplicate(true);too_many[1].skills.append("HXS_A04");too_many[1].skill_ranks.HXS_A04=1
 check(Session.new(rules,runtime,cfg,too_many,"test_b07").engine.entry_error=="active_slot_limit","learned optional fifth skill must be equipped by replacement")
 too_many[1].skills.erase("HXS_A03")
 check(Session.new(rules,runtime,cfg,too_many,"test_b07").engine.entry_error=="","optional skill lawful four-slot replacement")
 check(s.engine.actor_by_id(Core.X).hp==1050 and s.engine.actor_by_id(Core.X).max_hp==1494,"N02 no double scaling/healing")
 var last_phase:int=1
 for round_index in range(120):
  if s.engine.state.outcome!="":break
  for cmd in Driver.commands(s):check(s.set_command(cmd[0],cmd[1],cmd[2])=="","legal driver command")
  check(s.resolve_round(),"real full round")
  var rebuilt=Session.from_snapshot(JSON.parse_string(JSON.stringify(s.snapshot())),rules,runtime)
  check(rebuilt!=null,"every-round JSON replay")
  for a in s.engine.state.actors:
   check(a.mana_gained<=12,"MP income cap "+a.id)
   check(int(a.get("passive_healed",0))<=int(floor(a.max_hp*.03)),"passive heal cap "+a.id)
  if int(s.engine.state.objective.phase)!=last_phase:
   last_phase=int(s.engine.state.objective.phase)
   var previous:Dictionary=s.engine.state.objective.phase_history[0]
   for a in previous.actors:
    if a.team=="party":check(Same.equivalent(a.ready,s.engine.actor_by_id(a.id).ready),"phase cooldown retained")
 check(s.engine.state.outcome=="victory","legal minimum-level stat fixture wins")
 check(not s.receipt().is_empty(),"victory proof")
 if not s.receipt().is_empty():check(not Session.replay_receipt(s.receipt(),rules,runtime,cfg,party).is_empty(),"full exact replay")
 for removed in ["HXS_A01","HXS_A02","HXS_A03","HXS_A07"]:
  var optional_party:=party.duplicate(true);optional_party[1].skills.erase(removed);optional_party[1].skills.append("HXS_A04");optional_party[1].skill_ranks.HXS_A04=1
  var alternative=Session.new(rules,runtime,cfg,optional_party,"test_b07")
  check(alternative.engine.entry_error=="" and Driver.run(alternative),"lawful alternate four-slot route "+removed)
  check(not Session.replay_receipt(alternative.receipt(),rules,runtime,cfg,optional_party).is_empty(),"alternate loadout replay "+removed)
 var finish:=s.snapshot();s.engine._check_outcome();check(Same.equivalent(finish,s.snapshot()),"postwin heal cannot repeat")
 var post_count:=0
 for e in s.engine.state.events:
  if e.type=="postbattle_heal":post_count+=1
 check(post_count==2,"only each living hero once20percent")
 var forged:=s.snapshot();forged.state.actors[0].hp-=1
 check(not s.restore(forged) and Same.equivalent(finish,s.snapshot()),"bad finalHP snapshot atomic")
 s.retry();var baseline:=s.snapshot()
 for bad in [null,[],true,{"action_id":"cancel","revision":true},{"action_id":"cancel","revision":0},{"action_id":"cancel","revision":s.engine.state.revision,"victory":true}]:
  check(not s.apply_input(bad).accepted and Same.equivalent(baseline,s.snapshot()),"bad input atomic")
 for bad in [[false,"normal_attack",Core.CHANG],[Core.HERO,"HXS_A05",Core.X],[Core.X,"HXS_A06",Core.CHANG],[Core.HERO,"CO_02",Core.CHANG]]:
  check(s.set_command(bad[0],bad[1],bad[2])!="" and Same.equivalent(baseline,s.snapshot()),"future/foreign/combo command refused")
 # Explicit resource-limit fixtures, never campaign save substitutions.
 s.engine.state.objective.synergy=2
 check(s.set_command(Core.HERO,"CO_02",Core.CHANG)=="","reserve combo")
 check(s.engine.state.objective.reserved==2 and s.engine.state.commands.size()==2,"combo reserves both and two bars")
 check(s.apply_input({"action_id":"cancel","revision":s.engine.state.revision}).accepted,"cancel reservation")
 check(s.engine.state.objective.reserved==0 and s.engine.state.objective.synergy==2,"refund exact once")
 check(s.apply_input({"action_id":"cancel","revision":s.engine.state.revision}).accepted and s.engine.state.objective.synergy==2,"repeatedcancel does not mint")
 check(s.set_command(Core.HERO,"CO_02",Core.CHANG)=="","reserve again")
 s.engine._apply_status(s.engine.actor_by_id(Core.X),"stun",1,1)
 check(s.resolve_round(),"controlled participant cancels at execution")
 check(s.engine.state.objective.reserved==0 and s.engine.state.objective.synergy==2,"execution refund no combo gain")
 # Healing formula, cleanse, exact nonlethal state and DOT immunity.
 s.retry();var h:Dictionary=s.engine.actor_by_id(Core.HERO);var x:Dictionary=s.engine.actor_by_id(Core.X)
 h.hp=500;s.engine._apply_status(h,"poison",157,3);s.engine._apply_status(h,"speed_down",.1,2)
 var old_mp:int=x.mp
 check(s.set_command(Core.HERO,"self_guard",Core.HERO)=="" and s.set_command(Core.X,"HXS_A02",Core.HERO)=="" and s.resolve_round(),"actual ranked heal")
 var cleanse:=0;var healed:=0
 for e in s.engine.state.events:
  if e.type=="cleanse":cleanse+=1
  if e.type=="heal" and e.detail.reason=="HXS_A02":healed+=e.amount
 check(cleanse==2 and healed==277,"rank3 heal exact floor277 removes2")
 check(x.mp==old_mp-28+4,"genuine cleanse refund4 only")
 s.retry();h=s.engine.actor_by_id(Core.HERO);x=s.engine.actor_by_id(Core.X)
 for r in range(2):
  check(s.set_command(Core.HERO,"self_guard",Core.HERO)=="" and s.set_command(Core.X,"self_guard",Core.X)=="" and s.resolve_round(),"unguarded poison fixture rounds")
 check(s.engine._status_value(h,"poison")==157 and s.engine._status_value(x,"poison")==0,"real poison emitted with N02 immunity")
 var ticks:=0
 for e in s.engine.state.events:
  if e.type=="poison_tick":ticks+=1;check(e.amount==157,"ATK-derived poison tick no percentHP")
 check(ticks==1,"first poison tick next round only")
 s.retry();x=s.engine.actor_by_id(Core.X);var guard:Dictionary=s.engine.actor_by_id("guard_east");guard.hp=1
 check(s.set_command(Core.HERO,"self_guard",Core.HERO)=="" and s.set_command(Core.X,"normal_attack","guard_east")=="" and s.resolve_round(),"nonlethal actual attack")
 check(guard.hp==1 and guard.defeated and not s.engine.alive(guard),"oneHP失战 cannot keepacting")
 var thin:=party.duplicate(true);thin[1].hp=1
 var doomed=Session.new(rules,runtime,cfg,thin,"test_b07")
 check(doomed.set_command(Core.HERO,"self_guard",Core.HERO)=="" and doomed.set_command(Core.X,"normal_attack",Core.CHANG)=="" and doomed.resolve_round(),"lowresource defeat actual turn")
 # West guard rests on round1; first attack arrives on round2.
 if doomed.engine.state.outcome=="":doomed.set_command(Core.HERO,"self_guard",Core.HERO);doomed.set_command(Core.X,"normal_attack",Core.CHANG);doomed.resolve_round()
 check(doomed.engine.state.outcome=="defeat" and doomed.receipt().is_empty(),"anyrescuer down failure no revival")
 doomed.retry();check(doomed.engine.actor_by_id(Core.X).hp==1,"retry original wound")
 # Explicit damage-channel map: physical multi-hit blocked once, inner allowed;
 # protection remains independent of the immunity channel.
 s.retry();var shell:Dictionary=s.engine.actor_by_id(Core.CHANG);shell.shell=true;shell.protected_through=2
 var shell_hp:int=shell.hp;var mana_before:int=s.engine.actor_by_id(Core.HERO).mp
 check(s.set_command(Core.HERO,"LX_A03",Core.CHANG)=="" and s.set_command(Core.X,"self_guard",Core.X)=="" and s.resolve_round(),"physical shell fixture executes")
 check(shell.hp==shell_hp and s.engine.actor_by_id(Core.HERO).mp==mana_before-23-8,"three physical hits immune one8MP drain")
 s.retry();shell=s.engine.actor_by_id(Core.CHANG);shell.shell=true;shell.protected_through=2
 s.engine._apply_status(shell,"diagnosed",.15,3)
 check(s.set_command(Core.HERO,"LX_A04",Core.CHANG)=="" and s.set_command(Core.X,"self_guard",Core.X)=="" and s.resolve_round(),"inner shell fixture executes")
 check(shell.hp<2800 and s.engine.state.break_count==0,"A04 inner damage bypasses shell without bypassing protection")
 s.retry();shell=s.engine.actor_by_id(Core.CHANG);shell.shell=true;shell.protected_through=2;s.engine.state.objective.synergy=2
 check(s.set_command(Core.HERO,"CO_02",Core.CHANG)=="" and s.resolve_round(),"CO02 inner shell fixture")
 check(shell.hp<2800 and s.engine.state.break_count==0,"CO02 inner damage and no protectedcancel")
 for size in [Vector2i(640,360),Vector2i(1280,720)]:
  root.size=size;s.retry()
  var panel=BattlePanel.new();root.add_child(panel);panel.position=Vector2(20,20);panel.size=Vector2(size)-Vector2(40,40);panel.render(s.get_view(),runtime.skills,s.can_resolve())
  await process_frame;await process_frame
  check(panel.get_combined_minimum_size().x<=size.x-40 and panel.get_combined_minimum_size().y<=size.y-40,"twohero panel fits "+str(size))
  check(panel.slots.has(Core.HERO+"_skills") and panel.slots.has(Core.X+"_skills") and panel.slots.combo.disabled,"bothheroskillselectors and gatedcombo")
  var old:Button=panel.slots[Core.HERO+"_confirm"];var received:Array=[];panel.command_requested.connect(func(a,b,c,d):received.append([a,b,c,d]))
  panel.render(s.get_view(),runtime.skills,s.can_resolve());old.pressed.emit();check(received.is_empty(),"old selector callback inert")
  panel.slots[Core.HERO+"_confirm"].pressed.emit();check(received.size()==1 and received[0][0]==Core.HERO,"hero selector emits own legal command")
  panel.slots[Core.X+"_confirm"].pressed.emit();check(received.size()==2 and received[1][0]==Core.X,"doctor selector emits own legal command")
  panel.queue_free();await process_frame
 print("Chapter eleven combat: ",checks," checks, ",failures," failures")
 quit(1 if failures else 0)
