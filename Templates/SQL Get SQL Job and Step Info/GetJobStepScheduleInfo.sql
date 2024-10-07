
-- Main query to list SQL Server Agent jobs, stored procedures, and schedule details
SELECT
    jobs.name AS JobName,
    steps.database_name,
    steps.step_id AS StepID,
    steps.step_name AS StepName,
    steps.command AS Command,
    schedules.name AS ScheduleName,
    CASE schedules.freq_type
        WHEN 1 THEN 'One time'
        WHEN 4 THEN 'Daily'
        WHEN 8 THEN 'Weekly'
        WHEN 16 THEN 'Monthly'
        WHEN 32 THEN 'Monthly relative'
        WHEN 64 THEN 'When SQL Server Agent starts'
        WHEN 128 THEN 'Start whenever the CPU(s) become idle'
        ELSE 'Unknown'
    END AS FrequencyType,
    CASE schedules.freq_type
        WHEN 4 THEN CAST(schedules.freq_interval AS VARCHAR) + ' days'
        WHEN 8 THEN
            CASE
                WHEN schedules.freq_interval & 1 = 1 THEN 'Sunday '
                WHEN schedules.freq_interval & 2 = 2 THEN 'Monday '
                WHEN schedules.freq_interval & 4 = 4 THEN 'Tuesday '
                WHEN schedules.freq_interval & 8 = 8 THEN 'Wednesday '
                WHEN schedules.freq_interval & 16 = 16 THEN 'Thursday '
                WHEN schedules.freq_interval & 32 = 32 THEN 'Friday '
                WHEN schedules.freq_interval & 64 = 64 THEN 'Saturday '
                ELSE ''
            END
        WHEN 16 THEN 'Day ' + CAST(schedules.freq_interval AS VARCHAR)
        WHEN 32 THEN 
            CASE schedules.freq_relative_interval
                WHEN 1 THEN 'First '
                WHEN 2 THEN 'Second '
                WHEN 4 THEN 'Third '
                WHEN 8 THEN 'Fourth '
                WHEN 16 THEN 'Last '
                ELSE ''
            END + 
            CASE schedules.freq_interval
                WHEN 1 THEN 'Sunday'
                WHEN 2 THEN 'Monday'
                WHEN 3 THEN 'Tuesday'
                WHEN 4 THEN 'Wednesday'
                WHEN 5 THEN 'Thursday'
                WHEN 6 THEN 'Friday'
                WHEN 7 THEN 'Saturday'
                ELSE ''
            END
        ELSE 'N/A'
    END AS FrequencyInterval,
    schedules.active_start_date AS StartDate,
    RIGHT('0000' + CAST(schedules.active_start_time AS VARCHAR(6)), 6) AS StartTime
FROM
    msdb.dbo.sysjobs AS jobs
INNER JOIN
    msdb.dbo.sysjobsteps AS steps ON jobs.job_id = steps.job_id
INNER JOIN
    msdb.dbo.sysjobschedules AS jobschedules ON jobs.job_id = jobschedules.job_id
INNER JOIN
    msdb.dbo.sysschedules AS schedules ON jobschedules.schedule_id = schedules.schedule_id
WHERE
    steps.subsystem = 'TSQL'
    AND steps.command LIKE '%EXEC%'
ORDER BY
    jobs.name,
    steps.step_id;
