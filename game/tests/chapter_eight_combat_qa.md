# Chapter eight combat evidence (2026-10-14)

Approved contract: `10cac89deeebb2e9437b5190c88e731fe788b7d8`, `docs/development/chapter-eight-content.md` §§4,7,9. Standard only; no difficulty system added. No GUI, images, upload, export or release performed.

## Implemented boundary

- `chapter_eight_engine.gd`, `chapter_eight_encounter.gd`, `chapter_eight_encounters.json`, and `chapter_eight_battle_panel.gd` are isolated from frozen chapter 0–7 combat.
- River duel is three two-round windows; cover, actual three-talents induction and actual flying-star interruption each run six resolved rounds. Yun Shu is alive, and the three adjacent steps lead back to the ballista operation position. No extra boss reward.
- B05 uses calibrated level38 K=173.063291139241. Three unique hubs sum3200. Six actions can prevent every arrow. Breaking on round2 cancels the pending round3 arrow; breaking during loading does not suppress a future chain. The following protection round allows calibration, not a new break.
- The same battle pauses in the world. MP/CD/statuses/equipped slots/P03 event set/item-use count and global round persist. Actual campaign HP growth differences are merged into the existing actor; MP is retained. Fire confirmation creates one phase2 checkpoint only after prior growth synchronization.
- Each escort interception is a preparation action taking the entire270 raw package through one DEF/25% reduction branch. It does not call generic50% guard sharing. A no-P03 Lv37 actor loses123HP in this branch, with exactly one damage event.
- Phase2 pressure3800 is not organismHP. The carrier has neither `hp` nor `max_hp`; counter damage never reaches a fictional HP target. Three unique induction events remove1267/1267/1266. Normal attacks are narrative only and give no damage, layer, kill, heal or mana reward. Flying-star and other incompatible attacks reject before spending.
- Two passive slots enforce acquisition and uniqueness. Only equipped P03 gets unique genuine disarm/interruption layers, max3. Induction adds no layer. Multiple category tags give25% once; category bonuses take the maximum. Attack/defense layers use permanent panels and same-type maximums. No absent ally or scene civilian triggers P02.
- No medicine-use action exists in frozen prior runtime or this chapter. The campaign preserves `medicine_uses=0`; no consumables are granted or spent, and no medicine/CD reset is introduced.

## Real minimum and separate stress fixture

The actual formal0–7 no-side route ends11220XP,500 copper, no N01. The500 is chapter7's mandatory terminal award; it is not a0-copper formal save. The root confirmed this distinction. `test_chapter_eight_combat_minimum.gd` runs the real preceding chapters and formal chapter7 save validation before applying exact approved chapter8 transactions. No coin API or spending is involved in the battle route.

At B05 entry, actual13050XP/Lv37 and the approved equipment give1127HP/132MP/178ATK/111DEF/40SPD after explicit preparation. First six actions preserve1127HP and build three P03 layers. Main awards300,65,150 synchronize in order. Phase2 uses three-talents at global rounds9/12/15,19MP each, ready rounds11/14/17, with the actual rank3 recovery and caps. Final845HP/117MP after15 global rounds; no N01, item, shop or optional L04 required.

A separately labelled pure combat stress fixture begins phase2 at0MP without N01/P03/items. It really misses the first induction window, guards, observes and protects the exposed batch again. It completes after18 global rounds at595HP/21MP. This is not claimed as a legal historical campaign save.

## Commands and results

Use isolated `XDG_CACHE_HOME=/tmp/kunlun-eight-cache`, `XDG_DATA_HOME=/tmp/kunlun-eight-data`, `XDG_CONFIG_HOME=/tmp/kunlun-eight-config` with `godot --headless --path game --script res://tests/<name>.gd`.

- `test_chapter_eight_combat`:263 checks,0 failures.
- `test_chapter_eight_combat_boundaries`:102 checks,0 failures.
- `test_chapter_eight_combat_minimum`:414 checks,0 failures (shared historical driver prints `Chapter seven minimum source`).
- `test_chapter_eight_battle_panel`:713 checks,0 failures. Both1280×720 and640×360, dynamic shrinking, objective board/feedback/footer visibility, scroll preservation, popup/focus, input cap/retry, stable IDs, real costs/CD, and actual6+6+9-round button-driven flow. This is headless layout/input verification, not GUI acceptance.
- `chapter_eight_combat_process_driver`: launch separate `CH08_REPLAY_MODE=write` then `read` Godot processes.30 writer checks and150 reader checks,0 failures. Fourteen saved points cover queued phase1 input, intermission, grown intermission, confirmed phase2 entry, each batch crossing/protected/queued-counter and completion. Exact resource/CD/layer/path snapshots match; tampered state is rejected atomically.
- Frozen regressions: `test_combat`134, `test_chapter_two_combat`171, `test_chapter_three_combat`5171, `test_chapter_four_combat`707, `test_chapter_five_combat`49, `test_chapter_five_combat_boundaries`175, `test_chapter_six_combat`77, `test_chapter_six_combat_boundaries`83, `test_chapter_seven_combat`101, `test_chapter_seven_combat_boundaries`204; all0 failures, logs scanned for`SCRIPT ERROR`/`ERROR`.

## Trust protocol

The campaign owns permanent actors, rewards and world progress. Stage1 receipts reject every history operation except input/command/resolve. Phase2 verification uses the campaign's trusted resumed checkpoint as an exact immutable history prefix; suffixes again permit only input/command/resolve. `phase_attempt_id` binds the current escort token while the initial attempt and battle identity remain stable. A bare success flag, stale revision, boolean/float public revision, forged prefix, replayed depleted hub, or modified snapshot cannot produce an accepted battle receipt.

`sync_campaign_actor` and bounded `sync_campaign_context` are world-owner transitions and are replayed only inside the trusted prefix. No-op context sync appends nothing. The campaign navigation layer must independently require its canonical context/party for phase1 and immutable resumed prefix for phase2; deterministic self-replay alone is not authorization to invent world growth.

Remaining independent gates: full campaign/world integration matrix and its natural GUI route, final art/audio, timing/difficulty tuning, export and publication. Unit fixtures and headless UI do not claim these gates.
