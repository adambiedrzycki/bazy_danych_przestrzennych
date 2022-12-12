CREATE EXTENSION postgis_raster;

SELECT * FROM public.uk_250k;

-- zad3
CREATE TABLE rasters_combined AS
SELECT lo_from_bytea(0, ST_AsGDALRaster(ST_Union(rast), 'GTiff', ARRAY['COMPRESS=DEFLATE', 'PREDICTOR=2', 'PZLEVEL=9'])) AS loid
FROM public.uk_250k;
--
SELECT lo_export(loid, 'uk_250k.tiff') --> Save the file in a place
--where the user postgres have access. In windows a flash drive usualy works
--fine.
FROM rasters_combined;

-- zad5
-- załadowanie poprzez postgis bundle
SELECT * FROM public.main_national_parks;

-- zad6
CREATE TABLE uk_lake_district AS
SELECT ST_Clip(a.rast, b.geom, true)
FROM uk_250k AS a, main_national_parks AS b
WHERE ST_Intersects(a.rast, b.geom) AND b.gid = 1; --gid=1 to nasz porządany obszar


SELECT * FROM uk_lake_district;
--DROP TABLE uk_lake_district;

--zad7
CREATE TABLE tmp_out AS
SELECT lo_from_bytea(0,
       ST_AsGDALRaster(ST_Union(st_clip), 'GTiff',  ARRAY['COMPRESS=DEFLATE', 'PREDICTOR=2', 'PZLEVEL=9'])
        ) AS loid
FROM uk_lake_district;

-- Zapisywanie pliku
SELECT lo_export(loid, 'D:/format/studia/semestr 5/bazyDanychPrzestrzennych/7/uk_lake_district.tif')

FROM tmp_out;

-- Usuwanie obiektu
SELECT lo_unlink(loid)
FROM tmp_out;

DROP TABLE tmp_out;

--zad9
SELECT * FROM sentinel2;

--zad10
CREATE TABLE sentinel2_clip AS
SELECT ST_Clip(a.rast, b.geom, true)
FROM sentinel2 AS a, main_national_parks AS b
WHERE ST_Intersects(a.rast, b.geom) AND b.gid = 1; --gid=1 to nasz porządany obszar

CREATE TABLE NDWI AS
WITH r AS (
	SELECT r.rid, r.rast AS rast
	FROM sentinel2_clip AS r
)
SELECT
	r.rid, ST_MapAlgebra(
		r.rast, 1,
		r.rast, 4,
		'([rast2.val] - [rast1.val]) / ([rast2.val] + [rast1.val])::float','32BF'
	) AS rast
FROM r;

--zad11
CREATE TABLE tmp_outNDWI AS
SELECT lo_from_bytea(0, ST_AsGDALRaster(ST_Union(rast), 'GTiff',  ARRAY['COMPRESS=DEFLATE', 'PREDICTOR=2', 'PZLEVEL=9'])) AS loid
FROM NDWI;

-- Zapisywanie pliku na dysku 

SELECT lo_export(loid, 'D:/format/studia/semestr 5/bazyDanychPrzestrzennych/7/NDWI.tif') FROM tmp_outNDWI;

