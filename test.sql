SELECT
    COUNT(DISTINCT Origin)              AS iata_codes,
    COUNT(DISTINCT OriginAirportID)     AS airport_ids,
    COUNT(DISTINCT OriginAirportSeqID)  AS seq_ids,
    COUNT(DISTINCT OriginCityMarketID)  AS city_markets
FROM staging.raw_flights;

SELECT DISTINCT Origin, OriginAirportID, OriginAirportSeqID, OriginCityMarketID, OriginCityName
FROM staging.raw_flights
WHERE OriginCityName LIKE '%New York%'
ORDER BY Origin;

SELECT DISTINCT 
    CAST(OriginAirportID AS INT) AS OriginAirportID,
    CAST(OriginCityMarketID AS INT) AS OriginCityMarketID,
    CAST(OriginAirportSeqID AS INT) AS OriginAirportSeqID,
    CAST(Origin AS VARCHAR(5)) AS Origin,
    CAST(LEFT(OriginCityName, LEN(OriginCityName) - 4) AS VARCHAR(20)) AS OriginCityName,
    CAST(OriginWAC AS SMALLINT) AS OriginWAC,
    CAST(OriginStateFips AS SMALLINT) AS OriginStateFips,
    CAST(OriginState AS VARCHAR(5)) AS OriginState,
    CAST(OriginStateName AS VARCHAR(30)) AS OriginStateName
FROM staging.raw_flights;


SELECT DISTINCT TOP 5 Origin, OriginState, OriginStateName, OriginStateFips, OriginWAC
FROM staging.raw_flights;

