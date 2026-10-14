# Chapter three spatial encounter QA

These are hand-authored development geometry and candidate pixel dressing, not final art or the authoritative V3 map extents. The independent harness never writes campaign saves or awards XP. All movement in encounters uses the same deterministic, collision-checked controller for direction keys and buttons; time advances only on a move or an explicit one-phase wait.

## Entrypoints

From repository root, with isolated XDG cache/data/config directories:

- `godot --headless --path game --script res://tests/test_chapter_three_escape.gd`
- `godot --headless --path game --script res://tests/test_chapter_three_world.gd`
- `godot --path game --script res://tests/preview_chapter_three_world.gd -- shadow`
- Replace `shadow` with `abacus`, `decoy`, `medicine`, or `lingtai` for the other variants.

The preview renders a 320×180 nearest-neighbor world at 4× with a separate Chinese UI. Arrow keys are discrete 16-pixel encounter moves; Space advances one phase; buttons invoke exactly the same controller. Escape closes the preview. No real-time QTE is required.

## Stone shadows, reproducible route

Start (80,208). Walk to Yurang (144,208), inspect, and correct steps 1 and 2 in order. Walk to Zhuhai (224,208), wait until overlap, and feint while Ming can see the action. Continue to Zhuanzhu (272,208), carry Xiaoshuang, then proceed to Wuyang (368,208), feint at overlap, cross Gao Jianli (416,208), Jing Ke (496,208), and exit (560,208).

For the abacus branch, take two additional, different cover rests. After carrying, approach pocket one from (352,208) → (352,112) → (304,112). Remain hidden for approach → overlap → recede. Exit the same way. After Gao Jianli, approach pocket two from (496,208) → (496,112) → (448,112), remain hidden through the same three phases, and exit the same way. The L-shaped stone plinths genuinely block sight; repeating one pocket never credits another.

Ming follows his last visible position through collision-safe navigation. Before both wrong steps have been corrected, the opening observation is a safe tutorial pause. After correction two, waiting in plain sight allows him to catch the player. Capture does not kill either character. Retry restores the encounter checkpoint, and does not issue a receipt or rewards.

## Cloak decoy, reproducible route

The standalone preview starts carrying Xiaoshuang at (80,208). Inspect blood at (144,208), then go via (304,208) and (304,112) to the concealed hollow (224,112). Shelter Xiaoshuang and take her unique pale-jade cloak. Lead the animals to (256,112), and leave them guarding. Return via (304,112) and (304,208), and cover the dry branch at (352,208). Walk through east lane (448,208) to departure (560,208). Wait in the safe departure area until Ming visibly acquires the cloak and actually walks beyond the fork at x=304.

In the campaign, a trusted preceding scene that already placed Xiaoshuang and both animals in `ch03_hidden_hollow.occupants` starts at that concealed checkpoint instead. Retry restores that checkpoint and returns the same cloak to Xiaoshuang. It never duplicates the cloak or repeats rewards. Returning to the hollow after laying the decoy invalidates the attempt.

## Interface and evidence

`shadow_escape.gd` implements begin, apply_input, get_view, snapshot, restore, and receipt. Snapshot restoration replays every direction/object operation against the frozen map hash and compares state/event hashes. It does not accept external positions, arbitrary completed flags, forged snapshots, unknown versions, or changed geometry. Receipts contain attempt/map/scene/objective IDs, input and engine event logs, before/after hashes, and no reward mutation. The chapter transaction must compare and consume the trusted receipt, never accept a UI `won` flag.

`world.sync_escape_view(view)` disables ordinary player motion and draws actual controller positions, facing, last-visible mark, phase-highlighted anchors, carried composite, sheltered animals, and the placed cloak. On leaving this mode, clear with an empty view; the main UI owns whether to re-enable ordinary movement.

## Latest automated evidence

2026-10-13: dedicated escape 67 checks, world 334 checks, zero failures or script errors. Existing chapter-one world 333 and chapter-two world 429 passed after the world changes. Dedicated preview headless startup passed. Human GUI playthrough and finished art remain separate gates.

Collision revision 2 additionally verifies occupied-cell entry and same-tick swept interception before awarding a fork crossing. The pure-input t72 head-on swap is now captured. A full 8192-input attempt still allows a safe retry, clears only that uncommitted attempt, and restores/replays cleanly.
