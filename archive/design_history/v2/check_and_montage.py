from pathlib import Path
from PIL import Image, ImageOps, ImageDraw
from pypdf import PdfReader
import re,json

root=Path(r'D:\novel\策划工作\v2')
s=(root/'正文_v2.0.md').read_text(encoding='utf-8')
chapter=s.split('## 04 ',1)[1].split('## 05 ',1)[0]
rows=[x.split('|') for x in chapter.splitlines() if re.match(r'^\| (序|\d\d) \|',x)]
hours=sum(float(x[3].strip()) for x in rows)
assert len(rows)==21 and hours==40
assert len(re.findall(r'^\| [RLK]\d\d \|',s,re.M))==16
assert len(re.findall(r'^\| B\d\d \|',s,re.M))==16
pdf=Path(r'D:\novel\output\pdf\昆仑_像素2D完整策划案_v2.0.pdf')
r=PdfReader(pdf);texts=[p.extract_text() or '' for p in r.pages]
assert len(texts)==41 and all(t.strip() for t in texts)
assert all('\ufffd' not in t for t in texts)
alltext='\n'.join(texts)
for value in ['929.52','243','华山故居故事样章','自守','天道14','人物塑造']:
    assert value in alltext,value
assert 'v1.0' not in alltext
pages=sorted((root/'预览').glob('page-*.png'))
assert len(pages)==41
for n in range(0,len(pages),6):
    canvas=Image.new('RGB',(1380,1320),'#cccccc');draw=ImageDraw.Draw(canvas)
    for j,f in enumerate(pages[n:n+6]):
        im=Image.open(f);x=(j%3)*460;y=(j//3)*660
        canvas.paste(ImageOps.contain(im,(445,628)),(x,y+25))
        draw.text((x+6,y+6),f.stem,fill='black')
    canvas.save(root/'预览'/('sheet-%02d.png'%(n//6+1)))
print(json.dumps({'pages':len(texts),'main_hours':hours,'chapters':len(rows),'side_quests':16,'boss_units':16,'budget_wan':round((243*2.2+240)*1.2,2),'indexed_original_chapters':86,'checks':'passed'},ensure_ascii=False))
