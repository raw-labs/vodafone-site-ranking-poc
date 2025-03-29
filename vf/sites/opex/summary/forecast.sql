-- @param site_types A comma-separated list of site types. Permissible values are: [LTC, P-core, PX, regular, CHE, NFV, PABR, Amitie, RA, OpX, Gi-LAN]
-- @type site_types varchar
-- @default site_types null

-- @param site_codes A comma-separated list of site codes.
-- @type site_codes varchar
-- @default site_codes null

-- @param site_name The name of the site. Substring search is supported.
-- @type site_name varchar
-- @default site_name null

-- @param site_regions A comma-separated list of site regions. Substring match is supported.
-- @type site_regions varchar
-- @default site_regions null

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

-- @param year The current/base year of Opex data
-- @type year integer
-- @default year 2024

-- @param min_month Minimum month (1..12) to include in OPEX calculations
-- @type min_month integer
-- @default min_month 1

-- @param max_month Maximum month (1..12) to include in OPEX calculations
-- @type max_month integer
-- @default max_month 12

-- @param min_cost Filter out any sites with base cost <= min_cost
-- @type min_cost integer
-- @default min_cost null

-- @param max_cost Filter out any sites with base cost >= max_cost
-- @type max_cost integer
-- @default max_cost null

-- @param topN If set, returns only the top N base-cost sites (descending). Otherwise sorts ascending by site_code.
-- @type topN integer
-- @default topN null

-- @param forecast_years How many future years to forecast beyond 'year'
-- @type forecast_years integer
-- @default forecast_years 1

-- @param annual_growth_percent The annual cost growth rate (percentage). 
-- E.g. 0.24 means +24% each year
-- @type annual_growth_percent decimal
-- @default annual_growth_percent 0.23

-- @param page the current page number to retrieve
-- @type page integer
-- @default page 1

-- @param page_size the number of records per page
-- @type page_size integer
-- @default page_size 50

-- @return For each site, returns the base year cost plus future cost projections 
--         over the next N years at the specified annual growth rate.

WITH unique_postal_codes AS (
    SELECT postcode
    FROM vdf.vfsites
    GROUP BY postcode
    HAVING COUNT(*)=1
),
split_site_codes AS (
  SELECT TRIM(x) AS code
  FROM regexp_split_to_table(COALESCE(:site_codes, ''), ',') AS x
),
-- 1) Standard site filtering logic
filtered_sites AS (
    SELECT *
    FROM vdf.vfsites
    WHERE
      (
        :site_types IS NULL
        OR regexp_split_to_array(
             COALESCE(TRIM(REPLACE(UPPER(:site_types), '-','')), ''), 
             ','
           )
        &&
        regexp_split_to_array(
          TRIM(
            REPLACE(
              REPLACE(UPPER(site_category), 'PABR','PABR,PCORE') 
              ||','||
              UPPER(site_type)
              ,'-',''
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
      AND (
        :site_name IS NULL
        OR upper(site_name) ILIKE CONCAT('%', :site_name, '%')
      )
      AND (
        :site_regions IS NULL 
        OR EXISTS (
          SELECT 1
          FROM unnest(regexp_split_to_array(TRIM(UPPER(:site_regions)), ',')) AS arr1(elem1)
          CROSS JOIN unnest(regexp_split_to_array(TRIM(UPPER(region)), ',')) AS arr2(elem2)
          WHERE TRIM(elem2) LIKE TRIM(elem1) || '%'
        )
      )
      AND (
        :site_address IS NULL
        OR upper(address) ILIKE CONCAT('%', :site_address, '%')
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
        OR (:gis_migrated=true  AND UPPER(gis_migrated) = 'TRUE')
        OR (:gis_migrated=false AND UPPER(gis_migrated) = 'FALSE')
      )
      AND (
        :comments IS NULL
        OR upper(comments) ILIKE CONCAT('%', :comments, '%')
      )
      AND (
        :restricted IS NULL
        OR (:restricted=true  AND UPPER(restricted) = 'TRUE')
        OR (:restricted=false AND UPPER(restricted) = 'FALSE')
      )
      AND (
        :power_resilience IS NULL
        OR UPPER(power_resilience) ILIKE CONCAT('%', :power_resilience, '%')
      )
      AND (
        :network_domain IS NULL
        OR (UPPER(:network_domain)='MOBILE' AND site_type IN ('MTX','LTC'))
        OR (UPPER(:network_domain)='FIXED'  AND site_type NOT IN ('MTX','LTC'))
      )
),
-- 2) Compute base cost from vfopex for the selected year + months.
filtered_vfopex AS (
    SELECT 
      sitecode,
      ROUND(SUM(CAST(vfopex.reading_value AS DECIMAL))*0.25/1000, 2) AS base_cost_k_gbp
    FROM vdf.vfopex
    WHERE 
      DATE_PART('year',  CAST(vfopex.reading_date AS DATE)) = :year
      AND DATE_PART('month', CAST(vfopex.reading_date AS DATE)) BETWEEN :min_month AND :max_month
    GROUP BY sitecode
),
-- 3) Bridge to get the site_code => base cost.
base_data AS (
    SELECT 
      fs.*,
      fv.base_cost_k_gbp
    FROM filtered_sites fs
    JOIN vdf.vfbridge b
      ON UPPER(TRIM(b.site_code))=UPPER(TRIM(fs.site_code))
         OR (b.postcode = fs.postcode AND b.postcode IN (SELECT postcode FROM unique_postal_codes))
         OR (
           b.site_code IS NOT NULL
           AND (
             fs.site_code ILIKE CONCAT('%(',b.site_code,')%')
             OR (UPPER(TRIM(b.site_code))~CONCAT(fs.site_code,'\\s*[,&].*'))
             OR (UPPER(TRIM(b.site_code))~CONCAT('.*[,&]\\s*',fs.site_code))
           )
         )
    JOIN filtered_vfopex fv
      ON UPPER(TRIM(b.bridge_site_code))=UPPER(TRIM(fv.sitecode))
    -- ORDER / LIMIT logic for topN is below
),
-- 4) Filter out min_cost / max_cost. Also do topN ordering.
base_data_filtered AS (
    SELECT base_data.*
    FROM base_data
    WHERE 
      (:min_cost IS NULL OR base_data.base_cost_k_gbp > :min_cost)
      AND (:max_cost IS NULL OR base_data.base_cost_k_gbp < :max_cost)
    ORDER BY
      CASE WHEN :topN IS NOT NULL THEN base_data.base_cost_k_gbp END DESC,
      CASE WHEN :topN IS NULL THEN base_data.site_code END ASC
    LIMIT CASE WHEN :topN IS NOT NULL THEN :topN ELSE 1000 END
),
-- 5. Forecast next X years using geometric growth at annual_growth_percent.
forecasted_years AS (
    SELECT
      bd.*,
      -- the future year => base 'year' + offset */
      (:year + g) AS forecast_year,
       
      --   Future cost = base_cost_k_gbp * (1 + annual_growth_percent)^g
      --   Example: if annual_growth_percent=0.24 => each year is +24% cumulatively
      
      ROUND(
        bd.base_cost_k_gbp * POWER(1 + COALESCE(:annual_growth_percent,0), g),
        2
      ) AS forecasted_cost_k_gbp
    FROM base_data_filtered bd
    CROSS JOIN generate_series(1, COALESCE(:forecast_years,0)) AS g
)
-- 6. Final SELECT then union of base year + the future years 
SELECT 
  bd.site_code,bd.site_name,bd.site_type,bd.site_category,bd.region,bd.status,bd.address,bd.postcode,
  bd.gis_migrated,bd.floorplans,bd.location,bd.comments,bd.restricted,bd.freehold_leasehold,bd.power_resilience,
  :year AS forecast_year,
  bd.base_cost_k_gbp AS forecasted_cost_k_gbp
FROM base_data_filtered bd

UNION ALL

SELECT 
  fy.site_code,fy.site_name,fy.site_type,fy.site_category,fy.region,fy.status,fy.address,fy.postcode,
  fy.gis_migrated,fy.floorplans,fy.location,fy.comments,fy.restricted,fy.freehold_leasehold,fy.power_resilience,
  fy.forecast_year,
  fy.forecasted_cost_k_gbp
FROM forecasted_years fy

ORDER BY site_code, forecast_year
LIMIT :page_size
OFFSET (:page - 1)*:page_size;
