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
