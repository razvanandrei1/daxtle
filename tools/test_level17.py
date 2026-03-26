#!/usr/bin/env python3
"""Level 17 design — 3 colors + destroy block, difficulty 6-7."""

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
# Level 17 — "Three Colors" + Destroy
#
# 3 color ids, 1 D block, ~14-16 cells
# The sacrifice must avoid killing a color that's needed
# Target difficulty: 6-7
# ══════════════════════════════════════════════════════════════

# ──────────────────────────────────────────────────────────────
# Design A: Diamond shape, 3 colors radiating from center
#
#   Row 0:       (1,0) (2,0) (3,0)
#   Row 1: (0,1) (1,1) (2,1) (3,1)
#   Row 2: (0,2) (1,2) (2,2) (3,2)
#   Row 3:       (1,3) (2,3)
#
# 14 cells. D at center area.
# ──────────────────────────────────────────────────────────────

a1 = {
    "A": [
        [1,0,1], [2,0], [3,0],
        [0,1], [1,1], [2,1], [3,1,2],
        [0,2,3], [1,2], [2,2], [3,2],
        [1,3], [2,3]
    ],
    "B": [
        {"dir":"down", "id":1, "origin":[2,0]},
        {"dir":"left", "id":1, "origin":[3,0]},
        {"dir":"left", "id":2, "origin":[3,2]},
        {"dir":"up", "id":3, "origin":[1,3]},
        {"dir":"right", "id":3, "origin":[0,1]}
    ],
    "D": [{"origin":[2,2]}]
}
test(a1, "A1 diamond")

# A2: different block arrangement
a2 = {
    "A": [
        [1,0], [2,0], [3,0,2],
        [0,1,3], [1,1], [2,1], [3,1],
        [0,2], [1,2], [2,2], [3,2,1],
        [1,3,1], [2,3]
    ],
    "B": [
        {"dir":"down", "id":1, "origin":[1,0]},
        {"dir":"down", "id":1, "origin":[2,0]},
        {"dir":"left", "id":2, "origin":[3,1]},
        {"dir":"up", "id":3, "origin":[2,3]},
    ],
    "D": [{"origin":[1,2]}]
}
test(a2, "A2 diamond 4blk")


# ──────────────────────────────────────────────────────────────
# Design B: Asymmetric L-shape
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
        [0,0,1], [1,0], [2,0],
        [0,1], [1,1,2], [2,1], [3,1],
        [0,2], [1,2], [2,2], [3,2,3],
        [1,3], [2,3], [3,3]
    ],
    "B": [
        {"dir":"down", "id":1, "origin":[0,0]},  # sac — goes down, eventually hits D
        {"dir":"right", "id":1, "origin":[0,1]},
        {"dir":"left", "id":2, "origin":[2,0]},
        {"dir":"down", "id":3, "origin":[3,1]},
        {"dir":"up", "id":3, "origin":[2,3]}
    ],
    "D": [{"origin":[1,2]}]
}
test(b1, "B1 L-shape")

# B2: sacrifice block goes down to D
b2 = dict(b1)
b2["B"] = [
    {"dir":"down", "id":1, "origin":[1,0]},  # sac — (1,0)→(1,1)→(1,2)=D
    {"dir":"right", "id":1, "origin":[0,1]},
    {"dir":"left", "id":2, "origin":[2,0]},
    {"dir":"down", "id":3, "origin":[3,1]},
    {"dir":"up", "id":3, "origin":[2,3]}
]
test(b2, "B2 sac@(1,0)")


# ──────────────────────────────────────────────────────────────
# Design C: Hook shape
#
#   Row 0: (0,0) (1,0) (2,0) (3,0)
#   Row 1: (0,1) (1,1) (2,1)
#   Row 2:       (1,2) (2,2) (3,2)
#   Row 3:       (1,3) (2,3) (3,3)
#
# 15 cells. Offset rows create distinctive silhouette.
# ──────────────────────────────────────────────────────────────

c1 = {
    "A": [
        [0,0], [1,0,1], [2,0], [3,0],
        [0,1,2], [1,1], [2,1],
        [1,2], [2,2], [3,2],
        [1,3,3], [2,3], [3,3]
    ],
    "B": [
        {"dir":"right", "id":1, "origin":[0,0]},
        {"dir":"down", "id":1, "origin":[2,0]},  # sac
        {"dir":"down", "id":2, "origin":[0,0]},   # hmm, 2 blocks same cell — no
    ],
    "D": [{"origin":[2,2]}]
}
# Fix: no two blocks on same cell
c1["B"] = [
    {"dir":"right", "id":1, "origin":[0,0]},
    {"dir":"down", "id":1, "origin":[3,0]},  # sac — (3,0) down to... (3,1) no cell. Bad.
    {"dir":"left", "id":2, "origin":[2,1]},
    {"dir":"up", "id":3, "origin":[2,3]},
]
# (3,0) down → (3,1) not a cell. Need to fix.
# skip c1

c2 = {
    "A": [
        [0,0], [1,0,1], [2,0], [3,0],
        [0,1,2], [1,1], [2,1],
        [1,2], [2,2], [3,2],
        [1,3,3], [2,3], [3,3]
    ],
    "B": [
        {"dir":"right", "id":1, "origin":[0,0]},
        {"dir":"down", "id":1, "origin":[2,0]},   # sac — (2,0)→(2,1)→(2,2)=D? Let's check cells
        {"dir":"left", "id":2, "origin":[2,1]},
        {"dir":"up", "id":3, "origin":[2,3]},
    ],
    "D": [{"origin":[2,2]}]
}
test(c2, "C2 hook")


# ──────────────────────────────────────────────────────────────
# Design D: Staircase
#
#   Row 0:             (2,0) (3,0)
#   Row 1:       (1,1) (2,1) (3,1)
#   Row 2: (0,2) (1,2) (2,2)
#   Row 3: (0,3) (1,3)
#
# 11 cells. Very compact.
# ──────────────────────────────────────────────────────────────

d1 = {
    "A": [
        [2,0,1], [3,0],
        [1,1], [2,1], [3,1,2],
        [0,2,3], [1,2], [2,2],
        [0,3], [1,3]
    ],
    "B": [
        {"dir":"left", "id":1, "origin":[3,0]},
        {"dir":"down", "id":1, "origin":[2,0]},  # sac
        {"dir":"left", "id":2, "origin":[3,1]},   # starts on own target — BAD
        {"dir":"up", "id":3, "origin":[1,3]},
    ],
    "D": [{"origin":[2,1]}]
}
# Fix: B2 starts on id=2 target at (3,1). That's own-color. Bad.
d1["B"][2] = {"dir":"down", "id":2, "origin":[3,0]}  # wait, B0 already at (3,0).
# Skip d1, try d2

d2 = {
    "A": [
        [2,0], [3,0,1],
        [1,1,2], [2,1], [3,1],
        [0,2], [1,2], [2,2,3],
        [0,3], [1,3]
    ],
    "B": [
        {"dir":"left", "id":1, "origin":[3,1]},
        {"dir":"down", "id":1, "origin":[2,0]},  # sac — (2,0)→(2,1)→(2,2) hits target...
        {"dir":"left", "id":2, "origin":[2,1]},
        {"dir":"up", "id":3, "origin":[1,3]},
    ],
    "D": [{"origin":[1,2]}]
}
test(d2, "D2 staircase")


# ──────────────────────────────────────────────────────────────
# Design E: Wide cross, 16 cells
#
#   Row 0:       (1,0) (2,0) (3,0)
#   Row 1: (0,1) (1,1) (2,1) (3,1) (4,1)
#   Row 2:       (1,2) (2,2) (3,2)
#   Row 3:       (1,3) (2,3) (3,3)
#
# 15 cells. Plus/cross shape.
# ──────────────────────────────────────────────────────────────

e1 = {
    "A": [
        [1,0,1], [2,0], [3,0],
        [0,1], [1,1], [2,1], [3,1,2], [4,1],
        [1,2], [2,2], [3,2],
        [1,3], [2,3,3], [3,3]
    ],
    "B": [
        {"dir":"down", "id":1, "origin":[2,0]},
        {"dir":"right", "id":1, "origin":[0,1]},
        {"dir":"left", "id":2, "origin":[4,1]},
        {"dir":"up", "id":3, "origin":[1,3]},
        {"dir":"left", "id":3, "origin":[3,3]},
    ],
    "D": [{"origin":[2,2]}]
}
test(e1, "E1 cross 5blk")

# E2: fewer blocks, tighter
e2 = {
    "A": [
        [1,0,1], [2,0], [3,0],
        [0,1,3], [1,1], [2,1], [3,1,2], [4,1],
        [1,2], [2,2], [3,2],
        [1,3], [2,3], [3,3]
    ],
    "B": [
        {"dir":"down", "id":1, "origin":[2,0]},  # sac — goes through center
        {"dir":"right", "id":1, "origin":[0,1]},
        {"dir":"left", "id":2, "origin":[4,1]},
        {"dir":"up", "id":3, "origin":[2,3]},
    ],
    "D": [{"origin":[2,2]}]
}
test(e2, "E2 cross 4blk")

# E3: targets further apart, more routing
e3 = {
    "A": [
        [1,0], [2,0], [3,0,2],
        [0,1,1], [1,1], [2,1], [3,1], [4,1],
        [1,2], [2,2], [3,2],
        [1,3,3], [2,3], [3,3]
    ],
    "B": [
        {"dir":"down", "id":1, "origin":[1,0]},   # sac — down column 1
        {"dir":"right", "id":1, "origin":[0,1]},   # wait, starts on own target. BAD.
        {"dir":"left", "id":2, "origin":[4,1]},
        {"dir":"up", "id":3, "origin":[2,3]},
    ],
    "D": [{"origin":[2,2]}]
}
# Fix B1 starting on own target
e3["B"][1] = {"dir":"left", "id":1, "origin":[2,0]}
e3["B"][0] = {"dir":"down", "id":1, "origin":[1,0]}
# Now 2 id=1 blocks: one at (1,0) down, one at (2,0) left. 1 target for id=1: (0,1).
# Sac goes down from (1,0) through (1,1)→(1,2)→D? D at (2,2). Sac in col 1 doesn't hit D in col 2.
# Need sac to reach D. Let me put D at (1,2).
e3["D"] = [{"origin":[1,2]}]
test(e3, "E3 cross D@(1,2)")


# ──────────────────────────────────────────────────────────────
# Design F: Arrow/chevron shape
#
#   Row 0:       (1,0) (2,0)
#   Row 1: (0,1) (1,1) (2,1) (3,1)
#   Row 2: (0,2) (1,2) (2,2) (3,2)
#   Row 3:       (1,3) (2,3)
#
# 14 cells. Symmetric arrow pointing right.
# ──────────────────────────────────────────────────────────────

f1 = {
    "A": [
        [1,0], [2,0],
        [0,1,1], [1,1], [2,1], [3,1,2],
        [0,2], [1,2], [2,2,3], [3,2],
        [1,3], [2,3]
    ],
    "B": [
        {"dir":"down", "id":1, "origin":[1,0]},
        {"dir":"right", "id":1, "origin":[0,2]},   # sac
        {"dir":"left", "id":2, "origin":[3,2]},
        {"dir":"up", "id":3, "origin":[1,3]},
    ],
    "D": [{"origin":[2,2]}]
}
test(f1, "F1 arrow 4blk")

# F2: 5 blocks
f2 = {
    "A": [
        [1,0], [2,0],
        [0,1,1], [1,1], [2,1,2], [3,1],
        [0,2], [1,2], [2,2], [3,2,3],
        [1,3], [2,3]
    ],
    "B": [
        {"dir":"down", "id":1, "origin":[1,0]},
        {"dir":"right", "id":1, "origin":[0,2]},   # sac — right to D
        {"dir":"left", "id":2, "origin":[3,1]},
        {"dir":"up", "id":3, "origin":[2,3]},
        {"dir":"down", "id":3, "origin":[2,0]},
    ],
    "D": [{"origin":[1,2]}]
}
test(f2, "F2 arrow 5blk")

# F3: D in center, different targets
f3 = {
    "A": [
        [1,0,2], [2,0],
        [0,1], [1,1,1], [2,1], [3,1],
        [0,2], [1,2], [2,2], [3,2,3],
        [1,3], [2,3]
    ],
    "B": [
        {"dir":"down", "id":1, "origin":[2,0]},
        {"dir":"right", "id":1, "origin":[0,1]},  # sac — right through row 1
        {"dir":"down", "id":2, "origin":[1,0]},
        {"dir":"up", "id":3, "origin":[2,3]},
    ],
    "D": [{"origin":[2,1]}]
}
test(f3, "F3 arrow center-D")


# ──────────────────────────────────────────────────────────────
# Design G: Compact T-shape
#
#   Row 0: (0,0) (1,0) (2,0) (3,0) (4,0)
#   Row 1:       (1,1) (2,1) (3,1)
#   Row 2:       (1,2) (2,2) (3,2)
#   Row 3:             (2,3)
#
# 13 cells. T-shape.
# ──────────────────────────────────────────────────────────────

g1 = {
    "A": [
        [0,0], [1,0], [2,0], [3,0], [4,0,2],
        [1,1,1], [2,1], [3,1],
        [1,2], [2,2], [3,2,3],
        [2,3]
    ],
    "B": [
        {"dir":"right", "id":1, "origin":[0,0]},
        {"dir":"down", "id":1, "origin":[2,0]},   # sac
        {"dir":"left", "id":2, "origin":[4,0]},    # starts on own target! BAD
        {"dir":"up", "id":3, "origin":[2,3]},
    ],
    "D": [{"origin":[2,2]}]
}
# Fix: move B2 and target
g1["B"][2] = {"dir":"left", "id":2, "origin":[3,0]}
test(g1, "G1 T-shape")

# G2: different arrangement
g2 = {
    "A": [
        [0,0,3], [1,0], [2,0], [3,0], [4,0],
        [1,1], [2,1,1], [3,1],
        [1,2], [2,2], [3,2,2],
        [2,3]
    ],
    "B": [
        {"dir":"down", "id":1, "origin":[2,0]},   # sac
        {"dir":"left", "id":1, "origin":[3,0]},
        {"dir":"left", "id":2, "origin":[4,0]},
        {"dir":"up", "id":3, "origin":[2,3]},
        {"dir":"left", "id":3, "origin":[1,1]},
    ],
    "D": [{"origin":[2,1]}]
}
test(g2, "G2 T-shape v2")


# ──────────────────────────────────────────────────────────────
# Design H: Windmill / pinwheel shape
#
#   Row 0: (0,0) (1,0)       (3,0)
#   Row 1: (0,1) (1,1) (2,1) (3,1)
#   Row 2: (0,2) (1,2) (2,2) (3,2)
#   Row 3: (0,3)       (2,3) (3,3)
#
# 15 cells. Two diagonal corners removed.
# ──────────────────────────────────────────────────────────────

h1 = {
    "A": [
        [0,0], [1,0], [3,0,2],
        [0,1,1], [1,1], [2,1], [3,1],
        [0,2], [1,2], [2,2], [3,2],
        [0,3], [2,3,3], [3,3]
    ],
    "B": [
        {"dir":"down", "id":1, "origin":[1,0]},
        {"dir":"right", "id":1, "origin":[0,2]},   # sac
        {"dir":"left", "id":2, "origin":[3,1]},
        {"dir":"up", "id":3, "origin":[3,3]},
        {"dir":"down", "id":3, "origin":[0,0]},
    ],
    "D": [{"origin":[2,2]}]
}
test(h1, "H1 windmill 5blk")

# H2: 4 blocks
h2 = {
    "A": [
        [0,0], [1,0], [3,0],
        [0,1,1], [1,1], [2,1], [3,1,2],
        [0,2], [1,2], [2,2], [3,2],
        [0,3,3], [2,3], [3,3]
    ],
    "B": [
        {"dir":"down", "id":1, "origin":[1,0]},
        {"dir":"left", "id":2, "origin":[3,0]},
        {"dir":"up", "id":3, "origin":[2,3]},
        {"dir":"right", "id":3, "origin":[0,2]},   # sac
    ],
    "D": [{"origin":[2,2]}]
}
test(h2, "H2 windmill 4blk")

# H3: rearrange targets/blocks
h3 = {
    "A": [
        [0,0], [1,0], [3,0,2],
        [0,1], [1,1,1], [2,1], [3,1],
        [0,2], [1,2], [2,2], [3,2],
        [0,3,3], [2,3], [3,3]
    ],
    "B": [
        {"dir":"down", "id":1, "origin":[0,0]},
        {"dir":"left", "id":2, "origin":[3,1]},
        {"dir":"up", "id":3, "origin":[3,3]},
        {"dir":"right", "id":3, "origin":[0,1]},   # sac — right through row 1
    ],
    "D": [{"origin":[2,1]}]
}
test(h3, "H3 windmill v3")
