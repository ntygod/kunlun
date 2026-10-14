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
assert '6:' not in (root/'scripts/campaign/chapter_registry.gd').read_text()
print(f'PASS: chapter3 15 nodes / 4 maps / {len(steps3)} typed steps, 34 preserved source units, 12 choices, 1030 XP and explicit unregistered chapter6')

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
print(f'PASS: chapter5 21 nodes / 13 maps / {len(steps5)} steps, source hashes, scene order, 2535 XP and 400 copper; chapter6 unregistered')
