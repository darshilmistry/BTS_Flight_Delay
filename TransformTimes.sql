CREATE FUNCTION dbo.ToTime (@hhmm VARCHAR(5))
RETURNS TIME(0)
AS
BEGIN
    RETURN TRY_CAST(STUFF(@hhmm, 3, 0, ':') AS TIME(0));
END
GO


SELECT TOP 10

	dbo.ToTime(CRSDepTime) AS CRSDepTime,
	dbo.ToTime(CRSArrTime) AS CRSArrTime,
	dbo.ToTime(WheelsOff) AS WheelsOff,
	dbo.ToTime(WheelsOn) AS WheelsOn


FROM warehouse.fact_flight;

SELECT TOP 5 * FROM warehouse.fact_flight;


-- 1. Add typed columns
ALTER TABLE warehouse.fact_flight ADD
    SchedDepTime  TIME(0),
    SchedArrTime  TIME(0),
    WheelsOffTime TIME(0),
    WheelsOnTime  TIME(0);
GO

-- 2. Populate
UPDATE warehouse.fact_flight
SET SchedDepTime  = dbo.ToTime(CRSDepTime),
    SchedArrTime  = dbo.ToTime(CRSArrTime),
    WheelsOffTime = dbo.ToTime(WheelsOff),
    WheelsOnTime  = dbo.ToTime(WheelsOn);
GO

-- 3. Check what failed BEFORE dropping the source columns
SELECT
    SUM(CASE WHEN CRSDepTime IS NOT NULL AND SchedDepTime  IS NULL THEN 1 ELSE 0 END) AS dep_failed,
    SUM(CASE WHEN CRSArrTime IS NOT NULL AND SchedArrTime  IS NULL THEN 1 ELSE 0 END) AS arr_failed,
    SUM(CASE WHEN WheelsOff  IS NOT NULL AND WheelsOffTime IS NULL THEN 1 ELSE 0 END) AS off_failed,
    SUM(CASE WHEN WheelsOn   IS NOT NULL AND WheelsOnTime  IS NULL THEN 1 ELSE 0 END) AS on_failed
FROM warehouse.fact_flight;
GO

-- 4. Quarantine failed rows
CREATE SCHEMA quarantine;
GO

CREATE TABLE quarantine.flights (
    QuarantineKey   BIGINT IDENTITY(1,1) PRIMARY KEY,
    QuarantinedAt   DATETIME2(0) NOT NULL DEFAULT SYSUTCDATETIME(),
    SourceTable     VARCHAR(100) NOT NULL,
    RejectionReason VARCHAR(200) NOT NULL,
    RawRow          NVARCHAR(MAX) NOT NULL
);
GO

INSERT INTO quarantine.flights (SourceTable, RejectionReason, RawRow)
SELECT
    'warehouse.fact_flight',
    CASE
        WHEN WheelsOff IS NOT NULL AND WheelsOffTime IS NULL
         AND WheelsOn  IS NOT NULL AND WheelsOnTime  IS NULL THEN 'unparseable WheelsOff and WheelsOn'
        WHEN WheelsOff IS NOT NULL AND WheelsOffTime IS NULL THEN 'unparseable WheelsOff'
        ELSE 'unparseable WheelsOn'
    END,
    (SELECT f.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
FROM warehouse.fact_flight f
WHERE (WheelsOff IS NOT NULL AND WheelsOffTime IS NULL)
   OR (WheelsOn  IS NOT NULL AND WheelsOnTime  IS NULL);

SELECT * FROM quarantine.flights;

-- 4. Only after checking: drop the strings
ALTER TABLE warehouse.fact_flight DROP COLUMN CRSDepTime, CRSArrTime, WheelsOff, WheelsOn;
GO