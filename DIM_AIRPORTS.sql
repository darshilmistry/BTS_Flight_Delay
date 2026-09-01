CREATE SCHEMA warehouse;
GO

CREATE TABLE warehouse.dim_airport (
    AirportSeqID    INT PRIMARY KEY,
    CityMarketID    INT NOT NULL,
    IATA            VARCHAR(5), 
    CityName        VARCHAR(50),
    WAC             SMALLINT NOT NULL,
    StateFips       SMALLINT NOT NULL,
    State           VARCHAR(5),
    StateName       VARCHAR(30)
);
GO

INSERT INTO warehouse.dim_airport(
    AirportSeqID, CityMarketID, IATA, CityName, WAC, StateFips, State, StateName)

SELECT DISTINCT 
    CAST(OriginAirportSeqID AS INT) AS OriginAirportSeqID,
    CAST(OriginCityMarketID AS INT) AS OriginCityMarketID,
    CAST(Origin AS VARCHAR(5)) AS Origin,
    CAST(LEFT(OriginCityName, LEN(OriginCityName) - 4) AS VARCHAR(50)) AS OriginCityName,
    CAST(OriginWAC AS SMALLINT) AS OriginWAC,
    CAST(OriginStateFips AS SMALLINT) AS OriginStateFips,
    CAST(OriginState AS VARCHAR(5)) AS OriginState,
    CAST(OriginStateName AS VARCHAR(30)) AS OriginStateName
FROM staging.raw_flights

UNION

SELECT DISTINCT 
    CAST(DestAirportSeqID AS INT) AS DestAirportSeqID,
    CAST(DestCityMarketID AS INT) AS DestCityMarketID,
    CAST(Dest AS VARCHAR(5)) AS Dest,
    CAST(LEFT(DestCityName, LEN(DestCityName) - 4) AS VARCHAR(50)) AS DestCityName,
    CAST(DestWAC AS SMALLINT) AS DestWAC,
    CAST(DestStateFips AS SMALLINT) AS DestStateFips,
    CAST(DestState AS VARCHAR(5)) AS DestState,
    CAST(DestStateName AS VARCHAR(30)) AS DestStateName
FROM staging.raw_flights

;

GO

SELECT TOP 5 * FROM warehouse.dim_airport;


/*
ALTER TABLE warehouse.dim_airport ADD AirportID INT;
GO

UPDATE warehouse.dim_airport
SET AirportID = CAST(LEFT(CAST(AirportSeqID AS VARCHAR(10)), 5) AS INT);

ALTER TABLE warehouse.dim_airport DROP CONSTRAINT PK__dim_airp__929851CC35AF0B26;
GO

ALTER TABLE warehouse.dim_airport ALTER COLUMN AirportID INT NOT NULL;
GO

ALTER TABLE warehouse.dim_airport ADD PRIMARY KEY (AirportID);
GO

SELECT name, type_desc
FROM sys.key_constraints
WHERE parent_object_id = OBJECT_ID('warehouse.dim_airport');

EXEC sp_help 'warehouse.dim_airport';


SELECT AirportID, COUNT(*)
FROM (
    SELECT DISTINCT CAST(OriginAirportID AS INT) AS AirportID, CAST(OriginAirportSeqID AS INT) AS Seq, Origin, OriginCityName
    FROM staging.raw_flights
    UNION
    SELECT DISTINCT CAST(DestAirportID AS INT), CAST(DestAirportSeqID AS INT), Dest, DestCityName
    FROM staging.raw_flights
) x
GROUP BY AirportID
HAVING COUNT(*) > 1;

SELECT DISTINCT Origin, OriginAirportID, Dest, DestAirportID
FROM staging.raw_flights
WHERE OriginAirportID = 10135 OR DestAirportID = 10135
ORDER BY Origin;
*/