# Valle Ventoso 2.0 — blockout experimental

> Las cifras de las secciones originales son hist?ricas. El ajuste vigente se detalla al final.

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


## Ajuste de balance 2026-10-25

Solicitud: menos cajas y reparto equitativo, bots +30 %, más obstáculos en
los extremos, vientos técnicos pequeños, S4 fragmentada e islas sólidas.

- 24 cajas (antes 32): cuatro en cada sector. S4 reparte dos por rama,
  escalonadas longitudinalmente; sensores, objetos y reaparición intactos.
- Valor inicial de este ajuste: `BotProfile.skill_multiplier = 1.3` (vigente ahora: **1.85**, véase el ajuste adicional al final). Anticipación ×1,30; tiempos de reacción,
  tolerancia y error divididos por 1,30. Es un aumento de capacidad configurada,
  no una promesa de ganar un 30 % más ni correr un 30 % más rápido.
  La IA limita el objetivo al corredor libre y prioriza islas sólidas, luego orden
  de entrada: una puerta futura incompatible no invalida el paso actual.
- Siete formaciones GAP adicionales en X=650, 5300, 9200, 10400, 13200,
  16350 y 17550. Penalizan quedarse en techo/suelo; los obstáculos verticales
  conservan la recuperación atravesable solicitada. Total: 29 formaciones. La montaña inicial pasa de X=1900 a 2200
  para conservar una ventana de turbo tras la primera puerta. Los filtros de
  turbo no cambian: no se exige que todos los bots lo gasten en cada carrera.
- Los seis sensores técnicos S3/S5 pasan a 120×24 px: área reducida un 88 %
  en las entradas/salidas y un 79 % en las depresiones. Se conserva ×1,20.
  Son ventanas pequeñas positivas; el globo activa viento al solapar el sensor,
  no necesita caber entero dentro. Las islas/techos exigen cambios de altura.
  MergeCurrent, compartida con la entrada de S5, también se reduce a 120×24.
- UpperCurrent pasa de 2400×110 a tres ventanas: 450×30, 350×30 y 350×30,
  centros (10800,165), (11700,175), (12600,160). Roca alta A profundizada
  a Y=120 y nuevas puertas en los extremos de S4. Diez vientos en total.
- Las cuatro islas `Kind.ISLAND` nunca reciben excepciones de colisión,
  ni durante la protección de impacto: caras superiores, inferiores y puntas
  conservan el collider. Hay que rodearlas con el quemador. Flappy mantiene
  su comportamiento existente. La penalización y protección siguen vigentes.

Fuente de geometría: `scenes/Track01.tscn`; mapa SVG regenerado con
`tools/generate_track_map.py`. El documento de coordenadas anterior conserva
el pase inicial; consultar la escena/mapa para las posiciones actuales.
Referencia de API consultada: [PhysicsBody2D](https://docs.godotengine.org/en/stable/classes/class_physicsbody2d.html)
y [CharacterBody2D](https://docs.godotengine.org/en/stable/classes/class_characterbody2d.html).

### Validación del ajuste

Godot 4.7.2 Standard, simulaciones a 60 Hz. `valle_redesign`, `track`,
`competition`, `obstacle`, `turbo`, `chaos`, `flying_creature`, `world_visual`
y `race_flow`, además de `items`: diez suites PASS, cero fallos.

- Tres recorridos controlados, sin turbo y sin impactos: rápido 80,43 s,
  mismo recorrido sin viento 82,52 s, alternativa inferior 81,32 s.
- Ambas ramas de S4 sin impactos: alta 15,70 s, baja 16,73 s.
- Seis semillas finales: 24/24 llegadas, bots entre 81,06 y 84,83 s,
  con 3–15 impactos por carrera. Mantener pulsado arriba registra 17 impactos;
  no pulsar registra 15. Los extremos siguen siendo atravesables con penalización,
  tal como se pidió para las formaciones verticales.
- Prueba física nueva: 120 ticks empujando contra cada cara horizontal de una
  isla; el globo no la atraviesa ni recibe una excepción durante la protección.
  Las pruebas anteriores de recuperación al atravesar rocas verticales pasan.
- Se actualizan las coordenadas de recogida de las pruebas para usar los nodos
  reales. El antiguo vuelo que exigía atravesar el divisor deja de ser válido;
  se sustituye por pruebas de solidez. La monotonía estricta se exige en vuelos
  limpios: un choque contra una pendiente sólida puede producir retroceso local.
- Los ensayos iniciales detectaron bloqueos de bots sobre la entrada de S3.
  Dar prioridad al paso de las islas sólidas los resolvió en las seis semillas
  finales. Los resultados fallidos intermedios no se cuentan como validación.

Logs locales: `.godot/balance-{valle_redesign,track,competition,world_visual}-delivery.log`,
`.godot/balance-turbo-release.log`, `.godot/balance-chaos-accepted.log` y
`.godot/balance-{obstacle,flying_creature,race_flow}-final.log` y
`.godot/balance-items-delivery.log`.
Importación con salida 0; persisten errores ambientales de certificados y de
guardado de ajustes del editor fuera del workspace. No hubo errores de GDScript
en las ejecuciones finales indicadas. Mapa PNG/SVG regenerado y geometría revisada.

El playtesting humano de dificultad, lectura del viento y sensación de solidez
queda pendiente; las simulaciones no acreditan diversión ni balance competitivo.

## Pasos estrechos y corriente inferior — 2026-10-25

Este ajuste posterior sustituye las dimensiones y la ubicación de la corriente
de S4 descritas en el balance anterior. No cambia física, habilidad de bots,
cantidad de cajas, multiplicadores ni reglas de colisión.

- **S3 y S5:** islas con crestas Y=200/210, depresión Y=400 y base Y=420.
  El techo central baja hasta Y=240. Los pasos superiores críticos miden
  168/178 px en las crestas y 160 px en el centro; abajo quedan 220 px.
  El globo mide 118,8 px de alto: quedan 41,2–59,2 px verticales totales
  en los estrechamientos superiores. Las pruebas físicas reservan además
  10 px por lado al buscar un paso continuo, incluyendo el ancho del globo.
  Las rampas de entrada/salida se conservan para permitir la transición.
- **S4:** el divisor ocupa Y=330–450. Arriba quedan 298 px, reducidos a
  210 px junto a la roca más profunda; abajo quedan 190 px, reducidos a
  150 px en LowerRouteRock. La puerta de entrada inferior se ajusta a Y=600.
  La ruta inferior exige más precisión y recibe las tres corrientes ×1,20,
  de 350×24 px, en (10800,550), (11700,550) y (12600,550).
  Se renombran a LowerCurrent, LowerCurrentMiddle y LowerCurrentExit.
  No queda corriente en la rama superior de S4.
- Se ajustan las alturas de las cajas afectadas, el marcador de ruta baja y
  los carteles «ALTA · amplia» / «BAJA · rápida y precisa». Se conservan las
  cuatro cajas de cada sector y las dos oportunidades por rama de S4.
  El mapa PNG/SVG se regenera desde Track01.

### Evidencia del estrechamiento

Godot 4.7.2, física a 60 Hz. Las pruebas revisan las diferencias de anchura,
la posición inferior de las tres corrientes, sus sensores fuera de roca,
el paso del globo con margen y las cajas accesibles.

- Recorrido superior técnico sin impactos: 81,48 s con viento, 82,52 s sin él.
  Alternativa inferior de S3/S5, también limpia: 82,37 s.
- Ambas ramas de S4 sin impactos: superior 16,733 s, inferior 15,767 s.
  La prueba comprueba que sólo la rama inferior recibe viento durante S4.
- Competición: seis semillas, 24/24 llegadas. `competition`, `chaos` y
  `world_visual` PASS; logs `.godot/narrow-{competition,chaos,world_visual}-v3.log`.
- Recorridos y geometría: `track` y `valle_redesign` PASS, cero fallos;
  logs `.godot/narrow-{track,valle_redesign}-final.log`.
  Las configuraciones preliminares con roces o polígonos inválidos se descartaron;
  no forman parte de los resultados finales. Persiste el aviso ambiental de
  certificados de Windows.

Validación humana pendiente: comodidad de los márgenes mínimos, lectura de la
ruta inferior rápida y maniobras con turbo u objetos. La evidencia automatizada
demuestra transitabilidad; no establece un mínimo universal de comodidad.

## Habilidad de bots: 20 % adicional — 2026-10-25

Historial del ajuste intermedio; reemplazado por el multiplicador 1,75 descrito a continuación.

`BotProfile.skill_multiplier` pasa de 1,30 a **1,56** (1,30 × 1,20), compartido por los tres perfiles existentes. El paso del inspector es ahora 0,01 para representar ese valor exactamente. Se conserva el sistema: anticipación multiplicada por habilidad; reacción, tolerancia de altura y error divididos por ella. Respecto del ajuste anterior, la anticipación aumenta un 20 % y esos tiempos/márgenes bajan un 16,67 %. No se modifican velocidad, física, rutas, objetos, terreno ni arte.

Comparación automatizada en Godot 4.7.2, headless a 60 Hz, semillas 1–6 idénticas, objetos y turbo activos: `competition_test.gd -- 6` PASS antes y después. Llegan los 18/18 bots en ambas muestras (24/24 participantes contando al humano pasivo). El tiempo medio de bots pasa de 82,737 s a 82,673 s; las colisiones acumuladas bajan de 105 a 97 (7,6 %). Primeros entre bots: antes Lord 3 / Greta 2 / Timo 1; después Lord 3 / Greta 3 / Timo 0. Son resultados observados, no victorias forzadas ni garantías de mejora en cada carrera.

Evidencia: [simulaciones con 1,30](bots-skill-130-simulations.json) y [simulaciones con 1,56](bots-skill-156-simulations.json). Logs locales `.godot/bots-{130,156}-competition.log`. Persisten avisos de certificados y recursos/ObjectDB al cerrar; ambas suites terminan con cero fallos. El participante humano no pulsa teclas en esta prueba: no permite medir dificultad frente a una persona activa. Queda pendiente jugar carreras para evaluar competitividad percibida; esta muestra solo muestra menos choques y un cambio mínimo de tiempo medio.

## Habilidad de bots: nivel solicitado del 75 % — 2026-10-25

Interpretado como +75 % sobre la habilidad base original: `BotProfile.skill_multiplier = 1.75`, frente a 1.56 anterior. El sistema existente no define un máximo absoluto de capacidad ni una escala porcentual normalizada; 1.75 es el multiplicador de anticipación y el divisor de reacción/tolerancias/error. Se mantienen perfiles, velocidad y físicas.

Godot 4.7.2, seis semillas iguales a la comparación anterior: `competition_test.gd -- 6` PASS, 18/18 bots y 24/24 participantes llegan. Tiempo medio de bots 82,641 s (antes 82,673 s); colisiones totales 85 (antes 97). Victorias entre bots: Lord 3, Timo 2, Greta 1. [Resultados completos](bots-skill-175-simulations.json). El humano permanece pasivo en estas simulaciones; pendiente evaluar dificultad con conducción humana.

Controles vigentes: Esc pausa/reanuda y abre el panel con acceso al menú; desde el podio vuelve al Home. Espacio activa turbo y Z usa el poder equipado. Detalles, pruebas y límites en [controles y pausa](controls-pause.md).

## Habilidad de bots: nivel solicitado del 85 % — 2026-10-25

Valor vigente: `BotProfile.skill_multiplier = 1.85`, frente a 1.75 anterior, siguiendo la escala acordada de aumento sobre la base original. Se conserva el resto de la configuración, controles y jugabilidad.

Godot 4.7.2, `competition_test.gd -- 6` a 60 Hz: PASS, cero fallos; llegan 18/18 bots y 24/24 participantes. Con las mismas seis semillas, tiempo medio de bots 82,230 s (antes 82,641 s) y 78 colisiones (antes 85). Ganadores entre bots: Timo 3, Greta 2, Lord 1. [Resultados](bots-skill-185-simulations.json); log local `.godot/bots-185-competition.log`. Persisten avisos del entorno de certificados y ObjectDB al cerrar. El humano de la simulación permanece pasivo; pendiente valorar dificultad jugando contra una persona activa. Sin commit.
