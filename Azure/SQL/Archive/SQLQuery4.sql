SELECT 
	TailNumber,
	MIN(FlightDate) AS FirstFlight,
	Max(FlightDate) AS LastFlight,
	COUNT(*) AS Cycles,
	SUM(ActualElapsedTime) AS HoursFlown,
	SUM(Distance) AS DistanceFlown,
	SUM(ActualElapsedTime) / COUNT(*) AS DistancePerCycle
FROM warehouse.fact_flight
GROUP BY TailNumber;