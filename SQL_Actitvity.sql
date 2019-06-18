SELECT	DES.host_name
		,	DES.program_name
		,	DES.client_version
		,	DES.login_name
		,	DES.login_time
		,	DES.last_request_start_time
		,	DES.last_request_end_time
		,	DES.status
		,	DES.memory_usage
		,	DES.cpu_time
		,	DEST.text
		,	DB_NAME(DEST.dbid) db_named	 
	FROM sys.dm_exec_sessions AS DES
	--CROSS APPLY sys.dm_exec_inputbuffer(DES.session_id,0) AS InBuff --(only avaliable on 2016 )
	JOIN sys.dm_exec_connections AS DEC ON DEC.session_id = DES.session_id
	CROSS APPLY sys.dm_exec_sql_text(DEC.most_recent_sql_handle) AS DEST
	
