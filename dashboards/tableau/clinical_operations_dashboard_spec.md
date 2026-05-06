# Clinical Operations Dashboard (Tableau) Specification

## Goal
Enable service line leaders and operations managers to monitor throughput, outcomes, and patient experience in one interactive workspace.

## Layout
- Top: KPI strip (volume, wait time, ALOS, readmission, HCAHPS).
- Center-left: Department and service-line trend views.
- Center-right: Diagnosis/physician drill matrix.
- Bottom: Distribution and outlier analysis.

## Required Visuals
1. Department-level patient volume trend (monthly with moving average).
2. Service-line wait time boxplot (highlight outliers).
3. Satisfaction score by service line (diverging bar with benchmark line).
4. Readmission by diagnosis and payer (heatmap).
5. Physician performance scatter:
   - X = adjusted LOS
   - Y = readmission rate
   - Size = patient volume
   - Color = payer mix risk score
6. Detail table with actions to filter all views.

## Interactivity Requirements
- Filters: Hospital, Date, Department, Service Line, DRG/Diagnosis, Physician, Payer.
- Parameter toggle for metric focus: Volume / Throughput / Quality / Financial Risk.
- Set actions:
  - Click top decile performers.
  - Click bottom decile performers.
- Viz-in-tooltip for patient volume trend when hovering service lines.
- URL action to open payer-specific denial playbook docs.

## Tableau Calculations (examples)
```tableau
Denial Rate = SUM([Denied Amount]) / SUM([Total Charge Amount])

ALOS Variance = AVG([ALOS]) - AVG([Target ALOS])

Readmission Variance = AVG([Readmission Rate 30D]) - AVG([Benchmark Readmission Rate])
```
