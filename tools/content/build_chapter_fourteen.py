#!/usr/bin/env python3
"""Deterministic chapter14 authored content. Runtime proofs are implemented separately."""
import json,hashlib
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
C={'schema_version':1,'chapter':14,'quest_id':'MQ14','title':'紫竹长恨','status':'development_candidate','completion_memory':'MEM_MQ14_ZIZHULIN_DAWN','scenes':[],'side_quests':{},'choice_groups':{},'dialogue_registry':{},'reward_transactions':[]}
R={'schema_version':1,'chapter':14,'scenes':{},'side_quests':{}}
def scene(key,title,mapid,cast,xp=0):
 sid='ch14_'+key
 C['scenes'].append({'id':sid,'title':title,'map_id':'map_ch14_'+mapid,'style':'village','cast':cast.split('、'),'dialogue':[],'choices':[],'objective':title,'completion_gate':{'all_of':[]},'source_refs':['03:SC-14-01—05','06:MQ-14/PZ-06','chapter-fourteen-source-review.md'],'silent_reward':True})
 R['scenes'][sid]=[]
 if xp:C['reward_transactions'].append({'id':'reward_mq13_'+key,'xp':xp,'after_scene':sid,'trigger':'evt_ch14_'+key+'_complete','silent':True})
 return sid
def event(sid,op,id,name,lines=(),txn=False,**extra):
 e={'op':op,'id':id,'name':name,'kind':'interact','receipts':[id],'effects':[{'op':'chapter_fourteen_event','id':id}] if txn else [],'step_id':sid+':%02d'%len(R['scenes'][sid])}
 if lines:
  e['refs']=[]
  for i,line in enumerate(lines):
   speaker,text=line.split('|',1) if '|' in line else ('旁白',line)
   did=id if i==0 else id+'_line_%02d'%i
   C['dialogue_registry'][did]={'speaker':speaker,'kind':'stage' if speaker=='旁白' else 'speech','text':text};e['refs'].append(did)
 e.update(extra);R['scenes'][sid].append(e);C['scenes'][-1]['completion_gate']['all_of'].append(id)
def say(sid,key,title,*lines,txn=False):event(sid,'dialogue','evt_ch14_'+key,title,lines,txn)
def play(sid,op,id,title):event(sid,op,id,title)
def choice(sid,key,title,options):
 group='choice_ch14_'+key;C['choice_groups'][group]={'title':title,'choice_key':key,'options':[{'id':('ch14_'+key+'_'+suffix),'label':label,'feedback':feedback} for suffix,label,feedback in options]}
 event(sid,'choice',group,title,group=group,choice_key=key)
 event(sid,'branch_feedback',group+'_feedback','这一念的回声',group=group,choice_key=key)
def echo(sid,key,tag,normal,remembered):
 say(sid,key,'旧日回响',normal)
 memory_id='evt_ch14_'+key+'_remembered'
 speaker,text=remembered.split('|',1)
 C['dialogue_registry'][memory_id]={'speaker':speaker,'kind':'speech','text':text}
 R['scenes'][sid][-1].update(memory_tag=tag,memory_refs=[memory_id])
def end(sid,text):say(sid,sid[5:]+'_complete','继续行旅',text)
H='char_liang_xiao';X='char_hua_xiaoshuang';S='char_huasheng'
P='梁萧、花晓霜、花生、赵昺'
s=scene('dadu_arrival','帝京隐姓名','observatory',P+'、郭守敬',100)
say(s,'dadu_settled','借一方灯火','旁白|北行至大都，郭守敬收留了梁萧一行。柳莺莺已经戴笠远去；同行的空位提醒着众人，海上旧约仍未散去。','郭守敬|梁老弟，若愿在太史院帮忙，名字不必张扬，算出的道理却可以堂堂正正留给天下人。','梁萧|我只愿把所学用在不必伤人的地方。',txn=True)
end(s,'漏刻声中，众人安顿下来。幼童跟晓霜辨草，花生替院里搬运沉重仪器。')
s=scene('calendar','太史测影校历','observatory','梁萧、郭守敬',100)
say(s,'calendar_setup','景符与缺刻','郭守敬|四十尺高表的影缘模糊，景符小孔能把横梁细影定得清楚。先校影，再合各地测算，莫急着誊成定本。','梁萧|农时差一分，百姓就多受一分辛苦。每一步都要留得下复核的凭据。')
echo(s,'k01_calendar','MEM_K01_GNOMON_SHADOW','梁萧|先看光斑与横梁的关系，不能拿一个背熟的数替代观察。','梁萧|当年灵台的短表，如今成了太史院的高表。重差测影的道理仍要逐寸核对。')
play(s,'puzzle','pz_ch14_calendar','移动景符定影，校核缺刻与回归年')
say(s,'calendar_completed','授时为农桑','郭守敬|三百六十五点二四二五日！以此数定岁实，终于能把各处记录合起来。','梁萧|历法准一刻，便少误一季农桑。先生，这才是才学该去的地方。',txn=True);end(s,'校勘稿与测影记录一同封存。')
s=scene('alley_clinic','城南药香','alley','花晓霜、花生、赵昺',45)
say(s,'clinic_arrival','眼前的病家','花晓霜|先替他们挡风、清出通路，再把药包按记号分开。赵昺，你替我记下谁还在等。','赵昺|我记得。每个人都有名字。')
play(s,'world_puzzle','world_ch14_alley_clinic','晓霜安置候诊人、整理药包并护住小巷通路')
say(s,'clinic_completed','一盏灯一家人','旁白|晓霜逐户安顿病人，花生替老人送回米粮。赵昺认真核对门牌，不让等候的人被遗忘。',txn=True);end(s,'晚间，太史院的灯还亮着。')
s=scene('night_companionship','灯下同守','observatory','梁萧、花晓霜',35)
say(s,'night_draft','错页也留下','梁萧|这几处差数总合不上。我再算一遍。','花晓霜|我陪你。算错的那页先别扔，明早也许还用得上。')
echo(s,'r01_draft','MEM_R01_KEEP_DRAFT','梁萧|留着改过的痕迹，才能知道错在哪里。','梁萧|当年那本未合的算册，你也这样替我留着。如今再难，我不会先把错页撕了。')
choice(s,'night_reply','晓霜替他拾起落下的笔',[('share','把算稿推到两人之间。','梁萧放慢语速，把难处一点点说给晓霜听。'),('rest','收好错稿，先陪她喝碗热汤。','灯火暂歇，未解的算题留待天明，不再成为独自硬撑的理由。')]);end(s,'冬雪退去，城中渐渐传来佛诞法会的消息。')
s=scene('festival_mother','佛前不敢相认','festival',P+'、全太后、九如',45)
say(s,'mother_recognized','香客如海','赵昺|娘！我是昺儿！你看看我！','全太后|小施主认错人了……贫尼尘缘已尽，不识得什么昺儿。快走，莫平白丢了性命。','花晓霜|她不是不认你，是怕有人盯着。先跟姐姐退到栏外。','旁白|全太后背过身去，攥紧的衣袖里落满眼泪。梁萧看见殿外密宗耳目正在靠近。',txn=True);end(s,'释天风突然抢夺供果，香客惊散，九如现身护住人群。')
s=scene('festival_cover','面具下护人','festival',P+'、九如、释天风',45)
say(s,'festival_pressure','不把人群当战场','梁萧|花生，先护住孩子和老人。我戴上面具引开他们，别让人群挤倒。','九如|梁小友，手下留人。')
play(s,'world_puzzle','world_ch14_festival_cover','梁萧分开拥挤人群、引开追逐并护送幼童')
say(s,'festival_cleared','暂避耳目','旁白|梁萧与九如合力解开追逐，把冲突引出香客之间。母子终究未能相认，赵昺仍望着尼庵的方向。',txn=True);end(s,'孩子只想再看母亲一眼。众人商量夜里去无色庵探望。')
s=scene('nunnery_entry','夜潜无色庵','nunnery',P+'、九如',40)
say(s,'night_visit','愿望不是旗号','赵昺|我不叫她娘也成，我只想知道她过得好不好。','花晓霜|我们轻轻进去，不惊动旁人。若不安全，就先回来。','梁萧|只为探亲，不为争位。花生守住退路。')
choice(s,'night_approach','临近庵门',[('listen','先停在墙根听清守卫脚步。','梁萧记下巡行间隙，领众人避开廊灯。'),('comfort','先安抚幼童，再随九如绕入侧门。','赵昺点头收住哭声，握紧晓霜的手。')]);end(s,'侧院里忽然传来巨响，释天风追至，将一名士卒抛向九如。')
s=scene('nunnery_rescue','接住被抛来的人','nunnery',P+'、九如、释天风',45)
say(s,'soldier_thrown','不以人挡掌','九如|他也是一条命！','旁白|九如接住士卒，却因此硬受一掌，气息顿挫。梁萧抢入院中，为众人解开围困。')
play(s,'world_puzzle','world_ch14_nunnery_rescue','护开受伤士卒、接应九如并解出院中退路')
say(s,'jiuru_injured','神仙倒解围','旁白|梁萧施展神仙倒解围，九如将士卒放到安全处，伤势却已难以再战。','花生|师父，俺扶你！',txn=True);end(s,'烟雾从暗廊涌来。梁萧回首时，晓霜与幼童所在的石阶已空。')
s=scene('abduction','玉罗汉落阶','nunnery','梁萧、花生、九如',30)
say(s,'xiaoshuang_abducted','两人被掳','旁白|密宗影卫借乱掳走晓霜与赵昺，只留下半枚玉罗汉。晓霜与众人失散，只能设法追踪救回。','梁萧|花生，送九如大师到安全处，再同我去大天王寺。','九如|老衲赴不了约了。花生，你代我去。破阵救人，不可杀戮无辜。',txn=True);end(s,'花生收紧袈裟，向寺门走去。')
s=scene('temple_gate','石狮破门','temple_gate','梁萧、花生',85)
say(s,'gate_blocked','铜门不启','花生|快把晓霜姐姐和孩子放出来！','梁萧|门可破，人不可伤。先看清狮台受力，再抬。')
play(s,'world_puzzle','world_ch14_stone_lion','花生稳足、抬起石狮并破开封闭山门')
say(s,'stone_lion_mastered','伏魔震初成','旁白|花生举狮撞开铜门，震地之力在一声长喝中贯通。伏魔大金刚震基础式正式掌握，尚未靠合招代替破阵。',txn=True);end(s,'前殿金刚杵阵已列开，梁萧与花生停下整备。')
s=scene('temple_loadout','兄弟戒杀整备','temple_hall','梁萧、花生',30)
choice(s,'temple_loadout','寺内戒杀，选择双人四式',[('recommended','梁：观势、龙须、飞星、碧海；花生：破器、解脱、巨灵、伏魔震。','兄弟各取四式，兼顾观察、破器与解除定身。'),('alternate','梁：三才、龙须、飞星、碧海；花生：破器、解脱、巨灵、伏魔震。','梁萧改用三才迎击，花生仍以四式破阵护人。')])
say(s,'temple_loadout_committed','先记戒律','梁萧|阵中僧人并非该死之人，失去战力便停手。','花生|俺记着。先破兵刃，再找阵眼。',txn=True);end(s,'护法上师合十，铜轮深处传出沉重的转动声。')
s=scene('temple_battle','大天王寺戒杀破阵','temple_hall','梁萧、花生、护法上师',50)
play(s,'objective_battle','enc_ch14_datianwang_temple','双人非致命破阵，解除节点后震塌四轮')
say(s,'b11_completed','阵破而人存','旁白|守寺僧人失去战力而未丧命，四座铜轮崩落。梁萧与花生收势停手；兄弟终于能将九宫巨灵之势合而为一。',txn=True);end(s,'内殿的门缓缓打开，八思巴端坐莲花座上。')
s=scene('dharma','万法归一归何处','temple_hall','梁萧、花生、八思巴、赵昺',50)
say(s,'dharma_question','一与苍生','八思巴|万法归一，天下归元，苍生方免兵燹。施主何苦逆天而行？','梁萧|若所谓归一只是百姓的白骨，我不能把这样的答案称作慈悲。')
play(s,'puzzle','pz_ch14_buddhist_debate','听清机锋，追问归一所归并回应苍生之苦')
say(s,'dharma_answered','水汽金莲散','梁萧|国师说万法归一，那一又归于何处？','八思巴|一归万有，一归真如。','梁萧|若归一的代价是千万无辜化作焦土，那一归之所便不是慈悲。','旁白|水汽与灯火所成的法相散去。八思巴拨珠的手停了下来。',txn=True);end(s,'八思巴合十长叹，命人解开幼童的绳索。')
s=scene('emperor_released','放还幼童','temple_hall','梁萧、花生、八思巴、赵昺',40)
say(s,'emperor_released','先送孩子走','赵昺|梁叔叔！晓霜姐姐被断臂的人带走了！','梁萧|花生，先把他送回九如大师身边。我问清晓霜下落便来。','八思巴|晓霜姑娘已被萧冷带往西山。老衲欠他旧恩，不得不留施主片刻。',txn=True);end(s,'梁萧抬头，殿外又有身影封住归路。')
s=scene('wheel_capture','车轮力竭','temple_hall','梁萧、八思巴、萧冷',40)
say(s,'relay_pressure','不是另一场胜利','旁白|为偿萧冷昔年的救命之恩，八思巴继续以密宗车轮相困。梁萧担心晓霜，接连应对，已无暇调息。他只想尽快脱身，去找晓霜。')
play(s,'world_puzzle','world_ch14_wheel_capture','梁萧护住退路、化解连续围困，最终力竭受制')
say(s,'liang_captured','被带往西山','旁白|车轮相困终于耗尽梁萧余力。萧冷趁隙制住他，将他带往紫竹林。花生与幼童已经离寺，殿中只剩他一人。',txn=True);end(s,'车轮碾过雪泥，西山紫竹渐渐遮住天光。')
s=scene('zizhu_reunion','十年一声娘','zizhu','梁萧、花晓霜、萧玉翎、萧冷',25)
say(s,'mother_reunited','竹舍前相见','梁萧|娘……萧儿找了你整整十年。','萧玉翎|萧儿，你都长这么大了。快走，别再为我陷在这里。','萧冷|玉翎师妹，我只是想逼你离开这座牢笼……','旁白|晓霜受制于石坛旁。萧玉翎苍白的鬓角与颤抖的手，让梁萧看清这十年并无安稳富贵。',txn=True);end(s,'林梢一声冷笑，萧千绝落在石碑前。')
s=scene('father_truth','白水湾旧债','zizhu','梁萧、花晓霜、萧玉翎、萧冷、萧千绝',0)
say(s,'father_truth_revealed','掌中暗伤','萧千绝|三赌虽让梁文靖赢去半招，老夫最后一掌已把阴劲打入他心脉。他苟延几年，不过是掌下一缕孤魂。','萧玉翎|师父……你竟一直骗我！','梁萧|爹不是病死的。你杀我生父，又让娘为你守了十年毒誓！',txn=True)
choice(s,'mother_protection','面对跪地哀求的母亲',[('support','先扶起母亲，再面对萧千绝。','梁萧扶母亲离开掌风，却无法压住心中骤起的悲愤。'),('shield','站到母亲身前，不许她再受威胁。','梁萧以身体挡住萧千绝的视线，掌中劲力越蓄越深。')]);end(s,'母亲先设法解开晓霜受制的穴道，林中对峙已无法挽回。')
s=scene('zizhu_duel','两股掌风之间','zizhu','梁萧、花晓霜、萧玉翎、萧冷、萧千绝',0)
say(s,'xiaoshuang_freed','先护住她','萧玉翎|晓霜，快离开掌风！','旁白|萧玉翎救下晓霜。梁萧与萧千绝却已被旧仇推向决死相搏；晓霜虽重获自由，却来不及插入两人之间。',txn=True)
play(s,'world_puzzle','world_ch14_zizhu_duel','梁萧应对掌风、护开旁人，推进不可逆剧情对峙')
say(s,'duel_converged','双掌将发','旁白|归藏剑意、阴阳流与碧海六劲交织。百余合的对峙收束为两股决死掌力，谁都未肯退让。',txn=True);end(s,'萧玉翎看见儿子与师父即将同归于尽，纵身冲入二人之间。')
s=scene('mother_intervenes','慈母阻掌','zizhu','梁萧、花晓霜、萧玉翎、萧冷、萧千绝',0)
say(s,'mother_struck','不愿再失去谁','萧玉翎|不要——！','旁白|两股掌风同时击中萧玉翎。白光一闪，她倒入梁萧怀中。掌力来自儿子与师父两方，已经无法收回。','梁萧|娘！我不要报仇了，我带你回华山！',txn=True);end(s,'母亲攥住梁萧的手，余下的话已轻得几乎听不见。')
s=scene('mother_vow','永不寻仇','zizhu','梁萧、花晓霜、萧玉翎、萧冷、萧千绝',0)
say(s,'mother_last_words','最后的托付','萧玉翎|萧儿……答应娘，不要再向师父报仇。不要让这条仇恨的路再走下去。','梁萧|娘，我听你的。你别走。')
choice(s,'mother_vow','接住母亲最后的托付',[('swear','泣血立誓，不再寻仇。','梁萧一遍遍答应。母亲终于松开紧攥的手。'),('bow','俯身叩首，以行动承诺。','梁萧攥住衣角，向母亲郑重叩首，接受这份不可反悔的托付。')])
say(s,'mother_died','紫竹止仇','旁白|萧玉翎含泪而逝。梁萧抱紧她渐冷的身体，方才所有求胜之念尽成空白。',txn=True);end(s,'萧冷望着玉翎的遗体，终于看清自己的执念害了谁。')
s=scene('xiao_leng_end','执念的尽头','zizhu','梁萧、花晓霜、萧冷、萧千绝',0)
say(s,'xiao_leng_died','无可追回','萧冷|玉翎师妹，是我害了你。','旁白|萧冷在悔恨中自尽，竹叶落下，遮住了地上的刀影。萧千绝顷刻白头，僵立无言。',txn=True);end(s,'梁萧抱着母亲，眼中的生气一点点沉下去。晓霜迈过碎竹，走到他身前。')
s=scene('break_blade','晓霜挡在身前','zizhu','梁萧、花晓霜、萧千绝',0)
say(s,'despair','先把剑放下','梁萧|阿雪、三狗、娘……我这一身才学，究竟护住了谁。','花晓霜|梁萧哥哥，看着我。你娘舍下性命救你，不是要你随她而去。先把剑交给我。')
play(s,'world_puzzle','world_ch14_break_blade','晓霜靠近梁萧、接下利刃并挡住继续逼迫')
say(s,'qianjue_departed','斥退仇恨','花晓霜|萧千绝，你赢了武功，却把身边的人一个个逼走。天下第一，不能抵一个活人的性命！','旁白|萧千绝失魂退入风雪。晓霜留下，始终守在梁萧身边；不再让任何人以仇恨逼迫他。',txn=True);end(s,'风声掠过竹梢，长夜仍未过去。')
s=scene('dawn_vigil','寒夜守到天明','dawn','梁萧、花晓霜',0)
say(s,'vigil_words','不是一个人活下去','花晓霜|你愿意护人，便和我一起走。往后看见一个受苦的人，我们就尽力帮一个。今晚先让我陪着你。','旁白|晓霜缓缓走近，蹲下握住梁萧冰冷的双手。她没有追问，也没有催促，只让他知道身边仍有人陪着。')
play(s,'world_puzzle','world_ch14_dawn_vigil','晓霜靠近、握手、安置御寒衣物并守候破晓')
choice(s,'dawn_response','破晓时，梁萧终于回应',[('embrace','回抱晓霜，放声痛哭。','压住多年的悲伤终于流出。晓霜扶住他，等他慢慢缓过气。'),('promise','望着母亲，答应好好活下去。','梁萧接受母亲的止仇之誓，也接受晓霜就在身边的陪伴。')])
say(s,'dawn_vow','为护生而活','梁萧|我不再寻仇。往后的路，与你一道护人。','花晓霜|好。今天先走一步，明天再走一步。',txn=True);end(s,'晨曦照上断竹，远处传来花生与九如的脚步。')
s=scene('southbound','扶柩南归之前','dawn','梁萧、花晓霜、花生、九如、赵昺',0)
say(s,'southbound_ready','有人替你分担','花生|大哥，俺替你抬。俺力气大，走得稳。','九如|回去吧，扶你母亲南归入土为安。','旁白|幼童由九如照护，众人准备扶柩南归。家乡的墓地还在远方，下一程要带母亲回到父亲身边。',txn=True)
say(s,'chapter_complete','紫竹长恨归档','旁白|第十四章行旅归档。母亲与萧冷长眠，柳莺莺仍在自己的归途。梁萧与晓霜带着止仇之誓走向天明。',txn=True);end(s,'南归路长。这不是整个故事的终点。')
controllers={'alley_clinic':X,'temple_gate':S,'break_blade':X,'dawn_vigil':X,'southbound':X}
for row in C['scenes']:row['controller']=controllers.get(row['id'][5:],H)
# Main budget is silent; no purple-bamboo encounter reward or victory popup.
assert sum(r['xp'] for r in C['reward_transactions'])==805, sum(r['xp'] for r in C['reward_transactions'])
C['source_mapping']={p.name:{'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'authority':'V3; chapter-fourteen-source-review.md records conflicts'} for p in (ROOT/'docs/design/v3').glob('*.md') if p.name[:2] in ['01','03','05','06','07','08']}
C['runtime_contract']={'mandatory_xp':2105,'main_xp':805,'puzzle_xp':1000,'encounter_xp':300,'optional_xp':0,'minimum_entry_xp':35595,'minimum_b11_entry_xp':35595,'numbered_bosses':['B11'],'active_skill_slots':4,'permanent_death_revivable':False,'purple_bamboo_combat_rewards':False}
C['currency_budget']={'mandatory':850,'optional':0}
C['actor_registry']=[{'id':i,'name':n} for i,n in [(H,'梁萧'),(X,'花晓霜'),(S,'花生'),('char_liu_yingying','柳莺莺'),('npc_guo_shoujing','郭守敬'),('npc_zhao_bing','赵昺'),('npc_quan_taihou','全太后'),('npc_jiuru','九如'),('npc_shi_tianfeng','释天风'),('npc_basiba','八思巴'),('char_xiao_yuling','萧玉翎'),('npc_xiao_leng','萧冷'),('npc_xiao_qianjue','萧千绝'),('npc_temple_master','护法上师')]]
C['item_registry']=[{'id':'item_ch14_calendar_record','name':'授时校勘录','source_document':'06','source_id':'PZ06','permanent':True}]
for name,data in [('chapter_fourteen.json',C),('chapter_fourteen_runtime.json',R)]:
 (ROOT/'game/data'/name).write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n')
print(len(C['scenes']),'scenes',sum(map(len,R['scenes'].values())),'steps',len(C['dialogue_registry']),'dialogue lines')
