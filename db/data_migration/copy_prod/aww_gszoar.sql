SELECT
	ogc_fid, 
	CASE 
        WHEN ST_IsEmpty(wkb_geometry)
            THEN NULL
        ELSE ST_Multi(wkb_geometry) 
    END AS wkb_geometry,
	"zone", 
	new_date, 
	archive_date, 
	archive, 
	rrbnr, 
	rrb_date
FROM
    aww_gszoar
WHERE
    archive = 0
;
