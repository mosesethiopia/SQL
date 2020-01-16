
DECLARE @is_active bit
	, @with_steps bit 
	, @isAR varchar(12)

SELECT @is_active = 1, @with_steps = 0, @isAR = 'Job Names Like'

SELECT 'Job Time'
SELECT	J.name job_name
	,	J.enabled job_enabled
	,	sysschedules.name schedule_name
	,	sysschedules.freq_recurrence_factor
	,	CASE
			WHEN freq_subday_type = 2 then ' every ' + CAST(freq_subday_interval AS varchar(7)) + ' seconds' + ' starting at '+ STUFF(STUFF(RIGHT(REPLICATE('0', 6) +  CAST(active_start_time as varchar(6)), 6), 3, 0, ':'), 6, 0, ':')
			WHEN freq_subday_type = 4 then ' every ' + cast(freq_subday_interval as varchar(7)) + ' minutes' + ' starting at '+ stuff(stuff(RIGHT(replicate('0', 6) +  cast(active_start_time as varchar(6)), 6), 3, 0, ':'), 6, 0, ':')
			WHEN freq_subday_type = 8 then ' every ' + cast(freq_subday_interval as varchar(7)) + ' hours'   + ' starting at '+ stuff(stuff(RIGHT(replicate('0', 6) +  cast(active_start_time as varchar(6)), 6), 3, 0, ':'), 6, 0, ':')
			ELSE ' starting at ' + STUFF(STUFF(RIGHT(replicate('0', 6) +  CAST(active_start_time as varchar(6)), 6), 3, 0, ':'), 6, 0, ':')
		END time
	,	CASE
		WHEN freq_type = 4 THEN 'Daily'	END frequency
	,	'every ' + cast (freq_interval as varchar(3)) + ' day(s)'  Days
FROM msdb.dbo.sysjobs AS J
JOIN msdb.dbo.sysjobschedules on j.job_id = sysjobschedules.job_id
JOIN msdb.dbo.sysschedules on sysjobschedules.schedule_id = sysschedules.schedule_id
WHERE freq_type = 4
ORDER BY time
		
SELECT	DISTINCT JO.name as 'JobName'
	,	HJ.run_date
	,	run_time
	,	msdb.dbo.agent_datetime(run_date, run_time) as 'RunDateTime'
FROM msdb.dbo.sysjobs JO
INNER JOIN msdb.dbo.sysjobhistory HJ ON JO.job_id = HJ.job_id 
WHERE JO.enabled = 1  
	AND msdb.dbo.agent_datetime(run_date, run_time)  BETWEEN DATEADD(MINUTE,-30,GETDATE()) AND GETDATE()
ORDER BY JobName, RunDateTime DESC

IF @with_steps = 1
BEGIN 
	SELECT	J.name	AS Job_Name
		,	J.[description] AS Job_Description
		,	SC.name AS Catagory_Name
		,	DP.name AS Job_Owner
		,	CASE
				WHEN freq_type = 8 then 'Weekly'
			END Frequency
		,	REPLACE(	CASE WHEN freq_interval&1 = 1	THEN 'Sunday, '		ELSE '' END
				+		CASE WHEN freq_interval&2 = 2	THEN 'Monday, '		ELSE '' END
				+		CASE WHEN freq_interval&4 = 4	THEN 'Tuesday, '	ELSE '' END
				+		CASE WHEN freq_interval&8 = 8	THEN 'Wednesday, '	ELSE '' END
				+		CASE WHEN freq_interval&16 = 16 THEN 'Thursday, '	ELSE '' END
				+		CASE WHEN freq_interval&32 = 32 THEN 'Friday, '		ELSE '' END
				+		CASE WHEN freq_interval&64 = 64 THEN 'Saturday, '	ELSE '' END
				,', ',',') Days
		,	CASE
				WHEN freq_subday_type = 2 then ' Every ' + cast(freq_subday_interval as varchar(7)) + ' Seconds' + ' starting at ' + stuff(stuff(RIGHT(replicate('0', 6) +  cast(active_start_time as varchar(6)), 6), 3, 0, ':'), 6, 0, ':') 
				WHEN freq_subday_type = 4 then ' Every ' + cast(freq_subday_interval as varchar(7))  + ' Minutes' + ' starting at ' + stuff(stuff(RIGHT(replicate('0', 6) +  cast(active_start_time as varchar(6)), 6), 3, 0, ':'), 6, 0, ':')
				WHEN freq_subday_type = 8 then ' Every ' + cast(freq_subday_interval as varchar(7))  + ' Hours'   + ' starting at ' + stuff(stuff(RIGHT(replicate('0', 6) +  cast(active_start_time as varchar(6)), 6), 3, 0, ':'), 6, 0, ':')
				ELSE ' starting at ' + stuff(stuff(RIGHT(replicate('0', 6) +  cast(active_start_time as varchar(6)), 6), 3, 0, ':'), 6, 0, ':')
			END Time_Line
		,	JS.step_name
		,	JS.command
		,	CASE 
				WHEN J.enabled	= 1 THEN 'Active'
				ELSE 'No-Active'
			END Job_Status
		,	CASE 
				WHEN JSC.schedule_id IS NULL THEN 'NO'
				ELSE 'YES'
			END is_Scheduled
		,	CASE 
				WHEN J.delete_level	= 0 THEN 'Never Deleted'
				WHEN J.delete_level = 1 THEN 'On Success'
				WHEN J.delete_level = 2 THEN 'On Failure'
				WHEN J.delete_level = 3 THEN 'On Completion'
			END Job_Deletion_Status	
	FROM msdb..sysjobs AS J
	LEFT JOIN msdb.sys.servers AS S ON J.originating_server_id = S.server_id
	LEFT JOIN msdb.dbo.syscategories AS SC ON SC.category_id = J.category_id
	LEFT JOIN msdb.dbo.sysjobsteps AS JS ON JS.job_id = J.job_id
	LEFT JOIN msdb.sys.database_principals AS DP ON DP.sid = J.owner_sid 
	LEFT JOIN msdb.dbo.sysjobschedules AS JSC ON J.job_id = JSC.job_id
	LEFT JOIN msdb.dbo.sysschedules AS SCH ON SCH.schedule_id = JSC.schedule_id 
	WHERE J.enabled = @is_active
		AND SC.name = COALESCE(@isAR,SC.name)
	ORDER BY SC.category_id DESC
END 
ELSE
	SELECT	J.name	AS Job_Name
		,	J.[description] AS Job_Description
		,	SC.name AS Catagory_Name
		,	DP.name AS Job_Owner
		,	CASE
				WHEN freq_type = 8 then 'Weekly'
			END Frequency
		,	REPLACE(	CASE WHEN freq_interval&1 = 1 THEN 'Sunday, ' ELSE '' END
				+	CASE WHEN freq_interval&2 = 2 THEN 'Monday, ' ELSE '' END
				+	CASE WHEN freq_interval&4 = 4 THEN 'Tuesday, ' ELSE '' END
				+	CASE WHEN freq_interval&8 = 8 THEN 'Wednesday, ' ELSE '' END
				+	CASE WHEN freq_interval&16 = 16 THEN 'Thursday, ' ELSE '' END
				+	CASE WHEN freq_interval&32 = 32 THEN 'Friday, ' ELSE '' END
				+	CASE WHEN freq_interval&64 = 64 THEN 'Saturday, ' ELSE '' END
				,', ',',') Days
		,	CASE
				WHEN freq_subday_type = 2 then ' every ' + cast(freq_subday_interval as varchar(7)) + ' seconds' + ' starting at ' + stuff(stuff(RIGHT(replicate('0', 6) +  cast(active_start_time as varchar(6)), 6), 3, 0, ':'), 6, 0, ':') 
				WHEN freq_subday_type = 4 then ' every ' + cast(freq_subday_interval as varchar(7))  + ' minutes' + ' starting at ' + stuff(stuff(RIGHT(replicate('0', 6) +  cast(active_start_time as varchar(6)), 6), 3, 0, ':'), 6, 0, ':')
				WHEN freq_subday_type = 8 then ' every ' + cast(freq_subday_interval as varchar(7))  + ' hours'   + ' starting at ' + stuff(stuff(RIGHT(replicate('0', 6) +  cast(active_start_time as varchar(6)), 6), 3, 0, ':'), 6, 0, ':')
				ELSE ' starting at ' + stuff(stuff(RIGHT(replicate('0', 6) +  cast(active_start_time as varchar(6)), 6), 3, 0, ':'), 6, 0, ':')
			END Time_Line
		,	CASE 
				WHEN J.enabled	= 1 THEN 'Active'
				ELSE 'No-Active'
			END Job_Status
		,	CASE 
				WHEN JSC.schedule_id IS NULL THEN 'NO'
				ELSE 'YES'
			END is_Scheduled
		,	CASE 
				WHEN J.delete_level	= 0 THEN 'Never Deleted'
				WHEN J.delete_level = 1 THEN 'On Success'
				WHEN J.delete_level = 2 THEN 'On Failure'
				WHEN J.delete_level = 3 THEN 'On Completion'
			END Job_Deletion_Status	
	FROM msdb..sysjobs AS J
	LEFT JOIN msdb.sys.servers AS S ON J.originating_server_id = S.server_id
	LEFT JOIN msdb.dbo.syscategories AS SC ON SC.category_id = J.category_id
	LEFT JOIN msdb.sys.database_principals AS DP ON DP.sid = J.owner_sid 
	LEFT JOIN msdb.dbo.sysjobschedules AS JSC ON J.job_id = JSC.job_id
	LEFT JOIN msdb.dbo.sysschedules AS SCH ON SCH.schedule_id = JSC.schedule_id 
	WHERE J.enabled = @is_active
		AND SC.name = COALESCE(@isAR,SC.name)
	ORDER BY SC.category_id DESC

