# Chapter nine independent state and source review

Reviewed by independent state reviewer, 2026-10-14 UTC. No production files/index modified; all test scripts and fixtures are isolated under /tmp. No GUI, upload, Fal, release or export claim.

## Outcome

No remaining blocking state/source defect found in the covered scope. Skill acquisition defect found on 2eb2544 is closed at 87443a58e0daae46aa73efbac9f5dbff9a4c8f02. Final incremental production review/test target: 71e3503d9ebcec620b8d2d27a035ee9cd5c47658.

## Resolved finding

Chapter 4 R02 actually appends LYY_A03 to learned skills and sets rank 1 (chapter_four_runtime.gd), consistent with V3 module 07 skill row. At the original chapter-nine endpoint this remained rank 1 in both real R02-complete and chapter-five-first-acquisition histories. Root clarified ordinary ACTIVE-skill catch-up, and no invented N/P ranks. 87443a58 now catches up only already learned active skills at the chapter-nine archive; genuine R02 acquisition gets A03 rank 3, otherwise rank 2. Old chapters/source saves are not rewritten. Exact new rules and passive/internal exception are in the revised source decisions.

The original author main fixture used logical-only synthetic F5 while the input binding requires physical F5; it did not write a file. This was a test-fixture issue, not a demonstrated production save failure. The final 71e3503 main fixture passes with matching keys and fresh test data.

## Independent test evidence

At 87443a58, custom review_nine_state.gd: 15 complete routes, 6373 checks, zero failures.
- Natural source: A 471, B 471, no L05 455, early partial/close 474, blood-well late return 473.
- Actual A escort partial then cutoff 517; actual B sorting partial then cutoff 482; A escort partial then resume at final window 535; B sorting partial then resume 500.
- Real generated 0–8 minimum 15015 XP/1050 copper: 330.
- Real generated 0–8 historical routes R02 absent 331 / R02 completed 344.
- Real chapter-seven minimum through actual chapter-eight loadout input, then chapter nine: empty slots 330; one P03 330; P02/P03 330. Natural source additionally covers P01/P03, historic default P01/P02.

Checks cover exact +2830/+3130 XP and +600 copper; absent Liu equal XP and only max-HP growth delta with MP/status preserved; fixed-level snow actual vitals; ordinary gear/two slots; old items byte-equivalent; Wang fixed death; intact unique diamond; both hammer/slips retained; L05 key/memory only on archive; prepared has no bird 500 and payment follows drifted; repeated old tokens have no effect; malformed model commands, sync/phase/reward injection, token/history mutation, summary shape/type/vital/resource injection reject atomically; 0–8 bounded summaries remain equivalent; repeated final restore remains idempotent.

At 71e3503 final incremental recheck:
- Custom natural A 345, no L05 329, paused B resumed at final window 374: 1048 checks, zero failures.
- Registered actual-main test 142; battle-main stale panel test 71; boundaries 86: all zero failures.
- Custom real main, two independent Godot processes: writer 23 / reader 21, zero failures. Actual F5 writes pine phase 1, wood collecting/part carry, and same wood cranking; independent process F9 restores exact token, full model snapshot, actors and items, and resumes legal completion.

Prior unchanged models at 2eb2544 were rerun independently: puzzles 1422, world 1214, encounter 244, all zero failures. These are separately layered results, not a claim that every old test was fully rerun on 71e3503.

## Source fidelity

Read AGENTS, current scope/readmes, both approved chapter-nine contracts, relevant original V3 03/06/07 passages and registered runtime/content. 16 nodes preserve the key chain: calendar hope; separated observation/needle/mountain places; prayer before live-pine harvest; one bird preparation and later full escape proof; Wang's fixed death and distinct hammer/tag/stone ownership; stop arrows and treated/released captives; L05 through final tent confirmation; fixed well tragedy; empty finger rather than returned ring; narrative-only palm wound; intact diamond; refused calendar petition/western order; dual bag priority without deleting either object; distinct court rewards abandoned while ordinary resources remain. Original choices are retained via the explicitly approved adaptations, not reverted to conflicting novel/V3 alternatives. Validator passes 16 nodes / 88 main+side steps and source hashes.

History coverage includes natural A plus formally generated alternate old histories, not exhaustive Cartesian combinations or GUI playthroughs. The unchanged-source assertions cover retained original items, including custody and old bird/box/star choices as present in those histories. No medicine inventory/API is claimed.

## Reproduction and evidence paths

Custom scripts: /tmp/kunlun-nine-state-87443/game/tests/review_nine_state.gd and /tmp/kunlun-nine-state-71e3503/game/tests/review_nine_main_process.gd. REVIEW_CASE selects A/B/none/partial/late/partialA/partialB/resumeA/resumeB; REVIEW_SOURCE optionally selects a formal fixture; REVIEW_FAST=1 omits the exhaustive malformed-summary field matrix. Main script uses PROCESS_MODE=write then read in separate Godot processes. Logs: /tmp/k9-review/fixed_*.log, last_*.log, final_main_*.log, final_test_chapter_nine_*.log. Standalone test fixture exports /tmp/k9-review/final_*.json are not authoritative evidence because parallel routes can replace the same descriptive output name; per-process logs and source IDs are the evidence.

Frozen natural chapter-eight original remained read-only and SHA256 unchanged after review:
41299aae21511c4a3913c9d15ec124b098c07470ab59fb6bc24d266606adf42e.

Formal generated minimum fixture SHA256 d6e605a9ae1cbc77cdbd0a473f6641f600dc84e8e8249f9a5e8b1ce977f48ff6; history 0/0 02fc54a59c8bc4bb4ceb2c9a2c70fe6faa2a9a19057b36dd4fa18d4b17b27157; history 1/3 c888476a7424a953db63adb3cdab39cb270882c731eb3b85aba64ff96b636fdd.

## Persisted reproduction copies

The reviewed custom scripts are now retained as `game/tests/review_chapter_nine_state.gd` and `game/tests/review_chapter_nine_main_process.gd`. The /tmp log paths above identify the original independent runs; they are not shipped save slots or claims of retained user progress.
