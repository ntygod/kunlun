extends SceneTree
const Model=preload("res://scripts/world_actions/chapter_ten_world_actions.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func fixture(id:String)->Dictionary:
 var maps:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(Model.MAP_PATH)).maps
 for mid in maps:
  if maps[mid].sessions.has(id):
   var c:Dictionary=maps[mid].sessions[id]
   return {"chapter":10,"revision":1,"current_token":"ch10-test:"+id,"objective_id":id,"map_id":mid,"control_actor_id":c.control_actor_id,"scene_id":c.scene_id,"phase":c.scene_id,"world_objects":{},"actors":{},"items":{},"choices":{},"inherited_choices":{},"knowledge":[]}
 return {}
func _initialize()->void:
 for id in Model.IDS:
  var c:=fixture(id);var model=Model.new();check(model.begin(id,"attempt",c),"begin "+id)
  var old:Dictionary=model.snapshot()
  for action in [{"type":"move","dx":true,"dy":0},{"type":"move","dx":2,"dy":0},{"type":"hold","milliseconds":100000},{"type":"linger","milliseconds":-1},{"type":"complete"},{"type":"interact","success":true}]:
   check(not model.apply_input(action).ok,"bad command "+str(action));check(Model._encoded(old)==Model._encoded(model.snapshot()),"bad input atomic")
  var wrong:Dictionary=c.duplicate(true);wrong.control_actor_id="char_axue" if c.control_actor_id==Model.H else Model.H
  check(not model.begin(id,"bad",wrong),"actor bound");check(Model._encoded(old)==Model._encoded(model.snapshot()),"begin atomic")
  check(not model.apply_input({"type":"interact"}).ok or id=="world_ch10_rescue","no remote completion")
  for i in range(1200):
   if model.state.complete:break
   var action:Dictionary=model.next_demo_action();check(not action.is_empty(),"route exists "+id)
   if action.is_empty():break
   check(model.apply_input(action).ok,"legal path "+id+" "+str(action))
   check(model.is_walkable(model._p(model.state.position)),"feet walkable")
   if i%47==0:
    var snapshot:Dictionary=JSON.parse_string(JSON.stringify(model.snapshot()));var restored=Model.new()
    check(restored.restore(snapshot,c),"JSON partial replay "+id)
    check(Model._encoded(restored.snapshot())==Model._encoded(model.snapshot()),"partial identical")
    var corrupt:Dictionary=snapshot.duplicate(true);corrupt.state.complete=true
    if not model.state.complete:check(not restored.restore(corrupt,c),"cannot inject solved")
  check(model.state.complete,"complete "+id)
  check(not Model.replay_receipt(JSON.parse_string(JSON.stringify(model.receipt())),c).is_empty(),"receipt replays "+id)
  check(not model.apply_input({"type":"interact"}).ok,"duplicate completion denied")
  if id=="world_ch10_escort_children":
   check(model.state.actor_paths.npc_chu_wan.size()>1 and model.state.actor_paths.npc_zhao_shi.size()>1,"children actually followed")
   check(model._escort_ready(),"children arrive safely before completion")
  if id=="world_ch10_axue_return":check(model.state.clues==["reeds","hooves","cloth"],"actual three clues");check(model.state.control_actor_id==Model.A,"Axue alone")
  if id=="world_ch10_friends":check(model.state.safe_friends.size()==5,"five safe not killed")
  if id=="world_ch10_farewell":check(model.get_view().options.is_empty(),"no choice menu");check(model.state.stage==2,"both held actions")
  if id=="world_ch10_river_release":check(Model.A not in model.state.visible_actor_ids and not model.state.actor_positions.has(Model.A),"river no ghost")
  if id=="world_ch10_shore_walk":check(model.state.active_ms>=60000,"sixty active seconds");check(model._near("exit"),"actual shore end")
  if id=="world_ch10_recollection":check(model.state.recollection,"real linger path")
 var continuation:=fixture("world_ch10_escort_children")
 continuation.world_objects.ch10_spatial_state={"map_id":"map_ch10_pass","control_actor_id":Model.H,"player_position":[144,224]}
 var follow=Model.new();check(follow.begin("world_ch10_escort_children","follow",continuation),"same-map continuation")
 check(follow.state.position==[144,224],"previous feet preserved")
 var before:Dictionary=follow.snapshot();continuation.world_objects.ch10_spatial_state.player_position=[true,224]
 check(not follow.begin("world_ch10_escort_children","invalid",continuation),"invalid prior feet denied")
 check(Model._encoded(before)==Model._encoded(follow.snapshot()),"prior failure atomic")
 var rec=Model.new();check(rec.begin("world_ch10_recollection","leave",fixture("world_ch10_recollection")),"optional begin");check(rec.apply_input({"type":"leave"}).ok and rec.state.complete and not rec.state.recollection,"optional leave not fake recollection")
 var shore=Model.new();check(shore.begin("world_ch10_shore_walk","short",fixture("world_ch10_shore_walk")),"shore begin")
 check(not shore.apply_input({"type":"move","dx":1,"dy":0}).ok,"no fast grid skip")
 for i in range(239):check(shore.apply_input({"type":"walk","dx":1,"dy":0,"milliseconds":250}).ok,"actual movement")
 check(not shore.apply_input({"type":"interact"}).ok and not shore.state.complete,"59.75 seconds cannot exit")
 check(shore.apply_input({"type":"walk","dx":1,"dy":0,"milliseconds":250}).ok,"sixty seconds")
 check(shore.apply_input({"type":"interact"}).ok and shore.state.complete,"sixty seconds and location")
 print("Chapter ten world: ",checks," checks, ",failures," failures");quit(1 if failures else 0)
