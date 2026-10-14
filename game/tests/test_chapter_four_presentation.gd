extends "res://tests/test_chapter_four.gd"
func run() -> void:
 base=JSON.parse_string(FileAccess.get_file_as_string("res://data/prologue.json"))
 var c:=Campaign.new(base)
 var fixture:="res://../output/cache/chapter_three_gui/manual_natural_final.json"
 if FileAccess.file_exists(fixture):check(c.restore_persisted(JSON.parse_string(FileAccess.get_file_as_string(fixture)))=="","natural fixture")
 else:
  c=chapter_two_ending(true);c.enter_chapter_three()
  while not c.state.finished:act_three(c,16)
 c.enter_registered_chapter(4)
 while c.current_token()!="ch04_tile_intercept:00":
  if not intro(c):check(false,"reach pouch dialogue");quit(1);return
 var rt:=c.current_chapter_runtime()
 var purse:Dictionary=c.items.item_ch04_pouch.duplicate(true)
 var coins:int=c.state.coins;var xp:int=c.state.xp
 # Synthetic presentation fixtures only; not claimed as naturally earned low-money saves.
 for amount in [0,1,2]:
  c.items.item_ch04_pouch.escrow=amount
  var taunt:String=rt._line("dlg_ch04_source_841").text
  check(("一枚铜钱也没有" in taunt)==(amount==0),"exact zero-copper taunt")
  check(("这点零钱" in taunt)==(amount>0),"nonzero taunt remains source adaptation")
  check(c.state.coins==coins and c.state.xp==xp,"presentation cannot mint rewards")
 c.items.item_ch04_pouch=purse
 var prior:Dictionary=rt.state.duplicate(true)
 rt.state.scope="L01";rt.state.side_step=8
 for choice in ["ch04_l01_fish","ch04_l01_rice"]:
  rt.state.choices={"L01":choice}
  var lines:Array=rt.presentation()
  check(("莼菜鲈鱼" in lines[0].text)==(choice=="ch04_l01_fish"),"meal follows actual cargo choice")
 rt.state=prior.duplicate(true)
 for scene_id in ["ch04_quiet_gusu","ch04_departure_window"]:
  for i in range(rt.content.scenes.size()):
   if rt.content.scenes[i].id==scene_id:rt.state.scene_index=i
  rt.state.step=1;rt.state.scope="main"
  for r02 in ["undiscovered","executing","archived"]:
   for l01 in ["undiscovered","executing","archived"]:
    rt.state.optional.R02.status=r02;rt.state.optional.L01.status=l01
    var before:Dictionary=rt.state.duplicate(true)
    var view:Dictionary=rt.optional_window_view()
    var done:bool=r02=="archived" and l01=="archived"
    check(("均已归档" in view.confirmation)==done,"confirmation follows both actual archives")
    check(("尚未完成" in view.confirmation)==(not done and scene_id=="ch04_departure_window"),"deadline warning only when unfinished")
    check(Proof.equivalent(before,rt.state),"window text cannot alter runtime state")
 rt.state=prior.duplicate(true)
 while not c.actors.has("char_liu_yingying"):
  if not intro(c):check(false,"reach actual companion");quit(1);return
 var final_fixture:="res://../output/cache/chapter_four_gui_v2/manual_natural_final.json"
 if FileAccess.file_exists(final_fixture):check(c.restore_persisted(JSON.parse_string(FileAccess.get_file_as_string(final_fixture)))=="","actual chapter4 natural final remains readable")
 var before:Dictionary=c.export_save().duplicate(true)
 var app=load("res://scenes/main.tscn").instantiate();root.add_child(app);await process_frame
 app.story=c;app._load_chapter_scene();app._show_campaign_journal()
 var journal:String=app.modal_content.get_child(1).text
 check("当前同行年岁：梁萧17 / 柳莺莺16" in journal,"journal ages identify current Liang and Liu")
 check("牵挂记事：花晓霜16岁，未在当前队伍中" in journal,"Xiaoshuang explicitly historical absent actor")
 check(Proof.equivalent(before,c.export_save()),"journal cannot alter saved state or rewards")
 app.queue_free();await process_frame;await process_frame
 print("Chapter four presentation: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
