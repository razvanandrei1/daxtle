#!/usr/bin/env python3
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from solve_levels import parse_level, solve, ARROWS, DIRS

def trace(data, solution):
    board, blocks, teleport_map, destroy_set = parse_level(data)
    positions = list(b["origin"] for b in blocks)
    alive = [True] * len(blocks)
    destroy = set(destroy_set)
    def fmt(i):
        d = blocks[i]["dir"]
        a = {"right":"→","left":"←","up":"↑","down":"↓","none":"●"}[d]
        return f"B{i}(id{blocks[i]['id']}{a})"
    def show():
        for i in range(len(blocks)):
            if alive[i]:
                t = "✓" if positions[i] in blocks[i]["targets"] else ""
                print(f"  {fmt(i)} at {positions[i]} {t}")
            else:
                print(f"  {fmt(i)} DEAD")
        if destroy: print(f"  D: {sorted(destroy)}")
        print()
    print("=== INITIAL ===")
    show()
    from solve_levels import simulate_move
    for step, d in enumerate(solution, 1):
        result = simulate_move(tuple(positions), tuple(alive), blocks, d, board, set(), teleport_map, destroy)
        if result:
            positions = list(result[0])
            alive = list(result[1])
            destroy = set(result[2])
        print(f"Step {step} {ARROWS[d]}:")
        show()
    won = all((not alive[i]) or (positions[i] in blocks[i]["targets"]) for i in range(len(blocks)))
    print(f"{'WIN!' if won else 'NOT WON'}")

v10 = {
    "A": [
        [0,0], [1,0], [2,0], [3,0],
        [0,1], [1,1], [2,1], [3,1,1],
        [0,2,2], [1,2], [2,2], [3,2],
        [1,3,1], [2,3]
    ],
    "B": [
        {"dir":"down", "id":1, "origin":[0,0]},
        {"dir":"down", "id":1, "origin":[2,0]},
        {"dir":"right", "id":1, "origin":[0,1]},
        {"dir":"down", "id":1, "origin":[1,0]},
        {"dir":"left", "id":2, "origin":[3,2]},
    ],
    "D": [{"origin":[0,2]}, {"origin":[2,2]}]
}
trace(v10, ["right","right","right","down","down","left","down","left","left"])
