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

-- @param page the current page number to retrieve
-- @type page integer
-- @default page 1

-- @param page_size the number of records per page. Default value is 50.
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

-- @param remaining_power_80_of_n_in_kw_maximum maximum minimum remaining power at 80% of N
-- @type remaining_power_80_of_n_in_kw_maximum DECIMAL
-- @default remaining_power_80_of_n_in_kw_maximum NULL

-- @return Vodafone Sites with Combined Fixed/Mobile Power Capacity Filters.

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
        fc.general_equipment_area_code || trim(regexp_replace(regexp_replace(general_system_name, '[AaBb]$', '', 'g'), 'SYS[ ]*[AaBb]', 'SYS', 'g')) as minus_compl,
        AVG(fc.power_kw_load_remaining_after_total_allocated) as remaining_power_capacity_in_kw,
        SUM(fc.power_actual_load_kw) as running_load_in_kw,
        SUM(fc.kw_power_remaining_80_of_n) as remaining_power_80_of_n_in_kw
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
        CAST(NULL as FLOAT) as total_allocated_in_kw
    FROM vf_fixed_capacity_avg as fc
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
combined AS (
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
)
SELECT distinct *
FROM combined
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
LIMIT COALESCE(:page_size, 50)
OFFSET (COALESCE(:page, 1) - 1) * COALESCE(:page_size, 50);
