#!/usr/bin/env python3
import json
import sys
from pathlib import Path

from jsonschema import Draft202012Validator

ROOT = Path(__file__).resolve().parent.parent
SCHEMA_PATH = ROOT / "schema" / "v1" / "circuit-graph.schema.json"
EXAMPLES_DIRS = [
    ROOT / "schema" / "v1" / "examples",
    ROOT / "examples" / "hello_circuit" / "circuits",
]


def main() -> int:
    schema = json.loads(SCHEMA_PATH.read_text(encoding="utf-8"))
    validator = Draft202012Validator(schema)

    examples = sorted(
        path for examples_dir in EXAMPLES_DIRS for path in examples_dir.glob("*.json")
    )
    if not examples:
        print(f"No example files found in {EXAMPLES_DIRS}")
        return 1

    had_errors = False
    for example_path in examples:
        instance = json.loads(example_path.read_text(encoding="utf-8"))
        errors = sorted(validator.iter_errors(instance), key=lambda e: e.path)
        if errors:
            had_errors = True
            print(f"FAIL {example_path.relative_to(ROOT)}")
            for error in errors:
                location = "/".join(str(p) for p in error.path) or "<root>"
                print(f"  - {location}: {error.message}")
        else:
            print(f"OK   {example_path.relative_to(ROOT)}")

    return 1 if had_errors else 0


if __name__ == "__main__":
    sys.exit(main())
