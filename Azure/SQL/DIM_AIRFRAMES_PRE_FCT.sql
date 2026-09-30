CREATE OR ALTER PROCEDURE staging.usp_load_dim_airframe_ids_only
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRAN;

        INSERT INTO warehouse.dim_airframe (TailNumber)
        SELECT DISTINCT s.Tail_Number
        FROM staging.raw_flights s
        WHERE s.Tail_Number IS NOT NULL
          AND s.Tail_Number <> 'UNKNOW'
          AND NOT EXISTS (
              SELECT 1 FROM warehouse.dim_airframe d
              WHERE d.TailNumber = s.Tail_Number
          );

        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        THROW;
    END CATCH
END;