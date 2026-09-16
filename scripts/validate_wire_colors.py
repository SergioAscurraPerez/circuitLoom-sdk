#!/usr/bin/env python3
"""Checks every wire in the repo's circuit examples against the standard
electronics color convention: red for anything touching a power pin, black
for anything touching a ground pin. See docs/components.md#wire-color-convention.
"""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
EXAMPLES_DIRS = [
    ROOT / "schema" / "v1" / "examples",
    ROOT / "examples" / "hello_circuit" / "circuits",
]

EXPECTED_COLOR_BY_ROLE = {"power": "red", "ground": "black"}


def main() -> int:
    had_errors = False
    for examples_dir in EXAMPLES_DIRS:
        for path in sorted(examples_dir.glob("*.json")):
            errors = _check_file(path)
            if errors:
                had_errors = True
                print(f"FAIL {path.relative_to(ROOT)}")
                for error in errors:
                    print(f"  - {error}")
            else:
                print(f"OK   {path.relative_to(ROOT)}")

    return 1 if had_errors else 0


def _check_file(path: Path) -> list[str]:
    doc = json.loads(path.read_text(encoding="utf-8"))
    circuit = doc["circuit"]
    pin_roles = {
        (node["id"], pin["id"]): pin["role"]
        for node in circuit["nodes"]
        for pin in node["pins"]
    }

    errors = []
    for edge in circuit.get("edges", []):
        wire_color = edge.get("wire_color")
        if wire_color is None:
            continue

        expected_colors = set()
        for endpoint in (edge["from"], edge["to"]):
            role = pin_roles.get((endpoint["node_id"], endpoint["pin_id"]))
            expected = EXPECTED_COLOR_BY_ROLE.get(role)
            if expected is not None:
                expected_colors.add(expected)

        # A wire touching both a power and a ground pin (a dead short) can't
        # satisfy both colors at once — that IS the fault being depicted, so
        # matching either expected color is accepted rather than flagged.
        if expected_colors and wire_color not in expected_colors:
            errors.append(
                f"edge {edge['id']}: wire_color is '{wire_color}', expected "
                f"one of {sorted(expected_colors)}"
            )
    return errors


if __name__ == "__main__":
    sys.exit(main())
