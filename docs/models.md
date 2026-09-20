# Realistic 3D models (glTF)

Each catalog component can ship a realistic glTF model at
`addons/circuitloom_sdk/models/<type>.glb` (`<type>` is the component's `type` in
[`components.json`](../addons/circuitloom_sdk/data/components.json), e.g. `led.glb`).
`ComponentCatalog` uses that model when it exists and satisfies the contract below;
otherwise it falls back to the primitive placeholder (see [components.md](components.md)),
so a component always builds and there is never a broken resource reference.

- Contract: [`addons/circuitloom_sdk/data/model_contract.json`](../addons/circuitloom_sdk/data/model_contract.json)
- Loader: `addons/circuitloom_sdk/src/components/model_loader.gd` (`ModelLoader`)
- CI validator: `scripts/validate_models.py`

## The contract

The pin ids are the same `pin_id`s a circuit graph uses (see
[circuit-graph-schema.md](circuit-graph-schema.md)), so a wire drawn between two pins can
be anchored on the model.

| Component | Pins (`PIN_<id>`) | Parts driven at runtime |
|---|---|---|
| `arduino_uno` | `5V`, `GND`, `D0`–`D13`, `A0`–`A5` | `STATE_LED_ON`, `STATE_LED_L` |
| `led` | `anode`, `cathode` | `STATE_Lens` |
| `resistor` | `a`, `b` | — |
| `push_button` | `leg_a`, `leg_b` | `MOVE_Cap` |
| `buzzer` | `pos`, `neg` | — |
| `servo_motor` | `vcc`, `gnd`, `sig` | `MOVE_Horn` |
| `potentiometer` | `a`, `wiper`, `b` | `MOVE_Knob` |
| `ultrasonic_sensor` | `vcc`, `trig`, `echo`, `gnd` | — |
| `breadboard` | `PWR_RAIL_POS`, `PWR_RAIL_NEG` | — |
| `photoresistor` | `a`, `b` | — |

A model must:

- Have a single root node named after the component type, with everything else below it.
- Have one empty node per pin, named `PIN_<id>`, at the exact point where a wire connects.
  No `PIN_` node outside the table.
- Have every part listed for it. `STATE_*` parts are meshes whose material the SDK changes
  (emission, color); `MOVE_*` parts are meshes the SDK rotates or moves, with their origin
  on the axis of rotation.
- Use real-world scale: 1 unit = 1 meter, transforms applied (no node scale other than 1).
  The contract also holds a sanity range (`extent_m`) for the model's longest dimension to
  catch unit mistakes, such as exporting millimeters as meters.
- Use PBR materials named `MAT_<part>`, and embed any texture in the `.glb`.
- Avoid node names ending in Godot's import suffixes (`-col`, `-noimp`, `-convcol`, `-occ`,
  `-navmesh`, `-vehicle`, `-wheel`, `-rigid`, `-loop`, `-alpha`, `-vcol`).

## Exporting from Blender

Model in meters, Z up, with the front of the component facing -Y, and export with
`File > Export > glTF 2.0`: format **glTF Binary (.glb)**, selected objects only, **+Y Up**,
apply modifiers, embedded materials/images, no cameras or lights, no animation.

Then open the project in Godot once so it imports the file, and commit the generated
`<type>.glb.import` next to it.

## LED states

`LedState` (`addons/circuitloom_sdk/src/components/led_state.gd`) shows an LED model as off,
on or burned by changing the material of its `STATE_Lens` part, and follows the circuit
events (see [events.md](events.md)):

```gdscript
var led := ComponentCatalog.build_component("led")
add_child(led)

var led_state := LedState.new(led)
led_state.bind(monitor, "led_1")  # "led_1" is the LED's node id in the circuit
```

| Event | LED |
|---|---|
| `on_circuit_valid` | on if current flows through it, off otherwise |
| `on_short_circuit` | off |
| `on_component_damaged` for its node | burned, and it stays burned until `led_state.reset()` |

Each LED gets its own copy of the material, so lighting one never lights the others. A
model without a `STATE_Lens` is left untouched (`is_attached()` is `false`), so the
primitive fallback keeps working.

## Validating

```bash
python scripts/validate_models.py
```

Checks every `.glb` in `models/` against the contract (pins, parts, root name, applied
scale, `MAT_` names, embedded resources, size range) and that the contract lists exactly
the types in `components.json`. It needs only the Python standard library and runs in CI.

At runtime `ModelLoader.load_model(type)` performs the pin and part checks on the imported
scene and returns `null` (with a warning) when the model breaks the contract, which makes
`ComponentCatalog` use the primitive fallback.
