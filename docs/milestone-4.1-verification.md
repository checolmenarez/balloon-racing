# M4.1 — Claridad visual del jugador local

## Cambios

- scripts/balloon.gd: propiedad is_local_player y estado impact_tint separado
  de la modulacion del cuerpo. El dibujo pasa a un subarbol visual.
- scripts/balloon_art.gd: dibujo procedural original, sin cambiar geometria.
- scripts/balloon_visual.gd y scenes/Balloon.tscn: CanvasGroup con Artwork
  y marcador TÚ. El grupo aplica transparencia una sola vez a la silueta,
  evitando acumulacion de alpha entre las figuras superpuestas del dibujo.
- scripts/balloon_visibility.gd: prioridad local, deteccion geometrica de
  superposicion, histeresis y transicion de opacidad. Configurable en Inspector.
- scenes/Main.tscn y scripts/main.gd: propiedad local inicial y conexion
  del gestor visual con los competidores ya existentes.
- tests/visibility_test.gd: verificaciones y demostracion grafica opcional.
- tests/obstacle_test.gd: consulta impact_tint en vez de modulate del cuerpo,
  pues ese estado visual se ha separado. Las aserciones fisicas se conservan.
- README.md y este informe: configuracion y comandos reproducibles.

No cambian recursos fisicos, perfiles de bots, posiciones iniciales, pista,
orden fisico, mascaras de colision, reglas de impacto ni clasificacion.

## Decisiones visuales

Solo Visual cambia su z_index absoluto: 1 para rivales y 2 para el globo
local. El cuerpo conserva su Z original. El escenario actual permanece
en Z=0; el primer plano que deba ocultar competidores utiliza Z>=3.
El jugador no se coloca en un CanvasLayer por encima del mundo.

El rectangulo visual conservador es 88x135 px, transformado al mundo.
Una vez detectada la superposicion, se mantiene hasta abandonar un margen
adicional de 12 px. La opacidad rival converge linealmente hacia 0.45;
fade_time=0.12 controla la duracion de un cambio completo de alpha 0 a 1
(el cambio normal 1 a 0.45 tarda unos 66 ms). Al salir vuelve a su alpha
normal; si hay impacto, se conserva la transparencia de impacto de M2.
Se usa el menor alpha de ambos efectos para evitar acumularlos.

El globo local conserva alpha 1, incluso al recibir un impacto; mantiene
el cambio de tono como feedback. TÚ es una etiqueta pequeña con contorno,
unida al subarbol visual y oculta en los otros globos. Se coloca sobre la
envolvente, tambien visible junto al techo sin coincidir con la indicacion SPACE.

La propiedad local es independiente de color, nombre y controlador. Cambiar
la propiedad visual no transfiere controles ni camara: ese cambio de posesion
pertenece a un futuro sistema multijugador. Esta version no incorpora red.
Se espera un globo local por vista; si no hay ninguno, todos recuperan su
presentacion neutral y no se muestra marcador.

## Validaciones realizadas

- Godot 4.7.2 Standard: importacion y arranque headless, sin errores GDScript.
- VISIBILITY TEST headless: PASS. Cuatro cuerpos coincidentes, alpha local 1,
  alpha rival 0.45, restauracion, configuracion, cambio de propiedad al azul,
  marcador, impacto, ausencia de propietario y capas fisicas intactas.
- 120 alternancias junto al borde de entrada/salida: el alpha rival se
  mantiene estable gracias a la histeresis. Esto comprueba un caso sintetico;
  queda la evaluacion visual humana durante una carrera normal.
- VISIBILITY TEST grafico: PASS. Se comprueba por pixeles que la silueta
  local roja/azul realmente se dibuja opaca y que un elemento Z=3 la oculta.
- Capturas inspeccionadas: superposicion total/parcial, propiedad local azul
  y marcador al techo. La revision detecto y corrigio un CanvasGroup que
  intentaba dibujar directamente: el dibujo debe estar en su hijo Artwork.
- FLIGHT TEST, OBSTACLE TEST, TRACK TEST y RACE TEST: PASS a 60 Hz tras los
  cambios finales. Controles, colisiones, penalizaciones, recorrido, ambos
  caminos, resultados de bots, clasificacion y seguimiento de camara intactos.
- Ejecucion grafica con ANGLE/Direct3D 11, seleccionado automaticamente por
  el motor ante la falta de soporte OpenGL 3.3 del equipo.

## Prueba manual reproducible

Usar el comando `visibility_test.gd -- --preview` del README. La prueba
congela y recoloca los cuerpos solo en esa ejecucion de demostracion; no
añade atajos de depuracion ni cambia las posiciones de la carrera normal.
Cada caso permanece tres segundos. Las capturas se guardan bajo .godot.
Para jugar, F5 como siempre; SPACE y F2 mantienen su comportamiento.

Pendiente: evaluar comodidad y legibilidad en movimiento con una persona.
Sin cambios en Phaser, parametros fisicos, networking ni commits.
