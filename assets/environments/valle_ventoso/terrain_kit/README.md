# Valle Ventoso 2.0 — Terrain Kit (producción preliminar)

Piezas PNG RGBA separadas para Godot 4.7. Se incluyen terreno inferior, techo, islas, agua, vegetación, molinos, puentes, casas y parallax.

IMPORTANTE: Las piezas se extrajeron de una lámina de concepto. Son recortes individuales con transparencia estimada automáticamente; NO son aún tileables, ni forman un atlas con pivotes homologados. Revisar bordes/halos antes de producción final. No escalar las piezas de forma extrema ni pegarlas sobre un polígono enorme como textura plana.

## Integración segura
1. Copiar directorios a res://assets/environments/valle_ventoso/terrain_kit/.
2. Preservar Track01.tscn, colisiones y script de gameplay; separar nodos CollisionShape2D de los nodos Visuals.
3. En cada obstáculo, componer segmentos con Sprite2D para que césped / roca coincidan con la silueta del collider, sin dejar fondos rectangulares.
4. Para pendientes inclinadas usar piezas de rampa izquierda/derecha; para picos y salientes piezas específicas. Para extensiones largas, repetir tramos planos con variación y solapamiento pequeño, NO estirar todo el PNG.
5. Cascadas y enredaderas en nodos aparte (z-index separado), de preferencia anclados a un borde y no en medio de la pared.
6. Molinos y casas se colocan solamente sobre superficies sólidas creíbles y con tamaño coherente respecto de los corredores.
7. Parallax en capas propias detrás del gameplay; iconos de peligro y colisiones no tapados por decoración.
8. Validar S1–S6 en 1280×720 con cámara real, 4 corredores y reducción de efectos.

## Plan por sectores
- S1: upper flats + lower peaks + 1 árbol/molino al fondo, mantener limpio.
- S2: islas centrales y rocas superior/inferior; Flappy visible; arbustos mínimos.
- S3: irregular lower formations y roca colgante; cascada en un borde sólido, viento claramente visible.
- S4: conservando bifurcación, decorar límite superior/inferior y divisor como isla larga compuesta, no un bloque macizo.
- S5: bloques irregulares con vegetación contenida; evitar saturación de molino/puente; viento dominante.
- S6: menos decoración cercana, vistas de castillo/parallax y meta libre.

**Estado**: kit preliminar usable como fuente de sprites para una primera composición. Requiere QA artístico: bordes de extracción, proporción, repetición y coherencia en el motor.
