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
