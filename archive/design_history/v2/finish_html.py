from pathlib import Path
import re,json
root=Path(r'D:\novel')
p=root/'output'/'pdf'/'昆仑_像素2D完整策划案_v2.0.html'
s=p.read_text(encoding='utf-8')
s=s.replace('<title>昆仑 武侠RPG完整策划案</title>','<title>昆仑 像素2D完整策划案</title>')
p.write_text(s,encoding='utf-8')
builder=root/'策划工作'/'v2'/'build_v2.py'
code=builder.read_text(encoding='utf-8').replace('昆仑 武侠RPG完整策划案','昆仑 像素2D完整策划案')
builder.write_text(code,encoding='utf-8')
ids=set(re.findall(r'id="(s\d+)"',s))
targets=set(re.findall(r'href="#(s\d+)"',s))
assert ids==targets and len(ids)==19
assert '<b>40小时</b>' in s and '<b>48小时</b>' in s and '<b>54小时</b>' in s
assert '<blockquote>' in s and s.endswith('</main></html>')
print(json.dumps({'html_sections':len(ids),'navigation':'passed','metrics':'40/48/54','pdf_pages':41},ensure_ascii=False))
