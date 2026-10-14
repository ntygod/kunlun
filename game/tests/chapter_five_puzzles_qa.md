# Chapter five puzzle model QA

## Scope and provenance

Six deterministic teaching models, not complete chapter acceptance. Chapter five source decisions and the V3 quest text remain authoritative. Directed-chain node topology, lock depths/directions and indexed trigram board are approved implementation candidates because V3 does not specify executable algorithms. The external-light three-mirror interpretation is an approved adaptation of V3 module 06, lines 199–204. Neither the six exterior locks nor the trigram cabinet opens the box itself.

The resolver never awards XP, currency or inventory. Only the campaign integration may atomically apply a verified final receipt. Standalone previews use synthetic trusted context. No final pixel art, voice, exported-build or natural GUI acceptance is claimed here.

## Frozen interface

`begin(id, attempt_id, context)`, `set_context(context)`, `apply_input(action)`, `get_view()` (`kind=chapter_five`), `snapshot()`, `restore(snapshot)`, `receipt()`, `get_receipts()`, and static `replay_receipt(receipt, context)` follow the previous chapter interface. Model/snapshot version is 1; receipts freeze the complete per-puzzle `MODEL_SPEC` plus algorithm ID. The input log is limited to 1024 entries. Retry/reset remain available at the limit and preserve cumulative hint/assistance provenance.

| Puzzle ID | Final objective |
| --- | --- |
| chain_ch05_linkage | chain_triple_verified |
| lock_ch05_six | six_locks_opened |
| bagua_ch05_reverse | reverse_bagua_verified |
| oranges_ch05_hundred | oranges_verified |
| box_ch05_light | light_box_opened |
| box_ch05_reseal | box_deception_verified |

Box sessions require trusted `box_instance=item_ch05_pure_yang_box`, and `items[box_instance]` with a nonempty owner and form `sealed` for light or `opened` for reseal. That original item's frozen hash cannot change within the session. Other puzzles need no inventory context. Optional `scene_id` must be a string. Missing actual box is rejected, not synthesized.

Hints record levels in `state.hint`; they do not mark assistance. After three hint layers, explicit `assist_step_v1` performs one genuine legal action and marks `assisted`. Undo/retry preserve both records. Existing versioned assist semantics must not be changed after publication.

## Concrete rules and failure evidence

- Chain: actually traverse 0→1→2→4 before installing the third link and proving 0→1→2→3→4. Disconnection, loops and bypasses fail.
- Six locks: observe each lock; depth sequence 2,1,3,2,3,1 and direction sequence +1,-1,+1,-1,-1,+1. Wrong probe/turn fails without spending real resources.
- Trigrams: ray (32,90) east strikes the disc at western rim (96,90); observe and establish west before reading forward order 乾兑离震巽坎艮坤. Reverse indexed mapping is 0,7,6,5,4,3,2,1; all eight unique tiles and pair checks are required. Movement invalidates prior pair verification.
- Oranges: positive integer counts, total 100, exact thirds-of-a-coin equation 21x+9y+z=300. All four solutions pass: (2,20,78), (4,15,81), (6,10,84), (8,5,87). Count and cost must each be checked.
- Light: source (160,16) south, mirrors (160,64)/(64,64)/(64,128), tangents 135°/135°/45°, box holes (112,128)/(144,128), receiver (224,128). Initial angles 105°/150°/30°, rotations in 15° steps; ring rotates in 45° steps. Reflection uses ray/finite-segment intersections and actual reflected vectors. All three mirrors are necessary. Missing third mirror or its 30° angle misses the box. Ring rotates holes and glyph basis/character positions; 180° can pass both holes but projects inverted text and fails. Diagram renders that rotation. Enumeration of 12³×8 angle/ring configurations finds only [135,135,45,0] successful.
- Reseal: twelve distinct originals move from box to table, each gets one rubbing, both unique balls are removed, two distinct local stones are collected and loaded, then all twelve originals return to the same box before sealing. Originals, balls and stones are explicitly conserved across containers; copies are distinct derived objects. Partial snapshots preserve custody. Repeated removals/rubbings, wrong original/box and forged replacement containers do not duplicate items. Runtime maps final custody to its inventory IDs only after final verification.

Malformed action fields are rejected before logging or mutation. Save/receipt validation checks types before comparisons and bounds recursive data before normalization: finite numbers only, depth 20, 50,000 traversed nodes, bounded dictionaries/arrays/strings. Cyclic/deep trees, wrong context shapes and excessive histories reject atomically.

## Automated evidence, 2026-10-14

Run from repository root with isolated XDG directories:

```sh
export XDG_CACHE_HOME=/tmp/kunlun-cache
export XDG_DATA_HOME=/tmp/kunlun-test-data
export XDG_CONFIG_HOME=/tmp/kunlun-config
godot --headless --path game --script res://tests/test_chapter_five_puzzles.gd
```

Author suite: **3146 checks, 0 failures**, no SCRIPT ERROR/ERROR. Includes JSON roundtrips after legal actions; strict proof/state/context matching; wrong inputs; undo/retry/log limits; all orange solutions; 13,824 optical configurations; all six manual and assisted completion paths; actual UI input signals in 616×336 and 1200×650 shells with Chinese font; and expanded malformed-tree/action/context rejection.

Independent reviewer, isolated `/tmp` copy, resolver SHA256 `91af55776e5603d58c91b69dfca63ed3a038e526db137d0f72d21e028540acfc`: original 2301 checks/0; independent adversarial/action pollution plus 3000 randomized custody steps **54248/0**; receipt malformed types/cycles/deep trees **834/0**. All reviewer fixed logs clean. This review covers models and replay, not natural GUI or campaign transactions.

## GUI preview

```sh
godot --path game --script res://tests/preview_chapter_five_puzzles.gd -- box_ch05_light
```

Replace the final argument with any ID above. Window starts at 640×360. Preview does not read/write campaign saves. For light, extinguish candle, inspect, mount all mirrors, rotate M1 +30°, M2 -15°, M3 +15°, trace then open. Check incorrect/missing third mirror and inverted ring before success. For reseal, remove/rub each page, take each ball, collect/load both stones, refit all originals then seal. Each control has nearby feedback; scroll restoration anchors the focused control after text height changes. Independent real GUI results are tracked separately by the chapter GUI reviewer.

Old puzzle regressions rerun on the shared chapter-five tree: chapter two 1150/0, chapter three 4543/0, chapter four 3027/0; all three logs clean.

## Refit layout correction, 2026-10-14

Natural full-route GUI found that the original page selector and refit button were separated by roughly 800 scroll pixels, requiring repeated travel for twelve originals. The panel now keeps selector/remove/rub/refit together (selector-to-refit less than 150 pixels), with local feedback immediately below. The exact selected page still drives the same `refit_panel` action; there is no auto-selection or model/proof change.

Extended author suite: **3436 checks, 0 failures**, clean log. New 616×335 (640×359 window shell) and 1200×650 tests reconstruct a legal partial checkpoint, use all twelve actual selection/button signals, check one-original-per-click, unchanged replayable final receipt, retained focus and ≤2px focus-anchor displacement, then free the UI with a pending restoration. The last check exposed a suspended anchor coroutine retaining a WeakRef on immediate close; a node-bound one-shot frame callback now disconnects on free. No model, content hash or receipt field changed.

Local natural GUI retest entry (no full chapter replay required):

```sh
godot --path game --script res://tests/preview_chapter_five_puzzles.gd -- box_ch05_reseal --refit-checkpoint
```

The preview generates the checkpoint solely through accepted actions, JSON-roundtrips it through restore, and starts with twelve rubbings, both removed balls, two loaded stones and all twelve originals awaiting refit. GUI verification remains separately reported by the graphical reviewer.
