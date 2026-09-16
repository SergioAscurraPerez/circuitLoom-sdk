# Circuit graph schema (v1)

The circuit data model is a serializable graph: **nodes** are components (with their
pins and specs), **edges** are wires connecting two pins. This is the shared structure
the rules engine (SDK-04) and any game/tool built on the SDK read and write.

- Schema: [`schema/v1/circuit-graph.schema.json`](../schema/v1/circuit-graph.schema.json) (JSON Schema, draft 2020-12)
- Example: [`schema/v1/examples/led-button-breadboard.json`](../schema/v1/examples/led-button-breadboard.json)
- Validator: `scripts/validate_schema_examples.py`, run in CI on every PR

## Versioning

The schema is explicitly versioned as `v1`:

- the file lives under `schema/v1/`
- its `$id` ends in `.../schema/v1/circuit-graph.schema.json`
- every document has a top-level `"schema_version": "v1"` field, validated as a `const`

A breaking change to the shape of nodes/edges/specs ships as `schema/v2/...` rather than
mutating `v1` in place, so existing serialized circuits keep validating against the
schema version they declare.

## Shape

```
{
  "schema_version": "v1",
  "circuit": {
    "id": "...",
    "name": "...",
    "nodes": [ { "id", "type", "pins": [...], "specs": {...} }, ... ],
    "edges": [ { "id", "from": {node_id, pin_id}, "to": {node_id, pin_id}, "wire_color" }, ... ]
  }
}
```

Each `node.type` is one of the 9 v1 component types, and `specs` is validated against a
type-specific schema (`$defs.specs.<type>`) via an `if/then` on `type`:

| type | specs fields |
|---|---|
| `arduino_uno` | `operating_voltage_v`, `digital_pins`, `analog_pins`, `pwm_pins` |
| `led` | `color`, `forward_voltage_v`, `max_current_ma` |
| `resistor` | `resistance_ohm`, `tolerance_percent`, `max_power_w` |
| `push_button` | `max_voltage_v`, `max_current_ma`, `normally_open` |
| `buzzer` | `kind` (`active`/`passive`), `rated_voltage_v`, `max_current_ma` |
| `servo_motor` | `operating_voltage_v`, `stall_current_ma`, `rotation_range_deg` |
| `potentiometer` | `resistance_ohm`, `taper` (`linear`/`logarithmic`) |
| `ultrasonic_sensor` | `operating_voltage_v`, `max_current_ma`, `range_cm_min`, `range_cm_max` |
| `breadboard` | `rows`, `columns`, `has_power_rails` |

Pins carry a `role` (`power`, `ground`, `digital_io`, `analog_io`, `pwm`, `passive`,
`trigger`, `echo`, `wiper`, `tie_point`) so the rules engine can reason about a pin
without hardcoding per-component-type logic.

## Known limitations (by design, for v1)

JSON Schema alone can't express cross-references, so it does **not** validate that:

- node/pin `id`s are unique within a circuit
- an edge's `from`/`to` point at pins that actually exist

Those are semantic checks that belong to the rules engine (SDK-04), which loads an
already schema-valid graph.

## Validating locally

```bash
pip install jsonschema
python scripts/validate_schema_examples.py
```
