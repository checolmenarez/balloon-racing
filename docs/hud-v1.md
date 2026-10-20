# HUD V1 — integración incremental

2026-10-18. Godot 4.7.2 Standard. Implementado sobre los cambios locales de
M7.2, conservados sin commits, push ni merge. No modifica gameplay.

## Arquitectura y fuentes de datos

El punto de entrada de carrera es `Main.tscn`. Su CanvasLayer HUD contiene
inventario, posición, progreso, contexto y debug. `RaceOverlay.tscn` continúa
siendo el componente compartido de cuenta atrás, reloj, pausa y resultados;
no se sustituyó ni se duplicó. Entrenamiento conserva su presentación anterior
y comparte la lógica de inventario/ruleta de `item_status.gd`.

- `race_hud.gd` se adjunta al CanvasLayer existente. Compone los marcos, cuatro
  filas reutilizables y el botón de pausa una sola vez. Reubica los nodos
  existentes según el viewport, con margen configurable de 16 px. La lista
  usa VBoxContainer; los PNG conservan su proporción en TextureRect.
- Objeto: `BalloonItems.equipped`, `collected`, `item_name()` y disponibilidad
  original; ruleta decorativa M7.2, icono en TextureRect separado y pop de 0,2 s.
  Usarlo durante la ruleta sigue siendo posible y cancela el icono pendiente.
- Turbo: `turbo_charges`, `turbo_wait_left`, `boost_left`, `racing` y
  `ItemCombat.enabled`. Se muestra contador, nunca medidor de combustible.
  El brillo suave de 0,6 s se crea solo en el paso a disponible.
- Teclas: consulta de InputMap mediante `HudStyle.binding()`. No se cambió el
  mapa de controles. El hint permanente solo aparece cuando está activo F2.
- Reloj: `RaceFlow.elapsed`, formateado mm:ss.cc por RaceOverlay. Conserva
  inicio, congelación y estados de carrera existentes.
- Contexto: `track_name`, `get_zone_index()` y cantidad real de Zones: seis
  tramos actualmente, sin vueltas ni métricas inventadas.
- Puesto y filas: `RaceStandings.get_place()` y `standings.order`, incluyendo
  su orden real de llegada. El HUD no ordena ni calcula clasificación.
- Avance por fila y barra inferior: `BalloonTrack.get_progress(world_x)`.
  Los retratos proceden de `MenuStyle.portrait(character_id, "normal")`, assets
  reales de `assets/ui/menus/portraits`, nunca de una referencia gráfica.
- Pausa: botón con foco visible y tooltip, llama a `RaceOverlay.toggle_pause()`;
  SPACE utiliza exactamente esa misma ruta. Continuar, reiniciar y Home siguen
  en el panel existente. El HUD de carrera se oculta al entrar en resultados.

Refresco de clasificación/contexto a 20 Hz, configurable mediante
`race_hud.refresh_seconds`; inventario a un máximo de 20 Hz en estado estable,
con actualización inmediata al cambiar objeto/cargas/boost y al cambiar locale.
Reloj y marcador de avance leen valores existentes por frame. No se crean
nodos, texturas o tweens por frame. Recursos cacheados y cuatro filas estables;
los tweens se crean únicamente por cambios de puesto, recogida o turbo listo.

## Kit y contradicciones resueltas

- En los PNG disponibles, **`icon_rocket.png` dibuja una bomba y `icon_bomb.png`
  dibuja un cohete**. `item_status.ICONS` los mapea por contenido real. Se
  conservaron nombres y bytes de los archivos; la prueba cubre ambos casos.
- La referencia ilustra segmentos de energía, pero la decisión D-005 exige
  cargas. Se cubren las celdas decorativas de `panel_turbo` con un fondo de
  contenido y se muestra el contador real. No existe una barra continua nueva.
- `panel_progress` incluye cuatro círculos decorativos que no representan
  métricas del juego. Se cubren con la barra de avance real; las banderas
  suministradas marcan los extremos. No se añaden hitos ni vueltas.
- «4 rivales» se interpreta conforme al juego aprobado: cuatro corredores
  totales (jugador y tres bots), no un quinto participante.
- El README externo recomienda commit o respaldo. Se respetó la prohibición
  del proyecto de crear commits; se guardó respaldo local en `.godot/`.

Uso de assets: panel_item + icono dinámico, panel_keyhint + tecla,
panel_status + estado, panel_turbo + contador; panel_timer y panel_sector con
Labels; panel_position con X/4; panel_leaderboard_row por corredor;
panel_progress y marker_start/finish; button_pause con símbolo y acción reales.
Turbo objeto usa icon_turbo_bolt y tormenta icon_storm. `button_settings`,
`icon_shield` e `icon_wind` permanecen disponibles pero no se presentan como
funciones nuevas. No hay Settings autorizado durante carrera. `MobileControls`
es solo un Control vacío, oculto e independiente; no hay botones ni lógica táctil.
La hoja y JPG externos se consultaron como referencia; no son controles ni
texturas cargadas por el juego. No se editaron los PNG del usuario.

## Verificación ejecutada

Importación headless en Godot 4.7.2: sin errores de scripts o recursos.
Suites headless PASS: `hud`, `polish`, `pause`, `training`, `track`, `race_flow`,
`turbo`, `items`, `race_audio`, `menus_redesign` (10 suites).

`hud_test.gd` prueba slot vacío/equipado/consumido, mapeo de iconos, contador y
disponibilidad de turbo, cambios de puesto y filas, avance real, reloj/tramo,
fuente de retratos, recuperación del pop, ausencia de crecimiento de nodos,
pausa con mouse y Enter, foco, final de carrera, ocultación en resultados,
ES/EN y layouts 1280×720/1280×800. En headless inyecta ratón con coordenadas del
viewport y notifica entrada de ratón, porque no existe una ventana del sistema.
Con renderizado utiliza Input.parse_input_event. No sustituye playtesting humano.

La prueba gráfica también pasó usando ANGLE (fallback de esta GPU). Capturas
inspeccionadas en `.godot/`:

- `hud-v1-empty-1280x720.png`: slot vacío, clasificación y tramo.
- `hud-v1-equipped-1280x720.png`: bomba, dos cargas listas y cuarto puesto.
- `hud-v1-equipped-1280x800.png`: 16:10, adelantamiento y turbo consumido.
- `hud-v1-english-1280x800.png`: textos del HUD en inglés.
- `hud-v1-pause.png`: panel de pausa existente y foco.

Se corrigieron durante esta revisión recortes de marcos por clipping de Label,
el mínimo de altura inicial de ProgressBar y los iconos invertidos del kit.
Las primeras pruebas del fixture también detectaron recogidas automáticas al
colocar cuerpos junto a cajas: el fixture ahora las aísla, sin alterar el juego.
La prueba de pista recorre sus seis zonas y conserva sus comprobaciones de
transitabilidad; M7.1 completa su ruta programada. Los hashes de los recursos
de física/items/turbo/bots y scripts competitivos permanecen iguales al inicio
de HUD V1. Las modificaciones M7.2 previas no se consideran cambios de este HUD.

Persisten avisos intermitentes ObjectDB/recursos al cerrar algunas suites,
como en la verificación M7.2. No se declara resuelto ese problema previo.
Los logs son `.godot/hud-v1-*.log`. Comandos (ruta de `$godot` en README):

```powershell
& $godot --headless --path . --editor --import --quit
& $godot --headless --path . --fixed-fps 60 --script res://tests/hud_test.gd
& $godot --path . --fixed-fps 60 --script res://tests/hud_test.gd
```

## Límites y aceptación manual pendiente

Las capturas acreditan disposición estática, contraste sobre cielo claro y
lectura en ambos formatos; son estados controlados de una carrera real con
cuerpos detenidos. No acreditan experiencia interactiva, ausencia perceptual
de stutter, legibilidad durante todas las rutas ni que ningún corredor/obstáculo
pueda pasar detrás de los paneles periféricos. La prueba geométrica mantiene
libre el corredor central de vuelo/anticipación, no toda la pantalla.

En las capturas se observa un cuadrado blanco en un elemento del decorado
superior, fuera del HUD. Los scripts/assets de mundo no se modificaron en esta
integración; su diagnóstico queda pendiente fuera de este alcance.

Validar manualmente una carrera con ambos formatos: A durante ruleta, D listo
y consumido, adelantamientos, sectores altos/bajos, meta, SPACE, clic/Enter,
Home y reinicio. Revisar nombres largos, reducción de ventana, cobertura de
peligros en el borde derecho y legibilidad de filas durante movimiento.
Entrenamiento conserva sus instrucciones; revisar su acceso y retorno.

## Archivos de esta integración

- Modificados: `scenes/Main.tscn`; `scripts/main.gd`, `race_overlay.gd`,
  `item_status.gd`, `race_progress.gd`; catálogos `localization/es.po`, `en.po`
  y POT existente; `README.md`, `docs/PROJECT_STATUS.md`, `docs/DECISIONS.md`.
- Nuevos: `scripts/hud_style.gd`, `hud_racer_row.gd`, `race_hud.gd`,
  `tests/hud_test.gd`, sus UID, y este documento.
- Assets ya aportados al inicio: 19 PNG en `assets/ui/hud/`; Godot generó sus
  `.import`, que deben conservarse. No se cambió el proyecto gráfico externo.

Referencias oficiales consultadas: [TextureRect](https://docs.godotengine.org/en/stable/classes/class_texturerect.html),
[Containers](https://docs.godotengine.org/en/stable/tutorials/ui/gui_containers.html)
y [Viewport/input](https://docs.godotengine.org/en/stable/classes/class_viewport.html).
