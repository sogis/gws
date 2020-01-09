WITH 
rrb_zonen AS ( -- Alle zu einem RRB zugehörigen zonen
	SELECT 
		concat_ws('/', date_part('year', publiziertab), offiziellenr) AS rrb_nr,
		gwszone AS zone_id
	FROM 
		afu_gewaesserschutz.gwszonen_rechtsvorschriftgwszone
	INNER JOIN afu_gewaesserschutz.gwszonen_dokument
		ON gwszonen_rechtsvorschriftgwszone.rechtsvorschrift =  gwszonen_dokument.t_id
	WHERE
        gwszonen_dokument.titel = 'Regierungsratsbeschluss'		
),

rrb_dok_ids AS ( -- Alle dok-ids eines rrb (inklusive rrb)
	SELECT
		rrb_nr,
		rechtsvorschrift AS dok_id
	FROM
		afu_gewaesserschutz.gwszonen_rechtsvorschriftgwszone
	INNER JOIN rrb_zonen 
		ON gwszonen_rechtsvorschriftgwszone.gwszone = rrb_zonen.zone_id
	GROUP BY 
		rrb_nr, 
		dok_id
)

SELECT 
	rrb_nr, 
	titel,
	textimweb,
	offiziellertitel,
	publiziertab,
	offiziellenr, 
	art,
	rechtsstatus
FROM
	afu_gewaesserschutz.gwszonen_dokument
INNER JOIN rrb_dok_ids 
	ON gwszonen_dokument.t_id = rrb_dok_ids.dok_id
ORDER BY 
	rrb_nr,
	titel
	
