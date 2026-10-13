from pathlib import Path
import re, json

base=Path(r'D:\novel\策划工作')
folder=base/'v2'
parts=['01定位与改编.md','人物塑造.md','04完整流程.md','叙事演出与样章.md','07至10玩法与操作.md','像素制作与预算.md','12技术13验证15交付.md']
sections={}
intro=''
for name in parts:
    text=(folder/name).read_text(encoding='utf-8')
    heads=list(re.finditer(r'^## (\d{2}) .+$',text,re.M))
    if name.startswith('01'):intro=text[:heads[0].start()]
    for i,m in enumerate(heads):
        n=int(m.group(1))
        assert n not in sections,n
        end=heads[i+1].start() if i+1<len(heads) else len(text)
        sections[n]=text[m.start():end].strip()
assert sorted(sections)==list(range(1,16))
body=intro+'\n\n'.join(sections[i] for i in range(1,16))+'\n\n'+(folder/'附录实施清单.md').read_text(encoding='utf-8')
(folder/'正文_v2.0.md').write_text(body,encoding='utf-8')

code=(base/'build_plan.py').read_text(encoding='utf-8')
code=code.replace("source=(WORK/'策划正文.md').read_text(encoding='utf-8')","source=(WORK/'v2'/'正文_v2.0.md').read_text(encoding='utf-8')")
code=code.replace("(WORK/'排版完整稿.md')","(WORK/'v2'/'排版完整稿_v2.0.md')")
code=code.replace("(WORK/'生成检查.json')","(WORK/'v2'/'生成检查_v2.0.json')")
code=code.replace('昆仑_武侠RPG完整策划案_v1.0','昆仑_像素2D完整策划案_v2.0')
code=code.replace('昆仑 武侠RPG完整策划案','昆仑 像素2D完整策划案')
code=code.replace('昆仑 武侠角色扮演游戏完整策划案','昆仑 像素风2D武侠游戏完整策划案')
code=code.replace('昆仑  武侠角色扮演游戏完整策划案','昆仑  像素风2D武侠游戏完整策划案')
code=code.replace('v1.0','v2.0')
code=code.replace('PC精品单机','PC像素剧情单机')
code=code.replace("'武侠角色扮演游戏<br/>完整策划案'","'像素风2D武侠游戏<br/>完整策划案'")
code=code.replace('采用现代3D画面与指令回合制','采用纯像素2D与指令回合制')
code=code.replace('完成从少年求生到守护他人的完整旅程。','以人物关系、可玩日常与关键抉择完成全篇旅程。')
code=code.replace("[['43小时','53小时','59小时']]","[['40小时','48小时','54小时']]")
code=code.replace("metrics=[['43小时','53小时','59小时']","metrics=[['40小时','48小时','54小时']")
code=code.replace('全篇剧情  战斗规则  美术方向  制作计划  成本模型','人物塑造  剧情分镜  华山样章  像素规范  制作模型')
code=code.replace('现代3D · 剧情单机 · 指令回合制','纯像素2D · 人物与剧情优先 · 指令回合制')
code=code.replace('昆仑<br>武侠角色扮演游戏完整策划案','昆仑<br>像素风2D武侠游戏完整策划案')
code=code.replace('<b>43小时</b>','<b>40小时</b>').replace('<b>53小时</b>','<b>48小时</b>').replace('<b>59小时</b>','<b>54小时</b>')
code=code.replace(" 'list':ParagraphStyle", " 'quote':ParagraphStyle('quote',fontName='CN',fontSize=9.5,leading=16,spaceAfter=6,leftIndent=14,rightIndent=10,wordWrap='CJK',textColor=INK),\n 'list':ParagraphStyle")
code=code.replace("        yield ('list' if re.match", "        if l.startswith('> '):yield ('quote',l[2:].rstrip());i+=1;continue\n        yield ('list' if re.match")
code=code.replace("html_blocks.append('<p>'+rendered+'</p>')", "html_blocks.append(('<blockquote>' if typ=='quote' else '<p>')+rendered+('</blockquote>' if typ=='quote' else '</p>'))")
code=code.replace("elif '月份' in headers:w=[.21,.12,.16,.51]", "elif '月份' in headers:w=[.21,.12,.16,.51]")
code=code.replace("elif n==5:w=[.065,.18,.085,.34,.33]", "elif n==5:\n        if '人月' in headers:w=[.20,.10,.12,.09,.49]\n        else:w=[.065,.18,.085,.34,.33]")
code=code.replace("if '开放章' in headers:w=[.10,.19,.10,.61]", "if '开放章' in headers:w=[.10,.19,.10,.61]\n        elif headers[0]=='拍次':w=[.08,.43,.49]")
code=code.replace("elif '费用' in ''.join(headers):w=[.28,.18,.54]", "elif '金额' in headers:w=[.28,.56,.16]\n        elif '费用' in ''.join(headers):w=[.28,.18,.54]")
code=code.replace('p{margin:0 0 17px}', 'p{margin:0 0 17px}blockquote{margin:6px 0;padding:5px 15px;border-left:3px solid #315c4b;background:#f5f8f5}')
(folder/'build_v2.py').write_text(code,encoding='utf-8')
print(json.dumps({'sections':len(sections),'body_characters':len(body),'builder':str(folder/'build_v2.py')},ensure_ascii=False))
