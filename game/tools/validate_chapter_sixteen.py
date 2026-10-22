#!/usr/bin/env python3
"""Chapter16 static source/data contracts. No engine or GUI acceptance implied."""
from pathlib import Path
import hashlib
import json
import math

ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / 'game/data'

def read(name: str) -> dict:
    return json.loads((DATA / name).read_text(encoding='utf-8'))

def validate() -> dict:
    content = read('chapter_sixteen.json')
    runtime = read('chapter_sixteen_runtime.json')
    maps = read('maps/chapter_sixteen_maps.json')['maps']
    scenes = content['scenes']
    scene_ids = [scene['id'] for scene in scenes]
    assert len(scene_ids) == len(set(scene_ids)) == 16
    assert set(scene_ids) == set(runtime['scenes'])
    assert len(maps) == 13
    assert {scene['quest_step'] for scene in scenes} == set(range(1, 7))
    for source in content['source_snapshots']:
        assert hashlib.sha256((ROOT / source['path']).read_bytes()).hexdigest() == source['sha256'], source['path']
    assert (DATA/'combat_rules.json').read_bytes() == (ROOT/'docs/design/v3/combat_rules.json').read_bytes()
    actors = {row['name'] for row in content['actor_registry']} | {'旁白'}
    events, rewards, puzzle_ids = set(), {}, set()
    for scene in scenes:
        assert scene['map_id'] in maps and scene['source_refs']
        assert set(scene['cast']) <= actors
        mapped = maps[scene['map_id']]
        for event in runtime['scenes'][scene['id']]:
            assert event['id'] not in events
            events.add(event['id'])
            assert event['op'] in {'dialogue','branch_feedback','choice','action','puzzle','objective_battle'}
            if event['op'] == 'dialogue':
                for ref in event['refs']:
                    line = content['dialogue_registry'][ref]
                    assert line['text'].strip() and line['speaker'] in set(scene['cast']) | {'旁白'}, (scene['id'], ref)
            if event['op'] == 'choice':
                options = content['choice_groups'][event['group']]['options']
                assert options and len({row['id'] for row in options}) == len(options)
            if event['op'] in {'action','puzzle'}:
                geometry = mapped['actions'][event['id']]
                x,y = geometry['position']; bx,by,bw,bh = mapped['walk_bounds']
                assert bx<=x<=bx+bw and by<=y<=by+bh and geometry['radius']>0
            if event['op']=='puzzle': puzzle_ids.add(event['puzzle_id'])
            for effect in event.get('effects',[]):
                if effect['op']=='chapter_sixteen_reward':
                    assert effect['id'] not in rewards and type(effect['xp']) is int
                    rewards[effect['id']]=effect['xp']
        assert set(scene['completion_gate']['all_of'])=={event['id'] for event in runtime['scenes'][scene['id']]}
    assert len(events)==64
    assert puzzle_ids=={'pz_ch16_river','pz_ch16_scale','pz_ch16_study'}
    assert sum(rewards.values())==2255
    assert sorted(rewards.values()).count(750)==2
    assert {row['runtime_id'] for row in content['source_mapping'] if row['resource_type']=='scene'}==set(scene_ids)
    for map_id, mapped in maps.items():
        assert len(mapped['spawn'])==2 and all(math.isfinite(v) for v in mapped['spawn'])
        assert mapped['size'][0]>=320 and mapped['size'][1]>=180, map_id
    return {'scenes':len(scenes),'maps':len(maps),'events':len(events),'quest_steps':6,'puzzles':len(puzzle_ids),'mandatory_xp':sum(rewards.values()),'source_hashes':len(content['source_snapshots']),'status':'passed'}

if __name__ == '__main__':
    print(json.dumps(validate(),ensure_ascii=False,sort_keys=True))
