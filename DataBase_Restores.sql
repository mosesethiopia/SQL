	;WITH DB_Restores
	AS
	(
		SELECT	[d].[name] AS DatabaseName
			,	[d].[create_date] 
			,	r.restore_date
			,	r.restore_type
			,	r.user_name
			,	[d].[compatibility_level] 
			,	[d].[collation_name] 
			,	ROW_NUMBER() OVER (PARTITION BY d.Name ORDER BY r.[restore_date] DESC) AS RowNum
	FROM master.sys.databases d
	LEFT OUTER JOIN msdb.dbo.[restorehistory] r ON r.[destination_database_name] = d.Name
	)
	SELECT DB_Restores.DatabaseName
		,	DB_Restores.create_date
		,	DB_Restores.restore_date
		,	DB_Restores.restore_type
		,	DB_Restores.user_name
		,	DB_Restores.compatibility_level
		,	DB_Restores.collation_name
	FROM DB_Restores
	WHERE [RowNum] = 1
	ORDER BY DB_Restores.restore_date DESC
