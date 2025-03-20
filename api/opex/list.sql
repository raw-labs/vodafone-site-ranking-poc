-- @param site_types A comma-separated list of site types. Permissible values are: 
--        [LTC, P-core, PX, regular, CHE, NFV, PABR, Amitie, RA, OpX, Gi-LAN]
-- @type site_types varchar
-- @default site_types null

-- @param site_codes A comma-separated list of site codes.
-- @type site_codes varchar
-- @default site_codes null

-- @param site_name The name of the site. Substring search is supported.
-- @type site_name varchar
-- @default site_name null

-- @param site_region The geographic region of the site (UK). Substring search is supported.
-- @type site_region varchar
-- @default site_region null

-- @param site_address The UK address of the site. Substring search is supported.
-- @type site_address varchar
-- @default site_address null

-- @param freehold_leasehold Freehold/Leasehold indication. 
--        Permissible values are: [Freehold, Leasehold]
-- @type freehold_leasehold varchar
-- @default freehold_leasehold null

-- @param site_status Permissible values are: [Normal, Closed, Planned Closure, Restricted]
-- @type site_status varchar
-- @default site_status null

-- @param gis_migrated True if the site has been migrated to GIS.
-- @type gis_migrated boolean
-- @default gis_migrated null

-- @param restricted True if the site access is restricted.
-- @type restricted boolean
-- @default restricted null

-- @param comments Comments or notes about sites. Substring search is supported.
-- @type comments varchar
-- @default comments null

-- @param power_resilience Power resilience. 
--        Permissible values: [Mixed (Both N & N+N), N only, N+N (Full A&B), N+N (Resilient)]
-- @type power_resilience varchar
-- @default power_resilience null

-- @param network_domain Distinguishes between mobile (MTX, LTC) and fixed sites. 
--        Permissible values are: [mobile, fixed]
-- @type network_domain varchar
-- @default network_domain null

-- @param year Year of opex data to be processed.
-- @type year integer
-- @default year 2024

-- @param min_month Minimum month (1..12) of opex data to be processed. 
--        All months between min_month..max_month are included.
-- @type min_month integer
-- @default min_month 1

-- @param max_month Maximum month (1..12) of opex data to be processed.
--        All months between min_month..max_month are included.
-- @type max_month integer
-- @default max_month 12

-- @return Each site_code plus an array containing monthly cost_k_gbp
--         with zero replaced by average-of-prior-months.

WITH 
/* 
   1. Use a RECURSIVE CTE to treat 0.0 as missing. 
      We'll fill it by average of prior non-zero months.
*/
RECURSIVE fill_imputed AS (
  -- (a) Anchor: the earliest month for each site
  SELECT
    sm.site_code,
    sm.month_num,
    /* If raw_cost_k_gbp is 0 then treat as NULL - missing - in the recursion logic. */
    CASE WHEN sm.raw_cost_k_gbp=0 THEN NULL
         ELSE sm.raw_cost_k_gbp
    END AS cost_k_gbp,
    -- running_sum
    CASE WHEN sm.raw_cost_k_gbp=0 THEN 0
         ELSE sm.raw_cost_k_gbp
    END AS running_sum,
    CASE WHEN sm.raw_cost_k_gbp=0 THEN 0
         ELSE 1
    END AS running_count
  FROM site_months_left_joined sm
  WHERE sm.month_num = (
    -- find minimum month for each site_code
    SELECT MIN(month_num)
    FROM site_months_left_joined
    WHERE site_code = sm.site_code
  )

  UNION ALL

  -- (b) For each next month, if cost=0 => impute from prior average
  SELECT
    nxt.site_code,
    nxt.month_num,
    COALESCE(
      NULLIF(nxt.raw_cost_k_gbp, 0),
      CASE WHEN prv.running_count=0 THEN 0
           ELSE prv.running_sum / prv.running_count
      END
    ) AS cost_k_gbp,
    prv.running_sum
      + COALESCE(
          NULLIF(nxt.raw_cost_k_gbp, 0),
          CASE WHEN prv.running_count=0 THEN 0
               ELSE prv.running_sum / prv.running_count
          END
        ) AS running_sum,
    prv.running_count + 1 AS running_count
  FROM fill_imputed prv
  JOIN site_months_left_joined nxt
    ON prv.site_code = nxt.site_code
   AND nxt.month_num = prv.month_num + 1
),
unique_postal_codes AS (
  SELECT postcode
  FROM vdf.vfsites
  GROUP BY postcode
  HAVING COUNT(*) = 1
),
split_site_codes AS (
  SELECT TRIM(x) AS code
  FROM regexp_split_to_table(COALESCE(:site_codes, ''), ',') AS x
),

/* 2. Filter Sites with your standard conditions */
filtered_sites AS (
  SELECT *
  FROM vdf.vfsites
  WHERE
    (
      :site_types IS NULL
      OR regexp_split_to_array(
           COALESCE(
             TRIM(REPLACE(UPPER(:site_types), '-', '')), 
             ''
           ), 
           ','
         )
      &&
      regexp_split_to_array(
        TRIM(
          REPLACE(
            REPLACE(UPPER(site_category), 'PABR', 'PABR,PCORE')
            || ',' ||
            UPPER(site_type),
            '-',''
          )
        ),
        ','
      )
    )
    AND (
      :site_codes IS NULL
      OR UPPER(TRIM(site_code)) IN (
          SELECT UPPER(TRIM(code)) FROM split_site_codes
      )
    )
    AND (:site_name IS NULL OR site_name ILIKE CONCAT('%', :site_name, '%'))
    AND (:site_region IS NULL OR UPPER(region) ILIKE CONCAT(:site_region, '%'))
    AND (:site_address IS NULL OR address ILIKE CONCAT('%', :site_address, '%'))
    AND (:freehold_leasehold IS NULL OR UPPER(freehold_leasehold) = UPPER(:freehold_leasehold))
    AND (:site_status IS NULL OR status = :site_status)
    AND (
      :gis_migrated IS NULL
      OR (:gis_migrated = true  AND UPPER(gis_migrated) = 'TRUE')
      OR (:gis_migrated = false AND UPPER(gis_migrated) = 'FALSE')
    )
    AND (
      :restricted IS NULL
      OR (:restricted = true  AND UPPER(restricted) = 'TRUE')
      OR (:restricted = false AND UPPER(restricted) = 'FALSE')
    )
    AND (
      :comments IS NULL
      OR comments ILIKE CONCAT('%', :comments, '%')
    )
    AND (
      :power_resilience IS NULL
      OR UPPER(power_resilience) ILIKE CONCAT('%', :power_resilience, '%')
    )
    AND (
      :network_domain IS NULL
      OR (UPPER(:network_domain) = 'MOBILE' AND site_type IN ('MTX','LTC'))
      OR (UPPER(:network_domain) = 'FIXED'  AND site_type NOT IN ('MTX','LTC'))
    )
),

month_range AS (
  SELECT generate_series(:min_month, :max_month) AS month_num
),

/* 3. CROSS JOIN each site with each month */
site_months AS (
  SELECT s.site_code, m.month_num
  FROM filtered_sites s
  CROSS JOIN month_range m
),

/* 4. Summarize monthly cost from bridging logic then vfopex. 
      Convert reading_value to kGBP then reading_value * 0.25 / 1000.
*/
site_months_left_joined AS (
  SELECT
    sm.site_code,
    sm.month_num,
    COALESCE(
      ROUND(
        SUM(CAST(o.reading_value AS DECIMAL) * 0.25) / 1000, 
        4
      ), 
      0.0
    ) AS raw_cost_k_gbp  -- might be 0 if no data
  FROM site_months sm
  LEFT JOIN vdf.vfbridge b
    ON UPPER(TRIM(b.site_code)) = UPPER(TRIM(sm.site_code))
    OR (
      b.postcode IN (SELECT postcode FROM unique_postal_codes)
      AND b.postcode = (
        SELECT fs.postcode FROM filtered_sites fs
        WHERE fs.site_code = sm.site_code LIMIT 1
      )
    )
    OR (
      b.site_code IS NOT NULL
      AND (
        TRIM(sm.site_code) LIKE CONCAT('%(', UPPER(TRIM(b.site_code)), ')%')
      )
      OR (UPPER(TRIM(b.site_code)) ~ CONCAT(sm.site_code, '\\s*[,&].*'))
      OR (UPPER(TRIM(b.site_code)) ~ CONCAT('.*[,&]\\s*', sm.site_code))
    )
  LEFT JOIN vdf.vfopex o
    ON UPPER(TRIM(b.bridge_site_code)) = UPPER(TRIM(o.sitecode))
    AND DATE_PART('year',  CAST(o.reading_date AS DATE)) = :year
    AND DATE_PART('month', CAST(o.reading_date AS DATE)) = sm.month_num
  GROUP BY sm.site_code, sm.month_num
),

/* 5. final_filled then pick final cost after the recursion. */
final_filled AS (
  SELECT
    site_code,
    month_num,
    cost_k_gbp
  FROM fill_imputed
),

/* 6. Convert each sites monthly data into a single row with an array of costs. */
monthly_opex_imputed AS (
  SELECT
    site_code,
    ARRAY_AGG(
      COALESCE(cost_k_gbp, 0.0) 
      ORDER BY month_num
    ) AS monthly_cost_k_gbp
  FROM final_filled
  GROUP BY site_code
)
SELECT distinct *
FROM monthly_opex_imputed
ORDER BY site_code;
