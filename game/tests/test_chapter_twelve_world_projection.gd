extends SceneTree
const World=preload("res://scripts/world.gd")
const Model=preload("res://scripts/world_actions/chapter_twelve_world_actions.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func _initialize()->void:call_deferred("run")
func run()->void:
 for action in ["move_left","move_right","move_up","move_down"]:
  if not InputMap.has_action(action):InputMap.add_action(action)
 var maps:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(Model.MAP_PATH)).maps
 for mid in maps:
  var w=World.new();root.add_child(w)
  w.configure({"id":"projection","map_id":mid,"cast":["梁萧","花晓霜"]},Vector2(INF,INF),{"items":{},"world_objects":{}})
  check(not w.layout.is_empty(),"registered "+mid)
  var model=Model.new();model.layout=maps[mid]
  for y in range(64,289,16):
   for x in range(32,449,16):check(model.is_walkable(Vector2(x,y))==w.player.is_walkable(Vector2(x,y)),"physical collision "+mid+str(Vector2(x,y)))
  for id in maps[mid].sessions:
   var c:Dictionary=maps[mid].sessions[id]
   var context:Dictionary={"chapter":12,"revision":1,"current_token":"projection:"+id,"objective_id":id,"map_id":mid,"scene_id":c.scene_id,"phase":c.scene_id,"control_actor_id":c.control_actor_id,"world_objects":{}}
   check(model.begin(id,"projection",context),"begin "+id)
   w.scene_data.id=c.scene_id
   w.sync_controlled_view(model.get_view())
   check(w.player.actor_id==c.control_actor_id,"actual controlled actor")
   check(w.player.position==model._p(model.state.position),"actual projected feet")
   if w.cast_actors.has(c.control_actor_id):check(not w.cast_actors[c.control_actor_id].visible,"controlled actor has no duplicate NPC")
   if id=="world_ch12_healer_safety":
    for patient in [Model.H,Model.L,Model.LU]:check(w.cast_actors[patient].resting,"three incapacitated actual actors")
    check(not w.cast_actors.has(Model.S),"Huasheng absent from poison forest")
   if w.cast_actors.has(Model.L):
    w.runtime_context.dead_actor_ids=[Model.L];w.sync_controlled_view(model.get_view())
    check(not w.cast_actors[Model.L].visible,"canonical absent dead mask wins")
    w.runtime_context.dead_actor_ids=[]

   var saved_feet:=Vector2(80,256)
   w.player.position=saved_feet
   var before_context:Dictionary={"world_objects":{"ch12_spatial_state":model.get_view().world_state}}
   var presentation=load("res://scripts/chapter_twelve_world_presentation.gd")
   presentation.project(w,before_context)
   check(w.player.position==saved_feet,"history never overwrites navigation")
   w.player.actor_id="char_hua_xiaoshuang"
   presentation.project(w,before_context)
   check(w.player.actor_id=="char_hua_xiaoshuang","history never overrides controller")
   w.scene_data.id="unrelated_phase"
   if w.cast_actors.has(Model.L):w.cast_actors[Model.L].visible=false
   presentation.project(w,before_context)
   if w.cast_actors.has(Model.L):check(not w.cast_actors[Model.L].visible,"stale phase cannot reintroduce Liu")

   await process_frame
  w.queue_free();await process_frame
 await sparse_battles()
 print("Chapter twelve projection: ",checks," checks, ",failures," failures");quit(1 if failures else 0)

func sparse_battles()->void:
 var Core=load("res://scripts/combat/chapter_twelve_engine.gd")
 var Session=load("res://scripts/combat/chapter_twelve_encounter.gd")
 var Fixture=load("res://tests/test_chapter_twelve_combat.gd")
 var rules:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/combat_rules.json"))
 var runtime:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/combat_runtime.json"))
 for id in Core.IDS:
  var cfg:Dictionary=Core.encounter_config(id)
  var mid:String="map_ch12_chiyou_clearing" if cfg.kind=="medicine" else "map_ch12_arena"
  cfg.context={"chapter":12,"map_id":mid,"current_token":"projection:"+id,"poison_authorized":true}
  var party:Array=[]
  var ids:Array={"han":[Core.X],"lei":[Core.HS],"chu":[Core.HERO],"medicine":[Core.HERO,Core.X,Core.LIU]}[cfg.kind]
  for who in ids:party.append(Fixture.fixture(who,29640 if cfg.kind=="medicine" else 25970))
  var battle=Session.new(rules,runtime,cfg,party,cfg.context.current_token)
  check(battle.engine.entry_error=="","actual battle begins "+id)
  var v:Dictionary=battle.get_view()
  var w=World.new();root.add_child(w)
  var controller:String=v.world_state.control_actor_id
  w.configure({"id":"battle_projection","map_id":mid,"cast":["梁萧","花晓霜","柳莺莺","花生","韩凝紫","雷行空","楚仙流","骆明绮"]},Vector2(64,256),{"controller_id":controller,"items":{},"world_objects":{}})
  var before:Dictionary={}
  for actor in w.cast_actors:before[actor]=w.cast_actors[actor].visible
  var observer:String=Core.LIU
  w.cast_actors[observer].resting=true
  var feet:Vector2=w.player.position
  w.sync_controlled_view(v)
  check(w.player.actor_id==controller and w.player.position==feet,"sparse battle controller without warp")
  for actor in before:check(w.cast_actors[actor].visible==before[actor],"sparse battle preserves cast "+id+actor)
  check(w.cast_actors[observer].resting,"sparse battle preserves injury posture")
  check(not w.cast_actors[controller].visible,"battle controller no NPC duplicate")
  w.runtime_context.dead_actor_ids=[observer];w.sync_controlled_view(v)
  check(not w.cast_actors[observer].visible,"sparse battle still honors death mask")
  await process_frame;w.queue_free();await process_frame
