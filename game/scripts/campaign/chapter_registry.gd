class_name ChapterRegistry
extends RefCounted
## Explicit runtime registrations, not discovery of every JSON in data/.
const ENTRIES := {
	1:{"content":"chapter_one","runtime":"chapter_one_runtime","maps":"maps/chapter_one_maps"},
	2:{"content":"chapter_two","runtime":"chapter_two_runtime","maps":"maps/chapter_two_maps"},
	3:{"content":"chapter_three","runtime":"chapter_three_runtime","maps":"maps/chapter_three_maps","capabilities":{"route_guidance":true,"checkpoint_inputs":true,"controlled_world":true,"world_sync_method":"sync_escape_view","battle_snapshot":true,"compact_battle_panel":"res://scripts/ui/chapter_three_battle_panel.gd","inherited_optional_journal":true,"ending_title":"灵台惊变 · 行旅归档","ending_body":"梁萧拒绝宫主之位，护晓霜脱出石阵，再独自引开明归。晓霜与猴犬留在藏身处。可继续江南花柳。","next_chapter":4}},
	4:{"content":"chapter_four","runtime":"chapter_four_runtime","maps":"maps/chapter_four_maps","runtime_script":"res://scripts/campaign/chapter_four_runtime.gd","summary_adapter":"res://scripts/campaign/chapter_four_summary.gd","capabilities":{"route_guidance":true,"checkpoint_inputs":true,"controlled_world":true,"world_sync_method":"sync_controlled_view","battle_snapshot":true,"compact_battle_panel":"res://scripts/ui/chapter_four_battle_panel.gd","inherited_optional_journal":true,"optional_window_view":true,"leader_selection":true,"auto_world_entry":true,"ending_title":"江南花柳 · 西行相伴","ending_body":"两人携小柳笠踏上西行水路。第04章行旅已归档；可继续纯阳之秘。这里不是全游戏通关。","next_chapter":5}},
	5:{"content":"chapter_five","runtime":"chapter_five_runtime","maps":"maps/chapter_five_maps","runtime_script":"res://scripts/campaign/chapter_five_runtime.gd","summary_adapter":"res://scripts/campaign/chapter_five_summary.gd","capabilities":{"route_guidance":true,"checkpoint_inputs":true,"controlled_world":true,"world_sync_method":"sync_controlled_view","battle_snapshot":true,"compact_battle_panel":"res://scripts/ui/chapter_five_battle_panel.gd","leader_selection":true,"auto_world_entry":true,"controlled_wait_retry":true,"effective_party_panels":true,"battle_world_presentation":true,"ending_title":"纯阳之秘 · 荒谷结义","ending_body":"梁萧与阿雪相依离谷。第05章行旅已归档；可继续华山故居。这里不是全游戏通关。","next_chapter":6}},
	6:{"content":"chapter_six","runtime":"chapter_six_runtime","maps":"maps/chapter_six_maps","runtime_script":"res://scripts/campaign/chapter_six_runtime.gd","summary_adapter":"res://scripts/campaign/chapter_six_summary.gd","capabilities":{"route_guidance":true,"checkpoint_inputs":true,"controlled_world":true,"world_sync_method":"sync_controlled_view","battle_snapshot":true,"compact_battle_panel":"res://scripts/ui/chapter_six_battle_panel.gd","leader_selection":true,"auto_world_entry":true,"controlled_wait_retry":true,"effective_party_panels":true,"optional_window_view":true,"reconsider_departure":true,"ending_title":"华山故居 · 清晨辞行","ending_body":"阿雪留村，梁萧随六友赴蔡州。第06章已归档；可继续六花折弓。","next_chapter":7}},
	7:{"content":"chapter_seven","runtime":"chapter_seven_runtime","maps":"maps/chapter_seven_maps","runtime_script":"res://scripts/campaign/chapter_seven_runtime.gd","summary_adapter":"res://scripts/campaign/chapter_seven_summary.gd","capabilities":{"route_guidance":true,"checkpoint_inputs":true,"controlled_world":true,"world_sync_method":"sync_controlled_view","battle_snapshot":true,"compact_battle_panel":"res://scripts/ui/chapter_seven_battle_panel.gd","puzzle_panel":"res://scripts/ui/chapter_seven_puzzle_panel.gd","compact_puzzle_panel":true,"auto_world_entry":true,"controlled_wait_retry":true,"effective_party_panels":true,"battle_world_presentation":true,"optional_window_view":true,"ending_title":"六花折弓 · 夜雨余声","ending_body":"阿雪留营休养，断弓与亡友粮袋伴随梁萧。第07章行旅已归档；可继续襄樊攻防。","next_chapter":8}},
	8:{"content":"chapter_eight","runtime":"chapter_eight_runtime","maps":"maps/chapter_eight_maps","runtime_script":"res://scripts/campaign/chapter_eight_runtime.gd","summary_adapter":"res://scripts/campaign/chapter_eight_summary.gd","capabilities":{"route_guidance":true,"checkpoint_inputs":true,"controlled_world":true,"world_sync_method":"sync_controlled_view","battle_snapshot":true,"compact_battle_panel":"res://scripts/ui/chapter_eight_battle_panel.gd","puzzle_panel":"res://scripts/ui/chapter_eight_puzzle_panel.gd","compact_puzzle_panel":true,"auto_world_entry":true,"controlled_wait_retry":true,"effective_party_panels":true,"battle_world_presentation":true,"optional_window_view":true,"ending_title":"襄樊攻防 · 星珠远别","ending_body":"火城、亡友与星珠留在行旅。第08章已归档；后续尚未接入，这里不是全游戏通关。"}}}
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

static func capability(id: int, key: String, fallback: Variant = false) -> Variant:
	return ENTRIES.get(id,{}).get("capabilities",{}).get(key,fallback)

static func adapter(id: int, key: String) -> String:
	return str(ENTRIES.get(id,{}).get(key,""))
