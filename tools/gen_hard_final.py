#!/usr/bin/env python3
"""Generate 5 more hard challenge levels (6-8 moves)."""

import sys, os, json, random
sys.path.insert(0, os.path.dirname(__file__))
from solve_levels import parse_level, solve, ARROWS

random.seed(99)
DIRS = ["left", "right", "up", "down"]

def gen_board(w, h, holes=0):
    cells = [(x,y) for x in range(w) for y in range(h)]
    if holes > 0:
        random.shuffle(cells)
        cells = cells[holes:]
    return cells

def try_level(board_cells, n_blocks, n_colors, has_d=False):
    cells = list(board_cells)
    if len(cells) < n_blocks + 2:
        return None
    block_colors = []
    for i in range(n_blocks):
        block_colors.append((i % n_colors) + 1)
    random.shuffle(block_colors)
    color_counts = {}
    for c in block_colors:
        color_counts[c] = color_counts.get(c, 0) + 1
    random.shuffle(cells)
    block_positions = cells[:n_blocks]
    remaining = [c for c in cells if c not in block_positions]
    random.shuffle(remaining)
    A = []
    target_cells = {}
    idx = 0
    for cid in range(1, n_colors+1):
        needed = color_counts.get(cid, 0)
        if has_d and cid == 1:
            needed -= 1
        if needed <= 0:
            continue
        for _ in range(needed):
            if idx >= len(remaining):
                return None
            target_cells[remaining[idx]] = cid
            idx += 1
    for cell in board_cells:
        if cell in target_cells:
            A.append([cell[0], cell[1], target_cells[cell]])
        else:
            A.append([cell[0], cell[1]])
    B = []
    for i, pos in enumerate(block_positions):
        cid = block_colors[i]
        d = random.choice(DIRS)
        if target_cells.get(pos) == cid:
            return None
        B.append({"dir": d, "id": cid, "origin": [pos[0], pos[1]]})
    data = {"A": A, "B": B, "difficulty": 3}
    if has_d:
        d_candidates = [c for c in board_cells if c not in block_positions and c not in target_cells]
        if not d_candidates:
            return None
        d_pos = random.choice(d_candidates)
        data["D"] = [{"origin": [d_pos[0], d_pos[1]]}]
    board, blocks, teleport_map, destroy_set = parse_level(data)
    solution = solve(board, blocks, teleport_map, destroy_set)
    if solution is None:
        return None
    return data, len(solution), solution

configs = [
    (3, 3, 0, 3, 2, True),
    (3, 3, 1, 3, 2, True),
    (3, 4, 0, 3, 2, True),
    (3, 4, 1, 3, 2, True),
    (4, 3, 0, 4, 2, True),
    (4, 3, 1, 4, 2, True),
    (4, 3, 0, 3, 2, True),
    (4, 3, 2, 4, 2, True),
    (3, 4, 0, 4, 2, True),
    (3, 4, 2, 4, 2, True),
    (4, 3, 0, 4, 2, False),
    (3, 3, 0, 3, 2, False),
    (4, 4, 2, 4, 2, True),
    (4, 4, 3, 4, 2, True),
    (5, 3, 0, 4, 2, True),
    (5, 3, 2, 4, 2, True),
    (3, 3, 0, 4, 2, True),
    (3, 4, 1, 4, 2, True),
]

results = []
seen = set()

for w, h, holes, nb, nc, hd in configs:
    board = gen_board(w, h, holes)
    for _ in range(2000):
        result = try_level(board, nb, nc, hd)
        if result is None:
            continue
        data, moves, solution = result
        if 6 <= moves <= 8:
            key = json.dumps(data, sort_keys=True)
            if key not in seen:
                seen.add(key)
                arrows = " ".join(ARROWS[d] for d in solution)
                results.append((data, moves, arrows))
                print(f"Found H{len(results)} ({moves} moves): {arrows}")
                if len(results) >= 10:
                    break
    if len(results) >= 10:
        break

print(f"\nTotal found: {len(results)}")
for i, (data, moves, arrows) in enumerate(results):
    print(f"\nH{i+1} ({moves} moves): {arrows}")
    print(f"  {json.dumps(data, separators=(',',':'))}")
