"Reporting_Airline"
"DOT_ID_Reporting_Airline"
"IATA_CODE_Reporting_Airline"

SELECT TOP 5
	Reporting_Airline,
	DOT_ID_Reporting_Airline,	
	IATA_CODE_Reporting_Airline,
	Flight_Number_Reporting_Airline
FROM staging.raw_flights;


SELECT TOP 5
	Year, 
	Quarter, 
	Month, 
	DayofMonth, 
	DayOfWeek, 
	FlightDate
FROM staging.raw_flights;


SELECT MIN(CAST(Flight_Number_Reporting_Airline AS INT)),
       MAX(CAST(Flight_Number_Reporting_Airline AS INT))
FROM staging.raw_flights;


SELECT TOP 5
	DestAirportSeqID,
	COUNT(DISTINCT DestAirportID)
FROM staging.raw_flights
GROUP BY DestAirportSeqID
ORDER BY COUNT(DISTINCT DestAirportID) DESC;

SELECT 
	COUNT(*),
	COUNT(DISTINCT OriginAirportID),
	COUNT(DISTINCT OriginAirportSeqID),
	COUNT(DISTINCT DestAirportID),
	COUNT(DISTINCT DestAirportSeqID)
FROM staging.raw_flights;




SELECT TOP 5
	DestAirportSeqID,
	DestAirportID 
FROM staging.raw_flights
GROUP BY DestAirportSeqID
HAVING COUNT(DestAirportID) > 1 
ORDER BY COUNT(DestAirportID);

SELECT AirportID, COUNT(*)
FROM warehouse.dim_airport
GROUP BY AirportID
HAVING COUNT(*) > 1;

SELECT TOP 5
	Cancelled,
	CancellationCode
FROM staging.raw_flights
WHERE CancellationCode IS NOT NULL;

SELECT Cancelled, COUNT(*) FROM staging.raw_flights GROUP BY Cancelled;

SELECT Cancelled, CancellationCode FROM staging.raw_flights WHERE Cancelled = '1.00';

SELECT TOP 5
	Flights,
	Distance,
	Diverted
FROM staging.raw_flights
WHERE Diverted = '1.00'
ORDER BY Flights DESC;

SELECT DISTINCT Flights FROM staging.raw_flights;

SELECT TOP 20 ArrDelay, CarrierDelay, WeatherDelay, NASDelay, SecurityDelay, LateAircraftDelay
FROM staging.raw_flights
WHERE CarrierDelay IS NOT NULL;

SELECT
    Diverted,
    DivAirportLandings,
    DivReachedDest,
    DivActualElapsedTime,
    DivArrDelay,
    DivDistance,
    COUNT(*) AS rows_
FROM staging.raw_flights
GROUP BY Diverted, DivAirportLandings, DivReachedDest,
         DivActualElapsedTime, DivArrDelay, DivDistance
ORDER BY Diverted, DivAirportLandings;


SELECT TOP 5
	FlightDate,
	DOT_ID_Reporting_Airline,
	Tail_Number,
	Flight_Number_Reporting_Airline,
	OriginAirportID,
	Cancelled,
	CRSDepTime,
	DepDelay,
	TaxiOut,
	WheelsOff,
	DestAirportID,
	CRSArrTime,
	ArrDelay,
	WheelsOn,
	TaxiIn,
	Distance,
	Diverted,
	CRSElapsedTime,
	ActualElapsedTime,
	AirTime,
	CarrierDelay,
	WeatherDelay,
	NASDelay,
	SecurityDelay,
	LateAircraftDelay,
	DivArrDelay,
	TotalAddGTime,
	LongestAddGTime,
	DivAirportLandings,
	DivReachedDest,
	DivActualElapsedTime,
	DivDistance
FROM staging.raw_flights
WHERE DivAirportLandings IS NOT NULL
FOR JSON AUTO;

SELECT LEN(Tail_Number) AS len_, COUNT(*)
FROM staging.raw_flights
GROUP BY LEN(Tail_Number)
ORDER BY len_;


SELECT MAX(Distance) FROM staging.raw_flights;