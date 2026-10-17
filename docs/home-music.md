# A toda vela — música original del Home

Antecedente histórico: esta composición se conserva, pero la configuración
actual utiliza los MP3 entregados posteriormente. Véase [music-v2.md](music-v2.md).

Nueva composición instrumental sintetizada para Balloon Racing: 156 BPM,
Sol mayor, 32 compases 4/4, 49.231 segundos. Archivo integrado:
`assets/audio/home_arcade.wav` (estéreo PCM16, 44.1 kHz).

Motivo principal de llamada/respuesta con pequeños silencios, lead brillante
de carácter brass/reed, campanas en octavas, marimba sintetizada, acordes cortos
a contratiempo, bajo saltarín, bombo, caja con carácter de palmada y hi-hats.

- 0–1.54 s: firma melódica inmediata con campana y bombo.
- 1.54–6.15 s: incorporación de caja, hi-hats y acordes a contratiempo.
- 6.15–24.62 s: desarrollo del hook y pequeñas respuestas instrumentales.
- 24.62–36.92 s: sección contrastante, con menor densidad inicial.
- 36.92–49.23 s: regreso del hook con octava de campanas y cierre dominante.

La última armonía resuelve hacia la primera. Colas y ecos se envuelven dentro
del buffer para mantener continuidad al repetir; no hay silencio añadido ni
fade-out al final. El fade-in de inicio lo aplica Music, no el archivo.

## Producción y procedencia

`python tools/generate_home_music.py` reproduce exactamente la composición y
el render mediante la biblioteca estándar de Python. No usa samples,
grabaciones, melodías externas ni paquetes de terceros. Es una composición
original sintetizada durante este trabajo; no se incorporó música comercial
ni material sujeto a una licencia externa de samples. Conservar este generador
como registro de procedencia. No se atribuye una licencia de terceros ficticia.

La mezcla usa estéreo moderado, ecos a tempo, saturación suave y normalización
de pico a aproximadamente −1.51 dBFS, sin clipping PCM.

## Integración

`scenes/Music.tscn` asigna el WAV al campo `home_music` existente. No se crea
otro reproductor: se mantienen el autoload Music, el fade-in de 0.4 s, los
fundidos entre temas, volumen persistente y mute. Navegar entre Home y selector
no reinicia la canción. La carrera conserva su tema independiente.
La cuenta atrás y resultados siguen usando el tema de menú, como antes.

Para volver al tema anterior, vaciar `home_music` en el inspector; el fallback
`valle_ventoso.wav` permanece intacto. No se modificaron los generadores antiguos.

## Validación y límites

Importación y suites music, race_audio, home y home_music_override ejecutadas
con los comandos del README: las cuatro suites terminaron en PASS.
Comprobación PCM aprobada: formato, duración, pico,
ausencia de saturación numérica y salto de amplitud en la unión del loop.
La continuidad de muestras no sustituye la escucha de la unión musical.

Pendiente de aprobación auditiva humana: carácter musical, mezcla a volumen
de juego y comodidad tras varias repeticiones. No se ha realizado una escucha
crítica del render desde este entorno; las comprobaciones son técnicas.
