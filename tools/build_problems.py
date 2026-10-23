"""Build each problem's problem.json from its problem.toml.

Authors edit problem.toml (readable multi-line text). The skill reads
problem.json, because the TOML parser in the standard library needs Python
3.11 and students' computers may have an older Python (macOS ships 3.9).

    uv run python tools/build_problems.py          # rebuild
    uv run python tools/build_problems.py --check  # fail if any JSON is stale
"""

from __future__ import annotations

import argparse
import json
import sys
import tomllib
from pathlib import Path

PROBLEMS = Path(__file__).resolve().parents[1] / "plugin/skills/compbio-tutor/problems"


def render(toml_path: Path) -> str:
    data = tomllib.loads(toml_path.read_text(encoding="utf-8"))
    return json.dumps(data, indent=2, ensure_ascii=False) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--check", action="store_true", help="report stale files, change nothing")
    args = parser.parse_args()
    stale = []
    for toml_path in sorted(PROBLEMS.glob("*/problem.toml")):
        json_path = toml_path.with_suffix(".json")
        text = render(toml_path)
        current = json_path.read_text(encoding="utf-8") if json_path.exists() else None
        if current != text:
            stale.append(json_path)
            if not args.check:
                json_path.write_text(text, encoding="utf-8")
    if args.check and stale:
        print("Stale problem.json files (run tools/build_problems.py):")
        for path in stale:
            print(f"  {path}")
        return 1
    if not args.check:
        print(f"Rebuilt {len(stale)} problem.json file(s).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
