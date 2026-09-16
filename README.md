# CircuitLoom SDK

[![CI](https://github.com/SergioAscurraPerez/circuitLoom-sdk/actions/workflows/ci.yml/badge.svg)](https://github.com/SergioAscurraPerez/circuitLoom-sdk/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

> **Status: early development (pre-v0.1.0).** APIs and schemas are not yet stable.

CircuitLoom SDK is an open-source **Godot Engine addon** for simulating real electronic
circuits — the same components found in an Arduino UNO starter kit (LEDs, resistors,
buttons, buzzers, servos, potentiometers, an ultrasonic sensor, a protoboard) — as a
serializable, event-driven graph that games and interactive learning tools can build on.

## Positioning: why not Fritzing, Wokwi, or a similar simulator?

Tools like **Fritzing** (schematic/PCB design) and **Wokwi** (browser-based Arduino
simulator) are built to *design and validate a circuit as a standalone artifact* — you
open them, wire a circuit, check it, and export it. They are not meant to be embedded
inside another real-time application, and they don't expose their circuit model as
something a game engine can drive, render in 3D, or react to at runtime.

CircuitLoom SDK targets a different gap: **circuit simulation as a reusable building
block inside a game or interactive experience**, not as a destination tool. Concretely:

- **Godot-native, not a separate app.** It ships as a Godot addon (GDScript), installable
  from the Godot Asset Library, so it lives inside the same project as the game/lesson
  that uses it — no external simulator window, no import/export round-trip.
- **A serializable graph, not a black box.** The circuit is modeled explicitly as nodes
  (components/pins) and edges (wires), versioned (`v1`), so any consumer — a rules
  engine, a custom UI, a save file — can read and write the same structure.
- **Event-driven by design.** Consumers react to `on_short_circuit`,
  `on_component_damaged`, and `on_circuit_valid` without touching the internals of the
  rules engine, which is what makes it usable inside a game loop instead of only a
  one-shot validation pass.
- **3D and feedback-ready.** Low-poly component models, standard wire color coding, and
  ready-to-use spark/smoke failure effects come with the SDK, so an interactive scene
  doesn't have to be built from scratch to *look and feel* like a real circuit.

In short: Fritzing and Wokwi answer "is this circuit correct?" as a standalone question.
CircuitLoom SDK answers "how does this circuit behave, live, inside my game?" — aimed at
educators and game developers building electronics-learning experiences (e.g. an
Arduino-UNO-compatible teaching sandbox), not circuit designers producing a finished
schematic.

## Installation

> Not yet published to the Godot Asset Library (tracked as SDK-08 in the project backlog).
> Until then, clone this repo (or add it as a submodule) into your project's `addons/`
> folder as `addons/circuitloom_sdk/`, then enable **CircuitLoom SDK** under
> **Project > Project Settings > Plugins**.

Requires **Godot 4.5+**.

## Status

This SDK is being built in public, in order, against a public backlog. The circuit
data model is defined as a versioned, serializable graph — see
[`docs/circuit-graph-schema.md`](docs/circuit-graph-schema.md) — and is what the rules
engine (in progress) will run on.

## Contributing

Contributions are welcome — see [CONTRIBUTING.md](CONTRIBUTING.md) for the commit
convention, PR process, and how to run lint/tests locally. Please also read our
[Code of Conduct](CODE_OF_CONDUCT.md).

## License

MIT — see [LICENSE](LICENSE).
