----------------------------------------------------------------
-- Statement #1: Drop the opex table if it exists
----------------------------------------------------------------
DROP TABLE IF EXISTS vfopex_tmp;

CREATE TABLE vfopex_tmp AS
	SELECT 
	  sitename,
	  sitecode,
	  vod_site_type,
	  sitealias,
	  status,
	  meterno,
	  activedate,
	  closeddate,
	  supplier,
	  utility,
	  lastinvdate,
	  consumptionto,
	  actualreaddate,
	  (DATE('2023-04-01')) AS reading_date,
	  "2023_04_01_00_00_00" AS reading_value
	FROM opex
	UNION
	SELECT 
	  sitename,
	  sitecode,
	  vod_site_type,
	  sitealias,
	  status,
	  meterno,
	  activedate,
	  closeddate,
	  supplier,
	  utility,
	  lastinvdate,
	  consumptionto,
	  actualreaddate,
	  (DATE('2023-05-01')) AS reading_date,
	  "2023_05_01_00_00_00" AS reading_value
	FROM opex
	UNION
	SELECT 
	  sitename,
	  sitecode,
	  vod_site_type,
	  sitealias,
	  status,
	  meterno,
	  activedate,
	  closeddate,
	  supplier,
	  utility,
	  lastinvdate,
	  consumptionto,
	  actualreaddate,
	  (DATE('2023-06-01')) AS reading_date,
	  "2023_06_01_00_00_00" AS reading_value
	FROM opex
	UNION
	SELECT 
	  sitename,
	  sitecode,
	  vod_site_type,
	  sitealias,
	  status,
	  meterno,
	  activedate,
	  closeddate,
	  supplier,
	  utility,
	  lastinvdate,
	  consumptionto,
	  actualreaddate,
	  (DATE('2023-07-01')) AS reading_date,
	  "2023_07_01_00_00_00" AS reading_value
	FROM opex
	UNION
	SELECT 
	  sitename,
	  sitecode,
	  vod_site_type,
	  sitealias,
	  status,
	  meterno,
	  activedate,
	  closeddate,
	  supplier,
	  utility,
	  lastinvdate,
	  consumptionto,
	  actualreaddate,
	  (DATE('2023-08-01')) AS reading_date,
	  "2023_08_01_00_00_00" AS reading_value
	FROM opex
	UNION
	SELECT 
	  sitename,
	  sitecode,
	  vod_site_type,
	  sitealias,
	  status,
	  meterno,
	  activedate,
	  closeddate,
	  supplier,
	  utility,
	  lastinvdate,
	  consumptionto,
	  actualreaddate,
	  (DATE('2023-09-01')) AS reading_date,
	  "2023_09_01_00_00_00" AS reading_value
	FROM opex
	UNION
	SELECT 
	  sitename,
	  sitecode,
	  vod_site_type,
	  sitealias,
	  status,
	  meterno,
	  activedate,
	  closeddate,
	  supplier,
	  utility,
	  lastinvdate,
	  consumptionto,
	  actualreaddate,
	  (DATE('2023-10-01')) AS reading_date,
	  "2023_10_01_00_00_00" AS reading_value
	FROM opex
	UNION
	SELECT 
	  sitename,
	  sitecode,
	  vod_site_type,
	  sitealias,
	  status,
	  meterno,
	  activedate,
	  closeddate,
	  supplier,
	  utility,
	  lastinvdate,
	  consumptionto,
	  actualreaddate,
	  (DATE('2023-11-01')) AS reading_date,
	  "2023_11_01_00_00_00" AS reading_value
	FROM opex
	UNION
	SELECT 
	  sitename,
	  sitecode,
	  vod_site_type,
	  sitealias,
	  status,
	  meterno,
	  activedate,
	  closeddate,
	  supplier,
	  utility,
	  lastinvdate,
	  consumptionto,
	  actualreaddate,
	  (DATE('2023-12-01')) AS reading_date,
	  "2023_12_01_00_00_00" AS reading_value
	FROM opex
	UNION
	SELECT 
	  sitename,
	  sitecode,
	  vod_site_type,
	  sitealias,
	  status,
	  meterno,
	  activedate,
	  closeddate,
	  supplier,
	  utility,
	  lastinvdate,
	  consumptionto,
	  actualreaddate,
	  (DATE('2024-01-01')) AS reading_date,
	  "2024_01_01_00_00_00" AS reading_value
	FROM opex
	UNION
	SELECT 
	  sitename,
	  sitecode,
	  vod_site_type,
	  sitealias,
	  status,
	  meterno,
	  activedate,
	  closeddate,
	  supplier,
	  utility,
	  lastinvdate,
	  consumptionto,
	  actualreaddate,
	  (DATE('2024-02-01')) AS reading_date,
	  "2024_02_01_00_00_00" AS reading_value
	FROM opex
	UNION
	SELECT 
	  sitename,
	  sitecode,
	  vod_site_type,
	  sitealias,
	  status,
	  meterno,
	  activedate,
	  closeddate,
	  supplier,
	  utility,
	  lastinvdate,
	  consumptionto,
	  actualreaddate,
	  (DATE('2024-03-01')) AS reading_date,
	  "2024_03_01_00_00_00" AS reading_value
	FROM opex
	UNION
	SELECT 
	  sitename,
	  sitecode,
	  vod_site_type,
	  sitealias,
	  status,
	  meterno,
	  activedate,
	  closeddate,
	  supplier,
	  utility,
	  lastinvdate,
	  consumptionto,
	  actualreaddate,
	  (DATE('2024-04-01')) AS reading_date,
	  "2024_04_01_00_00_00" AS reading_value
	FROM opex
	UNION
	SELECT 
	  sitename,
	  sitecode,
	  vod_site_type,
	  sitealias,
	  status,
	  meterno,
	  activedate,
	  closeddate,
	  supplier,
	  utility,
	  lastinvdate,
	  consumptionto,
	  actualreaddate,
	  (DATE('2024-05-01')) AS reading_date,
	  "2024_05_01_00_00_00" AS reading_value
	FROM opex
	UNION
	SELECT 
	  sitename,
	  sitecode,
	  vod_site_type,
	  sitealias,
	  status,
	  meterno,
	  activedate,
	  closeddate,
	  supplier,
	  utility,
	  lastinvdate,
	  consumptionto,
	  actualreaddate,
	  (DATE('2024-06-01')) AS reading_date,
	  "2024_06_01_00_00_00" AS reading_value
	FROM opex
	UNION
	SELECT 
	  sitename,
	  sitecode,
	  vod_site_type,
	  sitealias,
	  status,
	  meterno,
	  activedate,
	  closeddate,
	  supplier,
	  utility,
	  lastinvdate,
	  consumptionto,
	  actualreaddate,
	  (DATE('2024-07-01')) AS reading_date,
	  "2024_07_01_00_00_00" AS reading_value
	FROM opex
	UNION
	SELECT 
	  sitename,
	  sitecode,
	  vod_site_type,
	  sitealias,
	  status,
	  meterno,
	  activedate,
	  closeddate,
	  supplier,
	  utility,
	  lastinvdate,
	  consumptionto,
	  actualreaddate,
	  (DATE('2024-08-01')) AS reading_date,
	  "2024_08_01_00_00_00" AS reading_value
	FROM opex
	UNION
	SELECT 
	  sitename,
	  sitecode,
	  vod_site_type,
	  sitealias,
	  status,
	  meterno,
	  activedate,
	  closeddate,
	  supplier,
	  utility,
	  lastinvdate,
	  consumptionto,
	  actualreaddate,
	  (DATE('2024-09-01')) AS reading_date,
	  "2024_09_01_00_00_00" AS reading_value
	FROM opex
	UNION
	SELECT 
	  sitename,
	  sitecode,
	  vod_site_type,
	  sitealias,
	  status,
	  meterno,
	  activedate,
	  closeddate,
	  supplier,
	  utility,
	  lastinvdate,
	  consumptionto,
	  actualreaddate,
	  (DATE('2024-10-01')) AS reading_date,
	  "2024_10_01_00_00_00" AS reading_value
	FROM opex
	UNION
	SELECT 
	  sitename,
	  sitecode,
	  vod_site_type,
	  sitealias,
	  status,
	  meterno,
	  activedate,
	  closeddate,
	  supplier,
	  utility,
	  lastinvdate,
	  consumptionto,
	  actualreaddate,
	  (DATE('2024-11-01')) AS reading_date,
	  "2024_11_01_00_00_00" AS reading_value
	FROM opex
	UNION
	SELECT 
	  sitename,
	  sitecode,
	  vod_site_type,
	  sitealias,
	  status,
	  meterno,
	  activedate,
	  closeddate,
	  supplier,
	  utility,
	  lastinvdate,
	  consumptionto,
	  actualreaddate,
	  (DATE('2024-12-01')) AS reading_date,
	  "2024_12_01_00_00_00" AS reading_value
	FROM opex
;

DROP TABLE IF EXISTS site_avg_fill;

CREATE TABLE site_avg_fill AS
SELECT
    sitecode, meterno,
    AVG(
      CASE 
        WHEN reading_value IS NOT NULL 
             AND reading_value != '0'
        THEN CAST(reading_value AS DECIMAL)
        ELSE NULL
      END
    ) AS fill_value
FROM vfopex_tmp
WHERE reading_date like '2024%'
GROUP BY sitecode, meterno;


DROP TABLE IF EXISTS vfopex;

/* 
   Create vfopex_avg_fill table with the same columns as vfopex. 
   Then insert from vfopex, substituting fill_value where needed. 
*/
CREATE TABLE vfopex AS
SELECT 
    v.sitecode,
    v.sitename,
    v.vod_site_type,
    v.sitealias,
    v.status,
    v.meterno,
    v.activedate,
    v.closeddate,
    v.supplier,
    v.utility,
    v.lastinvdate,
    v.consumptionto,
    v.actualreaddate,
    v.reading_date,
    /* 
       For reading_value, if it’s zero or null, 
       use fill_value from site_avg_fill (if not null). 
       Otherwise keep the original. 
    */
    CASE 
      WHEN (v.reading_value IS NULL OR v.reading_value = '0')
         THEN COALESCE(ROUND(s.fill_value,1), v.reading_value)
      ELSE v.reading_value
    END AS reading_value
FROM vfopex_tmp v
LEFT JOIN site_avg_fill s 
    ON s.sitecode = v.sitecode and s.meterno = v.meterno;
 
