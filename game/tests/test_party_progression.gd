extends SceneTree
const Growth=preload("res://scripts/campaign/progression.gd")
const Party=preload("res://scripts/campaign/party_progression.gd")
const Canonical=preload("res://scripts/campaign/bounded_save_codec.gd")
var checks:=0
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,label: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func run() -> void:
 for level in range(1,81):
  var xp:=Growth.threshold(level)
  var x:=39.0*float(level-1)/79.0
  var liang:=Growth.liang_panel(xp)
  check(liang.level==level,"level threshold")
  check(liang.max_hp==int(floor(150+38*x+0.45*x*x)),"unchanged Liang HP")
  check(liang.max_mp==int(floor(45+3.8*x)),"unchanged Liang MP")
  check(liang.atk==int(floor(24+5.6*x+0.06*x*x)),"unchanged Liang ATK")
  check(liang.def==int(floor(14+3.4*x+0.04*x*x)),"unchanged Liang DEF")
  check(liang.spd==int(floor(14+1.25*x)),"unchanged Liang SPD")
  var liu:=Growth.actor_panel(Party.LIU,xp)
  check(liu.max_hp==int(floor(135+33*x+0.38*x*x)),"Liu HP source")
  check(liu.max_mp==int(floor(40+3.4*x)),"Liu MP source")
  check(liu.atk==int(floor(23+5.3*x+0.055*x*x)),"Liu ATK source")
  check(liu.def==int(floor(11+2.8*x+0.03*x*x)),"Liu DEF source")
  check(liu.spd==int(floor(17+1.55*x)),"Liu SPD source")
 check(Growth.actor_panel("npc_jiu_ru",9999).is_empty(),"support has no growth")
 for old_sides in range(4):
  for new_sides in range(4):
   var base_xp:=2470+(400 if old_sides&1 else 0)+(250 if old_sides&2 else 0)
   var hero:=Growth.liang_panel(base_xp,{"max_hp":30,"max_mp":5,"atk":8,"def":5,"spd":1})
   hero.hp=1;hero.mp=0
   var actors:Dictionary={Party.HERO:hero}
   var ledger:Dictionary={}
   check(Party.award(actors,ledger,"pursuit",300),"prejoin reward")
   check(Party.recruit_liu(actors),"recruit once")
   var liu:Dictionary=actors[Party.LIU]
   check(liu.xp==base_xp+300 and liu.joined_at_xp==base_xp+300,"join copies current XP once")
   liu.hp=5;liu.mp=3;liu.status="asleep"
   check(not Party.recruit_liu(actors) and liu.hp==5,"rejoin cannot heal sleeping Liu")
   var hero_hp:int=hero.hp
   check(Party.refit(actors,Party.HERO) and hero.hp==hero_hp and hero.mp==0,"gear replaces without healing")
   check(Party.refit(actors,Party.LIU) and liu.hp==5 and liu.mp==3,"Liu gear clamp only")
   check(hero.equipment==Party.CH04_GEAR[Party.HERO] and liu.equipment==Party.CH04_GEAR[Party.LIU],"gear not stacked")
   check(not Party.refit(actors,Party.LIU),"gear idempotent")
   check(Party.award(actors,ledger,"rest_of_main",1695),"remaining budget both actors")
   if new_sides&1:check(Party.award(actors,ledger,"R02",400),"R02 reward")
   if new_sides&2:check(Party.award(actors,ledger,"L01",300),"L01 reward")
   var final_xp:=base_xp+1995+(400 if new_sides&1 else 0)+(300 if new_sides&2 else 0)
   check(hero.xp==final_xp and liu.xp==final_xp,"independent XP same budget not doubled")
   check(liu.mp==3 and hero.mp==0,"level does not invent MP recovery")
   var before:Dictionary=actors.duplicate(true)
   check(not Party.award(actors,ledger,"rest_of_main",1695) and Canonical.equivalent(before,actors),"reward retry atomic")
   var ids:=[Party.HERO,Party.LIU]
   for bad in [[{"id":Party.HERO,"hp":1,"mp":0}],[{"id":Party.HERO,"hp":1,"mp":0},{"id":Party.HERO,"hp":1,"mp":0}],[{"id":Party.HERO,"hp":1,"mp":0},{"id":Party.LIU,"hp":999999,"mp":0}],[{"id":Party.HERO,"hp":1,"mp":0},{"id":Party.LIU,"hp":true,"mp":0}]]:
    check(not Party.accept_resources(actors,bad,ids),"bad battle party rejected")
    check(Canonical.equivalent(before,actors),"both actor resources atomic")
   check(Party.accept_resources(actors,[{"id":Party.HERO,"hp":7,"mp":2},{"id":Party.LIU,"hp":9,"mp":4}],ids),"both actor resources accepted")
   check(hero.hp==7 and hero.mp==2 and liu.hp==9 and liu.mp==4,"both resources written")
 print("Party progression: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
