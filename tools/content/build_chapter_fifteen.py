import json, hashlib
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
H='char_liang_xiao';X='char_hua_xiaoshuang';S='char_huasheng'
# scene, title, map, controller, reward, semantic txns, world/puzzle
specs=[
('tongzhou','通州止斗','tongzhou',H,100,['tongzhou_arrival','tongzhou_restrained'],'world_ch15_tongzhou_restrain'),
('jiuru_leave','一声认输','tongzhou',H,75,['jiuru_yields','huasheng_wutai'],''),
('burial','合葬补靖','tomb',H,200,['burial_arrival','joint_burial_completed'],'world_ch15_joint_burial'),
('mourning','墓前守孝','tomb',H,150,['mourning_completed'],''),
('proposal','守孝期满','road',H,100,['proposal_prepared'],''),
('capture','囚龙加身','road',H,125,['dragon_lock_captured'],''),
('trial','百丈公审','baizhang',H,150,['trial_arrival','trial_witnessed'],'world_ch15_trial_witness'),
('friends','众友驰援','baizhang',H,125,['friends_intervene','huasheng_returned'],''),
('divine_powder','药雾交错','baizhang',X,125,['divine_powder_released','liang_unbound'],''),
('mercy','救下仇敌','baizhang',H,150,['baizhang_rescue_completed'],'world_ch15_baizhang_rescue'),
('departure','各循其道','road',H,75,['liang_departed_west'],''),
('abduction','风雪劫持','cliff',X,100,['xiaoshuang_abducted','baichier_died'],''),
('escape','借雾求生','cliff',X,150,['xiaoshuang_escaped'],'world_ch15_cliff_escape'),
('false_news','风雪中的谎言','cliff',X,75,['han_died_false_news'],''),
('recovery','自己的归路','clinic',X,100,['xiaoshuang_recovered'],''),
('tomb_return','墓前诊脉','tomb',X,100,['eastline_rejoined','tomb_triage_completed'],'world_ch15_tomb_triage'),
('clinic_window','留灯之问','clinic',X,75,[],''),
('poison_plot','墓旁毒局','tomb',X,125,['five_treasures_poisoned','luo_chang_died'],''),
('mud_training','曲直收放','duel',S,65,['mud_training_completed'],'world_ch15_mud_training'),
('loadout','医武整备','duel',X,0,['loadout_committed'],''),
('battle','医理破贺陀罗','duel',X,0,['b12_completed'],'enc_ch15_medical_disarm'),
('mercy_father','手中银针只救人','duel',X,200,['father_son_spared'],'world_ch15_mercy_guard'),
('treatment','病人不分恩仇','tomb',X,225,['postbattle_care_completed'],'world_ch15_postbattle_care'),
('clinic_departure','灯留给来人','clinic',X,180,['eastline_oath'],''),
('eastline_final','杏林远行','eastroad',X,200,['eastline_departed'],'world_ch15_eastline_departure'),
]
contract={'chapter':15,'scenes':[{'id':'ch15_'+s,'title':title,'map_id':'map_ch15_'+m,'controller':c,'xp':xp,'semantic_transactions':['evt_ch15_'+t for t in tx],'objective':ob} for s,title,m,c,xp,tx,ob in specs], 'main_xp':2970,'pre_b12_main_xp':2165,'battle_xp':300,'coins':900,'optional':{'quest_id':'R06','scene_id':'side_ch15_r06','open_scene':'ch15_clinic_window','final_window_scene':'ch15_clinic_departure','window_id':'side_ch15_r06','close_id':'confirm_ch15_eastline_departure','puzzle_id':'pz_ch15_r06_clinic_plan','world_id':'world_ch15_r06_clinic_repair','method_key':'r06_method','method_ids':['ch15_r06_method_a','ch15_r06_method_b'],'xp':400},'choices':{'trial_response':['ch15_trial_responsibility','ch15_trial_question'],'departure_words':['ch15_departure_clear','ch15_departure_concern'],'escape_response':['ch15_escape_mist','ch15_escape_conscience'],'poison_strategy':['ch15_poison_observe','ch15_poison_bluff'],'medical_loadout':['ch15_medical_loadout_recommended','ch15_medical_loadout_alternate','ch15_medical_loadout_keep'],'mercy_response':['ch15_mercy_shelter','ch15_mercy_stop'],'care_order':['ch15_care_treasures','ch15_care_equal']}}
assert sum(s[4] for s in specs)==2970
assert sum(s[4] for s in specs[:20])==2165
(ROOT/'docs/development/chapter-fifteen-content-contract.json').write_text(json.dumps(contract,ensure_ascii=False,indent=2)+'\n')
# Original adaptation, not verbatim transcriptions; each block is a visible playable beat.
lines={
 'tongzhou': [('旁白','扶柩南下，通州古道忽传来呼喝。释家人追着失神的释天风，行人纷纷退到路旁。'),('花生','老爷爷又发急了！俺先护住车马，梁大哥，你来拦住他的掌势。'),('梁萧','让出路来。只止住他，不伤人。'),('旁白','掌势终于收住，释天风仍怔怔望着九如。')],
 'jiuru_leave':[('释天风','老和尚，这一场到底是谁胜？'),('九如','是你胜。老衲输了，不必再比。'),('旁白','释天风的肩头渐渐松下。九如向灵柩合掌，又招手唤过花生。'),('花生','俺去五台随师父学佛，等事情了了就回来。晓霜姐姐，路上保重。')],
 'burial':[('旁白','襄樊旧岗荒草齐膝。梁萧找到父亲的墓碑，把母柩轻轻放在一旁。'),('梁萧','爹，娘回来了。当年不懂你的名字，今天这个字，孩儿知道怎样写了。'),('花晓霜','我陪你。先把碑前的草清净，再让他们安稳睡在一起。'),('旁白','石上“靖”字端正而深。梁萧收起剑，和晓霜在新土前静立。')],
 'mourning':[('旁白','初月拾枝，次月补土，第三月风过枯草。梁萧晨夕守墓，晓霜带幼帝照料邻近病人。'),('赵昺','我把水放在这里。今天也没有弄倒香炉。'),('梁萧','谢谢你。人走了，留下的事总要认真做完。'),('花晓霜','往后的路，也要好好走。')],
 'proposal':[('旁白','守孝期满，梁萧整好旧衣，备下并不贵重的礼物。'),('梁萧','等见了你爹，我会把这些年的事一一说清。'),('花晓霜','说清便好。别又一急就与人争起来。'),('旁白','梁萧难得露出笑意，沿山道迎上花清渊和秦伯符。')],
 'capture':[('花清渊','萧儿，先随我们走一程。'),('旁白','梁萧毫无戒心地近前。机关骤合，囚龙锁锁住双肩；礼盒跌在路边。'),('秦伯符','这是花宫主的严令……'),('梁萧','原来你们等的，不是我这一声问候。')],
 'trial':[('旁白','百丈坪刑台雾重。梁萧被锁在石桩前，只能环顾四周，不能自由离台。'),('公羊羽','梁萧，城破人亡，那些事你可肯认？'),('梁萧','我造的炮，我做的事，不能推给别人。修历救民，也不是假的。'),('旁白','梁萧看见故人，却没有低头求饶。')],
 'friends':[('明三秋','算学本为济世。若只凭门户便要杀他，明某今日便不守这门户！'),('秦伯符','锁是我参与加的，这一回我也有责任。谁要动手，先问过我。'),('旁白','九如与花生赶上山来。花生挡开忽赤因，却被公羊羽看破来势，迫退数步。'),('花生','俺打不过你，也不能眼看梁大哥死在这里！')],
 'divine_powder':[('花晓霜','他们若都停下手，萧哥哥便能脱险……'),('旁白','晓霜的药雾与暗处常宁所散的异药相遇，群豪站立不稳。火真人强行催动毒火，反被逆焰吞住。'),('梁萧','眼前还有人在受伤，不能只顾走！'),('旁白','秦伯符松开锁扣。梁萧挣脱拘束，转身冲向石坪。')],
 'mercy':[('旁白','忽赤因与贺陀罗趁乱逼近。梁萧引开掌势，为中毒者留出退路。'),('花晓霜','我照看倒下的人，你先拦住毒火！'),('梁萧','火真人，收手。再强撑只会连旁人也害了。'),('公羊羽','方才我欲杀你，你却肯救我……梁萧，你走罢。')],
 'departure':[('旁白','药雾散尽，众人再没有拦住山道。晓霜仍要照料伤者，梁萧先行离坪。'),('梁萧','晓霜，等这边安稳了，回天机宫歇一歇。'),('花晓霜','你也不要逞强。天下这么大，总有再见的一天。'),('旁白','梁萧转过山口，只以为晓霜有亲友相护；他并不知道后来崖上的变故。')],
 'abduction':[('旁白','暮雪中，韩凝紫截住晓霜，将她带向崖边。白痴儿扑上护主，金灵儿紧随其后。'),('花晓霜','韩前辈，有话冲我说，别伤它们！'),('旁白','白痴儿倒在雪里，再没有起来。金灵儿负伤伏在石后，仍望着晓霜。'),('花晓霜','白痴儿……我会记得你。活着的人，我还得护住。')],
 'escape':[('韩凝紫','花清渊欠我的，难道就这样算了？'),('花晓霜','欠你的不是这些无辜性命。前辈，停下来。'),('旁白','晓霜稳住紊乱内息，趁风雪遮眼沿侧崖退开。青色发带被扯落，身影没入雾中。'),('旁白','她落到有藤蔓遮护的浅隙，忍痛扶起金灵儿；仍在呼吸，仍能走。')],
 'false_news':[('旁白','远处崖顶传来花清渊的呼喊。韩凝紫抛出染血发带，谎称晓霜已经身亡。'),('韩凝紫','你再也见不到她了。'),('旁白','声音断在风雪里。韩凝紫终因执念而亡，花清渊与天机门人只见发带，误信了那句话。'),('旁白','梁萧早已离开百丈坪。此刻没有消息传到他耳中。')],
 'recovery':[('旁白','晓霜在避风棚中养伤，金灵儿挨着药箱休息。她没有等待谁来替自己决定去处。'),('花晓霜','先回墓前。若萧哥哥来过，总能留下一点消息。'),('旁白','她扶墙站稳，重新背起药箱。山路上没有梁萧的身影。'),('花晓霜','遇见需要救的人，就先救人。')],
 'tomb_return':[('旁白','合葬墓前坐着一位白头老人。萧千绝背对新碑，手里的枯叶已捏成细屑。'),('萧千绝','你回来了。她……临去前还说了什么？'),('花晓霜','婆婆要我们别再报仇。前辈，让我看看你的伤。'),('旁白','花生带着幼帝赶来，见晓霜尚在人世，欢喜得几乎说不出话。')],
 'clinic_window':[('赵昺','晓霜姐姐，村口草棚里还有好些伤病的人。咱们走了，他们怎么办？'),('花生','俺能补门、挑水。姐姐要留下些什么，俺来帮。'),('花晓霜','先听听乡亲的难处。若能留下一盏灯，后来的人便不必摸黑。')],
 'poison_plot':[('旁白','骆明绮、常宁与贺陀罗逼近墓地，中条五宝被挟来试毒。萧千绝与花生救人心切，也中了五行散。'),('花晓霜','别再逼他们试药。五位叔父已撑不住了。'),('旁白','争夺药物之际，常宁下毒，贺陀罗背后出掌，骆明绮倒地身亡。常宁随后也被自己卷入的毒局夺去性命。'),('花晓霜','花生，看着我。先稳住，不必听他们吓唬。')],
 'mud_training':[('萧千绝','一身力气直撞出去，十成倒有九成落空。看这泥丸，方圆曲直，未发之前都在手里。'),('旁白','萧千绝借弹泥丸示意收放。花生摊开掌心，再缓缓收指。'),('花生','不是使最大的劲，是把劲送到该到的地方。'),('花晓霜','我替你看清他的气脉，你替受伤的人挡住路。')],
 'loadout':[('花晓霜','先护持、望诊，再以龙须引出破绽，花生以曲直劲接应。'),('花生','俺听姐姐指点。两个人一齐动手，也不能只顾伤他。')],
 'battle':[('旁白','晓霜与花生并肩守在墓道前。萧千绝负伤留在场边，梁萧不在这场战斗中。'),('花晓霜','看清呼吸与气门的变化，护住同伴再出手。'),('旁白','两次医武闭环散去贺陀罗的行功经络。他倒地而未死，哈里斯惊惶地扶住父亲。')],
 'mercy_father':[('中条五宝','这父子害了多少人！难道就这样放走？'),('花晓霜','他的武功已经废了。我手里的银针用来救人，不用来取命。'),('花生','俺收拳。以后你们莫再欺负人。'),('旁白','晓霜挡在伤者前，待贺陀罗与哈里斯扶持着离开，才回身去看五宝。')],
 'treatment':[('萧千绝','老夫害了你们一家，你只消不管，便可报仇。为何还来救？'),('花晓霜','眼前是病人。婆婆拿性命止住的仇，不能再从我手里续上。'),('旁白','晓霜按轻重照顾五宝与萧千绝，花生备好清水与包布，幼帝照看药箱。'),('萧千绝','……老夫记下了。')],
 'clinic_departure':[('旁白','启程前，晓霜再望向村口草棚。灯可以留下，救人的规矩也该有人继续记着。'),('花晓霜','明日我们向东走。未办妥的事，今日便向乡亲交代清楚。'),('赵昺','我也要学。以后不做皇帝，只做能帮上忙的人。')],
 'eastline_final':[('旁白','暮色中的官道通向中原。晓霜牵着幼帝，花生挑起担子，金灵儿伏在包袱上。'),('花生','往哪边去找梁大哥？'),('花晓霜','只要他活着，总有重逢的一天。先往有人需要郎中的地方去。'),('旁白','远处林梢，白发的萧千绝默默相随。东西两路由此展开；十年医路，才迈出第一步。')],
}
choices={
 'trial_response':('刑台上的回答',[('ch15_trial_responsibility','认下自己做过的事，也请护友者退到安全处。','梁萧不推诿旧罪。明三秋仍横身在前：认错不等于任人私刑。'),('ch15_trial_question','问群豪：门户与救民，何者才是衡量人的尺度？','梁萧说起修历与免役。公羊羽沉默一瞬，众人的喧声渐低。')]),
 'departure_words':('离开百丈坪前',[('ch15_departure_clear','坦然辞别，不再纠缠眼前恩怨。','梁萧收掌下山。明三秋点头，盼他将才学用在更广阔处。'),('ch15_departure_concern','托亲友照看伤者，也请晓霜保重。','晓霜答应先照看病人再回天机宫。梁萧信她身边尚有亲友。')]),
 'escape_response':('在风雪中求生',[('ch15_escape_mist','稳住内息，借雾寻找侧崖退路。','晓霜屏息辨清落脚处，借一线空隙脱开拘束。'),('ch15_escape_conscience','唤她看一眼白痴儿，争取脱身的一息。','韩凝紫的手略一迟疑。晓霜没有追击，转身护住自己。')]),
 'poison_strategy':('先救花生',[('ch15_poison_observe','稳住花生，指出对方用药自相矛盾。','晓霜以医理拆穿恐吓，争取让花生缓过气来；不提供现实配药步骤。'),('ch15_poison_bluff','借对方疑心，诈称另有奇毒使其后退。','一句虚实难辨的话迫使对方停手，晓霜趁隙照顾花生。')]),
 'medical_loadout':('晓霜与花生：各选四式',[('ch15_medical_loadout_recommended','晓霜：望诊切脉、捻针推宫、龙须取气、神仙倒；花生：金刚护持、曲直弹指劲、金刚破器掌、罗汉解脱身。','按既定四槽装配，不治疗或补充资源。'),('ch15_medical_loadout_alternate','晓霜：望诊切脉、捻针推宫、龙须取气、杏林悬壶；花生：金刚护持、曲直弹指劲、金刚破器掌、伏魔大金刚震。','双方保留闭环核心四槽，改用晓霜支援与花生震阵；不额外恢复。'),('ch15_medical_loadout_keep','保留双方当前四槽。','保留已合法装配的技能。若缺少闭环所需招式，可取消后重新整备。')]),
 'mercy_response':('废武之后如何止戈',[('ch15_mercy_shelter','走到伤者身前，说明银针只为救人。','晓霜挡住五宝的怒气，花生松开拳头。贺陀罗与哈里斯被允许离去。'),('ch15_mercy_stop','请花生收拳，请五宝把余力留给活着的人。','花生退开半步。晓霜坚持先救伤者，父子二人都留下性命。')]),
 'care_order':('照护顺序',[('ch15_care_treasures','先安置五宝，将萧前辈所需用品放在墓石旁。','伤势更急者先得到照护，也保全老人的颜面。'),('ch15_care_equal','逐一核对轻重，亲手把照护用品递给萧前辈。','晓霜不以旧怨分先后，依眼前伤势安排照护。')]),
 'r06_method':('留给后来人的医所',[('ch15_r06_method_a','留下简明草药图谱，由幼帝和阿福抄画辨识。','晓霜选择留下可供学习的图谱，教乡亲先辨风险、再求助郎中。'),('ch15_r06_method_b','整理耐存储备与教学木人，交给阿福看管。','晓霜将虚构药材储备封好，教具只用于游戏内辨识，不提供现实用药或针法。')]),
}
scene_choices={'trial':'trial_response','departure':'departure_words','escape':'escape_response','poison_plot':'poison_strategy','loadout':'medical_loadout','mercy_father':'mercy_response','treatment':'care_order'}
registry={};runtime={'schema_version':1,'chapter':15,'scenes':{},'side_quests':{}};scenes=[];reward=[]
def event(op,id,name='',txn=False,**kw):
 d={'op':op,'id':id,'name':name,'kind':'interact','receipts':[id],'effects':[{'op':'chapter_fifteen_event','id':id}] if txn else []};d.update(kw);return d
def dialogue(id,ls,txn=False):
 refs=[]
 for i,(who,text) in enumerate(ls):
  ref=id if i==0 else id+'_line_%02d'%i;refs.append(ref);registry[ref]={'speaker':who,'kind':'stage' if who=='旁白' else 'dialogue','text':text,'source_document':'04/06','source_id':'MQ-15','adaptation':'chapter-fifteen-source-review.md'}
 return event('dialogue',id,ls[0][1][:28],txn,refs=refs)
def choose(key):
 group='choice_ch15_'+key;title=choices[key][0]
 return [event('choice',group,title,group=group,choice_key=key),event('branch_feedback',group+'_feedback','这一念的回声',group=group,choice_key=key)]
for short,title,m,controller,xp,tx,objective in specs:
 sid='ch15_'+short;seq=[];ls=lines[short]
 # Intro semantic commits only precede an objective when there are two defined commits.
 if short=='loadout':seq+=choose('medical_loadout');seq.append(dialogue('evt_ch15_loadout_committed',ls,True))
 elif short=='battle':
  seq.append(dialogue('evt_ch15_battle_intro',ls[:2]));seq.append(event('objective_battle',objective,'晓霜与花生完成两阶段医武闭环'));seq.append(dialogue('evt_ch15_b12_completed',ls[2:],True))
 else:
  intro='evt_ch15_'+tx[0] if len(tx)>1 else 'evt_ch15_'+short+'_intro'
  seq.append(dialogue(intro,ls[:2] if short=='poison_plot' else ls[:max(1,len(ls)-1)],len(tx)>1))
  if short in scene_choices:seq+=choose(scene_choices[short])
  if short=='clinic_window':seq.append(event('quest_window','side_ch15_r06','留给来人的灯：可整理医所，也可暂且前行'))
  if short=='clinic_departure':seq.append(event('quest_window','confirm_ch15_eastline_departure','远行前确认：尚可完成留灯；离开后本章窗口关闭',deadline=True,effects=[{'op':'chapter_fifteen_event','id':'evt_ch15_r06_window_closed'}]))
  if objective:seq.append(event('world_puzzle',objective,title+' · 亲自完成'))
  if tx:seq.append(dialogue('evt_ch15_'+tx[-1],ls[2:] if short=='poison_plot' else ls[-1:],True))
  else:seq.append(dialogue('evt_ch15_'+short+'_after',ls[-1:]))
 end='evt_ch15_'+short+'_complete';seq.append(dialogue(end,[('旁白',{'eastline_final':'东线行旅由此启程。此处归档第十五章，并非全游戏终点。'}.get(short,'眼前这一程已办妥，继续行旅。'))]))
 for i,e in enumerate(seq):e['step_id']=sid+':%02d'%i
 runtime['scenes'][sid]=seq
 cast=list(dict.fromkeys([who for who,_ in ls if who!='旁白']))
 scenes.append({'id':sid,'title':title,'map_id':'map_ch15_'+m,'style':{'tongzhou':'road','tomb':'forest','road':'road','baizhang':'mountain','cliff':'mountain','clinic':'village','duel':'forest','eastroad':'road'}[m],'cast':cast,'dialogue':[],'choices':[],'objective':title,'completion_gate':{'all_of':[e['id']for e in seq]},'source_refs':['04:SC-15-01—05','06:MQ-15/R06','chapter-fifteen-source-review.md'],'silent_reward':True,'controller':controller})
 if xp:reward.append({'id':'reward_mq15_'+short,'xp':xp,'after_scene':sid,'trigger':end,'silent':True})
side=[]
side.append(dialogue('evt_ch15_r06_accept',[('赵昺','咱们明日走了，再有病人来，这棚子里谁能照应？'),('花晓霜','留下能学的东西，也留下愿意守灯的人。')]))
side.append(dialogue('evt_ch15_r06_survey',[('旁白','两间旧土屋尚能避雨，苦井需要清理。村中阿福认得些字，愿留下帮乡亲。'),('阿福','我没读过许多书，也能学么？'),('花晓霜','先学认真听人说话，不逞能，不把不懂的事装作懂。')]))
side+=choose('r06_method')
side.append(event('puzzle','pz_ch15_r06_clinic_plan','按所选方法整理医所教学与有限储备'))
side.append(event('world_puzzle','world_ch15_r06_clinic_repair','清井、修门、扫地，亲手把风灯挂稳'))
side.append(dialogue('evt_ch15_r06_evening',[('旁白','灯光落在土墙上。幼帝伏在桌边睡去，阿福把抄好的纸仔细压平。'),('阿福','我会照看这里。有人不舒服，先请郎中来，不能自己胡乱作主。'),('花晓霜','病人不分贵贱。路再难走，也别把这盏灯吹灭。')]))
side.append(dialogue('evt_ch15_r06_completed',[('赵昺','我也不回去做皇帝。我想学着把这样的灯点到更远的地方。'),('旁白','幼帝将手书百草单交给晓霜。草庐留给后来者，行旅仍向前。')],True))
for i,e in enumerate(side):e['step_id']='R06:%02d'%i
runtime['side_quests']['R06']=side
side_quests=[{'id':'R06','title':'留给来人的灯','map_id':'map_ch15_clinic','style':'village','cast':['花晓霜','花生','赵昺','阿福'],'dialogue':[],'choices':[],'objective':'整理医所并留下可传承的照护规矩与风灯','completion_gate':{'all_of':[e['id']for e in side]},'completion_memory':'MEM_R06_CLINIC_LANTERN','reward_transaction':'reward_r06_once','xp':400,'source_refs':['06:R06'],'close_before':'confirm_ch15_eastline_departure'}]
choice_groups={}
for key,(title,opts) in choices.items():choice_groups['choice_ch15_'+key]={'title':title,'choice_key':key,'options':[{'id':id,'label':label,'feedback':feedback}for id,label,feedback in opts]}
# Optional memories alter visible dialogue only; never grant a past side quest.
echoes=[
 ('ch15_burial','evt_ch15_joint_burial_completed','MEM_L04_GRANDPARENTS_SAVED',[
  ('花晓霜','你看，刘婆婆牵着孙儿来了。她说是当年樊城获救的祖孙，专程带一碗清水来祭拜爹娘。'),
  ('梁萧','孩子长高了。那时阿雪替他擦过脸……这碗水，我替爹娘接下。')]),
 ('ch15_tomb_return','evt_ch15_tomb_triage_completed','MEM_R04_TRIAGE_ORDER',[
  ('花晓霜','还记得青杏院那一碗温粥。伤病轻重缓急各不同，眼前也一样，先听清、看清，不能因熟识谁就偏向谁。')]),
 ('ch15_mercy_father','evt_ch15_father_son_spared','MEM_R05_GENTLE_STRENGTH',[
  ('花生','俺想起山道上那位老汉。能托住他的力气，也能在这里收回来；不是拳头落得越重，才叫有本事。'),
  ('花晓霜','那日留下的是一条能走的路。今日也一样，止住作恶，留下性命。')]),
]
for scene_id,event_id,tag,echo_lines in echoes:
 e=next(e for e in runtime['scenes'][scene_id] if e['id']==event_id)
 refs=e['refs'].copy()
 for index,(speaker,text) in enumerate(echo_lines):
  ref=event_id+'_memory_%02d'%index
  registry[ref]={'speaker':speaker,'kind':'dialogue','text':text,'source_document':'06','source_id':tag,'adaptation':'chapter-fifteen-source-review.md'}
  refs.append(ref)
 e['memory_tag']=tag;e['memory_refs']=refs
actors={'char_liang_xiao':'梁萧','char_hua_xiaoshuang':'花晓霜','char_huasheng':'花生','char_xiao_yuling':'萧玉翎','npc_zhao_bing':'赵昺','npc_jiuru':'九如','npc_shi_tianfeng':'释天风','npc_ming_sanqiu':'明三秋','npc_qin_bofu':'秦伯符','npc_gongyang_yu':'公羊羽','npc_hua_qingyuan':'花清渊','npc_hua_wuchi':'花无媸','npc_han_ningzi':'韩凝紫','npc_xiao_qianjue':'萧千绝','npc_huozhenren':'火真人','npc_huchi_yin':'忽赤因','npc_hetuoluo':'贺陀罗','npc_harris':'哈里斯','npc_chang_ning':'常宁','npc_luo_mingqi':'骆明绮','follower_baichier':'白痴儿','follower_jinlinger':'金灵儿','npc_ch15_afu':'阿福','npc_ch15_wubao':'中条五宝'}
content={'schema_version':1,'chapter':15,'quest_id':'MQ15','title':'百丈分离','status':'development_candidate','completion_memory':'MEM_MQ15_PARTING_AT_BAIZHANG','scenes':scenes,'side_quests':side_quests,'choice_groups':choice_groups,'dialogue_registry':registry,'reward_transactions':reward,'source_mapping':{'primary':['04:SC-15-01—05','06:MQ-15/R06','07:B12/GRANT_HS06_BASE/GRANT_CO04_TRIAL'],'decisions':'chapter-fifteen-source-review.md','map_ids':'Semantic IDs; source MAP/MG numbers are not reused as runtime identity'},'runtime_contract':{'mandatory_xp':3270,'main_xp':2970,'puzzle_xp':0,'encounter_xp':300,'optional_xp':400,'minimum_entry_xp':37700,'minimum_b12_entry_xp':39865,'numbered_bosses':['B12'],'active_skill_slots':4,'permanent_death_revivable':False,'liang_knows_xiaoshuang_survived':False,'liang_hears_death_rumour_this_chapter':False},'currency_budget':{'mandatory':900,'optional':0},'actor_registry':[{'id':id,'name':name}for id,name in actors.items()],'item_registry':[{'id':'item_ch15_r06_child_herb_sheet','name':'幼帝手书的百草单'},{'id':'item_ch15_proposal_gift','name':'朴素的提亲礼'}]}
content['source_decisions']=content.pop('source_mapping')
content['source_mapping']={p.name:{'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'authority':'V3; chapter-fifteen-source-review.md records conflicts'} for p in sorted((ROOT/'docs/design/v3').glob('*.md')) if p.name[:2] in ['01','04','05','06','07','08']}
for name,obj in [('chapter_fifteen.json',content),('chapter_fifteen_runtime.json',runtime)]:
 (ROOT/'game/data'/name).write_text(json.dumps(obj,ensure_ascii=False,indent=2)+'\n')
print('scenes',len(scenes),'main steps',sum(map(len,runtime['scenes'].values())),'dialogue',len(registry),'mainXP',sum(x['xp'] for x in reward))
