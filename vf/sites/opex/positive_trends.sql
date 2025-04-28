-- @param site_types A comma-separated list of site types. Permissible values are:
--   [LTC, P-core, PX, regular, CHE, NFV, PABR, Amitie, RA, OpX, Gi-LAN]
-- @type site_types varchar
-- @default site_types null

-- @param site_codes A comma-separated list of site codes.
-- @type site_codes varchar
-- @default site_codes null

-- @param site_name The name of the site. Substring search is supported.
-- @type site_name varchar
-- @default site_name null

-- @param site_regions A comma-separated list of geographic regions (UK).
-- @type site_regions varchar
-- @default site_regions null

-- @param site_address The UK address of the site. Substring search is supported.
-- @type site_address varchar
-- @default site_address null

-- @param freehold_leasehold Freehold/Leasehold. Permissible values: [Freehold, Leasehold]
-- @type freehold_leasehold varchar
-- @default freehold_leasehold null

-- @param site_status Permissible values: [Normal, Closed, Planned Closure, Restricted]
-- @type site_status varchar
-- @default site_status null

-- @param gis_migrated True if the site is migrated to GIS.
-- @type gis_migrated boolean
-- @default gis_migrated null

-- @param restricted True if site access is restricted.
-- @type restricted boolean
-- @default restricted null

-- @param comments Substring search for site comments.
-- @type comments varchar
-- @default comments null

-- @param power_resilience Permissible values: [Mixed (Both N & N+N), N only, 
--      N+N (Full A&B), N+N (Resilient)]
-- @type power_resilience varchar
-- @default power_resilience null

-- @param network_domain [mobile|fixed] to distinguish MTX/LTC from others
-- @type network_domain varchar
-- @default network_domain null

-- @param year Year of the Opex data (default 2024).
-- @type year integer
-- @default year 2024

-- @param min_month Minimum month in [1..12]. 
-- @type min_month integer
-- @default min_month 1

-- @param max_month Maximum month in [1..12].
-- @type max_month integer
-- @default max_month 12

-- @param userid user identifier injected for authorization and data redaction purposes.
-- @type userid varchar
-- @default userid NULL

-- @return Sites showing a strictly decreasing monthly cost from min_month..max_month,
--         plus the first/last cost and drop_percentage between them.

WITH user_blacklist_opex AS (
  SELECT id
  FROM environment.secrets,
       unnest(string_to_array(secret, ',')) id
  WHERE name = 'user-blacklist-opex' AND id = :userid
), user_blacklist_capacity AS (
  SELECT id
  FROM environment.secrets,
       unnest(string_to_array(secret, ',')) id
  WHERE name = 'user-blacklist-capacity' AND id = :userid
), user_blacklist_space AS (
  SELECT id
  FROM environment.secrets,
       unnest(string_to_array(secret, ',')) id
  WHERE name = 'user-blacklist-space' AND id = :userid
), user_blacklist_lease AS (
  SELECT id
  FROM environment.secrets,
       unnest(string_to_array(secret, ',')) id
  WHERE name = 'user-blacklist-lease' AND id = :userid
), 
--------------------------------------------------------------------
-- 1. Filter Sites
--------------------------------------------------------------------
unique_postal_codes AS (
  SELECT postcode
  FROM vdf.vfsites
  GROUP BY postcode
  HAVING COUNT(*)=1
),
split_site_codes AS (
  SELECT TRIM(x) AS code
  FROM regexp_split_to_table(COALESCE(:site_codes, ''), ',') AS x
),
filtered_sites AS (
  SELECT *
  FROM vdf.vfsites
  WHERE
    (
      :site_types IS NULL
      OR (
        regexp_split_to_array(
          COALESCE(TRIM(REPLACE(UPPER(:site_types),'-','')), ''),
          ','
        )
        &&
        regexp_split_to_array(
          TRIM(
            REPLACE(
              REPLACE(UPPER(site_category),'PABR','PABR,PCORE')
              || ',' || UPPER(site_type),
            '-','')
          ),','
        )
      )
    )
    AND (
      :site_codes IS NULL
      OR UPPER(TRIM(site_code)) IN (
          SELECT UPPER(TRIM(code)) FROM split_site_codes
      )
    )
    AND (
      :site_name IS NULL
      OR UPPER(site_name) ILIKE CONCAT('%', UPPER(:site_name), '%')
    )
    AND (
      :site_regions IS NULL
      OR EXISTS (
        SELECT 1
        FROM unnest(
          regexp_split_to_array(TRIM(UPPER(:site_regions)), ',')
        ) arr1(elem1)
        CROSS JOIN unnest(
          regexp_split_to_array(TRIM(UPPER(region)), ',')
        ) arr2(elem2)
        WHERE TRIM(elem2) LIKE TRIM(elem1) || '%'
      )
    )
    AND (
      :site_address IS NULL
      OR UPPER(address) ILIKE CONCAT('%', UPPER(:site_address), '%')
    )
    AND (
      :freehold_leasehold IS NULL
      OR UPPER(freehold_leasehold) = UPPER(:freehold_leasehold)
    )
    AND (
      :site_status IS NULL
      OR status = :site_status
    )
    AND (
      :gis_migrated IS NULL
      OR (:gis_migrated = true AND UPPER(gis_migrated)='TRUE')
      OR (:gis_migrated = false AND UPPER(gis_migrated)='FALSE')
    )
    AND (
      :comments IS NULL
      OR UPPER(comments) ILIKE CONCAT('%', UPPER(:comments), '%')
    )
    AND (
      :restricted IS NULL
      OR (:restricted = true AND UPPER(restricted)='TRUE')
      OR (:restricted = false AND UPPER(restricted)='FALSE')
    )
    AND (
      :power_resilience IS NULL
      OR UPPER(power_resilience) ILIKE CONCAT('%', UPPER(:power_resilience), '%')
    )
    AND (
      :network_domain IS NULL
      OR (
        UPPER(:network_domain)='MOBILE'
        AND site_type IN ('MTX','LTC')
      )
      OR (
        UPPER(:network_domain)='FIXED'
        AND site_type NOT IN ('MTX','LTC')
      )
    )
),

--------------------------------------------------------------------
-- 2. Month Range + CROSS JOIN => site_months
--------------------------------------------------------------------
month_range AS (
  SELECT generate_series(:min_month, :max_month) AS month_num
),
site_months AS (
  SELECT fs.site_code, mr.month_num
  FROM filtered_sites fs
  CROSS JOIN month_range mr
),

--------------------------------------------------------------------
-- 3. Retrieve monthly cost directly from vfopex (already imputed).
--    If there are truly no cost rows, we consider cost=0 for that month.
--------------------------------------------------------------------
site_month_costs AS (
  SELECT
    sm.site_code,
    sm.month_num,
    SUM(
      CASE WHEN o.reading_value IS NOT NULL
           THEN CAST(o.reading_value AS DECIMAL)*0.25/1000
           ELSE 0
      END
    ) AS cost_k_gbp
  FROM site_months sm
  LEFT JOIN vdf.vfbridge b
    ON UPPER(TRIM(b.site_code))=UPPER(TRIM(sm.site_code))
    OR (
      b.postcode IN (SELECT postcode FROM unique_postal_codes)
      AND b.postcode=(
        SELECT fs.postcode FROM filtered_sites fs
        WHERE fs.site_code=sm.site_code
        LIMIT 1
      )
    )
    OR (
      b.site_code IS NOT NULL
      AND (
        TRIM(sm.site_code) LIKE CONCAT('%(', UPPER(TRIM(b.site_code)), ')%')
      )
      OR (UPPER(TRIM(b.site_code)) ~ CONCAT(sm.site_code,'\\s*[,&].*'))
      OR (UPPER(TRIM(b.site_code)) ~ CONCAT('.*[,&]\\s*',sm.site_code))
    )
  LEFT JOIN vdf.vfopex o
    ON UPPER(TRIM(b.bridge_site_code))=UPPER(TRIM(o.sitecode))
    AND DATE_PART('year',  CAST(o.reading_date AS DATE)) = :year
    AND DATE_PART('month', CAST(o.reading_date AS DATE))=sm.month_num
  GROUP BY sm.site_code, sm.month_num
),

--------------------------------------------------------------------
-- 4. ordered_costs => each row with cost_k_gbp plus LEAD(cost_k_gbp)
--    We'll check if next_cost < cost_k_gbp => negative slope
--------------------------------------------------------------------
ordered_costs AS (
  SELECT
    site_code,
    month_num,
    cost_k_gbp,
    LEAD(cost_k_gbp) OVER (
      PARTITION BY site_code
      ORDER BY month_num
    ) AS next_cost
  FROM site_month_costs
),

--------------------------------------------------------------------
-- 5. negative_trend_sites => check strict decreasing
--    => "BOOL_AND(next_cost < cost_k_gbp OR next_cost IS NULL)"
--------------------------------------------------------------------
positive_trend_sites AS (
  SELECT site_code
  FROM ordered_costs
  GROUP BY site_code
  HAVING BOOL_AND(
    (next_cost > cost_k_gbp) OR (next_cost IS NULL)
  )
),

--------------------------------------------------------------------
-- 6. min_max_costs => find first & last cost for each site to measure drop%
--------------------------------------------------------------------
min_max_costs AS (
  SELECT
    site_code,
    FIRST_VALUE(cost_k_gbp) OVER w AS first_cost,
    LAST_VALUE(cost_k_gbp)  OVER w AS last_cost
  FROM site_month_costs
  WINDOW w AS (
    PARTITION BY site_code
    ORDER BY month_num
    ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
  )
),

--------------------------------------------------------------------
-- 7. Combine => final with drop_percentage
--------------------------------------------------------------------
trend_with_drop AS (
  SELECT distinct
    nts.site_code,
    mmc.first_cost,
    mmc.last_cost,
    CASE
      WHEN mmc.first_cost=0 THEN NULL
      ELSE ROUND(
        ((mmc.last_cost - mmc.first_cost)/mmc.first_cost)*100,
        2
      )
    END AS increase_percentage
  FROM positive_trend_sites nts
  JOIN min_max_costs mmc USING (site_code)
)

--------------------------------------------------------------------
-- 8. Return strictly decreasing sites plus drop info
--------------------------------------------------------------------
SELECT distinct
  site_code,
  ROUND(first_cost, 1)  AS first_cost_k_gbp,
  ROUND(last_cost, 1)   AS last_cost_k_gbp,
  increase_percentage
FROM trend_with_drop
WHERE NOT EXISTS(SELECT * FROM user_blacklist_opex) -- redact all non-opex users
ORDER BY increase_percentage DESC NULLS LAST;
