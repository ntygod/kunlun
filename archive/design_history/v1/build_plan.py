from pathlib import Path
import re, html, json, hashlib
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.lib import colors
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.enums import TA_LEFT
from reportlab.platypus import (BaseDocTemplate, PageTemplate, Frame, Paragraph, Spacer, PageBreak, Table, TableStyle, KeepTogether)
from reportlab.platypus.tableofcontents import TableOfContents
from reportlab.lib.pagesizes import A4
from pypdf import PdfReader

ROOT=Path(r'D:\novel')
WORK=ROOT/'策划工作'
OUT=ROOT/'output'/'pdf'
OUT.mkdir(parents=True,exist_ok=True)
pdfmetrics.registerFont(TTFont('CN',r'C:\Windows\Fonts\msyh.ttc',subfontIndex=0))
pdfmetrics.registerFont(TTFont('CNB',r'C:\Windows\Fonts\msyhbd.ttc',subfontIndex=0))
pdfmetrics.registerFontFamily('CN',normal='CN',bold='CNB',italic='CN',boldItalic='CNB')

source=(WORK/'策划正文.md').read_text(encoding='utf-8')
records=[]
for name,kind in [('前传天机_阅读报告.md','three'),('纯阳破城_阅读报告.md','two'),('龙游劫波_阅读报告.md','three')]:
    txt=(WORK/name).read_text(encoding='utf-8')
    for line in txt.splitlines():
        if not line.startswith('|'): continue
        cells=[x.strip() for x in line.strip('|').split('|')]
        if kind=='two':
            if len(cells)!=2 or not re.match(r'^(纯阳|破城)\d+《',cells[0]): continue
            m=re.match(r'(.*?)\s*(\d+[–—-]\d+)$',cells[0]); title,loc=m.groups(); fact=cells[1]
        else:
            if len(cells)!=3 or not re.match(r'^\d+[–—-]\d+$',cells[1]): continue
            title,loc,fact=cells
        fact=re.sub(r'\*\*','',fact)
        sentences=re.split(r'(?<=。)',fact)
        brief=sentences[0]
        if len(brief)<50 and len(sentences)>1: brief+=sentences[1]
        if len(brief)>160:
            cuts=[m.end() for m in re.finditer('[；，。]',brief) if 70<m.end()<155]
            if cuts: brief=brief[:cuts[-1]].rstrip('；，。')+'。'
        records.append((title,loc.replace('—','–'),brief))
assert len(records)==72,len(records)
endings=[
('万夫莫敌',6965,7053,'百丈坪会上明三秋、秦伯符与九如花生先后援救；晓霜用神仙倒，梁萧保护众人。'),
('浊世滔滔',7054,7137,'梁与明三秋脱身，晓霜遇韩凝紫后逃生而被误传已死；梁赈灾治河、溯源西行并遇精绝。'),
('大哉昆仑',7138,7191,'梁自号西昆仑、赠火流星；精绝遭蒙军夜袭，他为保护老弱参战并杀花斑豹。'),
('随圆就方',7192,7268,'晓霜独立线：骆明绮与常宁死，萧千绝指点花生，晓霜以医理助花生击败贺陀罗。'),
('人命至重',7269,7317,'精绝战后、剑谷拒斗与铸剑之议；马拉加以生命天平开知识宝库，梁读书三年再西行。'),
('天狼啸月',7318,7395,'又七年后梁救行商，遇寻他送剑的风怜；狼群与阿莫疑案引出天山十二禽。'),
('故人相逢',7396,7496,'柳莺莺以天山首领身份与梁重逢；破双天狼，天罚首次杀敌，风怜自请拜梁为师。'),
('黄河九曲',7497,7576,'风怜随梁东行，九曲阁遇关洛四杰与花镜圆；梁误猜晓霜受囚，擒镜圆要求相见。'),
('龙奔万里',7577,7684,'铁塔与释天风交手，再比轻功；风怜促梁放人，明三秋告知晓霜死讯传闻。'),
('和谐之道',7685,7752,'梁在括苍山由算理悟谐之道，赴天机宫救风怜、夺回天罚，拒绝龙牙狮心拉拢。'),
('风云际会',7753,7827,'云殊败二僧后放走，与梁决斗落败；花氏不同组合使太乙分光，仍被破局。'),
('一剑横天',7828,7898,'公羊羽与花无媸联剑，梁悟人剑相御；晓霜花生等到场，重逢息斗，公羊羽封剑。'),
('隰桑有阿',7899,7962,'桑树之约重申共同生活与救人志向；元军压境、火炮毁三轮，众人争论守书与撤离。'),
('月照大江',7963,8016,'梁殿后，晓霜请关闸；萧千绝救徒而死，明归弑脱欢；江边察微弱心脉，花生九如分路。')]
for i,(title,a,b,fact) in enumerate(endings,1):records.append((f'天道{i}《{title}》',f'{a}–{b}',fact))
assert len(records)==86
appendix='\n\n## 附录 D 原著全篇阅读与改编索引\n\n本索引覆盖前传7章与正文79章。每条定位旨在对照原著篇章与游戏叙事节点，便于研发查考。行号以项目GBK原文件按换行分割计；重复文本保留其原始位置，不另算章节。第8017行起为韩云波后记，亦已阅读，不纳入剧情章数。\n\n| 卷章 | 原文行号 | 事件定位摘要 |\n| --- | --- | --- |\n'
for title,loc,fact in records:appendix+=f'| {title} | {loc} | {fact} |\n'
appendix+='\n阅读范围记录：前传及天机卷12–2558行；纯阳及破城卷2559–4570行；龙游及劫波卷4571–6964行；天道卷及后记6965–8041行。项目组已完成全书正文精读与因果梳理；底本缺损与版本异文详见附录C。\n'
full=source+appendix
(WORK/'排版完整稿.md').write_text(full,encoding='utf-8')

INK=colors.HexColor('#202723'); ACCENT=colors.HexColor('#315C4B'); GRAY=colors.HexColor('#64736C'); PALE=colors.HexColor('#EAF0EC')
PAGEW,PAGEH=A4
M=48; CW=PAGEW-2*M
styles={
 'body':ParagraphStyle('body',fontName='CN',fontSize=9.5,leading=16,spaceAfter=7,textColor=INK,wordWrap='CJK',allowWidows=0,allowOrphans=0),
 'h1':ParagraphStyle('h1',fontName='CNB',fontSize=17,leading=25,spaceBefore=12,spaceAfter=14,keepWithNext=True,textColor=colors.black,wordWrap='CJK'),
 'h2':ParagraphStyle('h2',fontName='CNB',fontSize=12,leading=19,spaceBefore=12,spaceAfter=7,keepWithNext=True,textColor=colors.black,wordWrap='CJK'),
 'cell':ParagraphStyle('cell',fontName='CN',fontSize=8.3,leading=13,spaceAfter=0,wordWrap='CJK',textColor=INK),
 'th':ParagraphStyle('th',fontName='CNB',fontSize=8.4,leading=13,spaceAfter=0,wordWrap='CJK',textColor=INK),
 'list':ParagraphStyle('list',fontName='CN',fontSize=9.5,leading=16,spaceAfter=6,leftIndent=10,firstLineIndent=-10,wordWrap='CJK',textColor=INK),
}

def safe(text):
    text=html.escape(text)
    text=re.sub(r'\*\*(.+?)\*\*',r'<b>\1</b>',text)
    return text

def blocks(txt):
    ls=txt.splitlines(); i=0
    while i<len(ls):
        l=ls[i].strip()
        if not l:i+=1;continue
        if l.startswith('# '):yield ('title',l[2:]);i+=1;continue
        if l.startswith('## '):yield ('h1',l[3:]);i+=1;continue
        if l.startswith('### '):yield ('h2',l[4:]);i+=1;continue
        if l.startswith('|'):
            rows=[]
            while i<len(ls) and ls[i].strip().startswith('|'):
                cs=[x.strip() for x in ls[i].strip().strip('|').split('|')]
                if not all(re.fullmatch(r':?-+:?',c.replace(' ','')) for c in cs):rows.append(cs)
                i+=1
            yield ('table',rows);continue
        yield ('list' if re.match(r'^\d+\. ',l) else 'body',l);i+=1

def widths(headers):
    n=len(headers)
    if n==2:w=[.25,.75]
    elif n==3:
        if '原文行号' in headers:w=[.25,.15,.60]
        elif '费用' in ''.join(headers):w=[.28,.18,.54]
        elif '编号' in headers:w=[.12,.3,.58]
        else:w=[.24,.30,.46]
    elif n==4:
        if '开放章' in headers:w=[.10,.19,.10,.61]
        elif headers[0]=='编号':w=[.09,.07,.28,.56]
        elif '消耗' in headers:w=[.23,.12,.34,.31]
        elif '月份' in headers:w=[.21,.12,.16,.51]
        else:w=[.21,.18,.27,.34]
    elif n==5:w=[.065,.18,.085,.34,.33]
    else:w=[1/n]*n
    return [CW*x/sum(w) for x in w]

class PlanDoc(BaseDocTemplate):
    def __init__(self,path):
        super().__init__(str(path),pagesize=A4,leftMargin=M,rightMargin=M,topMargin=48,bottomMargin=48,title='昆仑 武侠角色扮演游戏完整策划案',author='项目策划',pageCompression=1)
        self.heading_count=0
        self.addPageTemplates(PageTemplate(id='normal',frames=[Frame(M,48,CW,PAGEH-96,id='body',leftPadding=0,rightPadding=0,topPadding=0,bottomPadding=0)],onPage=self.draw_page))
    def beforeDocument(self):self.heading_count=0
    def afterFlowable(self,f):
        if isinstance(f,Paragraph) and f.style.name=='h1' and f.getPlainText()!='目录':
            self.heading_count+=1; key=f's{self.heading_count}'
            self.canv.bookmarkPage(key)
            self.canv.addOutlineEntry(f.getPlainText(),key,level=0,closed=False)
            self.notify('TOCEntry',(0,f.getPlainText(),self.page,key))
    def draw_page(self,c,d):
        if d.page==1:return
        c.saveState();c.setFont('CN',8);c.setFillColor(GRAY)
        c.drawString(M,PAGEH-27,'昆仑  武侠角色扮演游戏完整策划案')
        c.drawRightString(PAGEW-M,PAGEH-27,'v1.0  /  2026.10.13')
        c.drawString(M,28,'PC精品单机  ·  立项与预制作基线')
        c.drawRightString(PAGEW-M,28,str(d.page));c.restoreState()

story=[]
story.append(Spacer(1,36))
story.append(Paragraph('昆仑',ParagraphStyle('cover',fontName='CNB',fontSize=46,leading=64,textColor=colors.black)))
story.append(Spacer(1,14))
story.append(Paragraph('武侠角色扮演游戏<br/>完整策划案',ParagraphStyle('ct',fontName='CNB',fontSize=25,leading=37,textColor=colors.black)))
story.append(Spacer(1,30))
story.append(Paragraph('以凤歌小说为故事基础，采用现代3D画面与指令回合制，<br/>完成从少年求生到守护他人的完整旅程。',ParagraphStyle('intro',fontName='CN',fontSize=12,leading=22,textColor=INK)))
story.append(Spacer(1,35))
metrics=[['43小时','53小时','59小时'],['主线目标','主线与精选支线','主要收集完成']]
tb=Table([[Paragraph(s,ParagraphStyle(f'm{i}',fontName='CNB' if i==0 else 'CN',fontSize=21 if i==0 else 9,leading=27 if i==0 else 15,textColor=ACCENT if i==0 else GRAY)) for s in row] for i,row in enumerate(metrics)],colWidths=[CW/3]*3)
tb.setStyle(TableStyle([('BACKGROUND',(0,0),(-1,-1),PALE),('TOPPADDING',(0,0),(-1,0),14),('BOTTOMPADDING',(0,1),(-1,1),14),('LEFTPADDING',(0,0),(-1,-1),16)]))
story.append(tb);story.append(Spacer(1,35))
story.append(Paragraph('PC优先  /  三人上限队伍  /  序章加20章<br/>全篇剧情  战斗规则  美术方向  制作计划  成本模型<br/>附原著86章阅读索引',ParagraphStyle('spec',fontName='CN',fontSize=10.5,leading=22,textColor=INK)))
story.append(Spacer(1,38))
story.append(Paragraph('立项与预制作基线  v1.0<br/>2026年10月13日',ParagraphStyle('date',fontName='CN',fontSize=10,leading=20,textColor=GRAY)))
story.append(PageBreak())
story.append(Paragraph('目录',styles['h1']))
toc=TableOfContents()
toc.levelStyles=[ParagraphStyle('toc',fontName='CN',fontSize=10,leading=19,spaceBefore=3,leftIndent=0,textColor=INK)]
story.append(toc);story.append(PageBreak())

seen=False
html_blocks=[];html_toc=[];hid=0
for typ,val in blocks(full):
    if typ=='title':continue
    if not seen:
        if typ!='h1':continue
        seen=True
    if typ=='h1':
        hid+=1;html_toc.append(f'<a href="#s{hid}">{html.escape(val)}</a>')
        html_blocks.append(f'<h2 id="s{hid}">{html.escape(val)}</h2>')
        if val.startswith('附录 A') or val.startswith('附录 D'):story.append(PageBreak())
        story.append(Paragraph(safe(val),styles['h1']))
    elif typ=='h2':
        html_blocks.append(f'<h3>{html.escape(val)}</h3>');story.append(Paragraph(safe(val),styles['h2']))
    elif typ=='table':
        headers=val[0];n=len(headers)
        assert all(len(r)==n for r in val),(headers,val)
        data=[[Paragraph(safe(s),styles['th'] if j==0 else styles['cell']) for s in r] for j,r in enumerate(val)]
        table=Table(data,colWidths=widths(headers),repeatRows=1,hAlign='LEFT')
        table.setStyle(TableStyle([('BACKGROUND',(0,0),(-1,0),PALE),('VALIGN',(0,0),(-1,-1),'TOP'),('LEFTPADDING',(0,0),(-1,-1),7),('RIGHTPADDING',(0,0),(-1,-1),7),('TOPPADDING',(0,0),(-1,-1),7),('BOTTOMPADDING',(0,0),(-1,-1),7),('LINEBELOW',(0,0),(-1,0),.6,ACCENT),('LINEBELOW',(0,1),(-1,-1),.25,colors.HexColor('#D7DEDA')),('ROWBACKGROUNDS',(0,1),(-1,-1),[colors.white,colors.HexColor('#F8FAF8')])]))
        story.extend([table,Spacer(1,12)])
        h='<div class="tablewrap"><table><thead><tr>'+''.join('<th>'+safe(s)+'</th>' for s in headers)+'</tr></thead><tbody>'
        h+=''.join('<tr>'+''.join('<td>'+safe(s)+'</td>' for s in r)+'</tr>' for r in val[1:])+'</tbody></table></div>'
        html_blocks.append(h)
    else:
        story.append(Paragraph(safe(val),styles[typ]))
        rendered=safe(val)
        rendered=re.sub(r'(https://[^\s。]+)',r'<a href="\1">\1</a>',rendered)
        html_blocks.append('<p>'+rendered+'</p>')

pdf=OUT/'昆仑_武侠RPG完整策划案_v1.0.pdf'
doc=PlanDoc(pdf);doc.multiBuild(story)
css='''*{box-sizing:border-box}html{scroll-behavior:smooth}body{margin:0;background:#f2f4f1;color:#202723;font:16px/1.9 "Microsoft YaHei",sans-serif}nav{position:fixed;inset:0 auto 0 0;width:270px;padding:28px 22px;overflow:auto;background:#173c30;color:#fff}nav strong{font-size:24px}nav a{display:block;color:#d6e5de;text-decoration:none;font-size:13px;padding:4px 0;line-height:1.65}main{max-width:1080px;margin:0 auto 0 290px;padding:55px 55px 90px;background:white}.cover{padding:30px 0 50px}.cover h1{font-size:48px;line-height:1.3;margin-bottom:20px}.lead{font-size:20px}.meta{color:#63766c}.metrics{display:flex;gap:16px;margin-top:30px}.metric{background:#eaf0ec;flex:1;padding:18px}.metric b{display:block;font-size:27px;color:#315c4b}h2{font-size:29px;margin:65px 0 25px;scroll-margin-top:25px}h3{font-size:20px;margin:32px 0 15px}p{margin:0 0 17px}table{border-collapse:collapse;width:100%;font-size:13px;line-height:1.7;margin:18px 0 28px}td,th{text-align:left;vertical-align:top;padding:11px 12px;border-bottom:1px solid #d7deda}th{background:#eaf0ec}tr:nth-child(even){background:#f8faf8}.tablewrap{overflow-x:auto}a{color:#315c4b;overflow-wrap:anywhere}@media(max-width:1000px){nav{position:relative;width:100%;max-height:300px}main{margin:0;padding:24px}h2{font-size:24px}.cover h1{font-size:36px}}@media print{nav{display:none}main{margin:0;max-width:none;padding:0}body{background:white}h2{break-before:page}tr{break-inside:avoid}}'''
htm='<!doctype html><html lang="zh-CN"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>昆仑 武侠RPG完整策划案</title><style>'+css+'</style><nav><strong>昆仑 策划案</strong><p>v1.0 · 2026.10.13</p>'+''.join(html_toc)+'</nav><main><section class="cover"><h1>昆仑<br>武侠角色扮演游戏完整策划案</h1><p class="lead">现代3D · 剧情单机 · 指令回合制</p><p class="meta">PC优先 / 立项与预制作基线 / 2026年10月13日</p><div class="metrics"><div class="metric"><b>43小时</b>主线目标</div><div class="metric"><b>53小时</b>主线与精选支线</div><div class="metric"><b>59小时</b>主要收集完成</div></div></section>'+''.join(html_blocks)+'</main></html>'
htmp=OUT/'昆仑_武侠RPG完整策划案_v1.0.html';htmp.write_text(htm,encoding='utf-8')
r=PdfReader(pdf)
info={'pages':len(r.pages),'chapters_indexed':len(records),'source_characters':len(full),'pdf_bytes':pdf.stat().st_size,'html_bytes':htmp.stat().st_size,'original_sha256':hashlib.sha256((ROOT/'昆仑.txt').read_bytes()).hexdigest()}
(WORK/'生成检查.json').write_text(json.dumps(info,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(info,ensure_ascii=False))
