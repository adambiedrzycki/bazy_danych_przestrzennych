-- Database: cw1

-- DROP DATABASE IF EXISTS cw1;

CREATE DATABASE cw1
    WITH
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'Polish_Poland.1250'
    LC_CTYPE = 'Polish_Poland.1250'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1
    IS_TEMPLATE = False;
	

CREATE EXTENSION postgis;
CREATE TABLE drogi(id INTEGER, name VARCHAR (30), geom GEOMETRY);
INSERT INTO drogi VALUES (1, 'RoadX', ST_GeomFromText('LINESTRING(0 4.5, 12 4.5)', 0));
INSERT INTO drogi VALUES (2, 'RoadY', ST_GeomFromText('LINESTRING(7.5 10.5, 7.5 0)', 0))

CREATE TABLE budynki(id INTEGER, name VARCHAR (30), geom GEOMETRY, wysokosc INTEGER);
INSERT INTO budynki VALUES (1, 'BuildingA', ST_GeomFromText('POLYGON((8 4, 10.5 4, 10.5 1.5, 8 1.5, 8 4))', 0));
INSERT INTO budynki VALUES (2, 'BuildingB', ST_GeomFromText('POLYGON((4 7, 6 7, 6 5, 4 5, 4 7))', 0));
INSERT INTO budynki VALUES (3, 'BuildingC', ST_GeomFromText('POLYGON((3 8, 5 8, 5 6, 3 6, 3 8))', 0));
INSERT INTO budynki VALUES (4, 'BuildingD', ST_GeomFromText('POLYGON((9 9, 10 9, 10 8, 9 8 , 9 9))', 0));
INSERT INTO budynki VALUES (5, 'BuildingE', ST_GeomFromText('POLYGON((1 2, 2 2, 2 1, 1 1, 1 2))', 0));

CREATE TABLE pktinfo(id INTEGER, geom GEOMETRY, name VARCHAR(30), liczprac INTEGER);
INSERT INTO pktinfo VALUES(1,  ST_GeomFromText('POINT(1 3.5)'), 'G', 2);
INSERT INTO pktinfo VALUES(2,  ST_GeomFromText('POINT(5.5 1.5)'), 'H', 5);
INSERT INTO pktinfo VALUES(3,  ST_GeomFromText('POINT(9.5 6)'), 'I', 3);
INSERT INTO pktinfo VALUES(4,  ST_GeomFromText('POINT(6.5 6)'), 'J', 4);
INSERT INTO pktinfo VALUES(5,  ST_GeomFromText('POINT(6 9.5)'), 'K', 5);

--zad1
SELECT SUM(ST_Length(geom)) FROM drogi;

--zad2
SELECT ST_AsText(geom) AS WKT, ST_Area(geom) AS area, ST_Perimeter(geom) AS perim FROM budynki
WHERE name = 'BuildingB'

--zad3
SELECT name, ST_Area(geom) AS area FROM budynki 
ORDER BY name 

--zad4
SELECT name, ST_Perimeter(geom) AS perim FROM budynki 
ORDER BY ST_Area(geom) DESC LIMIT 2 

--zad5 
SELECT ST_Distance(budynki.geom, pktinfo.geom) FROM (budynki
CROSS JOIN pktinfo) WHERE budynki.name = 'BuildingC' AND pktinfo.name = 'G'

--zad6 
SELECT ST_Area(ST_Difference((SELECT budynki.geom FROM budynki WHERE name = 'BuildingC'), 
                        ST_Buffer((SELECT budynki.geom FROM budynki WHERE name = 'BuildingB'), 0.5)));

--zad7
SELECT budynki.name FROM (budynki
CROSS JOIN drogi) WHERE ST_Y(ST_Centroid(budynki.geom)) > (ST_Y(ST_Centroid(drogi.geom))) AND drogi.name = 'RoadX';
            
--zad8
SELECT ST_Area(ST_SymDifference((SELECT budynki.geom FROM budynki WHERE name = 'BuildingC'), 
                        (SELECT budynki.geom FROM budynki WHERE name = 'BuildingB')))