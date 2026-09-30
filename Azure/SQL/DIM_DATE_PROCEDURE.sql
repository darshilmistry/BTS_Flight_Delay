CREATE OR ALTER PROCEDURE staging.usp_load_dim_date
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @Start DATE, @End DATE;

    SELECT @Start = MIN(TRY_CAST(FlightDate AS DATE)),
           @End   = MAX(TRY_CAST(FlightDate AS DATE))
    FROM staging.raw_flights;

    IF @Start IS NULL
        THROW 50002, 'No valid FlightDate values in staging. Aborting dim_date load.', 1;

    BEGIN TRY
        BEGIN TRAN

        INSERT INTO warehouse.dim_date 
            (FlightDate, Yr, Qtr, WeekOfYear, Mnth, 
            Dt, DayName, MonthName, IsWeekend, IsHoliday)
        SELECT
            d.FlightDate,
            YEAR(d.FlightDate),
            DATEPART(QUARTER, d.FlightDate),
            DATEPART(ISO_WEEK, d.FlightDate),
            MONTH(d.FlightDate),
            DAY(d.FlightDate),
            DATENAME(WEEKDAY, d.FlightDate),
            DATENAME(MONTH, d.FlightDate),
            CASE WHEN DATENAME(WEEKDAY, d.FlightDate) IN ('Saturday', 'Sunday')
                 THEN 1 ELSE 0 END,
            0 -- TODO UPDATE HOLIDAYS
        FROM (
            SELECT DATEADD(DAY, gs.value, @Start) AS FlightDate
            FROM GENERATE_SERIES(0, DATEDIFF(DAY, @Start, @End)) gs
        ) d
        WHERE NOT EXISTS (
            SELECT 1 FROM warehouse.dim_date x
            WHERE x.FlightDate = d.FlightDate
        );

        COMMIT;
    END TRY

    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        THROW;
    END CATCH

END;