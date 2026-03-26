#!/usr/bin/env python3
"""Level 19 — final fix: Sac2 as id=2 to avoid own-target issue."""

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


# Split: Left 2×4, Right 3×2+1
#   (0,0)(1,0)   (4,0)(5,0)(6,0)
#   (0,1)(1,1)   (4,1)(5,1)(6,1)
#   (0,2)(1,2)   (4,2)
#   (0,3)(1,3)
# 15 cells. Portal: (1,3)↔(4,0). D1(1,2), D2(4,1).

# Z1: Sac2 is id=2 (avoids own-target). C goes through D2.
z1 = {
    "A": [
        [0,0], [1,0], [4,0], [5,0], [6,0],
        [0,1], [1,1], [4,1,2], [5,1], [6,1],
        [0,2], [1,2], [4,2,1],
        [0,3,1], [1,3]
    ],
    "T": [{"id":1, "one_way":False, "pos":[1,3, 4,0]}],
    "B": [
        {"dir":"down", "id":1, "origin":[1,0]},   # A: crosses portal
        {"dir":"down", "id":1, "origin":[0,0]},   # B: stays left
        {"dir":"right", "id":1, "origin":[0,2]},  # Sac1: → to D1(1,2)
        {"dir":"up", "id":2, "origin":[4,2]},     # Sac2: ↑ to D2(4,1). id=2! at (4,2) id=1 target. Wrong-color OK.
        {"dir":"left", "id":2, "origin":[6,1]},   # C: ←← to (4,1)✓ through D2
    ],
    "D": [{"origin":[1,2]}, {"origin":[4,1]}]
}
# 3 id=1 - 1 sac1 = 2 targets: (4,2),(0,3).
# 2 id=2 - 1 sac2 = 1 target: (4,1).
# A→portal→(4,0)→cont(4,1) D2 cleared→(4,1). ↓:A(4,1)→(4,2)✓.
# B→(0,3)✓. C→(4,1)✓. Sac2 dies on D2.
# Ordering: → before ↓2, ↑ before ↓3 AND before ←2.
test(z1, "Z1 final")


# Z2: Like Z1 but Sac2 goes ← instead (different direction)
z2 = {
    "A": [
        [0,0], [1,0], [4,0], [5,0], [6,0],
        [0,1], [1,1], [4,1,2], [5,1], [6,1],
        [0,2], [1,2], [4,2,1],
        [0,3,1], [1,3]
    ],
    "T": [{"id":1, "one_way":False, "pos":[1,3, 4,0]}],
    "B": [
        {"dir":"down", "id":1, "origin":[1,0]},
        {"dir":"down", "id":1, "origin":[0,0]},
        {"dir":"right", "id":1, "origin":[0,2]},  # Sac1
        {"dir":"left", "id":2, "origin":[5,1]},   # Sac2: ← to (4,1)=D2→dies
        {"dir":"left", "id":2, "origin":[6,1]},   # C: ←← to (4,1)✓ after D2 cleared
    ],
    "D": [{"origin":[1,2]}, {"origin":[4,1]}]
}
# When ←: Sac2 AND C both move!
# ←1: Sac2(5,1)→(4,1)=D2→dies! C(6,1)→(5,1).
# ←2: C(5,1)→(4,1)✓ D2 cleared. ✓
# One ← clears D2 via Sac2, second ← moves C to target!
# And → clears D1: Sac1(0,2)→(1,2)=D1→dies.
# Then ↓↓↓ for A and B.
test(z2, "Z2 sac2 ←")


# Z3: Z2 but A needs more setup (block in path)
z3 = {
    "A": [
        [0,0], [1,0], [4,0], [5,0], [6,0],
        [0,1], [1,1], [4,1,2], [5,1], [6,1],
        [0,2], [1,2], [4,2,1],
        [0,3,1], [1,3]
    ],
    "T": [{"id":1, "one_way":False, "pos":[1,3, 4,0]}],
    "B": [
        {"dir":"down", "id":1, "origin":[1,0]},   # A
        {"dir":"down", "id":1, "origin":[0,0]},   # B
        {"dir":"right", "id":1, "origin":[0,2]},  # Sac1
        {"dir":"left", "id":2, "origin":[5,1]},   # Sac2
        {"dir":"left", "id":2, "origin":[6,1]},   # C
        {"dir":"right", "id":1, "origin":[0,1]},  # E: in A's ↓ path! Gets pushed ↓ by A.
    ],
    "D": [{"origin":[1,2]}, {"origin":[4,1]}]
}
# 4 id=1 - 1 sac = 3 survivors. targets id=1: (4,2),(0,3). Only 2! Need 3.
# E goes → from (0,1) to (1,1). Target at (1,1)?
z3["A"][6] = [1,1,1]  # target at (1,1) for id=1
z3["A"][7] = [4,1,2]  # keep target at (4,1) for id=2
# But (1,1) has no block initially. E(→) at (0,1)→(1,1)✓. Then when ↓: A(1,0)→(1,1) E there!
# Push E→(1,2)=D1. If D1 not cleared: E dies!
# Ordering: → (Sac1 clears D1 and E reaches (1,1)) before ↓.
# But → moves BOTH Sac1 and E!
# →: Sac1(0,2)→(1,2)=D1→dies. E(0,1)→(1,1)✓.
# Then ↓: A(1,0)→(1,1) E there! Push E→(1,2). D1 cleared. E at (1,2). Off target!
# E pushed off target by A.
# What if E is NOT at (1,1) target? What if E goes further?
# →: E(0,1)→(1,1). →: E(1,1)→(2,1)?no cell. E stuck at (1,1).
# After A pushes E to (1,2): E at (1,2). Target at (1,1). E off target. Bad.
# Skip E idea.


# Z4: Z2 with wider left side for more routing
z4 = {
    "A": [
        [0,0], [1,0], [2,0], [5,0], [6,0], [7,0],
        [0,1], [1,1], [2,1], [5,1], [6,1], [7,1],
        [0,2], [1,2], [2,2], [5,2,1],
        [0,3], [1,3], [2,3,1]
    ],
    "T": [{"id":1, "one_way":False, "pos":[2,3, 5,0]}],
    "B": [
        {"dir":"down", "id":1, "origin":[2,0]},   # A: crosses col 2
        {"dir":"down", "id":1, "origin":[0,0]},   # B: stays left
        {"dir":"right", "id":1, "origin":[0,2]},  # Sac1: →→ to D1(2,2)?
        {"dir":"left", "id":2, "origin":[6,1]},   # Sac2: ← to D2(5,1)
        {"dir":"left", "id":2, "origin":[7,1]},   # C: ←← to (5,1)? D2 area
    ],
    "D": [{"origin":[2,2]}, {"origin":[5,1]}]
}
# Sac1(→) at (0,2)→(1,2)→(2,2)=D1→dies. 2 → moves.
# But only Sac1 has dir=→? Yes. 2→.
# Sac2(←) at (6,1)→(5,1)=D2→dies. 1←. C(←) at (7,1)→(6,1).
# ←2: C(6,1)→(5,1)✓ D2 cleared.
# But wait (5,1) is target? targets id=2: (5,1) is D2 location.
# Need target at (5,1) for C after D2 cleared.
z4["A"][9] = [5,1,2]
z4["A"][15] = [5,2]
# Fix: (5,2) not target, (5,1) is id=2 target.
# targets id=1: (2,3),(5,2). Hmm, (5,2) still has target marker.
# Rebuild A array properly.
z4["A"] = [
    [0,0], [1,0], [2,0], [5,0], [6,0], [7,0],
    [0,1], [1,1], [2,1], [5,1,2], [6,1], [7,1],
    [0,2], [1,2], [2,2], [5,2,1],
    [0,3,1], [1,3], [2,3]
]
# A exits portal at (5,0)→cont↓(5,1) D2 area. If D2 cleared: A at (5,1)? But (5,1) is id=2 target!
# A is id=1 at (5,1) = id=2 target. Not A's target. A needs id=1 target.
# A continues ↓ to (5,2)✓ id=1. If someone at (5,1) blocks cont → A stays at (5,0).
# After ↓: A(5,0)→(5,1). If (5,1) occupied by C → push. Complex.
# Let me simplify portal to not exit near targets.

# Let me go back to Z2 which already works at 6 moves and is clean enough.
# Z2 was the best design so far for this concept.


# Z5: Like Z1 but with Sac2 direction changed
z5 = {
    "A": [
        [0,0], [1,0], [4,0], [5,0], [6,0],
        [0,1], [1,1], [4,1,2], [5,1], [6,1],
        [0,2], [1,2], [4,2,1],
        [0,3,1], [1,3]
    ],
    "T": [{"id":1, "one_way":False, "pos":[1,3, 4,0]}],
    "B": [
        {"dir":"down", "id":1, "origin":[1,0]},   # A
        {"dir":"down", "id":1, "origin":[0,0]},   # B
        {"dir":"right", "id":1, "origin":[0,2]},  # Sac1: → to D1
        {"dir":"up", "id":2, "origin":[4,2]},     # Sac2: ↑ to D2(4,1). At (4,2) id=1 target. id=2 block. Wrong-color ✓
        {"dir":"left", "id":2, "origin":[6,1]},   # C: ←← to (4,1)✓
    ],
    "D": [{"origin":[1,2]}, {"origin":[4,1]}]
}
# Same as Z1. Sac2 dies on D2 clearing it. Then C reaches (4,1)✓.
# A exits portal, cont (4,1). C already there? Or C arrives after?
# If C at (4,1) before A: A cont blocked, stays at (4,0). Then ↓: A→(4,1) pushes C. Bad.
# If A arrives first at (4,1): then ↓ A→(4,2)✓. Then C arrives at (4,1)✓.
# Need: ↑ (clear D2), ↓↓↓ (A crosses, lands at (4,1), then (4,2)). Then ←← (C to (4,1)).
# But → (clear D1) must also come before ↓2.
test(z5, "Z5 = Z1 retest")


# Z6: Put Sac2 at (5,0) going left to D2
z6 = {
    "A": [
        [0,0], [1,0], [4,0], [5,0], [6,0],
        [0,1], [1,1], [4,1,2], [5,1], [6,1],
        [0,2], [1,2], [4,2,1],
        [0,3,1], [1,3]
    ],
    "T": [{"id":1, "one_way":False, "pos":[1,3, 4,0]}],
    "B": [
        {"dir":"down", "id":1, "origin":[1,0]},
        {"dir":"down", "id":1, "origin":[0,0]},
        {"dir":"right", "id":1, "origin":[0,2]},  # Sac1
        {"dir":"left", "id":2, "origin":[5,0]},   # Sac2: ← to (4,0)=portal! Teleports!
    ],
    "D": [{"origin":[1,2]}, {"origin":[4,1]}]
}
# Sac2 enters portal! Bad. Skip.


# Z7: C needs 3 ← moves, Sac2 clears on 1st ← automatically
z7 = {
    "A": [
        [0,0], [1,0], [4,0], [5,0], [6,0], [7,0],
        [0,1], [1,1], [4,1,2], [5,1], [6,1], [7,1],
        [0,2], [1,2], [4,2,1],
        [0,3,1], [1,3]
    ],
    "T": [{"id":1, "one_way":False, "pos":[1,3, 4,0]}],
    "B": [
        {"dir":"down", "id":1, "origin":[1,0]},
        {"dir":"down", "id":1, "origin":[0,0]},
        {"dir":"right", "id":1, "origin":[0,2]},  # Sac1
        {"dir":"left", "id":2, "origin":[5,1]},   # Sac2: ← to (4,1)=D2→dies
        {"dir":"left", "id":2, "origin":[7,1]},   # C: ←←← to (4,1)✓
    ],
    "D": [{"origin":[1,2]}, {"origin":[4,1]}]
}
# ←1: Sac2→(4,1)=D2→dies. C→(6,1).
# ←2: C→(5,1).
# ←3: C→(4,1)✓ D2 cleared.
# → (1 or 2 moves): Sac1 clears D1.
# ↓↓↓: A crosses, B descends.
# A exits portal→(4,0)→cont(4,1) C there! Stays at (4,0). ↓: A→(4,1) pushes C→(4,2).
# Hmm, A pushes C off target. Same issue.
# What if A targets (4,0)? A exits portal at (4,0), cont(4,1) C there. A stays at (4,0)✓.
# target id=1 at (4,0) instead of (4,2).
z7["A"][2] = [4,0,1]
z7["A"][14] = [4,2]
# But C at (4,1)✓ id=2. A at (4,0)✓ id=1. They don't conflict!
# Wait, does A cont from portal try to go to (4,1)? C there → A stays at (4,0)✓ target.
# Then ↓: A(4,0)→(4,1) C there→push C→(4,2). A at (4,1). Off target!
# Player must NOT do extra ↓ after A is at target. B needs 3 ↓ total.
# A crosses on ↓3. B reaches (0,3)✓ on ↓3 too. No need for ↓4.
test(z7, "Z7 wider right")
