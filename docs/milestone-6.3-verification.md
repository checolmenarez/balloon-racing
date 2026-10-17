# M6.3 — verificaciones

Implementado por etapas A–F sobre Godot 4.7.2 Standard. Validación inicial
sin errores bloqueantes. Sin cambios de gravedad, quemador o velocidad base.

## Cambios

- A: turbo_config, project.godot, balloon_items y main: dos cargas por
  corredor, D (antes SHIFT), nombre visible Turbo, A independiente (antes E).
- B: Balloon.tscn, balloon.gd, item_projectile, track, bot_profile y los
  tres recursos de bots: escala 0,88, colisión coherente, límites decimales,
  explosión ajustada al nuevo cuerpo y errores suaves algo mayores.
- C: Track01, item_box e item_config: 32 cajas frente a 21, más alturas,
  reaparición 8 s y obligación de abandonar el sensor para repetir recogida.
- D: nuevos StormEffect.tscn/storm_effect.gd; inventario, ItemCombat,
  ItemConfig y HUD integran selección, advertencia, penalización y protección.
- E: nuevos WindZone.tscn/wind_zone.gd, tres áreas en Track01; cálculo de
  velocidad centralizado en BalloonItems.speed_multiplier y Balloon._forward_speed.
- F: chaos_test y chaos_visual_test nuevos; regresiones adaptadas a tamaño,
  turbo personal y corrientes; pruebas de reinicio ampliadas; README actualizado.

Configuración y valores completos en README. Turbo y viento toman la ayuda
más fuerte (tope ×1,35), y se aplica la penalización más fuerte, no el producto
de penalizaciones. El rebote temporal de M2 se conserva. Tormenta fija su
objetivo al usarla; si éste termina antes del rayo, su efecto se cancela.
El cooldown empieza al aceptar la advertencia y cubre como mínimo advertencia
más penalización. Un ataque rechazado no gasta inventario.

## Pruebas ejecutadas

- Importación headless, compilación y ejecución de Main sin errores GDScript.
- turbo_test: dos cargas, tecla de turbo real, inventario conservado, no acumulación,
  tiempos, bloqueo fuera de carrera y reinicio. PASS.
- flight_test, obstacle_test: vuelo, límites, impactos y recuperación. PASS.
- race_test: los tres perfiles completan ambas ramas; clasificación, F2,
  cámara y física común. Aísla corrientes para medir navegación a velocidad base.
- track_test con corrientes reales: ambas rutas sin choques con entradas
  programadas; alta 79,35 s, baja 81,53 s a 60 Hz. Vuelos incorrectos también
  terminan. Estas entradas no prueban facilidad humana.
- items_test: cohete, bomba, Turbo, recogida, inventario y adelantamientos.
  Selecciones unitarias de los tres objetos originales aíslan Tormenta.
- visibility_test: orden local, contorno, opacidad, histéresis, cambio de
  propietario y ausencia de separación física. PASS.
- race_flow_test: cuenta atrás, salida, orden interpolado, podio, DNF,
  botón Otra carrera; restaura cargas, cajas, tormentas y corrientes. PASS.
- chaos_test: tamaño/hitbox, espacio para el globo en las 32 cajas, alturas,
  reaparición y recogida por rival; probabilidad por posición, objetivo líder,
  retención de Tormenta, advertencia HUD, daño temporal, control vertical,
  protección y uso automático por bot; viento para todos, movimiento real,
  áreas superpuestas, composición limitada y retorno a 220 px/s. PASS.
- competition_test: seis semillas con todos los sistemas activos y humano
  pasivo. Todos los competidores llegaron; resultados en .godot/m63-simulations.json.
- chaos_visual_test: capturas de corrientes/F2, nube de aviso, rayo y cuatro
  globos superpuestos. La nube se desplazó ligeramente para no tapar TÚ.

La adaptación decimal del techo reveló una comparación de punto flotante
que dejaba velocidad hacia fuera; se corrigió con tolerancia. La recogida al
reaparecer se consulta sólo en ese instante, evitando tomar automáticamente
una caja distinta al vaciar el inventario mientras se permanece sobre ella.

## Revisión humana pendiente

F5, flecha arriba, D y A; SPACE pausa/reanuda. Observar dos cargas y espera inicial. Probar ambas
ramas y salir/entrar a corrientes, recoger cajas a distintas alturas, usar
Tormenta desde atrás y comprobar aviso cuando el humano lidera. F2 muestra
cargas, velocidad, tiempos de efectos, tormentas recibidas y viento activo.
Terminar y pulsar Otra carrera para comprobar el estado limpio.

Quedan por valorar diversión, oportunidades reales de remontada, dificultad
de los bots, densidad de cajas y legibilidad en movimiento. No se declaran
validados por las simulaciones. El motor usa ANGLE automáticamente por la
GPU local; las capturas funcionan. Sin errores bloqueantes conocidos,
sin commits y sin modificar Phaser.
