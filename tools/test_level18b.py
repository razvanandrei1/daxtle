#!/usr/bin/env python3
"""Level 18 round 2 — D blocks in different directions for richer ordering."""

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
# Concept: Sac1 goes ↓ to D1, Sac2 goes → to D2.
# Different directions = they don't move on the same swipe.
# Other blocks sharing those directions create ordering tension.
# ══════════════════════════════════════════════════════════════


# ──── Board: 15-cell L-shape ────
#   Row 0: (0,0) (1,0) (2,0) (3,0)
#   Row 1: (0,1) (1,1) (2,1) (3,1)
#   Row 2: (0,2) (1,2) (2,2) (3,2)
#   Row 3:       (1,3) (2,3)

# D1 at (0,2), D2 at (3,1)
# Sac1(↓) at (0,0) goes ↓↓ to D1
# Sac2(→) at (1,1) goes →→ to D2

# 5 blocks: 4 id=1 + 1 id=2
# 2 sacs die → 2 id=1 survivors need 2 targets + 1 id=2 target

v1 = {
    "A": [
        [0,0], [1,0], [2,0], [3,0,1],
        [0,1], [1,1], [2,1], [3,1],
        [0,2], [1,2], [2,2,1], [3,2],
        [1,3], [2,3,2]
    ],
    "B": [
        {"dir":"down", "id":1, "origin":[0,0]},   # sac1 ↓↓ to D1(0,2)
        {"dir":"right", "id":1, "origin":[1,1]},  # sac2 →→ to D2(3,1)
        {"dir":"right", "id":1, "origin":[0,1]},  # B0 → along row 1. Pushed by sac1?
        {"dir":"down", "id":1, "origin":[2,0]},   # B1 ↓ col 2 to (2,2)✓
        {"dir":"left", "id":2, "origin":[2,3]},   # B2 ← to... (1,3)? target (2,3) is where B2 starts. BAD? B2 is id=2, target is id=2. Own target!
    ],
    "D": [{"origin":[0,2]}, {"origin":[3,1]}]
}
# B2 on own target. Fix.
v1["B"][4] = {"dir":"up", "id":2, "origin":[2,3]}
# B2(↑) at (2,3) → (2,2)✓? (2,2) is id=1 target, B2 is id=2. Not its target.
# B2 needs id=2 target. Fix target.
v1["A"][10] = [2,2]  # remove id=1 target from (2,2)
v1["A"].append([1,3,2])  # add id=2 target at (1,3)
# Wait, (1,3) already in A as [1,3]. Need to update it.
v1["A"] = [
    [0,0], [1,0], [2,0], [3,0,1],
    [0,1], [1,1], [2,1], [3,1],
    [0,2], [1,2], [2,2,1], [3,2],
    [1,3,2], [2,3]
]
# B2(↑) at (2,3) → (2,2)✓ id=1 target. B2 is id=2. Not its target.
# B2 needs to reach (1,3) id=2 target. B2 goes UP from (2,3)→(2,2)→(2,1)→(2,0). Can't reach (1,3) going up.
# Fix: B2 dir=left at (2,3) → (1,3)✓
v1["B"][4] = {"dir":"left", "id":2, "origin":[2,3]}
test(v1, "V1")


# V2: Add blocking interaction — B0 is in sac2's path
v2 = {
    "A": [
        [0,0], [1,0], [2,0], [3,0],
        [0,1], [1,1], [2,1], [3,1],
        [0,2], [1,2], [2,2], [3,2],
        [1,3,1], [2,3,2]
    ],
    "B": [
        {"dir":"down", "id":1, "origin":[0,0]},   # sac1 ↓↓ to D1(0,2)
        {"dir":"right", "id":1, "origin":[0,1]},  # sac2 → to... D2(3,2)? Long path.
        {"dir":"left", "id":1, "origin":[3,0]},   # B0 ← along row 0
        {"dir":"down", "id":1, "origin":[1,0]},   # B1 ↓ to (1,3)✓
        {"dir":"left", "id":2, "origin":[3,2]},   # B2 ← to (2,3)✓
    ],
    "D": [{"origin":[0,2]}, {"origin":[3,2]}]
}
# sac2(→) at (0,1): →→→ to (3,1). D2 at (3,2), sac2 goes right in row 1, never reaches row 2.
# Fix: D2 in row 1.
v2["D"] = [{"origin":[0,2]}, {"origin":[3,1]}]
# sac2(→) at (0,1): →→→ to (3,1)=D2. 3 right moves.
# But when →: sac2 AND who else? Nobody else has dir=right. Just sac2. OK.
# B2(←) at (3,2): → doesn't affect B2 (dir=left).
# Targets: id=1: (1,3). Only 1 target for 3 surviving id=1 blocks? Bad.
# 4 id=1 blocks - 2 sacs = 2 survivors. Need 2 targets.
v2["A"] = [
    [0,0], [1,0], [2,0], [3,0,1],
    [0,1], [1,1], [2,1], [3,1],
    [0,2], [1,2], [2,2], [3,2],
    [1,3,1], [2,3,2]
]
# targets id=1: (3,0), (1,3). 2 targets ✓
# B0(←) at (3,0): on own target! BAD.
v2["B"][2] = {"dir":"left", "id":1, "origin":[2,0]}
# B0(←) at (2,0) → (1,0)→(0,0). target? (3,0) is target but B0 goes LEFT. Can't reach.
# Fix: B0 goes to (0,0)? No target there.
# B0 can't reach (3,0) going left. Need different block/target.
# Let B1(↓) reach (1,3)✓ and someone else reach (3,0).
# B0(←) at (3,1)? → (2,1)→(1,1)→(0,1). No target.
# B0(↑) at (3,2)? → (3,1)→(3,0)✓. 2 up moves.
v2["B"][2] = {"dir":"up", "id":1, "origin":[3,2]}
# When ↑: only B0 moves (nobody else has dir=up).
# But B2(←) at (3,2): B0 ALSO at (3,2)? Can't have 2 blocks same cell!
# Move B2.
v2["B"][4] = {"dir":"left", "id":2, "origin":[2,2]}
# B2(←) at (2,2) → (1,2)→(0,2)=D1→dies if D1 not cleared!
# Another ordering constraint! D1 must be cleared before B2 goes ←←.
# ↓↓ clears D1. Then ←← for B2.
# But sac2 also needs →→→. And B0 needs ↑↑.
test(v2, "V2")


# V3: D blocks at (0,2) and (2,2), different column but same row
v3 = {
    "A": [
        [0,0], [1,0], [2,0], [3,0,1],
        [0,1], [1,1], [2,1], [3,1],
        [0,2], [1,2], [2,2], [3,2],
        [1,3,1], [2,3,2]
    ],
    "B": [
        {"dir":"down", "id":1, "origin":[0,0]},   # sac1 ↓↓ to D1(0,2)
        {"dir":"down", "id":1, "origin":[2,0]},   # sac2 ↓↓ to D2(2,2)
        {"dir":"up", "id":1, "origin":[3,2]},     # B0 ↑↑ to (3,0)✓
        {"dir":"down", "id":1, "origin":[1,0]},   # B1 ↓↓↓ to (1,3)✓
        {"dir":"left", "id":2, "origin":[3,1]},   # B2 ← to (2,3)✓
    ],
    "D": [{"origin":[0,2]}, {"origin":[2,2]}]
}
# When ↓: sac1, sac2, B1 ALL move.
# ↓1: sac1→(0,1), sac2→(2,1), B1→(1,1)
# ↓2: sac1→(0,2)=D1→dies, sac2→(2,2)=D2→dies, B1→(1,2)
# ↓3: B1→(1,3)✓
# Then ↑: B0(3,2)→(3,1) B2 at (3,1)! Push B2→(3,0)? target (3,0) is id=1, B2 is id=2. Pushed.
# ↑: B0(3,1)→(3,0)✓
# Then ←: B2 at... was pushed to (3,0) by ↑. B2(←) from (3,0)→(2,0)→(1,0)→(0,0). Target (2,3)?
# B2 can't reach (2,3) going left in row 0. BAD.
# What if B2 moves BEFORE ↑?
# ←: B2(3,1)→(2,1)→(1,1)→(0,1). After ↓ sac1 was at (0,1). If ↓ happened first, (0,1) occupied.
# If ← before ↓: B2(3,1)→(2,1). Then ↓: sac2(2,0)→(2,1) pushes B2→(2,2)=D2→dies!
# TRAP! ← before ↓ kills B2 on D2.
# Correct: ↓ first, then ← for B2, then ↑ for B0.
# After ↓↓↓: sac1 dead, sac2 dead, B1 at (1,3)✓. B0 at (3,2). B2 at (3,1).
# ←: B2(3,1)→(2,1). ←: B2(2,1)→(1,1). ←: B2(1,1)→(0,1). Target (2,3)? Not reachable.
# Hmm. B2 can't reach (2,3) going left.
# Fix: target id=2 reachable from B2's path. What about (0,1)?
v3["A"] = [
    [0,0], [1,0], [2,0], [3,0,1],
    [0,1,2], [1,1], [2,1], [3,1],
    [0,2], [1,2], [2,2], [3,2],
    [1,3,1], [2,3]
]
# B2(←) at (3,1) → ... → (0,1)✓ id=2 target.
# But after ↓↓: (0,1) has sac1 passed through (sac1 at (0,0)→(0,1)→(0,2)). After ↓2 sac1 is dead at (0,2). (0,1) is clear.
# ← needs to happen AFTER ↓↓ (when (0,1) is clear and D2 area safe).
# But if ← before ↓: B2 at (2,1) and sac2 pushes B2 onto D2. Trap!
test(v3, "V3")


# V4: Like V3 but with B0 having a longer path
v4 = {
    "A": [
        [0,0], [1,0], [2,0], [3,0],
        [0,1,2], [1,1], [2,1], [3,1,1],
        [0,2], [1,2], [2,2], [3,2],
        [1,3,1], [2,3]
    ],
    "B": [
        {"dir":"down", "id":1, "origin":[0,0]},   # sac1 ↓↓ to D1(0,2)
        {"dir":"down", "id":1, "origin":[2,0]},   # sac2 ↓↓ to D2(2,2)
        {"dir":"right", "id":1, "origin":[0,1]},  # B0 → along row 1 to (3,1)✓
        {"dir":"down", "id":1, "origin":[1,0]},   # B1 ↓↓↓ to (1,3)✓
        {"dir":"left", "id":2, "origin":[3,2]},   # B2 ← along row 2 to (0,1)? NO, row 2.
    ],
    "D": [{"origin":[0,2]}, {"origin":[2,2]}]
}
# B2(←) at (3,2) → (2,2)=D2→dies! If D2 not cleared.
# After D2 cleared: B2→(2,2)→(1,2)→(0,2)=D1? D1 also cleared. →(0,2). Target (0,1) is UP from (0,2).
# B2 goes LEFT not UP. Can't reach (0,1).
# Fix: B0(→) at (0,1) is on id=2 target(0,1). B0 is id=1. That's wrong-color. OK.
# B0 must move before B2 arrives... but B2 goes left in row 2, not row 1.
# B2 target: where? Add target in row 2.
v4["A"] = [
    [0,0], [1,0], [2,0], [3,0],
    [0,1], [1,1], [2,1], [3,1,1],
    [0,2,2], [1,2], [2,2], [3,2],
    [1,3,1], [2,3]
]
# B2(←) at (3,2) → (2,2)→(1,2)→(0,2)✓ id=2 target. Must clear both Ds first!
# B0(→) at (0,1): → to (1,1)→(2,1)→(3,1)✓
# When →: only B0 moves (sac2 is ↓, not →). B0(0,1)→(1,1).
# But when ↓: sac1(0,0)→(0,1). B0 at (0,1)? If B0 hasn't moved yet.
# Trap: ↓ before →: sac1→(0,1) pushes B0→(0,2)=D1→dies!
# Must: → first to clear B0 from (0,1), THEN ↓.
test(v4, "V4")


# V5: Add an extra interaction — B0 passes through sac2's column
v5 = {
    "A": [
        [0,0], [1,0], [2,0], [3,0],
        [0,1], [1,1], [2,1], [3,1,1],
        [0,2,2], [1,2], [2,2], [3,2],
        [1,3,1], [2,3]
    ],
    "B": [
        {"dir":"down", "id":1, "origin":[0,0]},   # sac1 ↓↓ to D1(0,2)
        {"dir":"down", "id":1, "origin":[2,0]},   # sac2 ↓↓ to D2(2,2)
        {"dir":"right", "id":1, "origin":[0,1]},  # B0 →→→ to (3,1)✓
        {"dir":"down", "id":1, "origin":[1,0]},   # B1 ↓↓↓ to (1,3)✓
        {"dir":"left", "id":2, "origin":[3,2]},   # B2 ←←← to (0,2)✓
    ],
    "D": [{"origin":[0,2]}, {"origin":[2,2]}]
}
# → first: B0(0,1)→(1,1). Safe — nothing at (1,1).
# →: B0(1,1)→(2,1). sac2 at (2,0) is ↓, not in row 1. (2,1) clear. B0 at (2,1).
# →: B0(2,1)→(3,1)✓
# ↓: sac1(0,0)→(0,1). sac2(2,0)→(2,1). B1(1,0)→(1,1).
# ↓: sac1(0,1)→(0,2)=D1→dies. sac2(2,1)→(2,2)=D2→dies. B1(1,1)→(1,2).
# ↓: B1(1,2)→(1,3)✓
# ←: B2(3,2)→(2,2) D2 cleared. Safe.
# ←: B2(2,2)→(1,2).
# ←: B2(1,2)→(0,2)✓ D1 cleared.
# Total: →→→↓↓↓←←← = 9 moves.
# Traps: ↓ before → pushes B0 off path. ← before ↓↓ hits D blocks.
test(v5, "V5")


# V6: Like V5 but tighter board (remove unused cells)
v6 = {
    "A": [
        [0,0], [1,0], [2,0], [3,0],
        [0,1], [1,1], [2,1], [3,1,1],
        [0,2,2], [1,2], [2,2],
        [1,3,1]
    ],
    "B": [
        {"dir":"down", "id":1, "origin":[0,0]},
        {"dir":"down", "id":1, "origin":[2,0]},
        {"dir":"right", "id":1, "origin":[0,1]},
        {"dir":"down", "id":1, "origin":[1,0]},
        {"dir":"left", "id":2, "origin":[2,2]},  # shorter B2 path
    ],
    "D": [{"origin":[0,2]}, {"origin":[2,2]}]
}
# B2 at (2,2) which is D2 location. Block on D cell. This means if B2 moves, it lives. But first move
# of the game: B2 is on D2, destroy collision only after movement. So B2 is fine at start.
# Actually, destroy collision: "_handle_destroy_collisions" — checks AFTER a move.
# At game start, blocks on D cells don't die. They're placed there intentionally.
# But this is unusual. Let me avoid it.
v6["B"][4] = {"dir":"left", "id":2, "origin":[3,1]}
# B2(←) at (3,1) on id=1 target. Wrong color. OK.
# B2(←) from (3,1)→(2,1)→(1,1)→(0,1). target (0,2) is ↓ from (0,1). B2 goes LEFT. Can't reach (0,2).
# Need target in row 1 for B2 or change direction.
# Fix: target id=2 at (0,1)
v6["A"] = [
    [0,0], [1,0], [2,0], [3,0],
    [0,1,2], [1,1], [2,1], [3,1,1],
    [0,2], [1,2], [2,2],
    [1,3,1]
]
# B2(←) at (3,1): on id=1 target. Wrong color. OK.
# B2 → (2,1)→(1,1)→(0,1)✓ id=2 target.
# But B0(→) at (0,1) is also going to (3,1). B0 at (0,1) starts on id=2 target — wrong color OK.
# When →: B0(0,1)→(1,1). B2 at (3,1) doesn't move (dir=←).
# When ←: B2(3,1)→(2,1). sac2 might be at (2,1) from ↓.
# Ordering: → then ↓ then ←.
test(v6, "V6 compact")


# V7: 15 cells, Z-shape with 2Ds in different rows
v7 = {
    "A": [
        [0,0], [1,0], [2,0], [3,0],
        [0,1], [1,1], [2,1], [3,1,1],
        [0,2,2], [1,2], [2,2], [3,2],
        [1,3,1], [2,3], [3,3]
    ],
    "B": [
        {"dir":"down", "id":1, "origin":[0,0]},   # sac1
        {"dir":"down", "id":1, "origin":[2,0]},   # sac2
        {"dir":"right", "id":1, "origin":[0,1]},  # B0 →→→ to (3,1)✓
        {"dir":"down", "id":1, "origin":[1,0]},   # B1 ↓↓↓ to (1,3)✓
        {"dir":"left", "id":2, "origin":[3,2]},   # B2 ←←← to (0,2)✓
    ],
    "D": [{"origin":[0,2]}, {"origin":[2,2]}]
}
test(v7, "V7 15cells")


# V8: Like V7 but B0 starts elsewhere for more interaction
v8 = {
    "A": [
        [0,0], [1,0], [2,0], [3,0],
        [0,1], [1,1], [2,1], [3,1],
        [0,2,2], [1,2], [2,2], [3,2,1],
        [1,3,1], [2,3], [3,3]
    ],
    "B": [
        {"dir":"down", "id":1, "origin":[0,0]},   # sac1
        {"dir":"down", "id":1, "origin":[2,0]},   # sac2
        {"dir":"down", "id":1, "origin":[3,0]},   # B0 ↓↓ to (3,2)✓
        {"dir":"down", "id":1, "origin":[1,0]},   # B1 ↓↓↓ to (1,3)✓
        {"dir":"left", "id":2, "origin":[3,2]},   # B2 ←←← to (0,2)✓. But B0 pushes B2?
    ],
    "D": [{"origin":[0,2]}, {"origin":[2,2]}]
}
# When ↓: ALL 4 id=1 blocks move (all dir=down)!
# ↓1: sac1→(0,1), sac2→(2,1), B0(3,0)→(3,1), B1(1,0)→(1,1)
# ↓2: sac1→(0,2)=D1→dies, sac2→(2,2)=D2→dies, B0(3,1)→(3,2) B2 at (3,2)! Push B2→(3,3). B1→(1,2).
# ↓3: B0(3,2)→(3,3) B2 at (3,3)! Push→(3,4)? No cell. B0 blocked. B1→(1,3)✓.
# B0 stuck at (3,2)✓ target! B0 at (3,2) which IS the target.
# B2 pushed to (3,3). B2(←) at (3,3) → (2,3)→(1,3) B1 there! Push B1→(0,3)?no cell(0,3 not in board).
# B2 blocked.
# Problem: B0 pushes B2 away from its path, and B2 can't get back.
# What if ← before ↓? B2(3,2)→(2,2)=D2→dies! Trap!
# The puzzle needs D2 cleared before B2 goes left. But D2 cleared on ↓2 which also pushes B2.
# Deadlock.
# Skip V8.


# V9: B2 starts in row 3, far from D blocks
v9 = {
    "A": [
        [0,0], [1,0], [2,0], [3,0],
        [0,1], [1,1], [2,1], [3,1,1],
        [0,2,2], [1,2], [2,2], [3,2],
        [1,3,1], [2,3], [3,3]
    ],
    "B": [
        {"dir":"down", "id":1, "origin":[0,0]},   # sac1
        {"dir":"down", "id":1, "origin":[2,0]},   # sac2
        {"dir":"right", "id":1, "origin":[0,1]},  # B0 → to (3,1)✓
        {"dir":"down", "id":1, "origin":[1,0]},   # B1 ↓ to (1,3)✓
        {"dir":"left", "id":2, "origin":[3,3]},   # B2 ← from (3,3) to (0,2)? Path: (3,3)→(2,3)→(1,3)→(0,3)?no cell.
    ],
    "D": [{"origin":[0,2]}, {"origin":[2,2]}]
}
# B2 path blocked. (0,3) doesn't exist. Target (0,2) in row 2 unreachable from row 3 going left.
# Fix: target in row 3 for id=2.
v9["A"] = [
    [0,0], [1,0], [2,0], [3,0],
    [0,1], [1,1], [2,1], [3,1,1],
    [0,2], [1,2], [2,2], [3,2],
    [1,3,1], [2,3,2], [3,3]
]
# B2(←) at (3,3) → (2,3)✓. 1 move. Too easy for B2.
# What if B2 at (3,2) going ← to (2,3)? Dir=left goes in row 2, not to (2,3).
# Let B2 have more interaction. B2(←) at (3,3)→(2,3)✓ then also B1 at (1,3)... no conflict.
# When ↓: sac1,sac2,B1 move. B0 is →. B2 is ←.
# ↓ first: sac1→(0,1) pushes B0? B0 at (0,1)! sac1(0,0)→(0,1) pushes B0→(0,2)=D1→B0 dies!
# TRAP! ↓ before → kills B0.
# Correct: → first to move B0 away, then ↓.
# →→→: B0(0,1)→(1,1)→(2,1)→(3,1)✓. 3 moves.
# ↓↓↓: sacs die, B1 to (1,3)✓. 3 moves.
# ←: B2(3,3)→(2,3)✓. 1 move.
# Total: 7 moves. Decent but maybe want more.
test(v9, "V9")


# V10: Like V9 but with B2 needing more moves and interaction with D area
v10 = {
    "A": [
        [0,0], [1,0], [2,0], [3,0],
        [0,1], [1,1], [2,1], [3,1,1],
        [0,2], [1,2], [2,2], [3,2],
        [1,3,1], [2,3], [3,3,2]
    ],
    "B": [
        {"dir":"down", "id":1, "origin":[0,0]},   # sac1
        {"dir":"down", "id":1, "origin":[2,0]},   # sac2
        {"dir":"right", "id":1, "origin":[0,1]},  # B0 →→→ to (3,1)✓
        {"dir":"down", "id":1, "origin":[1,0]},   # B1 ↓↓↓ to (1,3)✓
        {"dir":"left", "id":2, "origin":[3,2]},   # B2 ← through D area. Hits D2(2,2) if not cleared!
    ],
    "D": [{"origin":[0,2]}, {"origin":[2,2]}]
}
# B2(←) at (3,2): ←1: (3,2)→(2,2)=D2→dies if D2 not cleared!
# TRAP: ← before ↓↓ kills B2.
# After ↓↓: D2 cleared. B2(3,2)→(2,2)→(1,2)→(0,2)=D1 cleared too.→(0,2). Not a target for id=2.
# target (3,3) is id=2. B2 goes LEFT, can't reach (3,3).
# Fix: target in B2's left path.
v10["A"] = [
    [0,0], [1,0], [2,0], [3,0],
    [0,1], [1,1], [2,1], [3,1,1],
    [0,2,2], [1,2], [2,2], [3,2],
    [1,3,1], [2,3], [3,3]
]
# B2(←) at (3,2)→(2,2)→(1,2)→(0,2)✓ id=2 target.
# TRIPLE TRAP:
# 1. ↓ before →: sac1 pushes B0 onto D1
# 2. ← before ↓↓: B2 hits D2
# 3. → too late: B0 stuck at (0,1) when sac1 arrives
test(v10, "V10 triple trap")
