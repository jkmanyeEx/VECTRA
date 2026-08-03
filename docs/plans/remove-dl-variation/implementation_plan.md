# Remove Disk-Loading Variation from the Research Scope

Status: approved and implemented on 2026-07-28

## Decision

The active VECTRA research will no longer vary disk loading. Propeller diameter
and payload/mass sweeps will also be removed where they are described as ways
to vary disk loading. The experiment will keep the vehicle configuration,
propeller set, mass, and center of gravity fixed while cant angle is varied.

Disk loading may still appear only as a fixed, documented property of the
selected vehicle configuration when needed for reproducibility; it will not be
an independent variable, sweep dimension, or research claim.

## Scope

1. Update active project documentation:
   - `README.md`
   - `docs/plans/cant-implementation-plan.md`
   - `docs/walkthroughs/cant-implementation.md`
2. Update the active validation report source:
   - `docs/reports/cant-model-implementation-validation-report.md`
3. Regenerate the matching report editions from the updated source while
   preserving their current visual design:
   - `docs/reports/cant-model-implementation-validation-report.docx`
   - `docs/reports/cant-model-implementation-validation-report.pdf`
4. Search configuration, MATLAB, test, and report paths again. Remove any
   disk-loading or propeller/payload sweep behavior if found. The initial audit
   found no implemented sweep in MATLAB code or experiment configuration.
5. Add a Codex memory update recording that VECTRA now uses fixed disk loading,
   propeller configuration, mass, and center of gravity; the experimental
   variable remains cant angle.

## Historical artifacts

Past submitted assignment PDFs whose filenames or content describe
disk-loading variation will remain unchanged as archival records. They are not
active VECTRA specifications or current research reports. Rewriting or deleting
submitted historical evidence would obscure what was produced at that time.

## Verification

- Confirm active VECTRA code and documentation contain no disk-loading,
  propeller-diameter, payload, or mass *variation/sweep* instructions.
- Confirm the fixed vehicle/propeller/mass/CG controls are stated consistently.
- Extract text from the regenerated DOCX and PDF and compare the research-scope
  statements with the Markdown source.
- Render every DOCX/PDF page and visually inspect it for clipping, overlap,
  missing glyphs, broken pagination, and style drift.
- Inspect the final Git diff and verify unrelated telemetry work and
  `vendor/QuadSim` remain untouched.

## Approval record

The user approved this plan on 2026-07-28.
