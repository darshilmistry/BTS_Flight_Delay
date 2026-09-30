CREATE OR ALTER PROCEDURE staging.usp_load_dim_airport
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRAN;

        WITH AllAirports AS (
            SELECT TRY_CAST(OriginAirportID AS INT) AS AirportID,
                   Origin          AS IATA,
                   OriginCityName  AS CityName,
                   OriginStateFips AS StateFips,
                   OriginStateName AS StateName
            FROM staging.raw_flights
            UNION ALL
            SELECT TRY_CAST(DestAirportID AS INT),
                   Dest,
                   DestCityName,
                   DestStateFips,
                   DestStateName
            FROM staging.raw_flights
        ),
        OnePerID AS (
            SELECT AirportID,
                   MAX(IATA)      AS IATA,
                   MAX(CityName)  AS CityName,
                   MAX(StateFips) AS StateFips,
                   MAX(StateName) AS StateName
            FROM AllAirports
            WHERE AirportID IS NOT NULL
            GROUP BY AirportID
        )
        INSERT INTO warehouse.dim_airport (AirportID, IATA, CityName, StateFips, StateName)
        SELECT o.AirportID, o.IATA, o.CityName, o.StateFips, o.StateName
        FROM OnePerID o
        WHERE NOT EXISTS (
            SELECT 1 FROM warehouse.dim_airport d
            WHERE d.AirportID = o.AirportID
        );

        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        THROW;
    END CATCH
END;