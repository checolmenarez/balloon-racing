# Valle Ventoso 2.0 — coordenadas reales

Generado desde `scenes/Track01.tscn`. Posiciones en px del mundo; Y crece hacia abajo. Se listan nodos nuevos/modificados y los tres Flappy. Las rocas están ancladas en Y=0: sus superficies se indican por separado. Las cajas restantes conservan sus posiciones.

| Nodo | Estado | X, Y | Geometría / parámetros |
|---|---|---|---|
| `WindZones/RecoveryCurrent` | modificado | 7500, 170 | tamaño (400, 60); ×1.2 |
| `WindZones/CorridorCurrent` | modificado | 14600, 175 | tamaño (400, 60); ×1.2 |
| `FlyingObstacles/FlappyS2` | conservado | 4450, 340 | amplitud ±45 px; período 3 s; fase 0° |
| `FlyingObstacles/FlappyS5` | modificado | 13600, 340 | amplitud ±45 px; período 3 s; fase 120.0° |
| `Obstacles/AlternatingLower` | modificado | 4050, 0 | suelo; ancho 240.0; superficie inferior Y=550.0 |
| `Obstacles/DeepHangingRock` | modificado | 6350, 0 | techo; ancho 260.0; superficie superior Y=220.0 |
| `Obstacles/RisingMountain` | modificado | 6650, 0 | suelo; ancho 220.0; superficie inferior Y=500.0 |
| `Obstacles/FirstCorridor` | modificado | 8000, 0 | techo; ancho 360.0; superficie superior Y=220.0 |
| `Obstacles/UpperRouteRockB` | modificado | 12250, 0 | techo; ancho 260.0; superficie superior Y=90.0 |
| `Obstacles/PrecisionA` | modificado | 15100, 0 | techo; ancho 360.0; superficie superior Y=220.0 |
| `Obstacles/PrecisionB` | modificado | 15100, 0 | isla; ancho 1800.0; superficie superior Y=250.0; superficie inferior Y=450.0; polígono irregular: `outline` en escena |
| `Obstacles/PrecisionC` | modificado | 16400, 0 | suelo; ancho 300.0; superficie inferior Y=440.0 |
| `Obstacles/FinalUpper` | modificado | 16930, 0 | techo; ancho 260.0; superficie superior Y=220.0 |
| `Obstacles/FinalLower` | modificado | 17400, 0 | suelo; ancho 240.0; superficie inferior Y=470.0 |
| `ItemBoxes/Box2` | modificado | 2550, 280 | sensor 48 × 48; loot sin cambios |
| `ItemBoxes/Box3` | modificado | 2550, 440 | sensor 48 × 48; loot sin cambios |
| `ItemBoxes/Box4` | modificado | 3650, 180 | sensor 48 × 48; loot sin cambios |
| `ItemBoxes/Box5` | modificado | 6100, 320 | sensor 48 × 48; loot sin cambios |
| `ItemBoxes/Box6` | modificado | 7500, 170 | sensor 48 × 48; loot sin cambios |
| `ItemBoxes/Box7` | modificado | 9250, 280 | sensor 48 × 48; loot sin cambios |
| `ItemBoxes/Box8` | modificado | 9250, 440 | sensor 48 × 48; loot sin cambios |
| `ItemBoxes/Box13` | modificado | 13300, 300 | sensor 48 × 48; loot sin cambios |
| `ItemBoxes/Box14` | modificado | 14600, 175 | sensor 48 × 48; loot sin cambios |
| `ItemBoxes/Box15` | modificado | 15100, 550 | sensor 48 × 48; loot sin cambios |
| `ItemBoxes/Box16` | modificado | 16650, 310 | sensor 48 × 48; loot sin cambios |
| `ItemBoxes/Box17` | modificado | 16650, 465 | sensor 48 × 48; loot sin cambios |
| `ItemBoxes/Box18` | modificado | 16800, 340 | sensor 48 × 48; loot sin cambios |
| `ItemBoxes/Box19` | modificado | 17200, 180 | sensor 48 × 48; loot sin cambios |
| `ItemBoxes/Box20` | modificado | 17200, 460 | sensor 48 × 48; loot sin cambios |
| `ItemBoxes/Box22` | modificado | 2550, 150 | sensor 48 × 48; loot sin cambios |
| `ItemBoxes/Box23` | modificado | 3650, 470 | sensor 48 × 48; loot sin cambios |
| `ItemBoxes/Box24` | modificado | 6100, 490 | sensor 48 × 48; loot sin cambios |
| `ItemBoxes/Box25` | modificado | 8000, 550 | sensor 48 × 48; loot sin cambios |
| `ItemBoxes/Box26` | modificado | 9250, 160 | sensor 48 × 48; loot sin cambios |
| `ItemBoxes/Box29` | modificado | 13300, 490 | sensor 48 × 48; loot sin cambios |
| `ItemBoxes/Box30` | modificado | 16650, 165 | sensor 48 × 48; loot sin cambios |
| `ItemBoxes/Box31` | modificado | 16800, 520 | sensor 48 × 48; loot sin cambios |
| `Obstacles/IntroUpper` | nuevo | 2300, 0 | techo; ancho 220.0; superficie superior Y=180.0 |
| `Obstacles/ChoiceIsland` | nuevo | 3800, 0 | isla; ancho 650.0; superficie superior Y=280.0; superficie inferior Y=365.0 |
| `Obstacles/TechnicalIslandS3` | nuevo | 8000, 0 | isla; ancho 1800.0; superficie superior Y=250.0; superficie inferior Y=450.0; polígono irregular: `outline` en escena |
| `WindZones/TechnicalDipS3` | nuevo | 8000, 315 | tamaño (200, 70); ×1.2 |
| `WindZones/TechnicalExitS3` | nuevo | 8500, 185 | tamaño (400, 60); ×1.2 |
| `Obstacles/EntryFunnel` | nuevo | 9750, 0 | paso; ancho 500.0; superficie superior Y=220.0; superficie inferior Y=440.0 |
| `WindZones/TechnicalDipS5` | nuevo | 15100, 320 | tamaño (200, 70); ×1.2 |
| `WindZones/TechnicalExitS5` | nuevo | 15600, 165 | tamaño (400, 60); ×1.2 |
| `Obstacles/FinalLowerB` | nuevo | 17700, 0 | suelo; ancho 200.0; superficie inferior Y=490.0 |
| `FlyingObstacles/FlappyS6` | nuevo | 17950, 400 | amplitud ±30.0 px; período 3.6 s; fase 210.0° |

Inicio X=240; sectores X=240/2700/6000/9700/13400/16800; Fork X=9700; Merge X=13200; meta X=18400. Sin cambios.

Candidato futuro para escudo: `Box15` (15100, 550), fuera de la trayectoria rápida. Conserva el loot actual; no se añadió ningún poder.
