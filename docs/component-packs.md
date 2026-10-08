# Component packs

A component pack adds components to the catalog **from outside the addon**: another repo,
a private folder of a game, a mod. The SDK never needs to know them. Each pack component
builds through `ComponentCatalog`, has its pins and model contract like the built-in ones,
and carries its own electrical model, which `RulesEngine` evaluates without knowing its
type.

- Registry: `addons/circuitloom_sdk/src/components/component_packs.gd` (`ComponentPacks`)
- Schema: [`schema/v1/component-pack.schema.json`](../schema/v1/component-pack.schema.json)
- Example: [`examples/component_pack/`](../examples/component_pack/)
- Validator: `scripts/validate_component_pack.py`

## Layout

```
my_pack/
  pack.json
  models/
    dc_motor.glb        # optional, one per component, named after it
```

```json
{
  "schema_version": "v1",
  "id": "robotics",
  "name": "Robotics parts",
  "components": [
    {
      "name": "dc_motor",
      "display_name": "DC Gear Motor",
      "part_reference": "Generic 3-6V plastic gear motor, 1:48",
      "pins": [{ "id": "pos", "role": "power" }, { "id": "neg", "role": "ground" }],
      "electrical": { "model": "rated_load", "rated_voltage_v": 6, "rated_current_ma": 200 },
      "specs": { "gear_ratio": 48 },
      "parts": ["MOVE_Shaft"],
      "extent_m": [0.05, 0.09],
      "datasheet_source": "https://...",
      "dimensions_source": "https://... (mechanical drawing)",
      "notes": "Body 70 x 22.5 x 18.8 mm ..."
    }
  ]
}
```

- `id` and `name` are lowercase `snake_case`. The component's type is `<id>.<name>`
  (`robotics.dc_motor`), so it never collides with a built-in type or another pack.
- `pins` use the schema v1 pin roles. Pin ids are the `PIN_<id>` nodes of its model.
- `electrical` says how the rules engine treats it; see
  [rules-engine.md](rules-engine.md#component-packs). It must name pins that exist, and a
  `rated_load` or `source` needs a `power` and a `ground` pin.
- `specs` are free-form, for the game (the engine only reads `electrical`).
- `parts` are the `STATE_*` / `MOVE_*` nodes the game drives, and `extent_m` the sanity
  range of the model's longest side, as in the [model contract](models.md#the-contract).
- `dimensions_source` is required: where the model's real measurements come from (a
  mechanical drawing or datasheet outline). Models follow those measurements and carry no
  brands (see [models.md](models.md#the-contract)).

## Using a pack

```gdscript
var problems := ComponentPacks.register("res://packs/robotics")
if not problems.is_empty():
	push_error("Robotics pack: %s" % ", ".join(problems))

var motor := ComponentCatalog.build_component("robotics.dc_motor")  # model or placeholder
add_child(motor)

var node := ComponentPacks.node("robotics.dc_motor", "motor_1")  # circuit graph node
circuit_doc["circuit"]["nodes"].append(node)
```

- `register(dir)` validates the whole pack first and registers nothing when it has
  problems. Registering the same folder again reloads it; the same `id` from another
  folder is rejected.
- `ComponentCatalog.component_types()` lists the built-in types followed by every pack's.
- `build_component(type)` loads `models/<name>.glb` when it exists and satisfies the
  pack's contract (the instance is named `<name>`: node names can't contain a `.`).
  Without a model it builds a gray box at the component's size with a `PIN_` marker per
  pin and an empty node per part, so the component can be wired before it's modeled.
- `ComponentPacks.entry(type)` gives the pack's entry (display name, pins, specs...), and
  `unregister(id)` / `unregister_all()` remove packs.

`pack.json` is read with `FileAccess`, not imported, so a game's **export filter must
include it** (e.g. `*.json` in "Filters to export non-resource files").

## Validating in CI

From a checkout of the SDK (the validator needs `jsonschema`):

```bash
pip install jsonschema
python path/to/circuitLoom-sdk/scripts/validate_component_pack.py packs/robotics packs/sensors
```

It checks `pack.json` against the schema, the electrical terminals and roles, and every
`models/*.glb` with the same checks as `validate_models.py` (pins, parts, root named
`<name>`, applied scale, `MAT_` materials, embedded textures, size range).

## Licensing

A pack is not part of the SDK, so it can use any license, including a closed one: the SDK
is MIT and only asks that its own copyright notice travel with it.
