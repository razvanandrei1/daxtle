#!/usr/bin/env python3
"""Level 17 — round 2. More principled designs with verified paths."""

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


# ──────────────────────────────────────────────────────────────
# Core concept: 3 colors + 1 D block.
# The D block is in the path of one color block.
# Sacrifice (extra block) must clear D first.
# Wrong order kills the needed block.
#
# Principle: verify each block can reach its target BEFORE coding.
# ──────────────────────────────────────────────────────────────


# === Design 1: S-shape, 13 cells ===
#   Row 0: (0,0) (1,0) (2,0) (3,0)
#   Row 1:       (1,1) (2,1) (3,1)
#   Row 2:       (1,2) (2,2) (3,2)
#   Row 3: (0,3) (1,3) (2,3)
#
# B0(id=1,→) at (0,0) → target (3,0): →→→ (pushes Sac if Sac still there)
# B1(id=2,←) at (3,2) → target (1,2): ←← (must clear D at (2,2) first)
# B2(id=3,←) at (2,3) → target (0,3): ←←
# Sac(id=1,↓) at (2,0) → D at (2,2): ↓↓ then dies
# Traps: → before ↓ pushes Sac; ← before ↓ kills B1 on D.

s1 = {
    "A": [
        [0,0], [1,0], [2,0], [3,0,1],
        [1,1], [2,1], [3,1],
        [1,2,2], [2,2], [3,2],
        [0,3,3], [1,3], [2,3]
    ],
    "B": [
        {"dir":"right", "id":1, "origin":[0,0]},
        {"dir":"left", "id":2, "origin":[3,2]},
        {"dir":"left", "id":3, "origin":[2,3]},
        {"dir":"down", "id":1, "origin":[2,0]},
    ],
    "D": [{"origin":[2,2]}]
}
test(s1, "S1 base")

# S2: add 5th block for more interaction
s2 = dict(s1)
s2["B"] = [
    {"dir":"right", "id":1, "origin":[0,0]},
    {"dir":"left", "id":2, "origin":[3,2]},
    {"dir":"left", "id":3, "origin":[2,3]},
    {"dir":"down", "id":1, "origin":[2,0]},
    {"dir":"up", "id":2, "origin":[3,1]},  # B4: 2nd id=2 going up
]
s2["A"] = [
    [0,0], [1,0], [2,0], [3,0,1],
    [1,1], [2,1], [3,1,2],  # target for id=2 at (3,1)
    [1,2,2], [2,2], [3,2],
    [0,3,3], [1,3], [2,3]
]
# Now 2 id=2 blocks: B1(←) targets (1,2), B4(↑) targets (3,1).
# B4 at (3,1) going up: (3,1)→(3,0). target (3,1) is for id=2, but B4 starts there.
# B4 starts on own-color target — BAD. Move B4.
s2["B"][4] = {"dir":"up", "id":2, "origin":[1,1]}
# B4(id=2,↑) at (1,1) → target (3,1)? Can't reach (3,1) by going up.
# Needs target in column 1 upward. No row above (1,1) in the board... (1,0) is in board.
# But target (3,1) is in column 3. B4 goes UP, stays in column 1. Can't reach.
# Skip s2.


# S3: B1 at (3,1) going left, longer path through D area
s3 = {
    "A": [
        [0,0], [1,0], [2,0], [3,0,1],
        [1,1,2], [2,1], [3,1],
        [1,2], [2,2], [3,2,3],
        [0,3], [1,3], [2,3]
    ],
    "B": [
        {"dir":"right", "id":1, "origin":[0,0]},
        {"dir":"left", "id":2, "origin":[3,1]},   # ← through (2,1)→(1,1)✓
        {"dir":"up", "id":3, "origin":[2,3]},      # ↑ through (2,2)→(2,1)→(2,0)
        {"dir":"down", "id":1, "origin":[2,0]},    # sac ↓ to D
    ],
    "D": [{"origin":[2,2]}]
}
# B2(id=3,↑) at (2,3): goes up (2,3)→(2,2)=D → dies if D not cleared!
# So D must be cleared before B2 goes up. Another trap!
# Target for id=3: (3,2). But B2 goes UP, can't reach (3,2) by going up.
# Fix: target (3,2) needs a block going left or down. Let me change.
# Target id=3 at (2,1)? B2 goes up from (2,3): (2,3)→(2,2)→(2,1). Needs D cleared first.
s3["A"] = [
    [0,0], [1,0], [2,0], [3,0,1],
    [1,1,2], [2,1,3], [3,1],
    [1,2], [2,2], [3,2],
    [0,3], [1,3], [2,3]
]
test(s3, "S3 B2 through D")


# S4: Like S3 but with different D position creating multiple threats
s4 = {
    "A": [
        [0,0], [1,0], [2,0], [3,0,1],
        [1,1], [2,1,3], [3,1,2],
        [1,2], [2,2], [3,2],
        [0,3], [1,3], [2,3]
    ],
    "B": [
        {"dir":"right", "id":1, "origin":[0,0]},
        {"dir":"left", "id":2, "origin":[3,2]},   # ← to (3,1)✓. 1 move? No, (3,2)→(2,2)→(1,2)→...
        # Actually B1 goes LEFT, ending up in col 0-1, not reaching (3,1).
        # Let me make B1 go up instead.
        {"dir":"up", "id":3, "origin":[2,3]},     # ↑ to (2,1)✓
        {"dir":"down", "id":1, "origin":[2,0]},   # sac
    ],
    "D": [{"origin":[2,2]}]
}
# B1(id=2,←) at (3,2) going left can't reach (3,1) which is target for id=2.
# Fix: B1 direction or target
s4["B"][1] = {"dir":"up", "id":2, "origin":[3,2]}  # goes up (3,2)→(3,1)✓
test(s4, "S4 two-up blocks")


# === Design 2: Wide diamond, 14 cells ===
#   Row 0:       (1,0) (2,0)
#   Row 1: (0,1) (1,1) (2,1) (3,1)
#   Row 2: (0,2) (1,2) (2,2) (3,2)
#   Row 3:       (1,3) (2,3)

d1 = {
    "A": [
        [1,0], [2,0],
        [0,1,1], [1,1], [2,1], [3,1,2],
        [0,2], [1,2], [2,2,3], [3,2],
        [1,3], [2,3]
    ],
    "B": [
        {"dir":"down", "id":1, "origin":[1,0]},    # → target (0,1)? Goes down col 1.
        {"dir":"down", "id":1, "origin":[2,0]},    # sac → D at (2,2)
        {"dir":"left", "id":2, "origin":[3,2]},    # ← to (3,1)✓? Goes left not up. Fix.
        {"dir":"up", "id":3, "origin":[1,3]},      # ↑ to (2,2)? Goes up col 1 not col 2.
    ],
    "D": [{"origin":[2,2]}]
}
# Paths don't work. Let me redo.

d2 = {
    "A": [
        [1,0], [2,0],
        [0,1], [1,1,1], [2,1], [3,1],
        [0,2,3], [1,2], [2,2], [3,2,2],
        [1,3], [2,3]
    ],
    "B": [
        {"dir":"down", "id":1, "origin":[2,0]},    # sac ↓ col 2 to D(2,2)
        {"dir":"left", "id":1, "origin":[3,1]},    # ← row 1 to (1,1)✓
        {"dir":"left", "id":2, "origin":[3,2]},    # starts on own target — BAD
        {"dir":"up", "id":3, "origin":[1,3]},      # ↑ col 1 to (0,2)? Not in col 0.
    ],
    "D": [{"origin":[2,2]}]
}
# B2 on own target. Fix.
d2["B"][2] = {"dir":"up", "id":2, "origin":[2,3]}  # ↑ col 2, hits D if not cleared
# Target id=2 at (3,2). B2 goes up from (2,3), can't reach (3,2) col 3.
# Fix target to col 2: (2,1)?
d2["A"] = [
    [1,0], [2,0],
    [0,1], [1,1,1], [2,1,2], [3,1],
    [0,2,3], [1,2], [2,2], [3,2],
    [1,3], [2,3]
]
# B2(id=2,↑) at (2,3) → target (2,1): ↑↑ through (2,2)=D then (2,1)✓
# Needs D cleared first!
# B3(id=3,↑) at (1,3) → target (0,2): need to go up then left? ↑ goes up col 1.
# Can't reach col 0 by going up. Fix.
d2["B"][3] = {"dir":"left", "id":3, "origin":[1,3]}  # ← row 3 to... (0,3)? Not in board.
# (1,3) going left → (0,3)? No cell. Blocked.
# Add (0,3)?

d3 = {
    "A": [
        [1,0], [2,0],
        [0,1], [1,1,1], [2,1,2], [3,1],
        [0,2,3], [1,2], [2,2], [3,2],
        [0,3], [1,3], [2,3]
    ],
    "B": [
        {"dir":"down", "id":1, "origin":[2,0]},    # sac ↓ to D(2,2)
        {"dir":"left", "id":1, "origin":[3,1]},    # ← to (1,1)✓
        {"dir":"up", "id":2, "origin":[2,3]},      # ↑ to (2,1)✓ (through D area)
        {"dir":"left", "id":3, "origin":[1,3]},    # ← to (0,3)→... then what?
    ],
    "D": [{"origin":[2,2]}]
}
# B3(id=3,←) at (1,3) → (0,3). Target (0,2) is UP from (0,3). B3 goes LEFT not UP.
# B3 can only reach cells in row 3 going left. Target must be in row 3.
# No id=3 target in row 3. Fix: target id=3 at (0,3).
d3["A"] = [
    [1,0], [2,0],
    [0,1], [1,1,1], [2,1,2], [3,1],
    [0,2], [1,2], [2,2], [3,2],
    [0,3,3], [1,3], [2,3]
]
test(d3, "D3 diamond")


# === Design 3: Z-shape, clean 3-way ordering ===
#   Row 0: (0,0) (1,0) (2,0) (3,0)
#   Row 1:       (1,1) (2,1) (3,1)
#   Row 2: (0,2) (1,2) (2,2)
#   Row 3: (0,3) (1,3) (2,3)
#
# 14 cells. Z/S shape.

z1 = {
    "A": [
        [0,0], [1,0], [2,0], [3,0,1],
        [1,1], [2,1], [3,1],
        [0,2], [1,2,2], [2,2],
        [0,3,3], [1,3], [2,3]
    ],
    "B": [
        {"dir":"right", "id":1, "origin":[0,0]},   # → to (3,0)✓. Pushes Sac if there.
        {"dir":"left", "id":2, "origin":[3,1]},    # ← to (1,2)✓? Path: (3,1)→(2,1)→(1,1). Target (1,2) is DOWN. Can't reach by going left.
        {"dir":"left", "id":3, "origin":[2,3]},    # ← to (0,3)✓
        {"dir":"down", "id":1, "origin":[2,0]},    # sac ↓ to D(2,2)
    ],
    "D": [{"origin":[2,2]}]
}
# B1 can't reach (1,2) by going left. Fix: B1 goes down, or change target.
# Target id=2 at (1,1): B1(←) (3,1)→(2,1)→(1,1)✓. 2 left moves.
z1["A"] = [
    [0,0], [1,0], [2,0], [3,0,1],
    [1,1,2], [2,1], [3,1],
    [0,2], [1,2], [2,2],
    [0,3,3], [1,3], [2,3]
]
test(z1, "Z1 s-shape")


# Z2: B1 goes down instead for different interaction
z2 = {
    "A": [
        [0,0], [1,0], [2,0], [3,0,1],
        [1,1], [2,1], [3,1],
        [0,2], [1,2,2], [2,2],
        [0,3,3], [1,3], [2,3]
    ],
    "B": [
        {"dir":"right", "id":1, "origin":[0,0]},
        {"dir":"down", "id":2, "origin":[1,1]},    # ↓ to (1,2)✓. 1 down move.
        {"dir":"left", "id":3, "origin":[2,3]},
        {"dir":"down", "id":1, "origin":[2,0]},    # sac
    ],
    "D": [{"origin":[2,2]}]
}
# B1 and Sac both dir=down. When ↓: B1(1,1)→(1,2)✓ and Sac(2,0)→(2,1).
# ↓ again: B1(1,2)→(1,3) overshoots! Sac(2,1)→(2,2)=D dies.
# B1 overshoots if 2 ↓ moves. Need to block B1 at (1,2).
# What blocks B1? If (1,3) has a block... B2(id=3) could be at (1,3).
z2["B"][2] = {"dir":"left", "id":3, "origin":[1,3]}
# B2 at (1,3) blocks B1 overshoot on 2nd ↓!
# B2 going left: (1,3)→(0,3)✓. 1 move.
# But when ← swiped, B2 moves. If ← before ↓↓, B2 leaves (1,3), B1 can overshoot.
# Ordering: ↓↓ first (B1 blocked at (1,2) by B2, Sac reaches D).
# Then ← (B2 to (0,3)✓).
# Then → (B0 to (3,0)✓).
# Then... B1 at (1,2)✓ already? Yes!
test(z2, "Z2 blocked overshoot")

# Z3: Same but with B2 starting at (2,3) and a 5th block
z3 = {
    "A": [
        [0,0], [1,0], [2,0], [3,0,1],
        [1,1], [2,1], [3,1],
        [0,2], [1,2,2], [2,2],
        [0,3,3], [1,3], [2,3]
    ],
    "B": [
        {"dir":"right", "id":1, "origin":[0,0]},
        {"dir":"down", "id":2, "origin":[1,1]},
        {"dir":"left", "id":3, "origin":[2,3]},
        {"dir":"down", "id":1, "origin":[2,0]},    # sac
        {"dir":"up", "id":3, "origin":[1,3]},       # 5th block, id=3 going up
    ],
    "D": [{"origin":[2,2]}]
}
# B4(id=3,↑) at (1,3) blocks B1 overshoot AND goes up.
# B4 target: (0,3)? Can't go up to (0,3)... wait, no cell above (1,3) going up.
# (1,3)→(1,2)→(1,1)→(1,0). B4 target in col 1 upward.
# But (1,2) is target for id=2. B4 is id=3.
# B4 goes to (1,2), (1,1), (1,0). Target (0,3) is id=3 target but in col 0. Can't reach.
# Need id=3 target in col 1. Fix.
z3["A"] = [
    [0,0], [1,0,3], [2,0], [3,0,1],
    [1,1], [2,1], [3,1],
    [0,2], [1,2,2], [2,2],
    [0,3], [1,3], [2,3]
]
# Target id=3 at (1,0). B4(↑) from (1,3)→(1,2)→(1,1)→(1,0)✓
# But B1(↓) at (1,1) blocks. B4 pushes B1? No, B4 goes UP, B1 is above.
# (1,3)→(1,2): B1 might be at (1,2) already if ↓ happened. Push B1 up? No, up pushes up.
# B4 at (1,3)→(1,2). If B1 at (1,2), push B1 to (1,1). B4 at (1,2).
# Then B4(1,2)→(1,1). B1 at (1,1), push B1 to (1,0). B4 at (1,1).
# Then B4(1,1)→(1,0). B1 at (1,0), push B1 to... (1,-1)? No. Blocked.
# B4 can't reach (1,0) if B1 is pushed into it.
# This needs more thought. Skip.


# Z4: Simplify — 4 blocks only, tight interactions
z4 = {
    "A": [
        [0,0], [1,0], [2,0], [3,0,1],
        [1,1,2], [2,1], [3,1],
        [0,2], [1,2], [2,2],
        [0,3,3], [1,3], [2,3]
    ],
    "B": [
        {"dir":"right", "id":1, "origin":[0,0]},   # → to (3,0)✓
        {"dir":"down", "id":2, "origin":[3,1]},    # ↓ to... (3,2) no cell! Fix board.
        {"dir":"left", "id":3, "origin":[2,3]},    # ← to (0,3)✓
        {"dir":"down", "id":1, "origin":[2,0]},    # sac ↓ to D(2,2)
    ],
    "D": [{"origin":[2,2]}]
}
# (3,2) doesn't exist. B1 blocked at (3,1). Target (1,1)? B1 goes DOWN not LEFT.
# B1 at (3,1) dir=down can reach (3,2) if that cell exists. Add it.
z4["A"] = [
    [0,0], [1,0], [2,0], [3,0,1],
    [1,1], [2,1], [3,1],
    [0,2], [1,2], [2,2], [3,2,2],
    [0,3,3], [1,3], [2,3]
]
# 15 cells now. B1(↓) at (3,1) → (3,2)✓. 1 move.
test(z4, "Z4 15cells")


# === Design 4: Compact cross, 5 blocks ===
#   Row 0:       (1,0) (2,0) (3,0)
#   Row 1: (0,1) (1,1) (2,1) (3,1)
#   Row 2: (0,2) (1,2) (2,2) (3,2)
#   Row 3:       (1,3) (2,3)
# 14 cells.

x1 = {
    "A": [
        [1,0,1], [2,0], [3,0],
        [0,1], [1,1], [2,1], [3,1,2],
        [0,2,3], [1,2], [2,2], [3,2],
        [1,3], [2,3]
    ],
    "B": [
        {"dir":"down", "id":1, "origin":[2,0]},    # sac
        {"dir":"left", "id":1, "origin":[3,0]},    # ← to (1,0)✓
        {"dir":"down", "id":2, "origin":[3,1]},    # starts on target — BAD (id=2, target (3,1) is id=2)
        {"dir":"up", "id":3, "origin":[1,3]},      # ↑ to (0,2)? col 1 doesn't reach col 0.
    ],
    "D": [{"origin":[2,2]}]
}
# Multiple issues. Fix.

x2 = {
    "A": [
        [1,0,1], [2,0], [3,0],
        [0,1], [1,1], [2,1,2], [3,1],
        [0,2,3], [1,2], [2,2], [3,2],
        [1,3], [2,3]
    ],
    "B": [
        {"dir":"down", "id":1, "origin":[2,0]},    # sac ↓ to D(2,2)
        {"dir":"left", "id":1, "origin":[3,0]},    # ← (3,0)→(2,0)→(1,0)✓. Pushes Sac if there.
        {"dir":"up", "id":2, "origin":[2,3]},      # ↑ (2,3)→(2,2)→(2,1)✓. Needs D cleared!
        {"dir":"left", "id":3, "origin":[1,3]},    # ← (1,3)→(0,3)? No cell. Blocked!
    ],
    "D": [{"origin":[2,2]}]
}
# B3 stuck. Fix: B3 goes up or change board.
x2["B"][3] = {"dir":"up", "id":3, "origin":[1,3]}  # ↑ (1,3)→(1,2)→(1,1)→(1,0). target (0,2) in col 0. Can't reach.
# Fix target id=3 to col 1
x2["A"][7] = [1,2,3]  # target id=3 at (1,2)
x2["A"][8] = [0,2]    # (0,2) no target
# B3(↑) at (1,3) → (1,2)✓
test(x2, "X2 cross")


# === Design 5: Pinwheel with asymmetric voids ===
#   Row 0: (0,0) (1,0)       (3,0)
#   Row 1: (0,1) (1,1) (2,1) (3,1)
#   Row 2: (0,2) (1,2) (2,2) (3,2)
#   Row 3: (0,3)       (2,3) (3,3)
# 15 cells.

p1 = {
    "A": [
        [0,0], [1,0], [3,0,2],
        [0,1], [1,1,1], [2,1], [3,1],
        [0,2], [1,2], [2,2], [3,2],
        [0,3,3], [2,3], [3,3]
    ],
    "B": [
        {"dir":"down", "id":1, "origin":[1,0]},    # ↓ (1,0)→(1,1)✓. 1 move.
        {"dir":"down", "id":1, "origin":[0,0]},    # sac ↓ col 0
        {"dir":"left", "id":2, "origin":[3,1]},    # ← (3,1)→(2,1)→(1,1)→(0,1). target (3,0)? Can't reach by going left.
        {"dir":"up", "id":3, "origin":[2,3]},      # ↑ col 2
    ],
    "D": [{"origin":[0,2]}]
}
# B2 can't reach (3,0) going left. Fix: B2 direction or target.
# B2 dir=up at (3,2): (3,2)→(3,1)→(3,0)✓. 2 up moves.
p1["B"][2] = {"dir":"up", "id":2, "origin":[3,2]}
# Sac at (0,0) ↓: (0,0)→(0,1)→(0,2)=D→dies. 2 down moves.
# B0 at (1,0) ↓: (1,0)→(1,1)✓. 1 down move. But both move together on ↓!
# ↓1: B0(1,0)→(1,1)✓, Sac(0,0)→(0,1).
# ↓2: B0(1,1)→(1,2) overshoots! Sac(0,1)→(0,2)=D dies.
# B0 overshoots on 2nd ↓. What blocks B0 at (1,1)?
# Nothing. So B0 overshoots target. This is a problem... UNLESS something blocks (1,2).
# What if B3 is at (1,2)?? No, B3 is id=3 at (2,3).
# What if we add a block at (1,2) to block B0?
# Or what if D is at (1,2) and B0 would die? That creates the sacrifice dilemma.
# What if I only need 1 ↓ move? Then Sac must be 1 step from D.
# Sac at (0,1) ↓: (0,1)→(0,2)=D. 1 move.
p2 = {
    "A": [
        [0,0], [1,0], [3,0,2],
        [0,1], [1,1,1], [2,1], [3,1],
        [0,2], [1,2], [2,2], [3,2],
        [0,3,3], [2,3], [3,3]
    ],
    "B": [
        {"dir":"down", "id":1, "origin":[1,0]},    # ↓ (1,0)→(1,1)✓. 1 move.
        {"dir":"down", "id":1, "origin":[0,1]},    # sac ↓ (0,1)→(0,2)=D
        {"dir":"up", "id":2, "origin":[3,2]},      # ↑ (3,2)→(3,1)→(3,0)✓
        {"dir":"up", "id":3, "origin":[2,3]},      # ↑ col 2
    ],
    "D": [{"origin":[0,2]}]
}
# B0 and Sac both ↓. ↓1: B0→(1,1)✓, Sac→(0,2)=D→dies. Both in 1 move!
# B3(id=3,↑) at (2,3) → target (0,3). Goes up: (2,3)→(2,2)→(2,1)→(2,0)→... target (0,3) is col 0. Can't reach.
# Fix: target id=3 in col 2.
p2["A"] = [
    [0,0], [1,0], [3,0,2],
    [0,1], [1,1,1], [2,1,3], [3,1],
    [0,2], [1,2], [2,2], [3,2],
    [0,3], [2,3], [3,3]
]
# B3(↑) at (2,3) → (2,2)→(2,1)✓ target id=3.
test(p2, "P2 pinwheel")


# === Design 6: Back to Z-shape but carefully verified ===

z5 = {
    "A": [
        [0,0], [1,0], [2,0], [3,0,1],
        [1,1,2], [2,1], [3,1],
        [0,2], [1,2], [2,2],
        [0,3,3], [1,3], [2,3]
    ],
    "B": [
        {"dir":"right", "id":1, "origin":[0,0]},   # → (0,0)→(1,0)→(2,0)→(3,0)✓. 3 moves.
        {"dir":"left", "id":2, "origin":[3,1]},    # ← (3,1)→(2,1)→(1,1)✓. 2 moves.
        {"dir":"left", "id":3, "origin":[2,3]},    # ← (2,3)→(1,3)→(0,3)✓. 2 moves.
        {"dir":"down", "id":1, "origin":[2,0]},    # sac ↓ (2,0)→(2,1)→(2,2)=D. 2 moves.
    ],
    "D": [{"origin":[2,2]}]
}
test(z5, "Z5 verified")

# Z6: swap B1 and Sac interaction — B1 must go through D area
z6 = {
    "A": [
        [0,0], [1,0], [2,0], [3,0,1],
        [1,1], [2,1,2], [3,1],
        [0,2], [1,2], [2,2],
        [0,3,3], [1,3], [2,3]
    ],
    "B": [
        {"dir":"right", "id":1, "origin":[0,0]},
        {"dir":"left", "id":2, "origin":[3,1]},    # ← (3,1)→(2,1)✓ target id=2. 1 move.
        {"dir":"left", "id":3, "origin":[2,3]},    # ← (2,3)→(1,3)→(0,3)✓
        {"dir":"down", "id":1, "origin":[2,0]},    # sac
    ],
    "D": [{"origin":[2,2]}]
}
test(z6, "Z6 short B1 path")
