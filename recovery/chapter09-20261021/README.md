# Kunlun chapter 09 recovery checkpoint

This branch adds recovery artifacts only. It does not change main, publish a game release, or replace the preserved chapter 09 history.

The bundle preserves exact source commit `13de855271fb81abd8a5a51777de708c252b9186` and 104 commits after the existing main checkpoint. The evidence archive contains 53 original project test/evidence files plus an integrity manifest. All 50 historical hash checks matched before packaging. The previous temporary archive was lost, so the rebuilt archive has a different checksum; its constituent historical evidence files are unchanged.

## Restore

Fetch this recovery branch into a full clone of `ntygod/kunlun`, retaining main history. Copy `recovery/chapter09-20261021/` out to a temporary directory before switching branches. Read `manifest.json`; concatenate each listed file's chunks in listed order, verifying each chunk SHA256 and the complete file SHA256.

Then run `git bundle verify /path/to/kunlun-chapter09-delta.bundle`, import its `refs/heads/feat/chapter-nine` into a distinct recovery branch, and verify the resulting commit is exactly the source commit above. Do not reset main or overwrite unrelated work. Extract the evidence archive at the recovered repository root without overwriting any newer local evidence.

The bundle requires both listed prerequisite commits, already ancestors of existing main. Shallow clones must first obtain that history. Code instructions are in `AGENTS.md`. Current scope and still-open graphical checks are in `docs/development/chapter-nine-gui-acceptance.md`, `chapter-nine-ledger.md`, and `development-plan.md`.

The archive excludes engine caches, personal save directories, authentication files, and unrelated screenshots. Original chapter 08/09 natural-save JSON files must remain immutable.
