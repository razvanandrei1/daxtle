# Daxtle — Feature Proposal: Element C (Fixed Blocks)
**Status: Candidate — not yet in scope**

---

## 1. Overview

Element C is a static, immovable block that sits on the board and cannot be moved or pushed by any means. It acts as a permanent structural obstacle that the player must route around when solving the puzzle.

Element C introduces **irreversible spatial constraints** into level design — unlike the board shape itself, which is fixed and immediately visible, Element C blocks can be placed anywhere on valid board squares, creating internal walls that subdivide the playing field in non-obvious ways.

---

## 2. Behavior

- Element C occupies one or more squares on Element A, exactly like Element B
- It **cannot be moved** by swipes — it has no direction and does not respond to any player input
- It **cannot be pushed** by a moving Element B block — if a B block's push chain reaches a C block, the entire chain is treated as an invalid move and all involved B blocks shake and return
- It is **always visible** from the start of the level — it is never hidden or revealed mid-puzzle
- It **does not count** toward the win condition — only B blocks on their targets win the level

---

## 3. Visual Design

Element C should be visually distinct from both Element A (the board) and Element B (the colored blocks) while still feeling like it belongs to the same design language.

Suggested approach:
- Same square size as Element A (`Value_A`)
- A neutral, dark tone — significantly darker than the board surface but without a color tint
- No directional arrow (it has no direction)
- Slightly inset from the cell edges, similar to Element B, to maintain visual consistency
- Optionally: a subtle texture or cross-hatch pattern to reinforce its "fixed" quality

The color should not conflict with any B block color from the active theme. A dark charcoal or deep gray works across all three existing themes (WARM_SAND, COOL_SLATE, DARK_CHARCOAL).

---

## 4. Level Design Implications

Element C dramatically expands the design space without adding complexity for the player to learn. The rule is immediately intuitive — it looks solid, it is solid.

**What it enables:**

- **Corridor puzzles** — C blocks placed to create narrow channels that force blocks to travel in a specific order
- **Dead-end traps** — C blocks that make certain positions unreachable unless approached from the correct direction
- **Blocking without push** — placing a C block adjacent to a B block's target prevents overshooting without relying on another B block to stop it
- **Board subdivision** — irregular C block clusters that split the board into distinct zones, each requiring independent solution

**Design constraint:**
The level designer must ensure that no C block placement creates a dead state from the initial position. The existing BFS dead-state detector will catch this automatically during development if integrated with C block awareness.

---

## 5. JSON Format Extension

Element C is added as a new top-level array in the level JSON, alongside `A` and `B`.

**New field:**

| Field | Type | Description |
|---|---|---|
| `C` | Array | List of fixed block definitions |

**Each entry in the C array:**

| Field | Type | Description |
|---|---|---|
| `squares` | Array | Block shape as `{pos_x, pos_y}` offsets relative to origin |
| `origin_x` | Integer | Column on the A grid |
| `origin_y` | Integer | Row on the A grid |

Element C has no `id`, no `dir`, and no `target` — it is purely positional.

**Example:**

```json
{
  "level": 12,
  "A": [...],
  "B": [...],
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
}
```

Levels without any C blocks simply omit the `C` array — fully backward compatible with all existing levels.

---

## 6. Implementation Notes

**Movement system:** `Movement.resolve()` must be updated to treat C block cells as blocked during push propagation. C block cells should be added to the `board_set` equivalent used for wall checks, or handled as a separate occupied-cells set checked before any movement is applied.

**Dead-state BFS:** The BFS simulator in `_bfs_sim_move()` must also be updated to account for C block positions. C block cells are permanently occupied and should be treated as non-enterable for all B blocks.

**Rendering:** A new `FixedBlock` scene and script (`scripts/entities/FixedBlock.gd`) following the same setup pattern as `Block.gd`. Color sourced from `GameTheme` rather than `BlockColors`.

**Level loader:** `LevelLoader.get_fixed_blocks()` static method to parse the `C` array, returning an array of a new `FixedBlockData` class (analogous to `BlockData`).

**Intro animation:** C blocks should appear as part of the board initialization wave — scaling in alongside the board squares rather than after the B blocks, reinforcing that they are part of the environment rather than movable pieces.

---

## 7. Suggested Introduction Point

Element C should not appear in the first content expansion. Players need time to fully internalize the push mechanic before a new constraint is introduced.

Suggested placement: first appearance around level 30–35 in a hypothetical 100-level game, introduced alone on a simple board before being combined with complex push chains.

---

*Feature proposal — not yet scheduled for implementation*
*Last updated: March 2026*
