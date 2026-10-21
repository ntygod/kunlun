extends SceneTree
const Campaign=preload("res://scripts/campaign/campaign_state.gd")
func _initialize()->void:
 var path:=OS.get_environment("CH12_SOURCE")
 var original:=FileAccess.get_sha256(path)
 var c=Campaign.new(JSON.parse_string(FileAccess.get_file_as_string("res://data/prologue.json")))
 if c.restore_persisted(JSON.parse_string(FileAccess.get_file_as_string(path)))!="" or not c.enter_registered_chapter(12):push_error("formal11 source enters12");quit(1);return
 var before:=JSON.stringify(c.export_save())
 var context:Dictionary=c.world_context()
 if c.world_objects.get("ch11_wu_changqing",{}).get("status")!="dead" or "npc_wu_changqing" not in context.dead_actor_ids or "npc_wu_changqing" in context.present_actor_ids:push_error("chapter12 inherits existing Wu death in display context");quit(1);return
 if JSON.stringify(c.export_save())!=before or FileAccess.get_sha256(path)!=original:push_error("projection modified save/source");quit(1);return
 print("Chapter twelve Wu context: 3 checks, 0 failures")
 quit(0)
