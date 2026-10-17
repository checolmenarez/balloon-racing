# Milestone 2 — 12 de octubre de 2026

Motor utilizado: Godot 4.7.2.stable.official.ed1daf0bf Standard.

## Implementacion

Obstacle.tscn usa StaticBody2D en capa 2; Balloon detecta esa capa.
Cada formacion genera la misma silueta para dibujo y CollisionPolygon2D.
El modo GAP combina dos poligonos en un cuerpo. Anchos y alturas son
editables en el Inspector y se previsualizan gracias a @tool.

Recorrido en Main.tscn, posiciones de origen X y alturas Y del mundo:

- Inicio X=240; vuelo libre hasta el borde de la primera montaña en X=1460.
- Montaña X=1600, ancho 280, punta inferior Y=430.
- Formacion superior X=2900, ancho 280, punta superior Y=250.
- Montaña X=4100, ancho 300, punta inferior Y=380.
- Formacion superior X=5200, ancho 300, punta superior Y=290.
- Paso amplio X=6500, ancho 320, abertura entre Y=180 y Y=500: 320 px.
- Paso mas ajustado X=7900, ancho 340, abertura entre Y=230 y Y=480: 250 px.
- Espacio libre desde X=8070; punto de comprobacion X=9040 (40 s desde inicio
  sin penalizaciones). No hay meta, clasificacion ni final de partida.

La envolvente de colision del globo mide 135 px de alto: los pasos dejan
185 y 115 px de margen vertical total respectivamente. A 1280x720 la camara
muestra aproximadamente 920 px por delante del globo (4.2 s a velocidad base).

Movimiento horizontal = velocidad base por multiplicador recuperable mas
impulso horizontal de rebote recuperable. La asignacion del movimiento base
nunca elimina la penalizacion. Valores iniciales: multiplicador 0.60,
recuperacion lineal 0.8 s, impulso de rebote 90 px/s, proteccion 0.75 s.
La componente vertical del impulso usa la normal del contacto y respeta
el limite de velocidad vertical de M1.

Tras un impacto se crea una excepcion de colision solo con esa formacion.
Se retira cuando el globo ha pasado completamente su borde derecho y ha
terminado la proteccion. Esto evita reactivar una colision dentro de una roca
ancha y quedar bloqueado. Durante la proteccion los nuevos contactos tambien
permiten despejar la formacion, sin reiniciar penalizacion ni contador.
El globo cambia de tono y permanece translucido mientras despeja el cuerpo.

## Validaciones realizadas

- Lectura de AGENTS.md y revision de escenas, scripts, configuracion y README.
- Comprobacion --check-only de main.gd antes de editar: sin errores de
  GDScript. Los dos avisos historicos de VS Code no se reprodujeron; no se
  dispone de sus mensajes originales y no se atribuye una causa sin evidencia.
- Importacion headless del proyecto en Godot 4.7.2: salida 0.
- Ejecucion headless de Main durante 120 frames: salida 0.
- Regresion flight_test.gd a 30, 60 y 120 Hz: PASS, cero fallos. Se retira
  el nodo Obstacles en esta prueba para aislar el comportamiento de M1.
- obstacle_test.gd a 30, 60 y 120 Hz: PASS, cero fallos. Usa escenas reales
  y entradas de prueba, sin instalar control automatico en el juego.
- Tres configuraciones golpeadas deliberadamente con ancho 600: impacto real,
  multiplicador efectivo, rebote horizontal, desplazamiento reducido,
  recuperacion gradual, feedback visual (propiedad modulate), proteccion,
  un solo impacto por formacion y limpieza posterior de las excepciones.
- Recorrido completo hasta X=9040 sin colisiones con entradas de prueba.
- Recorrido completo con SPACE siempre liberado y siempre presionado:
  cuatro colisiones en cada caso, sin quedar atrapado. Se verifican limites
  verticales y velocidad maxima en cada paso de todas estas pruebas.
- Camara y F2 comprobados despues del recorrido; contador y penalizacion
  presentes en el panel existente. M1 verifica tambien cierre y repeticion F2.
- Ejecucion grafica de Main durante 600 frames: salida 0 y sin errores de
  GDScript. El controlador uso ANGLE/Direct3D 11 por falta de OpenGL 3.3.

Se corrigio un residuo de coma flotante al agotar la penalizacion a 30 Hz,
que mantenia su estado activo un paso extra. La prueba de rebote valida
su componente horizontal: un contacto lateral puede tener normal Y=0 y
no debe exigirse un rebote vertical en todos los choques.

El primer check restringido no pudo escribir logs en AppData; las ejecuciones
completas se realizaron fuera del sandbox con autorizacion y sin ese error.
Los comandos reproducibles estan en README.md.

## Revision manual pendiente

1. F5; evaluar anticipacion visual, facilidad del primer obstaculo y transicion
   entre alturas con SPACE. Las entradas automatizadas prueban viabilidad
   fisica, no diversion ni dificultad humana.
2. Chocar intencionadamente, abrir F2 y comprobar si el cambio de tono,
   rebote, reduccion y recuperacion de velocidad resultan suficientemente claros.
3. Atravesar ambos pasos; evaluar si 320 y 250 px de abertura son adecuados.
4. Confirmar la experiencia al redimensionar la ventana y la legibilidad del HUD.
5. Si VS Code conserva los dos avisos, revisar su texto en Problems; Godot
   carga los scripts sin errores, pero no se verifico visualmente ese panel.

Sin bots, power-ups, clasificacion, meta, menus, vidas, Game Over ni red.
No se modifico Phaser ni se crearon commits.
