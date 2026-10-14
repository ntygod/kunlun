#!/usr/bin/env python3
"""Original, explicitly authored integer-pixel candidate artwork. No generated images.
Run from any directory. All masks, paths, color placement and timing are authored here.
No randomness, image resampling (except nearest preview), external images or mirroring.
This is a review candidate, not accepted final hand-painted production art.
"""
from pathlib import Path
import json, hashlib
from PIL import Image, ImageDraw
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'game/assets/pixel_candidate'
PRE=ROOT/'output/cache/pixel-candidate'
OUT.mkdir(parents=True,exist_ok=True); PRE.mkdir(parents=True,exist_ok=True)
# Six specified PAL-01 keys + 22 proposed support colors, including character ramps.
HEX=['141820','1E262B','2C383D','3B494F','4A5A60','65747A','859391','A8B8B1',
     'DCE6E8','363B31','425440','5B8258','78966A','9CAC7B','443B34','5D4E3E',
     '715C45','8C7355','AB926B','C6B18A','E0CEAB','493C4F','9A7560','71576E',
     'D7B690','B95349','997487','E87A35']
PAL=[tuple(bytes.fromhex(h))+(255,) for h in HEX]
C=dict(zip('oxabcdefghijklmnpqrstuvwxyz!',PAL))
# symbolic drawing labels, independent from mask clothing codes
COL={'ink':0,'shadow':1,'hair':2,'hairlight':4,'skinshadow':22,'skin':24,'skinlight':20,
     'earth':17,'woodshadow':14,'wood':16,'woodlight':18,'clothlight':20}
def rgba(n):return PAL[n] if isinstance(n,int) else PAL[COL[n]]
def dot(im,x,y,n):
    assert isinstance(x,int) and isinstance(y,int), (x,y)
    im.putpixel((x,y),rgba(n))
def path(im,pts,n,w=1):
    assert all(isinstance(v,int) for p in pts for v in p)
    ImageDraw.Draw(im).line(pts,fill=rgba(n),width=w)
def box(im,xy,n):
    assert all(isinstance(v,int) for v in xy)
    ImageDraw.Draw(im).rectangle(xy,fill=rgba(n))
def poly(im,pts,n):
    assert all(isinstance(v,int) for p in pts for v in p)
    ImageDraw.Draw(im).polygon(pts,fill=rgba(n))
def mask(im,x,y,rows,colors):
    for j,row in enumerate(rows):
        for i,ch in enumerate(row):
            if ch!='.':dot(im,x+i,y+j,colors[ch])
# Face/hair masks are individually authored in all four directions (no flip).
HEADS={
'S':[
'....oooo....','...ohhho....','..ohHHhho...', '.ohHHHHhho..',
'.ohhhhHHho..','.ohsssshho..','.osslslsso..','..sssssso...',
'..ossSsso...','...osso.....'],
'N':[
'....oooo....','...ohhho....','..ohHHhho...', '.ohHHHHhho..',
'.ohHHHHhho..','.ohhHHhhho..','.ohhhhhhho..','..ohhhho....',
'...ohhho....','....oso.....'],
'W':[
'....oooo....','...ohhho....','..ohHHhho...', '.ohHHHHhho..',
'.ohhhhHHho..','.osssshhho..','osslsshhho..','.ssssssho...',
'..ossSho....','...osso.....'],
'E':[
'....oooo....','....ohhho...','...ohHHhho..','..ohHHHHhho.',
'..ohHHhhhho.','..ohhhsssso.','..ohhsslssso','...ohssssso.',
'....oSssso..','.....osso...']}
HC={'o':0,'h':2,'H':4,'s':24,'S':22,'l':0}
# Upper robe masks: fixed shoulder slope, sleeves, anatomical right-overlap closure.
TORSO={
'S':[
'......oo..oo......','....ooHHooHHoo....','...oHHHlLLlHHHo...',
'..oHHHlLLlHHHHHo..','.oHHHlLLlHHHMHHHo.','.oHMMHlLlHHHMMHHo.',
'oHMMMHHlHHHHMMMHo.','oHMMMHHoHHHHMMMHo.','oHMMMHHoHHHHMMMHo.',
'.oMMMHHoHHHHMMHo..','.oMMMHHoHHHHMMHo..','..ossoBBBBBBosso..'],
'N':[
'......oooooo......','....ooHHHHHHoo....','...oHHHHHHHHHHo...',
'..oHHHHHHHHHHHHo..','.oHHHHHHHHHMHHHHo.','.oHMMHHHHHHMMHHHo.',
'oHMMMHHHHHHHMMMHo.','oHMMMHHHMHHHMMMHo.','oHMMMHHHMHHHMMMHo.',
'.oMMMHHHMHHHMMHo..','.oMMMHHHMHHHMMHo..','..ossoBBBBBBosso..'],
'W':[
'.......oooo.......','.....ooHHLHo......','....oHHHlLHHo.....',
'...oHHHlLHHHHo....','...oHHHlHHHMHo....','...oHHHHHHMMHo....',
'...oHHHHHMMMHo....','...oHHHHMMMMHo....','...oHHHMMMMMHo....',
'....oHHMMMMHo.....','....ossMMMHo......','.....oBBBBBo......'],
'E':[
'.......oooo.......','......oHLLHoo.....','.....oHHLLHHHo....',
'....oHHHHLLHHHo...','....oHMHHHlHHHo...','....oHMMHHlHHHo...',
'....oHMMMHHHHHo...','....oHMMMMHHHHo...','....oHMMMMMHHHo...',
'.....oHMMMMHHo....','......oHMMMss o...'.replace(' ',''),'......oBBBBBo.....']}
def actor(kind,d,frame):
    im=Image.new('RGBA',(32,48))
    # Authored 16 x 6 contact shadow; only intentional non-binary alpha.
    shadow=PAL[1][:3]+(115,)
    for y,l,r in [(41,11,20),(42,9,22),(43,8,23),(44,8,23),(45,10,21),(46,13,18)]:
        ImageDraw.Draw(im).line((l,y,r,y),fill=shadow)
    boy=kind=='liang_xiao_young'; elder=kind=='liang_tiande'
    top=10 if boy else (6 if elder else 4)
    bob=1 if frame in (2,4) else 0
    # Four hand-keyed gait poses: support/ passing / other support / passing.
    phases={0:(0,0,0),1:(-1,1,-1),2:(0,-1,0),3:(1,-1,1),4:(-1,0,0)}
    a,b,sway=phases[frame]
    sway *= 2
    hem_y=35 if boy else 39
    legs_y=34 if boy else 37
    if d in ('S','N'):
        spread=1 if frame in (1,3) else 0
        for x,step in [(11-spread,a),(18+spread,b)]:
            box(im,(x,legs_y,x+3,42+min(step,0)),3)
            path(im,[(x+1,legs_y),(x+1,41+min(step,0))],5)
            box(im,(x-1,42+min(step,0),x+4,43+min(step,0)),0)
            path(im,[(x,42+min(step,0)),(x+3,42+min(step,0))],15)
    else:
        drift=3 if frame==1 else (-3 if frame==3 else 0)
        for x,step in [(12+drift,a),(17-drift,b)]:
            poly(im,[(x,legs_y),(x+3,legs_y),(x+3,41+min(step,0)),(x,42+min(step,0))],3)
            shoe=x-2 if d=='W' else x
            box(im,(shoe,42+min(step,0),shoe+5,43+min(step,0)),0)
            path(im,[(shoe+1,42+min(step,0)),(shoe+4,42+min(step,0))],15)
    main,lit,dark=(18,19,16) if boy else ((11,12,10) if not elder else (17,18,15))
    tc={'o':0,'H':main,'M':dark,'L':20,'l':19,'B':15,'s':24}
    torso_y=top+9+bob
    # Separate, hand-plotted robe hems; boy short coarse tunic vs scholar long robe.
    if d in ('S','N'):
        poly(im,[(10,torso_y+8),(21,torso_y+8),(24+sway,hem_y),(19,hem_y+1),(16,hem_y-1),(12,hem_y+1),(8+sway,hem_y)],0)
        poly(im,[(11,torso_y+8),(20,torso_y+8),(22+sway,hem_y-1),(18,hem_y),(15,hem_y-2),(11,hem_y),(10+sway,hem_y-1)],main)
        path(im,[(13,torso_y+9),(12+sway,hem_y-2)],lit)
        path(im,[(18,torso_y+10),(19+sway,hem_y-1)],dark)
        path(im,[(16,torso_y+10),(16,hem_y-2)],dark)
    else:
        poly(im,[(12,torso_y+8),(20,torso_y+8),(23-sway,hem_y),(18,hem_y+1),(14,hem_y-1),(10-sway,hem_y)],0)
        poly(im,[(13,torso_y+8),(19,torso_y+8),(21-sway,hem_y-1),(18,hem_y),(14,hem_y-2),(12-sway,hem_y-1)],main)
        path(im,[(16,torso_y+9),(15-sway,hem_y-2)],lit)
        path(im,[(19,torso_y+10),(20-sway,hem_y-1)],dark)
    mask(im,7,torso_y,TORSO[d],tc)
    # Lower sleeve tips shift by gait phase, preserving shoulder anchor.
    if frame and d in ('S','N'):
        box(im,(8,torso_y+8+a,10,torso_y+10+a),dark)
        box(im,(22,torso_y+8+b,24,torso_y+10+b),dark)
    if boy:
        # Stitched patch fixed to wearer's right lower front; left waist tally tube.
        if d=='S':
            box(im,(11,30+bob,13,32+bob),4);dot(im,11,30+bob,7);dot(im,13,32+bob,7)
            box(im,(22,29+bob,24,35+bob),15);path(im,[(23,28+bob),(23,33+bob)],19);dot(im,24,28+bob,20)
        elif d=='N':
            box(im,(8,29+bob,10,35+bob),15);path(im,[(9,28+bob),(9,33+bob)],19)
        elif d=='E':
            box(im,(19,29+bob,22,35+bob),15);path(im,[(20,27+bob),(20,33+bob)],19);path(im,[(22,28+bob),(22,31+bob)],20)
        else:
            box(im,(12,31+bob,14,33+bob),4);dot(im,12,31+bob,7)
            path(im,[(19,29+bob),(19,32+bob)],17) # far-side tube mostly occluded
    elif not elder:
        # Left-back folded fan: near on east, far/occluded on west. Right wood seal pouch.
        if d in ('N','E'):
            fx=9 if d=='N' else 20
            path(im,[(fx,25+bob),(fx+1,32+bob)],19,2);dot(im,fx,26+bob,20)
        if d in ('S','W'):
            sx=9 if d=='S' else 12
            box(im,(sx,26+bob,sx+3,30+bob),15);dot(im,sx+1,27+bob,18)
    hc=HC.copy()
    if elder:hc.update({'h':5,'H':7})
    mask(im,10,top+bob,HEADS[d],hc)
    if boy:
        # Cloth band wraps head, with two deliberately placed trailing tie pixels.
        path(im,[(12,top+3+bob),(19,top+3+bob)],17)
        if d=='W':path(im,[(20,top+4+bob),(22,top+6+bob),(21+sway,top+8+bob)],16)
        elif d=='E':path(im,[(12,top+4+bob),(10,top+6+bob),(10+sway,top+8+bob)],16)
        elif d=='N':path(im,[(16,top+4+bob),(18,top+7+bob),(17+sway,top+9+bob)],16)
    elif not elder:
        # Square scholar headcloth replaces topknot, avoiding a generic samurai silhouette.
        mask(im,11,top+bob,['..oooooo..','.oHHHHHHo.','.oHMMMMHo.','.oHHHHHHo.'],{'o':0,'H':4,'M':3})
        if d in ('N','W'):
            tx=19 if d=='W' else 16
            path(im,[(tx,top+7+bob),(tx+1,top+11+bob),(tx+sway,top+14+bob)],4)
            path(im,[(tx+2,top+7+bob),(tx+3,top+10+bob),(tx+2+sway,top+13+bob)],3)
        elif d=='E':path(im,[(12,top+7+bob),(11,top+11+bob),(12+sway,top+13+bob)],3)
    elif d!='N':
        # Age indicated by white temples and compact stubble, not a fabricated long beard.
        if d=='S':path(im,[(14,top+8+bob),(17,top+8+bob)],7);dot(im,13,top+6+bob,5)
        elif d=='W':path(im,[(12,top+8+bob),(14,top+8+bob)],7)
        else:path(im,[(17,top+8+bob),(19,top+8+bob)],7)
    return im

def liu_yingying_actor(d,f):
    """EXP-06 / POR-03, chapter-four green costume decision; one old school hat.
    Explicit short-skirt/leggings thief silhouette, not Xiaoshuang recoloring.
    Anatomical right rope hook and directional ponytail are independently drawn.
    """
    im=Image.new('RGBA',(32,48));contact_shadow(im)
    bob=1 if f in (2,4) else 0
    a,b,sway={0:(0,0,0),1:(-1,1,-2),2:(0,-1,0),3:(1,-1,2),4:(-1,0,0)}[f]
    # One willow hat on the back; near/far edge exposures explicitly specified.
    def hat(back=False):
        if d in ('S','N'):
            outline=[(9,15),(20,14),(25,18),(26,25),(22,31),(12,32),(6,27),(5,21)]
            inner=[(10,16),(20,16),(23,19),(24,25),(21,29),(12,30),(8,26),(7,21)]
            poly(im,[(x,y+bob) for x,y in outline],0)
            poly(im,[(x,y+bob) for x,y in inner],11)
            path(im,[(9,19+bob),(13,17+bob),(20,17+bob),(23,21+bob),(23,26+bob),(20,28+bob),(12,29+bob),(9,26+bob),(8,22+bob),(9,19+bob)],13)
            for pts in [[(10,21),(21,21)],[(9,24),(22,24)],[(12,27),(20,27)],[(13,18),(13,28)],[(17,18),(17,28)],[(20,20),(20,26)]]:
                path(im,[(x,y+bob) for x,y in pts],12)
            poly(im,[(14,20+bob),(18,19+bob),(21,22+bob),(19,25+bob),(14,25+bob),(12,23+bob)],10)
            path(im,[(14,21+bob),(18,20+bob),(20,22+bob)],12)
        elif d=='W':
            poly(im,[(20,15+bob),(25,17+bob),(27,23+bob),(24,30+bob),(20,31+bob),(18,25+bob),(18,19+bob)],0)
            poly(im,[(21,17+bob),(24,19+bob),(25,23+bob),(23,28+bob),(21,29+bob),(20,24+bob)],11)
            path(im,[(23,18+bob),(25,23+bob),(23,28+bob)],13)
            path(im,[(21,21+bob),(24,22+bob),(21,24+bob),(24,25+bob)],12)
        else:
            poly(im,[(10,15+bob),(6,17+bob),(4,23+bob),(6,29+bob),(10,31+bob),(13,26+bob),(13,19+bob)],0)
            poly(im,[(9,17+bob),(7,19+bob),(6,23+bob),(7,27+bob),(10,29+bob),(11,24+bob)],11)
            path(im,[(8,18+bob),(6,23+bob),(8,28+bob)],13)
            path(im,[(10,21+bob),(7,22+bob),(10,24+bob),(7,25+bob)],12)
    hat()
    if d in ('S','N'):
        spread=1 if f in (1,3) else 0
        legs=[(11-spread,a),(18+spread,b)]
    else:
        drift=3 if f==1 else (-3 if f==3 else 0)
        legs=[(12+drift,a),(17-drift,b)]
    for x,step in legs:
        poly(im,[(x,30),(x+3,30),(x+3,41+min(step,0)),(x,42+min(step,0))],2)
        path(im,[(x+1,33),(x+1,39+min(step,0))],4)
        for yy in (36,39):path(im,[(x,yy+min(step,0)),(x+3,yy+min(step,0))],5)
        shoe=x-1 if d!='E' else x
        box(im,(shoe,42+min(step,0),shoe+4,43+min(step,0)),0)
        dot(im,shoe+3,42+min(step,0),11)
    if d in ('S','N'):
        poly(im,[(11,24+bob),(20,24+bob),(25+sway,32),(22,35),(17,32),(12,35),(7+sway,32)],0)
        poly(im,[(12,25+bob),(19,25+bob),(23+sway,31),(21,33),(17,30),(12,33),(9+sway,31)],11)
        path(im,[(14,26+bob),(12+sway,31)],12)
        path(im,[(19,26+bob),(21+sway,31)],10)
        # Angled shoulder, narrow waist, fitted sleeves and exposed glove line.
        rows=['......oooooo......','....ooHHLHHHoo....','...oHHHlLLHHHHo...',
              '..oHHHlLlHHHHHHo..','.oHHHHlHHHHHHHHHo.','.oHMMHHHHHHMMHHHo.',
              '..oMMHHHHHHMMHHo..','..oMMHHHHHHMMHHo..','...ossoBBBBosso...']
        if d=='N':rows=['......oooooo......','....ooHHHHHHoo....','...oHHHHHHHHHHo...',
                        '..oHHHHHHHHHHHHo..','.oHHHHHHHHHHHHHHo.','.oHMMHHHHHHMMHHHo.',
                        '..oMMHHHHHHMMHHo..','..oMMHHHHHHMMHHo..','...ossoBBBBosso...']
        mask(im,7,14+bob,rows,{'o':0,'H':11,'M':10,'L':13,'l':12,'B':25,'s':24})
        path(im,[(11,24+bob),(21,24+bob)],25,2)
        if d=='S':path(im,[(18,25+bob),(19+sway,29+bob),(18+sway,32+bob)],25)
    else:
        poly(im,[(12,24+bob),(20,24+bob),(23-sway,32),(20,35),(16,32),(10-sway,34)],0)
        poly(im,[(13,25+bob),(19,25+bob),(21-sway,31),(20,33),(16,30),(12-sway,32)],11)
        path(im,[(16,26+bob),(15-sway,31)],12)
        mask(im,7,14+bob,TORSO[d],{'o':0,'H':11,'M':10,'L':13,'l':12,'B':25,'s':24})
        path(im,[(13,25+bob),(19,25+bob)],25,2)
    # High collar and neck cord, no physician's pale lapels or medicine box.
    if d=='S':path(im,[(13,14+bob),(16,18+bob),(20,14+bob)],15)
    # Right-hip soft rope loop with steel hook: near in W, concealed in E.
    hx={'S':8,'N':22,'W':11,'E':19}[d]
    if d!='E':
        path(im,[(hx+2,25+bob),(hx,27+bob),(hx,30+bob),(hx+2,31+bob),(hx+4,29+bob),(hx+3,26+bob),(hx+2,25+bob)],15)
        path(im,[(hx+2,26+bob),(hx+1,28+bob),(hx+2,30+bob)],19)
        path(im,[(hx+3,29+bob),(hx+4,31+bob),(hx+2,33+bob),(hx,31+bob)],6)
        dot(im,hx+4,30+bob,8)
    else:path(im,[(hx,26+bob),(hx+1,29+bob)],15)
    if d=='N':hat(True)
    # Face and ponytail, independently placed so there is no horizontal mirroring.
    mask(im,10,4+bob,HEADS[d],HC)
    mask(im,14,2+bob,['.ooo.','ohHho','.oho.'],{'o':0,'h':2,'H':4})
    tail={
      'S':[(20,5),(22,8),(23,13),(21,17)],
      'N':[(17,5),(18,9),(17,14),(19,18)],
      'W':[(19,4),(23,7),(24,11),(22,16)],
      'E':[(13,4),(9,7),(8,12),(10,17)]}[d]
    path(im,[(x+(sway//2 if y>10 else 0),y+bob) for x,y in tail],0,3)
    path(im,[(x+(sway//2 if y>10 else 0),y+bob) for x,y in tail],3)
    # Small jade shuttle in the hair, a sourced signature item (POR-03).
    if d in ('S','W'):path(im,[(12,5+bob),(15,4+bob)],12);dot(im,12,5+bob,13)
    else:path(im,[(17,4+bob),(20,5+bob)],12);dot(im,20,5+bob,13)
    return im

def axue_actor(d,f):
    """POR-06/EXP-10: plain white robe, wood pin low bun, small warm apron.
    Distinct new garment silhouette; no doctor's green dress or thief gear.
    """
    im=Image.new('RGBA',(32,48));contact_shadow(im)
    a,b,sway={0:(0,0,0),1:(-1,1,-1),2:(0,-1,0),3:(1,-1,1),4:(-1,0,0)}[f]
    bob=1 if f in (2,4) else 0;top=5+bob
    for x,step in [(12-a,min(a,0)),(18-b,min(b,0))]:
        box(im,(x,39+step,x+3,43+step),0);path(im,[(x,42+step),(x+2,42+step)],15)
    if d in ('S','N'):
        poly(im,[(11,25+bob),(20,25+bob),(24+sway,39),(20,41),(16,40),(12,41),(8+sway,39)],0)
        poly(im,[(12,26+bob),(19,26+bob),(22+sway,38),(19,39),(16,38),(12,39),(10+sway,38)],7)
        poly(im,[(13,27+bob),(17,27+bob),(18,38),(13,39),(11+sway,38)],8)
        path(im,[(20,29+bob),(21+sway,37)],6)
        rows=['......oooo......','....ooHHHHoo....','...oHHlLLHHHo...',
              '..oHHlLLlHHHHo..','.oHHHlLlHHHHHHo.','.oHMMHlHHHMMHHo.',
              '.oHMMHlHHHMMHHo.','..oMMHlHHHMMHo..','..oMMHlHHHMMHo..',
              '...ossoBBosso...']
        if d=='N':rows=['......oooo......','....ooHHHHoo....','...oHHHHHHHHo...',
                       '..oHHHHHHHHHHo..','.oHHHHHHHHHHHHo.','.oHMMHHHHHMMHHo.',
                       '.oHMMHHHHHMMHHo.','..oMMHHHHHMMHo..','..oMMHHHHHMMHo..',
                       '...ossoBBosso...']
        mask(im,8,14+bob,rows,{'o':0,'H':8,'M':7,'L':8,'l':6,'B':19,'s':24})
        path(im,[(11,25+bob),(21,25+bob)],19)
        if d=='S':
            poly(im,[(12,26+bob),(20,26+bob),(21,35+bob),(19,37+bob),(12,36+bob)],6)
            poly(im,[(13,27+bob),(19,27+bob),(20,35+bob),(18,36+bob),(13,35+bob)],20)
            path(im,[(15,28+bob),(15,34+bob)],19)
            # Forearms low and relaxed; no medicine bottle or martial weapon.
            path(im,[(10,22+a+bob),(11,26+a+bob)],7,2);dot(im,11,27+a+bob,24)
            path(im,[(22,22+b+bob),(21,26+b+bob)],7,2);dot(im,21,27+b+bob,24)
        else:
            path(im,[(16,26+bob),(14+sway,29+bob)],19)
            path(im,[(17,26+bob),(19+sway,29+bob)],19)
    else:
        poly(im,[(13,25+bob),(20,25+bob),(23-sway,39),(19,41),(16,39),(10-sway,39)],0)
        poly(im,[(14,26+bob),(19,26+bob),(21-sway,38),(18,39),(16,37),(12-sway,38)],7)
        path(im,[(15,27+bob),(14-sway,37)],8,2)
        mask(im,7,14+bob,TORSO[d],{'o':0,'H':8,'M':7,'L':8,'l':6,'B':19,'s':24})
        if d=='W':
            poly(im,[(12,27+bob),(15,27+bob),(14,36+bob),(11,36+bob)],20)
            path(im,[(12,27+bob),(12,35+bob)],19)
        else:
            poly(im,[(19,27+bob),(22,27+bob),(22,36+bob),(19,35+bob)],20)
            path(im,[(21,27+bob),(21,35+bob)],19)
    mask(im,10,top,HEADS[d],HC)
    # Modest swept crown instead of high ponytail or paired girl's buns.
    path(im,[(13,top+1),(18,top+1)],2)
    if d=='N':
        mask(im,13,top+7,['.ooo.','ohHho','ohhho','.ooo.'],{'o':0,'h':2,'H':4})
        path(im,[(12,top+8),(19,top+7)],17)
    elif d=='W':
        mask(im,19,top+6,['.oo.','ohho','oHho','.oo.'],{'o':0,'h':2,'H':4})
        path(im,[(19,top+7),(23,top+6)],17)
        dot(im,13,top+5,22)
    elif d=='E':
        mask(im,9,top+6,['.oo.','ohho','oHho','.oo.'],{'o':0,'h':2,'H':4})
        path(im,[(8,top+6),(12,top+7)],17)
    else:
        path(im,[(19,top+6),(22,top+7)],2,2)
        dot(im,21,top+6,17);dot(im,13,top+5,22)
    return im

def liu_carrying_liang_actor(d,f):
    """Chapter-five reversed piggyback: green Liu bears injured brown Liang.
    One grounded carrier, passenger legs folded and hands supported. No standing
    passenger overlay. The school hat is occluded under the carried person.
    """
    im=Image.new('RGBA',(32,48));contact_shadow(im)
    bob=1 if f in (2,4) else 0
    a,b,sway={0:(0,0,0),1:(-1,1,-1),2:(0,-1,0),3:(1,-1,1),4:(-1,0,0)}[f]
    # Shorter bearing stance: carrier crouches under weight, sole anchor unchanged.
    if d in ('S','N'):legs=[(11-(1 if f in (1,3) else 0),a),(18+(1 if f in (1,3) else 0),b)]
    else:
        drift=2 if f==1 else (-2 if f==3 else 0)
        legs=[(12+drift,a),(17-drift,b)]
    for x,step in legs:
        box(im,(x,33,x+3,42+min(step,0)),2)
        path(im,[(x+1,35),(x+1,40+min(step,0))],4)
        path(im,[(x,38+min(step,0)),(x+3,38+min(step,0))],5)
        shoe=x-1 if d!='E' else x
        box(im,(shoe,42+min(step,0),shoe+4,43+min(step,0)),0)
    # Passenger behind carrier in S and sides. N passenger is painted last.
    def passenger():
        if d=='S':
            poly(im,[(13,14+bob),(23,13+bob),(27,21+bob),(23,29+bob),(13,28+bob),(8,22+bob)],0)
            poly(im,[(14,15+bob),(22,14+bob),(25,21+bob),(22,27+bob),(14,26+bob),(10,22+bob)],17)
            mask(im,16,7+bob,HEADS['W'],HC)
            path(im,[(18,13+bob),(19,13+bob)],0)
            path(im,[(18,10+bob),(25,10+bob)],16)
            # Hanging bent knees flank the carrier rather than touch ground.
            path(im,[(12,26+bob),(7,30+bob),(9,36+bob)],0,4)
            path(im,[(12,26+bob),(7,30+bob),(9,34+bob)],3,2)
            path(im,[(22,26+bob),(27,30+bob),(25,36+bob)],0,4)
            path(im,[(22,26+bob),(27,30+bob),(25,34+bob)],3,2)
            path(im,[(8,36+bob),(11,36+bob)],0,2)
            path(im,[(23,36+bob),(26,36+bob)],0,2)
        elif d=='N':
            poly(im,[(10,13+bob),(22,12+bob),(26,18+bob),(24,28+bob),(17,31+bob),(9,28+bob),(6,20+bob)],0)
            poly(im,[(11,14+bob),(21,13+bob),(24,19+bob),(22,27+bob),(17,29+bob),(11,27+bob),(8,20+bob)],17)
            path(im,[(12,16+bob),(12,24+bob)],18)
            path(im,[(20,17+bob),(21,25+bob)],16)
            path(im,[(10,26+bob),(7,31+bob),(10,36+bob)],0,4)
            path(im,[(10,27+bob),(8,31+bob),(10,34+bob)],3,2)
            path(im,[(23,26+bob),(26,31+bob),(23,36+bob)],0,4)
            path(im,[(23,27+bob),(25,31+bob),(23,34+bob)],3,2)
            mask(im,12,6+bob,HEADS['N'],HC)
            path(im,[(14,9+bob),(21,9+bob)],16)
        elif d=='W':
            poly(im,[(20,12+bob),(27,15+bob),(28,23+bob),(23,29+bob),(17,25+bob),(15,18+bob)],0)
            poly(im,[(21,14+bob),(25,16+bob),(26,22+bob),(22,27+bob),(19,24+bob),(17,18+bob)],17)
            path(im,[(23,16+bob),(24,22+bob)],18)
            mask(im,12,6+bob,HEADS['W'],HC)
            path(im,[(14,12+bob),(15,12+bob)],0)
            path(im,[(14,9+bob),(21,9+bob)],16)
            path(im,[(22,26+bob),(17,30+bob),(20,35+bob)],0,4)
            path(im,[(22,26+bob),(18,30+bob),(20,33+bob)],3,2)
            path(im,[(18,35+bob),(22,35+bob)],0,2)
        else:
            poly(im,[(11,12+bob),(5,15+bob),(4,23+bob),(9,29+bob),(15,25+bob),(17,18+bob)],0)
            poly(im,[(10,14+bob),(7,16+bob),(6,22+bob),(10,27+bob),(13,24+bob),(15,18+bob)],17)
            path(im,[(8,16+bob),(7,22+bob)],18)
            mask(im,7,6+bob,HEADS['E'],HC)
            path(im,[(14,12+bob),(15,12+bob)],0)
            path(im,[(10,9+bob),(17,9+bob)],16)
            path(im,[(10,26+bob),(15,30+bob),(12,35+bob)],0,4)
            path(im,[(10,26+bob),(14,30+bob),(12,33+bob)],3,2)
            path(im,[(10,35+bob),(14,35+bob)],0,2)
    if d!='N':passenger()
    # Carrier's body leans and braces; clothing is the existing green thief identity.
    poly(im,[(11,23+bob),(20,23+bob),(23+sway,34),(19,36),(16,33),(12,36),(9+sway,34)],0)
    poly(im,[(12,24+bob),(19,24+bob),(21+sway,33),(19,34),(16,31),(12,34),(11+sway,33)],11)
    path(im,[(13,25+bob),(12+sway,32)],12)
    if d in ('S','N'):
        mask(im,7,21+bob,TORSO[d][:9],{'o':0,'H':11,'M':10,'L':13,'l':12,'B':25,'s':24})
        path(im,[(11,30+bob),(21,30+bob)],25,2)
        mask(im,8 if d=='S' else 7,11+bob,HEADS[d],HC)
        if d=='S':
            path(im,[(10,24+bob),(7,29+bob),(11,31+bob)],10,3)
            path(im,[(22,24+bob),(26,29+bob),(22,31+bob)],10,3)
            dot(im,11,31+bob,24);dot(im,22,31+bob,24)
            # Limp arms drape over shoulders rather than grip a weapon.
            path(im,[(20,20+bob),(13,22+bob),(10,25+bob)],16,3)
            path(im,[(22,20+bob),(23,23+bob),(20,26+bob)],18,2)
            dot(im,10,26+bob,24);dot(im,20,27+bob,24)
            path(im,[(18,13+bob),(20,16+bob),(20,21+bob)],2,2)
            dot(im,10,12+bob,12)
        else:
            passenger()
            mask(im,2,13+bob,HEADS['N'],HC)
            path(im,[(8,27+bob),(10,31+bob)],11,3);dot(im,10,31+bob,24)
            path(im,[(25,27+bob),(23,31+bob)],11,3);dot(im,23,31+bob,24)
            path(im,[(9,12+bob),(7,17+bob),(8,21+bob)],2,2);dot(im,8,12+bob,12)
    elif d=='W':
        mask(im,5,21+bob,TORSO['W'][:9],{'o':0,'H':11,'M':10,'L':13,'l':12,'B':25,'s':24})
        path(im,[(11,30+bob),(18,30+bob)],25,2)
        mask(im,5,11+bob,HEADS['W'],HC)
        path(im,[(17,19+bob),(12,21+bob),(10,25+bob)],16,3);dot(im,10,24+bob,24)
        path(im,[(13,25+bob),(15,30+bob),(20,30+bob)],10,3);dot(im,20,30+bob,24)
        path(im,[(15,13+bob),(18,17+bob),(17,21+bob)],2,2);dot(im,8,12+bob,12)
    else:
        mask(im,9,21+bob,TORSO['E'][:9],{'o':0,'H':11,'M':10,'L':13,'l':12,'B':25,'s':24})
        path(im,[(15,30+bob),(22,30+bob)],25,2)
        mask(im,14,11+bob,HEADS['E'],HC)
        path(im,[(13,19+bob),(20,21+bob),(22,25+bob)],16,3);dot(im,22,24+bob,24)
        path(im,[(20,25+bob),(17,30+bob),(12,30+bob)],10,3);dot(im,12,30+bob,24)
        path(im,[(16,13+bob),(13,17+bob),(14,21+bob)],2,2);dot(im,23,12+bob,12)
    return im

def contact_shadow(im):
    for y,l,r in [(41,11,20),(42,9,22),(43,8,23),(44,8,23),(45,10,21),(46,13,18)]:
        ImageDraw.Draw(im).line((l,y,r,y),fill=PAL[1][:3]+(115,))

def tianji_xiao_actor(d,f):
    """Age 16, SC-02-04: taller lean body, worn blue-grey scholar robe.
    New 40-pixel silhouette, not an enlarged or recolored ten-year-old sprite.
    EXP-01 tally tube stays on anatomical left. No adult sword/baggage.
    """
    im=Image.new('RGBA',(32,48));contact_shadow(im)
    bob=1 if f in (2,4) else 0
    a,b,sway={0:(0,0,0),1:(-1,1,-2),2:(0,-1,0),3:(1,-1,2),4:(-1,0,0)}[f]
    if d in ('S','N'):
        spread=1 if f in (1,3) else 0
        for x,step in [(11-spread,a),(18+spread,b)]:
            box(im,(x,31,x+3,42+min(step,0)),2)
            path(im,[(x+1,33),(x+1,39+min(step,0))],4)
            path(im,[(x,40+min(step,0)),(x+3,40+min(step,0))],6)
            box(im,(x-1,42+min(step,0),x+4,43+min(step,0)),0)
            path(im,[(x,42+min(step,0)),(x+3,42+min(step,0))],15)
        poly(im,[(10,25+bob),(21,25+bob),(25+sway,35),(21,37),(17,34),(13,37),(8+sway,35)],0)
        poly(im,[(11,26+bob),(20,26+bob),(23+sway,34),(21,35),(17,32),(13,35),(10+sway,34)],4)
        path(im,[(13,27+bob),(12+sway,34)],5)
        path(im,[(19,27+bob),(21+sway,34)],3)
        # Fresh authoring: narrow midriff, flared shoulders and sleeve taper.
        torso=['......oooooo......','....ooHHLLHHoo....','...oHHHlLLlHHHo...',
               '..oHHHlLLlHHHHHo..','.oHHHHlLlHHHHHHHo.','.oHMMHHlHHHHMMHHo.',
               '.oHMMHHlHHHHMMHHo.','..oMMHHlHHHHMMHo..','..oMMHHoHHHHMMHo..',
               '..oMMHHoHHHHMMHo..','...ossoBBBBosso...']
        if d=='N':
            torso=['......oooooo......','....ooHHHHHHoo....','...oHHHHHHHHHHo...',
                   '..oHHHHHHHHHHHHo..','.oHHHHHHHHHHHHHHo.','.oHMMHHHHHHHMMHHo.',
                   '.oHMMHHHHHHHMMHHo.','..oMMHHHMHHHMMHo..','..oMMHHHMHHHMMHo..',
                   '..oMMHHHMHHHMMHo..','...ossoBBBBosso...']
        mask(im,7,14+bob,torso,{'o':0,'H':4,'M':3,'L':7,'l':6,'B':15,'s':24})
        path(im,[(11,26+bob),(21,26+bob)],15,2)
        if f:
            path(im,[(9,23+bob+a),(10,26+bob+a)],3,2);dot(im,10,27+bob+a,24)
            path(im,[(22,23+bob+b),(22,26+bob+b)],3,2);dot(im,22,27+bob+b,24)
    else:
        drift=3 if f==1 else (-3 if f==3 else 0)
        for x,step in [(12+drift,a),(17-drift,b)]:
            poly(im,[(x,31),(x+3,31),(x+3,41+min(step,0)),(x,42+min(step,0))],2)
            path(im,[(x+1,33),(x+1,39+min(step,0))],4)
            shoe=x-2 if d=='W' else x
            box(im,(shoe,42+min(step,0),shoe+5,43+min(step,0)),0)
            path(im,[(shoe+1,42+min(step,0)),(shoe+4,42+min(step,0))],15)
        poly(im,[(12,24+bob),(20,24+bob),(23-sway,35),(19,37),(16,34),(10-sway,35)],0)
        poly(im,[(13,25+bob),(19,25+bob),(21-sway,34),(19,35),(16,32),(12-sway,34)],4)
        path(im,[(16,26+bob),(15-sway,33)],5)
        path(im,[(19,27+bob),(20-sway,34)],3)
        mask(im,7,14+bob,TORSO[d],{'o':0,'H':4,'M':3,'L':7,'l':6,'B':15,'s':24})
    # Left hip tube: independent near/far visibility; retained rough cloth patch.
    if d=='S':
        box(im,(22,27+bob,24,34+bob),15);path(im,[(23,26+bob),(23,32+bob)],19);dot(im,24,26+bob,20)
        box(im,(11,31+bob,13,33+bob),3);dot(im,11,31+bob,6)
    elif d=='N':
        box(im,(8,27+bob,10,34+bob),15);path(im,[(9,26+bob),(9,32+bob)],19)
    elif d=='E':
        box(im,(20,27+bob,23,34+bob),15);path(im,[(21,25+bob),(21,32+bob)],19);dot(im,23,26+bob,20)
    else:
        path(im,[(20,27+bob),(20,32+bob)],17);box(im,(12,31+bob,14,33+bob),3)
    mask(im,10,4+bob,HEADS[d],HC)
    path(im,[(12,7+bob),(19,7+bob)],16)
    if d=='W':path(im,[(20,8+bob),(22,11+bob),(21+sway,15+bob)],3)
    elif d=='E':path(im,[(12,8+bob),(10,11+bob),(10+sway,15+bob)],3)
    elif d=='N':path(im,[(16,8+bob),(18,11+bob),(17+sway,15+bob)],3)
    return im

def xiaoshuang_actor(d,f,older=False):
    """Two deliberately different body/wardrobe stages, age 10-11 and age 15.
    Child: double buns, powder ribbons, crossed hands and small porcelain vial.
    Age 15: taller narrow medical skirt, silver hairpin, held wooden medicine box.
    """
    im=Image.new('RGBA',(32,48));contact_shadow(im)
    top=6 if older else 10
    bob=1 if f in (2,4) else 0
    a,b,sway={0:(0,0,0),1:(-1,1,-1),2:(0,-1,0),3:(1,-1,1),4:(-1,0,0)}[f]
    shoulder=top+9+bob;waist=shoulder+7
    # Shoes only; dress length and narrow gentle steps distinguish her from boys.
    for x,step in [(12-a, min(a,0)),(18-b,min(b,0))]:
        box(im,(x,40+step,x+3,43+step),0)
        path(im,[(x,42+step),(x+2,42+step)],6)
    if d in ('S','N'):
        half=8 if older else 7
        poly(im,[(12,waist),(20,waist),(16+half+sway,40),(20,42),(16,41),(12,42),(16-half+sway,40)],0)
        poly(im,[(13,waist),(19,waist),(15+half+sway,39),(19,40),(16,39),(12,40),(17-half+sway,39)],12)
        path(im,[(14,waist+1),(12+sway,39)],13)
        path(im,[(17,waist+1),(17,39)],11)
        path(im,[(19,waist+2),(21+sway,39)],11)
        path(im,[(12+sway,40),(15,40)],7)
        path(im,[(18,40),(21+sway,40)],7)
        rows=['.....oooooo.....','...ooHHLLHHoo...','..oHHHlLLlHHHo..',
              '.oHHHHlLlHHHHHo.','.oHHMHHLHHMHHHo.','..oHMMHLHMMHHo..',
              '..oHHMHLHMHHHo..','...oHHBBBBHHo...']
        if d=='N':rows=['.....oooooo.....','...ooHHHHHHoo...','..oHHHHHHHHHHo..',
                        '.oHHHHHHHHHHHHo.','.oHHMHHHHHMHHHo.','..oHMMHHHMMHHo..',
                        '..oHHMHHHMHHHo..','...oHHBBBBHHo...']
        mask(im,8,shoulder,rows,{'o':0,'H':12,'M':11,'L':8,'l':7,'B':7})
    else:
        poly(im,[(13,waist),(20,waist),(23-sway,40),(19,42),(16,40),(11-sway,40)],0)
        poly(im,[(14,waist),(19,waist),(21-sway,39),(19,40),(16,38),(13-sway,39)],12)
        path(im,[(16,waist+1),(15-sway,39)],13)
        path(im,[(19,waist+1),(20-sway,39)],11)
        path(im,[(13-sway,40),(16,40)],7)
        if d=='W':
            rows=['......oooo.....','....ooHLLHo....','...oHHlLLHHo...',
                  '...oHHlLHHHHo..','...oHHHHMMHHo..','...oHHHMMMHHo..',
                  '....oHHMMHHo...','.....oBBBBHo...']
        else:
            rows=['.....oooo......','....oHLLHoo....','...oHHLLlHHo...',
                  '..oHHHHLlHHHo..','..oHHMMHHHHHo..','..oHHMMMHHHHo..',
                  '...oHHMMHHo....','...oHBBBBo.....']
        mask(im,8,shoulder,rows,{'o':0,'H':12,'M':11,'L':8,'l':7,'B':7})
    # Facial plane retains human proportions; no enlarged Q-style eyes.
    mask(im,10,top+bob,HEADS[d],HC)
    # Cover the male topknot silhouette with a broad swept hair crown.
    path(im,[(14,top+bob),(18,top+bob)],2)
    if not older:
        buns={'S':[(9,top+1),(20,top+1)],'N':[(9,top+1),(20,top+1)],
              'W':[(11,top),(18,top+2)],'E':[(12,top+2),(19,top)]}
        for bx,by in buns[d]:
            mask(im,bx,by+bob,['.oo.','ohho','oHho','.oo.'],{'o':0,'h':2,'H':4})
        ribbons={'S':[(10,top+5),(22,top+5)],'N':[(10,top+5),(22,top+5)],
                 'W':[(20,top+6),(14,top+4)],'E':[(13,top+6),(21,top+4)]}
        for rx,ry in ribbons[d]:path(im,[(rx,ry+bob),(rx+sway,ry+3+bob),(rx,ry+5+bob)],26)
    else:
        # Single low swept bun and wood-lan silver pin, no double childhood buns.
        bx=18 if d in ('N','W') else 11 if d=='E' else 18
        mask(im,bx,top+4+bob,['.ooo.','ohHho','.oho.'],{'o':0,'h':2,'H':4})
        pins={'S':[(19,top+3),(22,top+2)],'N':[(10,top+2),(13,top+3)],
              'W':[(17,top+3),(21,top+2)],'E':[(11,top+3),(13,top+3)]}
        path(im,[(x,y+bob) for x,y in pins[d]],7)
        px,py=pins[d][-1];dot(im,px,py+bob,8)
    # Held item and hands: never visible through the torso in north-facing frames.
    iy=waist-1
    if older:
        if d=='S':
            box(im,(12,iy,21,iy+6),0);box(im,(13,iy+1,20,iy+5),10)
            path(im,[(13,iy+2),(20,iy+2)],13);dot(im,17,iy+3,19)
            path(im,[(10,iy),(12,iy+3)],11,2);dot(im,12,iy+3,24)
            path(im,[(23,iy),(21,iy+3)],11,2);dot(im,21,iy+3,24)
        elif d=='E':
            box(im,(20,iy,26,iy+6),0);box(im,(21,iy+1,25,iy+5),10)
            path(im,[(21,iy+2),(25,iy+2)],13);dot(im,23,iy+3,19)
            path(im,[(17,iy-1),(19,iy+3),(22,iy+4)],11,2);dot(im,22,iy+4,24)
        elif d=='W':
            box(im,(7,iy,13,iy+6),0);box(im,(8,iy+1,12,iy+5),10)
            path(im,[(8,iy+2),(12,iy+2)],13);dot(im,10,iy+3,19)
            path(im,[(17,iy-1),(15,iy+3),(12,iy+4)],11,2);dot(im,12,iy+4,24)
        # N: the held box remains wholly occluded.
    elif d!='N':
        vx=16 if d=='S' else 10 if d=='W' else 23
        box(im,(vx-1,iy-1,vx+1,iy+2),0);box(im,(vx,iy-1,vx+1,iy+1),7);dot(im,vx,iy-2,8)
        if d=='S':
            path(im,[(11,iy-2),(13,iy+1),(15,iy+1)],11,2);dot(im,15,iy+1,24)
            path(im,[(22,iy-2),(20,iy+2),(18,iy+2)],11,2);dot(im,18,iy+2,24)
        elif d=='W':path(im,[(16,iy-2),(14,iy+2),(11,iy+2)],11,2);dot(im,11,iy+2,24)
        else:path(im,[(18,iy-2),(20,iy+2),(23,iy+2)],11,2);dot(im,23,iy+2,24)
    return im

def yuling_actor(d,frame):
    """NPC-01/POR-10: riding clothes, silver fox collar, one gold phoenix pin.
    Purple palette slot revisions require explicit candidate-palette approval.
    Pin on anatomical right is a production choice, not a claimed canonical side.
    """
    im=Image.new('RGBA',(32,48))
    for y,l,r in [(41,11,20),(42,9,22),(43,8,23),(44,8,23),(45,10,21),(46,13,18)]:
        ImageDraw.Draw(im).line((l,y,r,y),fill=PAL[1][:3]+(115,))
    a,b,sway={0:(0,0,0),1:(-1,1,-2),2:(0,-1,0),3:(1,-1,2),4:(-1,0,0)}[frame]
    bob=1 if frame in (2,4) else 0
    # Boot legs and divided riding coat are authored independently from scholars.
    if d in ('S','N'):
        spread=1 if frame in (1,3) else 0
        for x,step in [(11-spread,a),(18+spread,b)]:
            box(im,(x,33,x+3,41+min(step,0)),2)
            path(im,[(x+1,34),(x+1,40+min(step,0))],4)
            box(im,(x-1,42+min(step,0),x+4,43+min(step,0)),0)
            path(im,[(x,42+min(step,0)),(x+3,42+min(step,0))],15)
        poly(im,[(10,24+bob),(21,24+bob),(24+sway,37),(20,38),(16,34),(12,38),(8+sway,37)],0)
        poly(im,[(11,25+bob),(20,25+bob),(22+sway,36),(20,36),(16,32),(12,36),(10+sway,36)],23)
        path(im,[(13,26+bob),(11+sway,35)],26)
        path(im,[(18,26+bob),(20+sway,35)],21)
    else:
        drift=3 if frame==1 else (-3 if frame==3 else 0)
        for x,step in [(12+drift,a),(17-drift,b)]:
            poly(im,[(x,33),(x+3,33),(x+3,41+min(step,0)),(x,42+min(step,0))],2)
            shoe=x-2 if d=='W' else x
            box(im,(shoe,42+min(step,0),shoe+5,43+min(step,0)),0)
            path(im,[(shoe+1,42+min(step,0)),(shoe+4,42+min(step,0))],15)
        poly(im,[(12,24+bob),(20,24+bob),(23-sway,37),(18,38),(15,34),(10-sway,37)],0)
        poly(im,[(13,25+bob),(19,25+bob),(21-sway,36),(18,36),(15,32),(12-sway,35)],23)
        path(im,[(16,26+bob),(15-sway,33)],26)
        path(im,[(19,27+bob),(20-sway,35)],21)
    mask(im,7,13+bob,TORSO[d],{'o':0,'H':23,'M':21,'L':7,'l':8,'B':15,'s':24})
    # Narrow belt with warm metal clasp.
    if d in ('S','N'):path(im,[(11,25+bob),(21,25+bob)],15,2)
    else:path(im,[(13,25+bob),(19,25+bob)],15,2)
    if d!='N':dot(im,16 if d=='S' else 14 if d=='W' else 19,25+bob,19)
    # Chunked silver collar silhouette (hard pixels, no fur noise or smoothing).
    collars={
      'S':[(10,15),(11,14),(13,14),(14,16),(16,17),(18,15),(19,14),(22,15),(23,17),(21,18),(18,17),(16,19),(13,17),(10,18)],
      'N':[(10,15),(12,13),(15,14),(18,13),(21,14),(23,16),(21,18),(18,17),(16,18),(13,17),(10,18)],
      'W':[(12,14),(15,13),(19,15),(20,17),(18,19),(16,17),(13,17),(12,19),(10,17)],
      'E':[(13,15),(16,13),(20,14),(22,17),(20,19),(19,17),(16,18),(14,17)]}
    poly(im,[(x,y+bob) for x,y in collars[d]],7)
    highlights={'S':[[(10,15),(13,15),(16,18)],[(18,16),(20,15),(22,16)]],
                'N':[[(11,15),(14,15)],[(18,15),(21,16)]],
                'W':[[(12,15),(14,14),(16,15)],[(11,17),(12,17)]],
                'E':[[(17,14),(19,15),(21,17)]]}
    for pts in highlights[d]:path(im,[(x,y+bob) for x,y in pts],8)
    # One hand on the waist in idle; alternating close sleeve swing on walk.
    if d=='S':
        if frame==0:
            path(im,[(8,20+bob),(7,24+bob),(11,25+bob)],21,3)
            path(im,[(8,20+bob),(8,23+bob),(11,24+bob)],26)
            dot(im,11,24+bob,24)
        else:
            box(im,(8,22+a+bob,10,25+a+bob),21)
            dot(im,9,26+a+bob,24)
            box(im,(22,22+b+bob,24,25+b+bob),21)
            dot(im,23,26+b+bob,24)
    # Similar facial lineage to Liang Xiao, with arranged dark hair and high bun.
    mask(im,10,4+bob,HEADS[d],HC)
    mask(im,13,2+bob,['.oooo.','ohHhho','.ohho.'],{'o':0,'h':2,'H':4})
    if d=='N':
        mask(im,12,10+bob,['ohhhho','ohHHho','.ohho.'],{'o':0,'h':2,'H':4})
    # Independent asymmetric pin: right side near in W, occluded in E.
    pins={'S':[(10,7),(11,6),(13,7),(14,6)],
          'N':[(18,6),(20,6),(21,5),(22,6)],
          'W':[(13,6),(15,5),(18,6),(20,5)],
          'E':[(13,6),(14,5)]}
    path(im,[(x,y+bob) for x,y in pins[d]],19)
    px,py={'S':(10,6),'N':(22,5),'W':(19,5),'E':(13,5)}[d]
    dot(im,px,py+bob,20)
    return im

def actor_frame(name,d,f):
    if name=='axue_plain_16':return axue_actor(d,f)
    if name=='liu_carrying_liang':return liu_carrying_liang_actor(d,f)
    if name=='liu_yingying_jiangnan_16':return liu_yingying_actor(d,f)
    if name=='liang_xiao_tianji_16':return tianji_xiao_actor(d,f)
    if name=='hua_xiaoshuang_child':return xiaoshuang_actor(d,f,False)
    if name=='hua_xiaoshuang_tianji_15':return xiaoshuang_actor(d,f,True)
    if name=='xiao_yuling':return yuling_actor(d,f)
    if name.endswith('carrying_xiao'):return carry_actor(d,f)
    return actor(name,d,f)

def carry_actor(d,frame):
    """Father supports the same ten-year-old boy seated against his left hip.
    Child has original ten-pixel head, folded legs, and shoulder-holding arm;
    this is neither an infant scaled down nor a second ground-standing actor.
    """
    im=actor('liang_wenjing',d,frame)
    bob=1 if frame in (2,4) else 0
    if d=='S':
        mask(im,19,11+bob,HEADS['S'],HC)
        path(im,[(21,14+bob),(28,14+bob)],17)
        poly(im,[(21,21+bob),(28,21+bob),(29,29+bob),(24,32+bob),(19,29+bob)],0)
        poly(im,[(22,21+bob),(27,22+bob),(27,29+bob),(23,30+bob),(20,28+bob)],18)
        path(im,[(22,23+bob),(20,25+bob),(17,23+bob)],19,2)
        dot(im,17,22+bob,24)
        path(im,[(25,29+bob),(27,33+bob),(22,35+bob)],3,3)
        path(im,[(23,30+bob),(23,34+bob),(18,35+bob)],4,2)
        box(im,(17,35+bob,20,36+bob),0);box(im,(21,35+bob,24,36+bob),0)
        # Father's left forearm is on top, beneath child's seat and thighs.
        path(im,[(22,25+bob),(25,30+bob),(21,32+bob),(18,31+bob)],10,3)
        path(im,[(24,30+bob),(21,31+bob),(19,31+bob)],12,2);dot(im,18,31+bob,24)
    elif d=='N':
        mask(im,1,11+bob,HEADS['N'],HC)
        path(im,[(3,14+bob),(10,14+bob)],17)
        poly(im,[(4,21+bob),(10,21+bob),(13,27+bob),(10,31+bob),(3,30+bob),(1,24+bob)],0)
        poly(im,[(4,22+bob),(9,22+bob),(11,27+bob),(9,30+bob),(4,29+bob),(3,24+bob)],18)
        path(im,[(8,23+bob),(11,23+bob),(13,20+bob)],19,2);dot(im,13,20+bob,24)
        path(im,[(5,29+bob),(3,33+bob),(7,35+bob)],3,3)
        box(im,(6,35+bob,10,36+bob),0)
        path(im,[(9,25+bob),(6,29+bob),(11,31+bob)],10,3)
        path(im,[(7,29+bob),(10,30+bob)],12,2);dot(im,11,30+bob,24)
    elif d=='E':
        mask(im,18,11+bob,HEADS['E'],HC)
        path(im,[(21,14+bob),(28,14+bob)],17)
        poly(im,[(20,21+bob),(26,21+bob),(28,28+bob),(25,31+bob),(18,29+bob)],0)
        poly(im,[(21,22+bob),(25,22+bob),(26,28+bob),(24,30+bob),(20,28+bob)],18)
        path(im,[(21,23+bob),(18,23+bob),(17,20+bob)],19,2);dot(im,17,20+bob,24)
        path(im,[(23,29+bob),(28,32+bob),(26,36+bob)],3,3)
        path(im,[(21,29+bob),(25,32+bob),(23,36+bob)],4,2)
        box(im,(23,36+bob,27,37+bob),0)
        path(im,[(17,25+bob),(18,30+bob),(24,32+bob)],10,3)
        path(im,[(18,29+bob),(22,31+bob)],12,2);dot(im,24,32+bob,24)
    else:
        # Far-side child partly hidden by father's sleeve; distinct E/W drawing.
        mask(im,1,11+bob,HEADS['W'],HC)
        path(im,[(3,14+bob),(10,14+bob)],17)
        poly(im,[(4,21+bob),(10,21+bob),(13,27+bob),(10,31+bob),(3,28+bob)],0)
        poly(im,[(4,22+bob),(9,22+bob),(11,27+bob),(9,30+bob),(4,27+bob)],18)
        path(im,[(6,29+bob),(3,32+bob),(5,35+bob)],3,3);box(im,(2,35+bob,6,36+bob),0)
        path(im,[(10,24+bob),(11,29+bob),(6,31+bob)],10,4)
        path(im,[(10,25+bob),(10,28+bob),(7,30+bob)],12,2);dot(im,6,31+bob,24)
        path(im,[(9,23+bob),(13,23+bob),(14,20+bob)],19,2);dot(im,14,20+bob,24)
    return im

# Each terrain cluster is intentionally positioned, no noise/fractal generator.
def tile(kind):
    im=Image.new('RGBA',(32,32))
    if kind=='rock_strata':
        box(im,(0,0,31,31),3)
        poly(im,[(0,0),(31,0),(31,7),(23,6),(19,9),(0,9)],4)
        path(im,[(0,8),(13,8),(17,6),(29,6),(31,7)],5)
        poly(im,[(0,12),(8,11),(17,13),(31,11),(31,18),(24,20),(9,19),(0,21)],2)
        path(im,[(0,12),(8,11),(17,13),(31,11)],4)
        poly(im,[(0,25),(12,23),(20,25),(31,23),(31,31),(0,31)],4)
        path(im,[(1,25),(12,23),(20,25),(31,23)],5)
        path(im,[(22,0),(20,5),(22,7),(20,12)],2)
        path(im,[(7,19),(9,22),(7,26),(8,31)],1)
        for x,y in [(2,10),(3,10),(4,11),(26,21),(28,21)]:dot(im,x,y,10)
    elif kind=='rock_slab':
        box(im,(0,0,31,31),2)
        poly(im,[(0,0),(26,0),(29,4),(28,17),(23,22),(0,21)],4)
        poly(im,[(0,0),(26,0),(27,3),(20,4),(7,3),(0,5)],5)
        path(im,[(2,15),(10,14),(17,16),(22,13)],3)
        path(im,[(27,6),(25,10),(26,14),(22,18),(15,19)],1)
        poly(im,[(0,25),(7,23),(19,25),(22,31),(0,31)],3)
        path(im,[(0,25),(7,23),(14,25)],5)
        for x,y in [(2,20),(3,21),(5,20),(18,4),(19,4)]:dot(im,x,y,10)
    elif kind in ('cliff_edge','cliff_edge_b','cliff_edge_c'):
        box(im,(0,0,31,31),1)
        poly(im,[(0,0),(31,0),(31,8),(26,11),(20,10),(15,14),(5,12),(0,15)],4)
        poly(im,[(0,0),(31,0),(31,4),(24,6),(18,4),(10,8),(0,6)],10)
        path(im,[(0,9),(6,8),(13,10),(20,7),(26,8),(31,6)],5)
        poly(im,[(4,13),(12,15),(13,28),(8,31),(5,24)],3)
        poly(im,[(19,13),(25,12),(23,23),(19,26)],2)
        path(im,[(6,14),(7,22),(9,24)],4)
        path(im,[(24,13),(23,19)],4)
        for x,y in [(3,3),(12,5),(26,3)]:path(im,[(x-1,y+1),(x,y-1),(x+2,y)],11)
        if kind=='cliff_edge_b':
            box(im,(0,11,31,31),1)
            poly(im,[(0,10),(9,12),(17,10),(27,12),(31,10),(31,17),(24,20),(11,18),(5,22),(0,20)],3)
            path(im,[(0,10),(9,12),(17,10),(27,12),(31,10)],5)
            path(im,[(17,13),(15,18),(16,24),(12,31)],2)
        elif kind=='cliff_edge_c':
            box(im,(0,11,31,31),1)
            poly(im,[(0,10),(8,11),(12,10),(14,16),(13,24),(7,28),(0,26)],3)
            poly(im,[(17,11),(25,10),(31,11),(31,27),(24,31),(20,24)],2)
            path(im,[(0,10),(8,11),(12,10)],5)
            path(im,[(21,14),(22,22),(24,24)],4)
    elif kind.startswith('rock'):
        box(im,(0,0,31,31),2)
        poly(im,[(0,4),(9,0),(24,0),(31,7),(30,19),(23,23),(5,22),(0,16)],4)
        poly(im,[(0,4),(9,0),(24,0),(27,4),(13,3),(7,6)],5)
        poly(im,[(6,9),(19,6),(27,8),(23,12),(11,12)],3)
        poly(im,[(0,24),(8,22),(19,26),(18,31),(0,31)],3)
        path(im,[(1,17),(7,18),(12,16)],5);path(im,[(26,16),(23,20),(15,21)],2)
        path(im,[(20,0),(18,3),(19,5)],2);path(im,[(30,25),(25,26),(22,31)],1)
        for x,y in [(3,7),(4,8),(7,8),(25,20),(24,21),(26,22),(1,28),(3,29)]:dot(im,x,y,10)
        if kind=='rock_b':path(im,[(5,0),(8,8),(6,14),(10,19),(9,31)],1)
    elif kind.startswith('grass'):
        box(im,(0,0,31,31),10)
        poly(im,[(0,2),(12,1),(16,6),(28,7),(31,14),(22,17),(14,14),(7,19),(0,17)],9)
        poly(im,[(3,23),(10,20),(20,24),(31,22),(31,31),(14,29),(5,31)],11)
        for x,y in [(2,5),(12,3),(21,7),(28,3),(7,14),(18,16),(27,20),(3,26),(14,26),(23,30)]:
            path(im,[(x-1,y+1),(x,y-2),(x,y+1),(x+2,y-1)],11)
            dot(im,x,y-2,12)
        for x,y in [(5,8),(16,9),(23,12),(10,22),(29,27)]:path(im,[(x,y),(x+2,y)],10)
        if kind=='grass_b':
            for x,y in [(7,6),(23,24)]:path(im,[(x,y+3),(x+1,y)],12);dot(im,x+1,y,19)
    elif kind.startswith('earth'):
        box(im,(0,0,31,31),17)
        poly(im,[(0,0),(12,0),(9,6),(13,11),(8,17),(9,24),(4,31),(0,31)],16)
        poly(im,[(19,0),(23,0),(21,10),(25,16),(23,23),(25,31),(19,31),(20,22),(17,14)],18)
        for points in [[(2,8),(6,8),(8,9)],[(15,5),(18,4)],[(10,19),(15,19),(17,18)],[(25,7),(29,8)],[(27,24),(31,24)],[(5,28),(10,27)]]:path(im,points,16)
        for x,y in [(4,16),(26,15),(13,29),(29,4)]:
            box(im,(x,y,x+2,y+1),15);path(im,[(x,y),(x+1,y)],19)
        if kind=='earth_edge':
            poly(im,[(0,0),(7,0),(5,5),(8,9),(4,12),(7,18),(3,21),(5,28),(7,31),(0,31)],10)
            for x,y in [(5,4),(3,13),(4,24)]:path(im,[(x-1,y+1),(x,y-2),(x+1,y)],12)
    elif kind.startswith('boardwalk'):
        box(im,(0,0,31,31),14)
        # Four irregular width boards laid north-south, tileable at y edges.
        for l,r,col in [(0,6,17),(8,15,16),(17,23,17),(25,31,16)]:
            box(im,(l,0,r,31),col);path(im,[(l,0),(l,31)],18);path(im,[(r,0),(r,31)],15)
        for pts in [[(3,0),(3,7),(4,9),(4,16)],[(11,2),(10,5),(10,14)],[(20,12),(20,22),(21,25),(21,31)],[(28,0),(28,10)],[(29,18),(28,21),(28,31)]]:path(im,pts,15)
        for y in (5,26):
            for x in (3,11,20,28):dot(im,x,y,1);dot(im,x+1,y+1,18)
        path(im,[(10,18),(12,17),(13,19),(12,21),(10,20),(10,18)],15)
        dot(im,11,19,14)
        if kind=='boardwalk_worn':
            poly(im,[(18,0),(20,0),(19,4),(20,8),(18,6)],14)
            path(im,[(27,15),(29,14),(31,15)],19)
    elif kind.startswith('bamboo'):
        # Transparent foreground fence; bottom anchor 16,31.
        for x in (3,14,26):
            poly(im,[(x,4),(x+2,2),(x+4,4),(x+4,30),(x,30)],9)
            box(im,(x+1,5,x+3,29),11);path(im,[(x+1,5),(x+1,28)],13)
            for y in (9,19,28):path(im,[(x,y),(x+4,y)],9);path(im,[(x+1,y+1),(x+3,y+1)],12)
        for y in (12,23):
            box(im,(0,y,31,y+2),9);path(im,[(0,y),(31,y)],12);path(im,[(0,y+1),(31,y+1)],11)
            for x in (3,14,26):
                path(im,[(x,y-1),(x+3,y+3)],17);path(im,[(x+3,y-1),(x,y+3)],19)
        if kind=='bamboo_end':
            poly(im,[(0,0),(12,0),(12,31),(0,31)],0)
            # clear left side for end post, preserving transparency
            ImageDraw.Draw(im).rectangle((0,0,12,31),fill=(0,0,0,0))
    return im

def main():
    dirs=['S','N','W','E']; names=['liang_xiao_young','liang_wenjing','liang_tiande','liang_wenjing_carrying_xiao','xiao_yuling','liang_xiao_tianji_16','hua_xiaoshuang_child','hua_xiaoshuang_tianji_15','liu_yingying_jiangnan_16','axue_plain_16','liu_carrying_liang']
    meta={'status':'candidate_pending_art_review','palette':'pal01_candidate.json','cell':[32,48],
          'origin':[16,44],'filter':'nearest','mipmaps':False,'directions':dirs,'actors':{},
          'not_final':['4 walk frames vs V3 final 6; 1 idle vs final 2; interactions not supplied',
                       'Liang Tiande outfit details are interpretation from module 02, not locked module 08 model',
                       '28-color PAL-01 candidate extends six explicitly specified design colors']}
    sheet=Image.new('RGBA',(160,192))
    contact=Image.new('RGBA',(len(names)*192,228),(30,38,43,255)); cd=ImageDraw.Draw(contact)
    allframes=[]
    for ni,name in enumerate(names):
        sheet=Image.new('RGBA',(160,192)); frames=[]
        for di,d in enumerate(dirs):
            for f in range(5):
                im=actor_frame(name,d,f);sheet.alpha_composite(im,(f*32,di*48));allframes.append(im)
                frames.append({'id':f'{d}_{"idle" if f==0 else "walk_"+str(f)}','rect':[f*32,di*48,32,48],
                               'origin':[16,44],'duration_ms':480 if f==0 else 120,'facing':d,'state':'idle' if f==0 else 'walk'})
        sheet.save(OUT/(name+'.png'))
        meta['actors'][name]={'texture':name+'.png','frames':frames,'source_mapping':'EXP-01' if ni==0 else 'EXP-09' if ni==1 else ('chapter_01_pursuit_carry_candidate' if ni==3 else ('NPC-01/POR-10' if name=='xiao_yuling' else 'module_02_SC-00-01'))}
        if name.startswith('hua_xiaoshuang') or name=='liang_xiao_tianji_16':
            meta['actors'][name]['source_mapping']={'liang_xiao_tianji_16':'V3 module02 SC-02-04 / EXP-01 / POR-01','hua_xiaoshuang_child':'V3 module02 SC-02-01/03 / EXP-04 / POR-02','hua_xiaoshuang_tianji_15':'V3 module02 SC-02-04 / POR-02 / EXP-05'}[name]
            meta['actors'][name]['age_coverage']={'liang_xiao_tianji_16':[16,16],'hua_xiaoshuang_child':[10,11],'hua_xiaoshuang_tianji_15':[15,15]}[name]
        if name=='liu_yingying_jiangnan_16':
            meta['actors'][name].update({'source_mapping':'EXP-06 / POR-03 / chapter-four-content green-costume and unique-school-hat decision','age_coverage':[16,16],'hat_variant':'intact_school_hat_only','hat_count':1,'not_included':['damaged or repaired visual states','separate newly woven small gift hat','mounted poses']})
        if name=='axue_plain_16':
            meta['actors'][name].update({'source_mapping':'V3 POR-06/EXP-10 and chapter-five contracts','canonical_character':'char_axue','age_coverage':[16,16],'garment':'plain white with pale blue-grey shadows, wood pin low bun, small apron','status':'candidate_not_final'})
        if name=='liu_carrying_liang':
            meta['actors'][name].update({'source_mapping':'chapter-five B03 escape and root/world carrying direction agreement','carrier':'char_liu_yingying','passenger':'char_liang_xiao','carrier_clothes':'green','passenger_clothes':'brown','ground_contact':'carrier_only','collision_policy':'keep carrier existing feet collision unchanged','hat':'single school hat occluded by carried passenger; no ownership/state mutation','status':'candidate_not_final','not_included':['Axue carrying Liang','lifting and set-down transition animation']})
        cd.text((ni*192+4,4),name,fill=PAL[8])
        for di,d in enumerate(dirs):cd.text((ni*192+2,24+di*48),d,fill=PAL[7])
        contact.alpha_composite(sheet,(ni*192+20,24))
    contact.save(PRE/'actors_contact_1x.png');contact.resize((contact.width*4,contact.height*4),Image.Resampling.NEAREST).save(PRE/'actors_contact_4x.png')
    kinds=['rock_a','rock_b','grass_a','grass_b','earth_a','earth_edge','boardwalk_a','boardwalk_worn','bamboo_a','bamboo_end','rock_strata','rock_slab','cliff_edge','cliff_edge_b','cliff_edge_c']
    atlas=Image.new('RGBA',(32*5,96)); tmeta=[]
    tiles={}
    for i,k in enumerate(kinds):
        im=tile(k);tiles[k]=im;atlas.alpha_composite(im,((i%5)*32,(i//5)*32))
        tmeta.append({'id':k,'rect':[(i%5)*32,(i//5)*32,32,32],'origin':[16,31] if k.startswith('bamboo') else [0,0],
                      'layer':'L3_YSort_World' if k.startswith('bamboo') else 'L1_Ground_Base'})
    atlas.save(OUT/'pal01_tiles.png');meta['tiles']={'texture':'pal01_tiles.png','cell':[32,32],'entries':tmeta}
    tc=Image.new('RGBA',(480,156),PAL[1]);td=ImageDraw.Draw(tc)
    for i,k in enumerate(kinds):
        x=(i%5)*96;y=(i//5)*52;td.text((x+1,y+1),k,fill=PAL[8]);tc.alpha_composite(tiles[k],(x+32,y+17))
    tc.save(PRE/'tiles_contact_1x.png');tc.resize((1920,624),Image.Resampling.NEAREST).save(PRE/'tiles_contact_4x.png')
    # Context composition only, not runtime map replacement or new scene canon.
    scene=Image.new('RGBA',(320,180),PAL[1])
    for y in range(0,180,32):
        for x in range(0,320,32):
            rocks=['rock_strata','rock_slab','rock_b','rock_strata','rock_a','rock_slab','rock_strata','rock_slab','rock_b','rock_strata']
            k=rocks[(x//32+3*(y//32))%len(rocks)] if y<64 or y>=128 else ('boardwalk_a' if x%64==0 else 'boardwalk_worn')
            if y==0 and x<128:k='grass_a' if x<96 else 'earth_edge'
            if y==32:k=['cliff_edge_b','cliff_edge','cliff_edge_c','cliff_edge_b','cliff_edge_c'][x//32%5]
            if y==128:k=['cliff_edge_c','cliff_edge_b','cliff_edge','cliff_edge_b','cliff_edge_c'][x//32%5]
            scene.alpha_composite(tiles[k],(x,y))
    for x in range(0,320,32):scene.alpha_composite(tiles['bamboo_a'],(x,40))
    for i,n in enumerate(names[:3]):scene.alpha_composite(actor(n,'S',0),(100+i*44,72))
    scene.save(PRE/'context_1x.png');scene.resize((1280,720),Image.Resampling.NEAREST).save(PRE/'context_4x.png')
    meta['chapter_two_stage_notes']={
        'early_liang_xiao':{'texture':'liang_xiao_young.png','age_coverage':[11,12],'status':'temporary_reuse_of_existing_age10_body','source':'module02 first meeting and teaching scenes'},
        'early_hua_xiaoshuang':{'texture':'hua_xiaoshuang_child.png','age_coverage':[10,11],'source':'EXP-04 / module02 first meeting and teaching scenes'},
        'fifth_year_liang_xiao':{'texture':'liang_xiao_tianji_16.png','age_coverage':[16,16],'source':'module02 SC-02-04 blue robe overrides generic EXP-01 coarse-cloth color'},
        'fifth_year_hua_xiaoshuang':{'texture':'hua_xiaoshuang_tianji_15.png','age_coverage':[15,15],'source':'module02 SC-02-04 held medicine box and POR-02 teen medical dress'}}
    from build_yanzhi_candidate import build_yanzhi
    meta['mounts']=build_yanzhi(OUT,PRE,PAL)
    (OUT/'frames.json').write_text(json.dumps(meta,ensure_ascii=False,indent=2)+'\n')
    (OUT/'pal01_candidate.json').write_text(json.dumps({'status':'candidate_not_canonical_complete_palette','design_keys':['#1E262B','#4A5A60','#8C7355','#5B8258','#E87A35','#DCE6E8'],'colors':['#'+x for x in HEX],'shadow_alpha':115,'revision':'2026-10-14_yingying_vermilion_support','revised_unused_slots':{'21':{'old':'#72554B','new':'#493C4F'},'23':{'old':'#BD9777','new':'#71576E'},'26':{'old':'#A45435','new':'#997487'},'25':{'old':'#EDD3AD','new':'#B95349'}},'revision_note':'Parent approved unused support slot replacement; six design keys and all previous PNG pixels remain unchanged.'},indent=2)+'\n')
    (OUT/'pal01_candidate.gpl').write_text('GIMP Palette\nName: Kunlun PAL-01 candidate (not final)\nColumns: 7\n#\n'+''.join(f'{r:3d} {g:3d} {b:3d}  color_{i:02d}\n' for i,(r,g,b,a) in enumerate(PAL)))
    checks={'actor_count':len(names),'actor_frames':len(allframes),'tiles':len(kinds),'palette_colors':len(PAL),
            'binary_alpha_except_documented_shadow':True,'out_of_palette_pixels':0,'noninteger_coordinates':0,
            'distinct_walk_frames':{},'source_sha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest()}
    allowed=set(PAL)|{(0,0,0,0),PAL[1][:3]+(115,)}
    for name in names:
        for d in dirs:
            fs=[actor_frame(name,d,f) for f in range(1,5)]
            assert len({im.tobytes() for im in fs})==4
            checks['distinct_walk_frames'][name+'_'+d]=4
    for fp in OUT.glob('*.png'):
        im=Image.open(fp).convert('RGBA'); bad=set(im.getdata())-allowed
        assert not bad,(fp,bad)
    for name,data in meta['actors'].items():
        assert Image.open(OUT/data['texture']).size==(160,192)
        for f in data['frames']:
            x,y,w,h=f['rect'];assert x>=0 and y>=0 and x+w<=160 and y+h<=192
            assert f['origin']==[16,44] and (w,h)==(32,48)
    for t in tmeta:
        x,y,w,h=t['rect'];assert x>=0 and y>=0 and x+w<=atlas.width and y+h<=atlas.height
    for mount in meta['mounts'].values():
        mi=Image.open(OUT/mount['texture'])
        for f in mount['frames']:
            x,y,w,h=f['rect'];assert x>=0 and y>=0 and x+w<=mi.width and y+h<=mi.height
            assert f['origin']==[32,58] and (w,h)==(64,64)
    for mount in meta['mounts'].values():
        layer=mount.get('seated_rider_layer',{})
        if layer:
            li=Image.open(OUT/layer['texture'])
            assert li.size==(320,256)
            legacy=Image.open(OUT/'horse_yanzhi_riders_side.png').convert('RGBA')
            assert li.crop((0,128,320,256)).tobytes()==legacy.tobytes()
            for f in layer['frames']:
                x,y,w,h=f['rect'];assert x>=0 and y>=0 and x+w<=li.width and y+h<=li.height
                assert f['origin']==[32,58] and (w,h)==(64,64)
    checks['seated_rider_frames']=sum(len(m.get('seated_rider_layer',{}).get('frames',[])) for m in meta['mounts'].values())
    checks['mount_frames']=sum(len(m['frames']) for m in meta['mounts'].values())
    checks['frame_bounds_validated']=True
    # Focused carry review sheet for full-size inspection.
    focus=Image.new('RGBA',(180,212),PAL[1])
    focus.alpha_composite(Image.open(OUT/'liang_wenjing_carrying_xiao.png'),(10,10))
    focus.save(PRE/'carrying_contact_1x.png')
    focus.resize((720,848),Image.Resampling.NEAREST).save(PRE/'carrying_contact_4x.png')
    focus=Image.new('RGBA',(180,212),PAL[1])
    focus.alpha_composite(Image.open(OUT/'xiao_yuling.png'),(10,10))
    focus.save(PRE/'xiao_yuling_contact_1x.png')
    focus.resize((720,848),Image.Resampling.NEAREST).save(PRE/'xiao_yuling_contact_4x.png')
    chapter_contact=Image.new('RGBA',(3*180,212),PAL[1])
    for ci,cn in enumerate(['liang_xiao_tianji_16','hua_xiaoshuang_child','hua_xiaoshuang_tianji_15']):
        focus=Image.new('RGBA',(180,212),PAL[1])
        focus.alpha_composite(Image.open(OUT/(cn+'.png')),(10,10))
        focus.save(PRE/(cn+'_contact_1x.png'))
        focus.resize((720,848),Image.Resampling.NEAREST).save(PRE/(cn+'_contact_4x.png'))
        chapter_contact.alpha_composite(focus,(180*ci,0))
    chapter_contact.save(PRE/'chapter_two_contact_1x.png')
    chapter_contact.resize((2160,848),Image.Resampling.NEAREST).save(PRE/'chapter_two_contact_4x.png')
    focus=Image.new('RGBA',(180,212),PAL[1])
    focus.alpha_composite(Image.open(OUT/'liu_yingying_jiangnan_16.png'),(10,10))
    focus.save(PRE/'liu_yingying_contact_1x.png')
    focus.resize((720,848),Image.Resampling.NEAREST).save(PRE/'liu_yingying_contact_4x.png')
    ch5=Image.new('RGBA',(360,212),PAL[1])
    for i,n in enumerate(['axue_plain_16','liu_carrying_liang']):
        focus=Image.new('RGBA',(180,212),PAL[1]);focus.alpha_composite(Image.open(OUT/(n+'.png')),(10,10))
        focus.save(PRE/(n+'_contact_1x.png'))
        focus.resize((720,848),Image.Resampling.NEAREST).save(PRE/(n+'_contact_4x.png'))
        ch5.alpha_composite(focus,(i*180,0))
    ch5.save(PRE/'chapter_five_contact_1x.png')
    ch5.resize((1440,848),Image.Resampling.NEAREST).save(PRE/'chapter_five_contact_4x.png')
    (PRE/'checks.json').write_text(json.dumps(checks,indent=2)+'\n')
    print(json.dumps(checks,indent=2))
if __name__=='__main__':main()
