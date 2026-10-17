# Integración musical MP3

La escena autoload `scenes/Music.tscn` asigna `music_home_v2.mp3` al campo
`home_music`, y `music_race_01.mp3` / `music_race_02.mp3` al array `race_music`.
Los tres archivos están presentes en `assets/audio`.

## Reproducción

Se conserva el único AudioStreamPlayer Music, sus ocho voces SFX y los buses
Music/SFX. No se agregan reproductores de música. El script duplica los streams
y activa `loop` en MP3/OGG; mantiene el soporte WAV para recursos anteriores.
No se modifican manualmente archivos `.import` ni los MP3 originales.

- Home y selección comparten la nueva canción sin reiniciarla al navegar.
- La cuenta atrás mantiene la música del menú, como antes.
- RaceFlow solicita el tema de carrera al dar GO. En esa transición se elige
  aleatoriamente un elemento de `race_music`, con probabilidad uniforme.
- Solicitudes repetidas del tema race durante la carrera no cambian ni
  reinician la canción; el mismo tema se repite hasta salir del estado musical.
- Podio vuelve al tema de Home; regresar del podio al Home no lo reinicia.
- Reiniciar una carrera pasa por la cuenta atrás y hace una nueva elección
  al siguiente GO. Puede repetirse la canción anterior: no es alternancia forzada.
- Entrenamiento conserva sus llamadas existentes al tema race/menu.

El RandomNumberGenerator musical es independiente del RNG de gameplay.
El array es editable en el inspector: admite una sola pista. Si se retira
music_race_02.mp3 de una distribución, retirar también su referencia del array
y de Music.tscn. Un array vacío conserva `carrera.wav` como respaldo.
`home_music` vacío conserva `valle_ventoso.wav` como respaldo.
`home_arcade.wav` y los demás WAV originales permanecen en el repositorio.

El arranque conserva fade-in de 0.4 s; cambiar tema baja el mismo player hasta
−60 dB en 0.25 s, sustituye el stream y sube a su ganancia base en 0.25 s.
No hay dos canciones simultáneas. Las transiciones interrumpidas cancelan su
tween anterior. Volumen y mute del jugador permanecen en el bus Music y no son
sobrescritos por el fundido. La pausa musical conserva el comportamiento previo.

## Referencias y archivos modificados

- `scenes/Music.tscn`: home_arcade.wav → music_home_v2.mp3; array de carreras
  con referencias explícitas a ambos MP3 para incluirlos en la exportación.
- `scripts/music.gd`: carrera.wav pasa a fallback; selección musical por entrada
  al tema race, bucle MP3/OGG/WAV en copias privadas y RNG separado.
- `tests/music_test.gd` y `tests/race_audio_test.gd`: expectativas MP3.
- `tests/music_v2_test.gd`: regresión de playlist, navegación, bucle y volumen.
- README y documentos musicales: estado actual y antecedentes.

Las referencias a carrera.wav en generadores históricos y en la prueba de
compatibilidad WAV son intencionales. Ninguna se usa como canción activa con
la configuración actual. No se alteraron collision.wav, turbo.wav,
explosion.wav ni el código que dispara sus efectos.

## Verificación

Godot 4.7.2: importación sin errores de recursos ni GDScript. Suites PASS:
music_v2, music, race_audio, home_music_override, home, menu, menus_redesign,
pause y training. `music_v2_test.gd` verifica:

- Home → selector → carrera (GO) → podio → Home.
- Ambas canciones pueden elegirse en carreras sucesivas con semilla de prueba.
- Misma canción/transición ante solicitudes race repetidas.
- Configuración de una sola canción y fundidos interrumpidos.
- Volumen, mute y mantenimiento del reproductor único.
- Decodificación de los tres MP3 cruzando el fin del archivo: el contador de
  loops aumenta y el decoder entrega el bloque completo de muestras solicitado.

race_audio verifica efectos de turbo, colisión y explosión, pausa y limpieza
de voces al llegar al podio. El entorno conserva avisos ajenos a los recursos
musicales: almacén de certificados, fallback gráfico ANGLE y recursos al cerrar.

## Pendiente de escucha

La verificación técnica del loop no certifica que el final y principio de las
composiciones encajen musicalmente, ni elimina posibles silencios incluidos en
los MP3. Pendiente de validación auditiva: unión de cada loop, nivel relativo
entre los tres temas y efectos, fundido Home→GO y carrera→podio. No se editaron
ni recortaron las composiciones entregadas, ni se inventaron puntos de loop.
