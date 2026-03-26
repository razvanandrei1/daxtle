#!/usr/bin/env python3
"""Generate more challenge levels — focused on solvable designs."""

import sys, os, json
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
    return solution

# Rule: For N blocks of color X with T target cells for X: N <= T (or excess die on D blocks)

print("=== MEDIUM (need 4-5 moves) ===\n")

# Principle: 3 blocks, 2 colors, ordering constraint, no D block
# Each block must reach a target of its color

# MA: 3 blocks on 3x3, ordering
ma = {"A":[[0,0],[1,0],[2,0,1],[0,1],[1,1],[2,1,2],[0,2,1],[1,2],[2,2]],"B":[
    {"dir":"right","id":1,"origin":[0,0]},{"dir":"down","id":1,"origin":[0,1]},
    {"dir":"right","id":2,"origin":[0,2]}],"difficulty":2}
test(ma, "MA")

# MB: Push needed
mb = {"A":[[0,0],[1,0,1],[2,0],[0,1],[1,1],[2,1],[0,2,1],[1,2,2],[2,2]],"B":[
    {"dir":"down","id":1,"origin":[1,0]},{"dir":"right","id":1,"origin":[0,1]},
    {"dir":"down","id":2,"origin":[2,0]}],"difficulty":2}
test(mb, "MB")

# MC: L-shape, 3 blocks
mc = {"A":[[0,0],[1,0],[0,1],[1,1,1],[2,1],[0,2],[1,2,2],[2,2,1]],"B":[
    {"dir":"down","id":1,"origin":[0,0]},{"dir":"right","id":1,"origin":[0,2]},
    {"dir":"down","id":2,"origin":[1,0]}],"difficulty":2}
test(mc, "MC")

# MD: 4 blocks, wider
md = {"A":[[0,0],[1,0],[2,0],[3,0],[0,1,1],[1,1],[2,1,1],[3,1,2]],"B":[
    {"dir":"right","id":1,"origin":[0,0]},{"dir":"down","id":1,"origin":[2,0]},
    {"dir":"left","id":2,"origin":[3,0]}],"difficulty":2}
test(md, "MD")

# ME: 3 blocks, push chain
me = {"A":[[0,0],[1,0],[2,0],[0,1,1],[1,1],[2,1,1],[0,2,2],[1,2]],"B":[
    {"dir":"right","id":1,"origin":[0,0]},{"dir":"down","id":1,"origin":[1,0]},
    {"dir":"down","id":2,"origin":[0,0]}],"difficulty":2}
# Fix: 2 blocks at (0,0)
me["B"][2] = {"dir":"down","id":2,"origin":[2,0]}
test(me, "ME")

# MF: 2 blocks simple ordering
mf = {"A":[[0,0],[1,0],[2,0,1],[0,1],[1,1],[2,1],[0,2,1],[1,2],[2,2,2]],"B":[
    {"dir":"down","id":1,"origin":[2,0]},{"dir":"right","id":1,"origin":[0,0]},
    {"dir":"right","id":2,"origin":[0,2]}],"difficulty":2}
test(mf, "MF")

# MG: T-shape
mg = {"A":[[0,0],[1,0],[2,0],[3,0],[1,1],[2,1],[1,2,1],[2,2,2],[3,0,1]],"B":[
    {"dir":"down","id":1,"origin":[1,0]},{"dir":"down","id":2,"origin":[2,0]},
    {"dir":"left","id":1,"origin":[3,0]}],"difficulty":2}
test(mg, "MG")

# MH: Right-then-down
mh = {"A":[[0,0],[1,0],[2,0],[0,1],[1,1,1],[2,1],[0,2],[1,2,2],[2,2,1]],"B":[
    {"dir":"right","id":1,"origin":[0,0]},{"dir":"down","id":1,"origin":[2,0]},
    {"dir":"left","id":2,"origin":[2,1]}],"difficulty":2}
test(mh, "MH")

# MI: Cross with cargo
mi = {"A":[[1,0],[0,1],[1,1],[2,1],[1,2],[0,1,1],[2,1,2],[1,2,1]],"B":[
    {"dir":"none","id":1,"origin":[1,1]},{"dir":"down","id":1,"origin":[1,0]},
    {"dir":"left","id":2,"origin":[2,1]}],"difficulty":2}
# Fix duplicate cells
mi["A"] = [[1,0],[0,1,1],[1,1],[2,1,2],[1,2,1]]
test(mi, "MI")

# MJ: 4-block interleave
mj = {"A":[[0,0],[1,0],[2,0,1],[0,1],[1,1,2],[2,1],[0,2,1],[1,2],[2,2,2]],"B":[
    {"dir":"right","id":1,"origin":[0,0]},{"dir":"left","id":1,"origin":[2,1]},
    {"dir":"down","id":2,"origin":[1,0]},{"dir":"right","id":2,"origin":[0,2]}],"difficulty":2}
test(mj, "MJ")

# MK: Simple push
mk = {"A":[[0,0],[1,0],[2,0,1],[0,1,1],[1,1],[2,1],[1,2,2],[2,2,2]],"B":[
    {"dir":"right","id":1,"origin":[0,0]},{"dir":"down","id":1,"origin":[0,1]},
    {"dir":"down","id":2,"origin":[1,0]},{"dir":"right","id":2,"origin":[0,1]}],"difficulty":2}
# 2 blocks at (0,1). Fix.
mk["B"][3] = {"dir":"down","id":2,"origin":[2,0]}
test(mk, "MK")


print("\n=== HARD (need 6-8 moves) ===\n")

# HA: Destroy + 2 colors, campaign L14 inspired
ha = {"A":[[0,0],[1,0],[2,0],[0,1,1],[1,1],[2,1,1],[0,2],[1,2],[2,2,2],[1,3,1]],"B":[
    {"dir":"down","id":1,"origin":[0,0]},{"dir":"down","id":1,"origin":[1,0]},
    {"dir":"right","id":1,"origin":[0,1]},{"dir":"right","id":2,"origin":[0,2]}],
    "D":[{"origin":[1,2]}],"difficulty":3}
test(ha, "HA")

# HB: 4 blocks, push + destroy
hb = {"A":[[0,0],[1,0],[2,0],[3,0,1],[0,1],[1,1],[2,1],[3,1,1],[0,2,2],[1,2],[2,2],[3,2,2]],"B":[
    {"dir":"right","id":1,"origin":[0,0]},{"dir":"down","id":1,"origin":[1,0]},
    {"dir":"left","id":2,"origin":[3,1]},{"dir":"down","id":2,"origin":[3,0]}],
    "D":[{"origin":[2,2]}],"difficulty":3}
test(hb, "HB")

# HC: 3 colors + destroy (campaign L16 inspired)
hc = {"A":[[0,0],[1,0],[2,0],[3,0,1],[1,1,2],[2,1,3],[3,1],[1,2],[2,2],[3,2],[0,3],[1,3],[2,3]],"B":[
    {"dir":"right","id":1,"origin":[0,0]},{"dir":"left","id":2,"origin":[3,1]},
    {"dir":"up","id":3,"origin":[2,3]},{"dir":"down","id":1,"origin":[2,0]}],
    "D":[{"origin":[2,2]}],"difficulty":3}
test(hc, "HC")

# HD: Wide + push chain
hd = {"A":[[0,0],[1,0],[2,0],[3,0],[4,0,1],[0,1,1],[1,1],[2,1],[3,1],[4,1],[0,2,2],[1,2,2]],"B":[
    {"dir":"right","id":1,"origin":[0,0]},{"dir":"right","id":1,"origin":[0,1]},
    {"dir":"down","id":2,"origin":[1,0]},{"dir":"left","id":2,"origin":[4,1]}],
    "D":[{"origin":[2,1]}],"difficulty":3}
test(hd, "HD")

# HE: Diamond + ordering + D
he = {"A":[[1,0],[0,1],[1,1],[2,1],[0,2],[1,2],[2,2],[1,3],[1,0,1],[0,1,1],[2,2,2],[1,3,2]],"B":[
    {"dir":"down","id":1,"origin":[1,0]},{"dir":"right","id":1,"origin":[0,1]},
    {"dir":"left","id":2,"origin":[2,1]},{"dir":"down","id":2,"origin":[2,2]}],
    "D":[{"origin":[1,2]}],"difficulty":3}
# Fix: (1,0) appears twice with different targets
he["A"] = [[1,0],[0,1,1],[1,1],[2,1],[0,2,1],[1,2],[2,2],[1,3,2]]
he["B"] = [
    {"dir":"down","id":1,"origin":[1,0]},{"dir":"left","id":1,"origin":[2,1]},
    {"dir":"down","id":2,"origin":[2,2]},{"dir":"right","id":2,"origin":[0,2]}]
he["D"] = [{"origin":[1,2]}]
test(he, "HE")

# HF: Push through — 5 blocks
hf = {"A":[[0,0],[1,0],[2,0],[0,1],[1,1,1],[2,1],[3,1,2],[0,2,1],[1,2],[2,2],[3,2,2]],"B":[
    {"dir":"down","id":1,"origin":[0,0]},{"dir":"right","id":1,"origin":[0,1]},
    {"dir":"down","id":1,"origin":[2,0]},{"dir":"left","id":2,"origin":[3,1]},
    {"dir":"left","id":2,"origin":[3,2]}],"D":[{"origin":[2,2]}],"difficulty":3}
test(hf, "HF")

# HG: Wide ordering
hg = {"A":[[0,0],[1,0],[2,0],[3,0],[0,1,1],[1,1,1],[2,1],[3,1],[0,2],[1,2],[2,2,2],[3,2,2]],"B":[
    {"dir":"right","id":1,"origin":[0,0]},{"dir":"left","id":1,"origin":[3,0]},
    {"dir":"down","id":2,"origin":[2,0]},{"dir":"down","id":2,"origin":[3,0]}],"difficulty":3}
# 2 blocks at (3,0). Fix.
hg["B"][3] = {"dir":"left","id":2,"origin":[3,1]}
test(hg, "HG")

# HH: Asymmetric + D
hh = {"A":[[0,0],[1,0],[2,0],[3,0],[0,1],[1,1,1],[2,1],[3,1,2],[1,2,1],[2,2],[3,2,2]],"B":[
    {"dir":"right","id":1,"origin":[0,0]},{"dir":"down","id":1,"origin":[1,0]},
    {"dir":"left","id":2,"origin":[3,0]},{"dir":"down","id":2,"origin":[3,1]}],
    "D":[{"origin":[2,2]}],"difficulty":3}
test(hh, "HH")
