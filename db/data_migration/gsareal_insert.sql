-- Skript welches die Gewaesserschutzareale vom Solothurner Schema ins MGDM-Schema umbaut (ili2pg). Dokumente (Oereb) sind im Skript nicht beruecksichtigt
--
-- afu_gszoar selektiert die zutreffenden Zeilen und Spalten für den Umbau ins MGDM
-- singlepolygon löst so vorhanden multipolygone auf. partindex 0 --> war schon singlepolygon. partindex 1-x index des parts innerhalb multipolygon
-- gwsareal umfasst die notwendigen Informationen für die Befuellung der Klassen GWSAreal und des jeweiligen zugeordneten Status
-- insert_status fuellt die Informationen in die Tabelle "status"
-- insert_gwsareal fuellt die Informationen in die Tabelle "gwsareal"
with
afu_gszoar as
(
	 SELECT aww_gszoar.ogc_fid, aww_gszoar."zone", aww_gszoar.rrbnr, 
	 concat_ws('-', date_part('year', rrb_date), rrbnr) AS rrb_id,
	    aww_gszoar.rrb_date, aww_gszoar.wkb_geometry
	   FROM aww_gszoar
	  WHERE aww_gszoar.archive = 0 and "zone" = 'SARE'
),

singlepolygon as 
(
	select
		ogc_fid,
		coalesce((((dump).path)[1]),0) as partindex,
		ST_AsBinary((dump).geom) as singlepoly_wkb
	from 
	(
		select ST_DUMP(wkb_geometry) as dump, ogc_fid from 
		afu_gszoar
	) as dump
),

areal_fields as -- gwsareal felder gemappt aus aww_gszoar
(
	select 
	    ogc_fid,
		'Areal' as typ, 
		false as ist_altrechtlich, 
		'inKraft' as stat_rechtsstatus,
		rrb_date as stat_rechtskraftsdatum,
		rrbnr,
		rrb_id
	from afu_gszoar
),

gwsareal as
(
	select 
		nextval('afu_gewaesserschutz.t_ili2db_seq') as tid_areal,
		concat('Altdaten-FID: ', singlepolygon.ogc_fid,'-',partindex) as altdaten_id, 
		typ, 
		ist_altrechtlich, 
		stat_rechtsstatus,
		stat_rechtskraftsdatum,
		rrb_id,
		singlepoly_wkb
	from areal_fields
	inner join singlepolygon on areal_fields.ogc_fid = singlepolygon.ogc_fid
),

rrb_dat_tupel AS 
(
	SELECT 
		max(rrb_date) AS rrb_date,
		rrbnr,
		rrb_id
	FROM
		afu_gszoar
	GROUP BY 
		rrbnr, rrb_id
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
),

insert_gwsareal AS
(
	insert into afu_gewaesserschutz.gwsareal(t_id, typ, istaltrechtlich, astatus, bemerkungen, bemerkungen_lang, geometrie)
	(
		select 
			tid_areal, typ, ist_altrechtlich, tid_status, altdaten_id, 'de', ST_GeomFromWKB(singlepoly_wkb, 2056) 
		from 
			gwsareal
		INNER JOIN status ON
			gwsareal.rrb_id = status.rrb_id
	)
),

insert_dokument AS 
(
	INSERT INTO afu_gewaesserschutz.dokument(t_id, art, titel, offiziellenr, kanton, publiziertAb, rechtsstatus)(
		SELECT tid_dok, art, typ, nr, 'SO', rrb_date, 'inKraft' FROM dokument
	)
),

insert_link AS 
(
	insert into afu_gewaesserschutz.rechtsvorschriftgwsareal(rechtsvorschrift, gwsareal)
	(
		SELECT 
			tid_dok,
			tid_areal
		FROM 
			dokument
		INNER JOIN gwsareal ON
			dokument.rrb_id = gwsareal.rrb_id
	)
)

SELECT * FROM rrb_dat_tupel
;