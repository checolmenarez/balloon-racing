# Selección de personaje — refinamiento visual

La escena existente `scenes/CharacterSelect.tscn` conserva su controlador
`scripts/start_menu.gd`, el estado `RaceSelection.selected`, el catálogo de IDs
y el Theme Fredoka/Lilita. El Home sigue abriendo esta pantalla desde Selección
de personaje; ¡CORRER! conserva su acceso directo con la elección actual.
Comenzar carrera abre Main; Volver/Escape/B regresan al Home. La música continúa.

## Assets y correspondencia verificada

Se utilizan los siete PNG de `assets/ui/character_selection`. No estaba presente
`PREVIEW_character_select_mockup.png`; la lámina entregada guio los colores,
marcos y botones. Los nombres de los cuatro archivos no corresponden a su
contenido. `scripts/selection_profiles.gd` documenta y resuelve la asociación:

- Calaca → `char_timo_select.png` (pirata con calavera).
- Timo → `char_lord_pomposo_select.png` (aviador y rayo).
- Greta → `char_calaca_select.png` (inventora, engranajes y llave).
- Lord Pomposo → `char_greta_select.png` (noble con corona).

Los originales permanecen intactos. No se alteran sprites de carrera ni física.
La lámina se recorta con AtlasTexture para tarjetas y botones; los botones se
escalan antes de aplicar nueve segmentos para conservar los bordes redondeados.
El panel de detalle se recrea con StyleBoxFlat inspirado en la lámina para que
sus adornos no resten legibilidad al texto.

## Contenido y localización

SelectionProfiles contiene id, display_name, subtitle, short_role, description,
tags y art_texture para cada personaje, con los textos solicitados. Los nombres
de las tarjetas, roles, ficha, tags, botones y ayudas son controles de texto.
Solo la marca del logotipo oficial permanece dentro de su PNG.

Los campos dinámicos pasan por `tr()`. `localization/character_selection.pot`
incluye esos textos y los estáticos de la escena para preparar traducciones.
Crear archivos PO por idioma y registrarlos en las traducciones del proyecto;
actualizar el POT si cambian los perfiles. La descripción usa autowrap, los
contenedores calculan tamaños y los textos extensos deben validarse por idioma.
No hay traducciones ficticias ni cambios de habilidades asociados a los tags.

## Navegación y animación

- Foco inicial en la selección guardada; valor inválido → Calaca.
- Click, flechas izquierda/derecha y cruceta/stick horizontal cambian selección.
- Tab/Shift+Tab recorren tarjetas, Comenzar y Volver. Arriba/abajo conectan acciones.
- Enter confirma/activa; A y B del mando se manejan solo en esta escena porque
  ui_accept/ui_cancel globales no tenían eventos de mando. InputMap no se modifica.
- Tarjeta normal azul; selección dorada persistente, foco con contorno blanco,
  hover iluminado y feedback de presión. Escala seleccionada 1.05 en 0.16 s.
- Flotación del retrato seleccionado: Tween sobre fase sinusoidal continua,
  amplitud 4 px, periodo 3.2 s; no se reinicia por frame ni se detiene a mitad del ciclo.
- Detalles: aparición y desplazamiento de 8 px en 0.16 s; CTA con brillo periódico.
- `reduce_motion`, `bob_amplitude` y `selected_scale` son configurables.
  reduce_motion desactiva el movimiento al instanciar; el feedback visual permanece.
- Se desactiva el snapping GUI durante el selector, restaurándolo al salir.
  Se cancelan tweens al cambiar selección y al abandonar la escena.

## Verificación

`tests/character_selection_test.gd` comprueba clicks en las cuatro tarjetas,
campos de ficha, tags, asociación de arte, fallback, flechas con wrap, Tab,
Enter, eventos sintéticos de mando (cruceta/A/B), persistencia y navegación.
Sin headless guarda `.godot/character-selection-{720,800,900}.png`.

Se ejecutan además menu_test, menus_redesign_test y home_test para conservar
elección en carrera, podio, regreso al Home y navegación existente. Las capturas
deben revisarse a 1280×720, 1280×800 y 1600×900. La prueba con un mando físico y
la valoración perceptual del movimiento quedan para validación manual.

Archivos cambiados: CharacterSelect.tscn, start_menu.gd, selection_profiles.gd,
menu_test.gd (ruta del nombre elegido), character_selection_test.gd, catálogo POT,
este documento y referencia desde README. No se crean commits.
