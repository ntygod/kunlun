extends SceneTree
const Core=preload("res://scripts/combat/chapter_ten_engine.gd")
const Session=preload("res://scripts/combat/chapter_ten_encounter.gd")
const Campaign=preload("res://scripts/campaign/campaign_state.gd")
const Same=preload("res://scripts/campaign/encounter_session.gd")
const BattlePanel=preload("res://scripts/ui/chapter_ten_battle_panel.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func _initialize()->void:call_deferred("run")
func run()->void:
 var c=Campaign.new(JSON.parse_string(FileAccess.get_file_as_string("res://data/prologue.json")))
 check(c.restore_persisted(JSON.parse_string(FileAccess.get_file_as_string("res://../output/cache/chapter_nine_gui/manual_natural_final.json")))=="","real natural chapter9 source")
 var h:Dictionary=c.actors.char_liang_xiao.duplicate(true)
 h.team="party";h.id=Core.HERO;h.skills=["normal_attack","self_guard","observe","sancai_counter","LX_A03"];h.passives=h.get("equipped_passives",[]).duplicate()
 var cfg:=Core.encounter_config();cfg.context={"chapter":10,"current_token":"test_b06","map_id":"map_ch10_qiantang_bank"}
 var s=Session.new(c.rules,c.combat,cfg,[h],"test_b06")
 check(s.engine.entry_error=="","valid entry")
 check(s.engine.actor_by_id(Core.HERO).hp==h.hp and s.engine.actor_by_id(Core.HERO).mp==h.max_mp,"preserve HP; battle MP fill")
 check(s.set_command(Core.HERO,"LX_A04",Core.BOSS)!="","future skill refused")
 var start:=s.snapshot()
 for bad in [null,[],true,{"actor_id":Core.HERO,"action_id":"borrow_tide","revision":true},{"actor_id":Core.HERO,"action_id":"borrow_tide","revision":1.0},{"actor_id":Core.HERO,"action_id":"borrow_tide","victory":true}]:
  check(not s.apply_input(bad).accepted and Same.equivalent(start,s.snapshot()),"bad input atomic")
 for r in range(1,7):
  var skill:String={1:"LX_A03",2:"observe",3:"sancai_counter",4:"ch10_borrow_tide",5:"LX_A03",6:"self_guard"}[r]
  check(s.set_command(Core.HERO,skill,Core.HERO if skill in ["self_guard","ch10_borrow_tide"] else Core.BOSS)=="","legal planned round "+str(r))
  check(s.resolve_round(),"resolve "+str(r))
  if r<6:check(s.engine.state.outcome=="","no early victory")
  var rebuilt=Session.from_snapshot(JSON.parse_string(JSON.stringify(s.snapshot())),c.rules,c.combat)
  check(rebuilt!=null,"JSON replay partial round "+str(r))
  if r==3:
   check(s.engine.state.objective.phase=="phase_two" and s.engine.state.round==4,"phase2 at round4")
   check(s.engine.actor_by_id(Core.BOSS).atk==230 and s.engine.actor_by_id(Core.BOSS).def==135 and s.engine.actor_by_id(Core.BOSS).spd==42,"source phase2 stats")
 check(s.engine.state.outcome=="victory" and s.engine.state.objective.survived_rounds==6,"survival victory")
 check(not Session.replay_receipt(s.receipt(),c.rules,c.combat,cfg,[h]).is_empty(),"receipt genuine replay")
 var forged:=s.snapshot();forged.state.actors[0].hp+=1
 check(not s.restore(forged),"forged HP rejected")
 var before:=s.snapshot();check(not s.apply_input({"actor_id":Core.HERO,"action_id":"borrow_tide"}).accepted and Same.equivalent(before,s.snapshot()),"postvictory input refused")
 s.retry();check(Same.equivalent(start,s.snapshot()),"retry original resources and all history")
 # Guard-only alternative requires no late skill and receives real damage.
 for r in range(6):
  check(s.set_command(Core.HERO,"self_guard",Core.HERO)=="","guard legal");check(s.resolve_round(),"guard round")
 check(s.engine.state.outcome=="victory" and s.engine.actor_by_id(Core.HERO).hp<h.hp,"guard path survives with genuine losses")
 # Passive ownership and ranked observation survive strict JSON replay too.
 var unlearned:=h.duplicate(true);unlearned.learned_passives=[]
 check(Session.new(c.rules,c.combat,cfg,[unlearned],"test_b06").engine.entry_error=="unlearned_passive","equipped passives must actually be learned")
 var plain:=h.duplicate(true);plain.passives=[]
 var grief=Session.new(c.rules,c.combat,cfg,[plain],"test_b06")
 check(grief.engine._status_value(grief.engine.actor_by_id(Core.HERO),"friend_rage")==.2,"grief is independent of equipped P02")
 var with_p02=Session.new(c.rules,c.combat,cfg,[h],"test_b06")
 check(grief.engine.skill_cost(grief.engine.actor_by_id(Core.HERO),grief.engine.content.skills.LX_A03)==with_p02.engine.skill_cost(with_p02.engine.actor_by_id(Core.HERO),with_p02.engine.content.skills.LX_A03),"P02 does not double grief discount")
 var rank=Session.new(c.rules,c.combat,cfg,[h],"test_b06")
 check(rank.set_command(Core.HERO,"observe",Core.BOSS)=="" and rank.resolve_round(),"rank3 observe initial")
 check(rank.engine.actor_by_id(Core.HERO).get("observe_bonus",false),"first observation arms bonus")
 check(rank.set_command(Core.HERO,"sancai_counter",Core.BOSS)=="" and rank.resolve_round(),"counter after observation")
 check(rank.engine.actor_by_id(Core.HERO).get("observe_bonus",false),"counter preserves normal-action observation bonus")
 check(rank.set_command(Core.HERO,"normal_attack",Core.BOSS)=="" and rank.resolve_round(),"consume normal observation")
 check(not rank.engine.actor_by_id(Core.HERO).get("observe_bonus",false),"normal action consumes bonus")
 check(rank.set_command(Core.HERO,"observe",Core.BOSS)=="" and rank.resolve_round(),"later observation legal")
 check(not rank.engine.actor_by_id(Core.HERO).get("observe_bonus",false),"first-only rank3 bonus not minted twice")
 # A one-HP damage fixture verifies defeat, never claims to be a natural save.
 var frail:=h.duplicate(true);frail.hp=1
 var doomed=Session.new(c.rules,c.combat,cfg,[frail],"test_b06")
 for r in range(2):
  check(doomed.set_command(Core.HERO,"observe",Core.BOSS)=="","frail action");check(doomed.resolve_round(),"frail round")
 check(doomed.engine.state.outcome=="defeat" and doomed.receipt().is_empty(),"failed survival not victory")
 doomed.retry();check(doomed.engine.actor_by_id(Core.HERO).hp==1,"no healing by retry")
 # Enemy is an objective opponent: even extreme test damage must not end early.
 var strong:=h.duplicate(true);strong.atk=100000
 var cap=Session.new(c.rules,c.combat,cfg,[strong],"test_b06")
 check(cap.set_command(Core.HERO,"normal_attack",Core.BOSS)=="","stress attack");check(cap.resolve_round(),"stress round")
 check(cap.engine.actor_by_id(Core.BOSS).hp==1 and cap.engine.state.outcome=="","HP cap does not win")
 # UI uses actual legality and rejects old control callbacks after rerender.
 for size in [Vector2i(640,360),Vector2i(1280,720)]:
  root.size=size
  var panel=BattlePanel.new();root.add_child(panel);panel.position=Vector2(20,20);panel.size=Vector2(size)-Vector2(40,40)
  s.retry();panel.render(s.get_view(),c.combat.skills,s.can_resolve())
  await process_frame;await process_frame
  check(panel.slots.has("LX_A03") and panel.slots.ch10_borrow_tide.disabled,"scene skill gated before tide")
  var old:Button=panel.slots.LX_A03;var received:Array=[]
  panel.command_requested.connect(func(a,b,d,r):received.append([a,b,d,r]))
  panel.render(s.get_view(),c.combat.skills,s.can_resolve());old.pressed.emit()
  check(received.is_empty(),"stale callback refused")
  panel.slots.LX_A03.pressed.emit();check(received.size()==1,"real direct choice emitted")
  await process_frame;await process_frame
  check(panel.get_combined_minimum_size().x<=size.x-40,"panel width fits")
  check(panel.get_combined_minimum_size().y<=size.y-40,"panel height fits")
  panel.queue_free();await process_frame
 print("Chapter ten combat: ",checks," checks, ",failures," failures")
 quit(1 if failures else 0)
