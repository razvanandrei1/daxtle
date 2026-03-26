#!/usr/bin/env python3
"""Quick test harness for designing a single level."""

import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from solve_levels import parse_level, solve, ARROWS

def test(data, label=""):
    board, blocks, teleport_map, destroy_set = parse_level(data)
    solution = solve(board, blocks, teleport_map, destroy_set)
    if solution is None:
        print(f"{label}: NO SOLUTION (within 20 moves)")
    else:
        arrows = " ".join(ARROWS[d] for d in solution)
        print(f"{label} ({len(solution)} moves): {arrows}")
        print(f"  Dirs: {' '.join(solution)}")
    return solution


# ══════════════════════════════════════════════════════════════
# Level 16 — "Teleport Sacrifice"
# Concept: Portal + Destroy combined for the first time.
# Sacrifice block goes DOWN through portal to reach D on far side.
# Trap: moving ↓ before ← pushes B1 onto D, killing it.
# ══════════════════════════════════════════════════════════════

# Board shape (14 cells):
#   Row 0:       (1,0) (2,0) (3,0)
#   Row 1: (0,1) (1,1) (2,1) (3,1)
#   Row 2: (0,2) (1,2) (2,2) (3,2)
#   Row 3: (0,3) (1,3) (2,3)
#
# Portal: (0,2) ↔ (3,0)
# D block: (3,2)
#
# Blocks:
#   B_sac (id=1, down)  at (0,1) — sacrifice through portal
#   B1    (id=1, left)  at (3,1) — must move before ↓ or gets pushed onto D
#   B2    (id=1, up)    at (2,2) — pushes B1 up to complete targets
#   B3    (id=1, right) at (0,3) — goes right along row 3
#   B4    (id=2, down)  at (1,0) — goes down column 1

v1 = {
    "A": [
        [1,0], [2,0,1], [3,0],
        [0,1], [1,1], [2,1,1], [3,1],
        [0,2], [1,2], [2,2], [3,2],
        [0,3], [1,3,2], [2,3,1]
    ],
    "B": [
        {"dir":"down", "id":1, "origin":[0,1]},
        {"dir":"left", "id":1, "origin":[3,1]},
        {"dir":"up", "id":1, "origin":[2,2]},
        {"dir":"right", "id":1, "origin":[0,3]},
        {"dir":"down", "id":2, "origin":[1,0]}
    ],
    "T": [{"id":1, "one_way":False, "pos":[0,2, 3,0]}],
    "D": [{"origin":[3,2]}]
}
test(v1, "v1 base")


# v2: Move B3 start to (1,3) so it needs only 1 right move — tighter
v2 = dict(v1)
v2["B"] = list(v1["B"])
v2["B"][3] = {"dir":"right", "id":1, "origin":[1,3]}
test(v2, "v2 B3@(1,3)")


# v3: Add cell (3,3) for more routing options
v3 = dict(v1)
v3["A"] = v1["A"] + [[3,3]]
test(v3, "v3 +cell(3,3)")


# v4: Try D at (2,2) instead of (3,2) — blocks column 2 directly
v4 = dict(v1)
v4["D"] = [{"origin":[2,2]}]
# Sacrifice needs a different path now
# B2 (up) at (2,2) would be ON the D block... bad
# Move B2 to (2,3), dir=up
v4["B"] = [
    {"dir":"down", "id":1, "origin":[0,1]},
    {"dir":"left", "id":1, "origin":[3,1]},
    {"dir":"up", "id":1, "origin":[2,3]},
    {"dir":"right", "id":1, "origin":[0,3]},
    {"dir":"down", "id":2, "origin":[1,0]}
]
# Portal exit at (3,0), sacrifice goes (3,0)→(3,1)→(3,2)→... not to D(2,2)
# This won't work well, skip
# test(v4, "v4 D@(2,2)")


# v5: Bigger board — add (0,0) and (3,3), 16 cells, more routing
v5_board = [
    [0,0], [1,0], [2,0,1], [3,0],
    [0,1], [1,1], [2,1,1], [3,1],
    [0,2], [1,2], [2,2], [3,2],
    [0,3], [1,3,2], [2,3,1], [3,3]
]
v5 = {
    "A": v5_board,
    "B": [
        {"dir":"down", "id":1, "origin":[0,0]},
        {"dir":"left", "id":1, "origin":[3,1]},
        {"dir":"up", "id":1, "origin":[2,2]},
        {"dir":"right", "id":1, "origin":[0,3]},
        {"dir":"down", "id":2, "origin":[1,0]}
    ],
    "T": [{"id":1, "one_way":False, "pos":[0,2, 3,0]}],
    "D": [{"origin":[3,2]}]
}
test(v5, "v5 16cells sac@(0,0)")


# v6: Like v1 but B4 starts at (1,1) instead of (1,0) — shorter path
v6 = dict(v1)
v6["B"] = [
    {"dir":"down", "id":1, "origin":[0,1]},
    {"dir":"left", "id":1, "origin":[3,1]},
    {"dir":"up", "id":1, "origin":[2,2]},
    {"dir":"right", "id":1, "origin":[0,3]},
    {"dir":"down", "id":2, "origin":[1,1]}
]
test(v6, "v6 B4@(1,1)")


# v7: Try making B3 dir=left at (2,3) — same dir as B1, creates sync tension
v7 = dict(v1)
v7["B"] = [
    {"dir":"down", "id":1, "origin":[0,1]},
    {"dir":"left", "id":1, "origin":[3,1]},
    {"dir":"up", "id":1, "origin":[2,2]},
    {"dir":"left", "id":1, "origin":[2,3]},
    {"dir":"down", "id":2, "origin":[1,0]}
]
# Target (2,3) needs a different block — change targets
v7["A"] = [
    [1,0], [2,0,1], [3,0],
    [0,1], [1,1], [2,1,1], [3,1],
    [0,2], [1,2], [2,2], [3,2],
    [0,3,1], [1,3,2], [2,3]
]
test(v7, "v7 sync lefts")


# v8: Original but with an extra target interaction - B2 starts on wrong-color target
v8 = dict(v1)
v8["A"] = [
    [1,0], [2,0,1], [3,0],
    [0,1], [1,1], [2,1,1], [3,1],
    [0,2], [1,2], [2,2,2], [3,2],
    [0,3], [1,3], [2,3,1]
]
# B2 starts at (2,2) which is now id=2 target — block on wrong-color target
# Add separate id=2 target at (2,2) and id=2 block target at (1,3)
v8["B"] = [
    {"dir":"down", "id":1, "origin":[0,1]},
    {"dir":"left", "id":1, "origin":[3,1]},
    {"dir":"up", "id":1, "origin":[2,2]},
    {"dir":"right", "id":1, "origin":[0,3]},
    {"dir":"down", "id":2, "origin":[1,0]}
]
test(v8, "v8 B2 on wrong target")
