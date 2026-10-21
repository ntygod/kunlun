extends SceneTree
const P=preload("res://scripts/campaign/party_progression.gd")
const G=preload("res://scripts/campaign/progression.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func _initialize()->void:
 for id in [P.HUASHENG,P.XIAOSHUANG]:
  var internal:String="HS_N02" if id==P.HUASHENG else "HXS_N03"
  var old_internal:String="HS_N01" if id==P.HUASHENG else "HXS_N02"
  var base:Dictionary=G.actor_panel(id,39865,P.CH11_GEAR[id])
  var actor:Dictionary=P.newcore_panel(id,39865,P.CH11_GEAR[id],old_internal)
  actor.merge({"id":id,"kind":"core","status":"active","hp":321,"mp":17,"skills":[],"skill_ranks":{},"internal_skill":old_internal,"equipment":P.CH11_GEAR[id]},true)
  var actors:Dictionary={id:actor}
  check(P.equip_core_internal(actors,id,internal),"explicit internal upgrade "+id)
  check(actor.hp==321 and actor.mp==17,"upgrade never refills HP or MP")
  check(actor.panel_internal_skill==internal and internal in actor.learned_internals,"learned and panel agree")
  if id==P.HUASHENG:
   check(actor.max_hp==int(floor(base.max_hp*1.30)) and actor.atk==int(floor(base.atk*1.18)) and actor.spd==base.spd+6,"HS permanent panel exact")
   check(actor.def==base.def,"HS defense conversion not double baked")
  else:
   check(actor.max_hp==base.max_hp and actor.max_mp==int(floor(base.max_mp*1.35)) and actor.spd==base.spd+8,"X chapter-end internal panel exact")
   check(actor.def==base.def,"old N02 defense removed")
  var before:Dictionary=actors.duplicate(true)
  check(not P.equip_core_internal(actors,id,internal) and before==actors,"duplicate upgrade atomic")
  actor.hp=actor.max_hp;actor.mp=actor.max_mp
  check(P.newcore_panel(id,39865,P.CH11_GEAR[id],internal).max_hp==actor.max_hp,"panel deterministic")
 print("Chapter fifteen internal panels: ",checks," checks, ",failures," failures")
 quit(1 if failures else 0)
