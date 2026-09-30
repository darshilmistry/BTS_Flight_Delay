WITH TailSequence AS (
    SELECT
        TailNumber,
        FlightDate,
        OriginAirportID,
        DestAirportID,
        SchedDepTime,
        SchedArrTime,
        LEAD(OriginAirportID) OVER (PARTITION BY TailNumber ORDER BY FlightDate, SchedDepTime) AS NextOrigin,
        LEAD(SchedDepTime) OVER (PARTITION BY TailNumber ORDER BY FlightDate, SchedDepTime) AS NextDepTime,
        LEAD(FlightDate) OVER (PARTITION BY TailNumber ORDER BY FlightDate, SchedDepTime) AS NextFlightDate
    FROM warehouse.fact_flight
    WHERE TailNumber IS NOT NULL AND Cancelled = 0
)
SELECT
    TailNumber,
    FlightDate,
    DestAirportID AS TurnaroundAirport,
    SchedArrTime,
    NextDepTime,
    DATEDIFF(MINUTE,
    DATEADD(SECOND, DATEDIFF(SECOND, 0, SchedArrTime), CAST(FlightDate AS DATETIME)),
    DATEADD(SECOND, DATEDIFF(SECOND, 0, NextDepTime), CAST(NextFlightDate AS DATETIME))
) AS TurnaroundMinutes
FROM TailSequence
WHERE DestAirportID = NextOrigin