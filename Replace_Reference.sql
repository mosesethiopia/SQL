USE DBName

	GO

	DECLARE @Id		int
		,	@sql	varchar(MAX)
		,	@error	varchar(26)
		,	@dropsql varchar(MAX)
		,	@setup	varchar(25)

	SET @setup ='edi_prod_update'

	BEGIN TRANSACTION  @setup

		IF OBJECT_ID('tempdb..#test') IS NOT NULL
			DROP TABLE #test 

		CREATE TABLE #test
			(
					sqls varchar(Max)
				,	Id int IDENTITY(1,1)
				,	Name sysname
				,	shema sysname
				,	sql_orginal varchar(MAX)
				,	dropsql varchar(MAX)
				,	flag int 
			)

		INSERT INTO #test
				(		Name
					,	sql_orginal 
					,	sqls
					,	shema
				)
		SELECT	o.name
			,	definition
			,	REPLACE(REPLACE(REPLACE(M.definition,'edi_prod.','edi_dvlp.'),'OIT-ORBIT','OIT-ZENITH'),'gfharms','gfharmsProd')
			,   SCHEMA_NAME(O.schema_id)
		FROM sys.all_sql_modules M
		JOIN sys.all_objects O ON O.object_id = M.object_id
		JOIN sys.procedures	p ON p.object_id = o.object_id
		WHERE (		definition LIKE '%edi_prod.%'
			OR 
				definition LIKE '%OIT-ORBIT%'
		
			)
			AND o.type ='P'
			AND definition NOT LIKE '%GARRU.%'

		SELECT @Id = MAX(Id)
		FROM #test

		WHILE @Id > 0

		BEGIN 
			SELECT  @sql = sqls,
					@dropsql = 'DROP PROCEDURE  '+	ISNULL(QUOTENAME(shema) + N'.', N'') +
																	QUOTENAME(Name) + N';'
			FROM #test
			WHERE ID = @Id

			UPDATE #test
				SET dropsql = @sql
					,sqls = sql_orginal
			WHERE ID = @Id


			EXEC (@dropsql)
			EXEC (@sql)


			UPDATE #test
				SET flag =1 
			WHERE Id = @Id

			SET @Id = @Id - 1
		END 


	COMMIT TRANSACTION @setup

	GO
