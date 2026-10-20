# M7.2 — Game feel, animaciones y UX

Fecha: 2026-10-18. Motor ejecutado: Godot 4.7.2 Standard
(`v4.7.2.stable.official.ed1daf0bf`). Implementación y pruebas automatizadas;
**sin aceptación mediante playtesting humano**. No se crearon commits.

## Cambios

- Cuenta 3/2/1/¡YA! de 120 px, contorno y Tween de escala/alpha. RaceFlow conserva
  su transición y reloj; el audio opcional se dispara desde esa misma cuenta.
- Entrada de los cuatro corredores mediante desplazamiento temporal de Visual;
  los cuerpos, posiciones registradas, orden y colisiones permanecen intactos.
  Línea decorativa en la referencia Start, junto a la plataforma existente.
- Anclaje compartido de canasta en X/Y, incluida Greta con quemador y las poses
  inclinadas de Calaca/Timo. El lienzo de 384×512 no garantiza contenido alineado:
  la corrección anterior solo usaba Y y suponía X=192 para todas las poses.
  La escala sigue siendo uniforme y normaliza techo–canasta; transiciones de
  0,12 s evitan cambios instantáneos de transformación. Inclinación sutil según
  movimiento/turbo y sacudida de 0,28 s amortiguada, reiniciada sin acumularse.
- Halo pulsante de cajas sin cambiar sensores ni reaparición. Inventario/turbo
  arriba a la izquierda; iconos provisionales dibujados con primitivas nativas.
  Ruleta de 0,55 s sin RNG: el nombre muestra el objeto real desde el primer
  frame, se puede usar durante la animación, y consumirlo cancela el efecto.
  Cargas y disponibilidad consultan el estado existente. Entrenamiento reutiliza
  el mismo componente, sin un segundo inventario.
- Posición grande arriba a la derecha. La barra existente incluye retratos en
  filas para distinguir empates, con aro dorado local. Cada X consulta
  `track.get_progress`; la clasificación sigue en RaceStandings.
- Cohetes y bombas conservan sus reglas de impacto; flash, anillo expansivo y
  ocho trazos de partículas por dibujo. La cola visual de 0,25 s no colisiona,
  no vuelve a aplicar daño y se libera. No se añade un sistema de partículas.
- Tormenta activa pose hit, sacudida, mensaje local y sonido `collision.wav`
  reutilizado. Advertencia, objetivo, duración, potencia y protección intactos.
- Botón Home ya existente visible en pausa de carrera; restaura pausa, limpia
  efectos de audio y libera la escena. Se mantiene selección de personaje.
- Instrucciones con Theme global Fredoka/Lilita One, ajuste de línea en
  entrenamiento y ayuda de carrera al borde inferior. ES/EN mediante PO
  registrados en Godot y ampliación de `character_selection.pot`.

## Evidencia automatizada

PASS (código de salida 0) en las 12 suites: `polish`, `characters`, `race_flow`,
`items`, `turbo`, `chaos`, `pause`, `training`, `home`, `race_audio`,
`world_visual`, `visibility`. Los comandos usan:

```powershell
# Ruta de $godot en README.md.
& $godot --headless --path . --editor --import --quit
& $godot --headless --path . --fixed-fps 60 --script res://tests/polish_test.gd
# Repetir sustituyendo polish por cada suite indicada.
& $godot --path . --fixed-fps 60 --script res://tests/polish_test.gd
```

`polish_test.gd` verifica salida sin desplazamiento físico ni adelanto de GO,
orden/reloj, cancelación y resultado de ruleta, pausa de animaciones, inventario
y cargas, ausencia de consumo de RNG visual, recuperación de sacudida,
colisión inmutable, reacción y balance de tormenta, explosión sin segundo daño,
anclajes al terminar transiciones, traducciones ES/EN y Home desde pausa.
`characters_test.gd` conserva verificación de 20 poses, recursos, estados,
anclajes y dimensiones de colisión/física; usa el nuevo anclaje X/Y.
El recorrido M7.1 llegó a X=15803, etapa 3, con ascenso/descenso y diana,
sin colisiones y con un reintento programado.

Importación final con acceso normal al perfil de Godot: sin errores de scripts
ni recursos. Primer intento en sandbox emitió errores de certificados y
escritura de configuración/logs; se repitió con permisos de ejecución normales.
Algunas suites emitieron avisos intermitentes ObjectDB/recursos al cerrar;
`chaos` reportó un recurso todavía en uso. Las repeticiones verbose de
`characters` y `chaos` pasaron y no reprodujeron el aviso. No se atribuye una
causa nueva ni se declara resuelto el aviso de audio previamente documentado.

La prueba gráfica `polish` pasa con el fallback ANGLE de esta GPU. Captura
inspeccionada: `.godot/m72-hud.png` (fixture con cuerpos detenidos y estados
forzados). Se corrigieron solapamientos entre retratos al inicio y se desplazó
la ayuda para no atravesar al corredor superior. Esto acredita disposición
estática, **no** legibilidad en movimiento, comodidad ni satisfacción audiovisual.
Logs locales en `.godot/m72-*.log`; no son assets del juego ni se versionan.

## Parciales y recursos faltantes

- No hay cue apropiado de cuenta atrás ni fanfarria/vitoreo: asignar
  `Music.countdown_sound` y `Music.race_start_sound` en la escena Music.
  Los campos están vacíos deliberadamente; no se inventan rutas de audio.
- El sonido de tormenta reutiliza colisión. Su adecuación auditiva necesita
  revisión humana; no hay sonido específico de rayo.
- Iconos de inventario, cohete/bomba y explosiones siguen siendo placeholders
  nativos. No se creó arte definitivo.
- Los anclajes y transiciones no convierten ilustraciones distintas en frames
  idénticos. Permanecen diferencias internas de silueta, inclinación y tamaño
  relativo del globo/canasta, especialmente en turbo/hit. Una continuidad
  artística perfecta requiere poses registradas por arte; no se fuerza un
  reemplazo del sistema ni una deformación de los sprites.
- ES/EN cubre los textos de M7.2 y las instrucciones M7.1. No se declara
  traducido todo el Home, selector o resultados históricos. El locale del
  sistema y `--language en` permiten comprobar inglés; fallback español.

## Validación humana pendiente

1. F5 y salida con cada personaje: cuenta atrás, entrada, contraste y línea.
2. Alternar ↑, soltar, D e impactos; revisar especialmente Greta con quemador,
   transición turbo/hit, marcador TÚ y retorno de sacudida sin vibración continua.
3. Recoger cada objeto y usar A durante la ruleta. Revisar lectura de nombre,
   disponibilidad, cargas y progreso; comprobar ambas rutas sin ocultar peligros.
4. Cohete, bomba y tormenta con jugador atacante/afectado: contraste, mezcla
   sonora, flash no molesto, claridad de objetivo y reacción.
5. SPACE durante cuenta/ruleta/impacto; Continuar, Reiniciar y Home mediante
   teclado y ratón. Confirmar vuelta al Home sin sesión ni sonido de efectos.
6. Completar M7.1 y repetir etapas en ES/EN. Revisar instrucciones, duración
   percibida, tipografía, pantallas pequeñas y escalado de ventana.

## Archivos

- Escenas/configuración: `scenes/Main.tscn`, `scenes/Training.tscn`, `project.godot`.
- Inicio/HUD/navegación: `scripts/race_flow.gd`, `race_overlay.gd`, `main.gd`,
  `world_visual.gd`, nuevos `item_status.gd` y `race_progress.gd` (con sus UID).
- Personajes/efectos: `scripts/character_catalog.gd`, `balloon_visual.gd`,
  `item_box.gd`, `item_projectile.gd`, `balloon_items.gd`, `music.gd`.
- Entrenamiento/localización: `scripts/training.gd`,
  `localization/character_selection.pot`, nuevos `es.po` y `en.po`.
- Pruebas: `tests/characters_test.gd`, nuevo `tests/polish_test.gd` y su UID.
- Documentación: `README.md`, `docs/PROJECT_STATUS.md`, `DECISIONS.md`,
  `characters.md`, `controls-pause.md` y este informe.

No se modificaron recursos de física, turbo, objetos o perfiles de bots,
ni el proyecto Phaser. Referencias oficiales consultadas antes de editar:
[Tween](https://docs.godotengine.org/en/stable/classes/class_tween.html) y
[gettext/PO](https://docs.godotengine.org/en/stable/tutorials/i18n/localization_using_gettext.html).
