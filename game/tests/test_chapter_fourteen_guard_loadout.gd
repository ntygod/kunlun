extends "res://tests/test_chapter_fourteen_main_inputs.gd"
const Same=preload("res://scripts/campaign/encounter_session.gd")
const Txn=preload("res://scripts/campaign/chapter_fourteen_transactions.gd")
func run()->void:
 var source:=OS.get_environment("CH14_SOURCE")
 check(FileAccess.file_exists(source),"formal13 input exists")
 if failures:quit(1);return
 root.size=Vector2i(640,360)
 app=load("res://scenes/main.tscn").instantiate();root.add_child(app);await frames();app.set_process(false);app.size=Vector2(640,360);app._layout()
 check(app.story.restore_persisted(JSON.parse_string(FileAccess.get_file_as_string(source)))=="" and app.story.enter_registered_chapter(14),"formal13 normal14 entry")
 for i in range(500):
  if app.story.current_event().get("choice_key")=="temple_loadout":break
  if not Flow.advance(app.story):check(false,"legal prefix");quit(1);return
 check(app.story.current_event().get("choice_key")=="temple_loadout","normal progression reaches preparation")
 var skills:Array=["HS_A01","HS_A02","HS_A04","HS_A05"]
 for skill in skills:check(skill in app.story.actors.char_huasheng.skills,"already learned "+skill)
 var original:Dictionary=app.story.export_save();app._load_scene();await frames()
 var cancel:=button(app.modal_content,"暂且想想，返回菜单")
 check(cancel!=null,"cancel available")
 var scroll:Node=cancel.get_parent()
 while scroll!=null and not scroll is ScrollContainer:scroll=scroll.get_parent()
 if scroll is ScrollContainer:scroll.ensure_control_visible(cancel)
 await frames()
 await click(cancel);check(Same.equivalent(original,app.story.export_save()),"cancel does not mutate choices slots or resources")
 check(app.mode=="menu","cancel reaches menu")
 var resume:=button(app.modal_content,"返回行旅")
 if resume==null:quit(1);return
 await click(resume);await frames()
 var label:=""
 for row in app.story.available_choices():
  if row.id=="ch14_temple_loadout_guard":label=row.label
 check(app.story.available_choices().size()==3 and not label.is_empty(),"two prior options retained plus explicit guard")
 var pick:=button(app.modal_content,label)
 check(pick!=null and "舍巨力推山撼" in pick.text,"real option states tradeoff")
 # Keep ordinary ScrollContainer behavior; ensure this lower option is visible.
 var parent:Node=pick.get_parent()
 while parent!=null and not parent is ScrollContainer:parent=parent.get_parent()
 if parent is ScrollContainer:parent.ensure_control_visible(pick)
 await frames();check(Rect2(Vector2.ZERO,Vector2(640,360)).encloses(pick.get_global_rect()),"640 guard option fully reachable")
 await click(pick);check(app.mode=="chapter_feedback" and Same.equivalent(original,app.story.export_save()),"preview does not commit")
 await click(button(app.modal_content,"继续"))
 check(app.story.state.choices.temple_loadout=="ch14_temple_loadout_guard","normal UI commits existing choice event")
 for i in range(10):
  if app.story.current_event().op=="objective_battle":break
  check(Flow.advance(app.story),"normal preparation continuation")
 check(app.story.actors.char_huasheng.equipped_active_skills==skills,"four legal slots selected")
 check(app.story.world_objects.ch14_preparation.selection=="ch14_temple_loadout_guard","existing preparation receipt records option")
 var rt:RefCounted=app.story.current_chapter_runtime();var s:RefCounted=rt.make_objective_encounter()
 check(s!=null,"normal battle starts")
 if s==null:quit(1);return
 check(s.set_command("char_liang_xiao","observe","ch14_temple_master").is_empty(),"hero observation")
 check(s.set_command("char_huasheng","HS_A01","char_liang_xiao").is_empty(),"guard legal ally command")
 check(rt.save_objective_checkpoint(s),"persist pending through runtime gate")
 var saved:Dictionary=app.story.prepare_persisted_save()
 check(saved.error=="","pending guard serializes")
 check(app.story.restore_persisted(saved.payload)=="","pending guard strict restoration")
 s=app.story.current_chapter_runtime().make_objective_encounter()
 check(s.resolve_round(),"one real guard round")
 var redirected:=0;var reflected:=0
 for event in s.engine.state.events:
  if event.type=="damage" and event.detail.get("channel")=="guard":redirected+=int(event.amount)
  if event.type=="damage" and event.detail.get("channel")=="reflection":reflected+=int(event.amount)
 check(redirected>0 and reflected>0,"normal UI loadout enables actual transfer and reflection")
 check(app.story.current_chapter_runtime().save_objective_checkpoint(s),"persist settled through runtime gate")
 saved=app.story.prepare_persisted_save();check(saved.error=="" and app.story.restore_persisted(saved.payload)=="","settled guard save restores strictly")
 # Invalid learned-skill input is a separate negative fixture, never a natural save.
 var a:Dictionary=app.story.actors.duplicate(true);a.char_huasheng.skills.erase("HS_A01")
 var st:Dictionary=app.story.state.duplicate(true);st.choices.temple_loadout="ch14_temple_loadout_guard";st.semantic_commits.erase("evt_ch14_temple_loadout_committed")
 var items:Dictionary=app.story.items.duplicate(true);var world:Dictionary=app.story.world_objects.duplicate(true);var before:=JSON.stringify([a,items,st,world])
 check(not Txn.apply("evt_ch14_temple_loadout_committed",a,items,st,world) and JSON.stringify([a,items,st,world])==before,"unlearned guard rejected atomically")
 app.queue_free();await frames();print("Chapter14 guard loadout UI: ",checks," checks, ",failures," failures");quit(1 if failures else 0)
