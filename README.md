# Balloon Racing — M7.2: presentación y UX

Home V2.1: personajes +30 %, logo +25 %, flotación subpíxel y Theme global
Fredoka/Lilita One. Music usa los nuevos MP3 de Home y carreras, con fade-in
y selección aleatoria por carrera. Integración: [docs/music-v2.md](docs/music-v2.md).
Valores visuales, licencias y validación:
[docs/home-v2.1.md](docs/home-v2.1.md).

El selector usa los nuevos assets, fichas de personalidad y navegación con
mouse, teclado y mando. Correspondencia de imágenes y validación en
[docs/character-selection.md](docs/character-selection.md).

Godot 4.7.2 Standard y GDScript. Prototipo local: un humano y tres bots.

## Jugar

### Valle Ventoso 2.0 — blockout experimental

Pase visual de Valle Ventoso: roca ilustrada y agua tomadas de la lámina
`pista1_elements.png` proporcionada por el usuario, vegetación colgante, molinos
y puentes del kit existente. Los detalles se recortan contra las caras reales
de los obstáculos, sin nuevos colliders. Se retiran las capas de islas medias
y primer plano: quedan cuatro capas de parallax, con menor opacidad y nubes
cercanas por debajo del área de vuelo. Ajuste: `background_opacity` en
`scripts/world_visual.gd`. No se mueve ni modifica la geometría de Track01.

Seis sectores rediseñados, conservando límites, meta, física, turbo y 32 cajas.
S2 incorpora una isla con paso superior/inferior; S3 y S5 combinan islas
irregulares, techo y tres tramos de corriente a 1,20 que requieren dos cambios
de altura. S4 conserva la única bifurcación y añade un embudo de entrada.
S6 añade una segunda montaña y un tercer Flappy antes del sprint despejado.
Los bots toman el paso inferior local de las islas técnicas; mantienen sus
perfiles y la elección de S4. No se añadieron sistemas de navegación ni poderes.

[Resultados y pendientes](docs/valle-ventoso-2.md),
[coordenadas de nodos cambiados](docs/valle-ventoso-2-coordenadas.md) y
[mapa geométrico actualizado](docs/mapa-geometrico-valle-ventoso.svg).
Prueba específica: `tests/valle_redesign_test.gd`; el punto de entrada antiguo
`valle_incremental_test.gd` reutiliza esa suite. Capturas por sector:
`tests/valle_preview.gd` con renderizado. Regenerar mapa desde la escena:
`python tools/generate_track_map.py`, luego `./tools/render_track_map.ps1` en Windows.

### Flappy — obstáculos vivientes 1.0

Tres instancias exclusivas de Valle Ventoso: centro de S2 **(4450, 340)**,
S5 **(13600, 340)** y S6 **(17950, 400)**. S2/S5 conservan oscilación vertical
sinusoidal de ±45 px, período 3 s, fases 0°/120° y X fija; S6 usa ±30 px,
3,6 s y fase 210°. La escena reutilizable
`scenes/FlyingCreatureObstacle.tscn` usa `AnimatableBody2D` actualizado en física;
su cápsula de 70×82 px cubre el cuerpo, excluyendo alas, cresta y estrellas.
Texturas, escala visual, amplitud/período/fase y reacción son configurables;
la forma/tamaño se editan en `CollisionShape2D`. No hay reglas de mundo en el script.

Usa los PNG entregados `living_obstacle.png` y `living_obstacle_punch.png`.
El shader deforma las puntas de alas y anima párpados, sin generar sprites.
Impacto: pose punch durante 0,4 s, recuperación visual y penalización/sonido
estándar del globo. Se reutiliza la excepción de colisión hasta despejarlo
horizontalmente: un contacto no acumula penalizaciones. Flappy permanece vivo.
Pausa congela cuerpo y animación. Movimiento reducido atenúa efectos al 20 %,
sin cambiar oscilación jugable. Los bots consideran el barrido vertical con
una adaptación local, conservando perfiles y lógica de vuelo.

Validación inicial de Flappy 1.0 en Godot 4.7.2: 11 suites PASS (flying_creature, obstacle, flight, turbo,
items, arcade_feedback, world_visual, track, pause, game_feel, competition).
La suite nueva verifica 30/60/120 Hz simulados, collider, pasos arriba/abajo,
impacto único, recuperación, pausa y efectos reducidos. Track mantiene dos
rutas controladas sin colisiones; se actualizó su conductor de prueba para
esquivar los encuentros. Competition: tres semillas, todos los corredores en
meta, sin bloqueos. Flying_creature también PASS en ventana ANGLE; capturas
revisadas de ambos sectores. Logs/capturas: `.godot/flappy-*`.

Rendimiento histórico de Flappy 1.0 A/B: 1280×720, ANGLE/Intel HD, cuatro turbos en posición fija en
S2, VSync desactivado; tres pares alternados, 60 frames de calentamiento y
90 dibujados por muestra. Sin/con Flappy: **33,28/32,35 FPS**, **30,05/30,91
ms/frame** (+0,87 ms), 116/117 draw calls. Las dos criaturas se actualizan;
solo S2 aparece en cámara. Repetir `tests/feel_benchmark.gd -- etiqueta s2`,
añadiendo `no_flappy` para el control. No acredita 60 FPS ni rendimiento de
toda una carrera. Persisten avisos ambientales de certificados/recursos al
cerrar Godot. Pendiente playtesting humano de anticipación y apariencia;
los bots aún pueden chocar ocasionalmente. No se hicieron commits.

Referencia consultada: [AnimatableBody2D](https://docs.godotengine.org/en/stable/classes/class_animatablebody2d.html).

`music_home_v2.mp3` acompaña menú, cuenta atrás y podio.
Al dar GO se elige `music_race_01.mp3` o `music_race_02.mp3`; se mantiene durante
toda la carrera y se reproduce en bucle. Los WAV anteriores se conservan.
Los cambios usan un fundido de 0,25 s por lado. SPACE pausa ambos.

Efectos originales: colisión, turbo y explosión de bomba/misil. Se emiten
al producirse el evento aceptado; un turbo rechazado o un impacto protegido
no repite el sonido. Los bots usan los mismos efectos, atenuados por distancia
a la cámara. Hasta ocho voces simultáneas; podio y reinicio limpian los efectos.

Ajustar en `scenes/Music.tscn`: `volume_db` para música (-14 dB),
`effects_volume_db` para efectos (-12 dB), `effects_distance` (1000 px) y
`transition_seconds` (0,25 s). Los WAV están en `assets/audio`.
Regenerar sin dependencias ni samples externos:
`python tools/generate_music.py` (original),
`python tools/generate_music.py --race` (carrera) y
`python tools/generate_effects.py` (efectos).

`tests/race_audio_test.gd` verifica GO/podio, bucles, colisiones, ambos turbos,
bombas, misils, pausa y reinicio. También pasan music, menu, pause,
race_flow, items, turbo y obstacle. Persiste el aviso de referencias de audio
pendientes al cerrar Godot 4.7.2, ya observado antes de este cambio.
La mezcla y el carácter musical requieren evaluación auditiva manual.

Abrir project.godot y pulsar F5. El Home ofrece ¡CORRER!, Selección de personaje,
Entrenamiento M7.1, Cómo jugar y Opciones de audio. Entrenamiento M7.1 abre una
sesión de un jugador sin competidores, con cuatro zonas y una duración objetivo de
60–90 segundos; la implementación y sus pruebas automatizadas existen, pero la
experiencia completa todavía requiere playtesting humano.
¡CORRER! inicia con la elección actual, indicada en el Home. Selección de personaje
abre las tarjetas de Calaca, Timo, Greta o Lord Pomposo con ratón o flechas/Tab y Enter. Pulsar
**Comenzar carrera**: tras 3… 2… 1… ¡YA! comienza el reloj. La selección es
visual, todos conservan la misma física; los bots usan los personajes restantes.
La elección se conserva al reiniciar durante esta sesión.

Escape o Volver regresan al Home desde sus paneles y la selección.
Los niveles de música y efectos se guardan entre sesiones. Ver `docs/home.md`.
El podio muestra cuatro retratos según la clasificación real, estadísticas y TÚ
en el puesto del jugador. Otra carrera conserva la selección; Menú principal
o Escape vuelven al Home. Detalles y pruebas: `docs/menus.md`.

- Flecha arriba (UP): mantener para ascender; soltar para descender con inercia.
- D: turbo personal. Todos comienzan con **2 cargas**, independientes del inventario.
- A: usar el objeto equipado. Sólo se almacena uno.
- SPACE: pausar/reanudar, también durante la cuenta atrás. No pausa en resultados.
  El panel PAUSA permite Continuar, Reiniciar carrera o Volver al menú principal; Enter activa el botón enfocado.
  La pausa congela cuerpos, IA, proyectiles, efectos, cajas y reloj de carrera.
- F2: progreso, posición, velocidad, cargas, objetos usados, tormentas y viento.
- Otra carrera: reiniciar desde el podio, restaurando todos los estados.

El turbo personal está disponible 5 s después de GO. Hay 12 s mínimos entre
cargas; no se regeneran ni se consumen durante otro boost o fuera de carrera.
Los bots eligen tramos despejados. El HUD muestra cargas y tiempo de espera.

## Objetos y remontada

Actualización arcade (2026-10-22): las bombas detonan al tocar corredores,
también al aparecer solapadas; mantienen radio, fusible y protección del
lanzador de 0,4 s. Tras esa protección, el lanzador también puede detonarlas.
El contacto por arriba empuja al rival hacia abajo, alejándolo de la explosión.
Bombas/misiles muestran una cola visual de 0,55 s con onda, fuego, chispas y humo,
sin aplicar golpes adicionales. El misil conserva alcance, velocidad y golpe
individual; su aspecto ahora es turquesa/latón con aletas y punta roja.
HUD, entrenamiento y traducciones usan «Misil» / «Missile»; se conserva el enum
interno ROCKET para compatibilidad. La opacidad de rivales superpuestos pasa
de 45 % a 60 %; el jugador local sigue opaco. Parpadeo y gestos de brazos:
[personajes](docs/characters.md#gestos-de-pilotos--2026-10-22).

Prueba de contacto/solapamiento, protección, golpe único, limpieza, pausa y
nombre: `tests/arcade_feedback_test.gd` (sin `--headless` también guarda
`.godot/arcade-feedback.png`). Pasan además items, race_audio, visibility,
natural_motion, characters, polish, hud, training, pause y game_feel.
También pasan chaos, race_flow y competition (tres semillas con los cuatro
corredores llegando): catorce suites en total para esta intervención.
Capturas revisadas con ANGLE; persisten avisos de certificados/ObjectDB del
entorno. La intensidad y naturalidad requieren revisión humana en movimiento.

Las **32 cajas** se distribuyen en distintas alturas y ambas rutas. Mantienen
su sensor de 48×48 px. Una caja reaparece tras **8 s**; quien la recogió debe
salir del sensor antes de poder recogerla otra vez. Un inventario lleno no
consume la caja. No hay generación continua de cajas nuevas.

- Misil: horizontal, 720 px/s, vida 2,5 s; impacta rivales y escenario.
- Bomba: gravedad 650 px/s², fusible 1,8 s, radio 120 px, impulso hasta 90 px/s.
- Turbo (antes Superquemador): ×1,35 durante 2 s, igual que las cargas personales.
- Tormenta: ataca al líder que sigue compitiendo y está delante del usuario.
  Si no hay objetivo válido o está protegido, conserva el objeto.
  Nube/advertencia 0,8 s, penalización ×0,65 por 1,5 s y protección de 4 s
  desde la advertencia. No cancela el control vertical ni persigue un nuevo
  líder si cambia la clasificación durante la advertencia.

Probabilidad de Tormenta por puesto activo: **0 / 5 / 15 / 25 %**. El resto
se reparte entre misil, bomba y Turbo con pesos iniciales 1:1:1, tanto para
humanos como bots. No se garantizan objetos concretos por caja.

## Pista y velocidad

Valle Ventoso conserva 18.160 px, seis zonas y 17 formaciones. Hay cuatro
corrientes ×1,20: recuperación de S3, rama superior, reunión de rutas y corredor técnico.
Flechas azules indican sus áreas. La rama baja ofrece una alternativa más segura.

La intervención experimental 01 añade viento opcional tras FirstCorridor,
amplía la preparación de entrada a S4 y adelanta obstáculos/cajas de S6 para
dejar 680 px abiertos hasta meta. Resultados y revisión humana pendiente:
[reconocimiento, sección F](docs/valle-ventoso-reconocimiento.md#f-intervención-experimental-01).

La velocidad se calcula en un solo lugar: base × mayor ayuda × menor
multiplicador de penalización, más el rebote temporal de M2.

- Ayudas: máximo entre 1, Turbo y corrientes, con tope configurable ×1,35.
- Penalizaciones: la más fuerte entre obstáculo, misil/bomba y Tormenta.
- Ni corrientes superpuestas ni varios ataques multiplican sus efectos.
- Al salir del viento desaparece su ayuda; cada efecto temporal caduca.

Gravedad 350, quemador 650, avance 220 y límite vertical 250: sin cambios.
Los globos tienen escala visual 0,88 y colisión 77,44×118,8 px. El contorno,
TÚ y transparencia local se conservan; no se separan cuerpos artificialmente.

La meta registra orden y tiempo reales. Tras llegar el humano se espera
hasta 8 s al resto; los DNF no reciben tiempos inventados. Hay podio y reinicio.

## Parámetros

- resources/default_balloon_physics.tres: física y choques de escenario.
- resources/default_items.tres / scripts/item_config.gd: objetos, tormentas,
  probabilidades, reaparición de cajas y tope de ayudas de velocidad.
- resources/default_turbo.tres: cargas iniciales por tipo, espera e intervalos.
- resources/bot_*.tres: anticipación 430/510/580 px; reacción 0,31/0,27/0,24 s;
  tolerancia 18/14/12 px; error espacial suave 43/36/32 px. Variación de
  anticipación ±55 px. Probabilidad de rama alta 0,40/0,45/0,55.
- Track01/WindZones: posición, tamaño y multiplicador de cada corriente.
- Main/RaceFlow: cuenta atrás y timeout. Main/race_seed positivo: reproducción
  a igual frecuencia; cero: nueva semilla. No hay resultados forzados.

## Validación

Reconocimiento jugable de Valle Ventoso (sin rediseño):
[informe, oportunidades y evidencia](docs/valle-ventoso-reconocimiento.md),
[mapa técnico de seis sectores](docs/valle-recon/mapa.html).

Desde PowerShell, en la raíz:

~~~powershell
$godot = "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64_console.exe"
& $godot --headless --path . --editor --import --quit
& $godot --headless --path . --fixed-fps 60 --script res://tests/characters_test.gd
& $godot --headless --path . --fixed-fps 60 --script res://tests/menu_test.gd
& $godot --headless --path . --fixed-fps 60 --script res://tests/pause_test.gd
& $godot --headless --path . --fixed-fps 60 --script res://tests/chaos_test.gd
& $godot --headless --path . --fixed-fps 60 --script res://tests/turbo_test.gd
& $godot --headless --path . --fixed-fps 60 --script res://tests/race_flow_test.gd
& $godot --headless --path . --fixed-fps 60 --script res://tests/competition_test.gd -- 6
& $godot --path . --fixed-fps 60 --script res://tests/chaos_visual_test.gd
~~~

También existen flight_test, obstacle_test, track_test, race_test,
items_test y visibility_test. Las capturas y simulaciones se guardan en
.godot. Ver docs/milestone-6.3-verification.md para resultados y límites.
La actualización de entrada y pausa se verifica en docs/controls-pause.md.

La transitabilidad automatizada no valida comodidad, balance ni diversión.
Probar manualmente D y A simultáneos con flecha arriba, las dos ramas, cajas
reaparecidas, Tormenta y adelantamientos. Revisar podio y Otra carrera.

## Proyecto

scenes contiene escenas reutilizables; scripts la lógica; resources los
parámetros; tests las pruebas sin dependencias y docs el historial.
La plataforma principal aprobada es PC/Steam. Android e iOS quedan pospuestos,
conservando compatibilidad futura mediante los presets de exportación existentes.
.vscode mantiene el perfil de ejecución y configuración del editor externo.
Godot Tools usa el servidor de lenguaje del editor en 127.0.0.1:6005.
Conservar los .uid generados por Godot; .godot se ignora en Git.

Repositorio independiente de C:/Workspace/balloon-racing (Phaser).
No se crean commits automáticamente. Sin networking ni plugins nuevos.

## Personajes ilustrados

`Balloon.character_id` selecciona calaca, timo, greta o pomposo. El cat?logo
centraliza nombres, texturas y anclajes de canasta. Visual reutiliza
CharacterSprite para idle/burner/turbo/hit/victory y mantiene Artwork como
fallback ante un identificador inv?lido o ausencia de idle. Una pose ausente
usa idle. Solo el primer corredor registrado en meta celebra la victoria.

Las im?genes son poses independientes, no fotogramas consecutivos. Escala
uniforme y anclaje visual conservan la colisi?n y el movimiento. El contorno
local sigue la silueta; T?, prioridad y transparencia siguen activos.
Ver docs/characters.md para arquitectura, comprobaciones y l?mites visuales.

## M7.2 — presentación y UX

Cuenta atrás animada, entrada solo visual, línea de salida, anclajes por pose,
inclinación y reacción amortiguada, halo de cajas y explosiones expansivas.
El HUD coloca inventario/turbo a la izquierda y posición/progreso con retratos a
la derecha. La ruleta dura 1,55 s: el nombre siempre muestra el objeto real,
que puede usarse inmediatamente. Se cancela al consumirlo.

Pausa permite volver al Home y limpia los efectos. Entrenamiento reutiliza el
mismo componente de inventario y la tipografía global. Los textos M7.2 y las
instrucciones M7.1 tienen catálogos `localization/es.po` y `en.po`, registrados
en Godot y basados en el POT existente. No se añade selector de idioma: se usa
el locale del sistema, con fallback español; para comprobar inglés ejecutar
Godot con `--language en`. Los menús históricos aún tienen cadenas sin traducir.

`Music.countdown_sound` y `race_start_sound` son puntos de integración opcionales:
faltan sonidos apropiados de cuenta atrás y fanfarria/vitoreo. Tormenta reutiliza
el impacto `collision.wav`. No se han creado assets definitivos.

Ver [verificación M7.2](docs/milestone-7.2-verification.md) para pruebas,
archivos, limitaciones y revisión humana pendiente. Ejecutar además:

```powershell
& $godot --headless --path . --fixed-fps 60 --script res://tests/polish_test.gd
```

## HUD V1 — PNG integrados

La carrera usa los marcos de `assets/ui/hud/`: objeto y cargas a la izquierda,
reloj y tramo arriba al centro, puesto y cuatro filas ordenadas a la derecha,
y avance abajo al centro. Pausa se abre con SPACE o el botón inferior izquierdo.
F2 conserva debug y ayuda; el entrenamiento mantiene su presentación.

Los datos siguen viniendo de RaceFlow, RaceStandings, BalloonTrack y
BalloonItems. El turbo conserva cargas, sin barra de combustible. Los nombres
`icon_rocket.png` e `icon_bomb.png` del kit están invertidos respecto a su dibujo;
el mapeo los corrige sin editar los PNG. Detalles, capturas, pruebas y límites en
[HUD V1](docs/hud-v1.md). Este apartado sustituye la presentación provisional
M7.2 descrita arriba; no cambia sus reglas ni resultados históricos.

```powershell
& $godot --headless --path . --fixed-fps 60 --script res://tests/hud_test.gd
```

## Ruleta y gestos (2026-10-22)

La ruleta mantiene 1,55 s sin retrasar el uso del poder. Parpadeo base de
1,75 s y gestos de brazos cada 2,75 s. Los sonidos añadidos en esta intervención
se retiraron por solicitud del usuario: se restauraron los efectos anteriores,
sin voces de personajes ni sonidos de recogida o ruleta.

## Game Feel 2.1 — rendimiento y fluidez (2026-10-22)

Las estelas y motas de cada globo se dibujan en un solo lote, igual que los
trazos de cada corriente: se evitan líneas individuales con antialias que
fragmentaban el dibujo en ANGLE. El parallax reutiliza sus comandos entre
cruces de mosaicos, conservando capas, profundidad y deriva. No se cambian
física, IA, colisiones, duración/velocidad/cargas del turbo, mapa ni HUD.
Los cambios anteriores de contacto de bombas, misil y opacidad se preservan.

El turbo tiene compresión visual de 0,06 s antes de su pulso, estelas más
largas y recuperación interpolada de color. La anticipación no retrasa la
aceleración real. Las corrientes tienen trazos proporcionales a su fuerza.
Parpadeo base cada 2,5 s con desfase por piloto; gestos de brazos de 1,2 s
cada 3,5 s, con entrada/salida suaves y descanso. Reducir movimiento conserva
la atenuación al 20 % y detiene la deriva ambiental.

Medición reproducible: `tests/feel_benchmark.gd`, Godot 4.7.2, ventana
1280×720, Compatibility/ANGLE, Intel HD Graphics Family, D3D11 driver
8.15.10.2353. VSync desactivado, sin límite de FPS, `--fixed-fps 60` solo
para tiempo simulado. Semilla 21, cuatro globos en posiciones fijas con turbo
continuo, escenario/HUD/audio activos, física competitiva detenida. Por modo:
60 frames de calentamiento y tres muestras de 90 frames realmente dibujados
(`RenderingServer.frame_post_draw`, reloj de pared). No es una carrera humana.

- Normal: **18,57 → 32,54 FPS**, **53,84 → 30,73 ms/frame**; 172 → 120 draw calls.
- Reducido: **21,53 → 35,68 FPS**, **46,44 → 28,03 ms/frame**; 166 → 114 draw calls.
- FPS calculados como inversa del tiempo medio conjunto. JSON/logs originales
  en `.godot/feel-bench-before.*` y `.godot/feel-bench-after.*`.

Repetir sin otras aplicaciones gráficas exigentes:

```powershell
& $godot --path . --fixed-fps 60 --script res://tests/feel_benchmark.gd -- after
```

Validación automatizada: importación sin errores de scripts; 12 suites
headless PASS (game_feel, natural_motion, arcade_feedback, world_visual,
turbo, items, pause, characters, flight, visibility, polish y competition).
Competition completó tres carreras, semillas 1–3, con los cuatro corredores
en meta. Game_feel, natural_motion y visibility también PASS con renderizado
ANGLE; capturas de turbo y pilotos inspeccionadas. Se verifican pausa,
reducción de movimiento, collider y RNG; hashes de vuelo, objetos, combate,
proyectiles y Track01 coinciden con el inicio de esta intervención.
Logs: `.godot/feel21-*.log`. Persisten avisos ambientales de certificados y
de ObjectDB/recursos al cerrar algunas suites; no equivalen a validación humana.

Esta medición sigue por debajo de 60 FPS en este equipo. Los sonidos nuevos
se retiraron por solicitud del usuario; se conserva el audio anterior.
Pendientes perfilado en hardware objetivo y playtesting humano.

Referencias: [dibujo agrupado CanvasItem](https://docs.godotengine.org/en/stable/classes/class_canvasitem.html#class-canvasitem-method-draw-multiline-colors)
y [optimización GPU](https://docs.godotengine.org/en/stable/tutorials/performance/gpu_optimization.html).

## Game Feel 2.0 — primera intervención (2026-10-21)

Actualización 2026-10-22: movimiento interno continuo de globo/canasta/piloto,
recuperación con inercia y mezcla reversible de poses, manteniendo física y arte.
Detalles y pruebas actuales en [personajes](docs/characters.md#movimiento-continuo--2026-10-22).

Presentación visual en la rama `work/game-feel-2`, conservando el trabajo local
previo de Valle Ventoso. No cambia vuelo, IA, colisiones, objetos ni cámara.

- `scenes/Balloon.tscn`, `scripts/balloon_visual.gd` y `flight_effects.gd`:
  inclinación interpolada, balanceo desfasado por corredor, anticipación de
  quemador, squash/recuperación, pulso de turbo y siete estelas con motas.
  Los efectos leen estados aceptados; una sola reacción de impacto, sin inventar
  categorías de fuerza. Se dibujan en un hijo para preservar CanvasGroup.
- `scripts/wind_zone.gd`: flujo cian hacia la derecha, graduado por el
  multiplicador existente. El globo acusa entrada/salida y desvanece su estela.
- `scripts/world_visual.gd` y `world_parallax_layer.gd`: dos capas de nubes
  derivan a distinta velocidad; vegetación/banderas oscilan y seis motas tenues
  acompañan el suelo. Solo se transforman decoraciones, nunca colliders.
- `scripts/home.gd` y `game_feel.gd`: Opciones ofrece «Reducir movimiento y
  efectos», persistido en `user://presentation.cfg`. Reduce reacción/estelas al
  20 %, ralentiza viento y detiene deriva, vegetación, motas y entrada de globos.
  Las poses informativas se conservan. Intensidades locales usan `@export`.

Se reutilizan los 20 PNG idle/burner/turbo/hit/victory, el viento lateral,
las capas y decoraciones de Valle Ventoso, y los eventos/sonidos ya sincronizados
`turbo.wav`, `collision.wav` y `explosion.wav`. La música y el HUD se conservan.
No se separan canastas ni pilotos de ilustraciones aplanadas. Pendientes de
producción: aspas/torre separadas para girar molinos; pose específica de
adelantamiento; sonidos de encendido, recogida, corriente, adelantamiento y
meta (también sigue pendiente la cuenta atrás). Hit/victory ya cubren choque
y ganador; no se inventan expresiones ni sonidos sustitutos.

Validación automatizada: importación en Godot 4.7.2 sin errores de scripts;
20 suites PASS: game_feel, polish, flight, obstacle, turbo, items, characters,
pause, world_visual, race_audio, home, home_polish, race_flow, track,
valle_incremental, menu, hud, visibility, chaos y competition (seis semillas,
cuatro corredores llegando). Se actualizan dos expectativas obsoletas en
world_visual/home_polish: deriva de nubes/número de corrientes de la pista
actual y propiedad del ajuste de snapping al entrar al selector.
La prueba nueva cubre inclinación, turbo, impactos, viento, pausa, collider,
RNG competitivo y reducción de movimiento. Logs/capturas: `.godot/game-feel-*`.

La ejecución gráfica usa ANGLE en esta GPU Intel antigua y no acredita 60 FPS
estables: cuatro turbos activos procesaron 180 frames en 9,35 s (aproximadamente
19,2 frames/s en esta muestra). La medición es diagnóstica, con posiciones/entradas forzadas;
queda pendiente perfilar en el PC objetivo y hacer playtesting humano de
fluidez, legibilidad, poses y mezcla. Persisten avisos de certificados del
entorno y de recursos/ObjectDB al cerrar algunas suites. La primera ejecución
restringida tampoco podía escribir el perfil de Godot; las comprobaciones
posteriores usan APPDATA aislado bajo `.godot/game-feel-profile`.

Probar: F5 → ¡CORRER!, mantener/soltar ↑, D tras cinco segundos, chocar,
entrar/salir de una corriente y pausar con SPACE. Comparar con la opción de
movimiento reducido. Ejecutar `tests/game_feel_test.gd` como las suites de
arriba; sin `--headless` guarda capturas de turbo, impacto y Opciones.
La aceptación del Game Feel corresponde al Game Owner mediante juego humano.

Referencias consultadas: [interpolación independiente de FPS](https://docs.godotengine.org/en/stable/tutorials/math/interpolation.html)
y [dibujo 2D](https://docs.godotengine.org/en/stable/tutorials/2d/custom_drawing_in_2d.html).
