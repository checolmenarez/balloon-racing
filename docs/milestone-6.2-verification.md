# M6.2 — cargas de turbo por competidor

## Ajuste posterior: una carga para todos

La asignación actual es **1/1/1/1**, incluido el humano. La tecla **T** usa
su carga independiente; **E** sigue usando el objeto equipado. El HUD muestra
disponibilidad y espera inicial, y F2 incluye el contador de los cuatro.
Se mantiene la espera de 5 s desde GO y el bloqueo durante un boost activo.
Otra carrera restaura una carga por competidor.

Actualizados turbo_config.gd, item_combat.gd, main.gd, project.godot,
turbo_test.gd y README. La prueba ahora ejercita T con un cohete equipado,
verifica que el inventario no se consume y comprueba la asignación al reiniciar.

El resto del documento conserva el historial del experimento inicial de
tres cargas exclusivas para bots, sustituido por este ajuste.

## Alcance

Tres cargas por bot, cero por humano, independientes del inventario.
Estado en BalloonItems, API `initialize_turbo` / `use_turbo_charge`, sin
dependencia de una clase Bot para poseer o consumir cargas. RaceFlow asigna
la cantidad según el controlador y la configuración del tipo de carrera.
Puede configurarse una cantidad humana futura sin añadir controles ahora.

Un único `_activate_boost` sirve a cargas y superquemadores recogidos.
Rechaza reactivación sin gastar carga/objeto ni extender el tiempo. Mantiene
el multiplicador y duración de ItemConfig y la composición con penalizaciones.
Los usos de cargas no incrementan el contador de objetos utilizados.

La IA consulta condiciones cada 0,35 s, como los objetos existentes. Espera
5 s desde GO y al menos 12 s entre cargas. Exige espacio para todo el boost
más 80 px (mínimo configurable 650 px), margen vertical 45 px, velocidad
vertical <=90 px/s, error respecto al objetivo <=60 px, sin penalización
activa y suficiente recorrido hasta meta. No cambia la navegación ni perfiles.
No se garantiza gastar todas las cargas: una condición insegura las conserva.

## Archivos

- Nuevos: scripts/turbo_config.gd, resources/default_turbo.tres,
  tests/turbo_test.gd, esta documentación y .uid generados por Godot.
- Modificados: scripts/balloon_items.gd (estado y boost compartido),
  item_combat.gd (decisiones de uso), race_flow.gd (asignación inicial),
  main.gd (F2) y README.md.
- Sin cambios en pista, gráficos, controles, física ni perfiles de dificultad.

## Pruebas

Godot 4.7.2 Standard. Importación headless sin errores GDScript.

`turbo_test` a 60 Hz: PASS. Comprueba inventario independiente, uso de objetos
durante boost, bloqueo mutuo entre boost de objeto y carga, no extensión,
velocidad real 297 px/s, impacto combinado 178,2 px/s, recuperación a 220,
contador no negativo, no regeneración, bloqueo tras meta, asignación humana
mediante API y rechazo de activación cerca de roca/límite vertical/meta.

Carrera completa con semilla 1: los tres bots usaron tres cargas y todos
los competidores llegaron. Momentos de uso en segundos desde GO:

- Novato: 7,72; 31,18; 67,12.
- Equilibrado: 7,72; 37,78; 56,12.
- Competitivo: 8,45; 38,52; 56,85.

También verifica reloj, orden final real, F2 con los tres contadores y
recarga mediante Otra carrera con asignación 0/3/3/3.
Regresiones: race_flow, items, flight, obstacle, race y visibility.
Las pruebas aisladas anteriores desactivan RaceFlow y por tanto no reciben
cargas; turbo_test ejercita tanto componentes como el ciclo completo.

## Comprobación manual

F5 y F2 durante la cuenta atrás: los tres bots deben mostrar `Turbos 3`.
Tras GO, observar reducciones espaciadas y el efecto habitual de superquemador.
Con `Main.race_seed=1` se pueden reproducir los momentos anteriores a 60 Hz.
El humano sigue usando SPACE y E, sin cargas ni nuevos controles.
Al terminar, Otra carrera debe restablecer los tres contadores a 3.

La seguridad percibida de las decisiones y el efecto competitivo de regalar
cargas sólo a bots requieren prueba humana. No se cambió el balance general
para compensar este experimento. Sin commits ni modificaciones de Phaser.
