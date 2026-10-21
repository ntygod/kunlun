#!/usr/bin/env python3
"""Deterministic chapter13 authored content. Runtime proofs are implemented separately."""
import json,hashlib
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
C={'schema_version':1,'chapter':13,'quest_id':'MQ13','title':'南海鲸波','status':'development_candidate','completion_memory':'MEM_MQ13_CHAOYUN_WILLOW_HAT','scenes':[],'side_quests':{},'choice_groups':{},'dialogue_registry':{},'reward_transactions':[]}
R={'schema_version':1,'chapter':13,'scenes':{},'side_quests':{}}
def scene(key,title,mapid,cast,xp=0):
 sid='ch13_'+key
 C['scenes'].append({'id':sid,'title':title,'map_id':'map_ch13_'+mapid,'style':'village' if mapid=='chaoyun' else 'river','cast':cast.split('、'),'dialogue':[],'choices':[],'objective':title,'completion_gate':{'all_of':[]},'source_refs':['03:SC-13-01—04','06:MQ-13/PZ-05','chapter-thirteen-source-review.md'],'silent_reward':True})
 R['scenes'][sid]=[]
 if xp:C['reward_transactions'].append({'id':'reward_mq13_'+key,'xp':xp,'after_scene':sid,'trigger':'evt_ch13_'+key+'_complete','silent':True})
 return sid
def event(sid,op,id,name,lines=(),txn=False,**extra):
 e={'op':op,'id':id,'name':name,'kind':'interact','receipts':[id],'effects':[{'op':'chapter_thirteen_event','id':id}] if txn else [],'step_id':sid+':%02d'%len(R['scenes'][sid])}
 if lines:
  e['refs']=[]
  for i,line in enumerate(lines):
   speaker,text=line.split('|',1) if '|' in line else ('旁白',line)
   did=id if i==0 else id+'_line_%02d'%i
   C['dialogue_registry'][did]={'speaker':speaker,'kind':'stage' if speaker=='旁白' else 'speech','text':text};e['refs'].append(did)
 e.update(extra);R['scenes'][sid].append(e);C['scenes'][-1]['completion_gate']['all_of'].append(id)
def say(sid,key,title,*lines,txn=False):event(sid,'dialogue','evt_ch13_'+key,title,lines,txn)
def play(sid,op,id,title):event(sid,op,id,title)
def choice(sid,key,title,options):
 group='choice_ch13_'+key;C['choice_groups'][group]={'title':title,'choice_key':key,'options':[{'id':('ch13_water_'+suffix if key=='water_priority' else 'ch13_'+key+'_'+suffix),'label':label,'feedback':feedback} for suffix,label,feedback in options]}
 event(sid,'choice',group,title,group=group,choice_key=key)
 event(sid,'branch_feedback',group+'_feedback','这一念的回声',group=group,choice_key=key)
def echo(sid,key,tag,normal,remembered):
 say(sid,key,'旧日回响',normal)
 memory_id='evt_ch13_'+key+'_remembered'
 speaker,text=remembered.split('|',1)
 C['dialogue_registry'][memory_id]={'speaker':speaker,'kind':'speech','text':text}
 R['scenes'][sid][-1].update(memory_tag=tag,memory_refs=[memory_id])
def end(sid,text):say(sid,sid[5:]+'_complete','继续行旅',text)
P='梁萧、花晓霜、柳莺莺、花生'
s=scene('yashan_vow','此去只为一个孩子','yashan',P+'、赵昺',80)
say(s,'huasheng_rejoined','同行赴崖山','旁白|离开蚩尤林后，三人回到医棚接上花生与留守的行囊。快雪驮着药箱，白痴儿与金灵儿跟在岸边。','花生|俺守着病人，等得心焦。要是又有人受难，俺也去。','梁萧|崖山的消息传来了。赵家兄弟仍是孩子，我答应过要护他们平安。此去不是替谁复国。',txn=True)
say(s,'old_vow','阿雪的旧愿','花晓霜|阿雪姐姐护下他们时，也只望孩子活着。','柳莺莺|那就救人。江山姓什么，不该拿一个八岁娃娃来抵。');end(s,'暮春海风夹着烟灰，众人沿连船踏入崖山火线。')
s=scene('yashan_rescue','火船间护住幼童','yashan',P+'、赵昺、陆秀夫、云殊',25)
say(s,'royal_child','龙袍里的孩子','赵昺|梁叔叔，我认得你。哥哥被吓病了，再没有醒来。我不要再做皇帝！','花晓霜|先把这沉衣脱下。跟着我呼吸，我们带你离开。','旁白|陆秀夫在船舷高处悲号，火缆逼近御舱。梁萧必须先稳住救援路线。')
play(s,'world_puzzle','world_ch13_yashan_rescue','走过断板、救护幼童、安排铁锚接应')
say(s,'child_protected','铁锚护童','旁白|陆秀夫负帝投入波涛。花生奋力抛出铁锚，梁萧指住浪头，柳莺莺斩断火缆，把幼童与抢功的哈里斯一道拉上接应船。','梁萧|赵昺，抓紧。你能活，不必替任何人死。',txn=True);end(s,'陆秀夫沉入海中，残船载着敌友冲离火海。')
s=scene('temporary_alliance','背靠背的一掌','yashan',P+'、赵昺、云殊、贺陀罗',20)
say(s,'yun_alliance','救童的短暂联手','贺陀罗|把小皇帝交出来！','云殊|梁萧，先挡住他们！','旁白|三才掌与大逆诛心掌同源而发，二人仅为眼前护童短暂并肩。此刻的合力不是永久归队，也没有抹去旧债。',txn=True);end(s,'柳莺莺以暗器迫退追兵，残帆被暴风卷向外洋。')
s=scene('sea_betrayal','背后一掌','drift',P+'、赵昺、云殊、贺陀罗、哈里斯、阿滩',25)
say(s,'liang_overboard','梁萧坠海','旁白|贺陀罗为夺水粮残杀水手，血腥引来巨鲸。梁萧背对云殊护住孩子，云殊却趁掌力相持从后偷袭。','柳莺莺|梁萧——！','花晓霜|柳姐姐，不能跳！孩子还在，花生还在！','旁白|黑浪吞去梁萧。船上人只知他失踪，不能凭视角切换提前知道他仍活着。',txn=True);end(s,'柳莺莺压住哭声，带晓霜与花生退守后舱。')
s=scene('storm_rigging','孤舟由我掌缆','drift','柳莺莺、花晓霜、花生、赵昺、云殊、贺陀罗',25)
say(s,'rigging_orders','守住后舱','柳莺莺|花生守门，晓霜护孩子。把断索收回来，我来扣住船帆。','花晓霜|你手掌都磨破了。让我替你扎一扎。','柳莺莺|等浪过去。现在谁都不能松手。')
play(s,'world_puzzle','world_ch13_storm_rigging','柳莺莺沿甲板扣缆、整理断索并守住后舱')
say(s,'stern_secured','暂稳孤舟','旁白|缆绳重新绷紧，前后舱之间守住了一线余地。柳莺莺以夺器护人代替逞强伤人。',txn=True);end(s,'镜头离开孤舟。远处海面上，一只手攀住鲸背。')
s=scene('whale_back','独附巨鲸','whale','梁萧',20)
say(s,'whale_survival','另一边的海','旁白|梁萧攀住母鲸背脊，盐水刺进伤口。没有人替他指路，只有鲸歌从深海一声声传来。','梁萧|他们还在船上。我得活着回去……先听清这一呼一吸。');end(s,'潮声未停，孤舟的断梁又在浪中下沉。')
s=scene('huasheng_brace','怕水也不能放手','drift','柳莺莺、花晓霜、花生、赵昺',20)
say(s,'brace_fear','断梁压舱','花生|俺怕水……可俺一松手，你们就没地方站了。','柳莺莺|看着我，别看海！一步一步把梁托住。')
play(s,'world_puzzle','world_ch13_huasheng_brace','花生实际撑住断梁、护住舱内同伴')
say(s,'huasheng_braced','千钧有托','花晓霜|你不是不会怕，是怕也不肯丢下人。','旁白|花生把护体之力用在自己与同伴之间，悟得罗汉解脱身的守护。',txn=True);end(s,'晓霜拿起药箱，去换取伤者和孩子的一口淡水。')
s=scene('cabin_treatment','敌伤也须止血','drift','柳莺莺、花晓霜、花生、赵昺、哈里斯、阿滩',20)
play(s,'world_puzzle','world_ch13_cabin_treatment','晓霜护童、取净布、包扎伤者并换取淡水')
say(s,'healer_exchange','护童与换水','旁白|阿滩伸手劫持孩子，晓霜以九阴毒掌迫退他。哈里斯被鲨鱼咬伤，她仍俯身救治，以停杀换来三碗淡水。','花晓霜|先把刀放下。我救你，不是答应你继续害人。','柳莺莺|药给你，水留下。谁再靠近孩子，先过我这一关。',txn=True);end(s,'油灯照着染血的药布。海的另一边，梁萧学着随鲸歌调息。')
s=scene('thirteen_breaths','十三段潮息','whale','梁萧',25)
say(s,'breath_observation','听鲸歌辨潮','梁萧|大海从不与波浪硬拗。绵长之息，原来有收有放。')
play(s,'puzzle','pz_ch13_whale_breath','观察鲸歌潮汐，逐段完成十三段吐纳')
say(s,'whale_breath_learned','鲸息初成','旁白|十三段吐纳逐一接续。梁萧正式领悟鲸息功，不是凭一次对话补满既有伤损。','梁萧|气息通了，归路还得自己寻。',txn=True);end(s,'鲸背随潮起落，孤舟上还剩最后的水筒。')
s=scene('water_council','两竹筒水与三夜守望','drift','柳莺莺、花晓霜、花生、赵昺、哈里斯',25)
choice(s,'water_priority','有限淡水先给谁',[('vulnerable','先护孩子和重伤者，我们以雨水润唇。','晓霜把水分向幼童与伤者，自己只接一点雨水。'),('workers','先给撑船的花生和体弱晓霜。','花生把自己的份推回孩子面前，晓霜也留出一半。')])
play(s,'puzzle','pz_ch13_water_watch','按分水方案安排三夜守望与补给，不让同伴孤守')
say(s,'water_shared','水尽情未尽','旁白|分水与守夜都由众人实际完成。两人的手在小小竹筒旁相遇，再没有争夺的意思。',txn=True);end(s,'夜深后，柳莺莺终于肯放下刀，听晓霜说一句心里话。')
s=scene('sisters_watch','此夜同心','drift','柳莺莺、花晓霜、花生、赵昺',20)
say(s,'sisters_truth','说尽前嫌','柳莺莺|我断过你的手，伤过你的肩。你怎么还替我包扎？','花晓霜|柳姐姐在黑牢里的苦，我不能替你受。如今海上只有你明白我，我也明白你。')
choice(s,'sisters_response','以何回应晓霜',[('embrace','伸手抱住晓霜。','柳莺莺把她揽入怀中，许诺同生共归。'),('share','把雨水推回她唇边。','二人分饮苦涩雨水，彼此把后背交给对方。')])
say(s,'sisters_reconciled','霜刃飞索同舟渡','旁白|前嫌并未从记忆里抹掉，却不再支配她们。孤舟守夜后，二女正式获得霜刃飞索·孤舟惊鸿渡。',txn=True);end(s,'清晨，幼鲸的哀鸣从远处传来。')
s=scene('whale_harpoon','拔去幼鲸断叉','whale','梁萧',20)
say(s,'calf_hurt','鲸母子','旁白|幼鲸背上嵌着断叉，母鲸徘徊不去。梁萧俯身辨清伤口与海流，再一步步靠近。')
play(s,'world_puzzle','world_ch13_whale_harpoon','靠近幼鲸、稳定身体并拔除断叉')
say(s,'calf_freed','载我归去','旁白|断叉离身，母鲸长鸣，载着梁萧追向孤舟。','梁萧|多谢你。我的同伴，也在等我。',txn=True);end(s,'残破甲板在浪间出现，柳莺莺与晓霜不敢相信自己的眼睛。')
s=scene('reunion_oath','鲸海归来结金兰','wreck',P+'、赵昺、贺陀罗、云殊',25)
say(s,'brother_oath','以生死相托','柳莺莺|臭小子！你还知道回来！','花晓霜|活着……真的活着。','梁萧|花生，你护住他们，就是护住了我的命。愿与兄弟同担生死。','花生|俺没什么本事，只是不肯松手。','旁白|梁萧与花生撮土为香结义，以巧辅拙迫退贺陀罗。',txn=True);end(s,'陆地在望，贺陀罗却暗中凿破了船底。')
s=scene('sinking_rescue','沉船夺艇','wreck',P+'、赵昺、快雪、白痴儿、金灵儿',25)
say(s,'wreck_breach','抢救同舟人','旁白|贺陀罗杀死阿滩，凿船后夺艇逃离。快雪陷入崩塌的底舱，海水迅速灌入。花生甩出长绳，梁萧必须夺艇接回众人。')
play(s,'world_puzzle','world_ch13_sinking_rescue','甩绳夺艇，接应二女、孩子及同伴撤离')
say(s,'kuaixue_drowned','快雪沉入海中','旁白|众人登艇，白痴儿与金灵儿被护上木板，胭脂也被牵入浅滩。快雪没有再浮起。晓霜抱紧湿透的药箱，久久没有说话。','花晓霜|你驮我走过那么远……往后的路，我自己走。',txn=True);end(s,'荒岛上搭起简陋棚屋，失去的同伴不会随着换图重现。')
s=scene('island_tide','碧海惊涛初悟','island',P+'、赵昺',25)
say(s,'tide_palm_learned','一掌叠九潮','旁白|梁萧立在礁边，看海流一层层回卷。涡旋、陷空、滔天，刚柔之力在一掌中相接。','柳莺莺|既是在碧海惊涛里悟的，就叫碧海惊涛掌！','梁萧|好。不是为了逞胜，是为了让大家有条归路。',txn=True);end(s,'幼童听见云殊又谈起拥立与复国，缩回晓霜身后。')
s=scene('child_choice','他可以不做皇帝','island',P+'、赵昺、云殊、贺陀罗',20)
say(s,'child_declines_throne','假病止兵','赵昺|我不回去打仗。我想跟晓霜姐姐学治病。','旁白|梁萧与晓霜用假病之计止住云殊挟童复战的念头；不向玩家展示现实诊疗或用药步骤。','花晓霜|他是一个人，不是你复国的旗。','旁白|随后两人听见云殊与贺陀罗密谋杀梁夺船。',txn=True);end(s,'梁萧决定明滩造伪船，暗谷另辟生路。')
s=scene('ship_materials','明滩暗谷备木','island',P,25)
say(s,'materials_plan','造船的两张图','梁萧|明滩用朽木撑起外架，暗谷用铁力木做水密舱。不能把好木都耗在假船上。','花生|重木归俺。你们把次序说清楚就成。')
play(s,'world_puzzle','world_ch13_ship_materials','花生搬运木料并按明伪暗真分区放置')
say(s,'ship_materials_ready','材料各归其位','旁白|朽木与铁力木各归其位，谷口的声势掩住内侧工声。',txn=True);end(s,'四天工期开始，巡查者每日都要来两次。')
s=scene('hidden_ship','四日五行楼船','island',P,25)
say(s,'secret_ship_plan','明修暗造','柳莺莺|我在明滩敲给他们听，你们只管造真船。','花晓霜|五舱的接缝我来封。水轮受力处，还要梁萧哥哥再验一遍。')
play(s,'puzzle','pz_ch13_decoy_ship','四日统筹人力木材、伪船声势与五舱水轮')
say(s,'secret_ship_completed','船成不惊敌','旁白|四日暗造完成。明滩伪船留下暗漏，五行楼船藏在山坳水口，足以载众人归去。',txn=True);end(s,'起锚之前，梁萧明确选择独自断后的四式。')
s=scene('departure_loadout','礁前四式整备','reef','梁萧、柳莺莺、花晓霜、花生',15)
choice(s,'departure_loadout','独自断后，选择四主动槽',[('keep','保留已有四式。','梁萧保留现有装配，不把新学所有招式自动塞入四槽。'),('recommended','观势、三才归元、飞星掌、碧海惊涛掌。','梁萧选择观察、反制与新掌，准备应对公开火攻和重刺。'),('alternate','三才归元、龙须劲、飞星掌、碧海惊涛掌。','梁萧以破罩、反击和群体断蓄力配合独守。')])
say(s,'loadout_committed','守住跳板','梁萧|我挡住他们，你们起锚。进度未满，谁也别回头。','花生|俺踩水轮！','柳莺莺|缆索交给我，等着接你上船。',txn=True);end(s,'云殊与贺陀罗冲上礁岸。')
s=scene('island_departure','孤身断后','reef','梁萧、云殊、贺陀罗',300)
play(s,'objective_battle','enc_ch13_island_departure','梁萧单人断后，至少五轮并守至起锚100%')
say(s,'b10_survived','借浪登船','旁白|起锚完成，梁萧借最后一掌反震跃上甲板。云殊与贺陀罗被留在礁岸，均未被杀死。','梁萧|走！我们已不欠这场争斗。',txn=True);end(s,'鲸群在外海护航，前方仍须辨方向，不能任船随波漂远。')
s=scene('star_navigation','日影牵星返惠州','homebound',P+'、赵昺',300)
say(s,'navigation_setup','白昼日晷，夜里牵星','梁萧|日影定东西，星位辨南北。先把指北校准，再定归航线。','花晓霜|天机宫学过的测影，如今真能带我们回家。')
echo(s,'k01_echo','MEM_K01_GNOMON_SHADOW','梁萧|把眼前日影测准，再用星位互校，不能只凭旧印象。','梁萧|当年在灵台立表测影，几寸影子也要反复核对。今日在海上，还是这个道理。')
play(s,'puzzle','pz_ch13_star_navigation','以日晷影长与牵星板仰角校准惠州航向')
say(s,'navigation_completed','循星北归','旁白|日影与星位互相校核，海船终于驶向广东岸线。',txn=True);end(s,'船头的孩子脱下龙袍，抱起一个小药包。')
s=scene('huizhou_return','从此只做赵昺','homebound',P+'、赵昺',250)
say(s,'child_chooses_medicine','孩子自己的路','赵昺|我不做皇帝了。我想学医，像晓霜姐姐那样救人。','花晓霜|好。先从辨草、记名学起，不急着治病。','梁萧|你能自己选，这一趟才不算白来。',txn=True);end(s,'众人抵达惠州，朝云墓前柳色如烟。')
s=scene('chaoyun_warning','离别之前','chaoyun',P+'、赵昺',150)
say(s,'departure_warning_seen','此去不再同路','旁白|惠州停泊是本段不可逆离别前的停留点。柳莺莺将自主离队，旧支线只保留已取得的记事与物品，不在此补发错过的奖励。可先返回菜单保存、查看记事，再继续。','柳莺莺|南海这一程都记着。该带走的东西，你们再点一点。',txn=True);choice(s,'departure_confirmation','继续将进入柳莺莺自主离别',[('continue','已查看行旅，继续朝云离别。','众人把未尽的记事收好，接受此后的路不再完全相同。')]);end(s,'夜半，晓霜悄悄提起药箱，想替另外两人让出一条路。')
s=scene('sisters_farewell','不做彼此的影子','chaoyun','柳莺莺、花晓霜',200)
say(s,'sisters_farewell_truth','晓霜的退让与柳的选择','旁白|晓霜原想留下安神汤，独自负药箱远行。柳莺莺识破她的心意，已在六如亭前等候。','柳莺莺|你的药能瞒过臭小子，瞒不过我。要走也是我自己走，不要你把他让来让去。','花晓霜|柳姐姐……我们可以一道行医，一道走。','柳莺莺|我不做你们的影子，也不让你受委屈。海上那些日子，我已想明白了。');end(s,'柳莺莺拿起昔日柳笠，重新编紧松开的柳条。')
s=scene('chaoyun_farewell','柳笠策马去','chaoyun','柳莺莺、花晓霜、梁萧',200)
say(s,'willow_hat','带走柳笠，留下心意','柳莺莺|这顶笠我带回天山挡风沙。若欺负晓霜，我千里万里也要回来找你算账。','旁白|她戴上柳笠，牵住胭脂。书信与一盒胭脂留在亭中，笠并未留在墓前。')
echo(s,'r02_echo','MEM_R02_WILLOW_RAIN','柳莺莺|旧笠上的柳条松了，我自己重编便是。','柳莺莺|姑苏桥下那场春雨，还有你补进笠里的那根粗柳条，我都记着。')
play(s,'world_puzzle','world_ch13_chaoyun_farewell','柳莺莺戴笠、牵胭脂走向离别出口')
say(s,'liu_departed','自主挥别','旁白|柳莺莺策马北行，自主离队。这次离别被永久记住，但她仍活着，旧物与成长不被抹除。',txn=True)
choice(s,'farewell_response','梁萧最后的送别',[('retain','上前欲挽马缰，请她留下。','柳莺莺轻扬马鞭荡开挽留，潇洒向晨雾里行去。'),('respect','抱拳一揖，祝她一路珍重。','柳莺莺回首一笑，许下他日天山重逢。')]);end(s,'马蹄声渐远，柳叶落在空出的路侧。')
s=scene('willow_departure','白头之约','chaoyun','梁萧、花晓霜、花生、赵昺',145)
say(s,'white_head_vow','携手以后的路','梁萧|晓霜，别再一个人走。我愿与你修历行医，慢慢走到白头。','花晓霜|那便先把眼前的人照顾好，一天一天走下去。',txn=True)
say(s,'chapter_complete','南海鲸波归档','旁白|第十三章归档。柳莺莺离队的空席仍在，幼童随众人学医；这不是整个故事的终点。',txn=True);end(s,'海风已远，旧愿与新约一同留在行旅记事。')
# Explicit scene-level control survives dialogue, menu and reload as well as live models.
controllers={'sea_betrayal':'char_liu_yingying','storm_rigging':'char_liu_yingying','huasheng_brace':'char_huasheng','cabin_treatment':'char_hua_xiaoshuang','water_council':'char_liu_yingying','sisters_watch':'char_liu_yingying','ship_materials':'char_huasheng','sisters_farewell':'char_hua_xiaoshuang','chaoyun_farewell':'char_liu_yingying'}
for row in C['scenes']:row['controller']=controllers.get(row['id'][5:],'char_liang_xiao')
# Source mapping is immutable provenance, not generated asset or acceptance claims.
C['source_mapping']={p.name:{'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'authority':'V3; chapter-thirteen-source-review.md records conflicts'} for p in (ROOT/'docs/design/v3').glob('*.md') if p.name[:2] in ['01','03','05','06','07','08']}
C['runtime_contract']={'mandatory_xp':4030,'main_xp':2030,'puzzle_xp':1500,'encounter_xp':500,'optional_xp':0,'pre_b10_main_xp':485,'minimum_b10_entry_xp':33550,'numbered_bosses':['B10'],'active_skill_slots':4,'permanent_death_revivable':False}
C['currency_budget']={'mandatory':800,'optional':0}
C['actor_registry']=[{'id':i,'name':n} for i,n in [('char_liang_xiao','梁萧'),('char_hua_xiaoshuang','花晓霜'),('char_liu_yingying','柳莺莺'),('char_huasheng','花生'),('npc_zhao_bing','赵昺'),('npc_yun_shu','云殊'),('npc_hetuoluo','贺陀罗'),('npc_harris','哈里斯'),('npc_atan','阿滩'),('npc_lu_xiufu','陆秀夫'),('animal_kuaixue','快雪'),('follower_baichier','白痴儿'),('follower_jinlinger','金灵儿'),('animal_yanzhi','胭脂')]]
C['item_registry']=[{'id':'item_ch13_liu_letter','name':'朝云留书','source_document':'03/06','source_id':'SC-13-04/MQ13','permanent':True},{'id':'item_ch13_rouge_box','name':'胭脂盒','source_document':'06','source_id':'MQ13','permanent':True}]
assert sum(r['xp'] for r in C['reward_transactions'])==2030
battle_index=next(i for i,s in enumerate(C['scenes']) if s['id']=='ch13_island_departure')
pre={s['id'] for s in C['scenes'][:battle_index]}
assert sum(r['xp'] for r in C['reward_transactions'] if r['after_scene'] in pre)==485
for name,data in [('chapter_thirteen.json',C),('chapter_thirteen_runtime.json',R)]:
 (ROOT/'game/data'/name).write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n')
print(len(C['scenes']),'scenes',sum(map(len,R['scenes'].values())),'steps',len(C['dialogue_registry']),'dialogue lines')
