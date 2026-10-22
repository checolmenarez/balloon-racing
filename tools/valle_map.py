"""Render the runtime geometry snapshot, without parsing or changing gameplay."""
import json
from html import escape
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'docs' / 'valle-recon'
OUT.mkdir(exist_ok=True)
data = json.loads((ROOT / '.godot/valle-geometry.json').read_text(encoding='utf-8'))
(OUT / 'geometry.json').write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding='utf-8')

def svg_sector(i):
    start = data['zones'][i]['x']
    end = data['zones'][i+1]['x'] if i < 5 else 18400
    # Same scale on both axes; scroll horizontally to inspect at 1:1.
    width = end - start
    parts = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="{start-60} -55 {width+120} 770" width="{width+120}" height="770" role="img" aria-label="Sector {i+1}">',
             f'<rect x="{start-60}" y="-55" width="{width+120}" height="770" fill="#f7f7f2"/>']
    for y in [32, 100, 200, 300, 400, 500, 600, 640]:
        parts += [f'<path d="M{start} {y} H{end}" stroke="#c6cbc7"/>', f'<text x="{start-55}" y="{y+5}" font-size="16">{y}</text>']
    for x in range(int(start//250)*250+250, int(end)+1, 250):
        parts += [f'<path d="M{x} 32 V640" stroke="#e0e2dc"/>', f'<text x="{x}" y="685" font-size="16">{x}</text>']
    for w in data['winds']:
        x,y = w['x']-w['width']/2, w['y']-w['height']/2
        if x < end and x+w['width'] > start:
            parts += [f'<rect x="{x}" y="{y}" width="{w["width"]}" height="{w["height"]}" fill="#16889b" fill-opacity=".18" stroke="#16889b"/>',f'<text x="{max(start,x)+10}" y="{y+22}" font-size="17">{w["name"]} ×{w["multiplier"]}</text>']
    for o in data['obstacles']:
        if o['x']+o['width']/2 < start or o['x']-o['width']/2 > end: continue
        for polygon in o['polygons']:
            points = ' '.join(f'{x},{y}' for x,y in polygon)
            parts.append(f'<polygon points="{points}" fill="#59665d" stroke="#26362b"><title>{o["name"]}; ancho {o["width"]} px</title></polygon>')
        parts.append(f'<text x="{o["x"]}" y="-25" text-anchor="middle" font-size="16">{o["name"]}</text>')
    for b in data['boxes']:
        if start <= b['x'] < end:
            parts += [f'<rect x="{b["x"]-24}" y="{b["y"]-24}" width="48" height="48" fill="#dcb650" stroke="#594718"/>', f'<text x="{b["x"]+28}" y="{b["y"]+5}" font-size="16">{b["name"]}</text>']
    for name in ['Start','Fork','Merge','Finish']:
        x,y = data['references'][name]
        if start <= x <= end:
            parts += [f'<path d="M{x} 0 V650" stroke="#172e45" stroke-width="3" stroke-dasharray="8 6"/>',f'<text x="{x+8}" y="20" font-size="18">{name} x={x}</text>']
    parts += [f'<text x="{start}" y="715" font-size="17">X mundial (px) → · Y mundial (px) ↓ · escala igual en ambos ejes</text>', '</svg>']
    return ''.join(parts)

def table(headers, rows):
    return '<table><thead><tr>'+''.join('<th>'+escape(str(h))+'</th>' for h in headers)+'</tr></thead><tbody>'+''.join('<tr>'+''.join('<td>'+escape(str(v))+'</td>' for v in row)+'</tr>' for row in rows)+'</tbody></table>'

parts = ['''<!doctype html><html lang="es"><meta charset="utf-8"><title>Valle Ventoso · Reconocimiento técnico</title>
<style>body{font:16px system-ui;color:#20312b;background:#fafaf6;margin:32px}h1{font-size:26px}h2{font-size:21px;margin-top:36px}.map{overflow:auto;border:1px solid #b7beb7}svg{display:block}table{border-collapse:collapse;font-size:14px;width:100%}th,td{padding:9px;text-align:left;border-bottom:1px solid #d4d9d1}th{background:#e9eee7}p{max-width:1000px;line-height:1.5}code{background:#e9eee7}</style>
<h1>Valle Ventoso · Geometría actual</h1><p>Snapshot 2026-10-20 · Godot 4.7.2 · Fuente: polígonos de colisión instanciados por Track01.tscn y obstacle.gd. No es un rediseño. Los seis paneles usan escala 1:1; desplazar horizontalmente. Gris: sólidos reales; azul: sensores de viento ×1,20; amarillo: cajas 48×48; líneas discontinuas: referencias.</p>
<p>Salida x=240; meta x=18400; recorrido 18160 px. Límite vertical y=32…640. Globo: rectángulo 77,44×118,8, desplazado −5,72 en Y: 65,12 px sobre el origen y 53,68 debajo. El margen vertical citado resta 118,8 al paso; es una condición geométrica estática, no garantía dinámica. Los globos no colisionan entre sí.</p>''']
for i,z in enumerate(data['zones']):
    end = data['zones'][i+1]['x'] if i<5 else 18400
    parts += [f'<h2>S{i+1} · {escape(z["title"])} · x={z["x"]:g}…{end:g}</h2><div class="map">{svg_sector(i)}</div>']
    (OUT/f'sector-{i+1}.svg').write_text(svg_sector(i),encoding='utf-8')
rows=[]
for o in data['obstacles']:
    k=o['kind']; top=o['top']; bottom=o['bottom']
    gap = bottom-32 if k==0 else 640-top if k==1 else bottom-top if k==2 else None
    solid = f'{o["width"]:g} × {640-bottom:g}' if k==0 else f'{o["width"]:g} × {top-32:g}' if k==1 else f'{o["width"]:g} × {top-32:g} arriba; {o["width"]:g} × {640-bottom:g} abajo' if k==2 else f'{o["width"]:g} × {bottom-top:g}'
    passage=f'{gap:g} / {gap-118.8:.2f}' if gap else 'arriba 228 / 109.20; abajo 300 / 181.20 (sin rocas de rama)'
    rows.append([o['name'], f'{o["x"]-o["width"]/2:g}…{o["x"]+o["width"]/2:g}',solid,passage])
parts += ['<h2>Dimensiones de los 17 obstáculos</h2><p>Dimensiones = caja envolvente del polígono, no bloques rectangulares. Pasos medidos en la punta más restrictiva. En S4 se combinan isla y rocas: bajo UpperRouteRockA, 190 / 71,20 px; bajo B, 180 / 61,20 px; sobre LowerRouteRock, 240 / 121,20 px.</p>',table(['Obstáculo','Intervalo X (px)','Ancho × alto sólido (px)','Paso / margen del globo (px)'],rows)]
parts += ['<h2>32 cajas · centros y sensores reales</h2>',table(['Caja','X (px)','Y (px)','Sensor'],[[b['name'],b['x'],b['y'],'48 × 48'] for b in data['boxes']])]
parts += ['<h2>Viento · rectángulos de interacción</h2>',table(['Zona','Intervalo X (px)','Intervalo Y (px)','Tamaño (px)','Ayuda'],[[w['name'],f'{w["x"]-w["width"]/2:g}…{w["x"]+w["width"]/2:g}',f'{w["y"]-w["height"]/2:g}…{w["y"]+w["height"]/2:g}',f'{w["width"]:g} × {w["height"]:g}',w['multiplier']] for w in data['winds']])]
parts += ['<p>El cuerpo activa viento por solapamiento, no por su centro: las áreas de influencia sobre el origen del globo se extienden 38,72 px horizontalmente, 53,68 hacia arriba y 65,12 hacia abajo. Turbo ×1,35 y viento no se multiplican. Bifurcación anunciada en x=9700, isla x=10300…12900, convergencia de referencia x=13200; S5 empieza en 13400. La separación física no coincide con los límites de sector.</p><p>Datos completos: <a href="geometry.json">geometry.json</a>. Diagnóstico, propuestas y límites: <a href="../valle-ventoso-reconocimiento.md">informe</a>.</p></html>']
(OUT/'mapa.html').write_text(''.join(parts),encoding='utf-8')
print(OUT/'mapa.html')
