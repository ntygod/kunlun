#!/usr/bin/env python3
"""Archive a chapter-nine candidate and run independent-XDG regression checks.

Copies only six verified local natural-play test fixtures, never user save slots.
The generated minimum fixture is built with formal 0–8 commands.
"""
import argparse,pathlib,subprocess,os,json,hashlib,re,concurrent.futures,time,shutil
parser=argparse.ArgumentParser()
parser.add_argument('--revision',required=True)
parser.add_argument('--include-chapter-ten',action='store_true',help='Also copy verified natural chapter-nine fixture for chapter-ten tests')
parser.add_argument('--evidence-root',default='/tmp')
parser.add_argument('--include-chapter-eleven',action='store_true',help='Generate formal chapter-ten command fixture and include chapter-eleven regression')
parser.add_argument('--include-chapter-twelve',action='store_true',help='Generate formal chapter-eleven command fixture and include chapter-twelve regression')
args=parser.parse_args()
if args.include_chapter_twelve: args.include_chapter_eleven=True
if args.include_chapter_eleven: args.include_chapter_ten=True
repo=pathlib.Path(__file__).resolve().parents[2]
sha=subprocess.check_output(['git','rev-parse','--verify',args.revision+'^{commit}'],cwd=repo,text=True).strip()
stamp=sha[:8]; evidence=pathlib.Path(args.evidence_root);evidence.mkdir(parents=True,exist_ok=True)
dest=evidence/('kunlun-nine-clean-'+stamp);out=evidence/('kunlun-nine-clean-logs-'+stamp)
if dest.exists() or out.exists():raise RuntimeError('Use a fresh evidence root to avoid reusing test data')
dest.mkdir();out.mkdir()
archive=subprocess.Popen(['git','archive',sha],cwd=repo,stdout=subprocess.PIPE);subprocess.run(['tar','-x','-C',str(dest)],stdin=archive.stdout,check=True);archive.stdout.close();archive_code=archive.wait()
if archive_code!=0:raise RuntimeError("archive failed")
manifest={}
fixtures=['chapter_three_gui','chapter_four_gui_v2','chapter_five_gui','chapter_six_gui','chapter_seven_gui','chapter_eight_gui']
if args.include_chapter_ten: fixtures.append('chapter_nine_gui')
for filename in fixtures:
 rel=pathlib.Path('output/cache')/filename/'manual_natural_final.json';src=repo/rel;target=dest/rel;target.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(src,target);manifest[str(rel)]={'size':src.stat().st_size,'sha256':hashlib.sha256(src.read_bytes()).hexdigest()}
 if src.read_bytes()!=target.read_bytes():raise RuntimeError("fixture copy mismatch")
(out/'fixture_manifest.json').write_text(json.dumps(manifest,indent=2))
def env(name):
 e=os.environ.copy();base=out/'xdg'/name
 for kind in ['CACHE','DATA','CONFIG']:
  p=base/kind.lower();p.mkdir(parents=True,exist_ok=True);e['XDG_'+kind+'_HOME']=str(p)
 return e
def counts(text):
 checks=[];failures=[]
 for line in text.splitlines():
  pair=re.search(r"checks\s*:?\s*(\d+)\s*;?\s*failures\s*:?\s*(\d+)",line)
  if pair:
   checks.append(int(pair[1]));failures.append(int(pair[2]));continue
  pair=re.search(r"(\d+)\s+checks[, /]+\s*(\d+)\s+failures",line)
  if pair:checks.append(int(pair[1]));failures.append(int(pair[2]))
 return checks,failures

def run(name,args,extra=None):
 e=env(name);e.update(extra or {});t=time.time();p=subprocess.run(args,cwd=dest,env=e,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,timeout=3600);(out/(name+'.log')).write_text(p.stdout);errors=bool(re.search(r'(^|\n)(?:SCRIPT )?ERROR:|WARNING:|leaked',p.stdout));r={'name':name,'code':p.returncode,'seconds':round(time.time()-t,2),'errors':errors,'check_counts':counts(p.stdout)[0],'failure_counts':counts(p.stdout)[1]};print(json.dumps(r),flush=True);return r
results=[]
results.append(run('import',['godot','--headless','--path','game','--editor','--import','--quit']))
results.append(run('validate',['python','game/tools/validate_data.py']))
results.append(run('minimum_seed',['godot','--headless','--path','game','--script','res://tests/chapter_nine_minimum_source.gd']))
seed=out/'xdg/minimum_seed/data/godot/app_userdata/昆仑 · 钓鱼烽火（开发版）/chapter_nine_minimum_source.json'
if not seed.exists():raise RuntimeError('actual source generation failed')
chapter11_source=None
if args.include_chapter_eleven:
 command_dir=out/'chapter_ten_command_fixtures'
 results.append(run('chapter_ten_command_seed',['godot','--headless','--path','game','--script','res://tests/chapter_ten_state_process_driver.gd'],{'CH10_FIXTURE_DIR':str(command_dir),'CH10_REVISION':sha}))
 chapter11_source=command_dir/'command_terminal.json'
 if not chapter11_source.exists():raise RuntimeError('formal chapter-ten source generation failed')
 (out/'chapter11_source_manifest.json').write_text(json.dumps({'path':str(chapter11_source),'sha256':hashlib.sha256(chapter11_source.read_bytes()).hexdigest(),'provenance':'Formal commands from original chapter-nine natural save; not chapter-ten GUI'},indent=2))
chapter12_source=None
if args.include_chapter_twelve:
 chapter12_source=out/'chapter_eleven_command_terminal.json'
 results.append(run('chapter_eleven_command_seed',['godot','--headless','--path','game','--script','res://tests/chapter_twelve_source_driver.gd'],{'CH11_SOURCE':str(chapter11_source),'CH12_SOURCE_OUTPUT':str(chapter12_source)}))
 if not chapter12_source.exists():raise RuntimeError('formal chapter-eleven source generation failed')
 (out/'chapter12_source_manifest.json').write_text(json.dumps({'path':str(chapter12_source),'sha256':hashlib.sha256(chapter12_source.read_bytes()).hexdigest(),'provenance':'Formal chapter-ten and eleven commands from original chapter-nine natural save; not chapter-eleven GUI'},indent=2))
def test(path):
 name=path.stem;e=env(name);target=pathlib.Path(e['XDG_DATA_HOME'])/'godot/app_userdata/昆仑 · 钓鱼烽火（开发版）/chapter_nine_minimum_source.json';target.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(seed,target);extra={'CH09_MIN_SOURCE':str(target)}
 if chapter11_source:extra['CH11_SOURCE']=str(chapter11_source)
 if chapter12_source:extra['CH12_SOURCE']=str(chapter12_source)
 if name=='test_chapter_seven_world_process':
  wr=run(name+'_write',['godot','--headless','--path','game','--script','res://tests/'+path.name,'--','--write'],{**e,**extra});results.append(wr)
 return run(name,['godot','--headless','--path','game','--script','res://tests/'+path.name],extra)
paths=sorted((dest/'game/tests').glob('test*.gd'))+[dest/'game/tests/run_tests.gd']
with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
 for r in pool.map(test,paths):results.append(r);(out/'results.partial.json').write_text(json.dumps(results,indent=2))
if args.include_chapter_eleven:
 for script,variable in [('test_chapter_ten_navigation_process.gd','CH10_NAV_MODE'),('test_chapter_ten_hidden_friends.gd','CH10_FRIENDS_MODE')]:
  shared=env(script+'_process')
  for mode in ['writer','reader']:results.append(run(script+'_'+mode,['godot','--headless','--path','game','--script','res://tests/'+script],{**shared,variable:mode}))
 shared=env('chapter_eleven_puzzles_process')
 for mode in ['write','read']:results.append(run('chapter_eleven_puzzles_'+mode,['godot','--headless','--path','game','--script','res://tests/chapter_eleven_puzzles_process_driver.gd','--',mode],shared))
if args.include_chapter_twelve:
 shared=env('chapter_twelve_puzzles_process')
 for mode in ['write','read']:results.append(run('chapter_twelve_puzzles_'+mode,['godot','--headless','--path','game','--script','res://tests/chapter_twelve_puzzles_process_driver.gd','--',mode],shared))
if args.include_chapter_twelve:
 shared=env('chapter_twelve_battle_process')
 for mode in ['write','read']:results.append(run('chapter_twelve_battle_'+mode,['godot','--headless','--path','game','--script','res://tests/chapter_twelve_battle_process_driver.gd','--',mode],{**shared,'CH12_SOURCE':str(chapter12_source)}))
results.append(run('startup',['godot','--headless','--path','game','--quit-after','120']))
(out/'results.json').write_text(json.dumps(results,indent=2));print('FINAL',len(results),'runs',sum(sum(r['check_counts']) for r in results),'checks','FAILED',[r['name'] for r in results if r['code'] or r['errors'] or any(r['failure_counts'])],flush=True)
