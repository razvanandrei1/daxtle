# Daxtle — MVP Task List

---

## PHASE 1 — Project Setup

- [ ] **T01** Create new Godot 4 project, configure for mobile (iOS + Android)
- [ ] **T02** Set portrait-only orientation in project settings
- [ ] **T03** Define folder structure: `/scenes`, `/scripts`, `/levels`, `/assets`
- [ ] **T04** Create placeholder scene tree: Main, Game, UI layers
- [ ] **T05** Configure export presets for iOS and Android

---

## PHASE 2 — Element A (Board)

- [ ] **T06** Write JSON parser to load level file and extract element A square positions
- [ ] **T07** Calculate `Value_A` (square size) based on screen size, board dimensions, and 10% margin rule
- [ ] **T08** Instantiate and render element A squares centered on screen using `Value_A`
- [ ] **T09** Apply chessboard alternating color pattern to A squares
- [ ] **T10** Handle irregular board shapes (non-rectangular, missing squares)
- [ ] **T11** Visually distinguish missing squares from valid squares (empty space, no render)
- [ ] **T12** Return `Value_A` from instantiation for use by other systems

---

## PHASE 3 — Element B (Moving Blocks)

- [ ] **T13** Write JSON parser to extract element B definitions (id, dir, squares, origin, target)
- [ ] **T14** Instantiate element B blocks on element A using `Value_A` for sizing and placement
- [ ] **T15** Assign block colors at load time based on block ID using a project-defined color palette
- [ ] **T16** Render directional arrow on each B element indicating its movement direction
- [ ] **T17** Support multi-square B element shapes (relative `squares` array + `origin` offset)
- [ ] **T18** Highlight target zones on element A using a muted version of each B element's color

---

## PHASE 4 — Swipe Input

- [ ] **T19** Implement swipe gesture detection (left, right, up, down) anywhere on screen
- [ ] **T20** Set minimum swipe distance threshold to avoid accidental triggers
- [ ] **T21** Disable input during animation (prevent queued swipes mid-slide)
- [ ] **T22** Route swipe direction to movement system

---

## PHASE 5 — Movement System

- [ ] **T23** Implement movement logic: on swipe, move all B elements whose `dir` matches the swipe direction by one square
- [ ] **T24** Implement blocking logic: a B element cannot move if its next square is occupied by another B element
- [ ] **T25** Implement boundary check: detect if move would place any square of B outside the A grid boundary
- [ ] **T26** Implement missing square check: detect if move would place any square of B above a missing A square
- [ ] **T27** Implement smooth slide animation for valid moves using Tween
- [ ] **T28** Implement undo logic: snap B element back to previous position on invalid move (boundary or missing square)
- [ ] **T29** Show invalid move feedback: brief shake animation on the offending block (no level fail state)

---

## PHASE 6 — Win Condition

- [ ] **T30** After each move, check if all B elements are on their respective target positions
- [ ] **T31** Trigger win state immediately when last B element lands on its target
- [ ] **T32** Implement win animation: all B blocks pulse with a rhythmic glow simultaneously, then fade out — board fades out shortly after
- [ ] **T33** Transition to next level automatically after win animation completes

---

## PHASE 7 — Level Management

- [ ] **T34** Define level JSON file naming convention (e.g. `level_001.json`, `level_002.json`)
- [ ] **T35** Implement level loader: reads correct JSON file based on current level index
- [ ] **T36** Implement level progression: unlock and load next level on win
- [ ] **T37** Persist current level progress (save to disk, survives app close)
- [ ] **T38** Create 10 MVP levels with increasing difficulty, each verified as passable

---

## PHASE 8 — UI

- [ ] **T39** Design and implement minimal main menu (Play button, level select placeholder)
- [ ] **T40** Display current level number during gameplay
- [ ] **T41** Implement reset button — all B blocks animate smoothly back to their starting positions simultaneously (no snap)
- [ ] **T42** Implement back/menu button during gameplay
- [ ] **T43** Add level complete screen (minimal — next level prompt)

---

## PHASE 9 — Visual & Audio Polish

- [ ] **T44** Finalize color palette for element A (chessboard tones), B elements, targets, and background
- [ ] **T45** Refine B element arrow design (clean, minimal, readable at small sizes)
- [ ] **T46** Implement level initialization animation: board fades/scales in → B blocks slide in from above one by one with stagger delay → arrow fades in on each block after it lands → brief input-disabled pause before player can interact
- [ ] **T47** Source or create ambient background music (calm, looping, low-key)
- [ ] **T48** Add subtle sound effect for valid slide move
- [ ] **T49** Add distinct sound effect for invalid move / undo
- [ ] **T50** Add sound effect for win condition

---

## PHASE 10 — Testing & Export

- [ ] **T51** Test all movement edge cases: boundary, missing square, multi-square B elements, blocking
- [ ] **T52** Test all 10 levels end-to-end on device (iOS and Android)
- [ ] **T53** Test on multiple screen sizes and resolutions
- [ ] **T54** Profile performance — ensure smooth animations on low-end devices
- [ ] **T55** Export iOS build and test on device via TestFlight
- [ ] **T56** Export Android build and test on device

---

## Notes

- Business model tasks are out of scope for MVP (separate document)
- Level count for MVP: **10 levels**
- Win condition: instant, no confirmation step required
- Invalid move: immediate undo with warning, no level fail state
- Multi-square B element rule: if any square of B would land on an invalid position, the entire element undoes
