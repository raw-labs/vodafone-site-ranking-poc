
----------------------------------------------------------------
-- Statement #1: Drop the temp table if it exists
----------------------------------------------------------------
DROP TABLE IF EXISTS contracted_temp;

----------------------------------------------------------------
-- Statement #2: Create the temp table from your `sites_pr_raw`
--               using a WITH CTE, then "CREATE TEMP TABLE ... AS"
----------------------------------------------------------------
CREATE TEMP TABLE contracted_temp AS
SELECT
    site_code AS key_to_be_expanded,
    pc        AS a,  -- postal code
    site_code AS b,
    site_name AS c
FROM (
SELECT
        UPPER(TRIM(site_code)) AS site_code,
        regexp_capture(
          regexp_replace(address, '[\r\n]+', ' '),
          '([A-Za-z0-9]{2,5}\s*[A-Za-z0-9]{2,4})(?:[\s,]+UK)?[\s.,]*$',
          1
        ) AS pc,
        site_code,
        site_name
    FROM sites
) as base
;


----------------------------------------------------------------
-- Statement #3: Drop the final table if it exists
----------------------------------------------------------------
DROP TABLE IF EXISTS vfsites;


----------------------------------------------------------------
-- Statement #4: Create the final table `sites_pr` with all 
--               your splitting / range expansions, referencing
--               `contracted_temp` (which now has rowid).
----------------------------------------------------------------
CREATE TABLE vfsites AS

WITH
delimiters_unified AS (
  SELECT
    rowid AS cid,
    regexp_replace(key_to_be_expanded, '\s*[,&/]+\s*', ';') AS expanded,
    a,
    b,
    c
  FROM contracted_temp
),

splitted AS (
  WITH RECURSIVE split_init AS (
    SELECT
      cid,
      a,
      b,
      c,
      1 AS piece_index,
      CASE
        WHEN instr(expanded, ';') > 0
          THEN substr(expanded, 1, instr(expanded, ';') - 1)
        ELSE expanded
      END AS piece,
      CASE
        WHEN instr(expanded, ';') > 0
          THEN substr(expanded, instr(expanded, ';') + 1)
        ELSE ''
      END AS remainder
    FROM delimiters_unified
  ),
  split_recursive AS (
    SELECT
      cid,
      a,
      b,
      c,
      piece_index,
      piece,
      remainder
    FROM split_init

    UNION ALL

    SELECT
      cid,
      a,
      b,
      c,
      piece_index + 1,
      CASE
        WHEN instr(remainder, ';') > 0
          THEN substr(remainder, 1, instr(remainder, ';') - 1)
        ELSE remainder
      END,
      CASE
        WHEN instr(remainder, ';') > 0
          THEN substr(remainder, instr(remainder, ';') + 1)
        ELSE ''
      END
    FROM split_recursive
    WHERE remainder <> ''
  )
  SELECT *
  FROM split_recursive
),

range_split AS (
  SELECT
    sp.cid,
    sp.a,
    sp.b,
    sp.c,
    sp.piece_index,
    sp.piece,
    regexp_capture(sp.piece, '^(.*?)(\d+)\s*[-/]\s*(\d+)$', 1) AS r_prefix,
    regexp_capture(sp.piece, '^(.*?)(\d+)\s*[-/]\s*(\d+)$', 2) AS r_start,
    regexp_capture(sp.piece, '^(.*?)(\d+)\s*[-/]\s*(\d+)$', 3) AS r_end
  FROM splitted sp

  UNION ALL

  SELECT
    sp.cid,
    sp.a,
    sp.b,
    sp.c,
    sp.piece_index,
    sp.piece,
    NULL,
    NULL,
    NULL
  FROM splitted sp
  WHERE NOT (sp.piece REGEXP '^(.*?)(\d+)\s*[-/]\s*(\d+)$')
),

expanded_ranges AS (
  WITH RECURSIVE all_nums(n) AS (
    SELECT 1
    UNION ALL
    SELECT n + 1 FROM all_nums
    WHERE n < 50
  )
  SELECT
    rs.cid,
    rs.a,
    rs.b,
    rs.c,
    rs.piece_index,
    rs.r_prefix,
    rs.r_start,
    rs.r_end,
    all_nums.n AS range_num
  FROM range_split rs
  JOIN all_nums
  ON all_nums.n BETWEEN CAST(rs.r_start AS INT) 
                   AND CAST(rs.r_end AS INT)
  WHERE rs.r_prefix IS NOT NULL
),

non_ranges AS (
  SELECT
    rs.cid,
    rs.a,
    rs.b,
    rs.c,
    rs.piece_index,
    rs.piece AS expanded_piece
  FROM range_split rs
  WHERE rs.r_prefix IS NULL
),

combined AS (
  SELECT
    cid,
    a,
    b,
    c,
    piece_index,
    r_prefix || printf('%0*d', LENGTH(r_start), range_num) AS expanded_piece
  FROM expanded_ranges

  UNION ALL

  SELECT
    cid,
    a,
    b,
    c,
    piece_index,
    expanded_piece
  FROM non_ranges
),

extracted AS (
  SELECT
    cb.cid,
    cb.a,
    cb.b,
    cb.c,
    cb.piece_index,
    cb.expanded_piece,
    regexp_capture(cb.expanded_piece, '^([^0-9]+)(\d+)$', 1) AS prefix_found,
    regexp_capture(cb.expanded_piece, '^([^0-9]+)(\d+)$', 2) AS digits_found
  FROM combined cb
),

filled AS (
  SELECT
    e.cid,
    e.a,
    e.b,
    e.c,
    e.piece_index,
    e.expanded_piece,
    e.prefix_found,
    e.digits_found,
    (
      SELECT x2.prefix_found
      FROM extracted x2
      WHERE x2.cid = e.cid
        AND x2.piece_index <= e.piece_index
        AND x2.prefix_found IS NOT NULL
      ORDER BY x2.piece_index DESC
      LIMIT 1
    ) AS active_prefix,
    (
      SELECT LENGTH(x2.digits_found)
      FROM extracted x2
      WHERE x2.cid = e.cid
        AND x2.piece_index <= e.piece_index
        AND x2.prefix_found IS NOT NULL
      ORDER BY x2.piece_index DESC
      LIMIT 1
    ) AS active_digit_len
  FROM extracted e
),

sites_pr_query AS (
  SELECT
    f.a AS pc,
    f.b AS original_site_code,
    f.c AS site_name,
    CASE
      WHEN f.prefix_found IS NOT NULL AND f.prefix_found != '' THEN
        f.prefix_found
        || printf('%0*d', LENGTH(f.digits_found), CAST(f.digits_found AS INT))

      WHEN (f.expanded_piece REGEXP '^[0-9]+$') = 1
           AND f.active_prefix IS NOT NULL
      THEN
        f.active_prefix
        || printf('%0*d', f.active_digit_len, CAST(f.expanded_piece AS INT))

      ELSE
        f.expanded_piece
    END AS site_code
  FROM filled f
  ORDER BY f.a, f.b, site_code
)

SELECT distinct sites_pr_query.site_code, sites.site_name, sites.site_type, replace(replace(replace(sites.site_category, ']', ''), '[', ''), '"', '') AS site_category, 
		sites.region, sites.status, sites.address, sites_pr_query.pc as postcode,
		sites.gis_migrated, sites.floorplans, sites.location, sites.comments, sites.restricted, sites.freehold_leasehold, sites.power_resilience
FROM sites INNER JOIN sites_pr_query ON UPPER(sites.site_code)=UPPER(sites_pr_query.original_site_code)

--SELECT * 
-- FROM sites_pr_query
-- FROM expanded_ranges
-- FROM range_split
--FROM filled
;
