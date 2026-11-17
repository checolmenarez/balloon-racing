# M8.1 — Rediseño de gameplay de Vuelo Libre

Fecha de implementación técnica: 2026-11-10. Estado: listo para evaluación
humana del Game Owner. Las pruebas automatizadas y la inspección de capturas no
demuestran diversión, justicia percibida ni balance final.

## Resultado implementado

Vuelo Libre dejó de construir el recorrido activo con puertas rectangulares
genéricas. El generador usa ocho patrones diseñados, rutas seguras explícitas y
variación controlada. Cada patrón conserva una entrada con anticipación, un
desafío reconocible y una salida conectada con el siguiente segmento:

1. `progressive_ascent`: tres relieves inferiores que enseñan a ascender.
2. `anticipated_descent`: tres formaciones superiores que exigen soltar antes.
3. `high_low_alternation`: alternancia inferior/superior/inferior.
4. `narrow_passage`: embudo con hueco configurable y posible salida técnica.
5. `dual_route_island`: isla suspendida con ruta segura y ruta de riesgo.
6. `wind_shift`: dos cambios de altura apoyados por corrientes rápidas.
7. `flappy_encounter`: relieve de entrada, barrido vertical y escape seguro.
8. `recovery`: zona abierta periódica; algunas variantes no tienen monedas.

El primer segmento es un ascenso accesible, no una zona vacía. No se repite el
mismo patrón de forma inmediata. Los patrones avanzados se habilitan después
del tramo inicial y se intercala recuperación cada seis segmentos.

## Reutilización de Valle Ventoso 2.0

`SinglePlayerSegmentManager` instancia `Obstacle.tscn` y obtiene en tiempo de
ejecución la geometría vigente de `Track01.tscn`; no mantiene una copia paralela
de sus polígonos. Reutiliza las siluetas de `GentleMountain`, `RisingMountain`,
`AlternatingLower`, `AlternatingLowerB`, `IntroUpper`, `DeepHangingRock`,
`FirstCorridor`, `AlternatingUpperA`, `EntryFunnel`, `TechnicalIslandS3`,
`PrecisionB` y `PrecisionC`, inspiradas especialmente por S3–S5.

El acabado llama al kit actual de `terrain_kit_visual.gd`. Arte y colisión parten
del mismo polígono de `FlightObstacle`; las capturas verificadas muestran roca,
musgo y contornos coherentes con Valle. `SinglePlayerGate` permanece sólo como
archivo histórico de M8 y no aparece en el recorrido activo. No se modificó
`Track01.tscn` ni el mapa de Carrera.

## Coleccionables y Flappy

- Las monedas forman diagonales ascendentes/descendentes, arcos, rutas seguras y
  alternativas de riesgo. Hay zonas de alivio sin monedas; ya no existe una
  hilera horizontal continua como patrón dominante.
- Las estrellas sólo se intentan en patrones de riesgo, mantienen un mínimo de
  ocho segmentos entre apariciones y su posición se comprueba con las
  dimensiones completas del globo contra los colliders.
- Flappy conserva su escena reutilizable. Sólo las instancias de Vuelo Libre
  interpolan amplitud de 44 a 70 px y período de 3,25 a 2,65 s. La fase depende
  del índice del segmento y siempre existe una ruta exterior al barrido.
- Se conservan contador/sonido individual de moneda, curación, tope de vida y
  protección tras impacto.

## Curva de dificultad y velocidad real

Los valores editables viven en `SinglePlayerConfig`:

- velocidad inicial: 220 px/s;
- incremento: +5,5 % cada 900 px, continuo en vez de escalones discretos;
- máximo: ×1,55 (341 px/s);
- transición de velocidad: 1,8/s;
- tramo intermedio: 3.600 px; avanzado: 9.000 px;
- dificultad geométrica: 1.200–9.000 px;
- segmento: 2.400 px; hueco 280→215 px;
- anticipación mínima antes del primer obstáculo: 700 px;
- alivio: cada seis segmentos.

La instrumentación guarda `observed_horizontal_speed` y
`peak_horizontal_speed` desde el `CharacterBody2D`, después de aplicar la
velocidad al recurso duplicado del globo. Medición automatizada con física a
60 Hz: **224,4 px/s** al inicio de la muestra, **268,4 px/s** en el tramo
intermedio y **341,0 px/s** en el avanzado. El último valor coincide con el
tope configurado. La ligera diferencia inicial corresponde al avance durante
la ventana de muestreo.

Referencias oficiales consultadas: [CharacterBody2D](https://docs.godotengine.org/en/stable/classes/class_characterbody2d.html)
y [PhysicsDirectSpaceState2D](https://docs.godotengine.org/en/stable/classes/class_physicsdirectspacestate2d.html).

## Evidencia automatizada y visual

Ejecutado con Godot 4.7.2 Standard y física fija a 60 Hz:

- importación headless: código 0, sin errores de scripts ni recursos;
- `single_player_gameplay_test.gd`: 0 fallos. Recorre los ocho patrones a
  velocidad avanzada con la escena y física reales del globo; muestrea la ruta
  contra colliders; comprueba fuentes de Track01, estrellas alcanzables,
  ausencia de puertas genéricas, tres semillas, no repetición inmediata,
  separación de estrellas, recursos acotados y velocidad corporal real;
- `single_player_test.gd`: 0 fallos. Incluye selección, ausencia de bots,
  monedas/audio, vida, protección, curación, guardado, pausa y Game Over;
- benchmark de generación: 180 segmentos en 2.013,27 ms en la ejecución final,
  con seis segmentos y 44 coleccionables activos. El coste incluye componer el
  arte de terreno; no equivale a una medición de FPS;
- regresiones: `race_test.gd`, `track_test.gd`, `valle_redesign_test.gd`,
  `home_test.gd` y `character_selection_test.gd`, todas con código 0/0 fallos;
- render ANGLE 1280×720: inspeccionadas
  `.godot/single-player-intro.png`, `single-player-gameplay.png`,
  `single-player-dual-route.png` y `single-player-flappy.png`.

Avisos ambientales: el sandbox no permite escribir el almacén de certificados,
logs ni ajustes globales de Godot; la GPU local usa ANGLE. Algunas suites
mantienen un aviso de dos instancias `ObjectDB` al salir. No se observaron
errores de proyecto. No se declara 60 FPS estable en hardware objetivo.

## Límites y evaluación humana requerida

El Game Owner debe jugar intentos prolongados con varias semillas y comprobar:

- si el ascenso/descenso se anticipa de forma legible y no frustrante;
- si las ocho familias se distinguen en movimiento y el alivio cada seis
  segmentos llega con un ritmo adecuado;
- si monedas y estrellas plantean decisiones que valga la pena tomar;
- si Flappy se percibe desafiante, predecible y esquivable;
- si 224→268→341 px/s se siente claramente sin superar el tiempo de reacción;
- si personajes con la misma física percibida recorren todas las combinaciones;
- si una sesión de 15–20 minutos mantiene fluidez, memoria y audio;
- si reintento, récord, monedas acumuladas, pausa, Home y Carrera permanecen
  correctos después de varios Game Over.

Registrar semilla, personaje, distancia, causa de daño/Game Over, patrón
problemático y hardware. Si una combinación se siente inevitable, conservar la
semilla y distancia para reproducirla antes de cambiar balance.

## Comandos reproducibles

```powershell
& $godot --headless --editor --quit --path .
& $godot --headless --path . --fixed-fps 60 --script res://tests/single_player_test.gd
& $godot --headless --path . --fixed-fps 60 --script res://tests/single_player_gameplay_test.gd
& $godot --path . --fixed-fps 60 --script res://tests/single_player_visual_test.gd
& $godot --headless --path . --fixed-fps 60 --script res://tests/race_test.gd
```
