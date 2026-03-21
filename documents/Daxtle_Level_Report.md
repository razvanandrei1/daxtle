# Daxtle — Level Report

## Difficulty Scale
- **1/10** — Tutorial, no thinking required
- **3/10** — Easy, one key insight
- **5/10** — Medium, multiple steps with ordering
- **7/10** — Hard, multiple constraints and traps
- **9/10** — Expert, deep multi-phase planning

---

## Level 1 — "First Step"
- **Grid:** 3x1 | **Blocks:** 1 | **Swipes:** ~2
- **Difficulty:** 1/10
- **Mechanics:** Basic right movement
- **Observation:** Pure tutorial. Teaches swipe = move. Message guides the player.

## Level 2 — "Two Directions"
- **Grid:** 3x3 | **Blocks:** 2 | **Swipes:** ~4
- **Difficulty:** 1/10
- **Mechanics:** Two blocks, opposite directions (down + up), same color
- **Observation:** Teaches that multiple blocks move on the same swipe. No ordering needed.

## Level 3 — "Synchronized"
- **Grid:** 4x4 | **Blocks:** 4 | **Swipes:** ~4
- **Difficulty:** 2/10
- **Mechanics:** Four same-color blocks, right + left synchronized
- **Observation:** Teaches simultaneous movement of same-direction blocks. All solve in ~4 swipes.

## Level 4 — "The Cargo"
- **Grid:** 6x1 | **Blocks:** 2 (1 cargo) | **Swipes:** ~3
- **Difficulty:** 2/10
- **Mechanics:** Cargo block (dir: "none"), push mechanic
- **Observation:** Introduces cargo — blocks that can't move on their own. Player discovers push by swiping right.

## Level 5 — "Order Matters"
- **Grid:** 3x3 | **Blocks:** 2 | **Swipes:** ~4
- **Difficulty:** 3/10
- **Mechanics:** Move ordering, potential stuck state
- **Observation:** First level where wrong move order leads to stuck. Teaches the reset mechanic (double-tap). Message hints at ordering.

## Level 6 — "Two Colors"
- **Grid:** 3x3 | **Blocks:** 2 | **Swipes:** ~4
- **Difficulty:** 2/10
- **Mechanics:** Multiple block colors, each with own target
- **Observation:** Introduces the second color. Simple but teaches color-matching.

## Level 7 — "Chain Push"
- **Grid:** 3x3 | **Blocks:** 2 | **Swipes:** ~4
- **Difficulty:** 3/10
- **Mechanics:** Mandatory push — one block pushes another to target
- **Observation:** First mandatory push. The player must realize a block can't reach its target alone.

## Level 8 — "Two-Direction Push"
- **Grid:** 4x3 | **Blocks:** 3 (1 cargo) | **Swipes:** ~5
- **Difficulty:** 4/10
- **Mechanics:** Cargo pushed from two directions, two colors
- **Observation:** Cargo needs help from both a right-block and a down-block. Introduces multi-step push planning.

## Level 9 — "Portal Introduction"
- **Grid:** 4x2 | **Blocks:** 1 | **Teleports:** 1 | **Swipes:** ~5
- **Difficulty:** 2/10
- **Mechanics:** Teleport portal (block enters, exits on other side)
- **Observation:** Pure teleport tutorial. One block, one portal, straightforward path. Message explains portals.

## Level 10 — "Portal + Ordering"
- **Grid:** 4x3 | **Blocks:** 2 | **Teleports:** 1 | **Swipes:** ~5
- **Difficulty:** 3/10
- **Mechanics:** Teleport + move ordering (down before right)
- **Observation:** First teleport puzzle with a constraint. B2 must clear the path before B1 teleports. Last level with a tutorial message ("Now let's see how you do it!").

## Level 11 — "The Wall"
- **Grid:** 4x3 | **Blocks:** 3 | **Swipes:** 3
- **Difficulty:** 4/10
- **Mechanics:** Block as temporary wall, ordering dependency chain
- **Observation:** Introduces the wall concept. B2 walls B1, B3 blocks B2. Down must be last. Three colors, clean 3-swipe solution.

## Level 12 — "Mandatory Push"
- **Grid:** 3x4 | **Blocks:** 4 (2 teal, 2 coral) | **Swipes:** 3
- **Difficulty:** 5/10
- **Mechanics:** Mandatory push, dual-color pairs, chain push
- **Observation:** B1 pushes B3 which pushes B2 in a triple chain. "Up first" is the natural trap. Only 3 swipes but the chain push is non-obvious. B3 starts on a red target (visual tension).

## Level 13 — "Teleport Cascade"
- **Grid:** 3x3 | **Blocks:** 3 | **Teleports:** 1 | **Swipes:** 6
- **Difficulty:** 5/10
- **Mechanics:** Teleport + cascading dependencies (B3 blocks B2 blocks B1's teleport)
- **Observation:** Three blocks, three dependencies. B3 must clear B2's target, B2 must clear B1's teleport exit. Compact board with deep ordering.

## Level 14 — "Two-Direction Cargo"
- **Grid:** 4x4 | **Blocks:** 4 (1 cargo) | **Swipes:** 8
- **Difficulty:** 6/10
- **Mechanics:** Cargo pushed down then left, B3 dual role (pusher + wall), strict phase ordering
- **Observation:** Three phases: lefts (clear path) → downs (push cargo) → rights (B1 to target). Extra down overshoots. Wrong first move pushes cargo sideways. Significant step up in complexity.

## Level 15 — "The Gauntlet"
- **Grid:** 5x4 (irregular) | **Blocks:** 5 (1 cargo) | **Swipes:** 9
- **Difficulty:** 6/10
- **Mechanics:** Shared down direction (B3+B4), wall dependency, hole-constrained movement
- **Observation:** B3 and B4 share "down" — every down moves both. B4 walls B1 but must eventually leave. Hole at (0,1) constrains B2. Rights must precede downs.

## Level 16 — "Portal Push"
- **Grid:** 4x4 | **Blocks:** 5 (1 cargo) | **Teleports:** 1 (one-way) | **Swipes:** 7
- **Difficulty:** 7/10
- **Mechanics:** Cargo pushed into portal, two blocks sharing same portal, multi-constraint ordering
- **Observation:** First level where cargo teleports through a portal. B4 also uses the same portal on the first down — a "wow" moment. Three constraints: R before D, 3L before 2nd D, portal sharing.

## Level 17 — "Chain Separation"
- **Grid:** 5x3 | **Blocks:** 5 (2 cargo) | **Swipes:** 5
- **Difficulty:** 6/10
- **Mechanics:** Triple chain push, two-direction cargo (right → down → left), strict 3-phase ordering
- **Observation:** Bridge level between 16 and 18. Both cargos start on wrong-color targets (visual tension). One right chain-pushes both cargos apart, then each takes a different path. Three strict phases: R → D → L.

## Level 18 — "Crossing Assembly Lines"
- **Grid:** 5x5 (irregular, no cell at 4,1) | **Blocks:** 6 (2 cargo) | **Swipes:** 9
- **Difficulty:** 8/10
- **Mechanics:** Two crossing cargo paths, simultaneous down chains, 3-phase ordering with tight windows
- **Observation:** The hardest level. Two assembly lines cross: C1 goes right→down, C2 goes left→down. B2 and B4 push simultaneously on each down swipe, advancing both cargos. Multiple dead ends from wrong ordering. C2 starts on a wrong-color target.

---

## Overall Progression

```
Difficulty
  9 |
  8 |                                                          ●18
  7 |                                              ●16
  6 |                                   ●14  ●15        ●17
  5 |                         ●12 ●13
  4 |                   ●11
  3 |          ●5        ●10
  2 | ●1 ●2 ●3  ●4  ●6       ●9
  1 |
    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---
      1   2   3   4   5   6   7   8   9  10  11  12  13  14  15  16  17  18
```

**Mechanics introduction order:**
1-3: Movement basics → 4: Cargo → 5-6: Ordering + colors → 7-8: Push chains → 9-10: Teleports → 11-12: Wall/push strategy → 13: Teleport + cascading → 14: Multi-direction push → 15: Shared direction → 16: Portal push → 17-18: Multi-cargo

**Smooth ramps:** 1→6 (tutorial), 7→10 (intermediate), 11→14 (advanced), 15→18 (expert)

**Potential gap:** Level 14→15 is a noticeable jump (4x4 to 5x4, 4 blocks to 5, new irregular board concept). Could benefit from an intermediate level.
