#!/usr/bin/env python3
import subprocess
import os
import sys

def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    swift_script = os.path.join(script_dir, "generate_icon.swift")
    res = subprocess.run(["swift", swift_script])
    sys.exit(res.returncode)

if __name__ == "__main__":
    main()
