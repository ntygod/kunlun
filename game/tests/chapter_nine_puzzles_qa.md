# Chapter nine puzzle implementation checks

2026-10-14, local `feat/chapter-nine`, approved contract d4b65e9bf4d23503e45a9029c78ca9505351f7af. No reward issuance lives in the puzzle resolver. No new combat skill, inventory item, or Boss is added.

## Passed

- Formal model `test_chapter_nine_puzzles.gd`: 1422 checks, zero failures. Tests exact 21 mass / -1 moment; enumerates all 64 finite wing/tail/frame/standing configurations with exactly one valid solution; checks all 27 unfinished pine cursor/phase states reachable, multiple waiting solutions, blocked windows, illegal jumps, malformed inputs, StringName normalization, strict material source, wrong token, altered state, assisted/unknown retention, and all flight stages.
- UI `test_chapter_nine_puzzle_panel.gd`: 108 checks, zero failures. Real resolver-driven pine / assembly / trusted prepared checkpoint / flight to drifted, replayed receipts, 568×290 inner-panel layout for 640 viewport allowance, stable IDs, stale token/stage callbacks, stop/hide/F9 cancellation. Teaching schematics are explicitly not finished art. Rules/formulas remain outside scroll; full instructions and controls are scrollable.
- Separate Godot processes `chapter_nine_puzzles_process_driver.gd -- write` and `-- read`: actual JSON content validates pine cursor3/phase1, carrying while collecting, assembled body/frame/left_wing/tail, cranking before release, and rail_moving index1. New process restores and completes each via legal commands, replays final proof, rejects corrupted snapshot atomically. These tests use isolated `/tmp/kunlun-puzzle9-data`; no natural source save is touched.
- Legacy puzzle regressions: chapter8 630; chapter7 30320; chapter6 5686; chapter5 3436; chapter4 3027; chapter3 4543; foundation chapter puzzles 1150. All zero failures, logs scanned for SCRIPT ERROR / ERROR.

- Actual `main.tscn` headless `test_chapter_nine_main.gd`: 142 checks, zero failures at 640×360 and 1280×720. Real chapter8 source admission, all three puzzle events, board/rules/formulas/footer bounds, actual rail index1 with hero following the bird world projection, real F5/F9 input routes (fresh process-specific save directories), resulting save bytes independently parsed/restored and compared by actual token/state, menu stop and stale panel signal rejection. This is automated main-scene coverage, not graphical/manual QA.

## Persistence and proof boundary

Snapshots retain successful formal command logs (4096 total, 512 per unfinished segment). On segment exhaustion, retry keeps the actual replayed gate prefix (or trusted prepared node6 checkpoint), discards only the unfinished tail, and records unknown/assisted explicitly. The internal reset marker is rejected as player input. Ordinary retry retains prior commands and cannot lower history status. Full logs, current state, and trusted campaign context are replayed; hashes are change detectors, never proof of authenticity. Node6 can finish only prepared, with no PZ500. Node7 requires campaign-supplied node6 snapshot and original context, replays that prefix, then records the same bird through dual crank, release, four rail edges, fixed stall, palm lift, cloud exit, landing and drift. Only the completed result is eligible for campaign reward validation. Actor work paths and single-owner carried components are preserved; vehicle passengers share vehicle motion rather than fabricated walking edges.

## Not run / integration gate

No graphical/manual GUI run, Fal/image generation, upload, release, or remote publication. Story receipts, XP/currency idempotency, complete campaign save loader, and natural chapter8 entry are integration-owned gates. All artwork here is teaching schematic only.
