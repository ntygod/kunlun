"""Read-only numerical checks for the supplied v3 design tables."""
from pathlib import Path
from decimal import Decimal, ROUND_FLOOR
import argparse, csv, json, re, sys

def clean(s):
    return s.replace('**','').replace('`','').strip()

COEFF={
 '梁萧':{'HP':[150,38,.45],'MP':[45,3.8,0],'ATK':[24,5.6,.06],'DEF':[14,3.4,.04],'SPD':[14,1.25,0]},
 '花晓霜':{'HP':[125,30,.35],'MP':[55,4.5,0],'ATK':[18,4.2,.04],'DEF':[12,3,.03],'SPD':[13,1.15,0]},
 '柳莺莺':{'HP':[135,33,.38],'MP':[40,3.4,0],'ATK':[23,5.3,.055],'DEF':[11,2.8,.03],'SPD':[17,1.55,0]},
 '花生':{'HP':[190,52,.65],'MP':[35,2.8,0],'ATK':[26,5.8,.06],'DEF':[18,4.6,.055],'SPD':[10,.85,0]},
}
def stats(name,level,cap=40):
    x=Decimal(level-1)*Decimal(39)/Decimal(cap-1)
    return {k:int((Decimal(str(a))+Decimal(str(b))*x+Decimal(str(c))*x*x).to_integral_value(rounding=ROUND_FLOOR)) for k,(a,b,c) in COEFF[name].items()}

def write_csv(path,rows,fields):
    with path.open('w',encoding='utf-8-sig',newline='') as f:
        w=csv.DictWriter(f,fieldnames=fields);w.writeheader();w.writerows(rows)

def tables(path, id_pattern):
    rows={}
    for n,line in enumerate(path.read_text(encoding='utf-8').splitlines(),1):
        if not line.startswith('|'):continue
        cells=[clean(c) for c in line.strip('|').split('|')]
        if cells and re.fullmatch(id_pattern,cells[0]):
            rows[cells[0]]={'line':n,'cells':cells}
    return rows

def damage(atk,mult,defense,state=1,k=100):
    return max(1,int(atk*mult*k/(k+defense)*state))

def main():
    sys.stdout.reconfigure(encoding='utf-8')
    ap=argparse.ArgumentParser();ap.add_argument('--design-dir',type=Path,required=True);ap.add_argument('--out-dir',type=Path,required=True)
    a=ap.parse_args();a.out_dir.mkdir(parents=True,exist_ok=True)
    numeric=next(a.design_dir.glob('07_*.md')); text=numeric.read_text(encoding='utf-8');lines=text.splitlines()
    cap_match=re.search(r'\*\*等级上限\*\*：\s*\*\*(\d+)级',text)
    if not cap_match or int(cap_match.group(1)) not in (40,80):
        raise ValueError('Expected an explicit level cap of 40 or 80 in the design.')
    source_cap=int(cap_match.group(1))
    errors=[]; milestones=[]; skills={}; boss_refs=[]; current_boss=None
    curve_levels=[]; boss_recommendations={}; level_errors=[]; xp_errors=[]
    raw_healing_levels=[]
    for n,line in enumerate(lines,1):
        if line.startswith('### 5.2'):current_boss=None
        m=re.match(r'^### (B\d{2})[：:]',line)
        if m:current_boss=m.group(1)
        if current_boss:
            for ref in re.findall(r'\b(?:LX|HXS|LYY|HS)_A\d{2}\b|\bLX_P\d{2}\b|\bCO_\d{2}\b',line):boss_refs.append({'boss':current_boss,'line':n,'ref':ref})
            if line.startswith('- **推荐等级**'):
                level_match=re.search(r'Lv\.(\d+)(?:[～~](\d+))?',line)
                if level_match:boss_recommendations[current_boss]=[int(l) for l in level_match.groups() if l]
        if source_cap==80 and re.search(r'×\s*(?:角色)?等级(?:[⌋)\s]|$)',line):raw_healing_levels.append(n)
        if '关键节点累计XP' in line:
            for level,value in re.findall(r'Lv\.(\d+):\s*([\d,]+)',line):
                l=int(level);expected=100*(l-1)+15*(l-1)*(l-2)//2
                if int(value.replace(',',''))!=expected:xp_errors.append({'line':n,'level':l,'given':value,'formula':expected})
        if not line.startswith('|'):continue
        cells=[clean(c) for c in line.strip('|').split('|')]
        if len(cells)==8 and cells[2] in COEFF:
            m=re.search(r'Lv\.(\d+)',cells[0])
            if not m:continue
            level=int(m.group(1)); truth=stats(cells[2],level,source_cap)
            row={'line':n,'character':cells[2],'level':level}
            for stat,cell in zip(['HP','MP','ATK','DEF','SPD'],cells[3:]):
                v=re.match(r'(\d+)',cell)
                if v:
                    given=int(v.group(1));row[stat]=given
                    if given!=truth[stat]:errors.append({'line':n,'table':'milestone','character':cells[2],'level':level,'stat':stat,'given':given,'formula':truth[stat]})
                equip=re.search(r'\(\+(\d+)=(\d+)\)',cell.replace(' ',''))
                if equip and v and int(v.group(1))+int(equip.group(1))!=int(equip.group(2)):
                    errors.append({'line':n,'table':'equipment_sum','character':cells[2],'level':level,'stat':stat,'given':int(equip.group(2)),'formula':int(v.group(1))+int(equip.group(1))})
            milestones.append(row)
        if len(cells)==24 and cells[0].isdigit():
            for p in range(0,24,6):
                if not cells[p].isdigit():continue
                level=int(cells[p]);truth=stats('梁萧',level,source_cap);curve_levels.append(level)
                for stat,cell in zip(['HP','MP','ATK','DEF','SPD'],cells[p+1:p+6]):
                    if cell.isdigit() and int(cell)!=truth[stat]:errors.append({'line':n,'table':'level_curve','character':'梁萧','level':level,'stat':stat,'given':int(cell),'formula':truth[stat]})
        if cells and re.fullmatch(r'(?:LX|HXS|LYY|HS)_A\d{2}',cells[0]):
            chapters=[int(x) for x in re.findall(r'第(\d+)章',cells[3])]
            skills[cells[0]]={'id':cells[0],'line':n,'name':cells[1],'unlock_chapter':min(chapters) if chapters else None,'mp':cells[4],'cd':cells[5],'speed':cells[6],'effects':cells[-1]}
    boss_chapters={'B01':3,'B02':5,'B03':5,'B04':7,'B05':8,'B06':10,'B07':11,'B08':12,'B09':12,'B10':13,'B11':14,'B12':15,'B13':17,'B14':18,'B15':19,'B16':20}
    refs=[]
    for row in boss_refs:
        skill=skills.get(row['ref'])
        if skill and skill['unlock_chapter'] is not None and skill['unlock_chapter']>boss_chapters[row['boss']]:
            refs.append({**row,'boss_chapter':boss_chapters[row['boss']],'unlock_chapter':skill['unlock_chapter']})
    growth=[]
    for cap in [40,80]:
        for name in COEFF:
            for l in range(1,cap+1):growth.append({'cap':cap,'character':name,'level':l,'normalized_progress':round((l-1)/(cap-1),6),**stats(name,l,cap)})
    write_csv(a.out_dir/'normalized_growth_40_80.csv',growth,['cap','character','level','normalized_progress','HP','MP','ATK','DEF','SPD'])
    write_csv(a.out_dir/'stat_table_mismatches.csv',errors,['line','table','character','level','stat','given','formula'])
    write_csv(a.out_dir/'future_skill_references.csv',refs,['boss','line','ref','boss_chapter','unlock_chapter'])
    voice=next(a.design_dir.glob('05_*.md'));art=next(a.design_dir.glob('08_*.md'))
    voice_actions=tables(voice,r'ACT-\d{2}');art_actions=tables(art,r'ACT-\d{2}')
    actions=[]
    for action_id in sorted(voice_actions.keys()|art_actions.keys()):
        v=voice_actions.get(action_id);b=art_actions.get(action_id)
        actions.append({'id':action_id,'voice_line':v['line'] if v else '',
            'voice_name':v['cells'][1] if v else '', 'voice_frames':v['cells'][3] if v else '',
            'art_line':b['line'] if b else '', 'art_name':b['cells'][1] if b else '',
            'art_frames':b['cells'][4] if b else '',
            'check':'名称不同，须人工复核语义' if v and b and v['cells'][1]!=b['cells'][1] else '匹配/缺定义'})
    write_csv(a.out_dir/'action_id_comparison.csv',actions,['id','voice_line','voice_name','voice_frames','art_line','art_name','art_frames','check'])
    maps=[]
    for map_id,row in tables(art,r'MAP-\d{2}').items():
        sizes=[(int(w),int(h)) for w,h in re.findall(r'(\d+)\s*[×x]\s*(\d+)',row['cells'][4])]
        area=sum(w*h for w,h in sizes)
        maps.append({'id':map_id,'line':row['line'],'name':row['cells'][1],
            'sizes':' + '.join(f'{w}x{h}' for w,h in sizes),'area_tiles':area,
            'group_limit_tiles':960,'ratio':round(area/960,4),'exceeds_group_limit':area>960})
    write_csv(a.out_dir/'map_area_budget.csv',maps,['id','line','name','sizes','area_tiles','group_limit_tiles','ratio','exceeds_group_limit'])
    scenes=[];documents=[]
    for path in sorted(a.design_dir.glob('0[1-8]_*.md')):
        doc_lines=path.read_text(encoding='utf-8').splitlines()
        documents.append({'file':path.name,'lines':len(doc_lines),'bytes':path.stat().st_size})
        if path.name.startswith(('02_','03_','04_')):
            for n,line in enumerate(doc_lines,1):
                if not line.startswith('### '):continue
                m=re.search(r'\bSC-\d{2}-\d{2}\b',line)
                if m:scenes.append({'id':m.group(),'file':path.name,'line':n,'title':line.lstrip('# ').strip()})
    write_csv(a.out_dir/'scene_index.csv',scenes,['id','file','line','title'])
    xp=[];total_xp=0
    for level in range(1,81):
        required=100+15*(level-1) if level<80 else 0
        xp.append({'level':level,'cumulative_xp':total_xp,'xp_to_next':required})
        total_xp+=required
    write_csv(a.out_dir/'experience_80_draft.csv',xp,['level','cumulative_xp','xp_to_next'])
    boss_levels=[]
    for n,line in enumerate(lines,1):
        if not line.startswith('|'):continue
        cells=[clean(c) for c in line.strip('|').split('|')]
        if len(cells)==8 and re.fullmatch(r'B\d{2}',cells[0]) and cells[1].isdigit():
            levels=[int(l) for l in re.findall(r'\d+',cells[3])]
            old_levels=levels if source_cap==40 else [int(Decimal(l-1)*39/79+Decimal('1.5')) for l in levels]
            mapped=levels if source_cap==80 else [int(Decimal(l-1)*79/39+Decimal('1.5')) for l in levels]
            boss_levels.append({'boss':cells[0],'chapter':int(cells[1]),'line':n,
                'level_40':'Lv.'+'~'.join(map(str,old_levels)),
                'level_80':'Lv.'+'~'.join(map(str,mapped)),'name':cells[2]})
            if boss_recommendations.get(cells[0])!=levels:
                level_errors.append({'boss':cells[0],'line':n,'detail':boss_recommendations.get(cells[0]),'overview':levels})
    write_csv(a.out_dir/'boss_levels_80_draft.csv',boss_levels,['boss','chapter','line','level_40','level_80','name'])
    late_level=int(Decimal(37)*(source_cap-1)/39+Decimal('1.5'))
    liang=stats('梁萧',late_level,source_cap);hua=stats('花生',late_level,source_cap)
    scenarios=[
        {'id':'liang_b16_baseline','assumption':f'Lv{late_level}梁萧标准装备，未计心法；敌ATK400、倍率2.0、无状态修正',
            'hp':liang['HP']+460,'defense':liang['DEF']+62,'one_hit_damage':damage(400,2,liang['DEF']+62),
            'healing_per_round':int((liang['HP']+460)*.15)},
        {'id':'liang_b16_n03','assumption':'同上，LX_N03全属性+15%；每回合桑树之约恢复15%最大HP',
            'hp':int((liang['HP']+460)*1.15),'defense':int((liang['DEF']+62)*1.15),
            'one_hit_damage':damage(400,2,int((liang['DEF']+62)*1.15)),
            'healing_per_round':int(int((liang['HP']+460)*1.15)*.15)},
        {'id':'huasheng_n03','assumption':f'Lv{late_level}花生标准装备，HS_N03 HP+40% DEF+30%；敌ATK430、倍率2.2；不计全队15%减伤',
            'hp':int((hua['HP']+600)*1.4),'defense':int((hua['DEF']+78)*1.3),
            'one_hit_damage':damage(430,2.2,int((hua['DEF']+78)*1.3)),
            'healing_per_round':int(int((hua['HP']+600)*1.4)*.08)},
        {'id':'huasheng_n03_a08','assumption':'同上再加HS_A08的60%减伤；未计A08第二级额外15%回复，也未累计AOE代受次数',
            'hp':int((hua['HP']+600)*1.4),'defense':int((hua['DEF']+78)*1.3),
            'one_hit_damage':damage(430,2.2,int((hua['DEF']+78)*1.3),.4),
            'healing_per_round':int(int((hua['HP']+600)*1.4)*.08)},
    ]
    rules_path=a.design_dir/'combat_rules.json'
    if rules_path.exists():
        rules=json.loads(rules_path.read_text(encoding='utf-8'))
        benchmark=sum(boss_recommendations['B16'])/len(boss_recommendations['B16'])
        k=rules['defense']['k_base']+rules['defense']['k_per_power_level']*39*(benchmark-1)/(source_cap-1)
        liang_hp=liang['HP']+500;liang_def=liang['DEF']+68
        hua_hp=int((hua['HP']+660)*1.4);hua_def=int((hua['DEF']+85)*1.3)
        cases=[('liang_b16_baseline','梁萧第20章标准装备、未计心法',liang_hp,liang_def,400,2,0,.15,rules['sustain']['sangshu_regen']),
               ('liang_b16_n03','梁萧第20章标准装备、LX_N03全属性+15%',int(liang_hp*1.15),int(liang_def*1.15),400,2,0,.15,rules['sustain']['sangshu_regen']),
               ('huasheng_n03','花生第20章标准装备、HS_N03 HP+40%、DEF+30%；未计队伍护体',hua_hp,hua_def,430,2.2,0,.08,rules['sustain']['huasheng_regen']),
               ('huasheng_n03_a08','花生同上、镇海印护体30%；只计自身一次受击，未计代受',hua_hp,hua_def,430,2.2,rules['guard']['aoe_extra_reduction'],.08,rules['sustain']['huasheng_regen'])]
        scenarios=[];comparison=[]
        for ident,note,hp,defense,atk,mult,dr,old_regen,regen in cases:
            hit=damage(atk,mult,defense,1-dr,k)
            old_dr=.6 if ident.endswith('a08') else 0
            scenarios.append({'id':ident,'assumption':f'Lv{late_level}；关卡基准Lv{benchmark:g}；敌ATK{atk}×{mult}；'+note,
                'hp':hp,'defense':defense,'defense_k':round(k,6),'one_hit_damage':hit,'healing_per_round':int(hp*regen)})
            comparison.append({'id':ident,'same_panel_hp':hp,'same_panel_def':defense,'old_damage_k100':damage(atk,mult,defense,1-old_dr),
                'new_damage':hit,'old_passive_heal':int(hp*old_regen),'new_passive_heal':int(hp*regen)})
        redirected=damage(430,2.2*rules['guard']['aoe_share'],hua_def,1-rules['guard']['aoe_extra_reduction'],k)
        own=damage(430,2.2,hua_def,1-rules['guard']['aoe_extra_reduction'],k)
        scenarios.append({'id':'huasheng_a08_four_target_aoe','assumption':'同上；四人均受到ATK430×2.2的AOE，花生自身一包+三名同伴各50%原始包；无药香、无降攻',
            'hp':hua_hp,'defense':hua_def,'defense_k':round(k,6),'one_hit_damage':own+3*redirected,'healing_per_round':int(hua_hp*rules['sustain']['huasheng_regen'])})
        write_csv(a.out_dir/'combat_pressure_comparison.csv',comparison,['id','same_panel_hp','same_panel_def','old_damage_k100','new_damage','old_passive_heal','new_passive_heal'])
    write_csv(a.out_dir/'combat_pressure_examples.csv',scenarios,['id','assumption','hp','defense','defense_k','one_hit_damage','healing_per_round'])
    (a.out_dir/'skills_extracted.json').write_text(json.dumps(skills,ensure_ascii=False,indent=2),encoding='utf-8')
    summary={'source':str(numeric),'level_cap':source_cap,'documents':documents,'scene_definitions':len(scenes),
        'active_skills':len(skills),'milestone_rows':len(milestones),'stat_mismatches':errors,
        'level_curve_rows':len(curve_levels),'level_curve_complete':sorted(curve_levels)==list(range(1,source_cap+1)),
        'boss_level_mismatches':level_errors,'xp_milestone_mismatches':xp_errors,
        'raw_level_healing_formula_lines':raw_healing_levels,
        'future_skill_references':refs,'action_ids_compared':len(actions),
        'action_name_differences_require_manual_review':sum(r['voice_name']!=r['art_name'] for r in actions),
        'map_groups':len(maps),'map_groups_over_limit':sum(r['exceeds_group_limit'] for r in maps),
        'map_total_area_tiles':sum(r['area_tiles'] for r in maps),
        'b16_named_unit_hp_sum':6500+4*2600+8800+5000+9200+2*3800,
        'normalized_mapping':'x=39*(level-1)/(level_cap-1)',
        'unadjusted_level80_liang':stats('梁萧',80,40),'normalized_level80_liang':stats('梁萧',80,80),
        'xp80_draft_full_clear_budget':55000,'xp80_draft_required_for_cap':total_xp,
        'xp80_draft_required_path_budget':49500,
        'xp80_draft_required_path_level':max(r['level'] for r in xp if r['cumulative_xp']<=49500)}
    (a.out_dir/'audit_summary.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2),encoding='utf-8')
    print(json.dumps({k:v for k,v in summary.items() if k not in ('documents','stat_mismatches','future_skill_references')},ensure_ascii=False))

if __name__=='__main__':main()
