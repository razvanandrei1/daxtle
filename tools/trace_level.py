#!/usr/bin/env python3
"""Trace a solution step-by-step to verify puzzle logic."""

import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from solve_levels import parse_level, solve, ARROWS, DIRS

def trace(data, solution):
    board, blocks, teleport_map, destroy_set = parse_level(data)
    positions = list(b["origin"] for b in blocks)
    alive = [True] * len(blocks)
    destroy = set(destroy_set)

    def fmt_block(i):
        d = blocks[i]["dir"]
        arrow = {"right":"→","left":"←","up":"↑","down":"↓","none":"●"}[d]
        cid = blocks[i]["id"]
        return f"B{i}(id{cid}{arrow})"

    def show():
        for i, b in enumerate(blocks):
            if alive[i]:
                tgt = "✓TGT" if positions[i] in b["targets"] else ""
                print(f"    {fmt_block(i)} at {positions[i]} {tgt}")
            else:
                print(f"    {fmt_block(i)} DEAD")
        if destroy:
            print(f"    D blocks: {sorted(destroy)}")
        print()

    print("=== INITIAL STATE ===")
    print(f"  Portal: {teleport_map}")
    print(f"  D: {sorted(destroy_set)}")
    print(f"  Targets: ", end="")
    for i, b in enumerate(blocks):
        print(f"{fmt_block(i)}→{sorted(b['targets'])} ", end="")
    print()
    show()

    for step, d in enumerate(solution, 1):
        dv = DIRS[d]
        movers = [i for i, b in enumerate(blocks) if alive[i] and b["dir"] == d]
        if not movers:
            print(f"Step {step} {ARROWS[d]}: no movers!")
            continue

        movers.sort(key=lambda i: -(positions[i][0]*dv[0] + positions[i][1]*dv[1]))

        moved = []
        for mi in movers:
            old = positions[mi]
            dest = (old[0]+dv[0], old[1]+dv[1])
            # Check for push
            for j in range(len(positions)):
                if j != mi and alive[j] and positions[j] == dest:
                    pushed_to = (dest[0]+dv[0], dest[1]+dv[1])
                    if dest in teleport_map:
                        exit_cell = teleport_map[dest]
                        cont = (exit_cell[0]+dv[0], exit_cell[1]+dv[1])
                        positions[j] = cont if cont in board else exit_cell
                        moved.append(f"{fmt_block(j)} pushed→{positions[j]}")
                    else:
                        positions[j] = pushed_to
                        moved.append(f"{fmt_block(j)} pushed→{pushed_to}")

            if dest in teleport_map:
                exit_cell = teleport_map[dest]
                cont = (exit_cell[0]+dv[0], exit_cell[1]+dv[1])
                # Check if cont is free
                cont_free = cont in board and all(
                    not (alive[j] and positions[j] == cont) for j in range(len(positions)) if j != mi
                )
                if cont_free:
                    positions[mi] = cont
                    moved.append(f"{fmt_block(mi)} {old}→{dest}=PORTAL→{exit_cell}→{cont}")
                else:
                    positions[mi] = exit_cell
                    moved.append(f"{fmt_block(mi)} {old}→{dest}=PORTAL→{exit_cell}")
            else:
                positions[mi] = dest
                moved.append(f"{fmt_block(mi)} {old}→{dest}")

        # Handle destroy
        for i in range(len(positions)):
            if alive[i] and positions[i] in destroy:
                moved.append(f"{fmt_block(i)} DESTROYED at {positions[i]}")
                alive[i] = False
                destroy.discard(positions[i])

        print(f"Step {step} {ARROWS[d]}: {'; '.join(moved)}")
        show()

    # Check win
    won = all(
        (not alive[i]) or (positions[i] in blocks[i]["targets"])
        for i in range(len(blocks))
    )
    print(f"{'WIN!' if won else 'NOT WON'}")


# C2 level
c2 = {
    "A": [
        [1,0], [2,0,1], [3,0],
        [0,1], [1,1], [2,1,1], [3,1], [4,1],
        [0,2], [1,2], [3,2], [4,2],
        [1,3,2], [2,3], [3,3,1]
    ],
    "B": [
        {"dir":"down", "id":1, "origin":[0,1]},
        {"dir":"left", "id":1, "origin":[3,1]},
        {"dir":"up", "id":1, "origin":[2,3]},
        {"dir":"right", "id":1, "origin":[1,3]},
        {"dir":"down", "id":2, "origin":[1,0]}
    ],
    "T": [{"id":1, "one_way":False, "pos":[0,2, 4,1]}],
    "D": [{"origin":[4,2]}]
}

solution = ["left","left","right","up","right","up","down","left","left","up","left","down","down"]
trace(c2, solution)
