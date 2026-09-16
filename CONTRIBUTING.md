# Contributing to CircuitLoom SDK

Thanks for your interest in contributing! This project is an early-stage open-source
Godot addon, and contributions of all sizes are welcome — bug reports, docs fixes,
new components, or core engine work.

## Getting started

1. Fork the repo and clone your fork.
2. Open the project in **Godot 4.5+**.
3. Create a branch off `main` for your change.
4. Make your change, and add/update tests under `tests/` (we use [gdUnit4](https://github.com/godot-gdunit-labs/gdunit4)).
5. Run the lint and test suite locally before opening a PR (see below).

## Running checks locally

```bash
# Lint
pip install "gdtoolkit==4.*"
gdlint addons/ tests/

# Tests (requires the Godot editor + gdUnit4 addon installed)
# Open the project in Godot and run tests from the gdUnit4 panel,
# or use the gdUnit4 CLI runner — see their docs for headless usage.
```

CI runs the same lint and test suite on every pull request and must pass before merging.

## Commit convention

We use [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<optional scope>): <short summary>

<optional body>
```

Common types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `ci`.

Examples:

```
feat(rules-engine): detect short circuits across parallel branches
fix(events): emit on_circuit_valid only after a stable evaluation
docs(readme): add installation steps for Godot Asset Library
```

## Pull requests

- Keep PRs focused on a single change/HU where possible.
- Fill out the PR template — describe what changed, why, and how it was tested.
- A PR needs a passing CI run and at least one approving review before it can merge into `main`.
- Prefer squash-friendly, descriptive commit messages — history should read as a changelog.

## Code of Conduct

By participating in this project, you agree to abide by our [Code of Conduct](CODE_OF_CONDUCT.md).
