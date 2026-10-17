# Controles y pausa

Acciones del Input Map: burner=UP, use_item=A, use_turbo=D,
pause=SPACE, toggle_debug=F2. Eliminadas las asignaciones anteriores.
Se mantiene la lógica de objetos, dos cargas por corredor y toda la física.

RaceOverlay procesa siempre; el resto del árbol hereda el modo pausable.
SPACE alterna SceneTree.paused durante cuenta atrás, carrera o espera de
llegadas. Se ignora en resultados y se consume antes de ui_accept para
evitar que active Reiniciar por accidente. Las repeticiones de tecla no
alternan el estado. Continuar admite clic o Enter; SPACE siempre reanuda.
RaceFlow.restart quita la pausa antes de recargar Main.

Archivos: project.godot, scripts/main.gd, race_flow.gd, race_overlay.gd,
scenes/Main.tscn, RaceOverlay.tscn, README y documentación vigente.
Nuevo tests/pause_test.gd; actualizadas las teclas en pruebas existentes.

Godot 4.7.2: importación headless sin errores. Pruebas pause, flight, items,
turbo, race_flow, chaos y visibility: PASS. pause_test también pasó en modo
gráfico y produjo .godot/pause-preview.png, revisada visualmente.

La prueba inyecta UP/A/D/SPACE reales, verifica bindings únicos, pausa en
cuenta atrás, congelación de posiciones/velocidades de los cuatro cuerpos,
reacción de bots, proyectil y su edad, efecto de tormenta, boost, respawn de
caja, cámara y reloj. Comprueba repetición de SPACE, SPACE con Reiniciar
enfocado, señal del botón Continuar, Enter, reinicio y podio tras llegada.
El reinicio restaura dos cargas, limpia efectos/proyectiles y restaura cajas.

Pendiente manual: comodidad del esquema UP/A/D, clic físico en ambos botones
y pausa/reanudación en distintos momentos de una carrera normal. La señal
de los botones y el foco de teclado se verificaron automáticamente.
Sin problemas bloqueantes conocidos; sin commits.
