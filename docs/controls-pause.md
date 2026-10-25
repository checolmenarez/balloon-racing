# Controles y pausa

Acciones vigentes (2026-10-25): burner=UP, use_item=Z, use_turbo=SPACE,
pause=ESC, toggle_debug=F2. Eliminadas las asignaciones anteriores A/D/SPACE-pausa.
Se mantiene la lógica de objetos, dos cargas por corredor y toda la física.

RaceOverlay procesa siempre; el resto del árbol hereda el modo pausable.
ESC alterna SceneTree.paused durante cuenta atrás, carrera o espera de
llegadas. En resultados vuelve al menú principal. Las repeticiones de tecla no
alternan el estado. Continuar admite clic o Enter; ESC reanuda la carrera.
SPACE y Z se consumen durante la pausa sin activar botones ni gastar recursos.
Durante la carrera se procesa el turbo antes del foco GUI: SPACE no activa el
botón Pausa aunque esté enfocado. Ayuda, entrenamiento, HUD y traducciones
es/en muestran las nuevas teclas.
RaceFlow.restart quita la pausa antes de recargar Main.

Archivos: project.godot, scripts/main.gd, race_flow.gd, race_overlay.gd,
scenes/Main.tscn, RaceOverlay.tscn, README y documentación vigente.
Nuevo tests/pause_test.gd; actualizadas las teclas en pruebas existentes.

Godot 4.7.2: importación headless sin errores. Pruebas pause, flight, items,
turbo, race_flow, chaos y visibility: PASS. pause_test también pasó en modo
gráfico y produjo .godot/pause-preview.png, revisada visualmente.

La prueba inyecta UP/Z/SPACE/ESC reales, verifica bindings únicos, pausa en
cuenta atrás, congelación de posiciones/velocidades de los cuatro cuerpos,
reacción de bots, proyectil y su edad, efecto de tormenta, boost, respawn de
caja, cámara y reloj. Comprueba repetición de ESC, ESC con Reiniciar
enfocado, señal del botón Continuar, Enter, reinicio y podio tras llegada.
El reinicio restaura dos cargas, limpia efectos/proyectiles y restaura cajas.

Pendiente manual: comodidad del esquema UP/Z/SPACE, clic físico en ambos botones
y pausa/reanudación en distintos momentos de una carrera normal. La señal
de los botones y el foco de teclado se verificaron automáticamente.
Sin problemas bloqueantes conocidos; sin commits.

## Actualización M7.2 (2026-10-18)

El botón Home existente ahora es visible también en carrera. Su ruta quita
la pausa, limpia voces de efectos y cambia de escena, liberando la sesión.
Cuenta atrás, ruleta y movimientos visuales se congelan durante la pausa.
`pause_test.gd` y `polish_test.gd`: PASS; aceptación con teclado/ratón humano
pendiente. Detalles en `milestone-7.2-verification.md`.

## Validación del cambio de teclas — 2026-10-25

Godot 4.7.2: PASS en pause, items, turbo, training, hud, home y competition (seis semillas). La prueba de pausa verifica además turbo con foco en Pausa, repetición de Espacio sin gasto adicional ni activación GUI, bloqueo de poderes durante pausa y Esc desde el podio al menú. Se corrigió únicamente el setup de items_test: espera al registro físico de cuerpos antes de teleportarlos a sensores; la primera ejecución fallaba en recogidas por esa falta de sincronización.

HUD también PASS con ventana ANGLE; captura `.godot/hud-v1-equipped-1280x720.png` revisada: Z y [SPACE] caben en sus paneles. Logs `.godot/controls-175-*.log`; ejecuciones finales de items y pause usan sufijos `-recheck` y `-final`. Persisten avisos de certificados y ObjectDB al cerrar, sin fallos en las suites finales. No se realizó playtesting humano.

Referencia consultada: [orden de propagación de InputEvent en Godot](https://docs.godotengine.org/en/stable/tutorials/inputs/inputevent.html). Se conservan las acciones de InputMap; el turbo consume su evento antes de la GUI porque Espacio también pertenece a ui_accept.
