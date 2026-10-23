#!/usr/bin/env python3
"""MQ17 source/data contracts, never a substitute for engine or visual acceptance."""
from pathlib import Path
import hashlib
import json
import math

ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / 'game/data'

def read(name: str) -> dict:
    return json.loads((DATA / name).read_text(encoding='utf-8'))

def validate() -> dict:
    content = read('chapter_seventeen.json')
    runtime = read('chapter_seventeen_runtime.json')
    maps = read('maps/chapter_seventeen_maps.json')['maps']
    assert content['chapter'] == runtime['chapter'] == 17
    assert len(content['scenes']) == 18 and len(maps) == 10
    main_ids = {s['id'] for s in content['scenes']}
    assert len(main_ids) == 18 and main_ids == set(runtime['scenes'])
    assert {s['quest_step'] for s in content['scenes']} == set(range(1, 7))
    assert len(content['side_quests']) == 1
    assert content['side_quests'][0]['id'] == 'ch17_r07'
    assert content['side_quests'][0]['xp'] == 400
    assert (ROOT / content['source_decisions']).is_file()
    for source in content['source_snapshots']:
        assert hashlib.sha256((ROOT / source['path']).read_bytes()).hexdigest() == source['sha256'], source['path']
    assert (DATA/'combat_rules.json').read_bytes() == (ROOT/'docs/design/v3/combat_rules.json').read_bytes()
    actor_names = {a['name'] for a in content['actor_registry']} | {'旁白'}
    events, rewards, puzzles, choices, battles = set(), {}, set(), set(), set()
    for scene in content['scenes'] + content['side_quests']:
        steps = (runtime['scenes'] if scene['id'] in main_ids else runtime['side_quests'])[scene['id']]
        mapped = maps[scene['map_id']]
        assert scene['source_refs'] and set(scene['cast']) <= actor_names
        assert set(scene['completion_gate']['all_of']) == {e['id'] for e in steps}
        for index, event in enumerate(steps):
            assert event['id'] not in events
            assert event['step_id'] == f"{scene['id']}:{index:02d}"
            events.add(event['id'])
            assert event['op'] in {'dialogue','branch_feedback','action','choice','puzzle','objective_battle','quest_window'}
            if event['op'] == 'dialogue':
                for ref in event['refs']:
                    line = content['dialogue_registry'][ref]
                    assert line['text'].strip() and line['speaker'] in set(scene['cast']) | {'旁白'}, ref
            if event['op'] == 'choice':
                choices.add(event['group'])
                options = content['choice_groups'][event['group']]['options']
                assert len({o['id'] for o in options}) == len(options) == 2
            if event['op'] in {'action','puzzle'}:
                geometry = mapped['actions'][event['id']]
                x, y = geometry['position']; bx,by,bw,bh = mapped['walk_bounds']
                assert bx <= x <= bx+bw and by <= y <= by+bh and geometry['radius'] > 0
                for sx,sy,sw,sh in mapped['solids']:
                    assert not (sx-8 <= x < sx+sw+8 and sy-4 <= y < sy+sh+4), event['id']
            if event['op'] == 'puzzle': puzzles.add(event['puzzle_id'])
            if event['op'] == 'objective_battle': battles.add(event['id'])
            for effect in event.get('effects', []):
                if effect['op'] == 'chapter_seventeen_reward':
                    assert effect['id'] not in rewards and type(effect['xp']) is int and effect['xp'] > 0
                    rewards[effect['id']] = effect['xp']
    assert len(events) == 66 and len(choices) == 7
    assert puzzles == {'pz_ch17_evidence','pz_ch17_roof'}
    assert battles == {'ch17_road_wolves','ch17_wolf_double','ch17_amo'}
    assert sum(rewards.values()) == 1150
    rules = read('combat_rules.json')
    budget = next(r for r in rules['progression']['chapter_rewards'] if r['chapter'] == 17)
    assert budget['required_total'] == sum(rewards.values())
    assert rules['progression']['optional_by_id']['R07'] == 400
    assert len([v for v in rewards.values() if v == 750]) == 1
    assert {x['runtime_id'] for x in content['source_mapping']} == main_ids | {'ch17_r07'}
    assert {'ch17_evidence_'+k for k in ['howls','disguise','wounds','callus','case','zhuque']} <= events
    for mid, mapped in maps.items():
        assert all(math.isfinite(v) for v in mapped['spawn'])
        assert mapped['size'][0] >= 320 and mapped['size'][1] >= 180, mid
    return {'chapter':17,'main_scenes':18,'development_maps':10,'main_events':59,'optional_events':7,
            'choice_groups':7,'puzzles':2,'encounters':3,'mandatory_xp':1150,'optional_xp':400,
            'source_hashes':len(content['source_snapshots']),'status':'passed'}

if __name__ == '__main__':
    print(json.dumps(validate(), ensure_ascii=False, sort_keys=True))
