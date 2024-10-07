------------------------------------------------------------------------------------
------------------------------------------------------------------------------------
Declare @StartDate DateTime = '1/1/23'
Declare @EndDate DateTime = '2/27/24'

SELECT 
  FiscalYear,
  FiscalWeek,
  DATEPART(YEAR, AuditDate) AS [Year],  
  DATEPART(MONTH, AuditDate) AS [Month],  
  DATEPART(DAY, AuditDate) AS [Day],
  DATENAME(WEEKDAY, AuditDate) AS [DayOfWeek],
  FORMAT(AuditDate, 'hh') AS [Hour],
  FORMAT(AuditDate, 'tt') AS [AM_PM],
  COUNT(*) AS [TransactionCount]
FROM 
  [POS].[dbo].[InvoiceAudit] i
WHERE 
  AuditDate Between @StartDate AND @EndDate AND
  InvoiceStatus = 10 AND      --"Entered"
  [Action] = 'I'
GROUP BY 
  FiscalYear,
  FiscalWeek,
  DATEPART(YEAR, AuditDate),  
  DATEPART(MONTH, AuditDate),  
  DATEPART(DAY, AuditDate),
  DATENAME(WEEKDAY, AuditDate),
  DATEPART(HOUR, AuditDate),
  FORMAT(AuditDate, 'hh'),
  FORMAT(AuditDate, 'tt')
ORDER BY 
  [Year], 
  [Month], 
  [Day], 
  CASE WHEN (FORMAT(AuditDate, 'hh') = 12) OR (FORMAT(AuditDate, 'tt') = 'AM') THEN 0 ELSE 1 END, 
  [Hour];



------------------------------------------------------------------------------------
------------------------------------------------------------------------------------






