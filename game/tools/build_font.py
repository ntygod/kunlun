#!/usr/bin/env python3
"""Build a renamed OFL Chinese UI subset from Noto Sans CJK SC (face 2).
Optional build-time dependency: fonttools. Runtime has no Python dependency.
"""
from pathlib import Path
import argparse
from fontTools import subset
from fontTools.ttLib import TTFont
root = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument('--source', default='/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc')
args = parser.parse_args()
text = ''.join(p.read_text() for folder in ['scripts', 'data'] for p in (root/folder).rglob('*') if p.suffix in ['.gd','.json'])
text += ''.join(chr(i) for i in range(32,127)) + '−＋→•…〇一二三四五六七八九十'
font = TTFont(args.source, fontNumber=2, recalcTimestamp=False)
options = subset.Options()
options.name_IDs = ['*']
options.name_legacy = True
options.name_languages = ['*']
subsetter = subset.Subsetter(options=options)
subsetter.populate(text=text)
subsetter.subset(font)
for record in font['name'].names:
    if record.nameID in [1,3,4,6,16,17]:
        value = 'Kunlun UI Subset Regular' if record.nameID != 6 else 'KunlunUISubset-Regular'
        record.string = value.encode(record.getEncoding(), errors='replace')
font.save(root/'assets/fonts/kunlun_ui.ttf')
print('Built', root/'assets/fonts/kunlun_ui.ttf')
