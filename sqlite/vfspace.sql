DROP TABLE IF EXISTS vfspace;

CREATE TABLE vfspace AS
	SELECT *, 
	(
		CASE WHEN col1_c1='Total free sections:' 
		THEN round(CAST(regexp_capture(quantity, '^(.*)/(.*)', 1) as double) / cast(regexp_capture(quantity, '^(.*)/(.*)', 2) as double), 2)  
		ELSE NULL
		END
	) AS free_section_percentage 
	FROM space 
;
