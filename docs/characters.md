# Integración de personajes

## Arquitectura

- `Balloon.character_id`: identidad independiente del color; sin estadísticas nuevas.
- `CharacterCatalog`: cuatro IDs, nombres, texturas cacheadas y anclajes de canasta.
- `BalloonVisual`: reutiliza `CharacterSprite` y excluye `Artwork` cuando hay textura.
  ID inválido o idle ausente: arte procedural. Pose ausente: idle.
- Prioridad de poses: victoria > impacto > turbo > quemador > idle. Impacto consulta
  `impact_time_left`/`items.hit_left`; turbo consulta `items.boost_left`.
  RaceFlow comunica al visual la primera llegada real, sin cambiar la clasificación.
- El shader de contorno pertenece a cada sprite; sigue `is_local_player` mediante
  el sistema de visibilidad existente. La transparencia contempla el rectángulo del
  sprite, incluidos sus efectos, sin alterar sensores ni colisiones.
- RaceSelection reparte el personaje elegido al humano y los tres restantes a bots.
  Conserva los colores anteriores únicamente para fallback. Los nombres del podio
  identifican los personajes; F2 conserva los perfiles de IA.

## Alineación

Los 20 PNG son RGBA de 384×512. Se conservan intactos. Escala uniforme calculada
entre el techo ilustrado de referencia (Y=28) y la base de canasta (Y=486).
Las poses turbo necesitan anclajes específicos: Calaca 452, Timo 480, Greta 446,
Pomposo 446, excluyendo el escape. Se mapean a Y=-74 y Y=61 bajo Visual (escala
0,88). CollisionShape2D sigue midiendo 77,44×118,8 y no cambia de posición.
M7.2 añade transición de transformaciones de 0,12 s, inclinación suave y sacudida
amortiguada únicamente en Visual. No modifica cuerpos ni colisiones.
`CharacterCatalog.basket_anchor` corrige también X por pose: el PNG de Greta
quemador tiene la canasta desplazada dentro del lienzo; Calaca/Timo hit están
inclinados. Las dimensiones del lienzo son iguales, pero su contenido no está
registrado como una animación continua. La normalización conserva el tramo
vertical techo–canasta; no garantiza proporciones internas idénticas.
Ver `milestone-7.2-verification.md` para la evidencia actual y límites.

## Verificación

`characters_test.gd` comprueba los 20 recursos, alpha, estados, anclajes,
fallback, física y victoria mediante un cruce real de meta simulado.
`menu_test.gd` comprueba elección, cuatro identidades únicas y reinicio.
`visibility_test.gd` compara el jugador superpuesto con su render aislado.
Las pruebas de vuelo, obstáculos, pista, IA, objetos, turbo, caos, carrera y
pausa se conservan. Las antiguas comprobaciones que asumían el nombre literal
«Jugador» ahora usan el nombre real del competidor.

Resultado de ejecución en Godot 4.7.2: importación headless sin errores;
13 suites headless aprobadas (characters, menu, pause, flight, obstacle, track,
race, items, visibility, turbo, chaos, race_flow y competition). Competition
completó 12 semillas. También se ejecutaron las siete comprobaciones/capturas
gráficas de personajes, menú, visibilidad, pista, objetos, M6 y M6.3.
Se inspeccionaron las poses, menú, superposición y resultados renderizados.
El controlador gráfico usa ANGLE automáticamente por compatibilidad OpenGL;
no aparecieron errores nuevos de GDScript ni recursos faltantes.

Para capturas, ejecutar Godot sin `--headless` con `--script
res://tests/characters_test.gd` o `res://tests/visibility_test.gd`. Se guardan en
`.godot/characters-poses.png` y `.godot/m41-*.png`. El menú admite
`--script res://tests/menu_test.gd -- --capture`.

## Revisión manual

1. F5, elegir cada personaje y comenzar; comprobar los cuatro diseños distintos.
2. Mantener ↑, activar D después de la espera inicial y usar A con un objeto.
3. Chocar y observar la pose hit, recuperación, TÚ y solapamiento con rivales.
4. SPACE congela la carrera; reiniciar conserva la elección. F2 muestra el estado.
5. Terminar y comprobar nombres, tiempos y ganador; solo el primero celebra.

Las ilustraciones originales varían ligeramente de contorno, inclinación y
proporciones internas entre poses. Los anclajes estabilizan cuerpo y canasta,
pero no convierten las poses en una animación continua. Revisar en movimiento
si estas diferencias son aceptables; no se declara validada la sensación de juego.
La victoria puede quedar fuera de cámara si gana un bot y el podio puede ocultarla.
