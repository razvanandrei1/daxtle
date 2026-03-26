#!/usr/bin/env python3
"""BFS solver for Daxtle levels — mirrors PuzzleSolver.gd logic."""

import json, os, sys
from collections import deque

MAX_DEPTH = 20
DIRS = {"right": (1, 0), "left": (-1, 0), "down": (0, 1), "up": (0, -1)}
ARROWS = {"right": "\u2192", "left": "\u2190", "down": "\u2193", "up": "\u2191"}


def load_level(path):
    with open(path) as f:
        return json.load(f)


def parse_level(data):
    board = set()
    targets = {}  # (x,y) -> block_id
    for cell in data["A"]:
        pos = (cell[0], cell[1])
        board.add(pos)
        if len(cell) == 3:
            targets[pos] = cell[2]

    blocks = []
    for b in data.get("B", []):
        blocks.append({
            "id": b["id"],
            "dir": b["dir"],
            "origin": tuple(b["origin"]),
        })

    teleport_map = {}
    for t in data.get("T", []):
        a = (t["pos"][0], t["pos"][1])
        b = (t["pos"][2], t["pos"][3])
        teleport_map[a] = b
        teleport_map[b] = a

    destroy_set = set()
    for d in data.get("D", []):
        destroy_set.add(tuple(d["origin"]))

    # Build target_origins per block index
    target_by_id = {}
    for pos, bid in targets.items():
        target_by_id.setdefault(bid, []).append(pos)

    for b in blocks:
        b["targets"] = set(target_by_id.get(b["id"], []))

    return board, blocks, teleport_map, destroy_set


def encode_state(positions, alive, destroy):
    parts = []
    for i, pos in enumerate(positions):
        if alive[i]:
            parts.append(f"{pos[0]},{pos[1]}")
        else:
            parts.append("X")
    for d in sorted(destroy):
        parts.append(f"D{d[0]},{d[1]}")
    return "|".join(parts)


def check_win(positions, alive, blocks):
    for i, b in enumerate(blocks):
        if not alive[i]:
            continue
        if positions[i] not in b["targets"]:
            return False
    return True


def try_push(idx, dv, positions, alive, board, fixed, teleport_map, occupied):
    """Try to move block idx by dv. Returns new positions list or None."""
    if not alive[idx]:
        return None
    dest = (positions[idx][0] + dv[0], positions[idx][1] + dv[1])
    if dest not in board:
        return None

    new_positions = list(positions)

    if dest in occupied:
        other = occupied[dest]
        result = try_push(other, dv, new_positions, alive, board, fixed, teleport_map, occupied)
        if result is None:
            return None
        new_positions = result

    # Handle teleport
    if dest in teleport_map:
        exit_cell = teleport_map[dest]
        cont = (exit_cell[0] + dv[0], exit_cell[1] + dv[1])
        # Check if cont cell is available
        cont_occupied = any(new_positions[j] == cont and alive[j] for j in range(len(new_positions)) if j != idx)
        if cont in board and not cont_occupied and cont not in teleport_map:
            new_positions[idx] = cont
        else:
            exit_occupied = any(new_positions[j] == exit_cell and alive[j] for j in range(len(new_positions)) if j != idx)
            if not exit_occupied:
                new_positions[idx] = exit_cell
            else:
                return None
    else:
        new_positions[idx] = dest

    return new_positions


def simulate_move(positions, alive, blocks, direction, board, fixed, teleport_map, destroy):
    dv = DIRS[direction]

    # Find movers (blocks matching direction)
    movers = [i for i, b in enumerate(blocks) if alive[i] and b["dir"] == direction]
    if not movers:
        return None

    # Sort front-to-back
    movers.sort(key=lambda i: -(positions[i][0] * dv[0] + positions[i][1] * dv[1]))

    new_positions = list(positions)
    any_moved = False

    for mi in movers:
        occupied = {}
        for j in range(len(new_positions)):
            if alive[j] and j != mi:
                occupied[new_positions[j]] = j

        result = try_push(mi, dv, new_positions, alive, board, fixed, teleport_map, occupied)
        if result is not None:
            new_positions = result
            any_moved = True

    if not any_moved:
        return None

    # Handle destroy collisions
    new_alive = list(alive)
    new_destroy = set(destroy)
    for i in range(len(new_positions)):
        if new_alive[i] and new_positions[i] in new_destroy:
            new_alive[i] = False
            new_destroy.discard(new_positions[i])

    return tuple(new_positions), tuple(new_alive), frozenset(new_destroy)


def solve(board, blocks, teleport_map, destroy_set):
    positions = tuple(b["origin"] for b in blocks)
    alive = tuple(True for _ in blocks)
    destroy = frozenset(destroy_set)

    if check_win(positions, alive, blocks):
        return []

    initial_state = encode_state(positions, alive, destroy)
    visited = {initial_state}
    queue = deque()
    queue.append((positions, alive, destroy, []))

    while queue:
        positions, alive, destroy, path = queue.popleft()
        if len(path) >= MAX_DEPTH:
            continue

        for d in ["left", "right", "up", "down"]:
            result = simulate_move(positions, alive, blocks, d, board, set(), teleport_map, destroy)
            if result is None:
                continue
            new_pos, new_alive, new_destroy = result
            state = encode_state(new_pos, new_alive, new_destroy)
            if state in visited:
                continue
            visited.add(state)
            new_path = path + [d]
            if check_win(new_pos, new_alive, blocks):
                return new_path
            queue.append((new_pos, new_alive, new_destroy, new_path))

    return None


def main():
    levels_dir = os.path.join(os.path.dirname(__file__), "..", "levels")
    for i in range(1, 100):
        path = os.path.join(levels_dir, f"level_{i:03d}.json")
        if not os.path.exists(path):
            break
        data = load_level(path)
        board, blocks, teleport_map, destroy_set = parse_level(data)
        solution = solve(board, blocks, teleport_map, destroy_set)
        if solution is None:
            print(f"Level {i:2d}: NO SOLUTION FOUND")
        else:
            arrows = " ".join(ARROWS[d] for d in solution)
            dirs = " ".join(solution)
            print(f"Level {i:2d} ({len(solution):2d} moves): {arrows}")
            print(f"          {dirs}")


if __name__ == "__main__":
    main()
