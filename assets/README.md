# Balloon Racing — UI de Selección y Podio

Kit de recursos **por capas** para Godot 4.7. No son escenas Godot terminadas.

## Instalación
Copiar `assets/ui/menus/` a `res://assets/ui/menus/` dentro del proyecto. No sustituir ni borrar los sistemas de selección y resultados existentes.

## Incluye
- `portraits/`: 4 personajes x 6 variantes ya existentes (normal, happy, angry, surprised, idle, victory). Mantienen el estilo de las hojas originales; algunos recortes pueden tener imperfecciones propias de la generación previa.
- `components/character_card*.png`: marcos de selección vacíos sin texto.
- `components/podium_panel.png`, `podium_gold|silver|bronze|fourth.png`: panel y cuatro bases independientes, con texto y ranking a renderizar por Godot.
- `components/result_row.png`: estilo opcional para tabla de estadísticas.
- `background/`: fondo y botones del paquete Home reutilizados, sin textos, así como logo.
- `PREVIEW_seleccion.jpg` y `PREVIEW_podio.jpg`: maquetas orientativas de layout, NO usarlas como interfaz.
- `PROMPT_CODEX.txt`: integración conservadora.

## Diseño aprobado
Selección: cuatro tarjetas con los pilotos existentes, selección destacada y botón Comenzar carrera. Desde Home -> Selección de personaje; no abrir directamente al iniciar.
Podio: lugares 1,2,3,4 visibles; 1 centro y más alto, 2 izquierda, 3 derecha, 4 extremo derecho/ligeramente más bajo. Rostros sugeridos: 1 feliz, 2 normal (orgullo/herido), 3 enojado, 4 sorprendido o triste. El personaje seleccionado puede ocupar cualquier rango. En Godot ordenar dinámicamente por clasificación real.

## Límites
Las bases son imágenes sin números/textos. Implementarlos con Label/Button; no hardcodear tiempos ni ganadores. El kit no incluye fuentes licenciadas. La composición del fondo es JPG y las tarjetas/portraits son PNG con alfa. Las imágenes de resultados no tienen animations cuadro a cuadro.
