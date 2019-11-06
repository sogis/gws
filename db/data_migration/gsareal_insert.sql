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
		rrbnr
	from afu_gszoar
),

gwsareal as
(
	select 
		nextval('afu_gewaesserschutz.t_ili2db_seq') as tid_gwsareal,
		nextval('afu_gewaesserschutz.t_ili2db_seq') as tid_status,
		nextval('afu_gewaesserschutz.t_ili2db_seq') as tid_dokument,
		concat('Altdaten-FID: ', singlepolygon.ogc_fid,'-',partindex) as bemerkungen, 
		'de'::varchar AS bemerkungen_lang,
		typ, 
		ist_altrechtlich, 
		stat_rechtsstatus,
		stat_rechtskraftsdatum,
		rrbnr,
		singlepoly_wkb
	from areal_fields
	inner join singlepolygon on areal_fields.ogc_fid = singlepolygon.ogc_fid
),

insert_status as
(
	insert into afu_gewaesserschutz.astatus(t_id, rechtsstatus, rechtskraftdatum)
	(
		select tid_status, stat_rechtsstatus, stat_rechtskraftsdatum from gwsareal
	)
),

insert_gwsareal AS
(
	insert into afu_gewaesserschutz.gwsareal(t_id, typ, istaltrechtlich, astatus, bemerkungen, bemerkungen_lang, geometrie)
	(
		select
			tid_gwsareal, 
			typ, 
			ist_altrechtlich, 
			tid_status, 
			bemerkungen,
			bemerkungen_lang,
			ST_GeomFromWKB(singlepoly_wkb, 2056) 
		from gwsareal
	)
),

insert_dokument AS 
(
	INSERT INTO afu_gewaesserschutz.dokument(t_id, art, titel, offiziellenr, kanton, publiziertAb, rechtsstatus)(
		SELECT tid_dokument, 'Rechtsvorschrift', 'Regierungsratsbeschluss', rrbnr, 'SO', stat_rechtskraftsdatum, 'inKraft' from gwsareal
	)
)

insert into afu_gewaesserschutz.rechtsvorschriftgwsareal(rechtsvorschrift, gwsareal)
(
	SELECT tid_dokument, tid_gwsareal from gwsareal
)
;



