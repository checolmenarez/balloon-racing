# Home de Balloon Racing

La actualización vigente de composición, movimiento, Theme y audio se detalla
en [Home V2.1](home-v2.1.md), incluidos parámetros y recursos pendientes.

`scenes/StartMenu.tscn` sigue siendo la escena inicial. El selector solo se abre
mediante Selecci?n de personaje. No se modificaron gameplay ni escenas de carrera.

## Presentaci?n

Fondo a pantalla completa, logo superior y cuatro TextureRect decorativos:
Calaca arriba izquierda, Timo abajo izquierda, Greta arriba derecha y Pomposo
abajo derecha. Anchors y CenterContainer/VBoxContainer mantienen el layout.
La oscilaci?n tiene amplitud y velocidad configurables en el inspector.

Se conservaron los archivos originales descriptivos y se copiaron a las rutas
solicitadas en `assets/ui/home/{background,logo,characters,buttons,icons,decor}`.
`home_bg.png` corresponde a `paraiso_de_islas_flotantes_en_carrera.png`.
La l?mina decorativa queda disponible como `decor/decor_sheet.png`; el fondo ya
incluye banderines y flores, por lo que no se a?adieron adornos superpuestos.

Los Button existentes conservan texto editable y navegaci?n nativa. Usan
StyleBoxTexture con regiones de `buttons_sheet.png`, escaladas antes de aplicar
nueve segmentos para mantener los emblemas circulares. Los iconos son TextureRect
independientes con AtlasTexture de `icons_sheet.png`. Las regiones y su comentario
de mantenimiento est?n en `_skin` de `scripts/home.gd`: si cambia la distribuci?n
de las l?minas, actualizar esos rect?ngulos. No hay recortes pendientes para esta
versi?n de los assets. Logo y personajes recortan m?rgenes transparentes en memoria.

## Acciones y controles

- ?CORRER!: Main.tscn con el personaje actual; recibe el foco inicial.
- Selecci?n de personaje: CharacterSelect.tscn existente.
- Entrenamiento: Training.tscn existente, configurable mediante training_scene.
- C?mo jugar: instrucciones actuales y bot?n Volver.
- Opciones: m?sica y efectos persistentes, con buses independientes.
- Mouse, flechas, Tab/Shift+Tab y Enter; Escape regresa desde los paneles.
- Hover ilumina la textura; foco a?ade un contorno y mantiene la iluminaci?n.

## Validaci?n

Ejecutar los comandos del README con `tests/home_test.gd` y `tests/menu_test.gd`.
La prueba Home con renderer gr?fico verifica los cinco destinos, mouse, teclado,
foco, audio, regiones e iconos; guarda `.godot/home-720.png`, `home-800.png`,
`home-help.png` y `home-options.png`. Capturas revisadas en 1280?720 y 1280?800.
El test usa entradas de mouse y teclado sintetizadas por Godot.
En entornos restringidos puede asignarse APPDATA a `.godot/test-user` para
mantener ajustes de prueba dentro del repositorio y aislar el audio del usuario.
