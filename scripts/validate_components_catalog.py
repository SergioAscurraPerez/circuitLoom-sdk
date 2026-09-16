#!/usr/bin/env python3
import json
import sys
from pathlib import Path

from jsonschema import Draft202012Validator

ROOT = Path(__file__).resolve().parent.parent
SCHEMA_PATH = ROOT / "schema" / "v1" / "circuit-graph.schema.json"
CATALOG_PATH = ROOT / "addons" / "circuitloom_sdk" / "data" / "components.json"


def main() -> int:
    schema = json.loads(SCHEMA_PATH.read_text(encoding="utf-8"))
    catalog = json.loads(CATALOG_PATH.read_text(encoding="utf-8"))

    had_errors = False
    for entry in catalog["components"]:
        component_type = entry["type"]
        # Validate just this type's `specs` shape, reusing the schema's own
        # $defs so we check against the exact same subschema RulesEngine and
        # the circuit graph schema rely on — not a hand-copied duplicate.
        spec_schema = {
            "$schema": schema["$schema"],
            "$defs": schema["$defs"],
            "$ref": f"#/$defs/specs/{component_type}",
        }
        validator = Draft202012Validator(spec_schema)
        errors = sorted(validator.iter_errors(entry["specs"]), key=lambda e: e.path)
        if errors:
            had_errors = True
            print(f"FAIL {component_type}")
            for error in errors:
                location = "/".join(str(p) for p in error.path) or "<root>"
                print(f"  - {location}: {error.message}")
        else:
            print(f"OK   {component_type}")

    return 1 if had_errors else 0


if __name__ == "__main__":
    sys.exit(main())
