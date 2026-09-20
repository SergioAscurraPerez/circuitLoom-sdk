# Circuit events

`CircuitMonitor` (`addons/circuitloom_sdk/src/circuit_monitor.gd`) wraps
[`RulesEngine`](rules-engine.md) and turns its evaluation result into three Godot
signals, so a consumer reacts to circuit state without ever touching
`rules_engine.gd` — connecting to a signal from outside is the whole integration.

## The three events

| Signal | Fires when | Payload |
|---|---|---|
| `on_short_circuit(details: Dictionary)` | once per short circuit found | `{cause, component_id, net_id}` |
| `on_component_damaged(details: Dictionary)` | once per component over its rated current | `{node_id, current_ma, max_current_ma}` |
| `on_circuit_valid()` | the circuit has no shorts and no damaged components | — |

All three come from `RulesEngine.evaluate()`'s result (see
[`rules-engine.md`](rules-engine.md)) — `CircuitMonitor` just maps that result onto
signals; it adds no evaluation logic of its own.

## Walkthrough

The runnable version of this lives in [`examples/hello_circuit/`](../examples/hello_circuit/)
— `hello_circuit.gd` (the reusable logic) plus `run_example.gd` (a CLI entrypoint), and
three schema v1 circuits under `circuits/`. Run it with:

```bash
godot --headless --script res://examples/hello_circuit/run_example.gd
```

Step by step:

1. **Create a `CircuitMonitor`.**

   ```gdscript
   var monitor := CircuitMonitor.new()
   ```

2. **Connect to the events you care about — no core code involved.**

   ```gdscript
   monitor.on_short_circuit.connect(func(details): print("short circuit: %s" % details))
   monitor.on_component_damaged.connect(func(details): print("damaged: %s" % details))
   monitor.on_circuit_valid.connect(func(): print("circuit is valid"))
   ```

3. **Load a circuit (a schema v1 document) and check it.**

   ```gdscript
   var text := FileAccess.get_file_as_string("res://examples/hello_circuit/circuits/valid.json")
   var circuit: Dictionary = JSON.parse_string(text)
   monitor.check(circuit)  # -> emits on_circuit_valid
   ```

4. **Swap the circuit, see the other events fire.**

   `circuits/short_circuit.json` (a bare wire from 5V to GND) makes `check()` emit
   `on_short_circuit`. `circuits/overcurrent.json` (an LED with no series resistor)
   makes it emit `on_component_damaged`.

`check()` also returns the full `RulesEngine` result dictionary directly, for callers
that want the raw data instead of (or alongside) the events. The same dictionary is
available as `monitor.last_result`, already set when the signals are emitted, so an event
handler can read data the payload doesn't carry (for example `node_currents_ma`).
