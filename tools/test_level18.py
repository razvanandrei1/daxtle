#!/usr/bin/env python3
"""Level 18 — Twin Destroys: 2 D blocks, 2 sacrifices, difficulty 7."""

import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from solve_levels import parse_level, solve, ARROWS

def test(data, label=""):
    board, blocks, teleport_map, destroy_set = parse_level(data)
    solution = solve(board, blocks, teleport_map, destroy_set)
    if solution is None:
        print(f"{label}: NO SOLUTION")
    else:
        arrows = " ".join(ARROWS[d] for d in solution)
        print(f"{label} ({len(solution)} moves): {arrows}")
        print(f"  {' '.join(solution)}")
    return solution


# ══════════════════════════════════════════════════════════════
# Level 18 — "Twin Destroys"
#
# Core concept: 2 D blocks requiring 2 sacrifices from a pool.
# The two sacrifices must happen in the right order.
# One D gates a target, the other gates a push path.
# ~14 cells, 5-6 blocks, 2 colors, difficulty 7.
#
# With 2 D blocks: we need 2 "extra" blocks that get destroyed.
# If we have N blocks of color X with T targets for X, then
# N - T blocks must die on D blocks. Total deaths = 2.
# ══════════════════════════════════════════════════════════════


# ──────────────────────────────────────────────────────────────
# Design A: Diamond shape, 14 cells
#
#   Row 0:       (1,0) (2,0) (3,0)
#   Row 1: (0,1) (1,1) (2,1) (3,1)
#   Row 2: (0,2) (1,2) (2,2) (3,2)
#   Row 3:       (1,3) (2,3)
#
# 2 D blocks gating column 1 and column 2
# 5 id=1 blocks, 3 id=1 targets → 2 sacrifices
# 1 id=2 block, 1 id=2 target
# ──────────────────────────────────────────────────────────────

a1 = {
    "A": [
        [1,0], [2,0], [3,0],
        [0,1,1], [1,1], [2,1], [3,1,1],
        [0,2], [1,2], [2,2], [3,2],
        [1,3,2], [2,3,1]
    ],
    "B": [
        {"dir":"down", "id":1, "origin":[1,0]},   # sac1 — col 1 to D1
        {"dir":"down", "id":1, "origin":[2,0]},   # sac2 — col 2 to D2
        {"dir":"left", "id":1, "origin":[3,0]},   # needs target
        {"dir":"left", "id":1, "origin":[3,2]},   # needs target
        {"dir":"up", "id":2, "origin":[2,3]},     # id=2
    ],
    "D": [{"origin":[1,2]}, {"origin":[2,2]}]
}
test(a1, "A1 diamond 2D")

# A2: different target placement
a2 = {
    "A": [
        [1,0,1], [2,0], [3,0],
        [0,1], [1,1], [2,1], [3,1],
        [0,2,1], [1,2], [2,2], [3,2],
        [1,3,2], [2,3,1]
    ],
    "B": [
        {"dir":"down", "id":1, "origin":[1,0]},   # sac1 — starts on own target! BAD
        {"dir":"down", "id":1, "origin":[2,0]},   # sac2
        {"dir":"left", "id":1, "origin":[3,1]},
        {"dir":"left", "id":1, "origin":[3,2]},
        {"dir":"up", "id":2, "origin":[2,3]},
    ],
    "D": [{"origin":[1,2]}, {"origin":[2,2]}]
}
# sac1 on own target, fix
a2["A"][0] = [1,0]
a2["A"][7] = [0,2,1]
# targets id=1: (0,2), (2,3). Only 2 targets for 4 id=1 blocks → 2 die. ✓
# But (0,2) is reached how? B2(←) at (3,2): (3,2)→(2,2)→(1,2)→(0,2). Must clear both D blocks!
# B3(←) at (3,1): (3,1)→(2,1)→(1,1)→(0,1). target? No id=1 target at (0,1).
# Fix targets
a2["A"] = [
    [1,0], [2,0], [3,0],
    [0,1,1], [1,1], [2,1], [3,1],
    [0,2], [1,2], [2,2], [3,2],
    [1,3,2], [2,3,1]
]
# targets id=1: (0,1), (2,3) → 2 targets, 4 id=1 blocks → 2 die ✓
# B2(←) at (3,1) → (2,1)→(1,1)→(0,1)✓
# B3(←) at (3,2) → can't reach (2,3) going left. Need different block for (2,3).
# What if B3 goes down? No, its dir is left.
# Need a block that reaches (2,3). B4(id=2,↑) at (2,3)... that's the id=2 block on id=1 target area.
# Hmm. Let me rethink.

a3 = {
    "A": [
        [1,0], [2,0], [3,0],
        [0,1,1], [1,1], [2,1], [3,1],
        [0,2], [1,2], [2,2], [3,2,1],
        [1,3,2], [2,3]
    ],
    "B": [
        {"dir":"down", "id":1, "origin":[1,0]},   # sac1
        {"dir":"down", "id":1, "origin":[2,0]},   # sac2
        {"dir":"left", "id":1, "origin":[3,1]},   # ← to (0,1)✓
        {"dir":"down", "id":1, "origin":[3,0]},   # ↓ col 3 to (3,2)✓ — but pushes B2 if both ↓
        {"dir":"up", "id":2, "origin":[2,3]},      # ↑ to (1,3)✓
    ],
    "D": [{"origin":[1,2]}, {"origin":[2,2]}]
}
# 4 id=1 blocks, targets at (0,1),(3,2) → 2 targets, 2 die ✓
# B3(↓) at (3,0): when ↓, sac1, sac2, and B3 ALL move down.
# ↓1: sac1(1,0)→(1,1), sac2(2,0)→(2,1), B3(3,0)→(3,1). B2 at (3,1)! Push! B2→(3,2)✓
# ↓2: sac1(1,1)→(1,2)=D1→dies, sac2(2,1)→(2,2)=D2→dies, B3(3,1)→(3,2) B2 there→push B2→(3,3)?no cell
# B3 blocked at (3,1). B2 at (3,2)✓.
# But sac1 and sac2 both die on same ↓ move. Both D blocks cleared in 2 ↓ moves!
# Then ↑: B4(2,3)→(2,2)→(2,1)→... target (1,3). B4 goes UP not to (1,3).
# B4 target is (1,3)✓ but B4 goes UP away from (1,3). Fix: B4 dir=left?
# B4(id=2,←) at (2,3)→(1,3)✓. 1 move.
a3["B"][4] = {"dir":"left", "id":2, "origin":[2,3]}
test(a3, "A3 both sacs down")


# ──────────────────────────────────────────────────────────────
# Design B: L-shape, sequential D blocks
# D1 must be cleared before D2 can be reached
#
#   Row 0: (0,0) (1,0) (2,0)
#   Row 1: (0,1) (1,1) (2,1) (3,1)
#   Row 2: (0,2) (1,2) (2,2) (3,2)
#   Row 3:       (1,3) (2,3) (3,3)
#
# 15 cells
# ──────────────────────────────────────────────────────────────

b1 = {
    "A": [
        [0,0], [1,0], [2,0],
        [0,1], [1,1], [2,1], [3,1,1],
        [0,2,1], [1,2], [2,2], [3,2],
        [1,3], [2,3,2], [3,3]
    ],
    "B": [
        {"dir":"right", "id":1, "origin":[0,0]},   # → row 0, then needs to go somewhere
        {"dir":"down", "id":1, "origin":[1,0]},    # sac1 ↓ col 1
        {"dir":"down", "id":1, "origin":[2,0]},    # sac2 ↓ col 2
        {"dir":"left", "id":1, "origin":[3,2]},    # ← to target
        {"dir":"left", "id":2, "origin":[3,3]},    # ← to (2,3)✓
    ],
    "D": [{"origin":[1,2]}, {"origin":[2,2]}]
}
# 4 id=1 blocks, targets (3,1),(0,2) → 2 targets, 2 die ✓
# B0(→) at (0,0): → to (1,0) pushes sac1→(2,0) pushes sac2→(3,0)? no cell (3,0). Blocked!
# B0 can't go right because sac1 is at (1,0). Fix positions.
b1["B"][0] = {"dir":"left", "id":1, "origin":[3,1]}  # ← to... targets?
b1["B"][3] = {"dir":"right", "id":1, "origin":[0,0]}
# Now: B0(←) at (3,1), on own target (3,1 is id=1 target). BAD.
# Skip b1.

b2 = {
    "A": [
        [0,0], [1,0], [2,0],
        [0,1,1], [1,1], [2,1], [3,1],
        [0,2], [1,2], [2,2], [3,2,1],
        [1,3,2], [2,3], [3,3]
    ],
    "B": [
        {"dir":"down", "id":1, "origin":[0,0]},   # sac1 ↓ col 0 to D1
        {"dir":"down", "id":1, "origin":[2,0]},   # sac2 ↓ col 2 to D2
        {"dir":"right", "id":1, "origin":[0,1]},   # on own target (0,1)! BAD
        {"dir":"down", "id":1, "origin":[3,1]},   # ↓ to (3,2)✓
        {"dir":"left", "id":2, "origin":[2,3]},    # ← to (1,3)✓
    ],
    "D": [{"origin":[0,2]}, {"origin":[2,2]}]
}
# B2 on own target. Fix.
b2["B"][2] = {"dir":"left", "id":1, "origin":[3,1]}
b2["B"][3] = {"dir":"right", "id":1, "origin":[1,0]}
# B2(←) at (3,1) → (2,1)→(1,1)→(0,1)✓
# B3(→) at (1,0) → (2,0) pushes sac2... sac2 at (2,0). Push to (3,0)? no cell. Blocked.
# Fix: move sac2 elsewhere or change B3.
b2["B"][3] = {"dir":"down", "id":1, "origin":[3,1]}
b2["B"][2] = {"dir":"left", "id":1, "origin":[2,1]}
# B2(←) at (2,1) → (1,1)→(0,1)✓
# B3(↓) at (3,1) → (3,2)✓
# sac1(↓) at (0,0) → (0,1)→(0,2)=D1
# But B2 at (0,1)? No, B2 is at (2,1). sac1 goes (0,0)→(0,1)→(0,2)=D1. Clear path.
# When ↓: sac1, sac2, B3 all move down.
# ↓1: sac1(0,0)→(0,1)✓target? No, just passing. sac2(2,0)→(2,1). B2 at (2,1)! Push B2→(2,2)=D2→B2 dies!
# BAD! sac2 pushes B2 onto D2.
# Need B2 to move before ↓.
test(b2, "B2 L-shape")


# ──────────────────────────────────────────────────────────────
# Design C: Cross shape, D blocks on opposite sides
#
#   Row 0:       (1,0) (2,0)
#   Row 1: (0,1) (1,1) (2,1) (3,1)
#   Row 2: (0,2) (1,2) (2,2) (3,2)
#   Row 3:       (1,3) (2,3)
#
# 12 cells. Compact.
# D1 at (1,2), D2 at (2,1) — cross pattern
# ──────────────────────────────────────────────────────────────

c1 = {
    "A": [
        [1,0], [2,0],
        [0,1,1], [1,1], [2,1], [3,1],
        [0,2], [1,2], [2,2], [3,2,1],
        [1,3,2], [2,3]
    ],
    "B": [
        {"dir":"down", "id":1, "origin":[1,0]},   # sac1 ↓ to D1(1,2)
        {"dir":"down", "id":1, "origin":[2,0]},   # sac2 ↓ to D2(2,2)?
        {"dir":"left", "id":1, "origin":[3,1]},   # ← to (0,1)✓
        {"dir":"left", "id":1, "origin":[3,2]},   # ← to (3,2)✓? already there. No, target (3,2) is id=1.
        {"dir":"left", "id":2, "origin":[2,3]},   # ← to (1,3)✓
    ],
    "D": [{"origin":[1,2]}, {"origin":[2,2]}]
}
# B3 at (3,2) going left: that IS the target. Block starts on own target! BAD.
# Fix: B3 elsewhere.
c1["B"][3] = {"dir":"up", "id":1, "origin":[3,2]}
# B3(↑) at (3,2) → (3,1). target (3,2)? B3 goes UP away from target. Fix target.
# Let me rethink targets.

c2 = {
    "A": [
        [1,0], [2,0],
        [0,1,1], [1,1], [2,1], [3,1],
        [0,2], [1,2], [2,2], [3,2],
        [1,3,1], [2,3,2]
    ],
    "B": [
        {"dir":"down", "id":1, "origin":[1,0]},   # sac1 ↓ to D1(1,2)
        {"dir":"right", "id":1, "origin":[0,2]},  # sac2 → to D2(2,2)? No, → goes right (0,2)→(1,2)=D1→dies
        {"dir":"left", "id":1, "origin":[3,1]},   # ← to (0,1)✓
        {"dir":"down", "id":1, "origin":[2,0]},   # ↓ to (2,1)→(2,2)=D2. Or ↓↓→(2,3)? D2 first.
        {"dir":"left", "id":2, "origin":[3,2]},   # ← to (2,3)? Need (2,3) to be target.
    ],
    "D": [{"origin":[1,2]}, {"origin":[2,2]}]
}
# Messy. Let me be more systematic.

# ──────────────────────────────────────────────────────────────
# Design D: Carefully constructed — 2 sacs go down in different cols
# Each D block is in a different column.
# The ordering: which sac goes first matters because of push interactions.
#
#   Row 0: (0,0) (1,0) (2,0) (3,0)
#   Row 1: (0,1) (1,1) (2,1) (3,1)
#   Row 2:       (1,2) (2,2) (3,2)
#   Row 3:       (1,3) (2,3)
#
# 14 cells. Staircase shape.
# D1 at (1,2), D2 at (2,2)
# ──────────────────────────────────────────────────────────────

d1 = {
    "A": [
        [0,0], [1,0], [2,0], [3,0],
        [0,1,1], [1,1], [2,1], [3,1],
        [1,2], [2,2], [3,2,1],
        [1,3,2], [2,3]
    ],
    "B": [
        {"dir":"down", "id":1, "origin":[1,0]},   # sac1 ↓ col 1 to D1(1,2)
        {"dir":"down", "id":1, "origin":[2,0]},   # sac2 ↓ col 2 to D2(2,2)
        {"dir":"left", "id":1, "origin":[3,1]},   # ← to (0,1)✓
        {"dir":"down", "id":1, "origin":[3,0]},   # ↓ to (3,2)✓. Pushes B2 on 1st ↓?
        {"dir":"left", "id":2, "origin":[2,3]},   # ← to (1,3)✓
    ],
    "D": [{"origin":[1,2]}, {"origin":[2,2]}]
}
# When ↓: sac1, sac2, B3 all move.
# ↓1: sac1(1,0)→(1,1), sac2(2,0)→(2,1), B3(3,0)→(3,1) B2 at (3,1)! Push B2→(3,2)✓
# ↓2: sac1(1,1)→(1,2)=D1→dies, sac2(2,1)→(2,2)=D2→dies, B3(3,1)→(3,2) B2 at (3,2)! Push→(3,3)?no. B3 blocked.
# Both sacs die on ↓2. ✓. B3 stuck at (3,1).
# Then ←: B2 already at (3,2)✓. B4(2,3)→(1,3)✓.
# Then ← again: B2(3,1)→(2,1)→(1,1)→(0,1)✓
# Wait, B2 is the ← block. B2 at (3,1)? No, B2 was pushed to (3,2) by B3.
# Let me re-check. B2(id=1,←) at (3,1). ↓1 pushes B2→(3,2). B2 is now at (3,2)✓ target!
# But B2 direction is ←. B2 at (3,2) which IS the target. ✓. Done with B2.
# B3(↓) at (3,1) after ↓1. ↓2: B3→(3,2) blocked by B2. B3 stays at (3,1).
# Then ↓3: B3(3,1)→(3,2) still blocked. Hmm.
# B3 needs to reach (3,2). But B2 is there. B3 pushing B2 off target.
# If target is only (3,2) and B2 is there, B3 shouldn't also target (3,2).
# B3 target: any id=1 target. Targets are (0,1) and (3,2). B3 can't reach (0,1) going ↓.
# B3 at (3,1) going ↓ reaches (3,2) but B2 blocks. Dead end for B3.

# Wait: 5 id=1 blocks, 2 targets → 3 must die? No, 2 D blocks → at most 2 die.
# 5 - 2 = 3 survivors need 3 targets. I only have 2! Fix: add a 3rd target.

d2 = {
    "A": [
        [0,0], [1,0], [2,0], [3,0],
        [0,1,1], [1,1], [2,1], [3,1,1],
        [1,2], [2,2], [3,2,1],
        [1,3,2], [2,3]
    ],
    "B": [
        {"dir":"down", "id":1, "origin":[1,0]},   # sac1 ↓ to D1(1,2)
        {"dir":"down", "id":1, "origin":[2,0]},   # sac2 ↓ to D2(2,2)
        {"dir":"left", "id":1, "origin":[3,1]},   # ← to (0,1)✓
        {"dir":"down", "id":1, "origin":[3,0]},   # ↓ to (3,1)→(3,2)✓
        {"dir":"left", "id":2, "origin":[2,3]},   # ← to (1,3)✓
    ],
    "D": [{"origin":[1,2]}, {"origin":[2,2]}]
}
# 5 id=1 blocks, 3 id=1 targets → 2 die ✓
# ↓1: sac1→(1,1), sac2→(2,1), B3(3,0)→(3,1) pushes B2→(3,2)✓
# But B2 at (3,1) is id=1 target. B2 pushed OFF target to (3,2) which is ALSO target. OK.
# B2 starts at (3,1) which IS target for id=1. B2 IS id=1. Starts on own target! BAD.
# Fix: B2 not at (3,1).
d2["B"][2] = {"dir":"left", "id":1, "origin":[3,2]}  # B2 at (3,2) going ←
# B2 at (3,2) which is id=1 target. Own target again! BAD.
# Remove (3,2) as target.
d2["A"] = [
    [0,0], [1,0], [2,0], [3,0],
    [0,1,1], [1,1], [2,1], [3,1,1],
    [1,2], [2,2], [3,2],
    [1,3,2], [2,3,1]
]
# targets id=1: (0,1), (3,1), (2,3). B2(←) at (3,2) → (2,2)=D2→dies if D2 not cleared!
# That's a TRAP! B2 going left hits D2 if not cleared.
# After D2 cleared: B2(3,2)→(2,2)→(1,2). Target (2,3)? B2 goes LEFT not DOWN.
# B2 can't reach (2,3). Need someone else for (2,3).
# B3(↓) at (3,0) → (3,1)✓ target. Then who gets (2,3)?
# Nobody can reach (2,3). Fix.

# Let me try: target at (0,1), (3,1), and B3 reaches (3,1), B2 reaches (0,1).
d3 = {
    "A": [
        [0,0], [1,0], [2,0], [3,0],
        [0,1,1], [1,1], [2,1], [3,1,1],
        [1,2], [2,2], [3,2],
        [1,3,2], [2,3]
    ],
    "B": [
        {"dir":"down", "id":1, "origin":[1,0]},   # sac1 ↓ to D1
        {"dir":"down", "id":1, "origin":[2,0]},   # sac2 ↓ to D2
        {"dir":"left", "id":1, "origin":[3,2]},   # ← through cleared D area to (0,1)? Goes (3,2)→(2,2)→(1,2). Target (0,1) not in row 2.
        {"dir":"down", "id":1, "origin":[3,0]},   # ↓ to (3,1)✓
        {"dir":"left", "id":2, "origin":[2,3]},   # ← to (1,3)✓
    ],
    "D": [{"origin":[1,2]}, {"origin":[2,2]}]
}
# B2(←) can't reach (0,1) from row 2. Need to change.
# What if B2 is in row 1?
d3["B"][2] = {"dir":"left", "id":1, "origin":[2,1]}
# B2(←) at (2,1) → (1,1)→(0,1)✓. 2 ← moves.
# But when ↓1: sac2(2,0)→(2,1) pushes B2→(2,2)=D2→dies! BAD!
# B2 must move before ↓.
# ← first: B2(2,1)→(1,1). Then ↓: sac2(2,0)→(2,1). Safe.
# ← again: B2(1,1)→(0,1)✓.
# Then ↓↓: sac1→D1, sac2→D2. Both die.
# This creates the ordering: ← before ↓.
test(d3, "D3 ordering")


# ──────────────────────────────────────────────────────────────
# Design E: Wider, more room for interactions
#
#   Row 0: (0,0) (1,0) (2,0) (3,0) (4,0)
#   Row 1: (0,1) (1,1) (2,1) (3,1)
#   Row 2:       (1,2) (2,2) (3,2)
#   Row 3:       (1,3) (2,3)
#
# 15 cells.
# ──────────────────────────────────────────────────────────────

e1 = {
    "A": [
        [0,0], [1,0], [2,0], [3,0], [4,0],
        [0,1,1], [1,1], [2,1], [3,1,1],
        [1,2], [2,2], [3,2],
        [1,3,2], [2,3,1]
    ],
    "B": [
        {"dir":"down", "id":1, "origin":[1,0]},   # sac1
        {"dir":"down", "id":1, "origin":[2,0]},   # sac2
        {"dir":"left", "id":1, "origin":[2,1]},   # ← to (0,1)✓
        {"dir":"right", "id":1, "origin":[0,0]},  # → along row 0
        {"dir":"down", "id":1, "origin":[3,0]},   # ↓ to (3,1)✓
        {"dir":"left", "id":2, "origin":[2,3]},   # ← to (1,3)✓
    ],
    "D": [{"origin":[1,2]}, {"origin":[2,2]}]
}
# 5 id=1 blocks, 3 targets → 2 die ✓ + 1 id=2
# B3(→) at (0,0): → pushes sac1(1,0)→(2,0) pushes sac2→(3,0) pushes B4→(4,0). Chain!
# That's bad — pushes sacs off their columns.
# Trap: → first ruins sacrifice paths!
# But B3 needs to reach target. targets id=1: (0,1),(3,1),(2,3).
# B3(→) at (0,0) can reach... (1,0),(2,0),(3,0),(4,0). None are targets.
# B3 can't reach any target going right. Fix direction.
e1["B"][3] = {"dir":"down", "id":1, "origin":[0,0]}
# B3(↓) at (0,0) → (0,1)✓ target. 1 move.
# But (0,1) is target for id=1, B3 IS id=1. And B2(←) targets (0,1) too.
# Both B2 and B3 head to (0,1). Only one can be there.
# B2(←) at (2,1) → (1,1)→(0,1). B3(↓) at (0,0) → (0,1).
# If both reach (0,1), one pushes the other.
# When ↓: B3(0,0)→(0,1). sac1, sac2, B4 also move ↓.
# If B2 is at (0,1) already (from ←), B3 pushes B2→(0,2)?no cell. B3 blocked.
# So if ← first, B2 goes to (0,1), then B3 can't go down. Problem.

# Let me rethink targets.
e1["A"] = [
    [0,0], [1,0], [2,0], [3,0], [4,0],
    [0,1,1], [1,1], [2,1], [3,1],
    [1,2], [2,2], [3,2,1],
    [1,3,2], [2,3,1]
]
# targets id=1: (0,1), (3,2), (2,3)
# B2(←) at (2,1) → (0,1)✓
# B4(↓) at (3,0) → (3,1)→(3,2)✓
# B3(↓) at (0,0) → needs target. (2,3)? Can't reach col 2 going ↓.
# Remove B3, use 5 blocks instead of 6.
e2 = {
    "A": [
        [0,0], [1,0], [2,0], [3,0], [4,0],
        [0,1,1], [1,1], [2,1], [3,1],
        [1,2], [2,2], [3,2,1],
        [1,3,2], [2,3]
    ],
    "B": [
        {"dir":"down", "id":1, "origin":[1,0]},   # sac1 ↓ to D1(1,2)
        {"dir":"down", "id":1, "origin":[2,0]},   # sac2 ↓ to D2(2,2)
        {"dir":"left", "id":1, "origin":[2,1]},   # ← to (0,1)✓
        {"dir":"down", "id":1, "origin":[3,0]},   # ↓ to (3,2)✓
        {"dir":"left", "id":2, "origin":[2,3]},   # ← to (1,3)✓
    ],
    "D": [{"origin":[1,2]}, {"origin":[2,2]}]
}
# 4 id=1 blocks, 2 targets → 2 die ✓
# When ↓: sac1, sac2, B3 all move.
# ↓1: sac1→(1,1), sac2→(2,1) B2 there! Push B2→(1,1)?no, push goes DOWN. B2→(2,2)=D2→dies!
# BAD! sac2 pushes B2 onto D2.
# Fix: B2 must move ← before ↓.
# ← first: B2(2,1)→(1,1). Then ↓ safe.
# But do we have enough cell at (4,0)? B3 at (3,0) going down. (4,0) just sits empty.
# Let me also check if (0,0) is used. Nothing starts there.
# Trim: remove (0,0) and (4,0)?
e3 = {
    "A": [
        [1,0], [2,0], [3,0],
        [0,1,1], [1,1], [2,1], [3,1],
        [1,2], [2,2], [3,2,1],
        [1,3,2], [2,3]
    ],
    "B": [
        {"dir":"down", "id":1, "origin":[1,0]},   # sac1
        {"dir":"down", "id":1, "origin":[2,0]},   # sac2
        {"dir":"left", "id":1, "origin":[2,1]},   # ← to (0,1)✓
        {"dir":"down", "id":1, "origin":[3,0]},   # ↓ to (3,2)✓
        {"dir":"left", "id":2, "origin":[2,3]},   # ← to (1,3)✓
    ],
    "D": [{"origin":[1,2]}, {"origin":[2,2]}]
}
# 13 cells. Same issue with sac2 pushing B2.
# When ← first: B2(2,1)→(1,1). B4(2,3)→(1,3)✓. Both ← blocks move.
# ← again: B2(1,1)→(0,1)✓. B4 blocked at (1,3) (no cell left).
# Then ↓: sac1(1,0)→(1,1). sac2(2,0)→(2,1). B3(3,0)→(3,1).
# ↓ again: sac1(1,1)→(1,2)=D1→dies. sac2(2,1)→(2,2)=D2→dies. B3(3,1)→(3,2)✓.
# Check: B2(0,1)✓, B3(3,2)✓, B4(1,3)✓. WIN!
# Solution: ←←↓↓ = 4 moves? Let me check with solver.
test(e3, "E3 compact")

# E4: Like E3 but with more interaction — add a block that creates ordering
e4 = {
    "A": [
        [1,0], [2,0], [3,0],
        [0,1,1], [1,1], [2,1], [3,1,1],
        [1,2], [2,2], [3,2],
        [1,3,2], [2,3,1]
    ],
    "B": [
        {"dir":"down", "id":1, "origin":[1,0]},   # sac1
        {"dir":"down", "id":1, "origin":[2,0]},   # sac2
        {"dir":"left", "id":1, "origin":[2,1]},   # ← to (0,1)✓
        {"dir":"down", "id":1, "origin":[3,0]},   # ↓ to (3,1)✓. But B3 pushing nothing? (3,1) is empty initially.
        {"dir":"up", "id":2, "origin":[2,3]},     # ↑ through cleared D area
    ],
    "D": [{"origin":[1,2]}, {"origin":[2,2]}]
}
# 5 id=1 blocks, 3 targets → 2 die ✓
# B4(id=2,↑) at (2,3) → (2,2)→(2,1)→... target (1,3)? Goes UP not left.
# Target (1,3) is for id=2. B4 goes UP. Can't reach.
# Fix target or direction.
e4["B"][4] = {"dir":"left", "id":2, "origin":[2,3]}
# B4(←) at (2,3)→(1,3)✓. 1 move.
# But this is same as E3 with an extra target at (3,1).
# B3(↓) at (3,0): (3,0)→(3,1)✓. 1 ↓ move.
# ↓ interacts: sac1, sac2, B3 all move on ↓.
# If ← first: B2→(1,1)→(0,1), B4→(1,3)
# Then ↓↓: sacs die, B3 reaches (3,1)
# Solution: ←← ↓↓ = 4 moves. Still too short.
test(e4, "E4 extra target")


# ──────────────────────────────────────────────────────────────
# Design F: Make sacs need different # of ↓ moves
# sac1 needs 3↓, sac2 needs 2↓ — creates sequencing
#
#   Row 0: (0,0) (1,0) (2,0) (3,0)
#   Row 1: (0,1) (1,1) (2,1) (3,1)
#   Row 2: (0,2) (1,2) (2,2) (3,2)
#   Row 3:       (1,3) (2,3) (3,3)
#
# 15 cells.
# D1 at (1,3), D2 at (2,2)
# sac1 at (1,0) needs 3↓ to reach D1
# sac2 at (2,0) needs 2↓ to reach D2
# ──────────────────────────────────────────────────────────────

f1 = {
    "A": [
        [0,0], [1,0], [2,0], [3,0],
        [0,1,1], [1,1], [2,1], [3,1,1],
        [0,2], [1,2], [2,2], [3,2],
        [1,3], [2,3,1], [3,3,2]
    ],
    "B": [
        {"dir":"down", "id":1, "origin":[1,0]},   # sac1 ↓↓↓ to D1(1,3)
        {"dir":"down", "id":1, "origin":[2,0]},   # sac2 ↓↓ to D2(2,2), dies before sac1
        {"dir":"left", "id":1, "origin":[3,1]},   # ← to target
        {"dir":"right", "id":1, "origin":[0,1]},  # → along row 1
        {"dir":"left", "id":1, "origin":[3,0]},   # ← along row 0
        {"dir":"left", "id":2, "origin":[3,3]},   # ← to (3,3)? starts on own target! Fix.
    ],
    "D": [{"origin":[1,3]}, {"origin":[2,2]}]
}
# Too many blocks. And B5 on own target.
# Simplify: 5 blocks total.
f2 = {
    "A": [
        [0,0], [1,0], [2,0], [3,0],
        [0,1,1], [1,1], [2,1], [3,1,1],
        [0,2], [1,2], [2,2], [3,2],
        [1,3], [2,3,1], [3,3,2]
    ],
    "B": [
        {"dir":"down", "id":1, "origin":[1,0]},   # sac1 ↓↓↓ to D1(1,3)
        {"dir":"down", "id":1, "origin":[2,0]},   # sac2 ↓↓ to D2(2,2)
        {"dir":"left", "id":1, "origin":[3,1]},   # ← to (0,1)✓
        {"dir":"left", "id":1, "origin":[2,1]},   # ← to ... pushed by sac2? Interaction!
        {"dir":"right", "id":2, "origin":[0,2]},  # → to (3,3)? Long path. → (0,2)→(1,2)→(2,2)=D2→dies!
    ],
    "D": [{"origin":[1,3]}, {"origin":[2,2]}]
}
# B4(→) hits D2 going right! Bad. Fix.
f2["B"][4] = {"dir":"left", "id":2, "origin":[3,3]}
# B4 at (3,3) on own target (3,3,2). BAD.
f2["A"][-1] = [3,3]
f2["A"].append([0,2,2])  # hmm, (0,2) already in list. Let me rebuild.
f2["A"] = [
    [0,0], [1,0], [2,0], [3,0],
    [0,1,1], [1,1], [2,1], [3,1,1],
    [0,2,2], [1,2], [2,2], [3,2],
    [1,3], [2,3,1], [3,3]
]
f2["B"][4] = {"dir":"left", "id":2, "origin":[3,3]}
# B4(←) at (3,3) → (2,3)→(1,3)=D1... if D1 not cleared, dies!
# Another ordering constraint! D1 must be cleared before B4 goes ←←.
# But D1 is at (1,3). sac1 goes ↓↓↓ to (1,3)=D1. Takes 3 ↓ moves.
# B4 going ← from (3,3): ←1: (3,3)→(2,3), ←2: (2,3)→(1,3)=D1→dies if D1 still there.
# So: need 3 ↓ moves before B4 does 2 ← moves.
# But ← also moves B2(3,1) and B3(2,1).
# ←1: B2(3,1)→(2,1) B3 at (2,1)! Push B3→(1,1). B2 at (2,1). B4(3,3)→(2,3).
# ←2: B2(2,1)→(1,1) B3 at (1,1)! Push B3→(0,1)✓. B2 at (1,1). B4(2,3)→(1,3). If D1 still there→dies!
# So ↓↓↓ must happen before ←←. But ↓ also moves sac2(2,0).
# ↓1: sac1(1,0)→(1,1), sac2(2,0)→(2,1). B3 at (2,1)? If B3 moved ← already, (2,1) clear.
# If ↓ before ←: sac2(2,0)→(2,1) B3 at (2,1)! Push B3→(2,2)=D2→dies!
# BAD! sac2 pushes B3 onto D2.
# So ← must come before ↓ (to clear B3 from (2,1)).
# But we said ↓↓↓ before ←← (to clear D1 for B4).
# CONTRADICTION! This is the puzzle's tension!
# Resolution: ← ONCE to clear B3, then ↓↓↓, then ← again.
# Let me test this.
test(f2, "F2 sequential Ds")

# F3: Like F2 but without B3 blocking — different interaction
f3 = {
    "A": [
        [0,0], [1,0], [2,0], [3,0],
        [0,1,1], [1,1], [2,1], [3,1],
        [0,2,2], [1,2], [2,2], [3,2,1],
        [1,3], [2,3], [3,3]
    ],
    "B": [
        {"dir":"down", "id":1, "origin":[1,0]},   # sac1 ↓↓↓ to D1(1,3)
        {"dir":"down", "id":1, "origin":[2,0]},   # sac2 ↓↓ to D2(2,2)
        {"dir":"left", "id":1, "origin":[3,0]},   # ← row 0
        {"dir":"down", "id":1, "origin":[3,1]},   # ↓ to (3,2)✓
        {"dir":"left", "id":2, "origin":[3,3]},   # ← to (0,2)✓? Path: (3,3)→(2,3)→(1,3)=D1→dies!
    ],
    "D": [{"origin":[1,3]}, {"origin":[2,2]}]
}
# B4 hits D1 going left! Same issue.
# What if B4 goes UP instead?
f3["B"][4] = {"dir":"up", "id":2, "origin":[0,2]}
# B4(↑) at (0,2) on target (0,2,2). Own target! BAD.
f3["B"][4] = {"dir":"up", "id":2, "origin":[1,3]}
# B4(↑) at (1,3). (1,3) is D1 location! Block starts on D? Let me check...
# In the game, D blocks are separate from board squares. A block CAN start on a D cell? Hmm.
# Actually, D origins are separate objects. A block at (1,3) and D at (1,3) means the block
# immediately dies? No, destroy collision only happens AFTER a move.
# So B4 can start at D1's position safely. But first ↓ moves sac1 toward B4.
# This is getting complicated. Let me just test what works.
f3["B"][4] = {"dir":"left", "id":2, "origin":[3,2]}
# B4(←) at (3,2) → (2,2)=D2→dies! Also bad.
f3["B"][4] = {"dir":"down", "id":2, "origin":[0,0]}
# B4(↓) at (0,0) → (0,1)→(0,2)✓. 2 ↓ moves. Interacts with sac1/sac2/B3 (all ↓).
test(f3, "F3")
