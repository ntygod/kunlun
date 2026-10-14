# Chapter seven puzzle verification

2026-10-14 implementation checkpoint. This is headless/model coverage, not GUI acceptance.

## Implemented finite models

- Grain: three independently investigated evidence flags; paper placement, selected difference, combined equation, three non-negative integer inputs, and all three constraints on confirmation. No experience or actor mutation.
- L03: Zhao Shan, Wang Ke and Hu San; fixed selected tone, readable letter content IDs, writing, wax sealing and returning each letter to its author to await dispatch. No false claim of dispatch or player money transfer.
- Six flower: six stable living actor identities; independent drill/regroup context scopes and three-wave receipts; publicly specified templates, orientation, enemy/front-row directions and destination. Four-neighbour deterministic N/E/S/W shortest paths, per-cell commands and saved in-flight animation state. One latest unhorned movement transaction can be undone once. No shooting command.
- Assistance uses the same path, per-cell, facing and horn operations. It parks tokens on spaced boundary slots to avoid target-occupancy deadlocks. Retry does not undo passed waves. Bounded-log rollover preserves a fully replayable command prefix for already passed waves, and explicitly marks previous attempt history unverified and cannot be injected through the public command API.

## Reproducible headless checks

Use separate XDG_CACHE_HOME, XDG_DATA_HOME and XDG_CONFIG_HOME (all three).

- `godot --headless --path game --script res://tests/test_chapter_seven_puzzles.gd`: 29,956 checks, 0 failures. Includes 250 seeded random legal occupancy boards, an enclosed leader, every path cell, all rotations/translations, missing/dead/wrong-role support, invalid grain input, public reset injection, cross-scope proof rejection, tampered snapshots, hints/assistance and bounded history, including log rollover after already passed waves 1 and 2.
- `godot --headless --path game --script res://tests/chapter_seven_puzzles_process_driver.gd -- write`, then a new process with `-- read`: all four partial sessions restore, resume to completion and replay their proofs. This includes in-flight movement, not just completed states.
- Existing chapter six puzzles: 5,686 checks, 0 failures; five: 3,436/0; four: 3,027/0.
- Real chapter-six natural save through chapter-seven pre-battle prefix: 129 checks, 0 failures, including grain and L03 plus event-by-event JSON replay. Production context StringName keys are normalized before hashing; real inherited actors/items are accepted under bounded traversal.
- Headless UI investigation with actual Chinese font at 568-pixel width: grain 271px, letters 259px, formation 284px minimum panel height. Input controls are stable across render; busy movement blocks other commands, hidden panels pause timer advancement and visible panels resume. This is layout instrumentation, not rendered visual approval.

- `test_chapter_seven_puzzle_panel.gd`: 189 checks / 0 failures. Real main at 640×360 gives every chapter-seven panel a 552×288 viewport and equal body rectangle; all four fit without the prior 2-pixel overflow. It verifies main signal routing/close plus two letter tones and movement hidden-pause/resume. The main presentation fixture is synthetic; actual campaign input/context restoration is separately covered by the natural-save prefix/full integration tests.

## Not yet claimed

No GUI launch, screenshot review, full chapter combat/story acceptance, manual pacing, final pixel-art acceptance or export in this module checkpoint. Chapter seven's compact main modal now supplies 288 effective pixels at 640×360, verified by headless control rectangles; the older 180-pixel scroller was insufficient.
