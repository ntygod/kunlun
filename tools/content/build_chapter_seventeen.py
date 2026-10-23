#!/usr/bin/env python3
"""MQ17 source-mapped development content; never modifies V3 source documents."""
from __future__ import annotations
import hashlib
import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
D=ROOT/'game/data'
H='char_liang_xiao'; L='char_liu_yingying'; F='char_feng_lian'
names={H:'梁萧',L:'柳莺莺',F:'风怜','npc_ch17_taboluo':'塔波罗','npc_ch17_amo':'阿莫','npc_ch17_caifeng':'彩凤','npc_ch17_zhuque':'朱雀','npc_ch17_carpenter':'木工','npc_ch17_widow':'村妇','npc_ch17_child':'小禽村孤儿'}
content=dict(schema_version=1,chapter=17,quest_id='MQ17',title='天山故人',status='development_candidate',completion_memory='MEM_MQ17_FENGLIAN_APPRENTICE',scenes=[],side_quests=[],choice_groups={},dialogue_registry={},reward_transactions=[],currency_budget=0,actor_registry=[dict(id=k,name=v) for k,v in names.items()],item_registry=[dict(id=k,name=v) for k,v in [('item_ch17_tianfa','天罚剑匣'),('item_ch17_red_pine','天山红松小木雕'),('item_ch17_star_map','瀚海手绘星图')]],source_decisions='docs/development/chapter-seventeen-source-review.md',source_mapping=[])
runtime=dict(version=1,chapter=17,scenes={},side_quests={})
mapdata=dict(version=1,development_candidate=True,maps={})
for key,title,style,cast in [('sand','盐地沙丘','sand',[H,F,'npc_ch17_taboluo','npc_ch17_amo']),('trail','双谷狼道','snow',[H,F]),('gate','小禽村寨门','village',[H,L,F,'npc_ch17_caifeng']),('square','村务广场','village',[H,L,F,'npc_ch17_widow','npc_ch17_child']),('roof','西坳新屋','roof',[H,L,F,'npc_ch17_carpenter']),('valley','断魂崖雪谷','snow',[H,L,F]),('caravan','遇害商队','sand',[H,L,F,'npc_ch17_amo']),('evidence','雪谷勘查案','snow',[H,L,F,'npc_ch17_amo']),('lake','天池湖畔','lake',[H,L,F]),('grave','雪中葬友','snow',[H,L,F,'npc_ch17_caifeng'])]:
 mid='map_ch17_'+key
 mapdata['maps'][mid]=dict(name=title,style=style,size=[480,320],spawn=[64,256],walk_bounds=[32,72,416,216],solids=[[200,80,64,40]],water_rects=[],deep_water_rects=[],decor=[[200,80,64,40,'house' if style in ['village','roof'] else 'rock']],actors=[dict(id=a,position=[96+i*52,176]) for i,a in enumerate(cast)],actions={},paths={},source_mapping=dict(source_document='04:SC-17 / 06:MQ-17 / 08:PAL-09',source_id='MG26:'+key,status='development_candidate',note='Authored walkable development layout, not finished pixel art.'))
current=None; node=None; optional=False

def scene(key,title,mapkey,cast,step,source,controller=H,side=False):
 global current,node,optional
 optional=side;current='ch17_'+key
 node=dict(id=current,title=title,map_id='map_ch17_'+mapkey,style=mapdata['maps']['map_ch17_'+mapkey]['style'],cast=[names[x] for x in cast],dialogue=[],choices=[],objective=title,completion_gate={'all_of':[]},source_refs=source,quest_step=step,silent_reward=True,controller=controller)
 (content['side_quests'] if side else content['scenes']).append(node)
 (runtime['side_quests'] if side else runtime['scenes'])[current]=[]
 content['source_mapping'].append(dict(runtime_id=current,resource_type='scene',source_document='04/06',source_id=source,chapter=17,quest_step=step,asset_path='game/data/chapter_seventeen.json',status='development_candidate',decision_note='See chapter-seventeen-source-review.md.'))
 return node

def event(op,key,title,effect='',xp=0,**kw):
 seq=(runtime['side_quests'] if optional else runtime['scenes'])[current];eid='ch17_'+key
 effects=[]
 if effect:effects.append(dict(op='chapter_seventeen_event',id=effect))
 if xp:
  rid='reward_'+eid;effects.append(dict(op='chapter_seventeen_reward',id=rid,xp=xp));content['reward_transactions'].append(dict(id=rid,xp=xp,after_event=eid,silent=True,category=kw.pop('category','main')))
 e=dict(op=op,id=eid,name=title,kind='interact',receipts=[eid],effects=effects,step_id=f'{current}:{len(seq):02d}',**kw);seq.append(e);node['completion_gate']['all_of'].append(eid)
 if op in ['action','puzzle']:
  m=mapdata['maps'][node['map_id']];p=[[124,240],[232,248],[352,240],[352,208],[232,208],[124,208]][len(m['actions'])%6]
  m['actions'][eid]=dict(position=p,radius=22,name=title,description='靠近后按 E。')
 return e

def talk(key,*lines,effect='',xp=0,**kw):
 refs=[]
 for i,line in enumerate(lines):
  speaker,text=line if isinstance(line,tuple) else ('旁白',line);did=f'ch17_{key}_{i:02d}'
  content['dialogue_registry'][did]=dict(speaker=speaker,text=text,kind='stage' if speaker=='旁白' else 'speech',source_refs=node['source_refs'],status='adapted_development_script');refs.append(did)
 return event('dialogue',key,node['title'],effect,xp,refs=refs,**kw)
def action(key,title,effect='',xp=0):return event('action',key,title,effect,xp)
def choice(key,title,rows):
 group='choice_ch17_'+key
 content['choice_groups'][group]=dict(title=title,choice_key=key,options=[dict(id=key+'_'+i,label=label,text=label,feedback=feedback,memory_tag='MEM_CH17_'+key.upper()+'_'+i.upper(),effects=[]) for i,label,feedback in rows])
 event('choice',key,title,group=group,choice_key=key);event('branch_feedback',key+'_reply',title,group=group,choice_key=key)
def puzzle(key,title,kind,effect='',xp=0,**kw):return event('puzzle',key,title,effect,xp,puzzle_id='pz_ch17_'+kind,**kw)
refs=['04:SC-17-01','06:MQ-17 Step1']
scene('sand_rescue','沙地拖板救商','sand',[H,'npc_ch17_taboluo','npc_ch17_amo'],1,refs)
talk('arrival','十载西行之后，梁萧踏上归路。沙梁下，一队行商正被流沙困住。',effect='arrival')
action('sled_anchor','固定沙地拖板，放下缆绳')
action('water','沿湿沙取水，分给受困商人')
talk('merchants',('塔波罗','若没有这架沙地拖板，我们便走不出这片沙海。'),('阿莫','小人识得通往天山的路。'),effect='merchants_saved',xp=50)
scene('sword_delivery','六年送剑','sand',[H,F,'npc_ch17_taboluo','npc_ch17_amo'],1,refs)
talk('feng_return','火流星踏过沙梁。风怜抱着羊皮剑匣，踉跄停在梁萧面前。',('风怜','找了六年，终于找到你。欧龙子爷爷、铁哲大叔都不在了，剑却铸成了。'),effect='feng_returns')
action('sword_case','扶起风怜，查看剑匣',effect='sword_custody')
talk('refuse_sword',('梁萧','人命至重，怎能为一柄剑轻掷？先由你收好，我们带商队出去。'))
choice('caravan','临行安排',[('drawing','留下加固沙地拖板的图纸','塔波罗收下图纸。梁萧没有许下尚不能兑现的平安。'),('watch','嘱风怜留意阿莫足迹','风怜记住阿莫的步幅；这只是疑点，还不足以定罪。')])
scene('road_wolves','双谷狼道','trail',[H,F],2,['04:SC-17-01','06:MQ-17 Step2','combat_rules:MQ17.encounter_xp'])
talk('howls','东西两谷的狼哨几乎同时响起。风怜护住剑匣，梁萧挡在商队前方。')
event('objective_battle','road_wolves','草原狼群 · 护住归路',effect='road_safe',xp=100,category='encounter')
scene('fallen_birds','雪中旧痕','valley',[H,F],2,['06:MQ-17 Step2'])
action('birds','查看乌鸦与翠鸟留下的信号',effect='birds_fallen')
talk('zhuque','朱雀亦已遇害。彩凤循狼哨追来，误将梁萧当作凶手；风怜伸手护住剑匣。',effect='zhuque_fallen')
scene('reunion','小禽村重逢','gate',[H,L,F,'npc_ch17_caifeng'],2,['04:SC-17-02','06:MQ-17 Step2'])
talk('chief',('彩凤','朱雀刚刚遇害，怎能放陌生人进村！'),('柳莺莺','把兵刃放下。先救人，再把事情查清。'), '柳莺莺与梁萧隔着雪地相望，谁也没有立刻走近。',effect='liu_rejoins')
talk('reunion_echo',('梁萧','莺莺，十年不见。'),('柳莺莺','远道的客人先歇脚。村里的事，我还得去看。'))
scene('chief_duties','天山之主','square',[H,L,F,'npc_ch17_widow','npc_ch17_child'],3,['04:SC-17-02','06:MQ-17 Step3'],controller=L)
action('wall_survey','巡查北墙与雪口',effect='chief_wall_seen')
action('fuel_survey','核对炭火与羊毛毯',effect='chief_fuel_seen')
choice('chief_priority','柳莺莺的决断',[('wall','先稳住风墙，再分炉火','木工先补风墙，随后把炉火送进各屋。两件事都不能落下。'),('warmth','先安置孤儿，再加固风墙','村妇先把孩子带进暖屋，木工随即赶往北墙。')])
action('chief_order','下达分工，亲自确认落实',effect='chief_decided',xp=50)
talk('chief_after',('柳莺莺','这里的老小把命托给了我，便不是一句安慰能了的。'),('梁萧','这里的主人，确实当得起。'))
scene('roof_offer','西坳的约定','roof',[H,L,F,'npc_ch17_carpenter'],3,['06:R07'],controller=L)
talk('roof_offer','西侧还有一家人住在漏风的帐篷里。柳莺莺指向已备好的红松木。')
event('quest_window','roof_window','小禽村的新屋 · 可稍后再来')
talk('before_patrol',('柳莺莺','山后的狼哨还没有停，我们先把村外的威胁查清。'))
scene('battle_prepare','雪谷整备','gate',[H,L,F],4,['07:B13','07:LYY_A08','06:MQ-17 Step4'])
choice('loadout','梁萧整备',[('river','观势／三才／飞星／汇涓','观势辨认虚实，汇涓承接群狼连击。'),('tide','观势／飞星／滴水／惊涛','用滴水与惊涛控制战局，飞星保留救援所需剑路。')])
action('prepare','按已学武学整备，确认三人分工',effect='battle_ready')
scene('double','狼皮替身','valley',[H,L,F],4,['07:B13 phase1','04:SC-17-03'])
talk('double_appears','披狼皮的人率群狼堵住雪谷。柳莺莺望见铁爪套下露出的衣袖。')
event('objective_battle','wolf_double','天山双狼 · 狼皮替身',effect='double_defeated')
talk('double_dead','狼皮撕开，众人方知这只是替身。商队方向传来不祥的静寂。')
scene('snow_evidence','雪谷勘验','valley',[H,L,F],4,['06:PZ-08 evidence1/2/6'])
action('evidence_howls','比对东西两谷同时留下的哨痕',effect='evidence_howls')
action('evidence_disguise','检视狼皮与铁爪套',effect='evidence_disguise')
action('evidence_zhuque','核对朱雀致命伤的指力手法',effect='evidence_zhuque')
scene('caravan_evidence','商队遗骸','caravan',[H,L,F,'npc_ch17_amo'],4,['06:PZ-08 evidence3/4'])
talk('caravan_silence','塔波罗与同行者已遭灭口。只剩阿莫自称侥幸逃生。',effect='caravan_fallen')
action('evidence_wounds','勘验伤口：不是马匪弯刀',effect='evidence_wounds')
action('evidence_callus','查看阿莫虎口硬皮与狼哨蜡',effect='evidence_callus')
scene('case_evidence','剑匣留痕','evidence',[H,L,F,'npc_ch17_amo'],4,['06:PZ-08 evidence5'])
action('evidence_case','量度剑匣指印，询问风怜经过',effect='evidence_case')
talk('deduction','六处线索都已记下。猜疑不能替代证据；把两条因果链分清，再指认真凶。')
puzzle('logic_board','双狼血案 · 逻辑勘查板','evidence',effect='amo_exposed',xp=750,category='puzzle')
choice('accusation','先指出哪一处破绽',[('prints','先说指印与步距','梁萧将剑匣与足迹逐一相比，阿莫再也无法推说偶然。'),('wounds','先说伤口与狼哨蜡','柳莺莺封住退路，风怜把商队伤口与狼哨蜡放在案上。')])
scene('amo','天罚开刃','valley',[H,L,F,'npc_ch17_amo'],5,['07:B13 phase2','04:SC-17-03','06:MQ-17 Step5'])
talk('hostage',('阿莫','再向前一步，便试试这丫头能不能活！'), '风怜的退路被封。柳莺莺握住软索，梁萧的手停在剑匣旁。')
event('objective_battle','amo','天山双狼 · 救风怜',effect='amo_defeated',xp=100)
talk('sword_after','天罚锈壳脱落。梁萧收住剑势，众人才敢走近倒在雪中的风怜。',('梁萧','剑归匣中。先看风怜的伤。'))
scene('burial','葬友余波','grave',[H,L,F,'npc_ch17_caifeng'],6,['06:MQ-17 Step6'])
action('burial','安葬同伴与商旅，收拾遗物',effect='burial')
talk('burial_silence','雪地里没有战利品的欢呼。柳莺莺为孤儿拢好衣领，转身走向村中。')
scene('last_roof','离山前的约定','roof',[H,L,F,'npc_ch17_carpenter'],6,['06:R07 deadline'],controller=L)
event('quest_window','roof_last_window','新屋的约定 · 离山前最后处理')
talk('close_roof','去往湖畔之前，柳莺莺把村中分工重新交代了一遍。',effect='close_optional')
scene('lake','碧湖残照','lake',[H,L,F],6,['04:SC-17-04','06:MQ-17 Step6'])
action('lake_seat','走到青石旁，放下剑匣')
talk('shave',('柳莺莺','坐好，别乱动。十年风沙，都挂在胡子上了。'),('梁萧','有劳柳大首领。'), '刀锋收起，十年前的争执留在湖风里。',effect='shaved')
choice('lake_reply','向晓霜说起天山',[('respect','说天山有位叫人钦佩的大当家','柳莺莺朗声笑了。她不再需要做任何人的附庸。'),('peace','说你一切安好，叫她莫挂怀','柳莺莺手腕微顿，笑着请晓霜捎一帖润肤药膏。')])
talk('lake_farewell',('柳莺莺','去寻晓霜吧。我有我的小禽村。'),effect='lake_memory')
scene('apprentice','风怜拜师','square',[H,L,F],6,['04:SC-17-04','06:MQ-17 Step6'])
action('apprentice_kneel','听风怜郑重说出所求')
talk('apprentice',('风怜','我不求做英雄的妻子。我想学算学、机关与剑法，保护自己的族人。'),('梁萧','愿学，便也要敢问、敢辨是非。'),('柳莺莺','好徒弟就在眼前，还端什么架子？'),effect='apprentice',xp=100)
scene('departure','洒脱辞别','gate',[H,L,F],6,['04:SC-17-04','06:MQ-17 Step6'])
choice('parting','天山辞别',[('map','赠一卷亲绘星图','原手札仍随身，另绘的一卷星图交给天山主人。'),('bow','长揖道别，不添新约','两骑转过山口。柳莺莺挥手，走回灯火渐起的小禽村。')])
action('depart','与风怜东归，柳莺莺留守天山',effect='depart')
talk('ending','山村的灯火留在身后。风怜背着剑匣，第一次以弟子的身份随梁萧走向中土。')
# Optional route uses the existing seven-stage optional state machine, not a forced mainline choice.
q=scene('r07','小禽村的新屋','roof',[H,L,F,'npc_ch17_carpenter'],3,['06:R07'],controller=L,side=True)
q.update(completion_memory='MEM_R07_NEW_ROOF_TIANSHAN',reward_transaction='reward_r07_once',xp=400)
talk('r07_accept',('柳莺莺','屋子要由我们一起盖。我定分工，你们来帮手。'))
action('r07_slope','量度西北雪口与屋坡')
action('r07_stream','查看春季洪水水线与有限木料')
choice('r07_method','柳莺莺定下建屋方法',[('joinery','九宫榫卯斜顶，梁萧下锯','柳莺莺采纳图样，亲自决定起梁顺序。'),('wall','干打垒双层土墙与暖棚','按天山过冬经验改图，不把书上算式硬套进雪地。')])
puzzle('r07_build','三人协作 · 抬梁与保暖','roof',effect='roof_built')
talk('r07_after',('梁萧','这天山的主人，你当之无愧。'),('柳莺莺','少来酸书生客套。替我把晓霜妹子找回来。'),effect='roof_memory')
content['skill_registry']=[dict(id=k,name=v) for k,v in [('LX_A06','汇涓成河'),('LYY_A01','虚实步·惊鸿诱'),('LYY_A03','软索飞钩·绊马'),('LYY_A08','天山掠海·回风斩'),('LYY_N03','天山天禽心法'),('LYY_P04','洒脱放手'),('FL_S01','天罚负剑·破煞'),('FL_S02','沙海勘水·望气'),('FL_P01','率真敢谏')]]
content['runtime_contract']=dict(entry_min_xp=43225,mandatory_xp=1150,main_xp=300,puzzle_xp=750,encounter_xp=100,optional_xp=400,end_min_xp=44375,limited_panel='FL fixed Lv70 interpolation of 07 fixed endpoints; no core growth',boss_split='B13 phase1 before PZ08, phase2 after PZ08; no free HP recovery')
assert sum(x['xp'] for x in content['reward_transactions'])==1150
for prefix in ['04_','06_','07_','08_']:
 p=next((ROOT/'docs/design/v3').glob(prefix+'*.md'));content.setdefault('source_snapshots',[]).append(dict(path=str(p.relative_to(ROOT)),sha256=hashlib.sha256(p.read_bytes()).hexdigest()))
for name,data in [('chapter_seventeen.json',content),('chapter_seventeen_runtime.json',runtime),('maps/chapter_seventeen_maps.json',mapdata)]:
 (D/name).write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('MQ17:',len(content['scenes']),'scenes;',len(mapdata['maps']),'maps;',sum(map(len,runtime['scenes'].values())),'main steps;',sum(map(len,runtime['side_quests'].values())),'side steps')
