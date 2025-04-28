-- @param site_types A comma-separated list of site types. 
--        Permissible values are: [LTC, P-core, PX, regular, CHE, NFV, PABR, Amitie, RA, OpX, Gi-LAN]
-- @type site_types varchar
-- @default site_types null

-- @param site_codes A comma-separated list of site codes.
-- @type site_codes varchar
-- @default site_codes null

-- @param site_name The name of the site. Substring search is supported.
-- @type site_name varchar
-- @default site_name null

-- @param site_regions A comma-separated list of geographic regions (UK). 
--        Substring search is supported.
-- @type site_regions varchar
-- @default site_regions null

-- @param site_address The UK address of the site. Substring search is supported.
-- @type site_address varchar
-- @default site_address null

-- @param freehold_leasehold Freehold/Leasehold. 
--        Permissible values are: [Freehold, Leasehold]
-- @type freehold_leasehold varchar
-- @default freehold_leasehold null

-- @param site_status Permissible values: [Normal, Closed, Planned Closure, Restricted]
-- @type site_status varchar
-- @default site_status null

-- @param gis_migrated True if the site is migrated to GIS.
-- @type gis_migrated boolean
-- @default gis_migrated null

-- @param restricted True if the site access is restricted.
-- @type restricted boolean
-- @default restricted null

-- @param comments Comments or notes about sites. Substring search is supported.
-- @type comments varchar
-- @default comments null

-- @param power_resilience Power resilience (e.g. [Mixed (Both N & N+N), N only, ...]).
-- @type power_resilience varchar
-- @default power_resilience null

-- @param network_domain Distinguishes mobile (MTX, LTC) vs. fixed sites. 
--        Permissible values are: [mobile, fixed]
-- @type network_domain varchar
-- @default network_domain null

-- @param page the current page number to retrieve
-- @type page integer
-- @default page 1

-- @param page_size the number of records per page. Default 500.
-- @type page_size integer
-- @default page_size 500

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


WITH sites_excluded_duplicate_non_identical_numbers AS (
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
), split_site_codes AS (
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
                COALESCE(TRIM(REPLACE(UPPER(:site_types),'-','')), ''), 
                ','
            )
            &&
            regexp_split_to_array(
                TRIM(REPLACE(
                    REPLACE(UPPER(site_category), 'PABR','PABR,PCORE')
                    || ',' || UPPER(site_type),
                '-','')),
                ','
            )
        )
        AND (
            :site_codes IS NULL 
            OR UPPER(TRIM(site_code)) 
               IN (SELECT UPPER(TRIM(code)) FROM split_site_codes)
        )
		AND (:site_name IS NULL 
             OR UPPER(vfsites.site_name) 
                  ILIKE CONCAT('%', UPPER(:site_name), '%'))
        AND (
            :site_regions IS NULL 
            OR EXISTS (
                SELECT 1
                FROM unnest(
                  regexp_split_to_array(TRIM(UPPER(:site_regions)), ',')
                ) arr1(elem1)
                CROSS JOIN unnest(
                  regexp_split_to_array(TRIM(UPPER(vfsites.region)), ',')
                ) arr2(elem2)
                WHERE TRIM(elem2) LIKE TRIM(elem1) || '%'
            )
        )
        AND (:site_address IS NULL 
             OR UPPER(vfsites.address) 
                  ILIKE CONCAT('%', UPPER(:site_address), '%'))
		AND (:freehold_leasehold IS NULL 
             OR UPPER(vfsites.freehold_leasehold) = UPPER(:freehold_leasehold))
		AND (:site_status IS NULL 
             OR vfsites.status = :site_status)
		AND (:gis_migrated IS NULL 
             OR (
               :gis_migrated=true 
               AND UPPER(vfsites.gis_migrated)='TRUE'
             ) 
             OR (
               :gis_migrated=false 
               AND UPPER(vfsites.gis_migrated)='FALSE'
             )
        )
		AND (
          :comments IS NULL 
          OR UPPER(vfsites.comments) 
               ILIKE CONCAT('%', UPPER(:comments), '%')
        )
		AND (
          :restricted IS NULL 
          OR (
            :restricted=true 
            AND UPPER(vfsites.restricted)='TRUE'
          ) 
          OR (
            :restricted=false 
            AND UPPER(vfsites.restricted)='FALSE'
          )
        )
		AND (
          :power_resilience IS NULL 
          OR UPPER(vfsites.power_resilience) 
               ILIKE CONCAT('%', UPPER(:power_resilience), '%')
        )
        AND (
            :network_domain IS NULL
            OR (
              UPPER(:network_domain)='MOBILE' 
              AND vfsites.site_type IN ('MTX','LTC')
            )
            OR (
              UPPER(:network_domain)='FIXED' 
              AND vfsites.site_type NOT IN ('MTX','LTC')
            )
        )
),
combined AS (
    SELECT 
      s.*,
      sb.free_sections,
      sb.occupied_sections,
      sb.reserved_sections,
      sb.total_sections,
      sb.free_section_percentage,
      sb.free_sections_area,
      sb.occupied_sections_area,
      sb.lines_capability,
      sb.location_capability,
      sb.location_free_area,
      sb.location_occupied_area,
      sb.gen_site_code,
      UPPER(TRIM(regexp_replace(s.site_code,' (.*)',''))) as site_code_after,
      sb.site_code as sbsitecode
    FROM filtered_sites s
    INNER JOIN space_base sb 
     ON (
            gen_site_code IS NOT NULL 
            AND 
            (
              UPPER(TRIM(s.site_code))=UPPER(TRIM(sb.gen_site_code)) 
              OR 
              (
                UPPER(TRIM(s.site_code))!=UPPER(TRIM(sb.gen_site_code)) 
                AND 
                UPPER(TRIM(regexp_replace(s.site_code,' (.*)','')))=UPPER(TRIM(sb.gen_site_code))
              )
            )
        )
        OR 
        (
          (
            gen_site_code IS NULL 
            OR (
              UPPER(TRIM(s.site_code))!=UPPER(TRIM(sb.gen_site_code)) 
              AND 
              UPPER(TRIM(regexp_replace(s.site_code,' (.*)','')))!=UPPER(TRIM(sb.gen_site_code))
            ) 
          )
          AND 
          (
            UPPER(TRIM(s.site_code))=UPPER(TRIM(sb.site_code)) 
            OR 
            (
              UPPER(TRIM(s.site_code))!=UPPER(TRIM(sb.site_code)) 
              AND 
              UPPER(TRIM(regexp_replace(s.site_code,' (.*)','')))=UPPER(TRIM(sb.site_code))
              AND UPPER(TRIM(sb.site_code))!='BKLN05' AND UPPER(TRIM(s.site_code))!='BKLN05 EXT ROOM'
            )
          )
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
          OR (sb.free_section_percentage)>=:free_sections_percentage_minimum
        )
        AND (
          :free_sections_percentage_maximum IS NULL
          OR (sb.free_section_percentage)<=:free_sections_percentage_maximum
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
)
SELECT *
FROM combined
LIMIT COALESCE(:page_size, 500)
OFFSET (COALESCE(:page, 1) - 1) * COALESCE(:page_size, 500);
