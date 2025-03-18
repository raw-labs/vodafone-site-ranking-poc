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

-- @param group_by_field the field to group the summary by (e.g., 'site_type', 'site_region', 'status').
-- @type group_by_field varchar
-- @default group_by_field null

-- @return summary of the total number of accounts, grouped by the specified field.

WITH split_site_codes AS (
  SELECT TRIM(x) AS code
  FROM regexp_split_to_table(COALESCE(:site_codes, ''), ',') AS x
),
split_site_types AS (
  SELECT TRIM(x) AS code
  FROM regexp_split_to_table(COALESCE(:site_types, ''), ',') AS x
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
)
SELECT
    -- Dynamic grouping based on the group_by_field parameter
    CASE
        WHEN :group_by_field = 'site_type' THEN UPPER(site_type)
        WHEN :group_by_field = 'region' THEN UPPER(region)
        WHEN :group_by_field = 'status' THEN UPPER(status)
        WHEN :group_by_field = 'gis_migrated' THEN UPPER(gis_migrated)
        WHEN :group_by_field = 'restricted' THEN UPPER(restricted)
        WHEN :group_by_field = 'freehold_leasehold' THEN UPPER(freehold_leasehold)
        WHEN :group_by_field = 'power_resilience' THEN UPPER(power_resilience)
        ELSE 'All'
        END AS group_by_value,
    COUNT(*)
FROM filtered_sites
GROUP BY group_by_value
ORDER BY group_by_value;
