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
), unique_postal_codes AS (
  SELECT postcode
  FROM vdf.vfsites
  GROUP BY postcode
  HAVING count(*)=1
), split_site_codes AS (
  SELECT TRIM(x) AS code
  FROM regexp_split_to_table(COALESCE(:site_codes, ''), ',') AS x
), 
book_outliers_unmatched_postcodes AS (
    select vfsites.site_code, vfsites.site_name, vfsites.postcode, vfbridge.site_code as bridge_site_code,
        vfbridge.postcode as bridge_postcode,
        'Book outliers due to postcode mismatch' as outlier_reason
    from vdf.vfsites 
        left outer join vdf.vfbridge on upper(trim(vfbridge.site_code))=vfsites.site_code
    OR (vfbridge.postcode=vfsites.postcode AND vfbridge.postcode IN (select postcode from unique_postal_codes))
    OR (vfbridge.site_code IS NOT NULL AND (
        vfsites.site_code LIKE concat('%(',upper(trim(vfbridge.site_code)),')%'))
        -- OR (upper(trim(vfbridge.site_code)) ~ concat(vfsites.site_code,'\\s*[,&].*'))
        -- OR (upper(trim(vfbridge.site_code)) ~ concat('.*[,&]\\s*',vfsites.site_code)))
        OR trim(vfbridge.site_code)=trim(vfsites.site_code))
    where vfbridge.site_code IS NOT NULL 
        AND vfbridge.postcode IS NOT NULL 
        AND vfbridge.postcode IS NOT NULL
        AND upper(trim(vfbridge.postcode))!=upper(trim(vfsites.postcode))
),
book_outliers_duplicate_book AS (
    select vfsites.site_code, NULL, NULL, string_agg(vfbridge.site_code, ', '), string_agg(vfbridge.postcode, ', '), 'Duplicate book entry'
    from vdf.vfsites 
        inner join vdf.vfbridge on upper(trim(vfbridge.site_code))=vfsites.site_code
    OR (vfbridge.site_code IS NOT NULL AND (
        vfsites.site_code LIKE concat('%(',upper(trim(vfbridge.site_code)),')%'))
        -- OR (upper(trim(vfbridge.site_code)) ~ concat(vfsites.site_code,'\\s*[,&].*'))
        -- OR (upper(trim(vfbridge.site_code)) ~ concat('.*[,&]\\s*',vfsites.site_code)))
        OR trim(vfbridge.site_code)=trim(vfsites.site_code))
    group by vfsites.site_code
    having count(*)>1
),
book_outliers_rest AS (
    select vfsites.site_code, vfsites.site_name, vfsites.postcode, vfbridge.site_code as bridge_site_code,
        vfbridge.postcode as bridge_postcode,
        'Book mismatches' as outlier_reason
    from vdf.vfsites 
        left outer join vdf.vfbridge on upper(trim(vfbridge.site_code))=vfsites.site_code
    OR (vfbridge.postcode=vfsites.postcode AND vfbridge.postcode IN (select postcode from unique_postal_codes))
    OR (vfbridge.site_code IS NOT NULL AND (
        vfsites.site_code LIKE concat('%(',upper(trim(vfbridge.site_code)),')%'))
        -- OR (upper(trim(vfbridge.site_code)) ~ concat(vfsites.site_code,'\\s*[,&].*'))
        -- OR (upper(trim(vfbridge.site_code)) ~ concat('.*[,&]\\s*',vfsites.site_code)))
        OR trim(vfbridge.site_code)=trim(vfsites.site_code))
    where vfbridge.site_code IS NULL
),
opex_outliers AS (
    select vfsites.site_code, vfsites.site_name, vfsites.postcode, vfbridge.site_code as bridge_site_code,
    vfbridge.postcode as bridge_postcode,
    'Opex mismatches' as outlier_reason
    from vdf.vfsites
        inner join vdf.vfbridge on upper(trim(vfbridge.site_code))=vfsites.site_code
            OR (vfbridge.postcode=vfsites.postcode AND vfbridge.postcode IN (
                select postcode from unique_postal_codes)
            )
            OR (vfbridge.site_code IS NOT NULL AND (
                vfsites.site_code LIKE concat('%(',upper(trim(vfbridge.site_code)),')%'))
                -- OR (upper(trim(vfbridge.site_code)) ~ concat(vfsites.site_code,'\\s*[,&].*'))
                -- OR (upper(trim(vfbridge.site_code)) ~ concat('.*[,&]\\s*',vfsites.site_code))
                OR trim(vfbridge.site_code)=trim(vfsites.site_code)
            )
        left outer join vdf.opex on upper(trim(vfbridge.bridge_site_code))=upper(trim(opex.sitecode))
    where true
        -- AND vfbridge.site_code IS NOT NULL 
        -- AND vfbridge.postcode IS NOT NULL 
        -- AND vfbridge.postcode IS NOT NULL
        -- AND upper(trim(vfbridge.postcode))!=upper(trim(vfsites.postcode))
        AND opex.sitecode IS NULL
),
combined AS (
    select * from book_outliers_unmatched_postcodes
    UNION
    select * from book_outliers_duplicate_book
    UNION
    select * from book_outliers_rest
    UNION
    select * from opex_outliers
)
SELECT *
FROM combined
WHERE (
    :site_codes IS NULL OR UPPER(TRIM(site_code)) IN (SELECT UPPER(TRIM(code)) FROM split_site_codes)
) AND NOT EXISTS(SELECT * FROM user_blacklist_opex) -- redact all non-opex users
ORDER BY outlier_reason, site_code
