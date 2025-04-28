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

-- @param site_regions A comma-separated list of geographic regions for these sites.
-- @type site_regions varchar
-- @default site_regions null

-- @param site_address The UK address of the site. Substring search is supported.
-- @type site_address varchar
-- @default site_address null

-- @param freehold_leasehold Freehold/Leasehold indication. 
--        Permissible values: [Freehold, Leasehold]
-- @type freehold_leasehold varchar
-- @default freehold_leasehold null

-- @param site_status Permissible values: [Normal, Closed, Planned Closure, Restricted]
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
--        Permissible values: [mobile, fixed]
-- @type network_domain varchar
-- @default network_domain null

-- @param year Year of Opex data to be processed.
-- @type year integer
-- @default year 2024

-- @param min_month Minimum month (1..12) of Opex data to be processed.
--        All months between min_month..max_month are included.
-- @type min_month integer
-- @default min_month 1

-- @param max_month Maximum month (1..12) of Opex data to be processed.
--        All months between min_month..max_month are included.
-- @type max_month integer
-- @default max_month 12

-- @param userid user identifier injected for authorization and data redaction purposes.
-- @type userid varchar
-- @default userid NULL

-- @return Each site_code plus an array of monthly Opex values (in kGBP). Because the vfopex table already has zero→avg imputation, no recursion is required here.

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
-------------------------------------------------------------------
-- 1. Potential helper sets
-------------------------------------------------------------------
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

-------------------------------------------------------------------
-- 2. Filter Sites
-------------------------------------------------------------------
filtered_sites AS (
  SELECT *
  FROM vdf.vfsites
  WHERE
    -- site_types => check if site_category + site_type array intersects the given list */
    (
      :site_types IS NULL
      OR 
        regexp_split_to_array(
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
          SELECT UPPER(TRIM(code)) 
          FROM split_site_codes
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
             ) AS arr1(elem1)
        CROSS JOIN unnest(
              regexp_split_to_array(TRIM(UPPER(vfsites.region)), ',')
             ) AS arr2(elem2)
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
      OR (:gis_migrated = true AND UPPER(gis_migrated) = 'TRUE')
      OR (:gis_migrated = false AND UPPER(gis_migrated) = 'FALSE')
    )
    AND (
      :comments IS NULL
      OR UPPER(comments) ILIKE CONCAT('%', UPPER(:comments), '%')
    )
    AND (
      :restricted IS NULL
      OR (:restricted = true AND UPPER(restricted) = 'TRUE')
      OR (:restricted = false AND UPPER(restricted) = 'FALSE')
    )
    AND (
      :power_resilience IS NULL
      OR UPPER(power_resilience) ILIKE CONCAT('%', UPPER(:power_resilience), '%')
    )
    AND (
      :network_domain IS NULL
      OR (UPPER(:network_domain) = 'MOBILE' AND site_type IN ('MTX','LTC'))
      OR (UPPER(:network_domain) = 'FIXED'  AND site_type NOT IN ('MTX','LTC'))
    )
),

-------------------------------------------------------------------
-- 3. Create a month range, cross-join with sites => site_months
-------------------------------------------------------------------
month_range AS (
  SELECT generate_series(:min_month, :max_month) AS month_num
),
site_months AS (
  SELECT fs.site_code, mr.month_num, fs.postcode
  FROM filtered_sites fs
  CROSS JOIN month_range mr
),

-------------------------------------------------------------------
-- 4. Bridge to vfopex to pick up cost for each site_code + month
-------------------------------------------------------------------
site_months_joined_tmp AS (
  SELECT distinct b.bridge_site_code,
    sm.site_code,
    sm.month_num,
    (
      CASE
        WHEN o.reading_value IS NOT NULL
        THEN ROUND(CAST(o.reading_value AS DECIMAL) * 0.25 / 1000, 4)
        ELSE 0
      END
    ) AS cost_k_gbp
  FROM site_months sm
  /* Join bridging, so we can match site_code to vfopex.sitecode via vfbridge: */
  INNER JOIN vdf.vfbridge b
    ON UPPER(TRIM(b.site_code)) = UPPER(TRIM(sm.site_code))
    OR (b.postcode=sm.postcode AND b.postcode IN (
      select postcode from unique_postal_codes)
    )
    OR (
       b.site_code IS NOT NULL
       AND (
         TRIM(sm.site_code) LIKE CONCAT('%(', UPPER(TRIM(b.site_code)), ')%')
       )
       OR (UPPER(TRIM(b.site_code)) ~ CONCAT(sm.site_code, '\\s*[,&].*'))
       OR (UPPER(TRIM(b.site_code)) ~ CONCAT('.*[,&]\\s*', sm.site_code))
    )
  INNER JOIN vdf.vfopex o
    ON UPPER(TRIM(b.bridge_site_code)) = UPPER(TRIM(o.sitecode))
    AND DATE_PART('year',  CAST(o.reading_date AS DATE))  = :year
    AND DATE_PART('month', CAST(o.reading_date AS DATE)) = sm.month_num
),

site_months_joined AS (
  SELECT site_code, month_num, SUM(cost_k_gbp) as cost_k_gbp
  FROM site_months_joined_tmp
  GROUP BY site_code, month_num
),

-------------------------------------------------------------------
-- 5. Convert each site’s monthly data to an array 
-------------------------------------------------------------------
monthly_opex_final AS (
  SELECT
    site_code,
    ARRAY_AGG(
      cost_k_gbp
      ORDER BY month_num
    ) AS monthly_cost_k_gbp
  FROM site_months_joined
  GROUP BY site_code
)

-------------------------------------------------------------------
-- 6. Return
-------------------------------------------------------------------
SELECT * --site_code, monthly_cost_k_gbp
FROM site_months_joined_tmp -- monthly_opex_final
WHERE NOT EXISTS(SELECT * FROM user_blacklist_opex) -- redact all non-opex users
ORDER BY site_code;
