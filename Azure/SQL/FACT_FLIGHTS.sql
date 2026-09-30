CREATE OR ALTER PROCEDURE staging.usp_load_fact_flight
    @Year  VARCHAR(4),
    @Month VARCHAR(2),
    @Force BIT = 0

AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @Start DATE = DATEFROMPARTS(CAST(@Year AS INT), CAST(@Month AS INT), 1);
    DECLARE @End   DATE = DATEADD(MONTH, 1, @Start);


    IF NOT EXISTS (
        SELECT 1 FROM staging.raw_flights
        WHERE TRY_CAST(FlightDate AS DATE) >= @Start
          AND TRY_CAST(FlightDate AS DATE) <  @End
    )
        THROW 50001, 'Staging has no rows for the requested Year/Month. Aborting before delete.', 1;
    IF @Force = 0 AND EXISTS (
        SELECT 1 FROM warehouse.fact_flight
        WHERE FlightDate >= @Start AND FlightDate < @End
    )

    RETURN;

    BEGIN TRY
        BEGIN TRAN;

        IF @FORCE = 1
            DELETE FROM warehouse.fact_flight
            WHERE FlightDate >= @Start AND FlightDate < @End;

        INSERT INTO warehouse.fact_flight (
            FlightKey, FlightDate, CarrierID, OriginAirportID, DestAirportID, TailNumber, FlightNumber,
            SchedDepTime, SchedArrTime, WheelsOffTime, WheelsOnTime,
            DepDelay, ArrDelay, TaxiOut, TaxiIn, AirTime, CRSElapsedTime, ActualElapsedTime, Distance,
            CarrierDelay, WeatherDelay, NASDelay, SecurityDelay, LateAircraftDelay,
            Cancelled, Diverted,
            DivArrDelay, DivAirportLandings, DivReachedDest, DivActualElapsedTime, DivDistance,
            TotalAddGTime, LongestAddGTime
        )
        SELECT

            CAST(HASHBYTES('SHA2_256',
            CONCAT_WS('|',
                CONVERT(CHAR(8), TRY_CAST(s.FlightDate AS DATE), 112),
                TRY_CAST(s.DOT_ID_Reporting_Airline AS INT),
                TRY_CAST(s.Flight_Number_Reporting_Airline AS INT),
                TRY_CAST(s.OriginAirportID AS INT),
                TRY_CAST(S.CRSDepTime AS INT)
            )) AS BIGINT) AS FlightKey,

            TRY_CAST(s.FlightDate AS DATE),
            TRY_CAST(s.DOT_ID_Reporting_Airline AS INT),
            TRY_CAST(s.OriginAirportID AS INT),
            TRY_CAST(s.DestAirportID AS INT),
            NULLIF(s.Tail_Number, 'UNKNOW'),
            TRY_CAST(s.Flight_Number_Reporting_Airline AS INT),

            dbo.ToTime(s.CRSDepTime),
            dbo.ToTime(s.CRSArrTime),
            dbo.ToTime(s.WheelsOff),
            dbo.ToTime(s.WheelsOn),

            TRY_CAST(TRY_CAST(s.DepDelay          AS DECIMAL(9,2)) AS SMALLINT),
            TRY_CAST(TRY_CAST(s.ArrDelay          AS DECIMAL(9,2)) AS SMALLINT),
            TRY_CAST(TRY_CAST(s.TaxiOut           AS DECIMAL(9,2)) AS SMALLINT),
            TRY_CAST(TRY_CAST(s.TaxiIn            AS DECIMAL(9,2)) AS SMALLINT),
            TRY_CAST(TRY_CAST(s.AirTime           AS DECIMAL(9,2)) AS SMALLINT),
            TRY_CAST(TRY_CAST(s.CRSElapsedTime    AS DECIMAL(9,2)) AS SMALLINT),
            TRY_CAST(TRY_CAST(s.ActualElapsedTime AS DECIMAL(9,2)) AS SMALLINT),
            TRY_CAST(TRY_CAST(s.Distance          AS DECIMAL(9,2)) AS SMALLINT),

            TRY_CAST(TRY_CAST(s.CarrierDelay      AS DECIMAL(9,2)) AS SMALLINT),
            TRY_CAST(TRY_CAST(s.WeatherDelay      AS DECIMAL(9,2)) AS SMALLINT),
            TRY_CAST(TRY_CAST(s.NASDelay          AS DECIMAL(9,2)) AS SMALLINT),
            TRY_CAST(TRY_CAST(s.SecurityDelay     AS DECIMAL(9,2)) AS SMALLINT),
            TRY_CAST(TRY_CAST(s.LateAircraftDelay AS DECIMAL(9,2)) AS SMALLINT),

            TRY_CAST(TRY_CAST(s.Cancelled AS DECIMAL(3,2)) AS BIT),
            TRY_CAST(TRY_CAST(s.Diverted  AS DECIMAL(3,2)) AS BIT),

            TRY_CAST(TRY_CAST(s.DivArrDelay          AS DECIMAL(9,2)) AS SMALLINT),
            TRY_CAST(TRY_CAST(s.DivAirportLandings   AS DECIMAL(9,2)) AS TINYINT),
            TRY_CAST(TRY_CAST(s.DivReachedDest       AS DECIMAL(3,2)) AS BIT),
            TRY_CAST(TRY_CAST(s.DivActualElapsedTime AS DECIMAL(9,2)) AS SMALLINT),
            TRY_CAST(TRY_CAST(s.DivDistance          AS DECIMAL(9,2)) AS SMALLINT),
            TRY_CAST(TRY_CAST(s.TotalAddGTime        AS DECIMAL(9,2)) AS SMALLINT),
            TRY_CAST(TRY_CAST(s.LongestAddGTime      AS DECIMAL(9,2)) AS SMALLINT)
        FROM staging.raw_flights s
        WHERE TRY_CAST(s.FlightDate AS DATE) >= @Start
          AND TRY_CAST(s.FlightDate AS DATE) <  @End;

        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        THROW;
    END CATCH
END;