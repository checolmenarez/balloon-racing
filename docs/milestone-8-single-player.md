# M8 — Single Player / Vuelo Libre

> **Actualización M8.1 (2026-11-10):** el generador, balance, coleccionables y
> obstáculos descritos históricamente aquí fueron rediseñados. Para el estado
> vigente consultar [M8.1 — Rediseño de gameplay](milestone-8.1-gameplay-redesign.md).
> En particular, `SinglePlayerGate`, las siete familias originales y los valores
> de velocidad/segmento de este informe ya no describen el recorrido activo.

Fecha de implementación técnica: 2026-11-09. Estado: listo para revisión
humana; no validado todavía mediante playtesting humano.

## A. Funcionalidad implementada

- Home ofrece **CARRERA** y **VUELO LIBRE** como modalidades principales. El
  acceso principal a Entrenamiento M7.1 queda oculto, sin borrar su escena ni su
  código.
- Vuelo Libre reutiliza el selector de los cuatro personajes, `Balloon.tscn`,
  la física vertical, Flappy, corrientes, música, Input Map y arte de fondo de
  Valle Ventoso. No instancia bots, cajas, proyectiles, Tormenta, ranking ni meta.
- Avance horizontal automático con aceleración suave por distancia, limitada a
  150 % de la velocidad inicial. No modifica el recurso de física de Carrera.
- Recorrido extensible por segmentos con semilla reproducible, siete familias
  de patrón, ruta segura declarada, descansos, corrientes y Flappy. Conserva una
  ventana de segmentos y libera lo que queda atrás.
- Monedas en hileras, recogida única, pulso/destello y un evento sonoro por
  moneda. Un pool compartido de ocho voces evita crecimiento de audio; el tono
  sube ligeramente durante combinaciones rápidas.
- Vida, daño con protección, estrellas mágicas, HUD compacto, pausa, Game Over,
  reintento inmediato y resultados reales de tiempo/distancia/monedas.
- Persistencia local con `ConfigFile` en `user://single_player.cfg`: mejor
  distancia, mejor intento de monedas, total histórico y preferencia de intro.
  Datos ausentes, incompatibles o negativos vuelven a valores seguros.
- Intro ES/EN en el primer inicio, opción persistente **NO VOLVER A MOSTRAR** y
  explicación disponible en Cómo jugar.

## B. Arquitectura y archivos

La escena principal es `scenes/SinglePlayer.tscn`, controlada por
`scripts/single_player.gd`. `SinglePlayerSegmentManager` crea y retira segmentos
compuestos por `SinglePlayerGate` (subclase de `FlightObstacle`), Flappy,
`WindZone`, `Coin` y `MagicStar`. `HealthComponent` encapsula vida/protección y
`SinglePlayerSave` encapsula el archivo local. El fondo infinito reutiliza las
capas de Valle Ventoso mediante `single_player_world.gd`.

Archivos específicos nuevos:

- `scripts/single_player*.gd`, `scripts/health_component.gd`,
  `scripts/coin.gd`, `scripts/magic_star.gd`.
- `scenes/SinglePlayer.tscn`, `scenes/SinglePlayerGate.tscn`,
  `scenes/Coin.tscn`, `scenes/MagicStar.tscn`.
- `resources/default_single_player.tres`.
- `tests/single_player_test.gd` y `tests/single_player_visual_test.gd`.

Integración acotada: `home.gd`/`StartMenu.tscn`, `start_menu.gd`,
`race_selection.gd`, `music.gd` y catálogos ES/EN. Carrera no contiene lógica
específica de Vuelo Libre.

## C. Parámetros configurables

`resources/default_single_player.tres` usa `SinglePlayerConfig`:

- velocidad inicial 220 px/s;
- +4 % por cada 500 px, transición 1,5/s y máximo ×1,50;
- dificultad desde 1800 px;
- vida 100, daño 25, estrella +20 y protección 1,0 s;
- segmentos de 1800 px, cuatro por delante y uno por detrás;
- hueco de 285 px al inicio a 220 px avanzado;
- reacción mínima 650 px y semilla de prueba 82472. `run_seed = 0` crea un
  recorrido nuevo por intento; una semilla positiva reproduce la secuencia.

Son hipótesis de balance editables; no se alteró
`resources/default_balloon_physics.tres`.

## D. Pruebas y resultados reales

Ejecutado con Godot 4.7.2 Standard, fixed physics 60 Hz:

- importación headless: carga de scripts/recursos sin errores de proyecto;
- `single_player_test.gd`: PASS. Cubre jugador único/selección, física
  compartida, ausencia de combate competitivo, semillas, rutas, ventana
  acotada, monedas/eventos de audio, vida/protección/curación, velocidad y
  límite, persistencia/archivo inválido, pausa y Game Over único;
- simulación de generación: 180 segmentos en 271,02 ms en la ejecución final
  (255,89–527,02 ms en repeticiones de esta sesión), seis segmentos y 61
  coleccionables activos al final; el historial diagnóstico queda limitado a
  64 firmas. Es un benchmark CPU headless de generación, no una medición de FPS;
- regresiones PASS: `flight_test`, `obstacle_test`, `flying_creature_test`,
  `home_test`, `character_selection_test`, `menu_test`, `pause_test`,
  `race_test`, `race_audio_test` y `music_test`;
- render ANGLE 1280×720: capturas locales
  `.godot/single-player-intro.png` y `.godot/single-player-gameplay.png`
  inspeccionadas. El driver local no expone OpenGL 3.3 y Godot usa ANGLE.

Avisos ambientales observados: acceso denegado al log/editor settings bajo el
sandbox, certificado raíz de Windows y avisos históricos de ObjectDB al salir
de algunas suites. No se observaron errores de script, escena o colisión en la
suite final. No se declara 60 FPS estable.

## E. Problemas y pendientes

- Falta playtesting humano de diversión, justicia, mezcla, legibilidad y ritmo.
- Las rutas se validan por restricciones geométricas y simulación de generación;
  no sustituyen una sesión humana prolongada con todos los patrones.
- La persistencia real en `user://` no pudo escribirse dentro del sandbox de
  esta sesión; la prueba usa la misma clase con un archivo temporal bajo
  `.godot`. `ConfigFile` y la ruta de producción sí quedan implementados.
- El rendimiento visual prolongado requiere medición en hardware objetivo; el
  benchmark reportado sólo aísla generación/limpieza.

## F. Recursos provisionales

- Moneda y estrella: dibujo vectorial legible generado por Godot.
- Puertas procedurales: bloqueos vectoriales inspirados en la paleta rocosa;
  conservan collider rectangular estable, pero el acabado es provisional.
- Sonidos de moneda, estrella, récord y Game Over: tonos originales generados
  localmente en memoria, reproducibles y sin assets externos. Son funcionales
  y distintos, pero su mezcla final requiere revisión auditiva.
- Música: reutiliza inicialmente la música de carrera aprobada.

## G. Cómo iniciar y probar

1. Abrir `project.godot` con Godot 4.7.2 y pulsar F5.
2. Elegir **VUELO LIBRE**, seleccionar personaje y pulsar **Comenzar vuelo**.
3. Mantener Flecha arriba para subir y soltar para descender; ESC abre pausa.
4. Recoger monedas/estrellas, chocar para comprobar protección y agotar vida
   para revisar resultados, récord y **VOLVER A INTENTAR**.
5. Volver a Home y ejecutar **CARRERA** para comprobar el flujo competitivo.

Comandos reproducibles:

```powershell
& $godot --headless --path . --editor --import --quit
& $godot --headless --path . --fixed-fps 60 --script res://tests/single_player_test.gd
& $godot --path . --fixed-fps 60 --script res://tests/single_player_visual_test.gd
```

## H. Guía corta de playtesting humano

- ¿La intro explica sin ayuda externa subir, soltar, moneda, golpe y estrella?
- ¿Cada moneda suena agradable, incluso en una hilera rápida?
- ¿Las hileras sugieren una trayectoria y dejan ver el siguiente peligro?
- ¿La aceleración se percibe sin volver injusta la inercia vertical?
- ¿Los golpes y el segundo de protección se entienden?
- ¿Las estrellas ayudan sin eliminar el riesgo?
- ¿Se entiende la causa del Game Over y apetece reintentar?
- ¿Los intentos se sienten distintos sin patrones inevitables?
- ¿Pausa/reinicio/Home conservan personaje y récord correctamente?
- ¿Una sesión de 15–20 minutos mantiene fluidez, audio y memoria?

Registrar hardware, idioma, personaje, duración, semilla y observaciones. No
marcar como validado por humanos hasta completar esta revisión.

## I. Estado de bloques

- A — Base jugable: **completo técnicamente**.
- B — Coleccionables: **completo técnicamente**, audio/arte final pendientes.
- C — Recorrido extensible: **completo técnicamente**, balance humano pendiente.
- D — Presentación: **completo técnicamente**, aceptación audiovisual pendiente.
- E — Calidad: **parcial**; automatización y regresiones completas, benchmark
  visual prolongado y playtesting humano pendientes.

## J. Estado de Carrera

Carrera permanece operativa en las suites ejecutadas. `race_test.gd` completó
ambas rutas con cuatro corredores y `race_audio_test.gd` pasó. El único cambio
compartido de audio añade registro de efectos y pitch opcional conservando la
firma anterior. No se modificaron Track01, bots, objetos, Tormenta ni balance.

