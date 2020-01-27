CREATE OR REPLACE VIEW afu_gewaesserschutz_pub.gewaesserschutz_zone_areal_v AS
SELECT 
	t_id, 
	typ, 
	gesetzeskonform, 
	rechtskraftdatum, 
	dokumente::text, 
	apolygon
FROM 
	afu_gewaesserschutz_pub.gewaesserschutz_zone_areal;
