# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this
project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Model contract for realistic glTF component models (`data/model_contract.json`), a
  `ModelLoader` that validates them, and `scripts/validate_models.py` for CI
  ([docs](docs/models.md)).
- Realistic glTF model for the LED (`models/led.glb`). `ComponentCatalog` uses a component's
  model when it exists and satisfies the contract, and falls back to the primitive
  placeholder otherwise.

- `LedState`: shows the LED model as off, on or burned by changing the material of its
  `STATE_Lens` part, driven by `on_circuit_valid`, `on_short_circuit` and
  `on_component_damaged` ([docs](docs/models.md#led-states)).
- `CircuitMonitor.last_result`: the latest `check()` result, readable from event handlers.
- Realistic glTF models for the other nine components: Arduino UNO, breadboard, resistor,
  push button, buzzer, SG90 servo, potentiometer, HC-SR04 ultrasonic sensor and
  photoresistor. All 10 catalog components now use a real-scale model.

### Changed

- Resistor pins are `a`/`b` in the schema v1 example, matching the rest of the examples and
  tests.
- The spark and smoke effects are authored at real-world scale in local coordinates, so
  they scale and move with the component they are spawned under
  ([docs](docs/effects.md#scale-and-position)). Particles are now round and soft-edged, and
  the sparks are HDR so they bloom with glow.
- The hello_circuit demo scene shows the starter-kit components on the breadboard, the
  LED following the circuit events, sparks on the Arduino's power header, and a lit
  environment (glow, SSAO, screen-space reflections, shadows). `demo.gif` re-recorded.

### Fixed

- The spark and smoke particles ignored their parent's scale and their own per-particle
  scale, because billboarded particles drop it unless `billboard_keep_scale` is set.

## [0.1.0] - 2026-09-18

First public release.

### Added

- Serializable circuit graph, schema `v1`, with JSON Schema and validated examples
  ([docs](docs/circuit-graph-schema.md)).
- `RulesEngine`: voltage/current per node, short-circuit and overcurrent detection
  ([docs](docs/rules-engine.md)).
- `CircuitMonitor` events `on_short_circuit`, `on_component_damaged` and
  `on_circuit_valid`, so consumers react without touching the core
  ([docs](docs/events.md)).
- Catalog of 10 Arduino UNO starter-kit components with datasheet-verified specs and
  placeholder 3D models, plus standard wire color coding
  ([docs](docs/components.md)).
- Spark and smoke reference effect for short-circuit feedback, built only from Godot
  built-ins ([docs](docs/effects.md)).
- `hello_circuit` example: a headless walkthrough (`run_example.gd`) and a windowed demo
  (`demo_scene.gd`).
- Addon packaging for the Godot Asset Library and GitHub downloads: `.gitattributes`
  ships only `addons/`, `LICENSE`, `README.md` and `CHANGELOG.md`.
- README with installation steps, quick start and demo GIF.

### Fixed

- Spark effect was invisible when spawned into a running scene: it now uses
  `restart()`, tints from the particle color, and uses a visible particle size.

[Unreleased]: https://github.com/SergioAscurraPerez/circuitLoom-sdk/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/SergioAscurraPerez/circuitLoom-sdk/releases/tag/v0.1.0
