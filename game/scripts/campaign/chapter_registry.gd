class_name ChapterRegistry
extends RefCounted
## Explicit runtime registrations, not discovery of every JSON in data/.
const ENTRIES := {
	1:{"content":"chapter_one","runtime":"chapter_one_runtime","maps":"maps/chapter_one_maps"},
	2:{"content":"chapter_two","runtime":"chapter_two_runtime","maps":"maps/chapter_two_maps"}}
static func read_json(id: String) -> Dictionary:
	var path := "res://data/"+id+".json"
	if not FileAccess.file_exists(path): return {}
	var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return value if value is Dictionary else {}
static func registered(id: int) -> bool: return ENTRIES.has(id)
static func definition(id: int) -> Dictionary:
	if not registered(id): return {}
	var entry: Dictionary = ENTRIES[id]
	return {"content":read_json(entry.content),"runtime":read_json(entry.runtime),"maps":read_json(entry.maps).get("maps",{})}
