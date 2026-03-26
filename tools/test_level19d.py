#!/usr/bin/env python3
"""Level 19 final round — push-through-portal on split board."""

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


# Split board: Left 2×4, Right 2×3
#   Left:        Right:
#   (0,0)(1,0)   (4,0)(5,0)
#   (0,1)(1,1)   (4,1)(5,1)
#   (0,2)(1,2)   (4,2)(5,2)
#   (0,3)(1,3)
# 14 cells. Portal: (0,3)↔(5,0)

P = [{"id":1, "one_way":False, "pos":[0,3, 5,0]}]

# ── X1: A pushes G through portal, D on right, clean ──
x1 = {
    "A": [
        [0,0], [1,0], [4,0,2], [5,0],
        [0,1], [1,1], [4,1], [5,1,1],
        [0,2], [1,2], [4,2], [5,2,1],
        [0,3], [1,3,1]
    ],
    "T": P,
    "B": [
        {"dir":"down", "id":1, "origin":[0,0]},   # A: pushes G ↓ through portal
        {"dir":"right", "id":1, "origin":[0,1]},  # G: pushed through portal by A
        {"dir":"down", "id":1, "origin":[1,0]},   # B: stays left
        {"dir":"up", "id":1, "origin":[5,2]},     # Sac: clears D at (5,1)
        {"dir":"left", "id":2, "origin":[5,0]},   # C: clears portal exit
    ],
    "D": [{"origin":[5,1]}]
}
test(x1, "X1 push-through")

# ── X2: Like X1 but G needs → after crossing ──
x2 = dict(x1)
x2["A"] = [
    [0,0], [1,0], [4,0,2], [5,0],
    [0,1], [1,1], [4,1], [5,1,1],
    [0,2], [1,2], [4,2], [5,2,1],
    [0,3], [1,3,1]
]
# Same targets. G pushed to (5,1) then → to (5,2)✓. A lands at (5,1)✓.
# But G dir=→, so → moves G. After → G at (5,2)✓, then ↓ A to (5,1)✓.
test(x2, "X2 G needs →")

# ── X3: Twin D blocks on split board ──
x3 = {
    "A": [
        [0,0], [1,0], [4,0,2], [5,0],
        [0,1], [1,1], [4,1], [5,1,1],
        [0,2], [1,2], [4,2], [5,2,1],
        [0,3], [1,3,1]
    ],
    "T": P,
    "B": [
        {"dir":"down", "id":1, "origin":[0,0]},   # A: pushes G through portal
        {"dir":"right", "id":1, "origin":[0,1]},  # G: pushed through
        {"dir":"down", "id":1, "origin":[1,0]},   # B: stays left
        {"dir":"up", "id":1, "origin":[5,2]},     # Sac1: clears D(5,1)
        {"dir":"left", "id":1, "origin":[1,2]},   # Sac2: clears D(0,2)
        {"dir":"left", "id":2, "origin":[5,0]},   # C
    ],
    "D": [{"origin":[5,1]}, {"origin":[0,2]}]
}
# 5 id=1 - 2 sacs = 3 targets. id=1 targets: (5,1),(5,2),(1,3). Wait, 3 targets.
# A→(5,1)? Let me trace.
# ← clears D(0,2) via Sac2 and moves C
# ↑ clears D(5,1) via Sac1
# ↓↓↓ pushes A and G through portal, B to bottom
test(x3, "X3 twin D split")


# ── X4: Portal (1,3)↔(4,0), A in col 1 ──
x4 = {
    "A": [
        [0,0], [1,0], [4,0], [5,0],
        [0,1], [1,1], [4,1,1], [5,1,2],
        [0,2], [1,2], [4,2],
        [0,3,1], [1,3]
    ],
    "T": [{"id":1, "one_way":False, "pos":[1,3, 4,0]}],
    "B": [
        {"dir":"down", "id":1, "origin":[1,0]},   # A: crosses col 1 → portal → right side
        {"dir":"down", "id":1, "origin":[0,0]},   # B: stays left col 0
        {"dir":"up", "id":1, "origin":[4,2]},     # Sac: clears D(4,1)
        {"dir":"down", "id":2, "origin":[5,0]},   # C: stays right col 5
    ],
    "D": [{"origin":[4,1]}]
}
# A(↓) col 1: (1,0)→(1,1)→(1,2)→(1,3)=P→(4,0)→cont↓(4,1)=D→dies if not cleared
# Sac(↑) at (4,2)→(4,1)=D→dies
# B(↓) at (0,0)→(0,1)→(0,2)→(0,3)✓
# C(↓) at (5,0)→(5,1)✓
# When ↓: A, B, C all move. When ↑: Sac moves.
# ↑ must come before A reaches portal (↓3).
test(x4, "X4 col1 cross")

# X5: Like X4 but with interaction on left side
x5 = {
    "A": [
        [0,0], [1,0], [4,0], [5,0],
        [0,1], [1,1], [4,1,1], [5,1,2],
        [0,2], [1,2], [4,2,1],
        [0,3,1], [1,3]
    ],
    "T": [{"id":1, "one_way":False, "pos":[1,3, 4,0]}],
    "B": [
        {"dir":"down", "id":1, "origin":[1,0]},   # A: crosses
        {"dir":"down", "id":1, "origin":[0,0]},   # B: stays left
        {"dir":"up", "id":1, "origin":[4,2]},     # Sac: clears D. starts on id=1 target! BAD
        {"dir":"down", "id":2, "origin":[5,0]},   # C
        {"dir":"right", "id":1, "origin":[0,1]},  # E: blocked by A in col 1
    ],
    "D": [{"origin":[4,1]}]
}
# Sac on own target (4,2,1). Fix.
x5["A"][10] = [4,2]
# Now targets id=1: (4,1),(0,3). Only 2 targets for 4 id=1 blocks - 1 sac = 3. Need 3 targets.
# Add target.
x5["A"] = [
    [0,0], [1,0], [4,0], [5,0],
    [0,1], [1,1,1], [4,1,1], [5,1,2],
    [0,2], [1,2], [4,2],
    [0,3,1], [1,3]
]
# targets id=1: (1,1),(4,1),(0,3). E(→) at (0,1)→(1,1)✓? But A going ↓ through (1,1).
# When ↓: A(1,0)→(1,1). E at (0,1) dir=→, →(0,1)→(1,1) A at (1,1)? E goes → on → swipe.
# If → before ↓: E(0,1)→(1,1)✓. Then ↓: A(1,0)→(1,1) E there! Push E→(1,2). A at (1,1).
# E pushed off target! Bad.
# If ↓ first: A→(1,1). Then →: E(0,1)→(1,1) A there! Push A→(1,2)? Wait, → pushes RIGHT.
# E(0,1)→(1,1) A at (1,1). Push A→(2,1)?no cell? Wait, (2,1) doesn't exist in the board.
# Board left side: cols 0-1. (2,1) is in the gap. E blocked.
# So E must go to (1,1) before A. Then A must not push E.
# After E at (1,1)✓, A goes ↓ from (1,0)→(1,1) pushes E→(1,2). E off target.
# DEADLOCK: E at (1,1) always gets pushed by A.
# Skip E interaction.


# ── X6: X4 with added → block on right for more depth ──
x6 = {
    "A": [
        [0,0], [1,0], [4,0], [5,0],
        [0,1], [1,1], [4,1], [5,1],
        [0,2], [1,2], [4,2,1], [5,2,2],
        [0,3,1], [1,3]
    ],
    "T": [{"id":1, "one_way":False, "pos":[1,3, 4,0]}],
    "B": [
        {"dir":"down", "id":1, "origin":[1,0]},   # A: crosses
        {"dir":"down", "id":1, "origin":[0,0]},   # B: stays left
        {"dir":"up", "id":1, "origin":[4,2]},     # Sac: clears D. on own target! Fix
        {"dir":"right", "id":2, "origin":[4,1]},  # C: → on right side
    ],
    "D": [{"origin":[4,1]}]
}
# Sac at (4,2) which is id=1 target. BAD. And C at (4,1) which is D location.
# Block starts on D cell? D is separate. After first move, checked.
# C at (4,1): C dir=→. On → swipe, C(4,1)→(5,1). C leaves D cell safely.
# Then Sac needs to reach D(4,1). Sac(↑) at (4,2)→(4,1)=D→dies.
# But C was at (4,1). If C moves → first, (4,1) empty for Sac.
# Fix Sac target issue: remove target from (4,2).
x6["A"][10] = [4,2]
# targets id=1: (0,3). Only 1 target for 3 id=1 blocks - 1 sac = 2. Need 2.
# Add target.
x6["A"] = [
    [0,0], [1,0], [4,0], [5,0],
    [0,1], [1,1], [4,1], [5,1,1],
    [0,2], [1,2], [4,2], [5,2,2],
    [0,3,1], [1,3]
]
# A exits portal at (4,0)→cont↓(4,1)=D→dies if not cleared!
# After D cleared: A cont to (4,1). Then ↓: A(4,1)→(4,2).
# target (5,1) id=1. A at (4,2). Can't reach (5,1) going ↓. Fix target.
# target at (4,2)?
x6["A"] = [
    [0,0], [1,0], [4,0], [5,0],
    [0,1], [1,1], [4,1], [5,1],
    [0,2], [1,2], [4,2,1], [5,2,2],
    [0,3,1], [1,3]
]
# A→(4,1)→(4,2)✓. C(→) at (4,1)→(5,1)→(5,2)✓ id=2.
# But C starts on D(4,1)! When ↓ before →: Sac(4,2)↑ to (4,1)=D but C still there!
# ↑: Sac(4,2)→(4,1). C at (4,1)! Push C↑ to (4,0). Sac at (4,1)=D→dies.
# C pushed to (4,0). Then →: C(4,0)→(5,0). Target (5,2). Need more →.
# →→: C(4,0)→(5,0)→(5,1)?? Wait, board right side: (4,0)(5,0),(4,1)(5,1),(4,2)(5,2).
# C at (5,0). →: no cell right of (5,0) at (6,0). C stuck. Fix: wider right side.
# This is getting too complicated. Let me just go with X4.
test(x6, "X6 C on D")


# ── X7: X4 but A also pushes a block on left side ──
x7 = {
    "A": [
        [0,0], [1,0], [4,0], [5,0],
        [0,1], [1,1], [4,1,1], [5,1,2],
        [0,2], [1,2], [4,2],
        [0,3,1], [1,3]
    ],
    "T": [{"id":1, "one_way":False, "pos":[1,3, 4,0]}],
    "B": [
        {"dir":"down", "id":1, "origin":[1,0]},   # A
        {"dir":"down", "id":1, "origin":[0,0]},   # B
        {"dir":"up", "id":1, "origin":[4,2]},     # Sac
        {"dir":"down", "id":2, "origin":[5,0]},   # C
        {"dir":"right", "id":1, "origin":[1,1]},  # E: in A's ↓ path! Gets pushed.
    ],
    "D": [{"origin":[4,1]}]
}
# When ↓1: A(1,0)→(1,1) E there! Push E→(1,2)? No, push is ↓. E→(1,2). A at (1,1).
# Actually E dir=→. A pushes E DOWN (push in A's movement direction ↓). E goes from (1,1) to (1,2).
# Then ↓2: A(1,1)→(1,2) E at (1,2)! Push E→(1,3)=P→(4,0)→cont↓(4,1)=D!
# E pushed through portal onto D! E dies if D not cleared!
# So ↑ before ↓2 to clear D. E lands safely at (4,1)✓ target!
# Then ↓3: A(1,2)→(1,3)=P→(4,0)→cont↓(4,1) E there! Stays at (4,0).
# Wait, (4,0) not a target. Hmm.
# targets id=1: (4,1),(0,3). A at (4,0). Not target. Need target at (4,0) or A continues.
# ↓4: A(4,0)→(4,1) E there! Push E→(4,2). A at (4,1)✓.
# E pushed off target to (4,2). Bad.
# Unless 3 targets: (4,1),(4,2),(0,3). E at (4,2)✓?
# 5 id=1 - 1 sac = 4. Need 4 targets! Too many.
# 4 id=1 - 1 sac = 3 targets. I have A,B,E,Sac = 4 id=1. 4-1=3 targets: (4,1),(0,3), and one more.
# What if E ends at (4,2)✓? target at (4,2).
x7["A"] = [
    [0,0], [1,0], [4,0], [5,0],
    [0,1], [1,1], [4,1,1], [5,1,2],
    [0,2], [1,2], [4,2,1],
    [0,3,1], [1,3]
]
# targets id=1: (4,1),(4,2),(0,3). But Sac at (4,2) starts on own target! BAD.
x7["A"][10] = [4,2]
# Remove target from (4,2). Only 2 targets for 3 survivors. Need 3rd.
# Hmm. Let me just add a target at (1,3).
x7["A"] = [
    [0,0], [1,0], [4,0], [5,0],
    [0,1], [1,1], [4,1,1], [5,1,2],
    [0,2], [1,2], [4,2],
    [0,3,1], [1,3,1]
]
# targets id=1: (4,1),(0,3),(1,3). B→(0,3)✓ or (1,3)? B(↓) col 0 to (0,3)✓.
# Who gets (1,3)? E pushed through portal? Doesn't end at (1,3).
# Skip, this is too tangled.
test(x7, "X7 push E through")


# ── X8: Simplify everything — verified paths, 4 blocks ──
x8 = {
    "A": [
        [0,0], [1,0], [4,0,2], [5,0],
        [0,1], [1,1], [4,1,1], [5,1],
        [0,2], [1,2], [4,2],
        [0,3,1], [1,3]
    ],
    "T": [{"id":1, "one_way":False, "pos":[1,3, 4,0]}],
    "B": [
        {"dir":"down", "id":1, "origin":[1,0]},   # A: ↓↓↓ crosses portal to (4,1)✓
        {"dir":"down", "id":1, "origin":[0,0]},   # B: ↓↓↓ to (0,3)✓
        {"dir":"up", "id":1, "origin":[4,2]},     # Sac: ↑ to D(4,1)→dies
        {"dir":"left", "id":2, "origin":[5,0]},   # C: ← to (4,0)✓
    ],
    "D": [{"origin":[4,1]}]
}
# 3 id=1 - 1 sac = 2 targets ✓
# A enters portal at (1,3)→(4,0)→cont(4,1)=D. Must clear first!
# When ↓: A and B move. When ↑: Sac. When ←: C.
# ↑ before 3rd ↓ (when A reaches portal).
# ← any time (independent).
# C at (5,0). ← to (4,0). A will arrive at (4,0) via portal. If C at (4,0) when A arrives:
# A exits portal at (4,0). C at (4,0)? Exit occupied. Cont (4,1). D cleared. A at (4,1)✓.
# Actually C's position doesn't matter for A's crossing (portal bypasses exit if cont available).
test(x8, "X8 simple 4blk")


# ── X9: Like X8 but wider right island for more routing ──
x9 = {
    "A": [
        [0,0], [1,0], [4,0], [5,0], [6,0],
        [0,1], [1,1], [4,1], [5,1,1], [6,1,2],
        [0,2], [1,2], [4,2],
        [0,3,1], [1,3]
    ],
    "T": [{"id":1, "one_way":False, "pos":[1,3, 4,0]}],
    "B": [
        {"dir":"down", "id":1, "origin":[1,0]},
        {"dir":"down", "id":1, "origin":[0,0]},
        {"dir":"up", "id":1, "origin":[4,2]},     # Sac
        {"dir":"left", "id":2, "origin":[6,0]},   # C: ←← to target
    ],
    "D": [{"origin":[4,1]}]
}
# A exits portal→(4,0)→cont(4,1)=D. After clearing: A at (4,1). ↓: A(4,1)→(4,2)?
# Sac was at (4,2) but died. (4,2) empty? Sac went UP to (4,1)=D→died. (4,2) empty. A→(4,2).
# But A at (4,2) not a target. Target (5,1). A goes ↓ not →. Can't reach (5,1).
# Fix: target at (4,1) or (4,2).
# What if Sac takes 2↑ to reach D? Sac at (4,2)→(4,1)=D→dies. Just 1↑.
# A→(4,1)✓ if target there.
x9["A"][7] = [4,1,1]  # target at (4,1) instead of (5,1)
# C(←) at (6,0)→(5,0)→(4,0). A exits portal to (4,0) too. If C at (4,0), A bypasses to cont(4,1)✓.
# But C needs target at (6,1) which is id=2. C goes LEFT: (6,0)→(5,0)→(4,0). Can't reach (6,1) going left.
# Fix: C target at (4,0)? Or (5,0)?
x9["A"] = [
    [0,0], [1,0], [4,0,2], [5,0], [6,0],
    [0,1], [1,1], [4,1,1], [5,1], [6,1],
    [0,2], [1,2], [4,2],
    [0,3,1], [1,3]
]
# C(←)→(5,0)→(4,0)✓ id=2.
test(x9, "X9 wide right")
