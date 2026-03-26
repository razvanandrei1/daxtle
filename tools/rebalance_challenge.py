#!/usr/bin/env python3
"""Rebalance challenge levels: fix broken ones, reclassify by move count.
Easy: 2-3 moves, Medium: 4-5 moves, Hard: 6-8 moves."""

import json, os, shutil, sys
sys.path.insert(0, os.path.dirname(__file__))
from solve_levels import parse_level, solve

BASE = os.path.join(os.path.dirname(__file__), "..", "levels", "challenge")

# Step 1: Read all levels and solve them
all_levels = []
for tier in ["easy", "medium", "hard"]:
    tier_dir = os.path.join(BASE, tier)
    for fname in sorted(os.listdir(tier_dir)):
        if not fname.endswith(".json"):
            continue
        path = os.path.join(tier_dir, fname)
        with open(path) as f:
            data = json.load(f)
        board, blocks, teleport_map, destroy_set = parse_level(data)
        solution = solve(board, blocks, teleport_map, destroy_set)
        if solution is None:
            print(f"SKIP (unsolvable): {tier}/{fname}")
            continue
        moves = len(solution)
        if moves > 8:
            print(f"SKIP (>{8} moves): {tier}/{fname} ({moves} moves)")
            continue
        # Determine new tier
        if moves <= 3:
            new_tier = "easy"
        elif moves <= 5:
            new_tier = "medium"
        else:
            new_tier = "hard"
        if new_tier != tier:
            print(f"RECLASSIFY: {tier}/{fname} ({moves} moves) → {new_tier}")
        all_levels.append({
            "data": data,
            "moves": moves,
            "new_tier": new_tier,
            "old": f"{tier}/{fname}",
        })

# Step 2: Group by new tier
tiers = {"easy": [], "medium": [], "hard": []}
for level in all_levels:
    tiers[level["new_tier"]].append(level)

# Sort within each tier by move count
for tier in tiers:
    tiers[tier].sort(key=lambda l: l["moves"])

print(f"\n{'='*50}")
print(f"RESULT:")
print(f"  Easy:   {len(tiers['easy'])} levels (was 15)")
print(f"  Medium: {len(tiers['medium'])} levels (was 28)")
print(f"  Hard:   {len(tiers['hard'])} levels (was 17)")
print(f"  Total:  {sum(len(v) for v in tiers.values())} (was 60)")
print(f"{'='*50}")

# Step 3: Write files (only if --write flag passed)
if "--write" in sys.argv:
    for tier_name, levels in tiers.items():
        tier_dir = os.path.join(BASE, tier_name)
        # Clear existing files
        for f in os.listdir(tier_dir):
            if f.endswith(".json"):
                os.remove(os.path.join(tier_dir, f))
        # Write new files with correct difficulty tag
        diff_num = {"easy": 1, "medium": 2, "hard": 3}[tier_name]
        for i, level in enumerate(levels, 1):
            data = level["data"]
            data["difficulty"] = diff_num
            out_path = os.path.join(tier_dir, f"challenge_{i:03d}.json")
            with open(out_path, "w") as f:
                json.dump(data, f, separators=(",", ":"))
            print(f"  Wrote {tier_name}/challenge_{i:03d}.json ({level['moves']} moves, from {level['old']})")
    print("\nDone! Files written.")
else:
    print("\nDry run. Pass --write to apply changes.")
