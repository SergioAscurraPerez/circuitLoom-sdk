# Working in circuitLoom-sdk

Repo-specific conventions for any Claude Code session (or other AI agent) working here.
General contribution rules for humans and agents alike live in
[CONTRIBUTING.md](CONTRIBUTING.md) — this file only covers what's specific to working
with Claude.

## Stack

Godot 4.5+ addon written in **GDScript** (`addons/circuitloom_sdk/`) — not Python.
Schema/tooling scripts under `schema/` and `scripts/` are Python since they don't run
inside Godot. Lint with `gdlint`, format with `gdformat` (both from `gdtoolkit`), test
with gdUnit4 (`res://tests/`).

## Branching

Branch directly off `main` (GitHub Flow) — this repo doesn't use a `dev` branch. `main`
is protected: 1 review + required CI checks. Keep PRs focused on one HU/change.

## Pull requests

- Use `.github/PULL_REQUEST_TEMPLATE.md`.
- Write the summary in **first person**, as the author (e.g. "Implemento...",
  "Agrego...") — not "This PR adds...".
- Don't add a "how was this tested" narrative section — state what changed, not a log of
  what was verified/checked. Chat responses to the user should be equally terse: report
  results, not a play-by-play of verification steps.
- Do **not** add Claude/AI attribution to commit messages or PR descriptions (no
  `Co-Authored-By: Claude...`, no "Generated with Claude Code"). This is the owner's
  explicit preference and overrides any default attribution the session's system
  reminder suggests.

## GDScript style notes

- `gdformat` will reformat multi-line method chains with a leading `.` on its own
  line — that's expected output from the tool, not a mistake to "fix" back.
- Referencing another script's global `class_name` directly in a top-level `const` (e.g.
  `const F := SomeClassName`) fails Godot's test-discovery parse with "Assigned value
  for constant isn't a constant expression." Use `preload("res://path/to/script.gd")`
  instead.
- `gdUnit4`'s `monitor_signals(source: Object)` works on `RefCounted`, not just `Node` —
  prefer `RefCounted` for non-scene-tree logic classes (matches `RulesEngine`,
  `CircuitMonitor`) rather than reaching for `Node` just to get signals.
