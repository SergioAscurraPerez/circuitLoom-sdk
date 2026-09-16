# Rules engine (v1)

`RulesEngine` (`addons/circuitloom_sdk/src/rules_engine/rules_engine.gd`) consumes a
schema v1 circuit document (see [`circuit-graph-schema.md`](circuit-graph-schema.md)) and
computes, per pin/component, whether the circuit is electrically sound.

```gdscript
var result := RulesEngine.new().evaluate(circuit_doc)
# result.is_valid: bool
# result.short_circuits: Array[{cause, component_id, net_id}]
# result.damaged_components: Array[{node_id, current_ma, max_current_ma}]
# result.node_currents_ma: Dictionary[node_id -> float]
# result.pin_voltages: Dictionary["node_id:pin_id" -> float]
```

## Model

1. **Nets.** Union-find over pins, using `edges` (wires — zero resistance) and any
   `push_button` whose `specs.normally_open == false` (a normally-closed switch behaves
   like a wire). A `push_button` left open (`normally_open == true`, the default resting
   state) contributes no connection at all.
2. **Sources.** Only an `arduino_uno` node's `power`/`ground`-role pins are treated as an
   ideal voltage source / 0V reference.
3. **Loads.** Every other two-terminal-ish component (`resistor`, `led`, `buzzer`,
   `potentiometer`, `photoresistor`, and — via their `power`/`ground`-role pins only —
   `servo_motor`/`ultrasonic_sensor`) becomes an edge in a net-level graph, with an
   effective resistance:
   - `resistor`/`potentiometer`: `specs.resistance_ohm` directly (a potentiometer's
     `wiper` pin is ignored in v1 — it's treated as a fixed resistor across its two ends).
   - `photoresistor`: `specs.dark_resistance_ohm` — v1 has no light model, so it's always
     evaluated at its highest (dark-state) resistance, the most conservative reading.
   - `led`/`buzzer`/`servo_motor`/`ultrasonic_sensor`: derived as
     `rated_voltage / rated_current`, from whichever voltage/current spec pair the
     component has (e.g. an LED's `forward_voltage_v` / `max_current_ma`).
4. **Short circuits.** Two cases: (a) a net directly contains both a power-role and a
   ground-role pin (a bare wire, a closed switch, or any chain of those, ties them
   together), or (b) a resistive path from a power net to a ground net has ~0 total
   resistance (e.g. a misconfigured 0-ohm resistor).
5. **Current/voltage.** For every other power-net → ground-net path (simple paths, DFS,
   capped at 12 hops / 500 paths per source), current = source voltage / total path
   resistance (series sum); a component is flagged `damaged` if that current exceeds its
   own rated max. Parallel branches each see the full source voltage (ideal source
   assumption). Net voltage is the source voltage minus the cumulative drop along the
   path; pin voltage is its net's voltage.

## Known v1 limitations

- **Digital/PWM pins aren't sources.** Only the `power`-role pin (e.g. "5V") sources
  current. A component driven from a `digital_io`/`pwm` pin (e.g. an LED on an Arduino
  digital output) isn't evaluated for current/damage in v1 — that requires knowing the
  pin's runtime HIGH/LOW state, which isn't part of the static graph. It's still checked
  for direct shorts.
- **No diode polarity check.** An LED wired backwards isn't flagged.
- **No light model.** A `photoresistor` is a fixed resistor in v1, always at its
  dark-state resistance — it doesn't actually respond to a simulated light level.
- **Single ideal voltage source.** No internal source resistance, no total-current limit
  on the source itself.
- **Coverage tooling.** There's no mature, CI-ready GDScript line-coverage tool yet (the
  one third-party option found, `nano-coverage-godot`, is an alpha with no prebuilt
  binaries). Coverage for this module is verified by inspection against the test suite in
  `tests/unit/rules_engine/` instead of an automated CI gate — revisit once tooling
  matures.
