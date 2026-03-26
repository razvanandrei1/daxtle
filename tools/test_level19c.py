#!/usr/bin/env python3
"""Level 19 round 3 — split board with push-through-portal mechanic."""

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
# Core concept: Two tall islands connected by a portal at the
# bottom-left ↔ top-right. Blocks are PUSHED through the portal
# via a ↓ chain. D block on the portal exit must be cleared first.
#
#   Left:        Right:
#   (0,0)(1,0)   (4,0)(5,0)
#   (0,1)(1,1)   (4,1)(5,1)
#   (0,2)(1,2)   (4,2)(5,2)
#   (0,3)(1,3)
#
# 14 cells. Portal: (1,3)↔(4,0). D at (4,1).
# ══════════════════════════════════════════════════════════════

# ── W1: 5 blocks, push chain through portal ──
w1 = {
    "A": [
        [0,0], [1,0], [4,0], [5,0],
        [0,1], [1,1], [4,1], [5,1],
        [0,2], [1,2], [4,2,1], [5,2,2],
        [0,3,1], [1,3]
    ],
    "T": [{"id":1, "one_way":False, "pos":[1,3, 4,0]}],
    "B": [
        {"dir":"down", "id":1, "origin":[1,0]},   # A: pushes B down, crosses via portal
        {"dir":"right", "id":1, "origin":[0,1]},  # B: gets pushed ↓ through portal by A
        {"dir":"up", "id":1, "origin":[4,2]},     # Sac: ↑ to D(4,1)→dies. Starts on own target! BAD
        {"dir":"down", "id":2, "origin":[5,0]},   # C: stays right
        {"dir":"down", "id":1, "origin":[0,0]},   # E: stays left
    ],
    "D": [{"origin":[4,1]}]
}
# Sac on own target. Fix.
w1["A"][10] = [4,2]
w1["A"].insert(12, [4,1,1])  # Hmm, this is messy. Let me rebuild.

w1 = {
    "A": [
        [0,0], [1,0], [4,0], [5,0],
        [0,1], [1,1], [4,1,1], [5,1],
        [0,2], [1,2], [4,2], [5,2,2],
        [0,3,1], [1,3]
    ],
    "T": [{"id":1, "one_way":False, "pos":[1,3, 4,0]}],
    "B": [
        {"dir":"down", "id":1, "origin":[1,0]},   # A
        {"dir":"right", "id":1, "origin":[0,1]},  # B
        {"dir":"up", "id":1, "origin":[4,2]},     # Sac
        {"dir":"down", "id":2, "origin":[5,0]},   # C
        {"dir":"down", "id":1, "origin":[0,0]},   # E
    ],
    "D": [{"origin":[4,1]}]
}
# targets id=1: (4,1),(0,3). 4 id=1 blocks - 1 sac = 3. But only 2 targets! Need 3rd.
# Add target at... where does B end up? B pushed to (4,2). target at (4,2)?
w1["A"][10] = [4,2,1]
# targets id=1: (4,1),(0,3),(4,2). 3 targets ✓
test(w1, "W1 push-portal")


# ── W2: Simpler — no E block, 4 blocks ──
w2 = {
    "A": [
        [0,0], [1,0], [4,0], [5,0],
        [0,1], [1,1], [4,1,1], [5,1],
        [0,2,1], [1,2], [4,2], [5,2,2],
        [0,3], [1,3]
    ],
    "T": [{"id":1, "one_way":False, "pos":[1,3, 4,0]}],
    "B": [
        {"dir":"down", "id":1, "origin":[1,0]},   # A: crosses
        {"dir":"right", "id":1, "origin":[0,1]},  # B: gets pushed through
        {"dir":"up", "id":1, "origin":[4,2]},     # Sac: clears D
        {"dir":"down", "id":2, "origin":[5,0]},   # C: stays right
    ],
    "D": [{"origin":[4,1]}]
}
# 3 id=1, 2 targets (4,1),(0,2). 3-1=2 ✓
# A at (4,1)✓ after crossing. But where does B go?
# B pushed to right side. If target (0,2) on LEFT, B can't reach it from right.
# Need target on right for B. Add (4,2,1)?
# Hmm, but I have target (0,2,1) on left. A crosses to right. Who stays left for (0,2)?
# Nobody! A crosses, Sac dies. Only C stays right (id=2).
# Fix: need a block on left that stays.
# Add back E.

w3 = {
    "A": [
        [0,0], [1,0], [4,0], [5,0],
        [0,1], [1,1], [4,1,1], [5,1],
        [0,2], [1,2], [4,2,1], [5,2,2],
        [0,3,1], [1,3]
    ],
    "T": [{"id":1, "one_way":False, "pos":[1,3, 4,0]}],
    "B": [
        {"dir":"down", "id":1, "origin":[1,0]},   # A: pushes B, crosses
        {"dir":"right", "id":1, "origin":[0,1]},  # B: pushed through portal
        {"dir":"up", "id":1, "origin":[4,2]},     # Sac
        {"dir":"down", "id":2, "origin":[5,0]},   # C
        {"dir":"down", "id":1, "origin":[0,0]},   # E: stays left
    ],
    "D": [{"origin":[4,1]}]
}
# A→(4,1)✓, B→(4,2)✓, E→(0,3)✓, C→(5,2)✓. 4 id=1 - 1 sac = 3 targets ✓
test(w3, "W3 full")


# ── W4: Different portal position for visual variety ──
# Portal: (0,3)↔(5,0) — left bottom to right top
w4 = {
    "A": [
        [0,0], [1,0], [4,0], [5,0],
        [0,1], [1,1], [4,1], [5,1,1],
        [0,2], [1,2], [4,2,1], [5,2,2],
        [0,3], [1,3,1]
    ],
    "T": [{"id":1, "one_way":False, "pos":[0,3, 5,0]}],
    "B": [
        {"dir":"down", "id":1, "origin":[0,0]},   # A: goes down col 0, enters portal at (0,3)
        {"dir":"down", "id":1, "origin":[1,0]},   # B: goes down col 1, stays left. Target (1,3)✓
        {"dir":"up", "id":1, "origin":[4,2]},     # Sac: clears D at (4,1)? Or (5,1)?
        {"dir":"down", "id":2, "origin":[5,0]},   # C: goes down, but starts ON portal! Teleports?
    ],
    "D": [{"origin":[5,1]}]
}
# C at (5,0) which IS the portal. When ↓: C(5,0)→(5,1)=D. C dies on D!
# Fix: C starts elsewhere.
w4["B"][3] = {"dir":"left", "id":2, "origin":[5,2]}
# C(←) at (5,2)→(4,2)✓. 1 move.
# A(↓) at (0,0): ↓↓↓ to (0,3)=P→(5,0)→cont↓(5,1)=D→dies! If D not cleared.
# Sac(↑) at (4,2)→(4,1). D at (5,1). Sac doesn't reach D!
# Fix: Sac reaches D at (5,1). Sac(↑) at (5,2)? C is there.
# Sac(←) at... this is messy.
# Let's put D at (4,1) and Sac reaches it.
w4["D"] = [{"origin":[4,1]}]
w4["B"][2] = {"dir":"up", "id":1, "origin":[4,2]}
# Sac(↑) at (4,2)→(4,1)=D→dies. ✓
# But A exits portal at (5,0)→cont↓(5,1). target at (5,1)?
w4["A"] = [
    [0,0], [1,0], [4,0], [5,0],
    [0,1], [1,1], [4,1], [5,1,1],
    [0,2], [1,2], [4,2], [5,2,2],
    [0,3], [1,3,1]
]
# A→(5,1)✓, B→(1,3)✓, C→(4,2)✓ target? Need (4,2) as id=2 target.
w4["A"][10] = [4,2,2]
w4["A"][11] = [5,2]
# C(←) at (5,2)→(4,2)✓ id=2.
# A→(5,0)→(5,1)✓ id=1.
# B→(1,3)✓ id=1.
# Sac→D→dies.
# E needed? 3 id=1 blocks (A,B,Sac). 2 targets (5,1),(1,3). 3-1=2 ✓.
# 1 id=2 block (C). 1 target (4,2). ✓.
test(w4, "W4 col-0 portal")


# ── W5: Add more blocks for longer solution ──
w5 = {
    "A": [
        [0,0], [1,0], [4,0], [5,0],
        [0,1], [1,1], [4,1], [5,1,1],
        [0,2], [1,2], [4,2,2], [5,2],
        [0,3], [1,3,1]
    ],
    "T": [{"id":1, "one_way":False, "pos":[0,3, 5,0]}],
    "B": [
        {"dir":"down", "id":1, "origin":[0,0]},   # A: crosses via portal
        {"dir":"down", "id":1, "origin":[1,0]},   # B: stays left
        {"dir":"up", "id":1, "origin":[5,2]},     # Sac: ↑ to clear D
        {"dir":"left", "id":2, "origin":[5,1]},   # C: stays right. starts on id=1 target!
        {"dir":"right", "id":1, "origin":[0,1]},  # D_blk: pushed by A? Gets in A's ↓ path?
    ],
    "D": [{"origin":[5,1]}]
}
# C at (5,1) which is id=1 target. C is id=2. Wrong color. OK.
# But Sac(↑) at (5,2)→(5,1)=D→dies. Clears D at (5,1).
# A exits portal at (5,0)→cont↓(5,1). D cleared. A at (5,1)✓.
# C(←) at (5,1) must move BEFORE Sac clears D? No, before A arrives.
# If C stays at (5,1), A lands there and pushes C?
# A cont from portal: (5,0)→↓(5,1). If C at (5,1), cont blocked. A stays at (5,0).
# Then ↓: A(5,0)→(5,1) C there? If C moved ←, (5,1) clear.
# C(←): ←(5,1)→(4,1). Then ←(4,1)→(3,1)?no cell. target at (4,2)? C goes ← not ↓.
# Fix target id=2 at (4,1)?
w5["A"][6] = [4,1,2]
# C(←) at (5,1)→(4,1)✓ id=2. 1← move.
# But D_blk(→,id=1) at (0,1): what does it do?
# → from (0,1): (1,1)→... continues. Not in A's ↓ path.
# Overcomplicated. Let me simplify.

# ── W6: Clean 5-block design ──
w6 = {
    "A": [
        [0,0], [1,0], [4,0], [5,0],
        [0,1], [1,1], [4,1,2], [5,1],
        [0,2], [1,2], [4,2], [5,2],
        [0,3,1], [1,3,1]
    ],
    "T": [{"id":1, "one_way":False, "pos":[0,3, 5,0]}],
    "B": [
        {"dir":"down", "id":1, "origin":[0,0]},   # A: crosses
        {"dir":"down", "id":1, "origin":[1,0]},   # B: stays left to (1,3)✓
        {"dir":"up", "id":1, "origin":[5,2]},     # Sac: ↑↑ to D(5,1)? Wait D at where?
        {"dir":"left", "id":2, "origin":[5,1]},   # C: ← to (4,1)✓
    ],
    "D": [{"origin":[5,1]}]
}
# Sac(↑) at (5,2)→(5,1)=D→dies. C at (5,1) too! Two at same cell start? BAD.
# Move C to (5,0).
w6["B"][3] = {"dir":"left", "id":2, "origin":[5,0]}
# C at (5,0) = portal exit. Block starts on portal. OK (portals only activate on dest).
# C(←) at (5,0)→(4,0). target (4,1) not reachable going ←. Fix.
# C(↓) at (5,0)→(5,1)=D→dies! Bad.
# C(←) at (5,0)→(4,0). target at (4,0)?
w6["A"][2] = [4,0,2]
w6["A"][6] = [4,1]
# C(←) at (5,0)→(4,0)✓ id=2.
# But A exits portal at (5,0). If C still there, A blocked.
# Ordering: C must ← before A arrives via portal.
# When ↓: A and B both move. When ←: C moves. When ↑: Sac moves.
# ←: C(5,0)→(4,0)✓.
# ↑: Sac(5,2)→(5,1)=D→dies.
# ↓↓↓: A crosses, B to target.
# ↓1: A(0,0)→(0,1), B(1,0)→(1,1).
# ↓2: A(0,1)→(0,2), B(1,1)→(1,2).
# ↓3: A(0,2)→(0,3)=P→(5,0)→cont↓(5,1). D cleared. A at (5,1). B(1,2)→(1,3)✓.
# target for A? (5,1)? Add.
w6["A"] = [
    [0,0], [1,0], [4,0,2], [5,0],
    [0,1], [1,1], [4,1], [5,1,1],
    [0,2], [1,2], [4,2], [5,2],
    [0,3], [1,3,1]
]
# A at (5,1)✓ id=1. B at (1,3)✓ id=1. C at (4,0)✓ id=2.
# 3 id=1 - 1 sac = 2 targets ✓.
# Solution: ← ↑ ↓ ↓ ↓ = 5 moves.
# Traps: ↓ before ↑ kills A on D. ↓ before ← blocks A at portal exit.
test(w6, "W6 clean")


# ── W7: Add a D block on left side for more depth ──
w7 = dict(w6)
w7["D"] = [{"origin":[5,1]}, {"origin":[0,2]}]
# D at (0,2) AND (5,1). A goes through (0,2) going ↓!
# A(↓) at (0,0): ↓ to (0,1)→(0,2)=D→A dies!
# Must clear D(0,2) first. Need sac on left.
# Add 5th block: Sac2(→,id=1) at (0,2)? Block starts ON D. After first move, leaves.
# Actually, Sac2 must LAND on D. Sac2(←,id=1) at (1,2): ← to (0,2)=D→dies.
w7["B"] = [
    {"dir":"down", "id":1, "origin":[0,0]},   # A: crosses (must avoid D at (0,2))
    {"dir":"down", "id":1, "origin":[1,0]},   # B: stays left
    {"dir":"up", "id":1, "origin":[5,2]},     # Sac1: clears D(5,1)
    {"dir":"left", "id":2, "origin":[5,0]},   # C
    {"dir":"left", "id":1, "origin":[1,2]},   # Sac2: clears D(0,2)
]
# 4 id=1 - 2 sacs = 2 targets ✓. Already have 2 id=1 targets.
# ← moves BOTH C and Sac2.
# ←: C(5,0)→(4,0)✓. Sac2(1,2)→(0,2)=D→dies!
# One ← clears D(0,2) AND moves C to target! Efficient.
# ↑: Sac1(5,2)→(5,1)=D→dies!
# ↓↓↓: A and B cross/descend.
# Total: ← ↑ ↓ ↓ ↓ = 5 moves.
# But: ↓ before ←: A hits D(0,2). ↓ before ↑: A hits D(5,1) after crossing.
# DOUBLE D trap! Both must be cleared before A descends.
test(w7, "W7 twin D split")


# ── W8: Like W7 but with B getting pushed through portal ──
w8 = {
    "A": [
        [0,0], [1,0], [4,0,2], [5,0],
        [0,1], [1,1], [4,1], [5,1,1],
        [0,2], [1,2], [4,2,1], [5,2],
        [0,3], [1,3,1]
    ],
    "T": [{"id":1, "one_way":False, "pos":[0,3, 5,0]}],
    "B": [
        {"dir":"down", "id":1, "origin":[0,0]},   # A: pushes B through col 0, crosses
        {"dir":"right", "id":1, "origin":[0,1]},  # B: pushed ↓ by A, through portal
        {"dir":"up", "id":1, "origin":[5,2]},     # Sac: clears D
        {"dir":"left", "id":2, "origin":[5,0]},   # C
    ],
    "D": [{"origin":[5,1]}]
}
# A pushes B ↓: B at (0,1), A at (0,0)→(0,1) pushes B→(0,2).
# ↓2: A→(0,2) pushes B→(0,3)=P→(5,0)→cont↓(5,1). If D cleared: B at (5,1)✓?
# No, B at (5,1) is id=1 target. ✓!
# ↓3: A→(0,3)=P→(5,0)→cont↓(5,1) B at (5,1). Push B→(5,2). A at (5,1).
# B overshoots! B at (5,2). target (4,2) for id=1. B goes → from (5,2)?no cell right. B at (5,2).
# B stuck at (5,2). Target (4,2)? B goes RIGHT not LEFT. Can't reach (4,2).
# Fix: target at (5,2)? But Sac was there.
# Hmm. B gets pushed to (5,2) when A follows through portal.
# What if B reaches (5,1) target AND A doesn't push B further?
# A enters portal at (0,3): exits (5,0), cont ↓ (5,1) B there. A stays at (5,0).
# A at (5,0). target? Need target at (5,0) or A goes ↓ later.
# ↓4: A(5,0)→(5,1) B there. Push B→(5,2). A at (5,1)✓.
# B at (5,2). No target there. B stuck.
# Need to prevent A from pushing B off target.
# What if A targets (5,0) and B doesn't go to (5,1)?
# B exits portal at (5,0)→cont(5,1). Can't avoid continuation.
# Tricky.
test(w8, "W8 push-through")


# ── W9: Wider right island, B pushed to different col ──
w9 = {
    "A": [
        [0,0], [1,0], [4,0], [5,0], [6,0],
        [0,1], [1,1], [4,1], [5,1,1], [6,1,2],
        [0,2], [1,2], [4,2],
        [0,3], [1,3,1]
    ],
    "T": [{"id":1, "one_way":False, "pos":[0,3, 5,0]}],
    "B": [
        {"dir":"down", "id":1, "origin":[0,0]},   # A: crosses
        {"dir":"down", "id":1, "origin":[1,0]},   # B: stays left
        {"dir":"up", "id":1, "origin":[4,2]},     # Sac
        {"dir":"left", "id":2, "origin":[6,0]},   # C: ← to target on right
    ],
    "D": [{"origin":[4,1]}]
}
# Sac(↑) at (4,2)→(4,1)=D→dies.
# A exits portal at (5,0)→cont↓(5,1)✓. Not near D(4,1).
# C(←) at (6,0)→(5,0). Portal at (5,0)! C enters portal? C goes LEFT to (5,0)=portal→exits(0,3)→cont←(-1,3)?no cell. C at (0,3). Teleported to left!
# C accidentally crosses! Not intended.
# Fix: portal at different location.

w10 = {
    "A": [
        [0,0], [1,0], [4,0], [5,0], [6,0],
        [0,1], [1,1], [4,1], [5,1,1], [6,1,2],
        [0,2], [1,2], [4,2],
        [0,3], [1,3,1]
    ],
    "T": [{"id":1, "one_way":False, "pos":[1,3, 4,0]}],
    "B": [
        {"dir":"down", "id":1, "origin":[1,0]},   # A: crosses via portal in col 1
        {"dir":"down", "id":1, "origin":[0,0]},   # B: stays left col 0
        {"dir":"up", "id":1, "origin":[4,2]},     # Sac: clears D(4,1)
        {"dir":"left", "id":2, "origin":[6,0]},   # C: ← along row 0 on right side
    ],
    "D": [{"origin":[4,1]}]
}
# A(↓) col 1: (1,0)→(1,1)→(1,2)→(1,3)=P→(4,0)→cont↓(4,1)=D! If D cleared: (4,1). Else dies.
# Sac(↑) at (4,2)→(4,1)=D→dies.
# B(↓) col 0: (0,0)→(0,1)→(0,2)→(0,3). target (0,3)?
# C(←) at (6,0)→(5,0)→(4,0). (4,0) is where A exits portal! If A already there, push.
# When ←: C(6,0)→(5,0). ←: C(5,0)→(4,0). If A at (4,0), push A→(3,0)?no cell. C blocked.
# So C must reach (4,0) BEFORE A arrives. Or target is (5,0).
# target id=2 at (6,1): C(←) at (6,0) goes LEFT not DOWN. Can't reach (6,1).
# Fix: C goes ↓. C(↓,id=2) at (6,0)→(6,1)✓. 1↓.
w10["B"][3] = {"dir":"down", "id":2, "origin":[6,0]}
# When ↓: A, B, C all move.
# ↓1: A→(1,1), B→(0,1), C→(6,1)✓.
# ↓2: A→(1,2), B→(0,2).
# ↓3: A→(1,3)=P→(4,0)→cont(4,1). D cleared? Yes if ↑ done. A at (4,1).
#   B→(0,3). target (0,3)?
# Need targets: A at (4,1): id=1 target? Currently (5,1) is id=1 target.
# Fix: target at (4,1)?
# Wait, D was at (4,1). After D cleared, it's just a cell.
# Hmm, currently A exits portal cont to (4,1). If A continues ↓: (4,2)?
# Actually let me check: A enters (1,3)=P, exits (4,0), cont ↓ (4,1). D cleared → A at (4,1).
# Then ↓4: A(4,1)→(4,2). Sac was at (4,2) but Sac went ↑ and died.
# A at (4,2). target?
# Let me set targets properly.
w10["A"] = [
    [0,0], [1,0], [4,0], [5,0], [6,0],
    [0,1], [1,1], [4,1], [5,1,1], [6,1,2],
    [0,2], [1,2], [4,2],
    [0,3,1], [1,3]
]
# targets id=1: (5,1),(0,3). A needs (5,1)? A at (4,1) after crossing. ↓ to (4,2). Not (5,1).
# A can't reach (5,1) going ↓ (different column).
# Fix: target at (4,2). A at (4,2)✓.
w10["A"] = [
    [0,0], [1,0], [4,0], [5,0], [6,0],
    [0,1], [1,1], [4,1], [5,1], [6,1,2],
    [0,2], [1,2], [4,2,1],
    [0,3,1], [1,3]
]
# A→(4,2)✓. B→(0,3)✓. C→(6,1)✓.
# 3 id=1 (A,B,Sac), 2 targets (4,2),(0,3). 3-1=2 ✓.
test(w10, "W10 col1 portal")
