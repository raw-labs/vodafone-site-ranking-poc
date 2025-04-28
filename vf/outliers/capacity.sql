-- @param site_codes A comma-separated list of site codes.
-- @type site_codes varchar
-- @default site_codes null

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
), split_site_codes AS (
  SELECT TRIM(x) AS code
  FROM regexp_split_to_table(COALESCE(:site_codes, ''), ',') AS x
), mtx_capacity_plus_corner_cases AS (
    SELECT mtx
    FROM vdf.mtx_capacity
    UNION SELECT 'BKLN06'
    UNION SELECT 'XGL001 (BMGMTX)'
), unmatched_sites_in_capacity AS (
    select s.*
    FROM vdf.vfsites s 
        LEFT OUTER JOIN vdf.fixed_capacity fc 
            ON upper(trim(fc.general_equipment_area_code)) = trim(replace(replace(upper(s.site_code), '(GROUND FLOOR)', ''), 'ROOM', ''))
    WHERE fc.general_equipment_area_code IS NULL AND site_type NOT IN ('MTX','LTC')
    UNION
    SELECT s.*
    FROM vdf.vfsites s
        LEFT OUTER JOIN mtx_capacity_plus_corner_cases mc 
            ON s.site_code=mc.mtx 
            OR (s.site_code NOT IN ('XGL001 (BMGMTX)', 'BKLN06') AND s.site_name=trim(split_part(mc.mtx, ' TXO', 1)))
    WHERE (s.site_type='LTC' OR s.site_type='MTX') AND mc.mtx IS NULL
), unmatched_capacity_site_codes_in_sites AS (
    select fc.general_equipment_area_code as site_code
    FROM vdf.vfsites s 
        RIGHT OUTER JOIN vdf.fixed_capacity fc 
            ON upper(trim(fc.general_equipment_area_code)) = trim(replace(replace(upper(s.site_code), '(GROUND FLOOR)', ''), 'ROOM', ''))
    WHERE s.site_code IS NULL AND fc.general_equipment_area_code IS NOT NULL
    UNION
    SELECT mc.mtx
    FROM vdf.vfsites s
        RIGHT OUTER JOIN mtx_capacity_plus_corner_cases mc 
            ON s.site_code=mc.mtx 
            OR (s.site_code NOT IN ('XGL001 (BMGMTX)', 'BKLN06') AND s.site_name=trim(split_part(mc.mtx, ' TXO', 1)))
    WHERE s.site_code IS NULL AND mtx IS NOT NULL
),
exclusions AS (
    SELECT unmatched_sites_in_capacity.site_code, 
        'No capacity record found for this site' as exclusion_reason
    FROM unmatched_sites_in_capacity
    UNION
    SELECT unmatched_capacity_site_codes_in_sites.site_code, 
        'No site record found for this capacity entry' as exclusion_reason
    FROM unmatched_capacity_site_codes_in_sites
    UNION
    SELECT general_equipment_area_code,
        'Fixed capacity entry has empty system name' as exclusion_reason
    FROM vdf.fixed_capacity
    WHERE general_system_name IS NULL
)
SELECT trim(site_code) as site_code, exclusion_reason
FROM exclusions
WHERE (
    :site_codes IS NULL OR UPPER(TRIM(site_code)) IN (SELECT UPPER(TRIM(code)) FROM split_site_codes)
) AND NOT EXISTS(SELECT * FROM user_blacklist_capacity) -- redact all non-capacity users
ORDER BY exclusion_reason
