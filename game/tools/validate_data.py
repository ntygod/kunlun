#!/usr/bin/env python3
"""Static narrative contracts; no external dependencies."""
from pathlib import Path
import json
root = Path(__file__).resolve().parents[1]
data = json.loads((root/'data/prologue.json').read_text())
ids = [s['id'] for s in data['scenes']]
assert len(ids) == len(set(ids))
assert data['reward_xp'] == 0 and data['character']['level'] == 15
assert data['character']['id'] == 'char_liang_wenjing'
canonical = set()
for scene in data['scenes']:
    assert scene['dialogue'] and scene['choices']
    present = set(scene['cast']) | {'梁文靖','旁白','王立与众将'}
    for line in scene['dialogue']:
        assert line['text'].strip()
        assert line['speaker'] in present, (scene['id'], line['speaker'])
    for choice in scene['choices']:
        assert all(choice.get(k) for k in ('text','flag','feedback'))
    assert set(scene.get('requires_objects',[])) <= {o['id'] for o in scene['objects']}
    assert all(n>0 for n in scene['map_tiles'])
    if scene['source_scene'].startswith('SC-'):
        canonical.add(scene['source_scene'])
assert canonical == {f'SC-00-{n:02}' for n in range(1,6)}
assert (root/'data/combat_rules.json').read_bytes() == (root.parent/'docs/design/v3/combat_rules.json').read_bytes()
print(f'PASS: {len(ids)} semantic scene IDs, five canonical scene mappings, dialogue/cast/branch/XP/rules contracts')

# Chapter one has a typed event controller; source archives remain unmodified.
import hashlib
chapter = json.loads((root/'data/chapter_one.json').read_text())
runtime = json.loads((root/'data/chapter_one_runtime.json').read_text())
maps = json.loads((root/'data/maps/chapter_one_maps.json').read_text())['maps']
encounters = json.loads((root/'data/chapter_one_encounters.json').read_text())['encounters']
scene_ids = [s['id'] for s in chapter['scenes']]
assert len(scene_ids) == len(set(scene_ids)) == 10
assert set(runtime['scenes']) == set(scene_ids)
assert len(maps) == 7
assert set(chapter['source_archive']) == {f'SC-01-{n:02}' for n in range(1,5)}
for archive in chapter['source_archive'].values():
    assert hashlib.sha256(archive['text'].encode()).hexdigest() == archive['sha256']
steps = set()
actions = set()
battles = []
for scene in chapter['scenes']:
    assert scene['map_id'] in maps
    geometry = maps[scene['map_id']]
    for i,event in enumerate(runtime['scenes'][scene['id']]):
        assert event['step_id'] == f"{scene['id']}:{i:02}"
        assert event['step_id'] not in steps
        steps.add(event['step_id'])
        assert event['op'] in {'dialogue','action','choice','battle','trial'}
        if event['op'] == 'dialogue':
            assert 0 <= event['start'] < len(scene['dialogue'])
            assert event['end'] == -1 or event['start'] <= event['end'] < len(scene['dialogue'])
        elif event['op'] == 'action':
            actions.add(event['id'])
            assert event['id'] in geometry['actions'], (scene['id'],event['id'])
            if event['kind'] == 'route': assert len(geometry['paths'][event['id']]) >= 2
            if event['kind'] == 'glyph': assert event['glyph'] in ['梁','文']
        elif event['op'] == 'battle':
            assert event['id'] in encounters
            battles.append(event['id'])
    choices = [choice['id'] for choice in scene['choices']]
    assert len(choices) == len(set(choices))
assert len(battles) == 2 and len(set(battles)) == 2
assert sum(t['xp'] for t in chapter['reward_transactions']) == 345
assert len({t['id'] for t in chapter['reward_transactions']}) == 3
assert chapter['reward_budget']['level_cap'] == 80
print(f'PASS: chapter1 {len(scene_ids)} nodes / {len(maps)} maps / {len(steps)} typed steps, real encounters, source archive hashes, glyph/route/XP contracts')

# Registered chapter two: actual typed steps and geometry, not its source archive.
chapter2 = json.loads((root/'data/chapter_two.json').read_text())
runtime2 = json.loads((root/'data/chapter_two_runtime.json').read_text())
maps2 = json.loads((root/'data/maps/chapter_two_maps.json').read_text())['maps']
assert len(chapter2['scenes']) == len(runtime2['scenes']) == 19
assert len(maps2) == 11
assert set(runtime2['side_quests']) == {'ch02_r01','ch02_k01'}
for archive in chapter2['source_archive'].values():
    assert hashlib.sha256(archive['text'].encode()).hexdigest() == archive['sha256']
chapter2_steps = 0
for scene in chapter2['scenes'] + chapter2['side_quests']:
    sequence = (runtime2['scenes'] if scene['id'] in runtime2['scenes'] else runtime2['side_quests'])[scene['id']]
    assert scene['map_id'] in maps2
    receipts = set()
    for i,event in enumerate(sequence):
        chapter2_steps += 1
        assert event['step_id'] == f"{scene['id']}:{i:02}"
        receipts.update(event.get('receipts',[]))
        if event['op'] == 'action':
            assert event['id'] in maps2[scene['map_id']]['actions'], event['id']
            if event['kind'] == 'route': assert len(maps2[scene['map_id']]['paths'][event['id']]) >= 2
        if event['op'] == 'puzzle': assert event['entry_id'] in maps2[scene['map_id']]['actions'], event['entry_id']
    assert set(scene['completion_gate']['all_of']) <= receipts, scene['id']
assert sum(t['xp'] for t in chapter2['reward_transactions'] if t['category'] != 'optional_side_quest') == 1095
assert sum(t['xp'] for t in chapter2['reward_transactions']) == 1745
assert len({t['id'] for t in chapter2['reward_transactions']}) == 8
assert chapter2['exit_contract']['liang_age'] == 16
assert chapter2['exit_contract']['xiaoshuang_age'] == 15
assert chapter2['exit_contract']['optional_quests_do_not_block']
print(f'PASS: chapter2 19 nodes / 11 maps / {chapter2_steps} main+optional steps, source hashes, objective geometry and 1095+650 XP')

# Registered chapter three uses a source-preserving adapter, not source-only JSON.
chapter3 = json.loads((root/'data/chapter_three.json').read_text())
runtime3 = json.loads((root/'data/chapter_three_runtime.json').read_text())
maps3 = json.loads((root/'data/maps/chapter_three_maps.json').read_text())['maps']
assert len(chapter3['scenes']) == len(runtime3['scenes']) == 15
assert len(maps3) == 4 and chapter3['side_quests'] == []
for archive in chapter3['source_archive'].values():
    assert hashlib.sha256(archive['text'].encode()).hexdigest() == archive['sha256']
dialogue3 = {line['id']: line for line in chapter3['dialogue_registry']}
seen3, steps3, choices3 = [], [], []
for scene in chapter3['scenes']:
    assert scene['map_id'] in maps3
    sequence = runtime3['scenes'][scene['id']]
    receipts = set()
    for i,event in enumerate(sequence):
        assert event['step_id'] == f"{scene['id']}:{i:02}"
        steps3.append(event['step_id'])
        receipts.update(event.get('receipts',[]))
        if event['op'] == 'action':
            assert event['id'] in maps3[scene['map_id']]['actions'], event['id']
            if event['kind'] == 'route': assert len(maps3[scene['map_id']]['paths'][event['id']]) >= 2
        if event['op'] in ['puzzle','world_puzzle']:
            assert event['entry_id'] in maps3[scene['map_id']]['actions'], event['entry_id']
        if event['op'] == 'dialogue':
            end = len(scene['dialogue_refs'])-1 if event['end'] < 0 else event['end']
            seen3 += scene['dialogue_refs'][event['start']:end+1]
    assert set(scene['completion_gate']['all_of']) <= receipts
    choices3 += [choice['id'] for choice in scene['choices']]
assert len(steps3) == len(set(steps3)) == 76
assert len(choices3) == len(set(choices3)) == 12
assert all(reference in dialogue3 for reference in seen3)
assert all(line['id'] in seen3 for line in dialogue3.values() if line['provenance'] == 'source_verbatim')
assert sum(tx['xp'] for tx in chapter3['reward_transactions']) == 1030
assert chapter3['reward_transactions'][0]['xp'] == 235
assert runtime3['currency_reward']['amount'] == 300
for board in chapter3['interaction_contracts']['math_boards']:
    assert all(sum(a*x for a,x in zip(row,board['solution'])) == b for row,b in zip(board['matrix'],board['rhs']))
assert chapter3['exit_contract']['target_quest'] == 'MQ-04'
assert '\t10:' in (root/'scripts/campaign/chapter_registry.gd').read_text()
print(f'PASS: chapter3 15 nodes / 4 maps / {len(steps3)} typed steps, 34 preserved source units, 12 choices, 1030 XP and preserved chapter3 contract')

chapter4=json.loads((root/'data/chapter_four.json').read_text())
runtime4=json.loads((root/'data/chapter_four_runtime.json').read_text())
maps4=json.loads((root/'data/maps/chapter_four_maps.json').read_text())['maps']
assert len(chapter4['scenes'])==17 and len(maps4)==8
steps4=[]
for scene in chapter4['scenes']:
    sequence=runtime4['scenes'][scene['id']]
    receipts=set()
    for event in sequence:
        steps4.append(event['step_id'])
        receipts.update(event.get('receipts',[]))
        if event['op'] in ('action','puzzle','world_puzzle'):
            key=event.get('entry_id',event['id'])
            assert key in maps4[scene['map_id']]['actions'], key
    assert set(scene['completion_gate']['all_of']) <= receipts, scene['id']
assert len(steps4)==len(set(steps4))
assert chapter4['interaction_contracts']['staff_trial']['layout']['rival_start']==12
assert sum(t['xp'] for t in chapter4['reward_transactions'] if t['category']!='optional')==1995
print(f'PASS: chapter4 17 nodes / 8 maps / {len(steps4)} main typed steps, real module IDs, 1995 main XP')

for name in ('chapter_four_runtime.gd','chapter_four_transactions.gd','party_progression.gd'):
    source=(root/'scripts/campaign'/name).read_text()
    for line in source.splitlines():
        if 'assert(' in line:
            assert not any(token in line for token in ('reserve_pouch(', 'steal_pouch(', 'return_pouch(', 'transfer_keepsake(', 'recruit_liu(', 'Party.refit(', 'Party.award(')), (name,line)
print('PASS: chapter4 mandatory transaction calls are outside removable assertions (not a release export test)')


chapter5=json.loads((root/'data/chapter_five.json').read_text())
runtime5=json.loads((root/'data/chapter_five_runtime.json').read_text())
maps5=json.loads((root/'data/maps/chapter_five_maps.json').read_text())['maps']
assert len(chapter5['scenes'])==len(runtime5['scenes'])==21 and len(maps5)==13
assert set(s['map_id'] for s in chapter5['scenes'])==set(maps5)
assert isinstance(chapter5['actor_registry'],list) and all('id' in a and 'name' in a for a in chapter5['actor_registry'])
for archive in chapter5['source_archives']:
    assert hashlib.sha256(archive['text'].encode()).hexdigest()==archive['sha256']
steps5=[]
for scene in chapter5['scenes']:
    assert scene['map_id'] in maps5
    receipts=set()
    for index,event in enumerate(runtime5['scenes'][scene['id']]):
        assert event['step_id']==f"{scene['id']}:{index:02}"
        steps5.append(event['step_id']);receipts.update(event.get('receipts',[]))
        if event['op'] in ('action','puzzle','world_puzzle'):
            key=event.get('entry_id',event['id'])
            assert key in maps5[scene['map_id']]['actions'],key
            if event.get('kind')=='route':
                path=maps5[scene['map_id']]['paths'][key]
                assert len(path)>=2 and path[-1]==maps5[scene['map_id']]['actions'][key]['position']
        if event['op']=='dialogue':
            assert all(ref in chapter5['dialogue_registry'] for ref in event['refs'])
    assert set(scene['completion_gate']['all_of'])<=receipts,scene['id']
assert len(steps5)==len(set(steps5))
assert sum(t['xp'] for t in chapter5['reward_transactions'])==2535
assert chapter5['currency_budget']['amount']==400
sequence=[s['id'] for s in chapter5['scenes']]
assert sequence.index('ch05_chuxianliu_intervention')<sequence.index('ch05_hostage_thorn')<sequence.index('ch05_pool_escape')
assert [(x,y,100-x-y) for x in range(1,100) for y in range(1,100-x) if 21*x+9*y+(100-x-y)==300]==[(2,20,78),(4,15,81),(6,10,84),(8,5,87)]
print(f'PASS: chapter5 21 nodes / 13 maps / {len(steps5)} steps, source hashes, scene order, 2535 XP and 400 copper')

chapter6=json.loads((root/'data/chapter_six.json').read_text())
runtime6=json.loads((root/'data/chapter_six_runtime.json').read_text())
maps6=json.loads((root/'data/maps/chapter_six_maps.json').read_text())['maps']
assert len(chapter6['scenes'])==len(runtime6['scenes'])==11 and len(maps6)==9
assert set(s['map_id'] for s in chapter6['scenes'])==set(maps6)
assert sum(t['xp'] for t in chapter6['reward_transactions'])==2125
assert chapter6['runtime_contract']=={'main_nodes':11,'required_xp':2525,'main_xp':2125,'encounter_xp':400,'puzzle_xp':0,'optional_xp':700}
assert sum(s['xp'] for s in chapter6['side_quests'])==700 and chapter6['currency_budget']==450
for archive in chapter6['source_archives'].values():
    source=(root.parent/archive['path']).read_bytes()
    assert hashlib.sha256(source).hexdigest()==archive['sha256']
    lines=source.decode().splitlines()
    for segment in archive['segments']:
        assert '\n'.join(lines[segment['start']-1:segment['end']])==segment['text']
steps6=[]
for scene in chapter6['scenes']+chapter6['side_quests']:
    sequence=runtime6['scenes' if scene['id'].startswith('ch06_') else 'side_quests'][scene['id']]
    receipts=set()
    for index,event in enumerate(sequence):
        assert event['step_id']==f"{scene['id']}:{index:02}"
        steps6.append(event['step_id']);receipts.update(event.get('receipts',[]))
        if event['op'] in ('action','puzzle','world_puzzle'):
            key=event.get('entry_id',event['id'])
            assert key in maps6[scene['map_id']]['actions'],(scene['id'],key)
            if event.get('kind')=='route':
                route=maps6[scene['map_id']]['paths'][key]
                assert route[-1]==maps6[scene['map_id']]['actions'][key]['position']
        if event['op']=='dialogue':assert all(ref in chapter6['dialogue_registry'] for ref in event['refs'])
        if event['op']=='choice':assert event['group'] in chapter6['choice_groups']
    assert set(scene['completion_gate']['all_of'])<=receipts
assert len(steps6)==len(set(steps6))
assert runtime6['scenes']['ch06_departure'][-1]['id']=='departure_confirmed'
assert not runtime6['scenes']['ch06_departure'][1]['deadline']
assert '10:{' in (root/'scripts/campaign/chapter_registry.gd').read_text()
print(f'PASS: chapter6 11 nodes / 9 maps / {len(steps6)} main+side steps, source hashes, 2125+400 main XP / 700 optional / 450 copper; chapter6 preserved')

chapter7=json.loads((root/'data/chapter_seven.json').read_text())
runtime7=json.loads((root/'data/chapter_seven_runtime.json').read_text())
maps7=json.loads((root/'data/maps/chapter_seven_maps.json').read_text())['maps']
assert len(chapter7['scenes'])==len(runtime7['scenes'])==14 and len(maps7)==8
assert sum(t['xp'] for t in chapter7['reward_transactions'])==1345
assert chapter7['runtime_contract']=={'main_nodes':14,'required_xp':1695,'main_xp':1345,'encounter_xp':350,'puzzle_xp':0,'optional_xp':300}
assert chapter7['currency_budget']==500 and sum(s['xp'] for s in chapter7['side_quests'])==300
for archive in chapter7['source_archives'].values():
    source=(root.parent/archive['path']).read_bytes()
    assert hashlib.sha256(source).hexdigest()==archive['sha256']
    lines=source.decode().splitlines()
    for segment in archive['segments']:
        assert '\n'.join(lines[segment['start']-1:segment['end']])==segment['text']
steps7=[]
for scene in chapter7['scenes']+chapter7['side_quests']:
    sequence=runtime7['scenes' if scene['id'].startswith('ch07_') else 'side_quests'][scene['id']]
    receipts=set()
    for index,event in enumerate(sequence):
        assert event['step_id']==f"{scene['id']}:{index:02}"
        steps7.append(event['step_id']);receipts.update(event.get('receipts',[]))
        if event['op'] in ('action','puzzle','world_puzzle'):
            assert event.get('entry_id',event['id']) in maps7[scene['map_id']]['actions'],(scene['id'],event['id'])
        if event['op']=='dialogue':assert all(ref in chapter7['dialogue_registry'] for ref in event['refs'])
        if event['op']=='choice':assert event['group'] in chapter7['choice_groups']
    assert set(scene['completion_gate']['all_of'])<=receipts
assert len(steps7)==len(set(steps7))
assert runtime7['scenes']['ch07_funiu_departure'][-1]['id']=='ch07_departure_confirmed'
assert runtime7['scenes']['ch07_funiu_departure'][-1]['deadline']
print(f'PASS: chapter7 14 nodes / 8 maps / {len(steps7)} main+side steps, source hashes, 1345+350 XP / 300 optional / 500 copper')

chapter8=json.loads((root/'data/chapter_eight.json').read_text())
runtime8=json.loads((root/'data/chapter_eight_runtime.json').read_text())
maps8=json.loads((root/'data/maps/chapter_eight_maps.json').read_text())['maps']
assert len(chapter8['scenes'])==len(runtime8['scenes'])==17
assert [r['xp'] for r in chapter8['reward_transactions']]==[20,30,30,40,20,30,20,20,20,300,65,150,300,150,200,200,100]
assert sum(r['xp'] for r in chapter8['reward_transactions'])==1695
assert sum(r['xp'] for r in chapter8['reward_transactions'][:9])==230
assert chapter8['runtime_contract']['mandatory_xp']==1695+800+800+500
assert chapter8['currency_budget']['mandatory']==550
for archive in chapter8['source_archives'].values():
    source=(root.parent/archive['path']).read_bytes()
    assert hashlib.sha256(source).hexdigest()==archive['sha256']
    lines=source.decode().splitlines()
    for segment in archive['segments']:
        assert '\n'.join(lines[segment['start']-1:segment['end']])==segment['text']
steps8=[]
for scene in chapter8['scenes']+chapter8['side_quests']:
    sequence=runtime8['scenes' if scene['id'].startswith('ch08_') else 'side_quests'][scene['id']]
    receipts=set()
    assert scene['map_id'] in maps8
    for index,event in enumerate(sequence):
        assert event['step_id']==f"{scene['id']}:{index:02}"
        steps8.append(event['step_id']);receipts.update(event.get('receipts',[]))
        if event['op'] in ('action','puzzle','world_puzzle'):
            assert event.get('entry_id',event['id']) in maps8[scene['map_id']]['actions'],(scene['id'],event['id'])
        if event['op']=='dialogue':assert all(ref in chapter8['dialogue_registry'] for ref in event['refs'])
        if event['op']=='choice':assert event['group'] in chapter8['choice_groups']
    assert set(scene['completion_gate']['all_of'])<=receipts
assert len(steps8)==len(set(steps8))
assert runtime8['scenes']['ch08_fire_assault'][0]['id']=='ch08_fire_confirmed'
assert runtime8['scenes']['ch08_fire_assault'][0]['deadline']
print(f'PASS: chapter8 17 nodes / {len(maps8)} maps / {len(steps8)} steps, source hashes, 1695+800+800+500 mandatory / 300 optional / 550 copper')

chapter9=json.loads((root/'data/chapter_nine.json').read_text())
assert isinstance(chapter9["item_registry"],list)
assert {item["id"] for item in chapter9["item_registry"]} == {"item_ch09_"+name for name in ["shadow_slips","wang_hammer","physician_key","serpent_diamond","general_seal","court_robe","merit_armor","award_chest"]}
assert all(isinstance(item["name"],str) and item["name"] and item["numeric_buff"] is False for item in chapter9["item_registry"])
runtime9=json.loads((root/'data/chapter_nine_runtime.json').read_text())
maps9=json.loads((root/'data/maps/chapter_nine_maps.json').read_text())['maps']
assert len(chapter9['scenes'])==len(runtime9['scenes'])==16
assert len(maps9)==8
assert [r['xp'] for r in chapter9['reward_transactions']]==[40,70,60,60,50,100,100,180,80,100,120,150,100,100,100,120]
assert sum(r['xp'] for r in chapter9['reward_transactions'])==1530
assert chapter9['runtime_contract']['mandatory_xp']==2830
assert chapter9['currency_budget']=={'mandatory':600,'optional':0}
for archive in chapter9['source_archives'].values():
    source=(root.parent/archive['path']).read_bytes()
    assert hashlib.sha256(source).hexdigest()==archive['sha256']
    lines=source.decode().splitlines()
    for segment in archive['segments']:
        assert '\n'.join(lines[segment['start']-1:segment['end']])==segment['text']
novel=chapter9['source_mapping']['original_novel']
assert hashlib.sha256((root.parent/novel['path']).read_bytes()).hexdigest()==novel['sha256']
steps9=[]
for scene in chapter9['scenes']+chapter9['side_quests']:
    sequence=runtime9['scenes' if scene['id'].startswith('ch09_') else 'side_quests'][scene['id']]
    receipts=set()
    assert scene['map_id'] in maps9
    for index,event in enumerate(sequence):
        assert event['step_id']==f"{scene['id']}:{index:02}"
        steps9.append(event['step_id']);receipts.update(event.get('receipts',[]))
        if event['op'] in ('action','puzzle','world_puzzle'):
            assert event.get('entry_id',event['id']) in maps9[scene['map_id']]['actions'],(scene['id'],event['id'])
        if event['op']=='dialogue':assert all(ref in chapter9['dialogue_registry'] for ref in event['refs'])
        if event['op']=='choice':assert event['group'] in chapter9['choice_groups']
    assert set(scene['completion_gate']['all_of'])<=receipts
assert len(steps9)==len(set(steps9))
assert runtime9['scenes']['ch09_bayan_rupture'][0]['id']=='confirm_ch09_enter_command_tent'
assert runtime9['scenes']['ch09_bayan_rupture'][0]['deadline']
assert runtime9['scenes']['ch09_wood_bird_assembly'][0]['puzzle_id']==runtime9['scenes']['ch09_cloud_escape'][0]['puzzle_id']=='pz_ch09_wood_bird'
print(f'PASS: chapter9 16 nodes / 8 maps / {len(steps9)} steps, source hashes, 1530+500+500+300 mandatory / 300 optional / 600 copper')

chapter10=json.loads((root/'data/chapter_ten.json').read_text())
runtime10=json.loads((root/'data/chapter_ten_runtime.json').read_text())
maps10=json.loads((root/'data/maps/chapter_ten_maps.json').read_text())['maps']
assert len(chapter10['scenes'])==len(runtime10['scenes'])==13 and len(maps10)==6
assert not chapter10['side_quests']
assert sum(r['xp'] for r in chapter10['reward_transactions'])==2770
assert sum(r['xp'] for r in chapter10['reward_transactions'][:7])==1505
assert chapter10['runtime_contract']['mandatory_xp']==3070
assert chapter10['runtime_contract']['encounter_xp']==300
assert chapter10['currency_budget']=={'mandatory':650,'optional':0}
assert {i['id'] for i in chapter10['item_registry']}=={'item_ch10_axue_sewing_kit'}
assert all(i['numeric_buff'] is False for i in chapter10['item_registry'])
for name, source in chapter10['source_mapping'].items():
    if 'sha256' not in source: continue
    path=root.parent/source['path'] if 'path' in source else root.parent/'docs/design/v3'/name
    assert hashlib.sha256(path.read_bytes()).hexdigest()==source['sha256']
steps10=[]
for scene in chapter10['scenes']:
    receipts=set()
    assert scene['map_id'] in maps10
    for index,event in enumerate(runtime10['scenes'][scene['id']]):
        assert event['step_id']==f"{scene['id']}:{index:02}"
        steps10.append(event['step_id']);receipts.update(event.get('receipts',[]))
        if event['op'] in ('action','puzzle','world_puzzle'):
            assert event.get('entry_id',event['id']) in maps10[scene['map_id']]['actions'],(scene['id'],event['id'])
        if event['op']=='dialogue':
            assert all(ref in chapter10['dialogue_registry'] for ref in event['refs'])
            assert all(effect=={'op':'chapter_ten_event','id':event['id']} for effect in event['effects'])
        if event['op']=='choice':assert event['group'] in chapter10['choice_groups']
    assert set(scene['completion_gate']['all_of'])<=receipts
assert len(steps10)==len(set(steps10))
assert not any(e['op']=='choice' for name in ('ch10_last_embrace','ch10_river_farewell') for e in runtime10['scenes'][name])
print(f'PASS: chapter10 13 nodes / 6 maps / {len(steps10)} steps, source hashes, 2770+300 mandatory / 0 optional / 650 copper')

chapter11=json.loads((root/'data/chapter_eleven.json').read_text())
runtime11=json.loads((root/'data/chapter_eleven_runtime.json').read_text())
maps11=json.loads((root/'data/maps/chapter_eleven_maps.json').read_text())['maps']
assert len(chapter11['scenes'])==len(runtime11['scenes'])==16 and len(maps11)==6
assert sum(r['xp'] for r in chapter11['reward_transactions'])==2910
assert sum(r['xp'] for r in chapter11['reward_transactions'][:8])==1625
assert chapter11['runtime_contract']['mandatory_xp']==3310
assert chapter11['currency_budget']=={'mandatory':700,'optional':0}
for name, source in chapter11['source_mapping'].items():
    if 'sha256' not in source: continue
    path=root.parent/source['path'] if 'path' in source else root.parent/'docs/design/v3'/name
    assert hashlib.sha256(path.read_bytes()).hexdigest()==source['sha256']
steps11=[]
for scene in chapter11['scenes']:
    receipts=set()
    assert scene['map_id'] in maps11
    for index,event in enumerate(runtime11['scenes'][scene['id']]):
        assert event['step_id']==f"{scene['id']}:{index:02}"
        steps11.append(event['step_id']);receipts.update(event.get('receipts',[]))
        if event['op'] in ('action','puzzle','world_puzzle'):
            assert event.get('entry_id',event['id']) in maps11[scene['map_id']]['actions'],(scene['id'],event['id'])
        if event['op']=='dialogue':assert all(ref in chapter11['dialogue_registry'] for ref in event['refs'])
        if event['op']=='choice':assert event['group'] in chapter11['choice_groups']
    assert set(scene['completion_gate']['all_of'])<=receipts
assert len(steps11)==len(set(steps11))
assert set(runtime11['side_quests'])=={'R04'}
print(f'PASS: chapter11 16 nodes / 6 maps / {len(steps11)} steps, source hashes, 2910+400 mandatory / 400 optional / 700 copper')

chapter12=json.loads((root/'data/chapter_twelve.json').read_text())
runtime12=json.loads((root/'data/chapter_twelve_runtime.json').read_text())
maps12=json.loads((root/'data/maps/chapter_twelve_maps.json').read_text())['maps']
assert len(chapter12['scenes'])==len(runtime12['scenes'])==21 and len(maps12)==8
assert sum(r['xp'] for r in chapter12['reward_transactions'])==6690
assert sum(r['xp'] for r in chapter12['reward_transactions'][:5])==1745
assert chapter12['runtime_contract']['mandatory_xp']==7340
assert chapter12['currency_budget']=={'mandatory':750,'optional':0}
for name, source in chapter12['source_mapping'].items():
    if 'sha256' not in source: continue
    path=root.parent/source['path'] if 'path' in source else root.parent/'docs/design/v3'/name
    assert hashlib.sha256(path.read_bytes()).hexdigest()==source['sha256']
steps12=[]
for scene in chapter12['scenes']:
    receipts=set()
    assert scene['map_id'] in maps12
    for index,event in enumerate(runtime12['scenes'][scene['id']]):
        assert event['step_id']==f"{scene['id']}:{index:02}"
        steps12.append(event['step_id']);receipts.update(event.get('receipts',[]))
        if event['op'] in ('action','puzzle','world_puzzle'):
            assert event.get('entry_id',event['id']) in maps12[scene['map_id']]['actions'],(scene['id'],event['id'])
        if event['op']=='dialogue':assert all(ref in chapter12['dialogue_registry'] for ref in event['refs'])
        if event['op']=='choice':assert event['group'] in chapter12['choice_groups']
    assert set(scene['completion_gate']['all_of'])<=receipts
assert len(steps12)==len(set(steps12))
assert set(runtime12['side_quests'])=={'R05'}
print(f'PASS: chapter12 21 nodes / 8 maps / {len(steps12)} steps, source hashes, 6690+650 mandatory / 400 optional / 750 copper')

chapter13=json.loads((root/'data/chapter_thirteen.json').read_text())
runtime13=json.loads((root/'data/chapter_thirteen_runtime.json').read_text())
maps13=json.loads((root/'data/maps/chapter_thirteen_maps.json').read_text())['maps']
assert len(chapter13['scenes'])==len(runtime13['scenes'])==26 and len(maps13)==8
assert sum(r['xp'] for r in chapter13['reward_transactions'])==2030
assert chapter13['runtime_contract']['mandatory_xp']==4030
assert chapter13['currency_budget']=={'mandatory':800,'optional':0}
for name, source in chapter13['source_mapping'].items():
    assert hashlib.sha256((root.parent/'docs/design/v3'/name).read_bytes()).hexdigest()==source['sha256'], name
steps13=[]
for scene in chapter13['scenes']:
    assert scene['map_id'] in maps13
    receipts=set()
    for index,event in enumerate(runtime13['scenes'][scene['id']]):
        assert event['step_id']==scene['id']+':'+str(index).zfill(2)
        steps13.append(event['step_id']);receipts.update(event.get('receipts',[]))
        if event['op'] in ['action','puzzle','world_puzzle']:
            assert event.get('entry_id',event['id']) in maps13[scene['map_id']]['actions'],(scene['id'],event['id'])
        if event['op']=='dialogue':assert all(ref in chapter13['dialogue_registry'] for ref in event['refs'])
        if event['op']=='choice':assert event['group'] in chapter13['choice_groups']
    assert set(scene['completion_gate']['all_of'])<=receipts
assert len(steps13)==len(set(steps13)) and not runtime13['side_quests']
print(f'PASS: chapter13 26 nodes / 8 maps / {len(steps13)} steps, source hashes, 2030+1500+500 mandatory / 800 copper')

chapter14=json.loads((root/'data/chapter_fourteen.json').read_text())
runtime14=json.loads((root/'data/chapter_fourteen_runtime.json').read_text())
maps14=json.loads((root/'data/maps/chapter_fourteen_maps.json').read_text())['maps']
assert len(chapter14['scenes'])==len(runtime14['scenes'])==24 and len(maps14)==8
assert sum(r['xp'] for r in chapter14['reward_transactions'])==805
assert chapter14['runtime_contract']['mandatory_xp']==2105
assert chapter14['currency_budget']=={'mandatory':850,'optional':0}
for name, source in chapter14['source_mapping'].items():
    assert hashlib.sha256((root.parent/'docs/design/v3'/name).read_bytes()).hexdigest()==source['sha256'], name
steps14=[]
for scene in chapter14['scenes']:
    assert scene['map_id'] in maps14
    receipts=set()
    for index,event in enumerate(runtime14['scenes'][scene['id']]):
        assert event['step_id']==scene['id']+':'+str(index).zfill(2)
        steps14.append(event['step_id']);receipts.update(event.get('receipts',[]))
        if event['op'] in ['action','puzzle','world_puzzle']:
            assert event.get('entry_id',event['id']) in maps14[scene['map_id']]['actions'],(scene['id'],event['id'])
        if event['op']=='dialogue':assert all(ref in chapter14['dialogue_registry'] for ref in event['refs'])
        if event['op']=='choice':assert event['group'] in chapter14['choice_groups']
    assert set(scene['completion_gate']['all_of'])<=receipts
assert len(steps14)==len(set(steps14)) and not runtime14['side_quests']
print(f'PASS: chapter14 24 nodes / 8 maps / {len(steps14)} steps, source hashes, 805+1000+300 mandatory / 850 copper')
