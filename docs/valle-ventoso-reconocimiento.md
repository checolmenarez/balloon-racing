# Valle Ventoso: reconocimiento jugable del estado actual

**Baseline histórico:** las secciones A–E y el mapa enlazado describen el circuito
anterior a la intervención experimental 01. Consultar la sección F para los cambios
posteriores autorizados y sus resultados; se conserva la evidencia original para comparar.

Fecha: 2026-10-20. Alcance: análisis, mapa y observación aislada. **No se implementó Valle Ventoso 2.0.** No se editaron Main, escenas de producción, físicas, bots, obstáculos ni arte. No se hicieron commits. Los resultados siguientes son automatizados; no hubo playtesting humano.

## A. Mapa técnico

Abrir [mapa con seis sectores e inventario completo](valle-recon/mapa.html). Incluye los polígonos efectivos instanciados por Godot, dimensiones envolventes, pasos mínimos, las 32 coordenadas de cajas, los tres rectángulos de viento, salida, bifurcación, convergencia y meta. Los paneles SVG se desplazan horizontalmente y mantienen la misma escala en X e Y. [Snapshot de geometría](valle-recon/geometry.json).

La fuente de verdad sigue siendo `scenes/Track01.tscn` y sus scripts; estos archivos son una fotografía fechada, no una segunda configuración. `tools/valle_recon.gd -- geometry` extrae los polígonos de CollisionPolygon2D después de `_ready`; `tools/valle_map.py` produce el mapa desde esa extracción, sin reconstruir las formas a partir de dibujos.

- Recorrido: x=240…18400, **18.160 px**; referencia sin ayudas ni impactos: 82,55 s a 220 px/s. Techo y suelo: y=32 y 640. Y aumenta hacia abajo.
- Globo: RectangleShape2D real de **77,44 × 118,8 px**, centro desplazado −5,72 px respecto al origen. Extensiones: 65,12 arriba y 53,68 abajo. Origen permitido por límites: y=97,12…586,32.
- S1: 240…2700, 2460 px, 11,18 s base, 1 formación, 6 cajas.
- S2: 2700…6000, 3300 px, 15 s base, 4 formaciones, 2 cajas.
- S3: 6000…9700, 3700 px, 16,82 s base, 3 formaciones, 7 cajas.
- S4: 9700…13400, 3700 px, 16,82 s base, 4 formaciones, 6 cajas.
- S5: 13400…16800, 3400 px, 15,45 s base, 3 formaciones, 7 cajas.
- S6: 16800…18400, 1600 px, 7,27 s base, 2 formaciones, 4 cajas.

Los tiempos base solo dividen distancia por velocidad; no son tiempos medidos. Cajas en x=13400 pertenecen a S5 según `get_zone_index`. Las formaciones GAP cuentan como un nodo con dos sólidos.

**S4 tiene tres límites diferentes.** El marcador Fork está en 9700; el divisor físico empieza en 10300 y termina en 12900; Merge está en 13200, mientras S5 comienza en 13400. La isla tiene puntas biseladas de 104 px y cuerpo central y=260…340. No hay dos distancias horizontales distintas a meta: la ventaja superior viene principalmente del viento.

La rama alta deja 228 px de paso sin rocas de techo, 190 en UpperRouteRockA y **180 en B**. Margen vertical del globo: 109,2 / 71,2 / **61,2 px**, respectivamente. En B, el origen debe estar entre y=145,12 y 206,32 en la sección restrictiva. La rama baja deja 300 px, o **240** sobre LowerRouteRock; margen de 181,2 / **121,2 px**. Estos intervalos estáticos no incorporan reacción, inercia ni ataques. El mapa muestra las pendientes reales; no deben sustituirse por rectángulos sólidos.

Corrientes ×1,20:

- UpperCurrent: x=10450…12850, y=112…222, tamaño 2400×110.
- MergeCurrent: x=13050…13750, y=212,5…307,5, tamaño 700×95; atraviesa el límite S4/S5.
- CorridorCurrent: x=14600…15500, y=365…435, tamaño 900×70.

El solapamiento del cuerpo activa la corriente incluso con su origen fuera del rectángulo. Turbo ×1,35 y viento usan el máximo, no se multiplican. A velocidad base sin penalización, dos segundos de turbo añaden 154 px respecto a no usarlo; dentro del viento añaden solo 66 px. Son cálculos nominales, no ganancias garantizadas de carrera.

## B. Diagnóstico por sector

Muestra: 12 semillas × 3 bots = **36 recorridos de bots**, con combate, cajas, viento y reglas de producción. El humano no pulsa teclas. Se excluye de las métricas de bots. `colisiones` significa incrementos de `collision_count`: impactos de escenario aceptados, no todos los contactos físicos ni ataques de objetos.

### S1 — Vuelo inicial

Paso mínimo 438 px; margen 319,2. Dos grupos de tres cajas en x=1200 y 2400; montaña en 1900. Sin impactos de bots, 40 recogidas, 22 objetos usados y 27 cargas personales gastadas en la muestra. Es una apertura amplia que permite familiarización; el turbo se concentra alrededor de x=2100, después de la primera montaña. Eso deriva de la espera inicial y del criterio de espacio libre de los bots, no de una decisión estratégica humana observada.

### S2 — Alternancia

Cuatro centros separados exactamente **900 px**, alternando techo/suelo. Pasos de 400, 378, 360 y 358 px; márgenes 281,2, 259,2, 241,2 y 239,2. Sin impactos de bots, 20 recogidas y 32 usos; ninguna carga personal. El patrón es regular y legible, pero podría volverse predecible. Esta es una hipótesis de ritmo: cero choques no equivale a aburrimiento ni justifica endurecerlo automáticamente.

La condición de turbo personal exige al menos 674 px libres hacia delante (220×1,35×2+80). Los huecos entre bordes de estas rocas de 280 px son 620 px: la lógica actual de bots no encuentra una ventana entre ellas. No se propone cambiar esa lógica.

### S3 — Ascenso de dificultad

DeepHangingRock deja 340 px; RisingMountain, 333; FirstCorridor, 265, con margen 146,2. **6 impactos**: dos cerca de RisingMountain y cuatro de FirstCorridor, según coordenadas de evento. 54 recogidas, 42 usos, **34 cargas personales**. El tramo de salida del corredor hacia la bifurcación concentra turbos: aproxima la decisión de ruta a una fase de mayor velocidad. Ya existe una preparación de dificultad; no hace falta introducir un primer corredor o más alternancia como si faltaran.

### S4 — Dos rutas

**27 de 41 impactos totales de bots (65,9 %)**. Alta: 21 impactos en 16 recorridos (1,31/recorrido); baja: 6 en 20 (0,30/recorrido). Se observan impactos en la entrada del divisor, rocas superiores y montaña inferior. La etiqueta de ruta es la preferencia sorteada por el bot, no una clasificación geométrica continua de su trayectoria: un impacto puede permitir atravesar la isla.

Tiempo medido entre cruzar x=9700 y x=13400, a resolución de un tick: **14,925 s alta frente a 16,898 s baja**, aproximadamente 1,97 s de diferencia. Tiempo total medio: 78,220 frente a 80,493 s. Rangos totales: alta 75,886…79,842; baja 79,238…81,149. La muestra mezcla perfiles, objetos y ataques; no demuestra causalidad ni una ventaja universal de 2,27 s.

Hay dos cajas arriba y cuatro abajo, repartidas entre x=10600 y 12700. La mayor oferta inferior **ya existe**. En esta muestra hubo 16 recogidas arriba (1 por recorrido) y 25 abajo (1,25). No se puede convertir esa diferencia en probabilidades de recogida por caja sin instrumentación adicional. Las filas bajas y=490/540 están solo a 50 px: el globo puede solapar ambos sensores al pasar, y el inventario único impide tomar los dos sin consumir el primero. Más cajas no equivalen automáticamente a más decisiones.

La ruta alta ya intercambia precisión por velocidad, pero la penalización no borró su ventaja media. Al golpear una formación se añade una excepción de colisión hasta superar su extremo derecho; para el divisor puede durar una porción larga de S4. Eso explica por qué transitabilidad y navegación correcta deben evaluarse por separado. No se propone alterar esa regla.

### S5 — Corredores

Gaps de 275, 255 y 250 px; márgenes 156,2, 136,2 y 131,2. Los centros verticales del paso se desplazan 327,5 → 407,5 → 300. **8 impactos**, cuatro alrededor de PrecisionC, dos en A y dos en B. 35 recogidas, 34 usos y 6 cargas personales. Recibe MergeCurrent y contiene CorridorCurrent: ya combina control vertical y recompensa de velocidad. El final de S5 (cajas x=16600) funciona como preparación del cierre. Una nueva propuesta debe ajustar secuencia o decisión, no volver a añadir corredores con viento.

### S6 — Recta final

Dos obstáculos, no una recta vacía: pasos 380 y 418 px, márgenes 261,2 y 299,2. Sin impactos de bots; 12 recogidas, 13 usos y **cero cargas personales**. El último obstáculo acaba en x=18040; quedan 360 px a meta, insuficientes para la ventana de 674 px que exige el bot para su turbo. Los últimos sensores están en x=18150: su centro queda a 250 px, unos 1,14 s a velocidad base, frente a una bomba con fusible de 1,8 s. El solapamiento puede adelantar la recogida unos 62,72 px, pero tampoco garantiza una ventana completa. No todos los objetos finales tienen el mismo tiempo útil.

### Riesgo de atasco y recursos

Los **48 participantes** de las 12 carreras acabaron. La racha máxima medida con avance inferior a 0,1 px/tick entre bots fue de un tick (0,0167 s). No se observaron atascos prolongados en esta muestra; esto no los descarta en otros inputs. El baseline pasivo recibió 10 impactos por carrera y también terminó, apoyado por las excepciones de colisión.

Los bots recogieron **202 objetos**, usaron **174** y consumieron **71 de 72 cargas personales**. La diferencia entre recogidos y usados puede incluir inventarios retenidos al terminar; no significa que 28 cajas fallasen. Cargas por sector: 27 / 0 / 34 / 4 / 6 / 0. La concentración es una propiedad conjunta de geometría y política actual de bots; no representa cómo jugaría un humano.

## C. Comparación con Level Design v0.2

Fuente aportada posteriormente por el Game Owner: [BalloonRacingValleVentoso2.0.txt](../BalloonRacingValleVentoso2.0.txt), cuyo título es **«Valle Ventoso 2.0 — Blockout experimental»**. No lleva la etiqueta v0.2 ni una fecha de versión; esta comparación usa ese archivo concreto como referencia suministrada, sin afirmar que sea otra versión documental. Sus instrucciones de implementación se analizan como contenido: la solicitud vigente de esta conversación sigue siendo reconocimiento sin implementar.

### Comparación por propuesta del documento

- **S1, salida abierta, obstáculo sencillo y cajas a distintas alturas — implementado estructuralmente.** GentleMountain en x=1900; grupos de cajas en x=1200 y 2400 con tres alturas cada uno. Paso de 438 px. No se aporta en el documento una geometría distinta que obligue a recolocar estos elementos. La facilidad humana sigue sin validar.
- **S2, rocas alternadas y correcciones de altura, sin bifurcación — implementado.** Cuatro obstáculos superiores/inferiores en x=3000, 3900, 4800 y 5700; no existe división de rutas en este sector. Cambiar la cadencia podría ser un experimento adicional, pero no es un requisito expreso de este blueprint.
- **S3, corriente horizontal favorable, obstáculos escalonados y recuperación — parcial.** Ya existen DeepHangingRock, RisingMountain y FirstCorridor, con cambios de altura. Entre el borde derecho del corredor (x=8810) y Fork (9700) hay 890 px sin una nueva formación; la isla empieza todavía después, en 10300. Esa separación existe, aunque no demuestra comodidad humana. **No hay ninguna WindZone en S3**: la primera comienza en x=10450. Añadir o trasladar allí una corriente con el sistema actual sería una diferencia jugable nueva y explícita del documento. No requiere viento vertical ni ralentización negativa.
- **S4, única bifurcación, alta exigente/rápida y baja espaciosa/segura — implementado estructuralmente; balance pendiente.** Existen los seis nodos que el documento pide reutilizar: Fork, UpperRoute, LowerRoute, Merge, RouteDivider y UpperCurrent. La alta tiene menor paso y viento ×1,20; la baja es más amplia. La diferencia temporal ya es medible (sección B). No hay un atajo geométrico más corto en X. El documento no fija una ventaja objetivo, por lo que no se puede declarar incumplimiento de balance solo por los tiempos observados ni presentar la bifurcación o el viento superior como novedades.
- **S5, precisión estática, cambios de altura y viento moderado, sin segunda bifurcación — implementado estructuralmente.** PrecisionA/B/C cambian el centro del paso; CorridorCurrent da ×1,20 y MergeCurrent alcanza el comienzo del sector. No hay una segunda división física. “Moderado” no tiene umbral cuantificado en la referencia: la intensidad existe, su adecuación requiere playtesting.
- **S6, obstáculos iniciales sencillos, cajas opcionales y tramo final abierto — parcial respecto a la intención de ritmo.** Existen dos obstáculos, cuatro cajas y meta en 18400. FinalLower está centrado en 17900, al 68,75 % del sector; su sólido termina en 18040. Solo los últimos 360 px están abiertos, alrededor de 1,64 s a velocidad base. Por tanto, el cierre abierto existe, pero los obstáculos no están concentrados únicamente al inicio. El documento no indica la longitud mínima de la recta: no se inventa un umbral de aceptación. Las cajas finales en 18150 dejan poco tiempo de uso, como se analiza en B.

### Restricciones y aceptación

Los límites de los seis sectores coinciden con los del documento; los intervalos enteros que terminan en 2699, 5999, etc. equivalen a los límites de transición usados en el mapa. Ya hay una sola bifurcación en S4, viento exclusivamente horizontal favorable y dos cargas personales. Preservar controles, objetos, HUD, menús, podio y arte es una restricción de conservación, no una funcionalidad nueva. No se propone crear cañones funcionales, molinos con colisión dinámica ni otra arquitectura de navegación.

Las pruebas de la sección E aportan evidencia del estado actual para completar los seis sectores, llegar con cuatro corredores, navegación limpia con entradas programadas, efectos de viento, objetos, turbo, clasificación y meta. Los 48 finales y la ausencia de atasco prolongado son resultados de la muestra, no garantías universales.

Quedan límites de aceptación concretos:

- **Comparación controlada de S4:** el documento usa “interior/exterior” sin asociarlo a alta/baja. Se conserva alta/baja como nomenclatura verificable. El observador mide S4 con bots, pero mezcla perfiles y combate. `track_test` compara rutas con entradas programadas y sin combate, aunque informa el tiempo total, no un split aislado de S4. No se declara ejecutado el experimento controlado de S4 interior/exterior solicitado en la referencia.
- **Bots por ambas ramas:** las semillas observadas incluyen 16 recorridos con preferencia alta y 20 baja. No equivalen a una matriz controlada de todos los perfiles por ambas rutas; las excepciones de colisión pueden permitir cruzar la isla. `race_test.gd` existe, pero no fue ejecutado en este reconocimiento.
- **Importación sin errores:** no se cumple literalmente en el entorno de esta auditoría: hubo errores de certificados y de escritura de ajustes. Las suites pasaron, pero eso no convierte la importación en limpia. Tampoco se puede evaluar “sin errores nuevos” de un blockout que no se ha implementado.
- **Diversión, dificultad y balance:** pendientes de prueba humana, como también exige el documento.

**Conclusión de la comparación:** la mayor parte del blueprint describe sistemas y estructuras ya presentes. El cambio explícito más claro es el viento en S3; el cierre de S6 necesita concretar su intención espacial. En S4 la oportunidad es ajustar preparación y riesgo/recompensa, no construir otra bifurcación. No se justifica rediseñar los seis sectores solo para reproducir la lista del documento.

## D. Cinco oportunidades, ordenadas por beneficio/esfuerzo estimado

Son hipótesis para autorizar y probar después. No se aplicó ninguna. Las cinco reutilizan mecánicas existentes; el esfuerzo indica alcance relativo, no una cotización.

1. **Dar más espacio de preparación a la entrada alta de S4.** Beneficio alto / esfuerzo bajo-medio. Ensayar un inicio físico de isla algo más tardío, manteniendo Fork y el resto de la ruta como referencias de comparación. Ataca la concentración de impactos de entrada tras el turbo de S3; no añade otra bifurcación ni modifica el bot. La señalización ya existe: comprobar primero si el problema es distancia de maniobra o lectura. Criterio: reducir impactos de entrada sin borrar la exigencia posterior de las rocas altas; medir con los mismos perfiles/semillas y con humanos.

2. **Introducir la corriente favorable que falta en S3.** Beneficio potencial alto / esfuerzo bajo-medio. Ensayar una zona horizontal corta en el tramo de recuperación posterior a FirstCorridor, reutilizando WindZone y el multiplicador existente. Es el delta explícito de la referencia; no se propone viento vertical. Elegir su posición y longitud después de medir la preparación de S4: la muestra ya concentra 34 cargas de turbo en S3, y el viento no se suma al turbo. Criterio: que el recorrido por la corriente aporte una decisión de altura o un beneficio medible a velocidad base, sin agravar los impactos de entrada a la isla ni eliminar la recuperación. No añadirla automáticamente si el ensayo solo acelera una sección ya saturada de turbo.

3. **Recalibrar la duración del premio superior.** Beneficio alto / esfuerzo bajo, con necesidad de validación controlada. Probar menor longitud de UpperCurrent, conservando ×1,20, contra el estado actual. La novedad es el balance del premio, no crear viento en la rama alta. La alta sigue siendo más rápida pese a más impactos en la muestra. Criterio: una ejecución alta limpia conserva ventaja, mientras una ejecución con errores tiene un coste observable frente a la baja. El blueprint pide incentivo temporal pero no fija su magnitud: no reducirlo por defecto ni fijar un objetivo de segundos sin acordarlo con el Game Owner y probar ambas rutas con inputs comparables.

4. **Separar longitudinalmente cajas que hoy son alternativas casi simultáneas.** Beneficio medio-alto / esfuerzo bajo. Probar el traslado de una de las cajas inferiores en cada par de S4 a otro X transitable dentro de la rama, conservando número total y sorteo de objetos. Evita que y=490/540 en el mismo X actúe como dos sensores para una sola oportunidad de inventario. La rama baja ya tiene cuatro cajas: no se propone añadir más. Criterio: aparecen oportunidades distintas de recoger–usar–recoger, sin que la baja domine por suministro ni queden cajas dentro de sólidos. Validar clearance con la consulta física existente. Es una oportunidad derivada del análisis, no una exigencia explícita del blueprint.

5. **Anticipar los recursos finales y ampliar el cierre abierto de S6.** Beneficio medio / esfuerzo medio. Ensayar FinalLower y el último grupo de cajas más temprano, con clearance comprobado, conservando meta, número de elementos y reglas de objetos. Concreta la intención del blueprint de obstáculos iniciales y final abierto; hoy quedan solo 360 px tras el último sólido. Criterio: medir usos e impactos de objetos recogidos en ese grupo antes de que termine su objetivo, y comprobar que las cajas no exigen atravesar el obstáculo. Si se desea una ventana de turbo de bot, deben quedar ≥674 px despejados y cumplirse además sus filtros de altura/velocidad y disponibilidad de cargas; una recta mayor por sí sola no garantiza uso. La bomba puede explotar antes del fusible al colisionar: el fusible no es un tiempo mínimo de utilidad.

## E. Evidencia, reproducción y límites

Fuentes revisadas: Track01.tscn, track.gd, bot_controller.gd, obstacle.gd, wind_zone.gd, Balloon.tscn, balloon.gd, balloon_items.gd, item_box.gd, item_combat.gd, item_projectile.gd, main.gd, race_flow.gd; recursos de físicas, turbo y perfiles; README, PROJECT_STATUS, DECISIONS y verificación M6.3. Para completar C se leyó el archivo aportado `BalloonRacingValleVentoso2.0.txt` íntegro. El historial M6.3 se usa como contexto, no como sustituto de las ejecuciones nuevas. Esta ampliación documental no cambió el circuito ni volvió a ejecutar las simulaciones: conserva la evidencia medida del reconocimiento.

Motor observado: **Godot 4.7.2.stable.official.ed1daf0bf**. Se consultaron las referencias oficiales de [línea de comandos](https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html) y [SceneTree](https://docs.godotengine.org/en/stable/classes/class_scenetree.html) para ejecución aislada y visualización de colisiones. La documentación stable es una referencia de API, no una prueba de la versión local.

Resultados de esta sesión:

- Importación headless: salida 0; hubo errores de entorno al leer certificados y guardar ajustes del editor fuera del workspace. No se declara importación libre de errores.
- `track_test -- 60`: PASS, 0 fallos. Alta limpia 79,35 s; baja limpia 81,53 s. Baselines incorrectos: 85,77 s/10 impactos; 83,83 s/10; 82,30 s/4. Este test desactiva combate y RaceFlow; **no equivale a una carrera competitiva completa**.
- `competition_test -- 6`: PASS, 0 fallos; cuatro llegadas en cada semilla, mismas físicas y límite de velocidad, clearance de cajas. Se preserva su JSON de resultados.
- `obstacle_test` a 60 Hz, `turbo_test`, `chaos_test`, `race_flow_test`: **PASS, 0 fallos**, salida 0. Resultados y mensajes de cierre en los logs conservados. Las suites distinguen impactos, cargas, viento/objetos y ciclo de carrera.
- Observador `valle_recon -- 12`: 12 semillas, sin modificar controladores ni desactivar combate. Registra deltas de contadores por tick, tiempos de sector, eventos con posición, tiempo en viento/boost y rachas de avance bajo. No registra intención humana, todos los contactos ni adjudica automáticamente cada impacto a un obstáculo.
- Se corrigió un nombre de nodo en la primera extracción de geometría (`Shape`, no `CollisionShape2D`) y se volvió a ejecutar el observador. Una primera invocación de track/obstacle recibió 6 como frecuencia física; se repitieron a 60 Hz. Las cifras principales corresponden a 60 Hz; no se mezclan esos ensayos.
- Modo `visual`: arranque headless de 180 frames, salida 0, sin errores GDScript. Esto verifica carga, no legibilidad. Los seis SVG pasan el parser XML; se rasterizó e inspeccionó la geometría de S4 con Godot (su rasterizador omite texto SVG). No hubo navegador conectado disponible para comprobar el HTML renderizado. El mapa conserva etiquetas SVG para el navegador, pero su tipografía no fue validada visualmente en esta sesión.
- Se verificaron contra el JSON final los 36 recorridos de bots, 48 llegadas, 41 impactos y 71 cargas; inventario de geometría: 17 obstáculos, 32 cajas y 3 vientos. La vista Canvas es un complemento fuera del repositorio; no hubo compilador/runtime de Canvas accesible para validarla. El mapa HTML/SVG y el informe son la entrega independiente de ese complemento.
- Los logs muestran errores de certificados del entorno y avisos de objetos/recursos vivos al cerrar, también documentados históricamente para audio. No se atribuye causalidad nueva ni se considera su limpieza parte de esta auditoría. Las primeras ejecuciones también tuvieron restricciones al escribir logs de usuario; las posteriores usan `.godot`.

Reproducir desde PowerShell en la raíz (ruta del motor tomada del README):

```powershell
$godot = "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64_console.exe"
& $godot --headless --path . --fixed-fps 60 --log-file .godot/valle-recon.log --script res://tools/valle_recon.gd -- 12
python tools/valle_map.py
& $godot --headless --path . --fixed-fps 60 --script res://tests/track_test.gd -- 60
& $godot --headless --path . --fixed-fps 60 --script res://tests/competition_test.gd -- 6
```

Depuración durante una carrera normal, sin cambiar Main:

```powershell
& $godot --path . --script res://tools/valle_recon.gd -- visual
```

Activa `SceneTree.debug_collisions_hint` antes de cargar Main. Se pueden ver sólidos y sensores; F2 conserva los datos existentes. No se escriben propiedades de gameplay ni se crea un autoload. Este modo es manual: no añadir `--fixed-fps` para juzgar ritmo en tiempo real. El arranque se comprueba separadamente; su legibilidad en carrera y el playtest humano quedan pendientes. Para revertir la instrumentación basta retirar `tools/valle_recon.gd` y su `.uid` si Godot lo generó; el generador de mapa tampoco es referenciado por producción.

Evidencia durable en [valle-recon](valle-recon/): geometría, mapas, JSON de carreras y logs. Los tiempos de cruce de S4 se muestrean a 60 Hz (aprox. ±1 tick por cruce); los de meta los interpola RaceFlow. La agrupación por ruta no controla perfil ni objetos: usarla como señal para un experimento, no como demostración causal. La diversión, lectura visual, tensión, recuperación y preferencia de ruta deben evaluarse jugando. La sección C queda completada contra el archivo de blockout aportado; su equivalencia de versión con la etiqueta v0.2 no está documentada.

## F. Intervención experimental 01

Autorizada expresamente en la solicitud «Mejora jugable incremental 01», 2026-10-20.
Rama: `dev/valle-ventoso-incremental-01`. Sin commit, push ni merge.
El único archivo de producción modificado es `scenes/Track01.tscn`.
Se mantienen los seis sectores, referencias, 17 formaciones y 32 cajas; sin cambios
en Main, IA, físicas, controles, HUD, personajes ni balance de objetos/turbo.

### Configuración final

- **S3:** RecoveryCurrent, centro (9100,335), tamaño 400×70, ×1,20. Sensor x=8900…9300,
  y=300…370. El globo deja de solaparlo aproximadamente en x=9338,72, antes de Fork=9700.
  Reutiliza WindZone, sus flechas y reglas existentes. No hay viento vertical.
- **S4:** RouteDivider pasa de centro x=11600/ancho 2600 a x=11800/ancho 2200.
  Su entrada se retrasa de 10300 a 10700 (+400 px), manteniendo el extremo en 12900
  y las superficies y=260/340. Se conservan las rocas posteriores y **UpperCurrent
  exactamente igual**, en posición, tamaño y multiplicador. El bisel de la isla sigue
  siendo el proporcional que ya genera obstacle.gd; no se modifica ese script.
- **S6:** FinalUpper 17250→16930; FinalLower 17900→17580. Ambos avanzan 320 px,
  conservando 650 px entre centros y 380 px entre sus bordes. Box18/31: x=17600→17220;
  Box19/20: x=18150→17800; alturas y sensores sin cambios. Último sólido termina
  en 17720: **680 px abiertos frente a 360**. Meta inalterada en 18400.

### Pruebas y comparación

Pruebas a 60 Hz en Godot 4.7.2: `track_test`, `obstacle_test`, `race_test` (bots con
ambas asignaciones de rutas), `race_flow_test`, `chaos_test`, `turbo_test`, `items_test`,
`competition_test -- 6` y `valle_incremental_test`. Los resultados finales se conservan
en [registro de pruebas](valle-recon/incremental-01-tests.txt).

- **Viento aislado, sin turbo:** mismo vuelo x=8860→9700 a altura objetivo 335:
  3,833 s desactivado frente a 3,467 s activado; ahorro **0,367 s**, velocidad 220→264→220.
  La vía baja a y=520 tarda 3,833 s, sin activar viento. Una cuarta pasada desde
  x=8500 cruza FirstCorridor y evita el viento por abajo sin impactos: la alternativa
  no depende de colocar al globo directamente después del obstáculo.
- **Rutas programadas sin combate:** alta **79,35→78,98 s**, baja **81,53→81,17 s**,
  ambas con cero impactos. El conductor de prueba adelanta su última maniobra
  de x=17550 a 17250 para seguir las rocas recolocadas; no se relajó la aserción de cero choques.
  Se añadió medición de S4 (9700→13400): alta 14,633→14,650 s y baja 16,817→16,817 s.
  La variación superior es un tick; conserva una ventaja limpia de aproximadamente 2,17 s.
  Para obtener el split del baseline se ejecutó su escena de HEAD en una copia temporal
  en `.godot`, con el conductor original de S6 y el mismo observador de tiempos.
- **12 semillas, 36 recorridos de bots con combate:** impactos S4 **27→26**;
  entrada, definida consistentemente como x∈[9700,11000), **9→8**. S6 **0→0**.
  Impactos por sector finales: 0/0/6/26/8/0; total **41→40**. No es una mejora grande
  ni demuestra causalidad aislada: el combate y el inventario pueden divergir tras el cambio.
- **Tiempo de bots:** media total **79,483→79,350 s**, rango final 75,886…81,075 s.
  Media S4 alta **14,925→14,826 s** (16 recorridos); baja **16,898→16,838 s** (20).
  Las preferencias de ruta se conservan para las mismas semillas; no garantizan
  trayectoria perfecta porque siguen vigentes las excepciones tras colisiones.
- **S6:** desde el centro de las últimas cajas quedan **600 px frente a 250**:
  2,73 s a velocidad base frente a 1,14; incluso a 297 px/s quedan 2,02 s frente a 0,84.
  Son ventanas nominales sin penalizaciones ni retraso de reacción, no impactos garantizados.
  Usos de objetos dentro de S6: **13→18**; recogidas **12→11**. Los usos pueden proceder
  de inventarios recogidos antes: no se atribuyen todos a las cajas recolocadas.
- **Llegadas y bloqueos:** **48/48** en la muestra final, igual que el baseline.
  Racha máxima de avance inferior a 0,1 px/tick: un tick; sin atasco prolongado observado.

Se descartaron dos configuraciones previas: la primera elevó S4 a 29 impactos;
la segunda redujo S4 a 26 pero elevó S6 a 5. Restaurar la separación original de
las rocas finales eliminó esa regresión en la misma muestra. Los resultados de esas
configuraciones no se mezclan con los finales. Una pasada de competencia del segundo
candidato se interrumpió para ajustarlo; solo cuenta la repetición completa final.

La importación carga el proyecto pero mantiene los errores de entorno ya observados
(certificados y escritura de ajustes del editor). Las capturas con renderer gráfico
usan ANGLE; los avisos de recursos al cierre permanecen. No se declara un entorno
sin errores ni validación humana. Se consultó la referencia oficial de
[Area2D](https://docs.godotengine.org/en/stable/classes/class_area2d.html) para comprobar
el comportamiento de los sensores; la nueva zona reutiliza la implementación existente.

Evidencia final: [simulaciones](valle-recon/incremental-01.json),
[geometría instanciada](valle-recon/incremental-01-geometry.json) y registro de pruebas.
El mapa y JSON originales de A–E se conservan como baseline, sin sobrescribirlos.
Cambios de soporte: `tests/track_test.gd`, nuevo `tests/valle_incremental_test.gd`,
README, esta sección y la referencia de estado en PROJECT_STATUS.

**Comprobación personal:** recorrer S3 entrando y evitando la corriente sin D;
probar la transición a la rama alta con y sin turbo; verificar que las rocas posteriores
siguen exigiendo precisión; recoger y usar A en S6 y reservar D para el cierre;
comprobar ambas rutas, adelantamientos y lectura de las cajas en movimiento.
Las pruebas automatizadas demuestran transitabilidad y efectos medidos, no diversión.
