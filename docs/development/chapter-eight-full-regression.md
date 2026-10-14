# Chapter eight clean-copy regression

Candidate: `2d618ebc097b32d41906791cfeab5205efdf89fd` (tree `ff5e70b29e32108c71728ef068f1cee501c052f7`).

All **122 execution rows** passed; **107,345 counted assertions**, zero failures, and no `ERROR` in final logs. The separate design-reference validator passed 184 checks (not added to the Godot total).
The 90 regular executable test scripts account for 93,576 assertions; branch variants, matrices and process checks account for 13,769 additional assertions.

## Method

Clean git archive; fresh Godot 4.6.3 import; isolated per-job XDG cache/data/config; six hash-verified natural fixtures; paired fresh processes share only their own group XDG.

The executor restarted during the run. The 22 terminal results already recorded were retained; unfinished/unknown work was rerun. All 620 tracked archive files and six fixtures were reverified after restart; the sole line-ending difference is the existing `.gitattributes` CRLF rule for the PowerShell workspace helper. No production change was made during this suite.

The original runner misread the existing Chapter04 combat checks 707 failures 0 line. Final normalization recognizes both count formats; the actual test exited 0 with failures 0. Raw logs and raw runner records retained.

## Coverage

- All resident finite `test_*.gd` tests through chapter eight, plus foundation `run_tests.gd`.
- Natural chapter-eight A, sand-method B, and no-L04 routes; full historical matrices and additional old-history branches.
- Seven fresh-process write/read pairs: chapter-seven combat/puzzles/world; chapter-eight combat/puzzles/world/full campaign state.
- Data validation, combat-rule verification, V3 design audit, clean import and 120-frame startup.
- The full manifest, per-row commands/environment/exit codes/assertion totals, fixture hashes and final log SHA256 values are in `chapter-eight-verification.json`.

The V3 audit ran successfully but still reports **24 existing action-name mapping differences and 28 map groups over limits**. Execution success does not resolve those full-game design findings.

## Exclusions and limits

- Assertion counts are not unique independent scenarios.
- Headless tests do not imply graphical QA, finished pixel-art acceptance, release export, or publication.
- Generic consumables are not implemented; medicine_uses remains a zero-only placeholder. Nonzero drug-use inheritance is not claimed.
- Existing standard-difficulty runtime only; other difficulty UI is not implemented.
- Interactive preview/fixture-preparation scripts and pure driver helpers are not independently executed. Drivers are exercised by the listed tests.
- Asset generation/build tools and standalone profiling diagnostics are outside this finite regression suite.

## Results

| Job | Assertions | Result |
| --- | ---: | --- |
| `audit_v3` | 0 | passed |
| `chapter_eight_branch_b` | 152 | passed |
| `chapter_eight_history_old_branch_0` | 3328 | passed |
| `chapter_eight_no_side` | 146 | passed |
| `chapter_five_battle_entry_natural` | 52 | passed |
| `chapter_five_history_old_branch_0` | 2296 | passed |
| `chapter_four_interleave` | 114 | passed |
| `chapter_four_residual` | 123 | passed |
| `chapter_four_second` | 122 | passed |
| `chapter_four_unfinished` | 122 | passed |
| `chapter_seven_history_old_branch_0` | 2600 | passed |
| `chapter_seven_minimum_source` | 356 | passed |
| `chapter_six_history_old_branch_0` | 2368 | passed |
| `clean_import` | 0 | passed |
| `clean_startup_120` | 0 | passed |
| `process_eight_combat_read` | 150 | passed |
| `process_eight_combat_write` | 30 | passed |
| `process_eight_puzzles_read` | 0 | passed |
| `process_eight_puzzles_write` | 0 | passed |
| `process_eight_state_read` | 0 | passed |
| `process_eight_state_write` | 0 | passed |
| `process_eight_world_read` | 0 | passed |
| `process_eight_world_write` | 0 | passed |
| `process_seven_combat_read` | 35 | passed |
| `process_seven_combat_write` | 36 | passed |
| `process_seven_puzzles_read` | 0 | passed |
| `process_seven_puzzles_write` | 0 | passed |
| `process_seven_world_read` | 0 | passed |
| `process_seven_world_write` | 0 | passed |
| `run_tests` | 476 | passed |
| `summary_generated_fixture` | 1739 | passed |
| `test_battle_panel` | 7 | passed |
| `test_bounded_saves` | 587 | passed |
| `test_chapter_eight` | 152 | passed |
| `test_chapter_eight_battle_panel` | 713 | passed |
| `test_chapter_eight_boundaries` | 234 | passed |
| `test_chapter_eight_combat` | 263 | passed |
| `test_chapter_eight_combat_boundaries` | 102 | passed |
| `test_chapter_eight_combat_minimum` | 414 | passed |
| `test_chapter_eight_combat_review` | 309 | passed |
| `test_chapter_eight_entry` | 0 | passed |
| `test_chapter_eight_history_matrix` | 3512 | passed |
| `test_chapter_eight_low_vitals` | 5 | passed |
| `test_chapter_eight_minimum` | 398 | passed |
| `test_chapter_eight_puzzle_main` | 39 | passed |
| `test_chapter_eight_puzzle_panel` | 93 | passed |
| `test_chapter_eight_puzzles` | 630 | passed |
| `test_chapter_eight_world` | 829 | passed |
| `test_chapter_eight_world_projection` | 580 | passed |
| `test_chapter_five` | 295 | passed |
| `test_chapter_five_battle_entry` | 368 | passed |
| `test_chapter_five_combat` | 49 | passed |
| `test_chapter_five_combat_boundaries` | 175 | passed |
| `test_chapter_five_history_matrix` | 2480 | passed |
| `test_chapter_five_main` | 224 | passed |
| `test_chapter_five_puzzles` | 3436 | passed |
| `test_chapter_five_routes` | 316 | passed |
| `test_chapter_five_transactions` | 138 | passed |
| `test_chapter_five_world` | 946 | passed |
| `test_chapter_four` | 121 | passed |
| `test_chapter_four_combat` | 707 | passed |
| `test_chapter_four_horse_wait` | 28 | passed |
| `test_chapter_four_main` | 195 | passed |
| `test_chapter_four_presentation` | 70 | passed |
| `test_chapter_four_puzzles` | 3027 | passed |
| `test_chapter_four_routes` | 434 | passed |
| `test_chapter_four_transactions` | 224 | passed |
| `test_chapter_four_world` | 739 | passed |
| `test_chapter_main` | 105 | passed |
| `test_chapter_one` | 628 | passed |
| `test_chapter_puzzles` | 1150 | passed |
| `test_chapter_seven` | 263 | passed |
| `test_chapter_seven_battle_panel` | 30 | passed |
| `test_chapter_seven_boundaries` | 112 | passed |
| `test_chapter_seven_combat` | 101 | passed |
| `test_chapter_seven_combat_boundaries` | 204 | passed |
| `test_chapter_seven_combat_minimum` | 431 | passed |
| `test_chapter_seven_demo_main` | 34 | passed |
| `test_chapter_seven_funiu_panel` | 148 | passed |
| `test_chapter_seven_history_matrix` | 2784 | passed |
| `test_chapter_seven_main` | 131 | passed |
| `test_chapter_seven_minimum` | 364 | passed |
| `test_chapter_seven_puzzle_panel` | 730 | passed |
| `test_chapter_seven_puzzles` | 30320 | passed |
| `test_chapter_seven_world` | 1179 | passed |
| `test_chapter_seven_world_projection` | 132 | passed |
| `test_chapter_six` | 580 | passed |
| `test_chapter_six_battle_panel` | 283 | passed |
| `test_chapter_six_boundaries` | 197 | passed |
| `test_chapter_six_combat` | 77 | passed |
| `test_chapter_six_combat_boundaries` | 83 | passed |
| `test_chapter_six_combat_minimum` | 383 | passed |
| `test_chapter_six_helper_timing` | 204 | passed |
| `test_chapter_six_history_matrix` | 2552 | passed |
| `test_chapter_six_main` | 118 | passed |
| `test_chapter_six_puzzles` | 5686 | passed |
| `test_chapter_six_routes` | 634 | passed |
| `test_chapter_six_transactions` | 65 | passed |
| `test_chapter_six_world` | 907 | passed |
| `test_chapter_six_world_projection` | 24 | passed |
| `test_chapter_three` | 2606 | passed |
| `test_chapter_three_battle_lifecycle` | 128 | passed |
| `test_chapter_three_battle_panel` | 250 | passed |
| `test_chapter_three_boundaries` | 334 | passed |
| `test_chapter_three_combat` | 5171 | passed |
| `test_chapter_three_escape` | 67 | passed |
| `test_chapter_three_main` | 679 | passed |
| `test_chapter_three_puzzles` | 4543 | passed |
| `test_chapter_three_world` | 348 | passed |
| `test_chapter_two` | 903 | passed |
| `test_chapter_two_boundaries` | 372 | passed |
| `test_chapter_two_combat` | 171 | passed |
| `test_chapter_two_main` | 426 | passed |
| `test_chapter_two_world` | 429 | passed |
| `test_chapter_world` | 333 | passed |
| `test_combat` | 134 | passed |
| `test_completed_chapter_summary` | 1382 | passed |
| `test_dialogue_layout` | 28 | passed |
| `test_menu_save_hotkey` | 69 | passed |
| `test_party_progression` | 1249 | passed |
| `validate_data` | 0 | passed |
| `verify_combat_rules` | 0 | passed |
