-- Skript welches die Gewaesserschutzzonen vom Solothurner Schema ins MGDM-Schema umbaut (ili2pg). Dokumente (Oereb) sind im Skript nicht beruecksichtigt
--
-- afu_gszoar selektiert die zutreffenden Zeilen und Spalten für den Umbau ins MGDM
-- singlepolygon löst so vorhanden multipolygone auf. partindex 0 --> war schon singlepolygon. partindex 1-x index des parts innerhalb multipolygon
-- zone_fields baut die Attribute um auf die vom MGDM verlangten Werte
-- gwszone umfasst die notwendigen Informationen für die Befuellung der Klassen GWSAreal und des jeweiligen zugeordneten Status
-- insert_status fuellt die Informationen in die Tabelle "status"
-- insert_gwszone fuellt die Informationen in die Tabelle "gwszone"
with 
afu_gszoar as
(
	SELECT 
		aww_gszoar.ogc_fid, 
	 	aww_gszoar."zone",
	 	concat_ws('-', date_part('year', rrb_date), rrbnr) AS rrb_id,
	 	aww_gszoar.rrbnr, 
	    aww_gszoar.rrb_date, 
	    aww_gszoar.wkb_geometry
	FROM aww_gszoar
	WHERE aww_gszoar.archive = 0 
	and "zone" != 'SARE'
	--AND st_isvalid(wkb_geometry)
),
singlepolygon as 
(
	select
		ogc_fid,
		coalesce((((dump).path)[1]),0) as partindex,
		ST_AsBinary((dump).geom) as geo_wkb
	from 
	(
		select ST_DUMP(wkb_geometry) as dump, ogc_fid 
		from afu_gszoar
	) as dump
),
zone_fields as -- gwszone felder gemappt aus aww_gszoar
(
	select 
		ogc_fid, 
		case
			when trim("zone") = 'GZ1' then 'S1'
			when trim("zone") = 'GZ2' then 'S2'
			when trim("zone") = 'GZ2B' then 'S2'
			when trim("zone") = 'GZ3' then 'S3'
			else 'Umbauproblem: Nicht behandelte Codierung von Attibut [zone]'
		end as typ,
		CASE 
			WHEN rrb_date < '01.01.2001' 
				THEN TRUE
			ELSE FALSE
		END AS ist_altrechtlich, 
		'inKraft' as stat_rechtsstatus,
		rrb_date as stat_rechtskraftsdatum,
		rrb_id
	from afu_gszoar
),
gwszone as
(
	select 
		nextval('afu_gewaesserschutz.t_ili2db_seq') as tid_gwszone,
		concat('Altdaten-FID: ',singlepolygon.ogc_fid,'-',partindex) as altdaten_id, 
		typ,
		ist_altrechtlich,
		stat_rechtsstatus,
		stat_rechtskraftsdatum,
		rrb_id,
		geo_wkb as singlepoly_wkb
	from zone_fields
	inner join singlepolygon on zone_fields.ogc_fid = singlepolygon.ogc_fid
),
rrb_dat_tupel AS 
(
	SELECT 
		max(rrb_date) AS rrb_date,
		rrb_id,
		rrbnr
	FROM
		afu_gszoar
	GROUP BY 
		rrb_id, rrbnr
),
status AS
(
	SELECT 
		nextval('afu_gewaesserschutz.t_ili2db_seq') as tid_status,
		'inKraft' AS rechtsstatus, 
		rrb_date AS rechtskraftdatum,
		rrb_id
	FROM
		rrb_dat_tupel
),
dokument AS 
(
	SELECT 
		nextval('afu_gewaesserschutz.t_ili2db_seq') as tid_dok,
		'Rechtsvorschrift' AS art,
		'Regierungsratsbeschluss' AS typ,
		rrb_date,
		rrb_id,
		rrbnr AS nr
	FROM
		rrb_dat_tupel
	UNION ALL
		SELECT 
		nextval('afu_gewaesserschutz.t_ili2db_seq') as tid_dok,
		'Rechtsvorschrift' AS art,
		'Schutzzonenreglement' AS typ,
		rrb_date,
		rrb_id,
		NULL AS nr
	FROM
		rrb_dat_tupel
	UNION ALL
		SELECT 
		nextval('afu_gewaesserschutz.t_ili2db_seq') as tid_dok,
		'Hinweis' AS art,
		'Schutzzonenplan' AS typ,
		rrb_date,
		rrb_id,
		NULL AS nr
	FROM
		rrb_dat_tupel
),
insert_status AS
(
	insert into afu_gewaesserschutz.astatus(t_id, rechtsstatus, rechtskraftdatum)
	(
		select tid_status, rechtsstatus, rechtskraftdatum from status
	)
	RETURNING *
),
insert_gwszone AS
(
	insert into afu_gewaesserschutz.gwszone(t_id, typ, istaltrechtlich, astatus, bemerkungen, bemerkungen_lang, geometrie)
	(
		select 
			tid_gwszone, typ, ist_altrechtlich, tid_status, altdaten_id, 'de', ST_GeomFromWKB(singlepoly_wkb, 2056) 
		from 
			gwszone
		INNER JOIN status ON
			gwszone.rrb_id = status.rrb_id
	)
	RETURNING *
),
insert_dokument AS 
(
	INSERT INTO afu_gewaesserschutz.dokument(t_id, art, titel, offiziellenr, kanton, publiziertAb, rechtsstatus, textimweb)(
		SELECT tid_dok, art, typ, nr, 'SO', rrb_date, 'inKraft', NULL FROM dokument
	)
	RETURNING *
),
insert_link AS 
(
	insert into afu_gewaesserschutz.rechtsvorschriftgwszone(rechtsvorschrift, gwszone)
	(
		SELECT 
			tid_dok,
			tid_gwszone
		FROM 
			dokument
		INNER JOIN gwszone ON
			dokument.rrb_id = gwszone.rrb_id
	)
	RETURNING *
)

SELECT concat_ws(' ', 'gszone_insert.sql:', count(*), 'Zeilen in [astatus] eingefuegt.') AS msg FROM insert_status
UNION ALL
SELECT concat_ws(' ', 'gszone_insert.sql:', count(*), 'Zeilen in [gszone] eingefuegt.') AS msg FROM insert_gwszone
UNION ALL
SELECT concat_ws(' ', 'gszone_insert.sql:', count(*), 'Zeilen in [dokument] eingefuegt.') AS msg FROM insert_dokument
UNION ALL
SELECT concat_ws(' ', 'gszone_insert.sql:', count(*), 'Zeilen in [rechtsvorschriftgwszone] eingefuegt.') AS msg FROM insert_link
;