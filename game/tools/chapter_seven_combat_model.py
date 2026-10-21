"""Independent arithmetic/state model. No production imports and no invented skills.
Input is emitted by chapter_seven_minimum_source.gd after real 0–6 replay/validation.
This is a lower-bound strategy witness, not engine/UI acceptance.
"""
import json, math, sys
K=100+4*39*30/79
COEF={'max_hp':(150,38,.45),'max_mp':(45,3.8,0),'atk':(24,5.6,.06),'def':(14,3.4,.04),'spd':(14,1.25,0)}
def panel(xp,gear):
    level=max(n for n in range(1,81) if 100*(n-1)+15*(n-1)*(n-2)//2<=xp)
    x=39*(level-1)/79
    return dict({k:math.floor(a+b*x+c*x*x)+gear.get(k,0) for k,(a,b,c) in COEF.items()},level=level)
def damage(atk,mult,defense,reduce=0):return max(1,math.floor(atk*mult*K/(K+defense)*(1-reduce)))
def run(source,at_b04):
    hero=source['actors']['char_liang_xiao']; snow=source['actors']['char_axue']
    p=panel(source['xp']+(900 if at_b04 else 0),hero['equipment'])
    # Required explicit rest, worst three first errors; subsequent XP adds max-HP difference.
    hp=p['max_hp']-90; ahp=snow['max_hp']; boss=2100; trace=[]; round=1
    atk=math.floor(p['atk']*1.08) if hero.get('internal_skill')=='LX_N01' else p['atk']
    while boss>1400:
        boss=max(1,boss-damage(atk,1,75))
        hit=(damage(130,1.4,p['def']) if round%6 in (2,4) else damage(130,1.85,p['def']) if round%6==0 and boss>1400 else 0)
        hp-=hit;trace.append(dict(phase=1,round=round,action='normal_attack',hero=hp,boss=boss,damage=hit));round+=1
    for action in ('free_axue','handoff_haiya'):
        hit=damage(130,1.4,p['def']) if round%6 in (2,4) else 0
        hp-=hit;trace.append(dict(phase=1,round=round,action=action,hero=hp,boss=boss,damage=hit));round+=1
    for r in range(1,7):
        hit=damage(145,1,p['def']) if r in (2,6) else damage(130,1.4,p['def']) if r==4 else 0
        ahit=damage(145,1,40) if r in (2,6) else damage(130,1.4,40) if r==4 else 0
        hp-=hit;ahp-=ahit
        trace.append(dict(phase=2,round=r,action=('calibrate' if r%2 else 'fire'),hero=hp,axue=ahp,damage=hit))
    return dict(panel=p,n01=hero.get('internal_skill')=='LX_N01',trace=trace,hero_end=hp,axue_end=ahp,success=all(t['hero']>0 and t.get('axue',1)>0 for t in trace))
if __name__=='__main__':
    src=json.load(open(sys.argv[1])); assert src['xp']==9525 and src['coins']==0
    for actual in (False,True):
        out=run(src,actual);print(json.dumps(dict(actual_b04_xp=actual,**out),ensure_ascii=False))
