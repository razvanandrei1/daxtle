# Daxtle — Game Design Document
**Version 4.0 — Current Implementation**

---

## Table of Contents

1. [Overview](#1-overview)
2. [Platform & Technical Stack](#2-platform--technical-stack)
3. [Player Input](#3-player-input)
4. [Game Elements](#4-game-elements)
   - 4.1 [Element A — The Board](#41-element-a--the-board)
   - 4.2 [Element B — The Blocks](#42-element-b--the-blocks)
   - 4.3 [Element C — Fixed Blocks](#43-element-c--fixed-blocks)
   - 4.4 [Element T — Teleport Pairs](#44-element-t--teleport-pairs)
5. [Game Rules & Logic](#5-game-rules--logic)
   - 5.1 [Movement](#51-movement)
   - 5.2 [Pushing](#52-pushing)
   - 5.3 [Invalid Moves](#53-invalid-moves)
   - 5.4 [Stuck Detection](#54-stuck-detection)
   - 5.5 [Win Condition](#55-win-condition)
   - 5.6 [Reset](#56-reset)
6. [Level Structure](#6-level-structure)
   - 6.1 [Level Progression](#61-level-progression)
   - 6.2 [Level Design Constraints](#62-level-design-constraints)
   - 6.3 [JSON Format](#64-json-format)
7. [Screens & Navigation](#7-screens--navigation)
8. [Visual Design](#8-visual-design)
   - 8.1 [Aesthetic](#81-aesthetic)
   - 8.2 [Typography](#82-typography)
   - 8.3 [Color & Theme System](#83-color--theme-system)
   - 8.4 [Animations](#84-animations)
   - 8.5 [Layout & Safe Area](#85-layout--safe-area)
9. [Audio Design](#9-audio-design)
10. [MVP Scope](#10-mvp-scope)

---

## 1. Overview

**Daxtle** is a minimalist mobile puzzle game built around a simple but deeply satisfying mechanic: slide colored blocks across an irregular grid to land each one on its matching target.

Every block has a fixed, predefined direction — it can only ever move one way. A single swipe moves all blocks sharing that direction simultaneously, and a moving block will push any block it collides with — meaning every move can have cascading consequences across the entire board.

The game features five element types: board squares (A), directional blocks (B), cargo blocks (B with no direction), fixed obstacles (C), and teleport portals (T). These are introduced progressively across 50 hand-crafted levels organized into five chapters.

The game is calm and deliberate. There are no timers, no lives, no move counters, and no fail states. The satisfaction comes entirely from the "aha" moment when the correct sequence clicks into place.

---

## 2. Platform & Technical Stack

| Property | Value |
|---|---|
| Engine | Godot 4.6 (GDScript) |
| Target platforms | iOS and Android |
| Orientation | Portrait only |
| Game mode | Level-based |
| Font | Nunito Bold (variable weight) |
| Business model | Defined in a separate document |

---

## 3. Player Input

The player interacts with the game through four swipe gestures, performed anywhere on the screen:

| Gesture | Action |
|---|---|
| Swipe left | Trigger left movement |
| Swipe right | Trigger right movement |
| Swipe up | Trigger upward movement |
| Swipe down | Trigger downward movement |

A swipe in a given direction attempts to move all B blocks whose predefined direction matches that swipe. Blocks with a different predefined direction (or no direction) are unaffected unless pushed by a moving block.

A minimum drag distance threshold filters out accidental taps. Input is fully disabled while any animation is in progress.

---

## 4. Game Elements

### 4.1 Element A — The Board

Element A is the static playing field. It is composed of adjoining squares arranged in a grid pattern, but not necessarily rectangular. The board can take any shape: L-shapes, crosses, staircases, hourglasses, T-shapes, or any other configuration. Missing squares create holes that blocks cannot enter.

**Rendering.** The board is always centered on screen. Each square's size (`Value_A`) is calculated dynamically so the board fits with a 10% margin on all sides. Squares are rendered as flat rounded rectangles in the active theme's surface color, separated by a small gap (4.2% of `Value_A`). Target squares show a semi-transparent tint (35% opacity) of the corresponding block's color.

**Data format.** Board squares are defined as a matrix of `[x, y]` coordinate pairs:

```json
"A": [[0,0], [1,0], [2,0], [0,1], [1,1], [2,1]]
```

Only listed positions exist on the board. Any position not listed is a hole.

---

### 4.2 Element B — The Blocks

Element B refers to the movable blocks that the player manipulates. All B blocks are 1×1 (single square). There are two variants:

**Directional blocks** have a fixed movement direction (`"left"`, `"right"`, `"up"`, or `"down"`) that never changes during gameplay. A directional arrow — rendered as a filled rounded triangle, darkened 30% from the block's color — indicates the direction.

**Cargo blocks** have no direction (`"none"`). They cannot be moved by any swipe on their own. They can only be repositioned when another block pushes into them. Cargo blocks display a small centered dot instead of an arrow.

**Color.** Each block is assigned a unique color based on its ID from the active theme palette. Colors are defined per-theme, not per-level.

**Target.** Each block has a designated target position, highlighted on the board with a muted tint of the block's color.

**Data format:**

```json
{
  "id": "B1",
  "dir": "right",
  "origin_x": 0, "origin_y": 1,
  "target_origin_x": 3, "target_origin_y": 1
}
```

| Field | Description |
|---|---|
| `id` | Unique identifier (e.g. "B1", "B2") — determines color from theme |
| `dir` | `"left"`, `"right"`, `"up"`, `"down"`, or `"none"` (cargo) |
| `origin_x / origin_y` | Starting grid position |
| `target_origin_x / target_origin_y` | Target grid position |

---

### 4.3 Element C — Fixed Blocks

Element C is a static, immovable block occupying one or more board squares. It acts as a permanent wall that blocks B block movement and push chains.

**Behavior:**
- Cannot be moved by any swipe or push
- If a push chain reaches a C block, the chain is blocked
- Always visible from the start of the level
- Does not count toward the win condition
- Scales in during the board wave animation (part of the environment)

**Visual appearance.** Rendered in a neutral dark tone defined per-theme, significantly darker than the surface color. No arrow or symbol.

**Data format:**

```json
"C": [
  {
    "id": "C1",
    "squares": [{"pos_x": 0, "pos_y": 0}],
    "origin_x": 2, "origin_y": 2
  }
]
```

---

### 4.4 Element T — Teleport Pairs

Teleport pairs are two linked portal cells on the board. When a block enters one portal, it exits at the partner cell.

**Behavior:**
- Bidirectional by default; optional `one_way` flag restricts to A→B only
- After teleporting, the block attempts one continuation step (exit + direction). If that cell is valid, empty, not fixed, and not another portal, the block lands there. Otherwise it stays at the exit cell
- Pushed blocks can teleport (push chain enters portal → exits at partner)
- A block already sitting on a portal does NOT teleport — only entering triggers it
- Both portals of a pair flash simultaneously when activated

**Visual appearance.** Each portal is drawn as a colored ring with a center dot, using a per-pair color from the theme's teleport palette. Multiple pairs on the same board use different colors.

**Data format:**

```json
"T": [
  {"id": "T1", "ax": 1, "ay": 0, "bx": 4, "by": 4}
]
```

| Field | Description |
|---|---|
| `id` | Pair identifier — used for color assignment |
| `ax / ay` | Grid position of portal A |
| `bx / by` | Grid position of portal B |
| `one_way` | Optional boolean. If true, only A→B. Default: false |

---

## 5. Game Rules & Logic

### 5.1 Movement

When the player swipes, every B block whose direction matches the swipe attempts to move one square in that direction. All other blocks remain stationary. Cargo blocks (`dir: "none"`) never move on their own.

Movement is animated with a smooth slide using cubic easing. All moving blocks animate simultaneously.

**Teleport movement.** When a block's destination is a portal cell, the block enters the portal and exits at the partner cell. A sequential animation plays: slide to portal → shrink to zero → jump to exit → pop back to full size → slide to continuation cell (if applicable).

---

### 5.2 Pushing

When a moving block would enter a square occupied by another B block, it pushes that block one square in the same swipe direction. Push chains propagate recursively: if the pushed block collides with another, that block is pushed too.

**Key rules:**
- Pushed blocks move in the swipe direction, NOT in the pushed block's own direction
- Cargo blocks can be pushed in any direction
- If a push chain reaches a C block or board edge, the entire chain is blocked
- Push chains can pass through teleport portals — blocks at the exit cell join the active push set

**Pushing as a design tool.** Mandatory pushes are a core mechanic: some blocks' targets are in rows/columns they can never reach alone, requiring another block to push them into position.

---

### 5.3 Invalid Moves

A move is invalid if any block in the chain would land outside the board, on a hole, or on a C block. When invalid:

1. All involved blocks play a shake animation (nudge toward wall, spring back)
2. Blocks return to previous positions
3. No penalty or fail state

---

### 5.4 Stuck Detection

After every valid move, the game checks whether any block can move in any of the four directions. If no moves are possible and the level is not won, the board is stuck:

1. The board shakes with a gentle horizontal oscillation
2. After a brief pause, all blocks animate back to starting positions (auto-reset)

This is a lightweight check (not BFS) — it only detects the immediate "no moves available" state. The player is responsible for recognizing deeper dead-end situations, which they can resolve with the manual reset button.

---

### 5.5 Win Condition

The level is won when all B blocks simultaneously occupy their target positions. When won:

1. All B blocks flash (disappear/appear) twice
2. A reverse diagonal chain wave scales down all elements (board squares, B blocks, C blocks, teleports) from bottom-right to top-left — mirroring the intro animation
3. The next level loads once the exit animation completes

---

### 5.6 Reset

A reset button (circular arrow icon) appears in the top-right corner after the player's first move. Tapping it smoothly slides all blocks back to their starting positions using cubic ease-in-out at 2.5× normal speed. The reset button hides again after reset.

The game also auto-resets when stuck (see 5.4).

---

## 6. Level Structure

### 6.1 Level Progression

The game contains 50 hand-crafted levels organized into five chapters:

| Chapter | Levels | Theme | Key Mechanic |
|---|---|---|---|
| 1 — Core | 1–10 | Pure blocks, rectangular boards | Directions, sequencing, same-direction push chains |
| 2 — Mandatory Push | 11–20 | Cross-direction push, mild shape variation | Blocks must be pushed to rows/columns they can't reach alone |
| 3 — Holes | 21–30 | Irregular boards, missing squares | Board shape constrains routing, combined with some pushes |
| 4 — Fixed Blocks | 31–40 | C blocks as walls/stops | Internal walls, billiard stops, combined with holes and pushes |
| 5 — Teleports | 41–50 | Portal pairs | Non-Euclidean routing, push-through portals; mandatory pushes in second half |

Each chapter begins with easy introduction levels and progresses through increasing complexity. Difficulty never places two very hard levels back-to-back.

---

### 6.2 Level Design Constraints

- Every level must be **provably solvable**
- No B block's target may overlap another B block's starting position
- No two B blocks may share the same starting position
- Every element must earn its place — the signal-to-noise rule applies (see Daxtle_LevelDesign_Guidelines.md)
- Each level has exactly one design intention

---

### 6.3 JSON Format

Each level is stored as `level_NNN.json`. Top-level fields:

| Field | Type | Description |
|---|---|---|
| `level` | Integer | Level number |
| `A` | Array | Board squares as `[x, y]` coordinate pairs |
| `B` | Array | Block definitions |
| `C` | Array | *(Optional)* Fixed block definitions |
| `T` | Array | *(Optional)* Teleport pair definitions |

**Example — Level 1:**

```json
{
  "level": 1,
  "A": [[0,0], [1,0], [2,0]],
  "B": [
    {
      "id": "B1", "dir": "right",
      "origin_x": 0, "origin_y": 0,
      "target_origin_x": 2, "target_origin_y": 0
    }
  ]
}
```

**Example — Level with C blocks and teleports:**

```json
{
  "level": 48,
  "A": [[0,0],[1,0],[2,0],[3,0], [0,1],[1,1],[2,1],[3,1], [0,2],[1,2],[2,2],[3,2], [0,3],[1,3],[2,3],[3,3]],
  "B": [
    {"id": "B1", "dir": "right", "origin_x": 0, "origin_y": 0, "target_origin_x": 1, "target_origin_y": 2},
    {"id": "B2", "dir": "down", "origin_x": 1, "origin_y": 0, "target_origin_x": 2, "target_origin_y": 2}
  ],
  "C": [
    {"id": "C1", "squares": [{"pos_x": 0, "pos_y": 0}], "origin_x": 1, "origin_y": 1}
  ],
  "T": [
    {"id": "T1", "ax": 3, "ay": 0, "bx": 0, "by": 2}
  ]
}
```

---

## 7. Screens & Navigation

The game has four screens, navigated via show/hide with process mode toggling:

**Main Menu** → **Level Select** → **Game** (with back navigation at each step)

### Main Menu
- Title "DAXTLE" in bold, top center
- "Play" button (solid rounded rectangle in theme text color)
- "Settings" button (outlined rounded rectangle)
- "This is a MVP project" subtitle at bottom

### Level Select
- Horizontally scrollable pages, one per chapter (12 slots per 3×4 grid)
- Each page is a rounded rectangle frame containing level number cells
- Page indicator dots below
- Back arrow (top-left) returns to Main Menu
- Tapping a level cell plays a scale pulse, then loads the level

### Game Scene
- Board centered on screen with 10% margin
- Level number displayed top-center in bold
- Back arrow (top-left) — rounded triangle matching B component arrow style
- Reset icon (top-right) — circular arrow, appears after first move
- All icons use the universal tap pulse animation before triggering their action

---

## 8. Visual Design

### 8.1 Aesthetic

Minimalist throughout. Clean, calm, and deliberate. Every visual element serves a functional purpose. The design language is rounded rectangles and rounded triangles — consistent across board squares, blocks, arrows, buttons, and icons.

---

### 8.2 Typography

The project uses **Nunito Bold** (weight 700) as the universal font for all text. A variable font file (`Nunito-Variable.ttf`) is used with FontVariation resources for weight control. The font color across all UI matches the theme's `text` color — which in the WARM_SAND theme is the B1 teal color darkened by 30% (matching the triangle arrows on blocks).

---

### 8.3 Color & Theme System

Three themes are defined. Switching the active theme changes everything without touching level files.

| Theme | Background | Surface | Text | B1 | B2 | B3 | B4 |
|---|---|---|---|---|---|---|---|
| WARM_SAND | Warm sand | Muted tan | Dark teal | Teal | Coral | Blue | Amber |
| COOL_SLATE | Light grey | Blue-grey | Dark blue-grey | Blue | Coral | Teal | Amber |
| DARK_CHARCOAL | Dark | Dark grey | Light off-white | Bright blue | Bright coral | Bright teal | Bright amber |

Each theme also defines:
- `fixed` — C block color (neutral dark tone)
- `teleport` — array of 4 portal pair colors (purple, cyan, orange, green)

**Target zones** use 35% opacity of the block's color overlaid on the surface.

---

### 8.4 Animations

All animations use Tween-based interpolation. Input is disabled during all animations.

| Animation | Description |
|---|---|
| Normal move | Cubic ease-out slide, all moving blocks simultaneously |
| Teleport move | Slide to portal → shrink to zero → jump to exit → pop (back ease) → slide to continuation |
| Invalid move | Nudge toward wall (cubic) + spring back |
| Stuck state | Board horizontal oscillation → pause → auto-reset |
| Reset | All blocks slide to start (cubic ease-in-out, 2.5× duration) |
| Level intro | Diagonal chain wave (top-left → bottom-right): board squares, C blocks, and teleports scale up with back-ease. Then B blocks scale up with staggered delay, arrows fade in |
| Win | 2 flashes on B blocks, then reverse diagonal chain wave (bottom-right → top-left): all elements scale down with back-ease-in |
| Tap pulse | Universal: scale up to 115% (sine ease-out) then back to 100% (sine ease-in-out). Used on all tappable icons and level select cells |
| Portal activation | Both portals of the pair flash bright then fade back |

---

### 8.5 Layout & Safe Area

The board is always centered with 10% margin. UI elements (back arrow, reset icon) are positioned at the 10% horizontal margin, vertically offset by the device safe area inset (notch/status bar). The level number label is vertically aligned with both icons.

Safe area is detected via `DisplayServer.get_display_safe_area()` and applied at runtime.

---

## 9. Audio Design

Audio reinforces the calm, meditative feel. Nothing is loud or jarring.

| Sound | Description |
|---|---|
| Background music | Soft, looping ambient track |
| Slide sound | Subtle sound on each block movement |
| Invalid move sound | Gentle tone with shake animation |
| Reset sound | Soft whoosh as blocks return |
| Win sound | Warm resolving chord |
| Teleport sound | Brief distinct chime on portal activation |

---

## 10. MVP Scope

| Implemented | Not yet implemented |
|---|---|
| iOS and Android export | Tablet-specific layouts |
| 50 hand-crafted levels (5 chapters) | Level editor |
| All game elements (A, B, C, T) | Cloud save / sync |
| Cargo blocks (dir: "none") | Undo single move |
| Stuck detection + auto-reset | Hint system |
| Manual reset button | Achievements or leaderboards |
| Main Menu + Level Select + Game scenes | In-game theme switcher |
| Horizontal-scroll level select (3×4 pages) | Audio (not yet implemented) |
| Tap pulse animations | Settings screen |
| Safe area / notch support | |
| Three visual themes (dev use) | |
| Nunito Bold font | |
| Portrait orientation only | |
| Progress saved to disk | |

---

*Document version 4.0 — Daxtle Current Implementation*
*Last updated: March 2026*
