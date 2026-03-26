#!/usr/bin/env python3
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

# Redesign: 1-col gap (col 2 empty), portals NOT on targets
#
#   Left:        Right:
#   (0,0)(1,0)   (3,0)(4,0)(5,0)
#   (0,1)(1,1)   (3,1)(4,1)(5,1)
#   (0,2)(1,2)   (3,2)
#   (0,3)(1,3)
#
# 15 cells. Portal: (1,3)↔(3,0) — neither is a target.
# D1(1,2), D2(3,1). Targets NOT on portal or D cells.

fix1 = {
    "A": [
        [0,0], [1,0], [3,0], [4,0], [5,0],
        [0,1], [1,1], [3,1], [4,1,2], [5,1],
        [0,2], [1,2], [3,2,1],
        [0,3,1], [1,3]
    ],
    "T": [{"id":1, "one_way":False, "pos":[1,3, 3,0]}],
    "B": [
        {"dir":"down", "id":1, "origin":[1,0]},   # A: crosses portal
        {"dir":"down", "id":1, "origin":[0,0]},   # B: stays left
        {"dir":"right", "id":1, "origin":[0,2]},  # Sac1: → to D1(1,2)
        {"dir":"left", "id":1, "origin":[4,1]},   # Sac2: ← to D2(3,1). At (4,1) id=2 target. Wrong-color ✓
        {"dir":"left", "id":2, "origin":[5,1]},   # C: ← to (4,1)✓
    ],
    "D": [{"origin":[1,2]}, {"origin":[3,1]}]
}
# Targets: id=1 at (3,2),(0,3). id=2 at (4,1).
# Portals: (1,3),(3,0) — no targets there ✓
# D blocks: (1,2),(3,1) — no targets there ✓
# A exits portal at (3,0)→cont↓(3,1) D2 cleared→A at (3,1). ↓: A→(3,2)✓.
test(fix1, "FIX1")

# Same but target at (3,1) for A (skip 4th ↓)
fix2 = dict(fix1)
fix2["A"] = [
    [0,0], [1,0], [3,0], [4,0], [5,0],
    [0,1], [1,1], [3,1,1], [4,1,2], [5,1],
    [0,2], [1,2], [3,2],
    [0,3,1], [1,3]
]
# target at (3,1) where D2 was — D and target on same cell. Might be OK functionally.
test(fix2, "FIX2 target on D cell")

# Smaller right island — remove (5,0)
fix3 = {
    "A": [
        [0,0], [1,0], [3,0], [4,0],
        [0,1], [1,1], [3,1], [4,1,2],
        [0,2], [1,2], [3,2,1],
        [0,3,1], [1,3]
    ],
    "T": [{"id":1, "one_way":False, "pos":[1,3, 3,0]}],
    "B": [
        {"dir":"down", "id":1, "origin":[1,0]},
        {"dir":"down", "id":1, "origin":[0,0]},
        {"dir":"right", "id":1, "origin":[0,2]},  # Sac1
        {"dir":"left", "id":1, "origin":[4,1]},   # Sac2: wrong-color on (4,1) id=2 target
        {"dir":"left", "id":2, "origin":[4,0]},   # C: ← to... (3,0)=portal! Teleports! Bad.
    ],
    "D": [{"origin":[1,2]}, {"origin":[3,1]}]
}
# C enters portal. Fix: C elsewhere.
fix3["B"][4] = {"dir":"down", "id":2, "origin":[4,0]}
# C(↓) at (4,0)→(4,1)✓ id=2. 1 move. But Sac2 at (4,1)!
# Sac2 must move first. ←: Sac2→(3,1)=D2→dies. Then ↓: C→(4,1)✓.
# When ↓: A, B, C move. When ←: Sac2 moves.
# ← first: Sac2→dies.
# Then ↓: C(4,0)→(4,1)✓. A and B descend.
# But: (4,0) is where A exits portal! A enters (1,3)=P→exits(3,0)→cont(3,1). Not (4,0). OK.
test(fix3, "FIX3 compact right")

# fix4: Like fix1 but with C starting further right
fix4 = {
    "A": [
        [0,0], [1,0], [3,0], [4,0], [5,0],
        [0,1], [1,1], [3,1], [4,1,2], [5,1],
        [0,2], [1,2], [3,2,1],
        [0,3,1], [1,3]
    ],
    "T": [{"id":1, "one_way":False, "pos":[1,3, 3,0]}],
    "B": [
        {"dir":"down", "id":1, "origin":[1,0]},
        {"dir":"down", "id":1, "origin":[0,0]},
        {"dir":"right", "id":1, "origin":[0,2]},
        {"dir":"left", "id":1, "origin":[4,1]},   # Sac2
        {"dir":"down", "id":2, "origin":[4,0]},   # C: ↓ to (4,1)✓ after Sac2 leaves
    ],
    "D": [{"origin":[1,2]}, {"origin":[3,1]}]
}
# When ↓: A, B, C move. ←: Sac2.
# If ← first: Sac2(4,1)→(3,1)=D2→dies. Then ↓: C(4,0)→(4,1)✓.
# But ↓ also moves A: ↓↓↓→portal. And → for Sac1.
test(fix4, "FIX4 C goes down")

# fix5: Like fix1 but ensure C's path doesn't cross portal
fix5 = {
    "A": [
        [0,0], [1,0], [3,0], [4,0], [5,0],
        [0,1], [1,1], [3,1], [4,1], [5,1],
        [0,2], [1,2], [3,2,1],
        [0,3,1], [1,3]
    ],
    "T": [{"id":1, "one_way":False, "pos":[1,3, 3,0]}],
    "B": [
        {"dir":"down", "id":1, "origin":[1,0]},
        {"dir":"down", "id":1, "origin":[0,0]},
        {"dir":"right", "id":1, "origin":[0,2]},   # Sac1
        {"dir":"left", "id":1, "origin":[5,1]},    # Sac2: ← to (4,1)→(3,1)=D2→dies. 2←.
        {"dir":"left", "id":2, "origin":[5,0]},    # C: ← to (4,0). Portal at (3,0)? If C goes further: (4,0)→(3,0)=portal! Bad.
    ],
    "D": [{"origin":[1,2]}, {"origin":[3,1]}]
}
# C enters portal on 2nd ←. Fix: C stops before portal. Target at (4,0)?
fix5["A"][3] = [4,0,2]  # target id=2 at (4,0)
# C(←) at (5,0)→(4,0)✓. 1 move. Doesn't hit portal.
# Sac2(←) at (5,1)→(4,1)→(3,1)=D2→dies. 2← moves.
# When ←: Sac2 AND C both move.
# ←1: Sac2(5,1)→(4,1). C(5,0)→(4,0)✓. Done for C.
# ←2: Sac2(4,1)→(3,1)=D2→dies. C(4,0)→(3,0)=portal! C teleports! Bad!
# C gets dragged into portal on the 2nd ← because both have dir=←.
# Fix: C must NOT have more ← moves after reaching target.
# But the player must swipe ← twice for Sac2. C auto-moves on both swipes.
# Need C to be blocked at (4,0) on 2nd ←. What blocks C?
# (3,0) is portal. C goes to (3,0)=portal→teleports. Unavoidable.
# Fix: C has different direction. C(↓,id=2) at (4,0)→(4,1). Target at (4,1)?
fix5["A"][3] = [4,0]
fix5["A"][8] = [4,1,2]  # target id=2 at (4,1)
fix5["B"][4] = {"dir":"down", "id":2, "origin":[4,0]}
# C(↓) at (4,0)→(4,1)✓. When ↓: A, B, C all move.
# Sac2 at (5,1): ← to (4,1)→(3,1)=D2. When ←: only Sac2 moves.
# ←1: Sac2(5,1)→(4,1). C at (4,0)→↓ not ← on this swipe. C doesn't move on ←.
# Wait, C is ↓ not ←. C only moves on ↓ swipe. ✓ No conflict with ←.
# ←2: Sac2(4,1)→(3,1)=D2→dies. Only Sac2 moves.
# Then ↓: A, B, C all move. C(4,0)→(4,1)✓. But Sac2 was at (4,1) before ←. After ←2 Sac2 died. (4,1) clear. ✓.
# But wait, ↓ comes AFTER ←←. So C goes to (4,1) which is clear. ✓.
test(fix5, "FIX5 C goes ↓")
