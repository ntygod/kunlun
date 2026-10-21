extends "res://tests/test_chapter_ten_minimum.gd"
const ElevenFlow=preload("res://tests/chapter_eleven_campaign_driver.gd")
func after_source(c:RefCounted)->void:
 super.after_source(c)
 check(c.state.finished and c.state.xp==20915 and c.state.coins==2300,"actual minimum0–10 inherited")
 var old:Dictionary=c.actors.duplicate(true);var items:Dictionary=c.items.duplicate(true)
 check(c.enter_registered_chapter(11),"minimum11 entry")
 for i in range(100):
  if c.state.finished:break
  print("MIN11 ",c.current_token())
  if c.current_event().id=="enc_ch11_laoshan_rescue":
   check(c.state.xp==22540 and c.actors.char_liang_xiao.level==50,"actual minimum1625 preB07")
   check(not c.actors.has("char_huasheng") and not c.actors.char_hua_xiaoshuang.skills.has("HXS_A04"),"no future monk or optional sedative")
   print("MIN11_B07_ENTRY ",JSON.stringify({"hero":c.actors.char_liang_xiao,"doctor":c.actors.char_hua_xiaoshuang}))
  if not ElevenFlow.advance(c,1,false):check(false,"minimum11 advance "+c.current_token());return
 check(c.state.finished and c.state.xp==24225 and c.state.coins==3000,"minimum11 exact3310XP700coins")
 check(c.actors.char_axue==old.char_axue,"dead historical Axue unchanged")
 for id in items:check(c.items[id]==items[id],"legacy item retained "+id)
 var final:Dictionary=c.prepare_persisted_save();check(final.error=="","minimum11 bounded "+str(final.error))
 var restored=Campaign.new(base);check(restored.restore_persisted(final.payload)=="","minimum11 reload")
 print("CH11 FULL MINIMUM ",c.state.xp," XP / ",c.state.coins," copper; H",c.actors.char_liang_xiao.hp," X",c.actors.char_hua_xiaoshuang.hp)
