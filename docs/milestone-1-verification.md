# Milestone 1 — verificacion del 12 de octubre de 2026

Motor utilizado: Godot 4.7.2.stable.official.ed1daf0bf Standard.

## Resultados

- Importacion headless del editor completada con codigo 0, sin errores de
  GDScript ni carga de escenas/recursos.
- Main ejecutada en headless durante 120 frames: codigo 0.
- tests/flight_test.gd: PASS, cero fallos a 30, 60 y 120 Hz, usando
  --fixed-fps con la misma frecuencia y Engine.physics_ticks_per_second.
- Verificados gravedad, quemador, conservacion de inercia al pulsar/soltar,
  cambio gradual de direccion, velocidad horizontal constante y limite
  vertical de 250 px/s. Comprobacion de limites en cada paso de la prueba.
- Mantenimiento prolongado del quemador detiene el globo en Y=106;
  liberarlo permite volver al suelo en Y=579. Se incluye toda la geometria.
- Verificados avance continuo, seguimiento horizontal de camara, mapeo F2,
  apertura/cierre del panel y rechazo de repeticion automatica de la tecla.
- Main ejecutada con ventana durante 180 frames: codigo 0, sin errores de
  GDScript. El controlador selecciono ANGLE/Direct3D 11 automaticamente
  porque no soporta OpenGL 3.3; no se cambio la configuracion del equipo.

La primera ejecucion restringida no pudo escribir ajustes/registros en
AppData ni leer certificados del sistema. Se repitio fuera del sandbox
con autorizacion y dichos errores no reaparecieron. La primera prueba de
camara consultaba su posicion antes del procesamiento de ese frame;
la comprobacion se sincronizo antes de repetir las pruebas satisfactoriamente.

## Prueba humana pendiente

F5, mantener y soltar SPACE varias veces y comprobar la respuesta percibida,
la llama, el paisaje en movimiento y la legibilidad del panel F2. Los tests
verifican comportamiento numerico; no califican la sensacion de vuelo.
Los comandos reproducibles estan en README.md.

Sin bots, obstaculos, carreras, menus, puntuacion, red ni recursos externos.
No se crearon commits ni se modifico el proyecto Phaser.
