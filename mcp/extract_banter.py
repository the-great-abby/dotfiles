#!/usr/bin/env python3
"""Extract banter from auto-suggest JSON output."""
import json
import sys

try:
    data = json.load(sys.stdin)
    banter = data.get("banter", "")
    if banter and banter != "None":
        print(banter)
except:
    pass

