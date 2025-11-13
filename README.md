# Dungeon — LÖVE (Lua) Project

> **Short:** This small top-down game started as a school project at Epitech Rennes and was later revived and improved for personal development.  
> It’s a **work in progress**, featuring a smooth camera system, Tiled map integration, tile collisions, mouse aiming and shooting.

---

## 🧩 Project Status
**Currently in development.**  
It’s now being modernized with a **new map designed in Tiled**, including camera support, map collision logic, and smoother player control.  
---

## ⚙️ Tech Stack

- **Language:** [Lua](https://www.lua.org/)
- **Engine:** [LÖVE (Love2D)](https://love2d.org)
- **Map Editor:** [Tiled](https://www.mapeditor.org)
- **Modules:**
    - `main.lua` — core game loop, camera handling, scene switching
    - `camera.lua` — camera follow, zoom, world clamping
    - `tiled_loader.lua` — robust loader for Tiled Lua exports (supports atlas, collection, chunks, flips)
    - `maps/dungeon.lua` — wrapper around `assets/maps/dungeon.lua` (Tiled export)
    - `player.lua`, `arrow.lua`, `inventory.lua`, `tiles.lua`, etc.
    - `screens/allscreens.lua`, `menu.lua`, `firstmap.lua`, `secondmap.lua` — scenes and transitions

---

## 🕹️ Features

- Camera system with smooth follow and world clamping
- Pixel-perfect zoom and rendering
- Fully functional **Tiled map** loader (embedded tilesets, chunks, flip/rotation support)
- Tile and layer collision system (`solid = true`)
- Mouse-based aiming and shooting
- Map culling for performance (draws only visible tiles)
- Optional debug overlay (F1) to visualize solid tiles

---

## 🧱 Tiled Map Preparation

1. Use **Orthogonal** maps with a **32×32 tile size** (or adjust in the loader).
2. When exporting:
  - In Tiled: `Map → Embed Tilesets`
  - `File → Export As → Lua` → save to `assets/maps/dungeon.lua`
3. To mark collisions:
  - Either set `solid = true` on individual tiles in your tileset, **or**
  - Create a layer named `bordure` (or `border`/`collision`) and set its property `solid = true`
4. Make sure your tileset images are inside the project (`assets/tilesets/` or `assets/images/`)  
   → The loader automatically resolves paths if relative to the project.

---

## 🚀 Running the Game

### Requirements
- [LÖVE 11.x](https://love2d.org/) installed (any recent version)

### Run from terminal
### Option 1 — Run via Terminal
```bash
# Run from the project root
love .
```
### Option 2 — use the provided run.bat script
⚠️ Note: If LÖVE is installed elsewhere on your computer,
edit run.bat and replace the path to your local love.exe installation.