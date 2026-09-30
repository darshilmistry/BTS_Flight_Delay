CREATE OR ALTER PROCEDURE staging.usp_load_dim_carrier
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRAN;

        INSERT INTO warehouse.dim_carrier (CarrierID, IATA, AirlineName, MergedInto, ActiveThrough)
        SELECT v.CarrierID, v.IATA, v.AirlineName, v.MergedInto, v.ActiveThrough
        FROM (VALUES
            (19930, 'AS', 'Alaska Airlines',       NULL, NULL),
            (19805, 'AA', 'American Airlines',     NULL, NULL),
            (19790, 'DL', 'Delta Air Lines',       NULL, NULL),
            (20398, 'MQ', 'Envoy Air',             NULL, NULL),
            (19991, 'HP', 'America West Airlines', 'US', '2005-12-31'),
            (20355, 'US', 'US Airways',            NULL, NULL),
            (19977, 'UA', 'United Airlines',       NULL, NULL),
            (19393, 'WN', 'Southwest Airlines',    NULL, NULL),
            (19704, 'CO', 'Continental Airlines',  'UA', '2011-12-31'),
            (19386, 'NW', 'Northwest Airlines',    'DL', '2009-12-31')
        ) v (CarrierID, IATA, AirlineName, MergedInto, ActiveThrough)
        WHERE NOT EXISTS (
            SELECT 1 FROM warehouse.dim_carrier d WHERE d.CarrierID = v.CarrierID
        );

        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        THROW;
    END CATCH
END;