#!/usr/bin/env python3
"""Validate component packs (docs/component-packs.md): pack.json against
schema/v1/component-pack.schema.json, the checks JSON Schema can't express (electrical
terminals are pins, unique names) and every models/<name>.glb against its component's
pins, parts and size, with the same checks as validate_models.py.

    python scripts/validate_component_pack.py [pack dir ...]

Without arguments it checks examples/component_pack. Another repo can run it on its own
packs from a checkout of the SDK.
"""

import json
import sys
from pathlib import Path

from jsonschema import Draft202012Validator
from referencing import Registry, Resource

sys.path.insert(0, str(Path(__file__).resolve().parent))
from validate_models import validate_model  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent
SCHEMA_DIR = ROOT / "schema" / "v1"
DEFAULT_PACKS = [ROOT / "examples" / "component_pack"]


def pack_validator() -> Draft202012Validator:
    pack_schema = json.loads((SCHEMA_DIR / "component-pack.schema.json").read_text("utf-8"))
    graph_schema = json.loads((SCHEMA_DIR / "circuit-graph.schema.json").read_text("utf-8"))
    registry = Registry().with_resources(
        (schema["$id"], Resource.from_contents(schema)) for schema in (pack_schema, graph_schema)
    )
    return Draft202012Validator(pack_schema, registry=registry)


def semantic_problems(pack: dict) -> list[str]:
    problems: list[str] = []
    names: set[str] = set()
    for component in pack["components"]:
        name = component["name"]
        if name in names:
            problems.append(f"{name}: duplicated name")
        names.add(name)
        pin_ids = [pin["id"] for pin in component["pins"]]
        if len(set(pin_ids)) != len(pin_ids):
            problems.append(f"{name}: duplicated pin id")
        electrical = component["electrical"]
        for terminal in electrical.get("terminals", []):
            if terminal not in pin_ids:
                problems.append(f"{name}: electrical terminal '{terminal}' is not a pin")
        roles = {pin["role"] for pin in component["pins"]}
        if electrical["model"] in ("rated_load", "source") and not {"power", "ground"} <= roles:
            problems.append(f"{name}: a '{electrical['model']}' needs a power and a ground pin")
        low, high = component["extent_m"]
        if low > high:
            problems.append(f"{name}: extent_m must be [min, max]")
    return problems


def validate_pack(pack_dir: Path) -> list[str]:
    pack_path = pack_dir / "pack.json"
    if not pack_path.is_file():
        return [f"no pack.json in {pack_dir}"]
    pack = json.loads(pack_path.read_text("utf-8"))
    errors = sorted(pack_validator().iter_errors(pack), key=lambda e: list(e.path))
    if errors:
        return [f"{'/'.join(str(p) for p in e.path) or '<root>'}: {e.message}" for e in errors]

    problems = semantic_problems(pack)
    components = {component["name"]: component for component in pack["components"]}
    models_dir = pack_dir / "models"
    for path in sorted(models_dir.glob("*.glb")) if models_dir.is_dir() else []:
        component = components.get(path.stem)
        if component is None:
            problems.append(f"models/{path.name}: no component named '{path.stem}'")
            continue
        contract = {
            "pins": [pin["id"] for pin in component["pins"]],
            "parts": component.get("parts", []),
            "extent_m": component["extent_m"],
        }
        for problem in validate_model(path, path.stem, contract):
            problems.append(f"models/{path.name}: {problem}")
    return problems


def main(argv: list[str]) -> int:
    pack_dirs = [Path(arg) for arg in argv] or DEFAULT_PACKS
    had_errors = False
    for pack_dir in pack_dirs:
        problems = validate_pack(pack_dir)
        if problems:
            had_errors = True
            print(f"FAIL {pack_dir}")
            for problem in problems:
                print(f"  - {problem}")
        else:
            print(f"OK   {pack_dir}")
    return 1 if had_errors else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
