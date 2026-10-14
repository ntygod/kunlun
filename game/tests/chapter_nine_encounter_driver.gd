extends RefCounted
const H := "char_liang_xiao"
static func step(session: RefCounted, action: String, target: String) -> bool:
 return session.apply_input({"actor_id":H,"action_id":action,"value":target}).accepted and session.resolve_round()
static func run(session: RefCounted) -> bool:
 for id in ["well_soldier_1","well_soldier_2"]:
  if not step(session,"observe",id) or not step(session,"disarm",id): return false
 return session.get_view().outcome=="victory"
