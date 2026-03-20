# Daxtle — Level Design Guidelines
**Version 1.0**

---

## Table of Contents

1. [Design Philosophy](#1-design-philosophy)
2. [The Signal-to-Noise Rule](#2-the-signal-to-noise-rule)
3. [Element Rules](#3-element-rules)
   - 3.1 [Element A — The Board](#31-element-a--the-board)
   - 3.2 [Element B — Blocks](#32-element-b--blocks)
   - 3.3 [Missing Squares (Holes)](#33-missing-squares-holes)
   - 3.4 [Element C — Fixed Blocks](#34-element-c--fixed-blocks)
   - 3.5 [Teleport Pairs](#35-teleport-pairs)
4. [Solution Rules](#4-solution-rules)
5. [Design Intention](#5-design-intention)
6. [Difficulty & Progression](#6-difficulty--progression)
7. [Mechanic Introduction Rules](#7-mechanic-introduction-rules)
8. [Verification Checklist](#8-verification-checklist)

---

## 1. Design Philosophy

Every element in a Daxtle level must earn its place. The player reads the board before making a move — every block, every hole, every fixed obstacle communicates something. An element that communicates nothing is noise, and noise erodes the player's ability to reason clearly about the puzzle.

The guiding principle is: **if an element can be removed without changing the puzzle experience, remove it.**

This applies to everything — the number of blocks, the shape of the board, the placement of holes, the presence of fixed blocks, and the placement of teleports. A level that feels clean and inevitable is a well-designed level. A level that feels cluttered or arbitrary is not.

---

## 2. The Signal-to-Noise Rule

Every element in a level must be part of the solution path. This means:

- The player must need to think about it at some point during the solve
- Its presence must change how the puzzle is approached, even if it is not physically interacted with during the optimal solution
- Its absence would either make the puzzle unsolvable or trivially easier

**What counts as noise and must be removed:**

- Empty A squares that no block ever passes through, is blocked by, or routes around
- Holes that lie entirely outside the path of every block in every solution sequence
- C blocks (fixed blocks) that no block ever reaches or needs to avoid
- Teleport pairs where neither square is ever entered during any solution

**What is not noise, even if unused in the optimal solution:**

- An empty square that the player must consider as a potential routing option before dismissing it
- A hole that creates a constraint the player must notice even if they route around it cleanly
- A C block that the player must mentally account for when planning, even if no block ever slides into it

The distinction is between elements that **actively shape thinking** and elements that are simply **present without effect**. When in doubt, ask: would a player noticing this element change how they approach the puzzle? If yes, it belongs. If no, remove it.

---

## 3. Element Rules

### 3.1 Element A — The Board

The board shape does not need to be the tightest possible fit around the solution, but every square must be relevant. A square is relevant if:

- A block passes through it during at least one valid solution
- It creates a boundary that constrains a block's movement
- It creates a routing decision — the player must consider whether to use it

A square that sits entirely isolated from all block paths, creates no boundary pressure, and requires no routing decision is irrelevant and should be removed.

**Practical test:** Remove the square mentally. If no block's path changes, no constraint changes, and no decision changes, the square does not belong.

Irregular board shapes are encouraged. A cross, L-shape, or T-shape can communicate the level's routing logic at a glance. The board shape is itself a design tool — use it to guide the player's eye toward the solution space.

---

### 3.2 Element B — Blocks

The number of B blocks must be the minimum required to create the intended puzzle experience. Every block must be strictly necessary — if removing a block leaves the puzzle still solvable with the same core challenge intact, that block should not be in the level.

**Each B block must:**
- Have a target that is reachable from its starting position given at least one valid solution sequence
- Interact with at least one other element (another block, a hole, a C block, a teleport, or the board boundary) during the solution
- Be necessary — its absence must either make the puzzle unsolvable or remove the intended challenge entirely

**A B block is noise if:**
- It can be guided to its target independently of all other blocks with no sequencing constraint
- Its presence does not affect the path or behavior of any other block
- The level is equally solvable and equally challenging without it

---

### 3.3 Missing Squares (Holes)

A hole is relevant if it meaningfully constrains at least one block's routing options. A hole that sits in a region no block ever approaches is invisible to the player during play and adds nothing.

**A hole earns its place if:**
- It forces a block to take a different route than it would on a complete board
- It creates an invalid move risk that the player must actively avoid
- It creates a dead state risk if the player moves in the wrong order
- It separates two regions of the board in a way that affects routing decisions

**A hole is noise if:**
- No block's path ever comes within one square of it
- It could be filled in and no solution would change
- It exists only to make the board shape look more interesting visually

A hole should never be placed purely for aesthetic reasons. If the board shape needs visual interest, achieve it through the overall board outline rather than interior holes.

---

### 3.4 Element C — Fixed Blocks

A C block (fixed block) is relevant if at least one B block's path, routing decision, or push chain is directly affected by its presence.

**A C block earns its place if:**
- A B block's movement is stopped by it at some point during the solution
- It prevents a push chain from overshooting a target
- It closes off a routing option that would otherwise trivialize the puzzle
- A B block must route around it to reach its target

**A C block is noise if:**
- No B block ever slides into it or is stopped by it
- It occupies a region of the board that no block ever reaches
- Removing it would not change any block's path or any solution sequence

C blocks are structural — they define walls within the board. Every wall should have a reason to exist.

---

### 3.5 Teleport Pairs

A teleport pair is relevant if using it is either required for the solution or represents a meaningful alternative routing option that the player must consider.

**A teleport pair earns its place if:**
- At least one block must pass through it in every valid solution, or
- It offers an alternative path that the player must evaluate before choosing the correct approach

**A teleport pair is noise if:**
- Neither square is ever entered during any solution sequence
- It exists in a region of the board that no block ever reaches
- Using it always leads to an invalid state, making it a red herring with no reasoning value

Note: a teleport pair that functions as a deliberate red herring — one the player must consider and consciously reject — is acceptable if it genuinely contributes to the puzzle's tension. A teleport pair that is simply invisible to the player during the solve is not acceptable.

---

## 4. Solution Rules

**Solvability.** Every level must be provably solvable before shipping. A valid solution sequence must be identified and recorded by the designer.

**Multiple solutions.** Multiple valid solution sequences are acceptable. However, no alternative solution may trivialize the puzzle — all valid solutions should require roughly the same depth of reasoning. A level where one solution takes 3 moves and another takes 12 is poorly balanced and should be redesigned.

**Dead states.** The game's BFS dead-state detector will catch unsolvable states automatically, but the designer should also verify manually that the level does not have a single obvious wrong move that immediately creates a dead state on the first swipe. Early dead states feel punishing even with auto-reset.

**Starting position overlap.** No B block's starting position may overlap with any other B block's target position. No two B blocks may share the same starting position.

**Target reachability.** Every B block's target must be reachable in its movement direction relative to its starting position, accounting for the push mechanic and board constraints.

---

## 5. Design Intention

Every level must have exactly one design intention — a single mechanic idea or insight that the level is built to teach, test, or celebrate.

The design intention is the answer to the question: *"What does the player learn or experience in this level that they haven't experienced before, or haven't experienced in quite this way?"*

**Examples of valid design intentions:**
- "The player must use one block to stop another from overshooting its target"
- "The player must clear a path before a push chain can complete"
- "The player must route around a hole that splits the board into two zones"
- "The player must use a teleport to reach a target that is otherwise unreachable"
- "The player must sequence three blocks in strict order"

A level with no clear design intention is a random arrangement. A level with two competing design intentions is confusing. **One intention per level.**

The design intention should be written down before the level is built, not reverse-engineered after. If you cannot state the intention in one sentence, the level is not ready to be built.

---

## 6. Difficulty & Progression

**Difficulty measurement.** Difficulty is assessed by the designer's subjective judgment of how hard the solution is to discover — not by move count, block count, or any mechanical metric. A 3-move level can be harder than a 12-move level if the key insight is less obvious.

Factors that increase subjective difficulty:
- More blocks requiring strict sequencing
- Push chains involving 3 or more blocks
- Solutions that require moving blocks away from their targets before moving toward them
- Holes or C blocks that create non-obvious constraints
- Teleport pairs that invert spatial expectations

**Progression across levels.** Difficulty should generally increase across the level sequence. Occasional easier levels are acceptable and desirable as palette cleansers — a short, satisfying level after a hard one restores the player's confidence and sense of flow.

**Guidelines:**
- Never place two very hard levels back to back
- An easier level after a difficulty spike is a feature, not a flaw
- The last level of any difficulty tier should feel like a satisfying culmination, not an exhausting slog
- The first level of a new mechanic chapter always resets difficulty to easy, regardless of where it sits in the sequence

---

## 7. Mechanic Introduction Rules

Every new mechanic must be introduced in isolation before it is combined with other mechanics or with complexity.

**The introduction level for any new mechanic must:**
- Contain the minimum number of blocks needed to demonstrate the mechanic — ideally one or two
- Use a simple, regular board shape with no holes and no other special elements
- Have an obvious solution once the mechanic is understood
- Feel like a moment of discovery, not a test

**Combination rules:**
- A mechanic may not be combined with another non-standard mechanic until it has appeared in at least two levels on its own
- Holes may be combined with any mechanic after their own introduction
- C blocks and teleports must each have at least three isolated levels before they appear together in the same level

**Mechanic chapters.** When a new mechanic is introduced, it defines the start of a new chapter in the level sequence. The chapter begins with one or two easy introduction levels and progresses through increasing complexity before the next mechanic is introduced.

| Mechanic | Minimum isolated levels before combining |
|---|---|
| Push (Element B) | Built into core — always present |
| Holes (missing squares) | 2 isolated levels |
| Element C (fixed blocks) | 3 isolated levels |
| Teleport pairs | 3 isolated levels |
| C blocks + holes combined | After both have 3 isolated levels each |
| Teleports + C blocks combined | After both have 3 isolated levels each |

---

## 8. Verification Checklist

Before a level is considered complete and ready to ship, the designer must confirm every item on this checklist.

**Solvability**
- [ ] A valid solution sequence has been identified and written down
- [ ] The BFS dead-state detector confirms the level is solvable
- [ ] No single first move creates an immediate dead state

**Signal-to-noise**
- [ ] Every B block is strictly necessary — removing any one makes the puzzle trivially easier or unsolvable
- [ ] Every A square is relevant — no square is completely unreachable and inconsequential
- [ ] Every hole affects at least one block's routing or creates a meaningful constraint
- [ ] Every C block is reachable or creates a constraint that affects at least one block's path
- [ ] Every teleport square is either used in a solution or forces a meaningful routing consideration

**Solution quality**
- [ ] If multiple solutions exist, none trivializes the puzzle
- [ ] No alternative solution is drastically shorter or easier than the intended solution
- [ ] No B block's starting position overlaps any other block's target position

**Design intention**
- [ ] The level's design intention has been stated in one sentence
- [ ] Every element in the level serves that intention
- [ ] No element serves a different intention that competes with the primary one

**Mechanic introduction**
- [ ] If this level introduces a new mechanic, it does so in isolation
- [ ] If this level combines mechanics, both have appeared in sufficient isolated levels prior

**Difficulty**
- [ ] The level's difficulty is appropriate for its position in the sequence
- [ ] If this follows a hard level, it is acceptable as a palette cleanser
- [ ] If this precedes a new mechanic chapter, it does not end on excessive difficulty

---

*Document version 1.0 — Daxtle Level Design Guidelines*
*Last updated: March 2026*
