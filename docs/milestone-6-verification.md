# M6 — verificación y decisiones

Fecha: 2026-10-13. Motor: Godot 4.7.2 Standard oficial, Windows.

## Etapas

1. Inspección de AGENTS, README, escenas, física, IA y objetos. Importación
   y pruebas M5 aprobadas antes de modificar la base. Sin Parse Error.
2. Ciclo de carrera: cuenta regresiva, llegadas, timeout, podio y reinicio.
   `race_flow_test.gd` aprobado antes de continuar con pista y balance.
3. Pista y perfiles: pruebas de rutas y bots aprobadas. Doce simulaciones
   reproducibles con objetos y ciclo completo.
4. Contorno, presentación, regresiones, capturas y documentación.

## Archivos

Nuevos:

- scripts/race_flow.gd: estado de carrera y tiempos reales de cruce.
- scripts/race_overlay.gd, scenes/RaceOverlay.tscn: contador, reloj,
  espera, podio, clasificación completa y botón de reinicio.
- tests/race_flow_test.gd, competition_test.gd, m6_visual_test.gd.
- docs/milestone-5-verification.md, milestone-6-verification.md,
  m6-simulations.json (resultados reales de la muestra).

Modificados:

- main.gd, Main.tscn: conexiones, semilla reproducible, nueva UI.
- balloon.gd, balloon_items.gd, item_combat.gd: estado activo común;
  sin vuelo, recogida ni uso durante espera/final, sin daño a finalizados.
- race_standings.gd: conserva orden de llegada y ordena por X a los demás.
- bot_controller.gd, bot_profile.gd, resources/bot_*.tres: perfiles cercanos,
  variación suave por carrera y elección de ruta, sin ventajas físicas.
- Track01.tscn, track.gd: 17 formaciones, 21 cajas y referencia de meta.
- balloon_art.gd, balloon_visual.gd, balloon_visibility.gd: contorno local.
- Regresiones existentes: desactivan RaceFlow en sus fixtures aislados;
  track_test actualiza las entradas de vuelo al trazado nuevo;
  visibility_test añade transferencia del contorno al cambiar propiedad.
- README.md y los .uid generados por Godot.

## Diseño y parámetros

Física sin cambios: gravedad 350, quemador 650, avance 220, vertical 250.
Los objetos y penalizaciones de M5 mantienen sus valores.

Cuenta regresiva 3 s y espera máxima tras llegada humana 8 s, exportados
en RaceFlow. El reloj no incluye la cuenta atrás. Se cruza con el centro
del cuerpo; interpolación dentro del paso físico para llegadas simultáneas.
Sólo un empate exacto usa orden de registro. Los resultados guardan
estadísticas al cruzar y nunca asignan tiempo a quien no cruza.
La clasificación en vivo conserva tolerancia de 2 px; el orden final no
usa esa tolerancia. Las posiciones físicas no se cambian para ordenar.

Los cuerpos finalizados quedan inmóviles y sin capa de colisión para no
absorber proyectiles. No usan ni recogen objetos y rechazan daño. Un disparo
previo puede completar su trayectoria; no hay nuevas decisiones del bot
finalizado. Se eliminan proyectiles al abrir resultados.

Novato / equilibrado / competitivo:

- Anticipación: 500 / 580 / 650 px, con variación por salida de ±40 px.
- Reacción: 0,25 / 0,22 / 0,20 s.
- Tolerancia de altura: 12 / 10 / 8 px.
- Error espacial suave: 30 / 28 / 25 px; fase variable hasta ±3,14 rad.
- Probabilidad de ruta alta: 0,30 / 0,40 / 0,50.
- Predicción de inercia: 0,5 s, compartida en los perfiles.

Las elecciones ocurren antes de GO y no dependen de posiciones o resultados.
`race_seed` positivo en Main reproduce la salida y sorteos; cero aleatoriza.
Cada controlador duplica su recurso para no modificar perfiles compartidos.

Seis zonas: inicial abierta; cuatro alternancias; subida/bajada y primer
paso; bifurcación con isla; tres corredores cortos a alturas diferentes;
alternancia final con recuperación y meta abierta. Mismos 18.160 px.
Los pasos consideran 88×135 px de envolvente conservadora. Mínimo de ruta
alta: 180 px, ruta baja en saliente: 240 px; corredores: 265/275/255/250 px.
No hay velocidad exclusiva por ruta ni generación por cronómetro.

## Verificaciones ejecutadas

- Importación headless y ejecución de Main: sin errores de GDScript.
- flight_test y obstacle_test a 60 Hz: PASS; SPACE, límites, inercia,
  penalizaciones y recuperación permanecen operativos.
- items_test a 60 Hz: PASS, incluidos adelantamientos reales por boost.
- track_test a 30, 60 y 120 Hz: PASS. Ambas rutas sin choques con entradas
  programadas, unos 82,5 s. Vuelos incorrectos con choques llegan igualmente.
- race_test a 60 Hz: PASS. Cuatro cuerpos, misma física, navegación por
  ambas ramas, penalizaciones, clasificación, F2 y cámara del jugador.
- race_flow_test a 60 Hz: PASS. Quietud con SPACE antes de GO, bloqueo de
  objetos, salida simultánea, reloj, orden sub-frame inverso al de registro,
  finalizadores protegidos, podio de tres plazas, jugador cuarto, botón
  que recarga la escena y timeout con tres DNF sin tiempos inventados.
- competition_test, semillas 1–12 a 60 Hz: PASS. Todos llegaron, mismos
  recursos físicos, velocidades sin ventajas ocultas y todas las cajas con
  espacio para la envolvente del globo mediante consulta física conservadora.
- visibility_test headless y gráfico: PASS. Prioridad, opacidad completa,
  restauración, histéresis, sin desplazamiento físico, propiedad azul,
  contorno que sigue la propiedad y oclusión por escenario de primer plano.
- m6_visual_test gráfico: contador, GO, superposición total y resultados
  capturados y revisados. Estas capturas fuerzan posiciones de prueba para
  mostrar estados; no representan tiempos ni resultados de carreras reales.

La GPU local no expone OpenGL 3.3; Godot cambia automáticamente a ANGLE.
La ejecución gráfica y las capturas funcionan con ese fallback. No es un
error de GDScript ni se introdujo una dependencia.

## Simulaciones y límites

`docs/m6-simulations.json` guarda las doce carreras, semilla, puesto, tiempo,
perfil, ruta, choques y objetos. Novato lideró 6, equilibrado 4 y competitivo 2.
Tiempos bot de 78,34 a 83,34 s; jugador pasivo de 85,78 a 86,58 s.
No hubo DNF ni bloqueos. Los resultados no se fuerzan ni se usan en el juego.

El humano de la muestra no pulsa teclas ni usa objetos: se comparan bots,
no capacidad competitiva frente a una persona. Doce carreras no bastan para
concluir equilibrio; también pueden influir posición inicial, cajas únicas,
semilla y ruta elegida. Las pruebas con entradas perfectas sólo demuestran
transitabilidad física, no facilidad humana.

## Prueba manual pendiente

1. F5: observar 3, 2, 1 y GO; mantener SPACE y pulsar E durante la cuenta
   atrás para comprobar que nadie se mueve ni usa objetos antes de salir.
2. Alternar SPACE para esquivar; buscar cajas ?, usar E mientras se vuela.
   Observar ataques, boost, recuperación y cambios reales de posición.
3. Probar las dos ramas en carreras distintas y la anticipación necesaria
   para los corredores. Valorar visibilidad y oportunidades de adelantar.
4. Acercarse a rivales: TÚ y contorno siempre locales; opacidad de rivales
   se restaura al separarse. F2 debe conservar los datos de vuelo y objetos.
5. Cruzar meta, observar espera y podio, incluida la posición del jugador.
   Pulsar Otra carrera y verificar cuenta atrás e inventario/cajas nuevos.
6. Repetir varias carreras para valorar dificultad, reparto de cajas,
   oportunidades con cada objeto y diversión. Ajustes sujetos a esta revisión.

Sin errores bloqueantes conocidos. No se modificó Phaser ni se crearon commits.
