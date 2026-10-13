"""Bounded design-contract checks; this is not the game's battle engine."""
from copy import deepcopy
from decimal import Decimal, ROUND_CEILING
from pathlib import Path
import argparse
import json
import re
import sys

from audit_v3 import clean, tables, write_csv


def cumulative_xp(level):
    return 100 * (level - 1) + 15 * (level - 1) * (level - 2) // 2


def branch_damage(raw, defense, reduction, k):
    if raw <= 0:
        return 0
    return max(1, int(raw * k / (k + max(0, defense)) * (1 - reduction)))


def mp_cost(skill, maximum, discount=0):
    base = max(Decimal(skill['mp_floor']), Decimal(maximum) * Decimal(str(skill['mp_percent'])))
    return int((base * (1 - Decimal(str(min(discount, .5))))).to_integral_value(rounding=ROUND_CEILING))


class Synergy:
    """Small reference ledger for reservation and refund regression cases."""
    def __init__(self, rules, initial=0):
        self.rules, self.free, self.reserved, self.earned = rules, initial, 0, 0

    def gain(self, combo=False):
        if combo or self.earned >= self.rules['earned_per_round']:
            return
        if self.free + self.reserved < self.rules['capacity']:
            self.free += 1
            self.earned += 1

    def reserve(self):
        assert self.reserved == 0 and self.free >= self.rules['cost']
        self.free -= self.rules['cost']
        self.reserved = self.rules['cost']

    def refund(self):
        self.free += self.reserved
        self.reserved = 0

    def commit(self):
        assert self.reserved == self.rules['cost']
        self.reserved = 0


def apply_grant(state, grant):
    if grant['id'] in state['events']:
        return
    state['events'].add(grant['id'])
    state[grant['kind']].add(grant['skill'])
    state['synergy'] = max(state['synergy'], grant['min_synergy'])


def main():
    sys.stdout.reconfigure(encoding='utf-8')
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--design-dir', type=Path, required=True)
    parser.add_argument('--out-dir', type=Path, required=True)
    args = parser.parse_args()
    args.out_dir.mkdir(parents=True, exist_ok=True)
    rules = json.loads((args.design_dir / 'combat_rules.json').read_text(encoding='utf-8'))
    numeric_path = next(args.design_dir.glob('07_*.md'))
    numeric = numeric_path.read_text(encoding='utf-8')
    quests = next(args.design_dir.glob('06_*.md')).read_text(encoding='utf-8')
    checks = []

    def check(name, condition):
        checks.append({'check': name, 'passed': bool(condition)})

    # Cross-check real source tables, not just the JSON snapshot.
    active = tables(numeric_path, r'(?:LX|HXS|LYY|HS)_A\d{2}')
    limited = {}
    for line in numeric.splitlines():
        if not line.startswith('|'):
            continue
        cells = [clean(c) for c in line.strip('|').split('|')]
        if len(cells) > 1:
            match = re.search(r'\b(?:LWJ|AX|FL|YS|XQJ)_S\d{2}\b', cells[1])
            if match:
                limited[match.group()] = cells
    check('32 active and 10 limited commands registered', len(active) == 32 and len(limited) == 10 and len(rules['skills']) == 42)
    for key, spec in rules['skills'].items():
        cells = active[key]['cells'] if key in active else limited[key]
        cost, cooldown, speed = (cells[4:7] if key in active else cells[2:5])
        numbers = re.findall(r'\d+', cost)
        expected = [spec['mp_floor']] + ([int(round(spec['mp_percent'] * 100))] if '/' in cost else [])
        check(key + ' cost/CD/preparation match source',
              list(map(int, numbers)) == expected and int(cooldown) == spec['cooldown'] and ('准备' in speed) == spec['prepare'])
    check('percentage mana rounds up', mp_cost(rules['skills']['LX_A07'], 279) == 62)
    check('discount applied once after base max', mp_cost(rules['skills']['LX_A07'], 279, .8) == 31)
    check('zero cost command remains zero', mp_cost(rules['skills']['HS_A01'], 999) == 0)
    check('all 6 combos have explicit grant', {g['skill'] for g in rules['grants'] if g['skill'].startswith('CO_')} == {f'CO_{i:02}' for i in range(1, 7)})
    for g in rules['grants']:
        check(g['id'] + ' appears in quest and numeric source', g['id'] in numeric and g['id'] in quests)
        state = dict(events=set(), trial=set(), permanent=set(), synergy=0)
        checkpoint = deepcopy(state)
        apply_grant(state, g)
        first = deepcopy(state)
        apply_grant(state, g)
        check(g['id'] + ' no duplicate on skip/replay', first == state)
        state = deepcopy(checkpoint)
        apply_grant(state, g)
        check(g['id'] + ' checkpoint replay identical', first == state)
        if g['kind'] == 'trial':
            check(g['id'] + ' usable without prior victory', g['skill'] in state['trial'] and g['skill'] not in state['permanent'])
    for use in rules['grant_before_usage']:
        grant = next(g for g in rules['grants'] if g['skill'] == use['skill'])
        available = grant['when'] == 'before_battle' or (
            (grant['phase'], grant['round']) <= (use['phase'], use['round']) and grant['when'] == 'before_commands')
        check(use['skill'] + ' available at required first use', grant['battle'] == use['battle'] and available)
    check('B03 martial disable includes combo', rules['story_martial_disabled']['B03'] == ['梁萧'] and '禁用武学与合招' in numeric)

    guard = rules['guard']
    raw, k = 1000, 200
    target = branch_damage(raw * (1 - guard['share']), 100, .1, k)
    protector = branch_damage(raw * guard['share'], 300, guard['extra_reduction'], k)
    check('split raw damage before individual DEF', (target, protector) == (300, 150))
    check('zero share is zero damage', branch_damage(0, 300, .6, k) == 0)
    check('no double DEF on protector', protector != branch_damage(branch_damage(raw, 100, .1, k) * .5, 300, .25, k))
    aoe_share = guard['aoe_share']
    redirected = branch_damage(raw * aoe_share, 300, guard['aoe_extra_reduction'], k)
    own_packet = branch_damage(raw, 300, guard['aoe_extra_reduction'], k)
    check('AOE own packet once plus each ally once', redirected * 3 + own_packet == 700)
    reduction = min(rules['limits']['extra_damage_reduction'], max(.35, .2, .08))
    check('same-family damage reduction takes highest', branch_damage(1000, 0, reduction, 200) == 650)
    check('shield has recipient-based cap', min(999, int(1000 * rules['limits']['shield_max_hp'])) == 200)
    check('passive healing cannot offset arbitrary damage', min(500, int(1000 * rules['limits']['passive_heal_max_hp_per_round'])) == 30)
    check('all MP sources including 3-hit guard share cap', min(sum([4, 8, 4, 6, 2]), rules['limits']['mana_gain_per_actor_round']) == 12)
    check('multi-hit cannot multiply counters', min(3, rules['limits']['counter_per_actor_round']) == 1)

    turn = 3
    check('CD1 cast T3 ready T5', turn + 1 + rules['timing']['cooldown_ready_offset'] == 5)
    for protection, next_break in [(1, 5), (2, 6)]:
        allowed = [t for t in range(turn, turn + 4) if t > turn + protection]
        check(f'protection {protection}: no same-round or protected-round control', allowed[0] == next_break)
    check('break vulnerability ends T+1', turn + rules['timing']['break_vulnerability_extra_rounds'] == 4)
    check('preparation independent of defender low SPD', rules['timing']['preparation_before_speed'])
    check('phase does not issue another turn; revive waits', rules['timing']['phase_change_at_round_end'] and rules['timing']['revived_actor_can_act_next_round'])

    ledger = Synergy(rules['synergy'], 3)
    ledger.reserve()
    ledger.gain()
    check('reserved CP occupies full capacity', (ledger.free, ledger.reserved, ledger.earned) == (1, 2, 0))
    ledger.refund(); ledger.refund()
    check('cancel refunds exactly once', (ledger.free, ledger.reserved) == (3, 0))
    ledger.reserve(); ledger.commit(); ledger.gain(combo=True)
    check('combo does not regenerate CP', ledger.free == 1)
    ledger.gain(); ledger.gain()
    check('one earned CP shared across all sources', ledger.free == 2)
    # B12 example: two teaching loops, with the T2 CD2 skill ready at T5.
    ledger = Synergy(rules['synergy'])
    for t in range(1, 7):
        ledger.earned = 0
        if t in (3, 6):
            ledger.reserve(); ledger.commit()
        else:
            ledger.gain()
    check('B12 six-round CP loop without self refund', ledger.free == 0 and 2 + rules['skills']['HXS_A07']['cooldown'] + 1 == 5)
    # All damage channels hit the same nonlethal gate before defeat rewards.
    for channel in ['normal', 'skill', 'counter', 'dot', 'mechanism']:
        hp, lost = 50, False
        events = 0
        for hit in [70, 70]:
            if not lost:
                hp = max(1, hp - hit)
                lost = hp == 1
                events += int(lost)
        check('nonlethal ' + channel + ' stops at 1HP once', hp == 1 and events == 1)

    p = rules['progression']; chapters = p['chapter_rewards']; optional = p['optional_by_id']
    check('21 chapters and 16 optional quests', len(chapters) == 21 and len(optional) == 16)
    for field, budget in [('main_xp',35750),('puzzle_xp',8250),('encounter_xp',5500),('required_total',49500)]:
        check(field + ' total', sum(c[field] for c in chapters) == budget)
    check('full completion 55000; cap needs 54115', sum(optional.values()) == 5500 and p['full_clear_xp'] == 55000 and cumulative_xp(80) == 54115)
    paid = 0
    for c in chapters:
        paid += c['required_total']
        end = c['end_level']
        expected_line = '| '+c['quest_id']+' | '+' | '.join(str(c[key]) for key in ['main_xp','puzzle_xp','encounter_xp','required_total','cumulative_xp','end_level'])+' |'
        check(c['quest_id'] + ' XP arithmetic and source table',
              c['main_xp'] + c['puzzle_xp'] + c['encounter_xp'] == c['required_total'] and paid == c['cumulative_xp']
              and cumulative_xp(end) <= paid < cumulative_xp(end+1) and expected_line in quests)
    entries = p['boss_entry_checkpoints']
    for e in entries:
        c = chapters[e['chapter']]
        check(e['battle'] + ' XP available before fight',
              e['entry_xp'] >= cumulative_xp(e['minimum_level']) and
              e['entry_xp'] == e['previous_chapter_xp'] + e['chapter_main_paid'] + e['chapter_puzzle_paid'] + e['chapter_encounter_paid'] and
              all(e['chapter_'+kind+'_paid'] <= c[kind+'_xp'] for kind in ['main','puzzle','encounter']))
    check('B03 does not borrow post-battle puzzle XP', next(e for e in entries if e['battle']=='B03')['chapter_puzzle_paid'] == 0)
    merged = (args.design_dir/'昆仑_详细剧本与系统美术全案_v3.0.md').read_text(encoding='utf-8')
    for source in sorted(args.design_dir.glob('0[1-8]_*.md')):
        check(source.name + ' merged snapshot', merged.count(source.read_text(encoding='utf-8').strip()) == 1)

    write_csv(args.out_dir/'chapter_xp_80.csv', chapters, list(chapters[0]))
    write_csv(args.out_dir/'boss_entry_xp_80.csv', entries, list(entries[0]))
    failures = [c['check'] for c in checks if not c['passed']]
    result = {'rules_version':rules['version'], 'checks':len(checks), 'passed':len(checks)-len(failures), 'failures':failures,
              'scope':'Design tables and bounded reference scenarios only; no game-engine or full battle simulation.', 'details':checks}
    (args.out_dir/'combat_rules_verification.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print(json.dumps({k:v for k,v in result.items() if k!='details'},ensure_ascii=False))
    return bool(failures)


if __name__ == '__main__':
    raise SystemExit(main())
