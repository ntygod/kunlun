class_name ChapterFourTransactions
extends RefCounted
## Small chapter rules reused by live events and the completed-outcome adapter.
## Callers validate event order first. No external amount/item dictionary is merged.
const INK:="item_ch02_qingxin_inkstone"
const POUCH:="item_ch04_pouch"
const HERO:="char_liang_xiao"
const LIU:="char_liu_yingying"
static func reserve_pouch(state: Dictionary, items: Dictionary) -> bool:
 if items.has(POUCH) or not items.has(INK) or items[INK].get("owner")!=HERO:return false
 if not state.get("coins") is int or int(state.coins)<0:return false
 var amount:=mini(2,int(state.coins))
 items[POUCH]={"owner":HERO,"state":"carried","form":"cloth_pouch","escrow":amount,"returned":false,"custody":"liang","holds_fragment":items[INK].get("form")=="broken_fragment"}
 state.coins-=amount
 if items[POUCH].holds_fragment:items[INK].location=POUCH
 return true
static func steal_pouch(items: Dictionary) -> bool:
 var purse:Dictionary=items.get(POUCH,{})
 if purse.get("custody")!="liang" or purse.get("returned",true):return false
 purse.owner=LIU;purse.custody="liu"
 if purse.holds_fragment:items[INK].owner=LIU
 return true
static func return_pouch(state: Dictionary, items: Dictionary) -> bool:
 var purse:Dictionary=items.get(POUCH,{})
 if purse.get("custody")!="liu" or purse.get("returned",true):return false
 if purse.holds_fragment and (items[INK].get("owner")!=LIU or items[INK].get("location")!=POUCH):return false
 state.coins+=int(purse.escrow)
 purse.escrow=0;purse.returned=true;purse.owner=HERO;purse.custody="returned"
 if purse.holds_fragment:items[INK].owner=HERO;items[INK].erase("location")
 return true
static func transfer_keepsake(items: Dictionary, to_liu: bool) -> bool:
 var item:Dictionary=items.get(INK,{})
 if item.get("owner")!=HERO or item.get("state")!="carried" or item.get("form") not in ["intact","broken_fragment"]:return false
 if to_liu:item.owner=LIU
 return true
static func purse_closed(items: Dictionary) -> bool:
 var purse:Dictionary=items.get(POUCH,{})
 return purse.get("custody")=="returned" and purse.get("returned")==true and purse.get("escrow")==0 and purse.get("owner")==HERO
