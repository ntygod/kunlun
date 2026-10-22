#!/usr/bin/env python3
"""Run actual Godot checks with isolated user data, retain logs, reject diagnostics.
This script does not rewrite sources or manufacture a game/GUI acceptance result.
"""
from __future__ import annotations
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import time

ROOT = Path(__file__).resolve().parents[2]
REPO = ROOT.parent
ANSI = re.compile(r"\x1b\[[0-9;]*m")
DIAGNOSTICS = re.compile(r"(?m)^\s*(?:SCRIPT ERROR|ERROR|WARNING):")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--godot", required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--capture", action="store_true")
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    records: list[dict] = []

    def run(name: str, command: list[str], data_root: Path, timeout: int = 180) -> bool:
        env = dict(os.environ)
        for variable, directory in [("XDG_DATA_HOME", "data"), ("XDG_CACHE_HOME", "cache"), ("XDG_CONFIG_HOME", "config")]:
            folder = data_root / name / directory
            folder.mkdir(parents=True, exist_ok=True)
            env[variable] = str(folder)
        env["KUNLUN_UI_CAPTURE"] = str((args.output / "screenshots").resolve())
        env["LIBGL_ALWAYS_SOFTWARE"] = "1"
        start = time.monotonic()
        try:
            result = subprocess.run(command, cwd=REPO, env=env, capture_output=True, text=True, errors="replace", timeout=timeout)
            text = result.stdout + result.stderr
            code = result.returncode
        except subprocess.TimeoutExpired as error:
            text = str(error.stdout) + str(error.stderr) + "\nTIMEOUT\n"
            code = 124
        cleaned = ANSI.sub("", text)
        log = args.output / (name + ".log")
        log.write_text(text, encoding="utf-8")
        ok = code == 0 and DIAGNOSTICS.search(cleaned) is None
        records.append({"name": name, "passed": ok, "exit": code, "seconds": round(time.monotonic()-start, 2), "log": log.name, "sha256": hashlib.sha256(text.encode()).hexdigest()})
        print(f"{name}: {'PASS' if ok else 'FAIL'} exit={code}", flush=True)
        if args.capture or not ok:
            print(cleaned, flush=True)
        else:
            for line in cleaned.splitlines():
                if re.search(r"checks|failures|passed|validation", line, re.I): print(line)
        return ok

    with tempfile.TemporaryDirectory(prefix="kunlun-ink-ui-") as temporary:
        data_root = Path(temporary)
        if args.capture:
            run("native-capture", ["xvfb-run", "-a", "--server-args=-screen 0 1440x900x24", args.godot, "--path", "game", "--rendering-method", "gl_compatibility", "--audio-driver", "Dummy", "--script", "res://tests/capture_ink_ui.gd"], data_root)
        else:
            run("data-validation", [sys.executable, "game/tools/validate_data.py"], data_root)
            imported = run("import", [args.godot, "--headless", "--path", "game", "--editor", "--import", "--quit"], data_root)
            if imported:
                (args.output / "import-ok").write_text("Godot import completed without diagnostics\n")
                selected = {"run_tests.gd", "test_combat.gd", "test_battle_panel.gd", "test_battle_panel_usability.gd", "test_chapter_main.gd", "test_chapter_world.gd", "test_ink_ui.gd"}
                for path in (ROOT / "tests").glob("test_*.gd"):
                    if any(token in path.stem for token in ("_main", "_panel", "_layout", "_focus", "_ui")) and not any(token in path.stem for token in ("reader", "writer", "fixture")):
                        if "extends SceneTree" in path.read_text(encoding="utf-8"):
                            selected.add(path.name)
                for filename in sorted(selected):
                    if not (ROOT / "tests" / filename).exists():
                        records.append({"name": filename, "passed": False, "reason": "missing selected test"})
                        continue
                    run(Path(filename).stem, [args.godot, "--headless", "--path", "game", "--script", "res://tests/"+filename], data_root)
                run("startup", [args.godot, "--headless", "--path", "game", "--quit-after", "120"], data_root)
    report = {"commit": os.environ.get("GITHUB_SHA", "local-uncommitted"), "mode": "native-render-harness" if args.capture else "headless-regressions", "results": records, "not_run": ["natural full-campaign route", "all tactical configurations", "release export", "final pixel art and audio"]}
    filename = "native-summary.json" if args.capture else "regression-summary.json"
    (args.output / filename).write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
    failed = sum(not item["passed"] for item in records)
    print(f"{len(records)} executions, {failed} failed. Scope: {report['mode']}")
    return 1 if failed else 0

if __name__ == "__main__":
    raise SystemExit(main())
