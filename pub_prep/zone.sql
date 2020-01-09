
CREATE OR REPLACE VIEW afu_gewaesserschutz.gwszonen_gwszone_temp_v AS 

WITH 

docs_gesamttitel AS (
	SELECT
		t_id AS dok_id,
		CASE titel
			WHEN 'Regierungsratsbeschluss' THEN concat('RRB ', date_part('year', publiziertab), '/', offiziellenr, ': ',  offiziellertitel)
			WHEN 'Schutzzonenreglement' THEN concat('Reglement: ', offiziellertitel)
			WHEN 'Schutzzonenplan' THEN concat('Plan: ', offiziellertitel)
			ELSE offiziellertitel
		END AS titel,
		CASE titel
			WHEN 'Regierungsratsbeschluss' THEN 1
			WHEN 'Schutzzonenreglement' THEN 2
			WHEN 'Schutzzonenplan' THEN 3
			ELSE 4
		END AS sort,
		textimweb AS url
	FROM 
		afu_gewaesserschutz.gwszonen_dokument
),

docs_json AS (
	SELECT
		dok_id,
		sort,
		json_build_object('titel', titel,'url', url) AS json_rec
	FROM
		docs_gesamttitel
),

zone_docs AS (
	SELECT 
		gwszone AS zone_id,
		array_to_json(array_agg(json_rec ORDER BY sort))::TEXT AS dokumente
	FROM
		docs_json
	JOIN afu_gewaesserschutz.gwszonen_rechtsvorschriftgwszone
		ON docs_json.dok_id = gwszonen_rechtsvorschriftgwszone.rechtsvorschrift
	GROUP BY 
		gwszone
),

zone_and_status AS (
	SELECT 
		gwszonen_gwszone.t_id, 
		COALESCE(typ, kantonaletypbezeichnung) AS typ,
		istaltrechtlich,
		CASE istaltrechtlich
			WHEN false THEN 'neurechtlich'
			ELSE 'altrechtlich, nicht gesetzeskonform'
		END AS istaltrechtlich_text, 
		rechtskraftdatum,
		geometrie
	FROM afu_gewaesserschutz.gwszonen_gwszone
		INNER JOIN afu_gewaesserschutz.gwszonen_status
			ON gwszonen_gwszone.astatus = gwszonen_status.t_id
)

SELECT
	t_id, 
	typ,
	istaltrechtlich,
	istaltrechtlich_text,
	rechtskraftdatum,
	dokumente,
	geometrie
FROM
	zone_and_status
		INNER JOIN zone_docs
			ON zone_and_status.t_id = zone_docs.zone_id

/*
Todos:
- nicht rechtskräftiges herausfiltern
*/