extends SceneTree
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
 checks += 1
 if not ok: failures += 1;push_error(label)
func run() -> void:
 var app=load("res://scenes/main.tscn").instantiate()
 root.add_child(app)
 await process_frame
 app.modal.hide()
 app.active_scene_id="layout_only"
 app.lines=[{"speaker":"梁萧","text":"论算的逐步解释需要看得清楚，也需要可以滚动回看。".repeat(30)}]
 app.line_index=0
 app.mode="chapter_dialogue"
 app.dialogue_panel.show()
 app._show_line()
 app.header.text="昆仑 / 第03章 · 牛斗论算 · 这是较长的标题用来验证边界"
 app.objective.text="转向南侧石阶，沿台下绕行 · 路点2/2：向右方"
 for window_size in [Vector2i(1280,720),Vector2i(640,360),Vector2i(640,359),Vector2i(639,359)]:
  root.size=window_size
  app.size=Vector2(window_size)
  app._layout()
  for i in range(4):await process_frame
  var bounds=Rect2(Vector2.ZERO,Vector2(window_size))
  check(bounds.encloses(app.dialogue_panel.get_global_rect()),"dialogue within client "+str(window_size))
  check(app.dialogue_scroll.size.y>=48,"body visible below pixel scaling threshold "+str(window_size))
  check(app.dialogue_scroll.get_v_scroll_bar().max_value>app.dialogue_scroll.size.y,"long body scrolls "+str(window_size))
  for button in app.actions.get_children():
   check(app.dialogue_panel.get_global_rect().encloses(button.get_global_rect()),"footer stays in dialogue "+str(window_size))
  for label in [app.header,app.objective]:
   check(label.clip_text and app.display.get_global_rect().encloses(label.get_global_rect()),"HUD bounded to pixel view "+str(window_size))
 app.queue_free();await process_frame
 print("Dialogue layout: %d checks, %d failures"%[checks,failures])
 quit(1 if failures else 0)
