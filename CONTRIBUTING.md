# Contributing

## Change workflow

1. Define or update the implementation plan for changes spanning multiple
   components.
2. Preserve the upstream QuadSim submodule.
3. Add or update automated tests with the implementation.
4. Run project validation and applicable simulation tests.
5. Record model, configuration, protocol, and data-schema changes together.
6. Inspect the diff for credentials, tokens, private keys, device identifiers,
   and accidental raw logs.

## MATLAB conventions

- Place reusable code under the `+vectra` package.
- Use absolute paths derived from `vectra.root`.
- Avoid base-workspace dependencies outside the isolated upstream adapter.
- Use timetables for normalized time-series data.
- Include units in canonical variable names.
- Raise namespaced errors such as `vectra:config:FileNotFound`.

## Research changes

Changes that affect physical interpretation must document assumptions,
calibration range, uncertainty, and baseline impact. A model change is not
accepted solely because it compiles; it must preserve the zero-cant baseline or
explain the validated difference.
