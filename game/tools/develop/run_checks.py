#!/usr/bin/env python3
"""Reproducible develop integration verification with isolated saves and raw logs."""
from __future__ import annotations
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import time

ROOT = Path(__file__).resolve().parents[3]
DIAGNOSTIC = re.compile(r'(?m)^\s*(?:SCRIPT ERROR|ERROR|WARNING):')
ANSI = re.compile(r'\x1b\[[0-9;]*m')

def main() -> int:
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--godot',required=True)
    parser.add_argument('--output',type=Path,required=True)
    parser.add_argument('--native',action='store_true')
    args=parser.parse_args()
    output=args.output.resolve(); output.mkdir(parents=True,exist_ok=True)
    fixtures=output/'fixtures';fixtures.mkdir(exist_ok=True)
    process_dir=output/'process';process_dir.mkdir(exist_ok=True)
    logs=output/'logs';logs.mkdir(exist_ok=True)
    godot=str(Path(args.godot).resolve())
    env=dict(os.environ,GODOT_SILENCE_ROOT_WARNING='1',KUNLUN_FIXTURE_DIR=str(fixtures),
             CH14_SOURCE=str(fixtures/'chapter_13_minimum.json'),CH15_SOURCE=str(fixtures/'chapter_14_minimum.json'),
             CH16_SOURCE=str(fixtures/'chapter_15_minimum.json'),CH16_PROCESS_DIR=str(process_dir),
             CH17_SOURCE=str(fixtures/'chapter_16_minimum.json'),CH17_PROCESS_DIR=str(output/'process17'))
    results=[]
    def run(name: str, command: list[str], extra: dict|None=None, native: bool=False, timeout: int=240) -> bool:
        case_env=env|dict(extra or {})
        for key,folder in [('XDG_DATA_HOME','data'),('XDG_CONFIG_HOME','config'),('XDG_CACHE_HOME','cache')]:
            path=output/'isolated'/name/folder;path.mkdir(parents=True,exist_ok=True);case_env[key]=str(path)
        started=time.monotonic()
        try:
            completed=subprocess.run(command,cwd=ROOT,env=case_env,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,timeout=timeout)
            text=completed.stdout;code=completed.returncode
        except subprocess.TimeoutExpired as exc:
            text=(exc.stdout or b'').decode(errors='replace') if isinstance(exc.stdout,bytes) else (exc.stdout or '')
            text+='\nERROR: subprocess timeout\n';code=124
        clean=ANSI.sub('',text)
        known=[]
        if native:
            warning='WARNING: Could not set V-Sync mode, as changing V-Sync mode is not supported by the graphics driver.'
            if warning in clean:known.append(warning);clean=clean.replace(warning,'ENVIRONMENT WARNING (recorded): VSync unavailable in Xvfb/Mesa')
        failures=bool(code or DIAGNOSTIC.search(clean))
        path=logs/(name+'.log');path.write_text(text,encoding='utf-8')
        summaries=[line for line in clean.splitlines() if re.search(r'\d+ (?:checks|failures)|checks:|checks=',line,re.I)]
        row={'name':name,'status':'failed' if failures else 'passed','exit_code':code,'seconds':round(time.monotonic()-started,3),
             'command':command,'log':str(path.relative_to(output)),'log_sha256':hashlib.sha256(path.read_bytes()).hexdigest(),
             'test_summaries':summaries,'environment_warnings':known}
        results.append(row)
        (output/'summary.json').write_text(json.dumps({'runs':results,'scope':'model/headless + optional native render; not natural chapter GUI or release QA'},ensure_ascii=False,indent=2)+'\n')
        print(f'{name}: {row["status"]} exit={code}',flush=True)
        if failures:print(clean[-14000:],flush=True)
        return not failures
    def engine(script: str) -> list[str]:
        return [godot,'--headless','--path','game','--script','res://tests/'+script+'.gd']
    if not run('data-existing',[sys.executable,'game/tools/validate_data.py']):return 1
    if not run('data-ch16',[sys.executable,'game/tools/validate_chapter_sixteen.py']):return 1
    if not run('data-ch17',[sys.executable,'game/tools/validate_chapter_seventeen.py']):return 1
    if not run('import',[godot,'--headless','--path','game','--editor','--import','--quit']):return 1
    if not run('source-model-0-15',engine('prepare_develop_source'),timeout=300):return 1
    scripts=['run_tests','test_combat','test_battle_panel','test_battle_panel_usability','test_ink_ui','test_ink_battle_layout',
             'test_chapter_fourteen_combat','test_chapter_fourteen_guard','test_chapter_fourteen_guard_loadout','test_chapter_fourteen_captured_child',
             'test_chapter_fifteen_combat','test_chapter_fifteen_transactions','test_chapter_fifteen_internal_panels','test_chapter_fifteen_puzzles',
             'test_chapter_sixteen_puzzles','test_chapter_sixteen_combat','test_chapter_sixteen_boundaries','test_chapter_sixteen','test_chapter_sixteen_main']
    for script in scripts:run(script,engine(script))
    for mode in ['write','read']:run('ch16-process-'+mode,engine('chapter_sixteen_save_process'),{'CH16_PROCESS_MODE':mode})
    if not run('source-model-16',engine('prepare_chapter_seventeen_source'),timeout=300):return 1
    for script in ['test_chapter_seventeen_puzzles','test_chapter_seventeen_combat','test_chapter_seventeen_boundaries','test_chapter_seventeen','test_chapter_seventeen_optional','test_chapter_seventeen_main']:
        run(script,engine(script),timeout=300)
    for mode in ['write','read']:run('ch17-process-'+mode,engine('chapter_seventeen_save_process'),{'CH17_PROCESS_MODE':mode},timeout=300)
    run('startup',[godot,'--headless','--path','game','--quit-after','120'])
    if args.native:
        screenshots=output/'screenshots';screenshots.mkdir(exist_ok=True)
        run('native-ch16',['xvfb-run','-a','-s','-screen 0 1366x768x24',godot,'--path','game','--audio-driver','Dummy','--rendering-method','gl_compatibility','--script','res://tests/test_chapter_sixteen_main.gd'],{'KUNLUN_CH16_CAPTURE':str(screenshots/'chapter16')},native=True)
        run('native-ch17',['xvfb-run','-a','-s','-screen 0 1366x768x24',godot,'--path','game','--audio-driver','Dummy','--rendering-method','gl_compatibility','--script','res://tests/test_chapter_seventeen_main.gd'],{'KUNLUN_CH17_CAPTURE':str(screenshots/'chapter17')},native=True,timeout=300)
    hashes={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in fixtures.glob('*.json')}
    (output/'fixture-hashes.json').write_text(json.dumps({'source':'generated through actual model inputs, not natural GUI','sha256':hashes},indent=2)+'\n')
    failed=sum(r['status']=='failed' for r in results)
    print(f'{len(results)} executions, {failed} failed. Historical natural fixtures / complete OS gameplay / export are NOT RUN.',flush=True)
    return int(failed>0)

if __name__=='__main__':raise SystemExit(main())
