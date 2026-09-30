CREATE TABLE warehouse.dim_carrier (
    CarrierID INT PRIMARY KEY,
    IATA CHAR(2) NOT NULL,
    AirlineName VARCHAR(100) NOT NULL,
    MergedInto CHAR(2) NULL,
    ActiveThrough DATE NULL
);

INSERT INTO warehouse.dim_carrier(CarrierID, IATA, AirlineName, MergedInto, ActiveThrough)
VALUES
    (19930, 'AS', 'Alaska Airlines', NULL, NULL),
    (19805, 'AA', 'American Airlines', NULL, NULL),
    (19790, 'DL', 'Delta Air Lines', NULL, NULL),
    (20398, 'MQ', 'Envoy Air', NULL, NULL),
    (19991, 'HP', 'America West Airlines', 'US', '2005-12-31'),
    (20355, 'US', 'US Airways', NULL, NULL),
    (19977, 'UA', 'United Airlines', NULL, NULL),
    (19393, 'WN', 'Southwest Airlines', NULL, NULL),
    (19704, 'CO', 'Continental Airlines', 'UA', '2011-12-31'),
    (19386, 'NW', 'Northwest Airlines', 'DL', '2009-12-31');

ALTER TABLE warehouse.dim_carrier
ADD TailNumbers VARCHAR(MAX) NULL,
    TotalAirframes INT NULL;

WITH DistinctTails AS (
    SELECT DISTINCT CarrierID, TailNumber
    FROM warehouse.fact_flight
),
Aggregated AS (
    SELECT
        CarrierID,
        STRING_AGG(CAST(TailNumber AS VARCHAR(MAX)), ', ') AS TailNumbers,
        COUNT(TailNumber) AS TotalAirframes
    FROM DistinctTails
    GROUP BY CarrierID
)
UPDATE dc
SET dc.TailNumbers = a.TailNumbers,
    dc.TotalAirframes = a.TotalAirframes
FROM warehouse.dim_carrier dc
JOIN Aggregated a ON dc.CarrierID = a.CarrierID;

SELECT * FROM warehouse.dim_carrier;