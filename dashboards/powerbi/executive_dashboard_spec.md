# Executive Dashboard (Power BI) Specification

## Goal
Give hospital executives a fast, interactive view of revenue cycle performance and outcomes quality.

## Design Principles
- High-contrast, healthcare-friendly palette: navy (`#0B2545`), teal (`#2EC4B6`), amber (`#FFB703`), neutral grays.
- Prioritize visual hierarchy: KPI cards at top, trend narratives in middle, diagnostic visuals at bottom.
- Every chart must support cross-filtering and drill-through.

## Required KPI Cards
- Net Patient Revenue
- Operating Margin %
- Denial Rate %
- Case Mix Index (CMI)
- ALOS
- 30-day Readmission Rate
- Bed Occupancy %

## Core Visuals
1. Stacked area: Revenue by payer category over time.
2. Line + target band: Denial rate trend with monthly target.
3. Combo chart: CMI (line) with discharge volume (columns).
4. Waterfall: Gross charges -> contractuals -> denials -> net revenue.
5. Decomposition tree: Margin by hospital -> service line -> DRG -> payer.
6. Matrix heatmap: State x KPI variance to target.

## Interactivity Requirements
- Global slicers: Date range, Hospital, State, Service Line, Payer.
- Drill-through pages:
  - Revenue Leakage Analysis
  - Readmission and LOS Detail
  - Denial Root Cause Explorer
- Dynamic tooltips with sparkline for trailing 12 months.
- Bookmarks:
  - Financial Focus
  - Quality & Compliance Focus

## Suggested DAX Measures
```DAX
Net Patient Revenue = SUM('fact_revenue_cycle'[paid_amount])

Denial Rate % = DIVIDE(SUM('fact_revenue_cycle'[denied_amount]), SUM('fact_revenue_cycle'[total_charge_amount]))

ALOS = AVERAGE('fact_outcomes_quality'[alos])

Readmission Rate 30D = AVERAGE('fact_outcomes_quality'[readmission_rate_30d])
```
