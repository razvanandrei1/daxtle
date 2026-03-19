# Daxtle — MVP Task List

---

## PHASE 1 — Project Setup

- [x] **T01** Create new Godot 4 project, configure for mobile (iOS + Android)
- [x] **T02** Set portrait-only orientation in project settings
- [x] **T03** Define folder structure: `/scenes`, `/scripts`, `/levels`, `/assets`
- [x] **T04** Create placeholder scene tree: Main, Game, UI layers
- [x] **T05** Configure export presets for iOS and Android

---

## PHASE 2 — Element A (Board)

- [x] **T06** Write JSON parser to load level file and extract element A square positions
- [x] **T07** Calculate `Value_A` (square size) based on screen size, board dimensions, and 10% margin rule
- [x] **T08** Instantiate and render element A squares centered on screen using `Value_A`
- [x] **T09** ~~Apply chessboard alternating color pattern to A squares~~ — removed, board uses flat single surface color from active theme
- [x] **T10** Handle irregular board shapes (non-rectangular, missing squares)
- [x] **T11** Visually distinguish missing squares from valid squares (empty space, no render)
- [x] **T12** Return `Value_A` from instantiation for use by other systems

---

## PHASE 3 — Element B (Moving Blocks)

- [x] **T13** Write JSON parser to extract element B definitions (id, dir, squares, origin, target)
- [x] **T14** Instantiate element B blocks on element A using `Value_A` for sizing and placement
- [x] **T15** Assign block colors at load time based on block ID using a project-defined color palette
- [x] **T16** Render directional arrow on each B element indicating its movement direction
- [x] **T17** Support multi-square B element shapes (relative `squares` array + `origin` offset)
- [x] **T18** Highlight target zones on element A using a muted version of each B element's color

---

## PHASE 4 — Swipe Input

- [x] **T19** Implement swipe gesture detection (left, right, up, down) anywhere on screen
- [x] **T20** Set minimum swipe distance threshold to avoid accidental triggers
- [x] **T21** Disable input during animation (prevent queued swipes mid-slide)
- [x] **T22** Route swipe direction to movement system

---

## PHASE 5 — Movement System

- [x] **T23** Implement movement logic: on swipe, move all B elements whose `dir` matches the swipe direction by one square
- [x] **T24** Implement push mechanic: a moving B element pushes any block it collides with in the same direction by the same distance, propagating through chains
- [x] **T25** Implement boundary check: detect if move would place any square of B outside the A grid boundary
- [x] **T26** Implement missing square check: detect if move would place any square of B above a missing A square
- [x] **T27** Implement smooth slide animation for valid moves using Tween
- [x] **T28** Implement invalid move handling: all blocks in the chain shake and return (boundary or missing square)
- [x] **T29** Show invalid move feedback: brief spring-back shake animation on all offending blocks

---

## PHASE 6 — Win Condition

- [x] **T30** After each move, check if all B elements are on their respective target positions
- [x] **T31** Trigger win state immediately when last B element lands on its target
- [x] **T32** Implement win animation: all B blocks pulse with a rhythmic double-glow simultaneously, then fade out — board fades out shortly after
- [x] **T33** Transition to next level automatically after win animation completes

---

## PHASE 7 — Level Management

- [x] **T34** Define level JSON file naming convention (`level_001.json`, `level_002.json`, etc.)
- [x] **T35** Implement level loader: reads correct JSON file based on current level index
- [x] **T36** Implement level progression: load next level on win
- [ ] **T37** Persist current level progress (save to disk, survives app close)
- [ ] **T38** Create 10 MVP levels with increasing difficulty, each verified as passable

---

## PHASE 7B — Dead State Detection *(implemented beyond original scope)*

- [x] **T34B** Implement BFS-based dead state detector: after every valid move, check if the win state is still reachable from the current board position
- [x] **T35B** Implement dead state response: board shakes gently, then all blocks animate back to starting positions automatically
- [x] **T36B** Apply BFS state cap to keep detection fast and avoid false positives

---

## PHASE 8 — UI

- [ ] **T39** Design and implement minimal main menu (Play button)
- [x] **T40** Display current level number during gameplay
- [ ] **T41** Implement reset button — all B blocks animate smoothly back to their starting positions simultaneously (no snap)
- [ ] **T42** Implement back/menu button during gameplay
- [ ] **T43** Add level complete screen (minimal — next level prompt)

---

## PHASE 9 — Visual & Audio Polish

- [x] **T44** Finalize color palette: flat surface color for board, themed block colors, semi-transparent target tints — three full themes defined (WARM_SAND, COOL_SLATE, DARK_CHARCOAL)
- [x] **T45** Refine B element arrow design: filled triangle, darkened from block color, readable at all sizes
- [x] **T46** Implement level initialization animation: board squares appear in diagonal wave → B blocks scale up one by one with stagger → arrow fades in per block → brief input-disabled pause
- [ ] **T47** Source or create ambient background music (calm, looping, low-key)
- [ ] **T48** Add subtle sound effect for valid slide move
- [ ] **T49** Add distinct sound effect for invalid move / undo
- [ ] **T50** Add sound effect for win condition

---

## PHASE 10 — Testing & Export

- [ ] **T51** Test all movement edge cases: boundary, missing square, multi-square B elements, push chains
- [ ] **T52** Test all 10 levels end-to-end on device (iOS and Android)
- [ ] **T53** Test on multiple screen sizes and resolutions
- [ ] **T54** Profile performance — ensure smooth animations on low-end devices
- [ ] **T55** Export iOS build and test on device via TestFlight
- [ ] **T56** Export Android build and test on device

---

## PHASE 11 — Element C (Fixed Blocks) *(Post-MVP)*

> These tasks are scoped and ready but are not part of the MVP release. Implement after MVP is shipped and validated.

- [ ] **T57** Define `FixedBlockData` class (analogous to `BlockData`): stores shape and origin, no `id`, `dir`, or `target`
- [ ] **T58** Extend `LevelLoader` with `get_fixed_blocks()` static method to parse the optional `"C"` array from level JSON; omitting `"C"` must be backward compatible
- [ ] **T59** Create `FixedBlock` scene and `scripts/entities/FixedBlock.gd`: renders a neutral dark-colored rounded rectangle (no arrow), sized and positioned identically to B block squares
- [ ] **T60** Add C block color to `GameTheme` for all three themes (dark neutral tone, distinct from surface and all B block colors)
- [ ] **T61** Instantiate C blocks in `Game.gd` after board setup; store their occupied cells in a `_fixed_set` dictionary for fast lookup
- [ ] **T62** Update `Movement.resolve()` to treat C block cells as impassable — a push chain reaching a C cell is immediately invalid
- [ ] **T63** Update BFS dead-state simulator (`_bfs_sim_move()`) to treat C block cells as permanently occupied for all B block movement
- [ ] **T64** Integrate C blocks into the level initialization animation: C block squares scale up during the board wave (alongside A squares), before B blocks appear
- [ ] **T65** Update level design constraints documentation and verify all existing levels remain valid (no `"C"` array → no change in behavior)
- [ ] **T66** Author 3–5 test levels using C blocks to validate the mechanic and difficulty curve; verify each is solvable and no dead state exists from initial position

---

## PHASE 12 — Element T (Teleport Pairs) *(Post-MVP)*

> These tasks are scoped and ready but are not part of the MVP release. Implement after Element C is stable, as teleport levels may combine both mechanics.

- [ ] **T67** Define `TeleportPairData` class: stores `id`, two grid positions (`a` and `b`), and optional `one_way` flag
- [ ] **T68** Extend `LevelLoader` with `get_teleport_pairs()` static method to parse the optional `"T"` array from level JSON; omitting `"T"` must be backward compatible
- [ ] **T69** Store active teleport pairs in `Game.gd` as a dictionary mapping each teleport cell to its paired exit cell; account for `one_way` flag
- [ ] **T70** Add teleport color palette to `GameTheme` for all three themes: a small set of distinct tint colors (2–3), visually separate from surface, block, and C block colors
- [ ] **T71** Render teleport squares in `Board.gd` as a new draw pass (analogous to `_target_colors`): tint each teleport cell with its pair's assigned color and draw a subtle centered symbol
- [ ] **T72** Extend `Movement.resolve()` to detect when a block's resolved destination is a teleport entry square; relocate the block to the exit square and continue movement resolution from there (with infinite-loop guard: each block may teleport at most once per move)
- [ ] **T73** Handle invalid teleport: if the exit square is occupied (B block or C block) when a block attempts to teleport, treat the move as invalid and shake all involved blocks
- [ ] **T74** Handle push-chain teleport: if a push chain reaches a teleport square, the entire chain teleports together; if any block in the chain cannot exit, the entire chain is invalid
- [ ] **T75** Update BFS dead-state simulator (`_bfs_sim_move()`) to simulate teleport traversal: when a simulated block lands on a teleport entry, jump its position to the exit before continuing
- [ ] **T76** Implement teleport activation effect: on successful teleport, trigger a brief simultaneous scale or color pulse Tween on both squares of the pair from `Game.gd`
- [ ] **T77** Add teleport sound effect (distinct from slide and invalid move sounds)
- [ ] **T78** Author 3–5 test levels using teleport pairs (some combined with C blocks) to validate the mechanic; verify each is solvable and the BFS detector correctly identifies dead states
- [ ] **T79** Consider implementing a first-use tutorial hint for teleport levels: animated pulse between paired squares before the first move, fading after the player's first interaction

---

## Notes

- Business model tasks are out of scope for MVP (separate document)
- Level count for MVP: **10 levels** (5 implemented so far)
- Win condition: instant, no confirmation step required
- Invalid move: all blocks in chain shake and return, no level fail state
- Dead state: auto-detected via BFS after every move, triggers automatic reset
- Push mechanic: a moving block pushes any block it collides with — no hard blocking
- T09 chessboard pattern was removed — board uses flat single surface color per theme
- Element C (Phase 11) and Element T (Phase 12) are post-MVP; all existing level files remain valid without modification due to optional `"C"` and `"T"` arrays
