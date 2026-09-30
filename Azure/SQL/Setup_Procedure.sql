CREATE OR ALTER PROCEDURE dbo.usp_setup_objects
AS
BEGIN
    SET NOCOUNT ON;

    /* ---------- SCHEMAS ---------- */
    IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'staging')
        EXEC('CREATE SCHEMA staging');
    IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'warehouse')
        EXEC('CREATE SCHEMA warehouse');
    IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'quarantine')
        EXEC('CREATE SCHEMA quarantine');

    /* ------------------ STAGING ------------------ */
    
    IF OBJECT_ID(N'staging.raw_flights_landing', N'U') IS NULL
    CREATE TABLE staging.raw_flights_landing (
        Prop_0   VARCHAR(255), Prop_1   VARCHAR(255), Prop_2   VARCHAR(255), Prop_3   VARCHAR(255), Prop_4   VARCHAR(255),
        Prop_5   VARCHAR(255), Prop_6   VARCHAR(255), Prop_7   VARCHAR(255), Prop_8   VARCHAR(255), Prop_9   VARCHAR(255),
        Prop_10  VARCHAR(255), Prop_11  VARCHAR(255), Prop_12  VARCHAR(255), Prop_13  VARCHAR(255), Prop_14  VARCHAR(255),
        Prop_15  VARCHAR(255), Prop_16  VARCHAR(255), Prop_17  VARCHAR(255), Prop_18  VARCHAR(255), Prop_19  VARCHAR(255),
        Prop_20  VARCHAR(255), Prop_21  VARCHAR(255), Prop_22  VARCHAR(255), Prop_23  VARCHAR(255), Prop_24  VARCHAR(255),
        Prop_25  VARCHAR(255), Prop_26  VARCHAR(255), Prop_27  VARCHAR(255), Prop_28  VARCHAR(255), Prop_29  VARCHAR(255),
        Prop_30  VARCHAR(255), Prop_31  VARCHAR(255), Prop_32  VARCHAR(255), Prop_33  VARCHAR(255), Prop_34  VARCHAR(255),
        Prop_35  VARCHAR(255), Prop_36  VARCHAR(255), Prop_37  VARCHAR(255), Prop_38  VARCHAR(255), Prop_39  VARCHAR(255),
        Prop_40  VARCHAR(255), Prop_41  VARCHAR(255), Prop_42  VARCHAR(255), Prop_43  VARCHAR(255), Prop_44  VARCHAR(255),
        Prop_45  VARCHAR(255), Prop_46  VARCHAR(255), Prop_47  VARCHAR(255), Prop_48  VARCHAR(255), Prop_49  VARCHAR(255),
        Prop_50  VARCHAR(255), Prop_51  VARCHAR(255), Prop_52  VARCHAR(255), Prop_53  VARCHAR(255), Prop_54  VARCHAR(255),
        Prop_55  VARCHAR(255), Prop_56  VARCHAR(255), Prop_57  VARCHAR(255), Prop_58  VARCHAR(255), Prop_59  VARCHAR(255),
        Prop_60  VARCHAR(255), Prop_61  VARCHAR(255), Prop_62  VARCHAR(255), Prop_63  VARCHAR(255), Prop_64  VARCHAR(255),
        Prop_65  VARCHAR(255), Prop_66  VARCHAR(255), Prop_67  VARCHAR(255), Prop_68  VARCHAR(255), Prop_69  VARCHAR(255),
        Prop_70  VARCHAR(255), Prop_71  VARCHAR(255), Prop_72  VARCHAR(255), Prop_73  VARCHAR(255), Prop_74  VARCHAR(255),
        Prop_75  VARCHAR(255), Prop_76  VARCHAR(255), Prop_77  VARCHAR(255), Prop_78  VARCHAR(255), Prop_79  VARCHAR(255),
        Prop_80  VARCHAR(255), Prop_81  VARCHAR(255), Prop_82  VARCHAR(255), Prop_83  VARCHAR(255), Prop_84  VARCHAR(255),
        Prop_85  VARCHAR(255), Prop_86  VARCHAR(255), Prop_87  VARCHAR(255), Prop_88  VARCHAR(255), Prop_89  VARCHAR(255),
        Prop_90  VARCHAR(255), Prop_91  VARCHAR(255), Prop_92  VARCHAR(255), Prop_93  VARCHAR(255), Prop_94  VARCHAR(255),
        Prop_95  VARCHAR(255), Prop_96  VARCHAR(255), Prop_97  VARCHAR(255), Prop_98  VARCHAR(255), Prop_99  VARCHAR(255),
        Prop_100 VARCHAR(255), Prop_101 VARCHAR(255), Prop_102 VARCHAR(255), Prop_103 VARCHAR(255), Prop_104 VARCHAR(255),
        Prop_105 VARCHAR(255), Prop_106 VARCHAR(255), Prop_107 VARCHAR(255), Prop_108 VARCHAR(255),
        Prop_109 VARCHAR(255),  -- trailing-comma phantom
        Prop_110 VARCHAR(255)   -- spare filler, insurance
    );

        EXEC(N'
            CREATE OR ALTER VIEW staging.raw_flights AS
            SELECT
                Prop_0  AS [Year],                  Prop_1  AS [Quarter],
                Prop_2  AS [Month],                 Prop_3  AS [DayofMonth],
                Prop_4  AS [DayOfWeek],             Prop_5  AS [FlightDate],
                Prop_6  AS [Reporting_Airline],     Prop_7  AS [DOT_ID_Reporting_Airline],
                Prop_8  AS [IATA_CODE_Reporting_Airline],
                Prop_9  AS [Tail_Number],           Prop_10 AS [Flight_Number_Reporting_Airline],
                Prop_11 AS [OriginAirportID],       Prop_12 AS [OriginAirportSeqID],
                Prop_13 AS [OriginCityMarketID],    Prop_14 AS [Origin],
                Prop_15 AS [OriginCityName],        Prop_16 AS [OriginState],
                Prop_17 AS [OriginStateFips],       Prop_18 AS [OriginStateName],
                Prop_19 AS [OriginWac],
                Prop_20 AS [DestAirportID],         Prop_21 AS [DestAirportSeqID],
                Prop_22 AS [DestCityMarketID],      Prop_23 AS [Dest],
                Prop_24 AS [DestCityName],          Prop_25 AS [DestState],
                Prop_26 AS [DestStateFips],         Prop_27 AS [DestStateName],
                Prop_28 AS [DestWac],
                Prop_29 AS [CRSDepTime],            Prop_30 AS [DepTime],
                Prop_31 AS [DepDelay],              Prop_32 AS [DepDelayMinutes],
                Prop_33 AS [DepDel15],              Prop_34 AS [DepartureDelayGroups],
                Prop_35 AS [DepTimeBlk],            Prop_36 AS [TaxiOut],
                Prop_37 AS [WheelsOff],             Prop_38 AS [WheelsOn],
                Prop_39 AS [TaxiIn],                Prop_40 AS [CRSArrTime],
                Prop_41 AS [ArrTime],               Prop_42 AS [ArrDelay],
                Prop_43 AS [ArrDelayMinutes],       Prop_44 AS [ArrDel15],
                Prop_45 AS [ArrivalDelayGroups],    Prop_46 AS [ArrTimeBlk],
                Prop_47 AS [Cancelled],             Prop_48 AS [CancellationCode],
                Prop_49 AS [Diverted],              Prop_50 AS [CRSElapsedTime],
                Prop_51 AS [ActualElapsedTime],     Prop_52 AS [AirTime],
                Prop_53 AS [Flights],               Prop_54 AS [Distance],
                Prop_55 AS [DistanceGroup],
                Prop_56 AS [CarrierDelay],          Prop_57 AS [WeatherDelay],
                Prop_58 AS [NASDelay],              Prop_59 AS [SecurityDelay],
                Prop_60 AS [LateAircraftDelay],
                Prop_61 AS [FirstDepTime],          Prop_62 AS [TotalAddGTime],
                Prop_63 AS [LongestAddGTime],       Prop_64 AS [DivAirportLandings],
                Prop_65 AS [DivReachedDest],        Prop_66 AS [DivActualElapsedTime],
                Prop_67 AS [DivArrDelay],           Prop_68 AS [DivDistance],
                Prop_69 AS [Div1Airport],           Prop_70 AS [Div1AirportID],
                Prop_71 AS [Div1AirportSeqID],      Prop_72 AS [Div1WheelsOn],
                Prop_73 AS [Div1TotalGTime],        Prop_74 AS [Div1LongestGTime],
                Prop_75 AS [Div1WheelsOff],         Prop_76 AS [Div1TailNum],
                Prop_77 AS [Div2Airport],           Prop_78 AS [Div2AirportID],
                Prop_79 AS [Div2AirportSeqID],      Prop_80 AS [Div2WheelsOn],
                Prop_81 AS [Div2TotalGTime],        Prop_82 AS [Div2LongestGTime],
                Prop_83 AS [Div2WheelsOff],         Prop_84 AS [Div2TailNum],
                Prop_85 AS [Div3Airport],           Prop_86 AS [Div3AirportID],
                Prop_87 AS [Div3AirportSeqID],      Prop_88 AS [Div3WheelsOn],
                Prop_89 AS [Div3TotalGTime],        Prop_90 AS [Div3LongestGTime],
                Prop_91 AS [Div3WheelsOff],         Prop_92 AS [Div3TailNum],
                Prop_93 AS [Div4Airport],           Prop_94 AS [Div4AirportID],
                Prop_95 AS [Div4AirportSeqID],      Prop_96 AS [Div4WheelsOn],
                Prop_97 AS [Div4TotalGTime],        Prop_98 AS [Div4LongestGTime],
                Prop_99 AS [Div4WheelsOff],         Prop_100 AS [Div4TailNum],
                Prop_101 AS [Div5Airport],          Prop_102 AS [Div5AirportID],
                Prop_103 AS [Div5AirportSeqID],     Prop_104 AS [Div5WheelsOn],
                Prop_105 AS [Div5TotalGTime],       Prop_106 AS [Div5LongestGTime],
                Prop_107 AS [Div5WheelsOff],        Prop_108 AS [Div5TailNum]
            FROM staging.raw_flights_landing
            WHERE Prop_0 <> ''Year'';
    ');

    /* ---------------- WAREHOUSE --------------- */

    /* ---------- DIMENSIONS ---------- */
    IF OBJECT_ID(N'warehouse.dim_date', N'U') IS NULL
        CREATE TABLE warehouse.dim_date (
            FlightDate  DATE        NOT NULL PRIMARY KEY,
            Yr          SMALLINT    NOT NULL,
            Qtr         TINYINT     NOT NULL,
            WeekOfYear  TINYINT     NOT NULL,
            Mnth        TINYINT     NOT NULL,
            Dt          TINYINT     NOT NULL,
            DayName     VARCHAR(20) NOT NULL,
            MonthName   VARCHAR(20) NOT NULL,
            IsWeekend   BIT         NOT NULL,
            IsHoliday   BIT         NOT NULL DEFAULT 0
        );

    IF OBJECT_ID(N'warehouse.dim_carrier', N'U') IS NULL
    BEGIN
        CREATE TABLE warehouse.dim_carrier (
            CarrierID      INT          NOT NULL PRIMARY KEY,
            IATA           CHAR(2)      NOT NULL,
            AirlineName    VARCHAR(100) NOT NULL,
            MergedInto     CHAR(2)      NULL,
            ActiveThrough  DATE         NULL,
            TailNumbers    VARCHAR(MAX) NULL,
            TotalAirframes INT          NULL
        );
    END;

    IF OBJECT_ID(N'warehouse.dim_airport', N'U') IS NULL
    BEGIN
        -- paste your DDL, keyed on AirportID
        CREATE TABLE warehouse.dim_airport (
             AirportID       INT PRIMARY KEY,
             AirportSeqID    INT,
             CityMarketID    INT NULL,
             IATA            VARCHAR(5), 
             CityName        VARCHAR(50),
             WAC             SMALLINT NULL,
             StateFips       SMALLINT NULL,
             State           VARCHAR(5),
             StateName       VARCHAR(30)
        );
    END;

    IF OBJECT_ID(N'warehouse.dim_airframe', N'U') IS NULL
        CREATE TABLE warehouse.dim_airframe (
            TailNumber              VARCHAR(10) NOT NULL PRIMARY KEY,
            FirstFlightDate         DATE        NULL,
            LastFlightDate          DATE        NULL,
            TotalFlights            INT         NULL,
            TotalBlockMinutes       BIGINT      NULL,
            TotalDistance           BIGINT      NULL,
            AvgBlockMinutesPerCycle DECIMAL(10,2) NULL,
            MaxContinuousHops       INT         NULL,
            AvgContinuousHops       DECIMAL(10,2) NULL
        );

    /* ---------- FACT_FLIGHTS ---------- */
    IF OBJECT_ID(N'warehouse.fact_flight', N'U') IS NULL
    BEGIN
        -- paste your DDL
        CREATE TABLE warehouse.fact_flight (
            FlightKey           BIGINT PRIMARY KEY,
            FlightDate          DATE        NOT NULL,
            CarrierID           INT         NOT NULL,
            OriginAirportID     INT         NOT NULL,
            DestAirportID       INT         NOT NULL,
            TailNumber          VARCHAR(10),
            FlightNumber        INT,
            -- scheduled times, as strings pending conversion
            SchedDepTime        TIME(0),
            SchedArrTime        TIME(0),
            WheelsOffTime       TIME(0),
            WheelsOnTime        TIME(0),
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
            Cancelled           BIT         NULL,
            Diverted            BIT         NULL,
            -- diversion summary
            DivArrDelay             SMALLINT,
            DivAirportLandings      TINYINT,
            DivReachedDest          BIT NULL,
            DivActualElapsedTime    SMALLINT,
            DivDistance             SMALLINT,
            TotalAddGTime           SMALLINT,
            LongestAddGTime         SMALLINT,
            -- foreign keys
            CONSTRAINT FK_fact_date    FOREIGN KEY (FlightDate)      REFERENCES warehouse.dim_date (FlightDate),
            CONSTRAINT FK_fact_carrier FOREIGN KEY (CarrierID)       REFERENCES warehouse.dim_carrier (CarrierID),
            CONSTRAINT FK_fact_origin  FOREIGN KEY (OriginAirportID) REFERENCES warehouse.dim_airport (AirportID),
            CONSTRAINT FK_fact_dest    FOREIGN KEY (DestAirportID)   REFERENCES warehouse.dim_airport (AirportID)
        );
    END;

    /* -------------------- QUARANTINE -------------------- */
    IF OBJECT_ID(N'quarantine.bad_rows', N'U') IS NULL
        CREATE TABLE quarantine.bad_rows (
            QuarantineID  BIGINT IDENTITY(1,1) PRIMARY KEY,
            SourceTable   VARCHAR(100)  NOT NULL,
            FailedRule    VARCHAR(200)  NOT NULL,
            RowData       NVARCHAR(MAX) NOT NULL,
            QuarantinedAt DATETIME2     NOT NULL DEFAULT SYSUTCDATETIME()
        );
END;