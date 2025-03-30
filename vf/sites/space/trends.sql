-- @param site_codes A comma-separated list of site codes.
-- @type site_codes varchar
-- @default site_codes null

-- @param page the current page number to retrieve
-- @type page integer
-- @default page 1

-- @param page_size the number of records per page. Default value is 500.
-- @type page_size integer
-- @default page_size 500

-- @return Vodafone Sites with Combined Fixed/Mobile Power Capacity Filters.

WITH fixed_historic_tmp AS (
    SELECT general_equipment_area_code, '20'||substring(file_date, 1, 2)||'-'||substring(file_date, 3, 2) as file_date, MAX(space_available_suite_sections::int) as space_available_suite_sections
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
	SELECT *
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
    WHERE site_type NOT IN ('MTX','LTC')
)
SELECT distinct *
FROM combined
LIMIT COALESCE(:page_size, 500)
OFFSET (COALESCE(:page, 1) - 1) * COALESCE(:page_size, 500);
