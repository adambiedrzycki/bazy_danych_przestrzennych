CREATE EXTENSION postgis;

--zad4
CREATE TABLE tableB AS
	SELECT popp.* 
	FROM popp, majrivers 
	WHERE popp.f_codedesc = 'Building' AND  ST_Distance(majrivers.geom, popp.geom) < 1000;

SELECT * FROM tableB;
SELECT COUNT(*) 
FROM tableB; --wynik

--zad5
--tworzenie tabeli wg wymagań
SELECT name, geom, elev
INTO airportsNew 
FROM airports;

SELECT *
FROM airportsNew

--zad5a
SELECT name as maxzachod 
FROM airportsNew
ORDER BY ST_X(geom) DESC
LIMIT 1;

SELECT name as maxwschod
FROM airportsNew
ORDER BY ST_X(geom) 
LIMIT 1;

--zad5b
INSERT INTO airportsNew 
VALUES ('airportB',(SELECT ST_Centroid(ST_ShortestLine((SELECT geom 
					FROM airportsNew WHERE name = 'ANNETTE ISLAND'),
					(SELECT geom FROM airportsNew WHERE name = 'ATKA')))), 200);
SELECT *
FROM airportsNew

--zad6
SELECT ST_Area(ST_Buffer(ST_ShortestLine(lakes.geom, airportsNew.geom), 1000)) AS area
FROM lakes, airportsNew
WHERE lakes.names = 'Iliamna Lake' AND airportsNew.name = 'AMBLER';

--zad7
SELECT SUM(ST_Area(ST_Intersection(trees.geom, swamp.geom)))+ 
        SUM(ST_Area(ST_Intersection(trees.geom, tundra.geom))), trees.vegdesc 
        FROM trees, tundra, swamp GROUP BY trees.vegdesc