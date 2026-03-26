#!/usr/bin/env python3
"""Final batch — methodical designs with verified paths."""

import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from solve_levels import parse_level, solve, ARROWS

def test(data, label=""):
    board, blocks, teleport_map, destroy_set = parse_level(data)
    solution = solve(board, blocks, teleport_map, destroy_set)
    if solution is None:
        print(f"{label}: NO SOLUTION")
        return None
    n = len(solution)
    arrows = " ".join(ARROWS[d] for d in solution)
    print(f"{label} ({n} moves): {arrows}")
    return n

print("=== MEDIUM (4-5 moves) ===\n")

# Pattern: block A goes →, block B goes ↓. A must push or avoid B.
# 3x3 board variants with 2 colors, 3 blocks.

# P1: A→ pushes B↓, then B continues ↓
p1 = {"A":[[0,0],[1,0],[2,0],[0,1],[1,1,1],[2,1],[0,2,2],[1,2],[2,2,1]],"B":[
    {"dir":"right","id":1,"origin":[0,0]},
    {"dir":"down","id":2,"origin":[1,0]},
    {"dir":"down","id":1,"origin":[2,0]}],"difficulty":2}
test(p1, "P1")

# P2: ← then ↓ ordering
p2 = {"A":[[0,0,1],[1,0],[2,0],[0,1],[1,1],[2,1],[0,2],[1,2,1],[2,2,2]],"B":[
    {"dir":"left","id":1,"origin":[2,0]},
    {"dir":"down","id":1,"origin":[1,0]},
    {"dir":"right","id":2,"origin":[0,2]}],"difficulty":2}
test(p2, "P2")

# P3: 4 blocks on 4x2
p3 = {"A":[[0,0],[1,0],[2,0],[3,0,1],[0,1,2],[1,1,1],[2,1],[3,1]],"B":[
    {"dir":"right","id":1,"origin":[0,0]},
    {"dir":"left","id":1,"origin":[3,1]},
    {"dir":"down","id":2,"origin":[0,0]}],"difficulty":2}
# 2 at (0,0). Fix.
p3["B"][2] = {"dir":"down","id":2,"origin":[1,0]}
test(p3, "P3")

# P4: 3x3 with 3 blocks going in 3 directions
p4 = {"A":[[0,0],[1,0,1],[2,0],[0,1],[1,1],[2,1,2],[0,2,2],[1,2,1]],"B":[
    {"dir":"right","id":1,"origin":[0,0]},
    {"dir":"down","id":1,"origin":[0,1]},
    {"dir":"left","id":2,"origin":[2,0]}],"difficulty":2}
test(p4, "P4")

# P5: Simple push — → then ↓
p5 = {"A":[[0,0],[1,0],[2,0,1],[0,1],[1,1,2],[2,1,1]],"B":[
    {"dir":"right","id":1,"origin":[0,0]},
    {"dir":"down","id":2,"origin":[1,0]},
    {"dir":"down","id":1,"origin":[2,0]}],"difficulty":2}
test(p5, "P5")

# P6: → → ↓ ← pattern
p6 = {"A":[[0,0],[1,0],[2,0],[0,1,1],[1,1,2],[2,1,1]],"B":[
    {"dir":"right","id":1,"origin":[0,0]},
    {"dir":"down","id":1,"origin":[1,0]},
    {"dir":"down","id":2,"origin":[2,0]}],"difficulty":2}
test(p6, "P6")

# P7: 4x3, left+down
p7 = {"A":[[0,0],[1,0],[2,0],[3,0],[0,1],[1,1],[2,1,1],[3,1],[0,2,2],[1,2,1]],"B":[
    {"dir":"left","id":1,"origin":[3,0]},
    {"dir":"down","id":1,"origin":[1,0]},
    {"dir":"down","id":2,"origin":[0,0]}],"difficulty":2}
test(p7, "P7")

# P8: right + up
p8 = {"A":[[0,0,1],[1,0],[2,0,2],[0,1],[1,1],[2,1],[0,2],[1,2,1],[2,2]],"B":[
    {"dir":"up","id":1,"origin":[1,2]},
    {"dir":"right","id":1,"origin":[0,1]},
    {"dir":"up","id":2,"origin":[2,2]}],"difficulty":2}
test(p8, "P8")

# P9: push chain 3 blocks
p9 = {"A":[[0,0],[1,0],[2,0],[3,0],[0,1,1],[1,1,1],[2,1,2],[3,1,2]],"B":[
    {"dir":"right","id":1,"origin":[0,0]},
    {"dir":"right","id":2,"origin":[2,0]},
    {"dir":"down","id":1,"origin":[1,0]},
    {"dir":"down","id":2,"origin":[3,0]}],"difficulty":2}
test(p9, "P9")

# P10: asymmetric step
p10 = {"A":[[0,0],[1,0],[0,1],[1,1],[2,1,1],[0,2],[1,2,1],[2,2,2]],"B":[
    {"dir":"right","id":1,"origin":[0,0]},
    {"dir":"down","id":1,"origin":[1,0]},
    {"dir":"down","id":2,"origin":[2,1]}],"difficulty":2}
test(p10, "P10")


print("\n=== HARD (6-8 moves) ===\n")

# Scale down H3 (was 8 moves ✓) and create variants

# Q1: H3 from earlier — already 8 moves ✓
q1 = {"A":[[0,0],[1,0],[2,0],[3,0,1],[0,1,1],[1,1],[2,1],[3,1],[0,2],[1,2,2],[2,2],[3,2,2]],"B":[
    {"dir":"right","id":1,"origin":[0,0]},{"dir":"down","id":1,"origin":[1,0]},
    {"dir":"left","id":2,"origin":[3,1]},{"dir":"down","id":2,"origin":[3,0]}],
    "D":[{"origin":[2,2]}],"difficulty":3}
test(q1, "Q1=H3")

# Q2: H6 from earlier — already 6 moves ✓
q2 = {"A":[[0,0],[1,0],[2,0],[3,0,1],[0,1],[1,1],[2,1],[3,1],[0,2,2],[1,2],[2,2,1],[3,2,2]],"B":[
    {"dir":"right","id":1,"origin":[0,0]},{"dir":"down","id":1,"origin":[2,0]},
    {"dir":"left","id":2,"origin":[3,1]},{"dir":"down","id":2,"origin":[0,1]}],
    "D":[{"origin":[2,2]}],"difficulty":3}
test(q2, "Q2=H6")

# Q3: M4 but make it 6+ by adding D block
q3 = {"A":[[0,0],[1,0],[2,0],[0,1],[1,1,1],[2,1],[0,2,2],[1,2],[2,2,1]],"B":[
    {"dir":"right","id":1,"origin":[0,1]},{"dir":"down","id":1,"origin":[1,0]},
    {"dir":"down","id":2,"origin":[0,0]},{"dir":"right","id":1,"origin":[0,2]}],
    "D":[{"origin":[1,2]}],"difficulty":3}
test(q3, "Q3")

# Q4: L-shape destroy
q4 = {"A":[[0,0],[1,0],[2,0,1],[0,1],[1,1],[2,1],[0,2,1],[1,2,2],[2,2]],"B":[
    {"dir":"right","id":1,"origin":[0,0]},{"dir":"down","id":1,"origin":[0,1]},
    {"dir":"right","id":2,"origin":[0,2]},{"dir":"down","id":1,"origin":[2,0]}],
    "D":[{"origin":[2,2]}],"difficulty":3}
test(q4, "Q4")

# Q5: 4x3 + D, push chain
q5 = {"A":[[0,0],[1,0],[2,0],[3,0],[0,1,1],[1,1],[2,1,1],[3,1],[0,2],[1,2,2],[2,2],[3,2,2]],"B":[
    {"dir":"right","id":1,"origin":[0,0]},{"dir":"down","id":1,"origin":[2,0]},
    {"dir":"left","id":2,"origin":[3,0]},{"dir":"down","id":2,"origin":[3,1]}],
    "D":[{"origin":[1,2]}],"difficulty":3}
test(q5, "Q5")

# Q6: 3x4, ordering + D
q6 = {"A":[[0,0],[1,0],[2,0],[0,1,1],[1,1],[2,1],[0,2],[1,2],[2,2,2],[0,3,1],[1,3],[2,3,2]],"B":[
    {"dir":"down","id":1,"origin":[0,0]},{"dir":"right","id":1,"origin":[0,1]},
    {"dir":"down","id":1,"origin":[2,0]},{"dir":"right","id":2,"origin":[0,2]}],
    "D":[{"origin":[2,2]}],"difficulty":3}
test(q6, "Q6")

# Q7: Campaign L6 style — order matters
q7 = {"A":[[0,0],[1,0],[2,0,1],[0,1],[1,1],[2,1],[0,2,1],[1,2],[2,2,2]],"B":[
    {"dir":"right","id":1,"origin":[0,1]},{"dir":"down","id":1,"origin":[1,0]},
    {"dir":"down","id":2,"origin":[2,0]},{"dir":"right","id":1,"origin":[0,0]}],
    "D":[{"origin":[1,2]}],"difficulty":3}
test(q7, "Q7")

# Q8: Wide push — 5 blocks
q8 = {"A":[[0,0],[1,0],[2,0],[3,0],[4,0],[0,1,1],[1,1],[2,1,1],[3,1],[4,1,2]],"B":[
    {"dir":"right","id":1,"origin":[0,0]},{"dir":"down","id":1,"origin":[2,0]},
    {"dir":"left","id":2,"origin":[4,0]},{"dir":"down","id":1,"origin":[0,0]}],
    "D":[{"origin":[3,1]}],"difficulty":3}
# 2 at (0,0). Fix.
q8["B"][3] = {"dir":"down","id":1,"origin":[1,0]}
test(q8, "Q8")
