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

-- @return a list of site codes along with a related cost in thousands of British Pounds

WITH unique_postal_codes AS (
    SELECT postcode
    FROM vdf.vfsites
    GROUP BY postcode
    HAVING count(*)=1
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
        OR 
            -- UPPER(vfsites_with_custom_type.vf_site_type) IN (SELECT trim(replace(upper(code),'-','') ) FROM split_site_types)
            regexp_split_to_array(
                COALESCE(
                    trim(
                        replace(
                            upper(:site_types), '-',''
                        )
                    ), 
                ''), 
                ','
            ) 
            && 
            regexp_split_to_array(
                trim(
                    replace(
                        replace(
                            upper(site_category), 'PABR', 'PABR,PCORE'
                        ) 
                        ||','||
                        upper(site_type),'-',''
                    )
                ),
                ',')
        )
        AND (
        :site_codes IS NULL 
        OR UPPER(TRIM(site_code)) IN (SELECT UPPER(TRIM(code)) FROM split_site_codes)
        )
		AND (:site_name IS NULL OR vfsites.site_name ILIKE CONCAT('%', :site_name, '%'))
		AND (:site_region IS NULL OR UPPER(vfsites.region) ILIKE  CONCAT(:site_region, '%'))
		AND (:site_address IS NULL OR vfsites.address ILIKE CONCAT('%', :site_address, '%'))
		AND (:freehold_leasehold IS NULL OR UPPER(vfsites.freehold_leasehold) = UPPER(:freehold_leasehold))
		AND (:site_status IS NULL OR vfsites.status = :site_status)
		AND (:gis_migrated IS NULL OR 
			(:gis_migrated=true AND UPPER(vfsites.gis_migrated) = 'TRUE') OR
			(:gis_migrated=false AND UPPER(vfsites.gis_migrated) = 'FALSE'))
		AND (:comments IS NULL OR vfsites.comments ILIKE CONCAT('%', :comments, '%'))
		AND (:restricted IS NULL OR 
			(:restricted=true AND UPPER(vfsites.restricted) = 'TRUE') OR
			(:restricted=false AND UPPER(vfsites.restricted) = 'FALSE'))
		AND (:power_resilience IS NULL OR UPPER(vfsites.power_resilience) ILIKE CONCAT('%',:power_resilience,'%'))
        AND (
            :network_domain IS NULL
            OR (UPPER(:network_domain) = 'MOBILE' AND vfsites.site_type IN ('MTX','LTC'))
            OR (UPPER(:network_domain) = 'FIXED' AND vfsites.site_type NOT IN ('MTX','LTC'))
            )
),
filtered_vfopex AS (
    SELECT sitecode, ROUND((SUM(CAST(vfopex.reading_value AS DECIMAL)) * 0.25) / 1000, 2) AS total_cost_in_k_GBP
    FROM vdf.vfopex
    WHERE date_part('year', CAST(vfopex.reading_date AS DATE))=:year
        and date_part('month', CAST(vfopex.reading_date AS DATE))>=:min_month
        and date_part('month', CAST(vfopex.reading_date AS DATE))<=:max_month
    GROUP BY sitecode
),
base_data AS (
    select filtered_sites.site_code, 
    -- filtered_sites.site_name, filtered_sites.postcode, vfbridge.site_code as bridge_site_code,
    -- vfbridge.postcode as bridge_postcode, vfbridge.site_code as site_ref, 
    total_cost_in_k_GBP
    from filtered_sites
        inner join vdf.vfbridge on upper(trim(vfbridge.site_code))=filtered_sites.site_code
            OR (vfbridge.postcode=filtered_sites.postcode AND vfbridge.postcode IN (
                select postcode from unique_postal_codes)
            )
            OR (vfbridge.site_code IS NOT NULL AND (
                trim(filtered_sites.site_code) LIKE concat('%(',upper(trim(vfbridge.site_code)),')%'))
                OR (upper(trim(vfbridge.site_code)) ~ concat(filtered_sites.site_code,'\\s*[,&].*'))
                OR (upper(trim(vfbridge.site_code)) ~ concat('.*[,&]\\s*',filtered_sites.site_code))
            )
        inner join filtered_vfopex on upper(trim(vfbridge.bridge_site_code))=upper(trim(filtered_vfopex.sitecode))
    ORDER BY
        -- If topN is provided, sort by total_cost DESC; otherwise sort by site_code ASC
        CASE WHEN :topN IS NOT NULL THEN total_cost_in_k_GBP END DESC,
        CASE WHEN :topN IS NULL THEN filtered_sites.site_code END ASC
    LIMIT CASE WHEN :topN IS NOT NULL THEN :topN ELSE 1000 END
)
SELECT distinct *
FROM base_data
WHERE 
    (:min_cost IS NULL OR total_cost_in_k_GBP>:min_cost) 
    AND 
    (:max_cost IS NULL OR total_cost_in_k_GBP<:max_cost)
