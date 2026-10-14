# Chapter nine world/L05 development candidate verification

2026-10-14. Approved source/content contract: `d4b65e9bf4d23503e45a9029c78ca9505351f7af`. This is a headless implementation report, not natural GUI acceptance or finished pixel art.

## Owned implementation

- `data/maps/chapter_nine_maps.json`: eight semantic maps, dimensions matching the approved candidate sizes. All terrain, route and landmark placements are hand-authored. Stone-work, roofs, pines, temples, wells, physician chest and court rack are hand-drawn pixel primitives in `scripts/chapter_nine_world_presentation.gd`.
- `scripts/world_actions/chapter_nine_world_actions.gd`: controlled interactive scenes `scene_ch09_three_masters`, `scene_ch09_four_instruments`, and `rescue_ch09_l05`. No combat stats, grants, resource changes, death flags or new passive skills are owned by this model.
- `scripts/chapter_nine_world_presentation.gd`: read-only live/persisted spatial projection. The large wooden bird consumes the single puzzle model's construction/flight stage and actual passenger coordinates. `drifted/completed` hides the large bird. Court seal/robe/armor/chest display on the rack only when authoritative items say owner `camp`, location `linan_tent_rack`. Hammer, Li Ting's charred tag and empty-tent stone are independent objects.
- Shared `world.gd` and `main.gd` chapter-nine registration are owned by integration, not this worker.

## Space and physics

Eight maps: shigong_platform 512×320; pine_terrace 384×256; tiandu_peak 576×352; jingkou_camp 608×352; changzhou_street 608×352; west_temple 480×320; command_tent 256×192; linan_residence 576×352. These are 16-pixel logical tile dimensions; the world remains rendered in the existing 320×180 nearest-neighbor viewport with separate Chinese UI.

Every anchor and every generated mainline objective has a BFS route from its real entry. Model collision expands wall rectangles by the actual player's 8×4 half-footprint; the projection test compares every reachable grid cell to `KunlunPlayer.is_walkable`. The physical test follows each distinct anchor/objective route using actual `CharacterBody2D.move_and_collide`, without replacing each footpoint through direct position assignment. Separate targets restart only at the map entry; intermediate positions come exclusively from physics movement.

Tiandu preserves the wooden-bird controller's full 9×7 workspace: origin (176,144), 16-pixel steps. Its rail is (240,192) through (304,192). The physician rescue covers both the west temple and east city-god dry well in one continuous map; the doctor is never teleported across a transition.

## L05 behavior

- Public lock marks: left leaf, middle flower, right fruit. Three finite slots, explicit submit; wrong symbols, remote actions or malformed input change neither state nor input history. This lock has no PZ reward.
- A: inspect/unlock → choose A → question west-side wounded soldier → find doctor at actual dry-well footpoint → start escort → walk back while physician follows one legal edge per action → wait for physician to reach his temple station → return box. Only then does A claim a rescued physician.
- B: inspect/unlock → choose B → switch actual controlled actor to Axue → walk to public labelled medicine station and sort three finite label groups → switch back to Liang → place decoys at the actual road site → lure patrol and wait for actual exit → Xiaoxizi distributes on behalf of his absent teacher. B never sets `found_physician` or `returned_box`.
- Three unique raiders physically block their occupied feet, each requires front observation and actual traversal to the side of a pillar before nonlethal disarm. Each then walks a recorded four-neighbor path to its separate exit; no remote deletion. No raider HP or battle XP exists.
- Shared end: all three actually departed + branch prerequisites → treatment → aftermath → archive. Every contract `side_ch09_l05_*` event and the method choice are in the full proof; A and B have distinct command/event histories. `medicine_owner`, `physician_rescued` and final actor positions reflect the chosen method.
- Model output has no item/XP mutation. Runtime owns the unique 300 XP/key/memory/exploration-only unlock. Pause, return, optional deadline and final irreversible confirmation are integration responsibilities, covered separately by campaign/main tests.

## Reproduction and passing evidence

All runs use separate writable XDG cache/data/config rooted at `/tmp/ch09world`, never natural saves.

- `test_chapter_nine_world.gd`: 1214 checks, zero failures. Eight-map BFS, public lock, both actual L05 methods, individual continuous NPC paths, all stage receipts, JSON exact replay, malformed/fake completion rejection and unchanged live state on failed restore.
- `test_chapter_nine_world_projection.gd`: 11479 checks, zero failures. Sixteen mainline scenes load real maps; all actions/anchors physically reachable; cell-by-cell model/player collision equivalence; controlled actor and NPC coordinates on every real command in both L05 methods; departed raiders hidden; medicine/physician truthfulness; display does not mutate resource context.
- `test_chapter_nine_world_physics.gd`: 1731 checks, zero failures. Actual continuous `move_and_collide` routes to all distinct objectives/anchors in eight maps; two-soldier retreat presentation shows the path before hiding; restored retirement does not replay/resurrect the actor. Initial harness run lacked InputMap setup on its final fresh instance; final rerun includes the input setup and is error-free. No production change was needed for this harness issue.
- `chapter_nine_world_process_driver.gd -- write A /tmp/ch09world/l05_A.json`: 63 checks; separate process `read A`: 129. Actual partial physician escort written/read, then complete legal commands and validate full receipt.
- Same independent process sequence for B: write 46/read 141 checks. Actual decoy-before-lure state written/read, then legal completion without claiming physician rescue.
- Total process checks 379. All listed final logs have no `ERROR` or `SCRIPT ERROR`; assert counts are machine checks, not independent human-played scenes.

During development, JSON restore exposed number-to-string instability (`0` versus `0.0` in a lock event detail) and int/float array comparisons at physician/patrol destinations. Production now canonicalizes the lock slot detail to integer and compares positions as vectors. These failures were fixed and the final tests above rerun; they were not waived.

## Not claimed

No GUI was operated, no file uploaded, no natural save rewritten, no release/export run. No final-art status, full natural playthrough, battle balance, music/voice or elapsed-playtime acceptance is claimed. Three masters/four instruments are controlled interactive cutscenes, not disguised full battles or killable bosses. UI size/movement semantics additionally depend on integration and its dedicated panel/main tests.

## Narrow independent-review fixes (2026-10-14 22:17 UTC)

- Real `StringName` keys and values in context, commands, saved snapshots and proof are normalized to String before validation. Other types are not coerced. Identity fields now check String before comparison, so a boolean map/scene/objective cannot emit an engine operand error. Same-count payloads with a missing required key remain rejected atomically.
- A wait that cannot move a physician, patrol or raider is an explicit successful `no_op`: it changes no state, tick, input log, event or receipt. Inspection is likewise read-only. Selecting an already selected lock symbol is no-op only after inspection, while still locked, and at the chest; it does not unlock or validate the lock. A wait that advances an escort or retreat remains a genuine recorded command. There is no danger clock in this scene model; tick is only presentation.
- Actual 4100 idle waits after real A doctor escort/return preserve the complete snapshot byte-equivalent, survive JSON restore and permit the remaining real disarm/treatment/archive commands. Separate tests distinguish real moving physician, patrol and raider waits, which advance coordinates and retain input history.
- No checkpoint, fake completion, rollback or new migration layer was added. The 4096 genuinely effective-action cap remains a known optional-session boundary; at cap the user can pause to mainline or load a preceding save, but cannot continue this side session. Campaign pause/return/mainline verification is owned and reported by integration/independent review, not claimed from these model tests.
- Chapter nine remains an undelivered development candidate. Old experimental chapter-nine snapshots containing now-removed idle/inspection/same-lock log records are intentionally rejected by exact replay, and the independent review's original experimental files are retained as evidence. This is not a migration of, or change to, released chapters 0–8 saves.
- Source fidelity: corrected map/helper Fang Yue to approved Fang Lan (`方澜`, `npc_ch09_fang_lan`); Jin Fei uses the existing stable `npc_jin_fei`, not a new chapter-prefixed duplicate. Integration owns the matching content cast/registry entries.

Final narrow-fix reruns: boundaries **4502/0**, world **1214/0**, world projection **11479/0**, actual physics **1731/0**, separate-process A **63+129/0**, B **46+141/0**. All final logs were scanned and contain no `ERROR`, `SCRIPT ERROR` or `FAIL`. The boundary harness initially approached the physician station from the east and incorrectly expected an extra movement wait after he had already arrived; the corrected test uses a real south-side approach to leave one genuine movement edge. No state injection or production change was used to satisfy that test.
