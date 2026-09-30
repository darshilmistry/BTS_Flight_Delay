WITH DistinctTails AS (
    SELECT DISTINCT OriginAirportID, TailNumber, CarrierID
    FROM warehouse.fact_flight
)

SELECT
    STRING_AGG(CAST(TailNumber AS VARCHAR(MAX)), ', ') AS TailNumbers,
    COUNT(CAST(TailNumber AS VARCHAR(MAX))) AS TotalAirframes
FROM DistinctTails
GROUP BY CarrierID;

SELECT TOP 5 * FROM warehouse.fact_flight;