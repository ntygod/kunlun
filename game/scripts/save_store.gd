class_name SaveStore
extends RefCounted
## Same-directory temp + rename: preserve the old save on failed writes.
var directory: String
func _init(path: String = "user://saves") -> void:
	directory = path

func save_game(story: StoryState, slot: String = "manual") -> String:
	if slot not in ["manual", "auto"]:
		return "无效存档槽"
	var error := story.restore(story.state.duplicate(true))
	if not error.is_empty():
		return error
	if DirAccess.make_dir_recursive_absolute(directory) != OK:
		return "无法创建存档目录"
	var path := directory.path_join(slot + ".json")
	var temp := path + ".tmp"
	var file := FileAccess.open(temp, FileAccess.WRITE)
	if file == null:
		return "无法写入临时存档"
	file.store_string(JSON.stringify(story.state, "\t"))
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		return "存档写入失败；旧存档保留"
	if DirAccess.rename_absolute(temp, path) != OK:
		return "存档替换失败；旧存档保留"
	return ""

func load_game(story: StoryState, slot: String = "manual") -> String:
	if slot not in ["manual", "auto"]:
		return "无效存档槽"
	var path := directory.path_join(slot + ".json")
	if not FileAccess.file_exists(path):
		return "此槽位还没有存档"
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null or file.get_length() > 1024 * 1024:
		return "无法读取存档或文件过大"
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK:
		return "存档格式损坏；当前进度未变"
	return story.restore(parser.data)
