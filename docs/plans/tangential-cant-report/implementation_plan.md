# Tangential Cant Validation Report — Implementation Plan

Status: Approved and completed on 2026-07-28  
Primary audience: VECTRA researchers, project reviewers, and future experiment operators  
Primary language: Korean, with mathematical symbols and code identifiers retained in English

## 1. Objective

Produce a complete, evidence-backed technical report for the implemented alternating tangential cant geometry. The report will replace the project’s current working interpretation of cant angle for future experiments while preserving the older radial-cant report artifacts as historical records.

The central result to document is:

> An alternating tangential cant of `[-10°, +10°, -10°, +10°]` increases modeled yaw-control authority by approximately `2.9461×` relative to zero cant, while retaining balanced hover, full allocation rank, feasible steady-hover allocation, and operation below the modeled motor-speed limit.

This is a model and hover-qualification result. The report will explicitly avoid claiming that yaw-step response, disturbance rejection, or flight performance has already been validated.

## 2. Deliverables

Create a new, self-contained report set:

- `docs/reports/tangential-cant-yaw-validation-report.md`
- `docs/reports/tangential-cant-yaw-validation-report.docx`
- `docs/reports/tangential-cant-yaw-validation-report.pdf`
- `docs/reports/assets/tangential-cant-geometry.png`
- `docs/reports/assets/tangential-cant-yaw-coefficients.png`
- `docs/reports/assets/tangential-cant-hover-qualification.png`
- `scripts/reporting/build_tangential_cant_validation_report.py`

The existing `cant-model-implementation-validation-report.*` files and their generator will remain unchanged by this task. This avoids overwriting the radial-cant-era report and preserves unrelated working-tree edits already present in those files.

## 3. Evidence Sources

The report will derive its claims from the current repository and a fresh MATLAB validation run:

- `config/geometries/cant_tangential_10.json`
- `src/matlab/+vectra/+quadsim/extendQuadModel.m`
- `scripts/validateCantImplementation.m`
- `scripts/validateProject.m`
- relevant unit tests under `tests/unit/`
- freshly generated `results/reports/cant-validation/validation-report.json`
- the user-confirmed MATLAB console results

The generator will fail rather than publish if required evidence is missing, non-finite, inconsistent, or marked as failed.

## 4. Report Structure

### Cover and document control

- Report title and subtitle
- Geometry ID and revision date
- Scope statement: simulation-model and hover qualification
- Evidence status and validation summary

### Technical summary

- One-paragraph answer-first conclusion
- Compact table of the principal findings
- Clear separation between verified results and future dynamic-response claims

### 1. Research objective and cant definition

- Define cant as rotation from the global/body-up direction toward the local tangential direction
- State that `0°` is vertical and `90°` is fully tangential
- Define the signed alternating motor pattern
- Explain why tangential cant, rather than radial cant, creates an arm-force yaw moment

### 2. Geometry and coordinate convention

- Top-view motor numbering and body axes
- Radial and tangential unit-vector definitions
- Signed motor-cant table:

| Motor | Arm direction | Cant | Rotor reaction sign |
|---|---:|---:|---:|
| M1 | `+X` | `-10°` | `-` |
| M2 | `+Y` | `+10°` | `+` |
| M3 | `-X` | `-10°` | `-` |
| M4 | `-Y` | `+10°` | `+` |

### 3. Mathematical model

For motor azimuth `φᵢ`:

```text
eᵣ,ᵢ = [cos φᵢ, sin φᵢ, 0]ᵀ
eₜ,ᵢ = [-sin φᵢ, cos φᵢ, 0]ᵀ
uᵢ = sin θᵢ eₜ,ᵢ + cos θᵢ ẑ
```

The yaw contributions will be derived as:

```text
M_z,arm,i = d C_T sin θᵢ nᵢ²
M_z,reaction,i = sᵢ C_Q cos θᵢ nᵢ²
B_yaw,i = d C_T sin θᵢ + sᵢ C_Q cos θᵢ
```

The text will explain the signed-angle and rotor-direction convention that makes the arm-force and reaction-torque terms reinforce one another for the selected alternating geometry.

### 4. Implementation

- Geometry configuration and validation rules
- Motor-axis construction
- Force and moment propagation
- Cant-aware allocation matrix
- Zero-cant compatibility
- Failure conditions for invalid geometry or infeasible allocation

### 5. Validation method

- Configuration checks
- Analytic coefficient checks
- Equal-command balance checks
- Allocation rank and steady-hover feasibility
- Smoke-hover simulation and RPM-limit checks
- Zero-cant regression
- Complete automated test-suite result

### 6. Results

Report the verified values:

| Metric | Result |
|---|---:|
| Geometry | `alternating-tangential-cant-10` |
| Cant angles | `[-10°, +10°, -10°, +10°]` |
| Zero-cant yaw coefficient magnitude | `2.9250 × 10⁻⁹ N·m/rpm²` |
| Tangential-cant yaw coefficient magnitude | `8.6175 × 10⁻⁹ N·m/rpm²` |
| Yaw-authority gain | `2.9461×` |
| Expected vertical-force scale | `0.9848078` |
| Actual vertical-force scale | `0.9848078` |
| Expected hover-RPM ratio | `1.0077` |
| Simulated hover-RPM ratio | `1.0081` |
| Allocation rank | `4` |
| Hover allocation residual norm | `5.3560 × 10⁻¹⁹` |
| Steady-hover allocation feasible | Yes |
| Maximum simulated RPM | approximately `4302 rpm` |
| Motor limit exceeded | No |
| Automated tests | `19 passed, 0 failed` |

The report will also state:

- expected vertical-force reduction: approximately `1.5192%`
- expected hover-RPM increase: approximately `0.7684%`
- simulated hover-RPM increase: approximately `0.8134%`
- equal-command horizontal-force and total-moment sums are numerically balanced

### 7. Interpretation

- Why the tangential force component generates yaw moment
- Why alternating signs preserve common yaw command authority
- Relationship between increased yaw authority and the small vertical-thrust penalty
- Meaning of full allocation rank and a near-zero hover residual
- What the result does and does not establish

### 8. Limitations and uncertainty

- Static `C_T` and `C_Q` coefficients
- No motor/propeller calibration to the final aircraft
- No aerodynamic rotor–rotor or rotor–frame interaction
- No structural or servo/mount compliance
- Short smoke-hover simulation
- No closed-loop yaw-step comparison yet
- No PX4 SITL/HITL, bench, or flight validation
- Numerical results are model-specific and not yet physical-aircraft performance guarantees

### 9. Next experiment

Define the next controlled comparison between `0°` and `10°` tangential cant:

- identical mass, center of gravity, controller, propeller, battery model, and environment
- yaw-step and yaw-disturbance cases
- rise time, settling time, overshoot, integrated absolute error, RMS tracking error
- peak/differential motor command, saturation duration, and energy use
- explicit rejection of allocation-infeasible or saturated runs

The report will note that the broader approved cant sweep remains `0°`, `10°`, and `20°`.

### 10. Reproduction and traceability

- Exact MATLAB entry points
- Expected console/report fields
- Source/configuration paths
- Test command and acceptance criteria
- Report generation command
- Artifact provenance and revision information

### References

- Repository source and validation artifacts
- Quadrotor force/moment convention used by the model
- Vendor QuadSim baseline, identified as pinned and unmodified

## 5. Visual Plan

### Figure 1 — Tangential cant geometry

Type: top-view engineering schematic  
Purpose: show body axes, motor positions, tangential directions, signed cant pattern, and the definition that `0°` is vertical while `90°` is fully tangential  
Takeaway: the cant direction follows the tangent at each motor, not the radial arm direction

### Figure 2 — Signed yaw coefficients by motor

Type: centered grouped bar or lollipop chart  
Series: zero cant versus alternating tangential `10°`  
Encoding: motor on the category axis; signed `N·m/rpm²` coefficient on the value axis  
Takeaway: signs remain alternating and balanced, while coefficient magnitude increases from `2.9250 × 10⁻⁹` to `8.6175 × 10⁻⁹`

### Figure 3 — Hover qualification

Type: compact comparison chart  
Measures: vertical-force scale and hover-RPM ratio, with expected and simulated values visibly distinguished  
Takeaway: analytic and simulated results closely agree, and the yaw-authority increase is accompanied by a small hover penalty

Every figure will be followed immediately by a paragraph explaining what is plotted, the decision-relevant conclusion, and the limitation of the evidence.

## 6. Generation Approach

1. Run the current MATLAB validation and capture fresh structured evidence.
2. Write the Markdown report as the authoritative textual source.
3. Generate the three figures with explicit labels, units, and color-independent distinctions.
4. Generate the DOCX from the same structured report content.
5. Use `Times New Roman` for English/Latin text and `Batang` for Korean text, including mixed-language runs, code, and equations.
6. Produce the PDF from the finished DOCX so pagination and content match the primary document.
7. Keep the established navy/blue/gold visual language while improving legibility, table hierarchy, captions, and whitespace.

The generator will use deterministic inputs and will record the exact evidence values used in the report. It will not silently substitute hardcoded values when current validation evidence is absent.

## 7. Verification

### Evidence verification

- Confirm validation JSON parses successfully.
- Confirm `passed == true`.
- Assert geometry ID, cant type, signed angles, yaw coefficients, yaw gain, allocation rank, feasibility, RPM ratios, residual, finite state, and motor-limit status.
- Confirm all automated tests pass.
- Confirm zero-cant regression remains valid.

### Content verification

- Extract DOCX and PDF text.
- Check every required section heading, figure caption, metric, unit, geometry ID, and limitation statement.
- Verify Markdown, DOCX, and PDF report the same numerical values.
- Confirm no stale radial-cant claim appears as the current geometry definition.

### Visual verification

- Render every DOCX page to PNG and inspect every page.
- Render every PDF page to PNG and inspect every page.
- Check cover, running headers/footers, tables, equations, chart labels, page breaks, captions, and references.
- Confirm there are no missing Korean glyphs, tofu squares, clipped text, overlaps, orphaned headings, or unreadably small labels.
- Check that the figures remain understandable without relying only on color.

### Repository verification

- Review the final diff.
- Confirm the historical report and unrelated dirty files were not overwritten.
- Scan new source and artifacts for accidental credentials or private data.

## 8. Acceptance Criteria

The report revision is complete when:

1. The new Markdown, DOCX, and PDF contain the full technical narrative above.
2. All three formats agree with the fresh MATLAB evidence.
3. The central `2.9461×` yaw-authority result is correctly derived and clearly qualified.
4. Hover balance, allocation feasibility, zero-cant regression, and the `19/19` test result are documented.
5. Dynamic yaw performance is presented only as future work.
6. Every DOCX and PDF page passes visual inspection, including Korean font rendering.
7. The older radial report artifacts and unrelated working-tree changes remain intact.

## 9. Completion Record

- Fresh MATLAB validation: `19 passed, 0 failed`; integrated cant validation passed.
- Final report formats: Markdown, DOCX, and PDF.
- Final pagination: 17 US Letter pages in both DOCX render and PDF.
- Font mapping: `Times New Roman` for `w:ascii`/`w:hAnsi`; `Batang` for `w:eastAsia`/`w:cs`.
- Accessibility audit: no high-, medium-, or low-severity findings.
- Visual audit: all 17 pages inspected; no clipping, overlap, missing glyphs, or broken figures.
- PDF parity: all 17 PDF render pages are pixel-identical to the final DOCX-derived render.
