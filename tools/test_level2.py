#!/usr/bin/env python3
"""Level 16 design iteration — aiming for 10-12 moves, difficulty 7."""

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
# Design A: Wider board, sacrifice needs longer setup
# 16 cells, hook shape
#
#   Row 0: (0,0) (1,0) (2,0) (3,0)
#   Row 1: (0,1) (1,1) (2,1) (3,1) (4,1)
#   Row 2:       (1,2) (2,2) (3,2) (4,2)
#   Row 3:             (2,3) (3,3)
#
# Portal: (0,0) ↔ (3,3)  — top-left to bottom-right
# D: (4,2)
# ──────────────────────────────────────────────────────────────

a1 = {
    "A": [
        [0,0], [1,0], [2,0], [3,0],
        [0,1], [1,1], [2,1,1], [3,1], [4,1],
        [1,2,2], [2,2,1], [3,2], [4,2],
        [2,3,1], [3,3]
    ],
    "B": [
        {"dir":"down", "id":1, "origin":[0,0]},   # sac — goes down to portal... wait, portal at (0,0)
        {"dir":"left", "id":1, "origin":[4,1]},
        {"dir":"up", "id":1, "origin":[3,2]},
        {"dir":"right", "id":1, "origin":[2,3]},
        {"dir":"down", "id":2, "origin":[1,1]}
    ],
    "T": [{"id":1, "one_way":False, "pos":[0,0, 3,3]}],
    "D": [{"origin":[4,2]}]
}
test(a1, "A1")


# ──────────────────────────────────────────────────────────────
# Design B: 15 cells, staircase shape
#
#   Row 0:             (2,0) (3,0) (4,0)
#   Row 1:       (1,1) (2,1) (3,1) (4,1)
#   Row 2: (0,2) (1,2) (2,2) (3,2)
#   Row 3: (0,3) (1,3) (2,3)
#
# Portal: (0,2) ↔ (4,0) — left-mid to top-right
# D: (4,1) — right side, reachable after portal
# ──────────────────────────────────────────────────────────────

b1 = {
    "A": [
        [2,0], [3,0], [4,0],
        [1,1], [2,1,1], [3,1], [4,1],
        [0,2], [1,2], [2,2,1], [3,2],
        [0,3,1], [1,3,2], [2,3]
    ],
    "B": [
        {"dir":"down", "id":1, "origin":[0,2]},    # sac through portal at (0,2)... wait (0,2) is start
        {"dir":"left", "id":1, "origin":[3,1]},
        {"dir":"left", "id":1, "origin":[3,2]},
        {"dir":"right", "id":1, "origin":[0,3]},
        {"dir":"up", "id":2, "origin":[2,3]}
    ],
    "T": [{"id":1, "one_way":False, "pos":[0,3, 4,0]}],
    "D": [{"origin":[4,1]}]
}
test(b1, "B1 staircase")


# ──────────────────────────────────────────────────────────────
# Design C: 15 cells, cross-like shape
# Sacrifice enters portal from left, exits right, reaches D from above
#
#   Row 0:       (1,0) (2,0) (3,0)
#   Row 1: (0,1) (1,1) (2,1) (3,1) (4,1)
#   Row 2: (0,2) (1,2)       (3,2) (4,2)
#   Row 3:       (1,3) (2,3) (3,3)
#
# Portal: (0,2) ↔ (4,1) — left to far right
# D: (3,2) — accessible from portal exit going down
# ──────────────────────────────────────────────────────────────

c1 = {
    "A": [
        [1,0], [2,0,1], [3,0],
        [0,1], [1,1], [2,1,1], [3,1], [4,1],
        [0,2], [1,2], [3,2], [4,2],
        [1,3,2], [2,3], [3,3,1]
    ],
    "B": [
        {"dir":"down", "id":1, "origin":[0,1]},   # sac — down to (0,2)=portal, exits (4,1), cont (4,2)
        {"dir":"left", "id":1, "origin":[3,1]},
        {"dir":"up", "id":1, "origin":[2,3]},
        {"dir":"right", "id":1, "origin":[1,3]},
        {"dir":"down", "id":2, "origin":[1,0]}
    ],
    "T": [{"id":1, "one_way":False, "pos":[0,2, 4,1]}],
    "D": [{"origin":[3,2]}]
}
test(c1, "C1 cross")

# C1 variant: sac goes down to portal, exits at (4,1), continues down to (4,2), then D at (4,2)?
# But sac would die on D. D needs to be on sac's path.
c2 = dict(c1)
c2["D"] = [{"origin":[4,2]}]
test(c2, "C2 D@(4,2)")


# ──────────────────────────────────────────────────────────────
# Design D: Build on v1 but add cargo block for depth
#
#   Row 0:       (1,0) (2,0) (3,0)
#   Row 1: (0,1) (1,1) (2,1) (3,1)
#   Row 2: (0,2) (1,2) (2,2) (3,2)
#   Row 3: (0,3) (1,3) (2,3)
#
# Portal: (0,2) ↔ (3,0)
# D: (3,2)
# Cargo block at (2,1) — must be pushed to target
# ──────────────────────────────────────────────────────────────

d1 = {
    "A": [
        [1,0], [2,0,1], [3,0],
        [0,1], [1,1], [2,1], [3,1],
        [0,2], [1,2], [2,2,1], [3,2],
        [0,3], [1,3,2], [2,3,1]
    ],
    "B": [
        {"dir":"down", "id":1, "origin":[0,1]},   # sac
        {"dir":"left", "id":1, "origin":[3,1]},
        {"dir":"none", "id":1, "origin":[2,1]},   # cargo — must be pushed
        {"dir":"right", "id":1, "origin":[0,3]},
        {"dir":"down", "id":2, "origin":[1,0]}
    ],
    "T": [{"id":1, "one_way":False, "pos":[0,2, 3,0]}],
    "D": [{"origin":[3,2]}]
}
test(d1, "D1 cargo")

# D2: cargo at (1,1)
d2 = dict(d1)
d2["B"] = [
    {"dir":"down", "id":1, "origin":[0,1]},
    {"dir":"left", "id":1, "origin":[3,1]},
    {"dir":"none", "id":1, "origin":[1,1]},
    {"dir":"right", "id":1, "origin":[0,3]},
    {"dir":"down", "id":2, "origin":[1,0]}
]
test(d2, "D2 cargo@(1,1)")


# ──────────────────────────────────────────────────────────────
# Design E: 2 teleport pairs + destroy, 16 cells
# More complex teleport routing
#
#   Row 0: (0,0) (1,0)       (3,0) (4,0)
#   Row 1: (0,1) (1,1) (2,1) (3,1) (4,1)
#   Row 2:       (1,2) (2,2) (3,2)
#   Row 3:             (2,3)
#
# Portal A: (0,0) ↔ (4,0) — top corners
# D: (3,2) or (2,3)
# ──────────────────────────────────────────────────────────────

e1 = {
    "A": [
        [0,0], [1,0], [3,0], [4,0],
        [0,1], [1,1,1], [2,1], [3,1,1], [4,1],
        [1,2], [2,2,2], [3,2],
        [2,3,1]
    ],
    "B": [
        {"dir":"down", "id":1, "origin":[0,0]},
        {"dir":"left", "id":1, "origin":[4,1]},
        {"dir":"up", "id":1, "origin":[2,3]},
        {"dir":"down", "id":2, "origin":[2,1]}
    ],
    "T": [{"id":1, "one_way":False, "pos":[0,0, 4,0]}],
    "D": [{"origin":[3,2]}]
}
test(e1, "E1 wide")


# ──────────────────────────────────────────────────────────────
# Design F: Asymmetric L + portal, 15 cells
# Strong shape, longer paths
#
#   Row 0:       (1,0) (2,0) (3,0) (4,0)
#   Row 1: (0,1) (1,1) (2,1) (3,1)
#   Row 2: (0,2) (1,2) (2,2)
#   Row 3: (0,3) (1,3)
#
# Portal: (0,3) ↔ (4,0)
# D: (3,1) or (4,0) area
# ──────────────────────────────────────────────────────────────

f1 = {
    "A": [
        [1,0], [2,0,1], [3,0], [4,0],
        [0,1], [1,1,1], [2,1], [3,1],
        [0,2], [1,2], [2,2,1],
        [0,3], [1,3,2]
    ],
    "B": [
        {"dir":"down", "id":1, "origin":[0,1]},   # sac — down through portal
        {"dir":"left", "id":1, "origin":[3,1]},   # left along row 1
        {"dir":"up", "id":1, "origin":[2,2]},     # up column 2
        {"dir":"right", "id":1, "origin":[0,3]},  # right along row 3
        {"dir":"down", "id":2, "origin":[1,0]}    # down column 1
    ],
    "T": [{"id":1, "one_way":False, "pos":[0,3, 4,0]}],
    "D": [{"origin":[3,1]}]
}
test(f1, "F1 L-shape D@(3,1)")

# F2: D at far end of portal path
f2 = dict(f1)
f2["A"] = [
    [1,0], [2,0,1], [3,0], [4,0],
    [0,1,1], [1,1], [2,1], [3,1],
    [0,2], [1,2,1], [2,2],
    [0,3], [1,3,2]
]
f2["D"] = [{"origin":[3,0]}]
# sac goes down from (0,1) → (0,2) → (0,3)=portal → exits (4,0) → cont down (4,1)? no cell
# So sac lands at (4,0). Then sac goes down? (4,1) no cell. Stuck.
# D at (3,0): sac can't reach it from (4,0) by going down.
# Won't work, skip


# ──────────────────────────────────────────────────────────────
# Design G: Build on v1 shape but add more blocks, 6 blocks total
#
#   Row 0:       (1,0) (2,0) (3,0)
#   Row 1: (0,1) (1,1) (2,1) (3,1)
#   Row 2: (0,2) (1,2) (2,2) (3,2)
#   Row 3: (0,3) (1,3) (2,3)
#
# Portal: (0,2) ↔ (3,0)
# D: (3,2)
# 6 blocks: 4 id=1 + 1 id=2 + 1 cargo(id=1)
# ──────────────────────────────────────────────────────────────

g1 = {
    "A": [
        [1,0], [2,0,1], [3,0],
        [0,1], [1,1,1], [2,1], [3,1],
        [0,2], [1,2], [2,2,1], [3,2],
        [0,3], [1,3,2], [2,3]
    ],
    "B": [
        {"dir":"down", "id":1, "origin":[0,1]},    # sac
        {"dir":"left", "id":1, "origin":[3,1]},
        {"dir":"up", "id":1, "origin":[2,2]},
        {"dir":"right", "id":1, "origin":[0,3]},
        {"dir":"none", "id":1, "origin":[2,1]},    # cargo in the middle
        {"dir":"down", "id":2, "origin":[1,0]}
    ],
    "T": [{"id":1, "one_way":False, "pos":[0,2, 3,0]}],
    "D": [{"origin":[3,2]}]
}
test(g1, "G1 6blocks+cargo")

# G2: swap target locations
g2 = dict(g1)
g2["A"] = [
    [1,0,1], [2,0], [3,0],
    [0,1], [1,1], [2,1,1], [3,1],
    [0,2], [1,2], [2,2], [3,2],
    [0,3], [1,3,2], [2,3,1]
]
test(g2, "G2 diff targets")
