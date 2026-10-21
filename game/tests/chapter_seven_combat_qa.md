# Chapter seven combat verification scope

Approved contract: `docs/development/chapter-seven-content.md` at `deaedaef051da3c11b496505b1976a17998d02e1`. Standard difficulty only. V3 has story/sparring coefficients, but existing runtime has no difficulty selector; this module does not introduce a global difficulty system or claim those modes tested.

## Independent model before production integration

`chapter_seven_minimum_source.gd` executes the genuine no-side 0–6 campaign, entrusts all coins, validates and restores its v4 terminal. Result: 9525XP/Lv31/0 copper; Liang 774/911HP,112/116MP,145ATK,89DEF,35SPD; Axue 427/480HP,75MP. This legal route has no LX_N01. No medicine/purchases are used.

`game/tools/chapter_seven_combat_model.py <emitted JSON>` independently applies the approved rest, all three 30HP first mistakes, and chapter XP growth. Before B04, 9525+550 main+350 encounter =10425XP/Lv32,936HP/118MP/148ATK/91DEF. Seven basic attacks deal100 each, leaving Jin Fei1400HP; two rescue actions finish phase1 in9 rounds. Liang receives498 damage in phase1 and299 in phase2; ends49HP. Axue without even guarding ends105HP. No N01, P02, critical/interrupt, healing, money, or consumable benefit is required.

A deliberately over-conservative Lv31 counterexample without N01 takes8 attacks and dies in phase2 round4. The original paper's Lv31 seven-attack witness depends on N01 and is not valid for every history. The actual approved XP ledger resolves this without changing any contract parameter or granting a missing skill.

## Production engine probes

- `test_chapter_seven_combat.gd`:101 assertions, actual basic-attack route ends Liang49HP/Axue236HP (self-guard), Axue entranceMP0 preserved. Context-bound receipts, JSON replay, malformed input atomicity, real hazard walking and exactly90HP penalty.
- `test_chapter_seven_combat_boundaries.gd`:204 assertions, phase resources/checkpoint/retry, strict Variant command boundary (reject bool, floats, strings, null, containers before typed core), atomic malformed argument matrix, bad snapshot types, calibration/fire errors, ordinary attacks cannot damage structure, P02 strict35%/duration/retrigger/discount ceiling, AX cleansing104 independent of displayed rank, passive target/round/cap, whole-action shield.
- Active legal strategy (feixing when available; Axue heals on firing rounds) ends Liang514HP/110MP and Axue105HP/61MP in14 total rounds from same Lv32 entrance. This is one feasible strategy, not comprehensive balance.
- `test_chapter_seven_combat_minimum.gd`:431 assertions including full real 0–6 source. Then applies contract XP/rest with production PartyProgression, executes both encounters, replays proof; ends49HP/236HP. The forward chapter-seven setup is explicit contract transactions, not a claim that the complete narrative or GUI was traversed.
- `test_chapter_seven_battle_panel.gd`:30 headless UI assertions at1280×720 and640×360; captured vs rescued slots, scrollable intents, rules popup and real scene-button revision. Not graphical/manual acceptance.
- `chapter_seven_combat_process_driver.gd`: independent writer36/reader35 assertions, seven actual command-boundary snapshots: rescue queued, freed-before-handoff, handoff queued, phase2 checkpoint, only Liang calibration queued, calibrated-before-fire, and fire+AX queued. Each fresh process restore plus remaining inputs matches the exact final snapshot; forged refill rejects atomically. This is model disk/process verification, not GUI F5/F9.
- Old battle scripts re-run:core134,chapter2 171,chapter3 5171,chapter4 707,chapter5 49+175,chapter6 77+83; all zero failures. Logs also checked for SCRIPT ERROR/ERROR, not only exits.

All runs use isolated XDG cache/data/config under `/tmp/kunlun-ch7-combat`. Temporary logs are execution evidence, not persisted release artifacts. Full chapter-seven integration, all historical branch matrices, independent review, manual GUI, independent-process F5/F9, audio/art and release export are separate gates. Only the explicitly named process driver covers model disk/process replay; it does not claim GUI F5/F9.

## Interface and ownership

`ChapterSevenEncounter.new(rules,runtime,encounter,party,token)`; `get_view/apply_input/set_command/resolve_round/snapshot/restore/retry/receipt`; replay-only restoration and context-bound proof. `final_actors` contains exactly the two original party IDs and final HP/MP. No reward or permanent inventory writes. Funiu preserves MP (controlled hazard); B04 new battle fills Liang MP using original global rule, phase2 never restarts battle and Axue joins on original HP/MP. Phase2 retry replays the verified phase1 prefix.

World projection is read-only: prison→bridge map, bound/released postures, per-support broken states, actual convoy position/path; escorts advance at full round ends and Liang/Axue follow controlled final-rope path before collapse. The bridge threat is an environmental source: its remaining2800 durability is objective state, not a healable living actor; attacks cannot reduce it, yet the final full round still resolves its scheduled threat after the third shot.

## Funiu panel-only UX correction (2026-10-14)

Natural GUI evidence `output/cache/chapter_seven_gui/004_funiu_panel_occlusion.png` showed the modal obscuring world safe markers and a moving-action dropdown retaining index3: after stepping right from128 to144, the reintroduced left option occupied index3, unexpectedly changing the selected direction. This was a real presentation flaw, not a model failure.

The Funiu panel now omits disabled combat selectors and empty enemy-intent space. It shows exact current/target coordinates, remaining horizontal/vertical steps, current ox warning, and a read-only miniature route with gold player/green target. Four fixed-position direction buttons each emit exactly one existing16px move input with the current revision. Cover remains explicit input plus resolve; there is no batch movement, teleport, automatic cover, new success flag or altered proof. B04's remaining menus retain skill/target IDs and scene action actor/action/value/mark identity rather than option indexes; rendering never submits a replacement choice.

`test_chapter_seven_funiu_panel.gd`:144 headless assertions at1280×720 and640×360, including bounds fitting, original128→144→160 right-button reproduction, each single movement, both complete three-hazard routes through actual button signals, receipt replay, stable B04 action after options reverse/shrink, and no automatic substitution. Existing battle-panel30 assertions also pass. Engine/session/data files have no changes in this patch. These are headless checks; post-fix local manual GUI verification remains a separate parent-owned gate.
