# Component catalog (v1)

The 10 real components modeled for v1 — the same ones in a typical Arduino UNO starter
kit — with specs verified against a real datasheet or manufacturer/reseller spec page
for each. This is the canonical source for `node.specs` when authoring a schema v1
circuit (see [`circuit-graph-schema.md`](circuit-graph-schema.md)).

- Data: [`addons/circuitloom_sdk/data/components.json`](../addons/circuitloom_sdk/data/components.json)
- 3D placeholder models: `addons/circuitloom_sdk/src/components/*.gd` (see below)
- Validator: `scripts/validate_components_catalog.py`, run in CI on every PR — checks
  every entry's `specs` against the matching `$defs/specs/<type>` subschema in
  `schema/v1/circuit-graph.schema.json`

| Component | Part reference | Key specs | Source |
|---|---|---|---|
| Arduino UNO | Arduino UNO R3 (ATmega328P) | 5V, 14 digital pins, 6 analog pins, 6 PWM pins | [docs.arduino.cc](https://docs.arduino.cc/hardware/uno-rev3) |
| LED | Generic 5mm red LED | Vf 2.0V, 20mA max | [SparkFun](https://www.sparkfun.com/led-basic-red-5mm.html) |
| Resistor | 1/4W carbon/metal film, 220Ω 5% | 220Ω, 5%, 0.25W | [resistor color code calculator](https://www.allaboutcircuits.com/tools/resistor-color-code-calculator/) |
| Push button | Omron B3F 6x6mm tactile switch | up to 24V, up to 50mA | [Omron B3F datasheet](https://omronfs.omron.com/en_US/ecb/products/pdf/en-b3f.pdf) |
| Buzzer | Generic 5V active piezo buzzer | 5V rated, ~30mA | [components101](https://components101.com/misc/buzzer-pinout-working-datasheet) |
| Servo motor | TowerPro SG90 | 5V, ~650mA stall, 180° | [TowerPro SG90 brochure](https://www.auselectronicsdirect.com.au/assets/brochures/TA0132.pdf) |
| Potentiometer | Generic 10kΩ linear rotary pot | 10kΩ, linear | [SparkFun](https://www.sparkfun.com/rotary-potentiometer-10k-ohm-linear.html) |
| Ultrasonic sensor | HC-SR04 | 5V, 15mA, 2-400cm range | [SparkFun HC-SR04 datasheet](https://cdn.sparkfun.com/datasheets/Sensors/Proximity/HCSR04.pdf) |
| Breadboard | 830 tie-point full-size breadboard | 10x63 terminal strip + 4 power rails | [BusBoard BB830 datasheet](https://www.busboard.com/documents/datasheets/BPS-DAT-(KIT-BB830+SB830)-Datasheet.pdf) |
| Photoresistor | GL5528 5mm CdS LDR | ≥1MΩ dark, 10-20kΩ at 10 lux | [GL55 series manual](https://passionelectronique.fr/wp-content/uploads/datasheet-photoresistance-LDR-GL5528-CdS.pdf) |

A few figures are ranges rather than one unambiguous datasheet line (generic/unbranded
parts don't always have a single canonical source) — see the `notes` field per entry in
`components.json` for exactly which ones and why.

## Wire color convention

Wires (`edge.wire_color`) follow the standard electronics/breadboard prototyping
convention:

- **Red** — anything touching a `power`-role pin (e.g. an Arduino's 5V, a breadboard's
  positive rail).
- **Black** — anything touching a `ground`-role pin.
- Other colors (yellow, orange, blue, green, ...) are used for signal/data wires, which
  don't have one single mandated color in the general convention.

`scripts/validate_wire_colors.py` enforces the red/ground=black rule in CI against every
committed example circuit (a wire that touches *both* a power and a ground pin — i.e. a
depicted short circuit — is allowed to match either, since that miswiring is the whole
point of the example).

One component-specific exception worth knowing: the SG90 servo's 3-wire cable uses its
own well-established convention — **brown = GND, red = VCC, orange = signal** — which
differs from the general rule above (signal, not power, is orange there) because it's
the servo's own fixed cable, not a wire you choose the color for.

## 3D placeholder models

Each component has a minimal, primitive-based ("low-poly") 3D representation under
`addons/circuitloom_sdk/src/components/` — boxes/cylinders/spheres assembled in code via
`ComponentBuilder`, no external mesh/texture files. This means there's nothing to import
and nothing that can go missing: instantiating any of them can't produce a broken
resource reference. `ComponentCatalog.build() ` instantiates all 10 into one `Node3D`;
`tests/unit/components/test_component_catalog.gd` adds that to the scene tree and
asserts all 10 load with no null nodes and no orphaned children.

This is placeholder-quality geometry, not sculpted art — good enough to tell components
apart and wire up in an editor, not a final visual pass. A component with a realistic
glTF model in `addons/circuitloom_sdk/models/` uses it instead, and falls back to its
placeholder if the model is missing or breaks the contract — see [models.md](models.md).
