extends SceneTree
const Campaign=preload("res://scripts/campaign/campaign_state.gd")
const Tx=preload("res://scripts/campaign/chapter_twelve_transactions.gd")
const Same=preload("res://scripts/campaign/encounter_session.gd")
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;push_error(label)
func _initialize()->void:call_deferred("run")
func run()->void:
 var source:String=OS.get_environment("CH12_SOURCE")
 if source.is_empty():push_error("CH12_SOURCE required");quit(1);return
 var c=Campaign.new(JSON.parse_string(FileAccess.get_file_as_string("res://data/prologue.json")))
 check(c.restore_persisted(JSON.parse_string(FileAccess.get_file_as_string(source)))=="","formal source")
 var actors:Dictionary=c.actors.duplicate(true);var items:Dictionary=c.items.duplicate(true);var world:Dictionary=c.world_objects.duplicate(true)
 var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/chapter_twelve_runtime.json"));var allowed:Array=[]
 for events in data.scenes.values():
  for event in events:
   for effect in event.get("effects",[]):allowed.append(effect.id)
 for events in data.side_quests.values():
  for event in events:
   for effect in event.get("effects",[]):allowed.append(effect.id)
 var state:Dictionary={"allowed_transactions":allowed,"semantic_commits":[],"verified_puzzles":{},"choices":{},"memories":[],"optional":{"R05":{"status":"undiscovered","disposition":"open"}},"r05_closed":false,"currency_ledger":{},"coins":0}
 var before:Dictionary=actors.duplicate(true)
 state.choices.b08_loadout="ch12_b08_loadout_keep"
 check(Tx.apply("evt_ch12_b08_loadout_committed",actors,items,state,world),"explicit keep")
 check(Same.equivalent(before,actors),"keep preserves all actor fields and vitals")
 for selection in ["recommended","counter"]:
  state.choices.b08_loadout="ch12_b08_loadout_"+selection
  check(Tx.apply("evt_ch12_b08_loadout_committed",actors,items,state,world),"explicit B08 four slots "+selection)
  check(actors[Tx.X].equipped_active_skills.size()==4,"slot cap")
 state.choices.b09_loadout="ch12_b09_loadout_recommended"
 var snapshot:Dictionary=actors.duplicate(true)
 check(not Tx.apply("evt_ch12_b09_loadout_committed",actors,items,state,world) and Same.equivalent(snapshot,actors),"unlearned A04A05 rejects atomically")
 state.verified_puzzles.enc_ch12_han_duel=true;world.ch12_duels={"han":"pending"}
 check(Tx.apply("evt_ch12_han_won",actors,items,state,world),"Han proof grants A05")
 check(actors[Tx.X].equipped_active_skills==snapshot[Tx.X].equipped_active_skills,"grant does not replace slots")
 check(Tx.apply("evt_ch12_hxs04_ready",actors,items,state,world),"main A04 grant")
 actors[Tx.X].learned_passives.append("HXS_P03")
 check(Tx.apply("evt_ch12_b09_loadout_committed",actors,items,state,world),"new skills require explicit equip")
 check(actors[Tx.X].equipped_passives==["HXS_P01","HXS_P03"],"explicit matching passive preset")
 check(not actors[Tx.L].has("equipped_active_skills"),"doctor preparation cannot select Liu slots")
 state.choices.liuying_loadout="ch12_liuying_loadout_keep"
 check(not Tx.apply("evt_ch12_liuying_loadout_committed",actors,items,state,world),"no historical four-slot selection to keep")
 state.choices.liuying_loadout="ch12_liuying_loadout_hook"
 check(Tx.apply("evt_ch12_liuying_loadout_committed",actors,items,state,world),"explicit first Liu four slots")
 var selected:Array=actors[Tx.L].equipped_active_skills.duplicate()
 state.choices.liuying_loadout="ch12_liuying_loadout_keep"
 check(Tx.apply("evt_ch12_liuying_loadout_committed",actors,items,state,world) and actors[Tx.L].equipped_active_skills==selected,"keep preserves existing Liu four slots")
 for id in [Tx.H,Tx.X,Tx.L,Tx.S,Tx.A]:
  check(actors[id].hp==before[id].hp and actors[id].mp==before[id].mp,"skills/loadout no healing "+id)
 state.semantic_commits.append("evt_ch12_hxs04_ready")
 check(not Tx.apply("evt_ch12_hxs04_ready",actors,items,state,world),"repeat semantic transaction rejected")
 var oldliu:Dictionary=actors[Tx.L].duplicate(true);world.ch12_duels.chu="draw";world.ch12_duels.lei="draw";state.verified_puzzles.world_ch12_freed_escort=true
 check(Tx.apply("evt_ch12_liuying_rejoined",actors,items,state,world),"same Liu reunion")
 for key in ["hp","mp","age","equipment","story_injury"]:check(Same.equivalent(oldliu.get(key),actors[Tx.L].get(key)),"reunion preserves "+key)
 for skill in ["LYY_A03","LYY_A04","LYY_A05"]:check(actors[Tx.L].skill_ranks[skill]==3,"missed rank catchup "+skill)
 state.verified_puzzles.world_ch12_medical_departure=true
 check(Tx.apply("evt_ch12_chapter_archived",actors,items,state,world),"chapter endpoint")
 check(actors[Tx.H].skill_ranks.LX_A04==2 and state.coins==750,"only terminal skill tier and750")
 check(not Tx.apply("evt_ch12_chapter_archived",actors,items,state,world),"currency ledger once")
 check(Same.equivalent(actors[Tx.A],before[Tx.A]),"permanent dead unchanged")
 print("CH12 TRANSACTIONS ",checks," checks ",failures," failures");quit(0 if failures==0 else 1)
