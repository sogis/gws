SELECT
	ogc_fid, 
	CASE 
        WHEN ST_IsEmpty(wkb_geometry)
            THEN NULL
        ELSE ST_Multi(wkb_geometry) 
    END AS wkb_geometry,
	erf_datum, 
	"zone", 
	erfasser, 
	symbol, 
	new_date, 
	archive_date, 
	archive
FROM
    aww_gsab
WHERE
    archive = 0
;
