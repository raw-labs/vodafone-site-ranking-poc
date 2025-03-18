-- @param site_types A comma-separated list of site types. Permissible values are: [LTC, P-core, PX, regular, CHE, NFV, PABR, Amitie, RA, OpX, Gi-LAN]
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

-- @param freehold_leasehold Freehold/Leasehold indication. Permissible values are: [Freehold, Leasehold]
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

-- @param power_resilience Power resilience. Permissible values are: [Mixed (Both N & N+N), N only, N+N (Full A&B), N+N (Resilient)]
-- @type power_resilience varchar
-- @default power_resilience null

-- @param network_domain Distinguishes between mobile (MTX, LTC) and fixed sites. Permissible values are: [mobile, fixed]
-- @type network_domain varchar
-- @default network_domain null

-- @param year year of opex data to be processed
-- @type year integer
-- @default year 2024

-- @param min_month minimum month of opex data to be processed. Default is 1 (January). All months between min_month and max_month are processed.
-- @type min_month integer
-- @default min_month 01

-- @param max_month maximum month of opex data to be processed. Default is 12 (December). All months between [min_month..max_month] are processed.
-- @type max_month integer
-- @default max_month 12

-- @param min_cost filter sites with cost more than min_cost
-- @type min_cost integer
-- @default min_cost NULL

-- @param max_cost filter sites with cost less than max_cost
-- @type max_cost integer
-- @default max_cost NULL

-- @param page the current page number to retrieve
-- @type page integer
-- @default page 1

-- @param page_size the number of records per page. Default value is 50.
-- @type page_size integer
-- @default page_size 500

-- @param topN sort results by top-N sites the highest operational costs. If not provided, then results are sorted by site code.
-- @type topN integer
-- @default topN NULL

-- @return Sites that exhibit strictly decreasing monthly Opex costs from min_month..max_month. 
--         (Zero is treated as missing and imputed by prior average.)

WITH 
/*
   5. Recursive CTE: fill_imputed
      - Zero / treat as missing / impute from prior average.
*/
RECURSIVE fill_imputed AS (
  -- a) Anchor: the earliest month
  SELECT
    sm.site_code,
    sm.month_num,
    CASE WHEN sm.cost_k_gbp = 0 THEN NULL
         ELSE sm.cost_k_gbp
    END AS cost_k_gbp,
    CASE WHEN sm.cost_k_gbp IS NULL OR sm.cost_k_gbp=0 THEN 0
         ELSE sm.cost_k_gbp
    END AS running_sum,
    CASE WHEN sm.cost_k_gbp IS NULL OR sm.cost_k_gbp=0 THEN 0
         ELSE 1
    END AS running_count
  FROM site_months_left_joined sm
  WHERE sm.month_num = (
    SELECT MIN(month_num)
    FROM site_months_left_joined
    WHERE site_code = sm.site_code
  )

  UNION ALL

  -- b) For each subsequent month, if cost=0 => treat as missing => use average of prior months.
  SELECT
    nxt.site_code,
    nxt.month_num,
    COALESCE(
      NULLIF(nxt.cost_k_gbp, 0),   -- if it's 0, treat as NULL
      CASE WHEN prv.running_count=0 THEN 0
           ELSE prv.running_sum / prv.running_count
      END
    ) AS cost_k_gbp,
    prv.running_sum
      + COALESCE(
          NULLIF(nxt.cost_k_gbp, 0),
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

/* 
  1. unique_postal_codes, split_site_codes, filtered_sites 
      are the same as in your existing code. 
*/
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
filtered_sites AS (
    SELECT *
    FROM vdf.vfsites
    WHERE
        (
            :site_types IS NULL 
            OR regexp_split_to_array(
                COALESCE(
                    TRIM(
                        REPLACE(
                            UPPER(:site_types), '-',''
                        )
                    ), 
                    ''
                ), 
                ','
            )
            &&
            regexp_split_to_array(
                TRIM(
                    REPLACE(
                        REPLACE(
                            UPPER(site_category), 'PABR', 'PABR,PCORE'
                        ) 
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
            OR (:gis_migrated=true AND UPPER(gis_migrated) = 'TRUE')
            OR (:gis_migrated=false AND UPPER(gis_migrated) = 'FALSE')
        )
        AND (:comments IS NULL OR comments ILIKE CONCAT('%', :comments, '%'))
        AND (
            :restricted IS NULL 
            OR (:restricted=true AND UPPER(restricted) = 'TRUE')
            OR (:restricted=false AND UPPER(restricted) = 'FALSE')
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

/*
   2. The base data you provided: we gather monthly cost_k_gbp for each site_code.
*/
filtered_base_data AS (
    SELECT 
        fs.site_code,
        DATE_PART('month', CAST(o.reading_date AS DATE))::int AS month_num,
        SUM(CAST(o.reading_value AS DECIMAL) * 0.25) / 1000 AS cost_k_gbp
    FROM filtered_sites fs
    INNER JOIN vdf.vfbridge b
        ON UPPER(TRIM(b.site_code)) = UPPER(fs.site_code)
        OR (
            b.postcode = fs.postcode 
            AND b.postcode IN (SELECT postcode FROM unique_postal_codes)
        )
        OR (
            b.site_code IS NOT NULL
            AND (
                TRIM(fs.site_code) LIKE CONCAT('%(', UPPER(TRIM(b.site_code)), ')%')
            )
            OR (UPPER(TRIM(b.site_code)) ~ CONCAT(fs.site_code, '\\s*[,&].*'))
            OR (UPPER(TRIM(b.site_code)) ~ CONCAT('.*[,&]\\s*', fs.site_code))
        )
    INNER JOIN vdf.vfopex o
        ON UPPER(TRIM(b.bridge_site_code)) = UPPER(TRIM(o.sitecode)) 
        AND DATE_PART('year', CAST(o.reading_date AS DATE)) = :year
        AND DATE_PART('month', CAST(o.reading_date AS DATE)) BETWEEN :min_month AND :max_month
    GROUP BY fs.site_code, DATE_PART('month', CAST(o.reading_date AS DATE))
),

/*
   3. We build a cross join so each site has a record for every month in min_month..max_month
*/
all_site_months AS (
    SELECT fs.site_code, m.month_num
    FROM filtered_sites fs
    CROSS JOIN generate_series(:min_month, :max_month) AS m(month_num)
),

/*
   4. Left-join actual cost. If no row / cost_k_gbp is NULL.
      If cost is 0 in filtered_base_data / we keep it as 0 for now, 
      but will treat it as missing in the recursion.
*/
site_months_left_joined AS (
    SELECT
        asm.site_code,
        asm.month_num,
        COALESCE(rmc.cost_k_gbp, 0) AS cost_k_gbp  -- keep zero if no data
    FROM all_site_months asm
    LEFT JOIN filtered_base_data rmc 
        ON asm.site_code = rmc.site_code
       AND asm.month_num = rmc.month_num
),

/*
   6. final_filled then pick the final cost after imputation
*/
final_filled AS (
  SELECT
    site_code,
    month_num,
    cost_k_gbp
  FROM fill_imputed
),

/*
   7. ordered_costs then each row with cost & LEAD(cost_k_gbp) then next month cost
*/
ordered_costs AS (
  SELECT
    site_code,
    month_num,
    cost_k_gbp,
    LEAD(cost_k_gbp) OVER (PARTITION BY site_code ORDER BY month_num) AS next_cost
  FROM final_filled
),

/*
   8. negative_trend_sites then ensure next_cost less than cost_k_gbp - or next_cost IS NULL
*/
negative_trend_sites AS (
  SELECT site_code
  FROM ordered_costs
  GROUP BY site_code
  HAVING BOOL_AND(
    (next_cost < cost_k_gbp) OR (next_cost IS NULL)
  )
),

/*
   9. min_max_costs then capture the first & last cost after imputation
*/
min_max_costs AS (
  SELECT
    site_code,
    FIRST_VALUE(cost_k_gbp) OVER w AS first_cost,
    LAST_VALUE(cost_k_gbp)  OVER w AS last_cost
  FROM final_filled
  WINDOW w AS (
    PARTITION BY site_code
    ORDER BY month_num
    ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
  )
),

/*
   10. trend_with_drop then compute drop_percentage
*/
trend_with_drop AS (
  SELECT distinct
    nts.site_code,
    mmc.first_cost,
    mmc.last_cost,
    CASE 
      WHEN mmc.first_cost=0 THEN NULL
      ELSE ROUND(
        ((mmc.first_cost - mmc.last_cost) / mmc.first_cost)*100
        , 2
      )
    END AS drop_percentage
  FROM negative_trend_sites nts
  JOIN min_max_costs mmc USING (site_code)
)

SELECT
  site_code,
  first_cost,
  last_cost,
  drop_percentage
FROM trend_with_drop
ORDER BY drop_percentage DESC NULLS LAST;

-- select * from final_filled where site_code='BRN'

