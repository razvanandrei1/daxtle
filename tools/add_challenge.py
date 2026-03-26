#!/usr/bin/env python3
"""Add selected new challenge levels to the folders."""

import json, os

BASE = os.path.join(os.path.dirname(__file__), "..", "levels", "challenge")

# 5 best medium (4-5 moves, varied mechanics)
new_medium = [
    # M1: 4 moves, 2 blocks, clean push
    {"A":[[0,0],[0,1],[0,2],[1,0],[1,1],[1,2],[2,0,2],[2,1,1],[2,2]],"B":[{"dir":"right","id":1,"origin":[0,1]},{"dir":"up","id":2,"origin":[1,2]}],"difficulty":2},
    # M2: 4 moves, 3 blocks, ordering
    {"A":[[0,0,1],[0,1],[0,2,1],[1,0],[1,1],[1,2,2],[2,0],[2,1],[2,2]],"B":[{"dir":"left","id":1,"origin":[1,1]},{"dir":"down","id":2,"origin":[1,0]},{"dir":"left","id":1,"origin":[2,0]}],"difficulty":2},
    # M3: 5 moves, 3 blocks, wider board
    {"A":[[0,0],[0,1],[0,2],[1,0],[1,1],[1,2,1],[2,0],[2,1],[2,2],[3,0,2],[3,1],[3,2,1]],"B":[{"dir":"down","id":1,"origin":[3,1]},{"dir":"right","id":2,"origin":[0,0]},{"dir":"left","id":1,"origin":[2,2]}],"difficulty":2},
    # M5: 4 moves, 3 blocks + D block
    {"A":[[0,0],[0,1],[0,2],[1,0],[1,1,1],[1,2],[2,0,2],[2,1],[2,2]],"B":[{"dir":"up","id":2,"origin":[2,2]},{"dir":"down","id":1,"origin":[1,0]},{"dir":"left","id":1,"origin":[2,1]}],"difficulty":2,"D":[{"origin":[0,1]}]},
    # M10: 4 moves, 3 blocks, 4x2
    {"A":[[0,0],[0,1],[1,0,1],[1,1],[2,0],[2,1,1],[3,0],[3,1,1]],"B":[{"dir":"left","id":1,"origin":[3,0]},{"dir":"right","id":1,"origin":[1,1]},{"dir":"down","id":1,"origin":[2,0]}],"difficulty":2},
]

# 5 best hard (6-8 moves, complex mechanics)
new_hard = [
    # H1: 6 moves, 3 blocks, ordering trap
    {"A":[[0,0,1],[0,1],[0,2,2],[1,0],[1,1],[1,2],[2,0,1],[2,1],[2,2]],"B":[{"dir":"left","id":2,"origin":[2,2]},{"dir":"up","id":1,"origin":[1,2]},{"dir":"right","id":1,"origin":[0,1]}],"difficulty":3},
    # H2: 6 moves, 4 blocks + D
    {"A":[[1,2],[3,1,2],[3,0],[1,1],[2,2],[2,0],[2,1,1],[1,0],[0,2,2],[0,1],[0,0]],"B":[{"dir":"down","id":2,"origin":[1,1]},{"dir":"right","id":1,"origin":[0,1]},{"dir":"left","id":2,"origin":[2,2]},{"dir":"up","id":1,"origin":[1,2]}],"difficulty":3,"D":[{"origin":[0,0]}]},
    # H3: 7 moves, 4 blocks + D
    {"A":[[1,2],[3,1],[3,0],[1,1],[2,2],[2,0,2],[2,1],[1,0],[0,2],[0,1,2],[0,0,1]],"B":[{"dir":"up","id":2,"origin":[2,2]},{"dir":"left","id":1,"origin":[3,1]},{"dir":"down","id":1,"origin":[1,0]},{"dir":"up","id":2,"origin":[0,2]}],"difficulty":3,"D":[{"origin":[1,2]}]},
    # H4: 6 moves, 3 blocks, push chain
    {"A":[[0,0],[0,1],[1,0,1],[1,1,1],[2,0],[2,1],[3,0,1],[3,1]],"B":[{"dir":"left","id":1,"origin":[3,1]},{"dir":"right","id":1,"origin":[0,0]},{"dir":"up","id":1,"origin":[2,1]}],"difficulty":3},
    # H5: 6 moves, 3 blocks + D
    {"A":[[2,0],[2,3],[2,2],[0,3],[1,3],[0,1],[2,1],[1,0,2],[1,2,1],[0,2],[1,1]],"B":[{"dir":"left","id":1,"origin":[2,2]},{"dir":"right","id":1,"origin":[0,3]},{"dir":"up","id":2,"origin":[1,3]}],"difficulty":3,"D":[{"origin":[2,3]}]},
]

# Add to folders
for tier, levels in [("medium", new_medium), ("hard", new_hard)]:
    tier_dir = os.path.join(BASE, tier)
    existing = [f for f in os.listdir(tier_dir) if f.endswith(".json")]
    start_num = len(existing) + 1
    for i, data in enumerate(levels):
        num = start_num + i
        path = os.path.join(tier_dir, f"challenge_{num:03d}.json")
        with open(path, "w") as f:
            json.dump(data, f, separators=(",", ":"))
        print(f"Created {tier}/challenge_{num:03d}.json")

print("\nDone!")
