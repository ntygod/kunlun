extends SceneTree
const Core=preload("res://scripts/combat/chapter_fourteen_engine.gd")
const Session=preload("res://scripts/combat/chapter_fourteen_encounter.gd")
const Driver=preload("res://tests/chapter_fourteen_encounter_driver.gd")
const Party=preload("res://scripts/campaign/party_progression.gd")
const Same=preload("res://scripts/campaign/encounter_session.gd")
const BattlePanel=preload("res://scripts/ui/chapter_fourteen_battle_panel.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error(label)
static func party_fixture()->Array:
 var result:Array=[]
 for id in [Core.HERO,Core.HS]:
  var internal:String="LX_N02" if id==Core.HERO else "HS_N01"
  var a:Dictionary=Party.newcore_panel(id,35595,Party.CH11_GEAR[id],internal)
  a.merge({"id":id,"team":"party","hp":a.max_hp,"mp":20,"fixed_level":64,"skills":["normal_attack","self_guard","guard_ally"],"skill_ranks":{"LX_A01":3,"LX_A02":3,"LX_A03":3,"LX_A04":2,"LX_A05":1,"LX_N02":1} if id==Core.HERO else {"HS_A01":2,"HS_A02":2,"HS_A03":1,"HS_A04":1,"HS_A05":1,"HS_N01":1},"equipped_active_skills":["LX_A01","LX_A03","LX_A04","LX_A05"] if id==Core.HERO else ["HS_A02","HS_A04","HS_A03","HS_A05"],"passives":["LX_P01","LX_P03"] if id==Core.HERO else ["HS_P01","HS_P02"],"learned_passives":["LX_P01","LX_P03"] if id==Core.HERO else ["HS_P01","HS_P02"],"internal_skill":internal,"panel_internal_skill":internal,"internal_stats_applied":true},true)
  for skill in a.equipped_active_skills:a.skills.append({"LX_A01":"observe","LX_A02":"sancai_counter"}.get(skill,skill))
  result.append(a)
 return result
func _initialize()->void:call_deferred("run")
func run()->void:
 var rules:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/combat_rules.json"));var runtime:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/combat_runtime.json"))
 var cfg:=Core.encounter_config();cfg.context={"chapter":14,"current_token":"b11_test"}
 var party:=party_fixture()
 var entry_path:=OS.get_environment("CH14_BATTLE_ENTRY")
 var entry_hash:=""
 if not entry_path.is_empty():
  entry_hash=FileAccess.get_sha256(entry_path)
  var entry:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(entry_path));party=entry.party
  print("Actual campaign party source ",entry_path," SHA256 ",entry_hash)
 var s=Session.new(rules,runtime,cfg,party,"b11_test")
 check(s.engine.entry_error=="","valid brothers party")
 if failures:print(s.engine.entry_error);quit(1);return
 check(s.engine.actor_by_id(Core.HERO).max_hp==party[0].max_hp,"internal panel unchanged")
 var phase_seen:=false
 for i in range(100):
  if s.get_view().outcome!="":break
  var phase:int=s.get_view().objective.phase
  for c in Driver.commands(s):check(s.set_command(c[0],c[1],c[2])=="","legal actual strategy")
  if i==0 or (phase==2 and not phase_seen):check(Session.from_snapshot(JSON.parse_string(JSON.stringify(s.snapshot())),rules,runtime)!=null,"pending replay")
  phase_seen=phase_seen or phase==2
  check(s.resolve_round(),"settle actual round")
  if failures:break
 print("B11 rounds ",s.engine.state.round," outcome ",s.engine.state.outcome," HP ",s.engine.actor_by_id(Core.HERO).hp," ",s.engine.actor_by_id(Core.HS).hp)
 check(s.get_view().outcome=="victory","natural strategy wins")
 check(s.get_view().objective.combo_trial and s.get_view().objective.nodes.size()>=2 and s.get_view().objective.wheels_collapsed,"both nodes then four wheels")
 for id in Core.MONKS:check(s.engine.actor_by_id(id).hp==1 and s.engine.actor_by_id(id).defeated,"monk lives unable to act")
 check(not Session.replay_receipt(s.receipt(),rules,runtime,cfg,party).is_empty(),"exact victory replay")
 var before:=s.snapshot();var forged:=s.snapshot();forged.state.objective.nodes=[]
 check(not s.restore(forged) and Same.equivalent(before,s.snapshot()),"tampered proof atomic rejection")
 # Explicit bounded mechanics fixtures, not natural saves.
 s.retry();var e=s.engine;var monk:Dictionary=e.actor_by_id(Core.MASTER)
 for channel in ["normal","counter","reflection","dot","mechanism"]:
  monk.hp=5;monk.defeated=false;e._lose_hp(e.actor_by_id(Core.HERO),monk,100)
  check(monk.hp==1 and monk.defeated,"nonlethal HP gate "+channel)
  check(e._lose_hp(e.actor_by_id(Core.HERO),monk,100)==0,"defeated cannot be hit twice")
 s.retry();e=s.engine
 check(s.set_command(Core.HERO,"normal_attack","npc_innocent")!="","innocent not selectable")
 var innocent:Dictionary={"id":"npc_innocent","innocent":true};e._lose_hp(e.actor_by_id(Core.HERO),innocent,1)
 check(e.state.outcome=="defeat" and not e.state.objective.innocents_safe,"scenario innocent harm fails")
 s.retry();e=s.engine
 var phase_resources:Array=[]
 for who in [Core.HERO,Core.HS]:
  var a:Dictionary=e.actor_by_id(who);a.hp-=80;a.mp=17;a.ready["test_cd"]=99;phase_resources.append([a.hp,a.mp,a.ready.duplicate(true)])
 for id in Core.MONKS:e.actor_by_id(id).hp=1;e.actor_by_id(id).defeated=true
 e.state.mode="round_end";e._check_outcome()
 check(e.state.objective.phase==2 and e.state.objective.synergy==2,"phase2 trial granted before command phase")
 for n in range(2):
  var a:Dictionary=e.actor_by_id([Core.HERO,Core.HS][n]);check(Same.equivalent(phase_resources[n],[a.hp,a.mp,a.ready]),"phase does not refill resources or cooldowns")
 e.begin_round()
 check(s.set_command(Core.HERO,"CO_05",Core.WHEELS[0])=="","early combo may execute but cannot bypass nodes")
 check(e.state.commands.size()==2 and e.state.objective.reserved==2,"combo reserves both slots exactly two")
 check(s.apply_input({"actor_id":Core.HERO,"action_id":"cancel"}).accepted and e.state.objective.synergy==2,"cancel refunds once")
 s.apply_input({"actor_id":Core.HERO,"action_id":"cancel"});check(e.state.objective.synergy==2,"repeated cancel cannot generate synergy")
 check(s.set_command(Core.HERO,"CO_05",Core.WHEELS[0])=="" and s.resolve_round(),"early actual combo round resolves")
 check(not e.state.objective.wheels_collapsed,"no free wheel collapse before two broken nodes")
 check(e._lose_hp(e.actor_by_id(Core.HERO),e.actor_by_id(Core.WHEELS[0]),999999)>=0 and not e.actor_by_id(Core.WHEELS[0]).defeated,"normal damage cannot erase node objective")
 check(e.validate_command(Core.HERO,"normal_attack",Core.ARRAY)=="wheel_shield_locked","boss unselectable before collapse")
 var bad_party:=party.duplicate(true);bad_party[1].skills.append("HS_A01");bad_party[1].equipped_active_skills.append("HS_A01")
 check(Session.new(rules,runtime,cfg,bad_party,"b11_test").engine.entry_error!="","fifth slot rejected")
 check(s.set_command(Core.HS,"HS_A04",Core.MASTER)!="","friendly shield cannot target enemy")
 # Two ordinary attack channels and scenario DOT/reflection converge on lethal gate.
 for channel in ["normal","counter","reflection","mechanism"]:
  var t:Dictionary=e.actor_by_id(Core.MASTER);t.hp=2;t.defeated=false;e._damage_action(e.actor_by_id(Core.HERO),t,100,false,channel,"bounded_test")
  check(t.hp==1 and t.defeated,"full damage branch nonlethal "+channel)
 e.state.objective.wheels_collapsed=true;e.actor_by_id(Core.ARRAY).hp=1;e.actor_by_id(Core.ARRAY).defeated=true
 e.actor_by_id(Core.HERO).hp=123;e.actor_by_id(Core.HS).hp=0;e.actor_by_id(Core.HS).defeated=true;e.state.mode="round_end";e._check_outcome()
 check(e.state.outcome=="victory" and e.actor_by_id(Core.HERO).hp==123,"surviving brother gets no invented postbattle heal")
 check(e.actor_by_id(Core.HS).hp==int(e.actor_by_id(Core.HS).max_hp*.2) and not e.actor_by_id(Core.HS).defeated,"fallen brother revives with20percent")
 s.retry();var panel:=BattlePanel.new();root.add_child(panel);root.size=Vector2i(640,360);panel.position=Vector2(10,10);panel.size=Vector2(620,340);panel.render(s.get_view(),{},false);await process_frame;await process_frame
 check(panel.get_node_or_null("heading")!=null,"actual battle panel heading")
 check(panel.slots[Core.HERO+"_target"].get_item_text(0)!="char_liang_xiao","target uses label")
 for key in [Core.HERO+"_skills",Core.HERO+"_target",Core.HERO+"_confirm",Core.HS+"_skills",Core.HS+"_target",Core.HS+"_confirm","resolve","retry","continue","leave"]:
  var rect:Rect2=panel.slots[key].get_global_rect();check(rect.position.x>=0 and rect.end.x<=640 and rect.position.y>=0 and rect.end.y<=360,"640 actual control rectangle "+key)
 check(s.set_command("unknown","normal_attack",Core.MASTER)!="","unknown actor safely rejected")
 panel.queue_free();await process_frame
 if not entry_path.is_empty():check(FileAccess.get_sha256(entry_path)==entry_hash,"actual entry remains unchanged")
 print("Chapter14 combat: ",checks," checks, ",failures," failures")
 quit(1 if failures else 0)
