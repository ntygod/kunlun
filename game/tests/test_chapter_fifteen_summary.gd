extends SceneTree
const Campaign=preload("res://scripts/campaign/campaign_state.gd")
const Same=preload("res://scripts/campaign/encounter_session.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func _initialize()->void:call_deferred("run")
func run()->void:
 var path:=OS.get_environment("CH15_TERMINAL")
 if path.is_empty():push_error("CH15_TERMINAL command terminal required");quit(1);return
 var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(path));var c=Campaign.new(JSON.parse_string(FileAccess.get_file_as_string("res://data/prologue.json")))
 check(c.restore_persisted(data)=="" and c.active_chapter==15 and c.state.finished,"actual bounded15 terminal restored")
 var before:Dictionary=c.export_save();var variants:Array=[]
 var altered:Dictionary=data.duplicate(true);altered.archive[-1].boundary_vitals.char_liang_xiao.hp=999999;variants.append(altered)
 altered=data.duplicate(true);altered.archive[-1].boundary_vitals.char_liu_yingying.mp=-1;variants.append(altered)
 altered=data.duplicate(true);altered.archive[-1].boundary_vitals.char_axue.hp=1;variants.append(altered)
 altered=data.duplicate(true);altered.archive[-1].semantic_commits.reverse();variants.append(altered)
 altered=data.duplicate(true);altered.archive[-1].milestones.pop_back();variants.append(altered)
 altered=data.duplicate(true);altered.archive[-1].choices.medical_loadout="invented_method";variants.append(altered)
 altered=data.duplicate(true);altered.archive[-1].leader_id="char_liu_yingying";variants.append(altered)
 altered=data.duplicate(true);altered.archive[-1].claimed_reward=3270;variants.append(altered)
 altered=data.duplicate(true);altered.archive[-1].summary_version=true;variants.append(altered)
 for i in range(variants.size()):check(c.restore_persisted(variants[i])!="" and Same.equivalent(before,c.export_save()),"malformed archive rejected atomically "+str(i))
 var packed:Dictionary=c.prepare_persisted_save();check(packed.error=="" and Same.equivalent(packed.payload,data),"canonical save idempotent")
 print("Chapter fifteen summary: ",checks," checks, ",failures," failures")
 quit(1 if failures else 0)
