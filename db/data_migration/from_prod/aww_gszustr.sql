SELECT
	ogc_fid, 
	CASE 
        WHEN ST_IsEmpty(wkb_geometry)
            THEN NULL
        ELSE ST_Multi(wkb_geometry) 
    END AS wkb_geometry,
    "name", 
    im_kanton, 
    typ, 
    archive, 
    archive_date, 
    new_date
FROM
    public.aww_gszustr
WHERE
    archive = 0
;