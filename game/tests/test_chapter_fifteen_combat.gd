extends SceneTree
const Core=preload("res://scripts/combat/chapter_fifteen_engine.gd")
const Session=preload("res://scripts/combat/chapter_fifteen_encounter.gd")
const Driver=preload("res://tests/chapter_fifteen_encounter_driver.gd")
const Party=preload("res://scripts/campaign/party_progression.gd")
const Growth=preload("res://scripts/campaign/progression.gd")
const Same=preload("res://scripts/campaign/encounter_session.gd")
const BattlePanel=preload("res://scripts/ui/chapter_fifteen_battle_panel.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error(label)
static func party_fixture()->Array:
 var source:=OS.get_environment("CH15_BATTLE_ENTRY")
 if not source.is_empty():return JSON.parse_string(FileAccess.get_file_as_string(source)).party
 var result:Array=[]
 for who in [Core.X,Core.HS]:
  var a:Dictionary=Growth.actor_panel(who,39865,Party.CH11_GEAR[who])
  var x:bool=who==Core.X;var active:Array=["HXS_A01","HXS_A02","HXS_A07","HXS_A04"] if x else ["HS_A01","HS_A06","HS_A02","HS_A04"]
  a.max_hp=int(floor(a.max_hp*(1.2 if x else 1.3)))
  if x:a.def=int(floor(a.def*1.15))
  else:a.atk=int(floor(a.atk*1.18));a.spd+=6
  a.merge({"id":who,"team":"party","hp":a.max_hp,"mp":20,"fixed_level":68,"skills":["normal_attack","self_guard","guard_ally"]+active,"equipped_active_skills":active,"skill_ranks":{},"passives":["HXS_P01"] if x else ["HS_P01","HS_P02"],"learned_passives":["HXS_P01","HXS_P02","HXS_P03"] if x else ["HS_P01","HS_P02","HS_P03"],"internal_skill":"HXS_N02" if x else "HS_N02","panel_internal_skill":"HXS_N02" if x else "HS_N02","internal_stats_applied":true},true)
  for id in active:a.skill_ranks[id]=1
  result.append(a)
 return result
static func encounter_fixture(token:String)->Dictionary:
 var config:=Core.encounter_config();var source:=OS.get_environment("CH15_BATTLE_ENTRY")
 config.context=JSON.parse_string(FileAccess.get_file_as_string(source)).context if not source.is_empty() else {"chapter":15,"current_token":token}
 return config
func _initialize()->void:call_deferred("run")
func run()->void:
 var rules:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/combat_rules.json"));var runtime:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/combat_runtime.json"))
 var config:=encounter_fixture("b12_test")
 var party:=party_fixture();var s=Session.new(rules,runtime,config,party,str(config.context.current_token))
 check(s.engine.entry_error=="","valid healer/huasheng entry")
 if failures:quit(1);return
 check(s.engine.actor_by_id(Core.X).mp==party[0].max_mp,"independent battle starts fullMP")
 check(s.engine.validate_command(Core.X,"CO_04",Core.HE)!="","no premature trial")
 for i in range(20):
  if s.get_view().outcome!="":break
  var before:Dictionary=s.snapshot()
  check(s.set_command(Core.X,"CO_04",Core.HE,int(s.get_view().revision)-1)!="" and s.snapshot()==before,"stale atomic")
  for c in Driver.commands(s):check(s.set_command(c[0],c[1],c[2])=="","legal manual medical command")
  var clone=Session.from_snapshot(JSON.parse_string(JSON.stringify(s.snapshot())),rules,runtime)
  check(clone!=null and Same.equivalent(clone.snapshot(),s.snapshot()),"every pending JSON restore")
  check(s.resolve_round(),"resolve actual round")
  if s.get_view().round==3:
   check(s.get_view().objective.combo_trial and s.get_view().objective.synergy>=2,"third round trial before commands")
   check(s.engine.actor_by_id(Core.HE).protected_through>=3,"effective break protection extends third round")
  if s.get_view().objective.phase==2 and s.get_view().round==4:
   check(s.get_view().objective.seals==1,"phase1 one seal")
   check(s.engine.actor_by_id(Core.X).mp<party[0].max_mp,"transition does not refill partyMP")
 check(s.get_view().outcome=="victory" and s.get_view().objective.seals==2,"two real medical loops win")
 print("B12 entry ",party.map(func(a):return [a.id,a.hp,a.max_hp,a.mp,a.max_mp])," final ",s.final_party())
 check(s.engine.actor_by_id(Core.HE).hp>=1 and s.engine.actor_by_id(Core.HE).defeated,"enemy alive nonlethal")
 check(s.get_view().round==7,"six completed rounds")
 var proof:Dictionary=s.receipt();check(not Session.replay_receipt(proof,rules,runtime,config,party).is_empty(),"strict victory receipt")
 var forged:Dictionary=proof.duplicate(true);forged.final_actors[0].hp+=1
 check(Session.replay_receipt(forged,rules,runtime,config,party).is_empty(),"forgedHP rejected")
 var heals:=0;var seals:=0;var third_actions:=0
 for e in s.get_view().events:
  if e.type=="postbattle_heal":heals+=1
  if e.type=="medical_seal" and e.detail.protected:seals+=1
  if e.type=="enemy_action" and e.round in [3,6]:third_actions+=1
 check(heals==2 and seals==2 and third_actions==2,"equippedP01 once and protected combos retain enemy actions")
 var saved:Dictionary=s.snapshot();s.engine._check_outcome();check(s.snapshot()==saved,"victory idempotent")
 s.retry();check(s.get_view().round==1 and s.engine.actor_by_id(Core.X).hp==party[0].hp,"retry restores original HP")
 var unkind:Array=party.duplicate(true);unkind[0].passives=[]
 var noheal=Session.new(rules,runtime,config,unkind,str(config.context.current_token));check(Driver.run(noheal),"withoutP01 still legal")
 check(not noheal.get_view().objective.postheal,"no unequipped postheal")
 await ui(s)
 print("Chapter fifteen combat: ",checks," checks, ",failures," failures")
 quit(1 if failures else 0)
func ui(s:RefCounted)->void:
 root.size=Vector2i(640,360)
 var panel:=BattlePanel.new();root.add_child(panel);panel.position=Vector2(4,4);panel.size=Vector2(632,352)
 panel.render(s.get_view(),{},s.can_resolve());await process_frame;await process_frame
 check(Rect2(Vector2.ZERO,Vector2(640,360)).encloses(panel.slots.resolve.get_global_rect()),"640 resolve fits")
 check(panel.slots.has(Core.X+"_skills") and panel.slots.has(Core.HS+"_skills"),"both combatants controls")
 check(panel.slots[Core.X+"_skills"].item_count==7,"four equipped plus basic actions")
 var received:Array=[]
 panel.command_requested.connect(func(actor,skill,target,revision):received.append([actor,skill,target,revision]))
 var confirm:Button=panel.slots[Core.X+"_confirm"]
 var at:Vector2=confirm.get_global_rect().get_center()
 for pressed in [true,false]:
  var e:=InputEventMouseButton.new();e.position=at;e.global_position=at;e.button_index=MOUSE_BUTTON_LEFT;e.button_mask=MOUSE_BUTTON_MASK_LEFT if pressed else 0;e.pressed=pressed;Input.parse_input_event(e);Input.flush_buffered_events();await process_frame
 check(received.size()==1 and received[0][0]==Core.X and received[0][2]==Core.HE,"640 actual mouse command signal")
 panel.slots[Core.HS+"_confirm"].grab_focus();await process_frame
 for pressed in [true,false]:
  var e:=InputEventKey.new();e.keycode=KEY_ENTER;e.physical_keycode=KEY_ENTER;e.pressed=pressed;Input.parse_input_event(e);Input.flush_buffered_events();await process_frame
 check(received.size()==2 and received[1][0]==Core.HS,"actual Return command signal")
 panel.queue_free();await process_frame
