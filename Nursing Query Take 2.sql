--SELECT	
--	DISTINCT [Hrs_LPNadmin_ctr],
--	[Hrs_RNadmin_ctr]
--FROM dbo.Population_With_Nursing_Data
--WHERE [Rank] <= 50;

--SELECT DISTINCT [Annual_Change]
--FROM dbo.Population_With_Nursing_Data;

--SELECT DISTINCT 
--	AVG(Hrs_RNDON_ctr) AS Don,
--	AVG(Hrs_RNadmin_ctr) AS RNadmin,
--	AVG(Hrs_RN_ctr) AS RN,
--	AVG(Hrs_LPNadmin_ctr) AS LPNadmin,
--	AVG(Hrs_LPN_ctr) AS LPN
--FROM dbo.Population_With_Nursing_Data;

ALTER TABLE dbo.Population_With_Nursing_Data
ADD [City_State] AS CONCAT([CITY], ' ', [STATE]);


WITH CTE AS (
    SELECT
        [PROVNUM],
        [PROVNAME],
        [CITY],
        [STATE],
        [City_State],
        [Rank],
        SUM([MDScensus]) AS MDScensus,
        SUM([Hrs_RN] + [Hrs_LPN]) AS TotalNursingHours,
        SUM([Hrs_RN_ctr] + [Hrs_LPN_ctr]) AS ContractingNursingHours
    FROM dbo.Population_With_Nursing_Data
    GROUP BY [PROVNUM], [PROVNAME], [City_State], [CITY], [STATE], [Rank]
),
CTE2 AS (
    SELECT
        *,
        ROUND(([ContractingNursingHours] / [TotalNursingHours]), 2) AS PercentageContracting
    FROM CTE
    WHERE [ContractingNursingHours] > 0
),
CTE3 AS (
    SELECT 
        *,
        DENSE_RANK() OVER (PARTITION BY [City_State] ORDER BY [PercentageContracting] DESC) AS PercContRank_WithinCity
    FROM CTE2
)
SELECT *
INTO SummedHRSTableByLocationAndProvider
FROM CTE3
ORDER BY City_State DESC;

SELECT *
FROM SummedHRSTableByLocationAndProvider
ORDER BY [City_state],[PercContRank_WithinCity]



--SELECT * FROM DBO.Population_With_Nursing_Data;

WITH CTE AS (
    SELECT
        [CITY],
        [STATE],
        [City_State],
        [Rank],
        SUM([MDScensus]) AS MDScensus,
        SUM([Hrs_RN] + [Hrs_LPN]) AS TotalNursingHours,
        SUM([Hrs_RN_ctr] + [Hrs_LPN_ctr]) AS ContractingNursingHours
    FROM dbo.Population_With_Nursing_Data
    GROUP BY [City_State], [CITY], [STATE], [Rank]
),
CTE2 AS (
	SELECT 
		*,
		([TotalNursingHours]/[MDScensus])*60 AS NursingMinutesPerPatient,
		([ContractingNursingHours]/[TotalNursingHours])*100 AS PercentContract
	FROM CTE
	WHERE [Rank] <= 50),
CTE3 AS(
	SELECT 
		*,
	DENSE_RANK() OVER (ORDER BY [PercentContract] DESC) AS	Contract_Percent_City_State_Rank
	FROM CTE2
)
SELECT  *
INTO Contract_Percent_City_State_Rank_Table
FROM CTE3
ORDER BY Contract_Percent_City_State_Rank

ALTER TABLE Contract_Percent_City_State_Rank_Table
ADD NursingMinuterPerPatientRanking INT;

WITH RankedData AS (
    SELECT
        NursingMinutesPerPatient,
        DENSE_RANK() OVER (ORDER BY NursingMinutesPerPatient) AS NursingMinuterPerPatientRanking,
        City_State -- Replace with your table's primary key column
    FROM Contract_Percent_City_State_Rank_Table
)
UPDATE Contract_Percent_City_State_Rank_Table
SET NursingMinuterPerPatientRanking = RankedData.NursingMinuterPerPatientRanking
FROM Contract_Percent_City_State_Rank_Table
INNER JOIN RankedData
    ON Contract_Percent_City_State_Rank_Table.City_State = RankedData.City_State;

SELECT *
FROM Contract_Percent_City_State_Rank_Table
ORDER BY NursingMinuterPerPatientRanking