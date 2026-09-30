
CREATE TABLE warehouse.dim_date (
    FlightDate DATE,
    Yr SMALLINT,
    Qtr TINYINT,
    WeekOfYear TINYINT,
    Mnth TINYINT,
    Dt TINYINT,
    DayName VARCHAR(20),
    MonthName Varchar(20),
    IsWeekend BIT,
    IsHoliday BIT,
    PRIMARY KEY(FlightDate)
);
GO

DECLARE @MaxDate DATE = (SELECT MAX(TRY_CAST(FlightDate AS DATE)) FROM staging.raw_Flights WHERE TRY_CAST(FlightDate AS DATE) IS NOT NULL);
DECLARE @MinDate DATE = (SELECT MIN(TRY_CAST(FlightDate AS DATE)) FROM staging.raw_Flights WHERE TRY_CAST(FlightDate AS DATE) IS NOT NULL);


WITH DateSpine AS (
    SELECT @MinDate AS FlightDt
    UNION ALL
    SELECT DATEADD(DAY, 1, FlightDt)
    FROM DateSpine
    WHERE DATEADD(DAY, 1, FlightDt) <= @MaxDate
)
INSERT INTO warehouse.dim_date (FlightDate, Yr, Qtr, WeekOfYear, Mnth, Dt, DayName, MonthName, IsWeekend, IsHoliday)
SELECT 
    FlightDt,
    YEAR(FlightDt),
    DATEPART(QUARTER, FlightDt),
    DATEPART(ISO_WEEK, FlightDt),
    MONTH(FlightDt),
    DAY(FlightDt),
    DATENAME(WEEKDAY, FlightDt),
    DATENAME(MONTH, FlightDt),
    CASE WHEN DATEPART(WEEKDAY, FlightDt) IN (1, 7) THEN 1 ELSE 0 END,
    0
FROM DateSpine

OPTION (MAXRECURSION 1000);

SELECT * FROM warehouse.dim_date;