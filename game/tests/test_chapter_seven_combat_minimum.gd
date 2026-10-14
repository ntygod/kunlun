extends "res://tests/chapter_seven_minimum_source.gd"
const SevenSession=preload("res://scripts/combat/chapter_seven_encounter.gd")
const SevenDriver=preload("res://tests/chapter_seven_battle_driver.gd")
## Real validated chapter6 history, then explicit contract transactions. Full chapter7
## narrative integration is separately tested; this doesn't claim its GUI or all variants.
func after_source(c:RefCounted) -> void:
 var actors:Dictionary=c.actors.duplicate(true)
 var ledger:Dictionary={}
 for pair in [["roll",75],["grain",100],["campfire",75]]:Party.award(actors,ledger,pair[0],pair[1])
 for id in ["char_liang_xiao","char_axue"]:actors[id].hp=actors[id].max_hp
 Party.award(actors,ledger,"depart",50)
 var input_party:Array=[]
 for id in ["char_liang_xiao","char_axue"]:
  var actor:Dictionary=actors[id].duplicate(true)
  actor.team="party";actor.id=id
  actor.skills=["normal_attack","self_guard","guard_ally","observe","sancai_counter","LX_A03"] if id=="char_liang_xiao" else ["normal_attack","guard_ally","AX_S01","AX_S02"]
  input_party.append(actor)
 var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/chapter_seven_encounters.json"))
 var ox=SevenSession.new(c.rules,c.combat,data.encounters.enc_ch07_fire_ox_ambush,input_party,"genuine_minimum_ox")
 var d=SevenDriver.new(check);d.fire_ox(ox,true)
 check(ox.engine.state.outcome=="victory","genuine minimum actual controlled hazard")
 check(Party.accept_resources(actors,ox.final_party(),["char_liang_xiao","char_axue"]),"verified hazard resources")
 for pair in [["ox_encounter",350],["ox_story",100],["ring",75],["infiltrate",75]]:Party.award(actors,ledger,pair[0],pair[1])
 check(actors.char_liang_xiao.xp==10425 and actors.char_liang_xiao.level==32,"exact contract B04 threshold")
 for a in input_party:
  var current:Dictionary=actors[a.id]
  for field in ["hp","mp","max_hp","max_mp","atk","def","spd"]:a[field]=current[field]
 var battle=SevenSession.new(c.rules,c.combat,data.encounters.enc_ch07_chasm_rescue,input_party,"genuine_minimum_b04")
 d.b04(battle)
 check(battle.engine.state.outcome=="victory" and battle.engine.actor_by_id("char_liang_xiao").hp==49,"real no-N01 route reaches B04 victory49HP")
 check(not SevenSession.replay_receipt(battle.receipt(),c.rules,c.combat,battle.encounter,input_party).is_empty(),"genuine minimum battle receipt replay")
 print("CH07 GENUINE MINIMUM ",JSON.stringify(battle.final_party())," turn ",battle.engine.state.round-1)
