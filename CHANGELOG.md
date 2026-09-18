# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this
project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
