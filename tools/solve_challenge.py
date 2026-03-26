#!/usr/bin/env python3
"""Solve all challenge levels and report move counts."""

import json, os, sys
sys.path.insert(0, os.path.dirname(__file__))
from solve_levels import parse_level, solve, ARROWS

BASE = os.path.join(os.path.dirname(__file__), "..", "levels", "challenge")

for tier in ["easy", "medium", "hard"]:
    tier_dir = os.path.join(BASE, tier)
    files = sorted(f for f in os.listdir(tier_dir) if f.endswith(".json"))
    print(f"\n{'='*60}")
    print(f"  {tier.upper()} ({len(files)} levels)")
    print(f"{'='*60}")
    over8 = 0
    for fname in files:
        path = os.path.join(tier_dir, fname)
        with open(path) as f:
            data = json.load(f)
        board, blocks, teleport_map, destroy_set = parse_level(data)
        solution = solve(board, blocks, teleport_map, destroy_set)
        if solution is None:
            flag = " *** NO SOLUTION ***"
            print(f"  {fname}: {flag}")
        else:
            n = len(solution)
            flag = " *** OVER 8 ***" if n > 8 else ""
            arrows = " ".join(ARROWS[d] for d in solution)
            if flag:
                over8 += 1
            print(f"  {fname} ({n:2d} moves): {arrows}{flag}")
    if over8:
        print(f"  >> {over8} levels exceed 8 moves")
