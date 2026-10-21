extends SceneTree
const T=preload("res://scripts/campaign/chapter_fifteen_transactions.gd")
const P=preload("res://scripts/campaign/party_progression.gd")
const Same=preload("res://scripts/campaign/encounter_session.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func _initialize()->void:
 var path:=OS.get_environment("CH15_SOURCE")
 if path.is_empty():push_error("CH15_SOURCE actual chapter14 terminal required");quit(1);return
 var C=load("res://scripts/campaign/campaign_state.gd")
 var c=C.new(JSON.parse_string(FileAccess.get_file_as_string("res://data/prologue.json")))
 check(c.restore_persisted(JSON.parse_string(FileAccess.get_file_as_string(path)))=="","formal source restored")
 if failures:quit(1);return
 # Explicit isolated fixtures test invalid transactions; they do not claim playthrough.
 var a:Dictionary=c.actors.duplicate(true);var items:Dictionary=c.items.duplicate(true);var world:Dictionary=c.world_objects.duplicate(true)
 var state:Dictionary={"allowed_transactions":["evt_ch15_mud_training_completed"],"semantic_commits":[],"verified_puzzles":{},"memories":[],"knowledge":[],"choices":{},"optional":{"R06":{"status":"active"}}}
 var before:Array=[a.duplicate(true),items.duplicate(true),state.duplicate(true),world.duplicate(true)]
 check(not T.apply("evt_ch15_mud_training_completed",a,items,state,world) and Same.equivalent(before,[a,items,state,world]),"unproven authorization atomic")
 state.verified_puzzles.world_ch15_mud_training=true
 var hp:int=a[P.HUASHENG].hp;var mp:int=a[P.HUASHENG].mp
 check(T.apply("evt_ch15_mud_training_completed",a,items,state,world),"proven mud authorization")
 check(a[P.HUASHENG].hp==hp and a[P.HUASHENG].mp==mp and a[P.HUASHENG].internal_skill=="HS_N02","new internal preserves injury and MP")
 check("HS_A06" in a[P.HUASHENG].skills and "HS_P03" not in a[P.HUASHENG].learned_passives,"mud grants precise technique, not premature sacrifice passive")
 state.semantic_commits.append("evt_ch15_mud_training_completed");before=[a.duplicate(true),items.duplicate(true),state.duplicate(true),world.duplicate(true)]
 check(not T.apply("evt_ch15_mud_training_completed",a,items,state,world) and Same.equivalent(before,[a,items,state,world]),"repeat authorization rejects atomically")
 state.allowed_transactions.append("evt_ch15_r06_completed");state.choices.r06_method="ch15_r06_method_a"
 before=[a.duplicate(true),items.duplicate(true),state.duplicate(true),world.duplicate(true)]
 check(not T.apply("evt_ch15_r06_completed",a,items,state,world) and Same.equivalent(before,[a,items,state,world]),"optional reward requires both actual proofs")
 state.verified_puzzles.pz_ch15_r06_clinic_plan=true;state.verified_puzzles.world_ch15_r06_clinic_repair=true
 check(T.apply("evt_ch15_r06_completed",a,items,state,world),"verified optional completion")
 check(items.item_ch15_r06_child_herb_sheet.quantity==1 and "MEM_R06_CLINIC_LANTERN" in state.memories,"keepsake and memory actual")
 state.semantic_commits.append("evt_ch15_r06_completed");before=[a.duplicate(true),items.duplicate(true),state.duplicate(true),world.duplicate(true)]
 check(not T.apply("evt_ch15_r06_completed",a,items,state,world) and Same.equivalent(before,[a,items,state,world]),"optional duplicate never mints keepsake")
 print("Chapter fifteen transactions: ",checks," checks, ",failures," failures");quit(1 if failures else 0)
