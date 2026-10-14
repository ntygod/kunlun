extends SceneTree
const Rules=preload("res://scripts/campaign/chapter_four_transactions.gd")
const Canonical=preload("res://scripts/campaign/bounded_save_codec.gd")
var checks:=0
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,text: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(text)
func run() -> void:
 for coins in [0,1,2,550]:
  for form in ["intact","broken_fragment"]:
   for transfer in [false,true]:
    var state:Dictionary={"coins":coins}
    var items:Dictionary={Rules.INK:{"owner":Rules.HERO,"state":"carried","form":form},"item_ch01_xuanyuan_sword":{"owner":Rules.HERO,"state":"carried"}}
    check(Rules.reserve_pouch(state,items),"reserve actual balance")
    check(state.coins+items[Rules.POUCH].escrow==coins,"escrow conserves money")
    check(items[Rules.POUCH].escrow==mini(2,coins),"escrow min2")
    check(not Rules.reserve_pouch(state,items),"cannot reserve twice")
    check(Rules.steal_pouch(items),"theft changes custody")
    check(items[Rules.INK].owner==(Rules.LIU if form=="broken_fragment" else Rules.HERO),"intact inkstone never stolen")
    check(items[Rules.INK].form==form,"same inkstone form")
    check(not Rules.steal_pouch(items),"cannot steal escrow twice")
    check(Rules.return_pouch(state,items),"actual same purse returned")
    check(state.coins==coins and Rules.purse_closed(items),"original money exactly restored")
    check(not Rules.return_pouch(state,items) and state.coins==coins,"return once")
    check(Rules.transfer_keepsake(items,transfer),"conditional custody gift")
    check(items[Rules.INK].owner==(Rules.LIU if transfer else Rules.HERO) and items[Rules.INK].form==form,"single actual form/owner retained")
    check(items.size()==3 and items.item_ch01_xuanyuan_sword.owner==Rules.HERO,"no duplicated fragment or thrown sword")
 print("Chapter four transactions: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
