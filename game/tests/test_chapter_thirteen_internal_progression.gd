extends SceneTree
const Party=preload("res://scripts/campaign/party_progression.gd")
const Growth=preload("res://scripts/campaign/progression.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func _initialize()->void:
 var actors:Dictionary={}
 for id in [Party.HERO,Party.LIU]:
  var a:Dictionary=Growth.actor_panel(id,31565,{})
  a.merge({"hp":100,"mp":20,"skills":[],"skill_ranks":{},"internal_skill":"LX_N01" if id==Party.HERO else "LYY_N01","status":"active"})
  actors[id]=a
 var old:=actors.duplicate(true);var ledger:Dictionary={}
 check(Party.award(actors,ledger,"old_growth",100),"old internal growth succeeds")
 for id in actors:
  var expected:Dictionary=Growth.actor_panel(id,31665,{})
  check(actors[id].max_hp==expected.max_hp and actors[id].max_mp==expected.max_mp and actors[id].atk==expected.atk and actors[id].def==expected.def,"old chapter panel unchanged")
 actors=old.duplicate(true);ledger.clear()
 for pair in [[Party.HERO,"LX_N02"],[Party.LIU,"LYY_N02"]]:
  var id:String=pair[0]
  check(Party.equip_core_internal(actors,id,pair[1]),"upgrade new internal")
  check(actors[id].hp==100 and actors[id].mp==20,"upgrade does not refill current resources")
  var snapshot:=JSON.stringify(actors)
  check(not Party.equip_core_internal(actors,id,pair[1]) and JSON.stringify(actors)==snapshot,"repeat upgrade atomic")
 check(actors[Party.HERO].max_hp==int(floor(old[Party.HERO].max_hp*1.18)) and actors[Party.HERO].max_mp==int(floor(old[Party.HERO].max_mp*1.25)) and actors[Party.HERO].def==int(floor(old[Party.HERO].def*1.12)),"whale permanent multipliers")
 check(actors[Party.LIU].atk==int(floor(old[Party.LIU].atk*1.15)) and actors[Party.LIU].max_mp==int(floor(old[Party.LIU].max_mp*1.20)),"Liu permanent multipliers")
 var maxima:Dictionary={}
 for id in actors:maxima[id]=actors[id].max_hp
 check(Party.award(actors,ledger,"new_growth",500),"new internal growth")
 for id in actors:
  var expected:=Party.newcore_panel(id,32065,{},actors[id].internal_skill)
  check(actors[id].max_hp==expected.max_hp and actors[id].max_mp==expected.max_mp and actors[id].atk==expected.atk and actors[id].def==expected.def,"growth preserves internal once")
  check(actors[id].hp==100+expected.max_hp-maxima[id] and actors[id].mp==20,"growth preserves missing HP and current MP")
 var snapshot:=JSON.stringify(actors)
 check(not Party.award(actors,ledger,"new_growth",500) and JSON.stringify(actors)==snapshot,"duplicate reward atomic")
 print("Chapter thirteen internal progression: ",checks," checks, ",failures," failures")
 quit(1 if failures else 0)
