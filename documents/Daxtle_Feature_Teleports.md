# Daxtle — Feature Proposal: Teleport Pairs
**Status: Candidate — not yet in scope**

---

## 1. Overview

Teleport pairs are two specially marked squares on Element A that are linked together. When a B block slides onto one square of a pair, it is instantly transported to the other square, continuing its movement from there if space permits.

Teleport pairs introduce **non-Euclidean routing** into Daxtle — a block can effectively travel from one part of the board to a completely disconnected part in a single move. This creates puzzle types that are genuinely impossible to design with the existing mechanic alone, and produces the strongest "aha" moments of any proposed feature.

---

## 2. Behavior

**Entry and exit:**
- When a B block moves onto a teleport entry square, it is instantly relocated to the paired exit square
- The block retains its direction and continues moving if the square ahead of the exit is valid and clear
- If the exit square is occupied (by another B block or a C block), the teleport is treated as an invalid move — the entering block shakes and returns

**Directionality:**
- Teleport pairs are bidirectional by default — a block can enter from either square and exit from the other
- Optional: directional teleports (one-way) can be indicated visually with an arrow on the entry square; this is a level design choice, not a system constraint

**Push interaction:**
- If a push chain reaches a teleport square, the entire chain teleports together — each block in the chain exits from the paired square in sequence
- If any block in the chain cannot exit (exit blocked), the entire chain is invalid

**Multiple pairs:**
- A level can contain more than one teleport pair
- Each pair is independent — entering one pair always exits at its specific partner, never at another pair's square

---

## 3. Visual Design

Teleport pairs should be immediately recognizable as linked without requiring explanation. The visual language should feel consistent with the board aesthetic while clearly communicating "these two squares are connected."

Suggested approach:
- Each square of a pair is tinted with the same unique color, distinct from any B block color
- A subtle symbol or shape (e.g. a small circle or diamond) centered on each teleport square
- The tint is integrated into the board surface, similar to how target zones are rendered — not a floating UI element
- Pairs use different colors from each other if multiple pairs exist on the same board (pair 1 = one tint, pair 2 = another tint)
- Colors sourced from the active theme's teleport palette, defined separately from block colors

On activation, a brief visual flash or pulse on both squares simultaneously reinforces the connection — the player sees both squares react at the same moment.

---

## 4. Level Design Implications

Teleport pairs are the most powerful design tool in this proposal. Used well, they create puzzles that feel magical — a block disappears from one side of the board and reappears on the other, completely changing what's possible.

**What they enable:**

- **Shortcutting** — a block that would need many moves to travel across the board can teleport directly, but only if positioned correctly first
- **Cross-board dependencies** — solving one side of the board affects the other side through shared teleport access
- **Misdirection** — the player assumes a block must travel a long path; the teleport reveals a shortcut they hadn't considered
- **Exit blocking puzzles** — a B block must be cleared from a teleport exit before another block can use the pair, adding sequencing constraints
- **Push-through teleports** — a B block pushes another B block into a teleport, teleporting the pushed block to an unexpected position

**Design constraints:**
- Teleport exit squares must not be a B block's starting position
- Teleport exit squares should not be adjacent to board boundaries in a direction that would cause an immediately invalid exit
- The level designer must verify that teleport pairs do not create unreachable states from the initial configuration — the BFS dead-state detector must account for teleport traversal to remain accurate

---

## 5. JSON Format Extension

Teleport pairs are added as a new top-level array in the level JSON.

**New field:**

| Field | Type | Description |
|---|---|---|
| `T` | Array | List of teleport pair definitions |

**Each entry in the T array:**

| Field | Type | Description |
|---|---|---|
| `id` | String | Pair identifier (e.g. "T1", "T2") — used for visual color assignment |
| `a_x / a_y` | Integer | Grid position of the first square in the pair |
| `b_x / b_y` | Integer | Grid position of the second square in the pair |
| `one_way` | Boolean | Optional. If true, only `a` is an entry point, `b` is exit only. Default: false |

**Example:**

```json
{
  "level": 25,
  "A": [...],
  "B": [...],
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
}
```

Levels without teleport pairs simply omit the `T` array — fully backward compatible with all existing levels.

---

## 6. Implementation Notes

**Movement system:** `Movement.resolve()` must be extended to check whether a block's destination square is a teleport entry. If it is, the block's resolved position becomes the paired exit square. The movement continues from the exit square in the block's direction if that next square is valid and unoccupied.

**Continuation after teleport:** After teleporting, the block effectively "re-enters" the movement resolution from the exit square. This may trigger further teleports if the exit square is itself a teleport entry — care must be taken to detect and break infinite teleport loops (a block cannot teleport more than once per move).

**Dead-state BFS:** `_bfs_sim_move()` must simulate teleport traversal. When a block moves onto a teleport square, its simulated position should jump to the exit square before continuing. Without this, the dead-state detector will produce false positives on levels that are solvable only via teleports.

**Rendering:** Teleport squares are rendered as part of the board draw pass in `Board.gd`, similar to target zones. A new `_teleport_colors` dictionary (analogous to `_target_colors`) maps grid positions to their pair tint color.

**Activation effect:** A brief simultaneous pulse on both squares of a pair when a block teleports. Implemented as a short Tween on both squares' cell scale or color modulate, triggered from `Game.gd` after a teleport is resolved.

**Level loader:** `LevelLoader.get_teleport_pairs()` static method to parse the `T` array, returning an array of a new `TeleportPairData` class.

---

## 7. Suggested Introduction Point

Teleport pairs are conceptually simple but spatially surprising. They should be introduced after the player is fully comfortable with push chains and irregular boards — not before.

Suggested placement: first appearance around level 40–50 in a hypothetical 100-level game. The first teleport level should use a single pair on a simple board with one B block, so the player can discover the mechanic with no other variables in play.

A brief visual tutorial hint (an animated pulse between the two paired squares before the first move) may help players discover the mechanic without explicit instruction text.

---

*Feature proposal — not yet scheduled for implementation*
*Last updated: March 2026*
