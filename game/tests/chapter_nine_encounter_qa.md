# Chapter nine blood-well encounter verification

2026-10-14; development implementation, not graphical acceptance or a release.

## Contract and architecture

- `chapter_nine_engine.gd` is a separate scene controller. It does not inherit or call `CombatEngine.start`. Initial HP/MP are copied without a refill. The campaign owns the one-time living-Liang HP preparation and the unique 300 XP transaction.
- Only Liang is in `actors`. `well_soldier_1` and `well_soldier_2` are scene threat IDs, with observed state, paths and retirement state, not HP-bearing enemies. Pressure begins at two.
- Odd beat: the current soldier publicly raises his blade. Observe that stable ID to establish observation. Even beat: disarm that same observed soldier to retire him and cancel the attack. Missing/wrong actions consume a beat, and the even beat inflicts damage; observation clears before the next cycle.
- Error damage is `max(1,floor(130*1.30*K/(K+DEF)))`, with `K=100+4*39*39/79`, matching the existing defense formula's fixed level-40 calibration and rounding. No battle stance, P03 stack, counter, mana reward, skill or item is synthesized.
- Retired/unknown targets, malformed inputs and stale revisions reject atomically. Public revisions must be actual integers, not booleans or integral floats; serialized integral JSON numbers are accepted for trusted replay schema numbers. StringName context values are supported.
- A normal panel click submits a single validated `execute:true` scene input. This avoids redundant confirmation and avoids a rejected stale input accidentally resolving some other pending command. Omitting `execute` preserves a genuine intermediate preparation state for save/reload.
- Restore and victory verification replay formal inputs against the immutable entrance. Retry rebuilds that entrance, without asking the campaign to rest or reward again.

## Reproducible commands

Use isolated `XDG_CACHE_HOME`, `XDG_DATA_HOME`, and `XDG_CONFIG_HOME` directories. Current local evidence used `/tmp/kunlun-nine-enc-{cache,data,config}`.

```
godot --headless --path game --editor --import --quit
godot --headless --path game --script res://tests/test_chapter_nine_encounter.gd
godot --headless --path game --script res://tests/test_chapter_nine_encounter_panel.gd
CH09_REPLAY_MODE=write godot --headless --path game --script res://tests/chapter_nine_encounter_process_driver.gd
CH09_REPLAY_MODE=read godot --headless --path game --script res://tests/chapter_nine_encounter_process_driver.gd
godot --headless --path game --script res://tests/chapter_nine_minimum_source.gd
godot --headless --path game --script res://tests/test_chapter_nine_encounter_sources.gd
godot --headless --path game --script res://tests/test_chapter_nine_encounter_campaign.gd
```

The minimum source driver executes the existing formal chapter 0–8 route and saves `user://chapter_nine_minimum_source.json`. It does not edit XP, coins, actors or historical side-quest outcomes.

## Passed evidence

- Engine: 244 assertions, zero failures. Four-action zero-damage victory, isolated 0 MP/1 HP pressure, wrong-target damage and recovery, low-HP defeat and retry, no martial commands, mandatory snapshot/context keys, malformed constructors, exact proof, JSON restore and forged MP rejection.
- Headless panel geometry/signals: 124 assertions, zero failures at 1280×720 and 640×360, including intermediate preparation, stable IDs, visible retirement, and four total ordinary button clicks. This is not manual graphical testing.
- Independent writer process: one assertion; independent reader process: 15 assertions, zero failures. Cases are partially queued action, actual mistake damage, and the first soldier retired. Each continues remaining real commands to an identical final snapshot and receipt; forged refill rejection leaves the current state unchanged.
- Genuine 0–8 minimum source: 399 assertions, zero failures. Entry is 15015 XP / level 40 / 1050 copper; Liang 905/1208 HP and 117/138 MP; no N01. It is not a zero-copper old save.
- Source-resource probes: 32 assertions, zero failures. The minimum and original natural chapter-eight saves are restored formally, then their real combat panels are passed into the standalone encounter. Standard play leaves all entrance resources unchanged. Actual repeated mistakes reach 97 HP after eight 101-damage hits on the minimum panel, and 37 HP after ten 99-damage hits on the natural panel; both then win with four standard actions. MP remains 117 and 122 respectively. These are standalone probes of real chapter-eight resources, not a claim about the chapter-nine preparation/reward pipeline.
- Original natural chapter-eight save SHA256 remains `41299aae21511c4a3913c9d15ec124b098c07470ab59fb6bc24d266606adf42e`; not overwritten.
- All 16 pre-existing `test_*combat*.gd` suites returned exit 0, zero failures, and no `SCRIPT ERROR`/`ERROR` log lines. This includes genuine minimum combat routes for chapters six, seven and eight and the 5171-check chapter-three suite.

## Spatial and campaign integration / remaining gates

- Actual map coordinates are now bound: map_ch09_changzhou_street, soldier one [400,224] via y=240 to [560,240], soldier two [464,224] via y=208 to [560,208]. Every step is 16-pixel four-neighbour, inside walk bounds, outside solids including a five-pixel body margin. The view sends formal actor paths and hides only retired targets at their route endpoints. World-helper tween/manual visual verification remains with the world/GUI owners.
- End-to-end chapter-nine campaign: 182 assertions, zero failures. Both real chapter-eight sources advance through formal chapter-nine events to the well. Explicit rest changes only living Liang HP to full; MP and both other actors are unchanged. Actual damaged campaign saves restore exactly; retry restores the one true entry without repeated rest/XP. Minimum entrance is 1263 HP/117 MP; twelve actual 99-damage mistakes reach 75 HP. Natural entrance is 1376 HP/122 MP; fourteen actual 96-damage mistakes reach 32 HP. Both then complete four zero-damage actions and accept exactly one 300 XP transaction; repeat proof/token cannot award again. This does not claim a naturally achieved zero-MP old save; 0 MP remains the separately labelled isolated stress test.
- Main-panel autosave after single-click execution, save/load through the campaign, and actual manual GUI validation belong to integration/GUI owners.
- No GUI, Fal, image generation, uploads, release exports or remote publication were performed by this task.
