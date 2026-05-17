# DAX Measures Documentation

This document contains the custom DAX measures used in the **Global Petroleum Export Performance Analysis** dashboard developed in Microsoft Power BI.

The measures were designed to support:
- Executive KPI reporting
- Dynamic business insights
- Interactive filtering
- Performance ranking analysis
- Dashboard storytelling

---

# Core KPI Measures

## Total Revenue

Calculates the total petroleum export revenue.

```DAX
Total Revenue =
SUM(vw_global_exports_analytics[export_value_usd_m])
```

---

## Total Export Volume

Calculates the total export volume across all records.

```DAX
Total Export Volume =
SUM(vw_global_exports_analytics[export_volume_mbbl])
```

---

## Average Revenue Per Barrel

Calculates the average revenue generated per barrel exported.

```DAX
Avg Revenue Per Barrel =
AVERAGE(vw_global_exports_analytics[revenue_per_barrel])
```

---

## OPEC Revenue Contribution %

Calculates the percentage contribution of OPEC countries to total export revenue.

```DAX
OPEC Revenue Contribution % =
DIVIDE(
    CALCULATE(
        [Total Revenue],
        vw_global_exports_analytics[opec_status] = "OPEC"
    ),
    [Total Revenue],
    0
)
```

---

# Dynamic Insight Measures

## Top Country by Revenue

Returns the highest revenue-generating export country dynamically based on filters and slicers.

```DAX
Top Country by Revenue =
VAR TopCountry =
    TOPN(
        1,
        SUMMARIZE(
            vw_global_exports_analytics,
            vw_global_exports_analytics[exporting_country],
            "Revenue", [Total Revenue]
        ),
        [Revenue],
        DESC
    )
RETURN
    CONCATENATEX(
        TopCountry,
        vw_global_exports_analytics[exporting_country],
        ", "
    )
```

---

## Best Oil Type

Returns the best-performing oil category based on total revenue.

```DAX
Best Oil Type =
VAR TopOilType =
    TOPN(
        1,
        SUMMARIZE(
            vw_global_exports_analytics,
            vw_global_exports_analytics[oil_type],
            "Revenue", [Total Revenue]
        ),
        [Revenue],
        DESC
    )
RETURN
    CONCATENATEX(
        TopOilType,
        vw_global_exports_analytics[oil_type],
        ", "
    )
```

---

## Highest Revenue Year

Returns the year with the highest total export revenue.

```DAX
Highest Revenue Year =
VAR TopYear =
    TOPN(
        1,
        SUMMARIZE(
            vw_global_exports_analytics,
            vw_global_exports_analytics[year],
            "Revenue", [Total Revenue]
        ),
        [Revenue],
        DESC
    )
RETURN
    CONCATENATEX(
        TopYear,
        vw_global_exports_analytics[year],
        ", "
    )
```

---

# Dashboard Purpose

These DAX measures were used to:
- Drive executive KPI cards
- Generate dynamic dashboard insights
- Support slicer-responsive analytics
- Enable business storytelling through data
- Improve interactivity and analytical depth

---

# Tools Used

| Tool | Purpose |
|---|---|
| Microsoft Power BI | Dashboard development |
| DAX | KPI and analytical measure creation |
| PostgreSQL | Data preparation and transformation |
| PgAdmin4 | SQL development environment |

---

# Project

Global Petroleum Export Performance Analysis
