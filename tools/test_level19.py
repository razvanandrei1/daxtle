#!/usr/bin/env python3
"""Level 19 — Split board connected only by teleport(s). Visual impact."""

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
# Concept: Board split into LEFT and RIGHT halves with a gap.
# No cells connect them — teleport is the ONLY bridge.
# Blocks must cross between halves to reach targets.
#
# Visual: two islands separated by empty column(s).
# Difficulty target: 6-7
# ══════════════════════════════════════════════════════════════


# ──── Layout A: Two 2×3 islands separated by 1-col gap ────
#
#   Col: 0  1  ·  3  4
#   R0: (0,0)(1,0)  (3,0)(4,0)
#   R1: (0,1)(1,1)  (3,1)(4,1)
#   R2: (0,2)(1,2)  (3,2)(4,2)
#
# 12 cells. Portal bridges the gap.

a1 = {
    "A": [
        [0,0], [1,0], [3,0], [4,0],
        [0,1], [1,1], [3,1], [4,1],
        [0,2,1], [1,2], [3,2], [4,2,2]
    ],
    "B": [
        {"dir":"right", "id":1, "origin":[0,0]},
        {"dir":"down", "id":1, "origin":[3,0]},
        {"dir":"left", "id":2, "origin":[4,0]},
    ],
    "T": [{"id":1, "one_way":False, "pos":[1,1, 3,1]}],
    "D": []
}
# B0(→) at (0,0): →(1,0). →(2,0)?no cell. But (1,1) is portal...
# Portal only activates when dest IS the portal cell. B0 goes right, not down to portal.
# B0 stuck at (1,0). Can't cross!
# Need B0 to enter portal. B0 must reach (1,1) or (3,1).
# B0(↓) instead? (0,0)→(0,1)→(0,2)✓ target. Doesn't cross.
# Who crosses? Someone whose movement direction leads to a portal cell.
# Portal at (1,1)↔(3,1). A block moving right from (0,1) to (1,1) enters portal → exits (3,1) → cont right (4,1).
# A block moving left from (4,1) to (3,1) enters portal → exits (1,1) → cont left (0,1).
a1["B"] = [
    {"dir":"right", "id":1, "origin":[0,1]},  # → enters portal at (1,1) → exits (3,1) → cont (4,1)
    {"dir":"left", "id":2, "origin":[4,1]},   # ← enters portal at (3,1) → exits (1,1) → cont (0,1)
    {"dir":"down", "id":1, "origin":[0,0]},   # ↓ stays on left
    {"dir":"down", "id":2, "origin":[4,0]},   # ↓ stays on right
]
a1["A"] = [
    [0,0], [1,0], [3,0], [4,0],
    [0,1], [1,1], [3,1], [4,1],
    [0,2,2], [1,2,1], [3,2,1], [4,2,2]
]
# B0(→) at (0,1): → to (1,1)=portal → exits (3,1) → cont (4,1). Lands at (4,1).
# Then → again: (4,1)→(5,1)?no. Stuck at (4,1). Target at (3,2) or (1,2)?
# targets id=1: (1,2),(3,2). B0 at (4,1). Can't reach targets going →.
# B0 needs a different path after teleporting.
# Hmm. After teleporting, B0 is on the right side but can only go →.
# Need blocks that cross AND can reach targets on the other side.

# Key insight: the crossing block must have a direction that:
# 1. Enters the portal (direction leads to portal cell)
# 2. After exiting, can eventually reach a target on the other side

# If portal is (1,2)↔(3,0):
# Block going DOWN from (1,1) to (1,2)=portal → exits (3,0) → cont down (3,1). Lands on right side, column 3.
# Then continues ↓: (3,1)→(3,2). Can reach targets in col 3 going down.

# Block going UP from (3,1) to (3,0)=portal → exits (1,2) → cont up (1,1). Lands on left side, column 1.
# Then continues ↑: (1,1)→(1,0). Can reach targets in col 1 going up.

a2 = {
    "A": [
        [0,0], [1,0], [3,0], [4,0],
        [0,1], [1,1], [3,1], [4,1],
        [0,2], [1,2], [3,2], [4,2]
    ],
    "T": [{"id":1, "one_way":False, "pos":[1,2, 3,0]}],
    "B": [
        {"dir":"down", "id":1, "origin":[1,0]},  # ↓ col 1: (1,0)→(1,1)→(1,2)=portal→(3,0)→cont(3,1). Crosses!
        {"dir":"up", "id":2, "origin":[3,2]},    # ↑ col 3: (3,2)→(3,1)→(3,0)=portal→(1,2)→cont(1,1). Crosses!
        {"dir":"down", "id":1, "origin":[0,0]},  # stays left
        {"dir":"up", "id":2, "origin":[4,2]},    # stays right
    ],
    "D": []
}
# After crossing: B0 on right, B1 on left. B2 stays left, B3 stays right.
# Targets: B0(id=1) needs target on right. B1(id=2) needs target on left.
a2["A"] = [
    [0,0], [1,0,2], [3,0], [4,0,1],
    [0,1], [1,1], [3,1], [4,1],
    [0,2,1], [1,2], [3,2], [4,2,2]
]
# targets id=1: (4,0),(0,2). id=2: (1,0),(4,2).
# B0(↓,id=1) at (1,0): crosses to right, needs (4,0)? B0 at (3,1) after portal. ↓: (3,1)→(3,2). Target (4,0) not reachable ↓.
# This is tricky. After B0 crosses to (3,1), it goes ↓ to (3,2). Not a target.
# Fix: target id=1 at (3,2). B0 goes (3,1)→(3,2)✓.
a2["A"] = [
    [0,0], [1,0,2], [3,0], [4,0],
    [0,1], [1,1], [3,1], [4,1],
    [0,2,1], [1,2], [3,2,1], [4,2,2]
]
# B0(↓) crosses to (3,1), then ↓ to (3,2)✓.
# B1(↑) crosses to (1,1), then ↑ to (1,0)✓ target id=2.
# B2(↓,id=1) at (0,0): ↓ to (0,1)→(0,2)✓ target id=1.
# B3(↑,id=2) at (4,2): ↑ to (4,1)→(4,0). target (4,2) is id=2. B3 starts there! BAD.
a2["A"][-1] = [4,2]
# Remove target from (4,2). target id=2 only at (1,0).
# B3(↑) at (4,2) goes to (4,0). No target there. B3 has no target!
# 2 id=2 blocks: B1, B3. 1 id=2 target at (1,0). Need 2 id=2 targets or a D block.
# Add target id=2 at (4,0).
a2["A"] = [
    [0,0], [1,0,2], [3,0], [4,0,2],
    [0,1], [1,1], [3,1], [4,1],
    [0,2,1], [1,2], [3,2,1], [4,2]
]
# B3(↑) at (4,2) → (4,1)→(4,0)✓ id=2.
# B1(↑) at (3,2) crosses to (1,1), then (1,0)✓ id=2.
# But B0(↓) and B1(↑) interfere: B0 enters portal from top, B1 from bottom.
# When ↓: B0(1,0)→(1,1)→(1,2)=portal→(3,0)→(3,1). B2(0,0)→(0,1).
# When ↑: B1(3,2)→(3,1)→(3,0)=portal→(1,2)→(1,1). B3(4,2)→(4,1).
# Order matters! If ↓ first, B0 goes to (3,1). Then ↑: B1(3,2)→(3,1) B0 there! Push B0→(3,0)=portal!
# B0 re-enters portal? Going UP B0 is pushed to (3,0) which is portal exit → teleports to (1,2)→cont up (1,1).
# This could get complex. Let me just test.
test(a2, "A2 cross-swap")


# ──── Layout B: Two 3×2 islands side by side ────
#
#   Col: 0  1  2  ·  4  5  6
#   R0: (0,0)(1,0)(2,0)  (4,0)(5,0)(6,0)
#   R1: (0,1)(1,1)(2,1)  (4,1)(5,1)(6,1)
#
# 12 cells. Wide split.

b1 = {
    "A": [
        [0,0], [1,0], [2,0], [4,0], [5,0], [6,0],
        [0,1,1], [1,1], [2,1], [4,1], [5,1,2], [6,1]
    ],
    "T": [{"id":1, "one_way":False, "pos":[2,0, 4,0]}],
    "B": [
        {"dir":"right", "id":1, "origin":[0,0]},  # → crosses portal at (2,0)?
        # (0,0)→(1,0)→(2,0)=portal→(4,0)→cont right (5,0). Crosses!
        {"dir":"left", "id":2, "origin":[6,0]},   # ← crosses portal at (4,0)?
        # (6,0)→(5,0)→(4,0)=portal→(2,0)→cont left (1,0). Crosses!
        {"dir":"down", "id":1, "origin":[1,0]},   # stays left
        {"dir":"down", "id":2, "origin":[5,0]},   # stays right. starts on target! BAD
    ],
    "D": []
}
# Fix B3 position
b1["B"][3] = {"dir":"down", "id":2, "origin":[6,0]}
b1["B"][1] = {"dir":"left", "id":2, "origin":[6,1]}
# B1(←) at (6,1): →(5,1)→(4,1). Not portal (portal at row 0). stays right side.
# Need portal in right row for B1 to cross.
# Actually portal (2,0)↔(4,0) is only in row 0.
# B1 at (6,1) going left in row 1 can't reach portal in row 0.
# Fix: B1 in row 0.
b1["B"] = [
    {"dir":"right", "id":1, "origin":[0,0]},  # → crosses to right side via portal
    {"dir":"left", "id":2, "origin":[6,0]},   # ← crosses to left side via portal
    {"dir":"down", "id":1, "origin":[0,1]},   # stays left. But (0,1) is target id=1! Starts on own target! Fix.
    {"dir":"down", "id":2, "origin":[4,0]},   # at portal cell, goes ↓ to (4,1). stays right.
]
# Lots of issues. Let me rethink.

# Let me simplify: just 3 blocks that must cross.
b2 = {
    "A": [
        [0,0], [1,0], [2,0], [4,0], [5,0], [6,0],
        [0,1], [1,1], [2,1], [4,1], [5,1], [6,1]
    ],
    "T": [{"id":1, "one_way":False, "pos":[2,1, 4,1]}],
    "B": [
        {"dir":"right", "id":1, "origin":[0,1]},  # → row 1: (0,1)→(1,1)→(2,1)=portal→(4,1)→(5,1). Crosses!
        {"dir":"left", "id":2, "origin":[6,1]},   # ← row 1: (6,1)→(5,1)→(4,1)=portal→(2,1)→(1,1). Crosses!
        {"dir":"down", "id":1, "origin":[5,0]},   # ↓ stays right, reaches (5,1). But B0 might be there.
    ],
    "D": []
}
# After B0 crosses to (5,1), B2(↓) at (5,0) goes to (5,1) — collision with B0!
# Push B0→(5,2)?no cell. B2 blocked.
# Fix timing: B2 goes ↓ before B0 crosses.
# targets: id=1: on right side? id=2: on left side?
b2["A"] = [
    [0,0,2], [1,0], [2,0], [4,0], [5,0], [6,0,1],
    [0,1], [1,1], [2,1], [4,1], [5,1,1], [6,1]
]
# B0(→,id=1) crosses to right. Target (5,1) or (6,0).
# B0 lands at (5,1) after portal+cont. target (5,1) is id=1. ✓. But then B2 at (5,0) can't go ↓.
# B1(←,id=2) crosses to left. Target (0,0) is id=2. B1 lands at (1,1) after portal. Then ← to (0,1). target (0,0) is above.
# B1 goes LEFT not UP. Can't reach (0,0).
# This is getting messy. Let me try a completely different layout.


# ──── Layout C: Two triangles/L-shapes ────
#
#   Left:          Right:
#   (0,0)(1,0)     (4,0)(5,0)
#   (0,1)(1,1)     (4,1)(5,1)
#   (0,2)          (4,2)(5,2)
#
# 10 cells. Asymmetric islands.
# Portal: (1,1)↔(4,1) in the middle row

c1 = {
    "A": [
        [0,0], [1,0], [4,0], [5,0],
        [0,1], [1,1], [4,1], [5,1],
        [0,2], [4,2,1], [5,2,2]
    ],
    "T": [{"id":1, "one_way":False, "pos":[0,2, 5,2]}],
    "B": [
        {"dir":"down", "id":1, "origin":[0,0]},  # ↓ col 0: (0,0)→(0,1)→(0,2)=portal→(5,2)→cont↓? no. Lands (5,2). target id=2 there. Wrong id.
        {"dir":"down", "id":1, "origin":[1,0]},  # ↓ col 1
        {"dir":"up", "id":2, "origin":[5,2]},    # ↑ col 5: starts on id=2 target! BAD.
        {"dir":"up", "id":1, "origin":[4,2]},    # ↑ col 4
    ],
    "D": []
}
# Many issues. Let me try a cleaner approach.


# ──── Layout D: Two vertical strips with 2-col gap ────
#
#   Col: 0  1  ·  ·  4  5
#   R0: (0,0)(1,0)      (4,0)(5,0)
#   R1: (0,1)(1,1)      (4,1)(5,1)
#   R2: (0,2)(1,2)      (4,2)(5,2)
#   R3: (0,3)                (5,3)
#
# 14 cells. Two tall strips with stagger at bottom.
# Portal at bottom: (0,3)↔(5,3)

d1 = {
    "A": [
        [0,0], [1,0,2], [4,0,1], [5,0],
        [0,1], [1,1], [4,1], [5,1],
        [0,2], [1,2], [4,2], [5,2],
        [0,3], [5,3]
    ],
    "T": [{"id":1, "one_way":False, "pos":[0,3, 5,3]}],
    "B": [
        {"dir":"down", "id":1, "origin":[0,0]},  # ↓ col 0 to (0,3)=portal→(5,3)→cont↓ no cell. Lands (5,3). Then... stuck.
        {"dir":"down", "id":1, "origin":[4,0]},  # starts on own target! BAD
        {"dir":"up", "id":2, "origin":[5,3]},    # ↑ (5,3)=portal? No, portal activates on DEST.
        # ↑ from (5,3): dest (5,2). Not portal. B2 goes to (5,2).
    ],
    "D": []
}
# Not working well. Portal at row 3 edges is awkward.

# ──── Layout E: Two 3×3 blocks, 1-col gap, portal mid-height ────
#
#   Col: 0  1  2  ·  4  5  6
#   R0: (0,0)(1,0)(2,0)  (4,0)(5,0)(6,0)
#   R1: (0,1)(1,1)(2,1)  (4,1)(5,1)(6,1)
#   R2: (0,2)(1,2)(2,2)  (4,2)(5,2)(6,2)
#
# 18 cells. Portal: (2,1)↔(4,1) — middle row connection.
# Blocks cross via → and ← through the portal.

e1 = {
    "A": [
        [0,0], [1,0], [2,0], [4,0], [5,0], [6,0],
        [0,1], [1,1], [2,1], [4,1], [5,1], [6,1],
        [0,2], [1,2], [2,2], [4,2], [5,2], [6,2]
    ],
    "T": [{"id":1, "one_way":False, "pos":[2,1, 4,1]}],
    "B": [
        {"dir":"right", "id":1, "origin":[0,1]},  # → row 1 to portal, crosses to right
        {"dir":"left", "id":2, "origin":[6,1]},   # ← row 1 to portal, crosses to left
        {"dir":"down", "id":1, "origin":[5,0]},   # stays right
        {"dir":"down", "id":2, "origin":[1,0]},   # stays left
    ],
    "D": []
}
# B0(→) at (0,1): →→ to (2,1)=portal→(4,1)→cont(5,1). Crosses! At (5,1).
# B1(←) at (6,1): ←← to (4,1)=portal→(2,1)→cont(1,1). Crosses! At (1,1).
# But if both try to cross simultaneously (→ and ← are different swipe dirs), they don't interfere.
# B0 and B1 swap sides! Cool visual.
# B2(↓,id=1) at (5,0): ↓↓ to (5,2). Target?
# B3(↓,id=2) at (1,0): ↓↓ to (1,2). Target?
# After B0 crosses to (5,1): B0 is id=1 on right side. Target for B0 on right?
# After B1 crosses to (1,1): B1 is id=2 on left side. Target for B1 on left?
e1["A"] = [
    [0,0], [1,0], [2,0], [4,0], [5,0], [6,0],
    [0,1,2], [1,1], [2,1], [4,1], [5,1], [6,1,1],
    [0,2], [1,2,2], [2,2], [4,2], [5,2,1], [6,2]
]
# targets id=1: (6,1),(5,2). id=2: (0,1),(1,2).
# B0(→,id=1) crosses to (5,1). →: (5,1)→(6,1)✓. Total: →→→ (3 moves).
# B1(←,id=2) crosses to (1,1). ←: (1,1)→(0,1)✓. Total: ←←← (3 moves).
# B2(↓,id=1) at (5,0): ↓↓ to (5,2)✓.
# B3(↓,id=2) at (1,0): ↓↓ to (1,2)✓.
# But when ↓: B2 AND B3 both move (both ↓). ↓1: B2→(5,1), B3→(1,1).
# If B0 at (5,1) or B1 at (1,1): collision!
# B0 needs to leave (5,1) before B2 arrives. B0→(6,1) before ↓.
# B1 needs to leave (1,1) before B3 arrives. B1→(0,1) before ↓.
# So: →→→ and ←←← before ↓↓. Nice ordering constraint!
# But if ↓ first: B2(5,0)→(5,1), B3(1,0)→(1,1). These cells are empty (B0 at (0,1), B1 at (6,1)).
# ↓ first is actually safe! No collision.
# Then →: B0(0,1)→(1,1) B3 at (1,1)! Push B3→(2,1)=portal→(4,1)→(5,1) B2 there!
# This gets complex. Let me just test it.
test(e1, "E1 3x3 split")


# E2: Add interaction — D block on one side, push needed across portal
e2 = {
    "A": [
        [0,0], [1,0], [2,0], [4,0], [5,0], [6,0],
        [0,1], [1,1], [2,1], [4,1], [5,1,1], [6,1],
        [0,2,2], [1,2], [2,2], [4,2], [5,2], [6,2,1]
    ],
    "T": [{"id":1, "one_way":False, "pos":[2,1, 4,1]}],
    "B": [
        {"dir":"right", "id":1, "origin":[0,1]},  # crosses to right
        {"dir":"left", "id":2, "origin":[6,1]},   # crosses to left
        {"dir":"down", "id":1, "origin":[4,0]},   # stays right
        {"dir":"down", "id":2, "origin":[2,0]},   # stays left
    ],
    "D": [{"origin":[5,2]}]
}
# D at (5,2). B2(↓,id=1) at (4,0): ↓↓ to (4,2). Doesn't hit D.
# Who hits D? B0(→) after crossing to right side: at (5,1). ↓ not B0's dir.
# Nobody naturally hits D at (5,2). Need a sac.
# What if B2 goes through D? B2(↓) at (4,0)→(4,1)→(4,2). No D in col 4.
# Add sac block.
e2["B"].append({"dir":"down", "id":1, "origin":[5,0]})
# sac(↓) at (5,0)→(5,1)→(5,2)=D. But B0 might be at (5,1) after crossing.
# If → before ↓: B0 at (5,1). Then ↓: sac(5,0)→(5,1) B0 there! Push B0→(5,2)=D→B0 dies!
# Trap! → before ↓ kills B0.
# Correct: ↓ first (sac goes to (5,2)=D, dies), then →.
# But when ↓: B2(4,0)→(4,1), B3(2,0)→(2,1)=portal→(4,1)→cont↓?
# Wait, B3 going ↓ to (2,1)=portal. Portal! B3 teleports to (4,1). Cont ↓ (4,2).
# But B2 at (4,1) from same ↓ move! Collision.
# This is very complex. Let me test.
test(e2, "E2 split+D")


# E3: Simpler — no D, just crossing puzzle
e3 = {
    "A": [
        [0,0], [1,0], [2,0], [4,0], [5,0], [6,0],
        [0,1], [1,1], [2,1], [4,1], [5,1], [6,1],
        [0,2,2], [1,2], [2,2], [4,2], [5,2,1], [6,2]
    ],
    "T": [{"id":1, "one_way":False, "pos":[2,1, 4,1]}],
    "B": [
        {"dir":"right", "id":1, "origin":[0,1]},  # → crosses to right, needs (5,2)
        {"dir":"left", "id":2, "origin":[6,1]},   # ← crosses to left, needs (0,2)
        {"dir":"down", "id":1, "origin":[5,0]},   # ↓ right side
        {"dir":"down", "id":2, "origin":[1,0]},   # ↓ left side
    ],
    "D": []
}
# B0(→) at (0,1): →→ to (2,1)=portal→(4,1)→(5,1). Then needs to reach (5,2). Can't go ↓ (dir=→).
# → from (5,1): (6,1). Not target. → from (6,1): no cell. Stuck.
# B0 can't reach (5,2). Fix.
# Target at (6,1): B0 →→→ to (6,1)? (0,1)→(1,1)→(2,1)=portal→(5,1)→(6,1)?
# Portal cont: (4,1)→(5,1). Then →: (5,1)→(6,1)✓.
# So: → → → → = 4 moves? No: →1: (0,1)→(1,1). →2: (1,1)→(2,1)=portal→(5,1). →3: (5,1)→(6,1)✓.
# 3 → moves for B0 to reach (6,1).
e3["A"] = [
    [0,0], [1,0], [2,0], [4,0], [5,0], [6,0],
    [0,1], [1,1], [2,1], [4,1], [5,1], [6,1,1],
    [0,2,2], [1,2], [2,2], [4,2], [5,2], [6,2]
]
# B0 → → → to (6,1)✓
# B1(←) at (6,1): starts on target id=1! BAD. B1 is id=2.
# (6,1) is target id=1. B1 is id=2 at (6,1). Wrong-color target. OK!
# B1 ← ← ← : (6,1)→(5,1)→(4,1)=portal→(2,1)→cont(1,1). Then ←: (1,1)→(0,1). ←: (0,1)→? no cell left. Stuck at (0,1).
# Target (0,2) is id=2. B1 goes LEFT, can't go DOWN to (0,2).
# Fix: target id=2 at (0,1).
e3["A"] = [
    [0,0], [1,0], [2,0], [4,0], [5,0], [6,0],
    [0,1,2], [1,1], [2,1], [4,1], [5,1], [6,1,1],
    [0,2], [1,2], [2,2], [4,2], [5,2], [6,2]
]
# B1 → (0,1)✓. But B0 starts at (0,1)! Two blocks same cell! BAD.
# Move B0 start.
e3["B"][0] = {"dir":"right", "id":1, "origin":[0,0]}
# B0(→) at (0,0): → in row 0. (0,0)→(1,0)→(2,0). Not portal (portal in row 1). Stuck at (2,0). Can't cross!
# Fix: portal in row 0 or B0 starts in row 1 elsewhere.
e3["B"][0] = {"dir":"right", "id":1, "origin":[0,2]}
# B0(→) at (0,2): → in row 2. No portal in row 2. Stuck.
# Portal only in row 1. Only row 1 blocks can cross.
# Need B0 to be in row 1 but not at (0,1).
# B0 can't start at (0,1) because B1 targets (0,1).
# What if B0 starts at (1,0) and goes ↓ to (1,1) first, then →?
# But B0 dir is →. Can't go ↓ then →. Fixed direction.
# A block that needs to cross must start in portal's row.

# Let me try: B0 and B1 both start in row 1, different x positions.
e4 = {
    "A": [
        [0,0], [1,0], [2,0], [4,0], [5,0], [6,0],
        [0,1], [1,1], [2,1], [4,1], [5,1], [6,1],
        [0,2], [1,2], [2,2], [4,2], [5,2], [6,2]
    ],
    "T": [{"id":1, "one_way":False, "pos":[2,1, 4,1]}],
    "B": [
        {"dir":"right", "id":1, "origin":[0,1]},  # crosses R
        {"dir":"left", "id":2, "origin":[6,1]},   # crosses L
        {"dir":"down", "id":1, "origin":[5,0]},   # stays R, ↓ to (5,2)
        {"dir":"down", "id":2, "origin":[1,0]},   # stays L, ↓ to (1,2)
    ],
    "D": []
}
# After crossing: B0 at (5,1)→(6,1). B1 at (1,1)→(0,1).
# B2 at (5,0)→(5,1)→(5,2). B3 at (1,0)→(1,1)→(1,2).
# B0 at (5,1) blocks B2 from going to (5,1)!
# B1 at (1,1) blocks B3 from going to (1,1)!
# Ordering: B0 must leave (5,1) before B2 arrives. B1 must leave (1,1) before B3 arrives.
# → (B0 crosses to (5,1)) then → (B0 to (6,1)) — but wait, that's 3 → total.
# Actually → moves B0 each time. ↓ moves B2 and B3.
# If ↓ before B0/B1 finish crossing → push into portal!
e4["A"] = [
    [0,0], [1,0], [2,0], [4,0], [5,0], [6,0,1],
    [0,1,2], [1,1], [2,1], [4,1], [5,1], [6,1],
    [0,2], [1,2,2], [2,2], [4,2], [5,2,1], [6,2]
]
# targets id=1: (6,0),(5,2). id=2: (0,1),(1,2).
# B0 → to (6,1). Not target. → to... (6,1) is end of row. Stuck.
# Target at (6,1)?
e4["A"] = [
    [0,0], [1,0], [2,0], [4,0], [5,0], [6,0],
    [0,1,2], [1,1], [2,1], [4,1], [5,1], [6,1,1],
    [0,2], [1,2,2], [2,2], [4,2], [5,2,1], [6,2]
]
test(e4, "E4 swap puzzle")


# ──── Layout F: Two 2×4 vertical strips, narrower gap ────
#
#   Col: 0  1  ·  3  4
#   R0: (0,0)(1,0)  (3,0)(4,0)
#   R1: (0,1)(1,1)  (3,1)(4,1)
#   R2: (0,2)(1,2)  (3,2)(4,2)
#   R3: (0,3)(1,3)  (3,3)(4,3)
#
# 16 cells. Portal: (1,2)↔(3,0) — diagonal bridge!
# ↓ from left enters portal, exits top-right, continues ↓ on right side.

f1 = {
    "A": [
        [0,0], [1,0], [3,0], [4,0],
        [0,1], [1,1], [3,1], [4,1],
        [0,2], [1,2], [3,2], [4,2],
        [0,3,1], [1,3], [3,3,2], [4,3]
    ],
    "T": [{"id":1, "one_way":False, "pos":[1,2, 3,0]}],
    "B": [
        {"dir":"down", "id":1, "origin":[1,0]},  # ↓ col 1: (1,0)→(1,1)→(1,2)=portal→(3,0)→(3,1). Crosses!
        {"dir":"up", "id":2, "origin":[3,3]},    # ↑ col 3: (3,3)→(3,2)→(3,1)→(3,0)=portal→(1,2)→(1,1). Crosses!
        {"dir":"down", "id":1, "origin":[0,0]},  # ↓ col 0 to (0,3)✓
        {"dir":"up", "id":2, "origin":[4,3]},    # ↑ col 4 to (4,0)
    ],
    "D": []
}
# B0(↓) crosses to right at (3,1). Then ↓: (3,1)→(3,2)→(3,3)✓ target id=2? No, B0 is id=1. target (3,3) is id=2.
# Fix: target at (3,3) is id=1 or B0 targets something else.
f1["A"] = [
    [0,0], [1,0], [3,0], [4,0,2],
    [0,1], [1,1], [3,1], [4,1],
    [0,2], [1,2], [3,2], [4,2],
    [0,3,1], [1,3], [3,3,1], [4,3]
]
# targets id=1: (0,3),(3,3). id=2: (4,0).
# B0(↓,id=1) crosses to (3,1), then ↓↓ to (3,3)✓.
# B1(↑,id=2) crosses to (1,1), then ↑ to (1,0). target (4,0) is id=2 on right side. B1 at (1,0) can't reach (4,0).
# Fix: B1 target on left.
f1["A"] = [
    [0,0], [1,0,2], [3,0], [4,0],
    [0,1], [1,1], [3,1], [4,1],
    [0,2], [1,2], [3,2], [4,2],
    [0,3,1], [1,3], [3,3,1], [4,3,2]
]
# B1(↑,id=2) crosses to (1,1)→(1,0)✓ target id=2.
# B3(↑,id=2) at (4,3): ↑↑↑ to (4,0). target (4,3) is id=2. B3 starts on own target! BAD.
# Fix: B3 target at (4,0)? No target there. Add it.
# Or B3 doesn't need to cross. B3(↑) at (4,3): (4,3)→(4,2)→(4,1)→(4,0). target?
f1["A"] = [
    [0,0], [1,0,2], [3,0], [4,0,2],
    [0,1], [1,1], [3,1], [4,1],
    [0,2], [1,2], [3,2], [4,2],
    [0,3,1], [1,3], [3,3,1], [4,3]
]
# targets id=2: (1,0),(4,0). B1(↑) crosses to (1,0)✓. B3(↑) stays at right, to (4,0)✓.
# B2(↓,id=1) at (0,0): ↓↓↓ to (0,3)✓.
# B0(↓,id=1) at (1,0): ↓ to (1,1)→(1,2)=portal→(3,0)→(3,1). Then ↓↓ to (3,3)✓.
# When ↓: B0, B2 both move (both ↓).
# ↓1: B0(1,0)→(1,1), B2(0,0)→(0,1).
# ↓2: B0(1,1)→(1,2)=portal→(3,0)→cont(3,1). B2(0,1)→(0,2).
#   But B1 going ↑: B1(3,3)→(3,2). Does B1 interfere?
# When ↑: B1, B3 move (both ↑).
# If ↑ and ↓ interleave: complex!
# ↑1: B1(3,3)→(3,2), B3(4,3)→(4,2).
# ↓1: B0(1,0)→(1,1), B2(0,0)→(0,1).
# ↓2: B0→portal→(3,1). B1 at (3,2). B0 at (3,1), B1 at (3,2). No conflict.
# ↑2: B1(3,2)→(3,1) B0 there! Push B0→(3,0)=portal→(1,2)→cont↑(1,1)! B0 re-teleports!
# Wild! Let me just test this.
test(f1, "F1 vertical strips")


# F2: Add D block for more depth
f2 = dict(f1)
f2["D"] = [{"origin":[3,2]}]
# D at (3,2). B0 going ↓ from (3,1) would hit D at (3,2)!
# Must clear D first. But who?
# Need a sac block. Add 5th block.
f2["B"] = [
    {"dir":"down", "id":1, "origin":[1,0]},  # crosses to right
    {"dir":"up", "id":2, "origin":[3,3]},    # crosses to left. But goes ↑ through D at (3,2)!
    {"dir":"down", "id":1, "origin":[0,0]},  # stays left
    {"dir":"up", "id":2, "origin":[4,3]},    # stays right
    {"dir":"down", "id":1, "origin":[3,0]},  # sac — ↓ to (3,1)→(3,2)=D→dies
]
# B1(↑) at (3,3): ↑ to (3,2)=D→dies! Must clear D first.
# sac(↓) at (3,0): ↓↓ to (3,2)=D. But sac entering from above needs 2 ↓.
# ↓1: sac(3,0)→(3,1). ↓2: sac(3,1)→(3,2)=D→dies.
# B0 also ↓: (1,0)→(1,1), then →(1,2)=portal→(3,0)→(3,1). If sac already at (3,1)!
# Push sac? sac at (3,1), B0 teleports to (3,0)→cont(3,1) sac there. B0 stays at (3,0)?
# Complex timing.
# 5 id=1 blocks: B0,B2,sac. 2 targets (0,3),(3,3). 3-2=1 die. But have 3 id=1. 3-2=1 must die. ✓
test(f2, "F2 strips+D")


# F3: simpler, no D, just crossing with push interaction
f3 = {
    "A": [
        [0,0], [1,0], [3,0], [4,0],
        [0,1], [1,1], [3,1], [4,1],
        [0,2], [1,2], [3,2], [4,2],
        [0,3,1], [1,3,2], [3,3,1], [4,3,2]
    ],
    "T": [{"id":1, "one_way":False, "pos":[1,3, 3,0]}],
    "B": [
        {"dir":"down", "id":1, "origin":[1,0]},  # ↓ crosses via portal at (1,3)→(3,0)→(3,1)
        {"dir":"up", "id":2, "origin":[3,3]},    # ↑ crosses via portal at (3,0)→(1,3)→(1,2)
        {"dir":"down", "id":1, "origin":[0,0]},  # stays left to (0,3)✓
        {"dir":"up", "id":2, "origin":[4,3]},    # stays right to (4,0)
    ],
    "D": []
}
# B0(↓) at (1,0): ↓↓↓ to (1,3)=portal→(3,0)→cont(3,1). Then ↓↓ to (3,3)✓.
# B1(↑) at (3,3): ↑ to... wait, (3,3) is target for id=1. B1 is id=2. Wrong color. OK.
# B1(↑) at (3,3): ↑↑↑ to (3,0)=portal→(1,3)→cont(1,2). Then ↑↑ to (1,0).
# But target (1,3) is id=2. B1 passes THROUGH (1,3) going up.
# Actually portal at (1,3)↔(3,0). B1 enters portal at (3,0), exits (1,3), cont up (1,2).
# (1,3) is target id=2. B1 is id=2. B1 at (1,3)? No, continuation moves B1 to (1,2).
# B1 overshoots target! Need to stop B1 at (1,3).
# What if something blocks B1 at (1,3)? B2(↓,id=1) is going down col 0, not col 1.
# B0(↓) enters portal at (1,3). If B0 already crossed, (1,3) is portal (always accessible).
# After B0 teleports from (1,3), (1,3) is empty. B1 arrives and continues past it.
# Hmm. What if I put target at (1,2) instead?
f3["A"] = [
    [0,0], [1,0], [3,0], [4,0],
    [0,1], [1,1], [3,1], [4,1],
    [0,2], [1,2,2], [3,2], [4,2],
    [0,3,1], [1,3], [3,3,1], [4,3,2]
]
# B1 crosses to (1,2)✓ target id=2. Then ↑ to (1,1)→(1,0). Overshoots?
# After teleporting: B1 exits at (1,3), cont up (1,2)✓. B1 LANDS at (1,2) on the continuation step. Done!
# B3(↑,id=2) at (4,3): ↑↑↑ to (4,0). target (4,3) is id=2. Starts on own target? No, (4,3,2)=target.
# B3 IS id=2 at (4,3) which IS id=2 target. BAD!
f3["A"][-1] = [4,3]
f3["A"][3] = [4,0,2]
# targets id=2: (1,2),(4,0). B3(↑) at (4,3)→(4,2)→(4,1)→(4,0)✓.
# When ↑: B1 and B3 both move.
# ↑1: B1(3,3)→(3,2), B3(4,3)→(4,2).
# ↑2: B1(3,2)→(3,1), B3(4,2)→(4,1).
# ↑3: B1(3,1)→(3,0)=portal→(1,3)→cont(1,2)✓. B3(4,1)→(4,0)✓.
# Both reach targets on the SAME ↑ move! Satisfying.
# When ↓: B0 and B2 both move.
# ↓1: B0(1,0)→(1,1), B2(0,0)→(0,1).
# ↓2: B0(1,1)→(1,2) B1 at (1,2)?? If ↑ happened first, B1 at (1,2)! Push B1↓ to (1,3).
# B1 pushed OFF target!
# So ↓ before ↑: B0 passes through (1,2) safely (B1 not there yet).
# ↓3: B0(1,2)→(1,3)=portal→(3,0)→cont(3,1). B2(0,2)→(0,3)✓.
# ↓4: B0(3,1)→(3,2). B1 at (3,2)?? If ↑ happened, B1 might have moved.
# Timing depends on order. If all ↓ first, then all ↑:
# ↓1: B0→(1,1), B2→(0,1).
# ↓2: B0→(1,2), B2→(0,2).
# ↓3: B0→(1,3)=portal→(3,1). B2→(0,3)✓.
# ↓4: B0(3,1)→(3,2).
# ↓5: B0(3,2)→(3,3)✓.
# Then ↑↑↑: B1 and B3 cross/go to targets.
# Total: ↓↓↓↓↓↑↑↑ = 8 moves.
# But does ↑ after ↓ cause issues?
# ↑1: B1(3,3)? No, B0 is at (3,3)! B1(3,3)→... wait, B0 occupies (3,3).
# B1 can't move to (3,2) because... B1 at (3,3), B0 at (3,3)? Both at same cell?
# No! B0 moved to (3,3) on ↓5. B1 starts at (3,3). They were both there? No, B1 was at (3,3) initially. When ↓ started, B0 at (1,0) going down. B0 reaches (3,3) on ↓5. B1 still at (3,3) (B1 is ↑, not ↓). So B0↓5: (3,2)→(3,3) B1 at (3,3)! Push B1→(3,4)?no. B0 blocked at (3,2).
# B0 can never reach (3,3) because B1 is there!
# So ↑ must happen BEFORE B0 reaches (3,3). Interleaving needed!
test(f3, "F3 portal at bottom")
