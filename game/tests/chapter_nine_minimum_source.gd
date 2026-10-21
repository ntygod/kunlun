extends "res://tests/test_chapter_eight_minimum.gd"
## Reuses formal 0–8 actions, not an edited XP/coin fixture.
func after_source(c: RefCounted) -> void:
 super.after_source(c)
 var saved:Dictionary=c.prepare_persisted_save()
 check(saved.error=="","minimum chapter8 source verified")
 var file=FileAccess.open("user://chapter_nine_minimum_source.json",FileAccess.WRITE)
 file.store_string(JSON.stringify(saved.payload));file.close()
 print("CH09_MINIMUM_SOURCE ",ProjectSettings.globalize_path("user://chapter_nine_minimum_source.json")," ",c.state.xp," XP / ",c.state.coins," copper")
