"""Export the current merged v3 source to the existing HTML and PDF paths."""
from pathlib import Path
import argparse
import html
import json
import math
import re
import sys

from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, PageBreak, Table, TableStyle
from pypdf import PdfReader


def inline(value):
    # These five source characters have no glyph in the selected YaHei face.
    for old, new in {'⌊':'floor(', '⌋':')', '↔':'<->', '∉':' not in ', '⑫':'(12)'}.items():
        value = value.replace(old, new)
    value = html.escape(value)
    value = re.sub(r'&lt;br\s*/?&gt;', '<br/>', value, flags=re.I)
    value = re.sub(r'\*\*(.+?)\*\*', r'<b>\1</b>', value)
    value = re.sub(r'`([^`]+)`', r'\1', value)
    return value


def blocks(text):
    lines = text.splitlines()
    i = 0
    while i < len(lines):
        line = lines[i].strip()
        if not line or line == '---':
            i += 1
            continue
        heading = re.match(r'^(#{1,6})\s+(.*)', line)
        if heading:
            yield ('heading', (len(heading.group(1)), heading.group(2)))
            i += 1
        elif line.startswith('|'):
            rows = []
            while i < len(lines) and lines[i].strip().startswith('|'):
                cells = [s.strip() for s in lines[i].strip().strip('|').split('|')]
                if not all(re.fullmatch(r':?-+:?', c.replace(' ', '')) for c in cells):
                    rows.append(cells)
                i += 1
            if rows:
                yield ('table', rows)
        elif line.startswith('```') or line in ('`json', '`'):
            closing = '```' if line.startswith('```') else '`'
            i += 1
            while i < len(lines) and not lines[i].strip().startswith(closing):
                yield ('code', lines[i])
                i += 1
            i += 1
        else:
            kind = 'quote' if line.startswith('>') else 'body'
            yield (kind, line.lstrip('> ').strip() if kind == 'quote' else line)
            i += 1


def main():
    sys.stdout.reconfigure(encoding='utf-8')
    sys.stderr.reconfigure(encoding='utf-8')
    parser = argparse.ArgumentParser()
    parser.add_argument('--root', type=Path, default=Path(__file__).resolve().parents[2])
    parser.add_argument('--report', type=Path)
    args = parser.parse_args()
    root = args.root.resolve()
    source = next((root / 'docs/design/v3').glob('*v3.0.md'))
    output = root / 'output/pdf'
    pdf_path = output / (source.stem + '.pdf')
    html_path = output / (source.stem + '.html')
    original_html = html_path.read_text(encoding='utf-8')
    header = original_html[:original_html.index('<nav')]
    parsed = list(blocks(source.read_text(encoding='utf-8')))
    pdfmetrics.registerFont(TTFont('V3CN', 'C:/Windows/Fonts/msyh.ttc', subfontIndex=0))
    pdfmetrics.registerFont(TTFont('V3CNB', 'C:/Windows/Fonts/msyhbd.ttc', subfontIndex=0))
    pdfmetrics.registerFontFamily('V3CN', normal='V3CN', bold='V3CNB', italic='V3CN', boldItalic='V3CNB')
    ink = colors.HexColor('#202723')
    accent = colors.HexColor('#315c4b')
    styles = {
        'body': ParagraphStyle('body', fontName='V3CN', fontSize=9, leading=14, spaceAfter=5, wordWrap='CJK', textColor=ink),
        'quote': ParagraphStyle('quote', fontName='V3CN', fontSize=9, leading=14, leftIndent=10, spaceAfter=5, wordWrap='CJK', textColor=ink),
        'code': ParagraphStyle('code', fontName='V3CN', fontSize=7.5, leading=11, leftIndent=8, spaceAfter=1, wordWrap='CJK'),
    }
    for level in range(1, 7):
        size = {1:17, 2:13, 3:11, 4:10, 5:9, 6:9}[level]
        styles[f'h{level}'] = ParagraphStyle(f'h{level}', fontName='V3CNB', fontSize=size,
            leading=size*1.4, spaceBefore=12, spaceAfter=7, keepWithNext=True, wordWrap='CJK', textColor=accent)
    width = A4[0] - 80
    story = []
    toc = []
    rendered = []
    section_id = 0
    first_module = True
    for kind, value in parsed:
        if kind == 'heading':
            level, title = value
            anchor = ''
            if level <= 2:
                section_id += 1
                anchor = f" id='sec{section_id}'"
                toc.append(f"<a class='toc-h{level}' href='#sec{section_id}'>{inline(title)}</a>")
            rendered.append(f'<h{level}{anchor}>{inline(title)}</h{level}>')
            if level == 1:
                if not first_module:
                    story.append(PageBreak())
                first_module = False
            story.append(Paragraph(inline(title), styles[f'h{level}']))
        elif kind == 'table':
            count = len(value[0])
            if any(len(row) != count for row in value):
                raise ValueError(f'Inconsistent table columns: {value[0]}')
            rendered.append('<div class="tablewrap"><table><thead><tr>' + ''.join('<th>'+inline(c)+'</th>' for c in value[0]) +
                '</tr></thead><tbody>' + ''.join('<tr>'+''.join('<td>'+inline(c)+'</td>' for c in row)+'</tr>' for row in value[1:]) + '</tbody></table></div>')
            size = 6.1 if count >= 8 else 7.5
            cell_style = ParagraphStyle('cell', fontName='V3CN', fontSize=size, leading=size*1.35, wordWrap='CJK', textColor=ink)
            head_style = ParagraphStyle('head', parent=cell_style, fontName='V3CNB')
            weights = [math.sqrt(max(12, min(220, max(len(re.sub('<[^>]+>', '', row[col])) for row in value)))) for col in range(count)]
            col_widths = [width*w/sum(weights) for w in weights]
            data = [[Paragraph(inline(cell), head_style if ri == 0 else cell_style) for cell in row] for ri, row in enumerate(value)]
            table = Table(data, colWidths=col_widths, repeatRows=1, splitInRow=1, hAlign='LEFT')
            table.setStyle(TableStyle([
                ('VALIGN', (0,0), (-1,-1), 'TOP'), ('BACKGROUND', (0,0), (-1,0), colors.HexColor('#eaf0ec')),
                ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, colors.HexColor('#f8faf8')]),
                ('LINEBELOW', (0,0), (-1,-1), .3, colors.HexColor('#d7deda')),
                ('LEFTPADDING', (0,0), (-1,-1), 2), ('RIGHTPADDING', (0,0), (-1,-1), 2),
                ('TOPPADDING', (0,0), (-1,-1), 3), ('BOTTOMPADDING', (0,0), (-1,-1), 3),
            ]))
            story.extend([table, Spacer(1, 7)])
        else:
            tag = 'blockquote' if kind == 'quote' else 'p'
            rendered.append(f'<{tag}>{inline(value)}</{tag}>')
            story.append(Paragraph(inline(value) or ' ', styles[kind]))
    final_html = header + '<nav><strong>昆仑 详细全案</strong><p>v3.0 · 80级成长体系</p>' + ''.join(toc) + '</nav><main>' + ''.join(rendered) + '</main></body></html>'
    html_path.write_text(final_html, encoding='utf-8', newline='\n')

    def footer(canvas, doc):
        canvas.saveState()
        canvas.setFont('V3CN', 7)
        canvas.setFillColor(colors.HexColor('#64736c'))
        canvas.drawString(40, 24, '昆仑 详细剧本与系统美术全案 v3.0')
        canvas.drawRightString(A4[0]-40, 24, str(doc.page))
        canvas.restoreState()

    document = SimpleDocTemplate(str(pdf_path), pagesize=A4, leftMargin=40, rightMargin=40,
        topMargin=36, bottomMargin=38, title='昆仑 详细剧本与系统美术全案 v3.0', author='昆仑项目')
    document.build(story, onFirstPage=footer, onLaterPages=footer)
    reader = PdfReader(pdf_path)
    pages = [page.extract_text() or '' for page in reader.pages]
    beginnings = [re.sub(r'\s+', '', text[:220]) for text in pages]
    report = {'pages':len(pages), 'pdf_bytes':pdf_path.stat().st_size, 'html_bytes':html_path.stat().st_size,
        'module07_start':next(i+1 for i,text in enumerate(beginnings) if '07战斗角色定位' in text),
        'module08_start':next(i+1 for i,text in enumerate(beginnings) if '2D像素美术资产全量清单' in text)}
    if args.report:
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding='utf-8')
    print(json.dumps(report, ensure_ascii=False))


if __name__ == '__main__':
    main()
