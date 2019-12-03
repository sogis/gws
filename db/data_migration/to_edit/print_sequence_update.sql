WITH 
max_tids_in_tables AS (
	SELECT max(t_id) AS max_tid from afu_gewaesserschutz.gwszonen_rechtsvorschriftgwsareal
	UNION ALL
	SELECT max(t_id) AS max_tid from afu_gewaesserschutz.gwszonen_rechtsvorschriftgwszone
	UNION ALL
	SELECT max(t_id) AS max_tid from afu_gewaesserschutz.gwszonen_gwsareal
	UNION ALL
	SELECT max(t_id) AS max_tid from afu_gewaesserschutz.gsbereiche_gsbereich
	UNION ALL
	SELECT max(t_id) AS max_tid from afu_gewaesserschutz.gwszonen_gwszone
	UNION ALL
	SELECT max(t_id) AS max_tid from afu_gewaesserschutz.gwszonen_dokument
	UNION ALL
	SELECT max(t_id) AS max_tid from afu_gewaesserschutz.gwszonen_status
),
next_val AS (
	SELECT (max(max_tid) + 1) AS _next_val FROM max_tids_in_tables
)

SELECT 
	concat_ws(' ', 'set_sequence.sql: MANUELL DIE SEQUENZ SETZEN: [select setval(''afu_gewaesserschutz.t_ili2db_seq'',', _next_val, ');]') AS msg 
FROM next_val
;

