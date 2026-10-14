extends SceneTree
const Campaign=preload("res://scripts/campaign/campaign_state.gd")
const Same=preload("res://scripts/campaign/encounter_session.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func _initialize()->void:
 var base=JSON.parse_string(FileAccess.get_file_as_string("res://data/prologue.json"))
 var old=Campaign.new(base);var now=Campaign.new(base)
 check(old.restore_persisted(JSON.parse_string(FileAccess.get_file_as_string("res://../output/cache/chapter_eight_gui/manual_natural_final.json")))=="","old natural restore")
 var raw:String=FileAccess.get_file_as_string("res://../output/cache/chapter_nine_gui/manual_natural_final.json")
 check(now.restore_persisted(JSON.parse_string(raw))=="","final natural restore")
 check(now.active_chapter==9 and now.state.finished,"actual archived9")
 check(now.state.xp==20795 and now.state.coins==3050,"exact natural L05 total")
 for id in old.items:check(Same.equivalent(old.items[id],now.items.get(id)),"old item unchanged "+id)
 for id in ["char_liang_xiao","char_liu_yingying"]:check(Same.equivalent(old.actors[id].equipment,now.actors[id].equipment),"standard gear retained "+id)
 var hero:Dictionary=now.actors.char_liang_xiao;var liu:Dictionary=now.actors.char_liu_yingying;var snow:Dictionary=now.actors.char_axue
 check(hero.hp==1404 and hero.max_hp==1404 and hero.mp==122 and hero.max_mp==151 and hero.level==47,"hero resources")
 check(liu.hp==919 and liu.max_hp==1130 and liu.mp==83 and liu.max_mp==127 and liu.level==47,"Liu resources")
 check(snow.hp==236 and snow.max_hp==480 and snow.mp==75 and snow.max_mp==75 and snow.level==23,"snow fixed actual resources")
 check(now.reward_ledger.get("reward_mq09_pine_once")==500 and now.reward_ledger.get("reward_mq09_wood_bird_once")==500 and now.reward_ledger.get("reward_mq09_well_encounter_once")==300 and now.reward_ledger.get("reward_ch09_l05")==300,"four exact special awards")
 check(now.state.optional.L05.status=="archived" and now.items.item_ch09_physician_key.quantity==1,"L05 archive unique key")
 check(now.items.item_ch09_serpent_diamond.quantity==1,"unique diamond")
 check(now.world_objects.ch09_wood_bird.state=="completed" and now.world_objects.ch09_wood_bird.location=="river_drifted_away" and not now.world_objects.ch09_wood_bird.portable,"bird drifted")
 for id in ["item_ch09_general_seal","item_ch09_court_robe","item_ch09_merit_armor","item_ch09_award_chest"]:check(now.items[id].owner=="camp" and now.items[id].location=="linan_tent_rack","court story reward left "+id)
 print("ACTOR_STATUS ",JSON.stringify(now.state.get("actor_states",{})))
 for id in now.items:
  if id.begins_with("item_ch09_"):print("ITEM ",id," ",JSON.stringify(now.items[id]))
 print("FINAL_HERO ",JSON.stringify(hero));print("FINAL_LIU ",JSON.stringify(liu));print("FINAL_SNOW ",JSON.stringify(snow))
 print("FINAL_OBJECTS ",JSON.stringify(now.world_objects))
 print("FINAL_HASH ",raw.sha256_text());print("Chapter nine natural final audit: ",checks," checks, ",failures," failures")
 quit(1 if failures else 0)
