#!/usr/bin/env python3
"""Level 19 — twin D on split board, block crosses through both."""

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
#   (0,0)(1,0)   (4,0)(5,0)
#   (0,1)(1,1)   (4,1)(5,1)
#   (0,2)(1,2)   (4,2)(5,2)
#   (0,3)(1,3)
# 14 cells. Portal: (1,3)↔(4,0)

# A(↓) goes down col 1, hits D1 at (1,2), crosses portal, hits D2 at (4,1).
# Both D blocks must be cleared by separate sacrifices before A passes.

# ── Y1: Twin D, 5 blocks ──
y1 = {
    "A": [
        [0,0], [1,0], [4,0], [5,0],
        [0,1], [1,1], [4,1], [5,1,2],
        [0,2], [1,2], [4,2,1],
        [0,3,1], [1,3]
    ],
    "T": [{"id":1, "one_way":False, "pos":[1,3, 4,0]}],
    "B": [
        {"dir":"down", "id":1, "origin":[1,0]},   # A: crosses, navigates both Ds
        {"dir":"down", "id":1, "origin":[0,0]},   # B: stays left
        {"dir":"right", "id":1, "origin":[0,2]},  # Sac1: → to D1(1,2)→dies
        {"dir":"up", "id":1, "origin":[4,2]},     # Sac2: ↑ to D2(4,1)→dies
        {"dir":"down", "id":2, "origin":[5,0]},   # C: stays right
    ],
    "D": [{"origin":[1,2]}, {"origin":[4,1]}]
}
# 4 id=1 - 2 sacs = 2 targets ✓
# Traps: ↓ before → kills A on D1. ↓↓↓ before ↑ kills A on D2.
test(y1, "Y1 twin D cross")


# ── Y2: Sac1 uses ← instead of → ──
y2 = dict(y1)
y2["B"] = [
    {"dir":"down", "id":1, "origin":[1,0]},
    {"dir":"down", "id":1, "origin":[0,0]},
    {"dir":"left", "id":1, "origin":[1,2]},   # Sac1 at D1! Starts there. Moves away on ←.
    # Actually Sac1 must LAND on D1 to clear it. Starting there doesn't clear.
    {"dir":"up", "id":1, "origin":[4,2]},
    {"dir":"down", "id":2, "origin":[5,0]},
]
# Sac1 at (1,2) = D1 location. Block starts on D. First move takes Sac1 away.
# D1 NOT cleared. Need block to land on D1.
# Fix: Sac1(←) at (1,1): ← to (0,1). Doesn't reach D1(1,2).
# Sac1(↓) at (1,1): ↓ to (1,2)=D1→dies! But Sac1 has same dir as A.
# When ↓: A and Sac1 and B all move. Sac1(1,1)→(1,2)=D1→dies on ↓1.
# A(1,0)→(1,1). Good.
# Then ↓2: A(1,1)→(1,2). D1 cleared. Safe! A at (1,2).
y2["B"][2] = {"dir":"down", "id":1, "origin":[1,1]}
# But wait, A at (1,0)→(1,1). Sac1 at (1,1)! Push! A pushes Sac1→(1,2)=D1→Sac1 dies!
# Both A and Sac1 have dir=↓. Front-to-back sort: Sac1(1,1) y=1, A(1,0) y=0.
# For ↓, highest y first. Sac1 processes first.
# Sac1(1,1)→(1,2)=D1→dies. Then A(1,0)→(1,1). Safe.
# Perfect! Both move on same ↓, Sac1 clears path for A!
test(y2, "Y2 sac1 same col")


# ── Y3: Like Y2 but add ← block on right for more depth ──
y3 = {
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
        {"dir":"down", "id":1, "origin":[1,1]},   # Sac1: same col, clears D1 ahead of A
        {"dir":"up", "id":1, "origin":[4,2]},     # Sac2: clears D2
        {"dir":"left", "id":2, "origin":[5,1]},   # C: ← to target... (4,1)=D2! Dies!
    ],
    "D": [{"origin":[1,2]}, {"origin":[4,1]}]
}
# C(←) at (5,1)→(4,1)=D2→dies! If D2 not cleared.
# Ordering: ↑ before ← to clear D2 for C.
# But ↑ is for Sac2. So Sac2 must clear D2 before C goes ←.
# C(←) needs D2 cleared first. Sac2(↑) clears D2.
# Triple constraint: ↑ before ←, and D1 auto-cleared by Sac1 on ↓.
# Fix C target: (4,1). But after D cleared, (4,1) is just a cell.
y3["A"][6] = [4,1,2]  # target id=2 at (4,1)
y3["A"][11] = [5,2]   # remove id=2 from (5,2)
# C(←) at (5,1)→(4,1)✓ if D2 cleared. ✓
test(y3, "Y3 C through D2")


# ── Y4: Different C position to avoid D2 ──
y4 = {
    "A": [
        [0,0], [1,0], [4,0], [5,0],
        [0,1], [1,1], [4,1], [5,1,2],
        [0,2], [1,2], [4,2,1],
        [0,3,1], [1,3]
    ],
    "T": [{"id":1, "one_way":False, "pos":[1,3, 4,0]}],
    "B": [
        {"dir":"down", "id":1, "origin":[1,0]},   # A
        {"dir":"down", "id":1, "origin":[0,0]},   # B
        {"dir":"down", "id":1, "origin":[1,1]},   # Sac1: clears D1 on same ↓ as A
        {"dir":"up", "id":1, "origin":[4,2]},     # Sac2: clears D2
        {"dir":"down", "id":2, "origin":[5,0]},   # C: ↓ stays right, safe from D
    ],
    "D": [{"origin":[1,2]}, {"origin":[4,1]}]
}
# C(↓) at (5,0)→(5,1)✓.
# 5 id=1 - 2 sacs = 3 survivors. Targets: (4,2),(0,3). Only 2! Need 3.
# Hmm, where does Sac1 clearing create an issue? Sac1(↓) at (1,1) dies on D1(1,2).
# A, B, Sac1 all ↓. A(1,0), B(0,0), Sac1(1,1).
# ↓1: sort by y desc: Sac1(y=1), A(y=0), B(y=0). Sac1→(1,2)=D1→dies. A→(1,1). B→(0,1).
# Good. But 5 id=1 blocks? A, B, Sac1, Sac2. That's 4. Plus C(id=2). Total 5 blocks.
# 4 id=1 - 2 sacs = 2 survivors (A, B). Need 2 targets. ✓
test(y4, "Y4 auto-clear D1")


# ── Y5: Like Y4 but add ← block for more moves ──
y5 = {
    "A": [
        [0,0], [1,0], [4,0], [5,0],
        [0,1], [1,1], [4,1], [5,1,2],
        [0,2], [1,2], [4,2,1],
        [0,3,1], [1,3]
    ],
    "T": [{"id":1, "one_way":False, "pos":[1,3, 4,0]}],
    "B": [
        {"dir":"down", "id":1, "origin":[1,0]},   # A
        {"dir":"down", "id":1, "origin":[0,0]},   # B
        {"dir":"down", "id":1, "origin":[1,1]},   # Sac1
        {"dir":"up", "id":1, "origin":[4,2]},     # Sac2
        {"dir":"down", "id":2, "origin":[5,0]},   # C
        {"dir":"left", "id":1, "origin":[5,1]},   # E: ← on right side
    ],
    "D": [{"origin":[1,2]}, {"origin":[4,1]}]
}
# 5 id=1 - 2 sacs = 3 survivors. Targets: (4,2),(0,3). Only 2. Need 3.
# E needs target. E(←) at (5,1)→(4,1)=D2→dies! Unless D2 cleared.
# E is NOT a sacrifice. E needs to survive and reach target.
# After D2 cleared: E(5,1)→(4,1)✓? target at (4,1)?
y5["A"][6] = [4,1,1]  # target id=1 at (4,1)
# targets id=1: (4,2),(0,3),(4,1). 3 targets ✓
# Ordering: ↑ must clear D2 before ← (for E to safely reach (4,1)).
# And ↓ auto-clears D1. And ← needs to happen after ↑.
test(y5, "Y5 E through D2")


# ── Y6: Without Sac1 (D1 in A's push path instead) ──
y6 = {
    "A": [
        [0,0], [1,0], [4,0], [5,0],
        [0,1], [1,1], [4,1], [5,1,2],
        [0,2], [1,2], [4,2,1],
        [0,3,1], [1,3]
    ],
    "T": [{"id":1, "one_way":False, "pos":[1,3, 4,0]}],
    "B": [
        {"dir":"down", "id":1, "origin":[1,0]},   # A
        {"dir":"down", "id":1, "origin":[0,0]},   # B
        {"dir":"right", "id":1, "origin":[0,2]},  # Sac1: → to D1(1,2)→dies
        {"dir":"up", "id":1, "origin":[4,2]},     # Sac2: ↑ to D2(4,1)→dies
        {"dir":"down", "id":2, "origin":[5,0]},   # C
    ],
    "D": [{"origin":[1,2]}, {"origin":[4,1]}]
}
# Sac1(→) at (0,2)→(1,2)=D1→dies. 1→ move.
# → before ↓↓ to clear A's path.
# ↑ before ↓↓↓ to clear portal exit.
test(y6, "Y6 → sac1")


# ── Y7: Y6 with more blocks for deeper puzzle ──
y7 = {
    "A": [
        [0,0], [1,0], [4,0], [5,0],
        [0,1], [1,1], [4,1], [5,1],
        [0,2], [1,2], [4,2,1], [5,2,2],
        [0,3,1], [1,3]
    ],
    "T": [{"id":1, "one_way":False, "pos":[1,3, 4,0]}],
    "B": [
        {"dir":"down", "id":1, "origin":[1,0]},   # A
        {"dir":"down", "id":1, "origin":[0,0]},   # B
        {"dir":"right", "id":1, "origin":[0,2]},  # Sac1: → to D1
        {"dir":"up", "id":1, "origin":[4,2]},     # Sac2: ↑ to D2. on own target! Fix
        {"dir":"left", "id":2, "origin":[5,1]},   # C: ← to target
        {"dir":"left", "id":1, "origin":[5,0]},   # E: ← through cleared D2 area
    ],
    "D": [{"origin":[1,2]}, {"origin":[4,1]}]
}
# Sac2 at (4,2) which is id=1 target. BAD.
y7["A"][10] = [4,2]
# Remove target from (4,2). Now targets id=1: (0,3). Only 1 target for 4 id=1 survivors (A,B,E + whoever). Too few.
# Let me reconsider.
# id=1 blocks: A, B, Sac1, Sac2, E = 5. Minus 2 sacs = 3 survivors.
# Need 3 id=1 targets.
y7["A"] = [
    [0,0], [1,0], [4,0], [5,0],
    [0,1], [1,1], [4,1,1], [5,1],
    [0,2], [1,2], [4,2], [5,2,2],
    [0,3,1], [1,3,1]
]
# targets id=1: (4,1),(0,3),(1,3). E(←) at (5,0)→(4,0). Portal at (4,0)! E enters portal→(1,3)→cont←(0,3)!
# E teleports to left side! Unintended.
# Fix: E doesn't enter portal. E(↓) instead.
y7["B"][5] = {"dir":"down", "id":1, "origin":[5,0]}
# E(↓) at (5,0)→(5,1). C at (5,1)! Push C→(5,2)✓. E at (5,1).
# Then ↓: E(5,1)→(5,2) C there! Push→no cell. E blocked.
# E needs target at (5,1)? No id=1 target there.
# Skip E. 4 blocks + C = 5 total.
# 3 id=1 - 2 sacs = 1 survivor. Just A. 1 target.
# Too simple with only A crossing.

# ── Y8: Wider right island ──
y8 = {
    "A": [
        [0,0], [1,0], [4,0], [5,0], [6,0],
        [0,1], [1,1], [4,1], [5,1], [6,1],
        [0,2], [1,2], [4,2,1],
        [0,3,1], [1,3]
    ],
    "T": [{"id":1, "one_way":False, "pos":[1,3, 4,0]}],
    "B": [
        {"dir":"down", "id":1, "origin":[1,0]},   # A: crosses
        {"dir":"down", "id":1, "origin":[0,0]},   # B: stays left
        {"dir":"right", "id":1, "origin":[0,2]},  # Sac1: → to D1(1,2)
        {"dir":"up", "id":1, "origin":[4,2]},     # Sac2: ↑ to D2(4,1)
        {"dir":"left", "id":2, "origin":[6,1]},   # C: ← across right island
    ],
    "D": [{"origin":[1,2]}, {"origin":[4,1]}]
}
# C(←) at (6,1)→(5,1)→(4,1)=D2! If not cleared: dies!
# Ordering: ↑ before ←← for C.
# targets id=1: (4,2),(0,3). 4 id=1 - 2 sacs = 2 ✓
# target id=2: where? C ends at (4,1) if D2 cleared. target at (4,1)?
y8["A"][7] = [4,1,2]  # target at (4,1) for id=2
# Wait, but A also exits portal to (4,1) if cont available.
# A exits at (4,0)→cont↓(4,1). But C might be at (4,1)!
# If ← before ↓↓↓: C at (4,1). A exits portal, cont(4,1) has C. A stays at (4,0).
# Then ↓: A(4,0)→(4,1) C there! Push C→(4,2)✓ id=1 target. But C is id=2.
# Hmm. A pushes C off its target.
# What if C targets (4,1) and A targets (4,2)?
# Then after A pushes C: C at (4,2), A at (4,1). C off target. Bad.
# What if C passes through (4,1) and continues? C(←) at (4,1)... goes LEFT.
# (4,1)→(3,1)?no cell. C stuck at (4,1)✓ if that's the target.
# A arrives at (4,0). Needs to get to (4,2). ↓: A(4,0)→(4,1) C there. Push C→(4,2). A at (4,1).
# C at (4,2) which is id=1 target. C is id=2. Wrong target.
# A at (4,1) which is id=2 target. A is id=1. Wrong target.
# Neither on own target! Not a win.
# Need different arrangement. Let C not end up where A goes.

# C(←) goes to (5,1) target instead?
y8["A"] = [
    [0,0], [1,0], [4,0], [5,0], [6,0],
    [0,1], [1,1], [4,1], [5,1,2], [6,1],
    [0,2], [1,2], [4,2,1],
    [0,3,1], [1,3]
]
# C(←) at (6,1)→(5,1)✓ id=2. 1← move. Doesn't go through D2.
# Then who creates the ← ordering constraint?
# Nobody goes through D2 area (col 4 row 1). Only A does via portal.
# A exits portal at (4,0)→cont(4,1)=D2. Must clear D2 first via ↑.
test(y8, "Y8 wide right")


# ── Y9: Y8 with C needing 2← and going through D area ──
y9 = {
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
        {"dir":"up", "id":1, "origin":[4,2]},     # Sac2
        {"dir":"left", "id":2, "origin":[6,1]},   # C: ←← to (4,1)✓ through D2 area!
    ],
    "D": [{"origin":[1,2]}, {"origin":[4,1]}]
}
# C(←) at (6,1)→(5,1)→(4,1)=D2→dies if not cleared!
# Must ↑ (Sac2 clears D2) before C's 2nd ← move.
# And must → (Sac1 clears D1) before A's 2nd ↓.
# Triple ordering: → before ↓2, ↑ before ↓3 AND before ←2.
test(y9, "Y9 C through D2")
