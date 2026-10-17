# Selección y resultados

Se mantienen StartMenu.tscn, CharacterSelect.tscn y RaceOverlay.tscn.
El Home sigue siendo la escena inicial. Su botón Selección de personaje abre
el selector; ¡CORRER! utiliza RaceSelection.selected, la misma elección que
Comenzar carrera y Otra carrera. No hay un segundo estado de selección.

El selector usa cuatro Button agrupados, marcos normal/seleccionado,
TextureRect con los retratos completos idle y Label para nombres y atributos.
No instancia cuerpos de gameplay. El marco dorado indica selección; el
contorno blanco indica foco de teclado. Todos conservan las mismas habilidades.
Containers, anchors y escalado con proporciones conservadas distribuyen la UI.

MenuStyle centraliza únicamente texturas, estilos de botones y retratos de UI.
Los recursos proceden de assets/ui/menus; PREVIEW_* no se cargan en el juego.
Las poses faltantes usan el idle del catálogo existente. Greta surprised tiene
un fragmento de canasta ajeno encima: AtlasTexture recorta esa franja al mostrarla,
sin modificar el PNG original ni las imágenes utilizadas en carrera.

Resultados sigue leyendo RaceFlow.records, record_for y standings.order.
El orden visual 2, 1, 3, 4 representa puestos, no identidades. Cada columna
consulta el corredor real, su expresión por puesto y su is_local_player.
La clasificación conserva tiempos, choques y objetos capturados al finalizar.
Los DNF conservan Sin terminar, sin inventar tiempos. Otra carrera llama al
reinicio existente. Menú principal y Escape regresan al Home sin perder elección.
La pausa, el cálculo de resultados y la simulación no fueron modificados.

El botón Entrenamiento del Home abre `scenes/Training.tscn`. El diseño M7.1
aprobado es una sesión de 60–90 segundos objetivo, con un jugador, cuatro zonas
y sin competidores. El código y `tests/training_test.gd` verifican la ruta, la
entrada desde Home y la ausencia de rivales; la duración percibida, claridad de
las instrucciones y experiencia completa aún requieren playtesting humano.

## Verificación

Ejecutar con el Godot indicado en README:

```powershell
& $godot --headless --path . --editor --import --quit
& $godot --headless --path . --fixed-fps 60 --script res://tests/menus_redesign_test.gd
& $godot --path . --fixed-fps 60 --script res://tests/menus_redesign_test.gd
```

La prueba recorre los cuatro personajes desde Home, inicia carreras, introduce
cruces controlados en el modelo real y verifica expresiones, estadísticas,
jugador cuarto, reinicio y regreso al Home. Incluye ganadores distintos de Calaca.
No representa una prueba humana de una carrera completa. Comprueba límites de
layout en 1280×720 y 1280×800; con renderer genera .godot/menus-*.png.
home_test verifica entradas reales de ratón/teclado, foco y Escape;
race_flow_test cubre orden por tiempo y DNF. Se mantienen las demás regresiones.

Para revisión manual: F5 → Selección de personaje → elegir con ratón o
flechas/Tab y Enter → Comenzar carrera. Terminar, comprobar TÚ y estadísticas,
probar Otra carrera y Menú principal. Cambiar el tamaño de ventana y comprobar
también el mando físico si se utiliza; no se probó un dispositivo conectado.
Entrenamiento ya está integrado desde Home. La revisión manual de su experiencia
completa permanece pendiente; la prueba automatizada no sustituye el playtesting.

Resultado de esta integración: importación headless correcta y 18 suites PASS,
incluida competition_test con 12 carreras. menus_redesign_test y home_test
también pasaron con renderizado; se revisaron capturas 16:9 y 16:10.
Sin errores nuevos de GDScript. Persisten avisos previos de recursos de audio
en uso al salir de algunas pruebas headless. El equipo usa el fallback ANGLE
del motor para renderizar por las limitaciones de su controlador OpenGL.
