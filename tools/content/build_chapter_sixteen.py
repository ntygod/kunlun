#!/usr/bin/env python3
"""Deterministic MQ-16 development content. Does not edit authoritative V3 sources."""
from __future__ import annotations
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
H = 'char_liang_xiao'
F = 'char_feng_lian'
R = 'npc_ranya'
D = ROOT / 'game/data'
content = dict(schema_version=1, chapter=16, quest_id='MQ16', title='西方昆仑',
    status='development_candidate', completion_memory='MEM_MQ16_EQUALITY_OF_LIFE',
    scenes=[], side_quests=[], choice_groups={}, dialogue_registry={}, reward_transactions=[],
    currency_budget=0, actor_registry=[{'id':i,'name':n} for i,n in [
        (H,'梁萧'),(F,'风怜'),(R,'兰娅'),('npc_ch16_official','守仓官'),
        ('npc_ch16_elder','治水老人'),('npc_ch16_child','精绝遗孤'),
        ('npc_ou_longzi','欧龙子'),('npc_jiesu','捷苏'),('npc_tiezhe','铁哲'),
        ('npc_ch16_arutai','阿鲁台·花斑豹'),('npc_ch16_raiders','叛军前锋')]],
    item_registry=[{'id':i,'name':n} for i,n in [
        ('item_ch16_bamboo_strip','故居枯竹篾'),('item_ch16_scholar_notes','马拉加手札'),
        ('item_ch16_firestarter','随身火石'),('item_ch16_counting_rods','旅用算筹')]],
    source_decisions='docs/development/chapter-sixteen-source-review.md', source_mapping=[])
runtime = dict(schema_version=1, chapter=16, scenes={}, side_quests={})
mapdata = dict(version=1, development_candidate=True, maps={})
current = None

def map_(key: str, name: str, style: str, cast: list[str], decor: list[list] | None = None):
    mid='map_ch16_'+key
    mapdata['maps'][mid] = dict(name=name, style=style, size=[480,320], spawn=[64,256],
        walk_bounds=[32,72,416,216], solids=[], water_rects=[], deep_water_rects=[],
        decor=decor or [], actors=[{'id':x,'position':[128+idx*48,176]} for idx,x in enumerate(cast) if x!=H],
        actions={}, paths={}, source_mapping=dict(source_document='06 MQ-16 / 04 SC-16 / 08 regional palettes',
        source_id='MG24' if key in ['river','home','source'] else 'MG25',status='development_candidate',
        note='Hand-authored route geometry and development primitives; not final pixel art.'))
    return mid

maps={}
for key,name,style,cast,decor in [
 ('river','黄河决口','river',[H,'npc_ch16_elder','npc_ch16_official'],[[48,80,48,48,'house'],[368,80,48,48,'house']]),
 ('home','华山故居·重访','home',[H],[[96,84,240,40,'ruin'],[144,132,32,24,'table'],[304,136,24,24,'table']]),
 ('source','星宿海','source',[H],[[48,80,32,24,'rock'],[336,88,48,32,'rock']]),
 ('oasis','精绝城外','oasis',[H,F],[[64,80,32,40,'tree'],[360,88,32,40,'tree']]),
 ('stable','绿洲马场','oasis',[H,F],[[80,96,40,24,'table']]),
 ('night','精绝夜袭','night',[H,F,'npc_ch16_child'],[[72,80,64,48,'house'],[336,80,64,48,'ruin']]),
 ('funeral','荒原葬礼','mourning',[H,F,'npc_ch16_child'],[[144,104,24,24,'old_grave'],[208,104,24,24,'old_grave'],[272,104,24,24,'old_grave']]),
 ('valley','西域剑谷','valley',[H,F,'npc_ou_longzi','npc_jiesu','npc_tiezhe'],[[64,80,64,40,'rock'],[336,80,64,40,'rock']]),
 ('malaga','马拉加庭院','malaga',[H,R],[[80,80,320,48,'house']]),
 ('vault','知识宝库门前','vault',[H,R],[[192,72,96,48,'platform']]),
 ('library','三年书窗','library',[H,R],[[80,80,48,48,'table'],[336,80,48,48,'table']]),
 ('egypt','亚历山大·残像','egypt',[H],[[224,80,48,72,'rock']]),
 ('athens','雅典卫城','athens',[H],[[96,80,16,72,'ruin'],[224,80,16,72,'ruin'],[352,80,16,72,'ruin']]),
]: maps[key]=map_(key,name,style,cast,decor)

def scene(key,title,map_key,cast,source,quest_step):
    global current
    current='ch16_'+key
    node=dict(id=current,title=title,map_id=maps[map_key],style=mapdata['maps'][maps[map_key]]['style'],
        cast=cast,dialogue=[],choices=[],objective=title,completion_gate={'all_of':[]},
        source_refs=source,quest_step=quest_step,silent_reward=True,controller=H)
    content['scenes'].append(node); runtime['scenes'][current]=[]
    content['source_mapping'].append(dict(runtime_id=current,resource_type='scene',source_document='04/06',
        source_id=source,chapter=16,quest_step=quest_step,asset_path='game/data/chapter_sixteen.json',
        status='development_candidate',decision_note='Adapted dialogue; source decisions recorded separately.'))
    return node

def event(op,key,name,*,effect='',xp=0,**kw):
    assert current is not None
    seq=runtime['scenes'][current]; eid='ch16_'+key
    e=dict(op=op,id=eid,name=name,kind='interact',receipts=[eid],effects=[],step_id=f'{current}:{len(seq):02d}')
    if effect:e['effects'].append(dict(op='chapter_sixteen_event',id=effect))
    if xp:
        rid='reward_'+eid
        e['effects'].append(dict(op='chapter_sixteen_reward',id=rid,xp=xp))
        content['reward_transactions'].append(dict(id=rid,xp=xp,after_event=eid,silent=True))
    e.update(kw);seq.append(e);content['scenes'][-1]['completion_gate']['all_of'].append(eid)
    if op in ['action','puzzle']:
        m=mapdata['maps'][content['scenes'][-1]['map_id']]
        # Readable approach positions, well clear of NPCs and props.
        pos=[[136,232],[240,240],[352,240],[352,208],[240,208]][(len(m['actions']))%5]
        m['actions'][eid]=dict(position=pos,radius=22,name=name,description='靠近后按 E。')
    return e

def talk(key,*lines,effect='',xp=0):
    refs=[]
    for idx,line in enumerate(lines):
        speaker,text=line if isinstance(line,tuple) else ('旁白',line)
        did=f'ch16_{key}_line_{idx:02d}'
        content['dialogue_registry'][did]=dict(speaker=speaker,text=text,kind='stage' if speaker=='旁白' else 'speech',
            source_refs=content['scenes'][-1]['source_refs'],status='adapted_development_script')
        refs.append(did)
    return event('dialogue',key,content['scenes'][-1]['title'],refs=refs,effect=effect,xp=xp)

def action(key,name,effect='',xp=0):return event('action',key,name,effect=effect,xp=xp)
def puzzle(key,name,kind,effect='',xp=0):return event('puzzle',key,name,puzzle_id='pz_ch16_'+kind,effect=effect,xp=xp)
def choice(key,title,options):
    group='choice_ch16_'+key
    content['choice_groups'][group]=dict(title=title,choice_key=key,options=[
        dict(id=key+'_'+i,label=label,text=label,feedback=feedback,memory_tag='MEM_CH16_'+key.upper()+'_'+i.upper(),effects=[])
        for i,label,feedback in options])
    event('choice',key,title,group=group,choice_key=key)
    event('branch_feedback',key+'_feedback',title,group=group,choice_key=key)

a=['06:MQ-16 Step1','04:SC-16-01']
scene('granary','黄河救灾','river',['梁萧','守仓官','治水老人'],a,1)
talk('entry','黄河决口，粮仓却紧闭着。梁萧收住向西的脚步。',('治水老人','堤下还有人，莫先与水争强。'),effect='west_arrival')
action('granary_disarm','制伏守仓官，收去刀械',effect='official_restrained')
action('granary_open','打开粮仓，交粮册给灾民',effect='granary_opened',xp=100)
talk('relief','粮食交给灾民分发。梁萧走向洪水冲刷的旧堤。')
scene('river','顺水分流','river',['梁萧','治水老人'],a+['06:PZ-07 river'],1)
talk('river_survey','来水十成，北渠与中渠各承四成；南渠名为二成，淤泥却堵去一半。',('梁萧','少的一成，不该压给下游的人。'))
puzzle('river_diversion','演段治水 · 调闸与开渠','river',effect='river_saved',xp=750)
choice('river_reason','为何留下',[('people','先救堤下百姓','水路通了，梁萧先去查看岸边的棚屋。'),('home','想起故居与旧人','一道流水绕过灶边石阶的旧景，忽然回到眼前。')])
talk('river_after','旧河道接去最后一成洪峰。梁萧离开时，没有人在问他是哪国人。')
scene('home','故居吊雪','home',['梁萧'],a,1)
action('home_door','推开故居柴扉')
talk('home_silence','灶火早冷，灰尘盖住木凳。这里没有等候他回家的脚步声。')
choice('home_first','先走向何处',[('stove','冷寂的土灶','阿雪，我回来看你了。'),('stool','昔日削竹的木凳','梁萧拾起半截枯竹篾，拂去灰土，收入怀中。')])
action('home_mourn','在旧屋停步，收好所见',effect='home_remembrance',xp=80)
talk('home_echo','檐下只剩风声。',effect='home_echo')
scene('source','星宿溯源','source',['梁萧'],['06:MQ-16 Step2','07:LX_A06'],2)
action('source_west','沿西侧细流观察汇口')
action('source_middle','在中央水洼看清分合')
action('source_east','顺东侧流水找到同一条河')
talk('source_realization',('梁萧','一溪微弱，百溪会合，却能穿山越石。'), '他不再以强力截断水路，而顺着细流的来势，一一接引。',effect='learn_river',xp=100)
scene('feng_rescue','精绝救人','oasis',['梁萧','风怜'],['06:MQ-16 Step3','04:SC-16-02'],3)
talk('feng_danger','城外沙路上，少女被恶徒逼得无路可退。梁萧横身隔开刀锋。')
action('feng_cover','挡住追逼者，护少女到树后',effect='feng_rescued')
talk('feng_name',('风怜','我叫风怜。你从哪里来？'),('梁萧','西昆仑，无国无家之人。'))
scene('horse','火流星','stable',['梁萧','风怜'],['06:MQ-16 Step3'],3)
action('horse_watch','停在马侧，观察惊动的方向')
action('horse_approach','缓步靠近，不从马后逼迫')
action('horse_lead','稳住缰绳，引马离开人群',effect='horse_tamed')
choice('horse_gift','将缰绳交给风怜',[('trust','让她亲自接过缰绳','风怜试着唤了一声，火流星在她掌边停住。'),('teach','先说明安抚与照料的方法','梁萧把如何照料烈马一一说清，再退开半步。')])
action('horse_handover','交付火流星，不留作自己坐骑',effect='horse_given')
scene('raid_preparation','灯火将尽','night',['梁萧','风怜','精绝遗孤'],['06:MQ-16 Step3','07:LX_A06'],3)
talk('raid_warning','海都叛军冲入绿洲。火光里传来孩子的哭声，梁萧停下离去的脚步。')
action('raid_shelter','先把妇孺送进石屋',effect='civilians_sheltered')
choice('west_loadout','夜战整备',[('river','汇涓成河／观势／三才／飞星','以汇涓接引连击，以观势和飞星寻找反击机会。'),('tide','汇涓成河／观势／滴水／惊涛','以汇涓自保，以滴水破甲、惊涛压制群敌。')])
talk('raid_ready',('梁萧','退到屋后。这里交给我。'),effect='west_loadout')
scene('raid','夜战护民','night',['梁萧'],['06:MQ-16 Step3','07:LX_A06','combat_rules:MQ16.encounter_xp'],3)
event('objective_battle','night_raid','精绝夜袭 · 守住石屋',effect='raid_resolved',xp=100)
talk('raid_aftermath','阿鲁台倒下，绿洲的火光却没有立刻熄灭。没有欢呼，只有寻找亲人的呼喊。')
scene('funeral','荒原挽歌','funeral',['梁萧','风怜','精绝遗孤'],['06:MQ-16 Step4','04:SC-16-02'],4)
action('funeral_bury','参加合葬，将遗物放在墓旁')
action('funeral_orphan','把孤儿送到幸存亲族身边',effect='orphans_sheltered',xp=100)
talk('funeral_vow',('梁萧','救得了一时，若只以杀止杀，何处才是尽头？'),('风怜','活着的人还在等明日。'))
scene('sword_valley','剑谷拒婚','valley',['梁萧','风怜','欧龙子','捷苏','铁哲'],['06:MQ-16 Step4','04:SC-16-02'],4)
talk('sword_offer',('捷苏','可敢再较一次高下？'),('欧龙子','若以此剑斩断天机宫之剑，名剑与婚约，皆可成全。'), '炉旁仍是未竟的剑胎。梁萧没有伸手接剑。')
action('sword_refuse','退离剑炉，拒绝争胜与婚约',effect='sword_refused')
choice('farewell','临别所留',[('tools','留下旅用火石与一副算筹','火石与旅用算筹留在桌上；旧日重要信物没有转赠。'),('quiet','不留物件，悄然远行','他没有留下可以使人误会的约定，只在夜色里远去。')])
action('valley_depart','离开剑谷，风怜留在原处',effect='leave_feng',xp=75)
scene('malaga','重逢兰娅','malaga',['梁萧','兰娅'],['06:MQ-16 Step5','04:SC-16-03'],5)
talk('ranya_reunion',('兰娅','父亲没有等到你。可他留下的门，还在。'), '梁萧垂首，在纳速拉丁留下的书案前停了很久。',effect='ranya_reunited')
action('ranya_memorial','向纳速拉丁旧案致意')
scene('life_scale','生命天平','vault',['梁萧','兰娅'],['06:MQ-16 Step5','06:PZ-07 scale','04:SC-16-03'],5)
talk('scale_inscription','黄金王冠、古老手稿与大马士革长剑摆在铜盘下。石门问：何物最重？')
puzzle('life_scale','生命天平 · 人与人','scale',effect='life_equal',xp=750)
talk('scale_open',('梁萧','若一条性命也不能轻掷，又怎能以国族贵贱称量？'), '两人走进书库。铜门在身后缓缓止住。')
scene('study_choice','书海初灯','library',['梁萧','兰娅'],['04:SC-16-03','06:MQ-16 Step5'],5)
choice('first_book','第一夜的书卷',[('geometry','先读几何','梁萧将熟悉的算理与异乡的证明逐一相照。'),('astronomy','先读天文','铜仪与星图在桌上展开，新的问题比答案更多。')])
choice('study_focus','三年研读的重心',[('geometry','几何原本与天体推演','以几何和天象互相印证；这份研读记入马拉加手札。'),('hydraulics','西域水利与机械图谱','将治水所得与异乡机械相照；这份研读记入马拉加手札。')])
scene('three_years','三年书窗','library',['梁萧','兰娅'],['06:MQ-16 Step5'],5)
puzzle('seasons','翻卷、测角、记下一季','study',effect='study_completed',xp=100)
talk('study_after','十二次寒暖写进手札，三年过去。梁萧合上书页，铜仪上留下了磨亮的手痕。')
action('library_depart','辞别兰娅，带着手札继续行旅',effect='leave_ranya')
scene('egypt','残像与旧人','egypt',['梁萧'],['06:MQ-16 Step6','04:SC-16-04'],6)
action('statue_approach','走近残缺石像，停步仰望')
talk('statue_memory','异乡残像没有双臂。海潮的声息忽与钱塘旧日重叠；阿雪仍只在记忆里。')
choice('statue_echo','留下怎样的回应',[('bamboo','取出故居竹篾，默念旧人','他把竹篾放在掌心，没有让它替自己许下新的誓言。'),('equation','在手札记下一道未竟的算式','有些空缺不必补齐。算式旁，留着一行没有写满的字。')])
action('statue_leave','收好旧物与手札，继续前行',effect='statue_remembered')
scene('athens','七载行旅','athens',['梁萧'],['06:MQ-16 Step6','04:SC-16-04'],6)
action('athens_west','沿卫城西侧残柱走向夕照')
action('athens_east','穿过断墙，向东方停步')
talk('ten_years','辞别马拉加又过七载。旧袍泛白，手札渐厚；十年的风沙，没有抹去旧人的名字。',effect='seven_years',xp=100)
talk('eastward',('梁萧','山河有界，性命不该有贵贱。'), '他收起算筹，转向万里关山。东方还有未了的故人。',effect='eastbound')

content['skill_registry']=[{'id':'LX_A06','name':'汇涓成河'}]
assert sum(r['xp'] for r in content['reward_transactions'])==2255
content['runtime_contract']=dict(entry_min_xp=40970, mandatory_xp=2255, main_xp=655,puzzle_xp=1500,encounter_xp=100,
    end_min_xp=43225, experience_rule='combat_rules_v1', enemy_tuning='development encounter, not a new numbered boss',
    incomplete=['final pixel art/audio','natural GUI full route','study focus endgame modifiers (no numeric contract yet)','chapters17-20'])
# Hash immutable authoritative sources. Runtime dialogue is an explicit adaptation.
for prefix in ['04_','06_','07_','08_']:
    path=next((ROOT/'docs/design/v3').glob(prefix+'*.md'))
    content.setdefault('source_snapshots',[]).append(dict(path=str(path.relative_to(ROOT)),sha256=hashlib.sha256(path.read_bytes()).hexdigest()))
for filename,obj in [('chapter_sixteen.json',content),('chapter_sixteen_runtime.json',runtime),('maps/chapter_sixteen_maps.json',mapdata)]:
    (D/filename).write_text(json.dumps(obj,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(f"MQ16: {len(content['scenes'])} scenes, {len(mapdata['maps'])} maps, {sum(map(len,runtime['scenes'].values()))} steps; 2255 XP")
