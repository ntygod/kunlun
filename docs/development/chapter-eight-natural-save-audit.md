# Chapter eight natural final-save audit

This is a read-only internal-state audit, separate from graphical acceptance.

- Source: `output/cache/chapter_eight_gui/manual_natural_final.json`, 39,290 bytes.
- SHA256: `41299aae21511c4a3913c9d15ec124b098c07470ab59fb6bc24d266606adf42e`.
- Production under audit: `2d618ebc097b32d41906791cfeab5205efdf89fd`; no production changes.
- Official restore, prepare-save validation and restore into a second new campaign all succeeded. Isolated XDG, no `ERROR`; original source unchanged.
- 32 explicit audit checks passed. Full checks and exact item/reward records: `chapter-eight-natural-save-audit.json`.

## Resources and ownership

| Actor | XP / level | HP | MP | Status |
| --- | --- | --- | --- | --- |
| Liang Xiao | 17,665 / 43 | 1,027 / 1,291 | 122 / 143 | present |
| Liu Yingying | 17,665 / 43 | 821 / 1,032 | 83 / 120 | temporarily absent |
| Axue | 0 / 23 | 236 / 480 | 75 / 75 | recovering in camp |

Chapter eight adds exactly 4,095 XP (1,695 main nodes + 800 dam + 800 cannon + 500 escort + 300 L04) and 550 copper; final copper is 2,450. Previous reward entries and all 46 previous items are unchanged. Six new unique story items exist; the star beads belong solely to Axue. The father's book remains entrusted at the chapter-six home; the returned pouch still has zero escrow. No item is given an invented numeric healing effect.

Liang's equipment is the single chapter-eight replacement, not stacked with old gear. Learned P01/P02/P03 are distinct from the two equipped slots P01/P03; there is exactly one loadout record. The final sword rank is 2. Axue's entire permanent actor record is unchanged from the natural chapter-seven source. Liu receives the same XP while absent, with only the legitimate max-HP growth difference added to current HP and no MP refill.

## L04 and battle chronology

L04 method A is archived: grandmother and child sheltered, both looters disarmed and departed, shelter dialogue complete, narrative injury true and method-B neighboring-hut protection false. Three civilian batches are safe, with zero lethal kills. Exactly two explicit rest receipts exist.

The semantic commit order is uniquely phase-one ballista battle → L04 rescue → L04 archived → fire confirmation → civilian escort. These are bounded archive outcomes. The final save has already discarded live battle snapshots and original per-turn proof history; therefore this audit does not claim to reconstruct actual MP/CD or P03 stacks from this final summary. Those require the separate in-progress save and GUI evidence. No nonzero drug-use inheritance is claimed, because consumable use is not implemented.

## Graphical checkpoint evidence correction

The first GUI-run filenames were not reliable descriptions of their saved contents. `b05_phase2_entry.json` and `l04_complete.json` actually contain an earlier live L04 checkpoint, not a phase-two entry or completed-L04 checkpoint. Those original GUI intermediate-save/reload claims are withdrawn pending a file-content-verified repeat. This does not invalidate the natural final-save audit above or the separately completed headless process tests.

A read-only official restore of `b05_phase1_queued.json` (222,315 bytes, SHA256 `e4a398f5dcb44c4cfd26304a2b20da878c70d2b0f75c9ec604202904d4a30b1e`) confirms token `ch08_ballista_objective:02`, phase one, round 2, command-selection mode: left gear inspection has resolved; the calibrated shot at that gear is queued but unresolved. Liang has 1,208/1,208 HP and 138/138 MP; P03 stacks are zero; three bolts and all three hubs remain. The last campaign event is the preceding dialogue completion because current queued battle input is stored in the navigation objective snapshot. This file proves the queued first-phase snapshot, not a finished six-action phase or three P03 stacks.

The replacement checkpoint repeat subsequently completed. `verified_phase2_entry.json` is 299,955 bytes with SHA256 `db2fc4db281316bb03858e8576bfb07011dbec023a1e7f0a67b1454e05f0a2c1`. Official restore confirms `ch08_civilian_escort:00`, phase two at total round 7, history/trusted prefix 169, HP1235/1235, MP138/140, P03=3, completed/archived L04 and confirmed fire. An empty immediate objective snapshot is valid at this entry: the single campaign checkpoint restores the same battle. The GUI owner separately verified independent restart and phase-two-only failure/retry. This replacement does not rehabilitate the original mislabeled files; see `chapter-eight-gui-acceptance.md` for precise scope.
