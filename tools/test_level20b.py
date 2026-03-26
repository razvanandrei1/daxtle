#!/usr/bin/env python3
"""Level 20 round 2 — fix target counts for cargo puzzles."""

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


# Key insight: each alive block needs its own target cell.
# cargo(id=1) + pusher(id=1) = 2 id=1 blocks → need 2 id=1 targets.
# Same for id=2.


# ── A: Asymmetric — red cargo must be routed ↓ then → ──
#   (0,0) (1,0) (2,0) (3,0)
#   (0,1) (1,1) (2,1) (3,1)
#   (0,2) (1,2) (2,2) (3,2)
#   (1,3) (2,3)
# 14 cells.

a1 = {
    "A": [
        [0,0], [1,0], [2,0], [3,0],
        [0,1,1], [1,1,1], [2,1], [3,1],
        [0,2], [1,2], [2,2,2], [3,2,2],
        [1,3], [2,3]
    ],
    "B": [
        {"dir":"none", "id":1, "origin":[2,1]},   # cargo green — push ← to row 1 targets
        {"dir":"none", "id":2, "origin":[2,1]},   # SAME CELL! Fix.
    ],
    "D": []
}
# Oops. Let me be more careful.

a2 = {
    "A": [
        [0,0], [1,0], [2,0], [3,0],
        [0,1,1], [1,1], [2,1], [3,1,1],
        [0,2,2], [1,2], [2,2], [3,2,2],
        [1,3], [2,3]
    ],
    "B": [
        {"dir":"none", "id":1, "origin":[1,1]},   # cargo green at (1,1) — push ← to (0,1)
        {"dir":"none", "id":2, "origin":[2,1]},   # cargo red at (2,1) — push ↓ then → to (3,2)
        {"dir":"left", "id":1, "origin":[3,1]},   # pusher ← → ends at (1,1) then pushes to (0,1)
        {"dir":"down", "id":2, "origin":[2,0]},   # ↓ pushes red down to (2,2)
        {"dir":"right", "id":2, "origin":[1,2]},  # → pushes red right to (3,2) after ↓
    ],
    "D": []
}
# id=1: cargo(1,1) + pusher←(3,1) = 2 blocks. targets: (0,1),(3,1).
# But pusher starts at (3,1) which is id=1 target! Own target! BAD.
# Fix: target at different position for pusher.
a2["A"] = [
    [0,0], [1,0], [2,0], [3,0],
    [0,1,1], [1,1], [2,1], [3,1],
    [0,2,2], [1,2], [2,2], [3,2,2],
    [1,3,1], [2,3]
]
# targets id=1: (0,1),(1,3). pusher← at (3,1)→(2,1)→(1,1)cargo→push→(0,1)✓. pusher at (1,1). target (1,3)?
# pusher dir=←. At (1,1). ← again: (1,1)→(0,1) cargo there! push cargo→(-1,1)?no. blocked.
# pusher stuck at (1,1). target (1,3) not reachable going ←. BAD.
# Need target for pusher in its ← path.
# pusher ends at (1,1) after pushing cargo to (0,1). target id=1 at (1,1)?
a2["A"] = [
    [0,0], [1,0], [2,0], [3,0],
    [0,1,1], [1,1,1], [2,1], [3,1],
    [0,2,2], [1,2], [2,2], [3,2,2],
    [1,3], [2,3]
]
# targets id=1: (0,1),(1,1). cargo goes to (0,1)✓, pusher ends at (1,1)✓.
# id=2: cargo(2,1) + ↓pusher(2,0) + →pusher(1,2) = 3 blocks. targets: (0,2),(3,2). Only 2! Need 3.
# Fix: add id=2 target or reduce id=2 blocks.
# What if ↓pusher is id=1? Then id=1 has 3 blocks, 2 targets. Need 3 targets or D block.
# Add D block to sacrifice one.
# Or make the → pusher also serve as the final position.
# →pusher at (1,2): after pushing red: →1: (1,2)→(2,2)red→push→(3,2)✓. pusher at (2,2). target at (2,2)?
a2["A"] = [
    [0,0], [1,0], [2,0], [3,0],
    [0,1,1], [1,1,1], [2,1], [3,1],
    [0,2], [1,2], [2,2,2], [3,2,2],
    [1,3], [2,3]
]
# id=2 targets: (2,2),(3,2). cargo→(3,2)✓, →pusher→(2,2)✓.
# id=2 blocks: cargo(2,1), ↓pusher(2,0), →pusher(1,2) = 3. targets = 2. Still short!
# Make ↓pusher id=1.
a2["B"][3] = {"dir":"down", "id":1, "origin":[2,0]}
# Now id=1: cargo(1,1), pusher←(3,1), ↓pusher(2,0) = 3. targets: (0,1),(1,1). Only 2. Need 3!
# Add target or D.
# ↓pusher goes down to (2,1)→(2,2)→(2,3). Where does it end?
# ↓1: pushes cargo_red from (2,1) to (2,2). pusher at (2,1).
# Then ↓2: pusher(2,1)→(2,2). Red already pushed. (2,2) has red? Yes, red was pushed there.
# Push red→(2,3). pusher at (2,2). Red at (2,3). target id=2 at (2,3)?
# Add target at (2,3) for id=1 (where ↓pusher might end up) or for ↓pusher path.
# ↓pusher at (2,1) after ↓1. ↓2: (2,1)→(2,2) red there, push→(2,3). pusher at (2,2).
# Wait, after → moves red to (3,2), (2,2) is empty.
# Order: ↓ first, then →. After ↓: red at (2,2), pusher_down at (2,1).
# →: right_pusher(1,2)→(2,2)red→push→(3,2)✓. Right_pusher at (2,2)✓.
# Then ↓: pusher_down(2,1)→(2,2) right_pusher at (2,2)! Push→(2,3)?
# Hmm complex. Let me just add a D block or reduce block count.

# SIMPLEST APPROACH: 4 blocks (2 cargos + 2 pushers), each color has 1 cargo + 1 pusher = 2 targets each.
# Pushers end up at their target after pushing cargo.

simple = {
    "A": [
        [0,0], [1,0], [2,0], [3,0],
        [0,1,1], [1,1,1], [2,1], [3,1],
        [0,2], [1,2], [2,2,2], [3,2,2],
        [1,3], [2,3]
    ],
    "B": [
        {"dir":"none", "id":1, "origin":[2,1]},   # cargo green — push ← to (0,1)
        {"dir":"none", "id":2, "origin":[1,2]},   # cargo red — push → to (3,2)
        {"dir":"left", "id":1, "origin":[3,1]},   # pusher ← ends at (1,1)✓
        {"dir":"right", "id":2, "origin":[0,2]},  # pusher → ends at (2,2)✓
    ],
    "D": []
}
# ←←: pusher(3,1)→(2,1)green→push→(1,1). ←: pusher(2,1)→(1,1)green→push→(0,1)✓. pusher at (1,1)✓.
# →→: pusher(0,2)→(1,2)red→push→(2,2). →: pusher(1,2)→(2,2)red→push→(3,2)✓. pusher at (2,2)✓.
# Independent! 4 moves. But let me test it works at all.
test(simple, "SIMPLE independent")


# Now add interaction: ↓ pusher that disrupts if used wrong.
interact1 = {
    "A": [
        [0,0], [1,0], [2,0], [3,0],
        [0,1,1], [1,1,1], [2,1], [3,1],
        [0,2], [1,2], [2,2,2], [3,2,2],
        [1,3], [2,3]
    ],
    "B": [
        {"dir":"none", "id":1, "origin":[2,1]},   # cargo green
        {"dir":"none", "id":2, "origin":[1,2]},   # cargo red
        {"dir":"left", "id":1, "origin":[3,1]},   # pusher ←
        {"dir":"right", "id":2, "origin":[0,2]},  # pusher →
        {"dir":"down", "id":1, "origin":[1,0]},   # ↓ in col 1 — interacts!
    ],
    "D": []
}
# ↓ pusher at (1,0). Goes ↓ to (1,1). But after ← pushes cargo green:
# After ←1: cargo green at (1,1). ↓: pusher(1,0)→(1,1) green there! Push green→(1,2) red at (1,2)!
# Push red→(1,3). Chain push! Both cargos end up in col 1 stacked.
# ↓ is a TRAP. But ↓ pusher needs a target. 3 id=1 blocks, 2 targets. Need 3 or D block.
# Add D block.
interact1["D"] = [{"origin":[2,2]}]
# ↓ pusher goes to D? (1,0)→(1,1)→(1,2)→(1,3). Doesn't reach (2,2).
# What if ↓ pusher is the sacrifice? It lands on D at some point.
# D at (1,3): ↓ pusher goes (1,0)→(1,1)→(1,2)→(1,3)=D→dies.
interact1["D"] = [{"origin":[1,3]}]
# pusher_down(1,0) goes ↓ and eventually hits D(1,3) after 3↓.
# But ↓ also pushes things along the way!
# Before ←: ↓1 pusher(1,0)→(1,1). No cargo there initially. green at (2,1), not (1,1). Fine.
# If ← first: green pushed to (1,1). Then ↓ pushes green further. Bad.
# If → first: red pushed from (1,2) to right. Then ↓ safe in col 1.
# Ordering constraint!
test(interact1, "INTERACT1 +↓+D")


# ──── Cargo route with ↓ separation ────
route1 = {
    "A": [
        [0,0], [1,0], [2,0], [3,0],
        [0,1,1], [1,1,1], [2,1], [3,1],
        [0,2], [1,2], [2,2,2], [3,2,2],
        [1,3], [2,3]
    ],
    "B": [
        {"dir":"none", "id":1, "origin":[1,1]},   # cargo green at (1,1) — needs (0,1)
        {"dir":"none", "id":2, "origin":[2,1]},   # cargo red at (2,1) — needs ↓ then → to (3,2)
        {"dir":"left", "id":1, "origin":[3,1]},   # ← pushes green left, BUT red is between!
        {"dir":"down", "id":1, "origin":[2,0]},   # ↓ pushes red down first to separate
        {"dir":"right", "id":2, "origin":[0,2]},  # → pushes red right in row 2
    ],
    "D": []
}
# 3 id=1 blocks, 2 targets. Need D or 3rd target.
# ↓pusher goes (2,0)→(2,1)red→push→(2,2). pusher at (2,1). Then ↓: (2,1)→(2,2)→(2,3). Target at (2,3)?
route1["A"][-1] = [2,3,1]  # target id=1 at (2,3)
# 3 id=1 targets: (0,1),(1,1),(2,3). ✓
# id=2: cargo_red + →pusher = 2. targets: (2,2),(3,2). →pusher at (2,2)✓, red at (3,2)✓.
# ← before ↓: pusher←(3,1)→(2,1)red→push red→(1,1)green→push green→(0,1)✓. Chain push!
# But red pushed LEFT, not down! Red ends at (1,1)✓ id=1 target. But red is id=2. Wrong target.
# Red must NOT go left. Must ↓ first to separate.
# Ordering: ↓ before ←. Then ← only pushes green.
test(route1, "ROUTE1 ↓ then ←")


# Same but more interaction — pusher paths cross
route2 = {
    "A": [
        [0,0], [1,0], [2,0], [3,0],
        [0,1,1], [1,1], [2,1], [3,1],
        [0,2], [1,2,2], [2,2,2], [3,2],
        [1,3,1], [2,3,1]
    ],
    "B": [
        {"dir":"none", "id":1, "origin":[1,1]},   # cargo green — ← to (0,1)
        {"dir":"none", "id":2, "origin":[2,1]},   # cargo red — ↓ to (2,2) then stays
        {"dir":"left", "id":1, "origin":[3,1]},   # ← pushes green (and red if not separated!)
        {"dir":"down", "id":1, "origin":[2,0]},   # ↓ pushes red down
        {"dir":"right", "id":2, "origin":[0,2]},  # → pushes ? in row 2
    ],
    "D": []
}
# 3 id=1, targets: (0,1),(1,3),(2,3). pusher←→(0,1)? No, pusher pushes cargo to (0,1).
# ←1: pusher(3,1)→(2,1) red at (2,1) if not separated. Push red→(1,1)green→push green→(0,1)✓.
# Red at (1,1). Green at (0,1)✓. But red wrong place.
# ↓ first: pusher_down(2,0)→(2,1)red→push→(2,2)✓. Then ← safe.
# ←1: pusher(3,1)→(2,1)→(1,1)green→push→(0,1)✓. pusher at (1,1)✓? target (1,3).
# pusher at (1,1). target (1,3). Can't reach going ←.
# Fix target: (1,1) for id=1.
route2["A"] = [
    [0,0], [1,0], [2,0], [3,0],
    [0,1,1], [1,1,1], [2,1], [3,1],
    [0,2], [1,2,2], [2,2,2], [3,2],
    [1,3], [2,3]
]
# ↓pusher at (2,0): goes to (2,1)→pushes red→(2,2)✓. pusher at (2,1). ↓ again: (2,1)→(2,2) red there. push→(2,3). pusher at (2,2).
# ↓pusher ends at (2,2) or (2,1). target for ↓pusher? (2,3)? Add.
route2["A"][-1] = [2,3,1]  # target id=1 at (2,3)
# 3 id=1: (0,1),(1,1),(2,3). ↓pusher needs to reach (2,3). ↓↓↓ from (2,0)→(2,1)→(2,2)→(2,3)✓.
# But ↓ also pushes cargo red: ↓1 pushes red to (2,2). ↓2: pusher(2,1)→(2,2) red→push→(2,3)✓ id=1? No (2,3) is id=1 target, red is id=2. Red at wrong target.
# ↓3: pusher(2,2)→(2,3) red at (2,3)→push→(2,4)?no. Blocked.
# Problem: ↓ keeps pushing red deeper.
# Fix: → pushes red right BEFORE ↓ pusher catches up.
# ↓1: red→(2,2). →1: right_pusher(0,2)→(1,2). →2: (1,2)→(2,2)red→push→(3,2). Red gone from col 2.
# Then ↓2: pusher(2,1)→(2,2). ↓3: (2,2)→(2,3)✓.
# Total: ↓ → → ← ← ↓ ↓ = 7 moves? Let me test.
test(route2, "ROUTE2")


# ── Compact cross with cargos ──
cross1 = {
    "A": [
        [1,0], [2,0],
        [0,1,1], [1,1,1], [2,1], [3,1],
        [0,2], [1,2], [2,2,2], [3,2,2],
        [1,3], [2,3]
    ],
    "B": [
        {"dir":"none", "id":1, "origin":[2,1]},   # cargo green — ← to (0,1) or (1,1)
        {"dir":"none", "id":2, "origin":[1,2]},   # cargo red — → to (2,2) or (3,2)
        {"dir":"left", "id":1, "origin":[3,1]},   # ← pushes green. ends at (1,1)✓.
        {"dir":"right", "id":2, "origin":[0,2]},  # → pushes red. ends at (2,2)✓.
        {"dir":"down", "id":1, "origin":[1,0]},   # ↓ — interacts with cargo green if timed wrong
    ],
    "D": [{"origin":[1,3]}]
}
# ↓ pusher needs to die on D(1,3). 3 id=1 - 1 sac = 2 targets (0,1),(1,1). ✓
# ↓ goes: (1,0)→(1,1)→(1,2)→(1,3)=D→dies.
# But (1,1) may have green cargo pushed there by ←.
# If ← before ↓: green at (1,1). ↓: pusher(1,0)→(1,1)green→push→(1,2)red→push→(1,3)=D→red dies!!
# TRAP: ← then ↓ kills cargo red on D!
# Correct: ↓ first (pusher goes to (1,1), green not there yet). Then ←.
# But ↓1: (1,0)→(1,1). green at (2,1) not (1,1). Safe. ↓2: (1,1)→(1,2) red at (1,2)! Push red→(1,3)=D→red dies!
# NO! ↓ pushes red into D too!
# ↓ must not reach row 2 while red is there.
# → first moves red: →1: pusher→(1,2)red→push→(2,2)✓. Then ↓ safe in col 1.
# Then ↓↓↓ to D(1,3). Then ←← to push green.
# Ordering: → before ↓ (to save red), ← after ↓ passes through (to not block ↓ pusher).
test(cross1, "CROSS1")


# ── Same idea but cleaner ──
cross2 = {
    "A": [
        [1,0], [2,0],
        [0,1,1], [1,1,1], [2,1], [3,1],
        [0,2], [1,2], [2,2,2], [3,2,2],
        [1,3], [2,3]
    ],
    "B": [
        {"dir":"none", "id":1, "origin":[2,1]},
        {"dir":"none", "id":2, "origin":[1,2]},
        {"dir":"left", "id":1, "origin":[3,1]},
        {"dir":"right", "id":2, "origin":[0,2]},
        {"dir":"down", "id":2, "origin":[2,0]},   # ↓ id=2 — sac on D
    ],
    "D": [{"origin":[2,3]}]
}
# 2 id=1, 2 targets ✓. 3 id=2 - 1 sac = 2 targets ✓.
# ↓: pusher_down(2,0)→(2,1)green→push→(2,2)?? Wait, green is cargo at (2,1).
# ↓ pushes green down! Not intended!
# ↓ is in col 2, green cargo is in col 2. ↓ pushes green!
# Fix: ↓ in col 1.
cross2["B"][4] = {"dir":"down", "id":2, "origin":[1,0]}
# ↓: (1,0)→(1,1)→(1,2)red→push→(1,3)→... if red at (1,2): push red to (1,3)→D? D at (2,3) not (1,3).
# ↓ pusher in col 1: (1,0)→(1,1)→(1,2)→(1,3). Red at (1,2) gets pushed to (1,3). D at (2,3). Red not on D. Pusher continues... no cell after (1,3)? Board has (1,3). ↓: (1,3)→(1,4)?no cell. Stuck.
# ↓ pusher ends at (1,3). Target for id=2? D at (2,3). Need pusher to reach D.
# This doesn't work well.

# Let me try with D at (1,3). ↓ sac goes there.
cross3 = {
    "A": [
        [1,0], [2,0],
        [0,1,1], [1,1,1], [2,1], [3,1],
        [0,2], [1,2], [2,2,2], [3,2,2],
        [1,3], [2,3]
    ],
    "B": [
        {"dir":"none", "id":1, "origin":[2,1]},
        {"dir":"none", "id":2, "origin":[1,2]},
        {"dir":"left", "id":1, "origin":[3,1]},
        {"dir":"right", "id":2, "origin":[0,2]},
        {"dir":"down", "id":2, "origin":[2,0]},
    ],
    "D": [{"origin":[2,3]}]
}
# ↓ sac(2,0)→(2,1)green→push→(2,2)?? Still pushes green! SAME ISSUE.
# ↓ and green in same col.
# Fix: green NOT in col 2. Green at (1,1).
cross3["B"][0] = {"dir":"none", "id":1, "origin":[1,1]}
# green at (1,1). ↓ at (2,0)→(2,1)→(2,2)→(2,3)=D→dies. Doesn't touch green. ✓
# ← pushes green: pusher(3,1)→(2,1)→(1,1)green→push→(0,1)✓. But wait, (2,1) empty? pusher moves 1 step.
# ←1: pusher(3,1)→(2,1).
# ←2: pusher(2,1)→(1,1)green→push→(0,1)✓. pusher at (1,1)✓.
# → pushes red: →1: pusher(0,2)→(1,2)red→push→(2,2)✓. →2: pusher(1,2)→(2,2)red→push→(3,2)✓. pusher at (2,2)✓.
# ↓: sac(2,0) needs to go ↓↓↓ to (2,3)=D. When ↓, only sac moves (no other ↓ blocks).
# But ↓ pushes through (2,1), (2,2). After → pushed red to (3,2), (2,2) is... →pusher at (2,2).
# ↓: sac(2,0)→(2,1)→(2,2) →pusher at (2,2)? If → already happened.
# Timing issue: if → before ↓, sac pushes →pusher. If ↓ before →, path is clear.
# ↓↓↓: sac(2,0)→(2,1)→(2,2)→(2,3)=D→dies. All clear if → hasn't happened yet.
# Then →→: safe.
# Ordering: ↓ before →. And ← anytime (independent col).
# TRAP: → before ↓ blocks sac's path!
test(cross3, "CROSS3 clean")
