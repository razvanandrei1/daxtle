#!/usr/bin/env python3
"""Add 5 more hard challenge levels."""

import json, os

BASE = os.path.join(os.path.dirname(__file__), "..", "levels", "challenge", "hard")

# Pick 5 with best variety: mix of 6 and 7 moves, different mechanics
new_hard = [
    # H1: 6 moves, 4 blocks + D, 2 colors
    {"A":[[0,0],[0,1],[0,2],[1,0],[1,1],[1,2,1],[2,0],[2,1,2],[2,2],[3,0],[3,1,2],[3,2]],"B":[{"dir":"right","id":2,"origin":[1,1]},{"dir":"up","id":1,"origin":[0,2]},{"dir":"left","id":1,"origin":[3,2]},{"dir":"down","id":2,"origin":[2,0]}],"difficulty":3,"D":[{"origin":[0,0]}]},
    # H5: 7 moves, 3 blocks + D, push chain
    {"A":[[0,0],[0,1],[0,2,1],[1,0],[1,1],[1,2],[2,0],[2,1],[2,2],[3,0],[3,1],[3,2,2]],"B":[{"dir":"down","id":2,"origin":[3,0]},{"dir":"right","id":1,"origin":[0,0]},{"dir":"left","id":1,"origin":[3,1]}],"difficulty":3,"D":[{"origin":[2,0]}]},
    # H6: 6 moves, 4 blocks + D, 3x4 board
    {"A":[[0,0,2],[0,1],[0,2],[0,3],[1,0,2],[1,1],[1,2,1],[1,3],[2,0],[2,1],[2,2],[2,3]],"B":[{"dir":"left","id":1,"origin":[2,2]},{"dir":"up","id":2,"origin":[1,3]},{"dir":"right","id":2,"origin":[0,1]},{"dir":"down","id":1,"origin":[2,0]}],"difficulty":3,"D":[{"origin":[2,1]}]},
    # H7: 6 moves, 4 blocks, no D
    {"A":[[0,0],[0,1],[0,2],[1,0],[1,1,2],[1,2],[2,0],[2,1],[2,2,1],[3,0,1],[3,1],[3,2,2]],"B":[{"dir":"right","id":1,"origin":[0,0]},{"dir":"up","id":2,"origin":[1,2]},{"dir":"down","id":1,"origin":[2,0]},{"dir":"down","id":2,"origin":[3,1]}],"difficulty":3},
    # H8: 7 moves, 4 blocks + D, wide board
    {"A":[[1,3],[3,0,2],[1,1],[3,3,1],[2,0],[0,0,2],[3,1],[0,2],[0,1],[2,3],[0,3],[3,2],[1,0],[2,1]],"B":[{"dir":"down","id":1,"origin":[1,0]},{"dir":"up","id":2,"origin":[3,1]},{"dir":"right","id":1,"origin":[0,3]},{"dir":"left","id":2,"origin":[2,0]}],"difficulty":3,"D":[{"origin":[1,1]}]},
]

existing = [f for f in os.listdir(BASE) if f.endswith(".json")]
start_num = len(existing) + 1

for i, data in enumerate(new_hard):
    num = start_num + i
    path = os.path.join(BASE, f"challenge_{num:03d}.json")
    with open(path, "w") as f:
        json.dump(data, f, separators=(",", ":"))
    print(f"Created hard/challenge_{num:03d}.json")

print(f"\nHard levels: {len(existing)} → {len(existing) + len(new_hard)}")
