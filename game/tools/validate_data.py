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
