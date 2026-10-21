extends SceneTree
const Core=preload("res://scripts/combat/chapter_twelve_engine.gd")
const Session=preload("res://scripts/combat/chapter_twelve_encounter.gd")
const Fixture=preload("res://tests/test_chapter_twelve_combat.gd")
const BattlePanel=preload("res://scripts/ui/chapter_twelve_battle_panel.gd")
const Same=preload("res://scripts/campaign/encounter_session.gd")
var checks:=0
var failures:=0
var commands:Array=[]
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func _initialize()->void:call_deferred("run")
func key(code:Key)->void:
 var e:=InputEventKey.new();e.keycode=code;e.physical_keycode=code;e.pressed=true;Input.parse_input_event(e);await process_frame
 e=InputEventKey.new();e.keycode=code;e.physical_keycode=code;e.pressed=false;Input.parse_input_event(e);await process_frame
func click(c:Control)->void:
 var pos:=c.get_global_rect().get_center()
 var motion:=InputEventMouseMotion.new();motion.position=pos;Input.parse_input_event(motion);await process_frame
 var e:=InputEventMouseButton.new();e.position=pos;e.button_index=MOUSE_BUTTON_LEFT;e.pressed=true;Input.parse_input_event(e);await process_frame
 e=InputEventMouseButton.new();e.position=pos;e.button_index=MOUSE_BUTTON_LEFT;e.pressed=false;Input.parse_input_event(e);await process_frame
func run()->void:
 root.size=Vector2i(640,360);root.gui_embed_subwindows=true
 var rules:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/combat_rules.json"));var runtime:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/combat_runtime.json"))
 for pair in [[Core.IDS[1],Core.HS,"HS_A01"],[Core.IDS[2],Core.HERO,Core.POEMS[0]],[Core.IDS[3],Core.X,"HXS_A02"]]:
  var cfg:=Core.encounter_config(pair[0]);cfg.context={"chapter":12,"current_token":"input_"+pair[0],"poison_authorized":true,"combo_unlocks":["CO_01","CO_02"]}
  var party:Array=[]
  for who in ([Core.HERO,Core.X,Core.LIU] if cfg.kind=="medicine" else [pair[1]]):party.append(Fixture.fixture(who,29640 if cfg.kind=="medicine" else 25970))
  var s=Session.new(rules,runtime,cfg,party,cfg.context.current_token)
  var p=BattlePanel.new();p.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);root.add_child(p)
  p.command_requested.connect(func(a,b,c,_r):commands.append([a,b,c]))
  p.render(s.get_view(),{},s.can_resolve());await process_frame;await process_frame
  var options:OptionButton=p.slots[pair[1]+"_skills"]
  var selected:=-1
  for n in range(options.item_count):
   if options.get_item_metadata(n)==pair[2]:selected=n
  check(selected>=0,"skill visible "+pair[2])
  # The dropdown is opened by a physical mouse event, then selected by keyboard.
  await click(options)
  await key(KEY_HOME)
  for n in range(selected+1):await key(KEY_DOWN)
  await key(KEY_ENTER)
  check(options.get_item_metadata(options.selected)==pair[2],"actual popup keys "+pair[2])
  var count:=commands.size();var confirm:Button=p.slots[pair[1]+"_confirm"]
  await click(confirm)
  check(commands.size()==count+1 and commands[-1][1]==pair[2],"actual confirm mouse "+pair[2])
  if cfg.kind=="medicine":
   var before:=s.snapshot();var inspect:Button=p.slots.inspect_herbs
   await click(inspect)
   check(p.slots.herb_observation.visible,"actual inspect click opens textual clues")
   check(Same.equivalent(before,s.snapshot()),"inspect consumes no state or action")
   inspect.grab_focus();await key(KEY_ENTER)
   check(not p.slots.herb_observation.visible,"actual inspect Return toggles")
  check(p.slots.resolve.get_global_rect().end.y<=360 and p.slots.leave.get_global_rect().end.x<=640,"640 controls within viewport")
  count=commands.size();p.hide();await key(KEY_ENTER);check(commands.size()==count,"hidden panel ignores Return")
  p.queue_free();await process_frame
 print("Chapter12 battle input: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
