# Power BI Reporting Layer

![dashboard](./dashboard.png)

---

## Purpose and audience

**Framing:** Operational Performance Benchmarking.
**Audience:** Airline and airport operations executives.

The dashboard answers one headline question: *who is performing worst, and why?*

- **Top level:** worst-performing airports, carriers, and routes on on-time performance and cancellations.
- **Drill-down:** delay-cause attribution (carrier, weather, NAS, security, late aircraft) underneath each ranking.

Design choices follow from the audience: a single page, KPI cards first, dark navy theme, and no visual that needs explaining.

<!-- Screenshot -->
<!-- ![Dashboard](../images/dashboard.png) -->

---

## Connection

| Setting | Value |
|---|---|
| Source | Azure SQL Database |
| Server format | `<server>.database.windows.net` |
| Storage mode | Import |
| Refresh | Manual (see [Future work](#future-work)) |

The server name must be the fully qualified `.database.windows.net` form. A short name falls back to Named Pipes and fails to connect.

**Why Import over DirectQuery:** Import keeps visuals fast and allows the full DAX function set. DirectQuery would make the dashboard live, but on a serverless free-tier database every view would wake the paused database, adding roughly a minute of latency.

---

## Data model

A standard star schema, imported directly from the `warehouse` schema.

| Table | Grain | Key |
|---|---|---|
| `fact_flight` | One row per scheduled flight | `FlightKey` (deterministic hash) |
| `dim_date` | One row per calendar day | `FlightDate` |
| `dim_carrier` | One row per carrier (including merged/historical) | `CarrierID` |
| `dim_airport` | One row per airport | `AirportID` |
| `dim_airframe` | One row per tail number | `TailNumber` |

**Relationships** are single-direction, one-to-many from each dimension to the fact. Most are auto-detected from the foreign keys defined in the warehouse.

**Role-playing airport dimension:** the fact references `dim_airport` twice (origin and destination). Power BI allows only one active relationship between two tables, so origin is active and destination analysis uses `USERELATIONSHIP` inside the relevant measures.

**Date handling:** `dim_date` is marked as the model's date table and Auto Date/Time is disabled. Auto Date/Time was used only as a temporary stepping stone before a real date dimension existed.

**Units:** delays and durations in minutes; distance in statute miles.

---

## Measures

Measures are built by referencing existing measures rather than rewriting raw aggregations, so each business definition lives in exactly one place.

### Volume

| Measure | Definition |
|---|---|
| `Flights CY` | Flight count in the current filter context |
| `Flights PY` | `Flights CY` shifted back one year |
| `Flights YoY %` | Change from `Flights PY` to `Flights CY` |

### On-time performance

| Measure | Definition |
|---|---|
| On-time departure % | Share of non-cancelled flights departing within ±10 minutes of schedule |
| On-time arrival % | Share of non-cancelled flights arriving within ±10 minutes of schedule |

Cancelled flights are excluded from the denominator. A flight that never flew can't be on time or late.

### Cancellations and diversions

| Measure | Definition |
|---|---|
| `CancelledFlights` | Count of cancelled flights in context |
| `All_Carriers_Cancelled` | Cancellations with the carrier filter removed, used as a benchmark baseline |
| Diverted flights | Count of diverted flights in context |

Boolean flags are counted explicitly rather than aggregated directly, since summing or averaging a `BIT` column gives misleading gauge values:

```dax
CancelledFlights =
CALCULATE ( COUNTROWS ( fact_flight ), fact_flight[Cancelled] = TRUE () )
```

### KPI card pattern

Every KPI card uses the same three-measure pattern: **CY**, **PY**, and **YoY %**. This keeps cards consistent and means a new KPI only needs its CY measure defined; the other two follow mechanically.

---

## Visual notes

- **Box-and-whisker (MAQ Software custom visual):** delay distribution per airport. The category field must be at airport grain. Using `FlightKey` as the category renders one dot per flight instead of a box.
- **Gauges:** cancellation and diversion rates, driven by the explicit count measures above.
- **Slicer scoping:** Edit Interactions limits certain slicers to specific visuals, so benchmark baselines stay fixed while the focus carrier or airport changes.

---

## Refreshing the data

1. Run the ADF `Main` pipeline for the desired month(s).
2. Open the `.pbix` in Power BI Desktop.
3. Click **Refresh**.

If the database is paused, the first refresh may take about a minute while it resumes.

---

## Future work

### Reporting layer

- **Automated refresh:** add a final ADF Web activity that triggers a Power BI dataset refresh via the REST API. Requires publishing to the Power BI Service, a service principal or managed identity with workspace access, and appropriate licensing.
- **Publish to Power BI Service:** shareable link, scheduled refresh as a fallback.
- **Incremental refresh:** refresh only recent months instead of reimporting the full history once the dataset grows.
- **Delay-cause drill-down page:** a dedicated page for attribution, with drill-through from any airport, carrier, or route.
- **Structural shock timeline:** once history is backfilled, visualise the 2001 and 2020 drops as annotated events.
- **Holiday analysis:** populate `dim_date[IsHoliday]` (currently stubbed to 0) and compare holiday vs non-holiday performance.
- **Route-level analysis:** connect `dim_route` to the fact via a route key; it currently exists but isn't related.
- **Airframe insights:** surface per-tail utilisation and wear-intensity metrics from `dim_airframe`.

### Pipeline and warehouse

- **Historical backfill:** load multiple years to support the shock timeline and year-over-year comparisons across long ranges.
- **Skip-if-loaded at pipeline level:** a Lookup + If Condition at the start of `Main` so a rerun of an already-loaded month doesn't re-download and re-stage it.
- **`MERGE`-based fact upsert** on `FlightKey`, replacing delete-and-insert for forced reloads.
- **Slowly changing dimensions:** track changes to airport and carrier attributes (SCD Type 1 or 2) instead of keeping first-seen values.
- **Quarantine routing:** send rows with unparseable dates, `UNKNOW` tail numbers, and other failures to `quarantine` instead of filtering them out.
- **Midnight handling:** map BTS `'2400'` to `00:00` in `dbo.ToTime` rather than returning NULL.
- **Timezone normalisation:** add UTC offsets to `dim_airport` so turnaround and cross-timezone durations are exact.
- **Continuous-hops logic:** implement `MaxContinuousHops` / `AvgContinuousHops` in `dim_airframe` with window functions.
- **Alerting:** wrap the main pipeline in an Execute Pipeline activity with a single failure path that sends a notification.
- **Production security:** restrict destructive procedures to FIDO2-authenticated admin identities via Microsoft Entra ID.
