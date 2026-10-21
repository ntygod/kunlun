extends "res://tests/test_chapter_nine_encounter.gd"
## These are truthful chapter-eight entry resource probes, NOT a replacement
## for walking chapter nine's rest/reward pipeline. Integration tests own that.
const Campaign=preload("res://scripts/campaign/campaign_state.gd")
func run():
 setup()
 for source in ["user://chapter_nine_minimum_source.json","res://../output/cache/chapter_eight_gui/manual_natural_final.json"]:
  var c=Campaign.new(JSON.parse_string(FileAccess.get_file_as_string("res://data/prologue.json")))
  var payload=JSON.parse_string(FileAccess.get_file_as_string(source))
  check(payload is Dictionary,"source exists "+source)
  if not payload is Dictionary:continue
  check(c.restore_persisted(payload)=="","formal source restore "+source)
  var minimum=source.begins_with("user://")
  check(c.state.xp==(15015 if minimum else 17665) and c.state.coins==(1050 if minimum else 2450),"real entry XP/copper")
  var p:Array=c.current_chapter_runtime().combat_party()
  check(p[0].internal_skill!="LX_N01","entry has no N01")
  var s=session(p);var resources=s.final_party()
  check(Driver.run(s) and s.final_party()==resources,"source resources four actions zero damage unchanged")
  s.retry()
  var hits:=0
  var damage=maxi(1,int(floor(169.0*Session.Core.K/(Session.Core.K+float(p[0].def)))))
  while s.final_party()[0].hp>damage:
   check(Driver.step(s,"wait","well_soldier_1") and Driver.step(s,"wait","well_soldier_1"),"real reachable mistakes")
   hits+=1
  var reachable_hp:int=s.final_party()[0].hp
  check(reachable_hp>0 and reachable_hp<=damage and Driver.run(s),"actual worst surviving reachable HP standard success")
  check(s.final_party()[0].mp==p[0].mp,"mistakes never change MP")
  print("SOURCE_PROBE ","minimum" if minimum else "natural"," xp=",c.state.xp," coins=",c.state.coins," entry=",resources," mistake_damage=",damage," mistakes=",hits," reachable_low_hp=",reachable_hp)
 print("Chapter nine source probes: %d checks, %d failures" % [checks,failures]);quit(1 if failures else 0)
