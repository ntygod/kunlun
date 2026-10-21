extends RefCounted
const Core=preload("res://scripts/combat/chapter_ten_engine.gd")
## Real commands only: works with learned A01/A02/A03, no optional N01/A04.
static func run(session:RefCounted,guard_only:bool=false)->bool:
 for i in range(6):
  var view:Dictionary=session.get_view()
  if view.outcome!="":return view.outcome=="victory"
  var skill:String="self_guard" if guard_only else {1:"LX_A03",2:"observe",3:"sancai_counter",4:"ch10_borrow_tide",5:"LX_A03",6:"self_guard"}[int(view.round)]
  var target:String=Core.HERO if skill in ["self_guard","ch10_borrow_tide"] else Core.BOSS
  if session.set_command(Core.HERO,skill,target,int(view.revision))!="":return false
  if not session.resolve_round():return false
 return session.get_view().outcome=="victory"
