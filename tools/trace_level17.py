#!/usr/bin/env python3
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from trace_level import trace

s3 = {
    "A": [
        [0,0], [1,0], [2,0], [3,0,1],
        [1,1,2], [2,1,3], [3,1],
        [1,2], [2,2], [3,2],
        [0,3], [1,3], [2,3]
    ],
    "B": [
        {"dir":"right", "id":1, "origin":[0,0]},
        {"dir":"left", "id":2, "origin":[3,1]},
        {"dir":"up", "id":3, "origin":[2,3]},
        {"dir":"down", "id":1, "origin":[2,0]},
    ],
    "D": [{"origin":[2,2]}]
}

# BFS solution
solution = ["left","left","right","down","right","right","down","up","up"]
trace(s3, solution)
