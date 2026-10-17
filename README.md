# Balloon Racing — M6.3: Comeback & Chaos

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

`music_home_v2.mp3` acompaña menú, cuenta atrás y podio.
Al dar GO se elige `music_race_01.mp3` o `music_race_02.mp3`; se mantiene durante
toda la carrera y se reproduce en bucle. Los WAV anteriores se conservan.
Los cambios usan un fundido de 0,25 s por lado. SPACE pausa ambos.

Efectos originales: colisión, turbo y explosión de bomba/cohete. Se emiten
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
bombas, cohetes, pausa y reinicio. También pasan music, menu, pause,
race_flow, items, turbo y obstacle. Persiste el aviso de referencias de audio
pendientes al cerrar Godot 4.7.2, ya observado antes de este cambio.
La mezcla y el carácter musical requieren evaluación auditiva manual.

Abrir project.godot y pulsar F5. El Home ofrece ¡CORRER!, Selección de personaje,
Cómo jugar y Opciones de audio; Entrenamiento queda pendiente de su escena real.
¡CORRER! inicia con la elección actual, indicada en el Home. Selección de personaje
abre las tarjetas de Calaca, Timo, Greta o Lord Pomposo con ratón o flechas/Tab y Enter. Pulsar
**Comenzar carrera**: tras 3… 2… 1… GO comienza el reloj. La selección es
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
  El panel PAUSA permite Continuar o Reiniciar carrera; Enter activa el botón enfocado.
  La pausa congela cuerpos, IA, proyectiles, efectos, cajas y reloj de carrera.
- F2: progreso, posición, velocidad, cargas, objetos usados, tormentas y viento.
- Otra carrera: reiniciar desde el podio, restaurando todos los estados.

El turbo personal está disponible 5 s después de GO. Hay 12 s mínimos entre
cargas; no se regeneran ni se consumen durante otro boost o fuera de carrera.
Los bots eligen tramos despejados. El HUD muestra cargas y tiempo de espera.

## Objetos y remontada

Las **32 cajas** se distribuyen en distintas alturas y ambas rutas. Mantienen
su sensor de 48×48 px. Una caja reaparece tras **8 s**; quien la recogió debe
salir del sensor antes de poder recogerla otra vez. Un inventario lleno no
consume la caja. No hay generación continua de cajas nuevas.

- Cohete: horizontal, 720 px/s, vida 2,5 s; impacta rivales y escenario.
- Bomba: gravedad 650 px/s², fusible 1,8 s, radio 120 px, impulso hasta 90 px/s.
- Turbo (antes Superquemador): ×1,35 durante 2 s, igual que las cargas personales.
- Tormenta: ataca al líder que sigue compitiendo y está delante del usuario.
  Si no hay objetivo válido o está protegido, conserva el objeto.
  Nube/advertencia 0,8 s, penalización ×0,65 por 1,5 s y protección de 4 s
  desde la advertencia. No cancela el control vertical ni persigue un nuevo
  líder si cambia la clasificación durante la advertencia.

Probabilidad de Tormenta por puesto activo: **0 / 5 / 15 / 25 %**. El resto
se reparte entre cohete, bomba y Turbo con pesos iniciales 1:1:1, tanto para
humanos como bots. No se garantizan objetos concretos por caja.

## Pista y velocidad

Valle Ventoso conserva 18.160 px, seis zonas y 17 formaciones. Hay tres
corrientes ×1,20: rama superior, reunión de rutas y corredor técnico.
Flechas azules indican sus áreas. La rama baja ofrece una alternativa más segura.

La velocidad se calcula en un solo lugar: base × mayor ayuda × menor
multiplicador de penalización, más el rebote temporal de M2.

- Ayudas: máximo entre 1, Turbo y corrientes, con tope configurable ×1,35.
- Penalizaciones: la más fuerte entre obstáculo, cohete/bomba y Tormenta.
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
