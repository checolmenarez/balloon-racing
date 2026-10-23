# Valle Ventoso 2.0 — blockout experimental

Implementado sobre `work/flappy-1`, preservando Game Feel y los cambios locales.
Meta X=18400, límites Y=32–640, seis marcadores, física, turbo, probabilidades
de objetos, HUD y personajes intactos. 22 formaciones, 32 cajas, ocho áreas
de viento y tres Flappy. Sin commits, push ni merge.

## Cambios y decisiones por sector

- **S1:** tres cajas iniciales; montaña conservada; roca superior en X=2300
  (faltaba en la escena de partida); segundo grupo trasladado a X=2550.
  Elegir altura y corregir con espacio, sin corriente ni criatura.
- **S2:** isla en X=3800, montaña inferior desplazada/rebajada y cajas arriba
  y abajo. Elegir un paso local y anticipar Flappy en X=4450; no hay nuevo Fork.
- **S3:** entrada alternada, isla irregular de dos crestas y depresión,
  techo central y tres tramos de WindZone a 1,20, separados para no ocupar roca.
  Cambiar altura dos veces para ganar tiempo o pasar por debajo sin precisión.
- **S4:** embudo X=9500–10000 y ajuste del segundo saliente superior.
  Elegir rapidez arriba o margen abajo; mismos Fork, Merge y UpperCurrent.
- **S5:** Flappy trasladado a X=13600; isla con crestas, techo, tres corrientes
  y montaña de salida. Prepararse tras la criatura, maniobrar o tomar el paso
  inferior; recuperar altura antes de S6.
- **S6:** cajas adelantadas, una roca superior y dos montañas; tercer Flappy
  en X=17950, ±30 px/3,6 s. Quedan 415 px sin colliders antes de la meta.
  Elegir la última caja, esquivar y gastar el turbo restante.

Las islas usan un `outline` exportado en FlightObstacle, compartido exactamente
por Polygon2D y CollisionPolygon2D. Se reutilizan roca, borde vegetal, viento
y sprites existentes. Ajuste local de IA: las islas irregulares se rodean por
abajo; S2 y S4 conservan la preferencia existente. Los bots no explotan todavía
el trazado superior técnico de S3/S5.

[Coordenadas reales](valle-ventoso-2-coordenadas.md) ·
[Mapa completo](mapa-geometrico-valle-ventoso.svg).

## Validación automatizada

Godot 4.7.2 Standard, importación final exitosa, física a 60 Hz: **12 suites PASS**.
Suites: `valle_redesign`, `track`,
`flying_creature`, `obstacle`, `flight`, `turbo`, `items`, `world_visual`,
`race_flow`, `pause`, `game_feel` y `competition`.

`valle_redesign` comprueba siluetas/colliders, viento fuera de roca, 25 px
adicionales por lado en pasos clave y muestras cada 25 px de ambos corredores
técnicos y alternativas inferiores. Tres carreras sin turbo y **cero impactos**:
rápida con viento 78,20 s, misma trayectoria sin viento 82,52 s, alternativa
segura 80,05 s. Un piloto de prueba utiliza el quemador real; no teletransporta
ni cambia velocidades. S2 se recorre por ambos lados.

- S3: rápida 15,88 s; misma trayectoria sin viento/alternativa 16,83 s.
- S5: rápida 14,22 s; sin viento 15,45 s; alternativa 15,17 s.
- S4: arriba 14,65 s; abajo 16,67 s; ventaja 2,02 s, sin retocar el viento.

El controlador de `track` completa las dos rutas de S4 sin impactos, además
de tres vuelos deliberadamente defectuosos que siguen llegando a meta.
`competition` comprueba llegadas de los cuatro participantes, clasificación,
igualdad de física, límite de velocidad y accesibilidad de todas las cajas.
Seis semillas finales: **24/24 llegadas**, sin bloqueos; bots entre 79,43 y
84,00 s, con 2–7 contactos por carrera. El humano pasivo de esa prueba tarda
85,46–86,51 s; no representa una partida humana real.
Capturas de los seis sectores revisadas en ANGLE: `.godot/valle-preview-s*.png`.
No equivalen a playtesting humano. Logs: `.godot/valle-final-*.log` y
`.godot/valle-redesign.log`.

## Rendimiento del blockout antes del pase visual

Intel HD / ANGLE D3D11, 1280×720, VSync desactivado, cuatro turbos simultáneos,
posiciones fijas. Dos pares alternados antes/después por sector; cada muestra
usa 60 frames de calentamiento y 90 medidos. FPS = 1000 / tiempo medio combinado.
La referencia es una copia de la escena antes de esta intervención.

| Muestra (X del jugador) | Antes FPS / ms | Después FPS / ms |
|---|---:|---:|
| S2 (4000) | 32,17 / 31,08 | 32,54 / 30,73 |
| S3 (7800) | 30,09 / 33,23 | 29,44 / 33,97 |
| S5 (14900) | 33,68 / 29,69 | 32,18 / 31,08 |
| S6 (17400) | 32,14 / 31,12 | 34,47 / 29,01 |

Mayor incremento observado: S5, +1,39 ms (~4,7 %). Sin regresión grave en estas
muestras; no acredita 60 FPS ni rendimiento de una carrera completa.
Modo reducido, una muestra por sector: S3 36,27 FPS/27,57 ms; S5 34,26 FPS/29,19 ms.
Las pruebas de Game Feel y Flappy verifican reducción visual sin cambiar reglas.

Reproducir con `tests/feel_benchmark.gd -- etiqueta x=7800`; añadir
`track=res://.godot/valle-before.tscn` para la copia de control guardada localmente,
o `reduced` para efectos reducidos. JSON de mediciones: `.godot/feel-bench-valle-*`.

## Pendientes y límites

La duración limpia de 78–83 s queda por debajo de los 90–120 s provisionales;
no se alargó la pista ni se alteró física para forzar ese objetivo. Los bots
pueden cometer errores; la aceptación humana de dificultad, diversión,
legibilidad, remontadas y ventaja real de rutas sigue pendiente. El embudo y
la salida de S6 necesitan esa evaluación jugando, además de las pruebas técnicas.

Pase artístico aplicado: roca y agua de la lámina `pista1_elements.png`
proporcionada por el usuario (`terrain/base/valle_reference_atlas.png`, copia
sin modificar), vegetación colgante, molinos, flores y puentes del kit existente.
Shader estático compartido para la roca; detalles recortados con Geometry2D
contra la silueta real, sin CanvasGroup adicional ni colisiones decorativas.
Cuatro capas de parallax: cielo, nubes lejanas, islas distantes y nubes bajas;
se retiran islas medias y primer plano. Las fuentes originales se conservan.
La selección artística y la legibilidad final siguen sujetas a juego humano.

Validación del pase visual: `world_visual`, `game_feel` y `valle_redesign` PASS;
la primera comprueba colliders después de aplicar el arte. La escena Track01
es idéntica byte por byte a la anterior al pase visual. Capturas de seis sectores
revisadas; los recorridos controlados mantienen cero impactos.

Comparación específica del pase visual, mismas condiciones ANGLE/1280×720,
cuatro turbos en X=7800, dos pares alternados de 60 frames de calentamiento
y 90 medidos: antes **32,17 FPS / 31,09 ms**, después **32,20 FPS / 31,05 ms**.
Sin diferencia relevante en esta muestra; no acredita 60 FPS. Datos locales:
`.godot/feel-bench-art-{before,after}-{1,2}.json`.

Persisten avisos ambientales de certificados y referencias/ObjectDB al cerrar
algunas pruebas, ya presentes antes. No se consideran errores de geometría.
Referencia técnica: [CollisionPolygon2D y descomposición de polígonos sólidos](https://docs.godotengine.org/en/stable/classes/class_collisionpolygon2d.html).
