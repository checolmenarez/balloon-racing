# M3 — Valle Ventoso — 13 de octubre de 2026

Godot 4.7.2.stable.official.ed1daf0bf Standard. M1 y M2 aprobados
manualmente por el usuario; M3 pendiente de evaluacion humana.

## Cambios y arquitectura

- scenes/Track01.tscn: pista reutilizable con trece formaciones, seis zonas,
  señalizacion y referencias de inicio, bifurcacion, rutas, reunion y meta.
- scripts/track.gd: progreso normalizado y acotado por coordenada X, consulta
  de zona y dibujo de meta. No depende del jugador ni controla su fisica.
- scripts/obstacle.gd: modo ISLAND para la formacion central suspendida.
  Comparte la geometria visual con la colision y las excepciones de M2.
- Main.tscn y main.gd: instancia del circuito, posicion inicial desde el
  marcador Start, barra inferior y extension del panel F2.
- tests/fixtures/M2Obstacles.tscn: recorrido M2 original preservado.
  flight_test.gd y obstacle_test.gd se adaptan a la nueva jerarquia;
  mantienen sus aserciones originales.
- tests/track_test.gd: rutas, progreso, zonas, meta, camara y continuidad
  tras colisiones, con entradas automaticas exclusivas de la prueba.
- tests/track_visual_test.gd: capturas del render de Godot en la bifurcacion,
  ruta alta con F2 y meta. Los PNG quedan en .godot y no forman parte del juego.
- README.md: distribucion, ejecucion y comandos reproducibles.

Sin cambios en balloon.gd, Balloon.tscn, balloon_physics.gd ni en
default_balloon_physics.tres. La camara conserva su seguimiento y anticipacion.
No se añade viento, bots, clasificacion, ventajas de ruta ni sistemas de carrera.

## Distribucion

1. Inicio, X=240–2700: vuelo abierto y montaña con punta en Y=470.
2. Alternancia, X=2700–6000: tres formaciones en X=3200, 4300 y 5400.
3. Dificultad progresiva, X=6000–9700: montaña mas alta, saliente mas profundo
   y abertura de 265 px en X=8900.
4. Dos rutas, X=9700–13400: aviso previo en X=9200; divisor central desde
   X=10300 hasta 12900, entre Y=260 y 340. Ruta alta de 228 px, con salientes
   en X=11250 y 12250 que reducen la abertura a 190 y 170 px. Ruta baja de
   300 px sin salientes adicionales. Reunion en X=13200.
5. Corredores, X=13400–16800: aberturas de 255, 245 y 235 px en X=14000,
   15150 y 16300; anchuras de 420, 460 y 500 px respectivamente.
6. Recta final, X=16800–18400: sin obstaculos, con linea de meta y banderin.

La colision del globo mide 135 px de alto; incluso el paso alto mas estrecho
deja 35 px de margen total. La ruta baja ofrece 165 px. A 1280x720 se ven
aproximadamente 920 px por delante del globo (4,2 s a velocidad normal).
El margen geometrico y la entrada automatizada prueban viabilidad; no
demuestran comodidad de control ni dificultad adecuada para una persona.

Longitud inicio–meta: 18.160 px. Duracion nominal: 82,55 s a 220 px/s.
Las dos rutas comparten velocidad y distancia horizontal. Las penalizaciones
pueden extender el tiempo. La meta solo limita el progreso a 100%; se permite
continuar volando, sin pantalla de resultados ni Game Over.

## Validacion

- Importacion headless y ejecucion de Main: codigo 0, sin errores GDScript.
- FLIGHT TEST y OBSTACLE TEST: PASS, cero fallos a 30, 60 y 120 Hz.
- TRACK TEST: PASS, cero fallos a 30, 60 y 120 Hz.
- Rutas alta y baja: meta alcanzada sin colisiones en aproximadamente
  82,53–82,57 s, pasando las seis zonas en orden.
- SPACE siempre suelto: meta en unos 84,8 s con siete impactos.
- SPACE siempre pulsado: meta en unos 85,3–85,5 s con nueve impactos.
- Entrada centrada para golpear el divisor: meta en unos 83,8–83,9 s,
  cinco impactos; excepcion del divisor retirada despues de despejarlo.
- Progreso acotado antes del inicio y despues de meta, barra a 100%, zona 6,
  referencias ordenadas, controles, limites verticales y camara comprobados.
- Main ejecutada con ventana durante 600 frames, codigo 0. El hardware usa
  ANGLE/Direct3D 11 automaticamente por falta de soporte OpenGL 3.3.
- Capturas del render inspeccionadas para señalizacion, paso alto, HUD y meta.

## Prueba manual de M3

F5, SPACE para ascender y soltar para descender; F2 para depuracion.
Hacer una pasada por arriba y otra por abajo, reiniciando con F8 y F5.
Evaluar anticipacion de la bifurcacion, margen del paso alto, transicion a
los corredores, claridad de la meta y de la barra. Provocar impactos para
confirmar que la sensacion de penalizacion aprobada en M2 se conserva.

No se declara validada la diversion ni la dificultad de M3 automaticamente.
No se realizaron commits ni se modifico el proyecto Phaser.
