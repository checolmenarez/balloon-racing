# Home V2.1

Estado musical vigente: Home y carreras usan los nuevos MP3; integración y
pruebas en [music-v2.md](music-v2.md). Las secciones musicales siguientes
documentan versiones anteriores.

Actualización musical posterior: ya se creó e integró «A toda vela», tema
original a 156 BPM. Véase [home-music.md](home-music.md). La solicitud de recurso
externo descrita abajo corresponde al estado inicial de V2.1 y queda resuelta;
la aprobación auditiva humana sigue pendiente.

## Cambios y valores finales

Se mantiene el flujo de navegación y los sprites de carrera. Los cuatro
TextureRect del Home crecen un 30 %, conservando el aspecto de sus PNG.
Sus centros se calculan con anchors relativos al viewport:

- Calaca: anchor (0.13, 0.30), rectángulo 364 × 390; centro (166.4, 216) a 720p.
- Timo: anchor (0.185, 0.755), rectángulo 299 × 325; centro (236.8, 543.6).
- Greta: anchor (0.875, 0.32), rectángulo 364 × 390; centro (1120, 230.4).
- Pomposo: anchor (0.845, 0.76), rectángulo 299 × 325; centro (1081.6, 547.2).

Los rectángulos pueden exceder el lateral; las caras permanecen visibles.
El logo oficial pasa de 200 a 250 px de alto (+25 %), centrado, sin distorsión.
Su entrada dura 0.5 s, de escala 0.95 a 1, con easing sinusoidal de salida.
El foco inicial y los controles están disponibles desde `_ready`.

## Diagnóstico y animación

La ejecución previa confirmó `gui_snap_controls_to_pixels=true`, mientras
`snap_2d_transforms_to_pixel` y `snap_2d_vertices_to_pixel` eran false.
El código anterior ya utilizaba una sinusoide en `_process`, sin redondeos ni
tweens repetidos: la cuantización de los Control a píxeles enteros explica
los escalones en desplazamientos de fracciones de píxel. No se atribuye a FPS
sin evidencia. Véase la propiedad en la documentación oficial de Viewport.

Home desactiva temporalmente el snapping GUI y restaura el valor anterior al
salir. Utiliza filtrado lineal local. No cambia el renderizado de las carreras.
La posición vertical usa una sinusoide de amplitud 6 px y periodos de
3.4 / 2.8 / 3.8 / 3.1 s, respectivamente; desfases 0 / 1.7 / 3.4 / 5.1 rad.
Rotación máxima ±1.2°, pivote (50 %, 65 %) de cada rectángulo. Los extremos
superior/inferior se calculan desde valores inmutables, evitando deriva de tamaño.
No hay reinicio de ciclos ni tweens de flotación. Se pausa al abrir paneles y
se detiene al salir; los tweens ligados al Home se cancelan explícitamente.

No existía una opción de reducción de movimiento. `Home.reduce_motion`,
expuesto en el inspector, desactiva flotación, rotación y entrada del logo;
también admite cambios en ejecución. El feedback de foco/hover se conserva.

Los seis parches de botones se preparan una sola vez y se reutilizan entre
botones y visitas al Home, evitando repetir lectura y escalado de la lámina.

## Tipografía y redistribución

`resources/ui_theme.tres` es el Theme global de `project.godot`; se aplica
también a HUD, entrenamiento, pausa y resultados. Fredoka variable, peso 500,
es la fuente de cuerpo/botones; Lilita One se usa mediante las variantes
ArcadeTitle y ArcadePrimary. Se respetan tamaños y contornos locales existentes.
El selector duplica el Theme global antes de personalizar sus contornos.

Archivos originales descargados de Google Fonts, sin modificar:

- `assets/fonts/Fredoka[wdth,wght].ttf` y `fredoka-OFL.txt`.
- `assets/fonts/LilitaOne-Regular.ttf` y `lilitaone-OFL.txt`.

Ambas usan SIL Open Font License 1.1, que permite incluirlas en software
comercial conservando copyright y licencia. No pueden venderse por separado.
Fuentes y licencias: https://github.com/google/fonts/tree/main/ofl/fredoka
y https://github.com/google/fonts/tree/main/ofl/lilitaone.
Al preparar una distribución, incluir ambos archivos OFL junto al ejecutable
o mediante el filtro de exportación `assets/fonts/*-OFL.txt`. No hay preset
de exportación en este repositorio. Las licencias no deben omitirse del paquete.

## Música: estado real y recurso pendiente

No se recibió una nueva composición. Se conserva `valle_ventoso.wav` como
fallback; no se presenta la pista anterior como música nueva ni se reutiliza
la música de carrera como sustitución de producción.

El único autoload Music sigue controlando música y buses. `home_music`, en
el inspector de `scenes/Music.tscn`, acepta el reemplazo. El arranque hace
fade-in de 0.4 s; las transiciones conservan 0.25 s por lado y el mismo player.
El volumen y mute pertenecen al bus Music, por lo que los fades no los alteran.
Volver a solicitar el tema actual no reinicia la pista. Los WAV se duplican
antes de configurar loop completo; OGG activa loop y conserva su loop_offset.

Proporcionar `assets/audio/home_arcade.ogg` (o WAV PCM), estéreo, 44.1/48 kHz,
con licencia comercial redistribuible o autoría propia documentada. Dirección:
145–160 BPM, motivo reconocible 0–2 s, ritmo 2–8 s, melodía 8–20 s, variaciones
posteriores y unión musical de loop sin silencio. Asignarlo a `home_music`.
Si contiene intro no repetible, usar OGG y configurar `loop_offset` al inicio
del segmento repetible. Pendientes: composición definitiva, escucha del nivel
relativo, continuidad del loop y aprobación de su carácter musical.

## Verificación

Godot 4.7.2; importación headless. Suites: home, menu, music, race_audio,
pause, training y menus_redesign. Prueba home_polish: 30 s de posiciones
subpíxel, límites de velocidad, ausencia de deriva, separación del menú en
1280×720/1280×800, fuentes y glifos españoles/ordinales, reducción de movimiento,
foco, restauración del snapping, liberación de escena y continuidad de música.
home_music_override prueba el slot nuevo con un WAV existente como fixture,
sin cambiar el recurso de producción; verifica loop, mute y continuidad.

Pruebas gráficas home y menus_redesign generan capturas de Home, ayuda,
opciones, selección y resultados. `home_polish_test.gd` genera
`.godot/home-v21-720.png` y `home-v21-800.png`.
Mouse y teclado se prueban mediante eventos sintetizados por Godot.
La evaluación perceptual en el monitor objetivo y la escucha son manuales;
la prueba de 30 s muestrea continuidad, no sustituye una evaluación humana.
El entorno conserva avisos de certificados, fallback ANGLE y recursos al cerrar.

Resultado: las nueve suites indicadas terminaron en PASS. Se revisaron además
capturas de HUD de carrera, HUD de entrenamiento y sus paneles de pausa;
no se observaron textos cortados ni superpuestos en esas capturas de 1280×720.

## Archivos de implementación

- `scenes/StartMenu.tscn`, `scripts/home.gd`: composición, motion y caché.
- `resources/ui_theme.tres`, `project.godot`, `assets/fonts/*`: Theme y fuentes.
- `scenes/CharacterSelect.tscn`, `scenes/RaceOverlay.tscn`,
  `scenes/Training.tscn`, `scripts/start_menu.gd`: variantes tipográficas.
- `scripts/music.gd`: slot musical, fallback y fade-in.
- `tests/home_polish_test.gd`, `tests/home_music_override_test.gd`: regresiones.
- Este documento y referencias desde README/Home.
