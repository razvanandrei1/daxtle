# Daxtle — Game Design Document
**Version 3.0 — MVP + Post-MVP Features**

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
   - 5.4 [Dead State Detection](#54-dead-state-detection)
   - 5.5 [Win Condition](#55-win-condition)
   - 5.6 [Reset](#56-reset)
6. [Level Structure](#6-level-structure)
   - 6.1 [Level Progression](#61-level-progression)
   - 6.2 [Level Design Constraints](#62-level-design-constraints)
   - 6.3 [Level Diversity & Long-term Potential](#63-level-diversity--long-term-potential)
   - 6.4 [JSON Format](#64-json-format)
   - 6.5 [Level Examples](#65-level-examples)
7. [Visual Design](#7-visual-design)
   - 7.1 [Aesthetic](#71-aesthetic)
   - 7.2 [Color & Theme System](#72-color--theme-system)
   - 7.3 [Animations](#73-animations)
   - 7.4 [Layout](#74-layout)
8. [Audio Design](#8-audio-design)
9. [MVP Scope](#9-mvp-scope)

---

## 1. Overview

**Daxtle** is a minimalist mobile puzzle game built around a simple but deeply satisfying mechanic: slide colored blocks across an irregular grid to land each one on its matching target.

Every block has a fixed, predefined direction — it can only ever move one way. The player's challenge is to figure out the correct sequence of swipes to guide all blocks to their targets, using the blocks themselves as tools. Crucially, a single swipe moves all blocks sharing that direction simultaneously, and a moving block will push any block it collides with — meaning every move can have cascading consequences across the entire board.

The game is calm and deliberate. There are no timers, no lives, no move counters, and no fail states. A wrong move is simply undone. The satisfaction comes entirely from the "aha" moment when the correct sequence clicks into place.

---

## 2. Platform & Technical Stack

| Property | Value |
|---|---|
| Engine | Godot 4 (GDScript) |
| Target platforms | iOS and Android |
| Orientation | Portrait only (no landscape support) |
| Game mode | Level-based (no freeplay) |
| Business model | Defined in a separate document |

---

## 3. Player Input

The player interacts with the game exclusively through four swipe gestures, each performed anywhere on the screen:

| Gesture | Action |
|---|---|
| Swipe left | Trigger left movement |
| Swipe right | Trigger right movement |
| Swipe up | Trigger upward movement |
| Swipe down | Trigger downward movement |

A swipe in a given direction attempts to move all B blocks whose predefined direction matches that swipe. Blocks with a different predefined direction are completely unaffected by that swipe.

A minimum drag distance threshold filters out accidental taps before a swipe is registered. Input is fully disabled while any animation is in progress — including movement, invalid move feedback, reset, and level initialization — preventing accidental queued moves.

---

## 4. Game Elements

### 4.1 Element A — The Board

Element A is the static playing field on which the puzzle takes place. It is composed of adjoining squares arranged in a grid pattern, but not necessarily rectangular in shape.

**Shape flexibility.** The board can take any form: a simple 4×4 square, a narrow 2×5 strip, an L-shape, a cross, or any other configuration of connected squares. Individual squares may also be absent from the interior of the grid, creating holes that the player must navigate around. This shape flexibility is one of the key sources of puzzle diversity in Daxtle.

**Rendering and sizing.** The board is always centered on the screen. The size of each individual square — referred to throughout the codebase as `Value_A` — is calculated dynamically at load time so that the entire board fits on screen with a 10% margin on all sides. A small 3×3 board will therefore render with larger squares than a large 7×7 board. `Value_A` is returned by the board's instantiation method and shared with all other game systems.

**Visual appearance.** Board squares are rendered as flat solid rectangles with rounded corners in a single surface color defined by the active theme. A small gap (5% of `Value_A`) separates adjacent squares. Missing squares are simply not rendered — they appear as empty space. Target squares render with a muted tint of the corresponding block's color overlaid on top of the surface color.

**Data format.** The board is defined in the level JSON file as an array of square positions using integer grid coordinates. Only squares listed in this array exist on the board. Any grid position not listed is treated as a missing square.

```json
"A": [
  {"pos_x": 0, "pos_y": 0},
  {"pos_x": 1, "pos_y": 0},
  {"pos_x": 0, "pos_y": 1}
]
```

---

### 4.2 Element B — The Blocks

Element B refers to the movable colored blocks that the player manipulates. There can be multiple B elements per level — typically between two and six — each defined and behaving independently.

**Shape.** Like Element A, a B block can span multiple squares. Its shape is defined as an array of squares relative to its own origin point. A 1×1 block occupies one square; an L-shaped block might occupy three. All squares of a B block share the same color and always move together as a single rigid unit.

**Size.** Each square of a B block is exactly the same size as an A square (`Value_A`), ensuring perfect grid alignment at all times. Blocks are rendered to fill each cell they occupy (matching the board square size, minus the standard inter-cell gap), with rounded corners consistent with the board aesthetic.

**Color.** Each B block is assigned a unique color at load time based on its ID. Colors are defined in the active game theme — not in the level JSON file. This keeps level data clean and allows the entire color scheme to be changed without touching level files.

**Direction.** Each B block has a fixed, predefined movement direction: left, right, up, or down. This direction never changes during gameplay. A directional arrow — rendered as a filled triangle, darkened from the block's color — is drawn on the block so the player always knows which way it will move.

**Target.** Each B block has a designated target position on the board. The target square is highlighted with a muted, semi-transparent tint of the corresponding block's color, drawn directly on the board surface.

**Data format.** A B block is defined in the level JSON with its shape, starting position on the A grid, direction, and target position:

```json
{
  "id": "B1",
  "dir": "right",
  "squares": [{"pos_x": 0, "pos_y": 0}],
  "origin_x": 0,
  "origin_y": 1,
  "target_origin_x": 3,
  "target_origin_y": 1
}
```

| Field | Description |
|---|---|
| `id` | Unique identifier (e.g. "B1", "B2") — used to assign color from the active theme |
| `dir` | Movement direction: `"left"`, `"right"`, `"up"`, or `"down"` |
| `squares` | Block shape as `{pos_x, pos_y}` offsets relative to its own origin |
| `origin_x / origin_y` | Where the block's origin is placed on the A grid at level start |
| `target_origin_x / target_origin_y` | Where the block's origin must be to count as on its target |

---

### 4.3 Element C — Fixed Blocks

> **Status: Post-MVP — not yet implemented**

Element C is a static, immovable block that occupies one or more board squares and cannot be moved or pushed under any circumstances. It acts as a permanent structural obstacle that the player must route around when solving the puzzle.

Element C introduces **irreversible spatial constraints** into level design — unlike the board shape itself (which is fixed and immediately visible), C blocks can be placed anywhere on valid board squares, creating internal walls that subdivide the playing field in non-obvious ways.

**Behavior:**
- Occupies one or more squares on Element A, exactly like Element B in terms of spatial footprint
- Cannot be moved by any swipe — it has no direction and does not respond to player input
- Cannot be pushed by a moving B block — if a push chain reaches a C block, the entire chain is treated as invalid and all involved B blocks shake and return
- Always visible from the start of the level — never hidden or revealed mid-puzzle
- Does not count toward the win condition — only B blocks on their targets win the level

**Visual appearance.** Same square size and gap as A squares and B blocks. Rendered in a neutral, dark tone — significantly darker than the board surface but without any color tint. No directional arrow. During level initialization, C blocks scale in as part of the board wave (alongside A squares), not with the B blocks, reinforcing that they are part of the environment rather than movable pieces.

**Data format.** Element C is defined as a new top-level array `"C"` in the level JSON. Each entry has a shape and an origin. No `id`, `dir`, or `target` fields — C blocks are purely positional.

```json
"C": [
  {
    "squares": [{"pos_x": 0, "pos_y": 0}],
    "origin_x": 2,
    "origin_y": 2
  },
  {
    "squares": [{"pos_x": 0, "pos_y": 0}, {"pos_x": 1, "pos_y": 0}],
    "origin_x": 4,
    "origin_y": 1
  }
]
```

Levels without any C blocks simply omit the `"C"` array — fully backward compatible with all existing levels.

**Level design implications.** C blocks dramatically expand the design space without adding complexity for the player to learn. The rule is immediately intuitive: it looks solid, it is solid. They enable corridor puzzles, dead-end traps, blocking without push dependencies, and board subdivision into distinct zones. The level designer must ensure no C block placement creates a dead state from the initial position — the BFS dead-state detector enforces this automatically when C block awareness is implemented.

**Suggested introduction point:** Around level 30–35 in a 100-level game, introduced alone on a simple board before being combined with complex push chains.

---

### 4.4 Element T — Teleport Pairs

> **Status: Post-MVP — not yet implemented**

Teleport pairs are two specially marked squares on Element A that are linked together. When a B block slides onto one square of a pair, it is instantly transported to the paired square, continuing its movement from there if space permits.

Teleport pairs introduce **non-Euclidean routing** into Daxtle — a block can effectively travel from one part of the board to a completely disconnected part in a single move, producing the strongest "aha" moments of any planned feature.

**Behavior:**
- When a B block moves onto a teleport square, it is instantly relocated to the paired square
- The block retains its direction and continues moving if the square ahead of the exit is valid and clear
- If the exit square is occupied (by another B block or a C block), the teleport is treated as invalid — the entering block shakes and returns
- Teleport pairs are **bidirectional** by default — a block can enter from either square and exit from the other
- Optional: one-way teleports (entry-only on one side) can be defined per-pair in the level JSON
- If a push chain reaches a teleport square, the entire chain teleports together — each block exits from the paired square in sequence; if any block cannot exit, the entire chain is invalid
- A block cannot teleport more than once per move (infinite-loop protection)
- A level can contain multiple independent teleport pairs; entering one pair always exits at its specific partner

**Visual appearance.** Each square of a pair is tinted with the same unique color, distinct from any B block color and sourced from a dedicated teleport palette in the active theme. A subtle symbol centered on each square reinforces the link. If multiple pairs exist on the same board, each pair uses a different tint. On activation, both squares of a pair flash simultaneously with a brief pulse, reinforcing the connection to the player.

**Data format.** Teleport pairs are defined as a new top-level array `"T"` in the level JSON.

```json
"T": [
  {
    "id": "T1",
    "a_x": 1, "a_y": 0,
    "b_x": 4, "b_y": 4,
    "one_way": false
  },
  {
    "id": "T2",
    "a_x": 0, "a_y": 3,
    "b_x": 5, "b_y": 1,
    "one_way": false
  }
]
```

| Field | Type | Description |
|---|---|---|
| `id` | String | Pair identifier (e.g. "T1", "T2") — used for visual color assignment |
| `a_x / a_y` | Integer | Grid position of the first square of the pair |
| `b_x / b_y` | Integer | Grid position of the second square of the pair |
| `one_way` | Boolean | Optional. If true, only `a` is an entry point, `b` is exit only. Default: false |

Levels without teleport pairs simply omit the `"T"` array — fully backward compatible with all existing levels.

**Level design implications.** Teleport pairs are the most powerful design tool in this proposal. They enable shortcutting across the board, cross-board dependencies, misdirection, exit-blocking puzzles, and push-through teleport chains. Design constraints: teleport exit squares must not be a B block's starting position; the BFS dead-state detector must account for teleport traversal to remain accurate.

**Suggested introduction point:** Around level 40–50 in a 100-level game. The first teleport level should use a single pair on a simple board with one B block so the player can discover the mechanic with no other variables in play.

---

## 5. Game Rules & Logic

### 5.1 Movement

When the player swipes in a direction, every B block whose predefined direction matches the swipe direction attempts to move one square in that direction. All other blocks remain stationary.

For example: a swipe right causes only blocks with `dir: "right"` to attempt movement. Blocks with any other direction are completely unaffected.

Movement is animated with a smooth slide using cubic easing. All moving blocks animate simultaneously. No further input is accepted until all animations have completed.

---

### 5.2 Pushing

When a moving block (the pusher) would enter a square occupied by another B block (the pushed), it does not stop — instead it pushes that block in the same direction by the same number of squares.

**Push distance.** The pushed block travels exactly the same number of squares as the pusher. It does not slide freely until hitting a wall — it moves precisely as far as the pusher dictates.

**Chain pushing.** If the pushed block is adjacent to a third block in the push direction, the push propagates through the entire chain. B1 pushes B2, which pushes B3, and so on. All blocks in the chain are evaluated together and move simultaneously.

**C block interaction.** If a push chain reaches a C block (fixed block), the C block does not move and does not push back. The entire chain is immediately treated as invalid — all B blocks involved shake and return. No partial movement occurs.

**Invalid push.** If the push would cause any block in the chain — pusher or pushed — to land on a boundary, a missing square, or a C block cell, the entire move is invalid. All blocks involved shake and return to their previous positions.

**Pushing as a design tool.** Blocks can be used to carry each other into positions neither could reach independently. This creates puzzles where the player must consider not just move order, but which blocks are positioned to act as pushers at the right moment.

---

### 5.3 Invalid Moves

A move is considered invalid if, after applying the movement, any square of any block in the active chain would land on either:

- A position **outside the outer boundary** of the A grid, or
- A **missing square** (hole) within the A grid, or
- A square occupied by an **Element C (fixed block)**

When an invalid move is detected:

1. All blocks involved play a brief shake animation — nudging toward the wall then springing back
2. All blocks return to their previous positions as part of the shake
3. The level continues with no penalty and no fail state

---

### 5.4 Dead State Detection

After every valid move, the game automatically checks whether the current board state is still solvable. This is done using a breadth-first search (BFS) over all reachable states from the current position, simulating the full push mechanic at each step.

The BFS simulation must account for all active game elements:
- **C blocks** — permanently occupied cells that no B block can enter
- **Teleport pairs** — when a simulated block moves onto a teleport square, its position jumps to the paired exit square before continuing

If the BFS exhausts all reachable states without finding a winning configuration, the level is considered to be in a dead state. When this happens:

1. The entire board plays a gentle oscillating shake animation
2. After a brief pause, all blocks automatically animate back to their starting positions (same as a manual reset)
3. Input is re-enabled once the reset animation completes

The BFS has a safety cap on the number of states explored to keep detection fast. If the cap is reached before a conclusion is reached, the game assumes the level is still solvable (safe default — avoids false positives).

Dead state detection removes the need for the player to manually recognize when they are stuck, and ensures the game never leaves the player stranded.

---

### 5.5 Win Condition

The level is won the instant all B blocks are simultaneously occupying their respective target positions. This is checked automatically after every move animation completes.

When the win condition is met:

1. All B blocks pulse with a rhythmic double-glow animation simultaneously
2. All B blocks fade out together
3. The board fades out shortly after
4. The next level loads automatically once the fade completes

There is no score, no star rating, and no confirmation step. The only measure of success in Daxtle is solving the puzzle.

---

### 5.6 Reset

The player can reset the current level at any time using the reset button. When triggered, all B blocks animate smoothly back to their original starting positions simultaneously, using the same smooth cubic interpolation as normal movement. Nothing snaps or jumps.

The game also resets automatically when a dead state is detected (see Section 5.4).

There is no move counter. The game keeps no record of how many moves the player used, and no rating is assigned based on efficiency or speed.

---

## 6. Level Structure

### 6.1 Level Progression

Levels are played in strict sequence. Each time a level is completed, the next level loads automatically. Progress is saved to disk and persists between app sessions.

---

### 6.2 Level Design Constraints

All levels must satisfy the following rules before shipping:

- Every level must be **provably solvable** — a valid solution sequence must be identified before the level is included
- No B block's **target position** may overlap with any other B block's **starting position**
- No two B blocks may share the **same starting position**
- Every B block must have a **reachable path** to its target given at least one valid sequence of moves, accounting for the push mechanic and the board shape
- A B block's target must be **reachable in its movement direction** relative to its start — however, the target does not need to be directly and unobstructedly ahead. The push mechanic allows a block to be stopped at positions it could not reach in a straight unobstructed slide, which is a key source of interesting puzzle design
- No **C block placement** may create a dead state from the initial position
- **Teleport exit squares** must not be a B block's starting position; exit squares must not be immediately adjacent to board boundaries in a way that causes an invalid exit

---

### 6.3 Level Diversity & Long-term Potential

Daxtle's design space is large. The following variables combine to produce a wide range of distinct puzzle experiences:

- **Board shape** — regular grids, irregular shapes, interior holes, sizes from 3×3 to 7×7 and beyond
- **Number of B blocks** — from one (tutorial) to six (expert)
- **Block directions** — four possible directions per block, creating varied interaction patterns
- **Block shapes** — 1×1, 1×2, L-shaped, and other multi-square forms
- **Push chains** — how many blocks interact in a single swipe
- **Sequencing constraints** — strict order required, partial order, or free order puzzles
- **C blocks** — fixed obstacles that subdivide the board and create routing constraints
- **Teleport pairs** — non-Euclidean connections that enable cross-board routing

Natural puzzle themes that each feel meaningfully different to the player:

| Theme | Description |
|---|---|
| Pure sequencing | Order of swipes matters; no pushing involved |
| Push to place | One block must push another to its target |
| Chain push | A three-block push chain must be orchestrated correctly |
| Hole navigation | Missing squares force non-obvious routing |
| Multi-shape blocks | L-shapes and larger pieces change spatial reasoning |
| Convergence | Multiple blocks targeting the same area in sequence |
| Decoy moves | Swipes that reposition uninvolved blocks before the key move |
| Corridor routing | C blocks create channels that force a specific approach order |
| Fixed-block trap | A C block adjacent to a target prevents overshooting without another B block |
| Board subdivision | C block clusters split the board into distinct zones requiring independent solution |
| Teleport shortcut | A block teleports across the board, making a long path trivially short — if set up correctly |
| Exit blocking | A B block must be cleared from a teleport exit before another block can use the pair |
| Push-through teleport | A B block pushes another into a teleport, relocating it to an unexpected position |

A conservatively scoped but high-quality launch can support 50–80 hand-crafted levels. With multi-square block shapes, complex board geometries, C blocks, and teleport pairs, the design space comfortably supports 200+ levels before any further mechanics are introduced.

---

### 6.4 JSON Format

Each level is stored as a separate JSON file named using a zero-padded convention: `level_001.json`, `level_002.json`, etc.

**Top-level fields:**

| Field | Type | Description |
|---|---|---|
| `level` | Integer | The level number |
| `A` | Array | List of valid board squares as `{pos_x, pos_y}` objects |
| `B` | Array | List of block definitions |
| `C` | Array | *(Optional)* List of fixed block definitions. Omit if no fixed blocks. |
| `T` | Array | *(Optional)* List of teleport pair definitions. Omit if no teleport pairs. |

**Each block in the B array:**

| Field | Type | Description |
|---|---|---|
| `id` | String | Unique identifier (e.g. "B1", "B2") — used to assign color from active theme |
| `dir` | String | Movement direction: `"left"`, `"right"`, `"up"`, or `"down"` |
| `squares` | Array | Block shape as `{pos_x, pos_y}` offsets relative to its origin |
| `origin_x` | Integer | Starting column on the A grid |
| `origin_y` | Integer | Starting row on the A grid |
| `target_origin_x` | Integer | Target column on the A grid |
| `target_origin_y` | Integer | Target row on the A grid |

**Each entry in the C array:**

| Field | Type | Description |
|---|---|---|
| `squares` | Array | Block shape as `{pos_x, pos_y}` offsets relative to its origin |
| `origin_x` | Integer | Column on the A grid |
| `origin_y` | Integer | Row on the A grid |

**Each entry in the T array:**

| Field | Type | Description |
|---|---|---|
| `id` | String | Pair identifier (e.g. "T1", "T2") — used for visual color assignment |
| `a_x / a_y` | Integer | Grid position of the first square of the pair |
| `b_x / b_y` | Integer | Grid position of the second square of the pair |
| `one_way` | Boolean | Optional. If true, only `a` is an entry point. Default: false |

---

### 6.5 Level Examples

#### Simple level (2 blocks)

A plain 3×3 board. Two blocks, one ordering constraint.

- **B1** moves right — starts at (0,1), target at (2,1)
- **B2** moves down — starts at (1,0), target at (1,2)

Solution: swipe **down** first (B2 reaches target), then swipe **right** (B1 reaches target). Solving in reverse causes B1 to block B2's path.

```json
{
  "level": 1,
  "A": [
    {"pos_x": 0, "pos_y": 0}, {"pos_x": 1, "pos_y": 0}, {"pos_x": 2, "pos_y": 0},
    {"pos_x": 0, "pos_y": 1}, {"pos_x": 1, "pos_y": 1}, {"pos_x": 2, "pos_y": 1},
    {"pos_x": 0, "pos_y": 2}, {"pos_x": 1, "pos_y": 2}, {"pos_x": 2, "pos_y": 2}
  ],
  "B": [
    {
      "id": "B1", "dir": "right",
      "squares": [{"pos_x": 0, "pos_y": 0}],
      "origin_x": 0, "origin_y": 1,
      "target_origin_x": 2, "target_origin_y": 1
    },
    {
      "id": "B2", "dir": "down",
      "squares": [{"pos_x": 0, "pos_y": 0}],
      "origin_x": 1, "origin_y": 0,
      "target_origin_x": 1, "target_origin_y": 2
    }
  ]
}
```

#### Complex level (4 blocks)

A 6×6 irregular board with a missing corner at top-right (5,0), an interior hole at (3,3), and a missing corner at bottom-left (0,5). Four blocks with strict ordering and multiple push dependencies.

- **B1** moves right — starts at (0,2), target at (4,2)
- **B2** moves down — starts at (2,0), target at (2,4)
- **B3** moves left — starts at (5,1), target at (1,1)
- **B4** moves up — starts at (4,4), target at (4,1)

Solution: swipe **left** ×4 → **up** ×3 → **right** ×4 → **down** ×4. Each step sets up the next: B3 must clear row 1 before B4 can reach it, B4 must land at (4,1) before B1 fills (4,2), and B2 must move last because it crosses row 2 where B1 will already be sitting.

```json
{
  "level": 5,
  "A": [
    {"pos_x": 0, "pos_y": 0}, {"pos_x": 1, "pos_y": 0}, {"pos_x": 2, "pos_y": 0}, {"pos_x": 3, "pos_y": 0}, {"pos_x": 4, "pos_y": 0},
    {"pos_x": 0, "pos_y": 1}, {"pos_x": 1, "pos_y": 1}, {"pos_x": 2, "pos_y": 1}, {"pos_x": 3, "pos_y": 1}, {"pos_x": 4, "pos_y": 1}, {"pos_x": 5, "pos_y": 1},
    {"pos_x": 0, "pos_y": 2}, {"pos_x": 1, "pos_y": 2}, {"pos_x": 2, "pos_y": 2}, {"pos_x": 3, "pos_y": 2}, {"pos_x": 4, "pos_y": 2}, {"pos_x": 5, "pos_y": 2},
    {"pos_x": 0, "pos_y": 3}, {"pos_x": 1, "pos_y": 3}, {"pos_x": 2, "pos_y": 3}, {"pos_x": 4, "pos_y": 3}, {"pos_x": 5, "pos_y": 3},
    {"pos_x": 0, "pos_y": 4}, {"pos_x": 1, "pos_y": 4}, {"pos_x": 2, "pos_y": 4}, {"pos_x": 3, "pos_y": 4}, {"pos_x": 4, "pos_y": 4}, {"pos_x": 5, "pos_y": 4},
    {"pos_x": 1, "pos_y": 5}, {"pos_x": 2, "pos_y": 5}, {"pos_x": 3, "pos_y": 5}, {"pos_x": 4, "pos_y": 5}, {"pos_x": 5, "pos_y": 5}
  ],
  "B": [
    {
      "id": "B1", "dir": "right",
      "squares": [{"pos_x": 0, "pos_y": 0}],
      "origin_x": 0, "origin_y": 2,
      "target_origin_x": 4, "target_origin_y": 2
    },
    {
      "id": "B2", "dir": "down",
      "squares": [{"pos_x": 0, "pos_y": 0}],
      "origin_x": 2, "origin_y": 0,
      "target_origin_x": 2, "target_origin_y": 4
    },
    {
      "id": "B3", "dir": "left",
      "squares": [{"pos_x": 0, "pos_y": 0}],
      "origin_x": 5, "origin_y": 1,
      "target_origin_x": 1, "target_origin_y": 1
    },
    {
      "id": "B4", "dir": "up",
      "squares": [{"pos_x": 0, "pos_y": 0}],
      "origin_x": 4, "origin_y": 4,
      "target_origin_x": 4, "target_origin_y": 1
    }
  ]
}
```

---

## 7. Visual Design

### 7.1 Aesthetic

Daxtle uses a minimalist aesthetic throughout. The visual language is clean, calm, and deliberate — never cluttered or overly decorative. Every visual element serves a functional purpose. Typography is minimal: level numbers and UI labels use a clean sans-serif typeface at a small, unobtrusive size.

---

### 7.2 Color & Theme System

The entire color scheme is defined by a single active theme. Switching the active theme changes the background, board surface, and all block colors simultaneously without touching any level files.

Three themes are currently defined:

| Theme | Feel |
|---|---|
| `WARM_SAND` | Warm off-white background, muted sand surface, rich block colors |
| `COOL_SLATE` | Cool light-grey background, blue-grey surface, slightly cooler block colors |
| `DARK_CHARCOAL` | Dark background, dark surface, bright vivid block colors |

Each theme defines:
- `background` — the viewport clear color
- `surface` — the flat fill color for board squares
- `blocks` — an ordered array of colors for B1, B2, B3, B4

**Block colors** are assigned by index from the theme's block palette based on the block's numeric ID (B1 = index 0, B2 = index 1, etc.).

**Target zones** are rendered as a semi-transparent tint (35% opacity) of the corresponding block's color, drawn directly on top of the board surface square. This makes targets feel like a natural part of the board.

**Fixed block color (Element C).** C blocks are rendered in a neutral dark tone — a single color defined per theme that is significantly darker than the board surface and does not conflict with any B block color. A dark charcoal or deep gray works across all three existing themes.

**Teleport pair colors (Element T).** Each theme defines a dedicated teleport palette: a small set of distinct tint colors used to mark teleport squares. Each pair in a level is assigned one color from this palette; multiple pairs on the same board each receive a different tint. These colors are separate from block colors and must remain visually distinct from the surface, B block colors, and C block color.

---

### 7.3 Animations

All animations use smooth Tween-based interpolation. Input is fully disabled during all animations.

**Normal movement.** All eligible blocks slide simultaneously using cubic ease-out. The animation completes before the next input is accepted.

**Invalid move.** All blocks involved in the invalid chain nudge toward the wall with cubic ease-out, then spring back using spring easing. The entire shake completes before input is re-enabled.

**Dead state.** The entire board plays a gentle multi-step horizontal oscillation. After a brief pause, all blocks animate back to their starting positions (see Reset below).

**Reset.** All B blocks animate back to their starting positions simultaneously using cubic ease-in-out at 2.5× the normal move duration, giving the reset a distinctly slower, deliberate feel.

**Level initialization.** When a level loads, elements appear in the following sequence:
1. Board squares and C blocks scale up from zero in a diagonal wave, top-left to bottom-right, with a stagger between each square, using back-ease for a subtle overshoot. C blocks appear in this wave alongside A squares — reinforcing that they are part of the environment.
2. After the wave completes, each B block scales up from zero at its starting position, one at a time with a stagger, also using back-ease
3. Each block's directional arrow fades in immediately after its block finishes scaling
4. A brief hold follows before input is enabled

**Win animation.** When all blocks reach their targets:
1. All B blocks pulse bright → normal → bright → normal (two pulses) using sine easing
2. All B blocks fade to transparent together
3. The board fades to transparent shortly after
4. The next level loads once the fade completes

**Teleport activation.** When a B block teleports, both squares of the pair flash simultaneously with a brief scale pulse — providing immediate visual confirmation of the connection to the player. This flash is a short Tween on both squares' scale or color modulate, triggered from `Game.gd` after teleport resolution.

---

### 7.4 Layout

The board is always centered on screen. No UI elements overlap the playing area. The level number and navigation controls sit in the top margin, centered horizontally, 16px from the top edge.

---

## 8. Audio Design

Audio reinforces the calm, meditative feel of the game. Nothing is loud, sudden, or jarring. The game should feel equally comfortable played with sound on or off.

| Sound | Description |
|---|---|
| Background music | A soft, looping ambient track that plays throughout gameplay |
| Slide sound | A subtle, satisfying sound on each successful block movement |
| Invalid move sound | A gentle, non-alarming tone accompanying the shake animation |
| Reset sound | A soft whoosh or reverse-slide sound as blocks return to start |
| Win sound | A warm, resolving chord or chime when a level is completed |
| Teleport sound | A brief, distinct chime or whoosh distinct from the slide sound, played on teleport activation |

---

## 9. MVP Scope

| In scope | Out of scope |
|---|---|
| iOS and Android export | Tablet-specific layouts |
| 10 hand-crafted levels | Level editor |
| Portrait orientation only | Landscape orientation |
| Level-based sequential progression | Freeplay or endless mode |
| Progress saved to disk | Cloud save / sync |
| Animated reset (manual and auto) | Undo single move |
| Dead state auto-detection and reset | Hint system |
| No move counter or scoring | Achievements or leaderboards |
| Three visual themes (dev use) | In-game theme switcher for players |
| Minimal UI (level number, navigation) | Main menu |
| Basic ambient audio | Music selection or audio settings |
| Business model | Defined in separate document |
| — | Element C (fixed blocks) |
| — | Element T (teleport pairs) |

---

*Document version 3.0 — Daxtle MVP + Post-MVP Features*
*Last updated: March 2026*
