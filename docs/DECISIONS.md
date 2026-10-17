# Registro de decisiones

Registro mantenido en GitHub mediante este archivo. Las fechas exactas de decisiones históricas se indican como pendientes cuando no aparecen documentadas; la existencia de código o de pruebas no se interpreta como aprobación de producto.

| ID | Fecha | Tema | Rol responsable | Estado |
|---|---|---|---|---|
| D-001 | 2026-10-17 | GitHub como fuente oficial de verdad | Game Owner / Studio Operations | Aprobada |
| D-002 | 2026-10-12 | Motor objetivo: Godot 4.7.2 Standard y GDScript | Engineering | Documentada como instrucción vigente |
| D-003 | 2026-10-17 | Alcance de esta inicialización: documentación sin cambios de gameplay | Studio Operations / Technical Documentation | Aprobada |
| D-004 | Fecha exacta pendiente; aprobada previamente | Diseño funcional del entrenamiento M7.1 | Game Owner / Product | Aprobada |
| D-005 | Fecha exacta pendiente; aprobada previamente para M6.3 | Dos cargas de turbo por corredor en carreras | Game Owner / Product | Aprobada |
| D-006 | 2026-10-17 | Plataforma principal PC/Steam y publicación móvil pospuesta | Game Owner / Product | Aprobada |
| D-007 | 2026-10-17 | Sustitución de restricciones históricas incompatibles con el MVP | Game Owner / Studio Operations | Aprobada |

## D-001 — GitHub como fuente oficial de verdad

- **Contexto y justificación:** El Game Owner confirma que GitHub es la fuente oficial de verdad del proyecto.
- **Impacto sobre otros roles:** `docs/PROJECT_STATUS.md` registra el estado; este archivo registra decisiones; los cambios deben quedar visibles en la rama y en el historial de GitHub cuando sean aprobados.
- **Referencias:** `docs/PROJECT_STATUS.md`, `docs/DECISIONS.md`, solicitud de aprobación del Game Owner.
- **Estado de evidencia:** Aprobación explícita del Game Owner en la solicitud actual.

## D-002 — Motor objetivo

- **Contexto y justificación:** El proyecto establece Godot 4.7.2 Standard y GDScript como base técnica.
- **Impacto sobre otros roles:** Los cambios deben ser compatibles con esa versión y evitar dependencias innecesarias.
- **Referencias:** `AGENTS.md`, `README.md`, `docs/verification.md`, `project.godot`.
- **Estado de evidencia:** Instrucción del proyecto documentada el 2026-10-12; no es una nueva decisión de esta revisión.

## D-003 — Alcance de esta inicialización

- **Contexto y justificación:** La solicitud limita el trabajo a auditoría y documentación, sin modificar scripts, escenas, assets ni gameplay.
- **Impacto sobre otros roles:** No se esperan cambios de comportamiento ni nuevas dependencias; la revisión humana debe partir del estado existente.
- **Referencias:** solicitud de auditoría, `AGENTS.md`, `docs/PROJECT_STATUS.md`.
- **Estado de evidencia:** Aprobada explícitamente por el alcance de la solicitud.

## D-004 — Diseño funcional del entrenamiento M7.1

- **Contexto y justificación:** El Game Owner aprobó un entrenamiento corto, de 60–90 segundos objetivo, con un jugador, cuatro zonas, sin competidores y acceso desde Home.
- **Impacto sobre otros roles:** Product considera este el alcance funcional de M7.1; Engineering mantiene la escena y la integración; QA separa pruebas automatizadas de playtesting humano.
- **Referencias:** `scenes/Training.tscn`, `scripts/training.gd`, `scripts/home.gd`, `tests/training_test.gd`, `tests/home_test.gd`, `docs/PROJECT_STATUS.md`, `docs/menus.md`.
- **Implementación:** La escena y el acceso desde Home existen; las pruebas automatizadas cubren un jugador, ausencia de competidores, cuatro etapas y navegación desde Home.
- **Verificación humana:** La duración percibida, claridad de instrucciones y experiencia completa siguen pendientes de playtesting.
- **Fecha de aprobación:** Exacta pendiente de documentar; la aprobación está confirmada por el Game Owner.

## D-005 — Dos cargas de turbo por corredor en M6.3

- **Contexto y justificación:** El Game Owner aprobó anteriormente aumentar a dos las cargas de turbo por corredor para las carreras de M6.3. Esta decisión es independiente de la carga concedida durante el entrenamiento.
- **Impacto sobre otros roles:** Engineering conserva la configuración de carrera; QA puede validar el contador y el reinicio; Product no debe extrapolar este valor al entrenamiento.
- **Referencias:** `README.md`, `docs/milestone-6.3-verification.md`, `resources/default_turbo.tres`, `scripts/turbo_config.gd`, `tests/turbo_test.gd`, `scripts/training.gd`.
- **Implementación:** El código y las pruebas actuales usan dos cargas para los corredores de carrera; el entrenamiento asigna su carga de práctica de forma independiente.
- **Fecha de aprobación:** Exacta pendiente de documentar; la aprobación histórica está confirmada por el Game Owner.

## D-006 — Plataforma principal y publicación móvil

- **Contexto y justificación:** PC/Steam es la plataforma principal aprobada. La publicación Android/iOS queda pospuesta, conservando compatibilidad futura.
- **Impacto sobre otros roles:** Engineering prioriza el flujo de PC; Release no debe tratar los presets móviles como compromiso de publicación; QA puede mantener comprobaciones de compatibilidad futura sin convertirlas en objetivo de release.
- **Referencias:** `README.md`, `export_presets.cfg`, solicitud de aprobación del Game Owner.
- **Nota:** Los presets Android/iOS demuestran capacidad de configuración futura, no una publicación aprobada.

## D-007 — Sustitución de restricciones históricas de AGENTS.md

- **Contexto y justificación:** El Game Owner aprobó sustituir la prohibición histórica de bots, carreras y power-ups, incompatible con el MVP existente.
- **Impacto sobre otros roles:** Los sistemas existentes quedan dentro del alcance aprobado; no se autorizan nuevas funcionalidades ni ampliaciones de alcance sin aprobación expresa.
- **Referencias:** `AGENTS.md`, `docs/PROJECT_STATUS.md`, `README.md`, solicitud de aprobación del Game Owner.
- **Cambio aplicado:** La regla ahora exige mantener los sistemas existentes dentro del alcance aprobado y prohíbe ampliar ese alcance sin autorización.
