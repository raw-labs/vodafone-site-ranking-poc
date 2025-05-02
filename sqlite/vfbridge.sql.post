
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
    site_ref AS key_to_be_expanded,
    postcode        AS a,  -- postal code
    bridge_site_type AS b,
    bridge_site_code AS c
FROM (
SELECT
    CASE 
      WHEN site_ref_additional IS NOT NULL
           AND site_ref_additional <> ''
           AND UPPER(TRIM(site_ref_additional)) <> 'N/A'
           AND UPPER(TRIM(site_ref)) NOT LIKE '%MTX'
      THEN UPPER(TRIM(site_ref_additional))
      ELSE UPPER(TRIM(site_ref))
    END AS site_ref,
    UPPER(TRIM(postcode))         AS postcode,
    site_type                     AS bridge_site_type,
    site_code                     AS bridge_site_code,
    site_name                     AS bridge_site_name
  FROM bridge b
) as base
;


----------------------------------------------------------------
-- Statement #3: Drop the final table if it exists
----------------------------------------------------------------
DROP TABLE IF EXISTS vfbridge;


----------------------------------------------------------------
-- Statement #4: Create the final table `sites_pr` with all 
--               your splitting / range expansions, referencing
--               `contracted_temp` (which now has rowid).
----------------------------------------------------------------
CREATE TABLE vfbridge AS

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

bridge_pr_query AS (
  SELECT
    f.a AS postcode,
    f.b AS bridge_site_type,
    f.c AS bridge_site_code,
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

SELECT distinct * FROM bridge_pr_query
;
