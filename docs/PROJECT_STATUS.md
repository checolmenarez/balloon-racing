# Estado del proyecto

Fecha de actualización: 2026-10-17  
Commit de referencia: `448d2023d4f657f46b73d2ae00d9fe9ded44569c` — `MVP commit 1` (2026-10-16)

## Resumen del MVP

El repositorio contiene un prototipo jugable local de Balloon Racing para Godot 4.7.2 Standard: un jugador y tres bots recorren Valle Ventoso, con menús, selección de personaje, carrera, objetos, turbo, viento, pausa, audio y resultados. La escena de entrada configurada es `scenes/StartMenu.tscn`; la carrera se instancia desde `scenes/Main.tscn`.

Este estado se basa en el código presente, el README y las verificaciones históricas de `docs/`. No se hizo playtesting humano durante esta auditoría. El commit de referencia es el único commit del historial observado.

## Sistemas y funcionalidades implementados

La siguiente lista describe implementación observable y documentación relacionada; no implica que cada aspecto esté validado perceptualmente.

- Estructura Godot: escenas reutilizables en `scenes/`, lógica GDScript en `scripts/`, parámetros en `resources/`, pruebas en `tests/` y assets en `assets/`. `project.godot` apunta al Home como escena principal y define el Input Map.
- Vuelo y colisiones: `Balloon.tscn`, `balloon.gd`, `flight_controller.gd` y `obstacle.gd`, con física y límites parametrizados. Evidencia: `docs/milestone-1-verification.md`, `docs/milestone-2-verification.md`.
- Pista Valle Ventoso: `Track01.tscn` contiene referencias de inicio, bifurcaciones, meta, obstáculos, cajas y tres zonas de viento. Evidencia: `docs/milestone-3-verification.md` y `docs/milestone-6.3-verification.md`.
- Flujo de carrera: cuenta atrás, reloj, clasificación, meta, timeout, podio y reinicio mediante `race_flow.gd`, `race_standings.gd` y `RaceOverlay.tscn`. Evidencia: `docs/milestone-6-verification.md`.
- Rivales locales: `Main.tscn` instancia tres controladores bot y tres perfiles en `resources/bot_*.tres`. Evidencia: `docs/milestone-4-verification.md` y las simulaciones de M6.
- Objetos y caos: cajas, cohete, bomba, Turbo, Tormenta, protección, penalizaciones y reaparición mediante `item_box.gd`, `item_combat.gd`, `item_projectile.gd`, `storm_effect.gd` y `default_items.tres`. Evidencia: `docs/milestone-5-verification.md`, `docs/milestone-6.3-verification.md`.
- Turbo personal y viento: estado de cargas configurable en `turbo_config.gd`/`default_turbo.tres` y zonas en `Track01.tscn`. El README vigente documenta dos cargas por corredor; el historial de M6.2 conserva una fase experimental anterior que no debe tomarse como estado actual.
- Menús, selección y personajes: `StartMenu.tscn`, `CharacterSelect.tscn`, `home.gd`, `start_menu.gd`, `selection_profiles.gd` y `character_catalog.gd`. Evidencia: `docs/home.md`, `docs/home-v2.1.md`, `docs/character-selection.md` y `docs/characters.md`.
- Pausa y controles: `RaceOverlay.tscn`, `race_overlay.gd` y el Input Map de `project.godot`. Evidencia: `docs/controls-pause.md`.
- Audio: `Music.tscn`, `music.gd` y recursos MP3/WAV en `assets/audio`. Evidencia: `docs/music-v2.md`, `docs/home-music.md` y `docs/home-v2.1.md`.
- Entrenamiento M7.1: `scenes/Training.tscn`, `scripts/training.gd` y `tests/training_test.gd` implementan una sesión de un jugador, sin competidores, con cuatro zonas y duración objetivo de 60–90 segundos. `scripts/home.gd` conecta el botón del Home con la escena. El diseño está aprobado y la integración está implementada; la experiencia completa aún requiere playtesting humano.

## Funcionalidades verificadas

### Validación automatizada o reproducible documentada

Los documentos históricos reportan, sobre Godot 4.7.2 Standard, importación headless sin errores y PASS en suites de vuelo, obstáculos, pista, carrera, flujo de carrera, objetos, visibilidad, turbo, caos, pausa, menús, personajes, música y competencia. `tests/training_test.gd` y `tests/home_test.gd` también aportan evidencia automatizada para la ruta M7.1 y su acceso desde Home. También se documentan simulaciones reproducibles de M6 y M6.3, incluida `docs/m6-simulations.json`.

Las verificaciones gráficas documentadas ejecutan scripts sin `--headless` y revisan capturas de personajes, menús, pista, objetos, visibilidad, M6 y M6.3. Esas comprobaciones no equivalen a una prueba de aceptación humana del juego.

La importación exitosa solo demuestra que Godot puede cargar el proyecto. Los PASS de suites automatizadas demuestran las condiciones que cada prueba cubre; no sustituyen playtesting humano. Durante esta actualización documental se revisaron archivos y referencias sin modificar gameplay ni ejecutar suites de juego nuevas; las afirmaciones anteriores son resultados históricos citados en los documentos indicados.

### Playtesting humano pendiente

La documentación existente solicita revisar manualmente F5, controles UP/A/D, pausa, ambas rutas, cajas reaparecidas, Tormenta, adelantamientos, podio, reinicio, mando físico, legibilidad en movimiento, dificultad, balance, diversión y mezcla/loops de audio. Para M7.1 queda pendiente validar humanamente la duración percibida de 60–90 segundos, claridad de instrucciones, ritmo, accesibilidad y experiencia completa, aunque el acceso desde Home ya está implementado y cubierto por pruebas automatizadas.

## Trabajo en curso y pendientes conocidos

- Completar la revisión humana reproducible descrita en `docs/milestone-6.3-verification.md`, `docs/controls-pause.md`, `docs/menus.md` y `docs/music-v2.md`.
- Completar el playtesting humano de M7.1 y registrar sus resultados sin confundirlo con la cobertura automatizada existente.
- Mantener la decisión aprobada de dos cargas para carreras M6.3 separada de la carga de entrenamiento; la fase experimental histórica de M6.2 debe conservarse como historial.
- Confirmar traducciones reales: `localization/character_selection.pot` prepara cadenas, pero `docs/character-selection.md` indica que aún deben crearse y registrarse archivos PO por idioma.
- Mantener bajo observación el aviso de referencias de audio pendiente al cerrar Godot 4.7.2, registrado en README.

PC/Steam es la plataforma principal aprobada. Android/iOS están pospuestos, aunque se conserva compatibilidad futura en los presets. Las prioridades anteriores son decisiones o pendientes explícitamente documentados, no una planificación técnica nueva.

## Riesgos y deuda técnica

- La evidencia automatizada usa entradas programadas, simulaciones y capturas forzadas; no mide comodidad, balance, dificultad ni diversión humana.
- La GPU local usa el fallback ANGLE por no exponer OpenGL 3.3. Las ejecuciones documentadas funcionan, pero la compatibilidad visual con otros equipos no está demostrada.
- La documentación histórica contiene decisiones experimentales y parámetros sustituidos; sin una resolución humana puede inducir a duplicar o aplicar valores obsoletos.
- Los sistemas existentes de bots, carreras y power-ups están dentro del alcance aprobado; `AGENTS.md` prohíbe ampliar ese alcance o añadir nuevas funcionalidades sin autorización.
- La localización está preparada parcialmente y los textos largos deben revisarse por idioma.
- El aviso de referencias de audio al cerrar Godot permanece sin resolución documentada.
- Las decisiones históricas de M6.3 y M7.1 no tienen todas una fecha original documentada; el registro conserva esa incertidumbre explícitamente.

## Próximas prioridades conocidas

1. Realizar y registrar la revisión humana pendiente del MVP.
2. Completar y registrar el playtesting humano del entrenamiento M7.1.
3. Mantener separadas las cargas de carrera M6.3 y la carga de entrenamiento en futuras verificaciones.
4. Confirmar localización y revisar audio/compatibilidad visual en el entorno PC/Steam.
5. Mantener Android/iOS como compatibilidad futura pospuesta, no como objetivo de publicación actual.

Estas prioridades se derivan de pendientes explícitos de la documentación existente. Requieren confirmación del responsable del proyecto antes de convertirse en trabajo técnico.
