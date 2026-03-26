#!/usr/bin/env python3
"""Brute-force generator for challenge levels."""

import sys, os, json, random
sys.path.insert(0, os.path.dirname(__file__))
from solve_levels import parse_level, solve

random.seed(42)
DIRS = ["left", "right", "up", "down"]

def gen_board(w, h, holes=0):
    cells = [(x,y) for x in range(w) for y in range(h)]
    if holes > 0:
        random.shuffle(cells)
        cells = cells[holes:]
    return cells

def try_level(board_cells, n_blocks, n_colors, has_d=False):
    """Try to generate a random level. Returns (data, moves) or None."""
    cells = list(board_cells)
    if len(cells) < n_blocks + 2:
        return None

    # Pick target cells (1-2 per color)
    random.shuffle(cells)
    targets = {}
    for cid in range(1, n_colors+1):
        # Each color gets 1-2 targets based on how many blocks of that color
        pass

    # Assign blocks
    block_colors = []
    for i in range(n_blocks):
        block_colors.append((i % n_colors) + 1)
    random.shuffle(block_colors)

    # Count blocks per color
    color_counts = {}
    for c in block_colors:
        color_counts[c] = color_counts.get(c, 0) + 1

    # Pick positions for blocks (avoid duplicates)
    random.shuffle(cells)
    block_positions = cells[:n_blocks]

    # Pick target cells for each color
    remaining = [c for c in cells if c not in block_positions]
    random.shuffle(remaining)

    A = []
    target_cells = {}
    idx = 0
    for cid in range(1, n_colors+1):
        needed = color_counts.get(cid, 0)
        if has_d and cid == 1:
            needed -= 1  # one will die on D
        if needed <= 0:
            continue
        for _ in range(needed):
            if idx >= len(remaining):
                return None
            target_cells[remaining[idx]] = cid
            idx += 1

    # Build A array
    for cell in board_cells:
        if cell in target_cells:
            A.append([cell[0], cell[1], target_cells[cell]])
        else:
            A.append([cell[0], cell[1]])

    # Build B array
    B = []
    for i, pos in enumerate(block_positions):
        cid = block_colors[i]
        d = random.choice(DIRS)
        # Check block doesn't start on own-color target
        if target_cells.get(pos) == cid:
            return None
        B.append({"dir": d, "id": cid, "origin": [pos[0], pos[1]]})

    data = {"A": A, "B": B, "difficulty": 2}

    # Add D block
    if has_d:
        d_candidates = [c for c in board_cells if c not in block_positions and c not in target_cells]
        if not d_candidates:
            return None
        d_pos = random.choice(d_candidates)
        data["D"] = [{"origin": [d_pos[0], d_pos[1]]}]

    # Solve
    board, blocks, teleport_map, destroy_set = parse_level(data)
    solution = solve(board, blocks, teleport_map, destroy_set)
    if solution is None:
        return None
    return data, len(solution), solution


# Generate many and keep good ones
medium_results = []  # (data, moves, solution)
hard_results = []

configs = [
    # (width, height, holes, n_blocks, n_colors, has_d)
    (3, 3, 0, 2, 1, False),
    (3, 3, 0, 2, 2, False),
    (3, 3, 0, 3, 2, False),
    (3, 3, 1, 3, 2, False),
    (4, 2, 0, 3, 2, False),
    (4, 3, 0, 3, 2, False),
    (4, 3, 2, 3, 2, False),
    (3, 3, 0, 3, 2, True),
    (3, 4, 0, 3, 2, True),
    (4, 3, 0, 4, 2, True),
    (4, 3, 1, 4, 2, True),
    (3, 3, 0, 4, 2, True),
    (4, 3, 0, 4, 2, False),
    (4, 2, 0, 3, 1, False),
    (3, 4, 0, 4, 2, False),
    (3, 4, 1, 3, 2, True),
]

attempts = 0
for w, h, holes, nb, nc, hd in configs:
    board = gen_board(w, h, holes)
    for _ in range(500):
        attempts += 1
        result = try_level(board, nb, nc, hd)
        if result is None:
            continue
        data, moves, solution = result
        from solve_levels import ARROWS
        arrows = " ".join(ARROWS[d] for d in solution)

        if 4 <= moves <= 5 and len(medium_results) < 10:
            medium_results.append((data, moves, arrows))
        elif 6 <= moves <= 8 and len(hard_results) < 10:
            hard_results.append((data, moves, arrows))

        if len(medium_results) >= 10 and len(hard_results) >= 10:
            break
    if len(medium_results) >= 10 and len(hard_results) >= 10:
        break

print(f"Attempts: {attempts}")
print(f"\n=== MEDIUM ({len(medium_results)} found) ===")
for i, (data, moves, arrows) in enumerate(medium_results):
    print(f"  M{i+1} ({moves} moves): {arrows}")
    print(f"    {json.dumps(data, separators=(',',':'))}")

print(f"\n=== HARD ({len(hard_results)} found) ===")
for i, (data, moves, arrows) in enumerate(hard_results):
    print(f"  H{i+1} ({moves} moves): {arrows}")
    print(f"    {json.dumps(data, separators=(',',':'))}")
