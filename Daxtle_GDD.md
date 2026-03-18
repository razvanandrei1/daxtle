# Daxtle — Game Design Document
**Version 1.0 — MVP**

---

## Table of Contents

1. [Overview](#1-overview)
2. [Platform & Technical Stack](#2-platform--technical-stack)
3. [Player Input](#3-player-input)
4. [Game Elements](#4-game-elements)
   - 4.1 [Element A — The Board](#41-element-a--the-board)
   - 4.2 [Element B — The Blocks](#42-element-b--the-blocks)
5. [Game Rules & Logic](#5-game-rules--logic)
   - 5.1 [Movement](#51-movement)
   - 5.2 [Blocking](#52-blocking)
   - 5.3 [Invalid Moves](#53-invalid-moves)
   - 5.4 [Win Condition](#54-win-condition)
   - 5.5 [Reset](#55-reset)
6. [Level Structure](#6-level-structure)
   - 6.1 [Level Progression](#61-level-progression)
   - 6.2 [JSON Format](#62-json-format)
   - 6.3 [Full Level Example](#63-full-level-example)
7. [Visual Design](#7-visual-design)
8. [Audio Design](#8-audio-design)
9. [MVP Scope](#9-mvp-scope)

---

## 1. Overview

**Daxtle** is a minimalist mobile puzzle game built around a simple but deeply satisfying mechanic: slide colored blocks across an irregular grid to land each one on its matching target.

Every block has a fixed direction — it can only ever move one way. The player's challenge is to figure out the right sequence of swipes to guide all blocks to their targets simultaneously, using the blocks themselves as obstacles and tools.

The game is calm and deliberate. There are no timers, no lives, and no fail states. A wrong move is simply undone. The satisfaction comes entirely from the "aha" moment when the correct sequence clicks into place.

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
| Swipe left | Move left |
| Swipe right | Move right |
| Swipe up | Move up |
| Swipe down | Move down |

A swipe in a given direction moves **all eligible blocks** in that direction simultaneously. Which blocks respond to a given swipe depends on each block's predefined direction — this is explained in detail in Section 4.2.

Input is disabled while any block animation is in progress, preventing accidental queued moves.

---

## 4. Game Elements

### 4.1 Element A — The Board

Element A is the static playing field on which the puzzle takes place. It is composed of a collection of adjoining squares arranged in a grid — similar in appearance to a chessboard, but not necessarily rectangular in shape.

**Shape flexibility.** The board can be any shape: a 4×4 square, a narrow 2×5 strip, an L-shape, a cross, or any other configuration of connected squares. Individual squares may also be missing from the interior of the grid, creating holes the player must navigate around.

**Rendering.** The board is always centered on the screen. The size of each individual square — referred to throughout the codebase as `Value_A` — is calculated dynamically at load time so that the entire board fits on screen with a 10% margin on all sides. This means a small 3×3 board will have larger squares than a large 7×7 board. `Value_A` is returned by the board's instantiation method and shared with all other game systems.

The squares are visually delimited at all times. A subtle alternating color pattern (like a chessboard) helps the player read the grid clearly.

**Data format.** The board is defined in the level JSON file as an array of square positions using integer grid coordinates:

```json
"A": [
  {"pos_x": 0, "pos_y": 0},
  {"pos_x": 1, "pos_y": 0},
  {"pos_x": 0, "pos_y": 1}
]
```

Only squares present in this array exist on the board. Any grid position not listed is treated as empty (missing).

---

### 4.2 Element B — The Blocks

Element B refers to the movable colored blocks that the player manipulates. There can be multiple B elements per level, each defined independently.

**Shape.** Like Element A, a B block can span multiple squares. Its shape is defined as an array of squares relative to its own origin point. A 1×1 block has one square; an L-shaped block might have three. All squares of a B block share the same color and move together as a single unit.

**Size.** Each square of a B block is exactly the same size as an A square (`Value_A`), so blocks align perfectly with the board grid.

**Color.** Each B block is assigned a unique color at load time based on its ID. Colors are defined in the project and mapped to block IDs when the level is loaded — they are not stored in the level JSON. This keeps level data clean and allows the color scheme to be updated without touching level files.

**Direction.** Each B block has a fixed, predefined movement direction: left, right, up, or down. This direction never changes during gameplay. A directional arrow is rendered on the block so the player always knows which way it will move.

**Target.** Each B block has a designated target position on the board. The target is highlighted on the board using a muted version of the block's color, making it immediately clear where each block needs to end up.

**Data format.** A B block is defined in the level JSON with its shape, starting position, direction, and target:

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

- `squares` — the block's shape, defined relative to its own origin
- `origin_x / origin_y` — where the block's origin is placed on the A grid at the start of the level
- `target_origin_x / target_origin_y` — where the block's origin must be for the level to be won

---

## 5. Game Rules & Logic

### 5.1 Movement

When the player swipes in a direction, every B block whose predefined direction matches the swipe direction **moves one square** in that direction. All other blocks remain stationary.

For example: if the player swipes right, only blocks with `dir: "right"` will attempt to move. Blocks with any other direction are unaffected.

Movement is animated with a smooth slide. The animation completes before input is accepted again.

---

### 5.2 Blocking

A B block cannot move through or onto another B block. If a block's next position would overlap with a square already occupied by another block, that block **does not move** on that swipe — it stays in place.

**Chain blocking.** If two blocks share the same direction and are aligned in that direction, and the front block is blocked (by another block, a boundary, or a missing square), the back block also stops — even if the square it would move into is free. Blocking propagates through the entire chain. No block moves unless every block ahead of it in the movement direction can also move.

Blocking is intentional by design. Many puzzles require the player to use one block to stop another from overshooting its target. For example: if two blocks both move right, positioning one block to the right of the other will prevent the second from moving further.

Blocks do not push each other. A blocked block simply stays where it is.

---

### 5.3 Invalid Moves

A move is considered invalid if, after applying the movement, **any square of the moving block** would land on either:

- A position **outside the outer boundary** of the A grid, or
- A **missing square** within the A grid (a hole in the board)

When an invalid move is detected, the following happens:

1. A visual warning is displayed (e.g. a brief shake or flash on the offending block)
2. The block is immediately snapped back to its previous position (undo)
3. The level continues — there is no fail state

This applies to multi-square blocks as well: if *any* square of the block would land in an invalid position, the entire block is undone.

---

### 5.4 Win Condition

The level is won the instant **all B blocks are simultaneously on their target positions**. This is checked after every move completes.

When the win condition is met:
1. A win animation plays (e.g. blocks pulse or glow)
2. The next level is automatically unlocked
3. The game transitions to the next level

There is no confirmation step. The win is detected and acted upon immediately.

---

### 5.5 Reset

The player can reset the current level at any time using the reset button. When triggered, all B blocks animate smoothly back to their starting positions simultaneously. The same animation principles that apply to normal movement apply to the reset — nothing snaps or jumps.

There is no move counter. The game tracks no record of how many moves the player used, and no score or rating is assigned at the end of a level. The only measure of success is solving the puzzle.

---

## 6. Level Structure

### 6.1 Level Progression

Levels are played in sequence. Each time a level is completed, the next level is automatically unlocked and presented to the player. There is no way to skip ahead. Progress is saved to disk and persists between sessions.

**Level design constraints.** All levels must adhere to the following rules at design time:

- Every level must be provably solvable before shipping
- No B block's target position may overlap with any other B block's starting position
- No two B blocks may share the same starting position
- Every B block must have a clear path to its target given the correct sequence of moves

---

### 6.2 JSON Format

Each level is stored as a separate JSON file (e.g. `level_001.json`). The file defines:

| Field | Type | Description |
|---|---|---|
| `level` | Integer | The level number |
| `A` | Array | List of valid board squares as `{pos_x, pos_y}` objects |
| `B` | Array | List of block definitions (see below) |

Each block in the `B` array contains:

| Field | Type | Description |
|---|---|---|
| `id` | String | Unique identifier (e.g. "B1", "B2") — also used to assign color at load time |
| `dir` | String | Movement direction: `"left"`, `"right"`, `"up"`, or `"down"` |
| `squares` | Array | Block shape as `{pos_x, pos_y}` offsets relative to origin |
| `origin_x` | Integer | Starting column on the A grid |
| `origin_y` | Integer | Starting row on the A grid |
| `target_origin_x` | Integer | Target column on the A grid |
| `target_origin_y` | Integer | Target row on the A grid |

---

### 6.3 Full Level Example

The following example defines a level with an irregular 4×4 board (missing corners at top-right and bottom-left) and two blocks:

- **B1** (blue) starts at the left edge of row 1 and must slide right to the far end of the same row
- **B2** (coral) starts at column 2 of row 0 and must slide down to row 3

The intended solution is: swipe **down** three times (moving B2 to its target), then swipe **right** three times (moving B1 to its target). Solving in reverse order causes B1 to block B2's path mid-route.

```json
{
  "level": 1,
  "A": [
    {"pos_x": 0, "pos_y": 0},
    {"pos_x": 1, "pos_y": 0},
    {"pos_x": 2, "pos_y": 0},
    {"pos_x": 0, "pos_y": 1},
    {"pos_x": 1, "pos_y": 1},
    {"pos_x": 2, "pos_y": 1},
    {"pos_x": 3, "pos_y": 1},
    {"pos_x": 0, "pos_y": 2},
    {"pos_x": 1, "pos_y": 2},
    {"pos_x": 2, "pos_y": 2},
    {"pos_x": 3, "pos_y": 2},
    {"pos_x": 1, "pos_y": 3},
    {"pos_x": 2, "pos_y": 3},
    {"pos_x": 3, "pos_y": 3}
  ],
  "B": [
    {
      "id": "B1",
      "dir": "right",
      "squares": [{"pos_x": 0, "pos_y": 0}],
      "origin_x": 0,
      "origin_y": 1,
      "target_origin_x": 3,
      "target_origin_y": 1
    },
    {
      "id": "B2",
      "dir": "down",
      "squares": [{"pos_x": 0, "pos_y": 0}],
      "origin_x": 2,
      "origin_y": 0,
      "target_origin_x": 2,
      "target_origin_y": 3
    }
  ]
}
```

---

## 7. Visual Design

Daxtle uses a minimalist aesthetic throughout. The visual language should feel clean, calm, and deliberate — never cluttered or overly decorative.

**Color palette.** The board uses a subtle two-tone alternating pattern (like a muted chessboard) to help the player read the grid. Each B block is assigned a unique color at load time. Target zones are integrated directly into the board pattern — the square that represents a target replaces its normal chessboard tone with a muted, translucent tint of the corresponding block's color. This keeps the target feeling like a natural part of the board rather than a separate UI element placed on top of it.

**Typography.** Minimal. Level numbers and any UI labels use a clean sans-serif typeface at a small, unobtrusive size.

**Animations.** All block movements are smoothly interpolated (Tween-based). Invalid moves produce a brief shake on the offending block — enough to communicate the error without feeling punishing. The reset animation returns all blocks to their starting positions simultaneously using the same smooth interpolation as normal movement.

**Win animation.** When the level is solved, all B blocks pulse with a rhythmic glow simultaneously, then fade out together. The board fades out shortly after. The transition to the next level begins once the fade completes.

**Level initialization.** When a level loads, elements appear in the following sequence:

1. The board (Element A) fades or scales in as a whole
2. After the board settles, each B block slides in from just above its starting position, one by one, with a small stagger delay between them
3. The directional arrow on each block fades in last, after the block has landed

Player input is disabled throughout the initialization sequence and for a brief moment after the last block appears, preventing accidental swipes during the entrance animation.

**Layout.** The board is always centered on screen. No UI elements overlap the playing area.

---

## 8. Audio Design

Audio should reinforce the calm, meditative feel of the game. Nothing loud, sudden, or jarring.

- **Background music** — a soft, looping ambient track that plays throughout gameplay
- **Slide sound** — a subtle, satisfying sound when a block moves successfully
- **Invalid move sound** — a gentle, non-alarming tone indicating the move was undone
- **Win sound** — a warm, resolving chord or chime when a level is completed

All audio should be restrained. The game should be playable in a quiet environment without ever feeling intrusive.

---

## 9. MVP Scope

The following defines what is included in the initial MVP release:

| In scope | Out of scope |
|---|---|
| iOS and Android export | Tablet-specific layouts |
| 10 hand-crafted levels | Level editor |
| Portrait orientation | Landscape orientation |
| Level-based progression | Freeplay or endless mode |
| Per-session progress save | Cloud save / sync |
| Reset button (restart level) | Move counter or hints system |
| Basic ambient audio | Music selection or audio settings |
| Minimal UI | Animations beyond core gameplay |
| Business model | Defined in separate document |

The MVP establishes the complete core game loop. All elements described in this document are required for MVP. Features listed as out of scope may be considered for post-launch updates.

---

*Document version 1.0 — Daxtle MVP*
*Last updated: March 2026*
