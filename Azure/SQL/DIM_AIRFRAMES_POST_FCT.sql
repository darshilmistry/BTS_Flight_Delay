CREATE OR ALTER PROCEDURE staging.usp_update_airframe_stats
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRAN;

        WITH TailStats AS (
            SELECT
                TailNumber,
                MIN(FlightDate)                                AS FirstFlightDate,
                MAX(FlightDate)                                AS LastFlightDate,
                COUNT(*)                                       AS TotalFlights,
                SUM(CAST(ActualElapsedTime AS BIGINT))         AS TotalBlockMinutes,
                SUM(CAST(Distance AS BIGINT))                  AS TotalDistance,
                AVG(CAST(ActualElapsedTime AS DECIMAL(10,2)))  AS AvgBlockMinutesPerCycle
            FROM warehouse.fact_flight
            WHERE TailNumber IS NOT NULL
              AND Cancelled = 0
            GROUP BY TailNumber
        )
        UPDATE da
        SET da.FirstFlightDate         = ts.FirstFlightDate,
            da.LastFlightDate          = ts.LastFlightDate,
            da.TotalFlights            = ts.TotalFlights,
            da.TotalBlockMinutes       = ts.TotalBlockMinutes,
            da.TotalDistance           = ts.TotalDistance,
            da.AvgBlockMinutesPerCycle = ts.AvgBlockMinutesPerCycle
        FROM warehouse.dim_airframe da
        JOIN TailStats ts ON da.TailNumber = ts.TailNumber;

        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        THROW;
    END CATCH
END;