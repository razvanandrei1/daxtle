#!/usr/bin/env python3
"""Level 19 round 2 — split board, focused designs."""

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
# Key insight: portal (2,0)↔(5,1) allows:
#   → block in row 0 to cross from left to right (exits row 1)
#   ← block in row 1 to cross from right to left (exits row 0)
# Blocks swap rows when crossing! This creates natural interaction.
# ══════════════════════════════════════════════════════════════

# Board: two 3×2 islands, 2-col gap
#   (0,0)(1,0)(2,0)    (5,0)(6,0)(7,0)
#   (0,1)(1,1)(2,1)    (5,1)(6,1)(7,1)
# Portal: (2,0)↔(5,1)

BASE = [
    [0,0], [1,0], [2,0], [5,0], [6,0], [7,0],
    [0,1], [1,1], [2,1], [5,1], [6,1], [7,1]
]
PORTAL = [{"id":1, "one_way":False, "pos":[2,0, 5,1]}]


# ── V1: 4 blocks, each side sends 1 across, others stay ──
v1 = {
    "A": [
        [0,0], [1,0], [2,0], [5,0], [6,0,1], [7,0],
        [0,1,2], [1,1], [2,1], [5,1], [6,1], [7,1]
    ],
    "T": PORTAL,
    "B": [
        {"dir":"right", "id":1, "origin":[0,0]},  # crosses → to right side
        {"dir":"left", "id":2, "origin":[7,1]},   # crosses ← to left side
        {"dir":"down", "id":1, "origin":[6,0]},   # stays right. on own target! BAD
        {"dir":"down", "id":2, "origin":[1,0]},   # stays left
    ],
    "D": []
}
# B2 on own target. Fix.
v1["B"][2] = {"dir":"down", "id":1, "origin":[7,0]}
v1["A"][4] = [6,0]
v1["A"][11] = [7,1,1]
# B2(↓) at (7,0) → (7,1)✓ id=1.
# B3(↓) at (1,0) → (1,1). Target id=2 at (0,1). B3 goes ↓ to (1,1). Not target.
# Fix: target id=2 at (1,1).
v1["A"] = [
    [0,0], [1,0], [2,0], [5,0], [6,0], [7,0],
    [0,1,2], [1,1], [2,1], [5,1], [6,1], [7,1,1]
]
v1["B"][3] = {"dir":"left", "id":2, "origin":[2,1]}
# B3(←) at (2,1) → (1,1)→(0,1)✓.
test(v1, "V1 basic")


# ── V2: Crossing blocks interact with staying blocks ──
v2 = {
    "A": [
        [0,0], [1,0], [2,0], [5,0], [6,0], [7,0],
        [0,1], [1,1,2], [2,1], [5,1], [6,1,1], [7,1]
    ],
    "T": PORTAL,
    "B": [
        {"dir":"right", "id":1, "origin":[0,0]},  # crosses → needs (6,1)
        {"dir":"left", "id":2, "origin":[7,1]},   # crosses ← needs (1,1)
        {"dir":"down", "id":1, "origin":[6,0]},   # stays right, ↓ to (6,1). Blocks A's target!
        {"dir":"down", "id":2, "origin":[1,0]},   # stays left, ↓ to (1,1). Blocks B's target!
    ],
    "D": []
}
# B2(↓) at (6,0) → (6,1) which is A's target! A pushes B2 → (7,1)?
# B3(↓) at (1,0) → (1,1) which is B's target! B pushes B3 → (0,1)?
# When ↓: B2 AND B3 both move.
# ↓1: B2(6,0)→(6,1)✓ target. But A needs (6,1) too. B2 IS id=1, (6,1) IS id=1 target.
# B2 on own target! BAD.
# Fix: swap colors. B2 is id=2, target (6,1) is id=1.
v2["B"][2] = {"dir":"down", "id":2, "origin":[6,0]}
# B2(↓,id=2) at (6,0)→(6,1). (6,1) is id=1 target. B2 is id=2 — wrong color. OK!
# B3(↓,id=1) at (1,0)→(1,1). (1,1) is id=2 target. B3 is id=1 — wrong color. OK!
# Now: B2 sits on A's target, B3 sits on B's target. They must be pushed off.
# When A(→) crosses: A at (6,1), B2 also at (6,1)? If B2 already moved there.
# Sequence: ↓ first, then → and ←?
# ↓1: B2→(6,1), B3→(1,1). Now targets occupied by wrong-color blocks.
# →→: A(0,0)→(1,0)→(2,0)=P→(5,1)→(6,1) B2 there! Push B2→(7,1). A at (6,1)✓.
# ←←: B(7,1) B2 pushed there! B(7,1)→(6,1) A there! Push A→? No, A is → not ← dir. A pushed ← to (5,1).
# Hmm, B pushes A. B at (6,1), A at (5,1). Not what we want.
# What if → before ↓?
# →→: A(0,0)→(1,0)→(2,0)=P→(5,1)→(6,1). B2 at (6,0), not (6,1) yet. (6,1) clear. A at (6,1)✓.
# Then ↓: B2(6,0)→(6,1) A there! Push A→(7,1)? A goes ↓ direction? No, push is in ↓ direction.
# A at (6,1) pushed to (6,2)?no cell. B2 blocked at (6,0).
# B2 can't reach (6,1) because A is there. Where does B2 go? Needs different target.
# This is messy. Skip.


# ── V3: One-way crossing + D block for depth ──
v3 = {
    "A": [
        [0,0], [1,0], [2,0], [5,0], [6,0], [7,0],
        [0,1], [1,1], [2,1], [5,1], [6,1], [7,1]
    ],
    "T": PORTAL,
    "B": [
        {"dir":"right", "id":1, "origin":[0,1]},  # crosses → row 1? No, portal at (2,0) row 0.
        # → from (0,1): (0,1)→(1,1)→(2,1). Not portal. Stays left. Stuck at (2,1).
    ],
    "D": []
}
# Portal (2,0)↔(5,1): only row 0 → and row 1 ← can cross.
# Fix B0 to row 0.


# ── V4: Portal (2,1)↔(5,0) — row 1→ crosses, row 0← crosses ──
v4 = {
    "A": [
        [0,0,2], [1,0], [2,0], [5,0], [6,0], [7,0,1],
        [0,1], [1,1], [2,1], [5,1], [6,1], [7,1]
    ],
    "T": [{"id":1, "one_way":False, "pos":[2,1, 5,0]}],
    "B": [
        {"dir":"right", "id":1, "origin":[0,1]},  # → row 1 to (2,1)=P→(5,0)→(6,0). Crosses!
        {"dir":"left", "id":2, "origin":[7,0]},   # ← row 0 to (5,0)=P→(2,1)→(1,1). Crosses!
        {"dir":"right", "id":1, "origin":[5,1]},  # → stays right to (7,1)? Need target.
        {"dir":"left", "id":2, "origin":[2,0]},   # ← stays left to (0,0)✓
    ],
    "D": []
}
# A(→) crosses to (6,0)→(7,0)✓. 3→ total.
# B(←) crosses to (1,1)→(0,1). target? Need id=2 target on left.
# Fix.
v4["A"] = [
    [0,0], [1,0], [2,0], [5,0], [6,0], [7,0,1],
    [0,1,2], [1,1], [2,1], [5,1], [6,1], [7,1]
]
# A→→→ to (7,0)✓. B←←← to (0,1)✓.
# B2(→,id=1) at (5,1)→(6,1)→(7,1). Target? Add.
# B3(←,id=2) at (2,0)→(1,0)→(0,0). Target? Add.
v4["A"] = [
    [0,0,2], [1,0], [2,0], [5,0], [6,0], [7,0,1],
    [0,1,2], [1,1], [2,1], [5,1], [6,1], [7,1,1]
]
# id=1: (7,0),(7,1). id=2: (0,0),(0,1).
# B2(→) at (5,1)→(6,1)→(7,1)✓. 2→.
# B3(←) at (2,0)→(1,0)→(0,0)✓. 2←.
# When →: A and B2 both move. When ←: B and B3 both move.
# Do they conflict?
# →1: A(0,1)→(1,1), B2(5,1)→(6,1).
# →2: A(1,1)→(2,1)=P→(5,0)→(6,0), B2(6,1)→(7,1)✓.
# →3: A(6,0)→(7,0)✓.
# ←1: B(7,0) wait, A just went to (7,0). If → before ←, A at (7,0). B at (7,0)?
# B starts at (7,0)? No, B at (7,0) going ←. But A also going to (7,0).
# B starts at (7,0), A targets (7,0). If A arrives first, B was already there!
# Actually B STARTS at (7,0). A arrives at (7,0) on →3. But B leaves (7,0) on ←1.
# If ← first: B(7,0)→(6,0). Then →3: A→(7,0)✓. Safe.
# If → first: →3: A(6,0)→(7,0) B there! Push B→(8,0)?no. A blocked.
# ORDERING CONSTRAINT! ← must happen before →3 to move B away from (7,0)!
test(v4, "V4 row swap")


# ── V5: Like V4 but with a D block ──
v5 = dict(v4)
v5["D"] = [{"origin":[6,0]}]
v5["B"] = [
    {"dir":"right", "id":1, "origin":[0,1]},  # crosses to right
    {"dir":"left", "id":2, "origin":[7,0]},   # crosses to left
    {"dir":"right", "id":1, "origin":[5,1]},  # stays right
    {"dir":"left", "id":2, "origin":[2,0]},   # stays left
    {"dir":"right", "id":1, "origin":[0,0]},  # sac → to D at (6,0)?
    # sac goes (0,0)→(1,0)→(2,0). B3 at (2,0)! Push chain.
]
# Too complex. Try without sac.
# D at (6,0): A(→) crosses to (5,0) via portal then →(6,0)=D→dies!
# A must not continue to (6,0) if D is there. But continuation is only 1 step.
# A enters portal at (2,1), exits (5,0), cont → (6,0)=D → A dies on D!
# So D must be cleared before A crosses. Need sac.
# Sac(↓) at (6,0): ↓ to (6,1). D at (6,0) — sac starts ON D. Only destroyed after MOVING.
# ↓: sac(6,0)→(6,1). sac leaves D. D still there! Sac only dies if it LANDS on D.
# D at (6,0) is separate. sac at (6,0) starts there but doesn't die (no move happened yet).
# After sac moves away, D remains. Nobody destroyed D.
# Need a block whose dest is (6,0) to destroy D.
# Sac(←) at (7,0): ← to (6,0)=D → sac dies! But B also at (7,0)! Two blocks same cell! BAD.
# Sac(↓) at (6,0): wait, destroy only on landing after move. Sac starts on D, first ↓ takes sac to (6,1). Sac is alive. D still at (6,0).
# Hmm.
# Simpler: D at (1,0). sac(→) somewhere → (1,0)=D.
# Skip D block, V4 is already interesting.


# ── V6: V4 with 2 portals for more crossing options ──
v6 = {
    "A": [
        [0,0,2], [1,0], [2,0], [5,0], [6,0], [7,0,1],
        [0,1,2], [1,1], [2,1], [5,1], [6,1], [7,1,1]
    ],
    "T": [
        {"id":1, "one_way":False, "pos":[2,1, 5,0]},
        {"id":2, "one_way":False, "pos":[2,0, 5,1]},
    ],
    "B": [
        {"dir":"right", "id":1, "origin":[0,1]},
        {"dir":"left", "id":2, "origin":[7,0]},
        {"dir":"right", "id":1, "origin":[0,0]},  # crosses via P2
        {"dir":"left", "id":2, "origin":[7,1]},   # crosses via P2
    ],
    "D": []
}
# B0(→) row 1 → P1 at (2,1)→(5,0)→(6,0). Crosses.
# B1(←) row 0 → P1 at (5,0)?no, P1 entry for ← is (5,0)→(2,1). B1 at (7,0)→(6,0)→(5,0)=P1→(2,1)→(1,1). Crosses.
# B2(→) row 0 → (2,0)=P2→(5,1)→(6,1). Crosses via P2.
# B3(←) row 1 → (5,1)=P2→(2,0)→(1,0). Crosses via P2.
# When →: B0 AND B2 both move. When ←: B1 AND B3 both move.
# 4 blocks all crossing! Targets on opposite sides.
# B0 → (6,0)→(7,0)✓ id=1. B2 → (6,1)→(7,1)✓ id=1.
# B1 ← (1,1)→(0,1)✓ id=2. B3 ← (1,0)→(0,0)✓ id=2.
# When →: B0 and B2 cross via different portals. No conflict.
# →1: B0(0,1)→(1,1), B2(0,0)→(1,0).
# →2: B0(1,1)→(2,1)=P1→(5,0)→(6,0). B2(1,0)→(2,0)=P2→(5,1)→(6,1).
# Both cross on same →! Nice.
# →3: B0(6,0)→(7,0)✓. B2(6,1)→(7,1)✓.
# But B1 at (7,0) and B3 at (7,1)! B0 pushes B1 off (7,0). B2 pushes B3 off (7,1).
# →3: B0(6,0)→(7,0) B1 there! Push B1→(8,0)?no. Blocked.
# Same issue as V4. Must ← first to clear B1/B3.
# ←1: B1(7,0)→(6,0), B3(7,1)→(6,1).
# ←2: B1(6,0)→(5,0)=P1→(2,1)→(1,1). B3(6,1)→(5,1)=P2→(2,0)→(1,0).
# Both cross on same ←!
# ←3: B1(1,1)→(0,1)✓. B3(1,0)→(0,0)✓.
# Now →: B0 and B2 free to cross.
# →1: B0(0,1)→(1,1). B2(0,0)→(1,0).
# →2: Both cross.
# →3: Both to (7,0)✓ and (7,1)✓.
# Solution: ←←← →→→ = 6 moves? Or ←←←→→→. Let me test.
test(v6, "V6 dual portal swap")


# ── V7: Add height for more depth — 3 rows per side ──
#   (0,0)(1,0)(2,0)    (5,0)(6,0)(7,0)
#   (0,1)(1,1)(2,1)    (5,1)(6,1)(7,1)
#   (0,2)(1,2)              (6,2)(7,2)
# 16 cells. Portal: (2,1)↔(5,0)

v7 = {
    "A": [
        [0,0], [1,0], [2,0], [5,0], [6,0], [7,0,1],
        [0,1], [1,1], [2,1], [5,1], [6,1], [7,1],
        [0,2,2], [1,2], [6,2,1], [7,2]
    ],
    "T": [{"id":1, "one_way":False, "pos":[2,1, 5,0]}],
    "B": [
        {"dir":"right", "id":1, "origin":[0,1]},  # crosses via portal
        {"dir":"left", "id":2, "origin":[7,0]},   # crosses via portal (← enters at (5,0)→(2,1)→(1,1))
        {"dir":"down", "id":1, "origin":[6,0]},   # stays right ↓ to (6,2)✓
        {"dir":"down", "id":2, "origin":[1,0]},   # stays left ↓ to (1,2)→...target (0,2). can't reach col 0 going ↓.
    ],
    "D": []
}
# B3 can't reach (0,2). Fix: target at (1,2) for id=2.
v7["A"][12] = [0,2]
v7["A"][13] = [1,2,2]
# B3(↓) at (1,0)→(1,1)→(1,2)✓. 2↓.
# But B0(→) at (0,1): →(1,1). B3 at (1,1) after ↓1! Conflict.
# If →before↓: B0(0,1)→(1,1). Then ↓: B3(1,0)→(1,1) B0 there! Push B0→(1,2). B3 at (1,1).
# B0 pushed off its path! Bad.
# If ↓before→: B3(1,0)→(1,1). Then →: B0(0,1)→(1,1) B3 there! Push B3→(2,1)=portal→(5,0)→(6,0).
# B3 teleported to right side! Unexpected!
# This is wild but probably breaks the puzzle. Let me test.
test(v7, "V7 3-row split")


# ── V8: Cleaner — avoid shared cells between → and ↓ blocks ──
v8 = {
    "A": [
        [0,0], [1,0], [2,0], [5,0], [6,0], [7,0,1],
        [0,1], [1,1], [2,1], [5,1], [6,1], [7,1],
        [0,2,2], [1,2], [6,2,1], [7,2]
    ],
    "T": [{"id":1, "one_way":False, "pos":[2,1, 5,0]}],
    "B": [
        {"dir":"right", "id":1, "origin":[0,1]},  # crosses, avoids col 1
        {"dir":"left", "id":2, "origin":[7,1]},   # crosses via portal at (5,0)? No, ← row 1.
        # (7,1)→(6,1)→(5,1). Not portal. Stuck.
        {"dir":"down", "id":1, "origin":[6,0]},   # stays right
        {"dir":"down", "id":2, "origin":[0,0]},   # stays left to (0,2)✓
    ],
    "D": []
}
# B1 stuck. Portal (2,1)↔(5,0) — ← in row 1 enters (5,1)?no, that's not portal.
# ← block in row 0 enters (5,0)=portal→(2,1)→(1,1). B1 must be in row 0!
v8["B"][1] = {"dir":"left", "id":2, "origin":[7,0]}
# B1(←) at (7,0): ←← to (5,0)=P→(2,1)→cont(1,1). Then ←(1,1)→(0,1). target?
# Need id=2 target on left side. (0,2) is id=2 target. B1 goes LEFT not DOWN.
# Fix: id=2 target at (0,1).
v8["A"] = [
    [0,0], [1,0], [2,0], [5,0], [6,0], [7,0,1],
    [0,1,2], [1,1], [2,1], [5,1], [6,1], [7,1],
    [0,2], [1,2], [6,2,1], [7,2]
]
# B1 → (0,1)✓. B3(↓,id=2) at (0,0)→(0,1)→(0,2). B3 passes through (0,1)!
# If B3 goes ↓ before B1 arrives: B3→(0,1). B1 later pushes B3 off? ← pushes LEFT not DOWN.
# B1(←) at (1,1)→(0,1) B3 there! Push B3→(-1,1)?no. Blocked.
# Fix: B3 in different col.
v8["B"][3] = {"dir":"down", "id":2, "origin":[1,0]}
v8["A"] = [
    [0,0], [1,0], [2,0], [5,0], [6,0], [7,0,1],
    [0,1,2], [1,1], [2,1], [5,1], [6,1], [7,1],
    [0,2], [1,2,2], [6,2,1], [7,2]
]
# B3(↓,id=2) at (1,0)→(1,1)→(1,2)✓. 2↓.
# B1(←) crosses to (1,1). Then (0,1)✓. B3 at (1,1) after ↓1!
# if ↓ before ←: B3 at (1,1), B1 crosses to (1,1) — push B3.
# if ← first: B1 arrives at (1,1) before B3. Then ↓ moves B3(1,0)→(1,1) B1 there. Push B1→(1,2).
# Complex! Let me test.
test(v8, "V8 clean 3row")


# ── V9: Small split, 10 cells, focused ──
#   (0,0)(1,0)    (4,0)(5,0)
#   (0,1)(1,1)    (4,1)(5,1)
#        (1,2)    (4,2)
# Portal: (1,2)↔(4,0)

v9 = {
    "A": [
        [0,0], [1,0], [4,0], [5,0],
        [0,1,2], [1,1], [4,1], [5,1,1],
        [1,2], [4,2,1]
    ],
    "T": [{"id":1, "one_way":False, "pos":[1,2, 4,0]}],
    "B": [
        {"dir":"down", "id":1, "origin":[1,0]},  # ↓ to (1,2)=P→(4,0)→(4,1). Crosses! Then ↓ (4,2)✓.
        {"dir":"up", "id":2, "origin":[4,2]},    # ↑ to... (4,1)→(4,0)=P→(1,2)→cont↑(1,1). Crosses! Then ↑ (1,0).
        {"dir":"down", "id":1, "origin":[0,0]},  # stays left ↓ to (0,1).
        {"dir":"up", "id":2, "origin":[5,1]},    # stays right ↑ to (5,0). on own target? (5,1) is id=1 target. OK.
    ],
    "D": []
}
# B0(↓) crosses to right. target (4,2). (5,1) is id=1 target.
# B1(↑) crosses to left. target (0,1). (0,1) is id=2 target.
# B2(↓) stays left. target? (0,1) is id=2. Need id=1 target on left.
# Fix: no id=1 target on left.
# 3 id=1 blocks (B0,B2), 2 need targets. Hmm, B2 is id=1.
# targets id=1: (5,1),(4,2). B0 reaches (4,2)✓ after crossing. B2 needs (5,1)?
# B2(↓,id=1) at (0,0)→(0,1). target (5,1) on right side. B2 can't reach!
# Skip. Many target issues.


# ── V10: Simplest possible — 2 blocks cross, pure ordering ──
v10 = {
    "A": [
        [0,0], [1,0], [2,0], [5,0], [6,0], [7,0],
        [0,1], [1,1,1], [2,1], [5,1], [6,1,2], [7,1]
    ],
    "T": [{"id":1, "one_way":False, "pos":[2,0, 5,1]}],
    "B": [
        {"dir":"right", "id":1, "origin":[0,0]},  # → crosses row 0→portal→row 1. Target (6,1).
        # path: (0,0)→(1,0)→(2,0)=P→(5,1)→(6,1)✓. 3→ moves.
        {"dir":"left", "id":2, "origin":[7,1]},   # ← crosses row 1→portal→row 0. Target (1,1)?
        # But (1,1) is id=1 target. B1 is id=2. Wrong target.
        # Fix: (1,1) is id=2 target.
    ],
    "D": []
}
v10["A"] = [
    [0,0], [1,0], [2,0], [5,0], [6,0], [7,0],
    [0,1], [1,1,2], [2,1], [5,1], [6,1,1], [7,1]
]
# B0(→) → → → to (6,1)✓. B1(←) needs path.
# B1(←) at (7,1): ←← to (5,1). Portal at (5,1)→exits(2,0)→cont←(1,0). At (1,0).
# ← to (0,0). target (1,1) is id=2. B1 at (0,0), can't reach (1,1) going left.
# Fix: B1 needs to stop at (1,0). Target at (1,0)?
v10["A"] = [
    [0,0], [1,0,2], [2,0], [5,0], [6,0], [7,0],
    [0,1], [1,1], [2,1], [5,1], [6,1,1], [7,1]
]
# B1 ←← to (5,1)=P→(2,0)→(1,0)✓ id=2. But then ← again: (1,0)→(0,0). Overshoots!
# On ←3: B1(1,0)→(0,0). B1 past target!
# B1 reaches target on ←2 (portal cont to (1,0)). But ←3 moves B1 further.
# Need to NOT do ←3. Just ←← for B1.
# But B0 needs →→→. Can we interleave: →←→←→ = 5 moves?
# →1: B0→(1,0). B1 not affected (dir=←).
# ←1: B1→(6,1). But B0 target is (6,1)! B1 is ON B0's target. B1 at (6,1) which is id=1 target. B1 is id=2. Wrong color OK.
# →2: B0→(2,0)=P→(5,1)→(6,1). B1 at (6,1)! Push B1→(7,1). B0 at (6,1)✓.
# But now B1 pushed back to (7,1) start. Undo!
# ←2: B1(7,1)→(6,1) B0 there! Push B0→(5,1). B0 off target!
# Deadlock. The two blocks push each other.
# What if B0 at target (6,1) acts as wall for B1? But B1 pushes B0.
# Fix: have B1 cross BEFORE B0.
# ←←: B1 crosses to (1,0)✓. Then →→→: B0 crosses to (6,1)✓.
# B1 at (1,0). When →: B0(0,0)→(1,0) B1 there! Push B1→(2,0)=P→(5,1)→(6,1). B1 re-teleports!
# B0 pushes B1 through portal! B0 at (1,0), B1 at (6,1).
# →2: B0(1,0)→(2,0)=P→(5,1)→(6,1) B1 there! Push B1→(7,1). B0 at (6,1)✓.
# B1 back at (7,1)! Lost progress.
# The blocks keep pushing each other through the portal. Infinite loop potential.
# Need to separate them. Add more blocks or change positions.
test(v10, "V10 2-block cross")
