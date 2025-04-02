-- @param site_types A comma-separated list of site types. Permissible values are: [LTC, P-core, PX, regular, CHE, NFV, PABR, Amitie, RA, OpX, Gi-LAN]
-- @type site_types varchar
-- @default site_types null

-- @param site_codes A comma-separated list of site codes.
-- @type site_codes varchar
-- @default site_codes null

-- @param site_name The name of the site. Substring search is supported.
-- @type site_name varchar
-- @default site_name null

-- @param site_regions A comma-separated list of geographic region of the sites (UK). Substring search is supported.
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

-- @param page the current page number to retrieve
-- @type page integer
-- @default page 1

-- @param page_size the number of records per page. Default value is 500.
-- @type page_size integer
-- @default page_size 500

-- @param remaining_power_capacity_in_kw_minimum minimum remaining power capacity
-- @type remaining_power_capacity_in_kw_minimum DECIMAL
-- @default remaining_power_capacity_in_kw_minimum NULL

-- @param remaining_power_capacity_in_kw_maximum maximum remaining power capacity
-- @type remaining_power_capacity_in_kw_maximum DECIMAL
-- @default remaining_power_capacity_in_kw_maximum NULL

-- @param running_load_in_kw_minimum minimum running load in kwatt
-- @type running_load_in_kw_minimum DECIMAL
-- @default running_load_in_kw_minimum NULL

-- @param running_load_in_kw_maximum maximum running load in kwatt
-- @type running_load_in_kw_maximum DECIMAL
-- @default running_load_in_kw_maximum NULL

-- @param total_allocated_in_kw_minimum minimum total allocated in kwatt
-- @type total_allocated_in_kw_minimum DECIMAL
-- @default total_allocated_in_kw_minimum NULL

-- @param total_allocated_in_kw_maximum maximum total allocated in kwatt
-- @type total_allocated_in_kw_maximum DECIMAL
-- @default total_allocated_in_kw_maximum NULL

-- @param reserved_load_in_kw_minimum minimum reserved load in kwatt
-- @type reserved_load_in_kw_minimum DECIMAL
-- @default reserved_load_in_kw_minimum NULL

-- @param reserved_load_in_kw_maximum maximum reserved load in kwatt
-- @type reserved_load_in_kw_maximum DECIMAL
-- @default reserved_load_in_kw_maximum NULL

-- @param forecasted_load_in_kw_minimum minimum forecasted load in kwatt
-- @type forecasted_load_in_kw_minimum DECIMAL
-- @default forecasted_load_in_kw_minimum NULL

-- @param forecasted_load_in_kw_maximum maximum forecasted load in kwatt
-- @type forecasted_load_in_kw_maximum DECIMAL
-- @default forecasted_load_in_kw_maximum NULL

-- @param remaining_power_80_of_n_in_kw_minimum minimum remaining power at 80% of N
-- @type remaining_power_80_of_n_in_kw_minimum DECIMAL
-- @default remaining_power_80_of_n_in_kw_minimum NULL

-- @param remaining_power_80_of_n_in_kw_maximum maximum remaining power at 80% of N
-- @type remaining_power_80_of_n_in_kw_maximum DECIMAL
-- @default remaining_power_80_of_n_in_kw_maximum NULL


-- @param free_sections_minimum min number of free sections
-- @type free_sections_minimum integer
-- @default free_sections_minimum null

-- @param free_sections_maximum max number of free sections
-- @type free_sections_maximum integer
-- @default free_sections_maximum null

-- @param free_sections_percentage_minimum min percentage of free sections
-- @type free_sections_percentage_minimum decimal
-- @default free_sections_percentage_minimum null

-- @param free_sections_percentage_maximum max percentage of free sections
-- @type free_sections_percentage_maximum decimal
-- @default free_sections_percentage_maximum null

-- @param occupied_sections_minimum min number of occupied sections
-- @type occupied_sections_minimum integer
-- @default occupied_sections_minimum null

-- @param occupied_sections_maximum max number of occupied sections
-- @type occupied_sections_maximum integer
-- @default occupied_sections_maximum null

-- @param reserved_sections_minimum min number of reserved sections
-- @type reserved_sections_minimum integer
-- @default reserved_sections_minimum null

-- @param reserved_sections_maximum max number of reserved sections
-- @type reserved_sections_maximum integer
-- @default reserved_sections_maximum null

-- @param total_sections_minimum min total sections
-- @type total_sections_minimum integer
-- @default total_sections_minimum null

-- @param total_sections_maximum max total sections
-- @type total_sections_maximum integer
-- @default total_sections_maximum null

-- @param free_sections_area_minimum min free sections area (square meters)
-- @type free_sections_area_minimum decimal
-- @default free_sections_area_minimum null

-- @param free_sections_area_maximum max free sections area (square meters)
-- @type free_sections_area_maximum decimal
-- @default free_sections_area_maximum null

-- @param occupied_sections_area_minimum min occupied sections area (square meters)
-- @type occupied_sections_area_minimum decimal
-- @default occupied_sections_area_minimum null

-- @param occupied_sections_area_maximum max occupied sections area (square meters)
-- @type occupied_sections_area_maximum decimal
-- @default occupied_sections_area_maximum null

-- @param lines_capability_minimum min lines capability (square meters)
-- @type lines_capability_minimum decimal
-- @default lines_capability_minimum null

-- @param lines_capability_maximum max lines capability (square meters)
-- @type lines_capability_maximum decimal
-- @default lines_capability_maximum null

-- @param location_capability_minimum min location capability (square meters)
-- @type location_capability_minimum decimal
-- @default location_capability_minimum null

-- @param location_capability_maximum max location capability (square meters)
-- @type location_capability_maximum decimal
-- @default location_capability_maximum null

-- @param location_free_area_minimum min location free area (square meters)
-- @type location_free_area_minimum decimal
-- @default location_free_area_minimum null

-- @param location_free_area_maximum max location free area (square meters)
-- @type location_free_area_maximum decimal
-- @default location_free_area_maximum null

-- @param location_occupied_area_minimum min location occupied area (square meters)
-- @type location_occupied_area_minimum decimal
-- @default location_occupied_area_minimum null

-- @param location_occupied_area_maximum max location occupied area (square meters)
-- @type location_occupied_area_maximum decimal
-- @default location_occupied_area_maximum null

-- @param year year of opex data to be processed
-- @type year integer
-- @default year 2024

-- @param min_month minimum month of opex data to be processed. Default is 1 (January). All months between min_month and max_month are processed.
-- @type min_month integer
-- @default min_month 01

-- @param max_month maximum month of opex data to be processed. Default is 12 (December). All months between [min_month..max_month] are processed.
-- @type max_month integer
-- @default max_month 12

-- @param min_cost filter sites with cost more than min_cost in thousands of GBP (k GBP).
-- @type min_cost integer
-- @default min_cost NULL

-- @param max_cost filter sites with cost less than max_cost in thousands of GBP (k GBP)
-- @type max_cost integer
-- @default max_cost NULL

-- @param topN sort results by top-N sites the highest operational costs. If not provided, then results are sorted by site code.
-- @type topN integer
-- @default topN NULL

-- @param is_lease_at_risk true if lease is at risk (or lease is not secure), false otherwise (lease is secure)
-- @type is_lease_at_risk boolean
-- @default is_lease_at_risk NULL

-- @param less_than_given_days_until_lease_end retrieve all sites with lease end less than the given number of days 
-- @type less_than_given_days_until_lease_end integer
-- @default less_than_given_days_until_lease_end NULL

-- @param greater_than_given_days_until_lease_end retrieve all sites with lease end more than the given number of days 
-- @type greater_than_given_days_until_lease_end integer
-- @default greater_than_given_days_until_lease_end NULL

-- @return Vodafone Sites with Combined Fixed/Mobile Power Capacity Filters, Space Filters And Opex Filters.

WITH mobile_aggr_capacity AS (
	SELECT mtx, 
		(sum(CAST(remaining_element_capability_a AS FLOAT))*54.5/1000) as aggr_remaining_power_capacity_kw,
		(sum(CAST(element_load_a_19_01_25 AS FLOAT))*54.5/1000) as aggr_running_load_kw,
		(sum(CAST(reserved_a AS FLOAT)+CAST(forecast_a AS FLOAT))*54.5/1000) as aggr_total_allocated_kw,
		(sum(CAST(reserved_a AS FLOAT))*54.5/1000) as aggr_reserved_load_kw,
        (sum(CAST(forecast_a AS FLOAT))*54.5/1000) as aggr_forecasted_load_kw
	FROM vdf.mtx_capacity
	GROUP BY mtx
),
vf_mobile_capacity AS (
    SELECT a.mtx, 
        a.aggr_remaining_power_capacity_kw as remaining_power_capacity_in_kw,
        a.aggr_running_load_kw as running_load_in_kw,
        a.aggr_total_allocated_kw as total_allocated_in_kw,
        a.aggr_reserved_load_kw as reserved_load_in_kw,
        a.aggr_forecasted_load_kw as forecasted_load_in_kw,
        NULL as remaining_power_80_of_n_in_kw,
        'DC' as current_type
    FROM mobile_aggr_capacity a
    UNION
    -- corner case #1: BKLN06
    select
    'BKLN06' as mtx,
    (
        select CAST(room_capablility_kw as DECIMAL)
        from vdf.mtx_capacity_bkln06_room_capability
        where trim(col1_c1)='BKLN06'
        limit 1
    )
    -
    (
        select CAST(totals as DECIMAL)
        from vdf.mtx_capacity_bkln06
        where trim(col1_c1)='kW Allocated'
        limit 1
    ) as remaining_power_capacity_in_kw,
    (
        select CAST(totals as DECIMAL)
        FROM vdf.mtx_capacity_bkln06
        where trim(col1_c1)='kW Measured'
    ) as running_load_in_kw,
    (
        select CAST(totals as DECIMAL)
        FROM vdf.mtx_capacity_bkln06
        where trim(col1_c1)='kW Allocated'
    ) as total_allocated_in_kw,
    NULL as reserved_load_in_kw,
    NULL as forecasted_load_in_kw,
    NULL as remaining_power_80_of_n_in_kw,
    'AC' as current_type
    UNION
    -- corner case #2: XGL001
    select
        'XGL001 (BMGMTX)' as mtx, 
        (
            select CAST(room_capablility_kw as DECIMAL)
            from vdf.mtx_capacity_xgl001_room_capability
            where trim(col1_c1)='XGL001'
            limit 1
        )
        -
        (
            select CAST(totals as DECIMAL)
            from vdf.mtx_capacity_xgl001
            where trim(col1_c1)='kW Allocated'
            limit 1
        ) as remaining_power_capacity_in_kw,
        (
            select  CAST(totals as DECIMAL)
            FROM vdf.mtx_capacity_xgl001
            where trim(col1_c1)='kW Measured'
        ) as running_load_in_kw,
        (
            select  CAST(totals as DECIMAL)
            FROM vdf.mtx_capacity_xgl001
            where trim(col1_c1)='kW Allocated'
        ) as total_allocated_in_kw,
        NULL as reserved_load_in_kw,
        NULL as forecasted_load_in_kw,
        NULL as remaining_power_80_of_n_in_kw,
        'AC' as current_type

),
fixed_aggr_capacity AS (
    SELECT general_equipment_area_code, general_system_name,
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
    FROM vdf.fixed_capacity c
        INNER JOIN vdf.fixed_capacity_cover cv 
            ON c.general_system_name=cv.brag_0_black_0_10_red_10_25_amber_25_green
),
vf_fixed_capacity_avg AS (
    select 
        MAX(fc.general_equipment_area_code) as general_equipment_area_code, 
        fc.general_equipment_area_code || trim(regexp_replace(regexp_replace(replace(general_system_name,' (DO NOT CONNECT LOADS)',''), '[AaBb]$', '', 'g'), 'SYS[ ]*[AaBb]', 'SYS', 'g')) as minus_compl,
        AVG(fc.power_kw_load_remaining_after_total_allocated) as remaining_power_capacity_in_kw,
        SUM(fc.power_actual_load_kw) as running_load_in_kw,
        SUM(fc.kw_power_remaining_80_of_n) as remaining_power_80_of_n_in_kw,
        SUM(fc.total_allocated_load_kw) as total_allocated_load_kw
    FROM fixed_aggr_capacity as fc
    GROUP BY minus_compl
),
vf_fixed_capacity AS (
    select 
        general_equipment_area_code, 
        CAST(NULL as FLOAT) remaining_element_capability_in_amber,
        SUM(remaining_power_capacity_in_kw) as remaining_power_capacity_in_kw,
        SUM(running_load_in_kw) as running_load_in_kw,
        SUM(remaining_power_80_of_n_in_kw) as remaining_power_80_of_n_in_kw,
        CAST(NULL as FLOAT) as forecasted_load_in_kw,
        CAST(NULL as FLOAT) as reserved_load_in_kw,
        SUM(total_allocated_load_kw) as total_allocated_in_kw
    FROM vf_fixed_capacity_avg as fc
    GROUP BY general_equipment_area_code
),
sites_excluded_duplicate_non_identical_numbers AS (
    select distinct site_code --, col1_c1, count(distinct quantity), string_agg(distinct quantity, ',')
    from vdf."space"
    where col1_c1 IS NOT NULL
    group by site_code, col1_c1
    having count(distinct quantity)>1
), space_pivot AS (
    SELECT
        site_code,
        -- Parse the '3' from "3/78" when col1_c1 = 'Total free sections:'
        (
          CASE WHEN col1_c1 = 'Total free sections:' 
               THEN split_part(quantity, '/', 1)::int 
          END
        ) AS free_sections,

        (
          CASE WHEN col1_c1 = 'Total free sections:' 
               THEN free_section_percentage::decimal 
          END
        ) AS free_section_percentage,

        -- Parse the '75' from "75/78" when col1_c1 = 'Total occupied sections:'
        (
          CASE WHEN col1_c1 = 'Total occupied sections:' 
               THEN split_part(quantity, '/', 1)::int 
          END
        ) AS occupied_sections,

        -- Parse the '0' from "0/78" when col1_c1 = 'Total reserved sections:'
        (
          CASE WHEN col1_c1 = 'Total reserved sections:' 
               THEN split_part(quantity, '/', 1)::int 
          END
        ) AS reserved_sections,

        -- Parse the '78' from "0/78" => total possible sections
        (
          CASE WHEN col1_c1 = 'Total reserved sections:' 
               THEN split_part(quantity, '/', 2)::int 
          END
        ) AS total_sections,

        -- e.g. "3.452 m^2" => parse numeric portion => 3.452
        (
          CASE WHEN col1_c1 = 'Total free sections:' 
               THEN regexp_replace(area, '[^0-9\\.]+', '', 'g')::numeric 
          END
        ) AS free_sections_area,

        (
          CASE WHEN col1_c1 = 'Total occupied sections:' 
               THEN regexp_replace(area, '[^0-9\\.]+', '', 'g')::numeric 
          END
        ) AS occupied_sections_area,

        (
          CASE WHEN col1_c1 = 'Total Lines Capability' 
               THEN regexp_replace(area, '[^0-9\\.]+', '', 'g')::numeric 
          END
        ) AS lines_capability,

        (
          CASE WHEN col1_c1 = 'Total Location Capability' 
               THEN regexp_replace(area, '[^0-9\\.]+', '', 'g')::numeric 
          END
        ) AS location_capability,

        (
          CASE WHEN col1_c1 = 'Total Location Free Area' 
               THEN regexp_replace(area, '[^0-9\\.]+', '', 'g')::numeric 
          END
        ) AS location_free_area,

        (
          CASE WHEN col1_c1 = 'Total Location Occupied Area' 
               THEN regexp_replace(area, '[^0-9\\.]+', '', 'g')::numeric 
          END
        ) AS location_occupied_area,

        (
          CASE 
            WHEN col1_c1 LIKE 'Room%' 
            THEN regexp_replace(
                   regexp_replace(col1_c1, '^Room ', ''), 
                   ' on .*', ''
                 )
          END
        ) AS gen_site_code

    FROM vdf.vfspace
    WHERE site_code NOT IN (select site_code from sites_excluded_duplicate_non_identical_numbers)
), space_base AS (
    SELECT site_code, 
        MAX(free_sections) AS free_sections,
        MAX(free_section_percentage) AS free_section_percentage,
        MAX(occupied_sections) AS occupied_sections,
        MAX(reserved_sections) AS reserved_sections,
        MAX(total_sections) AS total_sections,
        MAX(free_sections_area) AS free_sections_area,
        MAX(occupied_sections_area) AS occupied_sections_area,
        MAX(lines_capability) AS lines_capability,
        MAX(location_capability) AS location_capability,
        MAX(location_free_area) AS location_free_area,
        MAX(location_occupied_area) AS location_occupied_area,
        MAX(gen_site_code) AS gen_site_code
    FROM space_pivot
    GROUP BY site_code
),
unique_postal_codes AS (
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
		AND (:site_name IS NULL OR upper(vfsites.site_name) ILIKE CONCAT('%', :site_name, '%'))
        AND (:site_regions IS NULL OR EXISTS (
            SELECT 1
            FROM unnest(regexp_split_to_array(trim(upper(:site_regions)), ',')) AS arr1(elem1)
                CROSS JOIN unnest(regexp_split_to_array(trim(upper(vfsites.region)), ',')) AS arr2(elem2)
            WHERE trim(elem2) LIKE '' ||trim(elem1) || '%'
        ))
        AND (:site_address IS NULL OR upper(vfsites.address) ILIKE CONCAT('%', :site_address, '%'))
		AND (:freehold_leasehold IS NULL OR UPPER(vfsites.freehold_leasehold) = UPPER(:freehold_leasehold))
		AND (:site_status IS NULL OR vfsites.status = :site_status)
		AND (:gis_migrated IS NULL OR 
			(:gis_migrated=true AND UPPER(vfsites.gis_migrated) = 'TRUE') OR
			(:gis_migrated=false AND UPPER(vfsites.gis_migrated) = 'FALSE'))
		AND (:comments IS NULL OR upper(vfsites.comments) ILIKE CONCAT('%', :comments, '%'))
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
combined_with_capacity_tmp AS (
    select s.*, -- fc.general_equipment_area_code, fc.general_system_name, 
        round(CAST(fc.remaining_power_capacity_in_kw AS DECIMAL), 1) as remaining_power_capacity_in_kw,
        round(CAST(fc.running_load_in_kw AS DECIMAL), 1) as running_load_in_kw,
        round(CAST(fc.total_allocated_in_kw AS DECIMAL), 1) as total_allocated_in_kw,
        round(CAST(fc.reserved_load_in_kw AS DECIMAL), 1) as reserved_load_in_kw,
        round(CAST(fc.forecasted_load_in_kw AS DECIMAL), 1) as forecasted_load_in_kw,
        round(CAST(fc.remaining_power_80_of_n_in_kw AS DECIMAL), 1) as remaining_power_80_of_n_in_kw
    FROM filtered_sites s 
        LEFT OUTER JOIN vf_fixed_capacity fc 
            ON upper(trim(fc.general_equipment_area_code)) = trim(replace(replace(upper(s.site_code), '(GROUND FLOOR)', ''), 'ROOM', ''))
    WHERE site_type NOT IN ('MTX','LTC')
    
    -- GROUP BY rollup(fc.general_equipment_area_code, fc.general_system_name)
    UNION
    SELECT distinct filtered_sites.*,
        -- vf_mobile_capacity.remaining_element_capability_in_amber,
        round(CAST(vf_mobile_capacity.remaining_power_capacity_in_kw AS DECIMAL), 1),
        round(CAST(vf_mobile_capacity.running_load_in_kw AS DECIMAL), 1),
        round(CAST(vf_mobile_capacity.total_allocated_in_kw AS DECIMAL), 1),
        round(CAST(vf_mobile_capacity.reserved_load_in_kw AS DECIMAL), 1),
        round(CAST(vf_mobile_capacity.forecasted_load_in_kw AS DECIMAL), 1),
        round(CAST(vf_mobile_capacity.remaining_power_80_of_n_in_kw AS DECIMAL), 1)
    FROM filtered_sites 
        LEFT OUTER JOIN vf_mobile_capacity
        ON filtered_sites.site_code=vf_mobile_capacity.mtx 
            OR (filtered_sites.site_code NOT IN ('XGL001 (BMGMTX)', 'BKLN06') AND filtered_sites.site_name=trim(split_part(vf_mobile_capacity.mtx, ' TXO', 1)))
    WHERE (filtered_sites.site_type='LTC' OR filtered_sites.site_type='MTX')
),
combined_with_capacity AS (
    SELECT * 
    FROM combined_with_capacity_tmp
    WHERE
        (:remaining_power_capacity_in_kw_minimum IS NULL OR remaining_power_capacity_in_kw>=:remaining_power_capacity_in_kw_minimum)
        AND (:remaining_power_capacity_in_kw_maximum IS NULL OR remaining_power_capacity_in_kw<=:remaining_power_capacity_in_kw_maximum)
        AND (:running_load_in_kw_minimum IS NULL OR running_load_in_kw>=:running_load_in_kw_minimum)
        AND (:running_load_in_kw_maximum IS NULL OR running_load_in_kw<=:running_load_in_kw_maximum)
        AND (:total_allocated_in_kw_minimum IS NULL OR total_allocated_in_kw>=:total_allocated_in_kw_minimum)
        AND (:total_allocated_in_kw_maximum IS NULL OR total_allocated_in_kw<=:total_allocated_in_kw_maximum)     
        AND (:reserved_load_in_kw_minimum IS NULL OR reserved_load_in_kw>=:reserved_load_in_kw_minimum)
        AND (:reserved_load_in_kw_maximum IS NULL OR reserved_load_in_kw<=:reserved_load_in_kw_maximum)
        AND (:forecasted_load_in_kw_minimum IS NULL OR forecasted_load_in_kw>=:forecasted_load_in_kw_minimum)
        AND (:forecasted_load_in_kw_maximum IS NULL OR forecasted_load_in_kw<=:forecasted_load_in_kw_maximum)
        AND (:remaining_power_80_of_n_in_kw_minimum IS NULL OR remaining_power_80_of_n_in_kw>=:remaining_power_80_of_n_in_kw_minimum)
        AND (:remaining_power_80_of_n_in_kw_maximum IS NULL OR remaining_power_80_of_n_in_kw<=:remaining_power_80_of_n_in_kw_maximum)
),
combined_with_space AS (
    SELECT 
      s.*,
      sb.free_sections,
      sb.occupied_sections,
      sb.reserved_sections,
      sb.free_section_percentage,
      sb.total_sections,
      sb.free_sections_area,
      sb.occupied_sections_area,
      sb.lines_capability,
      sb.location_capability,
      sb.location_free_area,
      sb.location_occupied_area
    FROM combined_with_capacity s
    LEFT OUTER JOIN space_base sb 
      ON (
           UPPER(TRIM(s.site_code))=UPPER(TRIM(sb.gen_site_code))
         )
         OR UPPER(TRIM(regexp_replace(s.site_code,' (.*)','')))
            =UPPER(TRIM(sb.gen_site_code))
         OR (
           UPPER(TRIM(s.site_code))=UPPER(TRIM(sb.site_code))
         )
         OR (
           UPPER(TRIM(regexp_replace(s.site_code,' (.*)','')))
            =UPPER(TRIM(sb.site_code))
         )
    WHERE 
        /* Existing free sections filter */
        (
          :free_sections_minimum IS NULL 
          OR sb.free_sections>=:free_sections_minimum
        )
        AND (
          :free_sections_maximum IS NULL 
          OR sb.free_sections<=:free_sections_maximum
        )
        
        AND (
          :free_sections_percentage_minimum IS NULL
          OR (sb.free_section_percentage * 100)>=:free_sections_percentage_minimum
        )
        AND (
          :free_sections_percentage_maximum IS NULL
          OR (sb.free_section_percentage * 100)<=:free_sections_percentage_maximum
        )

        /* Occupied sections filter */
        AND (
          :occupied_sections_minimum IS NULL 
          OR sb.occupied_sections>=:occupied_sections_minimum
        )
        AND (
          :occupied_sections_maximum IS NULL 
          OR sb.occupied_sections<=:occupied_sections_maximum
        )

        /* Reserved sections filter */
        AND (
          :reserved_sections_minimum IS NULL 
          OR sb.reserved_sections>=:reserved_sections_minimum
        )
        AND (
          :reserved_sections_maximum IS NULL 
          OR sb.reserved_sections<=:reserved_sections_maximum
        )

        /* Total sections filter */
        AND (
          :total_sections_minimum IS NULL 
          OR sb.total_sections>=:total_sections_minimum
        )
        AND (
          :total_sections_maximum IS NULL 
          OR sb.total_sections<=:total_sections_maximum
        )

        /* Free sections area */
        AND (
          :free_sections_area_minimum IS NULL 
          OR sb.free_sections_area>=:free_sections_area_minimum
        )
        AND (
          :free_sections_area_maximum IS NULL 
          OR sb.free_sections_area<=:free_sections_area_maximum
        )

        /* Occupied sections area */
        AND (
          :occupied_sections_area_minimum IS NULL 
          OR sb.occupied_sections_area>=:occupied_sections_area_minimum
        )
        AND (
          :occupied_sections_area_maximum IS NULL 
          OR sb.occupied_sections_area<=:occupied_sections_area_maximum
        )

        /* Lines capability */
        AND (
          :lines_capability_minimum IS NULL 
          OR sb.lines_capability>=:lines_capability_minimum
        )
        AND (
          :lines_capability_maximum IS NULL 
          OR sb.lines_capability<=:lines_capability_maximum
        )

        /* Location capability */
        AND (
          :location_capability_minimum IS NULL 
          OR sb.location_capability>=:location_capability_minimum
        )
        AND (
          :location_capability_maximum IS NULL 
          OR sb.location_capability<=:location_capability_maximum
        )

        /* Location free area */
        AND (
          :location_free_area_minimum IS NULL 
          OR sb.location_free_area>=:location_free_area_minimum
        )
        AND (
          :location_free_area_maximum IS NULL 
          OR sb.location_free_area<=:location_free_area_maximum
        )

        /* Location occupied area */
        AND (
          :location_occupied_area_minimum IS NULL 
          OR sb.location_occupied_area>=:location_occupied_area_minimum
        )
        AND (
          :location_occupied_area_maximum IS NULL 
          OR sb.location_occupied_area<=:location_occupied_area_maximum
        )
), combined_with_ownership_codes AS (
  SELECT combined_with_space.site_code, 
    ownership.at_risk, ownership.tenure, ownership.tenancy_reference, CAST(lease_end AS TIMESTAMP) as lease_end, CAST(lease_start AS TIMESTAMP) as lease_start
  FROM combined_with_space
    INNER JOIN vdf.vfbridge 
      ON upper(trim(vfbridge.site_code))=upper(trim(combined_with_space.site_code))
    INNER JOIN vdf.ownership 
      ON ownership.property_reference_2=regexp_replace(bridge_site_code, '(.*)\\_', '')
        AND upper(trim(ownership.business_division))='TECHNOLOGY' --AND upper(trim(ownership.primary_use))='OFFICE'
  UNION
  SELECT s.site_code, o.at_risk, o.tenure, o.tenancy_reference, CAST(lease_end AS TIMESTAMP) as lease_end, CAST(lease_start AS TIMESTAMP) as lease_start
  FROM combined_with_space s 
    INNER JOIN vdf.ownership o 
      ON s.postcode=o.postcode 
        AND upper(trim(o.business_division))='TECHNOLOGY' --AND upper(trim(o.primary_use))='OFFICE'
), combined_with_ownership_unfiltered AS (
  SELECT DISTINCT s.*, (CASE WHEN c.at_risk IS NOT NULL AND upper(trim(at_risk))='AT RISK' THEN true else false END) as at_risk, 
    c.tenure, c.tenancy_reference, CAST(lease_end AS TIMESTAMP) as lease_end, CAST(lease_start AS TIMESTAMP) as lease_start
  FROM combined_with_space s 
    LEFT OUTER JOIN combined_with_ownership_codes c
      ON s.site_code=c.site_code
        AND c.tenancy_reference=(SELECT MIN(tenancy_reference) FROM combined_with_ownership_codes ow WHERE ow.site_code=c.site_code)
        AND NOW()<CAST(lease_end AS TIMESTAMP) AND NOW()>CAST(lease_start AS TIMESTAMP) 
), combined_with_ownership AS (
  SELECT * 
  FROM combined_with_ownership_unfiltered
  WHERE (:is_lease_at_risk IS NULL OR :is_lease_at_risk=at_risk)
    AND (:less_than_given_days_until_lease_end IS NULL OR 
      DATE(lease_end) < (NOW()::date + :less_than_given_days_until_lease_end ))
    AND (:greater_than_given_days_until_lease_end IS NULL OR 
      DATE(lease_end) > (NOW()::date + :greater_than_given_days_until_lease_end ))
),
filtered_vfopex AS (
    SELECT distinct sitecode, ROUND((SUM(CAST(vfopex.reading_value AS DECIMAL)) * 0.25) / 1000, 2) AS total_cost_in_k_GBP
    FROM vdf.vfopex
    WHERE date_part('year', CAST(vfopex.reading_date AS DATE))=:year
        and date_part('month', CAST(vfopex.reading_date AS DATE))>=:min_month
        and date_part('month', CAST(vfopex.reading_date AS DATE))<=:max_month
    GROUP BY sitecode
),
combined_with_opex_tmp AS (
    SELECT combined_with_ownership.*,
        total_cost_in_k_gbp
    FROM combined_with_ownership
        left outer join vdf.vfbridge on upper(trim(vfbridge.site_code))=combined_with_ownership.site_code
            OR (vfbridge.postcode=combined_with_ownership.postcode AND vfbridge.postcode IN (
                select postcode from unique_postal_codes)
            )
            OR (vfbridge.site_code IS NOT NULL AND (
                trim(combined_with_ownership.site_code) LIKE concat('%(',upper(trim(vfbridge.site_code)),')%'))
                OR (upper(trim(vfbridge.site_code)) ~ concat(combined_with_ownership.site_code,'\\s*[,&].*'))
                OR (upper(trim(vfbridge.site_code)) ~ concat('.*[,&]\\s*',combined_with_ownership.site_code))
            )
        left outer join filtered_vfopex on upper(trim(vfbridge.bridge_site_code))=upper(trim(filtered_vfopex.sitecode))
    WHERE (:min_cost IS NULL OR total_cost_in_k_gbp>:min_cost) 
        AND 
        (:max_cost IS NULL OR total_cost_in_k_gbp<:max_cost)
        AND
        (CASE WHEN :topN IS NOT NULL THEN total_cost_in_k_gbp IS NOT NULL ELSE true END)
    ORDER BY
        -- If topN is provided, sort by total_cost DESC; otherwise sort by site_code ASC
        CASE WHEN :topN IS NOT NULL THEN total_cost_in_k_gbp END DESC,
        CASE WHEN :topN IS NULL THEN combined_with_ownership.site_code END ASC
    LIMIT CASE WHEN :topN IS NOT NULL THEN :topN ELSE 1000 END
),
combined_with_opex AS (
  SELECT distinct *
  FROM combined_with_opex_tmp
)
SELECT *
FROM combined_with_opex
ORDER BY
        -- If topN is provided, sort by total_cost DESC; otherwise sort by site_code ASC
        CASE WHEN :topN IS NOT NULL THEN total_cost_in_k_gbp END DESC,
        CASE WHEN :topN IS NULL THEN site_code END ASC
LIMIT COALESCE(:page_size, 500)
OFFSET (COALESCE(:page, 1) - 1) * COALESCE(:page_size, 500);
