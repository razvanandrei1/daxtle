#!/usr/bin/env python3
"""Level 20 — 2 different color cargo blocks (dir=none)."""

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
# Concept: 2 cargo blocks (dir=none), different colors.
# Must be pushed to their matching color targets.
# The puzzle: which block pushes which cargo, and from which direction.
# Pushing one cargo might block the path for the other.
# ══════════════════════════════════════════════════════════════


# ──── A: Diamond, 2 cargos in center ────
#   Row 0:       (1,0) (2,0) (3,0)
#   Row 1: (0,1) (1,1) (2,1) (3,1)
#   Row 2: (0,2) (1,2) (2,2) (3,2)
#   Row 3:       (1,3) (2,3)
# 14 cells.

a1 = {
    "A": [
        [1,0], [2,0], [3,0],
        [0,1,1], [1,1], [2,1], [3,1],
        [0,2], [1,2], [2,2], [3,2,2],
        [1,3], [2,3]
    ],
    "B": [
        {"dir":"none", "id":1, "origin":[2,1]},   # cargo green — must be pushed to (0,1)
        {"dir":"none", "id":2, "origin":[1,2]},   # cargo red — must be pushed to (3,2)
        {"dir":"right", "id":1, "origin":[1,0]},  # pusher — can push cargo green left? No, → pushes right.
        {"dir":"left", "id":2, "origin":[2,3]},   # pusher — pushes cargo red right? No, ← pushes left.
    ],
    "D": []
}
# → pushes things RIGHT. ← pushes LEFT. Need pushers in the right direction.
# To push cargo1 LEFT to (0,1): need a block going LEFT that hits cargo1.
# To push cargo2 RIGHT to (3,2): need a block going RIGHT that hits cargo2.
# Fix:
a1["B"] = [
    {"dir":"none", "id":1, "origin":[2,1]},   # cargo green at center
    {"dir":"none", "id":2, "origin":[1,2]},   # cargo red at center
    {"dir":"left", "id":1, "origin":[3,1]},   # pushes cargo1 left: (3,1)→(2,1)cargo→push cargo to (1,1)
    {"dir":"right", "id":2, "origin":[0,2]},  # pushes cargo2 right: (0,2)→(1,2)cargo→push cargo to (2,2)
]
# ← : pusher1(3,1)→(2,1) pushes cargo1→(1,1). ←: pusher1(2,1)→(1,1) pushes cargo1→(0,1)✓.
# → : pusher2(0,2)→(1,2) pushes cargo2→(2,2). →: pusher2(1,2)→(2,2) pushes cargo2→(3,2)✓.
# But when ←: BOTH pusher1 and pusher2 have... no, pusher2 is →. Only pusher1 moves on ←.
# When →: BOTH pusher1 and pusher2 have... no, pusher1 is ←. Only pusher2 moves on →.
# Independent! No interaction. ←← →→ = 4 moves. Too simple.
test(a1, "A1 independent")


# ──── B: Cargos block each other's paths ────
# Cargo1 must cross cargo2's position, or pushers interfere.

b1 = {
    "A": [
        [1,0], [2,0], [3,0],
        [0,1], [1,1], [2,1], [3,1,1],
        [0,2,2], [1,2], [2,2], [3,2],
        [1,3], [2,3]
    ],
    "B": [
        {"dir":"none", "id":1, "origin":[1,1]},   # cargo green — push right to (3,1)
        {"dir":"none", "id":2, "origin":[2,2]},   # cargo red — push left to (0,2)
        {"dir":"right", "id":1, "origin":[1,0]},  # pusher → pushes cargo1 right
        {"dir":"left", "id":2, "origin":[2,3]},   # pusher ← pushes cargo2 left
    ],
    "D": []
}
# →: pusher(1,0)→(2,0). Doesn't push cargo1 (different row). Hmm.
# Need pusher in same row as cargo.
# Pusher for cargo1 (at (1,1)): must be in row 1, going →. Pusher at (0,1).
# Pusher for cargo2 (at (2,2)): must be in row 2, going ←. Pusher at (3,2).
b1["B"] = [
    {"dir":"none", "id":1, "origin":[1,1]},   # cargo green
    {"dir":"none", "id":2, "origin":[2,2]},   # cargo red
    {"dir":"right", "id":1, "origin":[0,1]},  # pushes cargo1 right through row 1
    {"dir":"left", "id":2, "origin":[3,2]},   # pushes cargo2 left through row 2
]
# →: pusher1(0,1)→(1,1)cargo→push cargo1→(2,1). pusher1 at (1,1).
# →: pusher1(1,1)→(2,1)cargo1→push cargo1→(3,1)✓.
# ←: pusher2(3,2)→(2,2)cargo2→push cargo2→(1,2). pusher2 at (2,2).
# ←: pusher2(2,2)→(1,2)cargo2→push cargo2→(0,2)✓.
# Still independent! 4 moves. ←←→→ or →→←←.
# Need interaction. What if cargos are in the SAME row?
test(b1, "B1 same-row cargos?")


# ──── C: Both cargos in same row, must be pushed in opposite directions ────
c1 = {
    "A": [
        [1,0], [2,0], [3,0],
        [0,1,1], [1,1], [2,1], [3,1,2],
        [0,2], [1,2], [2,2], [3,2],
        [1,3], [2,3]
    ],
    "B": [
        {"dir":"none", "id":1, "origin":[1,1]},   # cargo green — push left to (0,1)
        {"dir":"none", "id":2, "origin":[2,1]},   # cargo red — push right to (3,1)
        {"dir":"left", "id":1, "origin":[3,0]},   # pusher ← in row 0, needs to get to row 1
        {"dir":"right", "id":2, "origin":[0,2]},  # pusher → in row 2, needs to get to row 1
    ],
    "D": []
}
# Pushers not in row 1! They need to be pushed into row 1 first? Or go ↓/↑ to row 1?
# But pushers have fixed directions (← and →). Can't go ↓/↑.
# They need to already be in row 1. Fix.

c2 = {
    "A": [
        [1,0], [2,0], [3,0],
        [0,1,1], [1,1], [2,1], [3,1,2],
        [0,2], [1,2], [2,2], [3,2],
        [1,3], [2,3]
    ],
    "B": [
        {"dir":"none", "id":1, "origin":[2,1]},   # cargo green — needs to go LEFT to (0,1)
        {"dir":"none", "id":2, "origin":[1,1]},   # cargo red — needs to go RIGHT to (3,1)
        {"dir":"left", "id":1, "origin":[3,1]},   # pusher ← in row 1, pushes cargo green left
        {"dir":"right", "id":2, "origin":[0,1]},  # pusher → in row 1, pushes cargo red right
    ],
    "D": []
}
# KEY INTERACTION: both pushers and cargos are in row 1!
# →: pusher2(0,1)→(1,1)cargo_red→push cargo_red→(2,1)cargo_green→push cargo_green→(3,1)✓target!
# Wait: pusher2 pushes cargo_red, which pushes cargo_green. Chain push!
# After →: pusher2(1,1), cargo_red(2,1), cargo_green(3,1)✓.
# But cargo_green target is (0,1) not (3,1)! cargo_green pushed wrong way!
# ← first: pusher1(3,1)→(2,1)cargo_green→push cargo_green→(1,1)cargo_red→push cargo_red→(0,1)✓target?
# Wait, cargo_red target is (3,1). cargo_red pushed LEFT to (0,1). Wrong!
# The cargos block each other. You can't push green left without pushing red left too.
# This creates the real puzzle!

# How to solve: must separate the cargos first. Push one up/down out of the way.
# But cargos can't move on their own. Need a pusher in a different direction.
# What if there's a ↓ block that pushes a cargo down out of the row?

c3 = {
    "A": [
        [1,0], [2,0], [3,0],
        [0,1,1], [1,1], [2,1], [3,1,2],
        [0,2], [1,2], [2,2], [3,2],
        [1,3], [2,3]
    ],
    "B": [
        {"dir":"none", "id":1, "origin":[2,1]},   # cargo green
        {"dir":"none", "id":2, "origin":[1,1]},   # cargo red
        {"dir":"left", "id":1, "origin":[3,1]},   # pusher left
        {"dir":"right", "id":2, "origin":[0,2]},  # pusher right (row 2, not row 1!)
        {"dir":"down", "id":1, "origin":[1,0]},   # ↓ pusher — pushes cargo_red DOWN out of row 1
    ],
    "D": []
}
# ↓: pusher_down(1,0)→(1,1)cargo_red→push cargo_red→(1,2). cargo_red now in row 2!
# Now row 1: pusher_left(3,1), cargo_green(2,1). No cargo_red blocking.
# ←: pusher_left(3,1)→(2,1)cargo_green→push→(1,1)→(0,1)✓? Wait, step by step.
# ←1: pusher_left(3,1)→(2,1). cargo_green at (2,1)? Yes. Push cargo_green→(1,1). pusher at (2,1).
# ←2: pusher(2,1)→(1,1). cargo_green at (1,1). Push→(0,1)✓.
# Now cargo_red at (1,2). Need to push right to (3,1)?
# →: pusher_right(0,2)→(1,2)cargo_red→push cargo_red→(2,2).
# →: pusher(1,2)→(2,2)cargo_red→push→(3,2). target (3,1) is row 1, not row 2!
# cargo_red pushed to wrong row! Need to push it back up then right.
# But there's no ↑ pusher.
# Fix: target at (3,2) instead of (3,1)?
c3["A"][6] = [3,1]
c3["A"][10] = [3,2,2]  # target id=2 at (3,2)
test(c3, "C3 separate then push")


# ──── D: Vertical cargos, pushed in different directions ────
#   Row 0:       (1,0) (2,0)
#   Row 1: (0,1) (1,1) (2,1) (3,1)
#   Row 2: (0,2) (1,2) (2,2) (3,2)
#   Row 3:       (1,3) (2,3)
# 12 cells. Compact diamond.

d1 = {
    "A": [
        [1,0], [2,0],
        [0,1], [1,1], [2,1], [3,1,2],
        [0,2,1], [1,2], [2,2], [3,2],
        [1,3], [2,3]
    ],
    "B": [
        {"dir":"none", "id":1, "origin":[2,1]},   # cargo green — push down to row 2, then left to (0,2)
        {"dir":"none", "id":2, "origin":[1,2]},   # cargo red — push up to row 1, then right to (3,1)
        {"dir":"down", "id":1, "origin":[2,0]},   # pushes cargo green down
        {"dir":"up", "id":2, "origin":[1,3]},     # pushes cargo red up
        {"dir":"left", "id":1, "origin":[3,2]},   # pushes cargo green left after it's in row 2
        {"dir":"right", "id":2, "origin":[0,1]},  # pushes cargo red right after it's in row 1
    ],
    "D": []
}
# 6 blocks! ↓ pushes green to row 2. ← pushes green left. ↑ pushes red to row 1. → pushes red right.
# ↓: pusher_down(2,0)→(2,1)cargo_green→push→(2,2). Green now in row 2.
# ↑: pusher_up(1,3)→(1,2)cargo_red→push→(1,1). Red now in row 1.
# ←: pusher_left(3,2)→(2,2)green→push→(1,2)→(0,2)✓? ←1:(3,2)→(2,2)push green→(1,2). ←2:(2,2)→(1,2)push→(0,2)✓.
# →: pusher_right(0,1)→(1,1)red→push→(2,1)→(3,1)✓? →1:(0,1)→(1,1)push red→(2,1). →2:(1,1)→(2,1)push→(3,1)✓.
# Total: ↓ ↑ ←← →→ = 6 moves. Or any interleaving.
# But: do they interact? ↓ and ↑ put cargos in new rows. ← and → push them to targets.
# Possible interaction: ← moves pusher_left while → moves pusher_right. Different dirs, independent.
# What if ↓ before ↑ matters? Green goes to (2,2). Then ↑ red goes to (1,1). No conflict.
# What about ← pushing red? Red is in row 1 after ↑. ← moves pusher_left in row 2. Different rows. No conflict.
# Still mostly independent. Need more interaction!
test(d1, "D1 6blocks")


# ──── E: Both cargos in column, pushers must route around each other ────
e1 = {
    "A": [
        [0,0,1], [1,0], [2,0],
        [0,1], [1,1], [2,1],
        [0,2], [1,2], [2,2,2],
        [0,3], [1,3]
    ],
    "B": [
        {"dir":"none", "id":1, "origin":[1,1]},   # cargo green — push to (0,0)
        {"dir":"none", "id":2, "origin":[1,2]},   # cargo red — push to (2,2)
        {"dir":"up", "id":1, "origin":[1,3]},     # ↑ pushes cargo red up, then cargo green up
        {"dir":"right", "id":2, "origin":[0,1]},  # → pushes cargo green right
    ],
    "D": []
}
# ↑: pusher_up(1,3)→(1,2)cargo_red→push red→(1,1)cargo_green→push green→(1,0). Chain push!
# Both cargos pushed up! Green at (1,0), red at (1,1).
# But green needs (0,0) and red needs (2,2). Green is now above its target. Red far from target.
# ←: nobody has ←.  →: pusher_right(0,1)→(1,1)red→push red→(2,1). Red in row 1 now.
# But red needs (2,2). Need ↓ to push red down. No ↓ pusher!
# Add ↓ pusher.
e1["B"].append({"dir":"down", "id":2, "origin":[2,0]})
# ↓: pusher_down(2,0)→(2,1) red at (2,1)? If red was pushed there by →.
# Let me just test and see what BFS finds.
test(e1, "E1 column chain")


# ──── F: 2 cargos that must swap positions ────
f1 = {
    "A": [
        [0,0], [1,0], [2,0], [3,0],
        [0,1,2], [1,1], [2,1], [3,1,1],
        [0,2], [1,2], [2,2], [3,2],
        [1,3], [2,3]
    ],
    "B": [
        {"dir":"none", "id":1, "origin":[1,1]},   # cargo green at (1,1) — target (3,1)
        {"dir":"none", "id":2, "origin":[2,1]},   # cargo red at (2,1) — target (0,1)
        {"dir":"down", "id":1, "origin":[1,0]},   # ↓ pushes green/red down
        {"dir":"down", "id":1, "origin":[2,0]},   # ↓ pushes red/green down
        {"dir":"right", "id":2, "origin":[0,2]},  # → pushes from left
        {"dir":"left", "id":1, "origin":[3,2]},   # ← pushes from right
    ],
    "D": []
}
# The cargos need to SWAP: green goes right, red goes left. But they block each other.
# Must push one down first to make room.
test(f1, "F1 cargo swap")


# ──── G: Simpler — 2 cargos, 3 active blocks, tight board ────
g1 = {
    "A": [
        [0,0], [1,0], [2,0],
        [0,1,2], [1,1], [2,1,1],
        [0,2], [1,2], [2,2],
        [1,3]
    ],
    "B": [
        {"dir":"none", "id":1, "origin":[1,1]},   # cargo green
        {"dir":"none", "id":2, "origin":[1,2]},   # cargo red
        {"dir":"down", "id":1, "origin":[1,0]},   # ↓ pushes both cargos down
        {"dir":"right", "id":2, "origin":[0,1]},  # → pushes cargo green right to (2,1)✓
        {"dir":"left", "id":1, "origin":[2,2]},   # ← pushes cargo red left to (0,2)? target?
    ],
    "D": []
}
# ↓ pushes cargo_green to (1,2) and cargo_red to (1,3)? But first ↓ pushes green into red.
# ↓: pusher(1,0)→(1,1)green→push green→(1,2)red→push red→(1,3). Chain push!
# Green at (1,2), red at (1,3). But targets: green(2,1) red(0,1).
# → pushes green right? Green at (1,2) now, → pusher at (0,1). →: (0,1)→(1,1). Green not in row 1 anymore.
# This doesn't work easily. Need different approach.
# What if we DON'T ↓ first? → first to push green right, then ↓?
# →: pusher_right(0,1)→(1,1)green→push green→(2,1)✓.
# Then ↓: pusher_down(1,0)→(1,1). Empty now (green moved). pusher at (1,1).
# ↓: pusher(1,1)→(1,2)red→push red→(1,3).
# ←: pusher_left(2,2)→(1,2). Red at (1,3) not at (1,2). (1,2) is empty. pusher at (1,2).
# ←: pusher(1,2)→(0,2). Where's red? At (1,3). Not in row 2. ← doesn't reach red.
# Hmm. Need to push red left BEFORE ↓ pushes it to row 3.
# ←: pusher_left(2,2)→(1,2)red→push red→(0,2). Wait, but cargo_green at (1,1) is above red at (1,2).
# ← pushes in row 2: pusher at (2,2)→(1,2) pushes red→(0,2). But is (0,2) a target for red?
# target id=2 at (0,1). (0,2) not target. Fix.
g1["A"][3] = [0,1]
g1["A"][6] = [0,2,2]  # target id=2 at (0,2)
# ←: pusher(2,2)→(1,2)red→push→(0,2)✓. 1 move.
# →: pusher(0,1)→(1,1)green→push→(2,1)✓. 1 move.
# Solution: ← → = 2 moves? Or → ← = 2 moves?
# When ←: only pusher_left moves. When →: only pusher_right moves.
# Independent. 2 moves. Too simple.
# But wait: ↓ pusher at (1,0) also exists. What if ↓ causes issues?
# ↓ should NOT be needed. If player swipes ↓: pusher(1,0)→(1,1). If green still there: push green→(1,2)red→push red→(1,3). Both cargos displaced!
# Trap: ↓ is a trap move that ruins everything.
# But optimal is just ← → or → ← = 2 moves. No real puzzle.
test(g1, "G1 simple 2-cargo")


# ──── H: More complex — cargos must be routed via push sequences ────
h1 = {
    "A": [
        [0,0], [1,0], [2,0], [3,0],
        [0,1,1], [1,1], [2,1], [3,1],
        [0,2], [1,2], [2,2], [3,2,2],
        [1,3], [2,3]
    ],
    "B": [
        {"dir":"none", "id":1, "origin":[2,1]},   # cargo green — target (0,1). Push left.
        {"dir":"none", "id":2, "origin":[1,2]},   # cargo red — target (3,2). Push right.
        {"dir":"down", "id":1, "origin":[2,0]},   # ↓ pushes green down to row 2
        {"dir":"up", "id":2, "origin":[1,3]},     # ↑ pushes red up to row 1
        {"dir":"left", "id":1, "origin":[3,1]},   # ← pushes green left (after it's separated from red's row)
        {"dir":"right", "id":2, "origin":[0,2]},  # → pushes red right (after it's separated from green's row)
    ],
    "D": []
}
# The trick: green is in row 1, red is in row 2. They're in different rows already!
# ← pushes green in row 1: (3,1)→(2,1)green→push→(1,1)→(0,1)✓. 2← moves.
# → pushes red in row 2: (0,2)→(1,2)red→push→(2,2)→(3,2)✓. 2→ moves.
# Independent again! Unless pushers interfere.
# What if ↓ and ↑ are needed to CREATE the push?
# Actually no, pushers are already in the right rows. ↓ and ↑ are extra blocks.
# Skip ↓ and ↑. Just 4 blocks.
h2 = {
    "A": [
        [0,0], [1,0], [2,0], [3,0],
        [0,1,1], [1,1], [2,1], [3,1],
        [0,2], [1,2], [2,2], [3,2,2],
        [1,3], [2,3]
    ],
    "B": [
        {"dir":"none", "id":1, "origin":[2,1]},   # cargo green
        {"dir":"none", "id":2, "origin":[1,2]},   # cargo red
        {"dir":"left", "id":1, "origin":[3,1]},   # ← pushes green
        {"dir":"right", "id":2, "origin":[0,2]},  # → pushes red
    ],
    "D": []
}
# ←← →→ = 4 moves. Independent. Boring.
# MAKE THEM INTERACT: put a pusher where it will push the WRONG cargo if done in wrong order.

h3 = {
    "A": [
        [0,0], [1,0], [2,0], [3,0],
        [0,1,1], [1,1], [2,1], [3,1],
        [0,2], [1,2], [2,2], [3,2,2],
        [1,3], [2,3]
    ],
    "B": [
        {"dir":"none", "id":1, "origin":[1,1]},   # cargo green — target (0,1)
        {"dir":"none", "id":2, "origin":[2,2]},   # cargo red — target (3,2)
        {"dir":"left", "id":1, "origin":[3,1]},   # ← in row 1 pushes green left
        {"dir":"right", "id":2, "origin":[0,2]},  # → in row 2 pushes red right
        {"dir":"down", "id":1, "origin":[2,0]},   # ↓ col 2 — pushes NOTHING initially, but after → ...
        {"dir":"up", "id":2, "origin":[1,3]},     # ↑ col 1 — pushes NOTHING initially, but after ← ...
    ],
    "D": []
}
# ← : pusher(3,1)→(2,1)→(1,1)green→push→(0,1)✓. 2←.
# → : pusher(0,2)→(1,2)→(2,2)red→push→(3,2)✓. 2→.
# ↓ is trap: ↓ pusher(2,0)→(2,1). After ← moved pusher to (2,1)?
# If ← before ↓: pusher_left at (2,1) after ←1. ↓: down_pusher(2,0)→(2,1) pusher_left there! Push→(2,2) red at (2,2). Push→(2,3). Chain! Messes everything up.
# So ↓ is a trap move. Player should not use it. But it exists on the board.
# Still: optimal is just ←← →→ = 4 moves. Not very interesting.
test(h3, "H3 with trap moves")


# ──── I: Cargos that MUST be re-routed — pushed down then across ────
i1 = {
    "A": [
        [0,0], [1,0], [2,0],
        [0,1], [1,1], [2,1],
        [0,2,1], [1,2], [2,2,2],
    ],
    "B": [
        {"dir":"none", "id":1, "origin":[2,1]},   # cargo green at (2,1) — target (0,2). Must go ↓ then ←.
        {"dir":"none", "id":2, "origin":[0,1]},   # cargo red at (0,1) — target (2,2). Must go ↓ then →.
        {"dir":"down", "id":1, "origin":[0,0]},   # ↓ pushes cargo red down
        {"dir":"down", "id":1, "origin":[2,0]},   # ↓ pushes cargo green down
        {"dir":"left", "id":2, "origin":[1,2]},   # ← pushes green left to (0,2)✓
        {"dir":"right", "id":1, "origin":[1,2]},  # Can't have 2 blocks at same cell!
    ],
    "D": []
}
# Fix: 2 blocks at (1,2). Remove one.
# Actually the → and ← pushers need to be in row 2 to push the cargos AFTER they're pushed down.
# But can't have both at (1,2). One at (0,2)? That's the target. One at (2,2)? That's the target.
# Tricky. Let me use a wider board.

i2 = {
    "A": [
        [0,0], [1,0], [2,0], [3,0],
        [0,1], [1,1], [2,1], [3,1],
        [0,2,1], [1,2], [2,2], [3,2,2],
    ],
    "B": [
        {"dir":"none", "id":1, "origin":[2,1]},   # cargo green — push ↓ to (2,2), then ← to (0,2)
        {"dir":"none", "id":2, "origin":[1,1]},   # cargo red — push ↓ to (1,2), then → to (3,2)
        {"dir":"down", "id":1, "origin":[1,0]},   # ↓ pushes red then green (chain?)
        {"dir":"down", "id":1, "origin":[2,0]},   # ↓ pushes green then...
        {"dir":"left", "id":1, "origin":[3,2]},   # ← in row 2 pushes green left
        {"dir":"right", "id":2, "origin":[0,2]},  # → in row 2 pushes red right
    ],
    "D": []
}
# When ↓: both ↓ pushers move AND push cargos down.
# ↓1: pusher1(1,0)→(1,1)red→push→(1,2). pusher2(2,0)→(2,1)green→push→(2,2).
# Both cargos now in row 2! Red at (1,2), green at (2,2).
# Now: ← pushes green left. ←1: pusher_left(3,2)→(2,2)green→push→(1,2)red→push→(0,2)✓?
# Wait: ← pushes green at (2,2) to (1,2) where red is! Red pushed to (0,2)✓ target id=1?
# target (0,2) is id=1. Red is id=2. Wrong target! Red is id=2 at id=1 target. Not its target.
# And green at (1,2). target (0,2) is id=1. Green needs (0,2). Green at (1,2) not there yet.
# ←2: pusher(2,2)→(1,2)green→push→(0,2). Red was pushed to (0,2) on ←1! Now green pushes red→(-1,2)?no cell. Blocked.
# The chain push puts red in green's target! Deadlock.
# Need to → red FIRST, then ↓, then ← green.
# →: pusher_right(0,2)→(1,2)→(2,2)→... wait, cargos haven't been pushed down yet. Row 2 has pusher_right(0,2), pusher_left(3,2). No cargos in row 2 yet.
# →1: pusher_right(0,2)→(1,2). Nothing to push. ←: pusher_left(3,2)→(2,2). Nothing.
# Need ↓ FIRST to bring cargos down. But then ← causes chain push problem.
# What if only ONE cargo goes down first?
# Need 2 separate ↓ pushers that move independently... but both are ↓ and move on same swipe!
# Unless one goes through a longer path.
test(i2, "I2 route cargos")


# ──── J: Asymmetric — one cargo pushed 1 direction, other needs 2 direction changes ────
j1 = {
    "A": [
        [0,0], [1,0], [2,0], [3,0],
        [0,1,1], [1,1], [2,1], [3,1],
        [0,2], [1,2], [2,2], [3,2,2],
        [1,3], [2,3]
    ],
    "B": [
        {"dir":"none", "id":1, "origin":[1,1]},   # cargo green — push left to (0,1)
        {"dir":"none", "id":2, "origin":[2,1]},   # cargo red — push down to (2,2), then right to (3,2)
        {"dir":"left", "id":1, "origin":[3,1]},   # ← in row 1
        {"dir":"down", "id":1, "origin":[2,0]},   # ↓ pushes red down
        {"dir":"right", "id":2, "origin":[0,2]},  # → pushes red right in row 2
    ],
    "D": []
}
# ←: pusher(3,1)→(2,1)red→push red→(1,1)green→push green→(0,1)✓. Red pushed wrong way!
# Need to ↓ red first to get it out of row 1.
# ↓: pusher_down(2,0)→(2,1)red→push→(2,2). Red at (2,2).
# Then ←: pusher_left(3,1)→(2,1)→(1,1)green→push→(0,1)✓. 2←.
# Then →: pusher_right(0,2)→(1,2)→(2,2)red→push→(3,2)✓. 2→.
# Total: ↓ ←← →→ = 5 moves.
# Trap: ← before ↓ — pushes red left through green, messing up both!
test(j1, "J1 asymmetric route")
