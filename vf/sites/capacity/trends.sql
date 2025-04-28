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
), mobile_aggr_capacity AS (
	SELECT mtx, TO_DATE(upper(trim(file_date)), '01 MON YY') as file_date,
		(sum(CAST(remaining_element_capability_a AS FLOAT))*54.5/1000) as aggr_remaining_power_capacity_kw,
		(sum(CAST(
                COALESCE(element_load_a_28_01_24,element_load_a_25_02_24,element_load_a_24_03_24,
                element_load_a_28_04_24,element_load_a_26_05_24,element_load_a_23_06_24,
                element_load_a_28_07_24,element_load_a_18_08_24,element_load_a_29_09_24,
                element_load_a_20_10_24,element_load_a_24_11_24,element_load_a_22_12_24)
            AS FLOAT))*54.5/1000) as aggr_running_load_kw,
		(sum(CAST(reserved_a AS FLOAT)+CAST(forecast_a AS FLOAT))*54.5/1000) as aggr_total_allocated_kw,
		(sum(CAST(reserved_a AS FLOAT))*54.5/1000) as aggr_reserved_load_kw,
        (sum(CAST(forecast_a AS FLOAT))*54.5/1000) as aggr_forecasted_load_kw
	FROM vdf.historic_mtx_capacity
	GROUP BY mtx, file_date
),
vf_mobile_capacity AS (
    SELECT a.mtx, 
        ARRAY_AGG(a.aggr_remaining_power_capacity_kw order by file_date) as remaining_power_capacity_in_kw,
        ARRAY_AGG(a.aggr_running_load_kw order by file_date) as running_load_in_kw,
        ARRAY_AGG(a.aggr_total_allocated_kw order by file_date) as total_allocated_in_kw,
        ARRAY_AGG(a.aggr_reserved_load_kw order by file_date) as reserved_load_in_kw,
        ARRAY_AGG(a.aggr_forecasted_load_kw order by file_date) as forecasted_load_in_kw,
        ARRAY_AGG(CAST(NULL AS FLOAT)) as remaining_power_80_of_n_in_kw,
        'DC' as current_type
    FROM mobile_aggr_capacity a
    GROUP BY mtx
),
fixed_aggr_capacity AS (
    SELECT general_equipment_area_code, general_system_name, TO_DATE(upper(trim(c.file_date)), 'YYMM01') as file_date,
        (
            CASE 
                WHEN power_kw_load_remaining_after_total_allocated_inc__f6fe184e IS NULL 
						OR UPPER(power_kw_load_remaining_after_total_allocated_inc__f6fe184e) != '#N/A' 
                    THEN CAST(power_kw_load_remaining_after_total_allocated_inc__f6fe184e AS FLOAT)
                ELSE 0
            END
        ) as power_kw_load_remaining_after_total_allocated,
        (
            CASE 
                WHEN power_actual_load_kw IS NULL 
						OR UPPER(power_actual_load_kw) != '#N/A' 
                    THEN CAST(power_actual_load_kw AS FLOAT)
                ELSE 0
            END
        ) as power_actual_load_kw,
        (
            CASE 
                WHEN cv.kw_power_remaining_80_of_n IS NULL 
						OR UPPER(kw_power_remaining_80_of_n) != '#N/A' 
                    THEN CAST(kw_power_remaining_80_of_n AS FLOAT)
                ELSE 0
            END
        ) as kw_power_remaining_80_of_n,
        (
            CASE 
                WHEN cv.total_allocated_load_kw IS NULL 
						OR UPPER(total_allocated_load_kw) != '#N/A' 
                    THEN CAST(total_allocated_load_kw AS FLOAT)
                ELSE 0
            END
        ) as total_allocated_load_kw
    FROM vdf.historic_fixed_capacity c
        INNER JOIN vdf.historic_fixed_capacity_cover cv 
            ON c.general_system_name=cv.brag_0_black_0_10_red_10_25_amber_25_green AND c.file_date=cv.file_date
),
vf_fixed_capacity_avg AS (
    select 
        MAX(fc.general_equipment_area_code) as general_equipment_area_code, 
        fc.general_equipment_area_code || trim(regexp_replace(regexp_replace(replace(general_system_name,' (DO NOT CONNECT LOADS)',''), '[AaBb]$', '', 'g'), 'SYS[ ]*[AaBb]', 'SYS', 'g')) as minus_compl,
        file_date,
        AVG(fc.power_kw_load_remaining_after_total_allocated) as remaining_power_capacity_in_kw,
        SUM(fc.power_actual_load_kw) as running_load_in_kw,
        SUM(fc.kw_power_remaining_80_of_n) as remaining_power_80_of_n_in_kw,
        SUM(fc.total_allocated_load_kw) as total_allocated_load_kw
    FROM fixed_aggr_capacity as fc
    GROUP BY minus_compl, file_date
),
vf_fixed_capacity_sum AS (
    select 
        general_equipment_area_code, file_date,
        CAST(NULL as FLOAT) as remaining_element_capability_in_amber,
        SUM(remaining_power_capacity_in_kw) as remaining_power_capacity_in_kw,
        SUM(running_load_in_kw) as running_load_in_kw,
        SUM(remaining_power_80_of_n_in_kw) as remaining_power_80_of_n_in_kw,
        CAST(NULL as FLOAT) as forecasted_load_in_kw,
        CAST(NULL as FLOAT) as reserved_load_in_kw,
        SUM(total_allocated_load_kw) as total_allocated_in_kw
    FROM vf_fixed_capacity_avg as fc
    GROUP BY general_equipment_area_code, file_date
),
vf_fixed_capacity AS (
    select 
        general_equipment_area_code,
        ARRAY_AGG(remaining_element_capability_in_amber order by file_date) as remaining_element_capability_in_amber,
        ARRAY_AGG(remaining_power_capacity_in_kw order by file_date) as remaining_power_capacity_in_kw,
        ARRAY_AGG(running_load_in_kw order by file_date) as running_load_in_kw,
        ARRAY_AGG(remaining_power_80_of_n_in_kw order by file_date) as remaining_power_80_of_n_in_kw,
        ARRAY_AGG(forecasted_load_in_kw order by file_date) as forecasted_load_in_kw,
        ARRAY_AGG(reserved_load_in_kw order by file_date) as reserved_load_in_kw,
        ARRAY_AGG(total_allocated_in_kw order by file_date) as total_allocated_in_kw
    FROM vf_fixed_capacity_sum as fc
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
    select s.*, -- fc.general_equipment_area_code, fc.general_system_name, 
        fc.remaining_power_capacity_in_kw as remaining_power_capacity_in_kw,
        fc.running_load_in_kw as running_load_in_kw,
        fc.total_allocated_in_kw as total_allocated_in_kw,
        fc.reserved_load_in_kw as reserved_load_in_kw,
        fc.forecasted_load_in_kw as forecasted_load_in_kw,
        fc.remaining_power_80_of_n_in_kw as remaining_power_80_of_n_in_kw
    FROM filtered_sites s 
        LEFT OUTER JOIN vf_fixed_capacity fc 
            ON upper(trim(fc.general_equipment_area_code)) = trim(replace(replace(upper(s.site_code), '(GROUND FLOOR)', ''), 'ROOM', ''))
    WHERE original_site_type NOT IN ('MTX','LTC')
    
    -- GROUP BY rollup(fc.general_equipment_area_code, fc.general_system_name)
    UNION
    SELECT distinct filtered_sites.*,
        -- vf_mobile_capacity.remaining_element_capability_in_amber,
        vf_mobile_capacity.remaining_power_capacity_in_kw,
        vf_mobile_capacity.running_load_in_kw,
        vf_mobile_capacity.total_allocated_in_kw,
        vf_mobile_capacity.reserved_load_in_kw,
        vf_mobile_capacity.forecasted_load_in_kw,
        vf_mobile_capacity.remaining_power_80_of_n_in_kw
    FROM filtered_sites 
        LEFT OUTER JOIN vf_mobile_capacity
        ON filtered_sites.site_code=vf_mobile_capacity.mtx 
            OR (filtered_sites.site_code NOT IN ('XGL001 (BMGMTX)', 'BKLN06') AND filtered_sites.site_name=trim(split_part(vf_mobile_capacity.mtx, ' TXO', 1)))
    WHERE (filtered_sites.original_site_type='LTC' OR filtered_sites.original_site_type='MTX')
)
SELECT distinct *
FROM combined
WHERE NOT EXISTS(SELECT * FROM user_blacklist_capacity) -- redact all non-capacity users
LIMIT COALESCE(:page_size, 500)
OFFSET (COALESCE(:page, 1) - 1) * COALESCE(:page_size, 500);
