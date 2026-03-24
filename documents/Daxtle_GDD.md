# Daxtle — Game Design Document
**Version 6.0 — Current Implementation**

---

## Table of Contents

1. [Overview](#1-overview)
2. [Platform & Technical Stack](#2-platform--technical-stack)
3. [Player Input](#3-player-input)
4. [Game Elements](#4-game-elements)
   - 4.1 [Element A — The Board](#41-element-a--the-board)
   - 4.2 [Element B — The Blocks](#42-element-b--the-blocks)
   - 4.3 [Element C — Fixed Blocks](#43-element-c--fixed-blocks)
   - 4.4 [Element D — Destroy Blocks](#44-element-d--destroy-blocks)
   - 4.5 [Element T — Teleport Pairs](#45-element-t--teleport-pairs)
5. [Game Rules & Logic](#5-game-rules--logic)
   - 5.1 [Movement](#51-movement)
   - 5.2 [Pushing](#52-pushing)
   - 5.3 [Destroy Collisions](#53-destroy-collisions)
   - 5.4 [Invalid Moves](#54-invalid-moves)
   - 5.5 [Stuck Detection](#55-stuck-detection)
   - 5.6 [Win Condition](#56-win-condition)
   - 5.7 [Reset](#57-reset)
6. [Game Modes](#6-game-modes)
   - 6.1 [Campaign Mode](#61-campaign-mode)
   - 6.2 [Challenge Mode](#62-challenge-mode)
7. [Level Structure](#7-level-structure)
   - 7.1 [Level Progression](#71-level-progression)
   - 7.2 [Level Design Constraints](#72-level-design-constraints)
   - 7.3 [JSON Format](#73-json-format)
8. [Level Editor](#8-level-editor)
   - 8.1 [Tools](#81-tools)
   - 8.2 [Keyboard Shortcuts](#82-keyboard-shortcuts)
   - 8.3 [Actions](#83-actions)
   - 8.4 [Play Testing](#84-play-testing)
9. [Screens & Navigation](#9-screens--navigation)
   - 9.1 [Main Menu](#91-main-menu)
   - 9.2 [Level Select](#92-level-select)
   - 9.3 [Game Scene](#93-game-scene)
   - 9.4 [Settings](#94-settings)
   - 9.5 [About](#95-about)
   - 9.6 [SceneHeader Component](#96-sceneheader-component)
10. [Visual Design](#10-visual-design)
    - 10.1 [Aesthetic](#101-aesthetic)
    - 10.2 [Typography](#102-typography)
    - 10.3 [Color & Theme System](#103-color--theme-system)
    - 10.4 [Animations](#104-animations)
    - 10.5 [Layout & Safe Area](#105-layout--safe-area)
    - 10.6 [App Icon](#106-app-icon)
11. [Audio Design](#11-audio-design)
12. [Haptic Feedback](#12-haptic-feedback)
13. [Save System](#13-save-system)
14. [Build & Deployment](#14-build--deployment)
15. [Current Status & Roadmap](#15-current-status--roadmap)

---

## 1. Overview

**Daxtle** is a minimalist mobile puzzle game built around a simple but deeply satisfying mechanic: slide colored blocks across an irregular grid to land each one on its matching target.

Every block has a fixed, predefined direction — it can only ever move one way. A single swipe moves all blocks sharing that direction simultaneously, and a moving block will push any block it collides with — meaning every move can have cascading consequences across the entire board.

The game features six element types: board squares (A), directional blocks (B), cargo blocks (B with no direction), fixed obstacles (C), destroy blocks (D), and teleport portals (T). These are introduced progressively across hand-crafted levels.

The game offers two modes: a calm, deliberate **Campaign** with hand-crafted levels (no timers, no lives, no fail states), and a timed **Challenge** mode that draws from difficulty-rated puzzle pools with an increasing streak mechanic.

---

## 2. Platform & Technical Stack

| Property | Value |
|---|---|
| Engine | Godot 4.6 (GDScript, GL Compatibility renderer) |
| Target platforms | iOS (iPhone & iPad) and Android |
| Orientation | Portrait only |
| Viewport | 1080×1920 |
| Game modes | Campaign (level-based) and Challenge (timed endless) |
| Font | Fredoka Bold (variable weight) |
| Business model | Defined in a separate document |

### GDExtension

A native iOS GDExtension (`DaxtleHaptics`) provides UIKit haptic feedback. Built with godot-cpp (godot-4.5-stable), compiled as a static library for arm64. A macOS no-op stub is included to suppress editor warnings. The extension registers as an Engine singleton accessible from GDScript.

---

## 3. Player Input

The player interacts through three input methods:

### Touch (Primary)

| Gesture | Action |
|---|---|
| Swipe left | Trigger left movement |
| Swipe right | Trigger right movement |
| Swipe up | Trigger upward movement |
| Swipe down | Trigger downward movement |
| Double tap | Reset level (after first move) |

A minimum drag distance of 40px filters accidental taps. Input is fully disabled while any animation is in progress. The message panel area passes through touch input so swipes over tutorial text still work.

### Keyboard

Arrow keys (LEFT, RIGHT, UP, DOWN) trigger the corresponding swipe direction. R key resets the level during play testing.

### Gamepad

Left stick axis input with 0.5 deadzone. The `_axis_held` flag ensures one swipe per stick push — the stick must return to center before the next input registers.

---

## 4. Game Elements

### 4.1 Element A — The Board

Element A is the static playing field. It is composed of adjoining squares arranged in a grid pattern, but not necessarily rectangular. The board can take any shape: L-shapes, crosses, staircases, hourglasses, T-shapes, or any other configuration. Missing squares create holes that blocks cannot enter.

**Rendering.** The board is always centered on screen. Each square's size (`Value_A`) is calculated dynamically so the board fits with a 10% margin on all sides. Squares are rendered as flat rounded rectangles in the active theme's surface color, separated by a small gap (6.4% of `Value_A`), with corner radius at 8% of `Value_A`. Target squares show a semi-transparent tint of the corresponding block's color. Target borders are drawn on a separate overlay node with z_index = 1, ensuring they render above B blocks.

**Data format.** Board squares are defined as coordinate pairs, with an optional third element for target assignment:

```json
"A": [[0,0], [1,0], [2,0,1], [0,1], [1,1], [2,1]]
```

The third element (e.g. `1` in `[2,0,1]`) marks that cell as a target for block ID 1. Only listed positions exist on the board.

---

### 4.2 Element B — The Blocks

Element B refers to the movable blocks that the player manipulates. All B blocks are 1×1 (single square). There are two variants:

**Directional blocks** have a fixed movement direction (`"left"`, `"right"`, `"up"`, or `"down"`) that never changes during gameplay. A directional arrow — rendered as a filled rounded triangle with arc-based corner rounding (6 points per arc), darkened 30% from the block's color — indicates the direction.

**Cargo blocks** have no direction (`"none"`). They cannot be moved by any swipe on their own. They can only be repositioned when another block pushes into them. Cargo blocks display a small centered dot instead of an arrow.

**Color.** Each block is assigned a color based on its numeric ID from the active theme palette (up to 4 colors). Multiple blocks can share the same ID/color.

**Target.** Blocks with the same ID share the same target cells. The win condition checks that each block occupies any one of its ID's target positions.

**Data format:**

```json
{
  "id": 1, "dir": "right",
  "origin": [0, 1]
}
```

| Field | Description |
|---|---|
| `id` | Numeric identifier (1–4) — determines color from theme |
| `dir` | `"left"`, `"right"`, `"up"`, `"down"`, or `"none"` (cargo) |
| `origin` | Starting grid position `[x, y]` |

---

### 4.3 Element C — Fixed Blocks

Element C is a static, immovable block occupying one or more board squares. It acts as a permanent wall that blocks B block movement and push chains.

**Behavior:**
- Cannot be moved by any swipe or push
- If a push chain reaches a C block, the chain is blocked
- Always visible from the start of the level
- Does not count toward the win condition
- Scales in during the board wave animation (part of the environment)

**Visual appearance.** Rendered in a neutral dark tone defined per-theme (`fixed` color), significantly darker than the surface color. No arrow or symbol.

**Data format:**

```json
"C": [
  {
    "id": 1,
    "squares": [{"pos_x": 0, "pos_y": 0}],
    "origin": [2, 2]
  }
]
```

---

### 4.4 Element D — Destroy Blocks

Element D is a consumable block that destroys both itself and any B block that lands on it. It acts as a trap or a strategic sacrifice point.

**Behavior:**
- Does NOT block movement — B blocks pass through freely and land on D blocks
- When a B block lands on a D block after a move, both are destroyed and removed from play
- The destroyed B block no longer needs to reach a target (removed from win condition)
- D blocks do not count toward the win condition
- Scales in during the board wave animation (part of the environment)
- On reset, all destroyed D and B blocks are restored (full level reload)

**Visual appearance.** Rendered as a rounded square in the theme's `fixed` color lightened 15%, with an X mark overlay (two diagonal lines, 60% opacity, line width 3.5% of cell size). Visually distinct from C blocks by the lighter color and X mark.

**Destroy animation sequence:**
1. D block is removed instantly from the scene
2. B block fades out then fades back in (0.1s each direction)
3. B block enlarges to 115% scale (0.08s, quad ease-out)
4. B block shrinks to 0% scale (0.18s, quad ease-in)
5. B block is removed from play

**Data format:**

```json
"D": [
  {"origin": [2, 3]}
]
```

| Field | Description |
|---|---|
| `origin` | Grid position `[x, y]` of the destroy block |

---

### 4.5 Element T — Teleport Pairs

Teleport pairs are two linked portal cells on the board. When a block enters one portal, it exits at the partner cell.

**Behavior:**
- Bidirectional by default; optional `one_way` flag restricts to A→B only
- After teleporting, the block attempts one continuation step in its movement direction. If that cell is valid, empty, not fixed, and not another portal, the block lands there. Otherwise it stays at the exit cell
- Pushed blocks can teleport (push chain enters portal → exits at partner)
- A block already sitting on a portal does NOT teleport — only entering triggers it

**Visual appearance.** Each portal is drawn as a colored ring with a center dot, using a per-pair color from the theme's teleport palette (magenta, electric blue, gold, teal). Multiple pairs on the same board use different colors.

**Data format:**

```json
"T": [
  {"id": 1, "pos": [3, 1, 0, 3], "one_way": true}
]
```

| Field | Description |
|---|---|
| `id` | Pair identifier — used for color assignment |
| `pos` | `[ax, ay, bx, by]` — grid positions of portal A and B |
| `one_way` | Optional boolean. If true, only A→B. Default: false (bidirectional) |

---

## 5. Game Rules & Logic

### 5.1 Movement

When the player swipes, every B block whose direction matches the swipe attempts to move one square in that direction. All other blocks remain stationary. Cargo blocks (`dir: "none"`) never move on their own.

Movement duration is synced to the slide sound effect duration. All moving blocks animate simultaneously with cubic ease-out.

**Teleport movement.** When a block's destination is a portal cell, a sequential animation plays: slide to portal → shrink to zero (0.14s) → jump to exit → pop back to full size (0.18s, back ease) → slide to continuation cell (if applicable).

---

### 5.2 Pushing

When a moving block would enter a square occupied by another B block, it pushes that block one square in the same swipe direction. Push chains propagate recursively.

**Key rules:**
- Pushed blocks move in the swipe direction, NOT in the pushed block's own direction
- Cargo blocks can be pushed in any direction
- If a push chain reaches a C block or board edge, the entire chain is blocked
- Push chains can pass through teleport portals — blocks at the exit cell join the active push set

**Pushing as a design tool.** Mandatory pushes are a core mechanic: some blocks' targets are in rows/columns they can never reach alone, requiring another block to push them into position.

---

### 5.3 Destroy Collisions

After every move completes (including teleport animations), the game checks whether any B block occupies the same cell as a D block. If so:

1. The D block is instantly removed from the scene
2. The B block plays a flash + enlarge + shrink animation (see 4.4)
3. The B block is removed from the `_blocks` array
4. The D block's cell is removed from the `_destroy_set`
5. Win/stuck checks proceed with the reduced block set

Multiple B+D collisions in a single move are handled simultaneously.

---

### 5.4 Invalid Moves

A move is invalid if any block in the chain would land outside the board, on a hole, or on a C block. When invalid:

1. An invalid move sound plays
2. All involved blocks play a shake animation (nudge toward wall with cubic ease, spring back)
3. Blocks return to previous positions
4. No penalty or fail state

---

### 5.5 Stuck Detection

After every valid move, the game checks whether any block can move in any of the four directions. If no moves are possible and the level is not won:

1. Haptic fail feedback triggers
2. The board shakes with a horizontal oscillation
3. After a 0.25s pause, all blocks animate back to starting positions (auto-reset)

---

### 5.6 Win Condition

The level is won when all remaining B blocks (those not destroyed by D blocks) simultaneously occupy one of their ID's target positions. When won:

1. Input is disabled, win sound plays, haptic success feedback triggers
2. Targets, A cells under blocks, teleports, and remaining D blocks are hidden
3. All B block arrows scale down to zero (0.25s, back ease-in)
4. B blocks flash twice (fade out/in pattern over ~0.88s)
5. Exit chain: reverse diagonal wave (bottom-right → top-left) scales down all elements
6. The next level loads, or `all_levels_completed` triggers the congratulations popup

---

### 5.7 Reset

A reset icon (circular arrow) appears in the top-right corner after the player's first move (animated scale-up with back ease). Tapping it:

1. Plays reset sound
2. If any D blocks were consumed, performs a full level reload (restores destroyed blocks)
3. Otherwise smoothly slides all blocks back to their starting positions (cubic ease-in-out, 2.5× normal duration)
4. Hides the reset icon

Double-tap anywhere also triggers reset. The game auto-resets when stuck (see 5.5). Pressing R resets during play testing.

---

## 6. Game Modes

### 6.1 Campaign Mode

Sequential hand-crafted levels (1 to N). Progress is saved — the player unlocks the next level upon completion. Tutorial messages appear on early levels. The experience is calm and deliberate: no timers, no lives, no move counters, no fail states.

### 6.2 Challenge Mode

A timed, endless puzzle stream that tests speed and consistency.

**Timer mechanics:**
- Starting time: 30 seconds
- Time removed per solve: 1.5 seconds (decays with streak)
- Minimum time: 10 seconds
- Timer UI: rounded progress bar shrinking from top, flashes red below 5 seconds

**Difficulty pool system:**
- Three pools: easy, medium, hard (loaded from `levels/challenge/` subdirectories)
- Pool selection based on streak:
  - Low streak → easy pool (fallback: medium)
  - Mid streak → medium pool (fallback: hard)
  - High streak → hard pool (fallback: medium)
- Easy/medium puzzles are one-time use per run; hard pool reshuffles when exhausted

**Streak tracking:**
- Current streak displayed during play
- Best streak saved to disk
- Game over when timer expires OR board becomes unwinnable (BFS solvability check)

---

## 7. Level Structure

### 7.1 Level Progression

The game currently contains **21 hand-crafted campaign levels** plus challenge pools (15 easy, 28 medium, 17 hard):

| Range | Key Mechanics Introduced |
|---|---|
| 1 | Basic swipe — single block, single direction |
| 2 | Multiple blocks with different directions |
| 3 | Synchronized movement — same-direction blocks move together |
| 4 | All four directions on one board |
| 5 | Order matters — wrong sequence leads to dead-ends |
| 6 | Target matching — every block needs a matching target |
| 7 | Push collisions — blocks push other blocks on contact |
| 8 | Cargo blocks (`dir: none`) — need pushing from other blocks |
| 9 | Two colors — each color has its own destinations |
| 10 | Teleport portals — blocks warp between paired cells |
| 11–21 | Combinations of all mechanics at increasing complexity |

---

### 7.2 Level Design Constraints

- Every level must be **provably solvable**
- Blocks should NOT start on their own color's target (creates visual confusion)
- Blocks CAN sit on wrong-color targets (creates misdirection)
- Difficulty should feel chess-like — require thinking ahead, non-linear solutions
- No two B blocks may share the same starting position
- Every element must earn its place — no decorative filler

---

### 7.3 JSON Format

Each level is stored as `level_NNN.json` in the `levels/` directory. Challenge levels use `challenge_NNN.json` in subdirectories. Top-level fields:

| Field | Type | Description |
|---|---|---|
| `A` | Array | Board squares as `[x, y]` or `[x, y, target_id]` |
| `B` | Array | Block definitions with `id`, `dir`, `origin` |
| `C` | Array | *(Optional)* Fixed block definitions with `id`, `origin`, `squares` |
| `D` | Array | *(Optional)* Destroy block definitions with `origin` |
| `T` | Array | *(Optional)* Teleport pair definitions with `id`, `pos`, `one_way` |
| `message` | String | *(Optional)* Tutorial text shown below the board |

**Example — Level 1 (tutorial):**

```json
{
  "A": [[1,0], [2,0], [3,0,1], [0,0], [4,0]],
  "B": [{"dir": "right", "id": 1, "origin": [1, 0]}],
  "message": "Swipe anywhere on the screen to move the block to its destination."
}
```

**Example — Level with destroy blocks:**

```json
{
  "A": [[0,0], [1,0], [2,0,1], [0,1], [1,1], [2,1]],
  "B": [{"dir": "right", "id": 1, "origin": [0, 0]}],
  "D": [{"origin": [1, 0]}]
}
```

**Example — Level with teleports:**

```json
{
  "A": [[0,1], [2,1], [0,2], [2,2], [4,4,1], [4,5,1]],
  "B": [{"dir": "none", "id": 1, "origin": [0, 3]}, {"dir": "down", "id": 1, "origin": [0, 1]}],
  "T": [{"id": 1, "one_way": false, "pos": [0, 5, 2, 0]}, {"id": 2, "one_way": false, "pos": [2, 5, 4, 0]}]
}
```

---

## 8. Level Editor

The in-game level editor is activated by setting `Globals.LEVEL_EDITOR_MODE = true`. It provides a full suite of tools for creating, editing, validating, and play-testing levels.

### 8.1 Tools

The editor panel (bottom of screen) contains tool buttons organized in rows:

**Row 1 — Block tools:**

| Button | Tool | Description |
|---|---|---|
| B1 | Block 1 | Place block with color 1 |
| B2 | Block 2 | Place block with color 2 |
| B3 | Block 3 | Place block with color 3 |
| B4 | Block 4 | Place block with color 4 |
| D | Destroy | Place a destroy block |

**Row 2 — Target & Teleport tools:**

| Button | Tool | Description |
|---|---|---|
| T1–T4 | Target 1–4 | Mark cell as target for block ID 1–4 |
| TP1–TP3 | Teleport 1–3 | Place teleport pair (click two cells) |

**Placement:** Click a cell with a tool selected to place. Click an occupied cell to remove the element. Click with no tool selected to toggle board squares on/off.

**Block direction:** Hold W/A/S/D while clicking to set the block's direction (up/left/down/right). Without a key held, the block defaults to `dir: "none"` (cargo).

**Message display:** The editor shows the level's tutorial message (if any) in quotes above the tool buttons.

### 8.2 Keyboard Shortcuts

| Shortcut | Action |
|---|---|
| Ctrl+W/A/S/D | Expand grid (add row/column in that direction) |
| Shift+W/A/S/D | Shrink grid (remove row/column from that direction) |
| X | Deselect active tool |
| , (comma) | Load previous level |
| . (period) | Load next level |

### 8.3 Actions

| Button | Action |
|---|---|
| Validate | Checks all blocks have targets, runs BFS solvability check (max 20 moves) |
| Save | Repositions grid to (0,0), exports JSON to `res://levels/level_NNN.json` |
| Play | Launches quick play-test mode with current editor state |

### 8.4 Play Testing

The `LevelEditorPlay` scene loads the level from editor state and allows full gameplay testing:
- All game mechanics work (movement, pushing, teleports, destroy blocks)
- ESC returns to editor
- R key reloads the level
- Double-tap reloads the level
- Shows "Solved!" overlay on win, then auto-reloads

---

## 9. Screens & Navigation

All screens are managed by `Main.gd` with fade transitions (0.18s quad ease). Screens are shown/hidden with `process_mode` toggling to prevent background input.

### 9.1 Main Menu

The title "DAXTLE" is displayed as 6 individual colored blocks with letters, animated with a chain scale effect followed by a snake-like staggered rise to the top.

**Buttons** are square icon buttons arranged horizontally, appearing with a chain scale animation after the title settles:

| Button | Position | Style | Icon |
|---|---|---|---|
| Play | Center | Green (B1) background, background-colored triangle | Rounded right-pointing triangle |
| Level Select | Left of Play | Grey (surface) background, green icon | 3×3 dot grid (SVG) |
| Settings | Right of Play | Grey background, green icon | Gear (SVG, Material Design) |
| About | Further right | Grey background, green icon | Info "i" in circle (SVG) |

Play is larger; the three secondary buttons are 72% of Play's size, positioned below at 78% screen height.

### 9.2 Level Select

- 4×5 grid (20 levels per page) with horizontal swipe pagination
- Page indicator dots at bottom
- Locked levels appear dimmed until the previous level is completed
- Completed levels shown with filled background
- SceneHeader with "Level select" title and back button
- 10% horizontal margins matching board alignment

### 9.3 Game Scene

- Board centered on screen with 10% margin
- SceneHeader with level number as title (font size 62)
- ResetIcon (top-right, aligned with SceneHeader's `right_x`) — appears after first move
- Tutorial message panel below board (when level has a `message` field)
- Challenge mode: timer progress bar at top, streak counter at bottom

### 9.4 Settings

Three toggle rows with pulse animation feedback:

| Toggle | Visibility | Default |
|---|---|---|
| Music | All platforms | On |
| Sound Effects | All platforms | On |
| Haptics | iOS & Android only | On |

Each row has a label on the left and a toggle indicator on the right (filled circle = on, outlined circle = off). SceneHeader with "Settings" title. 10% horizontal margins.

### 9.5 About

Static text screen with game description and developer credit:

> DAXTLE is a minimalist puzzle game where you slide colored blocks onto their matching targets.
>
> Swipe to move all blocks at once. Think ahead — every move counts.
>
> Designed & developed by Razvan Andrei

Tapping anywhere on the screen returns to the main menu (with click sound and haptic). SceneHeader with "About" title also provides back navigation.

### 9.6 SceneHeader Component

A reusable `Node2D` component (`SceneHeader.gd` + `SceneHeader.tscn`) used by all sub-screens:

- Contains a `MenuIcon` (hamburger menu SVG) positioned at the left 10% margin
- Draws a centered title with configurable `title_text` and `title_font_size` (default 62)
- Exposes `right_x` and `bar_cy` for positioning external icons (e.g. ResetIcon)
- Emits `back_pressed` signal when the menu icon is tapped
- Safe-area aware (respects notch/status bar insets)

---

## 10. Visual Design

### 10.1 Aesthetic

Minimalist throughout. Clean, calm, and deliberate. Every visual element serves a functional purpose. The design language is rounded rectangles and rounded triangles — consistent across board squares, blocks, arrows, buttons, and icons. All UI is custom-drawn using Godot's `_draw()` API and `StyleBoxFlat`, not scene-tree UI nodes.

---

### 10.2 Typography

The project uses **Fredoka Bold** as the universal font for all text. A variable font file (`Fredoka-Variable.ttf`) is used with a TRES resource for weight control. The font color across all UI matches the theme's `text` color.

---

### 10.3 Color & Theme System

Three themes are defined. The active theme (`WARM_SAND`) is set as a constant in `GameTheme.gd`.

| Theme | Background | Surface | Text | B1 | B2 | B3 | B4 |
|---|---|---|---|---|---|---|---|
| WARM_SAND | #F5F0E3 | #D9D1C2 | #2B7366 | Teal | Coral | Blue | Amber |
| COOL_SLATE | #E8EDEF | #C4CDD2 | #38404C | Blue | Coral | Teal | Amber |
| DARK_CHARCOAL | #212328 | #2E3035 | #E0E0E5 | Bright blue | Bright coral | Bright teal | Bright amber |

Each theme also defines:
- `fixed` — C block color (neutral dark tone)
- `teleport` — array of 4 portal pair colors:
  - **Magenta** `#D94F8E` — Color(0.85, 0.31, 0.56)
  - **Electric Blue** `#4FA3D9` — Color(0.31, 0.64, 0.85)
  - **Gold** `#D9A84F` — Color(0.85, 0.66, 0.31)
  - **Teal** `#4FD9A8` — Color(0.31, 0.85, 0.66)

**Layout constants:** `GAP_FRACTION = 0.064`, `CORNER_FRACTION = 0.08`

---

### 10.4 Animations

All animations use Tween-based interpolation. Input is disabled during all animations.

| Animation | Description |
|---|---|
| **Title intro** | Chain scale effect on "DAXTLE" letters, then snake-like staggered rise (0.06s per letter) |
| **Button intro** | Chain scale pop-in (play first, then secondary L→R, 0.12s stagger) |
| **Level intro** | Diagonal wave (top-left → bottom-right): board squares, C blocks, D blocks, teleports scale up with back-ease. Then B blocks scale up with stagger, arrows fade in |
| **Normal move** | Cubic ease-out slide, synced to slide SFX duration |
| **Teleport move** | Slide → shrink (0.14s) → jump → pop (0.18s, back ease) → continuation slide |
| **Destroy collision** | D block removed instantly → B block fade out/in (0.1s each) → enlarge to 115% (0.08s) → shrink to 0 (0.18s) |
| **Invalid move** | Nudge toward wall (cubic, 45% of move duration) + spring back (85% of move duration) |
| **Stuck state** | Board horizontal oscillation (5 tweens) → 0.25s pause → auto-reset |
| **Reset** | All blocks slide to start (cubic ease-in-out, 2.5× duration). Full reload if D blocks were consumed |
| **Win** | Hide targets/A cells/teleports/D blocks → arrow scale-down (0.25s, back ease) → double flash → reverse diagonal exit wave |
| **Tap pulse** | Scale 1.0 → 1.15 → 1.0 (0.09s + 0.12s, sine ease). Used on all tappable elements |
| **Reset icon** | Scale 0 → 1 on appear (0.2s, back ease), scale 1 → 0 on hide (0.15s, back ease-in) |

---

### 10.5 Layout & Safe Area

The board is always centered with 10% margin (`Board.MARGIN = 0.10`). All UI elements respect this margin: SceneHeader icons, settings rows, level select grid, and about screen text.

Safe area is detected via `DisplayServer.get_display_safe_area()` and applied at runtime for notch/status bar/home indicator insets.

---

### 10.6 App Icon

The app icon is defined as `icon.svg` at the project root — a full green square (`#3DA391`) with a rounded right-pointing triangle arrow (`#2B7366`) centered inside it.

**iOS:** A deploy script renders the SVG to a single 1024×1024 PNG using `cairosvg` and places it in the Xcode asset catalog with single-size `Contents.json`. iOS auto-generates all required sizes.

**Android:** Adaptive icon with separate foreground (transparent background, centered game elements) and background (solid white). Generated by `generate_android_icons.py` using `cairosvg` + Pillow.

---

## 11. Audio Design

Audio reinforces the calm, meditative feel. The `AudioManager` autoload manages a music player and a 4-slot SFX pool (allows overlapping sounds). Music volume is set 12dB below SFX.

| Sound | File | Trigger | Description |
|---|---|---|---|
| Background music | `music_bg.ogg` | Game start (if enabled) | Soft, looping ambient track |
| Slide | `sfx_slide.wav` | Block movement | Movement sound (syncs animation duration) |
| Win | `sfx_win.wav` | Level complete | Warm resolving chord |
| Invalid | `sfx_invalid.wav` | Blocked movement | Gentle tone on failed move |
| Reset | `sfx_reset.wav` | Level reset | Soft whoosh |
| Teleport | `sfx_teleport.wav` | Portal activation | Brief chime |
| Click | `click.wav` | UI tap (buttons, icons) | Tactile click feedback |

**SFX pool:** 4 `AudioStreamPlayer` instances allow overlapping sounds. If all are busy, the first player is reused. `get_sfx_duration()` is used to sync movement animation length to the slide SFX.

All audio can be toggled independently (music / SFX) via Settings, persisted to disk.

---

## 12. Haptic Feedback

Three haptic patterns provide tactile feedback on mobile devices:

| Pattern | Trigger | iOS (Native UIKit) | Android (Fallback) |
|---|---|---|---|
| **Tap** | Swipe, UI tap | `UIImpactFeedbackGenerator(.light)` | 15ms vibration |
| **Win** | Level complete | `UINotificationFeedbackGenerator(.success)` | Triple-tap: 10ms + 20ms + 35ms |
| **Fail** | Stuck state | `UINotificationFeedbackGenerator(.error)` | Double-hit: 40ms + 60ms |

**iOS native implementation** uses a GDExtension (`DaxtleHaptics`) built with godot-cpp, compiled as a static library (`libdaxtle_haptics.ios.template_*.arm64.a`) bundled with godot-cpp. Registered as an Engine singleton, called from `Haptics.gd` via `Engine.get_singleton("DaxtleHaptics")`.

A macOS no-op stub is included so the editor doesn't produce extension errors.

Haptics are disabled on desktop. Toggleable in Settings, persisted to SaveData.

---

## 13. Save System

`SaveData.gd` (autoload singleton) persists to `user://save.json`:

| Field | Type | Default | Description |
|---|---|---|---|
| `progress_level` | int | 1 | Highest completed level (gates level select) |
| `last_level` | int | 1 | Resume point for "Play" button |
| `music_enabled` | bool | true | Music toggle state |
| `sfx_enabled` | bool | true | Sound effects toggle state |
| `haptics_enabled` | bool | true | Haptic feedback toggle state |
| `best_streak` | int | 0 | Best challenge mode streak |

Uses a load-merge-save pattern to preserve other fields when writing individual values.

---

## 14. Build & Deployment

### Deploy Script

`deploy/deploy_firebase.sh` automates building and distributing to Firebase App Distribution:

```
./deploy/deploy_firebase.sh [android|ios|all]
```

**Pipeline:**
1. Increment build number (shared counter in `.build_number`)
3. Godot headless export
4. *(iOS only)* Regenerate icon from SVG via `scripts/tools/regenerate_ios_icons.sh`
5. *(iOS only)* Patch launch screen, signing config
6. *(iOS only)* `xcodebuild archive` + `exportArchive` (release-testing method)
7. Firebase App Distribution upload

### Icon Generation

- **iOS:** `scripts/tools/regenerate_ios_icons.sh` — renders `icon.svg` → 1024px PNG → Xcode asset catalog (single size, iOS auto-generates all variants)
- **Android:** `scripts/tools/generate_android_icons.py` — renders `icon.svg` → legacy 192px, adaptive foreground 432px (transparent bg), adaptive background 432px (white), monochrome 432px

---

## 15. Current Status & Roadmap

### Implemented

| Feature | Status |
|---|---|
| iOS and Android builds + Firebase deployment | Done |
| 21 hand-crafted campaign levels | Done |
| Challenge mode (easy/medium/hard pools, timer, streaks) | Done |
| All game elements (A, B, C, D, T) | Done |
| Cargo blocks (dir: "none") with push mechanics | Done |
| Destroy blocks (D) with flash + shrink animation | Done |
| One-way and two-way teleports | Done |
| Stuck detection + auto-reset | Done |
| Manual reset + double-tap reset + R key reset | Done |
| 6 screens: Main Menu, Level Select, Game, Settings, About, Challenge Intro | Done |
| In-game level editor with validate, save, play-test | Done |
| SceneHeader reusable component | Done |
| Icon buttons with SVG assets (play, levels, settings, about) | Done |
| 4×5 scrollable level select with page dots | Done |
| Chain scale intro animations (title, buttons, board, blocks) | Done |
| Snake-like title rise animation | Done |
| Win sequence: arrow shrink → flash → exit wave | Done |
| Background music + 6 SFX (slide, win, invalid, reset, teleport, click) | Done |
| Native iOS haptics (GDExtension) + Android fallback | Done |
| Touch, keyboard, and gamepad input | Done |
| Safe area / notch support | Done |
| Three visual themes (dev use, WARM_SAND active) | Done |
| Progress + preferences + best streak saved to disk | Done |
| Portrait orientation only | Done |
| Fredoka Bold font | Done |
| Completion popup when all campaign levels beaten | Done |
| Automated icon generation from SVG | Done |
| PuzzleSolver BFS (solvability check, max 20 moves) | Done |

### Not Yet Implemented

| Feature | Priority |
|---|---|
| 30+ additional levels (target: 50) | High |
| Localization (10+ languages) | High |
| Game Center (leaderboards, achievements) | Medium |
| Move counter / star rating per level | Medium |
| Undo single move | Low |
| Hint system | Low |
| In-game theme switcher | Low |
| Cloud save / sync | Low |

---

*Document version 6.0 — Daxtle Current Implementation*
*Last updated: March 24, 2026*
