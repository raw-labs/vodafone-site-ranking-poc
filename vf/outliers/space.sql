-- @param site_codes A comma-separated list of site codes.
-- @type site_codes varchar
-- @default site_codes null

-- @param userid user identifier injected for authorization and data redaction purposes.
-- @type userid varchar
-- @default userid NULL

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
), base as (
    select site_code, col1_c1, replace(replace(col1_c1, '^Room ',''), ' on .*', '') as gen_site_code
    from vdf."space"
    where col1_c1 like 'Room%'
    group by site_code, col1_c1
), un1 as (
    select s.site_code as sites_site_code, 
        trim(regexp_replace(s.site_code, ' (.*)', '')) as sites_proc_site_code, 
        base.site_code as space_site_code,
        'Not found in Space data' as exclusion_reason
    from vdf.vfsites s left outer join base on 
    (upper(trim(s.site_code))=upper(trim(base.gen_site_code))) OR UPPER(trim(regexp_replace(s.site_code, ' (.*)', ''))) = UPPER(trim(base.gen_site_code)) OR
    (upper(trim(s.site_code))=upper(trim(base.site_code))) OR regexp_replace(s.site_code, ' (.*)', '') = UPPER(trim(base.site_code))
), un2 as (
    select s.site_code as sites_site_code, 
        trim(regexp_replace(s.site_code, ' (.*)', '')) as sites_proc_site_code, 
        base.site_code as space_site_code,
        'Not found in site data' as exclusion_reason
    from base left outer join vdf.vfsites s on 
    (upper(trim(s.site_code))=upper(trim(base.gen_site_code))) OR UPPER(trim(regexp_replace(s.site_code, ' (.*)', ''))) = UPPER(trim(base.gen_site_code)) OR
    (upper(trim(s.site_code))=upper(trim(base.site_code))) OR regexp_replace(s.site_code, ' (.*)', '') = UPPER(trim(base.site_code))
), 
all_data AS (
    select sites_site_code as site_code, exclusion_reason 
    from un1 where un1.sites_site_code IS NULL OR un1.space_site_code IS NULL
    union
    select space_site_code as site_code, exclusion_reason 
    from un2 where un2.sites_site_code IS NULL OR un2.space_site_code IS NULL
)
SELECT * 
FROM all_data 
WHERE (
    :site_codes IS NULL OR UPPER(TRIM(site_code)) IN (SELECT UPPER(TRIM(code)) FROM split_site_codes)
) AND NOT EXISTS(SELECT * FROM user_blacklist_space) -- redact all non-space users
ORDER BY exclusion_reason;
