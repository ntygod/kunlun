"""Original explicit-grid Yanzhi horse candidate; no images/models/mirroring.
Build is called by build_pixel_candidates.py and shares its approved 28 colors.
Horse alone is NOT evidence that mounted actors have been implemented.
"""
from PIL import Image, ImageDraw
import hashlib
from pathlib import Path

def build_yanzhi(out,pre,pal):
    def draw(d,f):
        im=Image.new('RGBA',(64,64));pen=ImageDraw.Draw(im)
        def poly(points,c):
            assert all(isinstance(v,int) for p in points for v in p)
            pen.polygon(points,fill=pal[c])
        def line(points,c,width=1):
            assert all(isinstance(v,int) for p in points for v in p)
            pen.line(points,fill=pal[c],width=width)
        def box(xy,c):
            assert all(isinstance(v,int) for v in xy)
            pen.rectangle(xy,fill=pal[c])
        for y,l,r in [(54,17,46),(55,10,53),(56,7,56),(57,7,56),(58,10,53),(59,17,46)]:
            pen.line((l,y,r,y),fill=pal[1][:3]+(115,))
        bob=1 if f in (2,4) else 0
        a,b={0:(0,0),1:(-3,3),2:(-1,1),3:(3,-3),4:(1,-1)}[f]
        if d in ('W','E'):
            # Far pair, then torso, then near pair. Legs flex at two joints.
            xfore,xhind=(22,46) if d=='W' else (43,19)
            for x,off in [(xfore+2,b),(xhind-2,a)]:
                line([(x,39+bob),(x+off,48),(x-off//2,55)],5,3)
                box((x-off//2-2,55,x-off//2+2,57),1)
            if d=='W':
                poly([(19,31+bob),(27,27+bob),(45,27+bob),(52,31+bob),(53,40+bob),(48,45+bob),(28,44+bob),(20,40+bob)],1)
                poly([(20,32+bob),(28,28+bob),(44,28+bob),(50,32+bob),(51,39+bob),(47,43+bob),(29,42+bob),(21,39+bob)],7)
                poly([(22,32+bob),(28,29+bob),(43,29+bob),(48,32+bob),(45,35+bob),(29,35+bob)],8)
                poly([(17,22+bob),(22,23+bob),(28,34+bob),(23,40+bob),(17,34+bob),(12,30+bob)],1)
                poly([(17,23+bob),(21,24+bob),(26,34+bob),(23,37+bob),(18,32+bob),(14,29+bob)],7)
                poly([(10,17+bob),(16,17+bob),(19,22+bob),(15,28+bob),(11,32+bob),(5,33+bob),(3,29+bob),(7,25+bob)],1)
                poly([(10,19+bob),(15,18+bob),(17,22+bob),(13,27+bob),(10,30+bob),(5,31+bob),(5,29+bob),(9,25+bob)],8)
                poly([(12,18+bob),(12,12+bob),(15,14+bob),(16,19+bob)],1)
                line([(14,14+bob),(14,17+bob)],7)
                line([(16,20+bob),(19,26+bob),(22,30+bob)],2,3)
                box((10,22+bob,11,23+bob),0)
                line([(5,29+bob),(8,30+bob)],5)
                line([(9,25+bob),(15,27+bob)],15)
                line([(14,27+bob),(26,29+bob)],15)
                poly([(20,27+bob),(23,28+bob),(25,32+bob),(22,35+bob),(19,32+bob)],25)
                poly([(43,29+bob),(48,31+bob),(49,36+bob),(46,38+bob),(42,35+bob)],25)
                line([(52,31+bob),(56,37+bob),(55+a//2,46),(58+a//2,51)],2,3)
            else:
                poly([(12,31+bob),(19,27+bob),(37,27+bob),(45,31+bob),(46,40+bob),(39,45+bob),(18,44+bob),(11,39+bob)],1)
                poly([(14,32+bob),(20,28+bob),(36,28+bob),(43,32+bob),(44,39+bob),(38,43+bob),(19,42+bob),(13,38+bob)],7)
                poly([(17,32+bob),(21,29+bob),(35,29+bob),(41,32+bob),(35,35+bob),(20,35+bob)],8)
                poly([(46,22+bob),(51,21+bob),(53,30+bob),(48,35+bob),(43,40+bob),(38,34+bob)],1)
                poly([(47,23+bob),(50,23+bob),(51,29+bob),(47,33+bob),(43,37+bob),(40,34+bob)],7)
                poly([(48,18+bob),(53,16+bob),(57,20+bob),(57,24+bob),(61,28+bob),(60,32+bob),(55,33+bob),(50,28+bob),(46,23+bob)],1)
                poly([(49,19+bob),(53,18+bob),(55,21+bob),(55,25+bob),(59,29+bob),(59,31+bob),(55,31+bob),(51,27+bob),(48,23+bob)],8)
                poly([(48,19+bob),(49,13+bob),(52,12+bob),(51,19+bob)],1)
                line([(50,14+bob),(50,17+bob)],7)
                line([(47,20+bob),(45,26+bob),(42,30+bob)],2,3)
                box((53,22+bob,54,23+bob),0)
                line([(57,29+bob),(59,29+bob)],5)
                line([(51,27+bob),(57,25+bob)],15)
                line([(51,27+bob),(37,29+bob)],15)
                poly([(17,29+bob),(22,29+bob),(24,33+bob),(21,36+bob),(17,34+bob)],25)
                poly([(39,33+bob),(42,34+bob),(43,38+bob),(39,40+bob),(37,37+bob)],25)
                line([(12,31+bob),(8,37+bob),(9-a//2,46),(6-a//2,51)],2,3)
            # One saddle spans front/rear seats, with visible girth.
            poly([(25,28+bob),(35,28+bob),(40,32+bob),(38,36+bob),(25,36+bob),(22,32+bob)],14)
            line([(25,29+bob),(35,29+bob),(38,32+bob)],18,2)
            line([(31,33+bob),(31,42+bob)],15,2)
            line([(30,39+bob),(33,39+bob),(33,42+bob),(30,42+bob),(30,39+bob)],6)
            for x,off in [(xfore,a),(xhind,b)]:
                line([(x,40+bob),(x+off,48),(x-off//2,56)],1,4)
                line([(x,41+bob),(x+off,48),(x-off//2,55)],7,2)
                box((x-off//2-2,56,x-off//2+3,57),0)
        else:
            # Separate front/rear drawings; neither is a rotated side profile.
            for x,off in [(24,a//2),(39,b//2)]:
                line([(x,38),(x+off,48),(x,54)],5,3);box((x-2,54,x+2,55),1)
            poly([(24,25+bob),(38,25+bob),(44,32+bob),(43,44+bob),(38,49+bob),(25,48+bob),(20,41+bob),(20,32+bob)],1)
            poly([(25,27+bob),(37,27+bob),(42,33+bob),(41,43+bob),(37,47+bob),(26,46+bob),(22,40+bob),(22,33+bob)],7)
            poly([(27,28+bob),(36,28+bob),(40,34+bob),(36,39+bob),(26,38+bob),(24,33+bob)],8)
            poly([(23,34+bob),(26,32+bob),(29,35+bob),(27,40+bob),(23,39+bob)],25)
            poly([(37,41+bob),(41,39+bob),(41,44+bob),(37,46+bob)],25)
            box((27,28+bob,36,34+bob),14);line([(28,29+bob),(35,29+bob)],18,2)
            for x,off in [(26,a//2),(37,b//2)]:
                line([(x,42+bob),(x+off,50),(x+off,56)],1,4)
                line([(x,43+bob),(x+off,50),(x+off,55)],7,2)
                box((x+off-2,56,x+off+2,57),0)
            if d=='S':
                poly([(26,23+bob+6),(37,23+bob+6),(39,31+bob+6),(36,40+bob+6),(28,40+bob+6),(24,32+bob+6)],1)
                poly([(27,24+bob+6),(36,24+bob+6),(37,31+bob+6),(35,38+bob+6),(29,38+bob+6),(26,31+bob+6)],7)
                poly([(27,18+bob+6),(25,13+bob+6),(29,15+bob+6),(30,20+bob+6)],1)
                poly([(34,20+bob+6),(36,14+bob+6),(39,13+bob+6),(37,21+bob+6)],1)
                poly([(27,20+bob+6),(36,20+bob+6),(38,27+bob+6),(35,34+bob+6),(29,34+bob+6),(25,27+bob+6)],8)
                line([(32,20+bob+6),(31,24+bob+6),(32,29+bob+6)],25,2)
                box((27,26+bob+6,28,27+bob+6),0);box((35,26+bob+6,36,27+bob+6),0)
                line([(28,32+bob+6),(35,32+bob+6)],15)
                line([(29,34+bob+6),(34,34+bob+6)],5)
            else:
                poly([(27,20+bob),(26,15+bob),(29,17+bob),(30,22+bob),(34,22+bob),(36,16+bob),(38,15+bob),(37,23+bob),(35,28+bob),(28,28+bob)],1)
                poly([(28,22+bob),(35,22+bob),(34,27+bob),(29,27+bob)],7)
                line([(32,21+bob),(31,27+bob),(33,32+bob)],2,3)
                line([(32,43+bob),(31+a//2,49),(33+a//2,55)],2,4)
                line([(32,44+bob),(32+a//2,50),(34+a//2,54)],4)
        return im
    def seated_pair(d,f):
        """Side-view only, front Liu / rear Liang per SC-04-02.
        Both pelvis anchors sit on the agreed saddle sockets; knees bend forward.
        New masks, not standing sprites cropped or scaled onto a horse.
        """
        im=Image.new('RGBA',(64,64));pen=ImageDraw.Draw(im)
        bob=1 if f in (2,4) else 0
        def line(points,c,width=1):
            assert all(isinstance(v,int) for p in points for v in p)
            pen.line(points,fill=pal[c],width=width)
        def poly(points,c):
            assert all(isinstance(v,int) for p in points for v in p)
            pen.polygon(points,fill=pal[c])
        def mask(x,y,rows,colors):
            for j,row in enumerate(rows):
                for i,ch in enumerate(row):
                    if ch!='.':im.putpixel((x+i,y+j),pal[colors[ch]])
        faces={
          'W':['....oooo....','...ohhho....','..ohHHhho...','.ohHHHHhho..','.ohhhhHHho..','.osssshhho..','osslsshhho..','.ssssssho...','..ossSho....','...osso.....'],
          'E':['....oooo....','....ohhho...','...ohHHhho..','..ohHHHHhho.','..ohHHhhhho.','..ohhhsssso.','..ohhsslssso','...ohssssso.','....oSssso..','.....osso...']}
        sockets=({'front':(35,29),'rear':(23,30)} if d=='E' else {'front':(26,29),'rear':(39,30)})
        for role in ['rear','front']:
            x,y=sockets[role];y+=bob
            green=role=='front';main=11 if green else 4;light=12 if green else 5;shade=10 if green else 3
            # Rear layer is drawn first; limbs overlap horse flank rather than reach ground.
            if d=='E':
                poly([(x-4,y-12),(x+2,y-14),(x+6,y-10),(x+5,y-2),(x+3,y+1),(x-4,y)],0)
                poly([(x-3,y-11),(x+2,y-12),(x+4,y-9),(x+3,y-2),(x+1,y),(x-3,y-1)],main)
                line([(x-2,y-10),(x-2,y-3)],light)
                poly([(x-3,y-1),(x+3,y),(x+9,y+5),(x+6,y+12),(x+3,y+12),(x+5,y+5),(x-4,y+2)],0)
                line([(x-2,y+1),(x+6,y+5),(x+4,y+11)],2,3)
                line([(x-1,y+1),(x+6,y+5),(x+5,y+9)],4)
                line([(x+3,y+12),(x+8,y+12)],0,2)
                line([(x+4,y-1),(x-3,y-1)],25 if green else 15)
                if green:
                    poly([(x-7,y-15),(x-10,y-12),(x-10,y-7),(x-7,y-4),(x-5,y-7),(x-5,y-12)],0)
                    line([(x-7,y-14),(x-8,y-10),(x-7,y-6)],12,2)
                line([(x+1,y-9),(x+7,y-5),(x+11,y-6)],shade,3)
                line([(x+2,y-9),(x+7,y-6)],light)
                im.putpixel((x+11,y-6),pal[24])
                if green:line([(x+11,y-6),(52,27+bob)],15)
            else:
                poly([(x+4,y-12),(x-2,y-14),(x-6,y-10),(x-5,y-2),(x-3,y+1),(x+4,y)],0)
                poly([(x+3,y-11),(x-2,y-12),(x-4,y-9),(x-3,y-2),(x-1,y),(x+3,y-1)],main)
                line([(x+2,y-10),(x+2,y-3)],light)
                poly([(x+3,y-1),(x-3,y),(x-9,y+5),(x-6,y+12),(x-3,y+12),(x-5,y+5),(x+4,y+2)],0)
                line([(x+2,y+1),(x-6,y+5),(x-4,y+11)],2,3)
                line([(x+1,y+1),(x-6,y+5),(x-5,y+9)],4)
                line([(x-8,y+12),(x-3,y+12)],0,2)
                line([(x-4,y-1),(x+3,y-1)],25 if green else 15)
                if green:
                    poly([(x+7,y-15),(x+10,y-12),(x+10,y-7),(x+7,y-4),(x+5,y-7),(x+5,y-12)],0)
                    line([(x+7,y-14),(x+8,y-10),(x+7,y-6)],12,2)
                line([(x-1,y-9),(x-7,y-5),(x-11,y-6)],shade,3)
                line([(x-2,y-9),(x-7,y-6)],light)
                im.putpixel((x-11,y-6),pal[24])
                if green:line([(x-11,y-6),(14,27+bob)],15)
            mask(x-6,y-25,faces[d],{'o':0,'h':2,'H':4,'s':24,'S':22,'l':0})
            if green:
                # One high ponytail and jade shuttle, not a second hat.
                if d=='E':
                    line([(x-2,y-24),(x-7,y-22),(x-8,y-16),(x-6,y-13)],0,3)
                    line([(x-2,y-24),(x-7,y-22),(x-8,y-16),(x-6,y-13)],3)
                    line([(x-3,y-24),(x,y-25)],12)
                else:
                    line([(x+1,y-24),(x+7,y-21),(x+8,y-16),(x+6,y-13)],0,3)
                    line([(x+1,y-24),(x+7,y-21),(x+8,y-16),(x+6,y-13)],3)
                    line([(x-4,y-24),(x-1,y-25)],12)
                    # Right-side visible hook remains attached to the waist.
                    line([(x+1,y),(x+3,y+2),(x+1,y+4),(x,y+2)],6)
            else:line([(x-4,y-22),(x+3,y-22)],16)
        return im

    def seated_pair_vertical(d,f):
        """All-view rider depth: S rear Liang behind Liu; N front Liu behind Liang.
        South horse head is supplied as an explicit final foreground occlusion.
        """
        im=Image.new('RGBA',(64,64));pen=ImageDraw.Draw(im)
        bob=1 if f in (2,4) else 0
        def poly(pts,c):
            assert all(isinstance(v,int) for p in pts for v in p)
            pen.polygon(pts,fill=pal[c])
        def line(pts,c,w=1):
            assert all(isinstance(v,int) for p in pts for v in p)
            pen.line(pts,fill=pal[c],width=w)
        def mask(x,y,rows,colors):
            for j,row in enumerate(rows):
                for i,ch in enumerate(row):
                    if ch!='.':im.putpixel((x+i,y+j),pal[colors[ch]])
        faces={
          'S':['....oooo....','...ohhho....','..ohHHhho...','.ohHHHHhho..','.ohhhhHHho..','.ohsssshho..','.osslslsso..','..sssssso...','..ossSsso...','...osso.....'],
          'N':['....oooo....','...ohhho....','..ohHHhho...','.ohHHHHhho..','.ohHHHHhho..','.ohhHHhhho..','.ohhhhhhho..','..ohhhho....','...ohhho....','....oso.....']}
        order=['rear','front'] if d=='S' else ['front','rear']
        sockets={'S':{'front':(32,31),'rear':(32,23)},'N':{'front':(32,23),'rear':(32,31)}}
        for role in order:
            x,y=sockets[d][role];y+=bob
            green=role=='front';main=11 if green else 4;light=12 if green else 5;shade=10 if green else 3
            # Knees splay around the barrel, calves folded back beside the saddle.
            poly([(x-4,y-1),(x-10,y+4),(x-10,y+11),(x-7,y+12),(x-7,y+6),(x-2,y+2)],0)
            poly([(x+4,y-1),(x+10,y+4),(x+10,y+11),(x+7,y+12),(x+7,y+6),(x+2,y+2)],0)
            line([(x-3,y),(x-8,y+4),(x-8,y+10)],2,3)
            line([(x+3,y),(x+8,y+4),(x+8,y+10)],2,3)
            line([(x-3,y),(x-8,y+4),(x-8,y+8)],4)
            line([(x+3,y),(x+8,y+4),(x+8,y+8)],4)
            line([(x-10,y+11),(x-7,y+11)],0,2)
            line([(x+7,y+11),(x+10,y+11)],0,2)
            poly([(x-4,y-15),(x+4,y-15),(x+8,y-10),(x+6,y-1),(x+3,y+2),(x-4,y+1),(x-7,y-5),(x-7,y-11)],0)
            poly([(x-3,y-14),(x+3,y-14),(x+6,y-10),(x+4,y-2),(x+2,y),(x-3,y-1),(x-5,y-6),(x-5,y-10)],main)
            line([(x-3,y-12),(x-3,y-4)],light)
            line([(x+3,y-11),(x+3,y-3)],shade)
            line([(x-5,y-1),(x+5,y-1)],25 if green else 15,2)
            if d=='S':
                line([(x-3,y-14),(x,y-10),(x+3,y-14)],12 if green else 7)
                line([(x-6,y-9),(x-6,y-4),(x-3,y-2)],shade,3)
                line([(x+6,y-9),(x+6,y-4),(x+3,y-2)],shade,3)
                im.putpixel((x-3,y-2),pal[24]);im.putpixel((x+3,y-2),pal[24])
                if green:
                    line([(x-3,y-2),(29,36+bob)],15)
                    line([(x+3,y-2),(35,36+bob)],15)
            else:
                # Back shoulder planes, no front lapel painted through body.
                line([(x-5,y-12),(x,y-10),(x+5,y-12)],shade)
            # Far head leans 2 px to keep both faces/hairstyles legible in oblique view.
            hx=x-6+(2 if role==order[0] else -1)
            hy=max(0,y-24)
            mask(hx,hy,faces[d],{'o':0,'h':2,'H':4,'s':24,'S':22,'l':0})
            if green:
                if d=='S':
                    line([(hx+9,hy+2),(hx+12,hy+6),(hx+11,hy+13)],0,3)
                    line([(hx+9,hy+2),(hx+12,hy+6),(hx+11,hy+13)],3)
                    line([(hx+2,hy+2),(hx+5,hy+1)],12)
                else:
                    line([(hx+6,hy+2),(hx+7,hy+8),(hx+6,hy+13)],0,3)
                    line([(hx+6,hy+2),(hx+7,hy+8),(hx+6,hy+13)],3)
                    line([(hx+8,hy+2),(hx+11,hy+3)],12)
                # One hat: when north-facing most is hidden by nearer Liang.
                if d=='N':
                    poly([(x-6,y-9),(x-3,y-12),(x+3,y-12),(x+6,y-8),(x+5,y-3),(x-4,y-3)],0)
                    poly([(x-4,y-9),(x-2,y-10),(x+2,y-10),(x+4,y-7),(x+3,y-5),(x-3,y-5)],11)
                    line([(x-3,y-8),(x+3,y-8)],13)
            else:line([(hx+2,hy+3),(hx+9,hy+3)],16)
        if d=='S':
            # Foreground horse face/neck masks rider pelvis, never the rider heads.
            horse=draw(d,f)
            fg=Image.new('L',(64,64));fp=ImageDraw.Draw(fg)
            fp.polygon([(27,19+bob),(30,26+bob),(34,26+bob),(36,20+bob),(39,19+bob),(38,33+bob),(36,46+bob),(28,46+bob),(24,38+bob),(25,27+bob)],fill=255)
            for yy in range(64):
                for xx in range(64):
                    if fg.getpixel((xx,yy)) and horse.getpixel((xx,yy))[3]==255:
                        im.putpixel((xx,yy),horse.getpixel((xx,yy)))
        return im

    dirs=['S','N','W','E'];atlas=Image.new('RGBA',(320,256));frames=[]
    for di,d in enumerate(dirs):
        for f in range(5):
            im=draw(d,f);atlas.alpha_composite(im,(64*f,64*di))
            frames.append({'id':f'{d}_{"idle" if f==0 else "walk_"+str(f)}','rect':[64*f,64*di,64,64],'origin':[32,58],'duration_ms':480 if f==0 else 120,'facing':d,'state':'idle' if f==0 else 'walk','seat_bob_y':1 if f in (2,4) else 0})
        assert len({draw(d,f).tobytes() for f in range(1,5)})==4
    atlas.save(out/'horse_yanzhi.png')
    preview=Image.new('RGBA',atlas.size,pal[1]);preview.alpha_composite(atlas)
    preview.save(pre/'horse_yanzhi_contact_1x.png')
    preview.resize((1280,1024),Image.Resampling.NEAREST).save(pre/'horse_yanzhi_contact_4x.png')
    riders=Image.new('RGBA',(320,128));combo=Image.new('RGBA',(320,128),pal[1])
    rframes=[]
    for row,d in enumerate(['W','E']):
        for f in range(5):
            ri=seated_pair(d,f);riders.alpha_composite(ri,(64*f,64*row))
            ci=draw(d,f);ci.alpha_composite(ri);combo.alpha_composite(ci,(64*f,64*row))
            rframes.append({'id':f'{d}_{"idle" if f==0 else "walk_"+str(f)}','rect':[64*f,64*row,64,64],'origin':[32,58],'facing':d,'horse_frame':f,'seat_bob_applied':True})
    riders.save(out/'horse_yanzhi_riders_side.png')
    combo.save(pre/'horse_yanzhi_dual_ride_side_1x.png')
    combo.resize((1280,512),Image.Resampling.NEAREST).save(pre/'horse_yanzhi_dual_ride_side_4x.png')
    full=Image.new('RGBA',(320,256));fullcombo=Image.new('RGBA',(320,256),pal[1]);fullframes=[]
    for row,d in enumerate(dirs):
        for f in range(5):
            ri=seated_pair(d,f) if d in ('W','E') else seated_pair_vertical(d,f)
            full.alpha_composite(ri,(64*f,64*row))
            ci=draw(d,f);ci.alpha_composite(ri);fullcombo.alpha_composite(ci,(64*f,64*row))
            fullframes.append({'id':f'{d}_{"idle" if f==0 else "walk_"+str(f)}','rect':[64*f,64*row,64,64],'origin':[32,58],'facing':d,'horse_frame':f,'seat_bob_applied':True,'duration_ms':480 if f==0 else 120})
    full.save(out/'horse_yanzhi_riders.png')
    fullcombo.save(pre/'horse_yanzhi_dual_ride_1x.png')
    fullcombo.resize((1280,1024),Image.Resampling.NEAREST).save(pre/'horse_yanzhi_dual_ride_4x.png')
    return {'horse_yanzhi':{'texture':'horse_yanzhi.png','cell':[64,64],'origin':[32,58],'frames':frames,'source_mapping':'chapter-four-content: original-novel white coat/red markings decision','status':'candidate_unmounted_only','riding_implemented':False,'seated_rider_side_reference':{'texture':'horse_yanzhi_riders_side.png','cell':[64,64],'origin':[32,58],'directions':['W','E'],'front':'liu_yingying','rear':'liang_xiao','frames':rframes,'status':'visual_candidate_only_not_engine_verified','missing':['north_seated_pair','south_seated_pair','mount_and_dismount_animation']},'seated_rider_layer':{'texture':'horse_yanzhi_riders.png','cell':[64,64],'origin':[32,58],'directions':['S','N','W','E'],'front':'liu_yingying','rear':'liang_xiao','frames':fullframes,'status':'four_direction_visual_candidate_not_engine_verified','south_horse_head_foreground_included':True,'depth_order':{'S':['liang_xiao','liu_yingying','horse_head'],'N':['liu_yingying','liang_xiao']},'missing':['mount_and_dismount_animation','runtime_state_and_movement_verification']},'proposed_pelvis_sockets':{'E':{'front':[35,29],'rear':[23,30]},'W':{'front':[26,29],'rear':[39,30]},'S':{'front':[32,31],'rear':[32,23]},'N':{'front':[32,23],'rear':[32,31]}},'socket_note':'Sockets need per-frame seat_bob_y. No standing actor may be placed here and called mounted. Four-direction seated layers supplied. South includes horse-head foreground occlusion; mount/dismount and runtime integration remain unfinished.','source_sha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest()}}
