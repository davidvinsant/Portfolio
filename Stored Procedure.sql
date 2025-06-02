USE [PrimaryDataMart]
GO
/****** Object:  StoredProcedure [dbo].[usp_GetProviderMonthlyRevenueSummary]    Script Date: 5/29/2025 10:54:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================


ALTER PROCEDURE [dbo].[usp_GetProviderMonthlyRevenueSummary] 
    @StartDate DATE,
    @EndDate DATE
AS
BEGIN
    SET NOCOUNT ON

    DROP TABLE IF EXISTS dbo.Provider_Monthly_Revenue_Summary

    WITH EncounterRevenueCTE AS (
        SELECT
            e.EncounterID,
            e.ProviderID,
            e.PatientID,
            e.PracticeID,
            e.ServiceDate,
            ISNULL(e.ChargeAmount, 0) AS ChargeAmount,
            ISNULL(p.PayerName, 'Self-Pay') AS PayerName
        FROM dbo.Encounters e
        LEFT JOIN dbo.Payers p ON e.PayerID = p.PayerID
        WHERE e.ServiceDate BETWEEN @StartDate AND @EndDate
    )


    SELECT
        pr.PracticeName,
        p.ProviderName,
        DATEADD(MONTH, DATEDIFF(MONTH, 0, er.ServiceDate), 0) AS RevenueMonth,
        COUNT(DISTINCT er.EncounterID) AS TotalEncounters,
        COUNT(DISTINCT er.PatientID) AS UniquePatients,
        SUM(er.ChargeAmount) AS TotalRevenue,
        AVG(er.ChargeAmount) AS AvgRevenuePerEncounter,
        SUM(CASE WHEN pat.Age < 18 THEN 1 ELSE 0 END) AS PediatricVisits,
        SUM(CASE WHEN er.PayerName = 'Medicare' THEN 1 ELSE 0 END) AS MedicareCount,
        SUM(CASE WHEN er.PayerName = 'Medicaid' THEN 1 ELSE 0 END) AS MedicaidCount
	INTO dbo.Provider_Monthly_Revenue_Summary
    FROM EncounterRevenueCTE er
    LEFT JOIN dbo.Providers p ON er.ProviderID = p.ProviderID
    LEFT JOIN dbo.Patients pat ON er.PatientID = pat.PatientID
    LEFT JOIN dbo.PracticeMappings pr ON er.PracticeID = pr.PracticeID
    GROUP BY
        pr.PracticeName,
        p.ProviderName,
		DATEADD(MONTH, DATEDIFF(MONTH, 0, er.ServiceDate), 0)

END
