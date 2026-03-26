#!/usr/bin/env python3
"""Generate new challenge levels. Medium: 4-5 moves, Hard: 6-8 moves."""

import sys, os, json, random
sys.path.insert(0, os.path.dirname(__file__))
from solve_levels import parse_level, solve, ARROWS

def test(data, label=""):
    board, blocks, teleport_map, destroy_set = parse_level(data)
    solution = solve(board, blocks, teleport_map, destroy_set)
    if solution is None:
        return None
    n = len(solution)
    arrows = " ".join(ARROWS[d] for d in solution)
    print(f"{label} ({n} moves): {arrows}")
    return solution


# ══════════════════════════════════════════════════════════════
# MEDIUM candidates (4-5 moves)
# Based on campaign mechanics: push, ordering, 2 colors
# ══════════════════════════════════════════════════════════════

# M1: Push ordering — 3 blocks, L-shape
m1 = {
    "A": [[0,0],[1,0],[2,0,1],[0,1],[1,1],[2,1],[0,2,1],[1,2],[2,2,2]],
    "B": [
        {"dir":"right","id":1,"origin":[0,0]},
        {"dir":"down","id":1,"origin":[0,1]},
        {"dir":"right","id":2,"origin":[0,2]}
    ],
    "difficulty": 2
}
test(m1, "M1")

# M2: 3 blocks, cross push
m2 = {
    "A": [[1,0],[0,1,1],[1,1],[2,1],[1,2,2],[2,2,1]],
    "B": [
        {"dir":"down","id":1,"origin":[1,0]},
        {"dir":"right","id":1,"origin":[0,1]},
        {"dir":"down","id":2,"origin":[2,1]}
    ],
    "difficulty": 2
}
test(m2, "M2")

# M3: Push chain with 2 colors
m3 = {
    "A": [[0,0],[1,0],[2,0],[3,0],[0,1,1],[1,1],[2,1],[3,1,2],[0,2,1],[1,2],[2,2,2]],
    "B": [
        {"dir":"right","id":1,"origin":[0,0]},
        {"dir":"down","id":1,"origin":[0,1]},
        {"dir":"left","id":2,"origin":[3,0]},
        {"dir":"down","id":2,"origin":[2,0]}
    ],
    "difficulty": 2
}
test(m3, "M3")

# M4: Ordering trap — down before right kills
m4 = {
    "A": [[0,0],[1,0],[2,0],[0,1],[1,1,1],[2,1],[0,2,2],[1,2],[2,2,1]],
    "B": [
        {"dir":"right","id":1,"origin":[0,1]},
        {"dir":"down","id":1,"origin":[1,0]},
        {"dir":"down","id":2,"origin":[0,0]}
    ],
    "difficulty": 2
}
test(m4, "M4")

# M5: 3 blocks, staircase
m5 = {
    "A": [[0,0],[1,0,1],[2,0],[0,1],[1,1],[2,1,2],[1,2,1],[2,2]],
    "B": [
        {"dir":"right","id":1,"origin":[0,0]},
        {"dir":"down","id":1,"origin":[2,0]},
        {"dir":"left","id":2,"origin":[2,1]}
    ],
    "difficulty": 2
}
test(m5, "M5")

# M6: Wide push — 4 blocks
m6 = {
    "A": [[0,0],[1,0],[2,0],[3,0,1],[0,1,2],[1,1],[2,1,1],[3,1]],
    "B": [
        {"dir":"right","id":1,"origin":[0,0]},
        {"dir":"down","id":1,"origin":[2,0]},
        {"dir":"left","id":2,"origin":[3,1]},
        {"dir":"down","id":2,"origin":[0,0]}  # same cell as B0! Fix.
    ],
    "difficulty": 2
}
m6["B"][3] = {"dir":"down","id":2,"origin":[1,0]}
test(m6, "M6")

# M7: Cargo push
m7 = {
    "A": [[0,0],[1,0],[2,0],[0,1,1],[1,1,1],[2,1,2]],
    "B": [
        {"dir":"none","id":1,"origin":[1,0]},
        {"dir":"right","id":1,"origin":[0,0]},
        {"dir":"down","id":2,"origin":[2,0]}
    ],
    "difficulty": 2
}
test(m7, "M7")

# M8: L-shape ordering
m8 = {
    "A": [[0,0],[1,0,1],[0,1],[1,1],[2,1],[0,2],[1,2,2],[2,2,1]],
    "B": [
        {"dir":"down","id":1,"origin":[1,0]},
        {"dir":"right","id":1,"origin":[0,1]},
        {"dir":"down","id":2,"origin":[2,1]}
    ],
    "difficulty": 2
}
test(m8, "M8")

# M9: Diamond push
m9 = {
    "A": [[1,0],[0,1],[1,1],[2,1],[1,2],[2,2,1],[0,2,2],[1,2]],
    "B": [
        {"dir":"down","id":1,"origin":[1,0]},
        {"dir":"right","id":1,"origin":[0,1]},
        {"dir":"left","id":2,"origin":[2,1]}
    ],
    "difficulty": 2
}
# (1,2) appears twice, fix
m9["A"] = [[1,0],[0,1],[1,1],[2,1],[0,2,2],[1,2],[2,2,1]]
test(m9, "M9")

# M10: Push with blocker
m10 = {
    "A": [[0,0],[1,0],[2,0],[3,0],[0,1,1],[1,1],[2,1],[3,1,1],[0,2,2],[1,2],[2,2,2]],
    "B": [
        {"dir":"right","id":1,"origin":[0,0]},
        {"dir":"left","id":1,"origin":[3,0]},
        {"dir":"down","id":2,"origin":[1,0]},
        {"dir":"down","id":2,"origin":[2,0]}
    ],
    "difficulty": 2
}
test(m10, "M10")

# M11: 2 blocks, long path
m11 = {
    "A": [[0,0],[1,0],[2,0],[0,1,1],[1,1],[2,1],[0,2],[1,2,2],[2,2,1]],
    "B": [
        {"dir":"down","id":1,"origin":[2,0]},
        {"dir":"left","id":1,"origin":[2,1]},
        {"dir":"right","id":2,"origin":[0,1]}
    ],
    "difficulty": 2
}
test(m11, "M11")

# M12: Step puzzle
m12 = {
    "A": [[0,0],[1,0],[2,0],[1,1],[2,1,1],[3,1],[2,2],[3,2,2],[3,0,1]],
    "B": [
        {"dir":"right","id":1,"origin":[0,0]},
        {"dir":"down","id":1,"origin":[1,0]},
        {"dir":"right","id":2,"origin":[2,2]}
    ],
    "difficulty": 2
}
test(m12, "M12")

print("\n" + "="*60)
print("HARD candidates (6-8 moves)")
print("="*60 + "\n")

# ══════════════════════════════════════════════════════════════
# HARD candidates (6-8 moves)
# Based on campaign: destroy, teleport, cargo, 3 colors
# ══════════════════════════════════════════════════════════════

# H1: Destroy block — ordering trap
h1 = {
    "A": [[0,0],[1,0],[2,0],[0,1,1],[1,1],[2,1,1],[0,2],[1,2],[2,2,2],[0,3,1]],
    "B": [
        {"dir":"down","id":1,"origin":[0,0]},
        {"dir":"down","id":1,"origin":[1,0]},
        {"dir":"right","id":1,"origin":[0,1]},
        {"dir":"right","id":2,"origin":[0,2]}
    ],
    "D": [{"origin":[1,2]}],
    "difficulty": 3
}
test(h1, "H1")

# H2: 3-color ordering
h2 = {
    "A": [[0,0],[1,0,1],[2,0],[0,1],[1,1,2],[2,1],[0,2,3],[1,2],[2,2]],
    "B": [
        {"dir":"right","id":1,"origin":[0,0]},
        {"dir":"down","id":2,"origin":[2,0]},
        {"dir":"left","id":3,"origin":[2,2]},
        {"dir":"down","id":1,"origin":[1,0]}
    ],
    "D": [{"origin":[1,2]}],
    "difficulty": 3
}
test(h2, "H2")

# H3: Push chain + destroy
h3 = {
    "A": [[0,0],[1,0],[2,0],[3,0,1],[0,1,1],[1,1],[2,1],[3,1],[0,2],[1,2,2],[2,2],[3,2,2]],
    "B": [
        {"dir":"right","id":1,"origin":[0,0]},
        {"dir":"down","id":1,"origin":[1,0]},
        {"dir":"left","id":2,"origin":[3,1]},
        {"dir":"down","id":2,"origin":[3,0]}
    ],
    "D": [{"origin":[2,2]}],
    "difficulty": 3
}
test(h3, "H3")

# H4: Cargo + ordering
h4 = {
    "A": [[0,0],[1,0],[2,0],[0,1,1],[1,1,1],[2,1],[0,2],[1,2],[2,2,2]],
    "B": [
        {"dir":"none","id":1,"origin":[1,1]},
        {"dir":"left","id":1,"origin":[2,1]},
        {"dir":"down","id":1,"origin":[0,0]},
        {"dir":"right","id":2,"origin":[0,2]}
    ],
    "D": [{"origin":[1,2]}],
    "difficulty": 3
}
test(h4, "H4")

# H5: Wide push + destroy
h5 = {
    "A": [[0,0],[1,0],[2,0],[3,0],[0,1,1],[1,1],[2,1],[3,1,1],[0,2,2],[1,2],[2,2],[3,2,2]],
    "B": [
        {"dir":"right","id":1,"origin":[0,0]},
        {"dir":"down","id":1,"origin":[2,0]},
        {"dir":"left","id":2,"origin":[3,1]},
        {"dir":"left","id":1,"origin":[3,0]}
    ],
    "D": [{"origin":[1,2]}],
    "difficulty": 3
}
test(h5, "H5")

# H6: Complex ordering — 4 blocks, 2 colors
h6 = {
    "A": [[0,0],[1,0],[2,0],[3,0,1],[0,1],[1,1],[2,1],[3,1],[0,2,2],[1,2],[2,2,1],[3,2,2]],
    "B": [
        {"dir":"right","id":1,"origin":[0,0]},
        {"dir":"down","id":1,"origin":[2,0]},
        {"dir":"left","id":2,"origin":[3,1]},
        {"dir":"down","id":2,"origin":[0,1]}
    ],
    "D": [{"origin":[2,2]}],
    "difficulty": 3
}
test(h6, "H6")

# H7: Destroy + push chain + 2 colors (campaign L14 style)
h7 = {
    "A": [[1,0,1],[0,1,2],[1,1],[2,1],[0,2],[1,2],[2,2],[1,3,1]],
    "B": [
        {"dir":"right","id":1,"origin":[0,2]},
        {"dir":"down","id":1,"origin":[1,0]},
        {"dir":"left","id":2,"origin":[2,1]},
        {"dir":"up","id":1,"origin":[1,3]}
    ],
    "D": [{"origin":[1,2]}],
    "difficulty": 3
}
test(h7, "H7")

# H8: Wider board, 5 blocks
h8 = {
    "A": [[0,0],[1,0],[2,0],[3,0],[4,0,1],[0,1],[1,1],[2,1],[3,1,1],[4,1],[0,2,2],[1,2,2]],
    "B": [
        {"dir":"right","id":1,"origin":[0,0]},
        {"dir":"right","id":1,"origin":[0,1]},
        {"dir":"down","id":1,"origin":[3,0]},
        {"dir":"left","id":2,"origin":[4,1]},
        {"dir":"left","id":2,"origin":[1,1]}
    ],
    "D": [{"origin":[2,1]}],
    "difficulty": 3
}
test(h8, "H8")

# H9: 3 colors, no D
h9 = {
    "A": [[0,0],[1,0],[2,0],[3,0,1],[0,1],[1,1,2],[2,1],[3,1],[0,2,3],[1,2],[2,2],[3,2]],
    "B": [
        {"dir":"right","id":1,"origin":[0,0]},
        {"dir":"left","id":2,"origin":[3,1]},
        {"dir":"up","id":3,"origin":[1,2]},
        {"dir":"down","id":1,"origin":[1,0]}
    ],
    "D": [{"origin":[2,2]}],
    "difficulty": 3
}
test(h9, "H9")

# H10: L-shape + destroy
h10 = {
    "A": [[0,0],[1,0],[2,0],[0,1],[1,1,1],[2,1],[3,1,2],[0,2,1],[1,2],[2,2],[3,2,2]],
    "B": [
        {"dir":"down","id":1,"origin":[0,0]},
        {"dir":"right","id":1,"origin":[0,1]},
        {"dir":"down","id":1,"origin":[2,0]},
        {"dir":"left","id":2,"origin":[3,1]}
    ],
    "D": [{"origin":[2,2]}],
    "difficulty": 3
}
test(h10, "H10")
