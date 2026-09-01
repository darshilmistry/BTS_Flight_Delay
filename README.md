# US Flight Delay Data Warehouse

> **Status: in progress.** Ingestion and dimensional modelling are underway. Power BI layer not yet built.

A star-schema warehouse on Azure SQL for two decades of US domestic flight performance data, built to study how delays originate and propagate through an air transport network.

Stack: Azure SQL Database · T-SQL · Azure Blob Storage · Azure Data Factory · Power BI


## The question

Roughly 20% of US domestic flights arrive late, and the Bureau of Transportation Statistics attributes every minute of that delay to one of five causes. The interesting part is that the largest single bucket is *late-arriving aircraft* — delay inherited from the same airframe's previous leg. Most delay isn't originated. It's propagated.

This warehouse is built to quantify that, and to answer:

- **Attribution** - which cause dominates, and does that change by carrier, airport, and season?
- **Shocks** - the dataset contains two structural breaks: September 2001, when the network was grounded, and April 2020, when 41.3% of scheduled flights were cancelled and only 194,390 flights operated against a prior record low of 370,027. How long is the recovery, and does the network return to the same shape?
- **Carrier reliability over two decades**, across mergers - carrier codes are reused by different airlines over time, which is a modelling problem rather than a footnote.
- **Airport and route concentration** - do delays cluster in a small set of nodes (ORD, EWR, LGA, SFO), and does congestion at one propagate outward?

## Data source

Bureau of Transportation Statistics — Airline On-Time Performance.

| | |
|---|---|
| Publisher | US DOT / BTS |
| Format | Zipped CSV, one file per month |
| Access | Direct download, no registration or API key |
| Volume | ~500–700k flights/month, ~6–7M/year |
| History | October 1987 – present |
| Columns | 109 |
| Licence | US public domain |

**Scope: 2003–present.** The five delay-cause columns don't exist before June 2003, and they carry the central analytical question. Earlier years are optional stretch scope for the 9/11 story.

## Architecture

```
BTS monthly ZIPs
      │
      ▼
Azure Blob Storage ──── raw landing zone, one blob per month, immutable
      │
      ▼
Azure Data Factory ──── copy activity, orchestration, scheduling
      │
      ▼
Azure SQL Database
      ├── staging       all-VARCHAR landing tables, no type coercion on load
      ├── quarantine    rejected rows retained as JSON + rejection reason
      └── warehouse     star schema
      │
      ▼
Power BI ─────────────── semantic model, DAX measures, published report
```

Deliberately **not** used: Synapse, Fabric, Databricks, Event Hubs. None is required at this volume and each is a cost sink.


## Design decisions

**Staging is all-VARCHAR.** No type coercion happens on load. A malformed timestamp in a 109-column CSV shouldn't fail an entire monthly batch, so typing is deferred to the staging-to-warehouse transform where failures are attributable to a specific row and column.

**Rejected rows are quarantined, not dropped.** Rows that fail validation are written to a quarantine table with the full original row preserved as JSON in `NVARCHAR(MAX)`, alongside the rejection reason. Silently discarding records isn't clean data; it's an unaccounted-for gap that surfaces months later as a reconciliation problem. Quarantined rows can be repaired and replayed.

**Time fields are converted, not cast.** BTS stores local times as bare `HHMM` strings, which `CAST` won't accept. A scalar function `dbo.ToTime` uses `STUFF` to insert the colon and `TRY_CAST` to `TIME(0)`, returning `NULL` rather than erroring on the malformed values that do appear in the source.

**Airport dimension keyed on `AirportSeqID`.** BTS provides both `AirportID` (stable across time) and `AirportSeqID` (changes when an airport's attributes change, preserving point-in-time truth). SeqID gives historically accurate airport attributes per flight; the tradeoff is that SeqID fragments across years, so multi-year joins on this key need care. Documented here because it's the single most consequential key choice in the model.


## Load engineering notes

Getting the first month in took more debugging than expected. Recorded here because these are the failure modes anyone loading BTS data will hit:

| Symptom | Cause | Fix |
|---|---|---|
| Load fails on last row | Trailing `rows selected` artifact line — file was a query export, not a direct BTS download | Re-download from source |
| Every row lands in one column | CRLF vs LF mismatch | `ROWTERMINATOR = '0x0a'` |
| 110 fields against 109 declared columns | Trailing comma on every row | Added a filler column to absorb it |
| Path not found | Parentheses in filename | Renamed on upload |

**Diagnostic technique worth reusing:** when the row terminator is the suspect, load into a single-column staging table first. If the whole file arrives as one row, the terminator is wrong. This isolates the problem in one query instead of guessing at `BULK INSERT` options.


## Azure setup

Blob access uses the SAS-token pattern rather than embedding credentials in queries:

```
DATABASE SCOPED CREDENTIAL  ← SAS token
        │
EXTERNAL DATA SOURCE        ← blob container URL
        │
BULK INSERT / OPENROWSET
```

Running on the Azure SQL free offer (100,000 vCore-seconds/month, 32 GB) with auto-pause enabled. Single resource group so teardown is one delete. Data Factory triggers stay disabled between development sessions - ADF bills per activity run and is the main cost risk in this stack.


## Repository structure

```
├── sql/
│   ├── 00_schemas.sql          staging, warehouse, quarantine
│   ├── 01_external_source.sql  master key, credential, data source
│   ├── 02_staging.sql          landing tables
│   ├── 03_functions.sql        dbo.ToTime
│   ├── 04_dimensions.sql       dim_airport, dim_date, dim_carrier
│   └── 05_fact.sql             fact_flight
├── adf/                        pipeline definitions
├── powerbi/                    .pbix and semantic model
└── docs/                       project brief, data dictionary
```

---

## Roadmap

- [x] Azure SQL + Blob Storage provisioned, external data source configured
- [x] Schemas: staging, warehouse, quarantine
- [x] First monthly load debugged and landed
- [x] `dim_airport`
- [x] `dbo.ToTime` conversion function
- [x] Quarantine table with JSON row retention
- [x] `fact_flight` — 34 columns, time fields pending conversion
- [ ] `dim_date`, `dim_carrier` (carrier code reuse across mergers)
- [ ] Backfill 2003–present
- [ ] Data Factory pipeline for monthly incremental loads
- [ ] Power BI semantic model - KPI cards, delay attribution over time, worst-airport ranking, shock timeline

## Data notes

Two documented quirks in the source that affect any analysis built on it:

- **Zero-filled nulls.** Delay-cause columns contain `0` for both "this cause contributed nothing" and "no cause breakdown recorded." The two are not distinguishable in the raw file.
- **Schema drift.** Column sets change across years. Loads are validated per-batch rather than assuming a fixed 109-column shape holds for all of 2003–present.