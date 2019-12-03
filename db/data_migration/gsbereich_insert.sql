WITH gszustr as
(
	SELECT aww_gszustr.ogc_fid, aww_gszustr.wkb_geometry, aww_gszustr.typ, aww_gszustr.name
	FROM aww_gszustr 
	where archive = 0 
	AND im_kanton = 1
	--AND st_isvalid(wkb_geometry)
),
singlepoly_gszu as
(
	select
		ogc_fid,
		coalesce((((dump).path)[1]),0) as partindex,
		ST_AsBinary((dump).geom) as singlepoly_wkb
	from
	(
		select ST_DUMP(wkb_geometry) as dump, ogc_fid
		from gszustr
	) as dump
),
fields_gszustr as -- gwsbereich felder gemappt aus aww_gszoar
(
	select
		ogc_fid,
		case
			when trim(typ) = 'Zo' then 'Zo'
			when trim(typ) = 'Zu' then 'Zu'
			else 'Umbauproblem: Nicht behandelte Codierung von Attibut [typ]'
		end as typ,
		'gszustr'::varchar AS source_table
	from gszustr
),
gsab as
(
	SELECT aww_gsab.ogc_fid, aww_gsab.wkb_geometry, aww_gsab."zone", aww_gsab.erfasser
	FROM aww_gsab where archive = 0
),
singlepoly_gsab as
(
	select
		ogc_fid,
		coalesce((((dump).path)[1]),0) as partindex,
		ST_AsBinary((dump).geom) as singlepoly_wkb
	from
	(
		select ST_DUMP(wkb_geometry) as dump, ogc_fid
		from gsab
	) as dump
),
fields_gsab as -- gwsbereich felder gemappt aus aww_gszoar
(
	select
		ogc_fid,
		case
			when trim("zone") = 'B' then 'UB'
			when trim("zone") = 'O' then 'Ao'
			when trim("zone") = 'U' then 'Au'
			else 'Umbauproblem: Nicht behandelte Codierung von Attibut [zone]'
		end as typ,
		'gsab'::varchar AS source_table
	from gsab
),
unionall as
(
	select fields_gszustr.ogc_fid, typ, partindex, source_table, singlepoly_wkb
	from fields_gszustr
	inner join singlepoly_gszu on fields_gszustr.ogc_fid = singlepoly_gszu.ogc_fid
	union all
	select fields_gsab.ogc_fid, typ, partindex, source_table, singlepoly_wkb
	from fields_gsab
	inner join singlepoly_gsab on fields_gsab.ogc_fid = singlepoly_gsab.ogc_fid
),
gwsbereich as
(
	select
		nextval('afu_gewaesserschutz.t_ili2db_seq') as tid,
		concat('Altdaten-FID (', source_table, '): ', ogc_fid, '-',partindex) as bemerkungen,
		'de'::varchar AS bemerkungen_lang,
		typ,
		singlepoly_wkb
	from unionall
),
gsbereich_insert AS
(
	INSERT INTO afu_gewaesserschutz.gsbereiche_gsbereich(t_id, typ, bemerkungen, bemerkungen_lang, geometrie)
	(
	        SELECT
	                tid,
	                typ,
	                bemerkungen,
	                bemerkungen_lang,
	                ST_GeomFromWKB(singlepoly_wkb, 2056)
	        FROM gwsbereich
	        
	)
	RETURNING *
)

SELECT concat_ws(' ', 'gsbereich_insert.sql:', count(*), 'Zeilen in [gsbereich] eingefuegt.') AS msg FROM gsbereich_insert
;
