
-- @param site_codes A comma-separated list of site codes.
-- @type site_codes varchar
-- @default site_codes null

-- @param is_lease_at_risk true if lease is at risk (or lease is not secure), false otherwise (lease is secure)
-- @type is_lease_at_risk boolean
-- @default is_lease_at_risk NULL

-- @param less_than_given_days_until_lease_end retrieve all sites with lease end less than the given number of days 
-- @type less_than_given_days_until_lease_end integer
-- @default less_than_given_days_until_lease_end NULL

-- @param greater_than_given_days_until_lease_end retrieve all sites with lease end more than the given number of days 
-- @type greater_than_given_days_until_lease_end integer
-- @default greater_than_given_days_until_lease_end NULL

WITH split_site_codes AS (
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
), combined_with_ownership_codes AS (
  SELECT filtered_sites.site_code, 
    ownership.at_risk, ownership.tenure, ownership.tenancy_reference, CAST(lease_end AS TIMESTAMP) as lease_end, CAST(lease_start AS TIMESTAMP) as lease_start
    -- ownership.*
  FROM filtered_sites
    INNER JOIN vdf.vfbridge 
      ON upper(trim(vfbridge.site_code))=upper(trim(filtered_sites.site_code))
    INNER JOIN vdf.ownership 
      ON ownership.property_reference_2=regexp_replace(bridge_site_code, '(.*)\\_', '')
        AND upper(trim(ownership.business_division))='TECHNOLOGY' --AND upper(trim(ownership.primary_use))='OFFICE'
  UNION
  SELECT s.site_code, o.at_risk, o.tenure, o.tenancy_reference, CAST(lease_end AS TIMESTAMP) as lease_end, CAST(lease_start AS TIMESTAMP) as lease_start
    -- o.*
  FROM filtered_sites s 
    INNER JOIN vdf.ownership o 
      ON s.postcode=o.postcode 
        AND upper(trim(o.business_division))='TECHNOLOGY' --AND upper(trim(o.primary_use))='OFFICE'
), combined_with_ownership_unfiltered AS (
  SELECT DISTINCT s.*, (CASE WHEN c.at_risk IS NOT NULL AND upper(trim(at_risk))='AT RISK' THEN true else false END) as at_risk, c.tenure, c.tenancy_reference, CAST(lease_end AS TIMESTAMP) as lease_end, CAST(lease_start AS TIMESTAMP) as lease_start
    --c.*
  FROM filtered_sites s 
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
)
SELECT  *
FROM combined_with_ownership
