CREATE OR ALTER PROCEDURE staging.usp_update_carrier_stats
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRAN;

        WITH DistinctTails AS (
            SELECT DISTINCT CarrierID, TailNumber
            FROM warehouse.fact_flight
            WHERE TailNumber IS NOT NULL
        ),
        Aggregated AS (
            SELECT
                CarrierID,
                STRING_AGG(CAST(TailNumber AS VARCHAR(MAX)), ', ') AS TailNumbers,
                COUNT(*) AS TotalAirframes
            FROM DistinctTails
            GROUP BY CarrierID
        )
        UPDATE dc
        SET dc.TailNumbers    = a.TailNumbers,
            dc.TotalAirframes = a.TotalAirframes
        FROM warehouse.dim_carrier dc
        JOIN Aggregated a ON dc.CarrierID = a.CarrierID;

        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        THROW;
    END CATCH
END;