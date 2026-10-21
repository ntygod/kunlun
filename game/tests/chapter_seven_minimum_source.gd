extends "res://tests/test_chapter_five_history_matrix.gd"
const SixFlow=preload("res://tests/chapter_six_campaign_driver.gd")
func run() -> void:
 base=JSON.parse_string(FileAccess.get_file_as_string("res://data/prologue.json"))
 var c=chapter_two_subset(0)
 check(c.enter_chapter_three(),"minimum ch3 entry")
 for j in range(180):
  if c.state.finished:break
  if not act_three(c,16):check(false,"ch3 progress");quit(2);return
 check(c.enter_registered_chapter(4),"minimum ch4 entry")
 for j in range(260):
  if c.state.finished:break
  if not advance_four(c,0):check(false,"ch4 progress");quit(2);return
 check(c.enter_registered_chapter(5),"minimum ch5 entry")
 for j in range(220):
  if c.state.finished:break
  if not advance_whole_five(c):check(false,"ch5 progress");quit(2);return
 check(c.enter_registered_chapter(6),"minimum ch6 entry")
 for j in range(220):
  if c.state.finished:break
  if not SixFlow.advance(c,0,0):check(false,"ch6 progress");quit(2);return
 check(c.state.finished and c.state.xp==9525 and c.state.coins==0,"actual no-side zero-copper chapter6 end")
 var saved=c.prepare_persisted_save()
 check(saved.error=="","validate actual chapter6 terminal")
 var clone=Campaign.new(base)
 check(clone.restore_persisted(saved.payload)=="","restore actual terminal")
 var f=FileAccess.open("user://chapter_seven_minimum_source.json",FileAccess.WRITE)
 f.store_string(JSON.stringify({"actors":c.actors,"payload":saved.payload,"xp":c.state.xp,"coins":c.state.coins}));f.close()
 after_source(c)
 print("CH07 SOURCE ",JSON.stringify(c.actors))
 print("Chapter seven minimum source: ",checks," checks, ",failures," failures")
 quit(1 if failures else 0)

func after_source(_campaign:RefCounted) -> void:
 pass
