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

# Final candidate: 15-cell split board
#   Left:        Right:
#   (0,0)(1,0)   (4,0)(5,0)(6,0)
#   (0,1)(1,1)   (4,1)(5,1)(6,1)
#   (0,2)(1,2)   (4,2)
#   (0,3)(1,3)
# Portal: (1,3)↔(4,0). D1(1,2), D2(4,1).

final = {
    "A": [
        [0,0], [1,0], [4,0,1], [5,0], [6,0],
        [0,1], [1,1], [4,1,2], [5,1], [6,1],
        [0,2], [1,2], [4,2],
        [0,3,1], [1,3]
    ],
    "T": [{"id":1, "one_way":False, "pos":[1,3, 4,0]}],
    "B": [
        {"dir":"down", "id":1, "origin":[1,0]},
        {"dir":"down", "id":1, "origin":[0,0]},
        {"dir":"right", "id":1, "origin":[0,2]},
        {"dir":"left", "id":2, "origin":[5,1]},
        {"dir":"left", "id":2, "origin":[6,1]},
    ],
    "D": [{"origin":[1,2]}, {"origin":[4,1]}]
}
test(final, "FINAL 15-cell")

# Also test the wider 17-cell version (Z7)
z7 = {
    "A": [
        [0,0], [1,0], [4,0,1], [5,0], [6,0], [7,0],
        [0,1], [1,1], [4,1,2], [5,1], [6,1], [7,1],
        [0,2], [1,2], [4,2],
        [0,3,1], [1,3]
    ],
    "T": [{"id":1, "one_way":False, "pos":[1,3, 4,0]}],
    "B": [
        {"dir":"down", "id":1, "origin":[1,0]},
        {"dir":"down", "id":1, "origin":[0,0]},
        {"dir":"right", "id":1, "origin":[0,2]},
        {"dir":"left", "id":2, "origin":[5,1]},
        {"dir":"left", "id":2, "origin":[7,1]},
    ],
    "D": [{"origin":[1,2]}, {"origin":[4,1]}]
}
test(z7, "Z7 17-cell")
