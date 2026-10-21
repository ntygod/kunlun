extends SceneTree
const Core=preload("res://scripts/combat/chapter_thirteen_engine.gd")
const Session=preload("res://scripts/combat/chapter_thirteen_encounter.gd")
const Driver=preload("res://tests/chapter_thirteen_encounter_driver.gd")
const Party=preload("res://scripts/campaign/party_progression.gd")
const Growth=preload("res://scripts/campaign/progression.gd")
const Same=preload("res://scripts/campaign/encounter_session.gd")
const BattlePanel=preload("res://scripts/ui/chapter_thirteen_battle_panel.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error(label)
static func party_fixture()->Array:
 var h:Dictionary=Growth.actor_panel(Core.HERO,33550,Party.CH11_GEAR[Core.HERO])
 h.max_hp=int(floor(h.max_hp*1.18));h.max_mp=int(floor(h.max_mp*1.25));h.def=int(floor(h.def*1.12))
 h.merge({"id":Core.HERO,"team":"party","hp":h.max_hp,"mp":20,"fixed_level":62,"skills":["normal_attack","self_guard","guard_ally","observe","sancai_counter","LX_A04","LX_A05"],"skill_ranks":{"LX_A01":3,"LX_A02":3,"LX_A03":3,"LX_A04":2,"LX_A05":1,"LX_N02":1},"equipped_active_skills":["LX_A01","LX_A02","LX_A04","LX_A05"],"passives":["LX_P01","LX_P03"],"learned_passives":["LX_P01","LX_P02","LX_P03"],"internal_skill":"LX_N02","panel_internal_skill":"LX_N02","internal_stats_applied":true},true)
 return [h]
func _initialize()->void:call_deferred("run")
func run()->void:
 var rules:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/combat_rules.json"));var runtime:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/combat_runtime.json"))
 var cfg:=Core.encounter_config();cfg.context={"chapter":13,"current_token":"test_b10"}
 var party:=party_fixture();var s=Session.new(rules,runtime,cfg,party,"test_b10")
 check(s.engine.entry_error=="","valid single hero")
 if s.engine.entry_error!="":print(s.engine.entry_error);quit(1);return
 check(s.engine.actor_by_id(Core.HERO).max_hp==party[0].max_hp and s.engine.actor_by_id(Core.HERO).max_mp==party[0].max_mp,"N02 panel not applied twice")
 check(s.engine.actor_by_id(Core.HERO).mp==party[0].max_mp,"independent battle starts fullMP")
 for i in range(30):
  if s.get_view().outcome!="":break
  var before:=s.snapshot()
  for bad in [null,{}, {"actor_id":Core.HERO,"action_id":"win"},{"actor_id":Core.HERO,"action_id":"cancel","revision":true}]:check(not s.apply_input(bad).accepted and Same.equivalent(before,s.snapshot()),"invalid inputs atomic")
  for cmd in Driver.commands(s):check(s.set_command(cmd[0],cmd[1],cmd[2])=="","legal public strategy")
  var partial:Dictionary=JSON.parse_string(JSON.stringify(s.snapshot()));check(Session.from_snapshot(partial,rules,runtime)!=null,"pending command real replay restore")
  check(s.resolve_round(),"actual round settles")
  check(Session.from_snapshot(JSON.parse_string(JSON.stringify(s.snapshot())),rules,runtime)!=null,"every round replay")
  if i<4:check(s.get_view().outcome!="victory","no early win before five rounds")
 check(s.get_view().outcome=="victory" and s.get_view().objective.anchor==100,"natural command route completes B10")
 print("B10 finished round ",s.engine.state.round," HP ",s.engine.actor_by_id(Core.HERO).hp," MP ",s.engine.actor_by_id(Core.HERO).mp)
 check(s.get_view().objective.phase==2,"second phase entered")
 check(s.engine.actor_by_id(Core.YUN).hp>0 and s.engine.actor_by_id(Core.HE).hp>0,"both story opponents survive")
 check(not Session.replay_receipt(s.receipt(),rules,runtime,cfg,party).is_empty(),"exact victory receipt replay")
 var after:=s.snapshot();s.engine._check_outcome();check(Same.equivalent(after,s.snapshot()),"postheal idempotent")
 var forged:=s.snapshot();forged.state.objective.anchor=99;check(not s.restore(forged) and Same.equivalent(after,s.snapshot()),"forged progress restore atomic")
 s.retry();check(s.engine.actor_by_id(Core.HERO).hp==party[0].hp and s.engine.state.round==1,"retry original resources")
 # Bounded engine fixtures below exercise mechanics; they are not natural saves.
 var bad_party:=party.duplicate(true);bad_party[0].skills.append("LX_A03")
 check(Session.new(rules,runtime,cfg,bad_party,"test_b10").engine.entry_error!="","fifth active slot rejected")
 var exact:=s.snapshot()
 check(s.set_command(Core.HERO,"LX_A05",Core.YUN,true)!="" and Same.equivalent(exact,s.snapshot()),"boolean command revision rejected")
 var ignored=Session.new(rules,runtime,cfg,party,"test_b10")
 for i in range(4):
  check(ignored.set_command(Core.HERO,"self_guard",Core.HERO)=="" and ignored.resolve_round(),"ordinary guard route settles")
 check(ignored.get_view().objective.anchor==50 and ignored.get_view().outcome=="","unanswered fire costs30 instead of free five round win")
 var n=Session.new(rules,runtime,cfg,party,"test_b10");var h:Dictionary=n.engine.actor_by_id(Core.HERO);var foe:Dictionary=n.engine.actor_by_id(Core.YUN)
 h.hp=h.max_hp;h.def=0;var hp:int=h.hp
 n.engine._branch(foe,h,float(h.max_hp)*.26,"enemy","fixture_combo_1")
 var first:int=hp-int(h.hp);hp=h.hp
 n.engine._branch(foe,h,100.0,"enemy","fixture_combo_1")
 check(first==int(floor(h.max_hp*.26)) and hp-int(h.hp)==70,"N02 only subsequent segment gets30percent guard")
 check(n.get_view().objective.whale_procs==1,"one proc per enemy action")
 h.hp=h.max_hp;n.engine._branch(foe,h,float(h.max_hp)*.26,"enemy","fixture_combo_2")
 h.hp=h.max_hp;n.engine._branch(foe,h,float(h.max_hp)*.26,"enemy","fixture_combo_3");hp=h.hp;n.engine._branch(foe,h,100.0,"enemy","fixture_combo_3")
 check(n.get_view().objective.whale_procs==2 and hp-int(h.hp)==100,"N02 two procs per battle cap")
 h.hp=100;h.passive_healed=0;n.engine._passive_heal(h,.02,"fixture_breath");n.engine._passive_heal(h,.02,"fixture_counter")
 check(h.hp==100+int(floor(h.max_hp*.03)),"N02 and counter share3percent passive healing cap")
 var a=Session.new(rules,runtime,cfg,party,"test_b10");check(a.set_command(Core.HERO,"LX_A05",Core.YUN)=="" and a.resolve_round(),"A05 actual action")
 check(a.engine.actor_by_id(Core.HERO).get("shield",0)==0,"A05 rank1 never borrows rank3 tide shield")
 check(a.engine._status_value(a.engine.actor_by_id(Core.YUN),"speed_down")==.2 and a.engine._status_value(a.engine.actor_by_id(Core.HE),"speed_down")==.2,"A05 group slowdown")
 var broken:=0
 for e in a.get_view().events:
  if e.type=="fire_cancelled":broken+=1
 check(broken==1,"A05 cancels public fire once")
 var p=BattlePanel.new();root.add_child(p);root.size=Vector2i(640,360);p.size=Vector2(600,320);p.render(s.get_view(),{},s.can_resolve());await process_frame;await process_frame
 check(p.slots.has(Core.HERO+"_skills") and p.slots.has(Core.HERO+"_target"),"640 actual command selectors")
 check(p.slots[Core.HERO+"_vitals"].text.begins_with("梁萧"),"actual actor uses localized name")
 var received:Array=[];p.command_requested.connect(func(actor,skill,target,revision):received.append([actor,skill,target,revision]))
 var skills:OptionButton=p.slots[Core.HERO+"_skills"]
 for i in range(skills.item_count):
  if skills.get_item_metadata(i)=="self_guard":skills.select(i);skills.item_selected.emit(i)
 var target:OptionButton=p.slots[Core.HERO+"_target"]
 check(target.get_item_text(0)=="梁萧" and target.get_item_metadata(0)==Core.HERO,"self target localized without ID mutation")
 var b:Button=p.slots[Core.HERO+"_confirm"];var at:=b.get_global_rect().get_center()
 for pressed in [true,false]:
  var e:=InputEventMouseButton.new();e.position=at;e.global_position=at;e.button_index=MOUSE_BUTTON_LEFT;e.pressed=pressed;Input.parse_input_event(e);Input.flush_buffered_events();await process_frame
 check(received==[[Core.HERO,"self_guard",Core.HERO,int(s.get_view().revision)]],"actual mouse event confirms exact command")
 for id in [Core.HERO+"_skills",Core.HERO+"_target",Core.HERO+"_confirm","resolve","retry","continue","leave"]:check(Rect2(Vector2.ZERO,Vector2(640,360)).encloses(p.slots[id].get_global_rect()),"640 control bounds "+id)
 p.queue_free();await process_frame
 print("Chapter thirteen combat: ",checks," checks, ",failures," failures")
 quit(1 if failures else 0)
