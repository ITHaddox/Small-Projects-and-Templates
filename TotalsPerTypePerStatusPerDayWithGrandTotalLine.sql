USE SOITOSAP
GO

-- This script calculates the totals of each StatusCode for current records in the PIC, PMPS, and MBP tables.

-- Set date range for the search
DECLARE
    @StartSearchDateTime DateTime = DATEADD(day, -5, GETDATE()),  -- Default to 5 days of data
    @EndSearchDateTime DateTime = GETDATE(),                     -- Default to now
    @WaitingTooLong int = 60                                     -- Define "too long" waiting time in minutes

-- Create a temporary table for MovType descriptions
DROP TABLE IF EXISTS #MovTypeDescriptions
CREATE TABLE #MovTypeDescriptions (
    MovType VARCHAR(3),
    [Description] VARCHAR(30),
    TableNameAbbreviation VARCHAR(5),
    TableName VARCHAR(50)
)

-- Insert MovType descriptions into the temporary table
INSERT INTO #MovTypeDescriptions (MovType, [Description], TableNameAbbreviation, TableName)
VALUES
    ('201', 'Consumption'               ,'PIC',  'Posted Inventory Consumptions'),
    ('202', 'Consumption Reversal'      ,'PIC',  'Posted Inventory Consumptions'),
    ('303', 'Transfer Out'              ,'PIC',  'Posted Inventory Consumptions'),
    ('304', 'Transfer Reversal'         ,'PIC',  'Posted Inventory Consumptions'),
    ('305', 'Transfer Receive In'       ,'PIC',  'Posted Inventory Consumptions'),
    ('501', 'Production'                ,'PMPS', 'Posted Manufactured Product Stock'),
    ('502', 'Production Reversal'       ,'PMPS', 'Posted Manufactured Product Stock'),
    ('321', 'Quality --> UnRestricted'  ,'PMPS', 'Posted Manufactured Product Stock'),
    ('322', 'UnRestricted --> Quality'  ,'PMPS', 'Posted Manufactured Product Stock'),
    ('343', 'Blocked --> UnRestricted'  ,'PMPS', 'Posted Manufactured Product Stock'),
    ('344', 'UnRestricted --> Blocked'  ,'PMPS', 'Posted Manufactured Product Stock'),
    ('349', 'Blocked --> Quality'       ,'PMPS', 'Posted Manufactured Product Stock'),
    ('350', 'Quality --> Blocked'       ,'PMPS', 'Posted Manufactured Product Stock'),
    ('601', 'Sales Order GI'            ,'MBP',  'MMMovsByPlant'),
    ('602', 'Reversal Sales Order GI'   ,'MBP',  'MMMovsByPlant'),
    ('641', 'STO GI'                    ,'MBP',  'MMMovsByPlant'),
    ('642', 'Reversal STO GI'           ,'MBP',  'MMMovsByPlant'),
    ('101', 'Received STO GI'           ,'MBP',  'MMMovsByPlant'),
    ('102', 'Reversal Received STO GI'  ,'MBP',  'MMMovsByPlant'),
    ('653', 'GD Return Unrestr'         ,'MBP',  'MMMovsByPlant'), 
    ('551', 'GI Scrapping'              ,'MBP',  'MMMovsByPlant'),   
    ('711', 'GI InvDiff.:whouse'        ,'MBP',  'MMMovsByPlant'),  
    ('712', 'Reversal Received STO GI'  ,'MBP',  'MMMovsByPlant')

-- Common Table Expression (CTE) to calculate status code totals
WITH StatusCodeTotal_CTE AS (
    -- PIC - Posted Inventory Consumptions
    SELECT
        CAST(pic.CreateDateTime AS DATE) AS CreateDate,
        pic.MovType,
        mtd.[Description],
        SUM(CASE WHEN pic.StatusCode = 'C' THEN 1 ELSE 0 END) AS C_Processed, 
        SUM(CASE WHEN pic.StatusCode = 'X' THEN 1 ELSE 0 END) AS X_Error, 
        SUM(CASE WHEN pic.StatusCode = 'W' AND (DATEDIFF(MINUTE, CreateDateTime, GETDATE()) > @WaitingTooLong) THEN 1 ELSE 0 END) AS W_Too_Long,  
        SUM(CASE WHEN pic.StatusCode = 'N' THEN 1 ELSE 0 END) AS N_Ready, 
        0 AS X_Inv_Mnt_Process, -- Not applicable for this table
        0 AS X_Transfer_Process, -- Not applicable for this table
        0 AS MBP_F_CatInnovaProcessed,
        0 AS MBP_I_NoSend2CatInnova,
        0 AS MBP_T_SOIProcessed_Send2CatInnova,
        0 AS MBP_E_Error,
        0 AS MBP_C_Ready2Process,     
        GETDATE() AS Time_Report_Ran,
        @StartSearchDateTime AS Search_Start_Time,
        @EndSearchDateTime AS Search_End_Time,
        mtd.TableNameAbbreviation,
        mtd.TableName
    FROM PostedInventoryConsumptions pic (NOLOCK) 
    JOIN #MovTypeDescriptions mtd ON pic.MovType = mtd.MovType AND mtd.TableNameAbbreviation = 'PIC'
    WHERE pic.CreateDateTime BETWEEN @StartSearchDateTime AND @EndSearchDateTime 
    GROUP BY
        CAST(pic.CreateDateTime AS DATE),
        pic.MovType,
        mtd.[Description],
        mtd.TableNameAbbreviation,
        mtd.TableName

    UNION ALL

    -- PMPS - Posted Manufactured Product Stock
    SELECT
        CAST(pmps.CreateDateTime AS DATE) AS CreateDate,
        pmps.MovType,
        mtd.[Description],
        SUM(CASE WHEN pmps.StatusCode = 'C' THEN 1 ELSE 0 END) AS C_Processed, 
        SUM(CASE WHEN pmps.StatusCode = 'X' THEN 1 ELSE 0 END) AS X_Error,
        SUM(CASE WHEN pmps.StatusCode = 'W' AND (DATEDIFF(MINUTE, CreateDateTime, GETDATE()) > @WaitingTooLong) THEN 1 ELSE 0 END) AS W_Too_Long,  
        SUM(CASE WHEN pmps.StatusCode = 'N' THEN 1 ELSE 0 END) AS N_Ready, 
        SUM(CASE WHEN pmps.StatusCode = 'X' AND pmps.DocHeader > 18000000 AND pmps.movType IN (321,322,343,344,349,350) THEN 1 ELSE 0 END) AS X_Inv_Mnt_Process,   
        SUM(CASE WHEN pmps.StatusCode = 'X' AND pmps.DocHeader < 16000000 AND pmps.movType IN (321,322,343,344,349,350) THEN 1 ELSE 0 END) AS X_Transfer_Process, 
        0 AS MBP_F_CatInnovaProcessed,
        0 AS MBP_I_NoSend2CatInnova,
        0 AS MBP_T_SOIProcessed_Send2CatInnova,
        0 AS MBP_E_Error,
        0 AS MBP_C_Ready2Process,
        GETDATE() AS Time_Report_Ran,
        @StartSearchDateTime AS Search_Start_Time,
        @EndSearchDateTime AS Search_End_Time,
        mtd.TableNameAbbreviation,
        mtd.TableName
    FROM PostedManufacturedProductStock (NOLOCK) pmps
    JOIN #MovTypeDescriptions mtd ON pmps.MovType = mtd.MovType AND mtd.TableNameAbbreviation = 'PMPS'
    WHERE pmps.CreateDateTime BETWEEN @StartSearchDateTime AND @EndSearchDateTime 
    GROUP BY
        CAST(pmps.CreateDateTime AS DATE),
        pmps.MovType,
        mtd.[Description],
        mtd.TableNameAbbreviation,
        mtd.TableName

    UNION ALL

    -- MBP - MMMovsByPlant
    SELECT
        CAST(mbp.InterfaceDate AS DATE) AS CreateDate,
        mbp.MovType,
        mtd.[Description],
        0 AS C_Processed, 
        0 AS X_Error,
        0 AS W_Too_Long,  
        0 AS N_Ready, 
        0 AS X_Inv_Mnt_Process,   
        0 AS X_Transfer_Process, 
        SUM(CASE WHEN mbp.ProcessStatus = 'F' THEN 1 ELSE 0 END) AS MBP_F_CatInnovaProcessed,
        SUM(CASE WHEN mbp.ProcessStatus = 'I' THEN 1 ELSE 0 END) AS MBP_I_NoSend2CatInnova,
        SUM(CASE WHEN mbp.ProcessStatus = 'T' THEN 1 ELSE 0 END) AS MBP_T_SOIProcessed_Send2CatInnova,
        SUM(CASE WHEN mbp.ProcessStatus = 'E' THEN 1 ELSE 0 END) AS MBP_E_Error,
        SUM(CASE WHEN mbp.ProcessStatus = 'C' THEN 1 ELSE 0 END) AS MBP_C_Ready2Process,     
        GETDATE() AS Time_Report_Ran,
        @StartSearchDateTime AS Search_Start_Time,
        @EndSearchDateTime AS Search_End_Time,
        mtd.TableNameAbbreviation,
        mtd.TableName
    FROM MMMovsByPlant (NOLOCK) mbp
    JOIN #MovTypeDescriptions mtd ON mbp.MovType = mtd.MovType AND mtd.TableNameAbbreviation = 'MBP'
    WHERE mbp.InterfaceDate BETWEEN @StartSearchDateTime AND @EndSearchDateTime 
    GROUP BY
        CAST(mbp.InterfaceDate AS DATE),
        mbp.MovType,
        mtd.[Description],
        mtd.TableNameAbbreviation,
        mtd.TableName
)

-- Display data from previous queries then add a Total line after each date
SELECT * 
FROM StatusCodeTotal_CTE

UNION ALL

SELECT 
    CreateDate,
    'TOTAL' AS MovType,
    '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>' AS [Description],
    SUM(c.C_Processed) AS C_Processed, 
    SUM(X_Error) AS X_Error,
    SUM(W_Too_Long) AS W_Too_Long,  
    SUM(N_Ready) AS N_Ready, 
    SUM(X_Inv_Mnt_Process) AS X_Inv_Mnt_Process,   
    SUM(X_Transfer_Process) AS X_Transfer_Process, 
    SUM(MBP_F_CatInnovaProcessed) AS MBP_F_CatInnovaProcessed,
    SUM(MBP_I_NoSend2CatInnova) AS MBP_I_NoSend2CatInnova,
    SUM(MBP_T_SOIProcessed_Send2CatInnova) AS MBP_T_SOIProcessed_Send2CatInnova,
    SUM(MBP_E_Error) AS MBP_E_Error,
    SUM(MBP_C_Ready2Process) AS MBP_C_Ready2Process,        
    GETDATE() AS Time_Report_Ran,
    @StartSearchDateTime AS Search_Start_Time,
    @EndSearchDateTime AS Search_End_Time,
    'ZZZZZZZZZZZZZZZZZZZZZZZZZZZZ' AS TableNameAbbreviation,
    'ZZZZZZZZZZZZZZZZZZZZZZZZZZZZ' AS TableName
FROM StatusCodeTotal_CTE c
GROUP BY CreateDate

ORDER BY
    CreateDate,
    TableNameAbbreviation,
    MovType