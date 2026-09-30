CREATE TABLE warehouse.fact_flight (
    FlightKey           BIGINT IDENTITY(1,1) PRIMARY KEY,
    FlightDate          DATE        NOT NULL,
    CarrierID           INT         NOT NULL,
    OriginAirportID     INT         NOT NULL,
    DestAirportID       INT         NOT NULL,
    TailNumber          VARCHAR(10),
    FlightNumber        INT,
    -- scheduled times, as strings pending conversion
    CRSDepTime          VARCHAR(5),
    CRSArrTime          VARCHAR(5),
    WheelsOff           VARCHAR(5),
    WheelsOn            VARCHAR(5),
    -- measures
    DepDelay            SMALLINT,
    ArrDelay            SMALLINT,
    TaxiOut             SMALLINT,
    TaxiIn              SMALLINT,
    AirTime             SMALLINT,
    CRSElapsedTime      SMALLINT,
    ActualElapsedTime   SMALLINT,
    Distance            SMALLINT,
    -- delay attribution
    CarrierDelay        SMALLINT,
    WeatherDelay        SMALLINT,
    NASDelay            SMALLINT,
    SecurityDelay       SMALLINT,
    LateAircraftDelay   SMALLINT,
    -- flags
    Cancelled           BIT         NOT NULL,
    Diverted            BIT         NOT NULL,
    -- diversion summary
    DivArrDelay             SMALLINT,
    DivAirportLandings      TINYINT,
    DivReachedDest          BIT,
    DivActualElapsedTime    SMALLINT,
    DivDistance             SMALLINT,
    TotalAddGTime           SMALLINT,
    LongestAddGTime         SMALLINT
);
GO

INSERT INTO warehouse.fact_flight (
    FlightDate, CarrierID, OriginAirportID, DestAirportID,
    TailNumber, FlightNumber,
    CRSDepTime, CRSArrTime, WheelsOff, WheelsOn,
    DepDelay, ArrDelay, TaxiOut, TaxiIn, AirTime,
    CRSElapsedTime, ActualElapsedTime, Distance,
    CarrierDelay, WeatherDelay, NASDelay, SecurityDelay, LateAircraftDelay,
    Cancelled, Diverted,
    DivArrDelay, DivAirportLandings, DivReachedDest,
    DivActualElapsedTime, DivDistance, TotalAddGTime, LongestAddGTime
)
SELECT
    TRY_CAST(FlightDate AS DATE),
    TRY_CAST(DOT_ID_Reporting_Airline AS INT),
    TRY_CAST(OriginAirportID AS INT),
    TRY_CAST(DestAirportID AS INT),
    NULLIF(LTRIM(RTRIM(Tail_Number)), ''),
    TRY_CAST(Flight_Number_Reporting_Airline AS INT),
    NULLIF(CRSDepTime, ''),
    NULLIF(CRSArrTime, ''),
    NULLIF(WheelsOff, ''),
    NULLIF(WheelsOn, ''),
    TRY_CAST(TRY_CAST(DepDelay AS FLOAT) AS SMALLINT),
    TRY_CAST(TRY_CAST(ArrDelay AS FLOAT) AS SMALLINT),
    TRY_CAST(TRY_CAST(TaxiOut AS FLOAT) AS SMALLINT),
    TRY_CAST(TRY_CAST(TaxiIn AS FLOAT) AS SMALLINT),
    TRY_CAST(TRY_CAST(AirTime AS FLOAT) AS SMALLINT),
    TRY_CAST(TRY_CAST(CRSElapsedTime AS FLOAT) AS SMALLINT),
    TRY_CAST(TRY_CAST(ActualElapsedTime AS FLOAT) AS SMALLINT),
    TRY_CAST(TRY_CAST(Distance AS FLOAT) AS SMALLINT),
    TRY_CAST(TRY_CAST(CarrierDelay AS FLOAT) AS SMALLINT),
    TRY_CAST(TRY_CAST(WeatherDelay AS FLOAT) AS SMALLINT),
    TRY_CAST(TRY_CAST(NASDelay AS FLOAT) AS SMALLINT),
    TRY_CAST(TRY_CAST(SecurityDelay AS FLOAT) AS SMALLINT),
    TRY_CAST(TRY_CAST(LateAircraftDelay AS FLOAT) AS SMALLINT),
    TRY_CAST(TRY_CAST(Cancelled AS FLOAT) AS BIT),
    TRY_CAST(TRY_CAST(Diverted AS FLOAT) AS BIT),
    TRY_CAST(TRY_CAST(DivArrDelay AS FLOAT) AS SMALLINT),
    TRY_CAST(TRY_CAST(DivAirportLandings AS FLOAT) AS TINYINT),
    TRY_CAST(TRY_CAST(DivReachedDest AS FLOAT) AS BIT),
    TRY_CAST(TRY_CAST(DivActualElapsedTime AS FLOAT) AS SMALLINT),
    TRY_CAST(TRY_CAST(DivDistance AS FLOAT) AS SMALLINT),
    TRY_CAST(TRY_CAST(TotalAddGTime AS FLOAT) AS SMALLINT),
    TRY_CAST(TRY_CAST(LongestAddGTime AS FLOAT) AS SMALLINT)
FROM staging.raw_flights;

SELECT TOP 5 * FROM warehouse.fact_flight;