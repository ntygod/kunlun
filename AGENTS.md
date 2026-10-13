# Working on Kunlun

## Scope and sources

Build the complete Godot 4 pixel-art RPG under `game/`, beginning with shared foundations and then the prologue through chapter 20. Do not restart a separate Huashan demo. Read [README.md](README.md), [game/README.md](game/README.md), and the current [development plan](docs/development/development-plan.md) before changing scope or reporting completion.

V3's eight modules in `docs/design/v3/` are the authoritative editable design sources: 01 character/story, 02–04 scene scripts, 05 voice/actions, 06 quests, 07 combat, 08 art. The merged Markdown and HTML/PDF are snapshots, not independent sources. Preserve the user's design; do not silently rewrite it. The original novel uses GBK; new source files use UTF-8.

For combat, use the current `combat_rules.json`, `v3_combat_rules_review.md`, and `v3_level80_review.md`. The older numeric review includes already-fixed 40-level issues: do not revert current rules. Current progression caps at 80, with fixed panels for limited characters.

## Implementation contracts

- Use snake_case for code, engine filenames, and runtime IDs. Keep `scenes/`, `scripts/`, `data/`, and `assets/` roles clear; prefer data-driven content and testable rules separated from presentation.
- Inspect source conflicts before binding resources. MAP/MG and ACT IDs conflict between documents; use semantic runtime IDs with explicit source-document/ID mappings. Never assume matching IDs mean matching assets. Record unresolved narrative decisions in the development plan rather than inventing canon.
- Maintain a 320×180 nearest-neighbor pixel world and independent high-resolution Chinese UI. Use hand-crafted pixel art for final assets. Concept images and procedural placeholders are not finished pixel assets; label temporary work honestly. Do not use generated images, downscaled concept art, or uncorrected sprite mirroring as final art.
- Make quest/reward/skip transactions idempotent. Normal playback, skip, retry, and reload must restore consistent inventory, roster, input, memory tags, and world state. Do not award prologue XP to Liang Xiao's progression.
- Read only relevant repository skills if `.agents/skills/` becomes available. Do not copy unrelated projects' architecture or acceptance gates.

## Run and verify

The foundation uses Godot 4.6.3 and `game/project.godot` → `res://scenes/main.tscn`. From repository root:

```sh
godot --path game
python game/tools/validate_data.py
mkdir -p /tmp/kunlun-cache /tmp/kunlun-test-data /tmp/kunlun-config
export XDG_CACHE_HOME=/tmp/kunlun-cache
export XDG_DATA_HOME=/tmp/kunlun-test-data
export XDG_CONFIG_HOME=/tmp/kunlun-config
godot --headless --path game --editor --import --quit
godot --headless --path game --script res://tests/run_tests.gd
godot --headless --path game --quit-after 120
```

All three XDG directories are required in the restricted Linux environment; use a separate test-data directory to avoid touching personal saves. Import first on clean checkouts. Check logs for `SCRIPT ERROR` / `ERROR` as well as exit codes. On 2026-10-13 the implementation verification reported import and startup smoke without errors, 476 engine checks with 0 failures, and successful validation of 11 prologue nodes. The same import, 476 checks, and startup smoke also passed from a clean copy without a `.godot` cache. This is foundation coverage, not full-game acceptance; core graphical QA passed for opening interaction, 1280×720/640×360 layouts, menus, journal scrolling, and independent-process F5/F9 checks; full manual prologue/battle and export remain separate gates. See `game/README.md` and the development plan for scope and latest evidence.

Existing design checks, from repository root:

```sh
python tools/balance/audit_v3.py --design-dir docs/design/v3 --out-dir docs/reviews/v3_numeric_data
python tools/balance/verify_combat_rules.py --design-dir docs/design/v3 --out-dir docs/reviews/v3_numeric_data
```

The design checks update their output files; review generated differences. They are not a substitute for engine import, visual QA, battle playthroughs, or exported-build testing. Re-run affected checks after final edits. Report passed, failed, blocked, and not-run separately, and update the development plan with concrete evidence. A foundation or partial prologue is not the complete game; planned content and asset quotas are not completed work.
