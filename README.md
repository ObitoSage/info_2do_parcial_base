## CANDY SMASH

### Descripción General

CANDY SMASH es un juego de puzzle match-3 desarrollado en Godot Engine. El juego implementa mecánicas clásicas de intercambio de piezas para crear combinaciones de tres o más elementos del mismo color, con dos modos de juego distintos y un sistema completo de efectos especiales.

### Arquitectura del Proyecto

El proyecto utiliza una arquitectura modular con separación clara de responsabilidades:

- **Gestión Global**: `GameManager` como singleton autoloaded [2](#0-1) 
- **Escenas Principales**: Menú de selección de modo y escena principal de juego
- **Sistemas Core**: Grid, Piece, UI y Audio como componentes independientes

## Sistemas de Juego

### 1. Sistema de Grid (`scripts/grid.gd`)

El sistema central que maneja toda la lógica del tablero de juego:

#### Estados del Juego
- **MOVE**: Permite input del jugador para intercambiar piezas
- **WAIT**: Procesa matches, destruye piezas y rellena el tablero.

#### Tipos de Piezas Especiales
El juego incluye múltiples tipos de piezas especiales precargadas:

- **Piezas de Columna**: Destruyen toda una columna. 
- **Piezas de Fila**: Destruyen toda una fila. 
- **Piezas Bomba**: Destruyen en patrón de cruz.
- **Pieza Arcoíris**: Destruye todas las piezas del mismo color. 

#### Sistema de Hielo/Congelamiento
Mecánica especial que añade desafío al juego:

- **Congelamiento**: Las piezas pueden ser congeladas con efectos visuales de shader.
- **Descongelamiento**: Se activa automáticamente cuando las piezas congeladas forman parte de un match.
- **Spawn Aleatorio**: 25% de probabilidad de generar hielo después de cada movimiento.

### 2. Sistema de Piezas (`scripts/piece.gd`)

Cada pieza individual tiene propiedades y comportamientos específicos:

#### Propiedades Base
- `color`: Identificador del color de la pieza
- `piece_type`: Tipo de pieza ("normal", "column", "row", "rainbow", "bomb").
- `matched`: Estado de si la pieza está en un match.

#### Efectos Visuales de Piezas
- **Brillo Especial**: Las piezas especiales tienen un efecto de brillo pulsante.
- **Movimiento**: Animación elástica para el intercambio de piezas.
- **Flash de Match**: Efecto de destello cuando la pieza forma parte de un match.
- **Explosión**: Efecto especial para piezas bomba con escalado y rotación.

### 3. Sistema de Menú (`scripts/game_mode_menu.gd`)

Interfaz principal para selección de modo de juego:

#### Animaciones del Menú
- **Fondo Gradiente**: Animación continua de colores de fondo.
- **Título Pulsante**: Efecto de escala en el título.
- **Efectos de Hover**: Los botones se agrandan y brillan al pasar el mouse.

## Sistema de Audio

### Configuración de Audio (`scripts/grid.gd`)

El juego implementa un sistema de audio completo con múltiples reproductores:

#### Reproductores de Audio
- `audio_player`: Efectos de sonido principales
- `bg_music_player`: Música de fondo
- `special_effects_player`: Efectos especiales como explosiones.

#### Catálogo de Sonidos

**Sonidos de Selección de Frutas**:
- 12 variaciones de sonidos de selección (`FruitSelect_0.mp3` a `FruitSelect_11.mp3`).

**Sonidos de Matches**:
- `Match1.mp3` y `Match2.mp3`: Sonidos básicos de combinación.
- `Grood.mp3` y `Great.mp3`: Sonidos para matches especiales.
- `WowAwesome.mp3`: Sonido para matches excepcionales.

**Sonidos Especiales**:
- `IceBreak.mp3`: Sonido al romper hielo.
- `BlastTime.mp3`: Sonido para activación de piezas especiales.
- `GirlSetBall.mp3`: Sonido para explosiones de bombas. 
- `GameWin.mp3`: Sonido de victoria. 

**Música de Fondo**:
- `GameBGM.mp3`: Música principal del juego con loop automático.
- `MainBGM.mp3`: Música del menú principal.

#### Funciones de Reproducción
- `play_fruit_select_sound()`: Reproduce sonido aleatorio de selección.
- `play_ice_break_sound()`: Reproduce sonido de romper hielo.
- `play_girl_set_ball_sound()`: Reproduce sonido de explosión de bomba.

## Shaders y Efectos Visuales

### Sistema de Shaders

#### Shader de Hielo (`ice_freeze.gdshader`)
Aplicado a piezas congeladas con parámetros configurables:
- `freeze_progress`: Progreso de la animación de congelamiento
- `ice_color`: Color del efecto de hielo (azul por defecto)
- `ice_thickness`: Grosor del efecto visual.

#### Shader de Flash de Match (`match_flash.gdshader`)
Efecto de destello para piezas que forman matches:
- `flash_progress`: Controla la intensidad del destello.

### Sistema de Partículas (`scripts/match_particles.gd`)

Sistema de efectos de partículas para diferentes tipos de matches:

#### Configuración por Tipo de Match
- **Match de 3**: 20 partículas, escala 0.5-1.0, color amarillo
- **Match de 4**: 30 partículas, escala 0.8-1.5, color naranja  
- **Match de 5+**: 50 partículas, escala 1.0-2.0, color magenta.

### Efectos Especiales del Grid

#### Efectos de Línea y Explosión
- `create_line_effect()`: Efectos direccionales para matches de 4 piezas
- `create_explosion_effect()`: Efectos radiales para matches de 5+ piezas
- `create_cross_effect()`: Efectos en cruz para matches en T.

#### Flash de Pantalla
Efecto de destello de pantalla completa para matches especiales.

## Mecánicas de Juego

### Detección de Matches

El sistema detecta automáticamente:
- **Matches Horizontales**: 3+ piezas consecutivas en fila
- **Matches Verticales**: 3+ piezas consecutivas en columna
- **Matches en T**: Combinaciones que forman patrones de T.

### Creación de Piezas Especiales

- **4 piezas horizontales**: Crea pieza de fila
- **4 piezas verticales**: Crea pieza de columna  
- **5+ piezas**: Crea pieza arcoíris
- **Match en T**: Crea pieza bomba.

### Activación de Piezas Especiales

- **Columna**: Destruye toda la columna.
- **Fila**: Destruye toda la fila.
- **Bomba**: Destruye en patrón de cruz.
- **Arcoíris**: Destruye todas las piezas del mismo color.

### Modos de Juego

El juego ofrece dos modos configurables a través del `GameManager`:
- **Modo Movimientos**: Número limitado de movimientos
- **Modo Tiempo**: Tiempo limitado para conseguir la puntuación objetivo.

## Instalación y Configuración

1. **Requisitos**: Godot Engine 4.4 o superior
2. **Assets**: Todos los archivos de audio deben estar en `res://assets/audio/`
3. **Shaders**: Los shaders deben estar en `res
