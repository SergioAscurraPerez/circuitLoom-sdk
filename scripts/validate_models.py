#!/usr/bin/env python3
"""Validate every glTF model under addons/circuitloom_sdk/models/ against the model
contract (addons/circuitloom_sdk/data/model_contract.json).

Standard library only: a .glb is a small binary header plus a JSON chunk, and the JSON
chunk has everything the contract needs (node names, transforms, mesh bounds, images).
"""

import json
import math
import struct
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ADDON = ROOT / "addons" / "circuitloom_sdk"
MODELS_DIR = ADDON / "models"
CONTRACT_PATH = ADDON / "data" / "model_contract.json"
CATALOG_PATH = ADDON / "data" / "components.json"

PIN_PREFIX = "PIN_"
MATERIAL_PREFIX = "MAT_"
SCALE_TOLERANCE = 1e-4


def read_gltf_json(path: Path) -> dict:
    data = path.read_bytes()
    if len(data) < 20:
        raise ValueError("file too small to be a .glb")
    magic, version, _length = struct.unpack("<4sII", data[:12])
    if magic != b"glTF" or version != 2:
        raise ValueError("not a glTF 2.0 binary (.glb) file")
    chunk_length, chunk_type = struct.unpack("<I4s", data[12:20])
    if chunk_type != b"JSON":
        raise ValueError("first chunk is not JSON")
    return json.loads(data[20 : 20 + chunk_length])


def node_matrix(node: dict) -> list[list[float]]:
    """Local 4x4 transform (row-major) from a node's `matrix` or its TRS."""
    if "matrix" in node:
        m = node["matrix"]  # glTF stores column-major
        return [[m[c * 4 + r] for c in range(4)] for r in range(4)]
    tx, ty, tz = node.get("translation", [0, 0, 0])
    qx, qy, qz, qw = node.get("rotation", [0, 0, 0, 1])
    sx, sy, sz = node.get("scale", [1, 1, 1])
    rot = [
        [1 - 2 * (qy * qy + qz * qz), 2 * (qx * qy - qz * qw), 2 * (qx * qz + qy * qw)],
        [2 * (qx * qy + qz * qw), 1 - 2 * (qx * qx + qz * qz), 2 * (qy * qz - qx * qw)],
        [2 * (qx * qz - qy * qw), 2 * (qy * qz + qx * qw), 1 - 2 * (qx * qx + qy * qy)],
    ]
    return [
        [rot[0][0] * sx, rot[0][1] * sy, rot[0][2] * sz, tx],
        [rot[1][0] * sx, rot[1][1] * sy, rot[1][2] * sz, ty],
        [rot[2][0] * sx, rot[2][1] * sy, rot[2][2] * sz, tz],
        [0, 0, 0, 1],
    ]


def mat_mul(a: list[list[float]], b: list[list[float]]) -> list[list[float]]:
    return [[sum(a[r][k] * b[k][c] for k in range(4)) for c in range(4)] for r in range(4)]


def transform_point(m: list[list[float]], p: tuple[float, float, float]) -> tuple[float, ...]:
    return tuple(m[r][0] * p[0] + m[r][1] * p[1] + m[r][2] * p[2] + m[r][3] for r in range(3))


def walk(gltf: dict, index: int, parent: list[list[float]], visit) -> None:
    node = gltf["nodes"][index]
    world = mat_mul(parent, node_matrix(node))
    visit(node, world)
    for child in node.get("children", []):
        walk(gltf, child, world, visit)


def longest_extent(gltf: dict) -> float:
    """Longest side (meters) of the axis-aligned box around every mesh in the scene."""
    mins = [math.inf] * 3
    maxs = [-math.inf] * 3

    def visit(node: dict, world: list[list[float]]) -> None:
        if "mesh" not in node:
            return
        for primitive in gltf["meshes"][node["mesh"]]["primitives"]:
            accessor = gltf["accessors"][primitive["attributes"]["POSITION"]]
            lo, hi = accessor["min"], accessor["max"]
            for x in (lo[0], hi[0]):
                for y in (lo[1], hi[1]):
                    for z in (lo[2], hi[2]):
                        point = transform_point(world, (x, y, z))
                        for axis in range(3):
                            mins[axis] = min(mins[axis], point[axis])
                            maxs[axis] = max(maxs[axis], point[axis])

    identity = [[1 if r == c else 0 for c in range(4)] for r in range(4)]
    for root in gltf["scenes"][gltf.get("scene", 0)]["nodes"]:
        walk(gltf, root, identity, visit)
    if math.inf in mins:
        return 0.0
    return max(maxs[axis] - mins[axis] for axis in range(3))


def validate_model(path: Path, component_type: str, entry: dict) -> list[str]:
    try:
        gltf = read_gltf_json(path)
    except (ValueError, json.JSONDecodeError, struct.error) as error:
        return [f"unreadable .glb: {error}"]

    problems: list[str] = []
    nodes = gltf.get("nodes", [])
    names = {node.get("name", "") for node in nodes}

    scene_roots = gltf["scenes"][gltf.get("scene", 0)]["nodes"]
    if len(scene_roots) != 1 or nodes[scene_roots[0]].get("name") != component_type:
        problems.append(f"scene must have a single root node named '{component_type}'")

    for pin in entry["pins"]:
        if PIN_PREFIX + pin not in names:
            problems.append(f"missing {PIN_PREFIX}{pin}")
    for part in entry["parts"]:
        if part not in names:
            problems.append(f"missing {part}")
    for name in sorted(names):
        if name.startswith(PIN_PREFIX) and name[len(PIN_PREFIX) :] not in entry["pins"]:
            problems.append(f"unknown {name}")

    for node in nodes:
        scale = node.get("scale", [1, 1, 1])
        if any(abs(s - 1.0) > SCALE_TOLERANCE for s in scale):
            problems.append(f"node '{node.get('name', '?')}' has unapplied scale {scale}")

    for material in gltf.get("materials", []):
        if not material.get("name", "").startswith(MATERIAL_PREFIX):
            problems.append(f"material '{material.get('name', '?')}' must be named {MATERIAL_PREFIX}*")

    for kind in ("images", "buffers"):
        for item in gltf.get(kind, []):
            if "uri" in item and not item["uri"].startswith("data:"):
                problems.append(f"external {kind[:-1]} '{item['uri']}': embed it in the .glb")

    lo, hi = entry["extent_m"]
    extent = longest_extent(gltf)
    if not lo <= extent <= hi:
        problems.append(
            f"longest dimension is {extent * 1000:.1f} mm, outside the expected "
            f"{lo * 1000:.0f}-{hi * 1000:.0f} mm (exported in the wrong unit?)"
        )
    return problems


def main() -> int:
    contract = json.loads(CONTRACT_PATH.read_text(encoding="utf-8"))["components"]
    catalog = json.loads(CATALOG_PATH.read_text(encoding="utf-8"))
    catalog_types = {entry["type"] for entry in catalog["components"]}

    had_errors = False
    if set(contract) != catalog_types:
        had_errors = True
        print("FAIL model_contract.json types differ from components.json")
        for component_type in sorted(set(contract) ^ catalog_types):
            print(f"  - {component_type}")

    models = sorted(MODELS_DIR.glob("*.glb")) if MODELS_DIR.is_dir() else []
    for path in models:
        component_type = path.stem
        if component_type not in contract:
            had_errors = True
            print(f"FAIL {path.name}\n  - no contract for type '{component_type}'")
            continue
        problems = validate_model(path, component_type, contract[component_type])
        if problems:
            had_errors = True
            print(f"FAIL {path.name}")
            for problem in problems:
                print(f"  - {problem}")
        else:
            print(f"OK   {path.name}")

    print(f"{len(models)} of {len(contract)} models present")
    return 1 if had_errors else 0


if __name__ == "__main__":
    sys.exit(main())
