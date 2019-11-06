-- Drop table

-- DROP TABLE public.aww_gszoar;

CREATE TABLE IF NOT EXISTS public.aww_gszoar (
	ogc_fid serial NOT NULL,
	wkb_geometry geometry(MULTIPOLYGON, 2056) NULL,
	"zone" varchar NULL,
	new_date date NULL DEFAULT 'now'::text::date,
	archive_date date NULL DEFAULT '9999-01-01'::date,
	archive int2 NULL DEFAULT 0,
	rrbnr int4 NULL,
	rrb_date date NULL,
	CONSTRAINT aww_gszoar_pkey PRIMARY KEY (ogc_fid)
)
WITH (
	OIDS=TRUE
);
CREATE INDEX IF NOT EXISTS aww_gszoar_idx ON aww_gszoar USING gist (wkb_geometry);
CREATE INDEX IF NOT EXISTS aww_gszoar_oid_idx ON aww_gszoar USING btree (oid);

-- Drop table

-- DROP TABLE public.aww_gszustr;

CREATE TABLE IF NOT EXISTS public.aww_gszustr (
	ogc_fid serial NOT NULL,
	wkb_geometry geometry(MULTIPOLYGON, 2056) NULL,
	"name" varchar NULL,
	im_kanton float8 NULL,
	typ varchar NULL,
	archive int2 NULL DEFAULT 0,
	archive_date date NULL DEFAULT '9999-01-01'::date,
	new_date date NULL DEFAULT 'now'::text::date,
	CONSTRAINT aww_gszustr_pkey PRIMARY KEY (ogc_fid)
)
WITH (
	OIDS=TRUE
);
CREATE INDEX IF NOT EXISTS aww_gszustr_idx ON aww_gszustr USING gist (wkb_geometry);
CREATE UNIQUE INDEX IF NOT EXISTS aww_gszustr_ogc_fid_key ON aww_gszustr USING btree (ogc_fid);
CREATE INDEX IF NOT EXISTS aww_gszustr_oid_idx ON aww_gszustr USING btree (oid);


-- Drop table

-- DROP TABLE public.aww_gsab;

CREATE TABLE IF NOT EXISTS public.aww_gsab (
	ogc_fid serial NOT NULL,
	wkb_geometry geometry(MULTIPOLYGON, 2056) NULL,
	erf_datum int4 NULL,
	"zone" varchar NULL,
	erfasser varchar NULL,
	symbol int4 NULL,
	new_date date NULL DEFAULT 'now'::text::date,
	archive_date date NULL DEFAULT '9999-01-01'::date,
	archive int2 NULL DEFAULT 0,
	CONSTRAINT aww_gsab_pkey PRIMARY KEY (ogc_fid)
)
WITH (
	OIDS=TRUE
);
CREATE INDEX IF NOT EXISTS aww_gsab_idx ON aww_gsab USING gist (wkb_geometry);
CREATE UNIQUE INDEX IF NOT EXISTS aww_gsab_ogc_fid_key ON aww_gsab USING btree (ogc_fid);
CREATE INDEX IF NOT EXISTS aww_gsab_oid_idx ON aww_gsab USING btree (oid);


