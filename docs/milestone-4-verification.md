# M4 — Rivales controlados por bots — 13 de octubre de 2026

## Implementacion

Cuatro instancias de Balloon.tscn, todas en X=240: competitivo amarillo en
Y=110, equilibrado azul en Y=265, jugador rojo en Y=420 y novato verde en
Y=575. No se superponen al iniciar y no hay ventaja horizontal de salida.
El marcador Start de Track01 cambia solo su Y a 420 para situar al jugador.
El trazado, distancias, velocidad y demas parametros fisicos no cambian.

Balloon recibe una decision booleana de FlightController (SPACE) o
BotController. Solo balloon.gd integra velocidad, mueve, detecta impactos,
aplica penalizaciones y limita alturas. Los cuatro usan la misma instancia
de default_balloon_physics.tres. Las colisiones entre globos siguen
desactivadas, por la mascara original que detecta exclusivamente obstaculos.

BotController consulta las formaciones reales dentro de su anticipacion
mediante track.get_upcoming_obstacles. Combina alturas de montañas, techo,
pasos y divisor central, incluyendo dos restricciones simultaneas. En la
bifurcacion consulta los marcadores existentes y la ruta preferida del perfil.
Considera velocidad vertical al predecir Y y mantiene la decision hasta la
proxima reaccion. No escribe posicion, velocidad, capas ni penalizaciones.

BotProfile centraliza nombre, anticipacion, reaccion, tolerancia, error,
prediccion de inercia, fase del error y ruta. El error es una funcion suave
de la distancia, que sesga la altura estimada; no cambia bruscamente el vuelo.
Valores actuales y unidades en README.md. Las rutas iniciales son baja,
baja y alta; todos los perfiles pueden usar cualquiera de las dos.

Los bots conservan la proteccion de M2 tras un choque: la formacion golpeada
queda temporalmente exceptuada hasta despejarla. Esto es comun al jugador;
no se añade una capacidad de atravesar formaciones para la IA, ni se usa
teletransporte para recuperar puestos.

RaceStandings ordena por X real mediante insercion estable, con histeresis
de 2 px. Diferencias menores conservan el orden anterior, y el empate inicial
usa el orden de registro. No se usa una comparacion aproximada no transitiva
para ordenar. No hay resultados predefinidos ni ajuste de velocidad por puesto.
La clasificacion sigue en vivo despues de meta; no hay pantalla de resultados.

## Archivos

- Nuevos scripts: flight_controller.gd, bot_controller.gd, bot_profile.gd,
  race_standings.gd, junto a sus UID generados por Godot.
- Nuevos recursos: bot_novice.tres, bot_balanced.tres, bot_competitive.tres.
- Balloon.tscn y balloon.gd: controlador intercambiable y color configurable.
- Main.tscn y main.gd: rivales, controladores, salida, posicion y F2 ampliado.
- track.gd: consulta de obstaculos por distancia. Track01.tscn: Y del inicio.
- tests/race_test.gd: carreras, rutas, impactos compartidos y clasificacion.
- tests/track_visual_test.gd: captura adicional de salida; README y este informe.

## Diagnostico inicial

Se leyo AGENTS.md y se revisaron escenas, fisica y configuracion. El alcance
explicito de M4 autoriza bots y clasificacion, aunque AGENTS conserva la
restriccion de los milestones anteriores. No se editaron esas instrucciones.

Antes de modificar codigo, importacion y ejecucion headless de M3: salida 0,
sin errores GDScript ni Parse Error. El registro reciente de VS Code confirma
activacion de Godot Tools y no contiene Parse Error. No habia un servidor LSP
escuchando en el puerto 6005 al comprobarlo. No se inspecciono directamente
el panel Problems de VS Code: sus posibles diagnosticos antiguos no se
consideran resueltos solo porque no aparezcan en el registro.

## Pruebas

- Godot Standard 4.7.2.stable.official.ed1daf0bf: importacion y ejecucion correctas.
- FLIGHT TEST, OBSTACLE TEST, TRACK TEST y RACE TEST a 30, 60 y 120 Hz:
  doce combinaciones aprobadas, cero fallos con la parrilla definitiva.
- Regresion M1–M3: controles, inercia, limites, penalizacion, dos rutas,
  camara y F2 preservados.
- Exactamente cuatro globos, recurso fisico compartido, misma mascara,
  salida sin superposiciones y quemadores de bots independientes de SPACE.
- Carreras completas con rutas originales e intercambiadas: los tres
  perfiles alcanzan la meta. Se comprueba la rama elegida durante el vuelo.
  A 60 Hz y con rutas iniciales: equilibrado 82,55 s/0 impactos,
  competitivo 82,72 s/1 impacto y novato 82,92 s/2 impactos. El humano
  de la prueba, sin pulsar SPACE, llega en 84,83 s/7 impactos. Son mediciones
  de esa prueba determinista, no resultados prefijados ni una evaluacion humana.
- Impactos reales de bots, reduccion de velocidad y recuperacion; ademas
  se impone la misma entrada y geometria a los cuatro para comparar su
  respuesta fisica y contador de impactos.
- Clasificacion cambia en carrera. Prueba aislada de adelantamiento,
  recuperacion de puesto, empate cercano y adelantamiento claro.
- Cota de desplazamiento por pasos fisicos y limite de velocidad horizontal:
  sin teletransportes ni aumentos artificiales de velocidad.
- Panel F2 identifica perfiles, progresos y objetivos; la camara sigue
  exclusivamente al jugador.
- Ejecucion grafica y capturas de HUD, meta y colores. ANGLE/Direct3D 11
  es seleccionado por el motor porque el equipo no soporta OpenGL 3.3.

La prueba de desplazamiento toma en cuenta que move_and_slide puede proyectar
movimiento vertical sobre X en un contacto inclinado, y sincroniza la primera
medicion al terminar el paso en el que se añade la escena. No se cambio la
fisica para acomodar esas verificaciones.

## Pendiente de prueba humana

F5 inicia la carrera. SPACE controla el globo rojo; F2 muestra los datos.
Probar ambas rutas, provocar impactos y observar adelantamientos y recuperacion.
Reiniciar con F8 y F5. Evaluar legibilidad de colores/posicion y si los perfiles
son entretenidos y justos. Las pruebas no califican diversion ni balance.

La IA es determinista y especifica para las formaciones de esta pista;
no se garantiza que evite todos los choques. Un perfil mas habil puede perder
por escoger la ruta mas exigente. No hay power-ups, ataques, red, nuevas
pistas, habilidades, rubber banding, menus ni pantalla de resultados.
Sin commits y sin modificaciones al proyecto Phaser.
