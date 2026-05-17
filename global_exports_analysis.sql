/* =========================================================
PROJECT: GLOBAL PETROLEUM EXPORT PERFORMANCE ANALYSIS
========================================================= */

DROP VIEW IF EXISTS vw_global_exports_analytics;

CREATE VIEW vw_global_exports_analytics AS
WITH cleaned_data AS (
SELECT
TRIM("Export ID") AS export_id,
CAST("Year" AS INT) AS year,
CAST("Month" AS INT) AS month_number,
TO_CHAR(TO_DATE(CAST("Month" AS TEXT), 'MM'),'Month') AS month_name,
CONCAT(CAST("Year" AS TEXT),'-',LPAD(CAST("Month" AS TEXT), 2, '0')) AS year_month,
CASE
WHEN "Month" IN (1,2,3) THEN 'Q1'
WHEN "Month" IN (4,5,6) THEN 'Q2'
WHEN "Month" IN (7,8,9) THEN 'Q3'
ELSE 'Q4'
END AS quarter,
INITCAP(TRIM("Country")) AS exporting_country,
INITCAP(TRIM("Region")) AS region,
INITCAP(TRIM("Destination_Country")) AS destination_country,
INITCAP(TRIM("Oil_Type")) AS oil_type,
INITCAP(TRIM("Transport_Mode")) AS transport_mode,
CASE
WHEN "OPEC_Member" = 1 THEN 'OPEC'
ELSE 'Non-OPEC'
END AS opec_status,
ROUND(CAST("Export_Volume_Mbbl" AS NUMERIC), 2) AS export_volume_mbbl,
ROUND(CAST("Export_Value_USD_M" AS NUMERIC), 2) AS export_value_usd_m,
ROUND(CAST("Export_Value_USD_M" AS NUMERIC) / NULLIF(CAST("Export_Volume_Mbbl" AS NUMERIC), 0),2) AS revenue_per_barrel,
CASE
WHEN "Export_Volume_Mbbl" < 30 THEN 'Low Volume'
WHEN "Export_Volume_Mbbl" BETWEEN 30 AND 70 THEN 'Medium Volume'
ELSE 'High Volume'
END AS volume_category,
CASE
WHEN "Export_Value_USD_M" < 3000 THEN 'Low Revenue'
WHEN "Export_Value_USD_M" BETWEEN 3000 AND 7000 THEN 'Medium Revenue'
ELSE 'High Revenue'
END AS revenue_category
FROM global_exports
WHERE "Export_Volume_Mbbl" IS NOT NULL
AND "Export_Value_USD_M" IS NOT NULL
AND "Country" IS NOT NULL
AND "Destination_Country" IS NOT NULL
)
SELECT *
FROM cleaned_data;

/* =========================================================
EXECUTIVE KPI QUERY
========================================================= */

SELECT
COUNT(DISTINCT export_id) AS total_export_transactions,
COUNT(DISTINCT exporting_country) AS total_exporting_countries,
COUNT(DISTINCT destination_country) AS total_destination_countries,
ROUND(SUM(export_volume_mbbl), 2) AS total_export_volume_mbbl,
ROUND(SUM(export_value_usd_m), 2) AS total_export_revenue_usd_m,
ROUND(AVG(revenue_per_barrel), 2) AS avg_revenue_per_barrel,
ROUND(
100.0 * SUM(
CASE
WHEN opec_status = 'OPEC'
THEN export_value_usd_m
ELSE 0
END
)
/ SUM(export_value_usd_m),
2
) AS opec_revenue_share_pct
FROM vw_global_exports_analytics;

/* =========================================================
TOP EXPORTING COUNTRIES
========================================================= */

SELECT
exporting_country,
ROUND(SUM(export_volume_mbbl), 2) AS total_volume,
ROUND(SUM(export_value_usd_m), 2) AS total_revenue,
ROUND(AVG(revenue_per_barrel), 2) AS avg_revenue_per_barrel,
RANK() OVER (
ORDER BY SUM(export_value_usd_m) DESC
) AS revenue_rank
FROM vw_global_exports_analytics
GROUP BY exporting_country
ORDER BY total_revenue DESC;

/* =========================================================
REGIONAL PERFORMANCE ANALYSIS
========================================================= */

SELECT
region,
ROUND(SUM(export_volume_mbbl), 2) AS total_export_volume,
ROUND(SUM(export_value_usd_m), 2) AS total_export_revenue,
ROUND(AVG(revenue_per_barrel), 2) AS avg_revenue_per_barrel,
COUNT(DISTINCT exporting_country) AS number_of_exporters
FROM vw_global_exports_analytics
GROUP BY region
ORDER BY total_export_revenue DESC;

/* =========================================================
OIL TYPE PROFITABILITY ANALYSIS
========================================================= */

SELECT
oil_type,
ROUND(SUM(export_volume_mbbl), 2) AS total_volume,
ROUND(SUM(export_value_usd_m), 2) AS total_revenue,
ROUND(AVG(revenue_per_barrel), 2) AS avg_price_efficiency,
DENSE_RANK() OVER (
ORDER BY AVG(revenue_per_barrel) DESC
) AS profitability_rank
FROM vw_global_exports_analytics
GROUP BY oil_type
ORDER BY avg_price_efficiency DESC;
/* =========================================================
TRANSPORT MODE ANALYSIS
========================================================= */
SELECT
transport_mode,
ROUND(SUM(export_volume_mbbl), 2) AS total_volume,
ROUND(SUM(export_value_usd_m), 2) AS total_revenue,
ROUND(AVG(revenue_per_barrel), 2) AS avg_revenue_per_barrel,
COUNT(*) AS shipment_count
FROM vw_global_exports_analytics
GROUP BY transport_mode
ORDER BY total_revenue DESC;

/* =========================================================
DESTINATION MARKET ANALYSIS
========================================================= */

SELECT
destination_country,
ROUND(SUM(export_volume_mbbl), 2) AS imported_volume,
ROUND(SUM(export_value_usd_m), 2) AS imported_value,
COUNT(DISTINCT exporting_country) AS supplier_count,
ROUND(AVG(revenue_per_barrel), 2) AS avg_import_price
FROM vw_global_exports_analytics
GROUP BY destination_country
ORDER BY imported_value DESC;

/* =========================================================
MONTHLY TREND ANALYSIS
========================================================= */

SELECT
year,
month_number,
year_month,
ROUND(SUM(export_volume_mbbl), 2) AS monthly_volume,
ROUND(SUM(export_value_usd_m), 2) AS monthly_revenue,
ROUND(AVG(revenue_per_barrel), 2) AS avg_monthly_price,
ROUND(
(
SUM(export_value_usd_m)
- LAG(SUM(export_value_usd_m)) OVER (
ORDER BY year, month_number
)
)
/
NULLIF(
LAG(SUM(export_value_usd_m)) OVER (
ORDER BY year, month_number
),
0
) * 100,
2
) AS revenue_growth_pct
FROM vw_global_exports_analytics
GROUP BY
year,
month_number,
year_month
ORDER BY
year,
month_number;

/* =========================================================
OPEC VS NON-OPEC ANALYSIS
========================================================= */

SELECT
opec_status,
ROUND(SUM(export_volume_mbbl), 2) AS total_volume,
ROUND(SUM(export_value_usd_m), 2) AS total_revenue,
ROUND(AVG(revenue_per_barrel), 2) AS avg_revenue_per_barrel,
COUNT(DISTINCT exporting_country) AS exporter_count
FROM vw_global_exports_analytics
GROUP BY opec_status
ORDER BY total_revenue DESC;

/* =========================================================
TOP DESTINATION MARKETS BY YEAR
========================================================= */

SELECT
year,
destination_country,
ROUND(SUM(export_value_usd_m), 2) AS yearly_import_value,
RANK() OVER (
PARTITION BY year
ORDER BY SUM(export_value_usd_m) DESC
) AS yearly_market_rank
FROM vw_global_exports_analytics
GROUP BY
year,
destination_country
ORDER BY
year,
yearly_market_rank;