--Przykład 1 - ST_Intersects
--Przecięcie rastra z wektorem.

CREATE TABLE schema_biedrzycki.intersects AS
SELECT a.rast, b.municipality
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE ST_Intersects(a.rast, b.geom) AND b.municipality ilike 'porto';

--1. dodanie serial primary key:
alter table schema_biedrzycki.intersects
add column rid SERIAL PRIMARY KEY;
--2. utworzenie indeksu przestrzennego:
CREATE INDEX idx_intersects_rast_gist ON schema_biedrzycki.intersects
USING gist (ST_ConvexHull(rast));
--3. dodanie raster constraints:
-- schema::name table_name::name raster_column::name
SELECT AddRasterConstraints('schema_biedrzycki'::name,
'intersects'::name,'rast'::name);

--Przykład 2 - ST_Clip
--Obcinanie rastra na podstawie wektora.
CREATE TABLE schema_biedrzycki.clip AS
SELECT ST_Clip(a.rast, b.geom, true), b.municipality
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE ST_Intersects(a.rast, b.geom) AND b.municipality like 'PORTO';

--Przykład 3 - ST_Union
--Połączenie wielu kafelków w jeden raster.
CREATE TABLE schema_biedrzycki.union AS
SELECT ST_Union(ST_Clip(a.rast, b.geom, true))
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast);

--    xxxxxxxxxxxx        Tworzenie rastrów z wektorów (rastrowanie)       xxxxxxxxxxxx           --

--Przykład 1 - ST_AsRaster
--Przykład pokazuje użycie funkcji ST_AsRaster w celu rastrowania tabeli z parafiami o takiej
--samej charakterystyce przestrzennej tj.: wielkość piksela, zakresy itp.
CREATE TABLE schema_biedrzycki.porto_parishes AS
WITH r AS (
SELECT rast FROM rasters.dem
LIMIT 1
)
SELECT ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-32767) AS rast
FROM vectors.porto_parishes AS a, r
WHERE a.municipality ilike 'porto';

--Przykład 2 - ST_Union
--Drugi przykład łączy rekordy z poprzedniego przykładu przy użyciu funkcji ST_UNION w pojedynczy raster.
DROP TABLE schema_biedrzycki.porto_parishes; --> drop table porto_parishes first

CREATE TABLE schema_biedrzycki.porto_parishes AS
WITH r AS (
SELECT rast FROM rasters.dem
LIMIT 1
)
SELECT st_union(ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-32767)) AS rast
FROM vectors.porto_parishes AS a, r
WHERE a.municipality ilike 'porto';

--Przykład 3 - ST_Tile
--Po uzyskaniu pojedynczego rastra można generować kafelki za pomocą funkcji ST_Tile
DROP TABLE schema_biedrzycki.porto_parishes; --> drop table porto_parishes first

CREATE TABLE schema_biedrzycki.porto_parishes AS
WITH r AS (
SELECT rast FROM rasters.dem
LIMIT 1 )
SELECT st_tile(st_union(ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-
32767)),128,128,true,-32767) AS rast
FROM vectors.porto_parishes AS a, r
WHERE a.municipality ilike 'porto';

--    xxxxxxxxxxxx        Konwertowanie rastrów na wektory (wektoryzowanie)       xxxxxxxxxxxx           --

--Przykład 1 - ST_Intersection
--a ST_Intersection zwraca zestaw par wartości geometria-piksel, ponieważ ta funkcja przekształca
--raster w wektor przed rzeczywistym „klipem”.

create table schema_biedrzycki.intersection as
SELECT
a.rid,(ST_Intersection(b.geom,a.rast)).geom,(ST_Intersection(b.geom,a.rast)
).val
FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
WHERE b.parish ilike 'paranhos' and ST_Intersects(b.geom,a.rast);

--Przykład 2 - ST_DumpAsPolygons
--ST_DumpAsPolygons konwertuje rastry w wektory (poligony)

CREATE TABLE schema_biedrzycki.dumppolygons AS
SELECT
a.rid,(ST_DumpAsPolygons(ST_Clip(a.rast,b.geom))).geom,(ST_DumpAsPolygons(ST_Clip(a.rast,b.geom))).val
FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
WHERE b.parish ilike 'paranhos' and ST_Intersects(b.geom,a.rast);

--    xxxxxxxxxxxx        Analiza rastrów       xxxxxxxxxxxx           --

--Przykład 1 - ST_Band
--Funkcja ST_Band służy do wyodrębniania pasm z rastra
CREATE TABLE schema_biedrzycki.landsat_nir AS
SELECT rid, ST_Band(rast,4) AS rast
FROM rasters.landsat8;

--Przykład 2 - ST_Clip
--ST_Clip - wycięcie rastra z innego rastra. Poniższy przykład wycina jedną parafię z tabeli vectors.porto_parishes.
CREATE TABLE schema_biedrzycki.paranhos_dem AS
SELECT a.rid,ST_Clip(a.rast, b.geom,true) as rast
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE b.parish ilike 'paranhos' and ST_Intersects(b.geom,a.rast);

--Przykład 3 - ST_Slope
--ST_Slope wygeneruje nachylenie przy użyciupoprzednio wygenerowanej tabeli (wzniesienie).
CREATE TABLE schema_biedrzycki.paranhos_slope AS
SELECT a.rid,ST_Slope(a.rast,1,'32BF','PERCENTAGE') as rast
FROM schema_biedrzycki.paranhos_dem AS a;

--Przykład 4 - ST_Reclass
--ST_Reclass-reklasyfikuje raster
CREATE TABLE schema_biedrzycki.paranhos_slope_reclass AS
SELECT a.rid,ST_Reclass(a.rast,1,']0-15]:1, (15-30]:2, (30-9999:3',
'32BF',0)
FROM schema_biedrzycki.paranhos_slope AS a;

--Przykład 5 - ST_SummaryStats
--ST_SummaryStats - oblicza statystyki rastra.
SELECT st_summarystats(a.rast) AS stats
FROM schema_biedrzycki.paranhos_dem AS a;

--Przykład 6 - ST_SummaryStats oraz Union
--Przy użyciu UNION można wygenerować jedną statystykę wybranego rastra. ST_SummaryStats zwraca złożony typ danych. 
SELECT st_summarystats(ST_Union(a.rast))
FROM schema_biedrzycki.paranhos_dem AS a;

--Przykład 7 - ST_SummaryStats z lepszą kontrolą złożonego typu danych
WITH t AS (
SELECT st_summarystats(ST_Union(a.rast)) AS stats
FROM schema_biedrzycki.paranhos_dem AS a
)
SELECT (stats).min,(stats).max,(stats).mean FROM t;

--Przykład 8 - ST_SummaryStats w połączeniu z GROUP BY
--Aby wyświetlić statystykę dla każdego poligonu "parish" można użyć polecenia GROUP BY
WITH t AS (
SELECT b.parish AS parish, st_summarystats(ST_Union(ST_Clip(a.rast,
b.geom,true))) AS stats
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast)
group by b.parish
)
SELECT parish,(stats).min,(stats).max,(stats).mean FROM t;

--Przykład 9 - ST_Value
--ST_Value pozwala wyodrębnić wartość piksela z punktu lub zestawu punktów.
--Poniższy przykład wyodrębnia punkty znajdujące się w tabeli vectors.places.
--Ponieważ geometria punktów jest wielopunktowa, a funkcja ST_Value wymaga geometrii
--jednopunktowej, należy przekonwertować geometrię wielopunktową na geometrię
--jednopunktową za pomocą funkcji (ST_Dump(b.geom)).geom.
SELECT b.name,st_value(a.rast,(ST_Dump(b.geom)).geom)
FROM
rasters.dem a, vectors.places AS b
WHERE ST_Intersects(a.rast,b.geom)
ORDER BY b.name;

--Przykład 10 - ST_TPI
--ST_Value pozwala na utworzenie mapy TPI z DEM wysokości.
create table schema_biedrzycki.tpi30 as
select ST_TPI(a.rast,1) as rast
from rasters.dem a;
--Poniższa kwerenda utworzy indeks przestrzenny:
CREATE INDEX idx_tpi30_rast_gist ON schema_biedrzycki.tpi30
USING gist (ST_ConvexHull(rast));
--Dodanie constraintów:
SELECT AddRasterConstraints('schema_biedrzycki'::name,
'tpi30'::name,'rast'::name);


--Przykład do samodzielnego wykonania:

CREATE TABLE schema_biedrzycki.tpi30_10 AS
SELECT ST_TPI(a.rast,1) as rast
FROM rasters.dem AS a, vectors.porto_parishes AS b 
WHERE ST_Intersects(a.rast, b.geom) AND b.municipality ILIKE 'porto';

--Poniższa kwerenda utworzy indeks przestrzenny:
CREATE INDEX idx_tpi30_porto_rast_gist 
ON schema_biedrzycki.tpi30_10
USING gist (ST_ConvexHull(rast));

--Dodanie constraintów:
SELECT AddRasterConstraints('schema_biedrzycki'::name, 
'tpi30_10'::name,'rast'::name);

SELECT *FROM schema_biedrzycki.tpi30_10
DROP TABLE schema_biedrzycki.tpi30_10;

--    xxxxxxxxxxxx        Algebra map       xxxxxxxxxxxx           --

--Przykład 1 - Wyrażenie Algebry Map
CREATE TABLE schema_biedrzycki.porto_ndvi AS
WITH r AS (
SELECT a.rid,ST_Clip(a.rast, b.geom,true) AS rast
FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast)
)
SELECT
r.rid,ST_MapAlgebra(
r.rast, 1,
r.rast, 4,
'([rast2.val] - [rast1.val]) / ([rast2.val] +
[rast1.val])::float','32BF'
) AS rast
FROM r;
--indeks przestrzenny
CREATE INDEX idx_porto_ndvi_rast_gist ON schema_biedrzycki.porto_ndvi
USING gist (ST_ConvexHull(rast));
--Dodanie constraintów:
SELECT AddRasterConstraints('schema_biedrzycki'::name,
'porto_ndvi'::name,'rast'::name);

--Przykład 2 – Funkcja zwrotna
create or replace function schema_biedrzycki.ndvi(
value double precision [] [] [],
pos integer [][],
VARIADIC userargs text []
)
RETURNS double precision AS
$$
BEGIN
--RAISE NOTICE 'Pixel Value: %', value [1][1][1];-->For debug purposes
RETURN (value [2][1][1] - value [1][1][1])/(value [2][1][1]+value
[1][1][1]); --> NDVI calculation!
END;
$$
LANGUAGE 'plpgsql' IMMUTABLE COST 1000;
--W kwerendzie algebry map należy można wywołać zdefiniowaną wcześniej funkcję:
CREATE TABLE schema_biedrzycki.porto_ndvi2 AS
WITH r AS (
SELECT a.rid,ST_Clip(a.rast, b.geom,true) AS rast
FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast)
)
SELECT
r.rid,ST_MapAlgebra(
r.rast, ARRAY[1,4],
'schema_biedrzycki.ndvi(double precision[],
integer[],text[])'::regprocedure, --> This is the function!
'32BF'::text
) AS rast
FROM r;
--Dodanie indeksu przestrzennego:
CREATE INDEX idx_porto_ndvi2_rast_gist ON schema_biedrzycki.porto_ndvi2
USING gist (ST_ConvexHull(rast));
--Dodanie constraintów:
SELECT AddRasterConstraints('schema_biedrzycki'::name,
'porto_ndvi2'::name,'rast'::name);

--    xxxxxxxxxxxx        Eksport danych       xxxxxxxxxxxx           --

