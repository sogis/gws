WITH 
 
doccount_per_zone AS (
 	SELECT
 		gwszone,	
 		count(*) AS doc_count,
 		count(DISTINCT gwszonen_dokument.offiziellertitel) AS title_count,
 		count(DISTINCT gwszonen_dokument.textimweb) AS url_count
 	FROM
 		afu_gewaesserschutz.gwszonen_dokument
 		INNER JOIN afu_gewaesserschutz.gwszonen_rechtsvorschriftgwszone
 			ON gwszonen_dokument.t_id = gwszonen_rechtsvorschriftgwszone.rechtsvorschrift
 	WHERE 
 		gwszonen_dokument.art != 'Hinweis'
 	GROUP BY 
 		gwszone
),

doccount_per_areal AS (
 	SELECT
 		gwsareal,	
 		count(*) AS doc_count,
 		count(DISTINCT gwszonen_dokument.offiziellertitel) AS title_count,
 		count(DISTINCT gwszonen_dokument.textimweb) AS url_count
 	FROM
 		afu_gewaesserschutz.gwszonen_dokument
 		INNER JOIN afu_gewaesserschutz.gwszonen_rechtsvorschriftgwsareal
 			ON gwszonen_dokument.t_id = gwszonen_rechtsvorschriftgwsareal.rechtsvorschrift
 	WHERE 
 		gwszonen_dokument.art != 'Hinweis'
 	GROUP BY 
 		gwsareal
),

zones_not_done AS (
	 SELECT
	 	t_id,
	 	doc_count,
	 	title_count,
	 	url_count,
	 	geometrie
	 FROM 
	 	afu_gewaesserschutz.gwszonen_gwszone
	 	INNER JOIN doccount_per_zone
	 		ON gwszonen_gwszone.t_id = doccount_per_zone.gwszone
	 WHERE 
	 	doc_count != title_count
	 OR 
	 	doc_count != url_count
),

areal_not_done AS (
	 SELECT
	 	t_id,
	 	doc_count,
	 	title_count,
	 	url_count,
	 	geometrie
	 FROM 
	 	afu_gewaesserschutz.gwszonen_gwsareal
	 	INNER JOIN doccount_per_areal
	 		ON gwszonen_gwsareal.t_id = doccount_per_areal.gwsareal
	 WHERE 
	 	doc_count != title_count
	 OR 
	 	doc_count != url_count
),

not_done_union AS (
	SELECT 'zone' AS typ, t_id, geometrie FROM zones_not_done
	UNION ALL 
	SELECT 'areal' AS typ, t_id, geometrie FROM areal_not_done
),

not_done_gemeinden AS (	
	SELECT
		hoheitsgrenzen_gemeindegrenze.t_id
	FROM 
		agi_hoheitsgrenzen_pub.hoheitsgrenzen_gemeindegrenze
		JOIN not_done_union 
			ON ST_Intersects(hoheitsgrenzen_gemeindegrenze.geometrie, not_done_union.geometrie)
	GROUP BY 
		hoheitsgrenzen_gemeindegrenze.t_id
)

SELECT 
	hoheitsgrenzen_gemeindegrenze.t_id, 
	gemeindename, 
	(not_done_gemeinden.t_id IS NULL) AS done,
	now() AS aktualisiert_um,
	bfs_gemeindenummer,
	geometrie
FROM agi_hoheitsgrenzen_pub.hoheitsgrenzen_gemeindegrenze
	LEFT JOIN not_done_gemeinden
		ON hoheitsgrenzen_gemeindegrenze.t_id = not_done_gemeinden.t_id
; 