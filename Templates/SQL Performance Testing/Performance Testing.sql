/*******************************************************************
Example T-SQL to gather performance metrics.
  1. Total execution time
  2. Logical reads for each operation
  3. Number of rows processed in each step
  4. CPU time
  5. Actual vs. Estimated rows in the execution plan
*******************************************************************/


-- Create a table to store performance metrics
CREATE TABLE PerformanceMetrics (
    RunID INT IDENTITY(1,1) PRIMARY KEY,
    RunDateTime DATETIME DEFAULT GETDATE(),
    QueryStep VARCHAR(100),
    LogicalReads BIGINT,
    LogicalWrites BIGINT,
    CPUBusy BIGINT,
    ElapsedTime BIGINT,
    RowsAffected BIGINT
);

-- Wrap each major step in the script with:
DECLARE @start_time DATETIME, @end_time DATETIME,
        @start_cpu_busy BIGINT, @end_cpu_busy BIGINT,
        @start_logical_reads BIGINT, @end_logical_reads BIGINT,
        @start_logical_writes BIGINT, @end_logical_writes BIGINT;

SELECT @start_time = GETDATE(), 
       @start_cpu_busy = @@CPU_BUSY, 
       @start_logical_reads = @@TOTAL_READ,
       @start_logical_writes = @@TOTAL_WRITE;

-- Your query step here

SELECT @end_time = GETDATE(), 
       @end_cpu_busy = @@CPU_BUSY, 
       @end_logical_reads = @@TOTAL_READ,
       @end_logical_writes = @@TOTAL_WRITE;

INSERT INTO PerformanceMetrics (
  QueryStep, 
  LogicalReads, 
  LogicalWrites,
  CPUBusy, 
  ElapsedTime, 
  RowsAffected)
VALUES (
    'Step Description',
    @end_logical_reads - @start_logical_reads,
    @end_logical_writes - @start_logical_writes,
    @end_cpu_busy - @start_cpu_busy,
    DATEDIFF(MILLISECOND, @start_time, @end_time),
    @@ROWCOUNT
);


/*******************************************************************
Example T-SQL to compare performance:
*******************************************************************/


SELECT 
    OriginalRun.QueryStep,
    OriginalRun.LogicalReads AS OriginalReads,
    OptimizedRun.LogicalReads AS OptimizedReads,
    OriginalRun.CPUBusy AS OriginalCPU,
    OptimizedRun.CPUBusy AS OptimizedCPU,
    OriginalRun.ElapsedTime AS OriginalElapsed,
    OptimizedRun.ElapsedTime AS OptimizedElapsed
FROM 
    PerformanceMetrics OriginalRun
JOIN 
    PerformanceMetrics OptimizedRun ON OriginalRun.QueryStep = OptimizedRun.QueryStep
WHERE 
    OriginalRun.RunID = @OriginalRunID
    AND OptimizedRun.RunID = @OptimizedRunID