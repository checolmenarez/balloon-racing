import re, json, html
from pathlib import Path

root = Path(__file__).resolve().parents[1]
source = (root/'scenes/Track01.tscn').read_text(encoding='utf-8')
nodes=[]
for block in re.split(r'(?=\[node )',source)[1:]:
    header=block.splitlines()[0]
    n=dict(re.findall(r'(\w+)="([^"]*)"',header))
    for key,val in re.findall(r'^([\w/]+) = (.+)$',block,re.M):
        if val.startswith('Vector2('): n[key]=[float(v) for v in val[8:-1].split(',')]
        elif val.startswith('PackedVector2Array('):
            coords=[float(v) for v in val[19:-1].split(',')]
            n[key]=list(zip(coords[::2],coords[1::2]))
        elif val.startswith('"'): n[key]=val.strip('"')
        else:
            try:n[key]=float(val)
            except ValueError:pass
    nodes.append(n)
zones=[n for n in nodes if n.get('parent')=='Zones']
rocks=[n for n in nodes if n.get('parent')=='Obstacles']
boxes=[n for n in nodes if n.get('parent')=='ItemBoxes']
winds=[n for n in nodes if n.get('parent')=='WindZones']
birds=[n for n in nodes if n.get('parent')=='FlyingObstacles']
assert (len(zones),len(rocks),len(boxes),len(winds),len(birds))==(6,29,24,10,3)
ops=[]
def rect(x,y,w,h,fill,stroke='',dash=False):ops.append(dict(t='rect',x=x,y=y,w=w,h=h,fill=fill,stroke=stroke,dash=dash))
def line(x,y,x2,y2,color,width=1,dash=False):ops.append(dict(t='line',x=x,y=y,x2=x2,y2=y2,stroke=color,width=width,dash=dash))
def text(x,y,value,size=17,color='#203442',bold=False):ops.append(dict(t='text',x=x,y=y,text=str(value),size=size,fill=color,bold=bold))
def poly(points,fill,stroke=''):ops.append(dict(t='poly',points=points,fill=fill,stroke=stroke))
def ellipse(x,y,w,h,fill,stroke):ops.append(dict(t='ellipse',x=x,y=y,w=w,h=h,fill=fill,stroke=stroke))
S=.37; X=125; W=1600; H=2225
rect(0,0,W,H,'#f7f9fb')
text(65,58,'VALLE VENTOSO 2.0',34,bold=True)
text(65,94,'Mapa geométrico completo · 6 sectores · recorrido de 18.160 px',22)
text(65,122,'Geometría de colisión real. Lectura de izquierda a derecha y de arriba abajo.',17,'#526774')
bounds=[z['position'][0] for z in zones]+[18400]
for i,z in enumerate(zones):
    x=65+(bounds[i]-240)/18160*1470; w=(bounds[i+1]-bounds[i])/18160*1470
    rect(x,145,w,30,'#dce5eb' if i%2==0 else '#e9eef2','#ffffff')
    text(x+10,166,f'S{i+1}',15,bold=True)
rect(65,195,20,15,'#647887');text(94,208,'Obstáculo sólido',16)
rect(320,195,16,16,'#edb253','#aa7424');text(346,208,'Caja',16)
rect(465,195,25,15,'#d2eaf0','#26849a');text(501,208,'Corriente →',16)
ellipse(700,193,20,20,'#9971bb','#694687');text(732,208,'Flappy',16)
rect(870,192,20,22,'','#9971bb',True);text(902,208,'Envolvente de movimiento',16)
text(1250,208,'X → avance · Y ↓ altura',16)
for i,z in enumerate(zones):
    a,b=bounds[i:i+2]; y0=285+i*315; cw=(b-a)*S; ch=(640-32)*S
    sx=lambda v:X+(v-a)*S
    sy=lambda v:y0+(v-32)*S
    text(65,y0-25,f'S{i+1}  {z["metadata/title"]}',23,bold=True)
    text(650,y0-25,f'X: {a:,.0f}–{b:,.0f} px  ·  longitud: {b-a:,.0f} px'.replace(',','.'),17,'#526774')
    rect(X,y0,cw,ch,'#ffffff','#a5b4bf')
    for yy in [32,200,400,640]:
        line(X,sy(yy),X+cw,sy(yy),'#dce4e9')
        text(69,sy(yy)+5,yy,14,'#526774')
    text(24,y0+115,'Y px',13,'#526774')
    ticks=[a]+[v for v in range(int(a//500+1)*500,int(b),500) if v-a>180 and b-v>180]+[b]
    for xx in ticks:
        line(sx(xx),y0,sx(xx),y0+ch,'#e8edf1')
        text(sx(xx)-15,y0+ch+20,f'{xx:.0f}',13,'#526774')
    for n in winds:
        cx,cy=n['position']; w,h=n['size']; left=max(a,cx-w/2);right=min(b,cx+w/2)
        if right<=left:continue
        rect(sx(left),sy(cy-h/2),(right-left)*S,h*S,'#d2eaf0','#82b8c5')
        for xx in range(int(left)+90,int(right)-40,220):
            line(sx(xx),sy(cy),sx(xx+65),sy(cy),'#26849a',1.5)
            poly([(sx(xx+65),sy(cy)),(sx(xx+42),sy(cy-9)),(sx(xx+42),sy(cy+9))],'#26849a')
    for n in rocks:
        cx,cy=n['position'];width=n['width'];kind=int(n['kind']); top=n['upper_tip_y'];bottom=n['lower_tip_y']
        if cx+width/2<=a or cx-width/2>=b:continue
        polys=[]
        if n.get('outline'):
            polys=[[(cx+xx,yy) for xx,yy in n['outline']]]
        elif kind==3:
            mid=(top+bottom)/2
            polys=[[(cx-width/2,mid),(cx-width*.46,top),(cx+width*.46,top),(cx+width/2,mid),(cx+width*.46,bottom),(cx-width*.46,bottom)]]
        else:
            for upper in [True,False]:
                if upper and kind==0 or not upper and kind==1:continue
                anchor=32 if upper else 640;tip=top if upper else bottom;shoulder=tip+(-35 if upper else 35)
                polys.append([(cx-width/2,anchor),(cx-width*.22,shoulder),(cx,tip),(cx+width*.22,shoulder),(cx+width/2,anchor)])
        for ps in polys:
            for bound,sign in [(a,1),(b,-1)]:
                clipped=[]
                for j,p in enumerate(ps):
                    q=ps[j-1];pin=(p[0]-bound)*sign>=0;qin=(q[0]-bound)*sign>=0
                    if pin != qin:
                        t=(bound-q[0])/(p[0]-q[0]);clipped.append((bound,q[1]+t*(p[1]-q[1])))
                    if pin:clipped.append(p)
                ps=clipped
            if ps:poly([(sx(xx),sy(yy+cy)) for xx,yy in ps],'#647887','#435966')
        if a<=cx<b and kind in (1,2):text(sx(cx)-10,sy(top)+18,str(int(top)),13,'#435966')
        if a<=cx<b and kind in (0,2):text(sx(cx)-10,sy(bottom)-9,str(int(bottom)),13,'#435966')
    for n in boxes:
        xx,yy=n['position']
        if a<=xx<b:rect(sx(xx-24),sy(yy-24),48*S,48*S,'#edb253','#aa7424')
    for n in birds:
        xx,yy=n['position']
        if not a<=xx<b:continue
        amplitude=n.get('amplitude',45);period=n.get('period',3)
        rect(sx(xx-35),sy(yy+5-41-amplitude),70*S,(82+amplitude*2)*S,'','#9971bb',True)
        line(sx(xx),sy(yy-amplitude),sx(xx),sy(yy+amplitude),'#694687',2)
        ellipse(sx(xx-35),sy(yy+5-41),70*S,82*S,'#9971bb','#694687')
        line(sx(xx),sy(yy+46+amplitude),sx(xx),sy(505),'#9971bb',1,True)
        text(sx(xx)-10,sy(550),f'Flappy · X {int(xx)}',15,'#694687',True)
        text(sx(xx)-10,sy(605),f'Y {yy-amplitude:g}–{yy+amplitude:g} · {period:g} s',14,'#694687')
    if i==0:
        line(sx(240),y0,sx(240),y0+ch,'#203442',3)
        text(sx(240)+12,sy(420),'SALIDA',15,bold=True)
    if i==3:
        text(sx(10000),sy(150),'Ruta alta',16,'#203442',True)
        text(sx(10000),sy(540),'Ruta baja',16,'#203442',True)
        text(sx(11300),sy(318),'DIVISOR',15,'#ffffff',True)
        line(sx(13200),y0,sx(13200),y0+ch,'#526774',1,True)
        text(sx(13200)-70,sy(605),'Unión',14)
    if i==5:
        line(sx(18400),y0,sx(18400),y0+ch,'#203442',3)
        text(sx(18400)+14,sy(350),'META',19,bold=True)
    text(X+cw+16,y0+ch+20,'X px',13,'#526774')
text(65,2155,'Escala uniforme en los seis sectores: X e Y conservan la misma proporción. Límites de vuelo: Y = 32–640 px.',16)
text(65,2181,'Los números junto a las puntas indican Y. Flappy se simboliza en su centro de oscilación; el recuadro delimita su barrido físico.',15,'#526774')
text(65,2206,'Fuente: Track01.tscn, obstacle.gd y FlyingCreatureObstacle.tscn · estado local del 25 de octubre de 2026. Sin decoración.',14,'#526774')
(root/'.godot/map_geometry_ops.json').write_text(json.dumps(dict(width=W,height=H,ops=ops),ensure_ascii=False),encoding='utf-8')
svg=[f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">', '<title>Valle Ventoso — mapa geométrico por sectores</title>']
for o in ops:
    t=o['t']; fill=o.get('fill') or 'none';stroke=o.get('stroke') or 'none';style=f'fill="{fill}" stroke="{stroke}"'
    if o.get('dash'):style+=' stroke-dasharray="5 4"'
    if t=='text': svg.append(f'<text x="{o["x"]}" y="{o["y"]}" font-family="Segoe UI, sans-serif" font-size="{o["size"]}" font-weight="{700 if o["bold"] else 400}" fill="{fill}">{html.escape(o["text"])}</text>')
    elif t=='line':svg.append(f'<line x1="{o["x"]}" y1="{o["y"]}" x2="{o["x2"]}" y2="{o["y2"]}" {style} stroke-width="{o["width"]}"/>')
    elif t=='poly':svg.append(f'<polygon points="{" ".join(f"{x},{y}" for x,y in o["points"])}" {style}/>' )
    elif t=='ellipse':svg.append(f'<ellipse cx="{o["x"]+o["w"]/2}" cy="{o["y"]+o["h"]/2}" rx="{o["w"]/2}" ry="{o["h"]/2}" {style}/>' )
    else:svg.append(f'<rect x="{o["x"]}" y="{o["y"]}" width="{o["w"]}" height="{o["h"]}" {style}/>' )
svg.append('</svg>')
(root/'docs/mapa-geometrico-valle-ventoso.svg').write_text('\n'.join(svg),encoding='utf-8')
print(f'{len(rocks)} obstáculos, {len(boxes)} cajas, {len(winds)} corrientes y {len(birds)} Flappys; 6 sectores.')
