# Chapter six puzzle / craft QA

## Scope and approved source adaptations

Five new modules only. V3 module 06 MQ06 (388–407), R03 (817–844) and L02 (1026–1052), chapter-six-content.md and chapter-six-source-decisions.md are the content references. Root approved these executable teaching candidates on 2026-10-14; their precise coordinates, counts, bit patterns and finite test stages are implementation parameters, not quotations or exact historical craft/astronomical claims. Chapter five is unchanged.

- Stars: three readable father-note inspirations, three observed positions (2,0), (0,2), (-2,0). Predict the next quarter-turn via (-y,x), retaining radius squared 4. Validate a counterclockwise tangent with dot product zero, positive cross product and squared length 4. This is a small teaching model, not real celestial prediction. LX_A03 is granted by runtime only after the final receipt.
- Ten directions: fixed normal 4×4 square [16,2,3,13; 5,11,10,8; 9,7,6,12; 4,14,15,1]. Verify its four rows, four columns and two diagonals, each 34. This is explicitly a fixed-board checking exercise, not an editable board restricted to one secretly hardcoded answer. Arbitrary four cells need not sum to 34. Ten graph steps correspond to the visible line indices 0–9 and each line's fourth cell, not unimplemented world collision jumps.
- Basket: two ordinary bamboo units split into three unique strips each, six alternating weave rows (six-crossing masks 21/42), original ends folded into a rim, three load checks which recompute weave integrity. One basket proposed for runtime exchange, no inventory or XP mutation inside the resolver.
- R03: actual runtime choice bird/box is frozen. Exactly one fine-strip bundle splits into six unique strips and one weave. Three low-heat forming ticks, two branch-specific features from the same reserved strip ends, then three wind/water checks of the assembled weave. Wrong heat does not destroy quest material. Bird and box cannot both be produced; retry keeps the same choice. The separate main-story portable bamboo horse is not made by this module.
- L02: two pine logs each length four cut at two, yielding four handle components for two pairs of plough handles. New pine is not allocated to the waterwheel or cart. The original sleeve and willow pin require actual inspect/recover/repair actions; their locations move site→table→their original repaired apparatus. One iron hoop and one rawhide binding move table→waterwheel/cart respectively. Three actual resin units supply one coat per apparatus. Runtime authorization proves Li Ting agreed to help; each apparatus still needs a separate lift action and three load checks. Priority is waterwheel/cart according to runtime choice; both then plough handles. Future 20% recipe eligibility never reduces this puzzle's fixed two logs.

## Frozen interface and context

API: begin(id, attempt_id, trusted_context), set_context, get_view(kind=chapter_six), apply_input, snapshot, restore, receipt, get_receipts, static replay_receipt(proof,id,attempt,context). Model version 1. Zero puzzle XP; only final verified runtime transactions consume materials or award products.

| ID | Final objective | product |
| --- | --- | --- |
| stars_ch06_sword | stars_sword_verified | empty |
| array_ch06_steps | ten_directions_verified | empty |
| basket_ch06_weave | basket_weave_verified | basket |
| r03 | r03_craft_verified | bird or box |
| l02 | l02_repairs_verified | three_repairs |

Receipt materials_used is an exact ID→quantity recipe proposal. Items must have owner ch06_workbench or char_liang_xiao, state available, nonempty form and sufficient finite integral quantity. The session retains only the relevant immutable item entries, required authorizations, method, scene_id and objective_id, rather than copying all earlier chapter receipts. Hash binding covers this projection. If supplied, objective_id must equal the current puzzle ID.

- Basket: item_ch06_bamboo ×2.
- R03: item_ch06_fine_strips ×1; method bird/box; authorizations r03_soak_verified and r03_family_letter.
- L02: item_ch06_dry_pine ×2, item_ch06_reused_sleeve ×1, item_ch06_willow_pin ×1, item_ch06_iron_hoop ×1, item_ch06_rawhide ×1, item_ch06_pine_resin ×3. Method waterwheel/cart; authorizations l02_measure_waterwheel, l02_measure_cart, l02_measure_plough, l02_borrowed_materials_verified, l02_liting_help. Resin collection and Li Ting's agreement are runtime/world prerequisites, not objects invented by the panel.

Begin and restore reject missing material, spent material, insufficient stock, missing authorization or a changed method. Ordinary close does not reset the session. Retry restores only this session's reserved, uncommitted resources; final completion cannot be retried into another product. Undo and snapshots preserve the exact partial weave, stock and component locations.

## Hints, assistance and bounded-history honesty

Three hint levels are separate from explicit assist_step_v1. Each assisted action performs one normal legal operation, using the same validators; it is not a success flag. Undo/retry preserve hints and assisted status. Future changes must introduce a new versioned assist action rather than changing published semantics.

Input history is bounded at 1024. When full, reset/retry can always restart physical work. Public apply_input rejects the internal restart_after_limit action. Restore can replay a leading bounded restart summary, but its discarded-log hash is diagnostic, not proof of earlier actions. Every such restart sets state.history_reset=true and receipt.previous_attempt_history_unverified=true; undo/retry preserve this marker. UI explicitly states that the previous attempt's hint/assistance history cannot be verified. Such a result must never be described as an entirely unhinted manual history. All physical work in the new attempt must still validate. This is single-player deterministic replay, not cryptographically authenticated history.

Malformed trees are bounded before recursive normalization; non-finite values, wrong types, cycles, deep trees, impossible action fields and oversized histories reject safely. No private keys or fake signatures are used.

## Author evidence, 2026-10-14

Godot 4.6.3. Use isolated writable XDG directories:

~~~sh
export XDG_CACHE_HOME=/tmp/kunlun-cache
export XDG_DATA_HOME=/tmp/kunlun-test-data
export XDG_CONFIG_HOME=/tmp/kunlun-config
godot --headless --path game --script res://tests/test_chapter_six_puzzles.gd
~~~

Latest author suite: **5474 checks, 0 failures**, clean log. Covers seven method paths (both R03 branches and both L02 priorities), JSON roundtrip after every tested operation, stock/length/resin conservation, unique strips, wrong vectors/sums/steps/weave/heat/cuts, duplicate resource rejection, immutable method, partial interleaving, malformed snapshots and fields, actual bounded-history retry and explicit old-history marker. Both 616×335 and 1200×650 UI shells complete all seven paths through actual manual input signals, with collapsed long rules, adjacent selectors/actions and safe release while a focus restoration is pending. Assistance is separately tested through the same model validators.

Old puzzle regressions on the chapter-six tree: chapter two 1150/0, chapter three 4543/0, chapter four 3027/0, chapter five 3436/0. Import and these logs were clean. These are headless and signal checks, not natural GUI acceptance.

Independent model review is separately reported. Natural graphical playthrough, runtime atomic transactions, full chapter save migration and final art/voice are outside this module's author evidence.

## Preview

~~~sh
godot --path game --script res://tests/preview_chapter_six_puzzles.gd -- stars_ch06_sword
godot --path game --script res://tests/preview_chapter_six_puzzles.gd -- r03 box
godot --path game --script res://tests/preview_chapter_six_puzzles.gd -- l02 cart
~~~

Any of the five IDs is accepted; optional method selects the synthetic trusted fixture, not an in-session route change. Preview starts at 640×360 and never writes a campaign save. Rules expand/collapse, controls persist across renders, feedback repeats beside each action group and focus is anchored after text changes.

Independent reviewer final isolated-copy evidence: **5989 independent assertions, 0 failures** (1172 math/malformed input, 391 material/authorization, 270 double-limit/marker, 566 disk-write, 3590 fresh-process continuation of 151 partial checkpoints). Reviewer also reran author 5474/0; all final logs clean. Resolver SHA256 `128733a155bc17197cb1e4172d6b02fc8cb808e7893515297321252090c68e12`. This verifies model/replay/storage boundaries; UI statement above remains headless/signal/static only, not natural GUI.
