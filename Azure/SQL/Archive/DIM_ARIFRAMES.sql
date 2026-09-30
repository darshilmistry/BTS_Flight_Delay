CREATE TABLE warehouse.dim_airframes (
    TailNumber              VARCHAR(10)  NOT NULL PRIMARY KEY,
    FirstFlightDate         DATE         NULL,
    LastFlightDate          DATE         NULL,
    TotalFlights            INT          NOT NULL DEFAULT 0,
    TotalBlockMinutes       INT          NOT NULL DEFAULT 0,
    TotalDistance           INT          NOT NULL DEFAULT 0,
    AvgBlockMinutesPerCycle DECIMAL(10,2) NULL,
    AssociatedCarriers      INT
);

GO

INSERT INTO warehouse.dim_airframes (
    TailNumber,
    FirstFlightDate,
    LastFlightDate,
    TotalFlights,
    TotalBlockMinutes,
    TotalDistance,
    AvgBlockMinutesPerCycle,
    AssociatedCarriers
)
SELECT
    TailNumber                                          AS TailNumber,
    MIN(FlightDate)                                     AS FirstFlightDate,
    MAX(FlightDate)                                     AS LastFlightDate,
    COUNT(*)                                            AS TotalFlights,
    SUM(ActualElapsedTime)                              AS TotalBlockMinutes,
    SUM(Distance)                                       AS TotalDistance,
    CAST(SUM(ActualElapsedTime) AS DECIMAL(10,2))
        / NULLIF(COUNT(*), 0)                           AS AvgBlockMinutesPerCycle,
    MIN(CarrierID)                                      AS AssociatedCarriers
FROM warehouse.fact_flight
WHERE TailNumber IS NOT NULL AND TailNumber != 'UNKNOW'
GROUP BY TailNumber;


SELECT TOP 5 * FROM warehouse.dim_airframes;