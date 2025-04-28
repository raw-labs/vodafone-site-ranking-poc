-- @param site_codes A comma-separated list of site codes.
-- @type site_codes varchar
-- @default site_codes null

-- @param page the current page number to retrieve
-- @type page integer
-- @default page 1

-- @param page_size the number of records per page. Default value is 500.
-- @type page_size integer
-- @default page_size 500

-- @param userid user identifier injected for authorization and data redaction purposes.
-- @type userid varchar
-- @default userid NULL

-- @return Vodafone Sites with Combined Fixed/Mobile Power Capacity Filters.

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
), fixed_historic_tmp AS (
    SELECT general_equipment_area_code, '20'||substring(file_date, 1, 2)||'-'||substring(file_date, 3, 2) as file_date, SUM(space_available_suite_sections::int) as space_available_suite_sections
    FROM vdf.historic_fixed_capacity
    GROUP BY general_equipment_area_code, file_date
), fixed_historic AS (
    SELECT general_equipment_area_code,
        ARRAY_AGG(space_available_suite_sections order by file_date) as free_sections_monthly_trend_2024
    FROM fixed_historic_tmp
    GROUP BY general_equipment_area_code
),
split_site_codes AS (
  SELECT TRIM(x) AS code
  FROM regexp_split_to_table(COALESCE(:site_codes, ''), ',') AS x
),
filtered_sites AS (
	SELECT vfsites.site_code, vfsites.site_name, vfsites.site_type as original_site_type, replace(
                            upper(site_category), 'PABR', 'PABR,PCORE'
                        ) 
                        ||','||
                        upper(site_type) AS site_type, vfsites.site_category, vfsites.region, vfsites.status, 
                        vfsites.address, vfsites.postcode, vfsites.gis_migrated, vfsites.floorplans,
                        vfsites.location, vfsites.comments, vfsites.restricted, vfsites.freehold_leasehold, 
                        vfsites.power_resilience
	FROM vdf.vfsites
	WHERE
		(
      :site_codes IS NULL 
      OR UPPER(TRIM(site_code)) IN (SELECT UPPER(TRIM(code)) FROM split_site_codes)
    )
),
combined AS (
    select s.*, free_sections_monthly_trend_2024
    FROM filtered_sites s 
        LEFT OUTER JOIN fixed_historic fc 
            ON upper(trim(fc.general_equipment_area_code)) = trim(replace(replace(upper(s.site_code), '(GROUND FLOOR)', ''), 'ROOM', ''))
    WHERE original_site_type NOT IN ('MTX','LTC')
)
SELECT distinct *
FROM combined
WHERE NOT EXISTS(SELECT * FROM user_blacklist_space) -- redact all non-space users
LIMIT COALESCE(:page_size, 500)
OFFSET (COALESCE(:page, 1) - 1) * COALESCE(:page_size, 500);
