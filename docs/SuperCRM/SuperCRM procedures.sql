CREATE procedure [dbo].[AzureSQLMaintenance]
	(
		@operation nvarchar(10) = null,
		@mode nvarchar(10) = 'smart',
		@ResumableIndexRebuild bit = 0,
		@RebuildHeaps bit = 0,
		@LogToTable bit = 0,
		@debug nvarchar = 'none'
	)
as
begin
	set nocount on;
	SET ANSI_WARNINGS OFF;
	
	---------------------------------------------
	--- Varialbles and pre conditions check
	---------------------------------------------

	set quoted_identifier on;
	declare @idxIdentifierBegin char(1), @idxIdentifierEnd char(1);
	declare @statsIdentifierBegin char(1), @statsIdentifierEnd char(1);
	
	declare @msg nvarchar(max);
	declare @minPageCountForIndex int = 40;
	declare @OperationTime datetime2 = sysdatetime();
	declare @KeepXOperationInLog int =3;
	declare @ScriptHasAnError int = 0; 
	declare @ResumableIndexRebuildSupported int;
	declare @indexStatsMode sysname;

	/* make sure parameters selected correctly */
	set @operation = lower(@operation)
	set @mode = lower(@mode)
	set @debug = lower(@debug) /* any value at this time will produce the temp tables as permanent tables */
	
	if @mode not in ('smart','dummy')
		set @mode = 'smart'

	---------------------------------------------
	--- Begin
	---------------------------------------------

	if @operation not in ('index','statistics','all') or @operation is null
	begin
		raiserror('@operation (varchar(10)) [mandatory]',0,0)
		raiserror(' Select operation to perform:',0,0)
		raiserror('     "index" to perform index maintenance',0,0)
		raiserror('     "statistics" to perform statistics maintenance',0,0)
		raiserror('     "all" to perform indexes and statistics maintenance',0,0)
		raiserror(' ',0,0)
		raiserror('@mode(varchar(10)) [optional]',0,0)
		raiserror(' optionaly you can supply second parameter for operation mode: ',0,0)
		raiserror('     "smart" (Default) using smart decision about what index or stats should be touched.',0,0)
		raiserror('     "dummy" going through all indexes and statistics regardless thier modifications or fragmentation.',0,0)
		raiserror(' ',0,0)
		raiserror('@ResumableIndexRebuild(bit) [optional]',0,0)
		raiserror(' optionaly you can choose to rebuild indexes as resumable operation: ',0,0)
		raiserror('     "0" (Default) using non resumable index rebuild.',0,0)
		raiserror('     "1" using resumable index rebuild when it is supported.',0,0)
		raiserror(' ',0,0)
		raiserror('@RebuildHeaps(bit) [optional]',0,0)
		raiserror(' Logging option: @LogToTable(bit)',0,0)
		raiserror('     0 - (Default) do not log operation to table',0,0)
		raiserror('     1 - log operation to table',0,0)
		raiserror('		for logging option only 3 last execution will be kept by default. this can be changed by easily in the procedure body.',0,0)
		raiserror('		Log table will be created automatically if not exists.',0,0)
		raiserror(' ',0,0)
		raiserror('@LogToTable(bit) [optional]',0,0)
		raiserror(' Rebuild HEAPS to fix forwarded records issue on tables with no clustered index',0,0)
		raiserror('     0 - (Default) do not rebuild heaps',0,0)
		raiserror('     1 - Rebuild heaps based on @mode parameter, @mode=dummy will rebuild all heaps',0,0)
		raiserror(' ',0,0)
		raiserror('Example:',0,0)
		raiserror('		exec  AzureSQLMaintenance ''all'', @LogToTable=1',0,0)

	end
	else 
	begin
		
		---------------------------------------------
		--- Prepare log table
		---------------------------------------------

		/* Prepare Log Table */
		if object_id('AzureSQLMaintenanceLog') is null and @LogToTable=1
		begin
			create table AzureSQLMaintenanceLog (id bigint primary key identity(1,1), OperationTime datetime2, command varchar(4000),ExtraInfo varchar(4000), StartTime datetime2, EndTime datetime2, StatusMessage varchar(1000));
		end

		---------------------------------------------
		--- Resume operation
		---------------------------------------------

		/*Check is there is operation to resume*/
		if OBJECT_ID('AzureSQLMaintenanceCMDQueue') is not null 
		begin
			if 
				/*resume information exists*/ exists(select * from AzureSQLMaintenanceCMDQueue where ID=-1) 
			begin
				/*resume operation confirmed*/
				set @operation='resume' -- set operation to resume, this can only be done by the proc, cannot get this value as parameter

				-- restore operation parameters 
				select top 1
				@LogToTable = JSON_VALUE(ExtraInfo,'$.LogToTable')
				,@mode = JSON_VALUE(ExtraInfo,'$.mode')
				,@ResumableIndexRebuild = JSON_VALUE(ExtraInfo,'$.ResumableIndexRebuild')
				from AzureSQLMaintenanceCMDQueue 
				where ID=-1
				
				raiserror('-----------------------',0,0)
				set @msg = 'Resuming previous operation'
				raiserror(@msg,0,0)
				raiserror('-----------------------',0,0)
			end
			else
				begin
					-- table [AzureSQLMaintenanceCMDQueue] exist but resume information does not exists
					-- this might happen in case execution intrupted between collecting index & ststistics information and executing commands.
					-- to fix that we drop the table now, it will be recreated later 
					DROP TABLE [AzureSQLMaintenanceCMDQueue];
				end
		end


		---------------------------------------------
		--- Report operation parameters
		---------------------------------------------
		
		/*Write operation parameters*/
		raiserror('-----------------------',0,0)
		set @msg = 'set operation = ' + @operation;
		raiserror(@msg,0,0)
		set @msg = 'set mode = ' + @mode;
		raiserror(@msg,0,0)
		set @msg = 'set ResumableIndexRebuild = ' + cast(@ResumableIndexRebuild as varchar(1));
		raiserror(@msg,0,0)
		set @msg = 'set RebuildHeaps = ' + cast(@RebuildHeaps as varchar(1));
		raiserror(@msg,0,0)
		set @msg = 'set LogToTable = ' + cast(@LogToTable as varchar(1));
		raiserror(@msg,0,0)
		raiserror('-----------------------',0,0)
	end

	if @LogToTable=1 insert into AzureSQLMaintenanceLog values(@OperationTime,null,null,sysdatetime(),sysdatetime(),'Starting operation: Operation=' +@operation + ' Mode=' + @mode + ' Keep log for last ' + cast(@KeepXOperationInLog as varchar(10)) + ' operations' )	

	-- create command queue table, if there table exits then we resume operation in earlier stage.
	if @operation!='resume'
		create table AzureSQLMaintenanceCMDQueue (ID int identity primary key,txtCMD nvarchar(max),ExtraInfo varchar(max))

	---------------------------------------------
	--- Check if engine support resumable index operation
	---------------------------------------------
	if @ResumableIndexRebuild=1 
	begin
		if cast(SERVERPROPERTY('EngineEdition')as int)>=5 or cast(SERVERPROPERTY('ProductMajorVersion')as int)>=14
		begin
			set @ResumableIndexRebuildSupported=1;
		end
		else
		begin 
				set @ResumableIndexRebuildSupported=0;
				set @msg = 'Resumable index rebuild is not supported on this database'
				raiserror(@msg,0,0)
				if @LogToTable=1 insert into AzureSQLMaintenanceLog values(@OperationTime,null,null,sysdatetime(),sysdatetime(),@msg)	
		end
	end


	---------------------------------------------
	--- Index maintenance
	---------------------------------------------
	if @operation in('index','all')
	begin
		/**/
		if @mode='smart' and @RebuildHeaps=1 
			set @indexStatsMode = 'SAMPLED'
		else
			set @indexStatsMode = 'LIMITED'
	
		raiserror('Get index information...(wait)',0,0) with nowait;
		/* Get Index Information */
		select 
			i.[object_id]
			,ObjectSchema = OBJECT_SCHEMA_NAME(idxs.object_id)
			,ObjectName = object_name(idxs.object_id) 
			,IndexName = idxs.name
			,idxs.type
			,idxs.type_desc
			,i.avg_fragmentation_in_percent
			,i.page_count
			,i.index_id
			,i.partition_number
			,i.avg_page_space_used_in_percent
			,i.record_count
			,i.ghost_record_count
			,i.forwarded_record_count
			,null as OnlineOpIsNotSupported
			,null as ObjectDoesNotSupportResumableOperation
			,0 as SkipIndex
			,replicate('',128) as SkipReason
		into #idxBefore
		from sys.indexes idxs
		left join sys.dm_db_index_physical_stats(DB_ID(),NULL, NULL, NULL ,@indexStatsMode) i  on i.object_id = idxs.object_id and i.index_id = idxs.index_id
		where idxs.type in (0 /*HEAP*/,1/*CLUSTERED*/,2/*NONCLUSTERED*/,5/*CLUSTERED COLUMNSTORE*/,6/*NONCLUSTERED COLUMNSTORE*/) 
		and (alloc_unit_type_desc = 'IN_ROW_DATA' /*avoid LOB_DATA or ROW_OVERFLOW_DATA*/ or alloc_unit_type_desc is null /*for ColumnStore indexes*/)
		and OBJECT_SCHEMA_NAME(idxs.object_id) != 'sys'
		and idxs.is_disabled=0
		order by i.avg_fragmentation_in_percent desc, i.page_count desc
				
		-- mark indexes XML,spatial and columnstore not to run online update 
		update #idxBefore set OnlineOpIsNotSupported=1 where [object_id] in (select [object_id] from #idxBefore where [type]=3 /*XML Indexes*/)

		-- mark clustered indexes for tables with 'text','ntext','image' to rebuild offline
		update #idxBefore set OnlineOpIsNotSupported=1 
		where index_id=1 /*clustered*/ and [object_id] in (
			select object_id
			from sys.columns c join sys.types t on c.user_type_id = t.user_type_id
			where t.name in ('text','ntext','image')
		)
	
		-- do all as offline for box edition that does not support online
		update #idxBefore set OnlineOpIsNotSupported=1  
			where /* Editions that does not support online operation in case this has been used with on-prem server */
				convert(varchar(100),serverproperty('Edition')) like '%Express%' 
				or convert(varchar(100),serverproperty('Edition')) like '%Standard%'
				or convert(varchar(100),serverproperty('Edition')) like '%Web%'
		
		-- Do non resumable operation when index contains computed column or timestamp data type
		update idx set ObjectDoesNotSupportResumableOperation=1
		from #idxBefore idx join sys.index_columns ic on idx.object_id = ic.object_id and idx.index_id=ic.index_id
		join sys.columns c on ic.object_id=c.object_id and ic.column_id=c.column_id
		where c.is_computed=1 or system_type_id=189 /*TimeStamp column*/
		
		-- set SkipIndex=1 if conditions for maintenance are not met
		-- this is used to idntify is stats need to be updated or not. 
		update #idxBefore set SkipIndex=1,SkipReason='Maintenance is not needed'
		where (
					-- these are the condition when to skip index maintenance
					page_count> @minPageCountForIndex  /* not small tables */
					and
					avg_fragmentation_in_percent< 5 /* Less than 5% of fragmentation */
				)
				and @mode != 'dummy' /*for Dummy mode we do not want to skip anything */
		
		-- Skip columnstore indexes
		update #idxBefore set SkipIndex=1,SkipReason='Columnstore index'
		where (
					type in (
								5/*Clustered columnstore index*/,
								6/*Nonclustered columnstore index*/
							)
				)
				and @mode != 'dummy' /*for Dummy mode we do not want to skip anything */

		raiserror('---------------------------------------',0,0) with nowait
		raiserror('Index Information:',0,0) with nowait
		raiserror('---------------------------------------',0,0) with nowait

		select @msg = count(*) from #idxBefore 
		set @msg = 'Total Indexes: ' + @msg
		raiserror(@msg,0,0) with nowait

		select @msg = avg(avg_fragmentation_in_percent) from #idxBefore where page_count>@minPageCountForIndex
		set @msg = 'Average Fragmentation: ' + @msg
		raiserror(@msg,0,0) with nowait

		select @msg = sum(iif(avg_fragmentation_in_percent>=5 and page_count>@minPageCountForIndex,1,0)) from #idxBefore 
		set @msg = 'Fragmented Indexes: ' + @msg
		raiserror(@msg,0,0) with nowait

				
		raiserror('---------------------------------------',0,0) with nowait


		/* Choose the identifier to be used based on existing object name 
			this came up from object that contains '[' within the object name
			such as "EPK[export].[win_sourceofwealthbpf]" as index name
			if we use '[' as identifier it will cause wrong identifier name	
		*/
		if exists(
			select 1
			from #idxBefore 
			where IndexName like '%[%' or IndexName like '%]%'
			or ObjectSchema like '%[%' or ObjectSchema like '%]%'
			or ObjectName like '%[%' or ObjectName like '%]%'
			)
		begin
			set @idxIdentifierBegin = '"'
			set @idxIdentifierEnd = '"'
		end
		else 
		begin
			set @idxIdentifierBegin = '['
			set @idxIdentifierEnd = ']'
		end

			
		/* create queue for indexes */
		insert into AzureSQLMaintenanceCMDQueue(txtCMD,ExtraInfo)
		select 
		txtCMD = 'ALTER INDEX ' + @idxIdentifierBegin + IndexName + @idxIdentifierEnd + ' ON '+ @idxIdentifierBegin + ObjectSchema + @idxIdentifierEnd +'.'+ @idxIdentifierBegin + ObjectName + @idxIdentifierEnd + ' ' +
		case when (
					avg_fragmentation_in_percent>5 and avg_fragmentation_in_percent<30 and @mode = 'smart')/* index fragmentation condition */ 
					or 
					(@mode='dummy' and type in (5,6)/* Columnstore indexes in dummy mode -> reorganize them */
				) then
			 'REORGANIZE;'
			when OnlineOpIsNotSupported=1 then
			'REBUILD WITH(ONLINE=OFF,MAXDOP=1);'
			when ObjectDoesNotSupportResumableOperation=1 or @ResumableIndexRebuildSupported=0 or @ResumableIndexRebuild=0 then
			'REBUILD WITH(ONLINE=ON,MAXDOP=1);'
			else
			'REBUILD WITH(ONLINE=ON,MAXDOP=1, RESUMABLE=ON);'
		end
		, ExtraInfo = 
			case when type in (5,6) then
				'Dummy mode, reorganize columnstore indexes'
			else 
				'Current fragmentation: ' + format(avg_fragmentation_in_percent/100,'p')+ ' with ' + cast(page_count as nvarchar(20)) + ' pages'
			end
		from #idxBefore
		where SkipIndex=0 and type != 0 /*Avoid HEAPS*/


		---------------------------------------------
		--- Index - Heaps 
		---------------------------------------------

		/* create queue for heaps */
		if @RebuildHeaps=1 
		begin
			insert into AzureSQLMaintenanceCMDQueue(txtCMD,ExtraInfo)
			select 
			txtCMD = 'ALTER TABLE ' + @idxIdentifierBegin + ObjectSchema + @idxIdentifierEnd +'.'+ @idxIdentifierBegin + ObjectName + @idxIdentifierEnd + ' REBUILD;' 
			, ExtraInfo = 'Rebuilding heap - forwarded records ' + cast(forwarded_record_count as varchar(100)) + ' out of ' + cast(record_count as varchar(100)) + ' record in the table'
			from #idxBefore
			where
				type = 0 /*heaps*/
				and 
					(
						@mode='dummy' 
						or 
						(forwarded_record_count/record_count>0.3) /* 30% of record count */
						or
						(forwarded_record_count>105000) /* for tables with > 350K rows dont wait for 30%, just run yje maintenance once we reach the 100K forwarded records */
					)
		end /* create queue for heaps */
	end



	---------------------------------------------
	--- Statistics maintenance
	---------------------------------------------

	if @operation in('statistics','all')
	begin 
		/*Gets Stats for database*/
		raiserror('Get statistics information...',0,0) with nowait;
		select 
			ObjectSchema = OBJECT_SCHEMA_NAME(s.object_id)
			,ObjectName = object_name(s.object_id) 
			,s.object_id
			,s.stats_id
			,StatsName = s.name
			,sp.last_updated
			,sp.rows
			,sp.rows_sampled
			,sp.modification_counter
			, i.type
			, i.type_desc
			,0 as SkipStatistics
		into #statsBefore
		from sys.stats s cross apply sys.dm_db_stats_properties(s.object_id,s.stats_id) sp 
		left join sys.indexes i on sp.object_id = i.object_id and sp.stats_id = i.index_id
		where OBJECT_SCHEMA_NAME(s.object_id) != 'sys' and /*Modified stats or Dummy mode*/(isnull(sp.modification_counter,0)>=0 or @mode='dummy')
		order by sp.last_updated asc

		/*Remove statistics if it is handled by index rebuild / reorginize 
		I am removing statistics based on existance on the index in the list because for indexes with <5% changes we do not apply
		any action - therefore we might decide to update statistics */
		if @operation= 'all'
		update _stats set SkipStatistics=1 
			from #statsBefore _stats
			join #idxBefore _idx
			on _idx.ObjectSchema = _stats.ObjectSchema
			and _idx.ObjectName = _stats.ObjectName
			and _idx.IndexName = _stats.StatsName 
			where _idx.SkipIndex=0

		/*Skip statistics for Columnstore indexes*/
		update #statsBefore set SkipStatistics=1
		where type in (5,6) /*Column store indexes*/

		/*Skip statistics if resumable operation is pause on the same object*/
		if @ResumableIndexRebuildSupported=1
		begin
			update _stats set SkipStatistics=1
			from #statsBefore _stats join sys.index_resumable_operations iro on _stats.object_id=iro.object_id and _stats.stats_id=iro.index_id
		end
		
		raiserror('---------------------------------------',0,0) with nowait
		raiserror('Statistics Information:',0,0) with nowait
		raiserror('---------------------------------------',0,0) with nowait

		select @msg = sum(modification_counter) from #statsBefore
		set @msg = 'Total Modifications: ' + @msg
		raiserror(@msg,0,0) with nowait
		
		select @msg = sum(iif(modification_counter>0,1,0)) from #statsBefore
		set @msg = 'Modified Statistics: ' + @msg
		raiserror(@msg,0,0) with nowait
				
		raiserror('---------------------------------------',0,0) with nowait

		/* Choose the identifier to be used based on existing object name */
		if exists(
			select 1
			from #statsBefore 
			where StatsName like '%[%' or StatsName like '%]%'
			or ObjectSchema like '%[%' or ObjectSchema like '%]%'
			or ObjectName like '%[%' or ObjectName like '%]%'
			)
		begin
			set @statsIdentifierBegin = '"'
			set @statsIdentifierEnd = '"'
		end
		else 
		begin
			set @statsIdentifierBegin = '['
			set @statsIdentifierEnd = ']'
		end
		
		/* create queue for update stats */
		insert into AzureSQLMaintenanceCMDQueue(txtCMD,ExtraInfo)
		select 
		txtCMD = 'UPDATE STATISTICS '+ @statsIdentifierBegin + ObjectSchema + +@statsIdentifierEnd + '.'+@statsIdentifierBegin + ObjectName + @statsIdentifierEnd +' (' + @statsIdentifierBegin + StatsName + @statsIdentifierEnd + ') WITH FULLSCAN;'
		, ExtraInfo = '#rows:' + cast([rows] as varchar(100)) + ' #modifications:' + cast(modification_counter as varchar(100)) + ' modification percent: ' + format((1.0 * modification_counter/ rows ),'p')
		from #statsBefore
		where SkipStatistics=0;
	end

	if @operation in('statistics','index','all','resume')
	begin

		declare @SQLCMD nvarchar(max);
		declare @ID int;
		declare @ExtraInfo nvarchar(max);
	
		/*Print debug information in case debug is activated */
		if @debug!='None'
		begin
			drop table if exists idxBefore
			drop table if exists statsBefore
			drop table if exists cmdQueue
			if object_id('tempdb..#idxBefore') is not null select * into idxBefore from #idxBefore
			if object_id('tempdb..#statsBefore') is not null select * into statsBefore from #statsBefore
			if object_id('tempdb..AzureSQLMaintenanceCMDQueue') is not null select * into cmdQueue from AzureSQLMaintenanceCMDQueue
		end

		/*Save current execution parameters in case resume is needed */
		if @operation!='resume'
		begin
			set @ExtraInfo = (select top 1 LogToTable = @LogToTable, operation=@operation, operationTime=@OperationTime, mode=@mode, ResumableIndexRebuild = @ResumableIndexRebuild from sys.tables for JSON path, WITHOUT_ARRAY_WRAPPER)
			set identity_insert AzureSQLMaintenanceCMDQueue on
			insert into AzureSQLMaintenanceCMDQueue(ID,txtCMD,ExtraInfo) values(-1,'parameters to be used by resume code path',@ExtraInfo)
			set identity_insert AzureSQLMaintenanceCMDQueue off
		end
	
		---------------------------------------------
		--- Executing commands
		---------------------------------------------
		/*
		needed to rebuild indexes on comuted columns
		if ANSI_WARNINGS is set to OFF we might get the followin exception:
			Msg 1934, Level 16, State 1, Line 2
			ALTER INDEX failed because the following SET options have incorrect settings: 'ANSI_WARNINGS'. Verify that SET options are correct for use with indexed views and/or indexes on computed columns and/or filtered indexes and/or query notifications and/or XML data type methods and/or spatial index operations.
		*/
		SET ANSI_WARNINGS ON;

		raiserror('Start executing commands...',0,0) with nowait
		declare @T table(ID int, txtCMD nvarchar(max),ExtraInfo nvarchar(max));
		while exists(select * from AzureSQLMaintenanceCMDQueue where ID>0)
		begin
			update top (1) AzureSQLMaintenanceCMDQueue set txtCMD=txtCMD output deleted.* into @T where ID>0;
			select top (1) @ID = ID, @SQLCMD = txtCMD, @ExtraInfo=ExtraInfo from @T
			raiserror(@SQLCMD,0,0) with nowait
			if @LogToTable=1 insert into AzureSQLMaintenanceLog values(@OperationTime,@SQLCMD,@ExtraInfo,sysdatetime(),null,'Started')
			begin try
				exec(@SQLCMD)	
				if @LogToTable=1 update AzureSQLMaintenanceLog set EndTime = sysdatetime(), StatusMessage = 'Succeeded' where id=SCOPE_IDENTITY()
			end try
			begin catch
				set @ScriptHasAnError=1;
				set @msg = 'FAILED : ' + CAST(ERROR_NUMBER() AS VARCHAR(50)) + ERROR_MESSAGE();
				raiserror(@msg,0,0) with nowait
				if @LogToTable=1 update AzureSQLMaintenanceLog set EndTime = sysdatetime(), StatusMessage = @msg where id=SCOPE_IDENTITY()
			end catch
			delete from AzureSQLMaintenanceCMDQueue where ID = @ID;
			delete from @T
		end
		drop table AzureSQLMaintenanceCMDQueue;
	end
	
	---------------------------------------------
	--- Clean old records from log table
	---------------------------------------------
	if @LogToTable=1
	begin
		delete from AzureSQLMaintenanceLog 
		from 
			AzureSQLMaintenanceLog L join 
			(select distinct OperationTime from AzureSQLMaintenanceLog order by OperationTime desc offset @KeepXOperationInLog rows) F
				ON L.OperationTime = F.OperationTime
		insert into AzureSQLMaintenanceLog values(@OperationTime,null,cast(@@rowcount as varchar(100))+ ' rows purged from log table because number of operations to keep is set to: ' + cast( @KeepXOperationInLog as varchar(100)),sysdatetime(),sysdatetime(),'Cleanup Log Table')
	end

	if @ScriptHasAnError=0 	raiserror('Done',0,0)
	if @LogToTable=1 insert into AzureSQLMaintenanceLog values(@OperationTime,null,null,sysdatetime(),sysdatetime(),'End of operation')
	if @ScriptHasAnError=1 	raiserror('Script has errors - please review the log.',16,1)
end;

-- =============================================
-- Author:      <Author, , Name>
-- Create Date: <Create Date, , >
-- Description: <Description, , >
-- =============================================
CREATE FUNCTION [dbo].[CountInteracoesAtendimentosComVenda]
(
    @ContaSistemaId int,
	@mes int,
	@ano int
)
RETURNS int
AS
BEGIN

    -- Declare the return variable here
    DECLARE @iTotal int

	SET		@iTotal =	(
							select	avg(total) as MediaSemVendas
							from	(
										select	count(idInteracaoTipo) as total
										from	v_dashboards_interacoes as t1 with(nolock)
										where	t1.ContaSistemaId = 3 and
												MONTH(t1.DtInteracaoInclusao) = @mes and
												YEAR(t1.DtInteracaoInclusao) = @ano and
												exists	(
																select 1
																from	v_dashboards_interacoes as t2 with(nolock)
																where	t2.ContaSistemaId = 3 and
																		t1.AtendimentoCodigo = t2.AtendimentoCodigo and
																		t2.InteracaoTipoNome = 'Negociação (Venda)'
															)
										group by AtendimentoCodigo
									) as media
						)

	IF (@iTotal is null) BEGIN
		SET @iTotal = 0
	END

    -- Return the result of the function
    RETURN	@iTotal
END;

-- =============================================
-- Author:      <Author, , Name>
-- Create Date: <Create Date, , >
-- Description: <Description, , >
-- =============================================
CREATE FUNCTION [dbo].[CountInteracoesAtendimentosSemVenda]
(
    @ContaSistemaId int,
	@mes int,
	@ano int
)
RETURNS int
AS
BEGIN

    -- Declare the return variable here
    DECLARE @iTotal int

	SET		@iTotal =	(
							select	avg(total) as MediaSemVendas
							from	(
										select	count(idInteracaoTipo) as total
										from	v_dashboards_interacoes as t1 with(nolock)
										where	t1.ContaSistemaId = 3 and
												-- t1.UsuarioContaSistemaIncluiuId = @UsuarioContaSistemaIncluiuId and
												-- t1.IdInteracaoTipo = @IdInteracaoTipo and
												MONTH(t1.DtInteracaoInclusao) = @mes and
												YEAR(t1.DtInteracaoInclusao) = @ano and
												not exists	(
																select 1
																from	v_dashboards_interacoes as t2 with(nolock)
																where	t2.ContaSistemaId = 3 and
																		t1.AtendimentoCodigo = t2.AtendimentoCodigo and
																		t2.InteracaoTipoNome = 'Negociação (Venda)'
															)
										group by AtendimentoCodigo
									) as media
						)

	IF (@iTotal is null) BEGIN
		SET @iTotal = 0
	END

    -- Return the result of the function
    RETURN	@iTotal
END;

-- repassado data inicial e final irá retornar o formato dd:hr:min:ss
CREATE function [dbo].[DATEDIFFCustom](@dtInicial datetime, @dtFinal datetime)
RETURNS varchar(200)
begin

	declare @ret varchar(200);

	if @dtInicial is not null and @dtFinal is not null
		begin
			set @ret = (select 	
			CAST(DATEDIFF(SECOND, @dtInicial, @dtFinal) / 86400 as varchar) + ':' + -- dia
			CAST((DATEDIFF(SECOND, @dtInicial, @dtFinal) % 86400) / 3600 as varchar) + ':' + -- horas
			CAST(((DATEDIFF(SECOND, @dtInicial, @dtFinal) % 86400) % 3600) / 60 as varchar) + ':' + -- minutos
			CAST(((DATEDIFF(SECOND, @dtInicial, @dtFinal) % 86400) % 3600) % 60 as varchar) ) -- segundos
		end


    return @ret;
end;

CREATE function dbo.fn_diagramobjects() 
	RETURNS int
	WITH EXECUTE AS N'dbo'
	AS
	BEGIN
		declare @id_upgraddiagrams		int
		declare @id_sysdiagrams			int
		declare @id_helpdiagrams		int
		declare @id_helpdiagramdefinition	int
		declare @id_creatediagram	int
		declare @id_renamediagram	int
		declare @id_alterdiagram 	int 
		declare @id_dropdiagram		int
		declare @InstalledObjects	int

		select @InstalledObjects = 0

		select 	@id_upgraddiagrams = object_id(N'dbo.sp_upgraddiagrams'),
			@id_sysdiagrams = object_id(N'dbo.sysdiagrams'),
			@id_helpdiagrams = object_id(N'dbo.sp_helpdiagrams'),
			@id_helpdiagramdefinition = object_id(N'dbo.sp_helpdiagramdefinition'),
			@id_creatediagram = object_id(N'dbo.sp_creatediagram'),
			@id_renamediagram = object_id(N'dbo.sp_renamediagram'),
			@id_alterdiagram = object_id(N'dbo.sp_alterdiagram'), 
			@id_dropdiagram = object_id(N'dbo.sp_dropdiagram')

		if @id_upgraddiagrams is not null
			select @InstalledObjects = @InstalledObjects + 1
		if @id_sysdiagrams is not null
			select @InstalledObjects = @InstalledObjects + 2
		if @id_helpdiagrams is not null
			select @InstalledObjects = @InstalledObjects + 4
		if @id_helpdiagramdefinition is not null
			select @InstalledObjects = @InstalledObjects + 8
		if @id_creatediagram is not null
			select @InstalledObjects = @InstalledObjects + 16
		if @id_renamediagram is not null
			select @InstalledObjects = @InstalledObjects + 32
		if @id_alterdiagram  is not null
			select @InstalledObjects = @InstalledObjects + 64
		if @id_dropdiagram is not null
			select @InstalledObjects = @InstalledObjects + 128
		
		return @InstalledObjects 
	END;

CREATE function [dbo].[function_dashboards_atendimentos] (@ContaSistema INT, @DtInicio date,@DtFim date)
RETURNS TABLE
AS
RETURN(
SELECT 
	TabelaoAtendimento.ContaSistemaId, 
	TabelaoAtendimento.AtendimentoId AS AtendimentoCodigo, 
	TabelaoAtendimento.AtendimentoDtInclusao, 
	TabelaoAtendimento.AtendimentoDtInicio,
	TabelaoAtendimento.AtendimentoDtConclusao, 
	TabelaoAtendimento.AtendimentoStatus, 
	TabelaoAtendimento.AtendimentoConvercaoVenda,
	TabelaoAtendimento.AtendimentoConvercaoVendaComputado,
	TabelaoAtendimento.AtendimentoNegociacaoStatus  AS PerdidoOuGanho,
	TabelaoAtendimento.AtendimentoValorNegocio,
	TabelaoAtendimento.AtendimentoComissaoNegocio,
	TabelaoAtendimento.AtendimentoTipoDirecionamento,
	TabelaoAtendimento.AtendimentoQtdDiasSemInteracao,
	TabelaoAtendimento.GrupoId, 
	TabelaoAtendimento.GrupoNome, 
	TabelaoAtendimento.UsuarioContaSistemaId AS UsuarioContaSistemaAtendendoId, 
	TabelaoAtendimento.PessoaNome AS UsuarioContaSistemaAtendendoNome,  
	TabelaoAtendimento.PessoaApelido AS UsuarioContaSistemaAtendendoApelido, 
	TabelaoAtendimento.CriouAtendimentoUsuarioContaSistemaId AS UsuarioContaSistemaIdCriouAtendimento, 
	TabelaoAtendimento.CriouAtendimentoPessoaNome AS UsuarioContaSistemaNomeCriouAtendimento, 
	TabelaoAtendimento.ClassificacaoId AS ClassificacaoFaseId, 
	TabelaoAtendimento.ClassificacaoValor AS ClassificacaoFaseNome,
	TabelaoAtendimento.ClassificacaoValor2  AS ClassificacaoGrupoNome, 
	TabelaoAtendimento.AtendimentoIdMotivacaoNaoConversaoVenda AS MotivacaoNaoConversaoVendaId, 
	TabelaoAtendimento.AtendimentoMotivacaoNaoConversaoVenda AS MotivacaoNaoConversaoVendaNome,
	TabelaoAtendimento.ProdutoId,
	TabelaoAtendimento.ProdutoNome, 
	TabelaoAtendimento.ProdutoUF,
	TabelaoAtendimento.CampanhaId, 
	TabelaoAtendimento.CampanhaNome, 
	TabelaoAtendimento.CanalId, 
	TabelaoAtendimento.CanalNome,
	TabelaoAtendimento.CanalMeio, 
	TabelaoAtendimento.MidiaId, 
	TabelaoAtendimento.MidiaNome,
	TabelaoAtendimento.MidiaTipoValor, 
	TabelaoAtendimento.PecaId, 
	TabelaoAtendimento.PecaNome, 
	TabelaoAtendimento.CampanhaMarketingId, 
	TabelaoAtendimento.CampanhaMarketingNome,
	TabelaoAtendimento.GrupoPecaMarketingId, 
	TabelaoAtendimento.GrupoPecaMarketingNome, 
	TabelaoAtendimento.IntegradoraExternaId, 
	TabelaoAtendimento.IntegradoraExternaNome
FROM TabelaoAtendimento WITH(NOLOCK)
WHERE TabelaoAtendimento.ContaSistemaId = @ContaSistema
AND TabelaoAtendimento.AtendimentoDtInclusao between @DtInicio and @DtFim
);

CREATE function [dbo].[function_dashboards_interacoes] (@ContaSistema INT, @DtInicio date,@DtFim date)
RETURNS TABLE
AS
RETURN(
SELECT 
	TabelaoInteracaoResumo.IdContaSistema as ContaSistemaId,
	TabelaoInteracaoResumo.IdAtendimento as AtendimentoCodigo,
	TabelaoInteracaoResumo.IdInteracaoTipo,
	TabelaoInteracaoResumo.InteracaoTipoValor as InteracaoTipoNome,
	TabelaoInteracaoResumo.DtInteracao,
	TabelaoInteracaoResumo.DtInteracaoConclusao,
	TabelaoInteracaoResumo.DtInteracaoConclusaoFull,
	TabelaoInteracaoResumo.Periodo as PeriodoInteracaoInclusao,
	TabelaoInteracaoResumo.InteracaoAtorPartida,
	TabelaoInteracaoResumo.DtInteracaoInclusao,
	TabelaoInteracaoResumo.DtInteracaoInclusaoFull,
	TabelaoInteracaoResumo.InteracaoRealizado,
	TabelaoInteracaoResumo.IdMidia,
	TabelaoInteracaoResumo.StrMidia as MidiaNome,
	TabelaoInteracaoResumo.IdPeca,
	TabelaoInteracaoResumo.StrPeca as PecaNome,
	TabelaoInteracaoResumo.IdIntegradoraExterna,
	TabelaoInteracaoResumo.StrIntegradoraExterna as IntegradoraExternaNome,
	TabelaoInteracaoResumo.IdIntegradoraExternaAgencia,
	TabelaoInteracaoResumo.StrIntegradoraExternaAgencia as IntegradoraExternaAgenciaNome,
	TabelaoInteracaoResumo.IdGrupoPecaMarketing,
	TabelaoInteracaoResumo.StrGrupoPecaMarketing as GrupoPecaMarketingNome,
	TabelaoInteracaoResumo.IdCampanhaMarketing,
	TabelaoInteracaoResumo.StrCampanhaMarketing as CampanhaMarketingNome,
	TabelaoInteracaoResumo.IdCanal,
	TabelaoInteracaoResumo.StrCanal as CanalNome,
	TabelaoInteracaoResumo.IdProduto,
	TabelaoInteracaoResumo.StrProdutoNome as ProdutoNome,
	TabelaoInteracaoResumo.AlarmeDt,
	TabelaoInteracaoResumo.AlarmeDtUltimoStatus,
	TabelaoInteracaoResumo.AlarmeStatus,
	TabelaoInteracaoResumo.AlarmeRealizado,
	TabelaoInteracaoResumo.UsuarioContaSistemaRealizouId,
	TabelaoInteracaoResumo.UsuarioContaSistemaRealizouNome,
	TabelaoInteracaoResumo.UsuarioContaSistemaIncluiuId,
	TabelaoInteracaoResumo.UsuarioContaSistemaIncluiuNome
FROM TabelaoInteracaoResumo WITH(NOLOCK)
WHERE TabelaoInteracaoResumo.IdContaSistema = @ContaSistema
AND TabelaoInteracaoResumo.DtInteracaoInclusao between @DtInicio and @DtFim
);

CREATE function [dbo].[GetAnonimizacaoNome](@nome varchar(1000))
RETURNS varchar(200)
begin
	declare @nomeConcat varchar(30) = '(Anonimizado)'
	declare @nomeRet varchar(1000)

	set @nome = replace(@nome, @nomeConcat, '')

	set @nomeRet = (
										select UPPER(string_agg(LEFT(Replace(trim(TabAux.OrderID), ' ', ''), 1), ' ')) as Nome
										from 
											dbo.SplitIDstring(Replace(@nome, ' ', ',')) TabAux
										where
											Replace(trim(TabAux.OrderID), ' ', '') != ''
									)

    return isnull(@nomeRet, 'Lead') + ' ' + @nomeConcat			
end;

CREATE function [dbo].[GetAtendimentoCompromisso] 
(
	@IdContaSistema int,
	@IdUsuarioContaSistemaExecutando int,
	@IdUsuarioContaSistemaFiltrando int,
	@IntervaloPendenciaInicio datetime,
	@IntervaloPendenciaFim datetime,
	@analitico bit
)
RETURNS @TableRet TABLE
   (
		idAtendimento int,
		qtdAtendimentos int
   )

 AS
BEGIN
			if @IdUsuarioContaSistemaFiltrando is null
				begin
					set @IdUsuarioContaSistemaFiltrando = @IdUsuarioContaSistemaExecutando
				end

			if @analitico = 0 
				BEGIN

					insert @TableRet
					(
						idAtendimento,
						qtdAtendimentos
					)
					Select 
						NULL,
						COUNT(distinct Atendimento.Id)
		
					From
						Alarme with (nolock)
							inner join
						Atendimento with (nolock) on Atendimento.Id = Alarme.IdSuperEntidade
				
					Where
						Atendimento.IdUsuarioContaSistemaAtendimento = @IdUsuarioContaSistemaFiltrando
							and
						Atendimento.StatusAtendimento = 'ATENDIDO' 
							and
						Alarme.Status = 'IN'
							and
						(@IntervaloPendenciaInicio is null or Alarme.Data >= @IntervaloPendenciaInicio)
							and
						(@IntervaloPendenciaFim is null or Alarme.Data <= @IntervaloPendenciaFim)


					-- http://www.sommarskog.se/dyn-search.html
					OPTION (RECOMPILE);

				END
			ELSE
				BEGIN

					insert @TableRet
					(
						idAtendimento,
						qtdAtendimentos
					)
					Select 
						DISTINCT
						Atendimento.Id as idAtendimento,
						null
		
					From
						Alarme with (nolock)
							inner join
						Atendimento with (nolock) on Atendimento.Id = Alarme.IdSuperEntidade
				
					Where
						Atendimento.IdUsuarioContaSistemaAtendimento = @IdUsuarioContaSistemaFiltrando
							and
						Atendimento.StatusAtendimento = 'ATENDIDO' 
							and
						Alarme.Status = 'IN'
							and
						(@IntervaloPendenciaInicio is null or Alarme.Data >= @IntervaloPendenciaInicio)
							and
						(@IntervaloPendenciaFim is null or Alarme.Data <= @IntervaloPendenciaFim)


					-- http://www.sommarskog.se/dyn-search.html
					OPTION (RECOMPILE);
				END

	RETURN
END;

CREATE function [dbo].[GetAtendimentoInteracaoUltimaDtUtilConsiderar](@idAtendimento int)
RETURNS datetime
begin
	declare @dt as datetime = (
								Select
										(
											SELECT 
												-- Se faz necessário adicionar sempre 1 a data máxima retornada
												MAX(AtendimentoDtExpirar)
											FROM 
												(
													VALUES (Atendimento.DtInicioAtendimento), (InteracaoUltima.DtInclusao), (AlarmeUltimo.DataUltimoStatus), (AlarmeUltimoAtivo.Data), (Atendimento.dtInclusao)
												) AS UpdateDate(AtendimentoDtExpirar)
										) AS InteracaoUltimaDtUtilConsiderar
								from
									Atendimento with (nolock)
										left outer join
									Interacao InteracaoUltima with (nolock) on InteracaoUltima.Id = Atendimento.IdInteracaoUsuarioUltima
										left outer join
									Alarme AlarmeUltimo with (nolock) on AlarmeUltimo.Id = Atendimento.IdAlarmeUltimo
										left outer join
									Alarme AlarmeUltimoAtivo with (nolock) on AlarmeUltimoAtivo.Id = Atendimento.IdAlarmeUltimoAtivo

								where
									Atendimento.id = @idAtendimento
							)

    return @dt
end;

CREATE function [dbo].[GetAtendimentoSeguidoresList](@idAtendimento int)

RETURNS varchar(max)
AS
BEGIN
	declare @variavel_concatena varchar(MAX) = null
	declare @strConcatenador as varchar(5) = ';'

	SELECT  
		@variavel_concatena = STRING_AGG(CAST(UsuarioContaSistema.GUID AS VARCHAR(MAX)), @strConcatenador)

	FROM
		AtendimentoSeguidor WITH (NOLOCK) 
			Inner join
		UsuarioContaSistema  WITH (NOLOCK) on UsuarioContaSistema.id = AtendimentoSeguidor.IdUsuarioContaSistema
	where
		AtendimentoSeguidor.IdAtendimento = @idAtendimento
			and
		AtendimentoSeguidor.Status = 'AT'


    if @variavel_concatena is NULL begin
		set @variavel_concatena = null	
    end
    
    return @variavel_concatena

END;

CREATE function [dbo].[GetAtendimentosEncerramentoAutomatico] 
(
	@IdContaSistema int,
	@IdUsuarioContaSistemaExecutando int,
	@IdUsuarioContaSistemaFiltrando int,
	@IntervaloEncerrarInicio datetime,
	@IntervaloEncerrarFim datetime,
	@QtdRegistrosMaxRetornar int,
	@tipoRetorno varchar(15)
) 
RETURNS @TableRet TABLE
   (
		AtendimentoId int,
		ContaSistemaId int,
		PessoaProspectNome varchar(500),
		PessoaNome varchar(500),
		GrupoNome varchar(500),
		AtendimentoDtInicio datetime,
		InteracaoUltimaDtFull  datetime,
		InteracaoUltimaTipoValor varchar(500),
		ValorInt int,
		ValorText varchar(500),

		InteracaoUltimaDtUtilConsiderar datetime,
		AtendimentoDtExpiracao datetime,
		AtendimentoConfiguracaoQtdDiasExpiracao int,
		qtdAtendimentos int,

		negocioStatus varchar(10)
   )

 AS
	
	BEGIN
		declare @dtNow datetime = dbo.GetDateCustom()
		declare @AtendimentoParaEncerrarQtdMinutesMin int = null;
		declare @AtendimentoParaEncerrarQtdMinutesMax int = 0;

		if @IntervaloEncerrarInicio is not null
			set @AtendimentoParaEncerrarQtdMinutesMin = DATEDIFF (DAY, @dtNow, @IntervaloEncerrarInicio) - 1;

		if @IntervaloEncerrarFim is not null
			set @AtendimentoParaEncerrarQtdMinutesMax = DATEDIFF (DAY, @dtNow, @IntervaloEncerrarFim);


		if @tipoRetorno = 'ANALITICO' 
				
				BEGIN
					insert into @TableRet
					Select top (@QtdRegistrosMaxRetornar)
						Atendimento.Id as AtendimentoId,
						Atendimento.IdContaSistema,
						PessoaProspect.Nome as PessoaProspectNome,
						Pessoa.Nome as PessoaNome,
						Grupo.Nome as GrupoNome,
						Atendimento.DtInicioAtendimento as AtendimentoDtInicio,
						Atendimento.InteracaoUsuarioUltimaDt as InteracaoUltimaDtFull,
						InteracaoUltimaTipo.Valor as InteracaoUltimaTipoValor,
						CampanhaConfiguracao.ValorInt as QtdDiasSemInteracaoEncerrar,
						CampanhaConfiguracao.ValorText as ValorText,
						Atendimento.InteracaoUsuarioUltimaDt as InteracaoUltimaDtUtilConsiderar,
						DATEADD(day, CampanhaConfiguracao.ValorInt, Atendimento.InteracaoUsuarioUltimaDt) as AtendimentoDtExpiracao,
						CampanhaConfiguracao.ValorInt  as AtendimentoConfiguracaoQtdDiasExpiracao,
						null,
						Atendimento.negociacaoStatus

					from
						Atendimento  WITH (nolock)
							inner join
						CampanhaConfiguracao WITH (nolock) ON 
															Atendimento.idCampanha = CampanhaConfiguracao.IdCampanha and 
															CampanhaConfiguracao.Tipo = 'ENCERRAR_ATENDIMENTO_SEM_FOLLOWUP' and 
															CampanhaConfiguracao.ValorInt > 0
							inner join
						CampanhaCanal  WITH (nolock) on CampanhaCanal.IdCampanha = Atendimento.idCampanha and CampanhaCanal.IdCanal = Atendimento.IdCanalAtendimento 
							inner join
						UsuarioContaSistema  WITH (nolock) on UsuarioContaSistema.Id = Atendimento.IdUsuarioContaSistemaAtendimento
							inner join
						Pessoa  WITH (nolock) on UsuarioContaSistema.IdPessoa = Pessoa.Id
							inner join
						Grupo WITH (nolock) on Grupo.Id = Atendimento.idGrupo
							inner join
						PessoaProspect  WITH (nolock)  on PessoaProspect.Id = Atendimento.idPessoaProspect
							left outer join
						Interacao InteracaoUltima  WITH (NOLOCK) on InteracaoUltima.Id = Atendimento.IdInteracaoUsuarioUltima
							left outer join
						InteracaoTipo InteracaoUltimaTipo WITH (NOLOCK)  on InteracaoUltima.IdInteracaoTipo = InteracaoUltimaTipo.Id

					where
						CampanhaCanal.UsarCanalNoAutoEncerrar = 1
							and
						Atendimento.StatusAtendimento = 'ATENDIDO' 
							and 
						(@IdUsuarioContaSistemaFiltrando is null or Atendimento.IdUsuarioContaSistemaAtendimento = @IdUsuarioContaSistemaFiltrando)
							and 
						(@IdContaSistema is null or Atendimento.IdContaSistema = @IdContaSistema)
							and
						(
							Atendimento.InteracaoUsuarioUltimaDt <= DATEADD(DAY, -(CampanhaConfiguracao.ValorInt - @AtendimentoParaEncerrarQtdMinutesMax), @dtNow)
								and
							(
								-- Caso seja 1 considerará somente os atendimento que vão encerrar na quantidade de dias repassado
								-- Ex.: Se repassado 5, só irá considerar os atendimentos que irão vencer daqui a 5 dias
								-- caso repassado 0, irá retornar todos que estão para vencer em até 5 dias
								-- deve ser considerado atendimentos até 5 dias 23 h e 59 min
								@AtendimentoParaEncerrarQtdMinutesMin is null
									or
								@AtendimentoParaEncerrarQtdMinutesMin <= 0
									or
								Atendimento.InteracaoUsuarioUltimaDt >= DATEADD(DAY, -(CampanhaConfiguracao.ValorInt - @AtendimentoParaEncerrarQtdMinutesMin), @dtNow)
							)
						)

						-- http://www.sommarskog.se/dyn-search.html
						OPTION (RECOMPILE);


				END

			ELSE if @tipoRetorno = 'AGRUPADOTOTAL' 

				BEGIN

					insert into @TableRet (qtdAtendimentos)
					select
						count(TabAuxAnalitico.AtendimentoId) as qtdAtendimentos

						from 
							GetAtendimentosEncerramentoAutomatico	(
																		@IdContaSistema,
																		@IdUsuarioContaSistemaExecutando,
																		@IdUsuarioContaSistemaFiltrando,
																		@IntervaloEncerrarInicio,
																		@IntervaloEncerrarFim,
																		@QtdRegistrosMaxRetornar,
																		'ANALITICO'
																	) TabAuxAnalitico 

						-- http://www.sommarskog.se/dyn-search.html
						OPTION (RECOMPILE);
				END

			ELSE if @tipoRetorno = 'AGRUPADODIA' 

				BEGIN

					insert into @TableRet (ValorInt, qtdAtendimentos)
					Select 
						TabAux.qtdDia,
						COUNT(TabAux.AtendimentoId) as QtdAtendimentos
					From 
						(
							select
								(DATEDIFF(SECOND, @dtNow, AtendimentoDtExpiracao) / 86400) as qtdDia,
								TabAuxAnalitico.AtendimentoId

							from 
								GetAtendimentosEncerramentoAutomatico	(
																			@IdContaSistema,
																			@IdUsuarioContaSistemaExecutando,
																			@IdUsuarioContaSistemaFiltrando,
																			@IntervaloEncerrarInicio,
																			@IntervaloEncerrarFim,
																			@QtdRegistrosMaxRetornar,
																			'ANALITICO'
																		) TabAuxAnalitico 


						)  TabAux 
							
						Group by
							TabAux.qtdDia

						-- http://www.sommarskog.se/dyn-search.html
						OPTION (RECOMPILE);
				END

			return
		END;

CREATE function [dbo].[GetAtendimentosPendentes] 
(
	@IdContaSistema int,
	@IdUsuarioContaSistemaExecutando int,
	@IdUsuarioContaSistemaFiltrando int,
	@IntervaloPendenciaInicio datetime,
	@IntervaloPendenciaFim datetime,
	@analitico bit
) 

RETURNS @TableRet TABLE
   (
		idAtendimento int,
		idUsuarioContaSistemaAtendimento int,
		qtdAtendimentos int
   )

 AS
	
	begin

		declare @dtNow datetime = dbo.getDateCustom();

		if @IdUsuarioContaSistemaFiltrando is null
			begin
				set @IdUsuarioContaSistemaFiltrando = @IdUsuarioContaSistemaExecutando
			end

		if @analitico = 0 
			BEGIN
				
				insert @TableRet
				(
					idAtendimento,
					idUsuarioContaSistemaAtendimento,
					qtdAtendimentos
				)
				Select
					null,
					null,
					count(distinct Atendimento.Id) as qtdAtendimentos			
				From
					Atendimento WITH (NOLOCK)
						left outer join
					Alarme  WITH (NOLOCK) on Alarme.Id = Atendimento.IdAlarmeUltimoAtivo

				Where
					Atendimento.IdContaSistema = @IdContaSistema
						and
					Atendimento.IdUsuarioContaSistemaAtendimento = @IdUsuarioContaSistemaFiltrando
						and
					(
						-- Atendimentos que estão aguardando para serem atendidos
						Atendimento.StatusAtendimento = 'AGUARDANDOATENDIMENTO'
							or
						(
							Atendimento.StatusAtendimento = 'ATENDIDO'
								and
							(
								-- Recupera todos atendimentos sem alarme ou com alarme vencido
								(Atendimento.IdAlarmeUltimoAtivo is null or Alarme.Data < @dtNow)
									or
								(
									exists (select Atendimentoid from [dbo].[GetAtendimentosEncerramentoAutomatico] (@IdContaSistema,	@IdUsuarioContaSistemaExecutando, @IdUsuarioContaSistemaFiltrando,	@IntervaloPendenciaInicio, @IntervaloPendenciaFim, 999999, 'ANALITICO')  tabAuxAtendimentoEncerrar where tabAuxAtendimentoEncerrar.AtendimentoId = Atendimento.Id)
								)
							)
						)	
					)

				-- http://www.sommarskog.se/dyn-search.html
				OPTION (RECOMPILE);

			END
		ELSE
			BEGIN
				insert @TableRet
				(
					idAtendimento,
					idUsuarioContaSistemaAtendimento,
					qtdAtendimentos
				)
				Select
					distinct
					Atendimento.Id as AtendimentoId,
					Atendimento.IdUsuarioContaSistemaAtendimento as UsuarioContaSistemaId,
					null		
				From
					Atendimento WITH (NOLOCK)
						left outer join
					Alarme  WITH (NOLOCK) on Alarme.Id = Atendimento.IdAlarmeUltimoAtivo

				Where
					Atendimento.IdContaSistema = @IdContaSistema
						and
					Atendimento.IdUsuarioContaSistemaAtendimento = @IdUsuarioContaSistemaFiltrando
						and
					(
						-- Atendimentos que estão aguardando para serem atendidos
						Atendimento.StatusAtendimento = 'AGUARDANDOATENDIMENTO'
							or
						(
							Atendimento.StatusAtendimento = 'ATENDIDO'
								and
							(
								-- Recupera todos atendimentos sem alarme ou com alarme vencido
								(Atendimento.IdAlarmeUltimoAtivo is null or Alarme.Data < @dtNow)
									or
								(
									exists (select Atendimentoid from [dbo].[GetAtendimentosEncerramentoAutomatico] (@IdContaSistema,	@IdUsuarioContaSistemaExecutando, @IdUsuarioContaSistemaFiltrando,	@IntervaloPendenciaInicio, @IntervaloPendenciaFim, 999999, 'ANALITICO')  tabAuxAtendimentoEncerrar where tabAuxAtendimentoEncerrar.AtendimentoId = Atendimento.Id)
								)
							)
						)	
					)

				-- http://www.sommarskog.se/dyn-search.html
				OPTION (RECOMPILE);
			END
		return
	end;

-- Recupera as campanhas e canais que o usuário está habilitdo a atender de acordo com a data
-- do atendimento repassado
-- Irá retornar tb a quantidade de atendimentos sendo atendido por canal repassado
-- Se faz necessário para saber se o usuário tem capacidade de atender mais atendimento no canal ou campanha repassada
CREATE function [dbo].[GetCampanhaPlantaoUsuarioContaSistema](
	@idContaSistema int,
	@idUsuarioContaSistema int,
	@dtAtendimento datetime,
	@tipoCanal varchar(max)
)

RETURNS @TableRet TABLE
   (
		IdCampanha int,
		IdCanal int,
		CanalTipo varchar(100),
		IdGrupo int,
		IdPlantao int,
		QtdMaxCampanhaCanalAtendimentoSimultaneo int,
		QtdMaxCanalAtendimentoSimultaneo int,
		QtdMaxCampanhaAtendimentoSimultaneo int,

		QtdCampanhaCanalAtendimentoSimultaneo int,
		QtdCanalAtendimentoSimultaneo int,
		QtdCampanhaAtendimentoSimultaneo int
   )
AS
	begin
		-- Irá armazenar uma tabela com os tipos canal repassado no filtro
		declare @TableTipoCanal TABLE
		(
			TipoCanal varchar(100)
		)

		-- Irá armazenar a quantidade de atendimentos por campanha e canal sendo atendido no momento
		declare @TableTotalAtendimentoSimultaneo TABLE
		(
			IdCampanha int,
			IdCanal int,
			Total int
		)

		set @tipoCanal = dbo.RetNullOrVarChar(@tipoCanal)

		-- Caso seja repassado o tipo do canal irá inserir em uma tabela temporária para localizar abaixo
		if @tipoCanal is not null 
			begin
				insert @TableTipoCanal
				Select OrderID from SplitIDstring(@tipoCanal)
			end;


		-- irá inserir todos os canais, plantões e campanhas que o usuário está habilitado a atender no momento
		insert into @TableRet 
		(
			IdCampanha,
			IdCanal,
			CanalTipo,
			IdGrupo,
			IdPlantao,
			QtdMaxCampanhaCanalAtendimentoSimultaneo,
			QtdMaxCanalAtendimentoSimultaneo,
			QtdMaxCampanhaAtendimentoSimultaneo
		)
		Select
			distinct 
				CampanhaCanal.IdCampanha,
				CampanhaCanal.IdCanal,
				Canal.Tipo as CanalTipo,
				Grupo.Id as IdGrupo,
				Plantao.Id as IdPlantao,
				CampanhaCanal.NumeroMaxAtendimentoSimultaneo as QtdMaxCampanhaCanalAtendimentoSimultaneo,
				Canal.NumeroMaxAtendimentoSimultaneo as QtdMaxCanalAtendimentoSimultaneo,
				Campanha.NumeroMaxAtendimentoSimultaneo as QtdMaxCampanhaAtendimentoSimultaneo

		From
			UsuarioContaSistema with (nolock)
				inner join
			UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal with (nolock) on UsuarioContaSistema.Id = UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal.IdUsuarioContaSistema
				inner join
			CampanhaCanal  with (nolock) on UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal.IdCampanhaCanal = CampanhaCanal.Id
				inner join
			PlantaoHorario with (nolock) on PlantaoHorario.Id = UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal.IdPlantaoHorario
				inner join
			Plantao with (nolock) on Plantao.Id = PlantaoHorario.IdPlantao
				inner join
			CampanhaGrupo with (nolock) on CampanhaGrupo.Id = UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal.IdCampanhaGrupo
				inner join
			Grupo with (nolock) on Grupo.Id = CampanhaGrupo.IdGrupo
				inner join
			Canal with (nolock) on Canal.Id = CampanhaCanal.IdCanal
				inner join
			Campanha with (nolock) on Campanha.Id = CampanhaCanal.IdCampanha
				left outer join
			-- Caso seja repassado no filtro irá filtrar apenas os CANAIS DO tipo repassado
			@TableTipoCanal TableTipoCanalAux on TableTipoCanalAux.TipoCanal = Canal.Tipo
		
		where
			UsuarioContaSistema.Id = @idUsuarioContaSistema
				and
			UsuarioContaSistema.Status = 'AT'
				and
			UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal.Status = 'AT'
				and
			Campanha.Status = 'AT'
				and
			CampanhaGrupo.Status = 'AT'
				and
			Grupo.Status = 'AT'
				and
			Plantao.Status = 'AT'
				and
			(
				Plantao.DtInicioValidade <= @dtAtendimento
					and
				(Plantao.DtFimValidade >= @dtAtendimento or Plantao.DtFimValidade is null)
			)
				and
			(
				PlantaoHorario.DtInicio <= @dtAtendimento
					and
				PlantaoHorario.DtFim >= @dtAtendimento
					and
				PlantaoHorario.Status = 'AT'
			)
				and
			(
				@tipoCanal is null or TableTipoCanalAux.TipoCanal is not null
			)

		
		-- Insere na tabela auxiliar a quantidade de atendimentos simultâneos por canal e campanha
		-- Que o usuário está atendendo no momento
		-- Apenas atendimentos direcionados ao usuário que não esteja encerrado
		insert @TableTotalAtendimentoSimultaneo
		(
			IdCampanha,
			IdCanal,
			Total
		)
		Select
			Atendimento.idCampanha,
			Atendimento.IdCanalAtendimento,
			COUNT(Atendimento.Id) 
		from 
			Atendimento with (nolock)

		where 
			Atendimento.StatusAtendimento <> 'ENCERRADO' and 
			Atendimento.IdUsuarioContaSistemaAtendimento = @idUsuarioContaSistema and
			exists (Select TableRetAux.IdCampanha from @TableRet TableRetAux where TableRetAux.IdCampanha = Atendimento.IdCampanha or TableRetAux.IdCanal = Atendimento.IdCanalAtendimento) 

		group by
			Atendimento.idCampanha,
			Atendimento.IdCanalAtendimento


		-- Seta na tabela de retorno a quantidade de atendimentos simultâneo sendo atendido em cada canal, campanha e campanha canal
		Update
			@TableRet
		set
			QtdCanalAtendimentoSimultaneo = isnull((Select sum(TableAux.Total) from @TableTotalAtendimentoSimultaneo TableAux where TableAux.IdCanal = TableRetAux.IdCanal),0),
			QtdCampanhaAtendimentoSimultaneo = isnull((Select sum(TableAux.Total) from @TableTotalAtendimentoSimultaneo TableAux where TableAux.IdCampanha = TableRetAux.IdCampanha),0),
			QtdCampanhaCanalAtendimentoSimultaneo = isnull((Select sum(TableAux.Total) from @TableTotalAtendimentoSimultaneo TableAux where TableAux.IdCampanha = TableRetAux.IdCampanha and TableAux.IdCanal = TableRetAux.IdCanal),0)
		from
			@TableRet TableRetAux				

		return
	end;

CREATE function [dbo].[GetContaSistemaByUsuarioContaSistema](@idUsarioContaSistema int)

RETURNS int

begin
    declare     @ret     int = null

	Select 
		@ret = UsuarioContaSistema.IdContaSistema
	FROM
		UsuarioContaSistema WITH (NOLOCK)
	
	
	WHERE
		UsuarioContaSistema.Id = @idUsarioContaSistema
		

    return @ret
end;

create function [dbo].[GetDateCustom]()

RETURNS datetime

begin
    return [dbo].[GetDateTime]()
end;

CREATE function [dbo].[GetDateCustomMinorDay]()

RETURNS datetime

begin
    return Convert(DateTime, DATEDIFF(DAY, 0, [dbo].[GetDateCustom]()))
end;

CREATE function [dbo].[GetDateCustomNoMilleseconds]()

RETURNS datetime

begin
	declare @dtNow as datetime = [dbo].[GetDateTime]();

    return DATEADD(ms, -DATEPART(ms, @dtNow), @dtNow)
end;

CREATE function [dbo].[GetDateTime]()
RETURNS datetime
begin
	return dateadd(hh, -3, getdate())
	--declare @dt as datetime
	--declare @dtNow as datetime = getdate() 
	
	--if
	--	(@dtNow between '2018-11-04 03:00:00' and '2019-2-17 03:00:00')
	--		or
	--	(@dtNow between '2019-11-3 03:00:00' and '2020-2-15 03:00:00')
	--		set @dt = dateadd(hh, -2, @dtNow)
	--else
	--		set @dt = dateadd(hh, -3, @dtNow)

 --   return @dt
end;

CREATE function [dbo].[GetEmailsProspectList](@idPessoaProspect int)

RETURNS varchar (max)

begin
	--declare @variavel_concatena     varchar(MAX) = null
	declare @strConcatenador as varchar(5) = ', '
	declare @ret as varchar(max)

	--set @variavel_concatena=STUFF
	--		(
	--			(
	--			   SELECT  
	--					@strConcatenador + [dbo].[RetirarCaracteresXml](PessoaProspectEmail.Email)
	--			   FROM
	--					PessoaProspectEmail WITH (NOLOCK) 
	--				where
	--					PessoaProspectEmail.IdPessoaProspect = @idPessoaProspect

	--					for xml path(''), type
	--			).value('.', 'varchar(max)'),1,LEN(@strConcatenador),'')

 --   return @variavel_concatena

	SELECT  
		@ret = STRING_AGG(cast(PessoaProspectEmail.Email as varchar(max)), @strConcatenador)
	FROM
		PessoaProspectEmail WITH (NOLOCK) 
	where
		PessoaProspectEmail.IdPessoaProspect = @idPessoaProspect

	return [dbo].[RetirarCaracteresXml](@ret)
end;

CREATE function [dbo].[GetEnderecosProspectList](@idPessoaProspect int)

RETURNS varchar(max)
AS
BEGIN
	declare @variavel_concatena varchar(MAX) = null
	declare @strConcatenador as varchar(5) = '; '

	Select
		@variavel_concatena = STRING_AGG(CAST(TabAux.Endereco AS VARCHAR(MAX)), @strConcatenador)
	From
		(
			SELECT 
					 
							PessoaProspectEndereco.Logradouro + ' ' + 
							PessoaProspectEndereco.Numero + ' ' + 
							case when 
								PessoaProspectEndereco.IdBairro is not null 
							then 
								(select top 1 dbo.Bairro.NomeBairro from dbo.Bairro WITH (NOLOCK) where dbo.Bairro.IdBairro = PessoaProspectEndereco.IdBairro) 
							end 
							+ ' - ' +
							case when 
								PessoaProspectEndereco.IdCidade is not null 
							then 
								(select top 1 dbo.Cidade.Nome from dbo.Cidade WITH (NOLOCK) where dbo.Cidade.Id = PessoaProspectEndereco.IdCidade)
							end 
							+'-'+
							case when 
								PessoaProspectEndereco.IdCidade is not null 
							then 
								PessoaProspectEndereco.UF
							end as Endereco
			FROM
				PessoaProspectEndereco WITH (NOLOCK) 
			where
				PessoaProspectEndereco.IdPessoaProspect =  @idPessoaProspect
		) TabAux


    if @variavel_concatena is NULL begin
		set @variavel_concatena = null	
    end
    
    return @variavel_concatena
End;

CREATE procedure [dbo].[GetFichaPesquisa] 
(
	@IdAtendimento int,
	@FichaPesquisaTipo varchar(150),
	@SomenteFichaAtiva bit
)
as
Select FichaPesquisa.*
From 
		Atendimento WITH (NOLOCK)
			inner join
		CampanhaFichaPesquisa  WITH (NOLOCK) on CampanhaFichaPesquisa.IdCampanha = Atendimento.IdCampanha
			inner join
		FichaPesquisa  WITH (NOLOCK)on FichaPesquisa.Id = CampanhaFichaPesquisa.IdFichaPesquisa

	where
		Atendimento.Id = @IdAtendimento and
		CampanhaFichaPesquisa.FichaPesquisaTipo = @FichaPesquisaTipo and
		(@SomenteFichaAtiva = 0 or FichaPesquisa.Status = 'AT');

CREATE function [dbo].[GetFichaPesquisaRespostaList](@idRespostaFichaPesquisa int)

RETURNS varchar(max)
AS
BEGIN
	declare @variavel_concatena varchar(MAX) = null
	declare @strConcatenador as varchar(5) = '; '

	SELECT
		@variavel_concatena = STRING_AGG(Cast(Resposta.TextoResposta as varchar(max)), @strConcatenador)

	FROM
		RespostaFichaPesquisaResposta WITH (NOLOCK) 
			inner join
		Resposta WITH (NOLOCK) on Resposta.Id = RespostaFichaPesquisaResposta.IdResposta
	where
		RespostaFichaPesquisaResposta.IdRespostaFichaPesquisa = @idRespostaFichaPesquisa

	if @variavel_concatena is NULL begin
		set @variavel_concatena = ''	
	end

	return [dbo].[RetirarCaracteresXml](@variavel_concatena)

END;

-- Recupera a hierarquia dos grupos de acordo com a conta sistema repassada
-- Irá retornar inclusive os grupos desativados
CREATE function [dbo].[GetGrupoHierarquia](
@idContaSistema int)
returns table
as 
return 
(
	with grupoSuperiorTable (IdContaSistema, idGrupoSuperior, idGrupo, Nivel)  as (
		   select
				Grupo.IdContaSistema,
				Grupo.Id as idGrupoSuperior,
				Grupo.Id as idGrupo,
				0 as Nivel
		   from
				Grupo WITH (NOLOCK)

		   where
				Grupo.IdContaSistema = @idContaSistema
	 
		union all
	   
	  select
				Grupo.IdContaSistema,
				grupoSuperiorTable.idGrupoSuperior,
				Grupo.Id as idGrupo,
				Nivel + 1
	  from
				Grupo WITH (NOLOCK)
					   inner join
				GrupoSuperior WITH (NOLOCK) on GrupoSuperior. IdGrupo = Grupo . Id
					   inner join
				grupoSuperiorTable  on GrupoSuperior. IdGrupoSuperior = grupoSuperiorTable. idGrupo
	            
		   where
				GrupoSuperior . DtFim is null  and
				Grupo.IdContaSistema = @idContaSistema
	)
	            
	select
		grupoSuperiorTable.IdContaSistema,
		grupoSuperiorTable.idGrupoSuperior,
		grupoSuperiorTable.idGrupo as idGrupoInferior,
		len(GrupoAux.GrupoHierarquia) - len(replace(GrupoAux.GrupoHierarquia,',','')) as nivelgeral,
		ROW_NUMBER() OVER(PARTITION BY grupoSuperiorTable.idGrupo ORDER BY grupoSuperiorTable.Nivel DESC) as Nivel
	from
		grupoSuperiorTable
			left outer join
		GrupoAux on GrupoAux.id = grupoSuperiorTable.idGrupo
	where
		grupoSuperiorTable.idGrupoSuperior <> grupoSuperiorTable.idGrupo
);

CREATE function [dbo].[GetGrupoHierarquiaList](@idGrupo int)

RETURNS varchar (max)

begin

	declare @variavel_concatena as varchar(MAX) = null
	declare @strConcatenadorPuro as char(1) = ','
	declare @strConcatenador as varchar(2) = @strConcatenadorPuro + ' '

	SELECT
		@variavel_concatena = STRING_AGG(Cast(REPLACE(GrupoHierarquiaView.GrupoSuperiorNome, @strConcatenadorPuro, ' ') as varchar(max)), @strConcatenador) WITHIN GROUP (ORDER BY GrupoHierarquiaView.Nivel desc)
	FROM
		GrupoHierarquiaView WITH (NOLOCK) 
	where
		GrupoHierarquiaView.IdGrupoInferior = @idGrupo and
		GrupoHierarquiaView.Mostrar = 1


	if dbo.IsNullOrWhiteSpace(@variavel_concatena) = 0
		begin
			set @variavel_concatena  = @strConcatenador + @variavel_concatena
		end

    set @variavel_concatena  =	(Select top 1 REPLACE(nome, @strConcatenadorPuro, ' ') from Grupo WITH (NOLOCK) where id = @idGrupo) + COALESCE(@variavel_concatena, '')

    return [dbo].[RetirarCaracteresXml](@variavel_concatena)
end;

CREATE function [dbo].[GetGrupoHierarquiaTipoList](@idGrupo int)

RETURNS varchar (MAX)

begin

	declare @variavel_concatena     varchar(MAX) = null
	declare @strConcatenadorPuro as char(1) = ','
	declare @strConcatenador as varchar(2) = @strConcatenadorPuro + ' '



	SELECT
		@variavel_concatena = STRING_AGG(Cast(REPLACE(GrupoHierarquiaView.GrupoSuperiorNome, @strConcatenadorPuro, ' ') as varchar(max)), @strConcatenador) WITHIN GROUP (ORDER BY GrupoHierarquiaView.Nivel desc)
	FROM
		GrupoHierarquiaView WITH (NOLOCK) 
	where
		GrupoHierarquiaView.IdGrupoInferior = @idGrupo and
		GrupoHierarquiaView.Mostrar = 1


	if dbo.IsNullOrWhiteSpace(@variavel_concatena) = 0
		begin
			set @variavel_concatena  = @strConcatenador + @variavel_concatena
		end

    set @variavel_concatena  =	(select TOP 1 REPLACE(Tag.Valor, @strConcatenadorPuro, ' ') from Grupo WITH (NOLOCK) inner join Tag WITH (NOLOCK) on Grupo.IdTag = Tag.Id where Grupo.id = @idGrupo) +
								COALESCE(@variavel_concatena, '')	
	
    return @variavel_concatena
end;

-- Retorna todos os grupos que o usuário é administrador e seus inferiores
-- Retorna inclusive dos grupos desativados
CREATE function [dbo].[GetGrupoUsuarioAdmEInferiores](
@idUsuarioContaSistema int)
returns table
as
	return 
	(		
		-- Alterado em 27/10/2020 Fabrício
		Select 
			distinct 
				Grupo.*,
				GrupoAux.GrupoHierarquia,
				GrupoAux.GrupoHierarquiaTipo,
				GrupoAux.NivelGeral,
				CAST (isNull(UsuarioContaSistemaGrupoAdm.Id, 0) as bit) IsAdministrador,
				CAST (isNull(UsuarioContaSistemaGrupo.Id, 0) as bit) IsUsuario
		from
			GrupoHierarquiaUsuarioContaSistema WITH (NOLOCK) 
				inner join
			-- se faz necessário pois caso o grupo não tenha pai o mesmo não estará na hierarquia e não mostraria
			Grupo WITH (NOLOCK) on Grupo.Id = GrupoHierarquiaUsuarioContaSistema.IdGrupo
				left outer join
			GrupoAux WITH (NOLOCK) on GrupoAux.Id = GrupoHierarquiaUsuarioContaSistema.IdGrupo
				left outer join
			UsuarioContaSistemaGrupoAdm WITH (NOLOCK) on UsuarioContaSistemaGrupoAdm.IdGrupo = Grupo.Id and UsuarioContaSistemaGrupoAdm.IdUsuarioContaSistema = GrupoHierarquiaUsuarioContaSistema.IdUsuarioContaSistema and  UsuarioContaSistemaGrupoAdm.DtFim is null
				left outer join
			UsuarioContaSistemaGrupo WITH (NOLOCK) on UsuarioContaSistemaGrupo.IdGrupo = Grupo.Id and UsuarioContaSistemaGrupo.IdUsuarioContaSistema = GrupoHierarquiaUsuarioContaSistema.IdUsuarioContaSistema and  UsuarioContaSistemaGrupo.DtFim is null					
		where
			GrupoHierarquiaUsuarioContaSistema.IdUsuarioContaSistema = @idUsuarioContaSistema
	);

CREATE function [dbo].[GetGrupoUsuarioContaSistemaHierarquiaList](
@idUsuarioContaSistema int, 
@grupoQueEUsuario bit, 
@grupoQueEAdm bit, 
@somenteGrupoAtivo bit)

RETURNS varchar (max)

begin
	declare @strConcatenador as varchar(5) = '#$%'
	set @grupoQueEUsuario = dbo.RetBitNotNull(@grupoQueEUsuario, 1)
	set @grupoQueEAdm = dbo.RetBitNotNull(@grupoQueEAdm, 1)
	set @somenteGrupoAtivo = dbo.RetBitNotNull(@somenteGrupoAtivo, 1)

	declare @variavel_concatena_usuario as varchar(max) = null
	declare @variavel_concatena_adm as varchar(max) = null
	declare @variavel_ret as varchar(max) = null
	
	-- Retorna os grupos que é usuário
	if @grupoQueEUsuario = 1
		begin

			Select
				@variavel_concatena_usuario = STRING_AGG(Cast(TabAux.GrupoHierarquia as varchar(max)), @strConcatenador)
			From
				(
					Select 
						Distinct 
								GrupoAux.GrupoHierarquia
					From
						Grupo WITH (NOLOCK)
							inner join
						UsuarioContaSistemaGrupo WITH (NOLOCK) on UsuarioContaSistemaGrupo.IdGrupo = Grupo.Id
							left outer join
						GrupoAux with (nolock) on GrupoAux.id = Grupo.id
					where
						UsuarioContaSistemaGrupo.IdUsuarioContaSistema = @idUsuarioContaSistema
							and
						UsuarioContaSistemaGrupo.DtFim is null
							and
						Mostrar = 1
							and	
						(
							@somenteGrupoAtivo = 0 or Grupo.Status = 'AT'
						)
				) TabAux

		end

	-- Retorna os grupos que ele é adm
	if @grupoQueEAdm = 1
		begin
			Select
				@variavel_concatena_adm = STRING_AGG(Cast(TabAux.GrupoHierarquia as varchar(max)), @strConcatenador)
			From
				(
					Select 
						Distinct 
								GrupoAux.GrupoHierarquia
					From
						Grupo WITH (NOLOCK)
							inner join
						UsuarioContaSistemaGrupoAdm WITH (NOLOCK) on UsuarioContaSistemaGrupoAdm.IdGrupo = Grupo.Id
							left outer join
						GrupoAux with (nolock) on GrupoAux.id = Grupo.id
					where
						UsuarioContaSistemaGrupoAdm.IdUsuarioContaSistema = @idUsuarioContaSistema
							and
						UsuarioContaSistemaGrupoAdm.DtFim is null
							and
						Mostrar = 1
							and	
						(
							@somenteGrupoAtivo = 0 or Grupo.Status = 'AT'
						)
				) TabAux
		end

	-- seta a variável de retorno
	set @variavel_ret = @variavel_concatena_adm
	
	
	if dbo.IsNullOrWhiteSpace(@variavel_concatena_usuario) = 0 and dbo.IsNullOrWhiteSpace(@variavel_ret) = 0
		begin 
			set @variavel_ret = @variavel_ret + @strConcatenador + @variavel_concatena_usuario
		end
	else
		begin
			set @variavel_ret = @variavel_concatena_usuario
		end
	
	
	return [dbo].[RetirarCaracteresXml](@variavel_ret)
end;

-- Retorna todos os grupos do usuário e todos os grupos que o usuário é administrador e seus grupos filhos inferiores
-- Retorna inclusive os grupos desativados
CREATE function [dbo].[GetGrupoUsuarioTodosEInferiores](
@idUsuarioContaSistema int)
returns table
as
	return 
	(		
		-- Alterado em 27/10/2020 Fabrício

		Select distinct TableGrupo.*
		from
			(
				-- Retorna todos os grupos que o usuário é administrador
				-- E os grupos inferiores ao que o usuário em questão é administrador
				Select 
					TabAdmEInferiores.*
				from
					dbo.GetGrupoUsuarioAdmEInferiores(@idUsuarioContaSistema) TabAdmEInferiores
						
				union
				
				-- Retorna todos os grupos que o usuário é apenas usuário mesmo não sendo administrador
				Select 
					Grupo.*,
					GrupoAux.GrupoHierarquia,
					GrupoAux.GrupoHierarquiaTipo,
					GrupoAux.NivelGeral,
					CAST (isNull(UsuarioContaSistemaGrupoAdm.Id, 0) as bit) IsAdministrador,
					CAST (1 as bit) IsUsuario
				from
					UsuarioContaSistemaGrupo WITH (NOLOCK)
						inner join
					Grupo WITH (NOLOCK) on Grupo.Id = UsuarioContaSistemaGrupo.IdGrupo
						left outer join
					GrupoAux with (nolock) on GrupoAux.id = Grupo.Id
						left outer join
					UsuarioContaSistemaGrupoAdm WITH (NOLOCK) on UsuarioContaSistemaGrupoAdm.IdGrupo = Grupo.Id and UsuarioContaSistemaGrupoAdm.IdUsuarioContaSistema = UsuarioContaSistemaGrupo.IdUsuarioContaSistema and  UsuarioContaSistemaGrupoAdm.DtFim is null

					
				where
					UsuarioContaSistemaGrupo.IdUsuarioContaSistema = @idUsuarioContaSistema and
					(
						UsuarioContaSistemaGrupo.DtFim is null
							or
						UsuarioContaSistemaGrupo.DtFim >= dbo.GetDateCustom()
	
					) 
					
			) TableGrupo
	);

-- Converte uma string repassaga em um hash md5
-- Muito útil para saber se a cadeia de caracteres repassado sofreu mudança com a anterior
CREATE function [dbo].[GetHashMD5](@str varchar(max))

RETURNS char(32)
AS
BEGIN
    return CONVERT(char(32), HashBytes('MD5', isnull(@str,'')), 2)
END;

-- Converte uma string repassaga em um hash SHA1
-- Muito útil para saber se a cadeia de caracteres repassado sofreu mudança com a anterior
CREATE function [dbo].[GetHashSHA1](@str varchar(max))

RETURNS char(40)
AS
BEGIN
    return CONVERT(char(40), HashBytes('SHA1', isnull(@str,'')), 2)
END;

CREATE function [dbo].[GetInteracaoTextoList](@idContaSistema int, @idSuperEntidade int, @interacaoAtorPartida varchar(30), @tipo varchar(max), @strArrayIdInteracaoTipo varchar(max))

RETURNS varchar(max)
AS
BEGIN
	declare @variavel_concatena varchar(MAX) = null
	declare @strConcatenador as varchar(5) = '; '

	declare @TableIdInteracaoTipo TABLE
	(
		IdInteracaoTipo int
	)

	if @tipo is not null
		begin
			insert @TableIdInteracaoTipo
			(
				IdInteracaoTipo
			)
			Select 
				InteracaoTipo.id
			from 
				SplitIDstring(@tipo) TabSplit
					inner join
				InteracaoTipo with(nolock) on InteracaoTipo.IdContaSistema = @idContaSistema and (TabSplit.OrderID = InteracaoTipo.Tipo)
	end

	if @strArrayIdInteracaoTipo is not null
		begin
			insert @TableIdInteracaoTipo
			(
				IdInteracaoTipo
			)
			Select 
				InteracaoTipo.id
			from 
				dbo.SplitIDs(@strArrayIdInteracaoTipo) TabSplit
					inner join
				InteracaoTipo with(nolock) on InteracaoTipo.IdContaSistema = @idContaSistema and (TabSplit.OrderID = InteracaoTipo.Id)
	end

	-- comentado em 15/10/2021 por fabrício, isso n está mais sendo suportado bolar outra ideia
	--SELECT  
	--	@variavel_concatena = STRING_AGG(Cast(CONCAT('(', InteracaoTipo.Valor, ' em ', convert(varchar, Interacao.DtInclusao, 103), ' ', convert(varchar, Interacao.DtInclusao, 108), '): ', JSON_VALUE(InteracaoObj.ObjJson, '$.Obj.Texto')) as varchar(max)), @strConcatenador)

	--from 
	--	Interacao with (nolock)
	--		inner join
	--	InteracaoObj with (nolock) on InteracaoObj.Id = Interacao.Id
	--		inner join
	--	InteracaoTipo with (nolock) on InteracaoTipo.Id = Interacao.IdInteracaoTipo
	--		left outer join
	--	@TableIdInteracaoTipo TabAux on TabAux.IdInteracaoTipo = Interacao.IdInteracaoTipo

	--where 
	--	Interacao.IdContaSistema = @idContaSistema
	--		and
	--	Interacao.idSuperEntidade = @idSuperEntidade
	--		and
	--	(
	--		(@tipo is null and @strArrayIdInteracaoTipo is null) or TabAux.IdInteracaoTipo is not null
	--	)
	--		and
	--	(
	--		@interacaoAtorPartida is null or Interacao.InteracaoAtorPartida = @interacaoAtorPartida
	--	)

    return @variavel_concatena

END;

CREATE function [dbo].[GetMarcoProduto](
@idProduto int,
@dt datetime
)
returns table
as
	return 
	(		
		Select
			top 1 *
		From
			ProdutoMarco WITH (NOLOCK) 

		where
			ProdutoMarco.idProduto = @idProduto 
				and
			ProdutoMarco.DtInicio >= @dt 
				and
			(ProdutoMarco.DtFim <= @dt or ProdutoMarco.DtFim is null)
	);

CREATE function [dbo].[GetNomeComLikeFormatado] (@nome varchar(300))

RETURNS varchar(300)
AS
BEGIN
	declare @nomeRet varchar(300)

	set @nomeRet = dbo.RetNullOrVarChar(@nome)

	if @nomeRet is not null and @nomeRet != 'æ'
		set @nomeRet = replace(@nome, ' ', '%') + '%'

	return @nomeRet
END;

CREATE function [dbo].[GetPessoaProspectIntegracaoLogKeyExternoList](@idAtendimento int)

RETURNS varchar (max)

begin
	declare @variavel_concatena     varchar(MAX) = null
	declare @strConcatenador as varchar(5) = ', '

	set @variavel_concatena=STUFF
			(
				(
				   SELECT  
						@strConcatenador + 
						PessoaProspectIntegracaoLog.KeyExterno
				   FROM
						PessoaProspectIntegracaoLog WITH (NOLOCK)
					where
						PessoaProspectIntegracaoLog.IdAtendimento = @idAtendimento				
				
						for xml path(''), type
				).value('.', 'varchar(max)'),1,LEN(@strConcatenador),'')	

    return @variavel_concatena
end;

CREATE function [dbo].[GetPessoaProspectIntegracaoLogKeyMaxVendasList](@idAtendimento int)

RETURNS varchar (max)

begin
	declare @variavel_concatena     varchar(MAX) = null
	declare @strConcatenador as varchar(5) = ', '

	set @variavel_concatena=STUFF
			(
				(
				   SELECT  
						@variavel_concatena + 
						PessoaProspectIntegracaoLog.KeyMaxVendas
				   FROM
						PessoaProspectIntegracaoLog WITH (NOLOCK)
					where
						PessoaProspectIntegracaoLog.IdAtendimento = @idAtendimento
				
						for xml path(''), type
				).value('.', 'varchar(max)'),1,LEN(@strConcatenador),'')	
				
    return @variavel_concatena
end;

CREATE function [dbo].[GetPessoaTelefoneList](@idPessoa int)

RETURNS varchar (max)

begin
	declare @variavel_concatena varchar(MAX) = null
	declare @strConcatenador as varchar(5) = ','

	SELECT  
		@variavel_concatena = STRING_AGG(Cast(PessoaTelefone.DDD+PessoaTelefone.Telefone as varchar(max)),@strConcatenador)
	FROM
		PessoaTelefone WITH (NOLOCK) 
	where
		PessoaTelefone.IdPessoa = @idPessoa


    return [dbo].[RetirarCaracteresXml](@variavel_concatena)
end;

CREATE function [dbo].[GetPlantaoChatUsuarioNow](@idContaSistema int, @idUsuarioContaSistema int, @IdProduto int, @UF varchar(2), @TrazerUsuariosInferiores as bit)
RETURNS @TableRet TABLE
   (
		IdCampanha int,
		NomeCampanha VARCHAR(150),
		IdCanal int,
		NomeCanal VARCHAR(150),
		IdProduto int,
		UFProduto CHAR(2),
		NomeProduto VARCHAR(150)
   )
AS
	BEGIN
		declare @datenow AS DATETIME = dbo.GetDateCustom()
		declare @TableUsuarioInferior table (IdUsuarioContaSistema int, IdGrupo int)
	
		set @UF = dbo.RetNullOrVarChar(@UF);
	

		-- Seleciona todos os usuários e grupos que são inferiores ao usuário em questão
		Insert into @TableRet
		select
			distinct
			Campanha.Id as IdCampanha,
			Campanha.Nome as NomeCampanha,
			Canal.Id as IdCanal,
			Canal.Nome as NomeCanal,
			ProdutoCampanha.IdProduto as IdProduto,
			Produto.UF as UFProduto,
			Produto.Nome as NomeProduto
					
		from
			UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal WITH (NOLOCK)
				inner join
			UsuarioContaSistema  WITH (NOLOCK) on UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal.IdUsuarioContaSistema = UsuarioContaSistema.Id
				inner join
			CampanhaCanal  WITH (NOLOCK) on CampanhaCanal.id = UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal.idCampanhaCanal
				inner join
			Campanha WITH (NOLOCK) on Campanha.Id = CampanhaCanal.IdCampanha and Campanha.IdContaSistema = UsuarioContaSistema.IdContaSistema
				inner join
			Canal WITH (NOLOCK) on Canal.Id = CampanhaCanal.IdCanal and Canal.IdContaSistema = UsuarioContaSistema.IdContaSistema
				inner join  
			PlantaoHorario WITH (NOLOCK) on PlantaoHorario.id = UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal.idPlantaoHorario  
				inner join
			Plantao WITH (NOLOCK) on Plantao.IdCampanha = Campanha.Id
				inner join
			ProdutoCampanha WITH (NOLOCK) on ProdutoCampanha.IdCampanha = Campanha.Id
				left outer join
			Produto WITH (NOLOCK) on Produto.Id = ProdutoCampanha.IdProduto
				left outer join
			CampanhaGrupo WITH (NOLOCK) on CampanhaGrupo.Id = UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal.IdCampanhaGrupo				

	where
		UsuarioContaSistema.IdContaSistema = @idContaSistema
			and
		UsuarioContaSistema.Status = 'AT'
			and
		(
			@IdUsuarioContaSistema is null 
				or
			( 
				UsuarioContaSistema.Id = @IdUsuarioContaSistema
					or
				(
					@TrazerUsuariosInferiores = 1
						and
					-- recupera a lista de usuários inferiores
					Exists	
					(
						select 
							TbUserInferior.IdGrupo
						from
							dbo.GetUsuarioContaSistemaInferior(@IdUsuarioContaSistema) TbUserInferior
						where
							TbUserInferior.IdGrupo = CampanhaGrupo.IdGrupo and
							TbUserInferior.IdUsuarioContaSistema = UsuarioContaSistema.Id
					)
				)
			)
		)
			and
		Canal.Tipo = 'CHAT' and	
		Canal.Status = 'AT' and
		Campanha.Status = 'AT' and
		Plantao.Status = 'AT' and
		PlantaoHorario.Status = 'AT' and
		PlantaoHorario.DtInicio <= @datenow and 
		PlantaoHorario.DtFim >= @datenow and 
		(
			(
				Plantao.DtInicioValidade <= @datenow and
				Plantao.DtFimValidade is null
			)
				or
			(
				Plantao.DtInicioValidade <= @datenow and
				Plantao.DtFimValidade >= @datenow
			)
		)
			and
		(
			@IdProduto is null or Produto.Id = @IdProduto
		) 
			and
		(
			@UF is null or Produto.UF = @UF
		)

		-- http://www.sommarskog.se/dyn-search.html
		OPTION (RECOMPILE);

		RETURN

	END;

CREATE function [dbo].[GetPlantaoChatUsuarioNowCampanha](
@idContaSistema int,
@idUsuarioContaSistema int,
@IdProduto int,
@UF varchar(2),
@TrazerUsuariosInferiores as bit)
returns table
as 
return 
(
	Select
		distinct
		IdCampanha,
		NomeCampanha		
	from
		dbo.GetPlantaoChatUsuarioNow(@idContaSistema, @idUsuarioContaSistema, @IdProduto, @UF, @TrazerUsuariosInferiores)
);

CREATE function [dbo].[GetPlantaoChatUsuarioNowCampanhaCanal](
@idContaSistema int,
@idUsuarioContaSistema int
)
returns table
as 
return 
(
	Select
		distinct
		IdCampanha,
		NomeCampanha,
		IdCanal,
		NomeCanal		
	from
		dbo.GetPlantaoChatUsuarioNow(@idContaSistema, @idUsuarioContaSistema, null, null, 0)
);

CREATE function [dbo].[GetPlantaoChatUsuarioNowCanal](
@idContaSistema int,
@idUsuarioContaSistema int,
@idCampanha int,
@TrazerUsuariosInferiores as bit)
returns table
as 
return 
(
	Select
		distinct
		IdCanal,
		NomeCanal		
	from
		dbo.GetPlantaoChatUsuarioNow(@idContaSistema, @idUsuarioContaSistema, null, null, @TrazerUsuariosInferiores)
	where
		IdCampanha = @idCampanha
);

CREATE function [dbo].[GetPlantaoChatUsuarioNowOld](@idContaSistema int, @idUsuarioContaSistema int, @IdProduto int, @UF varchar(2), @TrazerUsuariosInferiores as bit)

RETURNS @TableRet TABLE
   (
		IdCampanha int,
		NomeCampanha VARCHAR(150),
		IdCanal int,
		NomeCanal VARCHAR(150),
		IdProduto int,
		UFProduto CHAR(2),
		NomeProduto VARCHAR(150)
   )
AS

BEGIN
	declare @datenow AS DATETIME = dbo.GetDateCustom()
	declare @TableUsuarioInferior table (IdUsuarioContaSistema int, IdGrupo int)
	
	set @UF = dbo.RetNullOrVarChar(@UF);
	
	-- Seleciona todos os usuários e grupos que são inferiores ao usuário em questão
		BEGIN
			-- Setará na tabela temporaria a hierarquia do usuário considerando os usuários inferiores
			-- Só fará isso caso @TrazerUsuariosInferiores seja = 1
			if @TrazerUsuariosInferiores = 1
				begin
					insert into @TableUsuarioInferior select IdUsuarioContaSistema, IdGrupo from dbo.GetUsuarioContaSistemaInferior(@IdUsuarioContaSistema);
				end
		
			Insert into @TableRet

				select
					distinct
					Campanha.Id as IdCampanha,
					Campanha.Nome as NomeCampanha,
					Canal.Id as IdCanal,
					Canal.Nome as NomeCanal,
					ProdutoCampanha.IdProduto as IdProduto,
					Produto.UF as UFProduto,
					Produto.Nome as NomeProduto
					
				from
					UsuarioContaSistema WITH (NOLOCK)
						inner join
					UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal  WITH (NOLOCK) on UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal.IdUsuarioContaSistema = UsuarioContaSistema.Id
						inner join
					CampanhaCanal  WITH (NOLOCK) on CampanhaCanal.id = UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal.idCampanhaCanal
						inner join
					Campanha WITH (NOLOCK) on Campanha.Id = CampanhaCanal.IdCampanha					
						inner join
					Canal WITH (NOLOCK) on Canal.Id = CampanhaCanal.IdCanal 
						inner join  
					PlantaoHorario WITH (NOLOCK) on PlantaoHorario.id = UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal.idPlantaoHorario
						inner join
					Plantao WITH (NOLOCK) on Plantao.IdCampanha = Campanha.Id
						inner join
					ProdutoCampanha WITH (NOLOCK) on ProdutoCampanha.IdCampanha = Campanha.Id
						left outer join
					Produto WITH (NOLOCK) on Produto.Id = ProdutoCampanha.IdProduto
						left outer join
					CampanhaGrupo WITH (NOLOCK) on CampanhaGrupo.Id = UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal.IdCampanhaGrupo				

			where
				UsuarioContaSistema.Status = 'AT'
					and
				Campanha.IdContaSistema = @idContaSistema
					and
				(
					@IdUsuarioContaSistema is null 
						or
					( 
						UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal.IdUsuarioContaSistema = @IdUsuarioContaSistema
							or
						(
							@TrazerUsuariosInferiores = 1
								and
							-- recupera a lista de usuários inferiores
							Exists	
							(
								select 
									TbUserInferior.IdGrupo
								from
									@TableUsuarioInferior TbUserInferior
								where
									CampanhaGrupo.IdGrupo = TbUserInferior.IdGrupo and
									TbUserInferior.IdUsuarioContaSistema = UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal.IdUsuarioContaSistema
							)
						)
					)
				)
					and
				UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal.Status = 'AT' and	
				Canal.Tipo = 'CHAT' and	
				Campanha.Status = 'AT' and
				Plantao.Status = 'AT' and
				PlantaoHorario.Status = 'AT' and
				PlantaoHorario.DtInicio <= @datenow and 
				PlantaoHorario.DtFim >= @datenow and 
				(
					(
						Plantao.DtInicioValidade <= @datenow and
						Plantao.DtFimValidade is null
					)
						or
					(
						Plantao.DtInicioValidade <= @datenow and
						Plantao.DtFimValidade >= @datenow
					)
				)
					and
				(
					@IdProduto is null or Produto.Id = @IdProduto
				) 
					and
				(
					@UF is null or Produto.UF = @UF
				)

				-- http://www.sommarskog.se/dyn-search.html
				OPTION (RECOMPILE);

			RETURN
		END
	END;

CREATE function [dbo].[GetPlantaoChatUsuarioNowProduto](
@idContaSistema int,
@idUsuarioContaSistema int,
@UF varchar(2),
@TrazerUsuariosInferiores bit)
returns table
as 
return 
(
	Select
		distinct
		IdProduto,
		NomeProduto		
	from
		dbo.GetPlantaoChatUsuarioNow(@idContaSistema, @idUsuarioContaSistema, null, @UF, @TrazerUsuariosInferiores)
);

CREATE function [dbo].[GetPlantaoChatUsuarioNowUF](
@idContaSistema int,
@idUsuarioContaSistema int,
@IdProduto int,
@TrazerUsuariosInferiores bit)
returns table
as 
return 
(
	Select
		distinct
		UFProduto	
	from
		dbo.GetPlantaoChatUsuarioNow(@idContaSistema, @idUsuarioContaSistema, @IdProduto, NULL, @TrazerUsuariosInferiores)
);

CREATE function [dbo].[GetProdutosDeInteresseProspectList](@idPessoaProspect int)

RETURNS varchar (max)

begin
	declare @variavel_ret as varchar(max) = null
	declare @variavel_concatena_1 varchar(MAX) = null
	declare @variavel_concatena_2 varchar(MAX) = null
	declare @strConcatenador as varchar(5) = ', '

	set @variavel_concatena_1 =STUFF
			(
				(
				   SELECT 
						distinct
						@strConcatenador + 
						[dbo].[RetirarCaracteresXml](Produto.Nome)
				   FROM
						PessoaProspectProdutoInteresse WITH (NOLOCK) 
							inner join
						Produto WITH (NOLOCK) on Produto.Id = PessoaProspectProdutoInteresse.IdProduto
					where
						PessoaProspectProdutoInteresse.IdPessoaProspect = @idPessoaProspect

				
						for xml path(''), type
				).value('.', 'varchar(max)'),1,LEN(@strConcatenador),'')


	set @variavel_concatena_2 =STUFF
			(
				(
				   SELECT  
						distinct 
						@strConcatenador + 
						[dbo].[RetirarCaracteresXml](Produto.Nome)
				   FROM
						Atendimento WITH (NOLOCK) 
							inner join
						Produto WITH (NOLOCK) on Produto.Id = Atendimento.IdProduto
					where
						Atendimento.IdPessoaProspect = @idPessoaProspect
	
						for xml path(''), type
				).value('.', 'varchar(max)'),1,LEN(@strConcatenador),'')

	-- seta a variável de retorno
	set @variavel_ret = @variavel_concatena_1
	
	
	if dbo.IsNullOrWhiteSpace(@variavel_concatena_2) = 0 and dbo.IsNullOrWhiteSpace(@variavel_ret) = 0
		begin 
			set @variavel_ret = @variavel_ret + @strConcatenador + @variavel_concatena_2
		end
	else
		begin
			set @variavel_ret = @variavel_concatena_2
		end
	
	
	return @variavel_ret
end;

CREATE function [dbo].[GetProdutoSubList](@idAtendimento int)

RETURNS varchar (max)

begin

	--declare @variavel_concatena as varchar(MAX) = null
	declare @strConcatenador as varchar(5) = ', '

	--set @variavel_concatena=STUFF
	--		(
	--			(
	--			   SELECT  
	--					@strConcatenador + 
	--					[dbo].[RetirarCaracteresXml](ProdutoSub.Nome)
	--			   FROM
	--					AtendimentoSubProduto WITH (NOLOCK)
	--						inner join
	--					ProdutoSub WITH (NOLOCK) on  ProdutoSub.Id = AtendimentoSubProduto.IdProdutoSub
	--				where
	--					AtendimentoSubProduto.IdAtendimento = @idAtendimento
				
	--					for xml path(''), type
	--			).value('.', 'varchar(max)'),1,LEN(@strConcatenador),'')				

    return (		Select 
						STRING_AGG(DBO.[RetirarCaracteresXml](ProdutoSub.Nome), @strConcatenador)
				   FROM
						AtendimentoSubProduto WITH (NOLOCK)
							inner join
						ProdutoSub WITH (NOLOCK) on  ProdutoSub.Id = AtendimentoSubProduto.IdProdutoSub
					where
						AtendimentoSubProduto.IdAtendimento = @idAtendimento)
end;

-- Recupera a quantidade de prospect a ser prospectado de acordo com o repassado
CREATE procedure [dbo].[GetProspectsProspeccaoQtd]
	@idContaSistema as int,
	@listIntIdsPessoaProspectOrigem as varchar(max),
	@listStringTags as varchar(max)
 as 
begin
	set @listIntIdsPessoaProspectOrigem = dbo.RetNullOrVarChar(@listIntIdsPessoaProspectOrigem)
	set @listStringTags = dbo.RetNullOrVarChar(@listStringTags)

	declare @total as int = 0

	if @listIntIdsPessoaProspectOrigem is not null
		begin
			set @total += isnull((Select 
							COUNT(distinct PessoaProspectOrigemPessoaProspect.IdPessoaProspect) 
						From
							PessoaProspectOrigem with(nolock)
								inner join
							dbo.SplitIDs(@listIntIdsPessoaProspectOrigem) TablePessoaProspectOrigem on PessoaProspectOrigem.Id = TablePessoaProspectOrigem.OrderID
								inner join
							PessoaProspectOrigemPessoaProspect  with(nolock) on PessoaProspectOrigemPessoaProspect.IdPessoaProspectOrigem = PessoaProspectOrigem.Id

						where
							PessoaProspectOrigem.idContaSistema = @idContaSistema),0)
		end

	if @listStringTags is not null
		begin
			set @total += isnull((Select 
								Count(distinct PessoaProspectTag.idPessoaProspect)
							From
								Tag with(nolock)
									inner join
								dbo.SplitIDstring(@listStringTags) TableTag on Tag.Valor = TableTag.OrderID
									inner join
								PessoaProspectTag with(nolock) on PessoaProspectTag.IdTag = Tag.Id

							where
								Tag.IdContaSistema = @idContaSistema and
								Tag.Tipo = 'TAGPROSPECT'),0)
		end

	select isnull(sum(@total),0) as Total
end;

CREATE function [dbo].[GetTagsProspectList](@idPessoaProspect int)

RETURNS varchar (max)

begin
	--declare @variavel_concatena     varchar(MAX) = null
	declare @strConcatenador as char(3) = ', '
	declare @ret as varchar(max)

--	set @variavel_concatena=STUFF
--			(
--				(
--				   SELECT  
--						@strConcatenador + [dbo].[RetirarCaracteresXml](Tag.Valor)
--				   FROM
--						PessoaProspectTag WITH (NOLOCK) 
--							inner join
--						Tag  WITH (NOLOCK) on Tag.Id = PessoaProspectTag.IdTag
--					where
--						PessoaProspectTag.IdPessoaProspect = @idPessoaProspect

--						for xml path(''), type
--				).value('.', 'varchar(max)'),1,LEN(@strConcatenador),'')

--    return @variavel_concatena


	SELECT  
		@ret = STRING_AGG(CAST(Tag.Valor AS VARCHAR(MAX)), @strConcatenador)
	FROM
		PessoaProspectTag WITH (NOLOCK) 
			inner join
		Tag  WITH (NOLOCK) on Tag.Id = PessoaProspectTag.IdTag
	where
		PessoaProspectTag.IdPessoaProspect = @idPessoaProspect


	return [dbo].[RetirarCaracteresXml](@ret)

end;

CREATE function [dbo].[GetTelefonesPessoaList](@idPessoa int)

RETURNS varchar (max)

begin

	declare @variavel_concatena as varchar(MAX) = null
	declare @strConcatenador as varchar(5) = ', '

SELECT  
	@variavel_concatena = STRING_AGG(CAST(('(' + PessoaTelefone.DDD+') ' + PessoaTelefone.Telefone) AS varchar(max)), @strConcatenador)
FROM
	PessoaTelefone WITH (NOLOCK) 
where
	PessoaTelefone.IdPessoa = @idPessoa

	return @variavel_concatena
end;

CREATE function [dbo].[GetTelefonesProspectList](@idPessoaProspect int)

RETURNS varchar (max)

begin

	--declare @variavel_concatena as varchar(MAX) = null
	declare @strConcatenador as varchar(5) = ', '

	--set @variavel_concatena=STUFF
	--		(
	--			(
	--			   SELECT  
	--					@strConcatenador + 
	--					'(' + PessoaProspectTelefone.DDD+') ' + 
	--					PessoaProspectTelefone.Telefone
	--			   FROM
	--					PessoaProspectTelefone WITH (NOLOCK) 
	--				where
	--					PessoaProspectTelefone.IdPessoaProspect = @idPessoaProspect
				
	--					for xml path(''), type
	--			).value('.', 'varchar(max)'),1,LEN(@strConcatenador),'')				

 --   return @variavel_concatena

 return (

 				   SELECT  
						STRING_AGG(CAST(('(' + PessoaProspectTelefone.DDD+') ' + PessoaProspectTelefone.Telefone) AS VARCHAR(MAX)), @strConcatenador)
				   FROM
						PessoaProspectTelefone WITH (NOLOCK) 
					where
						PessoaProspectTelefone.IdPessoaProspect = @idPessoaProspect

 )
end;

create function [dbo].[GetTeste] 
(
	@idContaSistema int,
	@IdUsuarioContaSistemaExecutando int,
	@IsAdministradorDoSistema bit,
	@SomenteAtendimentoDoUsuario bit,
	@SomenteAtendimentoUsuarioContaSistemaExecutandoSegue bit,
	@dtInteracaoMaiorQue datetime
)
RETURNS @TableRet TABLE
   (
		id int,
		Tipo varchar(800)
   )

 AS
BEGIN
		--declare @idContaSistema int = 377
		--declare @IdUsuarioContaSistemaExecutando int = 55813
		--declare @IsAdministradorDoSistema bit = 0
		--declare @SomenteAtendimentoDoUsuario bit = 0
		--declare @SomenteAtendimentoUsuarioContaSistemaExecutandoSegue bit = 0
		insert @TableRet
							(
								Id,
								Tipo
							)
		select 
			Interacao.Id, InteracaoTipo.Tipo
		from 
			Interacao 
				inner join 
			Atendimento on atendimento.id = interacao.idsuperentidade
				inner join 
			InteracaoTipo on InteracaoTipo.Id = Interacao.IdInteracaoTipo
				left outer join
			-- Seleciona para verificar se o usuario que esta executando e adm da campanha, caso seja o mesmo podera visualizar os registros
			CampanhaAdministrador WITH (NOLOCK) on (@IsAdministradorDoSistema = 0 and CampanhaAdministrador.idCampanha = Atendimento.IdCampanha and CampanhaAdministrador.idUsuarioContaSistema = @IdUsuarioContaSistemaExecutando)
				left outer join
			AtendimentoSeguidor on AtendimentoSeguidor.IdAtendimento = Atendimento.Id and AtendimentoSeguidor.IdUsuarioContaSistema = @IdUsuarioContaSistemaExecutando and AtendimentoSeguidor.Status = 'AT'
				left outer join 
			-- se ele é adm e n quer listar somente os atendimentos dele n se faz necessario executar essa pesquisa
			PessoaProspectFidelizado WITH (NOLOCK) on ((@IsAdministradorDoSistema = 0 or @SomenteAtendimentoDoUsuario = 1) and PessoaProspectFidelizado.IdPessoaProspect = Atendimento.idPessoaProspect and PessoaProspectFidelizado.IdCampanha = Atendimento.idCampanha and PessoaProspectFidelizado.DtFimFidelizacao is null and PessoaProspectFidelizado.IdUsuarioContaSistema = @IdUsuarioContaSistemaExecutando)
	
			Where
				Atendimento.idContaSistema = @IdContaSistema 
				and 
			 Interacao.DtInclusao >= @dtInteracaoMaiorQue
					and
				(
					(
						(@SomenteAtendimentoDoUsuario = 0 or Atendimento.IdUsuarioContaSistemaAtendimento = @IdUsuarioContaSistemaExecutando)
					)
						and
					(
						(@SomenteAtendimentoUsuarioContaSistemaExecutandoSegue = 0 or AtendimentoSeguidor.IdUsuarioContaSistema = @IdUsuarioContaSistemaExecutando)
					)
						and
					(
						-- caso seja somente os do usuário n faz sentido fazer as verificações abaixo
						@SomenteAtendimentoDoUsuario = 1
							or

						@SomenteAtendimentoUsuarioContaSistemaExecutandoSegue = 1
							or

						AtendimentoSeguidor.id is not null
							or

						-- caso seja administrador do sistema não irá considerar a hierarquia de grupos
						@IsAdministradorDoSistema = 1
							or

						-- caso seja administraodr da campanha todos os atendimentos da mesmo o usuário poderá ver
						CampanhaAdministrador.Id is not null
							or

						-- O usuário detem a fidelização do prospect
						PessoaProspectFidelizado.id is not null
							or
						-- Usuário não está fidelizado a ninguém e o atendimento está para o prospect, nesse caso provavelmente aguardando para ser atendido

						Atendimento.IdUsuarioContaSistemaAtendimento = @IdUsuarioContaSistemaExecutando
							or

						exists (Select GrupoHierarquiaUsuarioContaSistema.id from GrupoHierarquiaUsuarioContaSistema WITH (NOLOCK) where GrupoHierarquiaUsuarioContaSistema.idUsuarioContaSistema = @IdUsuarioContaSistemaExecutando and (GrupoHierarquiaUsuarioContaSistema.IdGrupo = PessoaProspectFidelizado.IdGrupo or GrupoHierarquiaUsuarioContaSistema.IdGrupo = Atendimento.idGrupo))
					)
				)


			return
	end


--group by InteracaoTipo.Tipo,  InteracaoTipo.Tipo
--order by total;

CREATE function [dbo].[GetUltimosUsuariosAtendimentoList](@idAtendimento int)

RETURNS varchar (max)

begin
	declare @variavel_concatena varchar(MAX) = null
	declare @strConcatenador as varchar(5) = ', '

select
	@variavel_concatena = STRING_AGG(Cast(TabAux1.Nome + ' (' + TabAux1.Email +') em '+ convert(VARCHAR(20),TabAux1.DtInteracao, 103) + ' ' + convert(VARCHAR(8), TabAux1.DtInteracao, 14) as Varchar(max)), @strConcatenador) WITHIN GROUP (ORDER BY TabAux1.DtInteracao ASC)  
from 
	dbo.GetUltimosUsuariosAtendimentoTable(@idAtendimento) TabAux1

    return [dbo].[RetirarCaracteresXml](@variavel_concatena)
end;

CREATE function [dbo].[GetUltimosUsuariosAtendimentoTable](@idAtendimento int)
returns table
as
	return 
	(		
		select
			row_number() over (order by Interacao.DtInteracao desc) as OrdemInversa,
			Interacao.IdSuperEntidade as AtendimentoId,
			UsuarioContaSistema.Id as UsuarioContaSistemaId,
			Pessoa.Nome,
			Pessoa.Email,
			Interacao.DtInteracao
		from 
			Interacao with (nolock)
				inner join
			InteracaoTipo with (nolock) on Interacao.IdInteracaoTipo = InteracaoTipo.Id
				inner join
			UsuarioContaSistema with (nolock) on UsuarioContaSistema.id = Interacao.IdUsuarioContaSistemaRealizou
				inner join
			Pessoa with (nolock) on Pessoa.Id = UsuarioContaSistema.IdPessoa
		where 
			InteracaoTipo.Tipo = 'ATENDIMENTOATENDIDO' and
			Interacao.IdSuperEntidade = @idAtendimento
	);

-- De acordo com o usuário repassado
-- Retornará todos os usuários inferiores ao mesmo e os grupos que esse usuário é inferior
CREATE function [dbo].[GetUsuarioContaSistemaInferior](@idUsuarioContaSistema int)
RETURNS @TableRet TABLE
   (
		IdUsuarioContaSistema int,
		IdGrupo Int
   )
AS

BEGIN

	DECLARE @TableRetAux TABLE
   (
		IdUsuarioContaSistema int,
		IdGrupo Int
   )

   	DECLARE @TableGrupo TABLE
   (
		IdGrupo int
   );

   declare @dtNow datetime = dbo.GetDateCustom()


	BEGIN
		-- insere na tabela auxiliar todos os grupos do usuário e inferiores
		-- se faz necessário para reusar
		insert into @TableGrupo 
		select tabAux.Id from GetGrupoUsuarioAdmEInferiores(@idUsuarioContaSistema) tabAux
		

		-- Seleciona todos os grupos que o usuário em questão é administrador
		-- Selecionará todos os usuários pertencentes a cada grupo que o mesmo é administrador
		insert into @TableRetAux
		select
			UsuarioContaSistemaGrupo.IdUsuarioContaSistema,
			UsuarioContaSistemaGrupo.IdGrupo
				
		from 
			@TableGrupo GruposSuperiores
				inner join
			UsuarioContaSistemaGrupo WITH (NOLOCK) on UsuarioContaSistemaGrupo.IdGrupo = GruposSuperiores.IdGrupo

		where
			(
				UsuarioContaSistemaGrupo.DtFim >= @dtNow
					or
				UsuarioContaSistemaGrupo.DtFim is null
			)

		-- Se faz necessário selecionar os grupos que o usuário é adm para que os adm dos grupos apareçam como inferior do usuário em questão
		-- já que na query acima não aparece
		insert into @TableRetAux
		select
			UsuarioContaSistemaGrupoAdm.IdUsuarioContaSistema,
			UsuarioContaSistemaGrupoAdm.IdGrupo				
		from 
			@TableGrupo GruposSuperiores
				inner join
			UsuarioContaSistemaGrupoAdm WITH (NOLOCK) on UsuarioContaSistemaGrupoAdm.IdGrupo = GruposSuperiores.IdGrupo
		where
			(
				UsuarioContaSistemaGrupoAdm.DtFim >= @dtNow
					or
				UsuarioContaSistemaGrupoAdm.DtFim is null
			) 

		insert into @TableRet
		Select distinct TableAux.IdUsuarioContaSistema, TableAux.IdGrupo from @TableRetAux TableAux

		RETURN 
	END
End;

-- Recupera os usuários que o usuário pode criar atendimento
-- recupera todos os usuários de todos os grupos da campanha a qual o usuário é administrador da campanha que esteja alocado em algum canal da campanha
-- ou todos os usuários inferiores ao usuário atual que esteja em algum grupo da campanha
-- @@somenteUsuarioAlocadoNaCampanha:	Caso true só recuperará os usuários habilitados a atender em um plantão horário ativo (válido) no momento em questão que esteja habilitado a atender no canal
--										Caso false, irá retornar todos os usuários de todos os grupos alocados na campanha mesmo que o usuário não esteja alocado em nenhum plantão ou horário, irá considerar somente os grupos
-- @retornarGrupo: caso positivo irá retornar o grupo do usuário, nesse caso o mesmo poderá retornar duplicado
-- @forcarAdmCampanha: caso positivo considerará que o usuário é adm da campanha, assim retornará todos os usuários alocados em todos os grupos da campanha indiferente da hierarquia
CREATE function [dbo].[GetUsuarioContaSistemaInferiorEspecializado](@idContaSistema int, @isAdministradorDoSistema bit, @idUsuarioContaSistema int, @idCampanha int, @idCanal int, @somenteUsuarioAlocadoNaCampanha bit, @retornarGrupo bit, @forcarAdmCampanha bit, @sempreAutoIncluirUsuario bit)

RETURNS @TableRet TABLE
   (
		IdUsuarioContaSistema int,
		GuidUsuarioContaSistema char(36),
		UsuarioGuidUsuarioCorrex char(36),
		UsuarioContaSistemaNome VARCHAR(500),
		UsuarioContaSistemaApelido VARCHAR(200),
		UsuarioContaSistemaEmail VARCHAR(500),
		GrupoHierarquia VARCHAR(max),
		IdGrupo int
   )
AS

Begin
	declare  @TableAux TABLE
	(
			IdUsuarioContaSistema int,
			GuidUsuarioContaSistema char(36),
			UsuarioGuidUsuarioCorrex char(36),
			UsuarioContaSistemaNome VARCHAR(500),
			UsuarioContaSistemaApelido VARCHAR(200),
			UsuarioContaSistemaEmail VARCHAR(500),
			GrupoHierarquia VARCHAR(max),
			IdGrupo int
	)

	declare @datenow AS DATETIME = dbo.GetDateCustom()
	
	-- Caso os parâmetros sejam repassados irá considerar os usuários alocados em campanhas
	if @idCampanha is not null 
		begin
			
			-- Retornará apenas usuários que sejam subordinado ao usuário em questão que estejam obrigatoriamente alocados na campanha
			-- Também retornará todos os usuários alocados em todos os grupos alocados na campanha caso o usuário em questão seja ADM da campanha
			if @somenteUsuarioAlocadoNaCampanha = 1
			
				begin

					Insert into @TableAux
					Select
						distinct
							UsuarioContaSistema.Id as IdUsuarioContaSistema,
							UsuarioContaSistema.Guid as GuidUsuarioContaSistema,
							Usuario.GuidUsuarioCorrex as UsuarioGuidUsuarioCorrex,
							Pessoa.Nome as UsuarioContaSistemaNome,
							Pessoa.Apelido as UsuarioContaSistemaApelido,
							Pessoa.Email,
							(case when @retornarGrupo = 1 then GrupoAux.GrupoHierarquia end) as GrupoHierarquia,
							(case when @retornarGrupo = 1 then Grupo.Id end) as IdGrupo
						
					From 
						UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal WITH (NOLOCK)
							inner join
						CampanhaGrupo WITH (NOLOCK) on UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal.IdCampanhaGrupo = CampanhaGrupo.Id
							inner join
						CampanhaCanal WITH (NOLOCK) on CampanhaCanal.Id = UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal.IdCampanhaCanal
							inner join
						UsuarioContaSistema WITH (NOLOCK) on UsuarioContaSistema.Id = UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal.IdUsuarioContaSistema
							inner join
						Usuario WITH (NOLOCK) on Usuario.IdPessoa = UsuarioContaSistema.IdPessoa
							inner join
						Pessoa WITH (NOLOCK) on Pessoa.Id = UsuarioContaSistema.IdPessoa						
							inner join
						Canal WITH (NOLOCK) on Canal.Id = CampanhaCanal.IdCanal
							inner join
						Grupo WITH (NOLOCK) on Grupo.Id = CampanhaGrupo.IdGrupo
							inner join
						PlantaoHorario WITH (NOLOCK) on PlantaoHorario.Id = UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal.IdPlantaoHorario
							inner join
						Plantao  WITH (NOLOCK) on Plantao.Id = PlantaoHorario.IdPlantao
							left outer join
						GrupoAux with (nolock) on GrupoAux.id = grupo.Id
							left outer join
						CampanhaAdministrador WITH (NOLOCK) on @isAdministradorDoSistema <> 1 and @forcarAdmCampanha <> 1 and CampanhaAdministrador.IdCampanha = CampanhaGrupo.IdCampanha and CampanhaAdministrador.IdUsuarioContaSistema = @idUsuarioContaSistema
							left outer join
						GetUsuarioContaSistemaInferior(@idUsuarioContaSistema) UsuariosInferiores on @isAdministradorDoSistema <> 1 and UsuariosInferiores.IdGrupo = CampanhaGrupo.IdGrupo and UsuariosInferiores.IdUsuarioContaSistema = UsuarioContaSistema.Id
						
					where
						UsuarioContaSistema.IdContaSistema = @idContaSistema 
							and
						CampanhaGrupo.IdCampanha = @idCampanha 
							and
						(
							@isAdministradorDoSistema = 1
								or
							@forcarAdmCampanha = 1
								or
							CampanhaAdministrador.Id is not null
								or
							UsuariosInferiores.IdUsuarioContaSistema is not null
								or
							UsuarioContaSistema.Id = @idUsuarioContaSistema
						)
							and
						Plantao.Status = 'AT' 
							and 
						PlantaoHorario.Status = 'AT' 
							and 
						(
							PlantaoHorario.DtInicio <= @datenow
								and 
							(PlantaoHorario.DtFim is null or PlantaoHorario.DtFim >= @datenow)
						) 
							and
						CampanhaGrupo.Status = 'AT' 
							and
						UsuarioContaSistema.Status = 'AT' 
							and
						Grupo.Status = 'AT' 
							and
						(@idCanal is null or CampanhaCanal.IdCanal = @idCanal and Canal.Status = 'AT') 

						-- http://www.sommarskog.se/dyn-search.html
						OPTION (RECOMPILE);
				end
				
			else
			 
				begin
					Insert into @TableAux
					Select 
						distinct
							UsuarioContaSistema.Id as IdUsuarioContaSistema,
							UsuarioContaSistema.Guid as GuidUsuarioContaSistema,
							Usuario.GuidUsuarioCorrex as UsuarioGuidUsuarioCorrex,
							Pessoa.Nome as UsuarioContaSistemaNome,
							Pessoa.Apelido as UsuarioContaSistemaApelido,
							Pessoa.Email,
							(case when @retornarGrupo = 1 then GrupoAux.GrupoHierarquia end) as GrupoHierarquia,
							(case when @retornarGrupo = 1 then Grupo.Id end) as IdGrupo
						
					From 
						Campanha WITH (NOLOCK)
							inner join
						CampanhaGrupo WITH (NOLOCK) on Campanha.Id = CampanhaGrupo.IdCampanha
							inner join
						Grupo WITH (NOLOCK) on Grupo.Id = CampanhaGrupo.IdGrupo
							left outer join
						GrupoAux with (nolock) on GrupoAux.id = grupo.id
							left outer join
						UsuarioContaSistemaGrupoAdm WITH (NOLOCK) on UsuarioContaSistemaGrupoAdm.IdGrupo = Grupo.Id and UsuarioContaSistemaGrupoAdm.DtFim is null
							left outer join
						UsuarioContaSistemaGrupo WITH (NOLOCK) on UsuarioContaSistemaGrupo.IdGrupo = grupo.id and UsuarioContaSistemaGrupo.DtFim is null
							left outer join
						UsuarioContaSistema WITH (NOLOCK) on UsuarioContaSistema.Id = UsuarioContaSistemaGrupoAdm.IdUsuarioContaSistema or UsuarioContaSistema.Id = UsuarioContaSistemaGrupo.IdUsuarioContaSistema
							left outer join
						Usuario WITH (NOLOCK) on Usuario.IdPessoa = UsuarioContaSistema.IdPessoa
							left outer join
						Pessoa WITH (NOLOCK) on Pessoa.Id = UsuarioContaSistema.IdPessoa
							left outer join
						CampanhaAdministrador WITH (NOLOCK) on @isAdministradorDoSistema <> 1 and @forcarAdmCampanha <> 1 and (CampanhaAdministrador.IdCampanha = CampanhaGrupo.IdCampanha and CampanhaAdministrador.IdUsuarioContaSistema = @idUsuarioContaSistema)
							left outer join
						GetUsuarioContaSistemaInferior(@idUsuarioContaSistema) UsuariosInferiores on @isAdministradorDoSistema <> 1 and UsuariosInferiores.IdGrupo = CampanhaGrupo.IdGrupo and UsuariosInferiores.IdUsuarioContaSistema = UsuarioContaSistema.Id
						
					where
						Campanha.Id = @idCampanha and
						Campanha.IdContaSistema = @idContaSistema and
						UsuarioContaSistema.Id is not null and
						
						CampanhaGrupo.Status = 'AT' and
						UsuarioContaSistema.Status = 'AT' and
						Grupo.Status = 'AT' and

						(
							@isAdministradorDoSistema = 1
								or
							@forcarAdmCampanha = 1
								or
							CampanhaAdministrador.Id is not null
								or
							UsuariosInferiores.IdUsuarioContaSistema is Not null
								or
							UsuarioContaSistema.Id = @idUsuarioContaSistema
						)
						-- http://www.sommarskog.se/dyn-search.html
						OPTION (RECOMPILE);
				end
		end
	-- Caso seja adm de sistema irá retornar todos os usuários ativos no sistema
	else 
		begin
			Insert into @TableAux
			
			Select  
				distinct 
					UsuarioContaSistema.Id,
					UsuarioContaSistema.Guid as GuidUsuarioContaSistema,
					Usuario.GuidUsuarioCorrex as UsuarioGuidUsuarioCorrex,
					Pessoa.Nome as UsuarioContaSistemaNome,
					Pessoa.Apelido as UsuarioContaSistemaApelido,
					Pessoa.Email,
					(case when @retornarGrupo = 1 then GrupoAux.GrupoHierarquia end) as GrupoHierarquia,
					(case when @retornarGrupo = 1 then Grupo.Id end) as IdGrupo
				
				from
					UsuarioContaSistema  WITH (NOLOCK)
						inner join
					Pessoa  WITH (NOLOCK) on Pessoa.Id = UsuarioContaSistema.IdPessoa
						inner join
					Usuario WITH (NOLOCK) on Usuario.IdPessoa = UsuarioContaSistema.IdPessoa
						left outer join
					GetUsuarioContaSistemaInferior(@idUsuarioContaSistema) UsuariosInferiores on UsuariosInferiores.IdUsuarioContaSistema = UsuarioContaSistema.Id
						left outer join
					Grupo  WITH (NOLOCK) on Grupo.Id = UsuariosInferiores.IdGrupo
						left outer join
					GrupoAux with (nolock) on GrupoAux.id = grupo.id
				where
					UsuarioContaSistema.IdContaSistema = @idContaSistema and 
					UsuarioContaSistema.Status = 'AT' and
					(
						@isAdministradorDoSistema = 1
							or
						@forcarAdmCampanha = 1
							or
						UsuariosInferiores.IdUsuarioContaSistema is not null
							or
						UsuarioContaSistema.Id = @idUsuarioContaSistema
					)
					-- http://www.sommarskog.se/dyn-search.html
					OPTION (RECOMPILE);
					
		end

	-- caso positivo irá verificar se no retorno existe o próprio usuário
	-- caso não exista irá incluir o mesmo
	if @idUsuarioContaSistema is not null and @sempreAutoIncluirUsuario = 1
		begin
			declare @existeUsuario int = isnull((select count(Tab1.IdUsuarioContaSistema) from @TableRet Tab1 where Tab1.IdUsuarioContaSistema = @idUsuarioContaSistema), 0)

			if @existeUsuario = 0
				begin
					Insert into @TableAux
			
					Select  
						distinct 
							UsuarioContaSistema.Id,
							UsuarioContaSistema.Guid as GuidUsuarioContaSistema,
							Usuario.GuidUsuarioCorrex as UsuarioGuidUsuarioCorrex,
							Pessoa.Nome as UsuarioContaSistemaNome,
							Pessoa.Apelido as UsuarioContaSistemaApelido,
							Pessoa.Email,
							(case when @retornarGrupo = 1 then GrupoAux.GrupoHierarquia end) as GrupoHierarquia,
							(case when @retornarGrupo = 1 then Grupo.Id end) as IdGrupo
				
						from
							UsuarioContaSistema  WITH (NOLOCK)
								inner join
							Pessoa  WITH (NOLOCK) on Pessoa.Id = UsuarioContaSistema.IdPessoa
								inner join
							Usuario WITH (NOLOCK) on Usuario.IdPessoa = UsuarioContaSistema.IdPessoa
								left outer join
							GetUsuarioContaSistemaInferior(@idUsuarioContaSistema) UsuariosInferiores on UsuariosInferiores.IdUsuarioContaSistema = UsuarioContaSistema.Id
								left outer join
							Grupo  WITH (NOLOCK) on Grupo.Id = UsuariosInferiores.IdGrupo
								left outer join
							GrupoAux with (nolock) on GrupoAux.id = grupo.id
						where
							UsuarioContaSistema.IdContaSistema = @idContaSistema and 
							UsuarioContaSistema.id = @idUsuarioContaSistema

							-- http://www.sommarskog.se/dyn-search.html
							OPTION (RECOMPILE);
				end
		end

	insert into @TableRet
	Select distinct * from @TableAux Tab order by Tab.UsuarioContaSistemaNome

	return
end;

CREATE function [dbo].[isEmail](@strAlphaNumeric VARCHAR(max))   
--Returns true if the string is a valid email address.  
RETURNS varchar(max)  
as  
BEGIN  
     DECLARE @valid bit = 0;

     IF @strAlphaNumeric IS NOT NULL AND LEN(@strAlphaNumeric) >= 6
		begin
          SET @strAlphaNumeric = rtrim(ltrim(LOWER(@strAlphaNumeric)))

		  if CHARINDEX(' ',@strAlphaNumeric) = 0
			begin
			  IF PATINDEX('%[^a-Z|0-9|!#$%&*+-/=$?^_+`{|}~.@-]%',@strAlphaNumeric) = 0
				 AND @strAlphaNumeric like '[a-z,0-9,_,-,$]%@[a-z,0-9,_,-]%.[a-z][a-z]%'
				 AND @strAlphaNumeric NOT like '%@%@%'  
				 AND CHARINDEX('.@',@strAlphaNumeric) = 0  
				 AND CHARINDEX('..',@strAlphaNumeric) = 0  
				 AND CHARINDEX(',',@strAlphaNumeric) = 0 
					begin
					   SET @valid=1  
					end
			end
		end

     RETURN @valid  
END;

CREATE function [dbo].[IsNullOrWhiteSpace](@texto varchar(max))
returns bit
as

begin
declare @ret bit

if @texto is null 
	begin
		return 1
	end


if LEN(LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(@texto,CHAR(10),''),CHAR(13),''),' ','')))) = 0
	set @ret = 1
else
	set @ret = 0

return @ret
end;

CREATE function [dbo].[ISZERO] (
    @Number FLOAT,
    @IsZeroNumber FLOAT
)
RETURNS FLOAT
AS
BEGIN

    IF (@Number = 0)
    BEGIN
        SET @Number = @IsZeroNumber
    END

    RETURN (@Number)

END;

CREATE function [dbo].LimparHashTag(@val varchar(max))
returns varchar(300)
as

begin
	return (select upper(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@val,'#',''),'@',''),',',''),' ',''),';',''),'<',''),'>','')) collate sql_latin1_general_cp1251_ci_as)
end;

CREATE procedure [dbo].[ProcAddInteracaoLote] 
	@IdContaSistema int,
	@IdUsuarioContaSistema int,
	@IdInteracaoTipo int,
	@DtInteracao datetime,
	@json varchar(max),
	@InteracaoAtorPartida varchar(15),
	@TipoCriacao varchar(15),
	@objVersao int,
	@xmlArrayIdsAtendimentos XML

as
	begin

		return

		declare @iQtdPorTransaction int = 20
		declare @tableIdAtendimento table (rowNumber int, idAtendimento int, idGuid char(36))
		declare @dtInclusao datetime = dbo.getdatecustom()

		declare @TabAuxInteracao table(id int, idContaSistema int, idSuperEntidade int, idInteracaoTipo int)

		insert into @tableIdAtendimento 
		select 
			ROW_NUMBER() OVER(ORDER BY Atendimento.id ASC) AS RowNumber,
			TabAux.ValInt, 
			NEWID() 
		from 
			dbo.SplitIDsXml(@xmlArrayIdsAtendimentos) TabAux
				inner join
			Atendimento with (nolock) on TabAux.ValInt = Atendimento.Id and Atendimento.IdContaSistema = @IdContaSistema


		declare @iCount int = (Select count(TabAux.rowNumber) from @tableIdAtendimento TabAux);
		declare @i int = 1;

		WHILE @i <= @iCount 
			BEGIN
				declare @iDessaVez int = @i + @iQtdPorTransaction

				BEGIN TRANSACTION
					insert
						into
							Interacao
								(
									IdContaSistema,
									IdSuperEntidade,
									IdUsuarioContaSistema,
									DtInclusao,
									Tipo,
									IdUsuarioContaSistemaRealizou,
									IdCanal,
									IdInteracaoTipo,
									InteracaoAtorPartida,
									DtInteracao,
									DtConclusao,
									Realizado,
									IdGuid,
									ObjTipo,
									ObjVersao,
									ObjTipoSub,
									TipoCriacao
								)  OUTPUT inserted.Id, inserted.IdContaSistema, inserted.IdSuperEntidade, inserted.IdInteracaoTipo into @TabAuxInteracao
						Select
							@IdContaSistema,
							TableAux.idAtendimento,
							@IdUsuarioContaSistema,
							@dtInclusao,
							'INTERACAOGERAL',
							@IdUsuarioContaSistema,
							null,
							@IdInteracaoTipo,
							@InteracaoAtorPartida,
							@DtInteracao,
							@DtInteracao,
							1,
							NEWID(),
							'SuperCRM.DTO.InteracaoGeral.InteracaoGeralPersistDTO',
							@objVersao,
							JSON_VALUE(@json,'$.ObjType'),
							@TipoCriacao

						from
							@tableIdAtendimento TableAux
						WHERE
							TableAux.rowNumber between @i and @iDessaVez

					insert 
						into InteracaoObj
							(
								Id,
								IdContaSistema,
								IdSuperEntidade,
								ObjTipo,
								ObjVersao,
								ObjTipoSub,
								ObjJson
							)
						Select 
							TabAux.id,
							TabAux.idContaSistema,
							TabAux.idSuperEntidade,
							'SuperCRM.DTO.InteracaoGeral.InteracaoGeralPersistDTO' as ObjTipo,
							@objVersao as ObjVersao,
							JSON_VALUE(@json,'$.ObjType') as ObjTipoSub,
							JSON_MODIFY(@json, '$.Obj.IdSuperEntidade', TabAux.idSuperEntidade) as ObjJson

						From
							@TabAuxInteracao TabAux
							

				COMMIT

				set @i = @i + @iQtdPorTransaction + 1
			END

	end;

CREATE procedure [dbo].[ProcAjustarCanalCarteiraCorretorCampanha]
as
begin
		
	declare @dtnow datetime = dbo.getDateCustom()
	declare @dtReferenciaUtilizarMaximo datetime = @dtnow
	declare @BatchNome varchar(1000) = 'Batch_AjustarCanalCarteiraCorretorCampanha'
	declare @dtUltimaAtualizacao datetime
	declare @GerarTudo bit = 1
	declare @errorSys bit = 0
	declare @erroMsg varchar(max) = ''
    
	select @dtUltimaAtualizacao = Max(TabelaoLog.Data2) from TabelaoLog with (nolock) where TabelaoLog.Nome = @BatchNome group by TabelaoLog.Nome

	-- Se o processamento atual não for de gerar tudo e a data não for nula
	-- Subentende-se que no momento está sendo atualizado e não deve rodar 2 atualizações ao mesmo tempo
	-- testará tb se faz mais de 120 minutos que a ultima query executou nesse caso irá considerar que hove erro e executará 
	-- zerando a hora para não ter problemas
	if (@dtUltimaAtualizacao is not null and DATEDIFF(MI, @dtUltimaAtualizacao, dbo.GetDateCustom()) < 180)
		begin
			return
		end
	

		-- Executar na sequência
		-- 09/01/2017

		-- Setará o canal padrão nas campanhas a qual não existe nenhum canal padrão carteira setado e exista ao menos um canal do tipo CARTEIRA
		update CampanhaCanal set CanalPadraoCarteira = 1
		from
			CampanhaCanal with (nolock)
				inner join
			(
				Select 
					min(CampanhaCanalAux.Id) as CampanhaCanalId
				From
					CampanhaCanal  CampanhaCanalAux with (nolock)
						INNER JOIN
					Canal with (nolock) on CampanhaCanalAux.IdCanal = Canal.Id
				where
					Canal.Tipo = 'CARTEIRA'
						and
					Canal.Status = 'AT'
						AND
					NOT EXISTS 
								(
									Select 
										CC.Id
									From 
										CampanhaCanal CC with (nolock)
											inner join
										Canal CanalAux with (nolock) on CanalAux.Id = CC.IdCanal
									where
										CC.IdCampanha = CampanhaCanalAux.IdCampanha
											and
										CC.CanalPadraoCarteira = 1
											AND
										CanalAux.Status = 'AT'
								)
				group by
					CampanhaCanalAux.IdCampanha
			) TabAux on CampanhaCanal.Id = TabAux.CampanhaCanalId


		-- Setará o canal padrão nas campanhas a qual não existe nenhum canal padrão carteira setado e exista ao menos um canal do tipo FISICO
		update CampanhaCanal set CanalPadraoCarteira = 1
		from
			CampanhaCanal with (nolock)
				inner join
			(
				Select 
					min(CampanhaCanalAux.Id) as CampanhaCanalId
				From
					CampanhaCanal CampanhaCanalAux with (nolock)
						INNER JOIN
					Canal with (nolock) on CampanhaCanalAux.IdCanal = Canal.Id
				where
					Canal.Tipo = 'FISICO'
						and
					Canal.Status = 'AT'
						AND
					NOT EXISTS 
								(
									Select 
										CC.Id
									From 
										CampanhaCanal CC with (nolock)
											inner join
										Canal CanalAux with (nolock) on CanalAux.Id = CC.IdCanal
									where
										CC.IdCampanha = CampanhaCanalAux.IdCampanha
											and
										CC.CanalPadraoCarteira = 1
											AND
										CanalAux.Status = 'AT'
								)
				group by
					CampanhaCanalAux.IdCampanha
			) TabAux on CampanhaCanal.Id = TabAux.CampanhaCanalId

		-- Setará o canal padrão nas campanhas a qual não existe nenhum canal padrão carteira setado e exista ao menos um canal do tipo FALECONOSCO
		update CampanhaCanal set CanalPadraoCarteira = 1
		from
			CampanhaCanal with (nolock)
				inner join
			(
				Select 
					min(CampanhaCanalAux.Id) as CampanhaCanalId
				From
					CampanhaCanal CampanhaCanalAux with (nolock)
						INNER JOIN
					Canal with (nolock) on CampanhaCanalAux.IdCanal = Canal.Id
				where
					Canal.Tipo = 'FALECONOSCO'
						and
					Canal.Status = 'AT'
						AND
					NOT EXISTS 
								(
									Select 
										CC.Id
									From 
										CampanhaCanal CC with (nolock)
											inner join 
										Canal CanalAux with (nolock) on CanalAux.Id = CC.IdCanal
									where
										CC.IdCampanha = CampanhaCanalAux.IdCampanha
											and
										CC.CanalPadraoCarteira = 1
											AND
										CanalAux.Status = 'AT'
								)
				group by
					CampanhaCanalAux.IdCampanha
			) TabAux on CampanhaCanal.Id = TabAux.CampanhaCanalId


		-- Setará o canal padrão nas campanhas a qual não existe nenhum canal padrão carteira setado e que o tipo do canal não seja CHAT
		-- Só cairá nesse caso caso nenhum acima tenha dado certo
		update CampanhaCanal set CanalPadraoCarteira = 1
		from
			CampanhaCanal with (nolock)
				inner join
			(
				Select 
					min(CampanhaCanalAux.Id) as CampanhaCanalId
				From
					CampanhaCanal CampanhaCanalAux with (nolock)
						INNER JOIN
					Canal with (nolock) on CampanhaCanalAux.IdCanal = Canal.Id
				where
					(Canal.Tipo <> 'CHAT' and Canal.Tipo <> 'ATIVO')
						and
					Canal.Status = 'AT'
						AND
					NOT EXISTS 
								(
									Select 
										CC.Id
									From 
										CampanhaCanal CC with (nolock)
											inner join
										Canal CanalAux with (nolock) on CanalAux.Id = CC.IdCanal
									where
										CC.IdCampanha = CampanhaCanalAux.IdCampanha
											and
										CC.CanalPadraoCarteira = 1
											AND
										CanalAux.Status = 'AT'
								)
				group by
					CampanhaCanalAux.IdCampanha
			) TabAux on CampanhaCanal.Id = TabAux.CampanhaCanalId


			Update 
	TabelaoLog 
	Set
	-- Adiciona 2 milesegundo desde a última execução para considerar todos atualizados desde a última atualização
	-- 2 pq é o mínimo que pode adicionar
	TabelaoLog.Data1 = @dtReferenciaUtilizarMaximo,
	TabelaoLog.Data2 = null,
	TabelaoLog.bit1 = 0,
	TabelaoLog.DtUltimaParcial = case when @GerarTudo = 0 then dbo.GetDateCustom() else TabelaoLog.DtUltimaParcial end,
	TabelaoLog.DtUltimaCompleta = case when @GerarTudo = 1 then dbo.GetDateCustom() else TabelaoLog.DtUltimaCompleta end
where
	TabelaoLog.Nome = @BatchNome

end;

-- Atualiza os grupos dos atendimentos que não estão setados a nenhum usuário
-- e que o grupo atual não está alocado a campanha em questão ou está sem grupo
-- 07/11/2017
CREATE procedure [dbo].[ProcAjustarGrupoAtendimentoNaoAlocadoCampanha]
as
begin
	declare @dateNow datetime = dbo.getdatecustom()
	declare @dateNowVarchar varchar(50) = convert(varchar(50), @dateNow, 126)
	declare @objVersaoInt int = 2019073118;
	declare @objVersaoVarchar varchar(12) = '2019073118';

	declare @TabAuxInteracao table(id int, idContaSistema int, idSuperEntidade int, idInteracaoTipo int)


	-- Exclui a tabela temporária caso a mesma exista
	IF OBJECT_ID('tempdb..#NewTableTemp') IS NOT NULL DROP TABLE #NewTableTemp

	-- Seleciona e insere na tabela temporária todos atendimentos que não
	-- está setada a nenhum usuário e o grupo do atendimento não faz mais parte da campanha
	Select top (1000)
		(
			Select max(CampanhaGrupo.IdGrupo)
			from CampanhaGrupo  with (nolock)
			where CampanhaGrupo.IdCampanha = Atendimento.idCampanha
		) as GrupoIdNew,
		Atendimento.idGrupo as GrupoIdOld,
		Atendimento.Id as AtendimentoId,
		Atendimento.idCampanha as CampanhaId,
		Atendimento.IdContaSistema as ContaSistemaId

	INTO #NewTableTemp

	From 
		Atendimento with (nolock)
			inner join
		ContaSistema with (nolock) on Atendimento.IdContaSistema = ContaSistema.Id
			left outer join
		CampanhaGrupo with (nolock) on CampanhaGrupo.IdCampanha = Atendimento.idCampanha and CampanhaGrupo.IdGrupo = Atendimento.idGrupo
	where
		ContaSistema.Status = 'AT'
			and
		-- SE FAZ necessário para evitar que atendimentos que estão aguardnado atendimento e esteja nulo não seja afetado
		Atendimento.StatusAtendimento <> 'AGUARDANDOATENDIMENTO'
			and
		Atendimento.IdUsuarioContaSistemaAtendimento is null
			and
		CampanhaGrupo.Id is null
			and
		exists
		(
			Select CampanhaGrupo.id
			from CampanhaGrupo  with (nolock)
			where CampanhaGrupo.IdCampanha = Atendimento.idCampanha
		)


	-- Atualiza o atendimento com o novo grupo
	update Atendimento set Atendimento.idGrupo = TableTemp.GrupoIdNew
	From 
		Atendimento with (nolock)
			inner join 
		#NewTableTemp TableTemp with (nolock) on Atendimento.Id = TableTemp.AtendimentoId

	-- Insere os logs nos atendimentos informando sobre a mudança
	insert 
		into Interacao 
			(
				IdContaSistema,
				IdSuperEntidade,
				IdUsuarioContaSistema,
				DtInclusao,
				DtInteracao,
				Tipo,
				IdUsuarioContaSistemaRealizou,
				IdInteracaoTipo,
				InteracaoAtorPartida,
				DtConclusao,
				Realizado,
				IdGuid,
				ObjTipo,
				ObjVersao,
				ObjTipoSub,
				TipoCriacao
			) OUTPUT inserted.Id, inserted.IdContaSistema, inserted.IdSuperEntidade, inserted.IdInteracaoTipo into @TabAuxInteracao
	Select
		TabTemp.ContaSistemaId,
		TabTemp.AtendimentoId as IdSuperEntidade,
		null as IdUsuarioContaSistema,
		@dateNow as DtInclusao,
		@dateNow as DtInteracao,
		'INTERACAOGERAL' as Tipo,
		null as IdUsuarioContaSistemaRealizou,
		InteracaoTipo.Id as IdInteracaoTipo,
		'AUTO' as InteracaoAtorPartida,
		@dateNow as DtConclusao,
		1 as Realizado,
		NEWID() as idGuid,
		'SuperCRM.DTO.InteracaoGeral.InteracaoGeralPersistDTO' as ObjTipo,
		@objVersaoInt as ObjVersao,
		'SuperCRM.DTO.InteracaoGeral.InteracaoGeralLogDTO' as ObjTipoSub,
		'AUTO' as TipoCriacao

	From 
		#NewTableTemp TabTemp with (nolock)
			inner join
		InteracaoTipo with (nolock) on InteracaoTipo.IdContaSistema = TabTemp.ContaSistemaId and InteracaoTipo.Tipo = 'LOG' AND InteracaoTipo.Sistema = 1



	insert 
		into InteracaoObj
			(
				Id,
				IdContaSistema,
				IdSuperEntidade,
				ObjTipo,
				ObjVersao,
				ObjTipoSub,
				ObjJson
			)
		Select 
			TabAux.id,
			TabAux.idContaSistema,
			TabAux.idSuperEntidade,
			'SuperCRM.DTO.InteracaoGeral.InteracaoGeralPersistDTO' as ObjTipo,
			@objVersaoInt as ObjVersao,
			'SuperCRM.DTO.InteracaoGeral.InteracaoGeralLogDTO' as ObjTipoSub,
			N'{"Type":"SuperCRM.DTO.InteracaoGeral.InteracaoGeralPersistDTO",
				"Texto":"",
				"Versao":'+@objVersaoVarchar+',
				"VersaoObj":'+@objVersaoVarchar+',"InteracaoTipoSys":"LOG","ObjType":"SuperCRM.DTO.InteracaoGeral.InteracaoGeralLogDTO","Obj":{"$type":"SuperCRM.DTO.InteracaoGeral.InteracaoGeralLogDTO, SuperCRM",
				"AtorPartida":"AUTO",
				"LogTipo":"ATENDIMENTO_GRUPO_ALTERADO",
				"Texto":"'+STRING_ESCAPE('Grupo do atendimento ('+ isnull(GrupoOld.Nome, 'sem grupo') +') alterado para ('+GrupoNew.Nome+') pois o mesmo não estava mais setado a nenhum usuário e o grupo do atendimento ('+ isnull(GrupoOld.Nome, 'sem grupo') +') não fazia mais parte da campanha ('+ isnull(Campanha.Nome, 'sem campanha') +').','json')+'",
				"IdUsuarioContaSistema":null,
				"VariaveisTipadas":{},
				"Variaveis":{},
				"DtMigracao":null,
				"Versao":'+@objVersaoVarchar+',
				"InteracaoTipoId":'+convert(varchar(15),TabAux.idInteracaoTipo)+',
				"InteracaoTipoIdGuid":null,
				"Tipo":"LOG",
				"DtInclusao":"'+@dateNowVarchar+'",
				"TextoAutomatico":false,
				"IdContaSistema":'+convert(varchar(15),TabAux.IdContaSistema)+',
				"IdSuperEntidade":'+convert(varchar(15),TabAux.idSuperEntidade)+',
				"TipoCriacao":"AUTO"}}' as ObjJson

		From
			@TabAuxInteracao TabAux
				inner join
			#NewTableTemp TabTemp with (nolock) on TabTemp.AtendimentoId = TabAux.idSuperEntidade
				inner join
			Campanha with (nolock) on Campanha.Id = TabTemp.CampanhaId
				left outer join
			Grupo GrupoNew with (nolock) on TabTemp.GrupoIdNew = GrupoNew.Id
				left outer join
			Grupo GrupoOld with (nolock) on TabTemp.GrupoIdOld = GrupoOld.Id


	drop table #NewTableTemp

end;

-- Atualiza os grupos dos atendimentos a qual o grupo do atendimento esteja setado a um usuário que por ventura
-- não faz parte do grupo do atendimento mas faz parte de outro grupo da campanha
-- setará o grupo da campanha a qual o usuário do atendimento faça parte
CREATE procedure [dbo].[ProcAjustarGrupoAtendimentoUsuario]
as
begin
	declare @dateNow datetime = dbo.getdatecustom()
	declare @dateNowVarchar varchar(50) = convert(varchar(50), @dateNow, 126)
	declare @objVersaoInt int = 2019073118;
	declare @objVersaoVarchar varchar(12) = '2019073118';

	declare @TabAuxInteracao table(id int, idContaSistema int, idSuperEntidade int, idInteracaoTipo int);


	-- Exclui a tabela temporária caso a mesma exista
	IF OBJECT_ID('tempdb..#NewTableTemp2') IS NOT NULL DROP TABLE #NewTableTemp2

	-- Seleciona e insere na tabela temporária todos atendimentos que não
	Select top (1000)
			(
				Select 
					max(CampanhaGrupo.IdGrupo) as idGrupo

				from
					CampanhaGrupo with (Nolock)
						inner join
					Grupo  with (Nolock) on Grupo.Id = CampanhaGrupo.IdGrupo
						inner join
					GetGrupoUsuarioTodosEInferiores(Atendimento.IdUsuarioContaSistemaAtendimento) TabAux1 on TabAux1.Id = CampanhaGrupo.IdGrupo
				where
					-- Se faz necessário para não recuperar atendimentos que estejam no grupo padrão já que se o grupo
					-- é o padrão provavelmente o usuário não está mais ativo ou o grupo do usuário não estão ativados
					--Grupo.Padrao = 0
					--	and
					Grupo.Status = 'AT'
						and
					CampanhaGrupo.IdCampanha = Atendimento.idCampanha
						and
					CampanhaGrupo.Status = 'AT'
						and
					(
						TabAux1.IsAdministrador = 1
							or
						TabAux1.IsUsuario = 1
					)
			) as GrupoIdNew,
			Atendimento.idGrupo as GrupoIdOld,
			Atendimento.Id as AtendimentoId,
			Atendimento.idCampanha as CampanhaId,
			Atendimento.IdUsuarioContaSistemaAtendimento as IdUsuarioContaSistemaAtendimento,
			Atendimento.IdContaSistema as ContaSistemaId

		into #NewTableTemp2

	from
		Atendimento with (nolock)
			inner join
		UsuarioContaSistema with (nolock) on Atendimento.IdUsuarioContaSistemaAtendimento = UsuarioContaSistema.Id
			inner join
		ContaSistema with (nolock) on ContaSistema.Id = UsuarioContaSistema.idContaSistema
			left outer join
		UsuarioContaSistemaGrupo with (Nolock) on UsuarioContaSistemaGrupo.IdGrupo = Atendimento.idGrupo and UsuarioContaSistemaGrupo.IdUsuarioContaSistema = Atendimento.IdUsuarioContaSistemaAtendimento and UsuarioContaSistemaGrupo.DtFim is null
			left outer join
		UsuarioContaSistemaGrupoAdm with (Nolock) on UsuarioContaSistemaGrupoAdm.IdGrupo = Atendimento.idGrupo and UsuarioContaSistemaGrupoAdm.IdUsuarioContaSistema = Atendimento.IdUsuarioContaSistemaAtendimento and UsuarioContaSistemaGrupoAdm.DtFim is null

	where
		Atendimento.IdUsuarioContaSistemaAtendimento is not null
			and
		Atendimento.StatusAtendimento <> 'AGUARDANDOATENDIMENTO'
			and
		ContaSistema.Status = 'AT'
			and
		UsuarioContaSistemaGrupo.Id is null
			and
		UsuarioContaSistemaGrupoAdm.Id is null
			and
		exists
		(
			Select
				CampanhaGrupo.Id

			from
				CampanhaGrupo with (Nolock)
					inner join
				Grupo  with (Nolock) on Grupo.Id = CampanhaGrupo.IdGrupo
					inner join
				GetGrupoUsuarioTodosEInferiores(Atendimento.IdUsuarioContaSistemaAtendimento) as TabAux1 on TabAux1.Id = CampanhaGrupo.IdGrupo
			where
				Grupo.Status = 'AT'
					and
				CampanhaGrupo.IdCampanha = Atendimento.idCampanha
					and
				CampanhaGrupo.Status = 'AT'
					and
				(
					TabAux1.IsAdministrador = 1
						or
					TabAux1.IsUsuario = 1
				)
		)

	-- Atualiza o atendimento com o novo grupo
	update Atendimento set Atendimento.idGrupo = TableTemp.GrupoIdNew
	From 
		Atendimento with (nolock)
			inner join 
		#NewTableTemp2 TableTemp with (nolock) on Atendimento.Id = TableTemp.AtendimentoId

	-- Insere os logs nos atendimentos informando sobre a mudança
	insert 
		into Interacao 
			(
				IdContaSistema,
				IdSuperEntidade,
				IdUsuarioContaSistema,
				DtInclusao,
				DtInteracao,
				Tipo,
				IdUsuarioContaSistemaRealizou,
				IdInteracaoTipo,
				InteracaoAtorPartida,
				DtConclusao,
				Realizado,
				IdGuid,
				ObjTipo,
				ObjVersao,
				ObjTipoSub,
				TipoCriacao
			) OUTPUT inserted.Id, inserted.IdContaSistema, inserted.IdSuperEntidade, inserted.IdInteracaoTipo into @TabAuxInteracao
	Select
		TabTemp.ContaSistemaId,
		TabTemp.AtendimentoId as IdSuperEntidade,
		null as IdUsuarioContaSistema,
		@dateNow as DtInclusao,
		@dateNow as DtInteracao,
		'INTERACAOGERAL' as Tipo,
		null as IdUsuarioContaSistemaRealizou,
		InteracaoTipo.Id as IdInteracaoTipo,
		'AUTO' as InteracaoAtorPartida,
		@dateNow as DtConclusao,
		1 as Realizado,
		NEWID() as idGuid,
		'SuperCRM.DTO.InteracaoGeral.InteracaoGeralPersistDTO' as ObjTipo,
		@objVersaoInt as ObjVersao,
		'SuperCRM.DTO.InteracaoGeral.InteracaoGeralLogDTO' as ObjTipoSub,
		'AUTO' as TipoCriacao

	From 
		#NewTableTemp2 TabTemp with (nolock)
			inner join
		InteracaoTipo with (nolock) on InteracaoTipo.IdContaSistema = TabTemp.ContaSistemaId and InteracaoTipo.Tipo = 'LOG' AND InteracaoTipo.Sistema = 1

	insert 
		into InteracaoObj
			(
				Id,
				IdContaSistema,
				IdSuperEntidade,
				ObjTipo,
				ObjVersao,
				ObjTipoSub,
				ObjJson
			)
		Select 
			TabAux.id,
			TabAux.idContaSistema,
			TabAux.idSuperEntidade,
			'SuperCRM.DTO.InteracaoGeral.InteracaoGeralPersistDTO' as ObjTipo,
			@objVersaoInt as ObjVersao,
			'SuperCRM.DTO.InteracaoGeral.InteracaoGeralLogDTO' as ObjTipoSub,
			N'{"Type":"SuperCRM.DTO.InteracaoGeral.InteracaoGeralPersistDTO",
			"Texto":"",
			"Versao":'+@objVersaoVarchar+',
			"VersaoObj":'+@objVersaoVarchar+',"InteracaoTipoSys":"LOG","ObjType":"SuperCRM.DTO.InteracaoGeral.InteracaoGeralLogDTO","Obj":{"$type":"SuperCRM.DTO.InteracaoGeral.InteracaoGeralLogDTO, SuperCRM",
			"AtorPartida":"AUTO",
			"LogTipo":"ATENDIMENTO_GRUPO_ALTERADO",
			"Texto":"'+STRING_ESCAPE('Grupo do atendimento ('+ isnull(GrupoOld.Nome, 'sem grupo') +') alterado para ('+GrupoNew.Nome+') pois o usuário ('+Pessoa.Nome+') não fazia mais parte do grupo ('+ isnull(GrupoOld.Nome, 'sem grupo') +') mas fazia parte do novo grupo ('+GrupoNew.Nome+') do atendimento.','json')+'",
			"IdUsuarioContaSistema":null,
			"VariaveisTipadas":{},
			"Variaveis":{},
			"DtMigracao":null,
			"Versao":'+@objVersaoVarchar+',
			"InteracaoTipoId":'+convert(varchar(15), TabAux.idInteracaoTipo)+',
			"InteracaoTipoIdGuid":null,
			"Tipo":"LOG",
			"DtInclusao":"'+@dateNowVarchar+'",
			"IdContaSistema":'+convert(varchar(15),TabAux.idContaSistema)+',
			"IdSuperEntidade":'+convert(varchar(15),TabAux.idSuperEntidade)+',
			"TextoAutomatico":false,
			"TipoCriacao":"AUTO"}}' as ObjJson

		From
			@TabAuxInteracao TabAux
				inner join
			#NewTableTemp2 TabTemp with (nolock) on TabTemp.AtendimentoId = TabAux.idSuperEntidade
				inner join
			UsuarioContaSistema with (nolock) on UsuarioContaSistema.Id = TabTemp.IdUsuarioContaSistemaAtendimento
				inner join
			Pessoa with (nolock) on UsuarioContaSistema.IdPessoa = Pessoa.Id
				left outer join
			Grupo GrupoNew with (nolock) on TabTemp.GrupoIdNew = GrupoNew.Id
				left outer join
			Grupo GrupoOld with (nolock) on TabTemp.GrupoIdOld = GrupoOld.Id

	drop table #NewTableTemp2

end;

CREATE procedure [dbo].[ProcAjustarIntegradoraExternaMidia]
as
begin
	declare @BatchNome varchar(1000) = 'Batch_AjustarIntegradoraExternaMidia'
	declare @DtNow datetime = dbo.GetDateCustom()

	declare @IdOutros int = (select Id from IntegradoraExterna where StrKey = '1B4C68DC-166B-45FB-90EC-2C3C6633688E')
	declare @IdPortaisImoveis int = (select Id from IntegradoraExterna where StrKey = '51DE5556-0716-494A-840C-0D968DC13476')
	declare @IdTelemarketing int = (select Id from IntegradoraExterna where StrKey = 'c2a13702-50f3-4e47-b69e-69e579c35a49')
	declare @IdDisplay int = (select Id from IntegradoraExterna where StrKey = '0cbfcf12-1456-4caf-b82e-4d217e3c7458')
	declare @IdDoubleClick int = (select Id from IntegradoraExterna where StrKey = 'bc91ae3e-4fac-4d24-91ef-8f00d24fc100')
	declare @IdEstadao int = (select Id from IntegradoraExterna where StrKey = '3d620be0-4ac5-491c-8101-f800663afa66')
	declare @IdCarroDeSom int = (select Id from IntegradoraExterna where StrKey = '7a5b1edb-2398-4fa9-b4ee-dce4921eb269')
	declare @IdGloboCom int = (select Id from IntegradoraExterna where StrKey = '4b856775-2ceb-4ded-98c2-3dec2bf4ad75')
	declare @IdBrasil247 int = (select Id from IntegradoraExterna where StrKey = '7aef0e9c-18c3-4fca-acd3-6384986a0f40')
	declare @IdPadaria int = (select Id from IntegradoraExterna where StrKey = '45e22b93-0fce-4ed8-8385-9bba0da7ca0d')
	declare @IdSite int = (select Id from IntegradoraExterna where StrKey = 'B00AE86F-DBE0-4762-8F60-10CDF593DB1C')
	declare @IdOutdoor int = (select Id from IntegradoraExterna where StrKey = '476B45AD-656C-4641-9B0C-85722A21AC85')
	declare @IdPanfletagem int = (select Id from IntegradoraExterna where StrKey = 'FA5001EB-F4D8-4548-870D-AC69F0A0F71A')
	declare @IdStand int = (select Id from IntegradoraExterna where StrKey = 'F28DAB91-452B-492F-82AB-90C0F33E5B97')
	declare @IdEvento int = (select Id from IntegradoraExterna where StrKey = '9E445B47-607B-4E29-A188-5FD2BE23D63D')
	declare @IdJornal int = (select Id from IntegradoraExterna where StrKey = '9414CC83-50F9-4012-B667-D519DCA761AA')
	declare @IdEmailMarketing int = (select Id from IntegradoraExterna where StrKey = 'D02656AC-C6D3-4A90-A326-D0BCC20CD090')
	declare @IdRadio int = (select Id from IntegradoraExterna where StrKey = '6282F173-7307-4AA1-B9F3-7837E155F347')
	declare @IdMailing int = (select Id from IntegradoraExterna where StrKey = 'FF2C93F6-5474-4715-A0B6-9C1EB65A7FC5')
	declare @IdTv int = (select Id from IntegradoraExterna where StrKey = '42751CB4-5894-42C7-BF3E-88EF7CE29FC9')
	declare @IdLinkedin int = (select Id from IntegradoraExterna where StrKey = 'E0439989-38C3-42F4-8346-8C8BD9511BEB')
	declare @IdRevista int = (select Id from IntegradoraExterna where StrKey = 'F74E9D0B-C1D2-46C0-AECD-2DD395F7023B')
	declare @IdIndicacao int = (select Id from IntegradoraExterna where StrKey = 'B1AFD06B-2C30-42B4-9060-6891DB48234F')
	declare @IdLandingPage int = (select Id from IntegradoraExterna where StrKey = '66E849AD-A6A2-4C9F-9B3C-7A9CBD0FC6CD')
	declare @IdMalaDireta int = (select Id from IntegradoraExterna where StrKey = '40134BBA-1EEA-476D-8BD6-BC98B3F89B87')
	declare @IdCorretor int = (select Id from IntegradoraExterna where StrKey = '84B9F764-481C-4905-B0DF-DFD7B4D78A12')
	declare @IdSms int = (select Id from IntegradoraExterna where StrKey = '50A1964E-ABB2-4613-99E0-14D6ECD604AC')
	declare @IdWhatsApp int = (select Id from IntegradoraExterna where StrKey = 'C3BE3762-1AA5-46F1-B9B4-0B3B8079B158')
	declare @IdFolheto int = (select Id from IntegradoraExterna where StrKey = '56E1E7FE-80BF-4413-9F3C-E55F14F5D97D')
	declare @IdTelefone int = (select Id from IntegradoraExterna where StrKey = '4508EA1D-65BF-4A4C-AB1F-6220D4E24654')
	declare @IdInternet int = (select Id from IntegradoraExterna where StrKey = '201B2769-A8F8-4FB5-9577-4C72D844F912')
	declare @IdBing int = (select Id from IntegradoraExterna where StrKey = 'C4403CF1-4229-4A57-8EED-F025B37808E7')
	declare @IdYahoo int = (select Id from IntegradoraExterna where StrKey = '34A8507C-C7B2-4AAA-B07B-E2DD7C8FDB8B')
	declare @IdCinema int = (select Id from IntegradoraExterna where StrKey = 'E87FC923-C24E-499C-9DF0-D519DCCF4E17')
	declare @IdWaze int = (select Id from IntegradoraExterna where StrKey = '494AE238-739A-4B2B-84B5-24928FB48D86')
	declare @IdTwitter int = (select Id from IntegradoraExterna where StrKey = '6A54507B-3666-440B-AEAD-008ECAF50D5E')
	declare @IdSpImoveis int = (select Id from IntegradoraExterna where StrKey = '949c0693-84dc-47df-ac9b-523e0336c3f0')
	declare @IdLoopImoveis int = (select Id from IntegradoraExterna where StrKey = 'b0f01f54-bdf9-4467-9848-8217b72695fa')
	declare @IdAgenteImovel int = (select Id from IntegradoraExterna where StrKey = '16913da3-7568-44b2-9c6d-661150efbb11')
	declare @IdImovelK int = (select Id from IntegradoraExterna where StrKey = 'b02e4275-8462-450e-aa60-dfa4aa3557a3')
	declare @IdProperati int = (select Id from IntegradoraExterna where StrKey = '73711f85-95f9-4b3f-aa69-9a132d9bd71c')
	declare @IdRdStation int = (select Id from IntegradoraExterna where StrKey = '2af9ffc0-e8d8-4337-a2b5-6b14177bf3d7')
	declare @IdStoria int = (select Id from IntegradoraExterna where StrKey = '09fd4cd8-cb78-43c3-a82c-c33af2956350')
	declare @IdMercadoLivre int = (select Id from IntegradoraExterna where StrKey = '685d26fc-26aa-4949-be0c-a0f83bb48970')
	declare @IdMeuImovel int = (select Id from IntegradoraExterna where StrKey = 'df793a77-30dd-40a8-ba2a-6999f4a71598')
	declare @IdMoving int = (select Id from IntegradoraExterna where StrKey = '993bb18a-517c-44c3-b4b2-f0c447fbb2a4')
	declare @IdAptoVc int = (select Id from IntegradoraExterna where StrKey = '07a1278b-aa6d-4324-80a0-26104534a61a')
	declare @IdImovelWeb int = (select Id from IntegradoraExterna where StrKey = '52185741-31b4-4ac3-a92b-4c766d15f6fc')
	declare @IdReweb int = (select Id from IntegradoraExterna where StrKey = '265a3655-6da9-40f5-b1ea-d9c05ab1145b')
	declare @IdZapImoveis int = (select Id from IntegradoraExterna where StrKey = 'ef4b59eb-1323-4df1-a6f8-e88ba79c4138')
	declare @IdZapier int = (select Id from IntegradoraExterna where StrKey = '20f69f84-377b-451f-8b9e-b3ad7971bb53')
	declare @IdGrupoZap int = (select Id from IntegradoraExterna where StrKey = '72900f0b-f577-4ab3-946c-98281e84ff60')
	declare @IdVivaReal int = (select Id from IntegradoraExterna where StrKey = '345c6b1e-33e9-45ca-a988-1182774f44c5')
	declare @IdGoogle int = (select Id from IntegradoraExterna where StrKey = 'cc5cb6d3-16ce-48c2-bbaa-c17c932109eb')
	declare @Id123Imoveis int = (select Id from IntegradoraExterna where StrKey = '79494f07-3aa2-4c43-9e32-11942a412820')
	declare @IdOlx int = (select Id from IntegradoraExterna where StrKey = 'ee10689f-1e6b-44b3-aa44-835138a43ba4')
	declare @IdYouTube int = (select Id from IntegradoraExterna where StrKey = 'c952e27a-47a2-4b02-b190-4d7abec8e4a1')
	declare @IdInstagram int = (select Id from IntegradoraExterna where StrKey = '739cdc08-c186-4364-8dfa-a9cf7395d889')
	declare @IdFacebook int = (select Id from IntegradoraExterna where StrKey = 'b0b3ddb3-e1c5-442d-b56a-11a53b235fd3')
	declare @IdUol int = (select Id from IntegradoraExterna where StrKey = 'ba4b7c42-cb48-4832-9a55-22ccd17a9511')
	declare @idCasafy int = (select Id from IntegradoraExterna where StrKey = '14a414ce-129a-4cfd-9504-1a2899fb522b')
	declare @idShop int = (select Id from IntegradoraExterna where StrKey = 'cd1689ce-5989-4d01-a881-bc51a1dbaf2e')
	declare @idTerra int = (select Id from IntegradoraExterna where StrKey = 'f5f5cf39-12b9-4134-afc2-6c9abf9455f9')
	declare @idMetro int = (select Id from IntegradoraExterna where StrKey = 'cf68516e-ef2d-40d9-a957-a6e2d7d7e97b')
	declare @idAbyara int = (select Id from IntegradoraExterna where StrKey = '3bffca5c-5ef8-4a60-8c6a-862fc3b4fde3')	
	declare @idBrasilBrokers int = (select Id from IntegradoraExterna where StrKey = 'c40104db-b711-450f-9f1a-3924480a769f')
	declare @idAnapro int = (select Id from IntegradoraExterna where StrKey = '4eb837cd-5c97-4c1c-99ad-c44d28910758')
	declare @idOnibus int = (select Id from IntegradoraExterna where StrKey = 'beb672a7-f382-4ea2-bebf-2c11e5ef1a45')
	declare @idChat int = (select Id from IntegradoraExterna where StrKey = 'be17c847-bce0-43c1-8367-b2017dab6e03')
	declare @idDgbz int = (select Id from IntegradoraExterna where StrKey = 'fef8e01a-8346-4147-9333-2442cb4534ae')
	declare @idTaboola int = (select Id from IntegradoraExterna where StrKey = '48a04f3a-bf09-462e-86f4-98ef72e90394')
	declare @idAptoNovo int = (select Id from IntegradoraExterna where StrKey = '24f3bf27-4cac-431e-9ad0-8c99e0892ec7')
	declare @idMidiaPadrao int = (select Id from IntegradoraExterna where StrKey = '580a0b4e-989b-4512-a192-6745e675f755')
	declare @idHypnoBox int = (select Id from IntegradoraExterna where StrKey = '443260d9-62e8-48e3-80f8-bdcdbba0d91a')
	declare @idMEDIAGRUPPE int = (select Id from IntegradoraExterna where StrKey = '374084ee-f899-4da1-853d-df9f0686a7d8')
	declare @idIngaia int = (select Id from IntegradoraExterna where StrKey = '75a14e0f-291b-418e-b4c1-e90719c19695')	
	declare @idLINKTREE int = (select Id from IntegradoraExterna where StrKey = '78af43f0-2f93-487f-aa82-547604756399')	

	-- A ordem dos updates deve ser mantida, pois uma mídia pode entrar em mais de um caso neste ajuste de integradoras. Portanto as mídias com prioridade maior, devem ser atualizadas no final
	-- Exemplo: Mídia com nome 'Site - Facebook' vai ser atualizada primeiro para a integradora SITE, mas no final do script será atualizada para a integradora FACEBOOK
	update Midia set IdIntegradoraExterna = @IdOutros, DtAtualizacao = @DtNow where (Nome like '%Postman%' or Nome like '%Super Mercado%' or Nome like '%SuperMercado%' or Nome like '%Proprietári%' or Nome like '%Promoção%' or Nome like '%Seta%' or Nome like '%Cancela%' or Nome like '%Faixa%' or Nome like '%Bandeira%' or Nome like '%Cavalete%' or Nome like '%Tapume%' or Nome like '%Placa%' or Nome like '%Outros%' or Nome = 'Outro') and (IdIntegradoraExterna is null or IdIntegradoraExterna <> @IdOutros)
	update Midia set IdIntegradoraExterna = @IdPortaisImoveis, DtAtualizacao = @DtNow where (Nome like '%Portal%' or Nome like '%Portais%' or Nome like '%LugarCerto%' or Nome like '%Lugar_Certo%' or Nome like '%Zn%') and (IdIntegradoraExterna is null or IdIntegradoraExterna <> @IdPortaisImoveis)
	update Midia set IdIntegradoraExterna = @IdSite, DtAtualizacao = @DtNow where ((Nome like '%Site%' and Nome not like '%Visite%') or Nome like '%www%' or Nome like '%http%' or Nome like '%acesso%direto%' or Nome like '%agend%visita%' or Nome like '%Institucional%' or Nome = 'direto') and (IdIntegradoraExterna is null or IdIntegradoraExterna <> @IdSite)
	update Midia set IdIntegradoraExterna = @IdOutdoor, DtAtualizacao = @DtNow where Nome like '%Outdoor%' and (IdIntegradoraExterna is null or IdIntegradoraExterna <> @IdOutdoor)
	update Midia set IdIntegradoraExterna = @IdPanfletagem, DtAtualizacao = @DtNow where (nome like '%de%Rua' or Nome like '%Panflet%' or nome like '%Aç%Rua%' or nome like '%blitz%' or nome like '%Banner%') and (IdIntegradoraExterna is null or IdIntegradoraExterna <> @IdPanfletagem)
	update Midia set IdIntegradoraExterna = @IdStand, DtAtualizacao = @DtNow where (Nome like '%Retorno%' or Nome like '%Stand%' or Nome like '%Quiosque%' or Nome like '%Pass%' or Nome = 'Espontâneo') and (IdIntegradoraExterna is null or IdIntegradoraExterna <> @IdStand)
	update Midia set IdIntegradoraExterna = @IdEvento, DtAtualizacao = @DtNow where (Nome like '%Evento%' or Nome like '%Feira%') and (IdIntegradoraExterna is null or IdIntegradoraExterna <> @IdEvento)
	update Midia set IdIntegradoraExterna = @IdJornal, DtAtualizacao = @DtNow where (Nome like '%Jornal%' or nome like '%Jornais%' or Nome like '%Correio Popular%' or Nome like '%Folha%' or Nome like '%OESP%' or Nome like '%estado de%' or Nome like '%estadode%' or Nome like '%Tribuna%' or Nome like '%Valor Econômico%' or Nome like '%Gazeta Mercantil%' or Nome like '%DCI%' or Nome like '%Correio Brasiliense%' or Nome like '%Correio %' or Nome like '%O Globo%') and (IdIntegradoraExterna is null or IdIntegradoraExterna <> @IdJornal)
	update Midia set IdIntegradoraExterna = @IdEmailMarketing, DtAtualizacao = @DtNow where (Nome like '%Email%' or Nome like '%E-mail%' or Nome like '%mkt%') and (IdIntegradoraExterna is null or IdIntegradoraExterna <> @IdEmailMarketing)
	update Midia set IdIntegradoraExterna = @IdRadio, DtAtualizacao = @DtNow where (Nome like '%Rádio%' or Nome like '%FM%') and (IdIntegradoraExterna is null or IdIntegradoraExterna <> @IdRadio)
	update Midia set IdIntegradoraExterna = @IdMailing, DtAtualizacao = @DtNow where (Nome like '%Mailing%' or Nome like '%Listagem Comprada%' or Nome like '%Mailling%' or Nome like '%Oferta%' or Nome like 'base %' or nome like '%Mainling%') and (IdIntegradoraExterna is null or IdIntegradoraExterna <> @IdMailing)
	update Midia set IdIntegradoraExterna = @IdTv, DtAtualizacao = @DtNow where (Nome like '%TV%' or Nome like '%Televisão%' or Nome like '%Rede Globo%' or Nome like '%band%new%' or Nome like '%balanço%geral' or Nome like '%Rede Record%' or Nome like '%SBT%' or Nome like '%GNT%' or Nome like '%Globo News%' or Nome like '%Multishow%') and (IdIntegradoraExterna is null or IdIntegradoraExterna <> @IdTv)
	update Midia set IdIntegradoraExterna = @IdLinkedin, DtAtualizacao = @DtNow where (Nome like '%Linked in%' or Nome like '%Linkedin%') and (IdIntegradoraExterna is null or IdIntegradoraExterna <> @IdLinkedin)
	update Midia set IdIntegradoraExterna = @IdRevista, DtAtualizacao = @DtNow where (Nome like '%Revista%' or Nome like '%Magazine%' or Nome like '%Veja%' or Nome like '%Qual%Imóvel%' or Nome like '%Exame%' or Nome like '%Época%' or Nome like '%Info Money%' or Nome like '%Isto É%' or Nome like '%Carta Capital%') and (IdIntegradoraExterna is null or IdIntegradoraExterna <> @IdRevista)
	update Midia set IdIntegradoraExterna = @IdIndicacao, DtAtualizacao = @DtNow where (Nome like '%Indicaç%' or Nome like '%Indicou%' or Nome like '%Amig%' or Nome like '%Cunhad%' or Nome like '%Sobrinh%' or Nome like '%Vizinh%') and (IdIntegradoraExterna is null or IdIntegradoraExterna <> @IdIndicacao)
	update Midia set IdIntegradoraExterna = @IdLandingPage, DtAtualizacao = @DtNow where Nome like '%Land%' and (IdIntegradoraExterna is null or IdIntegradoraExterna <> @IdLandingPage)
	update Midia set IdIntegradoraExterna = @IdMalaDireta, DtAtualizacao = @DtNow where (Nome like '%Mala Direta%' or Nome like '%MalaDireta%' or Nome like '%Malling%') and (IdIntegradoraExterna is null or IdIntegradoraExterna <> @IdMalaDireta)
	update Midia set IdIntegradoraExterna = @IdCorretor, DtAtualizacao = @DtNow where (Nome like '%Carteira%' or nome like '%corretor%') and (IdIntegradoraExterna is null or IdIntegradoraExterna <> @IdCorretor)
	update Midia set IdIntegradoraExterna = @IdSms, DtAtualizacao = @DtNow where Nome like '%SMS%' and (IdIntegradoraExterna is null or IdIntegradoraExterna <> @IdSms)
	update Midia set IdIntegradoraExterna = @IdFolheto, DtAtualizacao = @DtNow where (Nome like '%Folheto%' or Nome like '%Folder%') and (IdIntegradoraExterna is null or IdIntegradoraExterna <> @IdFolheto)
	update Midia set IdIntegradoraExterna = @IdTelefone, DtAtualizacao = @DtNow where (Nome like '%Telefone%' or Nome like '%Ligação%' or Nome like '%telefonica%' or Nome like '%0800%') and (IdIntegradoraExterna is null or IdIntegradoraExterna <> @IdTelefone)
	update Midia set IdIntegradoraExterna = @IdInternet, DtAtualizacao = @DtNow where Nome like '%Internet%' and (IdIntegradoraExterna is null or IdIntegradoraExterna <> @IdInternet)
	update Midia set IdIntegradoraExterna = @IdDisplay, DtAtualizacao = @DtNow where Nome = 'Display' and (IdIntegradoraExterna is null or IdIntegradoraExterna <> @IdDisplay)
	update Midia set IdIntegradoraExterna = @idMidiaPadrao, DtAtualizacao = @DtNow where Nome like '%padrao%' and (IdIntegradoraExterna is null or IdIntegradoraExterna <> @idMidiaPadrao)
	update Midia set IdIntegradoraExterna = @IdCinema, DtAtualizacao = @DtNow where Nome like '%Cinema%' and (IdIntegradoraExterna is null or IdIntegradoraExterna <> @IdCinema)
	update Midia set IdIntegradoraExterna = @IdPadaria, DtAtualizacao = @DtNow where Nome like '%padaria%' and (IdIntegradoraExterna is null or IdIntegradoraExterna <> @IdPadaria)
	update Midia set IdIntegradoraExterna = @IdTelemarketing, DtAtualizacao = @DtNow where Nome like '%telemarketing%' and (IdIntegradoraExterna is null or IdIntegradoraExterna <> @IdTelemarketing)
	update Midia set IdIntegradoraExterna = @IdCarroDeSom, DtAtualizacao = @DtNow where Nome like '%carro%som%' and (IdIntegradoraExterna is null or IdIntegradoraExterna <> @IdCarroDeSom)
	update Midia set IdIntegradoraExterna = @IdWaze, DtAtualizacao = @DtNow where Nome like '%Waze%' and (IdIntegradoraExterna is null or IdIntegradoraExterna <> @IdWaze)
	update Midia set IdIntegradoraExterna = @IdBing, DtAtualizacao = @DtNow where Nome like '%Bing%' and (IdIntegradoraExterna is null or IdIntegradoraExterna <> @IdBing)
	update Midia set IdIntegradoraExterna = @IdYahoo, DtAtualizacao = @DtNow where Nome like '%Yahoo%' and (IdIntegradoraExterna is null or IdIntegradoraExterna <> @IdYahoo)
	update Midia set IdIntegradoraExterna = @IdTwitter, DtAtualizacao = @DtNow where Nome like '%Twit%' and (IdIntegradoraExterna is null or IdIntegradoraExterna <> @IdTwitter)
	update Midia set IdIntegradoraExterna = @IdGloboCom, DtAtualizacao = @DtNow where Nome like '%globo%.%com%' and (IdIntegradoraExterna is null or IdIntegradoraExterna <> @IdGloboCom)
	update Midia set IdIntegradoraExterna = @IdEstadao, DtAtualizacao = @DtNow where Nome like '%estadao%' and (IdIntegradoraExterna is null or IdIntegradoraExterna <> @IdEstadao)
	update Midia set IdIntegradoraExterna = @IdWhatsApp, DtAtualizacao = @DtNow where Nome like '%Whats%' and (IdIntegradoraExterna is null or IdIntegradoraExterna <> @IdWhatsApp)	
	update Midia set IdIntegradoraExterna = @idBrasil247, DtAtualizacao = @DtNow where Nome like '%brasil%247%' and (IdIntegradoraExterna is null or IdIntegradoraExterna <> @idBrasil247)
	update Midia set IdIntegradoraExterna = @IdSpImoveis, DtAtualizacao = @DtNow where (Nome like '%sp imove%' or Nome like '%spimove%') and (IdIntegradoraExterna is null or IdIntegradoraExterna <> @IdSpImoveis)
	update Midia set IdIntegradoraExterna = @IdLoopImoveis, DtAtualizacao = @DtNow where Nome like '%Loop%' and (IdIntegradoraExterna is null or IdIntegradoraExterna <> @IdLoopImoveis)
	update Midia set IdIntegradoraExterna = @IdAgenteImovel, DtAtualizacao = @DtNow where Nome like '%Agente%' and (IdIntegradoraExterna is null or IdIntegradoraExterna <> @IdAgenteImovel)
	update Midia set IdIntegradoraExterna = @IdImovelK, DtAtualizacao = @DtNow where (Nome like '%Imovel K%' or Nome like '%ImovelK%') and (IdIntegradoraExterna is null or IdIntegradoraExterna <> @IdImovelK)
	update Midia set IdIntegradoraExterna = @IdProperati, DtAtualizacao = @DtNow where Nome like '%Properati%' and (IdIntegradoraExterna is null or IdIntegradoraExterna <> @IdProperati)
	update Midia set IdIntegradoraExterna = @IdRdStation, DtAtualizacao = @DtNow where Nome like '%station%' and (IdIntegradoraExterna is null or IdIntegradoraExterna <> @IdRdStation)
	update Midia set IdIntegradoraExterna = @IdDoubleClick, DtAtualizacao = @DtNow where Nome like '%doubleclick%' and (IdIntegradoraExterna is null or IdIntegradoraExterna <> @IdDoubleClick)
	update Midia set IdIntegradoraExterna = @IdStoria, DtAtualizacao = @DtNow where Nome like '%Storia%' and (IdIntegradoraExterna is null or IdIntegradoraExterna <> @IdStoria)
	update Midia set IdIntegradoraExterna = @IdMercadoLivre, DtAtualizacao = @DtNow where (Nome like '%Mercado%Livre%') and (IdIntegradoraExterna is null or IdIntegradoraExterna <> @IdMercadoLivre)
	update Midia set IdIntegradoraExterna = @IdMeuImovel, DtAtualizacao = @DtNow where (Nome like '%Meu Imovel%' or Nome = 'Meuimovel') and (IdIntegradoraExterna is null or IdIntegradoraExterna <> @IdMeuImovel)
	update Midia set IdIntegradoraExterna = @IdMoving, DtAtualizacao = @DtNow where Nome like '%Moving%' and (IdIntegradoraExterna is null or IdIntegradoraExterna <> @IdMoving)
	update Midia set IdIntegradoraExterna = @IdAptoVc, DtAtualizacao = @DtNow where Nome like '%Apto.vc%' and (IdIntegradoraExterna is null or IdIntegradoraExterna <> @IdAptoVc)
	update Midia set IdIntegradoraExterna = @IdImovelWeb, DtAtualizacao = @DtNow where ((Nome like '%web%' and Nome not like '%site%') or Nome like '%wimove%' or Nome like '%w imove%' or Nome like '%tiqueimove%' or Nome like '%tique imove%') and (IdIntegradoraExterna is null or IdIntegradoraExterna <> @IdImovelWeb)
	update Midia set IdIntegradoraExterna = @IdReweb, DtAtualizacao = @DtNow where Nome like '%Reweb%' and (IdIntegradoraExterna is null or IdIntegradoraExterna <> @IdReweb)
	update Midia set IdIntegradoraExterna = @IdZapImoveis, DtAtualizacao = @DtNow where Nome like '%Zap%' and (IdIntegradoraExterna is null or IdIntegradoraExterna <> @IdZapImoveis)
	update Midia set IdIntegradoraExterna = @IdZapier, DtAtualizacao = @DtNow where Nome like '%zapier%' and (IdIntegradoraExterna is null or IdIntegradoraExterna <> @IdZapier)
	update Midia set IdIntegradoraExterna = @IdGrupoZap, DtAtualizacao = @DtNow where Nome like '%Grupo Zap%' and (IdIntegradoraExterna is null or IdIntegradoraExterna <> @IdGrupoZap)
	update Midia set IdIntegradoraExterna = @IdVivaReal, DtAtualizacao = @DtNow where (Nome like '%Viva Real%' or Nome like '%VivaReal%') and (IdIntegradoraExterna is null or IdIntegradoraExterna <> @IdVivaReal)
	update Midia set IdIntegradoraExterna = @IdGoogle, DtAtualizacao = @DtNow where (Nome like '%Google%' or Nome like '%Organic%' or Nome like '%Adwords%' or Nome like '%cpc%') and (IdIntegradoraExterna is null or IdIntegradoraExterna <> @IdGoogle)
	update Midia set IdIntegradoraExterna = @Id123Imoveis, DtAtualizacao = @DtNow where Nome like '%123%' and (IdIntegradoraExterna is null or IdIntegradoraExterna <> @Id123Imoveis)
	update Midia set IdIntegradoraExterna = @IdOlx, DtAtualizacao = @DtNow where Nome like '%OLX%' and (IdIntegradoraExterna is null or IdIntegradoraExterna <> @IdOlx)
	update Midia set IdIntegradoraExterna = @IdYouTube, DtAtualizacao = @DtNow where Nome like '%YouTube%' and (IdIntegradoraExterna is null or IdIntegradoraExterna <> @IdYouTube)
	update Midia set IdIntegradoraExterna = @IdInstagram, DtAtualizacao = @DtNow where (Nome like '%Instagra%' or Nome like '%Instrag%') and (IdIntegradoraExterna is null or IdIntegradoraExterna <> @IdInstagram)
	update Midia set IdIntegradoraExterna = @idFacebook, DtAtualizacao = @DtNow where (Nome like '%Face%' or nome like 'Messenger%' or nome like 'Fbleads%' or nome = 'Fb') and (IdIntegradoraExterna is null or IdIntegradoraExterna <> @IdFacebook)
	update Midia set IdIntegradoraExterna = @IdUol, DtAtualizacao = @DtNow where (Nome like 'UOL%') and (IdIntegradoraExterna is null or IdIntegradoraExterna <> @IdUol)
	update Midia set IdIntegradoraExterna = @idCasafy, DtAtualizacao = @DtNow where (Nome like '%Casafy%') and (IdIntegradoraExterna is null or IdIntegradoraExterna <> @idCasafy)
	update Midia set IdIntegradoraExterna = @idShop, DtAtualizacao = @DtNow where (Nome like '%Shopp%') and (IdIntegradoraExterna is null or IdIntegradoraExterna <> @idShop)
	update Midia set IdIntegradoraExterna = @idTerra, DtAtualizacao = @DtNow where (Nome = 'Terra' or Nome = 'Terra.com.br') and (IdIntegradoraExterna is null or IdIntegradoraExterna <> @idTerra)
	update Midia set IdIntegradoraExterna = @idMetro, DtAtualizacao = @DtNow where (Nome like '%metro%' or Nome like '%estacao%') and (IdIntegradoraExterna is null or IdIntegradoraExterna <> @idMetro)
	update Midia set IdIntegradoraExterna = @idAbyara, DtAtualizacao = @DtNow where (Nome like '%abyara%') and (IdIntegradoraExterna is null or IdIntegradoraExterna <> @idAbyara)
	update Midia set IdIntegradoraExterna = @idBrasilBrokers, DtAtualizacao = @DtNow where (Nome like '%brasil%broker%') and (IdIntegradoraExterna is null or IdIntegradoraExterna <> @idBrasilBrokers)
	update Midia set IdIntegradoraExterna = @idAnapro, DtAtualizacao = @DtNow where (Nome like '%anapro%') and (IdIntegradoraExterna is null or IdIntegradoraExterna <> @idAnapro)
	update Midia set IdIntegradoraExterna = @idOnibus, DtAtualizacao = @DtNow where (Nome like '%bus%do%r%' or Nome like '%onibus%') and (IdIntegradoraExterna is null or IdIntegradoraExterna <> @idOnibus)
	update Midia set IdIntegradoraExterna = @idChat, DtAtualizacao = @DtNow where (Nome like '%chat%' or Nome like '%bate%papo%') and (IdIntegradoraExterna is null or IdIntegradoraExterna <> @idChat)
	update Midia set IdIntegradoraExterna = @idDgbz, DtAtualizacao = @DtNow where (Nome like '%dgbz%') and (IdIntegradoraExterna is null or IdIntegradoraExterna <> @idDgbz)
	update Midia set IdIntegradoraExterna = @idTaboola, DtAtualizacao = @DtNow where (Nome like '%taboola%') and (IdIntegradoraExterna is null or IdIntegradoraExterna <> @idTaboola)
	update Midia set IdIntegradoraExterna = @idAptoNovo, DtAtualizacao = @DtNow where (Nome like '%AptoNovo%' or Nome like 'Apto%Novo%') and (IdIntegradoraExterna is null or IdIntegradoraExterna <> @idAptoNovo)
	update Midia set IdIntegradoraExterna = @idHypnoBox, DtAtualizacao = @DtNow where (Nome like '%hypnobox%' or nome = 'Uselink') and (IdIntegradoraExterna is null or IdIntegradoraExterna <> @idHypnoBox)
	update Midia set IdIntegradoraExterna = @idMEDIAGRUPPE, DtAtualizacao = @DtNow where (Nome like '%MEDIA%GRUPPE%') and (IdIntegradoraExterna is null or IdIntegradoraExterna <> @idMEDIAGRUPPE)
	update Midia set IdIntegradoraExterna = @idIngaia, DtAtualizacao = @DtNow where (Nome like '%ingaia%' or Nome like 'gaia') and (IdIntegradoraExterna is null or IdIntegradoraExterna <> @idIngaia)
	update Midia set IdIntegradoraExterna = @idLINKTREE, DtAtualizacao = @DtNow where (Nome like '%LINKTREE%' or Nome like '%linktr%') and (IdIntegradoraExterna is null or IdIntegradoraExterna <> @idLINKTREE)

	-- Pensar em uma maneira de setar null no IdIntegradoraExterna na mudança de nome da mídia
	---- Se não entrou em nenhum if anterior, setamos como null a integradora externa, pois pode ter sido uma alteração de nome de mídia que já possuia integradora anteriormente e não possui mais
	--update Midia set IdIntegradoraExterna = null from Midia where Id = @IdMidia

	Update 
	TabelaoLog 
	Set
	TabelaoLog.Data1 = @DtNow,
	TabelaoLog.DtUltimaParcial =  dbo.GetDateCustom(),
	TabelaoLog.DtUltimaCompleta = dbo.GetDateCustom() 
where
	TabelaoLog.Nome = @BatchNome
end;

CREATE procedure [dbo].[ProcAjustarInteracaoUsuarioUltimaDt] as
begin

declare @iQtdGeral int = 1000000
declare @iQtdPorTransaction int = 200

declare @BatchNome varchar(1000) = 'Batch_AjustarInteracaoUsuarioUltimaDt'
declare @dtnow datetime = dbo.getDateCustom()

select
	top (@iQtdGeral)
		ROW_NUMBER() OVER(ORDER BY Atendimento.id ASC) AS RowNumber,
		Atendimento.Id,
		(
			SELECT 
				-- Se faz necessário adicionar sempre 1 a data máxima retornada
				MAX(AtendimentoDtExpirar) 
			FROM 
				(
					VALUES (Atendimento.DtInicioAtendimento), (InteracaoUltima.DtInclusao), (AlarmeUltimo.DataUltimoStatus), (AlarmeUltimoAtivo.Data), (SuperEntidade.DtInclusao)
				) AS UpdateDate(AtendimentoDtExpirar)
		) as DtMaxConsiderar
	into #tableTabAux
from
	Atendimento with (nolock)
		inner join
	SuperEntidade  with (nolock) on SuperEntidade.id = Atendimento.Id
		left outer join
	Interacao InteracaoUltima with (nolock) on InteracaoUltima.Id = Atendimento.IdInteracaoUsuarioUltima
		left outer join
	Alarme AlarmeUltimo with (nolock) on AlarmeUltimo.Id = Atendimento.IdAlarmeUltimo
		left outer join
	Alarme AlarmeUltimoAtivo with (nolock) on AlarmeUltimoAtivo.Id = Atendimento.IdAlarmeUltimoAtivo
where
	Atendimento.StatusAtendimento = 'ATENDIDO'
		AND
	Atendimento.InteracaoUsuarioUltimaDt <> (
			SELECT 
				-- Se faz necessário adicionar sempre 1 a data máxima retornada
				MAX(AtendimentoDtExpirar)
			FROM 
				(
					VALUES (Atendimento.DtInicioAtendimento), (InteracaoUltima.DtInclusao), (AlarmeUltimo.DataUltimoStatus), (AlarmeUltimoAtivo.Data), (SuperEntidade.DtInclusao)
				) AS UpdateDate(AtendimentoDtExpirar)
		) 

-- http://www.sommarskog.se/dyn-search.html
OPTION (RECOMPILE);


declare @iCount int = (Select count(TabAux.Id) from #tableTabAux TabAux);
declare @i int = 1;

WHILE @i <= @iCount 
	BEGIN
		--BEGIN TRANSACTION
			update 
				Atendimento 
					set 
						Atendimento.InteracaoUsuarioUltimaDt = tabaux.DtMaxConsiderar

										
								from
									#tableTabAux tabaux
										inner join  
									Atendimento with (nolock) on Atendimento.id = tabaux.id and tabAux.rownumber between @i and @i + @iQtdPorTransaction
									

			set @i = @i + @iQtdPorTransaction + 1
		--commit

		print @i
	end

	
	drop table #tableTabAux

	Update 
	TabelaoLog 
	Set
	TabelaoLog.Data1 = @DtNow,
	TabelaoLog.DtUltimaParcial =  dbo.GetDateCustom(),
	TabelaoLog.DtUltimaCompleta = dbo.GetDateCustom() 
where
	TabelaoLog.Nome = @BatchNome
end;

CREATE procedure [dbo].[ProcAlertaExisteAtrasado]
(
	@idContaSistema int,
	@idAtendimento int
)
as
begin

declare @dtnow datetime = dbo.getDateCustom()

Select 
	dbo.RetBitNotNull(Count(Alarme.id), 0) as Existe
From
	Alarme with (nolock)
		inner join
	Interacao  with (nolock) on Alarme.Id = Interacao.IdAlarme
		inner join
	Atendimento with (nolock) on Atendimento.id = Interacao.IdSuperEntidade

Where 
	Atendimento.idContaSistema = @idContaSistema and
	Atendimento.Id = @idAtendimento and
	Alarme.Status = 'IN' and
	Alarme.Data <= @dtnow
end;

CREATE procedure [dbo].[ProcAnonimizarPessoaProspect]
  @contaSistemaId int, @pessoaProspectId int, @atendimentoId int, @idUsuarioExecutandoAcao int, @obs varchar(max), @online bit,  @logar bit
as
begin
	declare @atendimentoIdAnonimizar as varchar(MAX)
	declare @pessoaProspectIdAnonimizar as int
	declare @dtNow as datetime = dbo.GetDateCustom()
	declare @ProspectNome as varchar(2000) 

	if @pessoaProspectId is not null
		begin
			Select @pessoaProspectIdAnonimizar = PessoaProspect.Id, @ProspectNome = PessoaProspect.Nome
			from PessoaProspect with (nolock)
			where
				PessoaProspect.Id = @pessoaProspectId and PessoaProspect.IdContaSistema = @contaSistemaId
		end
	else
		begin 
			Select @pessoaProspectIdAnonimizar = Atendimento.idPessoaProspect, @ProspectNome = PessoaProspect.Nome, @atendimentoIdAnonimizar = Atendimento.Id
			from 
				Atendimento  with (nolock)
					inner join
				PessoaProspect   with (nolock) on PessoaProspect.id = Atendimento.idPessoaProspect
			where
				Atendimento.Id = @atendimentoId and Atendimento.IdContaSistema = @contaSistemaId
		end
	

	if @pessoaProspectIdAnonimizar is not null
		begin
			if @online = 1
				begin
					declare @ProspectNomeAnonimizado varchar(300) = dbo.GetAnonimizacaoNome(@ProspectNome)

					delete from dbo.EnrichPersonSolicitanteEnrichPersonDataSource
					from dbo.EnrichPersonSolicitanteEnrichPersonDataSource
					inner join dbo.EnrichPersonSolicitante on dbo.EnrichPersonSolicitanteEnrichPersonDataSource.IdEnrichPersonSolicitante=dbo.EnrichPersonSolicitante.Id
					where EnrichPersonSolicitante.IdPessoaProspect = @pessoaProspectIdAnonimizar

					delete from dbo.EnrichPersonSolicitante
					where dbo.EnrichPersonSolicitante.IdPessoaProspect = @pessoaProspectIdAnonimizar
					
					delete from dbo.PessoaProspectEmail
					where dbo.PessoaProspectEmail.IdPessoaProspect = @pessoaProspectIdAnonimizar
 
					delete from dbo.PessoaProspectDocumento
					where dbo.PessoaProspectDocumento.IdPessoaProspect = @pessoaProspectIdAnonimizar
 
					delete from dbo.PessoaProspectTelefone
					where dbo.PessoaProspectTelefone.IdPessoaProspect = @pessoaProspectIdAnonimizar
 
					delete from dbo.PessoaProspectDadosGerais
					where dbo.PessoaProspectDadosGerais.IdPessoaProspect = @pessoaProspectIdAnonimizar

					update dbo.PessoaProspectEndereco set PessoaProspectEndereco.Complemento = null, PessoaProspectEndereco.Logradouro = null, PessoaProspectEndereco.Numero = null
					where PessoaProspectEndereco.IdPessoaProspect = @pessoaProspectIdAnonimizar
 
					update dbo.PessoaProspect set PessoaProspect.Nome = @ProspectNomeAnonimizado, DtAnonimizacao = @dtNow, IdUsuarioContaSistemaAnonimizado = @idUsuarioExecutandoAcao, RegistroStatus = null, RegistroStatusIdUsuarioContaSistema = null
					where dbo.PessoaProspect.id = @pessoaProspectIdAnonimizar 

					if(@logar = 1)
						begin
							set @obs = isnull(dbo.RetNullOrVarChar(@obs),'')

							if @atendimentoIdAnonimizar is not null
								begin
									set @atendimentoIdAnonimizar = (select STRING_AGG(atendimento.id, ', ') from Atendimento with(nolock) where idPessoaProspect = @pessoaProspectIdAnonimizar)
								end

							INSERT INTO [dbo].[LogAcoes]
										(IdGuid
										,[IdContaSistema]
										,[IdUsuarioContaSistemaExecutou]
										,[Tipo]
										,[TipoSub]
										,[Texto]
										,[ValueOld]
										,[ValueNew]
										,[NomeMethod]
										,[DtInclusao]
										,[TabelaBD]
										,[TabelaBDChave]
										,[EnviarEmailAdministradorAnapro]
										,[IdUsuarioContaSistemaImpactou])
									VALUES (
										NEWID(),
										@contaSistemaId,
										@idUsuarioExecutandoAcao,
										'Prospect',
										'Prospect_Anonimizado',
										'Prospect id: ('+ CONVERT(varchar(15), @pessoaProspectIdAnonimizar) +'), atendimentosId: ('+ CONVERT(varchar(15), isnull(@atendimentoIdAnonimizar,'-')) +') nome: ('+@ProspectNome+') anonimizado para o nome: ('+@ProspectNomeAnonimizado+'), todos os dados de contato excluído. '+@obs,
										CONVERT(varchar(15), @pessoaProspectIdAnonimizar),
										null,
										'ProcAnonimizarPessoaProspect',
										@dtnow,
										'PessoaProspect',
										CONVERT(varchar(15), @pessoaProspectIdAnonimizar),
										0,
										null)
							end
				end
			else
				begin
					update PessoaProspect
					set 
						PessoaProspect.RegistroStatus = 'ANO',
						PessoaProspect.RegistroStatusIdUsuarioContaSistema = @idUsuarioExecutandoAcao
					where
						PessoaProspect.Id = @pessoaProspectIdAnonimizar
					
					if @logar = 1
						begin
							set @obs = isnull(dbo.RetNullOrVarChar(@obs), '')
							set @atendimentoIdAnonimizar = ISNULL(@atendimentoIdAnonimizar,0)

							INSERT INTO [dbo].[LogAcoes]
										(
										IdGuid
										,[IdContaSistema]
										,[IdUsuarioContaSistemaExecutou]
										,[Tipo]
										,[TipoSub]
										,[Texto]
										,[ValueOld]
										,[ValueNew]
										,[NomeMethod]
										,[DtInclusao]
										,[TabelaBD]
										,[TabelaBDChave]
										,[EnviarEmailAdministradorAnapro]
										,[IdUsuarioContaSistemaImpactou])
									VALUES (
										NEWID(),
										@contaSistemaId,
										@idUsuarioExecutandoAcao,
										'PessoaProspect',
										'Prospect_AAnonimizar',
										'Prospect ('+ CONVERT(varchar(15), @pessoaProspectIdAnonimizar) +') do atendimento ('+CONVERT(varchar(15), @atendimentoIdAnonimizar)+') do prospect nome ('+@ProspectNome+') anonimização solicitada.'+@obs,
										CONVERT(varchar(15), @pessoaProspectIdAnonimizar),
										null,
										'ProcAnonimizarPessoaProspect',
										@dtnow,
										'PessoaProspect',
										CONVERT(varchar(15), @pessoaProspectIdAnonimizar),
										0,
										null)
						end

				end
	end
end;

CREATE procedure [dbo].[ProcAnonimizarPessoaProspectPreparacao]
 @IdContaSistema as int,
 @idUsuarioContaSistema as int,
 @strMotivo as varchar(max),
 @idsAtendimentos as varchar(max)
 as 

declare @dtnow datetime = dbo.getDateCustom()
declare @idAtendimento int

DECLARE AtendimentoCursorX CURSOR FOR
	(
		Select OrderID from SplitIDs(@idsAtendimentos)
	)

	-- abre o cursor e aloca o próximo
	open AtendimentoCursorX fetch next from AtendimentoCursorX into @IdAtendimento

	-- faz o loop nas conta sistema
	while(@@FETCH_STATUS = 0 )
		BEGIN
			exec ProcAnonimizarPessoaProspect @idContaSistema, null, @idAtendimento, @idUsuarioContaSistema, @strMotivo, 0, 1

			fetch next from AtendimentoCursorX into @idAtendimento
		end

	close AtendimentoCursorX
	deallocate AtendimentoCursorX;

CREATE procedure [dbo].[ProcAtendimentoExisteProximoPasso]
(
	@idContaSistema int,
	@idAtendimento int
)
as
begin

Select 
	dbo.RetBitNotNull(Count(Alarme.id), 0) as Existe
From
	Alarme with (nolock)
		inner join
	SuperEntidade with (nolock) on SuperEntidade.id = Alarme.IdSuperEntidade

Where 
	SuperEntidade.idContaSistema = @idContaSistema and
	Alarme.IdSuperEntidade = @idAtendimento and
	Alarme.Status = 'IN'

end;

-- Irá alocar automaticamente os usuários de um grupo que participa da campanha
-- em um canal onde o mesmo está setado como padrão na campanha
CREATE procedure [dbo].[ProcAutoAlocarUsuarioContaSistemaEmCanalCampanha]
	@idContaSistema as int,
	@idUsuarioContaSistema as int,
	@idGrupo as int,
	@idCampanha as int,
	@idCanal as int,
	@idPlantao as int,
	@idPlantaoHorario as int
 as 
begin
	declare @datenow AS DATETIME = dbo.GetDateCustom()
	
	insert into
		UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal
		(
			DtInclusao,
			IdUsuarioContaSistema,
			IdCampanhaGrupo,
			IdPlantaoHorario,
			IdCampanhaCanal,
			Status
		)
	Select 
		@datenow as DtInclusao,
		TAB.IdUsuarioContaSistema,
		TAB.idCampanhaGrupo,
		TAB.idPlantaoHorario,
		TAB.idCampanhaCanal,
		'AT'
		
	from
		(
			-- Seleciona todos os usuários dos grupos da campanha
			Select 
				distinct
					UsuarioContaSistemaGrupo.IdUsuarioContaSistema,
					CampanhaGrupo.Id as idCampanhaGrupo,
					PlantaoHorario.id as idPlantaoHorario,
					CampanhaCanal.Id as idCampanhaCanal
				
			From
				UsuarioContaSistemaGrupo  WITH (NOLOCK)
					inner join
				UsuarioContaSistema  WITH (NOLOCK) on UsuarioContaSistema.id = UsuarioContaSistemaGrupo.IdUsuarioContaSistema
					inner join
				ContaSistema  WITH (NOLOCK) on ContaSistema.Id = UsuarioContaSistema.IdContaSistema
					inner join
				CampanhaGrupo  WITH (NOLOCK) on CampanhaGrupo.IdGrupo = UsuarioContaSistemaGrupo.IdGrupo
					inner join
				Grupo  WITH (NOLOCK) on Grupo.Id = CampanhaGrupo.IdGrupo 
					inner join
				Campanha  WITH (NOLOCK) on Campanha.Id = CampanhaGrupo.IdCampanha
					inner join
				Plantao  WITH (NOLOCK) on Plantao.IdCampanha = Campanha.Id 
					inner join
				PlantaoHorario  WITH (NOLOCK) on PlantaoHorario.IdPlantao = Plantao.Id
					inner join
				CampanhaCanal  WITH (NOLOCK) on CampanhaCanal.IdCampanha = Campanha.Id 
					inner join
				Canal  WITH (NOLOCK) on Canal.Id = CampanhaCanal.IdCanal

			where
				(
					ContaSistema.Id = @idContaSistema
						and
					ContaSistema.Status = 'AT'
				)
					and
				(
					(@idGrupo is null or Grupo.Id = @idGrupo)
						and
					CampanhaGrupo.Status = 'AT'
						and
					Grupo.Status = 'AT'
				)
					and
				(
					(@idCampanha is null or Campanha.Id = @idCampanha)
						and
					Campanha.Status = 'AT'
				)
					and
				(
					-- Somente os canais da campanha que esteja como padrão
					CampanhaCanal.CanalPadrao = 1
				)
					and
				(
					(@idCanal is null or Canal.Id = @idCanal)
						and
					Canal.Status = 'AT'
				)	
					and
				(
					(@idUsuarioContaSistema is null or UsuarioContaSistema.id = @idUsuarioContaSistema )
						and
					UsuarioContaSistema.Status = 'AT'
				)
					and
				(
					UsuarioContaSistemaGrupo.DtInicio <= @datenow
						and
					(
						UsuarioContaSistemaGrupo.DtFim is null or
						UsuarioContaSistemaGrupo.DtFim >= @datenow
					)
				)
					and
				(
					(@idPlantao is null or Plantao.Id = @idPlantao)
						and
					Plantao.Status = 'AT'
						and
					(
						Plantao.DtFimValidade is null or
						Plantao.DtFimValidade >= @datenow
					)
				)
					and
				(
					(@idPlantaoHorario is null or PlantaoHorario.Id = @idPlantaoHorario)
						and
					PlantaoHorario.Status = 'AT'
						and
					(
						PlantaoHorario.DtFim is null or
						PlantaoHorario.DtFim >= @datenow
					)	
				)
					AND
				-- selecionará somente os que ainda não existem
				NOT EXISTS
				(
					Select
						UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal.Id
					from
						UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal  WITH (NOLOCK)
					where
						UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal.IdCampanhaCanal = CampanhaCanal.Id
							and
						UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal.IdCampanhaGrupo = CampanhaGrupo.Id
							AND
						UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal.IdPlantaoHorario = PlantaoHorario.Id
							AND
						UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal.IdUsuarioContaSistema = UsuarioContaSistemaGrupo.IdUsuarioContaSistema
				)
		) as TAB
end;

-- Irá alocar automaticamente os usuários de um grupo que participa da campanha
-- em um canal onde o mesmo está setado como padrão na campanha
CREATE procedure [dbo].[ProcAutoSetPerfilPadraoUsuarioContaSistema]
	@idContaSistema as int
 as 
begin
	declare @idPerfilPadrao int = (select PerfilUsuario.id from PerfilUsuario  WITH (NOLOCK) where PerfilUsuario.idContaSistema = @idContaSistema and PerfilUsuario.Padrao = 1)

	if @idPerfilPadrao > 0 
		begin
			update UsuarioContaSistema 
				set UsuarioContaSistema.idPerfilUsuario = @idPerfilPadrao 
			where 
				UsuarioContaSistema.IdContaSistema = @idContaSistema
					and
				UsuarioContaSistema.idPerfilUsuario is null
		end	
end;

CREATE procedure [dbo].[ProcCriarContaSistema]
(
	@INSTANCIANOME VARCHAR(100),
	@INSTANCIANOMEDIRETORIO VARCHAR(300),
	@IDCONTASISTEMA INT
)
as 


	DECLARE @IDPESSOASADM VARCHAR(100)
	DECLARE @IDPESSOASADMPRINCIPAL VARCHAR(100)
	--DECLARE @IDCONTASISTEMA INT
	DECLARE @IDPERFILUSUARIOADM INT
	DECLARE @IDPERFILUSUARIOPADRAO INT
	DECLARE @IDGRUPOSUPERIOR INT
	DECLARE @IDGRUPOPADRAO INT
	DECLARE @IDUSUARIOCONTASISTEMAADM INT
	DECLARE @IDIntegradoraExterna INT

	DECLARE @IDTOPICO INT

	DECLARE @IDMIDIATIPO INT

	DECLARE @IDFICHAPESQUISA INT
	DECLARE @IDPERGUNTA INT

	DECLARE @IdRegraFidelizacao int

	DECLARE @IDCAMPANHA INT
	DECLARE @IDPLANTAO INT

	DECLARE @IDCANALSTAND INT

	DECLARE @PRODUTOS varchar(max)
	DECLARE @PRODUTOSUF char(2)


	DECLARE @IDGUIDCONTASISTEMAREFERENCIA char(36)
	DECLARE @IDGUIDCONTASISTEMA char(36)

	-- NÃO ALTERAR
	DECLARE @GUIDPESSOAANAPROVENDAS char(36) = '67cbe17b-1449-4ba3-8f3e-358888ef50d4'

	-- NÃO ALTERAR
	DECLARE @IDCONTASISTEMAREFERENCIA INT = 151

	-- *******************************************************************
	-- *******************************************************************
	-- *******************************************************************
	-- Só alterar apartir daqui
	-- *******************************************************************
	-- *******************************************************************
	-- *******************************************************************

	-- Alterar aqui a guid da contasistema no CORREX
	-- set @GuidContaCorrex = @GuidContaCorrex

	SET @INSTANCIANOME = @INSTANCIANOME
	SET @INSTANCIANOMEDIRETORIO = @INSTANCIANOMEDIRETORIO

	-- *******************************************************************
	-- *******************************************************************
	-- *******************************************************************
	-- Só alterar até aqui
	-- *******************************************************************
	-- *******************************************************************
	-- *******************************************************************


	-- Produtos separados por ,
	SET @PRODUTOS = 'Produto 1,Produto 2'
	SET @PRODUTOSUF = 'SP'
	SET @IDGUIDCONTASISTEMAREFERENCIA = (select ContaSistema.Guid from ContaSistema where id = @IDCONTASISTEMAREFERENCIA)
	SET @IDGUIDCONTASISTEMA = (select NEWID())

	-- Id das pessoas que serão administradores da conta
	-- 1 = admin@anapro.com.br
	SET @IDPESSOASADMPRINCIPAL = '1'
	SET @IDPESSOASADM = '1,30311' -- SEPARADAS POR , ex: 1,2,3


	-- Conta Sistema
	--Insert into ContaSistema
	--	(
	--		Nome,
	--		Guid,
	--		Status,
	--		StatusConta,
	--		GuidCorrex
	--	)
	--		values
	--	(
	--		@INSTANCIANOME,
	--		@IDGUIDCONTASISTEMA,
	--		'AT',
	--		'AT',
	--		@GuidContaCorrex
	--	)


	--SET  @IDCONTASISTEMA  = @@IDENTITY


	-- Conta Host Padrão
	--Insert into ContaSistemaHost
	--	(
	--		IdContaSistema,
	--		Host,
	--		DtInclusao,
	--		Padrao,
	--		Tipo
	--	)
	--		values
	--	(
	--		@IDCONTASISTEMA,
	--		@INSTANCIAHOST,
	--		dbo.GetDateCustom(),
	--		1,
	--		'SISTEMA'
	--	)


	-- Conta Host Teste
	insert
	into	ContaSistemaHost(IdContaSistema, Host, DtInclusao, Padrao, tipo)
	values	(@IDCONTASISTEMA, 'webcrmsite' + CONVERT(varchar, @IDCONTASISTEMA), dbo.GetDateCustom(), 0, 'SISTEMA')

	-- Conta Host APP
	insert
	into	ContaSistemaHost(IdContaSistema, Host, DtInclusao, Padrao, tipo)
	values	(@IDCONTASISTEMA, 'app.anapro.com.br', dbo.GetDateCustom(), 0, 'APP')

	-- Perfil de usuário
	insert
	into	PerfilUsuario(Guid, idContaSistema, Nome, Administrador, DtInclusao, Padrao, Permissao, DtAtulizacao, UrlAutoAcessar)
	select	NEWID(),
			@IDCONTASISTEMA,
			REPLACE(PerfilUsuario.Nome,'Anapro Modelo', @INSTANCIANOME),
			PerfilUsuario.Administrador,
			dbo.GetDateTime(),
			PerfilUsuario.Padrao,
			PerfilUsuario.Permissao,
			dbo.GetDateTime(),
			PerfilUsuario.UrlAutoAcessar
	from	PerfilUsuario with (nolock)
	where	PerfilUsuario.idContaSistema = @IDCONTASISTEMAREFERENCIA

	set		@IDPERFILUSUARIOADM =	(
										select	top 1 PerfilUsuario.id
										from	PerfilUsuario with (nolock)
										where	PerfilUsuario.Administrador = 1 and 
												PerfilUsuario.idContaSistema = @IDCONTASISTEMA
									)

	set		@IDPERFILUSUARIOPADRAO =	(	
											select	top 1 PerfilUsuario.id
											from	PerfilUsuario with (nolock)
											where	PerfilUsuario.Padrao = 1 and
													PerfilUsuario.idContaSistema = @IDCONTASISTEMA
										)

	-- Insere o usuário admistrador da conta, no caso o administrador do anapro
	insert into UsuarioContaSistema(
				IdContaSistema,
				IdPessoa,
				idPerfilUsuario,
				DtInclusao,
				DtAtualizacao,
				QtdAcesso,
				Status,
				AccessToken,
				AccessTokenData)
	select		@IDCONTASISTEMA, 
				convert(int, OrderID),
				@IDPERFILUSUARIOADM,
				dbo.GetDateCustom(),
				dbo.GetDateCustom(),
				0,
				'AT',
				NEWID(),
				dbo.GetDateCustom()
	from		dbo.SplitIDs(@IDPESSOASADM)

	set		@IDUSUARIOCONTASISTEMAADM = (
											select	MIN(ID) 
											from	 USUARIOCONTASISTEMA with (nolock)
											where	IDPESSOA = @IDPESSOASADMPRINCIPAL
										)

	-- GRUPO SUPERIOR
	insert into Grupo(
			IdContaSistema,
			Nome,
			Padrao,
			Status,
			DtInclusao,
			DtAtualizacao,
			Tipo,
			Mostrar,
			IdGuid )
	values(	@IDCONTASISTEMA,
			'SUPER GRUPO',
			0,
			'AT',
			dbo.GetDateCustom(),
			dbo.GetDateCustom(),
			'CRM',
			0,
			NEWID()
	)

	SET @IDGRUPOSUPERIOR = @@IDENTITY

	-- GRUPO PADRÃO
	insert into Grupo	
		(
			IdContaSistema,
			Nome,
			Padrao,
			Status,
			DtInclusao,
			DtAtualizacao,
			Tipo,
			Mostrar,
			IdGuid
		)
			values
		(
			@IDCONTASISTEMA,
			'INCORPORADORA '+@INSTANCIANOME,
			1,
			'AT',
			dbo.GetDateCustom(),
			dbo.GetDateCustom(),
			'CRM',
			1,
			NEWID()
		)

	SET @IDGRUPOPADRAO= @@IDENTITY

	-- Insere os produtos
	insert
	into	Produto (IdContaSistema, Nome, status, uf, codigo, tipo, DtInclusao, GUID, ValorMedio, ComissaoMedio)
	select	@IDCONTASISTEMA, Tab.OrderId, 'AT', @PRODUTOSUF, NULL, 'SUPERCRM', dbo.GetDateCustom(), NEWID(), 0, 0 
	from	(
				select distinct TabAux.OrderID
				from SplitIDstring(@PRODUTOS) as TabAux
			) as Tab

	-- Adiciona o grupo padrão inferior ao super grupo
	INSERT INTO GrupoSuperior
		(
			IdGrupo,
			IdGrupoSuperior,
			DtInicio
		)
		  values
		(
			@IDGRUPOPADRAO,
			@IDGRUPOSUPERIOR,
			dbo.GetDateCustom()
		)

	
	-- Adiciona o usuário como superior dos grupos padrões
	INSERT INTO UsuarioContaSistemaGrupoAdm(
					IdUsuarioContaSistema,
					IdGrupo,
					DtInicio
				)
	select	UsuarioContaSistema.Id,
			@IDGRUPOSUPERIOR,
			dbo.GetDateCustom()
	from	UsuarioContaSistema with (nolock)
	where	UsuarioContaSistema.IdContaSistema = @IDCONTASISTEMA and
			exists 
				(
					select	OrderID
					from	dbo.SplitIDs(@IDPESSOASADM) 
					where	convert(int, OrderID) = UsuarioContaSistema.IdPessoa
				)

	INSERT INTO UsuarioContaSistemaGrupoAdm
		(
			IdUsuarioContaSistema,
			IdGrupo,
			DtInicio
		)
	select	UsuarioContaSistema.Id,
			@IDGRUPOPADRAO,
			dbo.GetDateCustom()
	from	UsuarioContaSistema with (nolock)
	where	UsuarioContaSistema.IdContaSistema = @IDCONTASISTEMA and
			exists	(
						select	OrderID
						FROM	dbo.SplitIDs(@IDPESSOASADM) 
						where	convert(int, OrderID) = UsuarioContaSistema.IdPessoa
					)

	-- gera a hierarquia do grupo
	-- exec ProcGerarGrupoHierarquia @IDCONTASISTEMA

	-- TIPOS de interação
	insert
	into	InteracaoTipo (idguid, IdContaSistema, Valor, ValorAbreviado, DtInclusao, Status, Mostrar, sistema, tipo)
	Select	newid(),
			@IDCONTASISTEMA,
			InteracaoTipo.Valor,
			InteracaoTipo.ValorAbreviado,
			dbo.GetDateCustom(),
			'AT',
			InteracaoTipo.Mostrar,
			InteracaoTipo.Sistema,
			InteracaoTipo.Tipo
	from	InteracaoTipo with (nolock)
	where	InteracaoTipo.IdContaSistema = @IDCONTASISTEMAREFERENCIA and InteracaoTipo.Status = 'AT'

	-- insere os canais
	insert into Canal (IdContaSistema, Meio, Nome, NumeroMaxAtendimentoSimultaneo, Status, TempoMaxInicioAtendimento, Tipo, TipoTempoMaxInicioAtendimento, HabilitarPrevisaoDeMensagem, MensagemAutomatica) 
	Select	@IDCONTASISTEMA, Meio, Nome, NumeroMaxAtendimentoSimultaneo, Status, TempoMaxInicioAtendimento, Tipo, TipoTempoMaxInicioAtendimento, HabilitarPrevisaoDeMensagem, MensagemAutomatica
	from	canal with (nolock)
	where	canal.IdContaSistema = @IDCONTASISTEMAREFERENCIA and canal.status = 'AT'

	SET  @IDCANALSTAND  =	(
								select min(Canal.id)
								from	Canal with (nolock)
								where	Canal.tipo = 'FISICO'
							)

	-- insere os tipos de interação para o stand de vendas
	insert
	into	CanalInteracaoTipo (IdCanal, IdInteracaoTipo, DtInclusao)
	select	@IDCANALSTAND, InteracaoTipo.Id, dbo.GetDateCustom()
	from	InteracaoTipo with (nolock)
	where	IdContaSistema = @IDCONTASISTEMA

	-- Insere o tipo de interação possível por usuário
	Insert	InteracaoTipoAtorPartida (IdInteracaoTipo, InteracaoAtorPartida)
	Select	InteracaoTipo.Id, 'USUARIO'
	from	InteracaoTipo with (nolock)
	WHERE	IdContaSistema = @IDCONTASISTEMA

	-- Insere as classificações
	insert
	into	Classificacao (IdContaSistema, Tipo, Valor, Valor2, Status, Ordem, DtInclusao, DtAtualizacao, Padrao, PadraoPerda, PadraoGanho, Mostrar, Acao, ProbabilidadeGanho, ObjCamposRequeridos)
	select	@IDCONTASISTEMA,
			Classificacao.Tipo,
			Classificacao.Valor,
			Classificacao.Valor2,
			Classificacao.Status,
			Classificacao.Ordem,
			dbo.GetDateCustom(),
			dbo.GetDateCustom(),
			Classificacao.Padrao,
			Classificacao.PadraoPerda,
			Classificacao.PadraoGanho,
			Classificacao.Mostrar,
			Classificacao.Acao,
			Classificacao.ProbabilidadeGanho,
			Classificacao.ObjCamposRequeridos
	from	Classificacao with (nolock)
	where	IdContaSistema = @IDCONTASISTEMAREFERENCIA AND Classificacao.Status = 'AT'

	-- Regra de fidelização
	insert
	into	RegraFidelizacao (IdGuid,IdContaSistema, DtCriacao, Nome)
	values	(NEWID(), @IDCONTASISTEMA, dbo.GetDateCustom(), 'Fidelização Global')
	
	SET		@IdRegraFidelizacao  = @@IDENTITY

	-- Insere a campanha online como padrão
	insert into Campanha (IdContaSistema, Nome, DtInclusao, NumeroMaxAtendimentoSimultaneo, Status, GUID, HoraInicioFuncionamentoRoleta, HoraFinalFuncionamentoRoleta, IdRegraFidelizacao)
	values (@IDCONTASISTEMA, 'Vendas', dbo.GetDateCustom(), 99999999, 'AT', NEWID(), '08:00:00', '20:00:00', @IdRegraFidelizacao)
	
	SET  @IDCAMPANHA  = @@IDENTITY

	-- Insere os canais da campanha
	insert
	into	CampanhaCanal (idcanal, idCampanha, CanalPadrao, TempoMaxInicioAtendimento, TipoTempoMaxInicioAtendimento, NumeroMaxAtendimentoSimultaneo, TipoPrioridade)
	select	id, @IDCAMPANHA, 1, Canal.TempoMaxInicioAtendimento, Canal.TipoTempoMaxInicioAtendimento, canal.NumeroMaxAtendimentoSimultaneo, 'PADRAO'
	from	Canal with (nolock)
	where	IdContaSistema = @IDCONTASISTEMA

	-- insere um plantão padrao
	insert
	into	plantao (idcampanha, nome, dtinicioValidade, dtFimValidade, Status)
	values	(@IDCAMPANHA, 'Plantão padrão', dbo.GetDateCustom(), DATEADD(year, 10, dbo.GetDateCustom()), 'AT')
	
	SET  @IDPLANTAO  = @@IDENTITY

	-- insere um plantao horário padrao
	insert
	into	PlantaoHorario (IdPlantao, DtInicio, DtFim, Status) 
	values (@IDPLANTAO, dbo.GetDateCustom(), DATEADD(year, 9, dbo.GetDateCustom()), 'AT')

	-- Insere os grupos da campanha
	insert
	into	CampanhaGrupo (IdGrupo, IdCampanha, Status, DtInclusao, DtModificacao)
	select	id, @IDCAMPANHA, 'AT', dbo.GetDateCustom(), dbo.GetDateCustom()
	from	Grupo with (nolock)
	where	IdContaSistema = @IDCONTASISTEMA AND Grupo.Mostrar = 1

	-- Insere os Produtos da campanha
	insert 
	into	ProdutoCampanha (IdProduto, IdCampanha)
	select	id, @IDCAMPANHA
	from	Produto with (nolock)
	WHERE	IdContaSistema = @IDCONTASISTEMA

	-- Insere o tipo de oportunidade para ser utilizado na conversão
	insert
	into	OportunidadeNegocioTipo (IdContaSistema, Nome, Descricao, DtInclusao, Tipo)
	values	(@IDCONTASISTEMA, 'VENDAAPROVADA', 'VENDAAPROVADA', dbo.GetDateCustom(), 'VENDA')

	-- Insere o tipo de mídia
	insert
	into	MidiaTipo (IdContaSistema, Valor, DtInclusao, IdGuid) 
	select	@IDCONTASISTEMA, MidiaTipo.Valor, dbo.GetDateTime(), NEWID()
	from	MidiaTipo with (nolock)
	where	MidiaTipo.IdContaSistema = @IDCONTASISTEMAREFERENCIA

	-- Insere as mídias
	insert
	into	Midia (IdContaSistema, Nome, Obs, Status, AutoInclusao, DtInclusao, idMidiaTipo, GUID, Publica, IdIntegradoraExterna)
	select	@IDCONTASISTEMA, Nome, Obs, Status, AutoInclusao, dbo.GetDateCustom(),
			(
				select		MidiaTipo.id
				from		MidiaTipo with (nolock)
								inner join MidiaTipo as MidiaTipoRef with (nolock) on
									MidiaTipoRef.valor = MidiaTipo.valor and
									MidiaTipo.idContaSistema = @IDCONTASISTEMA and 
									MidiaTipoRef.IdContaSistema = @IDCONTASISTEMAREFERENCIA and 
									MidiaTipoRef.id = midia.idMidiaTipo
			), NEWID(), Publica, IdIntegradoraExterna 
	from	midia with (nolock)
	where	midia.idContaSistema = @IDCONTASISTEMAREFERENCIA

	-- insere as motivações
	insert
	into	Motivacao (IdContaSistema, Descricao, Tipo, Status, DtInclusao) 
	Select	@IDCONTASISTEMA, Descricao, Tipo, Status, dbo.GetDateCustom()
	from	Motivacao with (nolock)
	Where	Motivacao.idContaSistema = @IDCONTASISTEMAREFERENCIA

	-- insere 1º ficha de pesquisa padrao
	insert
	into	FichaPesquisa (IdContaSistema, Nome, Descricao, DtInclusao, Status, AutoNumerarPerguntas) 
	select	@IDCONTASISTEMA, Nome, Descricao, dbo.GetDateCustom(), Status, AutoNumerarPerguntas
	from	FichaPesquisa with (nolock)
	where	FichaPesquisa.idContaSistema = @IDCONTASISTEMAREFERENCIA

	insert
	into	FichaPesquisaTipo (IdFichaPesquisa, Tipo, DtInclusao) 
	select	FichaPesquisa.id,
			FichaPesquisaTipo.Tipo,
			dbo.GetDateCustom()
	from	FichaPesquisa with (nolock)
				inner join FichaPesquisa as FichaPesquisaRef with (nolock) on
					FichaPesquisa.Nome = FichaPesquisaRef.Nome
				inner join FichaPesquisaTipo with (nolock) on
					FichaPesquisaTipo.IdFichaPesquisa = FichaPesquisaRef.id
	Where	FichaPesquisa.IdContaSistema = @IDCONTASISTEMA and
			FichaPesquisaRef.IdContaSistema = @IDCONTASISTEMAREFERENCIA


	insert
	into	Pergunta (IdFichaPesquisa, Descricao, Status, Tipo, Obrigatorio, DtInclusao) 
	select	FichaPesquisa.id,
			Pergunta.Descricao, 
			Pergunta.Status, 
			Pergunta.Tipo, 
			Pergunta.Obrigatorio,
			dbo.GetDateCustom()
	from	FichaPesquisa with (nolock)
				inner join FichaPesquisa as FichaPesquisaRef with (nolock) on
					FichaPesquisa.Nome = FichaPesquisaRef.Nome
				inner join Pergunta with (nolock) on 
					Pergunta.IdFichaPesquisa = FichaPesquisaRef.id
	where	FichaPesquisa.IdContaSistema = @IDCONTASISTEMA	and
			FichaPesquisaRef.IdContaSistema = @IDCONTASISTEMAREFERENCIA


	insert
	into	resposta (IdPergunta, TextoResposta, Status, DtInclusao, Peso) 
	select	Pergunta.id,
			Resposta.TextoResposta, 
			Resposta.Status, 
			dbo.GetDateCustom(), 
			Resposta.Peso
	from	Pergunta with (nolock)
			inner join Pergunta as PerguntaRef with (nolock) on
				Pergunta.Descricao = PerguntaRef.Descricao
			inner join Resposta with (nolock) on
				Resposta.IdPergunta = PerguntaRef.id
			inner join FichaPesquisa with (nolock) on
				FichaPesquisa.id = Pergunta.idFichaPesquisa
			inner join FichaPesquisa as FichaPesquisaRef with (nolock) on
				FichaPesquisaRef.id = PerguntaRef.idFichaPesquisa 
	Where	FichaPesquisa.IdContaSistema = @IDCONTASISTEMA and
			FichaPesquisaRef.IdContaSistema = @IDCONTASISTEMAREFERENCIA


	-- Vincula a Ficha de pesquisa a campanha
	insert
	into	CampanhaFichaPesquisa (IdCampanha, IdFichaPesquisa, FichaPesquisaTipo, DtInclusao) 
	select	(
				select	min(campanha.id)
				from	campanha
				where	idContaSistema = @IDCONTASISTEMA
			),
			FichaPesquisa.id,
			CampanhaFichaPesquisaRef.FichaPesquisaTipo,
			dbo.GetDateCustom()
	from	CampanhaFichaPesquisa as CampanhaFichaPesquisaRef
				inner join Campanha as CampanhaRef with (nolock) on
					CampanhaRef.id =  CampanhaFichaPesquisaRef.idCampanha
				inner join FichaPesquisa as FichaPesquisaRef with (nolock) on
					FichaPesquisaRef.id = CampanhaFichaPesquisaRef.IdFichaPesquisa
				inner join FichaPesquisa with (nolock) on
					FichaPesquisa.Nome = FichaPesquisaRef.nome
	where	FichaPesquisa.IdContaSistema = @IDCONTASISTEMA and
			FichaPesquisaRef.IdContaSistema = @IDCONTASISTEMAREFERENCIA


	-- Cadastra um topico de resposta como exemplo
	insert
	into	Topico (IdContaSistema, IdUsuarioContaSistema, Titulo, Texto, Status, Tipo, DtInclusao, DtAlteracao)
	values	( @IDCONTASISTEMA, @IDUSUARIOCONTASISTEMAADM, 'Localização (teste)', 'O empreendimento está localizado na área mais nobre da cidade, com vista panorâmica para o Parque do Clemente. Endereço: Quadra 45, conjunto 72, Bairro São Pedro.', 'AT', 'PADRAO', dbo.GetDateCustom(), NULL)
	
	set		@IDTOPICO = @@IDENTITY

	insert
	into	TopicoProduto (IdTopico, IdProduto, DtInclusao) 
	select	@IDTOPICO, id, dbo.GetDateCustom()
	from	Produto with (nolock)
	where	IdContaSistema = @IDCONTASISTEMA

	insert
	into	Tag (idContaSistema, IdUsuarioContaSistema, DtInclusao, Valor, Tipo, IdGuid)
	values (@IDCONTASISTEMA, @IDUSUARIOCONTASISTEMAADM, dbo.GetDateCustom(), 'endereço', 'PADRAO', NEWID())

	insert
	into	Tag (idContaSistema, IdUsuarioContaSistema, DtInclusao, Valor, Tipo, IdGuid)
	values (@IDCONTASISTEMA, @IDUSUARIOCONTASISTEMAADM, dbo.GetDateCustom(), 'localização', 'PADRAO', NEWID())
	
	insert
	into	Tag (idContaSistema, IdUsuarioContaSistema, DtInclusao, Valor, Tipo, IdGuid)
	values (@IDCONTASISTEMA, @IDUSUARIOCONTASISTEMAADM, dbo.GetDateCustom(), 'bairro', 'PADRAO', NEWID())

	insert
	into	TopicoTag (IdTag, IdTopico, DtInclusao)
	select	id, @IDTOPICO, dbo.GetDateCustom()
	from	Tag with (nolock)
	where	IdContaSistema = @IDCONTASISTEMA

	insert into IntegradoraExterna
		(
			StrKey,
			IdUsuarioContaSistema,
			Status,
			Nome,
			Tipo,
			DtInclusao,
			DtAtualizacao,
			Publico
		)
			VALUES
		(
			NEWID(),
			1,
			'AT',
			@INSTANCIANOME + convert(varchar(20),@IDCONTASISTEMA) +' (a própria)',
			'PROPRIA',
			dbo.GetDateCustom(),
			dbo.GetDateCustom(),
			0
		)

	SET @IDIntegradoraExterna  = @@IDENTITY

	insert into IntegradoraExternaContaSistema
		(
			idIntegradoraExterna,
			idContaSistema,
			DtInclusao,
			IdUsuarioContaSistema
		)
			VALUES
		(
			@IDIntegradoraExterna,
			@IDCONTASISTEMA,
			dbo.GetDateCustom(),
			1
		)

	-- Modulos de conta
	-- * topicos
	-- insert into ModuloSistemaContaSistema (idModuloSistema, idContaSistema, DtInclusao) values (1, @IDCONTASISTEMA, dbo.GetDateCustom())
	-- * nova versão
	-- insert into ModuloSistemaContaSistema (idModuloSistema, idContaSistema, DtInclusao) values (5, @IDCONTASISTEMA, dbo.GetDateCustom())


	-- Insere o nome do diretorio da conta sistema onde ficaram as imagens e arquivos da conta sistema em questão
	insert 
	into	ContaSistemaConfiguracao (IdContaSistema, Tipo, Valor, DtInclusao, DtModificacao, ValorInt, Status)
	values  (@IDCONTASISTEMA, 'CONTA_DIRETORIO', @INSTANCIANOMEDIRETORIO, dbo.GetDateCustom(), dbo.GetDateCustom(), 0, 'AT')

	-- Insere O TEMPO de Expiração da sessão
	insert
	into	ContaSistemaConfiguracao (IdContaSistema, Tipo, Valor, DtInclusao, DtModificacao, ValorInt, Status)
	values (@IDCONTASISTEMA, 'CONTA_MINUTO_EXP', NULL, dbo.GetDateCustom(), dbo.GetDateCustom(), 7200, 'AT')

	-- Insere a não duplicação de telefones como true
	insert
	into	ContaSistemaConfiguracao (IdContaSistema, Tipo, Valor, DtInclusao, DtModificacao, ValorInt, Status)
	values (@IDCONTASISTEMA, 'IGNORAR_TELEFONE_INVALIDO', NULL, dbo.GetDateCustom(), dbo.GetDateCustom(), 1, 'AT')

	-- Insere o tempo padrão de expiração do usuário do chat para 20 min
	insert
	into	ContaSistemaConfiguracao (IdContaSistema, Tipo, Valor, DtInclusao, DtModificacao, ValorInt, Status)
	values (@IDCONTASISTEMA, 'CHAT_MINUTO_EXP', NULL, dbo.GetDateCustom(), dbo.GetDateCustom(), 20, 'AT')

	-- Insere por padrão a fidelização por telefone
	insert 
	into	ContaSistemaConfiguracao (IdContaSistema, Tipo, Valor, DtInclusao, DtModificacao, ValorInt, Status)
	values (@IDCONTASISTEMA, 'FIDELIZACAO_POR_PROSPECT_TELEFONE', NULL, dbo.GetDateCustom(), dbo.GetDateCustom(), 1, 'AT')

	-- insere as configurações da oferta ativa
	insert
	into	ContaSistemaConfiguracao (IdContaSistema, IdUsuarioContaSistema, Tipo, DtInclusao, DtModificacao, ValorInt, Status, ValorObj, ObjTipo) 
	select	@IDCONTASISTEMA,
			@IDUSUARIOCONTASISTEMAADM,
			'CONFIGURACAO_OFERTAATIVA',
			dbo.GetDateCustom(),
			dbo.GetDateCustom(),
			0,
			'AT',
			REPLACE(REPLACE(ContaSistemaConfiguracao.ValorObj, '"ContaSistemaId":'+cast(@IDCONTASISTEMAREFERENCIA as varchar(15))+',', '"ContaSistemaId":'+cast(@IDCONTASISTEMA as varchar(15))+','), @IDGUIDCONTASISTEMAREFERENCIA, @IDGUIDCONTASISTEMA),
			ContaSistemaConfiguracao.ObjTipo
	from	ContaSistemaConfiguracao with (nolock)
	where	ContaSistemaConfiguracao.IdContaSistema = @IDCONTASISTEMAREFERENCIA and Tipo = 'CONFIGURACAO_OFERTAATIVA'

	exec	ProcAjustarCanalCarteiraCorretorCampanha



	select  contasistema.*
	from	contasistema
	where	id = @IDCONTASISTEMA;

--exec [dbo].[ProcEventoPreProcessamento]


-- Pré-processa os eventos antes do processamento
CREATE procedure [dbo].[ProcEventoPreProcessamento]
 as 
begin

	-- comentar
	-- return

	declare @NaoProcessado bit = 0
	declare @Processado bit = 1
	declare @dtTimeNow datetime = dbo.getdatecustom()
	declare @dtNow date = @dtTimeNow
	declare @dtAmanha date = DateADD(DAY, 1, @dtNow)
	declare @timeNow time = @dtTimeNow
	declare @TabAuxEventoPreTotal table(IdEventoPre int)
	declare @TabAuxEventoPreInsert table(IdEventoPre int)


	insert into @TabAuxEventoPreTotal
	Select
		top 10000
			EventoPre.id
	From
		EventoPre WITH (READPAST) 
	where
		EventoPre.Processado = @NaoProcessado


	Insert into
				Evento 
					(
						IdGuid,
						IdContaSistema,
						IdEventoPre,
						EventoTipo,
						DtInclusao,
						ObjAcaoType,
						ObjJson,
						ObjTipo,
						Processado,
						DtProcessado,
						Status,
						QtdTentativaProcessamento,
						AvisarAdmOnError,
						GrupoProcessamento,
						TimeProcessamentoSeg,
						HrValidadeProcessamentoInicio,
						HrValidadeProcessamentoFim,
						ObjJsonLog,
						DtValidadeInicio					
					) OUTPUT inserted.IdEventoPre into @TabAuxEventoPreInsert
	select 
		NEWID() as IdGuid,
		TabAuxEventoPre.IdContaSistema,
		TabAuxEventoPre.IdEventoPre,
		TabAuxEventoPre.EventoTipo,
		@dtTimeNow as DtInclusao,
		TabAuxEventoPre.ObjAcaoType,
		TabAuxEventoPre.ObjJson,
		TabAuxEventoPre.ObjTipo,
		0 as Processado,
		null as DtProcessado,
		'INC' as Status,
		0 as QtdTentativaProcessamento,
		TabAuxEventoPre.AvisarAdmOnError,
		TabAuxEventoPre.GrupoProcessamento,
		0 as TimeProcessamentoSeg,
		TabAuxEventoPre.HrValidadeProcessamentoInicio,
		TabAuxEventoPre.HrValidadeProcessamentoFim,
		null as ObjJsonLog,	
		case
			when TabAuxEventoPre.HrValidadeProcessamentoInicio is not null and TabAuxEventoPre.HrValidadeProcessamentoInicio < @timeNow then	
					CAST(@dtAmanha as datetime) + CAST(TabAuxEventoPre.HrValidadeProcessamentoInicio as datetime)
				else 
					@dtTimeNow
				end as DtValidadeInicio

	from 
		(
			Select distinct 
			 
				TabJSon.IdContaSistema as IdContaSistema,
				TabAuxEventoPreTotal.IdEventoPre as IdEventoPre,
				EventoPre.EventoTipo as EventoTipo,
				Acao.ObjType as ObjAcaoType,
				EventoPre.ObjJson as ObjJson,
				EventoPre.ObjTipo as ObjTipo,
				TabJSon.EnviarEmailAdmError as AvisarAdmOnError,
				EventoTipo.GrupoProcessamento as GrupoProcessamento,
				case 
						when AcaoEventoTipo.HrValidadeProcessamentoInicio is not null then 
							AcaoEventoTipo.HrValidadeProcessamentoInicio
						else
							EventoTipo.HrValidadeProcessamentoInicio
						end as HrValidadeProcessamentoInicio,

				case 
					when AcaoEventoTipo.HrValidadeProcessamentoFim is not null then 
						AcaoEventoTipo.HrValidadeProcessamentoFim
					else
						EventoTipo.HrValidadeProcessamentoFim
					end as HrValidadeProcessamentoFim

			From
				@TabAuxEventoPreTotal TabAuxEventoPreTotal 
					inner join 
				EventoPre on EventoPre.id = TabAuxEventoPreTotal.IdEventoPre
					CROSS APPLY 
				OPENJSON(EventoPre.ObjJson) 
											WITH	(
														IdContaSistema int '$.IdContaSistema',
														IdCampanha int '$.IdCampanha',
														IdUsuarioContaSistema int '$.IdUsuarioContaSistema',
														Observar bit '$.Observar',
														AutoExecutavel bit '$.AutoExecutavel',
														AcaoExecutadaNaInsersao bit '$.AcaoExecutadaNaInsersao',
														EnviarEmailAdmError bit '$.EnviarEmailAdmError'
													)  TabJSon
					inner join
				EventoTipo WITH (nolock) on EventoPre.EventoTipo = EventoTipo.Tipo and EventoTipo.Status = 'AT'
					left outer join
				Gatilho WITH (nolock) on	EventoTipo.Tipo is not null and
											(
												Gatilho.idContaSistema = TabJSon.IdContaSistema and 
												(Gatilho.IdCampanha is null or Gatilho.IdCampanha = TabJSon.IdCampanha) and 
												Gatilho.EventoTipo = EventoTipo.Tipo and
												Gatilho.Status = 'AT'
											)
					left outer join
				GatilhoAcao WITH (nolock) on GatilhoAcao.IdGatilho = Gatilho.id
					left outer join
				AcaoEventoTipo with (nolock) on 
													(
														(
															AcaoEventoTipo.IdAcao = GatilhoAcao.IdAcao and 
															AcaoEventoTipo.EventoTipo = Gatilho.EventoTipo
														)
															or
														(
															AcaoEventoTipo.AutoExecutavel = 1 and
															AcaoEventoTipo.EventoTipo = EventoTipo.Tipo
														)
													)
					left outer join
				Acao with (nolock) on Acao.Id = AcaoEventoTipo.IdAcao and Acao.Status = 'AT'
				
			Where
				TabJSon.Observar = 1
					and
				Acao.Id is not null
				

		) TabAuxEventoPre

	-- Se faz necessário estar na mesma transação para garantir que tudo que será processado será convertido em evento
	update 
		EventoPre
				set
					EventoPre.Status = 'PRO',
					EventoPre.DtProcessado = @dtTimeNow,
					EventoPre.Processado = @Processado
	where
		exists (Select TabAux.IdEventoPre from @TabAuxEventoPreInsert TabAux where TabAux.IdEventoPre = EventoPre.Id and EventoPre.Processado = 0)


	update 
		EventoPre
				set
					EventoPre.Status = 'CAN',
					EventoPre.DtProcessado = @dtTimeNow,
					EventoPre.Processado = @Processado
	where
		exists (Select TabAux.IdEventoPre from @TabAuxEventoPreTotal TabAux where TabAux.IdEventoPre = EventoPre.Id and EventoPre.Processado = 0)


	-- Atualiza os GatilhoExecucao como inativado para os que passaram da data de validade
	-- Se faz necessário para que o gatilho possa funcionar novamente
	update 
		GatilhoExecucao 
			set 
				DtAlteracao = @dtTimeNow, 
				Status = 'DE' 
		
			where 
				Status = 'AT' and 
				dtValidade is not null and 
				dtValidade <= @dtTimeNow

end;

-- Pré-processa os eventos antes do processamento
-- 25/10/2021
CREATE procedure [dbo].[ProcEventoPreProcessamentoOld]
 as 
begin

	-- comentar
	-- return

	declare @NaoProcessado bit = 0
	declare @Processado bit = 1
	declare @dtTimeNow datetime = dbo.getdatecustom()
	declare @dtNow date = @dtTimeNow
	declare @dtAmanha date = DateADD(DAY, 1, @dtNow)
	declare @timeNow time = @dtTimeNow
	declare @TabAuxEventoPreTotal table(IdEventoPre int)
	declare @TabAuxEventoPreInsert table(IdEventoPre int)


	insert into @TabAuxEventoPreTotal
	Select
		top 10000
			EventoPre.id
	From
		EventoPre WITH (READPAST) 
	where
		EventoPre.Processado = @NaoProcessado



	--Insert into
	--			Evento 
	--				(
	--					IdGuid,
	--					IdContaSistema,
	--					IdEventoPre,
	--					EventoTipo,
	--					DtInclusao,
	--					ObjAcaoType,
	--					ObjJson,
	--					ObjTipo,
	--					Processado,
	--					DtProcessado,
	--					Status,
	--					QtdTentativaProcessamento,
	--					AutoExecutavel,
	--					AvisarAdmOnError,
	--					GrupoProcessamento,
	--					TimeProcessamentoSeg,
	--					HrValidadeProcessamentoInicio,
	--					HrValidadeProcessamentoFim,
	--					ObjJsonLog,
	--					DtValidadeInicio					
	--				) OUTPUT inserted.IdEventoPre into @TabAuxEventoPreInsert
	--select 
	--	NEWID() as IdGuid,
	--	TabAuxEventoPre.IdContaSistema,
	--	TabAuxEventoPre.IdEventoPre,
	--	TabAuxEventoPre.EventoTipo,
	--	@dtTimeNow as DtInclusao,
	--	TabAuxEventoPre.ObjAcaoType,
	--	TabAuxEventoPre.ObjJson,
	--	TabAuxEventoPre.ObjTipo,
	--	0 as Processado,
	--	null as DtProcessado,
	--	'INC' as Status,
	--	0 as QtdTentativaProcessamento,
	--	TabAuxEventoPre.AutoExecutavel,
	--	TabAuxEventoPre.AvisarAdmOnError,
	--	TabAuxEventoPre.GrupoProcessamento,
	--	0 as TimeProcessamentoSeg,
	--	TabAuxEventoPre.HrValidadeProcessamentoInicio,
	--	TabAuxEventoPre.HrValidadeProcessamentoFim,
	--	null as ObjJsonLog,	
	--	case
	--		when TabAuxEventoPre.HrValidadeProcessamentoInicio is not null and TabAuxEventoPre.HrValidadeProcessamentoInicio < @timeNow then	
	--				CAST(@dtAmanha as datetime) + CAST(TabAuxEventoPre.HrValidadeProcessamentoInicio as datetime)
	--			else 
	--				@dtTimeNow
	--			end as DtValidadeInicio

	--from 
	--	(
	--		Select
	--			TabJSon.IdContaSistema as IdContaSistema,
	--			TabAuxEventoPreTotal.IdEventoPre as IdEventoPre,
	--			EventoPre.EventoTipo as EventoTipo,
	--			Acao.ObjType as ObjAcaoType,
	--			EventoPre.ObjJson as ObjJson,
	--			EventoPre.ObjTipo as ObjTipo,
	--			TabJSon.AutoExecutavel as AutoExecutavel,
	--			TabJSon.EnviarEmailAdmError as AvisarAdmOnError,
	--			EventoTipo.GrupoProcessamento as GrupoProcessamento,
	--			case 
	--					when AcaoEventoTipo.HrValidadeProcessamentoInicio is not null then 
	--						AcaoEventoTipo.HrValidadeProcessamentoInicio
	--					else
	--						EventoTipo.HrValidadeProcessamentoInicio
	--					end as HrValidadeProcessamentoInicio,

	--			case 
	--				when AcaoEventoTipo.HrValidadeProcessamentoFim is not null then 
	--					AcaoEventoTipo.HrValidadeProcessamentoFim
	--				else
	--					EventoTipo.HrValidadeProcessamentoFim
	--				end as HrValidadeProcessamentoFim

	--		From
	--			@TabAuxEventoPreTotal TabAuxEventoPreTotal 
	--				inner join 
	--			EventoPre WITH (READPAST) on EventoPre.id = TabAuxEventoPreTotal.IdEventoPre
	--				CROSS APPLY 
	--			OPENJSON(EventoPre.ObjJson) 
	--										WITH	(
	--													IdContaSistema int '$.IdContaSistema',
	--													IdCampanha int '$.IdCampanha',
	--													IdUsuarioContaSistema int '$.IdUsuarioContaSistema',
	--													Observar bit '$.Observar',
	--													AutoExecutavel bit '$.AutoExecutavel',
	--													EnviarEmailAdmError bit '$.EnviarEmailAdmError'
	--												)  TabJSon
	--				inner join
	--			EventoTipo WITH (READPAST) on EventoPre.EventoTipo = EventoTipo.Tipo and EventoTipo.Status = 'AT'
	--				left outer join
	--			Gatilho WITH (READPAST) on	EventoTipo.Tipo is not null and TabJSon.AutoExecutavel = 0 and
	--										(
	--											Gatilho.idContaSistema = TabJSon.IdContaSistema and 
	--											(Gatilho.IdCampanha is null or Gatilho.IdCampanha = TabJSon.IdCampanha) and 
	--											Gatilho.EventoTipo = EventoTipo.Tipo and
	--											Gatilho.Status = 'AT'
	--										)
	--				left outer join
	--			GatilhoAcao WITH (READPAST) on TabJSon.AutoExecutavel = 0 and GatilhoAcao.IdGatilho = Gatilho.id
	--				left outer join
	--			AcaoEventoTipo with (READPAST) on TabJSon.AutoExecutavel = 0 and 
	--												(
	--													(
	--														AcaoEventoTipo.IdAcao = GatilhoAcao.IdAcao and 
	--														AcaoEventoTipo.EventoTipo = Gatilho.EventoTipo
	--													)
	--														or
	--													(
	--														AcaoEventoTipo.AutoExecutavel = 1 and
	--														AcaoEventoTipo.EventoTipo = EventoTipo.Tipo
	--													)
	--												)
	--				left outer join
	--			Acao with (READPAST) on TabJSon.AutoExecutavel = 0 and Acao.Id = AcaoEventoTipo.IdAcao and Acao.Status = 'AT'

	--		Where
	--			TabJSon.Observar = 1
	--				and
	--			(
	--				TabJSon.AutoExecutavel = 1
	--					or
	--				Acao.Id is not null
	--			)

	--	) TabAuxEventoPre

	---- Se faz necessário estar na mesma transação para garantir que tudo que será processado será convertido em evento
	--update 
	--	EventoPre
	--			set
	--				EventoPre.Status = 'PRO',
	--				EventoPre.DtProcessado = @dtTimeNow,
	--				EventoPre.Processado = @Processado
	--where
	--	exists (Select TabAux.IdEventoPre from @TabAuxEventoPreInsert TabAux where TabAux.IdEventoPre = EventoPre.Id and EventoPre.Processado = 0)


	--update 
	--	EventoPre
	--			set
	--				EventoPre.Status = 'CAN',
	--				EventoPre.DtProcessado = @dtTimeNow,
	--				EventoPre.Processado = @Processado
	--where
	--	exists (Select TabAux.IdEventoPre from @TabAuxEventoPreTotal TabAux where TabAux.IdEventoPre = EventoPre.Id and EventoPre.Processado = 0)




	---- Atualiza os GatilhoExecucao como inativado para os que passaram da data de validade
	---- Se faz necessário para que o gatilho possa funcionar novamente
	--update 
	--	GatilhoExecucao 
	--		set 
	--			DtAlteracao = @dtTimeNow, 
	--			Status = 'DE' 
		
	--		where 
	--			Status = 'AT' and 
	--			dtValidade is not null and 
	--			dtValidade <= @dtTimeNow

end;

CREATE procedure [dbo].[ProcExcluirAtendimento]
 @IdContaSistema as int,
 @IdUsuarioContaSistemaExecutou as int,
 @IdAtendimento as int,
 @obs varchar(max),
 @excluirPessoaProspect as bit = 0,
 @excluirPessoaProspectSomenteSeForUnico as bit = 1,
 @online bit = 0,
 @logar bit
 as 
begin
	set nocount on

	declare @dtnow datetime = dbo.getDateCustom()
	declare @idUsuarioContaSistemaAtendimento int
	declare @IdAtendimentoTest int
	declare @idPessoaProspect int
	declare @pessoaProspectNome varchar(1000)
	declare @qtdAtendimentoPessoaProspect int = 0
	declare @AtendimentoRegistroStatus varchar(300) = null

	DECLARE @TableTempInteracaoMarketing TABLE  
	(  
		id INT  
	);  

	Select @IdAtendimentoTest = Atendimento.id, @idUsuarioContaSistemaAtendimento = Atendimento.IdUsuarioContaSistemaAtendimento, @idPessoaProspect = Atendimento.idPessoaProspect, @AtendimentoRegistroStatus = Atendimento.RegistroStatus, @pessoaProspectNome = PessoaProspect.Nome from Atendimento with (nolock) inner join PessoaProspect with (nolock) on Atendimento.idPessoaProspect = PessoaProspect.Id  where Atendimento.IdContaSistema = @IdContaSistema and Atendimento.Id = @IdAtendimento

	if(@IdAtendimentoTest > 0)
		begin
			
			if @online = 0
				begin
					if dbo.RetNullOrVarChar(@AtendimentoRegistroStatus) is null or @AtendimentoRegistroStatus <> 'DEL'
						begin
							Update Atendimento
							set 
								StatusAtendimento = 'ENCERRADO',
								TipoDirecionamentoStatus = 'CONCLUIDO',
								DtConclusaoAtendimento = @dtnow,
								idGrupo = null,
								IdUsuarioContaSistemaAtendimento = null,
								RegistroStatus = 'DEL',
								RegistroStatusIdUsuarioContaSistema = @IdUsuarioContaSistemaExecutou
							where
								Atendimento.Id = @idAtendimento


						if(@logar = 1)
							begin
								set @obs = isnull(dbo.RetNullOrVarChar(@obs), '')

								INSERT INTO [dbo].[LogAcoes]
										   (
										   IdGuid
										   ,[IdContaSistema]
										   ,[IdUsuarioContaSistemaExecutou]
										   ,[Tipo]
										   ,[TipoSub]
										   ,[Texto]
										   ,[ValueOld]
										   ,[ValueNew]
										   ,[NomeMethod]
										   ,[DtInclusao]
										   ,[TabelaBD]
										   ,[TabelaBDChave]
										   ,[EnviarEmailAdministradorAnapro]
										   ,[IdUsuarioContaSistemaImpactou])
									 VALUES (
											NEWID(),
										   @IdContaSistema,
										   @IdUsuarioContaSistemaExecutou,
										   'Atendimento',
										   'Atendimento_AExcluir',
										   'Atendimento ('+ CONVERT(varchar(15), @idAtendimento) +') do prospect ('+@pessoaProspectNome+') exclusão solicitada.'+@obs,
										   CONVERT(varchar(15), @idAtendimento),
										   null,
										   'ProcExcluirAtendimento',
										   @dtnow,
										   'Atendimento',
										   CONVERT(varchar(15), @idAtendimento),
										   0,
										   null)
								end
						end

					return
				end

			if @excluirPessoaProspect = 1
				begin

					-- Verifica quantos atendimentos existem vinculados a pessoa prospect em questão
					-- se faz necessário para saber se deve excluir o prospect ou não caso exista mais de um atendimento para o mesmo prospect
					select @qtdAtendimentoPessoaProspect = (select count(Atendimento.Id) from Atendimento with (nolock) where Atendimento.idPessoaProspect = @idPessoaProspect)

					if @excluirPessoaProspectSomenteSeForUnico = 0 or @qtdAtendimentoPessoaProspect <= 1
						begin
							exec ProcExcluirPessoaProspect @IdContaSistema, @idPessoaProspect, @IdUsuarioContaSistemaExecutou, @obs, @logar

							return
						end
				end
			
			-- Caso exista usuário atendendo o atendimento, retirará a fidelização do prospect desse usuário já que o mesmo está sendo deletado
			if (@idUsuarioContaSistemaAtendimento > 0)
				begin
					update PessoaProspectFidelizado set DtFimFidelizacao = @dtnow 
					where
						PessoaProspectFidelizado.IdPessoaProspect = @idPessoaProspect and
						PessoaProspectFidelizado.IdUsuarioContaSistema = @idUsuarioContaSistemaAtendimento and
						PessoaProspectFidelizado.DtFimFidelizacao is null

				end

			-- Deleta PessoaProspectOrigemPessoaProspect	
			Delete PessoaProspectOrigemPessoaProspect
			where PessoaProspectOrigemPessoaProspect.IdAtendimento = @idAtendimento


			-- Deleta ProspeccaoPessoaProspect	
			Delete ProspeccaoPessoaProspect
			where ProspeccaoPessoaProspect.IdAtendimento = @idAtendimento

			-- Deleta atendimento	
			Delete OportunidadeNegocio
			where OportunidadeNegocio.IdAtendimento = @idAtendimento

			-- Deleta atendimento	
			Delete AtendimentoSeguidor
			where
				AtendimentoSeguidor.IdAtendimento = @idAtendimento


			update Interacao set IdInteracaoParent = null 
			where
				Interacao.IdSuperEntidade = @idAtendimento

			-- seta as interações como null para que seja possível deletar em cascata
			update Atendimento
					set 
						Atendimento.IdInteracaoAutoUltima = null,
						Atendimento.IdInteracaoProspectUltima = null,
						Atendimento.IdInteracaoUsuarioUltima = null,
						Atendimento.IdAlarmeProximoAtivo = null,
						Atendimento.IdAlarmeUltimo = null,
						Atendimento.IdAlarmeUltimoAtivo = null,
						Atendimento.idInteracaoNegociacaoVendaUltima = null
				where
					Atendimento.Id = @idAtendimento
			
			
			;WITH tableInteracaoObj AS(
				SELECT Id
				FROM InteracaoObj
				WHERE InteracaoObj.IdSuperEntidade =  @idAtendimento
			)

			DELETE
			FROM tableInteracaoObj


			Delete Interacao OUTPUT deleted.IdInteracaoMarketing  INTO @TableTempInteracaoMarketing 
			where
				Interacao.IdSuperEntidade = @idAtendimento

			delete InteracaoMarketing where InteracaoMarketing.id in (select TabAux.id from @TableTempInteracaoMarketing TabAux)

			Delete Alarme
			where Alarme.idSuperEntidade = @idAtendimento

			-- Deleta atendimento	
			Delete Atendimento
			where
				Atendimento.Id = @idAtendimento
					and
				Atendimento.idContaSistema = @idContaSistema
			
			-- Deleta SuperEntidade
			Delete SuperEntidade 
			where 
				SuperEntidade.Id = @idAtendimento
					and
				SuperEntidade.idContaSistema = @idContaSistema

			-- deleta do resumo de interação
			delete TabelaoAtendimento where TabelaoAtendimento.AtendimentoId = @idAtendimento
			
			-- deleta do resumo de interação
			delete TabelaoInteracaoResumo where IdAtendimento = @idAtendimento

			-- deleta as notificações globais
			delete NotificacaoGlobal where NotificacaoGlobal.CodigoIdentificadorEntidade = 'Atendimento' and NotificacaoGlobal.CodigoIdentificadorInt = @idAtendimento
			

			if(@logar = 1)
				begin
					set @obs = isnull(dbo.RetNullOrVarChar(@obs), '')

					INSERT INTO [dbo].[LogAcoes]
							   (
							   idGuid
							   ,[IdContaSistema]
							   ,[IdUsuarioContaSistemaExecutou]
							   ,[Tipo]
							   ,[TipoSub]
							   ,[Texto]
							   ,[ValueOld]
							   ,[ValueNew]
							   ,[NomeMethod]
							   ,[DtInclusao]
							   ,[TabelaBD]
							   ,[TabelaBDChave]
							   ,[EnviarEmailAdministradorAnapro]
							   ,[IdUsuarioContaSistemaImpactou])
						 VALUES (
								NEWID(),
							   @IdContaSistema,
							   @IdUsuarioContaSistemaExecutou,
							   'Atendimento',
							   'Atendimento_Excluido',
							   'Atendimento ('+ CONVERT(varchar(15), @idAtendimento) +') do prospect ('+@pessoaProspectNome+') excluído.'+@obs,
							   CONVERT(varchar(15), @idAtendimento),
							   null,
							   'ProcExcluirAtendimento',
							   @dtnow,
							   'Atendimento',
							   CONVERT(varchar(15), @idAtendimento),
							   0,
							   null)
					end

	end
end;

CREATE procedure [dbo].[ProcExcluirAtendimentoPreparacao]
 @IdContaSistema as int,
 @idUsuarioContaSistema as int,
 @strMotivo as varchar(max),
 @idsAtendimentos as varchar(max)
 as 

declare @dtnow datetime = dbo.getDateCustom()
declare @idAtendimento int

DECLARE AtendimentoCursorX CURSOR FOR
	(
		Select OrderID from SplitIDs(@idsAtendimentos)
	)

	-- abre o cursor e aloca o próximo
	open AtendimentoCursorX fetch next from AtendimentoCursorX into @IdAtendimento

	-- faz o loop nas conta sistema
	while(@@FETCH_STATUS = 0 )
		BEGIN
			exec ProcExcluirAtendimento @idContaSistema, @idUsuarioContaSistema, @idAtendimento, @strMotivo, 1, 1, 0, 1

			fetch next from AtendimentoCursorX into @idAtendimento
		end

	close AtendimentoCursorX
	deallocate AtendimentoCursorX;

CREATE procedure [dbo].[ProcExcluirGrupo] @IdContaSistema as int, @IdUsuarioContaSistemaExecutandoAcao as int, @IdGrupoDel as int
 as 
begin
	Declare @dtNow as datetime = dbo.GetDateCustom()

	begin tran
		-- Seleciona todos os grupos inferiores ao grupo atual
		Select
			GrupoSuperior.idGrupoInferior into #temp
		from 
			GetGrupoHierarquia(@IdContaSistema) GrupoSuperior
		where
			GrupoSuperior.idGrupoSuperior = @IdGrupoDel

		-- Desativa todos os grupos que serão excluídos
		update
			Grupo
		set
			Grupo.Status = 'DE',
			Grupo.DtAtualizacao = @dtNow
		from
			Grupo with (nolock)
		where
			Grupo.IdContaSistema = @IdContaSistema
				and
			(
				exists (Select * from #temp temp where temp.idGrupoInferior = Grupo.Id)
					or
				Grupo.Id = @IdGrupoDel
			)

		--Coloca data fim nos usuarios dos grupos desativados
		update
			UsuarioContaSistemaGrupo
		set
			UsuarioContaSistemaGrupo.DtFim = @dtNow
		from
			UsuarioContaSistemaGrupo with (nolock)
		where
			(
				exists (Select * from #temp temp where temp.idGrupoInferior = UsuarioContaSistemaGrupo.IdGrupo)
					or
				UsuarioContaSistemaGrupo.IdGrupo = @IdGrupoDel
			)

		--Coloca data fim nos usuarios ADM dos grupos desativados
		update
			UsuarioContaSistemaGrupoAdm
		set
			UsuarioContaSistemaGrupoAdm.DtFim = @dtNow
		from
			UsuarioContaSistemaGrupoAdm with (nolock)
		where
			(
				exists (Select * from #temp temp where temp.idGrupoInferior = UsuarioContaSistemaGrupoAdm.IdGrupo)
					or
				UsuarioContaSistemaGrupoAdm.IdGrupo = @IdGrupoDel
			)

		-- Deleta os grupos excluídos de todas as campanhas
		begin
			with cteCampanhaGrupo as 
			(
				select 
					CampanhaGrupo.Id
				from 
					CampanhaGrupo with (nolock) 
				where
					exists (Select * from #temp temp where temp.idGrupoInferior = CampanhaGrupo.IdGrupo)
						or
					CampanhaGrupo.IdGrupo = @IdGrupoDel
			)
			delete from cteCampanhaGrupo
		end
	commit

	-- Recria a hierarquia de grupos da conta sistema
	--exec ProcGerarGrupoHierarquia @IdContaSistema
end;

CREATE procedure [dbo].[ProcExcluirInteracao]
 @IdContaSistema as int,
 @IdSuperEntidade as int,
 @idInteracao int
 as 
begin

set nocount on

DECLARE @TableTempInteracaoMarketing TABLE  
(  
	id INT  
);  

-- Atualiza as referencias de atendimento log caso exista
update Atendimento set 
						Atendimento.IdInteracaoAutoUltima = case when Atendimento.IdInteracaoAutoUltima = @idInteracao then null else Atendimento.IdInteracaoAutoUltima end,
						Atendimento.IdInteracaoProspectUltima = case when Atendimento.IdInteracaoProspectUltima = @idInteracao then null else Atendimento.IdInteracaoProspectUltima end,
						Atendimento.IdInteracaoUsuarioUltima = case when Atendimento.IdInteracaoUsuarioUltima = @idInteracao then null else Atendimento.IdInteracaoUsuarioUltima end
	from 
		Atendimento WITH (NOLOCK) 
	where
		Atendimento.id = @IdSuperEntidade
			and
		Atendimento.idContaSistema = @IdContaSistema
			and
		(
			Atendimento.IdInteracaoAutoUltima = @idInteracao
				or
			Atendimento.IdInteracaoProspectUltima = @idInteracao
				or
			Atendimento.IdInteracaoUsuarioUltima = @idInteracao
		)

-- deleta a interacao
Delete InteracaoMarketing
	from 
		Interacao WITH (NOLOCK)
			inner join
		InteracaoMarketing   WITH (NOLOCK) on InteracaoMarketing.id = Interacao.IdInteracaoMarketing
	where
		Interacao.idContaSistema = @IdContaSistema
			and
		Interacao.Id = @idInteracao
			and
		Interacao.IdSuperEntidade = @IdSuperEntidade

-- deleta a interacao
Delete Interacao OUTPUT deleted.IdInteracaoMarketing  INTO @TableTempInteracaoMarketing 
	from 
		Interacao WITH (NOLOCK)
			inner join
		SuperEntidade   WITH (NOLOCK) on SuperEntidade.id = Interacao.IdSuperEntidade
	where
		SuperEntidade.idContaSistema = @IdContaSistema
			and
		Interacao.Id = @idInteracao
			and
		Interacao.IdSuperEntidade = @IdSuperEntidade

delete InteracaoMarketing where InteracaoMarketing.id in (select TabAux.id from @TableTempInteracaoMarketing TabAux)

	-- deleta TabelaoInteracaoResumo
Delete TabelaoInteracaoResumo where TabelaoInteracaoResumo.IdInteracao = @idInteracao and TabelaoInteracaoResumo.IdContaSistema = @IdContaSistema and TabelaoInteracaoResumo.IdAtendimento = @IdSuperEntidade

end;

CREATE procedure [dbo].[ProcExcluirInteracaoDuplicado]
 @IdContaSistema as int,
 @IdCampanha as int,
 @idInteracao int
 as 
begin

declare @idAtendimento int

Select 
	@idAtendimento = max(Interacao.IdSuperEntidade)
From 
	Interacao WITH (nolock)
		inner join
	Atendimento  WITH (nolock) on Atendimento.Id = Interacao.IdSuperEntidade

Where
	Atendimento.idContaSistema = @IdContaSistema and
	Atendimento.idCampanha = @IdCampanha and
	Interacao.Id = @idInteracao and
	Interacao.Tipo = 'OUTROS' and
	Exists
	(
		Select InteracaoOld.Id
		From 
			Interacao InteracaoOld   WITH (READPAST)
		where
			InteracaoOld.IdSuperEntidade = Interacao.IdSuperEntidade and
			InteracaoOld.Id < Interacao.Id and
			InteracaoOld.DtInclusao > DATEADD(MINUTE, -30, Interacao.DtInclusao) and
			InteracaoOld.Tipo = Interacao.Tipo
	)
	
	-- caso exista irá excluir
	if @idAtendimento is not null and @idAtendimento > 0
		begin
			exec ProcExcluirInteracao @IdContaSistema, @idAtendimento, @idInteracao
		end
end;

CREATE procedure [dbo].[ProcExcluirLogAcoes]
as 
begin


	declare @iQtdGeral int = 200000
	declare @iQtdPorTransaction int = 500

	Select 
		top (@iQtdGeral)
			ROW_NUMBER() OVER(ORDER BY LogAcoes.id ASC) AS RowNumber,
			LogAcoes.Id
		into #tableTabAux
	from
		LogAcoes with (nolock)
			inner join
		ContaSistema  with (nolock) on ContaSistema.Id = LogAcoes.IdContaSistema

	where
		ContaSistema.Status = 'DE'


	declare @iCount int = (Select count(TabAux.Id) from #tableTabAux TabAux);
	declare @i int = 1;

	WHILE @i <= @iCount 
		BEGIN
			BEGIN TRANSACTION
				delete 
					LogAcoes 
					
					from
						LogAcoes
							inner join
						#tableTabAux tabAux on tabAux.Id = LogAcoes.Id and tabAux.rownumber between @i and @i + @iQtdPorTransaction


				set @i = @i + @iQtdPorTransaction + 1
			commit
		end


		drop table #tableTabAux

end;

CREATE procedure [dbo].[ProcExcluirPessoaProspect]
  @contaSistemaId int, @pessoaProspectId int, @idUsuarioExecutandoAcao int, @obs varchar(max), @logar bit
as
begin

	set nocount on

	declare @atendimentoIdDel as int
	declare @pessoaProspectIdDel as int
	declare @dtNow as datetime = dbo.GetDateCustom()
	declare @ProspectNome as varchar(2000) 

	Select @pessoaProspectIdDel = PessoaProspect.Id, @ProspectNome = PessoaProspect.Nome
	from PessoaProspect
	where
		PessoaProspect.Id = @pessoaProspectId and PessoaProspect.IdContaSistema = @contaSistemaId
	
	DECLARE @TableTemp TABLE  
	(  
		id INT  
	);  

	DECLARE @TableAtendimentoTemp TABLE  
	(  
		atendimentoId INT  
	);  


	if @pessoaProspectIdDel is not null
		begin
			
			-- Verifica se o prospect tem atendimento
			insert into @TableAtendimentoTemp
			Select 
				Atendimento.Id
			from
				Atendimento with (nolock) 
			where
				Atendimento.idPessoaProspect = @pessoaProspectId and Atendimento.IdContaSistema = @contaSistemaId

			set @atendimentoIdDel = (Select top 1 TabAux.atendimentoId from @TableAtendimentoTemp TabAux)


			if @atendimentoIdDel is not null
				begin	
					DECLARE AtendimentoCursorX CURSOR FOR
					(	
						Select
							TabAux.atendimentoId
						from
							@TableAtendimentoTemp TabAux

					) open AtendimentoCursorX fetch next from AtendimentoCursorX into @atendimentoIdDel

					while(@@FETCH_STATUS = 0 )
						begin
			
							exec ProcExcluirAtendimento @contaSistemaId, @idUsuarioExecutandoAcao, @atendimentoIdDel, @obs, 0, 0, 1, @logar

						fetch next from AtendimentoCursorX into @atendimentoIdDel
					end

					close AtendimentoCursorX
					deallocate AtendimentoCursorX

					
				end

			delete from dbo.EnrichPersonSolicitanteEnrichPersonDataSource
			from dbo.EnrichPersonSolicitanteEnrichPersonDataSource
			inner join dbo.EnrichPersonSolicitante on dbo.EnrichPersonSolicitanteEnrichPersonDataSource.IdEnrichPersonSolicitante=dbo.EnrichPersonSolicitante.Id
			where EnrichPersonSolicitante.IdPessoaProspect = @pessoaProspectId
 
			delete from dbo.EnrichPersonSolicitante
			where EnrichPersonSolicitante.IdPessoaProspect = @pessoaProspectId
				
			delete from dbo.PessoaProspectOrigemPessoaProspect
			OUTPUT deleted.IdPessoaProspectImportacaoTemp  INTO @TableTemp 
			where PessoaProspectOrigemPessoaProspect.IdPessoaProspect = @pessoaProspectId

			delete from PessoaProspectImportacaoTemp where PessoaProspectImportacaoTemp.Id in (Select TableAux.id from @TableTemp TableAux)
 
			delete from dbo.ProspeccaoPessoaProspect
			where ProspeccaoPessoaProspect.IdPessoaProspect = @pessoaProspectId

			delete from dbo.PessoaProspectTag
			where PessoaProspectTag.IdPessoaProspect = @pessoaProspectId
 
			delete SuperEntidade
			from
				SuperEntidade
					inner join
				OportunidadeNegocio on SuperEntidade.Id = OportunidadeNegocio.IdSuperEntidade
			where 
				OportunidadeNegocio.IdPessoaProspect = @pessoaProspectId

			delete from dbo.OportunidadeNegocio
			where OportunidadeNegocio.IdPessoaProspect = @pessoaProspectId

			delete from dbo.PessoaProspectFidelizado
			from dbo.PessoaProspectFidelizado
			inner join dbo.PessoaProspect on dbo.PessoaProspectFidelizado.IdPessoaProspect=dbo.PessoaProspect.Id
			where dbo.PessoaProspect.id = @pessoaProspectId and PessoaProspect.IdContaSistema = @contaSistemaId;
 
			delete from dbo.PoliticaDePrivacidadePessoaProspect
			from dbo.PoliticaDePrivacidadePessoaProspect
			inner join dbo.PessoaProspect on dbo.PoliticaDePrivacidadePessoaProspect.IdPessoaProspect=dbo.PessoaProspect.Id
			where dbo.PessoaProspect.id = @pessoaProspectId and PessoaProspect.IdContaSistema = @contaSistemaId;
 
			delete from dbo.PessoaProspectPrefereciaFidelizacao
			from dbo.PessoaProspectPrefereciaFidelizacao
			inner join dbo.PessoaProspect on dbo.PessoaProspectPrefereciaFidelizacao.IdPessoaProspect=dbo.PessoaProspect.Id
			where dbo.PessoaProspect.id = @pessoaProspectId and PessoaProspect.IdContaSistema = @contaSistemaId;
 
			delete from dbo.RespostaFichaPesquisa
			where dbo.RespostaFichaPesquisa.IdPessoaProspect = @pessoaProspectId
 
			delete from dbo.PessoaProspectEmail
			where PessoaProspectEmail.IdPessoaProspect = @pessoaProspectId
 
			delete from dbo.PessoaProspectDocumento
			where dbo.PessoaProspectDocumento.IdPessoaProspect = @pessoaProspectId 
 
			delete from dbo.PessoaProspectPerfil
			where dbo.PessoaProspectPerfil.IdPessoaProspect = @pessoaProspectId 
 
			delete from dbo.PessoaProspectTelefone
			where dbo.PessoaProspectTelefone.IdPessoaProspect = @pessoaProspectId 
 
			delete from dbo.PessoaProspectEndereco
			where dbo.PessoaProspectEndereco.IdPessoaProspect = @pessoaProspectId
 
			delete from dbo.PessoaProspectProdutoInteresse
			where dbo.PessoaProspectProdutoInteresse.IdPessoaProspect = @pessoaProspectId 
 
			delete from dbo.PessoaProspectDadosGerais
			where dbo.PessoaProspectDadosGerais.IdPessoaProspect = @pessoaProspectId
 
			delete from dbo.PessoaProspect
			where dbo.PessoaProspect.id = @pessoaProspectId

			delete from dbo.SuperEntidade
			where dbo.SuperEntidade.id = @pessoaProspectId
 
			if(@logar = 1)
				begin
					set @obs = isnull(dbo.RetNullOrVarChar(@obs), '')

					INSERT INTO [dbo].[LogAcoes]
								(
								IdGuid
								,[IdContaSistema]
								,[IdUsuarioContaSistemaExecutou]
								,[Tipo]
								,[TipoSub]
								,[Texto]
								,[ValueOld]
								,[ValueNew]
								,[NomeMethod]
								,[DtInclusao]
								,[TabelaBD]
								,[TabelaBDChave]
								,[EnviarEmailAdministradorAnapro]
								,[IdUsuarioContaSistemaImpactou])
							VALUES (
								NEWID(),
								@contaSistemaId,
								@idUsuarioExecutandoAcao,
								'Prospect',
								'Prospect_Excluido',
								'Prospect nome: ('+@ProspectNome+'), id: ('+ CONVERT(varchar(15), @pessoaProspectId) +') excluído.'+@obs,
								CONVERT(varchar(15), @pessoaProspectId),
								null,
								'ProcExcluirPessoaProspect',
								@dtnow,
								'PessoaProspect',
								CONVERT(varchar(15), @pessoaProspectId),
								0,
								null)
					end
	end
end;

-- Exclui todos os registros e referências relativas a PessoaProspectImportacao
CREATE procedure [dbo].[ProcExcluirPessoaProspectImportacao]
 @IdContaSistema as int,
 @idUsuarioContaSistema as int,
 @idPessoaProspectImportacao int,
 @strMotivo varchar(max)
 as 

declare @dtnow datetime = dbo.getDateCustom()
declare @iQtdPorTransaction int = 100
declare @idsAtendimentosExcluidos varchar(max)
declare @nomeImportacao varchar(max)

-- recupera o id atrelado a contasistema por segurança
Select top 1 @idPessoaProspectImportacao = PessoaProspectImportacao.id, @nomeImportacao = PessoaProspectImportacao.Nome from PessoaProspectImportacao WITH (NOLOCK) where PessoaProspectImportacao.Id = @idPessoaProspectImportacao and PessoaProspectImportacao.idContaSistema = @IdContaSistema


if @idPessoaProspectImportacao is not null
	begin
		
		begin -- #START - Seta os atendimentos que serão excluídos

			-- Seleciona os possíveis atendimentos que serão excluídos
			-- de acordo com os ids dos Prospects
			Select	
				ROW_NUMBER() OVER(ORDER BY tabAux2.id ASC) AS RowNumber,
				tabAux2.id as AtendimentoId

			into #tableTabAux
			from
				(
					select 
						distinct Atendimento.Id
	
					from 
						PessoaProspectOrigemPessoaProspect with (nolock)
							inner join
						PessoaProspectOrigem with (nolock) on PessoaProspectOrigemPessoaProspect.IdPessoaProspectOrigem = PessoaProspectOrigem.Id
							inner join
						Atendimento with (nolock) on Atendimento.idPessoaProspect = PessoaProspectOrigemPessoaProspect.IdPessoaProspect
					where
						PessoaProspectOrigem.IdPessoaProspectImportacao = @idPessoaProspectImportacao
				) tabAux2

			declare @iCount int = (Select count(TabAux.AtendimentoId) from #tableTabAux TabAux);
			declare @i int = 1;


			WHILE @i <= @iCount 
				BEGIN

						Select
							@idsAtendimentosExcluidos = CONCAT(STRING_AGG(tabAux.AtendimentoId,','), ',', @idsAtendimentosExcluidos)
						from
							#tableTabAux tabAux
						where
							tabAux.rownumber between @i and @i + @iQtdPorTransaction


					set @i = @i + @iQtdPorTransaction + 1

				end
				
				-- exclui a tabela temporária
				drop table #tableTabAux

		end -- #END


		-- Exclui os registros da tabela ProspeccaoPessoaProspectOrigem referente as prospecções que contem essa importação
		begin tran
			delete ProspeccaoPessoaProspectOrigem
			from
				ProspeccaoPessoaProspectOrigem WITH (NOLOCK)
					inner join
				PessoaProspectOrigem  WITH (NOLOCK) on PessoaProspectOrigem.id = ProspeccaoPessoaProspectOrigem.IdPessoaProspectOrigem
			where
				PessoaProspectOrigem.IdPessoaProspectImportacao = @idPessoaProspectImportacao
		commit

		-- Exclui os registros da tabela ProspeccaoPessoaProspect referente as prospecções que contem essa importação
		begin tran
			delete ProspeccaoPessoaProspect
			from
				ProspeccaoPessoaProspect  WITH (NOLOCK)
					inner join
				PessoaProspectOrigemPessoaProspect  WITH (NOLOCK) on PessoaProspectOrigemPessoaProspect.Id = ProspeccaoPessoaProspect.IdPessoaProspectOrigemPessoaProspect
					inner join
				PessoaProspectOrigem  WITH (NOLOCK) on PessoaProspectOrigem.Id = PessoaProspectOrigemPessoaProspect.IdPessoaProspectOrigem
			where
				PessoaProspectOrigem.IdPessoaProspectImportacao = @idPessoaProspectImportacao
		commit


		-- Exclui os registros da tabela PessoaProspectOrigemPessoaProspect referente as prospecções que contem essa importação
		begin tran
			delete PessoaProspectOrigemPessoaProspect
			from
				PessoaProspectOrigemPessoaProspect  WITH (NOLOCK)
					inner join
				PessoaProspectOrigem  WITH (NOLOCK) on PessoaProspectOrigem.Id = PessoaProspectOrigemPessoaProspect.IdPessoaProspectOrigem
			where
				PessoaProspectOrigem.IdPessoaProspectImportacao = @idPessoaProspectImportacao
		commit

		-- Exclui os registros da tabela PessoaProspectOrigem referente as prospecções que contem essa importação
		begin tran
			delete PessoaProspectOrigem
			where
				PessoaProspectOrigem.IdPessoaProspectImportacao = @idPessoaProspectImportacao
		commit

		-- Exclui os registros da tabela PessoaProspectImportacaoTemp referente a 
		begin tran
			delete PessoaProspectImportacaoTemp where PessoaProspectImportacaoTemp.IdPessoaProspectImportacao = @idPessoaProspectImportacao
		commit

		-- Exclui os registros da tabela PessoaProspectImportacao referente as prospecções que contem essa importação
		begin tran
			delete PessoaProspectImportacao
			where
				PessoaProspectImportacao.Id = @idPessoaProspectImportacao
		commit


		INSERT INTO [dbo].[LogAcoes]
				   (
				   IdGuid
				   ,[IdContaSistema]
				   ,[IdUsuarioContaSistemaExecutou]
				   ,[Tipo]
				   ,[TipoSub]
				   ,[Texto]
				   ,[ValueOld]
				   ,[ValueNew]
				   ,[NomeMethod]
				   ,[DtInclusao]
				   ,[TabelaBD]
				   ,[TabelaBDChave]
				   ,[EnviarEmailAdministradorAnapro]
				   ,[IdUsuarioContaSistemaImpactou])
			 VALUES (
					NEWID(),
				   @IdContaSistema,
				   @idUsuarioContaSistema,
				   'ImportacaoProspect',
				   'ImportacaoProspect_Excluido',
				   'Importação id: '+ CONVERT(varchar(15), @idPessoaProspectImportacao) +', nome: ' + @nomeImportacao +' excluída. Motivo: '+ @strMotivo,
				   'idsAtendimentos: '+@idsAtendimentosExcluidos,
				   null,
				   'ProcExcluirPessoaProspectImportacao',
				   @dtnow,
				   'PessoaProspectImportacao',
				   CONVERT(varchar(15), @idPessoaProspectImportacao),
				   0,
				   null)


	end;

CREATE procedure [dbo].[ProcExcluirPessoaProspectIntegracaoLog]
as 
begin


	declare @iQtdGeral int = 200000
	declare @iQtdPorTransaction int = 500

	Select 
		top (@iQtdGeral)
			ROW_NUMBER() OVER(ORDER BY PessoaProspectIntegracaoLog.id ASC) AS RowNumber,
			PessoaProspectIntegracaoLog.Id
		into #tableTabAux
	from
		PessoaProspectIntegracaoLog with (nolock)
			inner join
		ContaSistema  with (nolock) on ContaSistema.Id = PessoaProspectIntegracaoLog.IdContaSistema

	where
		ContaSistema.Status = 'DE'


	declare @iCount int = (Select count(TabAux.Id) from #tableTabAux TabAux);
	declare @i int = 1;

	WHILE @i <= @iCount 
		BEGIN
			BEGIN TRANSACTION
				delete 
					PessoaProspectIntegracaoLog 
					
					from
						PessoaProspectIntegracaoLog
							inner join
						#tableTabAux tabAux on tabAux.Id = PessoaProspectIntegracaoLog.Id and tabAux.rownumber between @i and @i + @iQtdPorTransaction


				set @i = @i + @iQtdPorTransaction + 1
			commit
		end


		drop table #tableTabAux

end;

-- 25/03/2020
CREATE procedure [dbo].[ProcExcluirProspeccaoAtendimento]
 @idContaSistema as int,
 @idUsuarioContaSistemaExecutando int,
 @idProspeccao int,
 @motivo varchar(max),
 @excluirImportacoesVinculadas bit,
 @excluirAtendimentosVinculados bit,
 @excluirAtendimentoOnline bit,
 @logarExclusaoAtendimento bit
 as 
begin
	declare @dtNow datetime = dbo.GetDateCustom()
	declare @IdAtendimento as int
	declare @IdPessoaProspect as int
	declare @IdUsuarioContaSistemaAtendimento as int
	declare @PessoaProspectImportacaoId as int
	declare @strAtendimentosId varchar(max) 
	declare @strNomeProspccao varchar(max) 

	if @excluirImportacoesVinculadas = 1
		begin
			DECLARE PessoaProspectImportacaoCursorX CURSOR FOR
			(
				Select 
					distinct 
						PessoaProspectImportacao.id
				From
					Prospeccao  with (nolock)
						inner join
					ProspeccaoPessoaProspectOrigem  with (nolock) on ProspeccaoPessoaProspectOrigem.IdProspeccao = Prospeccao.Id
						inner join
					PessoaProspectOrigem  with (nolock) on PessoaProspectOrigem.Id = ProspeccaoPessoaProspectOrigem.IdPessoaProspectOrigem
						inner join
					PessoaProspectImportacao  with (nolock) on PessoaProspectImportacao.Id = PessoaProspectOrigem.IdPessoaProspectImportacao
				where
					Prospeccao.id = @idProspeccao
						and
					Prospeccao.IdContaSistema = @idContaSistema
						and
					PessoaProspectImportacao.idContaSistema = @idContaSistema
			)

			-- abre o cursor e aloca o próximo
			open PessoaProspectImportacaoCursorX fetch next from PessoaProspectImportacaoCursorX into @PessoaProspectImportacaoId

			-- faz o loop nas conta sistema
			while(@@FETCH_STATUS = 0 )
				BEGIN
					BEGIN TRANSACTION
						exec ProcExcluirPessoaProspectImportacao @idContaSistema, @idUsuarioContaSistemaExecutando, @PessoaProspectImportacaoId, @motivo
					commit

					fetch next from PessoaProspectImportacaoCursorX into @PessoaProspectImportacaoId
				end

			close PessoaProspectImportacaoCursorX
			deallocate PessoaProspectImportacaoCursorX

		end


	if @excluirAtendimentosVinculados = 1
		begin
			if @excluirAtendimentoOnline = 1
				begin
					DECLARE AtendimentoCursorX CURSOR FOR
					(
						select
							Atendimento.Id as IdAtendimento,
							Atendimento.IdPessoaProspect,
							Atendimento.IdUsuarioContaSistemaAtendimento
						from 
							Prospeccao  with (nolock)
								inner join
							Atendimento  with (nolock) on Atendimento.IdProspeccao = Prospeccao.Id
						where
							Prospeccao.id = @idProspeccao
								and
							Prospeccao.IdContaSistema = @idContaSistema
					)

					-- abre o cursor e aloca o próximo
					open AtendimentoCursorX fetch next from AtendimentoCursorX into @IdAtendimento, @IdPessoaProspect, @IdUsuarioContaSistemaAtendimento

					-- faz o loop nas conta sistema
					while(@@FETCH_STATUS = 0 )
						BEGIN
							exec ProcExcluirAtendimento @idContaSistema, @idUsuarioContaSistemaExecutando, @idAtendimento, @motivo, 1, 1, 1, @logarExclusaoAtendimento

							fetch next from AtendimentoCursorX into  @IdAtendimento, @IdPessoaProspect, @IdUsuarioContaSistemaAtendimento
						end

					close AtendimentoCursorX
					deallocate AtendimentoCursorX
				end
			else
				begin
					begin tran
						select
							@strAtendimentosId = STRING_AGG(CAST(Atendimento.Id AS VARCHAR(MAX)), ',')
						from 
							Prospeccao with (nolock)
								inner join
							Atendimento with (nolock) on Atendimento.IdProspeccao = Prospeccao.Id
						where
							Prospeccao.id = @idProspeccao
								and
							Prospeccao.IdContaSistema = @idContaSistema

						exec ProcExcluirAtendimentoPreparacao @idContaSistema, @idUsuarioContaSistemaExecutando, @motivo, @strAtendimentosId
					commit

					begin tran
						-- Se faz necessário para que a prospecção possa ser excluída abaixo sem referência
						-- necesse acaso como os atendimentos já foram marcados para exclusão acima, não irá ter problemas de refrência
						update Atendimento set IdProspeccao = null 
						from
							Atendimento
								inner join
							dbo.SplitIDs(@strAtendimentosId) TableAux on TableAux.OrderID = Atendimento.Id
					commit

				end

		end

	begin tran
		set @strNomeProspccao = (Select Prospeccao.Nome from Prospeccao where IdContaSistema = @idContaSistema and id = @idProspeccao)

		delete from Prospeccao where IdContaSistema = @idContaSistema and id = @idProspeccao

		INSERT INTO [dbo].[LogAcoes]
				   (
				   IdGuid
				   ,[IdContaSistema]
				   ,[IdUsuarioContaSistemaExecutou]
				   ,[Tipo]
				   ,[TipoSub]
				   ,[Texto]
				   ,[ValueOld]
				   ,[ValueNew]
				   ,[NomeMethod]
				   ,[DtInclusao]
				   ,[TabelaBD]
				   ,[TabelaBDChave]
				   ,[EnviarEmailAdministradorAnapro]
				   ,[IdUsuarioContaSistemaImpactou])
			 VALUES (
					NEWID(),
				   @IdContaSistema,
				   @idUsuarioContaSistemaExecutando,
				   'ProspeccaoProspect',
				   'ProspeccaoProspect_Excluido',
				   'Prospecção id: '+ CONVERT(varchar(15), @idProspeccao) +', nome: ' + @strNomeProspccao +' excluída. Motivo: '+ @motivo,
				   CONVERT(varchar(15), @idProspeccao),
				   null,
				   'ProcExcluirProspeccaoAtendimento',
				   @dtnow,
				   'Prospeccao',
				   CONVERT(varchar(15), @idProspeccao),
				   0,
				   null)
	commit

end;

CREATE procedure [dbo].[ProcExcluirRespostaFichaPesquisa]
 @IdFichaPesquisa as int, @idPergunta as int, @IdAtendimento as int, @fichaPesquisaTipo as varchar(50)
 
 as 
		delete 
				RespostaFichaPesquisa 
		where 
				IdFichaPesquisa = @IdFichaPesquisa and
				IdPergunta = @idPergunta and
				IdAtendimento = @IdAtendimento and
				FichaPesquisaTipo = @fichaPesquisaTipo;

CREATE procedure [dbo].[ProcExpurgoCanalList]
(
	@somenteChat as bit
)
as

declare @dtNowFull as datetime = dbo.GetDateCustom()
declare @dtNow as date = CONVERT(date, @dtNowFull)
declare @timeNow as time = CONVERT(VARCHAR(8), @dtNowFull, 108)
declare @dayOfWeek as smallint = DATEPART(dw, @dtNowFull) - 1


DECLARE @TableAlteracoesAux TABLE
(
	RowNumber int,
	IdContaSistema int,
	IdCanalExpurgo int,
	IdCampanhaCanal int,
	IdPlantaoHorario int,
	IdUsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal int,
	IdUsuarioContaSistema int,
	AcaoCanalExpurgo varchar(40),
	TimeExpurgo time,
	CanalNome varchar(100),
	CampanhaNome varchar(100)
);	

insert into @TableAlteracoesAux	
Select 
	row_number() over (PARTITION BY TabAux.IdContaSistema, TabAux.IdCanalExpurgo, TabAux.IdCampanhaCanal, TabAux.IdPlantaoHorario order by TabAux.IdContaSistema, TabAux.IdCanalExpurgo, TabAux.IdCampanhaCanal, TabAux.IdPlantaoHorario, newid() desc, newid() asc) as RowNumber,
	TabAux.IdContaSistema,
	TabAux.IdCanalExpurgo,
	TabAux.IdCampanhaCanal,
	TabAux.IdPlantaoHorario,
	TabAux.IdUsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal,
	TabAux.IdUsuarioContaSistema,
	TabAux.AcaoCanalExpurgo,
	TabAux.TimeExpurgo,
	TabAux.CanalNome,
	TabAux.CampanhaNome
From
	(
		Select 
			distinct
				ContaSistema.Id as IdContaSistema,
				CanalExpurgo.Id as IdCanalExpurgo,
				CampanhaCanal.Id as IdCampanhaCanal,
				PlantaoHorario.Id as IdPlantaoHorario,
				UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal.id as IdUsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal,
				UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal.IdUsuarioContaSistema,
				CanalExpurgo.Acao as AcaoCanalExpurgo,
				CanalExpurgo.TimeExpurgo,
				Canal.Nome as CanalNome,
				Campanha.Nome as CampanhaNome
		From
			CanalExpurgo with (nolock)
				inner join
			Canal with (nolock) on Canal.Id = CanalExpurgo.IdCanal
				inner join
			ContaSistema  with (nolock) on ContaSistema.Id = Canal.IdContaSistema
				inner join
			CampanhaCanal with (nolock) on CampanhaCanal.IdCanal = CanalExpurgo.IdCanal
				inner join
			Campanha with (nolock) on Campanha.Id = CampanhaCanal.IdCampanha
				inner join
			Plantao with (nolock) on Plantao.IdCampanha = Campanha.Id 
				inner join
			PlantaoHorario with (nolock) on PlantaoHorario.IdPlantao = Plantao.Id
				inner join
			UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal with (nolock) on UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal.IdPlantaoHorario = PlantaoHorario.Id and UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal.IdCampanhaCanal = CampanhaCanal.Id

		where
			(
				(@somenteChat = 1 and Canal.Tipo = 'CHAT')
					or
				(@somenteChat = 0 and Canal.Tipo <> 'CHAT')
			)
				and
			(
				@dtNowFull >= Plantao.DtInicioValidade 
					and 
				(
					Plantao.DtFimValidade is null
						or
					Plantao.DtFimValidade >= @dtNowFull
				)
			)
				and
			(
				@dtNowFull >= PlantaoHorario.DtInicio 
					and 
				PlantaoHorario.DtFim >= @dtNowFull
			)
				and
			ContaSistema.Status = 'AT' 
				and
			Canal.Status = 'AT' 
				and
			Campanha.Status = 'AT'
				and
			Canal.Tipo <> 'ATIVO' and
			(
				CanalExpurgo.DtValidade is null
					or
				CanalExpurgo.DtValidade >= @dtNow
			)
				and
			CanalExpurgo.DiaSemanaExpurgo = @dayOfWeek
				and
			CanalExpurgo.TimeExpurgo <= @timeNow 
				and 
			--DateAdd(MI, 100, CanalExpurgo.TimeExpurgo) >= @timeNow
			DATEADD(DAY,DATEDIFF(DAY, 0, @dtNow),CAST(DateAdd(MI, 100, CanalExpurgo.TimeExpurgo)AS DATETIME)) >= @dtNowFull
				and
			(
				CanalExpurgo.DtUltimoExpurgoExecutado is null
					or
				CanalExpurgo.DtUltimoExpurgoExecutado < @dtNow
			)
	) TabAux

	OPTION (RECOMPILE)




-- Só deverá ser executado caso o canal seja diferente de chat
if @somenteChat = 0 
	begin
		-- Embaralha a fila
		Update UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal set Prioridade = TabAux.RowNumber
		From
			UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal
				inner join
			@TableAlteracoesAux TabAux on TabAux.IdUsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal = UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal.Id
		where
			TabAux.AcaoCanalExpurgo = 'EMBARALHAR'

		-- Expurga os usuários da fila excluindo os mesmos do canal
		DELETE UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal 
		From
			UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal
				inner join
			@TableAlteracoesAux TabAux on TabAux.IdUsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal = UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal.Id
		where
			TabAux.AcaoCanalExpurgo = 'EXPURGAR'
	end

-- Seta em canal expurgo a execução realizada
Update CanalExpurgo set DtUltimoExpurgoExecutadoFull = dbo.GetDateCustom(), DtUltimoExpurgoExecutado = CONVERT(date, dbo.GetDateCustom())
where
	exists (Select TabAux.IdCanalExpurgo from @TableAlteracoesAux TabAux where TabAux.IdCanalExpurgo = CanalExpurgo.Id)


-- Retorna oexpurgo realizado para que quando sendo chat possa executar no SERVIDOR
Select * from @TableAlteracoesAux;

CREATE procedure [dbo].[ProcFichaPesquisaExistePerguntaObrigatoriaNaoRespondida]
	@idFichaPesquisa as int,
	@idAtendimento as int,
	@FichaPesquisaTipo as varchar(50)
 as 
begin

Select COUNT(id)
From
	Pergunta WITH (NOLOCK)
Where
	Pergunta.Status = 'AT' and 
	Pergunta.IdFichaPesquisa = @idFichaPesquisa and
	Pergunta.Obrigatorio = 1 and
	Pergunta.Tipo = @FichaPesquisaTipo and
	not Exists (
				Select 
					id
				from
					RespostaFichaPesquisa WITH (NOLOCK)
					
				where
					RespostaFichaPesquisa.idFichaPesquisa = @idFichaPesquisa and
					RespostaFichaPesquisa.FichaPesquisaTipo = @FichaPesquisaTipo and
					RespostaFichaPesquisa.idAtendimento = @idAtendimento and
					RespostaFichaPesquisa.idPergunta = Pergunta.Id
			)
end;

CREATE procedure [dbo].[ProcGatilhoGerarEventoAtendimentoSemProximoPasso]
as
	declare @intervalosSegundosRepeticaoExecucao int = 10
	declare @ObjSerializadoTipo varchar(100) = 'CSHARP'
	declare @ObjTipo varchar(1000) = 'SuperCRM.DTO.Evento.EventoAtendimentoSemProximoPassoDTO'
	declare @EventoTipo varchar(300) = 'EVENTO_ATENDIMENTO_SEM_PROXIMO_PASSO'
	declare @DateNow datetime = dbo.GetDateCustom()
	declare @DateValidade datetime = DATEADD(DAY, 3, @DateNow) 
	declare @DtAtendimentoAtendidoConsiderar datetime = DATEADD(MINUTE, -60, @DateNow) 
	declare @DtUltimaInteracaoUsuario datetime = DATEADD(DAY, -2, @DateNow) 
	declare @DtAlarmeConsiderar datetime = DATEADD(HOUR, 12, @DateNow) 
	declare @TableAux TABLE
	(
		StrGuid char(36),
		ContaSistemaId int,
		AtendimentoId int,
		CampanhaId int,
		GatilhoId int,
		GatilhoFiltroHashSHA1 char(40),
		AcaoId int,
		GatilhoAcaoFiltroHashSHA1 char(40),
		EventoTipo varchar(300),
		StrXml varchar(max)
	);

	return

	---- Insere na tabela auxiliar
	---- Todos os atendimentos com atendimento criado a mais dq o tempo definido sem ter um próximo passo
	--Insert into @TableAux
	--Select 
		
	--	top 100

	--	TabAux.StrGuid as StrGuid,
	--	TabAux.IdContaSistema as ContaSistemaId,
	--	Atendimento.id as AtendimentoId,
	--	TabAux.IdCampanha as CampanhaId,
	--	TabAux.GatilhoId,
	--	TabAux.GatilhoFiltroHashSHA1,
	--	TabAux.AcaoId,
	--	TabAux.GatilhoAcaoFiltroHashSHA1,
	--	@EventoTipo as EventoTipo,
	--	(
	--		SELECT
	--			TabAux.StrGuid as StrGatilhoExecucaoGuid,
	--			Atendimento.idContaSistema as IdContaSistema, 
	--			AtendimentoAux.ID as IdAtendimento,
	--			TabAux.GatilhoId as IdGatilho,
	--			TabAux.GatilhoFiltroHashSHA1 as GatilhoFiltroHashSHA1,
	--			TabAux.GatilhoAcaoFiltroHashSHA1 as GatilhoAcaoFiltroHashSHA1,
	--			@DateValidade as DtValidade,
	--			@DateNow as DtEvento
			
	--		FROM 
	--			Atendimento AtendimentoAux  with (nolock)
				
	--		where
	--			AtendimentoAux.Id = Atendimento.Id
	--		-- Caso o elemento seja nulo será mostrado mesmo assim
	--		FOR xml RAW('EventoAtendimentoSemProximoPassoDTO'),  ELEMENTS XSINIL 
	--	) as ObjSerializado

	--From
	--	Atendimento with (nolock)
	--		inner join
	--	(
	--		-- Seleciona os gatilhos do tipo
	--		Select
	--			NEWID() as StrGuid,
	--			Gatilho.IdContaSistema,
	--			Gatilho.IdCampanha,
	--			Gatilho.Id as GatilhoId,
	--			Gatilho.GatilhoFiltroHashSHA1 as GatilhoFiltroHashSHA1,
	--			Acao.Id as AcaoId,
	--			GatilhoAcao.GatilhoAcaoFiltroHashSHA1 as GatilhoAcaoFiltroHashSHA1
	--		From 
	--			Gatilho WITH (NOLOCK)
	--				inner join
	--			EventoTipo   WITH (NOLOCK) on EventoTipo.Tipo = Gatilho.EventoTipo
	--				inner join
	--			GatilhoAcao WITH (NOLOCK) on GatilhoAcao.IdGatilho = Gatilho.id
	--				inner join
	--			Acao WITH (NOLOCK) on Acao.id = GatilhoAcao.idAcao
	--				inner join
	--			ContaSistema  WITH (NOLOCK) on ContaSistema.Id = Gatilho.IdContaSistema
	--		Where
	--			Gatilho.EventoTipo = @EventoTipo
	--				and
	--			Gatilho.Status = 'AT'
	--				and
	--			(Gatilho.DtUltimaExecucao is null or Gatilho.DtUltimaExecucao < DATEADD(SECOND, -@intervalosSegundosRepeticaoExecucao, @DateNow))
	--				and
	--			EventoTipo.Status = 'AT'
	--				and
	--			ContaSistema.Status = 'AT'
	--				and
	--			Acao.Status = 'AT'
	--	) TabAux on Atendimento.idCampanha = TabAux.IdCampanha
	--		left outer join
	--	Interacao InteracaoUltimaUsuario with (nolock) on InteracaoUltimaUsuario.id = Atendimento.idInteracaoUsuarioUltima

	--where
	--	-- Verifica se já existe um Gatilho em execução para esse atendimento
	--	-- Com a ação em questão 
	--	not exists 
	--	(
	--		Select 
	--			GatilhoExecucao.idGatilho 
	--		from
	--			GatilhoExecucao with (nolock)
	--		where
	--			GatilhoExecucao.idGatilho = TabAux.GatilhoId 
	--				and
	--			GatilhoExecucao.idAcao = TabAux.AcaoId 
	--				and
	--			GatilhoExecucao.Status = 'AT' 
	--				and
	--			GatilhoExecucao.CodigoIdentificadorInt = Atendimento.Id 
	--				and 
	--			-- Deve comparar com nulo pois caso seja nulo as colunas n podem ser comparadas pois sempre retornará true
	--			(GatilhoExecucao.GatilhoFiltroHashSHA1 is null or GatilhoExecucao.GatilhoFiltroHashSHA1 = TabAux.GatilhoFiltroHashSHA1)
	--				and 
	--			-- Deve comparar com nulo pois caso seja nulo as colunas n podem ser comparadas pois sempre retornará true
	--			(GatilhoExecucao.GatilhoAcaoFiltroHashSHA1 is null or GatilhoExecucao.GatilhoAcaoFiltroHashSHA1 = TabAux.GatilhoAcaoFiltroHashSHA1)
	--	)
	--		and
	--	Atendimento.StatusAtendimento = 'ATENDIDO' 
	--		and
	--	Atendimento.DtInicioAtendimento < @DtAtendimentoAtendidoConsiderar
	--		and
	--	-- Verifica se a data da ultima interação do usuário faz mais dq o tempo limite
	--	(InteracaoUltimaUsuario.id is null or InteracaoUltimaUsuario.DtInclusao < @DtUltimaInteracaoUsuario)
	--		and
	--	-- Verifica se existe alarmes ativo para o atendimento
	--	-- Ou que não está completo a mais de um determinado tempo
	--	not exists (
	--					Select AtendimentoLog.IdAlarme 
	--					from 
	--						AtendimentoLog with (nolock)
	--							inner join 
	--						Alarme with (nolock) on AtendimentoLog.IdAlarme = Alarme.Id and AtendimentoLog.IdAtendimento = Atendimento.Id
	--					where
	--						Alarme.Status = 'IN'
	--							or
	--						(Alarme.Status = 'FI' and Alarme.DataUltimoStatus > @DtAlarmeConsiderar)
	--				) 



	--	-- Insere na tabela GatilhoExecução todos os alertas criados para 
	--	-- que os mesmos não sejam executados novamente enquanto não forem sanados
	--	Insert into GatilhoExecucao
	--	(
	--		StrGuid,
	--		IdGatilho,
	--		IdAcao,
	--		GatilhoFiltroHashSHA1,
	--		GatilhoAcaoFiltroHashSHA1,
	--		Status,
	--		CodigoIdentificadorInt,
	--		CodigoIdentificadorStr,
	--		DtInclusao,
	--		DtAlteracao,
	--		DtValidade
	--	)
	--	Select
	--		TableEventos.StrGuid,
	--		TableEventos.GatilhoId,
	--		TableEventos.AcaoId,
	--		TableEventos.GatilhoFiltroHashSHA1,
	--		TableEventos.GatilhoAcaoFiltroHashSHA1,
	--		'AT',
	--		TableEventos.AtendimentoId,
	--		NULL,
	--		@DateNow,
	--		NULL,
	--		@DateValidade
	--	From
	--		@TableAux TableEventos

	--	-- Insere os eventos
	--	Insert into Evento
	--	(
	--		IdContaSistema,
	--		IdCampanha,
	--		IdUsuarioContaSistema,
	--		Tipo,
	--		DtInclusao,
	--		ObjSerializadoTipo,
	--		ObjSerializado,
	--		ObjTipo,
	--		Observar,
	--		Processado,
	--		Status,
	--		AutoExecutavel
	--	)
	--	Select
	--		Distinct
	--		TableEventos.ContaSistemaId,
	--		TableEventos.CampanhaId,
	--		Null,
	--		TableEventos.EventoTipo,
	--		@DateNow,
	--		@ObjSerializadoTipo,
	--		TableEventos.StrXml,
	--		@ObjTipo,
	--		1,
	--		0,
	--		'INCLUIDO',
	--		0
	--	From
	--		@TableAux TableEventos

	--	-- Seta a data da ultima Execução do Gatilho
	--	Update Gatilho set Gatilho.DtUltimaExecucao = @DateNow
	--	where exists (Select distinct TableEventos.GatilhoId from @TableAux TableEventos where Gatilho.Id = TableEventos.GatilhoId);

CREATE procedure [dbo].[ProcGerarGrupoHierarquia] @idsContaSistema varchar(max)
as 
begin
	declare @TableIdContaSistema TABLE ( id int )
	declare @dateNow datetime = dbo.getdateCustom()

	set @idsContaSistema = dbo.RetNullOrVarChar(@idsContaSistema) 

	insert @TableIdContaSistema (id)
	Select 
		OrderID 
	from 
		SplitIDs(@idsContaSistema) as TabSplit


	-- adiciona todos os grupos que não tem pai como o pai sendo o grupo padrão
	insert
	into	GrupoSuperior (IdGrupo, IdGrupoSuperior, DtInicio, DtFim, StatusRegistroBach )
	select	Grupo.Id,
			(
				select	id
				from	Grupo GrupoTemp WITH (NOLOCK)
				where	Grupo.IdContaSistema = GrupoTemp.idContaSistema and
						Padrao = 1
			),
			@datenow,
			@datenow,
			'AT'
	from	Grupo WITH (NOLOCK)
	where	Grupo.IdContaSistema not in (select TabTempIds.id from @TableIdContaSistema as TabTempIds) and
			Grupo.Padrao <> 1 and
			not exists  (	
							select	GrupoSuperior.Id
							from	GrupoSuperior WITH (NOLOCK)
							where	IdGrupo = Grupo.Id
						)


	;with	grupoSuperiorTable(idContaSistema, idGrupoSuperior, idGrupo, Nivel)  
	 as (	select	Grupo.IdContaSistema as idContaSistema,
					Grupo.Id as idGrupoSuperior,
					Grupo.Id as idGrupo,
					0 as Nivel
			from	Grupo WITH (NOLOCK)
			where	(
						@idsContaSistema is null or
						Grupo.IdContaSistema in
						(
							select	TabTemp.id
							from	@TableIdContaSistema as TabTemp
						)
					)

			union all
		
			select	Grupo.IdContaSistema as idContaSistema,
					grupoSuperiorTable.idGrupoSuperior,
					Grupo.Id as idGrupo,
					Nivel + 1
			from	Grupo WITH (NOLOCK)
						inner join GrupoSuperior WITH (NOLOCK) on
							GrupoSuperior.IdGrupo = Grupo.Id
						inner join grupoSuperiorTable on
							GrupoSuperior.IdGrupoSuperior = grupoSuperiorTable.idGrupo
			where	GrupoSuperior.DtFim is null and
					(
						@idsContaSistema is null or 
						Grupo.IdContaSistema in 
						(
							select TabTemp.id
							from @TableIdContaSistema as TabTemp
						)
					)
		)
	    select	grupoSuperiorTable.idContaSistema,
				grupoSuperiorTable.idGrupoSuperior,
				grupoSuperiorTable.idGrupo as idGrupoInferior,
				ROW_NUMBER() OVER(PARTITION BY grupoSuperiorTable.idGrupo ORDER BY grupoSuperiorTable.Nivel DESC) as Nivel
		into	#TableTemp
		from	grupoSuperiorTable
		where	grupoSuperiorTable.idGrupoSuperior <> grupoSuperiorTable.idGrupo


	;with cteGrupoHierarquia AS
			(
				SELECT	GrupoHierarquia.*
				FROM	GrupoHierarquia WITH (NOLOCK)
				WHERE	@idsContaSistema is null or
						GrupoHierarquia.idContaSistema in
						(
							select	TabTemp.id
							from	@TableIdContaSistema as TabTemp
						) 
			)
	MERGE cteGrupoHierarquia AS TARGET  
	USING (Select TableTemp.* from #TableTemp TableTemp) as SOURCE (idContaSistema, idGrupoSuperior, idGrupoInferior, Nivel)  
		ON (TARGET.IdGrupoSuperior = SOURCE.IdGrupoSuperior and TARGET.IdGrupoInferior = SOURCE.IdGrupoInferior) 
			WHEN MATCHED AND TARGET.Nivel <> SOURCE.Nivel THEN
				UPDATE SET TARGET.Nivel = SOURCE.Nivel
			WHEN NOT MATCHED BY TARGET THEN
				INSERT (IdContaSistema, IdGrupoSuperior, IdGrupoInferior, Nivel) VALUES (SOURCE.IdContaSistema, SOURCE.IdGrupoSuperior, SOURCE.IdGrupoInferior, SOURCE.Nivel)
			WHEN NOT MATCHED BY SOURCE THEN
				delete;



	;with	cteGrupoAux AS 
			(
				SELECT	GrupoAux.*
				FROM	GrupoAux WITH (NOLOCK)
				WHERE	exists
							(
								Select	*
								from	#TableTemp as TabTemp
								where	TabTemp.idGrupoInferior = GrupoAux.Id or 
										TabTemp.idGrupoSuperior = GrupoAux.Id
							)
			)
	MERGE cteGrupoAux AS TARGET  
	USING	(
				Select
					TabAux.GrupoId,
					TabAux.GrupoHierarquiaTipo,
					TabAux.GrupoHierarquia
				From
					(
						Select 
							Grupo.Id as GrupoId,
							dbo.GetGrupoHierarquiaList(grupo.id) as GrupoHierarquia,
							dbo.GetGrupoHierarquiaTipoList(grupo.id) as GrupoHierarquiaTipo
						From
							Grupo with (nolock)
						where
							exists
								(
									Select	* 
									from	#TableTemp as TabTemp
									where	TabTemp.idGrupoInferior = Grupo.Id or
											TabTemp.idGrupoSuperior = Grupo.Id
								)
					) as TabAux
			) as SOURCE (GrupoId, GrupoHierarquiaTipo, GrupoHierarquia)  
		ON (TARGET.id = SOURCE.GrupoId) 
			WHEN MATCHED AND TARGET.GrupoHierarquia <> SOURCE.GrupoHierarquia or TARGET.GrupoHierarquiaTipo <> SOURCE.GrupoHierarquiaTipo THEN
				UPDATE SET TARGET.GrupoHierarquia = SOURCE.GrupoHierarquia, TARGET.GrupoHierarquiaTipo = SOURCE.GrupoHierarquiaTipo, TARGET.NivelGeral = len(SOURCE.GrupoHierarquia) - len(replace(SOURCE.GrupoHierarquia,',',''))
			WHEN NOT MATCHED BY TARGET THEN
				INSERT (id, GrupoHierarquia, GrupoHierarquiaTipo, NivelGeral) VALUES (SOURCE.GrupoId, SOURCE.GrupoHierarquia, SOURCE.GrupoHierarquiaTipo, len(SOURCE.GrupoHierarquia) - len(replace(SOURCE.GrupoHierarquia,',','')))
			WHEN NOT MATCHED BY SOURCE THEN
				delete;
end;

CREATE procedure [dbo].[ProcGerarGrupoHierarquiaBatch] @gerarTudo bit
as 
begin
	declare @dateNow datetime = dbo.getdateCustom()
	declare @strIdsContaSistema varchar(max)
	declare @strIdsUsuarioContaSistema varchar(max)

	declare @TableGrupoTemp table (idContaSistema int)

	declare @objJson varchar(max) = (select top 1 TabelaoLog.Obj from TabelaoLog WITH (NOLOCK) where nome = 'Batch_Grupo')

	declare @GrupoVersaoUltima timestamp = convert(timestamp, sys.fn_cdc_hexstrtobin(JSON_VALUE(@objJson, '$.GrupoVersaoUltima')))
	declare @GrupoSuperiorVersaoUltima timestamp = convert(timestamp, sys.fn_cdc_hexstrtobin(JSON_VALUE(@objJson, '$.GrupoSuperiorVersaoUltima')))
	declare @UsuarioContaSistemaGrupoAdmVersaoUltima timestamp = convert(timestamp, sys.fn_cdc_hexstrtobin(JSON_VALUE(@objJson, '$.UsuarioContaSistemaGrupoAdmVersaoUltima')))
	declare @UsuarioContaSistemaGrupoVersaoUltima timestamp = convert(timestamp, sys.fn_cdc_hexstrtobin(JSON_VALUE(@objJson, '$.UsuarioContaSistemaGrupoVersaoUltima')))

	select Grupo.IdContaSistema, Grupo.versao into #tempGrupo from Grupo WITH (NOLOCK) where Grupo.versao > @GrupoVersaoUltima or @gerarTudo = 1

	select	Grupo.idContaSistema, GrupoSuperior.versao
	into	#tempGrupoSuperior
	from	GrupoSuperior WITH (NOLOCK)
				inner join Grupo WITH (NOLOCK) on
					Grupo.Id = GrupoSuperior.IdGrupo
	where	GrupoSuperior.versao > @GrupoSuperiorVersaoUltima or 
			@gerarTudo = 1
	
	select	Grupo.IdContaSistema, UsuarioContaSistemaGrupoAdm.IdUsuarioContaSistema, UsuarioContaSistemaGrupoAdm.versao
	into	#tempUsuarioContaSistemaGrupoAdm
	from	UsuarioContaSistemaGrupoAdm WITH (NOLOCK) 
				inner join Grupo WITH (NOLOCK) on
					Grupo.Id = UsuarioContaSistemaGrupoAdm.IdGrupo
	where	UsuarioContaSistemaGrupoAdm.versao > @UsuarioContaSistemaGrupoAdmVersaoUltima or
			@gerarTudo = 1


	-- Seleciona todas as contas que tiveram ao menos uma alteração em grupo ou grupo superior
	Select @strIdsContaSistema = STRING_AGG(cast(TabTemp.IdContaSistema as varchar(max)),',')
	from
		(
			Select 
				distinct TabTemp.IdContaSistema
			from
			(
				select TabTemp.IdContaSistema from #tempGrupo TabTemp
				union
				select TabTemp.IdContaSistema from #tempGrupoSuperior TabTemp
			) as TabTemp
		) as TabTemp

	-- Seleciona todas os usuários que sofreram alteração na hierarquia de grupo através de ser ou não administrador
	-- se faz necessário não selecionar os usuários que a contasistema tiveram alteração no grupo
	-- ja que nesse caso a hierarquia da conta inteira é refeita acima não havendo motivação para gerar a recriação da hierarquia do usuário pois já foi refeita na conta inteira
	-- incluindo tais usuários
	Select @strIdsUsuarioContaSistema = STRING_AGG(cast(TabTemp.IdUsuarioContaSistema as varchar(max)),',')
	from
		(
			Select 
				distinct TabTemp.IdUsuarioContaSistema
			from
				#tempUsuarioContaSistemaGrupoAdm as TabTemp
			where 
				TabTemp.IdContaSistema not in (select TabTempIds.IdContaSistema from #tempGrupo as TabTempIds)
					and
				TabTemp.IdContaSistema not in (select TabTempIds.IdContaSistema from #tempGrupoSuperior as TabTempIds)
		) as TabTemp


	set @GrupoVersaoUltima = isnull((select max(TempTable.versao) from #tempGrupo as TempTable), @GrupoVersaoUltima)
	set @GrupoSuperiorVersaoUltima = isnull((select max(TempTable.versao) from #tempGrupoSuperior as TempTable), @GrupoSuperiorVersaoUltima)
	set @UsuarioContaSistemaGrupoAdmVersaoUltima  = isnull((select max(TempTable.versao) from #tempUsuarioContaSistemaGrupoAdm as TempTable), @UsuarioContaSistemaGrupoAdmVersaoUltima)
	set @UsuarioContaSistemaGrupoVersaoUltima  = @UsuarioContaSistemaGrupoVersaoUltima

	if @gerarTudo = 1
		begin 
			delete from GrupoHierarquia
			delete from GrupoHierarquiaUsuarioContaSistema
		end


	if dbo.RetNullOrVarChar(@strIdsContaSistema) is not null
		begin
			exec [ProcGerarGrupoHierarquia] @strIdsContaSistema  
		end

	if dbo.RetNullOrVarChar(@strIdsUsuarioContaSistema) is not null or dbo.RetNullOrVarChar(@strIdsContaSistema) is not null
		begin
			exec [ProcGerarGrupoHierarquiaUsuarioContaSistema] @strIdsContaSistema, @strIdsUsuarioContaSistema  
		end

	-- sys.fn_varbintohexstr() & sys.fn_cdc_hexstrtobin()
	SET @objJson = JSON_MODIFY(JSON_MODIFY(JSON_MODIFY(JSON_MODIFY(@objJson,'$.GrupoVersaoUltima', sys.fn_varbintohexstr(@GrupoVersaoUltima)), '$.GrupoSuperiorVersaoUltima', sys.fn_varbintohexstr(@GrupoSuperiorVersaoUltima)), '$.UsuarioContaSistemaGrupoAdmVersaoUltima', sys.fn_varbintohexstr(@UsuarioContaSistemaGrupoAdmVersaoUltima)), '$.UsuarioContaSistemaGrupoVersaoUltima', sys.fn_varbintohexstr((@UsuarioContaSistemaGrupoVersaoUltima)))
	update TabelaoLog set  Data1 = (case when @gerarTudo = 1 then dbo.GetDateCustom() else TabelaoLog.Data1 end) ,TabelaoLog.DtUltimaCompleta = (case when @gerarTudo = 1 then dbo.GetDateCustom() else TabelaoLog.DtUltimaCompleta end), TabelaoLog.DtUltimaParcial = dbo.GetDateCustom(), TabelaoLog.Obj = @objJson where TabelaoLog.Nome in ( 'Batch_GerarGrupoHierarquiaBatch','Batch_Grupo')

end;

CREATE procedure [dbo].[ProcGerarGrupoHierarquiaUsuarioContaSistema] @idsContaSistema varchar(max), @idsUsuarioContaSistema varchar(max)
as 
begin

	declare @TableIdContaSistema TABLE (id int)
	declare @TableIdUsuarioContaSistema TABLE (id int)

	set @idsContaSistema = dbo.RetNullOrVarChar(@idsContaSistema) 
	set @idsUsuarioContaSistema = dbo.RetNullOrVarChar(@idsUsuarioContaSistema) 

	-- Insere na tabela temp de contasistema
	insert @TableIdContaSistema (id)
	Select 
		OrderID 
	from 
		SplitIDs(@idsContaSistema) as TabSplit

	-- Insere na tabela temp de usuariocontasistema
	insert @TableIdUsuarioContaSistema (id)
	Select 
		OrderID 
	from 
		SplitIDs(@idsUsuarioContaSistema) as TabSplit


	;WITH cteGrupoHierarquiaUsuarioContaSistema AS (
		SELECT 
			GrupoHierarquiaUsuarioContaSistema.*
		FROM
			GrupoHierarquiaUsuarioContaSistema WITH (NOLOCK)
		WHERE
			(@idsContaSistema is not null and GrupoHierarquiaUsuarioContaSistema.IdContaSistema in (select TabTemp.id from @TableIdContaSistema TabTemp)) or
			(@idsUsuarioContaSistema is not null and GrupoHierarquiaUsuarioContaSistema.IdUsuarioContaSistema in (select TabTemp.id from @TableIdUsuarioContaSistema TabTemp))
	)
	MERGE cteGrupoHierarquiaUsuarioContaSistema AS TARGET  
	USING (
			Select
				distinct 
					Grupo.IdContaSistema,
					UsuarioContaSistemaGrupoAdm.IdUsuarioContaSistema,			
					Grupo.Id as IdGrupo
			from
				UsuarioContaSistemaGrupoAdm WITH (NOLOCK)
					inner join GrupoHierarquia WITH (NOLOCK) ON
						GrupoHierarquia.IdGrupoSuperior = UsuarioContaSistemaGrupoAdm.IdGrupo OR
						GrupoHierarquia.IdGrupoInferior = UsuarioContaSistemaGrupoAdm.IdGrupo
					-- Seleciona todos os grupos inferiores ao grupo em questão, inclusive o proprio grupo superior
					inner join Grupo WITH (NOLOCK) on
						Grupo.Id = GrupoHierarquia.IdGrupoInferior
					inner join UsuarioContaSistema  WITH (NOLOCK) ON
						UsuarioContaSistema.Id = UsuarioContaSistemaGrupoAdm.IdUsuarioContaSistema
	
			where 
				(
					( @idsContaSistema is not null and Grupo.IdContaSistema in (select TabTemp.id from @TableIdContaSistema TabTemp)) or
					( @idsUsuarioContaSistema is not null and UsuarioContaSistemaGrupoAdm.IdUsuarioContaSistema in (select TabTemp.id from @TableIdUsuarioContaSistema TabTemp))
				) and 
					UsuarioContaSistema.Status = 'AT' and
					UsuarioContaSistemaGrupoAdm.DtFim is null
	) as SOURCE (IdContaSistema, IdUsuarioContaSistema, IdGrupo)  
		ON (TARGET.idContaSistema = SOURCE.idContaSistema and TARGET.idUsuarioContaSistema = SOURCE.idUsuarioContaSistema and TARGET.IdGrupo = SOURCE.IdGrupo) 
			WHEN NOT MATCHED BY TARGET THEN
				INSERT (IdContaSistema, idUsuarioContaSistema, IdGrupo) VALUES (SOURCE.IdContaSistema, SOURCE.idUsuarioContaSistema, SOURCE.IdGrupo)
			WHEN NOT MATCHED BY SOURCE THEN
				delete;


end;

CREATE procedure [dbo].[ProcGerarTabelao] 
(
	@DataReferencia datetime,
	@GerarTudo bit
)
as
	exec ProcGerarTabelaoV1 'parcial_completo'

	-- comentar
	return

	DECLARE @TableAlteracoes TABLE
	(
	  IdAtendimento int,
	  rownumber int
	);

	DECLARE @TableAlteracoesAux TABLE
	(
	  IdAtendimento int
	);

	declare @dtnow datetime = dbo.getDateCustom()
	declare @dtnowConsiderar datetime = dbo.GetDateCustomMinorDay()
	declare @iCount int = 0
	declare @iQtdPorTransaction int = 100000
	declare @isExecute bit = 1
	declare @dtReferenciaUtilizarMinimo as datetime
	declare @dtReferenciaUtilizarMaximo datetime = @dtnow
	declare @dtUltimaAtualizacao datetime
	declare @dtInicioGeral datetime = @dtnow
	declare @dtInicio datetime = @dtnow
	declare @dtInicioAux datetime

	declare @BatchNome varchar(1000) = 'Batch_TabelaoAtendimento'

	-- É necessário atualizar as datas = null para que caso estejam o sistema consiga comparar as datas
	update superentidade set DtAtualizacaoAuto = dbo.GetDateCustom() where DtAtualizacaoAuto is null 

	-- Retorna a data que começou a última atualização
	select @dtUltimaAtualizacao = Max(TabelaoLog.Data2) from TabelaoLog with (nolock) where TabelaoLog.Nome = @BatchNome group by TabelaoLog.Nome

	-- Se o processamento atual não for de gerar tudo e a data não for nula
	-- Subentende-se que no momento está sendo atualizado e não deve rodar 2 atualizações ao mesmo tempo
	-- testará tb se faz mais de 360 minutos que a ultima query executou nesse caso irá considerar que hove erro e executará 
	-- zerando a hora para não ter problemas
	if (@GerarTudo = 0 and @dtUltimaAtualizacao is not null and DATEDIFF(MI, @dtUltimaAtualizacao, dbo.GetDateCustom()) < 360)
		begin
			return
		end
	--else
	--	begin
	--		update TabelaoLog set TabelaoLog.Data2 = dbo.GetDateCustom(),  TabelaoLog.bit1 = @GerarTudo where TabelaoLog.Nome = @BatchNome
	--	end


	if @GerarTudo = 1
		begin
			-- Irá recuperar todos os registros atendimento que houve alteração
			-- Caso GerarTudo seja 1 irá gerar toda o tabelão
			insert into @TableAlteracoesAux
			Select 
				Atendimento.Id
			from 
				Atendimento  
					inner join
				ContaSistema with (nolock) on ContaSistema.id = Atendimento.idContaSistema
			where 
				ContaSistema.Status = 'AT'
					and
				Atendimento.RegistroStatus is null
		end
	else
		begin

			-- optei a fazer assim para não usar contasistema.status já que deixa muito lento
			-- ja que quando a base está inativada parará de atualizar naturalmente
			insert into @TableAlteracoesAux
			Select top 5000
					SuperEntidade.Id 
				from 
					SuperEntidade 
						inner join
					ContaSistema with (nolock) on ContaSistema.Id = SuperEntidade.idContaSistema

				where
					ContaSistema.Status = 'AT' and
					--SuperEntidade.DtAtualizacaoAuto >= @dtnowConsiderar and
					SuperEntidade.SuperEntidadeTipo = 'ATENDIMENTO'
						and
					not exists	(
									Select 
										TabelaoAtendimento.AtendimentoId
									from
										TabelaoAtendimento with (nolock)
									where
										TabelaoAtendimento.AtendimentoId = SuperEntidade.Id and 
										TabelaoAtendimento.DtAtualizacaoAuto = SuperEntidade.DtAtualizacaoAuto
								)


		end

	-- Insere na @TableAlteracoes os ids dos dos atendimentos com ROW_NUMBER() para facilitar os inserts em lote
	insert into @TableAlteracoes
	Select TabAux2.IdAtendimento, ROW_NUMBER() OVER(ORDER BY TabAux2.IdAtendimento ASC) AS RowNumber
	From
		(
			Select
				distinct TabAux.IdAtendimento 
			From
				@TableAlteracoesAux TabAux
		) TabAux2

	print 'END - select e insert dos ids - ' + convert(varchar(200) ,CAST((dbo.GetDateCustom() - @dtInicio) as time(0)))
	set @dtInicio = dbo.GetDateCustom()

	-- Caso não exista registro irá retornar para evitar processamento
	if isnull((select top 1 Tab1.IdAtendimento from @TableAlteracoes Tab1),0) = 0
		begin 
			set @isExecute = 0
		end

	if (@isExecute = 1)
		begin	

			-- insere os registros em uma tabela temporária
			Select
				temp.rownumber,

				@dtReferenciaUtilizarMaximo as DtInclusao,
				AtendimentoResumoView.ContasistemaId,
				AtendimentoResumoView.ContasistemaIdGuid,
					
				AtendimentoResumoView.Atendimentoid,
				CONVERT(binary(8), AtendimentoResumoView.AtendimentoVersao) as AtendimentoVersao,
				AtendimentoResumoView.AtendimentoidGuid,
				AtendimentoResumoView.AtendimentoDtInclusao,
				AtendimentoResumoView.AtendimentoDtInicio,
				AtendimentoResumoView.AtendimentoDtConclusao,
				AtendimentoResumoView.AtendimentoStatus,
				AtendimentoResumoView.AtendimentoNegociacaoStatus,
				AtendimentoResumoView.AtendimentoTipoDirecionamento,
				AtendimentoResumoView.AtendimentoValorNegocio,
				AtendimentoResumoView.AtendimentoComissaoNegocio,
	
				AtendimentoResumoView.ProdutoId,
				AtendimentoResumoView.ProdutoNome,
				AtendimentoResumoView.ProdutoUF,
				AtendimentoResumoView.ProdutoMarco,
				
				AtendimentoResumoView.CanalId,
				AtendimentoResumoView.CanalNome,
				AtendimentoResumoView.CanalMeio,
		
				AtendimentoResumoView.MidiaId,
				AtendimentoResumoView.MidiaNome,
				AtendimentoResumoView.MidiaTipoValor,

				AtendimentoResumoView.IntegradoraExternaId,
				AtendimentoResumoView.IntegradoraExternaIdGuid,
				AtendimentoResumoView.IntegradoraExternaExtensaoLogo,
				AtendimentoResumoView.IntegradoraExternaNome,
		
				AtendimentoResumoView.PecaId,
				AtendimentoResumoView.PecaNome,
		
				AtendimentoResumoView.CampanhaMarketingId,
				AtendimentoResumoView.CampanhaMarketingNome,
		
				AtendimentoResumoView.GrupoPecaMarketingId,
				AtendimentoResumoView.GrupoPecaMarketingNome,
		
				AtendimentoResumoView.GrupoId,
				AtendimentoResumoView.GrupoNome,
				AtendimentoResumoView.GrupoHierarquia,
				AtendimentoResumoView.GrupoHierarquiaTipo,
				AtendimentoResumoView.GrupoTag,
		
				AtendimentoResumoView.ClassificacaoId,
				AtendimentoResumoView.ClassificacaoIdGuid, 
				AtendimentoResumoView.ClassificacaoValor,
				AtendimentoResumoView.ClassificacaoValor2,
				AtendimentoResumoView.ClassificacaoOrdem,

				AtendimentoResumoView.ProspeccaoId,
				AtendimentoResumoView.ProspeccaoNome,
		
				AtendimentoResumoView.CampanhaId,
				AtendimentoResumoView.CampanhaNome,
		
				AtendimentoResumoView.CriouAtendimentoUsuarioContaSistemaId,
				AtendimentoResumoView.CriouAtendimentoPessoaNome,
		
				AtendimentoResumoView.UsuarioContaSistemaId,
				AtendimentoResumoView.UsuarioContaSistemaIdGuid,
				AtendimentoResumoView.UsuarioContaSistemaStatus,
		
				AtendimentoResumoView.PessoaId,
				AtendimentoResumoView.PessoaNome,
				AtendimentoResumoView.PessoaApelido,
				AtendimentoResumoView.PessoaEmail,

				AtendimentoResumoView.ProdutoSubList,
		
				AtendimentoResumoView.PessoaProspectId,
				AtendimentoResumoView.PessoaProspectIdGuid,
				AtendimentoResumoView.PessoaProspectDtInclusao,
				AtendimentoResumoView.PessoaProspectNome,
				left(AtendimentoResumoView.PessoaProspectEmailList, 8000) as AtendimentoResumoView,
				AtendimentoResumoView.PessoaProspectTelefoneList,
				AtendimentoResumoView.PessoaProspectCPF,
				AtendimentoResumoView.PessoaProspectTagList,
				AtendimentoResumoView.PessoaProspectSexo, 
				AtendimentoResumoView.PessoaProspectDtNascimento,
				AtendimentoResumoView.PessoaProspectProfissao, 
		
				AtendimentoResumoView.AtendimentoConvercaoVenda,
		
				AtendimentoResumoView.AtendimentoIdMotivacaoNaoConversaoVenda,
				AtendimentoResumoView.AtendimentoMotivacaoNaoConversaoVenda,

			
				AtendimentoResumoView.InteracaoPrimeiraId,
				AtendimentoResumoView.InteracaoPrimeiraDtFull,

				AtendimentoResumoView.InteracaoNegociacaoVendaUltimaId,
				AtendimentoResumoView.InteracaoNegociacaoVendaUltimaDtFull,

				AtendimentoResumoView.InteracaoUltimaId,
				AtendimentoResumoView.InteracaoUltimaDtFull,
				AtendimentoResumoView.InteracaoUltimaTipoValor,
				AtendimentoResumoView.InteracaoUltimaTipoValorAbreviado,
				AtendimentoResumoView.InteracaoUltimaDtUtilConsiderar,

				AtendimentoResumoView.AlarmeUltimoAtivoId,
				AtendimentoResumoView.AlarmeUltimoAtivoData,
				AtendimentoResumoView.AlarmeUltimoAtivoInteracaoTipoValor,

				AtendimentoResumoView.AlarmeProximoAtivoId,
				AtendimentoResumoView.AlarmeProximoAtivoData,
				AtendimentoResumoView.AlarmeProximoAtivoInteracaoTipoValor,

				AtendimentoResumoView.PessoaEnderecoUF1,
				AtendimentoResumoView.PessoaEnderecoCidade1,
				AtendimentoResumoView.PessoaEnderecoBairro1,
				AtendimentoResumoView.PessoaEnderecoLogradouro1,
				AtendimentoResumoView.PessoaEnderecoComplemento1,
				AtendimentoResumoView.PessoaEnderecoNumero1,
				AtendimentoResumoView.PessoaEnderecoCEP1,
				AtendimentoResumoView.PessoaEnderecoLatitude1,
				AtendimentoResumoView.PessoaEnderecoLongitude1,
				AtendimentoResumoView.PessoaEnderecoTipo1,

				AtendimentoResumoView.PessoaEnderecoUF2,
				AtendimentoResumoView.PessoaEnderecoCidade2,
				AtendimentoResumoView.PessoaEnderecoBairro2,
				AtendimentoResumoView.PessoaEnderecoLogradouro2,
				AtendimentoResumoView.PessoaEnderecoComplemento2,
				AtendimentoResumoView.PessoaEnderecoNumero2,
				AtendimentoResumoView.PessoaEnderecoCEP2,
				AtendimentoResumoView.PessoaEnderecoLatitude2,
				AtendimentoResumoView.PessoaEnderecoLongitude2,
				AtendimentoResumoView.PessoaEnderecoTipo2,

				AtendimentoResumoView.DtAtualizacaoAuto

				into #TabAtendimentoTemp

			From
				AtendimentoResumoView WITH (nolock)
					inner join
				@TableAlteracoes temp on temp.IdAtendimento = AtendimentoResumoView.Atendimentoid

			print 'END - select do (AtendimentoResumoView) e insert na tabela temporária  - ' + convert(varchar(200) ,CAST((dbo.GetDateCustom() - @dtInicio) as time(0)))
			set @dtInicio = dbo.GetDateCustom()

			if (ISNULL((Select top 1 Tab.Atendimentoid from #TabAtendimentoTemp Tab),0) > 0)
					begin
						if (@GerarTudo = 1)
							begin
								-- Exclui Todos os registros das conta sistema desabilitadas			
								-- Delete TabelaoAtendimento

								-- deleta todos os registros da tabela
								TRUNCATE TABLE TabelaoAtendimentoAux
		
								-- Desliga as constraints
								ALTER TABLE TabelaoAtendimentoAux NOCHECK CONSTRAINT ALL
			
								-- Desliga os índices
								ALTER INDEX All ON TabelaoAtendimentoAux DISABLE
								
								-- Delete o índice mas reconstroe abaixo
								--DROP INDEX [idxColumnStore] ON [dbo].[TabelaoAtendimento]
								
								-- Recria e habilita apenas o índice do id pois se n ocorre erro no insert
								-- Se faz necessário o try catch pois na interação en questão não é possível saber se está usando a tabela atual ou a renomeada
								--if exists (SELECT * FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS WHERE CONSTRAINT_NAME = 'PK_TabelaoAtendimentoAux' AND TABLE_NAME = 'TabelaoAtendimentoAux' AND TABLE_SCHEMA ='dbo')
								--	begin
								--		ALTER INDEX idxUniqueId ON TabelaoAtendimentoAux REBUILD
								--	end
								--else
								--	begin
										ALTER INDEX idxUniqueId ON TabelaoAtendimentoAux REBUILD
								--	end

							end
						else
							begin
								---- Deleta os registros do tabelão que estão contidos na tabela acima
								with cte as 
								(
									select 
										TabelaoAtendimento.AtendimentoId
									from 
										TabelaoAtendimento with (nolock) 
									where exists (select temp.IdAtendimento from @TableAlteracoes temp where temp.IdAtendimento = TabelaoAtendimento.AtendimentoId)
								)
								delete from cte
							end

						
						print 'END - deletando registros tabelão - ' + convert(varchar(200) ,CAST((dbo.GetDateCustom() - @dtInicio) as time(0)))
						set @dtInicio = dbo.GetDateCustom()
					end

		end

	if (@isExecute = 1)
		begin
			set @iCount = (Select count(TabAux.Atendimentoid) from #TabAtendimentoTemp TabAux);
			declare @i int = 1;

			WHILE @i <= @iCount 
				BEGIN
					BEGIN TRANSACTION TRAN_LOOPINSERCAO

						set @dtInicioAux = dbo.GetDateCustom()

						if (@GerarTudo = 0)
							begin
								-- Irá selecionar e inserir todos os registros em uma tabela temporária
								-- para depois então excluir os registros do tabelão atendimento 
								-- e os inserir, se faz necessário para quando estiver gerando ã tabela ficar o menor tempo possível 
								-- com lock
								Insert into TabelaoAtendimento
								(
									DtInclusao,
									ContasistemaId,
									ContasistemaIdGuid,
		
									Atendimentoid,
									versionAtendimento,
									AtendimentoIdGuid,
									AtendimentoDtInclusao,
									AtendimentoDtInicio,
									AtendimentoDtConclusao,
									AtendimentoStatus,
									AtendimentoNegociacaoStatus,
									AtendimentoTipoDirecionamento,
									AtendimentoValorNegocio,
									AtendimentoComissaoNegocio,
		
									ProdutoId,
									ProdutoNome,
									ProdutoUF,
									ProdutoMarco,

									CanalId,
									CanalNome,
									CanalMeio,
		
									MidiaId,
									MidiaNome,
									MidiaTipoValor,

									IntegradoraExternaId,
									IntegradoraExternaIdGuid,
									IntegradoraExternaExtensaoLogo,
									IntegradoraExternaNome,
		
									PecaId,
									PecaNome,
		
									CampanhaMarketingId,
									CampanhaMarketingNome,
		
									GrupoPecaMarketingId,
									GrupoPecaMarketingNome,
		
									GrupoId,
									GrupoNome,
									GrupoHierarquia,
									GrupoHierarquiaTipo,
									GrupoTag,
		
									ClassificacaoId,
									ClassificacaoIdGuid,
									ClassificacaoValor,
									ClassificacaoValor2,
									ClassificacaoOrdem,

									ProspeccaoId,
									ProspeccaoNome,
		
									CampanhaId,
									CampanhaNome,
		
									CriouAtendimentoUsuarioContaSistemaId,
									CriouAtendimentoPessoaNome,
		
									UsuarioContaSistemaId,
									UsuarioContaSistemaIdGuid,
									UsuarioContaSistemaStatus,
		
									PessoaId,
									PessoaNome,
									PessoaApelido,
									PessoaEmail,

									ProdutoSubList,
		
									PessoaProspectId,
									PessoaProspectIdGuid,
									PessoaProspectDtInclusao,
									PessoaProspectNome,
									PessoaProspectEmailList,
									PessoaProspectTelefoneList,
									PessoaProspectCPF,
									PessoaProspectTagList,
									PessoaProspectSexo,
									PessoaProspectDtNascimento,
									PessoaProspectProfissao,
		
		
									AtendimentoConvercaoVenda,

									AtendimentoIdMotivacaoNaoConversaoVenda,
									AtendimentoMotivacaoNaoConversaoVenda,

									InteracaoPrimeiraId,
									InteracaoPrimeiraDtFull,

									InteracaoNegociacaoVendaUltimaId,
									InteracaoNegociacaoVendaUltimaDtFull,

									InteracaoUltimaId,
									InteracaoUltimaDtFull,
									InteracaoUltimaTipoValor,
									InteracaoUltimaTipoValorAbreviado,
									InteracaoUltimaDtUtilConsiderar,

									AlarmeUltimoAtivoId,
									AlarmeUltimoAtivoData,
									AlarmeUltimoAtivoInteracaoTipoValor,

									AlarmeProximoAtivoId,
									AlarmeProximoAtivoData,
									AlarmeProximoAtivoInteracaoTipoValor,

									PessoaEnderecoUF1,
									PessoaEnderecoCidade1,
									PessoaEnderecoBairro1,
									PessoaEnderecoLogradouro1,
									PessoaEnderecoComplemento1,
									PessoaEnderecoNumero1,
									PessoaEnderecoCEP1,
									PessoaEnderecoLatitude1,
									PessoaEnderecoLongitude1,
									PessoaEnderecoTipo1,

									PessoaEnderecoUF2,
									PessoaEnderecoCidade2,
									PessoaEnderecoBairro2,
									PessoaEnderecoLogradouro2,
									PessoaEnderecoComplemento2,
									PessoaEnderecoNumero2,
									PessoaEnderecoCEP2,
									PessoaEnderecoLatitude2,
									PessoaEnderecoLongitude2,
									PessoaEnderecoTipo2,

									DtAtualizacaoAuto
								)
								Select 
									@dtReferenciaUtilizarMaximo as DtInclusao,
									TabAtendimentoTemp.ContasistemaId,
									TabAtendimentoTemp.ContasistemaIdGuid,
					
									TabAtendimentoTemp.Atendimentoid,
									TabAtendimentoTemp.AtendimentoVersao,
									TabAtendimentoTemp.AtendimentoidGuid,
									TabAtendimentoTemp.AtendimentoDtInclusao,
									TabAtendimentoTemp.AtendimentoDtInicio,
									TabAtendimentoTemp.AtendimentoDtConclusao,
									TabAtendimentoTemp.AtendimentoStatus,
									TabAtendimentoTemp.AtendimentoNegociacaoStatus,
									TabAtendimentoTemp.AtendimentoTipoDirecionamento,
									TabAtendimentoTemp.AtendimentoValorNegocio,
									TabAtendimentoTemp.AtendimentoComissaoNegocio,
	
									TabAtendimentoTemp.ProdutoId,
									TabAtendimentoTemp.ProdutoNome,
									TabAtendimentoTemp.ProdutoUF,
									TabAtendimentoTemp.ProdutoMarco,
				
									TabAtendimentoTemp.CanalId,
									TabAtendimentoTemp.CanalNome,
									TabAtendimentoTemp.CanalMeio,
		
									TabAtendimentoTemp.MidiaId,
									TabAtendimentoTemp.MidiaNome,
									TabAtendimentoTemp.MidiaTipoValor,

									TabAtendimentoTemp.IntegradoraExternaId,
									TabAtendimentoTemp.IntegradoraExternaIdGuid,
									TabAtendimentoTemp.IntegradoraExternaExtensaoLogo,
									TabAtendimentoTemp.IntegradoraExternaNome,
		
									TabAtendimentoTemp.PecaId,
									TabAtendimentoTemp.PecaNome,
		
									TabAtendimentoTemp.CampanhaMarketingId,
									TabAtendimentoTemp.CampanhaMarketingNome,
		
									TabAtendimentoTemp.GrupoPecaMarketingId,
									TabAtendimentoTemp.GrupoPecaMarketingNome,
		
									TabAtendimentoTemp.GrupoId,
									TabAtendimentoTemp.GrupoNome,
									TabAtendimentoTemp.GrupoHierarquia,
									TabAtendimentoTemp.GrupoHierarquiaTipo,
									TabAtendimentoTemp.GrupoTag,
		
									TabAtendimentoTemp.ClassificacaoId,
									TabAtendimentoTemp.ClassificacaoIdGuid, 
									TabAtendimentoTemp.ClassificacaoValor,
									TabAtendimentoTemp.ClassificacaoValor2,
									TabAtendimentoTemp.ClassificacaoOrdem,

									TabAtendimentoTemp.ProspeccaoId,
									TabAtendimentoTemp.ProspeccaoNome,
		
									TabAtendimentoTemp.CampanhaId,
									TabAtendimentoTemp.CampanhaNome,
		
									TabAtendimentoTemp.CriouAtendimentoUsuarioContaSistemaId,
									TabAtendimentoTemp.CriouAtendimentoPessoaNome,
		
									TabAtendimentoTemp.UsuarioContaSistemaId,
									TabAtendimentoTemp.UsuarioContaSistemaIdGuid,
									TabAtendimentoTemp.UsuarioContaSistemaStatus,
		
									TabAtendimentoTemp.PessoaId,
									TabAtendimentoTemp.PessoaNome,
									TabAtendimentoTemp.PessoaApelido,
									TabAtendimentoTemp.PessoaEmail,

									TabAtendimentoTemp.ProdutoSubList,
		
									TabAtendimentoTemp.PessoaProspectId,
									TabAtendimentoTemp.PessoaProspectIdGuid,
									TabAtendimentoTemp.PessoaProspectDtInclusao,
									TabAtendimentoTemp.PessoaProspectNome,
									TabAtendimentoTemp.PessoaProspectEmailList,
									TabAtendimentoTemp.PessoaProspectTelefoneList,
									TabAtendimentoTemp.PessoaProspectCPF,
									TabAtendimentoTemp.PessoaProspectTagList,
									TabAtendimentoTemp.PessoaProspectSexo, 
									TabAtendimentoTemp.PessoaProspectDtNascimento,
									TabAtendimentoTemp.PessoaProspectProfissao, 
		
									TabAtendimentoTemp.AtendimentoConvercaoVenda,
		
									TabAtendimentoTemp.AtendimentoIdMotivacaoNaoConversaoVenda,
									TabAtendimentoTemp.AtendimentoMotivacaoNaoConversaoVenda,

									TabAtendimentoTemp.InteracaoPrimeiraId,
									TabAtendimentoTemp.InteracaoPrimeiraDtFull,

									TabAtendimentoTemp.InteracaoNegociacaoVendaUltimaId,
									TabAtendimentoTemp.InteracaoNegociacaoVendaUltimaDtFull,

									TabAtendimentoTemp.InteracaoUltimaId,
									TabAtendimentoTemp.InteracaoUltimaDtFull,
									TabAtendimentoTemp.InteracaoUltimaTipoValor,
									TabAtendimentoTemp.InteracaoUltimaTipoValorAbreviado,
									TabAtendimentoTemp.InteracaoUltimaDtUtilConsiderar,

									TabAtendimentoTemp.AlarmeUltimoAtivoId,
									TabAtendimentoTemp.AlarmeUltimoAtivoData,
									TabAtendimentoTemp.AlarmeUltimoAtivoInteracaoTipoValor,

									TabAtendimentoTemp.AlarmeProximoAtivoId,
									TabAtendimentoTemp.AlarmeProximoAtivoData,
									TabAtendimentoTemp.AlarmeProximoAtivoInteracaoTipoValor,

									TabAtendimentoTemp.PessoaEnderecoUF1,
									TabAtendimentoTemp.PessoaEnderecoCidade1,
									TabAtendimentoTemp.PessoaEnderecoBairro1,
									TabAtendimentoTemp.PessoaEnderecoLogradouro1,
									TabAtendimentoTemp.PessoaEnderecoComplemento1,
									TabAtendimentoTemp.PessoaEnderecoNumero1,
									TabAtendimentoTemp.PessoaEnderecoCEP1,
									TabAtendimentoTemp.PessoaEnderecoLatitude1,
									TabAtendimentoTemp.PessoaEnderecoLongitude1,
									TabAtendimentoTemp.PessoaEnderecoTipo1,

									TabAtendimentoTemp.PessoaEnderecoUF2,
									TabAtendimentoTemp.PessoaEnderecoCidade2,
									TabAtendimentoTemp.PessoaEnderecoBairro2,
									TabAtendimentoTemp.PessoaEnderecoLogradouro2,
									TabAtendimentoTemp.PessoaEnderecoComplemento2,
									TabAtendimentoTemp.PessoaEnderecoNumero2,
									TabAtendimentoTemp.PessoaEnderecoCEP2,
									TabAtendimentoTemp.PessoaEnderecoLatitude2,
									TabAtendimentoTemp.PessoaEnderecoLongitude2,
									TabAtendimentoTemp.PessoaEnderecoTipo2,

									TabAtendimentoTemp.DtAtualizacaoAuto

								From
									#TabAtendimentoTemp TabAtendimentoTemp   WITH (NOLOCK)
								where
									not exists (Select TabelaoAtendimento.AtendimentoId from TabelaoAtendimento with (nolock) where TabelaoAtendimento.AtendimentoId = TabAtendimentoTemp.AtendimentoId)
										and
									TabAtendimentoTemp.rownumber between @i and @i + @iQtdPorTransaction
							end
						else
							begin
								-- Irá selecionar e inserir todos os registros em uma tabela temporária
								-- para depois então excluir os registros do tabelão atendimento 
								-- e os inserir, se faz necessário para quando estiver gerando ã tabela ficar o menor tempo possível 
								-- com lock
								Insert into TabelaoAtendimentoAux
								(
									DtInclusao,
									ContasistemaId,
									ContasistemaIdGuid,
		
									Atendimentoid,
									versionAtendimento,
									AtendimentoIdGuid,
									AtendimentoDtInclusao,
									AtendimentoDtInicio,
									AtendimentoDtConclusao,
									AtendimentoStatus,
									AtendimentoNegociacaoStatus,
									AtendimentoTipoDirecionamento,
									AtendimentoValorNegocio,
									AtendimentoComissaoNegocio,
		
									ProdutoId,
									ProdutoNome,
									ProdutoUF,
									ProdutoMarco,

									CanalId,
									CanalNome,
									CanalMeio,
		
									MidiaId,
									MidiaNome,
									MidiaTipoValor,

									IntegradoraExternaId,
									IntegradoraExternaIdGuid,
									IntegradoraExternaExtensaoLogo,
									IntegradoraExternaNome,
		
									PecaId,
									PecaNome,
		
									CampanhaMarketingId,
									CampanhaMarketingNome,
		
									GrupoPecaMarketingId,
									GrupoPecaMarketingNome,
		
									GrupoId,
									GrupoNome,
									GrupoHierarquia,
									GrupoHierarquiaTipo,
									GrupoTag,
		
									ClassificacaoId,
									ClassificacaoIdGuid,
									ClassificacaoValor,
									ClassificacaoValor2,
									ClassificacaoOrdem,

									ProspeccaoId,
									ProspeccaoNome,
		
									CampanhaId,
									CampanhaNome,
		
									CriouAtendimentoUsuarioContaSistemaId,
									CriouAtendimentoPessoaNome,
		
									UsuarioContaSistemaId,
									UsuarioContaSistemaIdGuid,
									UsuarioContaSistemaStatus,
		
									PessoaId,
									PessoaNome,
									PessoaApelido,
									PessoaEmail,

									ProdutoSubList,
		
									PessoaProspectId,
									PessoaProspectIdGuid,
									PessoaProspectDtInclusao,
									PessoaProspectNome,
									PessoaProspectEmailList,
									PessoaProspectTelefoneList,
									PessoaProspectCPF,
									PessoaProspectTagList,
									PessoaProspectSexo,
									PessoaProspectDtNascimento,
									PessoaProspectProfissao,
		
		
									AtendimentoConvercaoVenda,

									AtendimentoIdMotivacaoNaoConversaoVenda,
									AtendimentoMotivacaoNaoConversaoVenda,

									InteracaoPrimeiraId,
									InteracaoPrimeiraDtFull,

									InteracaoNegociacaoVendaUltimaId,
									InteracaoNegociacaoVendaUltimaDtFull,

									InteracaoUltimaId,
									InteracaoUltimaDtFull,
									InteracaoUltimaTipoValor,
									InteracaoUltimaTipoValorAbreviado,
									InteracaoUltimaDtUtilConsiderar,

									AlarmeUltimoAtivoId,
									AlarmeUltimoAtivoData,
									AlarmeUltimoAtivoInteracaoTipoValor,

									AlarmeProximoAtivoId,
									AlarmeProximoAtivoData,
									AlarmeProximoAtivoInteracaoTipoValor,

									PessoaEnderecoUF1,
									PessoaEnderecoCidade1,
									PessoaEnderecoBairro1,
									PessoaEnderecoLogradouro1,
									PessoaEnderecoComplemento1,
									PessoaEnderecoNumero1,
									PessoaEnderecoCEP1,
									PessoaEnderecoLatitude1,
									PessoaEnderecoLongitude1,
									PessoaEnderecoTipo1,

									PessoaEnderecoUF2,
									PessoaEnderecoCidade2,
									PessoaEnderecoBairro2,
									PessoaEnderecoLogradouro2,
									PessoaEnderecoComplemento2,
									PessoaEnderecoNumero2,
									PessoaEnderecoCEP2,
									PessoaEnderecoLatitude2,
									PessoaEnderecoLongitude2,
									PessoaEnderecoTipo2,

									DtAtualizacaoAuto
								)
								Select 
									@dtReferenciaUtilizarMaximo as DtInclusao,
									TabAtendimentoTemp.ContasistemaId,
									TabAtendimentoTemp.ContasistemaIdGuid,
					
									TabAtendimentoTemp.Atendimentoid,
									TabAtendimentoTemp.AtendimentoVersao,
									TabAtendimentoTemp.AtendimentoidGuid,
									TabAtendimentoTemp.AtendimentoDtInclusao,
									TabAtendimentoTemp.AtendimentoDtInicio,
									TabAtendimentoTemp.AtendimentoDtConclusao,
									TabAtendimentoTemp.AtendimentoStatus,
									TabAtendimentoTemp.AtendimentoNegociacaoStatus,
									TabAtendimentoTemp.AtendimentoTipoDirecionamento,
									TabAtendimentoTemp.AtendimentoValorNegocio,
									TabAtendimentoTemp.AtendimentoComissaoNegocio,
	
									TabAtendimentoTemp.ProdutoId,
									TabAtendimentoTemp.ProdutoNome,
									TabAtendimentoTemp.ProdutoUF,
									TabAtendimentoTemp.ProdutoMarco,
				
									TabAtendimentoTemp.CanalId,
									TabAtendimentoTemp.CanalNome,
									TabAtendimentoTemp.CanalMeio,
		
									TabAtendimentoTemp.MidiaId,
									TabAtendimentoTemp.MidiaNome,
									TabAtendimentoTemp.MidiaTipoValor,

									TabAtendimentoTemp.IntegradoraExternaId,
									TabAtendimentoTemp.IntegradoraExternaIdGuid,
									TabAtendimentoTemp.IntegradoraExternaExtensaoLogo,
									TabAtendimentoTemp.IntegradoraExternaNome,
		
									TabAtendimentoTemp.PecaId,
									TabAtendimentoTemp.PecaNome,
		
									TabAtendimentoTemp.CampanhaMarketingId,
									TabAtendimentoTemp.CampanhaMarketingNome,
		
									TabAtendimentoTemp.GrupoPecaMarketingId,
									TabAtendimentoTemp.GrupoPecaMarketingNome,
		
									TabAtendimentoTemp.GrupoId,
									TabAtendimentoTemp.GrupoNome,
									TabAtendimentoTemp.GrupoHierarquia,
									TabAtendimentoTemp.GrupoHierarquiaTipo,
									TabAtendimentoTemp.GrupoTag,
		
									TabAtendimentoTemp.ClassificacaoId,
									TabAtendimentoTemp.ClassificacaoIdGuid, 
									TabAtendimentoTemp.ClassificacaoValor,
									TabAtendimentoTemp.ClassificacaoValor2,
									TabAtendimentoTemp.ClassificacaoOrdem,

									TabAtendimentoTemp.ProspeccaoId,
									TabAtendimentoTemp.ProspeccaoNome,
		
									TabAtendimentoTemp.CampanhaId,
									TabAtendimentoTemp.CampanhaNome,
		
									TabAtendimentoTemp.CriouAtendimentoUsuarioContaSistemaId,
									TabAtendimentoTemp.CriouAtendimentoPessoaNome,
		
									TabAtendimentoTemp.UsuarioContaSistemaId,
									TabAtendimentoTemp.UsuarioContaSistemaIdGuid,
									TabAtendimentoTemp.UsuarioContaSistemaStatus,
		
									TabAtendimentoTemp.PessoaId,
									TabAtendimentoTemp.PessoaNome,
									TabAtendimentoTemp.PessoaApelido,
									TabAtendimentoTemp.PessoaEmail,

									TabAtendimentoTemp.ProdutoSubList,
		
									TabAtendimentoTemp.PessoaProspectId,
									TabAtendimentoTemp.PessoaProspectIdGuid,
									TabAtendimentoTemp.PessoaProspectDtInclusao,
									TabAtendimentoTemp.PessoaProspectNome,
									TabAtendimentoTemp.PessoaProspectEmailList,
									TabAtendimentoTemp.PessoaProspectTelefoneList,
									TabAtendimentoTemp.PessoaProspectCPF,
									TabAtendimentoTemp.PessoaProspectTagList,
									TabAtendimentoTemp.PessoaProspectSexo, 
									TabAtendimentoTemp.PessoaProspectDtNascimento,
									TabAtendimentoTemp.PessoaProspectProfissao, 
		
									TabAtendimentoTemp.AtendimentoConvercaoVenda,
		
									TabAtendimentoTemp.AtendimentoIdMotivacaoNaoConversaoVenda,
									TabAtendimentoTemp.AtendimentoMotivacaoNaoConversaoVenda,

									TabAtendimentoTemp.InteracaoPrimeiraId,
									TabAtendimentoTemp.InteracaoPrimeiraDtFull,

									TabAtendimentoTemp.InteracaoNegociacaoVendaUltimaId,
									TabAtendimentoTemp.InteracaoNegociacaoVendaUltimaDtFull,

									TabAtendimentoTemp.InteracaoUltimaId,
									TabAtendimentoTemp.InteracaoUltimaDtFull,
									TabAtendimentoTemp.InteracaoUltimaTipoValor,
									TabAtendimentoTemp.InteracaoUltimaTipoValorAbreviado,
									TabAtendimentoTemp.InteracaoUltimaDtUtilConsiderar,

									TabAtendimentoTemp.AlarmeUltimoAtivoId,
									TabAtendimentoTemp.AlarmeUltimoAtivoData,
									TabAtendimentoTemp.AlarmeUltimoAtivoInteracaoTipoValor,

									TabAtendimentoTemp.AlarmeProximoAtivoId,
									TabAtendimentoTemp.AlarmeProximoAtivoData,
									TabAtendimentoTemp.AlarmeProximoAtivoInteracaoTipoValor,

									TabAtendimentoTemp.PessoaEnderecoUF1,
									TabAtendimentoTemp.PessoaEnderecoCidade1,
									TabAtendimentoTemp.PessoaEnderecoBairro1,
									TabAtendimentoTemp.PessoaEnderecoLogradouro1,
									TabAtendimentoTemp.PessoaEnderecoComplemento1,
									TabAtendimentoTemp.PessoaEnderecoNumero1,
									TabAtendimentoTemp.PessoaEnderecoCEP1,
									TabAtendimentoTemp.PessoaEnderecoLatitude1,
									TabAtendimentoTemp.PessoaEnderecoLongitude1,
									TabAtendimentoTemp.PessoaEnderecoTipo1,

									TabAtendimentoTemp.PessoaEnderecoUF2,
									TabAtendimentoTemp.PessoaEnderecoCidade2,
									TabAtendimentoTemp.PessoaEnderecoBairro2,
									TabAtendimentoTemp.PessoaEnderecoLogradouro2,
									TabAtendimentoTemp.PessoaEnderecoComplemento2,
									TabAtendimentoTemp.PessoaEnderecoNumero2,
									TabAtendimentoTemp.PessoaEnderecoCEP2,
									TabAtendimentoTemp.PessoaEnderecoLatitude2,
									TabAtendimentoTemp.PessoaEnderecoLongitude2,
									TabAtendimentoTemp.PessoaEnderecoTipo2,

									TabAtendimentoTemp.DtAtualizacaoAuto

								From
									#TabAtendimentoTemp TabAtendimentoTemp WITH (NOLOCK)
								where
									TabAtendimentoTemp.rownumber between @i and @i + @iQtdPorTransaction
							end

						print 'insert ('+convert(varchar(200),@i)+') até ('+convert(varchar(200),(@i + @iQtdPorTransaction))+') - '+ convert(varchar(200) ,CAST((dbo.GetDateCustom() - @dtInicioAux) as time(0)))
									
						set @i = @i + @iQtdPorTransaction + 1

					COMMIT TRANSACTION TRAN_LOOPINSERCAO;  

				-- End do While
				END
			print 'END - insert no tabelão - ' + convert(varchar(200) ,CAST((dbo.GetDateCustom() - @dtInicio) as time(0)))
			set @dtInicio = dbo.GetDateCustom()
		
		end
		 
	if (@isExecute = 1 and @GerarTudo = 1)
		begin
			-- Liga as constraints
			--ALTER TABLE TabelaoAtendimento CHECK CONSTRAINT ALL
			
			-- Liga e Reconstroi os índices
			-- ONLINE = ON, permite o acesso ao dados sem bloqueio a tabela mas é mais demorado
			-- como a tabela é exclusiva setarei OFF nessa operação
			ALTER INDEX ALL ON TabelaoAtendimentoAux REBUILD PARTITION = ALL WITH (ONLINE = ON)
		end

	print 'END - geração dos índices - ' + convert(varchar(200) ,CAST((dbo.GetDateCustom() - @dtInicio) as time(0)))
	set @dtInicio = dbo.GetDateCustom()

	if (@isExecute = 1 and @GerarTudo = 1)
		begin
			EXEC sp_rename 'TabelaoAtendimento', 'TabelaoAtendimentoAuxOld2';
			EXEC sp_rename 'TabelaoAtendimentoAux', 'TabelaoAtendimento'; 
			EXEC sp_rename 'TabelaoAtendimentoAuxOld2', 'TabelaoAtendimentoAux';
		end

	print 'END - sp_rename ' + convert(varchar(200) ,CAST((dbo.GetDateCustom() - @dtInicio) as time(0)))
	set @dtInicio = dbo.GetDateCustom()

	if (@isExecute = 1 and @GerarTudo = 1)
		begin
			truncate table TabelaoAtendimentoAux
		end

	Update 
		TabelaoLog 
	Set
		-- Adiciona 2 milesegundo desde a última execução para considerar todos atualizados desde a última atualização
		-- 2 pq é o mínimo que pode adicionar
		TabelaoLog.Data1 = @dtReferenciaUtilizarMaximo,
		TabelaoLog.Data2 = null,
		TabelaoLog.bit1 = @GerarTudo,
		TabelaoLog.DtUltimaParcial = case when @GerarTudo = 0 then dbo.GetDateCustom() else TabelaoLog.DtUltimaParcial end,
		TabelaoLog.DtUltimaCompleta = case when @GerarTudo = 1 then dbo.GetDateCustom() else TabelaoLog.DtUltimaCompleta end
	where
		TabelaoLog.Nome = @BatchNome

	print 'Total de: '+ convert(varchar(45), @iCount) + ' em ' + convert(varchar(200) ,CAST((dbo.GetDateCustom() - @dtInicioGeral) as time(0)));

CREATE procedure [dbo].[ProcGerarTabelaoAlarme] 
(
	@DataReferencia datetime,
	@GerarTudo bit
)
as

	-- comentar
	-- return

	SET NOCOUNT ON

	DECLARE @TableAlteracoes TABLE
	(
	  IdAlarme int,
	  rownumber int
	);


	DECLARE @TableAlteracoesAux TABLE
	(
	  IdAlarme int
	);

	declare @dtnow datetime = dbo.getDateCustom()	
	declare @iCount int = 0
	declare @iQtdPorTransaction int = 15000
	declare @isExecute bit = 1
	declare @dtReferenciaUtilizarMinimo as datetime
	declare @dtReferenciaUtilizarMaximo datetime = @dtnow
	declare @dtUltimaAtualizacao datetime
	declare @dtInicioGeral datetime = @dtnow
	declare @dtInicio datetime = @dtnow
	declare @dtInicioAux datetime
	declare @BatchNome varchar(1000) = 'Batch_TabelaoAlarme'

	-- Retorna a data que começou a última atualização
	select @dtUltimaAtualizacao = Max(TabelaoLog.Data2) from TabelaoLog with (nolock) where TabelaoLog.Nome = @BatchNome group by TabelaoLog.Nome

	-- Se o processamento atual não for de gerar tudo e a data não for nula
	-- Subentende-se que no momento está sendo atualizado e não deve rodar 2 atualizações ao mesmo tempo
	-- testará tb se faz mais de 120 minutos que a ultima query executou nesse caso irá considerar que hove erro e executará 
	-- zerando a hora para não ter problemas
	if (@GerarTudo = 0 and @dtUltimaAtualizacao is not null and DATEDIFF(MI, @dtUltimaAtualizacao, dbo.GetDateCustom()) < 120)
		begin
			return
		end
	--else
	--	begin
	--		update TabelaoLog set TabelaoLog.Data2 = dbo.GetDateCustom() where TabelaoLog.Nome = @BatchNome
	--	end
		
	-- Caso seja repassado null
	-- Recupera a data a ser utilizada de acordo com a última vez que foi atualizado
	if @DataReferencia is null 
		begin
			set @dtReferenciaUtilizarMinimo = (select Max(TabelaoLog.Data1) from TabelaoLog with (nolock) where TabelaoLog.Nome = @BatchNome)
		end
	else
		begin
			set @dtReferenciaUtilizarMinimo = @DataReferencia
		end
	
	-- Caso esteja nulo setará a data atual
	if @dtReferenciaUtilizarMinimo is null
		begin
			set @dtReferenciaUtilizarMinimo = dbo.GetDateCustom()
		end

	if @GerarTudo = 1
		begin
			-- Irá recuperar todos os registros alarme que houve alteração
			-- Caso GerarTudo seja 1 irá gerar toda o tabelão
			insert into @TableAlteracoesAux
			Select
				Alarme.Id
			from 
				Alarme with (nolock) 

		end
	else
		begin
			-- o unio é usado  para ficar mais performatico que fazer uma única consulta com or
			insert into @TableAlteracoesAux
			Select
				Alarme.Id
			from
				Alarme with (nolock)
			where 
				Alarme.DtAtualizacaoAuto between @dtReferenciaUtilizarMinimo and @dtReferenciaUtilizarMaximo

			union
			
			Select
				Alarme.Id
			from 
				SuperEntidade with (nolock)
					inner join
				Alarme with (nolock) on Alarme.IdSuperEntidade = SuperEntidade.Id
			where 
				SuperEntidade.DtAtualizacaoAuto between @dtReferenciaUtilizarMinimo and @dtReferenciaUtilizarMaximo

			-- http://www.sommarskog.se/dyn-search.html
			OPTION (RECOMPILE);
		end

	-- Insere na @TableAlteracoes os ids dos prospects que deverá ser alterado
	insert into @TableAlteracoes
	Select TabAux2.IdAlarme, ROW_NUMBER() OVER(ORDER BY TabAux2.IdAlarme ASC) AS RowNumber
	From
		(
			Select
				distinct TabAux.IdAlarme 
			From
				@TableAlteracoesAux TabAux
		) TabAux2

	print 'END - select e insert dos ids - ' + convert(varchar(200) ,CAST((dbo.GetDateCustom() - @dtInicio) as time(0)))
	set @dtInicio = dbo.GetDateCustom()

	-- Caso não exista registro irá retornar para evitar processamento
	if (select COUNT(Tab1.IdAlarme) from @TableAlteracoes Tab1) = 0
		begin 
			set @isExecute = 0
		end

	if @isExecute = 1
		begin	

			-- Irá selecionar e inserir todos os registros em uma tabela temporária
			-- para depois então excluir os registros do tabelão alarme 
			-- e os inserir, se faz necessário para quando estiver gerando ã tabela ficar o menor tempo possível 
			-- com lock
			Select 
				temp.rownumber,
				Interacao.IdUsuarioContaSistema as UsuarioContaSistemaId,
				Pessoa.Nome as PessoaNome,
				Usuario.GuidUsuarioCorrex as UsuarioCorrexIdGuid,
				UsuarioContaSistema.GUID as UsuarioContaSistemaIdGuid,

				TabelaoAtendimento.PessoaProspectNome as PessoaProspectNome,
				TabelaoAtendimento.ContaSistemaId as ContaSistemaId,

				TabelaoAtendimento.AtendimentoId as AtendimentoId,

				Interacao.IdGuid as InteracaoIdGuid,
				Interacao.Id as InteracaoId,
				Interacao.DtInclusao as InteracaoDtInclusao,
				JSON_VALUE(InteracaoObj.ObjJson,'$.Obj.Texto') as InteracaoTexto,
				InteracaoTipo.Tipo as InteracaoInteracaotipo,

				Alarme.Status as AlarmeStatus,
				Alarme.Data as AlarmeData,
				Alarme.Id as AlarmeId,
				Alarme.idGuid as AlarmeIdGuid,
				Alarme.DtAtualizacaoAuto as AlarmeDtUltimaInteracao

				into #TabTemp 

			From
				Alarme WITH (nolock)
					inner join
				Interacao WITH (nolock) on Alarme.Id = Interacao.IdAlarme 
					inner join
				InteracaoObj WITH (nolock) on InteracaoObj.Id = Interacao.Id 
					inner join
				InteracaoTipo with (nolock) on Interacao.IdInteracaoTipo = InteracaoTipo.Id
					inner join
				TabelaoAtendimento WITH (NOLOCK) on TabelaoAtendimento.AtendimentoId = Interacao.IdSuperEntidade
					inner join
				@TableAlteracoes temp on temp.IdAlarme = Alarme.Id
					left outer join
				UsuarioContaSistema with (nolock) on UsuarioContaSistema.id = Interacao.IdUsuarioContaSistema
					left outer join
				Usuario with (nolock) on Usuario.IdPessoa = UsuarioContaSistema.IdPessoa
					left outer join
				Pessoa with (nolock) on Pessoa.Id = UsuarioContaSistema.IdPessoa
					
			print 'END - select do (AtendimentoResumoView) e insert na tabela temporária  - ' + convert(varchar(200) ,CAST((dbo.GetDateCustom() - @dtInicio) as time(0)))
			set @dtInicio = dbo.GetDateCustom()

			-- Deleta todos os registros do tabelão para conta sistemas desativadas
			-- Só irá deletar quando tiver refazendo todo o tabelão
			if (@GerarTudo = 1)
				begin
					-- deleta todos os registros da tabela
					TRUNCATE TABLE TabelaoAlarme
		
					-- Desliga as constraints
					ALTER TABLE TabelaoAlarme NOCHECK CONSTRAINT ALL
			
					-- Desliga os índices
					ALTER INDEX All ON TabelaoAlarme DISABLE
		
					-- Recria e habilita apenas o índice do id pois se n ocorre erro no insert
					ALTER INDEX PK_TABELAOALARME ON TabelaoAlarme REBUILD
				end

			if (@GerarTudo = 0)
				begin
					---- Deleta os registros do tabelão que estão contidos na tabela acima
					delete
						TabelaoAlarme 
					from
						TabelaoAlarme with (nolock) 
							inner join 
						@TableAlteracoes temp on temp.IdAlarme = TabelaoAlarme.AlarmeId
				end

			print 'END - deletando registros tabelão - ' + convert(varchar(200) ,CAST((dbo.GetDateCustom() - @dtInicio) as time(0)))
			set @dtInicio = dbo.GetDateCustom()				

			set @iCount = (Select count(TabAux.AlarmeId) from #TabTemp TabAux);
			declare @i int = 1;
				
			WHILE @i <= @iCount 
				BEGIN
					BEGIN TRANSACTION TRAN_LOOPINSERCAO
						set @dtInicioAux = dbo.GetDateCustom()

						-- Insere os registros do tabelão
						Insert into TabelaoAlarme
						(
							AlarmeId,
							AlarmeIdGuid,
							AlarmeData,
							AlarmeStatus,
							AlarmeDtUltimaInteracao,

							ContaSistemaId,

							UsuarioCorrexIdGuid,
							UsuarioContaSistemaIdGuid,
							UsuarioContaSistemaId,

							PessoaNome,

							PessoaProspectNome,

							AtendimentoId,

							InteracaoIdGuid,
							InteracaoId,
							InteracaoDtInclusao,
							InteracaoTexto,		
							InteracaoInteracaotipo
						)
						Select
							AlarmeId,
							AlarmeIdGuid,
							AlarmeData,
							AlarmeStatus,
							AlarmeDtUltimaInteracao,

							ContaSistemaId,

							UsuarioCorrexIdGuid,
							UsuarioContaSistemaIdGuid,
							UsuarioContaSistemaId,

							PessoaNome,

							PessoaProspectNome,

					
							AtendimentoId,
					
							InteracaoIdGuid,					
							InteracaoId,
							InteracaoDtInclusao,
							InteracaoTexto,		
							InteracaoInteracaotipo

						From 
							#TabTemp TabAux with(nolock)	
						where
							TabAux.rownumber between @i and @i + @iQtdPorTransaction									

						print 'insert ('+convert(varchar(200),@i)+') até ('+convert(varchar(200),(@i + @iQtdPorTransaction))+') - '+ convert(varchar(200) ,CAST((dbo.GetDateCustom() - @dtInicioAux) as time(0)))
						set @i = @i + @iQtdPorTransaction + 1
					
					COMMIT TRANSACTION TRAN_LOOPINSERCAO

				-- End do While
				END
			print 'END - insert no tabelão - ' + convert(varchar(200) ,CAST((dbo.GetDateCustom() - @dtInicio) as time(0)))
			set @dtInicio = dbo.GetDateCustom()

		end

	Update 
		TabelaoLog 
	Set
		-- Adiciona 2 milesegundo desde a última execução para considerar todos atualizados desde a última atualização
		-- 2 pq é o mínimo que pode adicionar
		TabelaoLog.Data1 = @dtReferenciaUtilizarMaximo,
		TabelaoLog.Data2 = null,
		TabelaoLog.bit1 = @GerarTudo,
		TabelaoLog.DtUltimaParcial = case when @GerarTudo = 0 then dbo.GetDateCustom() else TabelaoLog.DtUltimaParcial end,
		TabelaoLog.DtUltimaCompleta = case when @GerarTudo = 1 then dbo.GetDateCustom() else TabelaoLog.DtUltimaCompleta end
	where
		TabelaoLog.Nome = @BatchNome



	if (@isExecute = 1 and @GerarTudo = 1)
		begin
			-- Liga as constraints
			ALTER TABLE TabelaoAlarme CHECK CONSTRAINT ALL
			
			-- Liga e Reconstroi os índices
			ALTER INDEX ALL ON TabelaoAlarme REBUILD PARTITION = ALL WITH (ONLINE = ON)
		end

	print 'END - geração dos índices - ' + convert(varchar(200) ,CAST((dbo.GetDateCustom() - @dtInicio) as time(0)))
	print 'Total de: '+ convert(varchar(45), @iCount) + ' em ' + convert(varchar(200) ,CAST((dbo.GetDateCustom() - @dtInicioGeral) as time(0)));

CREATE procedure [dbo].[ProcGerarTabelaoFichaPesquisaResposta] 
(
	@DataReferencia datetime,
	@GerarTudo bit
)

as
	
	-- comentar
	-- return

	SET NOCOUNT ON


	DECLARE @TableAlteracoes TABLE
	(
	  RespostaFichaPesquisaRespostaId int,
	  rownumber int
	);

	DECLARE @TableAlteracoesAux TABLE
	(
	  RespostaFichaPesquisaRespostaId int
	);

	declare @dtnow datetime = dbo.getDateCustom()
	declare @iCount int = 0
	declare @iQtdPorTransaction int = 15000
	declare @isExecute bit = 1
	declare @dtReferenciaUtilizarMinimo as datetime
	declare @dtReferenciaUtilizarMaximo datetime = @dtnow
	declare @dtUltimaAtualizacao datetime
	declare @dtInicioGeral datetime = @dtnow
	declare @dtInicio datetime = @dtnow
	declare @dtInicioAux datetime

	declare @BatchNome varchar(1000) = 'Batch_TabelaoFichaPesquisaResposta'

	-- Retorna a data que começou a última atualização
	select @dtUltimaAtualizacao = Max(TabelaoLog.Data2) from TabelaoLog with (nolock) where TabelaoLog.Nome = @BatchNome

	-- Se o processamento atual não for de gerar tudo e a data não for nula
	-- Subentende-se que no momento está sendo atualizado e não deve rodar 2 atualizações ao mesmo tempo
	-- testará tb se faz mais de 120 minutos que a ultima query executou nesse caso irá considerar que hove erro e executará 
	-- zerando a hora para não ter problemas
	if (@GerarTudo = 0 and @dtUltimaAtualizacao is not null and DATEDIFF(MI, @dtUltimaAtualizacao, dbo.GetDateCustom()) < 120)
		begin
			return
		end
	--else
	--	begin
	--		update TabelaoLog set TabelaoLog.Data2 = dbo.GetDateCustom() where TabelaoLog.Nome = @BatchNome
	--	end
		
	-- Caso seja repassado null
	-- Recupera a data a ser utilizada de acordo com a última vez que foi atualizado
	if @DataReferencia is null 
		begin
			set @dtReferenciaUtilizarMinimo = (select Max(TabelaoLog.Data1) from TabelaoLog with (nolock) where TabelaoLog.Nome = @BatchNome)
		end
	else
		begin
			set @dtReferenciaUtilizarMinimo = @DataReferencia
		end
	
	-- Caso esteja nulo setará a data atual
	if @dtReferenciaUtilizarMinimo is null
		begin
			set @dtReferenciaUtilizarMinimo = dbo.GetDateCustom()
		end

	if @GerarTudo = 1
		begin
			-- Irá recuperar todos os registros atendimento que houve alteração
			-- Caso GerarTudo seja 1 irá gerar toda o tabelão
			insert into @TableAlteracoesAux
			Select
				RespostaFichaPesquisaResposta.Id
			from 
				RespostaFichaPesquisaResposta with (nolock) 
					inner join 
				RespostaFichaPesquisa  with (nolock) on RespostaFichaPesquisa.Id = RespostaFichaPesquisaResposta.IdRespostaFichaPesquisa
					inner join
				FichaPesquisa with (nolock) on FichaPesquisa.id = RespostaFichaPesquisa.IdFichaPesquisa
					inner join
				ContaSistema with (nolock) on ContaSistema.id = FichaPesquisa.IdContaSistema
			where 
				ContaSistema.Status = 'AT' 

		end
	else
		begin
		-- Irá recuperar todos os registros atendimento que houve alteração
		-- Caso GerarTudo seja 1 irá gerar toda o tabelão
			insert into @TableAlteracoesAux
			Select
				RespostaFichaPesquisaResposta.Id
			from 
				RespostaFichaPesquisaResposta with (nolock) 
					inner join 
				RespostaFichaPesquisa  with (nolock) on RespostaFichaPesquisa.Id = RespostaFichaPesquisaResposta.IdRespostaFichaPesquisa
					inner join
				FichaPesquisa with (nolock) on FichaPesquisa.id = RespostaFichaPesquisa.IdFichaPesquisa
					inner join
				ContaSistema with (nolock) on ContaSistema.id = FichaPesquisa.IdContaSistema
			where 
				(RespostaFichaPesquisaResposta.DtAtualizacaoAuto is not null and RespostaFichaPesquisaResposta.DtAtualizacaoAuto between @dtReferenciaUtilizarMinimo and @dtReferenciaUtilizarMaximo)

		end

	-- Insere na @TableAlteracoes os ids dos prospects que deverá ser alterado
	insert into @TableAlteracoes
	Select TabAux2.RespostaFichaPesquisaRespostaId, ROW_NUMBER() OVER(ORDER BY TabAux2.RespostaFichaPesquisaRespostaId ASC) AS RowNumber
	From
		(
			Select
				distinct TabAux.RespostaFichaPesquisaRespostaId
			From
				@TableAlteracoesAux TabAux
		) TabAux2

	print 'END - select e insert dos ids - ' + convert(varchar(200) ,CAST((dbo.GetDateCustom() - @dtInicio) as time(0)))
	set @dtInicio = dbo.GetDateCustom()

	-- Caso não exista registro irá retornar para evitar processamento
	if (select COUNT(*) from @TableAlteracoes) = 0
		begin 
			set @isExecute = 0
		end
	
	if @isExecute = 1
		begin	

			Select 
				temp.RowNumber,
				@dtnow AS DtInclusao,
				RespostaFichaPesquisaResposta.Id as RespostaFichaPesquisaRespostaId,
				FichaPesquisa.IdContaSistema as IdContaSistema,
				RespostaFichaPesquisaResposta.IdUsuarioContaSistema  as IdUsuarioContaSistemaRespondido,
				RespostaFichaPesquisa.IdAtendimento as IdAtendimento,

				FichaPesquisa.Id as FichaPesquisaId,
				FichaPesquisa.Nome as FichaPesquisaNome,
				FichaPesquisa.Descricao as FichaPesquisaDescricao,

				Pergunta.Id as PerguntaId,
				Pergunta.Descricao as PerguntaDescricao,
				Pergunta.Tipo as PerguntaTipo,
				Pergunta.Obrigatorio as PerguntaObrigatorio,

				Resposta.TextoResposta as RespostaDescricao,
				Resposta.Peso AS RespostaPeso,
				RespostaFichaPesquisaResposta.DtInclusao as RespostaDtRespondido,
				RespostaFichaPesquisa.FichaPesquisaTipo as RespostaFichaPesquisaFichaPesquisaTipo

				into #TabTemp 

			From
				RespostaFichaPesquisaResposta with (nolock)
					inner join
				RespostaFichaPesquisa with (nolock) on RespostaFichaPesquisa.Id = RespostaFichaPesquisaResposta.IdRespostaFichaPesquisa
					inner join
				Resposta with (nolock) on Resposta.id = RespostaFichaPesquisaResposta.IdResposta
					inner join
				Pergunta with (nolock) on Pergunta.Id = Resposta.IdPergunta
					inner join
				FichaPesquisa with (nolock) on FichaPesquisa.id = RespostaFichaPesquisa.IdFichaPesquisa
					inner join
				@TableAlteracoes temp on temp.RespostaFichaPesquisaRespostaId = RespostaFichaPesquisaResposta.Id

			print 'END - select e insert na tabela temporária  - ' + convert(varchar(200) ,CAST((dbo.GetDateCustom() - @dtInicio) as time(0)))
			set @dtInicio = dbo.GetDateCustom()

			if (ISNULL((Select top 1 Tab.RespostaFichaPesquisaRespostaId from #TabTemp Tab),0) > 0)
				begin
					-- Deleta todos os registros do tabelão para conta sistemas desativadas
					-- Só irá deletar quando tiver refazendo todo o tabelão
					if (@GerarTudo = 1)
						begin
							-- Exclui Todos os registros das conta sistema desabilitadas			
							-- Delete TabelaoAtendimento

							-- deleta todos os registros da tabela
							TRUNCATE TABLE TabelaoFichaPesquisaResposta
		
							-- Desliga as constraints
							ALTER TABLE TabelaoFichaPesquisaResposta NOCHECK CONSTRAINT ALL
			
							-- Desliga os índices
							ALTER INDEX All ON TabelaoFichaPesquisaResposta DISABLE
		
							-- Recria e habilita apenas o índice do id pois se n ocorre erro no insert
							ALTER INDEX PK_TABELAOFICHAPESQUISARESPOST ON TabelaoFichaPesquisaResposta REBUILD

						end

					if (@GerarTudo = 0)
						begin
							---- Deleta os registros do tabelão que estão contidos na tabela acima
							delete
								TabelaoFichaPesquisaResposta 
							from
								TabelaoFichaPesquisaResposta with (nolock) 
									inner join 
								@TableAlteracoes temp on temp.RespostaFichaPesquisaRespostaId = TabelaoFichaPesquisaResposta.RespostaFichaPesquisaRespostaId
						end

					print 'END - deletando registros tabelão - ' + convert(varchar(200) ,CAST((dbo.GetDateCustom() - @dtInicio) as time(0)))
					set @dtInicio = dbo.GetDateCustom()

					set @iCount = (Select count(TabAux.RespostaFichaPesquisaRespostaId) from #TabTemp TabAux);
					declare @i int = 1;
			
					WHILE @i <= @iCount 
						BEGIN 
							BEGIN TRANSACTION TRAN_LOOPINSERCAO

								set @dtInicioAux = dbo.GetDateCustom()

								-- Insere os registros do tabelão
								Insert into TabelaoFichaPesquisaResposta
								(
									DtInclusao,
									RespostaFichaPesquisaRespostaId,
									IdContaSistema,
									IdUsuarioContaSistemaRespondido,
									IdAtendimento,
									FichaPesquisaId,
									FichaPesquisaNome,
									FichaPesquisaDescricao,
									PerguntaId,
									PerguntaDescricao,
									PerguntaTipo,
									PerguntaObrigatorio,
									RespostaDescricao,
									RespostaPeso,
									RespostaDtRespondido,
									RespostaFichaPesquisaFichaPesquisaTipo
								)		

								Select 
									DtInclusao,
									RespostaFichaPesquisaRespostaId,
									IdContaSistema,
									IdUsuarioContaSistemaRespondido,
									IdAtendimento,

									FichaPesquisaId,
									FichaPesquisaNome,
									FichaPesquisaDescricao,

									PerguntaId,
									PerguntaDescricao,
									PerguntaTipo,
									PerguntaObrigatorio,

									RespostaDescricao,
									RespostaPeso,
									RespostaDtRespondido,
									RespostaFichaPesquisaFichaPesquisaTipo

								From
									#TabTemp TabTemp
								where
									TabTemp.rownumber between @i and @i + @iQtdPorTransaction

								print 'insert ('+convert(varchar(200),@i)+') até ('+convert(varchar(200),(@i + @iQtdPorTransaction))+') - '+ convert(varchar(200) ,CAST((dbo.GetDateCustom() - @dtInicioAux) as time(0)))
								set @i = @i + @iQtdPorTransaction + 1

							COMMIT TRANSACTION TRAN_LOOPINSERCAO

						-- End do While
						END
					print 'END - insert no tabelão - ' + convert(varchar(200) ,CAST((dbo.GetDateCustom() - @dtInicio) as time(0)))
					set @dtInicio = dbo.GetDateCustom()

				end

		end
		 

		Update 
			TabelaoLog 
		Set
			-- Adiciona 2 milesegundo desde a última execução para considerar todos atualizados desde a última atualização
			-- 2 pq é o mínimo que pode adicionar
			TabelaoLog.Data1 = @dtReferenciaUtilizarMaximo,
			TabelaoLog.Data2 = null,
			TabelaoLog.bit1 = @GerarTudo,
			TabelaoLog.DtUltimaParcial = case when @GerarTudo = 0 then dbo.GetDateCustom() else TabelaoLog.DtUltimaParcial end,
			TabelaoLog.DtUltimaCompleta = case when @GerarTudo = 1 then dbo.GetDateCustom() else TabelaoLog.DtUltimaCompleta end
		where
			TabelaoLog.Nome = @BatchNome


	if (@GerarTudo = 1)
		begin
			-- Liga as constraints
			ALTER TABLE TabelaoFichaPesquisaResposta CHECK CONSTRAINT ALL
			
			-- Liga e Reconstroi os índices
			ALTER INDEX ALL ON TabelaoFichaPesquisaResposta REBUILD PARTITION = ALL WITH (ONLINE = ON)
		end;

CREATE procedure [dbo].[ProcGerarTabelaoInteracaoResumo] 
(
	@DataReferencia datetime,
	@GerarTudo bit
)
as

	-- comentar
	-- return

	SET NOCOUNT ON

	exec ProcGerarTabelaoInteracaoResumoV1 @DataReferencia, @GerarTudo
		
	return

	DECLARE @TableAlteracoes TABLE
	(
	  InteracaoId int,
	  SuperEntidadeId int,
	  rownumber int
	);

	declare @dtnow datetime = dbo.getDateCustom()
	declare @dtConsiderarInteracao datetime = DATEADD(MONTH, -4, dbo.getDateCustom())
	declare @dtnowConsiderar datetime = dbo.GetDateCustomMinorDay()
	declare @iCount int = 0
	declare @iQtdPorTransaction int = 100000
	declare @isExecute bit = 1
	declare @dtReferenciaUtilizarMinimo as datetime
	declare @dtReferenciaUtilizarMaximo datetime = @dtnow
	declare @dtUltimaAtualizacao datetime
	declare @dtInicioGeral datetime = @dtnow
	declare @dtInicio datetime = @dtnow
	declare @dtInicioAux datetime
	declare @qtdAtendimentos int = 0

	declare @BatchNome varchar(1000) = 'Batch_TabelaoInteracaoResumo'

	-- É necessário atualizar as datas = null para que caso estejam o sistema consiga comparar as datas
	update superentidade set DtAtualizacaoAuto = dbo.GetDateCustom() where DtAtualizacaoAuto is null 

	-- Retorna a data que começou a última atualização
	select @dtUltimaAtualizacao = Max(TabelaoLog.Data2) from TabelaoLog with (nolock) where TabelaoLog.Nome = @BatchNome group by TabelaoLog.Nome

	-- Se o processamento atual não for de gerar tudo e a data não for nula
	-- Subentende-se que no momento está sendo atualizado e não deve rodar 2 atualizações ao mesmo tempo
	-- testará tb se faz mais de 360 minutos que a ultima query executou nesse caso irá considerar que hove erro e executará 
	-- zerando a hora para não ter problemas
	if (@GerarTudo = 0 and @dtUltimaAtualizacao is not null and DATEDIFF(MI, @dtUltimaAtualizacao, dbo.GetDateCustom()) < 360)
		begin
			return
		end
	--else
	--	begin
	--		update TabelaoLog set TabelaoLog.Data2 = dbo.GetDateCustom(),  TabelaoLog.bit1 = @GerarTudo where TabelaoLog.Nome = @BatchNome
	--	end

	if @GerarTudo = 1
		begin
			insert into @TableAlteracoes
			Select 
				Interacao.id as InteracaoId,
				Interacao.IdSuperEntidade as SuperEntidadeId,
				ROW_NUMBER() OVER(ORDER BY Interacao.id ASC) AS RowNumber
			From 
				Interacao with (nolock)
					inner join
				InteracaoTipo with (nolock) on Interacao.IdInteracaoTipo = InteracaoTipo.Id

			where
				(
					Interacao.DtInclusao >= @dtConsiderarInteracao
						or
					Interacao.DtInteracao >= @dtConsiderarInteracao
						or
					Interacao.DtConclusao >= @dtConsiderarInteracao
				)
					and
				(
					InteracaoTipo.Tipo in (
											'NOTA',
											'WHATSAPP',
											'EMAILENVIADO',
											'LIGACAO',
											'SOLICITACAOATENDIMENTO',
											'EMAILRECEBIDO',
											'ATENDIMENTOATENDIDO',
											'ATENDIMENTOCRIADO',
											'NEGOCIACAOSIMULACAO',
											'NEGOCIACAOPROPOSTA',
											'NEGOCIACAOVENDA',
											'ATENDIMENTOTRANSFERIDO',
											'ATENDIMENTOENCERRADO')

						or 
					InteracaoTipo.Tipo is null
				)
		end
	else
		begin

			insert into @TableAlteracoes
			Select top 20000
				Interacao.id as InteracaoId,
				Interacao.IdSuperEntidade as SuperEntidadeId,
				ROW_NUMBER() OVER(ORDER BY Interacao.id ASC) AS RowNumber
			From 
				-- força a utilização do índice já que o mesmo não está utilizando
				-- consertar
				Interacao WITH (nolock)
					inner join
				InteracaoTipo with (nolock) on Interacao.IdInteracaoTipo = InteracaoTipo.Id

			where
				(
					Interacao.DtInclusao >= @dtConsiderarInteracao
						or
					Interacao.DtInteracao >= @dtConsiderarInteracao
						or
					Interacao.DtConclusao >= @dtConsiderarInteracao
				)
					and
				(
					InteracaoTipo.Tipo in (
											'NOTA',
											'WHATSAPP',
											'EMAILENVIADO',
											'LIGACAO',
											'SOLICITACAOATENDIMENTO',
											'EMAILRECEBIDO',
											'ATENDIMENTOATENDIDO',
											'ATENDIMENTOCRIADO',
											'NEGOCIACAOSIMULACAO',
											'NEGOCIACAOPROPOSTA',
											'NEGOCIACAOVENDA',
											'ATENDIMENTOTRANSFERIDO',
											'ATENDIMENTOENCERRADO')

						or 
					InteracaoTipo.Tipo is null
				)
					and
				not exists	(
													Select 
														TabelaoInteracaoResumo.IdInteracao
													from
														TabelaoInteracaoResumo with (nolock)
													where
														TabelaoInteracaoResumo.IdInteracao = Interacao.Id and 
														TabelaoInteracaoResumo.versionIntercao = Interacao.versao
												)

		end
	print 'END - select e insert dos ids - ' + convert(varchar(200) ,CAST((dbo.GetDateCustom() - @dtInicio) as time(0)))
	set @dtInicio = dbo.GetDateCustom()

	-- conta a quantidade de atendimentos que será atualizado
	set @qtdAtendimentos = isnull((select count(distinct Tab1.SuperEntidadeId) from @TableAlteracoes Tab1),0)

	-- Caso não exista registro irá retornar para evitar processamento
	if @qtdAtendimentos = 0
		begin 
			set @isExecute = 0
		end

	if @isExecute = 1
		begin	
			-- insere os registros em uma tabela temporária
			select 
				temp.rownumber,

				Atendimento.idContaSistema as IdContaSistema,
				Atendimento.Id as IdAtendimento,
				Atendimento.IdPessoaProspect as IdPessoaProspect,
				Interacao.Id as IdInteracao,

				CONVERT(date,Interacao.DtInteracao) as DtInteracao,
				Interacao.DtInteracao as DtInteracaoFull,
				CONVERT(date,Interacao.DtInclusao) as DtInteracaoInclusao,
				Interacao.DtInclusao as DtInteracaoInclusaoFull,
				CONVERT(date,Interacao.DtConclusao) as DtInteracaoConclusao,
				Interacao.DtConclusao as DtInteracaoConclusaoFull,

				CASE
					WHEN Interacao.Realizado = 1 then 'SIM'
					ELSE 'NÃO'
				END AS InteracaoRealizado,

				Interacao.idInteracaoTipo as IdInteracaoTipo,
				InteracaoTipo.Valor as InteracaoTipoValor,
				InteracaoTipo.ValorAbreviado as InteracaoTipoValorAbreviado,
				@dtReferenciaUtilizarMaximo as DtInclusao,
				Interacao.InteracaoAtorPartida,
				case 
					when DATEPART(hh, Interacao.DtInclusao) >= 0 and DATEPART(hh, Interacao.DtInclusao) <= 13 then 'MANHÃ' 
					when DATEPART(hh, Interacao.DtInclusao) >= 14 and DATEPART(hh, Interacao.DtInclusao) <= 24 then 'TARDE'
				END AS Periodo,

				InteracaoMarketing.IdMidia,
				InteracaoMarketing.IdPeca,
				InteracaoMarketing.IdIntegradoraExterna,
				InteracaoMarketing.IdIntegradoraExternaAgencia,
				InteracaoMarketing.IdGrupoPecaMarketing,
				InteracaoMarketing.IdCampanhaMarketing,
				Interacao.IdCanal,
				Midia.Nome as StrMidia,
				Peca.Nome as StrPeca,
				IntegradoraExterna.Nome as StrIntegradoraExterna,
				IntegradoraExternaAgencia.Nome as StrIntegradoraExternaAgencia,
				GrupoPecaMarketing.Nome as StrGrupoPecaMarketing,
				CampanhaMarketing.Nome as StrCampanhaMarketing,
				Canal.Nome as StrCanal,
				Produto.id as IdProduto,
				Produto.Nome as StrProdutoNome,

				alarme.Data as AlarmeDt,
				Alarme.DataUltimoStatus as AlarmeDtUltimoStatus,
				Alarme.Status as AlarmeStatus,
				Alarme.Realizado as AlarmeRealizado,

				Interacao.IdUsuarioContaSistemaRealizou as UsuarioContaSistemaRealizouId,
				Interacao.IdUsuarioContaSistema as UsuarioContaSistemaIncluiuId,
				UsuarioContaSistemaRealizou.PessoaNome as UsuarioContaSistemaRealizouNome,
				UsuarioContaSistemaIncluiu.PessoaNome as UsuarioContaSistemaIncluiuNome,
				UsuarioContaSistemaRealizou.PessoaEmail as UsuarioContaSistemaRealizouEmail,
				UsuarioContaSistemaIncluiu.PessoaEmail as UsuarioContaSistemaIncluiuEmail,
				UsuarioContaSistemaRealizou.PessoaApelido as UsuarioContaSistemaRealizouApelido,
				UsuarioContaSistemaIncluiu.PessoaApelido as UsuarioContaSistemaIncluiuApelido,

				SuperEntidade.DtAtualizacaoAuto as SuperEntidadeDtAtualizacaoAuto,

				CONVERT(binary(8), Interacao.versao) as versionIntercao,
				CONVERT(binary(8), Atendimento.versao) as versionAtendimento
				
				into #TabAtendimentoTemp
			from 
				Interacao 
					inner join
				@TableAlteracoes temp on temp.InteracaoId = Interacao.Id
					inner join
				SuperEntidade WITH (NOLOCK) on SuperEntidade.Id = Interacao.IdSuperEntidade 
					inner join
				Atendimento with (nolock) on Atendimento.Id = SuperEntidade.Id
					inner join
				InteracaoTipo WITH (NOLOCK) on Interacao.idInteracaoTipo = InteracaoTipo.id
					left outer join
				InteracaoMarketing WITH (NOLOCK) on InteracaoMarketing.id = Interacao.IdInteracaoMarketing
					left outer join
				Midia WITH (NOLOCK) on Midia.id = InteracaoMarketing.idMidia
					left outer join
				Peca WITH (NOLOCK) on Peca.id = InteracaoMarketing.idPeca
					left outer join
				Canal WITH (NOLOCK) on Canal.id = Interacao.IdCanal
					left outer join
				Produto WITH (NOLOCK) on Produto.id = Interacao.IdProduto
					left outer join
				IntegradoraExterna WITH (NOLOCK) on IntegradoraExterna.id = InteracaoMarketing.IdIntegradoraExterna
					left outer join
				IntegradoraExterna IntegradoraExternaAgencia WITH (NOLOCK) on IntegradoraExternaAgencia.id = InteracaoMarketing.IdIntegradoraExternaAgencia
					left outer join
				GrupoPecaMarketing WITH (NOLOCK) on GrupoPecaMarketing.id = InteracaoMarketing.IdGrupoPecaMarketing
					left outer join
				CampanhaMarketing WITH (NOLOCK) on CampanhaMarketing.id = InteracaoMarketing.IdCampanhaMarketing
					left outer join
				Alarme  WITH (NOLOCK) on Alarme.id = Interacao.IdAlarme
					left outer join
				ViewUsuarioContaSistemaDetalhado UsuarioContaSistemaRealizou WITH (NOLOCK) on UsuarioContaSistemaRealizou.UsuarioContaSistemaId = Interacao.IdUsuarioContaSistemaRealizou
					left outer join
				ViewUsuarioContaSistemaDetalhado UsuarioContaSistemaIncluiu WITH (NOLOCK) on UsuarioContaSistemaIncluiu.UsuarioContaSistemaId = Interacao.IdUsuarioContaSistema
	
			print 'END - select do (Consulta das interações) e insert na tabela temporária  - ' + convert(varchar(200) ,CAST((dbo.GetDateCustom() - @dtInicio) as time(0)))
			set @dtInicio = dbo.GetDateCustom()

			if (ISNULL((Select top 1 Tab.IdInteracao from #TabAtendimentoTemp Tab),0) > 0)
				begin


					if (@GerarTudo = 1)
						begin
							-- deleta todos os registros da tabela
							TRUNCATE TABLE TabelaoInteracaoResumoAux
		
							-- Desliga as constraints
							ALTER TABLE TabelaoInteracaoResumoAux NOCHECK CONSTRAINT ALL
			
							-- Desliga os índices
							ALTER INDEX All ON TabelaoInteracaoResumoAux DISABLE
		
							-- Recria e habilita apenas o índice do id pois se n ocorre erro no insert
							-- Se faz necessário o try catch pois na interação en questão não é possível saber se está usando a tabela atual ou a renomeada
							if exists (SELECT * FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS WHERE CONSTRAINT_NAME = 'PK_TABELAOINTERACAORESUMOAUX' AND TABLE_NAME = 'TabelaoInteracaoResumoAux' AND TABLE_SCHEMA ='dbo')
								begin
									ALTER INDEX PK_TabelaoInteracaoResumoAux ON TabelaoInteracaoResumoAux REBUILD
								end
							else
								begin
									ALTER INDEX PK_TabelaoInteracaoResumo ON TabelaoInteracaoResumoAux REBUILD
								end

						end
					else
						begin
							---- Deleta os registros do tabelão que estão contidos na tabela acima
							with cte as 
							(
								select 
									TabelaoInteracaoResumo.IdInteracao
								from 
									TabelaoInteracaoResumo with (nolock) 
								where exists (select temp.InteracaoId from @TableAlteracoes temp where temp.InteracaoId = TabelaoInteracaoResumo.IdInteracao)
							)
							delete from cte
						end

					print 'END - deletando registros tabelão interação - ' + convert(varchar(200) ,CAST((dbo.GetDateCustom() - @dtInicio) as time(0)))
					set @dtInicio = dbo.GetDateCustom()

					set @iCount = (Select count(TabAux.IdAtendimento) from #TabAtendimentoTemp TabAux);
					declare @i int = 1;

				
					WHILE @i <= @iCount 
						BEGIN

								set @dtInicioAux = dbo.GetDateCustom()


								if (@GerarTudo = 0)
									begin
										-- Irá selecionar e inserir todos os registros em uma tabela temporária
										-- para depois então excluir os registros do tabelão atendimento 
										-- e os inserir, se faz necessário para quando estiver gerando ã tabela ficar o menor tempo possível 
										-- com lock
										Insert into TabelaoInteracaoResumo
										(
											id,
											IdContaSistema,
											IdAtendimento,
											IdPessoaProspect,
											IdInteracao,

											DtInteracao,
											DtInteracaoFull,
											DtInteracaoInclusao,
											DtInteracaoInclusaoFull,
											DtInteracaoConclusao,
											DtInteracaoConclusaoFull,

											InteracaoRealizado,

											IdInteracaoTipo,
											InteracaoTipoValor,
											InteracaoTipoValorAbreviado,
											DtInclusao,
											InteracaoAtorPartida,
											Periodo,

											IdMidia,
											IdPeca,
											IdIntegradoraExterna,
											IdIntegradoraExternaAgencia,
											IdGrupoPecaMarketing,
											IdCampanhaMarketing,
											IdCanal,
											StrMidia,
											StrPeca,
											StrIntegradoraExterna,
											StrIntegradoraExternaAgencia,
											StrGrupoPecaMarketing,
											StrCampanhaMarketing,
											StrCanal,
											IdProduto,
											StrProdutoNome,

											AlarmeDt,
											AlarmeDtUltimoStatus,
											AlarmeStatus,
											AlarmeRealizado,

											UsuarioContaSistemaRealizouId,
											UsuarioContaSistemaIncluiuId,
											UsuarioContaSistemaRealizouNome,
											UsuarioContaSistemaIncluiuNome,
											UsuarioContaSistemaRealizouEmail,
											UsuarioContaSistemaIncluiuEmail,
											UsuarioContaSistemaRealizouApelido,
											UsuarioContaSistemaIncluiuApelido,

											DtAtualizacaoAuto,
												
											versionIntercao,
											versionAtendimento
										)		

										select 
											TabAtendimentoTemp.IdInteracao,	
											TabAtendimentoTemp.IdContaSistema,
											TabAtendimentoTemp.IdAtendimento,
											TabAtendimentoTemp.IdPessoaProspect,
											TabAtendimentoTemp.IdInteracao,

											TabAtendimentoTemp.DtInteracao,
											TabAtendimentoTemp.DtInteracaoFull,
											TabAtendimentoTemp.DtInteracaoInclusao,
											TabAtendimentoTemp.DtInteracaoInclusaoFull,
											TabAtendimentoTemp.DtInteracaoConclusao,
											TabAtendimentoTemp.DtInteracaoConclusaoFull,

											TabAtendimentoTemp.InteracaoRealizado,

											TabAtendimentoTemp.IdInteracaoTipo,
											TabAtendimentoTemp.InteracaoTipoValor,
											TabAtendimentoTemp.InteracaoTipoValorAbreviado,
											TabAtendimentoTemp.DtInclusao,
											TabAtendimentoTemp.InteracaoAtorPartida,
											TabAtendimentoTemp.Periodo,

											TabAtendimentoTemp.IdMidia,
											TabAtendimentoTemp.IdPeca,
											TabAtendimentoTemp.IdIntegradoraExterna,
											TabAtendimentoTemp.IdIntegradoraExternaAgencia,
											TabAtendimentoTemp.IdGrupoPecaMarketing,
											TabAtendimentoTemp.IdCampanhaMarketing,
											TabAtendimentoTemp.IdCanal,
											TabAtendimentoTemp.StrMidia,
											TabAtendimentoTemp.StrPeca,
											TabAtendimentoTemp.StrIntegradoraExterna,
											TabAtendimentoTemp.StrIntegradoraExternaAgencia,
											TabAtendimentoTemp.StrGrupoPecaMarketing,
											TabAtendimentoTemp.StrCampanhaMarketing,
											TabAtendimentoTemp.StrCanal,
											TabAtendimentoTemp.IdProduto,
											TabAtendimentoTemp.StrProdutoNome,

											TabAtendimentoTemp.AlarmeDt,
											TabAtendimentoTemp.AlarmeDtUltimoStatus,
											TabAtendimentoTemp.AlarmeStatus,
											TabAtendimentoTemp.AlarmeRealizado,

											TabAtendimentoTemp.UsuarioContaSistemaRealizouId,
											TabAtendimentoTemp.UsuarioContaSistemaIncluiuId,
											TabAtendimentoTemp. UsuarioContaSistemaRealizouNome,
											TabAtendimentoTemp.UsuarioContaSistemaIncluiuNome,
											TabAtendimentoTemp. UsuarioContaSistemaRealizouEmail,
											TabAtendimentoTemp.UsuarioContaSistemaIncluiuEmail,
											TabAtendimentoTemp. UsuarioContaSistemaRealizouApelido,
											TabAtendimentoTemp.UsuarioContaSistemaIncluiuApelido,
												
											TabAtendimentoTemp.SuperEntidadeDtAtualizacaoAuto,
												
											TabAtendimentoTemp.versionIntercao,
											TabAtendimentoTemp.versionAtendimento	

										from 
											#TabAtendimentoTemp TabAtendimentoTemp

										where
											TabAtendimentoTemp.rownumber between @i and @i + @iQtdPorTransaction
									end
								else
									begin
										-- Irá selecionar e inserir todos os registros em uma tabela temporária
										-- para depois então excluir os registros do tabelão atendimento 
										-- e os inserir, se faz necessário para quando estiver gerando ã tabela ficar o menor tempo possível 
										-- com lock
										Insert into TabelaoInteracaoResumoAux
										(
											id,
											IdContaSistema,
											IdAtendimento,
											IdPessoaProspect,
											IdInteracao,

											DtInteracao,
											DtInteracaoFull,
											DtInteracaoInclusao,
											DtInteracaoInclusaoFull,
											DtInteracaoConclusao,
											DtInteracaoConclusaoFull,

											InteracaoRealizado,

											IdInteracaoTipo,
											InteracaoTipoValor,
											InteracaoTipoValorAbreviado,
											DtInclusao,
											InteracaoAtorPartida,
											Periodo,

											IdMidia,
											IdPeca,
											IdIntegradoraExterna,
											IdIntegradoraExternaAgencia,
											IdGrupoPecaMarketing,
											IdCampanhaMarketing,
											IdCanal,
											StrMidia,
											StrPeca,
											StrIntegradoraExterna,
											StrIntegradoraExternaAgencia,
											StrGrupoPecaMarketing,
											StrCampanhaMarketing,
											StrCanal,
											IdProduto,
											StrProdutoNome,

											AlarmeDt,
											AlarmeDtUltimoStatus,
											AlarmeStatus,
											AlarmeRealizado,

											UsuarioContaSistemaRealizouId,
											UsuarioContaSistemaIncluiuId,
											UsuarioContaSistemaRealizouNome,
											UsuarioContaSistemaIncluiuNome,
											UsuarioContaSistemaRealizouEmail,
											UsuarioContaSistemaIncluiuEmail,
											UsuarioContaSistemaRealizouApelido,
											UsuarioContaSistemaIncluiuApelido,

											DtAtualizacaoAuto,

											versionIntercao,
											versionAtendimento
										)		

										select 
											TabAtendimentoTemp.IdInteracao,	
											TabAtendimentoTemp.IdContaSistema,
											TabAtendimentoTemp.IdAtendimento,
											TabAtendimentoTemp.IdPessoaProspect,
											TabAtendimentoTemp.IdInteracao,

											TabAtendimentoTemp.DtInteracao,
											TabAtendimentoTemp.DtInteracaoFull,
											TabAtendimentoTemp.DtInteracaoInclusao,
											TabAtendimentoTemp.DtInteracaoInclusaoFull,
											TabAtendimentoTemp.DtInteracaoConclusao,
											TabAtendimentoTemp.DtInteracaoConclusaoFull,

											TabAtendimentoTemp.InteracaoRealizado,

											TabAtendimentoTemp.IdInteracaoTipo,
											TabAtendimentoTemp.InteracaoTipoValor,
											TabAtendimentoTemp.InteracaoTipoValorAbreviado,
											TabAtendimentoTemp.DtInclusao,
											TabAtendimentoTemp.InteracaoAtorPartida,
											TabAtendimentoTemp.Periodo,

											TabAtendimentoTemp.IdMidia,
											TabAtendimentoTemp.IdPeca,
											TabAtendimentoTemp.IdIntegradoraExterna,
											TabAtendimentoTemp.IdIntegradoraExternaAgencia,
											TabAtendimentoTemp.IdGrupoPecaMarketing,
											TabAtendimentoTemp.IdCampanhaMarketing,
											TabAtendimentoTemp.IdCanal,
											TabAtendimentoTemp.StrMidia,
											TabAtendimentoTemp.StrPeca,
											TabAtendimentoTemp.StrIntegradoraExterna,
											TabAtendimentoTemp.StrIntegradoraExternaAgencia,
											TabAtendimentoTemp.StrGrupoPecaMarketing,
											TabAtendimentoTemp.StrCampanhaMarketing,
											TabAtendimentoTemp.StrCanal,
											TabAtendimentoTemp.IdProduto,
											TabAtendimentoTemp.StrProdutoNome,

											TabAtendimentoTemp.AlarmeDt,
											TabAtendimentoTemp.AlarmeDtUltimoStatus,
											TabAtendimentoTemp.AlarmeStatus,
											TabAtendimentoTemp.AlarmeRealizado,

											TabAtendimentoTemp.UsuarioContaSistemaRealizouId,
											TabAtendimentoTemp.UsuarioContaSistemaIncluiuId,
											TabAtendimentoTemp. UsuarioContaSistemaRealizouNome,
											TabAtendimentoTemp.UsuarioContaSistemaIncluiuNome,
											TabAtendimentoTemp. UsuarioContaSistemaRealizouEmail,
											TabAtendimentoTemp.UsuarioContaSistemaIncluiuEmail,
											TabAtendimentoTemp. UsuarioContaSistemaRealizouApelido,
											TabAtendimentoTemp.UsuarioContaSistemaIncluiuApelido,
								
											TabAtendimentoTemp.SuperEntidadeDtAtualizacaoAuto,
												
											TabAtendimentoTemp.versionIntercao,
											TabAtendimentoTemp.versionAtendimento
													
										from 
											#TabAtendimentoTemp TabAtendimentoTemp

										where
											TabAtendimentoTemp.rownumber between @i and @i + @iQtdPorTransaction
									end

								print 'insert ('+convert(varchar(200),@i)+') até ('+convert(varchar(200),(@i + @iQtdPorTransaction))+') - '+ convert(varchar(200) ,CAST((dbo.GetDateCustom() - @dtInicioAux) as time(0)))
								set @i = @i + @iQtdPorTransaction + 1
								
						-- End do While
						END
					print 'END - insert no tabelão interação - ' + convert(varchar(200) ,CAST((dbo.GetDateCustom() - @dtInicio) as time(0)))
					set @dtInicio = dbo.GetDateCustom()


				end
		end

	if (@isExecute = 1 and @GerarTudo = 1)
		begin
			begin
				-- Liga e Reconstroi os índices
				-- Liga e Reconstroi os índices
				-- ONLINE = ON, permite o acesso ao dados sem bloqueio a tabela mas é mais demorado
				-- como a tabela é exclusiva setarei OFF nessa operação
				ALTER INDEX ALL ON TabelaoInteracaoResumoAux REBUILD PARTITION = ALL WITH (ONLINE = ON)
			end
		end

	print 'END - geração dos índices - ' + convert(varchar(200) ,CAST((dbo.GetDateCustom() - @dtInicio) as time(0)))
	set @dtInicio = dbo.GetDateCustom()

	if (@isExecute = 1 and @GerarTudo = 1)
		begin
			UPDATE STATISTICS TabelaoInteracaoResumoAux

			EXEC sp_rename 'TabelaoInteracaoResumo', 'TabelaoInteracaoResumoAuxOld2';
			EXEC sp_rename 'TabelaoInteracaoResumoAux', 'TabelaoInteracaoResumo'; 
			EXEC sp_rename 'TabelaoInteracaoResumoAuxOld2', 'TabelaoInteracaoResumoAux';
		
		end

	print 'END - sp_rename ' + convert(varchar(200) ,CAST((dbo.GetDateCustom() - @dtInicio) as time(0)))
	set @dtInicio = dbo.GetDateCustom()

	if (@isExecute = 1 and @GerarTudo = 1)
		begin
			truncate table TabelaoInteracaoResumoAux
		end

	Update 
		TabelaoLog 
	Set
		-- Adiciona 2 milesegundo desde a última execução para considerar todos atualizados desde a última atualização
		-- 2 pq é o mínimo que pode adicionar
		TabelaoLog.Data1 = @dtReferenciaUtilizarMaximo,
		TabelaoLog.Data2 = null,
		TabelaoLog.bit1 = @GerarTudo,
		TabelaoLog.DtUltimaParcial = case when @GerarTudo = 0 then dbo.GetDateCustom() else TabelaoLog.DtUltimaParcial end,
		TabelaoLog.DtUltimaCompleta = case when @GerarTudo = 1 then dbo.GetDateCustom() else TabelaoLog.DtUltimaCompleta end
	where
		TabelaoLog.Nome = @BatchNome
	
	
	print 'Total de atendimentos: '+ convert(varchar(45), @qtdAtendimentos) + '. Qtd de interações: '+ convert(varchar(45), @iCount) + ' em ' + convert(varchar(200) ,CAST((dbo.GetDateCustom() - @dtInicioGeral) as time(0)));

CREATE procedure [dbo].[ProcGerarTabelaoInteracaoResumoV1] 
(
	@DataReferencia datetime,
	@GerarTudo bit
)
as
	-- comentar
	-- return

	SET NOCOUNT ON

	DECLARE @TableAlteracoes TABLE
	(
	  InteracaoId int,
	  SuperEntidadeId int,
	  versao varbinary(8)
	);

	declare @dtnow datetime = dbo.getDateCustom()
	declare @dtConsiderarInteracao datetime = DATEADD(MONTH, -4, dbo.getDateCustom())
	declare @dtnowConsiderar datetime = dbo.GetDateCustomMinorDay()
	declare @iCount int = 0
	declare @iQtdPorTransaction int = 100000
	declare @isExecute bit = 1
	declare @dtReferenciaUtilizarMinimo as datetime
	declare @dtReferenciaUtilizarMaximo datetime = @dtnow
	declare @dtUltimaAtualizacao datetime
	declare @dtInicioGeral datetime = @dtnow
	declare @dtInicio datetime = @dtnow
	declare @dtInicioAux datetime
	declare @qtdAtendimentos int = 0
	declare @qtdInteracoes int = 0

	declare @BatchNome varchar(100) = 'Batch_TabelaoInteracaoResumo'

	declare @objJson varchar(max) = (select top 1 TabelaoLog.Obj from TabelaoLog where nome = @BatchNome)
	
	declare @versao timestamp
	declare @interacaoId int

	-- Retorna a data que começou a última atualização
	select @dtUltimaAtualizacao = Max(TabelaoLog.Data2) from TabelaoLog with (nolock) where TabelaoLog.Nome = @BatchNome group by TabelaoLog.Nome

	-- Se o processamento atual não for de gerar tudo e a data não for nula
	-- Subentende-se que no momento está sendo atualizado e não deve rodar 2 atualizações ao mesmo tempo
	-- testará tb se faz mais de 360 minutos que a ultima query executou nesse caso irá considerar que hove erro e executará 
	-- zerando a hora para não ter problemas
	if (@GerarTudo = 0 and @dtUltimaAtualizacao is not null and DATEDIFF(MI, @dtUltimaAtualizacao, dbo.GetDateCustom()) < 360)
		begin
			return
		end
	--else
	--	begin
	--		update TabelaoLog set TabelaoLog.Data2 = dbo.GetDateCustom(),  TabelaoLog.bit1 = @GerarTudo where TabelaoLog.Nome = @BatchNome
	--	end

	if @GerarTudo = 1
		begin
			insert into @TableAlteracoes
			Select 
				distinct(Interacao.id) as InteracaoId,
				Interacao.IdSuperEntidade as SuperEntidadeId,
				Interacao.versao as versao
			From 
				Interacao with (nolock)
					inner join
				InteracaoTipo with (nolock) on Interacao.IdInteracaoTipo = InteracaoTipo.Id

			where
				(
					Interacao.DtInclusao >= @dtConsiderarInteracao
						or
					Interacao.DtInteracao >= @dtConsiderarInteracao
						or
					Interacao.DtConclusao >= @dtConsiderarInteracao
				)
					and
				(
					InteracaoTipo.Tipo in (
											'NOTA',
											'WHATSAPP',
											'EMAILENVIADO',
											'LIGACAO',
											'SOLICITACAOATENDIMENTO',
											'EMAILRECEBIDO',
											'ATENDIMENTOATENDIDO',
											'ATENDIMENTOCRIADO',
											'NEGOCIACAOSIMULACAO',
											'NEGOCIACAOPROPOSTA',
											'NEGOCIACAOVENDA',
											'ATENDIMENTOTRANSFERIDO',
											'ATENDIMENTOENCERRADO')

						or 
					InteracaoTipo.Tipo is null
				)

				OPTION (RECOMPILE)
		end
	else
		begin
			set @versao = convert(varbinary(8), sys.fn_cdc_hexstrtobin(JSON_VALUE(@objJson, '$.parcialVersao')))
			set @interacaoId = JSON_VALUE(@objJson, '$.parcialInteracaoId')

			insert into @TableAlteracoes
			Select top 3000
				Interacao.id as InteracaoId,
				Interacao.IdSuperEntidade as SuperEntidadeId,
				Interacao.versao as versao
			From 
				-- força a utilização do índice já que o mesmo não está utilizando
				-- consertar
				Interacao WITH (nolock)
					inner join
				InteracaoTipo with (nolock) on Interacao.IdInteracaoTipo = InteracaoTipo.Id

			where
				(
					(
						Interacao.versao = @versao
							and
						Interacao.Id > @interacaoId
					)
						or
					Interacao.versao > @versao
				)
					and
				(
					InteracaoTipo.Tipo in (
											'NOTA',
											'WHATSAPP',
											'EMAILENVIADO',
											'LIGACAO',
											'SOLICITACAOATENDIMENTO',
											'EMAILRECEBIDO',
											'ATENDIMENTOATENDIDO',
											'ATENDIMENTOCRIADO',
											'NEGOCIACAOSIMULACAO',
											'NEGOCIACAOPROPOSTA',
											'NEGOCIACAOVENDA',
											'ATENDIMENTOTRANSFERIDO',
											'ATENDIMENTOENCERRADO')

						or 
					InteracaoTipo.Tipo is null
				)
			order by
				Versao asc,
				Interacao.Id asc

			OPTION (RECOMPILE)

		end

	-- conta a quantidade de atendimentos que será atualizado
	set @qtdAtendimentos = isnull((select count(distinct Tab1.SuperEntidadeId) from @TableAlteracoes Tab1),0)

		-- conta a quantidade de atendimentos que será atualizado
	set @qtdInteracoes = isnull((select count(distinct Tab1.InteracaoId) from @TableAlteracoes Tab1),0)


	print 'END - select e insert dos ids - ' + convert(varchar(200) ,CAST((dbo.GetDateCustom() - @dtInicio) as time(0))) + ', qtd atendimentos: ' + convert(varchar(30), @qtdAtendimentos) + ', qtd interacoes: ' + convert(varchar(30), @qtdInteracoes)
	set @dtInicio = dbo.GetDateCustom()


	-- Caso não exista registro irá retornar para evitar processamento
	if @qtdAtendimentos = 0
		begin 
			set @isExecute = 0
		end

	if @isExecute = 1
		begin	
			-- insere os registros em uma tabela temporária
			select 
				Interacao.idContaSistema as IdContaSistema,
				Interacao.IdSuperEntidade as IdAtendimento,
				Atendimento.IdPessoaProspect as IdPessoaProspect,
				Interacao.Id as IdInteracao,

				CONVERT(date,Interacao.DtInteracao) as DtInteracao,
				Interacao.DtInteracao as DtInteracaoFull,
				CONVERT(date,Interacao.DtInclusao) as DtInteracaoInclusao,
				Interacao.DtInclusao as DtInteracaoInclusaoFull,
				CONVERT(date,Interacao.DtConclusao) as DtInteracaoConclusao,
				Interacao.DtConclusao as DtInteracaoConclusaoFull,

				CASE
					WHEN Interacao.Realizado = 1 then 'SIM'
					ELSE 'NÃO'
				END AS InteracaoRealizado,

				Interacao.idInteracaoTipo as IdInteracaoTipo,
				InteracaoTipo.Valor as InteracaoTipoValor,
				InteracaoTipo.ValorAbreviado as InteracaoTipoValorAbreviado,
				@dtReferenciaUtilizarMaximo as DtInclusao,
				Interacao.InteracaoAtorPartida,
				case 
					when DATEPART(hh, Interacao.DtInclusao) >= 0 and DATEPART(hh, Interacao.DtInclusao) <= 13 then 'MANHÃ' 
					when DATEPART(hh, Interacao.DtInclusao) >= 14 and DATEPART(hh, Interacao.DtInclusao) <= 24 then 'TARDE'
				END AS Periodo,

				InteracaoMarketing.IdMidia,
				InteracaoMarketing.IdPeca,
				InteracaoMarketing.IdIntegradoraExterna,
				InteracaoMarketing.IdIntegradoraExternaAgencia,
				InteracaoMarketing.IdGrupoPecaMarketing,
				InteracaoMarketing.IdCampanhaMarketing,
				Interacao.IdCanal,
				Midia.Nome as StrMidia,
				Peca.Nome as StrPeca,
				IntegradoraExterna.Nome as StrIntegradoraExterna,
				IntegradoraExternaAgencia.Nome as StrIntegradoraExternaAgencia,
				GrupoPecaMarketing.Nome as StrGrupoPecaMarketing,
				CampanhaMarketing.Nome as StrCampanhaMarketing,
				Canal.Nome as StrCanal,
				Produto.id as IdProduto,
				Produto.Nome as StrProdutoNome,

				alarme.Data as AlarmeDt,
				Alarme.DataUltimoStatus as AlarmeDtUltimoStatus,
				Alarme.Status as AlarmeStatus,
				Alarme.Realizado as AlarmeRealizado,

				Interacao.IdUsuarioContaSistemaRealizou as UsuarioContaSistemaRealizouId,
				Interacao.IdUsuarioContaSistema as UsuarioContaSistemaIncluiuId,
				UsuarioContaSistemaRealizou.PessoaNome as UsuarioContaSistemaRealizouNome,
				UsuarioContaSistemaIncluiu.PessoaNome as UsuarioContaSistemaIncluiuNome,
				UsuarioContaSistemaRealizou.PessoaEmail as UsuarioContaSistemaRealizouEmail,
				UsuarioContaSistemaIncluiu.PessoaEmail as UsuarioContaSistemaIncluiuEmail,
				UsuarioContaSistemaRealizou.PessoaApelido as UsuarioContaSistemaRealizouApelido,
				UsuarioContaSistemaIncluiu.PessoaApelido as UsuarioContaSistemaIncluiuApelido,

				SuperEntidade.DtAtualizacaoAuto as SuperEntidadeDtAtualizacaoAuto,

				CONVERT(binary(8), Interacao.versao) as versionIntercao,
				CONVERT(binary(8), Atendimento.versao) as versionAtendimento
				
				into #TabAtendimentoTemp
			from 
				Interacao 
					inner join
				@TableAlteracoes temp on temp.InteracaoId = Interacao.Id
					inner join
				SuperEntidade WITH (NOLOCK) on SuperEntidade.Id = Interacao.IdSuperEntidade 
					inner join
				Atendimento with (nolock) on Atendimento.Id = SuperEntidade.Id
					inner join
				InteracaoTipo WITH (NOLOCK) on Interacao.idInteracaoTipo = InteracaoTipo.id
					left outer join
				InteracaoMarketing WITH (NOLOCK) on InteracaoMarketing.id = Interacao.IdInteracaoMarketing
					left outer join
				Midia WITH (NOLOCK) on Midia.id = InteracaoMarketing.idMidia
					left outer join
				Peca WITH (NOLOCK) on Peca.id = InteracaoMarketing.idPeca
					left outer join
				Canal WITH (NOLOCK) on Canal.id = Interacao.IdCanal
					left outer join
				Produto WITH (NOLOCK) on Produto.id = Interacao.IdProduto
					left outer join
				IntegradoraExterna WITH (NOLOCK) on IntegradoraExterna.id = InteracaoMarketing.IdIntegradoraExterna
					left outer join
				IntegradoraExterna IntegradoraExternaAgencia WITH (NOLOCK) on IntegradoraExternaAgencia.id = InteracaoMarketing.IdIntegradoraExternaAgencia
					left outer join
				GrupoPecaMarketing WITH (NOLOCK) on GrupoPecaMarketing.id = InteracaoMarketing.IdGrupoPecaMarketing
					left outer join
				CampanhaMarketing WITH (NOLOCK) on CampanhaMarketing.id = InteracaoMarketing.IdCampanhaMarketing
					left outer join
				Alarme  WITH (NOLOCK) on Alarme.id = Interacao.IdAlarme
					left outer join
				ViewUsuarioContaSistemaDetalhado UsuarioContaSistemaRealizou WITH (NOLOCK) on UsuarioContaSistemaRealizou.UsuarioContaSistemaId = Interacao.IdUsuarioContaSistemaRealizou
					left outer join
				ViewUsuarioContaSistemaDetalhado UsuarioContaSistemaIncluiu WITH (NOLOCK) on UsuarioContaSistemaIncluiu.UsuarioContaSistemaId = Interacao.IdUsuarioContaSistema
	
			print 'END - select do (Consulta das interações) e insert na tabela temporária  - ' + convert(varchar(200) ,CAST((dbo.GetDateCustom() - @dtInicio) as time(0)))
			set @dtInicio = dbo.GetDateCustom()

			if (ISNULL((Select top 1 Tab.IdInteracao from #TabAtendimentoTemp Tab),0) > 0)
				begin

					if (@GerarTudo = 1)
						begin
							-- deleta todos os registros da tabela
							TRUNCATE TABLE TabelaoInteracaoResumoAux
		
							-- Desliga as constraints
							ALTER TABLE TabelaoInteracaoResumoAux NOCHECK CONSTRAINT ALL
			
							-- Desliga os índices
							ALTER INDEX All ON TabelaoInteracaoResumoAux DISABLE
		
							-- Recria e habilita apenas o índice do id pois se n ocorre erro no insert
							-- Se faz necessário o try catch pois na interação en questão não é possível saber se está usando a tabela atual ou a renomeada
							if exists (SELECT * FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS WHERE CONSTRAINT_NAME = 'PK_TABELAOINTERACAORESUMOAUX' AND TABLE_NAME = 'TabelaoInteracaoResumoAux' AND TABLE_SCHEMA ='dbo')
								begin
									ALTER INDEX PK_TabelaoInteracaoResumoAux ON TabelaoInteracaoResumoAux REBUILD
								end
							else
								begin
									ALTER INDEX PK_TabelaoInteracaoResumo ON TabelaoInteracaoResumoAux REBUILD
								end

						end
					else
						begin
							---- Deleta os registros do tabelão que estão contidos na tabela acima
							delete 
								from TabelaoInteracaoResumo
								where 
							TabelaoInteracaoResumo.Id in (select temp.InteracaoId from @TableAlteracoes temp)
						end

					print 'END - deletando registros tabelão interação - ' + convert(varchar(200) ,CAST((dbo.GetDateCustom() - @dtInicio) as time(0)))
					set @dtInicio = dbo.GetDateCustom()

					BEGIN

						set @dtInicioAux = dbo.GetDateCustom()

						if (@GerarTudo = 0)
							begin
								-- Irá selecionar e inserir todos os registros em uma tabela temporária
								-- para depois então excluir os registros do tabelão atendimento 
								-- e os inserir, se faz necessário para quando estiver gerando ã tabela ficar o menor tempo possível 
								-- com lock
								Insert into TabelaoInteracaoResumo
								(
									id,
									IdContaSistema,
									IdAtendimento,
									IdPessoaProspect,
									IdInteracao,

									DtInteracao,
									DtInteracaoFull,
									DtInteracaoInclusao,
									DtInteracaoInclusaoFull,
									DtInteracaoConclusao,
									DtInteracaoConclusaoFull,

									InteracaoRealizado,

									IdInteracaoTipo,
									InteracaoTipoValor,
									InteracaoTipoValorAbreviado,
									DtInclusao,
									InteracaoAtorPartida,
									Periodo,

									IdMidia,
									IdPeca,
									IdIntegradoraExterna,
									IdIntegradoraExternaAgencia,
									IdGrupoPecaMarketing,
									IdCampanhaMarketing,
									IdCanal,
									StrMidia,
									StrPeca,
									StrIntegradoraExterna,
									StrIntegradoraExternaAgencia,
									StrGrupoPecaMarketing,
									StrCampanhaMarketing,
									StrCanal,
									IdProduto,
									StrProdutoNome,

									AlarmeDt,
									AlarmeDtUltimoStatus,
									AlarmeStatus,
									AlarmeRealizado,

									UsuarioContaSistemaRealizouId,
									UsuarioContaSistemaIncluiuId,
									UsuarioContaSistemaRealizouNome,
									UsuarioContaSistemaIncluiuNome,
									UsuarioContaSistemaRealizouEmail,
									UsuarioContaSistemaIncluiuEmail,
									UsuarioContaSistemaRealizouApelido,
									UsuarioContaSistemaIncluiuApelido,

									DtAtualizacaoAuto,
												
									versionIntercao,
									versionAtendimento
								)		

								select 
									TabAtendimentoTemp.IdInteracao,	
									TabAtendimentoTemp.IdContaSistema,
									TabAtendimentoTemp.IdAtendimento,
									TabAtendimentoTemp.IdPessoaProspect,
									TabAtendimentoTemp.IdInteracao,

									TabAtendimentoTemp.DtInteracao,
									TabAtendimentoTemp.DtInteracaoFull,
									TabAtendimentoTemp.DtInteracaoInclusao,
									TabAtendimentoTemp.DtInteracaoInclusaoFull,
									TabAtendimentoTemp.DtInteracaoConclusao,
									TabAtendimentoTemp.DtInteracaoConclusaoFull,

									TabAtendimentoTemp.InteracaoRealizado,

									TabAtendimentoTemp.IdInteracaoTipo,
									TabAtendimentoTemp.InteracaoTipoValor,
									TabAtendimentoTemp.InteracaoTipoValorAbreviado,
									TabAtendimentoTemp.DtInclusao,
									TabAtendimentoTemp.InteracaoAtorPartida,
									TabAtendimentoTemp.Periodo,

									TabAtendimentoTemp.IdMidia,
									TabAtendimentoTemp.IdPeca,
									TabAtendimentoTemp.IdIntegradoraExterna,
									TabAtendimentoTemp.IdIntegradoraExternaAgencia,
									TabAtendimentoTemp.IdGrupoPecaMarketing,
									TabAtendimentoTemp.IdCampanhaMarketing,
									TabAtendimentoTemp.IdCanal,
									TabAtendimentoTemp.StrMidia,
									TabAtendimentoTemp.StrPeca,
									TabAtendimentoTemp.StrIntegradoraExterna,
									TabAtendimentoTemp.StrIntegradoraExternaAgencia,
									TabAtendimentoTemp.StrGrupoPecaMarketing,
									TabAtendimentoTemp.StrCampanhaMarketing,
									TabAtendimentoTemp.StrCanal,
									TabAtendimentoTemp.IdProduto,
									TabAtendimentoTemp.StrProdutoNome,

									TabAtendimentoTemp.AlarmeDt,
									TabAtendimentoTemp.AlarmeDtUltimoStatus,
									TabAtendimentoTemp.AlarmeStatus,
									TabAtendimentoTemp.AlarmeRealizado,

									TabAtendimentoTemp.UsuarioContaSistemaRealizouId,
									TabAtendimentoTemp.UsuarioContaSistemaIncluiuId,
									TabAtendimentoTemp. UsuarioContaSistemaRealizouNome,
									TabAtendimentoTemp.UsuarioContaSistemaIncluiuNome,
									TabAtendimentoTemp. UsuarioContaSistemaRealizouEmail,
									TabAtendimentoTemp.UsuarioContaSistemaIncluiuEmail,
									TabAtendimentoTemp. UsuarioContaSistemaRealizouApelido,
									TabAtendimentoTemp.UsuarioContaSistemaIncluiuApelido,
												
									TabAtendimentoTemp.SuperEntidadeDtAtualizacaoAuto,
												
									TabAtendimentoTemp.versionIntercao,
									TabAtendimentoTemp.versionAtendimento	

								from 
									#TabAtendimentoTemp TabAtendimentoTemp
							end
						else
							begin
								-- Irá selecionar e inserir todos os registros em uma tabela temporária
								-- para depois então excluir os registros do tabelão atendimento 
								-- e os inserir, se faz necessário para quando estiver gerando ã tabela ficar o menor tempo possível 
								-- com lock
								Insert into TabelaoInteracaoResumoAux
								(
									id,
									IdContaSistema,
									IdAtendimento,
									IdPessoaProspect,
									IdInteracao,

									DtInteracao,
									DtInteracaoFull,
									DtInteracaoInclusao,
									DtInteracaoInclusaoFull,
									DtInteracaoConclusao,
									DtInteracaoConclusaoFull,

									InteracaoRealizado,

									IdInteracaoTipo,
									InteracaoTipoValor,
									InteracaoTipoValorAbreviado,
									DtInclusao,
									InteracaoAtorPartida,
									Periodo,

									IdMidia,
									IdPeca,
									IdIntegradoraExterna,
									IdIntegradoraExternaAgencia,
									IdGrupoPecaMarketing,
									IdCampanhaMarketing,
									IdCanal,
									StrMidia,
									StrPeca,
									StrIntegradoraExterna,
									StrIntegradoraExternaAgencia,
									StrGrupoPecaMarketing,
									StrCampanhaMarketing,
									StrCanal,
									IdProduto,
									StrProdutoNome,

									AlarmeDt,
									AlarmeDtUltimoStatus,
									AlarmeStatus,
									AlarmeRealizado,

									UsuarioContaSistemaRealizouId,
									UsuarioContaSistemaIncluiuId,
									UsuarioContaSistemaRealizouNome,
									UsuarioContaSistemaIncluiuNome,
									UsuarioContaSistemaRealizouEmail,
									UsuarioContaSistemaIncluiuEmail,
									UsuarioContaSistemaRealizouApelido,
									UsuarioContaSistemaIncluiuApelido,

									DtAtualizacaoAuto,

									versionIntercao,
									versionAtendimento
								)		

								select 
									TabAtendimentoTemp.IdInteracao,	
									TabAtendimentoTemp.IdContaSistema,
									TabAtendimentoTemp.IdAtendimento,
									TabAtendimentoTemp.IdPessoaProspect,
									TabAtendimentoTemp.IdInteracao,

									TabAtendimentoTemp.DtInteracao,
									TabAtendimentoTemp.DtInteracaoFull,
									TabAtendimentoTemp.DtInteracaoInclusao,
									TabAtendimentoTemp.DtInteracaoInclusaoFull,
									TabAtendimentoTemp.DtInteracaoConclusao,
									TabAtendimentoTemp.DtInteracaoConclusaoFull,

									TabAtendimentoTemp.InteracaoRealizado,

									TabAtendimentoTemp.IdInteracaoTipo,
									TabAtendimentoTemp.InteracaoTipoValor,
									TabAtendimentoTemp.InteracaoTipoValorAbreviado,
									TabAtendimentoTemp.DtInclusao,
									TabAtendimentoTemp.InteracaoAtorPartida,
									TabAtendimentoTemp.Periodo,

									TabAtendimentoTemp.IdMidia,
									TabAtendimentoTemp.IdPeca,
									TabAtendimentoTemp.IdIntegradoraExterna,
									TabAtendimentoTemp.IdIntegradoraExternaAgencia,
									TabAtendimentoTemp.IdGrupoPecaMarketing,
									TabAtendimentoTemp.IdCampanhaMarketing,
									TabAtendimentoTemp.IdCanal,
									TabAtendimentoTemp.StrMidia,
									TabAtendimentoTemp.StrPeca,
									TabAtendimentoTemp.StrIntegradoraExterna,
									TabAtendimentoTemp.StrIntegradoraExternaAgencia,
									TabAtendimentoTemp.StrGrupoPecaMarketing,
									TabAtendimentoTemp.StrCampanhaMarketing,
									TabAtendimentoTemp.StrCanal,
									TabAtendimentoTemp.IdProduto,
									TabAtendimentoTemp.StrProdutoNome,

									TabAtendimentoTemp.AlarmeDt,
									TabAtendimentoTemp.AlarmeDtUltimoStatus,
									TabAtendimentoTemp.AlarmeStatus,
									TabAtendimentoTemp.AlarmeRealizado,

									TabAtendimentoTemp.UsuarioContaSistemaRealizouId,
									TabAtendimentoTemp.UsuarioContaSistemaIncluiuId,
									TabAtendimentoTemp. UsuarioContaSistemaRealizouNome,
									TabAtendimentoTemp.UsuarioContaSistemaIncluiuNome,
									TabAtendimentoTemp. UsuarioContaSistemaRealizouEmail,
									TabAtendimentoTemp.UsuarioContaSistemaIncluiuEmail,
									TabAtendimentoTemp. UsuarioContaSistemaRealizouApelido,
									TabAtendimentoTemp.UsuarioContaSistemaIncluiuApelido,
								
									TabAtendimentoTemp.SuperEntidadeDtAtualizacaoAuto,
												
									TabAtendimentoTemp.versionIntercao,
									TabAtendimentoTemp.versionAtendimento
													
								from 
									#TabAtendimentoTemp TabAtendimentoTemp
							end
						END

					print 'END - insert no tabelão interação - ' + convert(varchar(200) ,CAST((dbo.GetDateCustom() - @dtInicio) as time(0)))
					set @dtInicio = dbo.GetDateCustom()

				end
		end

	if (@isExecute = 1 and @GerarTudo = 1)
		begin
			begin
				-- Liga e Reconstroi os índices
				-- Liga e Reconstroi os índices
				-- ONLINE = ON, permite o acesso ao dados sem bloqueio a tabela mas é mais demorado
				-- como a tabela é exclusiva setarei OFF nessa operação
				ALTER INDEX ALL ON TabelaoInteracaoResumoAux REBUILD PARTITION = ALL WITH (ONLINE = ON)
			end
		end

	print 'END - geração dos índices - ' + convert(varchar(200) ,CAST((dbo.GetDateCustom() - @dtInicio) as time(0)))
	set @dtInicio = dbo.GetDateCustom()

	if (@isExecute = 1 and @GerarTudo = 1)
		begin
			UPDATE STATISTICS TabelaoInteracaoResumoAux

			EXEC sp_rename 'TabelaoInteracaoResumo', 'TabelaoInteracaoResumoAuxOld2';
			EXEC sp_rename 'TabelaoInteracaoResumoAux', 'TabelaoInteracaoResumo'; 
			EXEC sp_rename 'TabelaoInteracaoResumoAuxOld2', 'TabelaoInteracaoResumoAux';
		
		end

	print 'END - sp_rename ' + convert(varchar(200) ,CAST((dbo.GetDateCustom() - @dtInicio) as time(0)))
	set @dtInicio = dbo.GetDateCustom()

	if (@isExecute = 1 and @GerarTudo = 1)
		begin
			truncate table TabelaoInteracaoResumoAux
		end

	if (@isExecute = 1)
		begin
			if (@GerarTudo = 0)
				begin
					set @versao = isnull((SELECT MAX(versao) from @TableAlteracoes), @versao)
					set @interacaoId = isnull((select MAX(InteracaoId) from @TableAlteracoes), @interacaoId)

					set @objJson = JSON_MODIFY(JSON_MODIFY(@objJson,'$.parcialVersao', sys.fn_varbintohexstr(@versao)), '$.parcialInteracaoId', @interacaoId)
				end

			if (@GerarTudo = 1)
				begin
					set @versao = isnull((SELECT MAX(versao) from @TableAlteracoes), @versao)
					set @interacaoId = isnull((select MAX(InteracaoId) from @TableAlteracoes), @interacaoId)

					set @objJson = JSON_MODIFY(JSON_MODIFY(@objJson,'$.parcialVersao', sys.fn_varbintohexstr(@versao)), '$.parcialInteracaoId', @interacaoId)
					set @objJson = JSON_MODIFY(JSON_MODIFY(@objJson,'$.completoVersao', sys.fn_varbintohexstr(@versao)), '$.completoInteracaoId', @interacaoId)
				end
					

			update TabelaoLog set TabelaoLog.Obj = @objJson where TabelaoLog.Nome = @BatchNome
		end



	Update 
		TabelaoLog 
	Set
		-- Adiciona 2 milesegundo desde a última execução para considerar todos atualizados desde a última atualização
		-- 2 pq é o mínimo que pode adicionar
		TabelaoLog.Data1 = @dtReferenciaUtilizarMaximo,
		TabelaoLog.Data2 = null,
		TabelaoLog.bit1 = @GerarTudo,
		TabelaoLog.DtUltimaParcial = case when @GerarTudo = 0 then dbo.GetDateCustom() else TabelaoLog.DtUltimaParcial end,
		TabelaoLog.DtUltimaCompleta = case when @GerarTudo = 1 then dbo.GetDateCustom() else TabelaoLog.DtUltimaCompleta end
	where
		TabelaoLog.Nome = @BatchNome
	
	
	print 'Total de atendimentos: '+ convert(varchar(45), @qtdAtendimentos) + '. Qtd de interações: '+ convert(varchar(30), @qtdInteracoes) + ' em ' + convert(varchar(200) ,CAST((dbo.GetDateCustom() - @dtInicioGeral) as time(0)));

CREATE procedure [dbo].[ProcGerarTabelaoV1] 
(
	@tipoProcessamento varchar(20)
)
as
	-- comentar
	-- return

	DECLARE @TableAlteracoes TABLE
	(
	  IdAtendimento int,
	  rownumber int
	);

	DECLARE @TableAlteracoesAux TABLE
	(
	  IdAtendimento int,
	  versao varbinary(8)
	);

	declare @dtnow datetime = dbo.getDateCustom()
	declare @iCount int = 0
	declare @iQtdPorTransaction int = 100000
	declare @isExecute bit = 1
	declare @dtReferenciaUtilizarMaximo datetime = @dtnow
	declare @dtUltimaAtualizacao datetime
	declare @dtInicioGeral datetime = @dtnow
	declare @dtInicio datetime = @dtnow
	declare @dtInicioAux datetime
	declare @versao varbinary(8)
	declare @atendimentoId int

	declare @BatchNome varchar(100) = 'Batch_TabelaoAtendimento'

	declare @objJson varchar(max) = (select top 1 TabelaoLog.Obj from TabelaoLog where nome = @BatchNome)
	

	-- Verifica se o repassado é diferente dos tipos de geração possível
	if @tipoProcessamento != 'parcial_completo' and @tipoProcessamento != 'parcial' and @tipoProcessamento != 'completo'
		begin
			return
		end

	-- Retorna a data que começou a última atualização
	select @dtUltimaAtualizacao = Max(TabelaoLog.Data2) from TabelaoLog with (nolock) where TabelaoLog.Nome = @BatchNome group by TabelaoLog.Nome

	-- Se o processamento atual não for de gerar tudo e a data não for nula
	-- Subentende-se que no momento está sendo atualizado e não deve rodar 2 atualizações ao mesmo tempo
	-- testará tb se faz mais de 360 minutos que a ultima query executou nesse caso irá considerar que hove erro e executará 
	-- zerando a hora para não ter problemas
	if ((@tipoProcessamento = 'parcial' OR @tipoProcessamento = 'parcial_completo') and @dtUltimaAtualizacao is not null and DATEDIFF(MI, @dtUltimaAtualizacao, dbo.GetDateCustom()) < 360)
		begin
			return
		end
	--else
	--	begin
	--		update TabelaoLog set TabelaoLog.Data2 = dbo.GetDateCustom(),  TabelaoLog.string1 = @tipoProcessamento where TabelaoLog.Nome = @BatchNome
	--	end


	if @tipoProcessamento = 'completo'
		begin
			-- Irá recuperar todos os registros atendimento que houve alteração
			-- Caso GerarTudo seja 1 irá gerar toda o tabelão
			insert into @TableAlteracoesAux
			Select 
				Atendimento.Id, Atendimento.versao
			from 
				Atendimento  
					inner join
				ContaSistema with (nolock) on ContaSistema.id = Atendimento.idContaSistema
			where 
				ContaSistema.Status = 'AT'
					and
				Atendimento.RegistroStatus is null
		end

	if @tipoProcessamento = 'parcial_completo'
		begin
			set @versao = convert(varbinary(8), sys.fn_cdc_hexstrtobin(JSON_VALUE(@objJson, '$.parcialCompletoVersao')))
			set @atendimentoId = JSON_VALUE(@objJson, '$.parcialCompletoAtendimentoId')

			insert into @TableAlteracoesAux
			select top 5000
				Atendimento.Id, (select (SELECT Max(VersaoMax) FROM (VALUES (Produto.versao), (Midia.versao), (Peca.versao), (Campanha.versao), (Grupo.versao), (PessoaProspect.versao), (Atendimento.versao)) as value (VersaoMax))) as Versao
			from 
				Atendimento
					inner join
				ContaSistema with (nolock) on ContaSistema.id = Atendimento.idContaSistema
					inner join
				PessoaProspect  with (nolock)  on PessoaProspect.Id = Atendimento.idPessoaProspect
					left outer join
				Produto  with (nolock)  on Produto.Id = Atendimento.idProduto
					left outer join
				Midia  with (nolock)  on Midia.Id = Atendimento.IdMidia
					left outer join
				Peca  with (nolock)  on Peca.Id = Atendimento.idPeca
					left outer join
				Campanha  with (nolock)  on Campanha.Id = Atendimento.idCampanha
					left outer join
				Grupo  with (nolock)  on Grupo.Id = Atendimento.idGrupo
			​
			where
				ContaSistema.status = 'AT'
					and
				(
					(
						Atendimento.versao = @versao
							or 
						PessoaProspect.versao = @versao
							or
						Produto.versao = @versao
							or
						Midia.versao = @versao
							or
						Peca.versao = @versao
							or
						Campanha.versao = @versao
							or 
						Grupo.versao = @versao
					)
						and
					Atendimento.Id > @atendimentoId
				)
					or
				(
					Atendimento.versao > @versao
						or 
					PessoaProspect.versao > @versao
						or
					Produto.versao > @versao
						or
					Midia.versao > @versao
						or
					Peca.versao > @versao
						or
					Campanha.versao > @versao
						or 
					Grupo.versao > @versao
				)
			order by
				Versao asc,
				Atendimento.Id asc

			OPTION (RECOMPILE)

		end

	if @tipoProcessamento = 'parcial'
		begin
			set @versao = convert(varbinary(8), sys.fn_cdc_hexstrtobin(JSON_VALUE(@objJson, '$.parcialVersao')))
			set @atendimentoId = JSON_VALUE(@objJson, '$.parcialAtendimentoId')

			-- optei a fazer assim para não usar contasistema.status já que deixa muito lento
			-- ja que quando a base está inativada parará de atualizar naturalmente
			insert into @TableAlteracoesAux
			Select top 5000
				Atendimento.Id, (select (SELECT Max(VersaoMax) FROM (VALUES (PessoaProspect.versao), (Atendimento.versao)) as value (VersaoMax))) as Versao
			from 
				Atendimento
					inner join
				ContaSistema with (nolock) on ContaSistema.id = Atendimento.idContaSistema
					inner join
				PessoaProspect  with (nolock)  on PessoaProspect.Id = Atendimento.idPessoaProspect
			​
			where
				ContaSistema.status = 'AT'
					and
				(
					(
						Atendimento.versao = @versao
							or 
						PessoaProspect.versao = @versao
					)
						and
					Atendimento.Id > @atendimentoId
				)
					or
				(
					Atendimento.versao > @versao
						or 
					PessoaProspect.versao > @versao
				)
			order by
				Versao asc,
				Atendimento.Id asc

			OPTION (RECOMPILE)

		end

	print 'END - select top q seleciona os ids e versão que serão atualizados - ' + convert(varchar(200) ,CAST((dbo.GetDateCustom() - @dtInicio) as time(0)))

	-- Insere na @TableAlteracoes os ids dos dos atendimentos com ROW_NUMBER() para facilitar os inserts em lote
	insert into @TableAlteracoes
	Select TabAux2.IdAtendimento, ROW_NUMBER() OVER(ORDER BY TabAux2.IdAtendimento ASC) AS RowNumber
	From
		(
			Select
				distinct TabAux.IdAtendimento 
			From
				@TableAlteracoesAux TabAux
		) TabAux2

	print 'END - select e insert dos ids - ' + convert(varchar(200) ,CAST((dbo.GetDateCustom() - @dtInicio) as time(0)))
	set @dtInicio = dbo.GetDateCustom()

	-- Caso não exista registro irá retornar para evitar processamento
	if isnull((select top 1 Tab1.IdAtendimento from @TableAlteracoes Tab1),0) = 0
		begin 
			set @isExecute = 0
		end

	if (@isExecute = 1)
		begin	

			-- insere os registros em uma tabela temporária
			Select
				temp.rownumber,

				@dtReferenciaUtilizarMaximo as DtInclusao,
				AtendimentoResumoView.ContasistemaId,
				AtendimentoResumoView.ContasistemaIdGuid,
					
				AtendimentoResumoView.Atendimentoid,
				CONVERT(binary(8), AtendimentoResumoView.AtendimentoVersao) as AtendimentoVersao,
				AtendimentoResumoView.AtendimentoidGuid,
				AtendimentoResumoView.AtendimentoDtInclusao,
				AtendimentoResumoView.AtendimentoDtInicio,
				AtendimentoResumoView.AtendimentoDtConclusao,
				AtendimentoResumoView.AtendimentoStatus,
				AtendimentoResumoView.AtendimentoNegociacaoStatus,
				AtendimentoResumoView.AtendimentoTipoDirecionamento,
				AtendimentoResumoView.AtendimentoValorNegocio,
				AtendimentoResumoView.AtendimentoComissaoNegocio,
	
				AtendimentoResumoView.ProdutoId,
				AtendimentoResumoView.ProdutoNome,
				AtendimentoResumoView.ProdutoUF,
				AtendimentoResumoView.ProdutoMarco,
				
				AtendimentoResumoView.CanalId,
				AtendimentoResumoView.CanalNome,
				AtendimentoResumoView.CanalMeio,
		
				AtendimentoResumoView.MidiaId,
				AtendimentoResumoView.MidiaNome,
				AtendimentoResumoView.MidiaTipoValor,

				AtendimentoResumoView.IntegradoraExternaId,
				AtendimentoResumoView.IntegradoraExternaIdGuid,
				AtendimentoResumoView.IntegradoraExternaExtensaoLogo,
				AtendimentoResumoView.IntegradoraExternaNome,
		
				AtendimentoResumoView.PecaId,
				AtendimentoResumoView.PecaNome,
		
				AtendimentoResumoView.CampanhaMarketingId,
				AtendimentoResumoView.CampanhaMarketingNome,
		
				AtendimentoResumoView.GrupoPecaMarketingId,
				AtendimentoResumoView.GrupoPecaMarketingNome,
		
				AtendimentoResumoView.GrupoId,
				AtendimentoResumoView.GrupoNome,
				AtendimentoResumoView.GrupoHierarquia,
				AtendimentoResumoView.GrupoHierarquiaTipo,
				AtendimentoResumoView.GrupoTag,
		
				AtendimentoResumoView.ClassificacaoId,
				AtendimentoResumoView.ClassificacaoIdGuid, 
				AtendimentoResumoView.ClassificacaoValor,
				AtendimentoResumoView.ClassificacaoValor2,
				AtendimentoResumoView.ClassificacaoOrdem,

				AtendimentoResumoView.ProspeccaoId,
				AtendimentoResumoView.ProspeccaoNome,
		
				AtendimentoResumoView.CampanhaId,
				AtendimentoResumoView.CampanhaNome,
		
				AtendimentoResumoView.CriouAtendimentoUsuarioContaSistemaId,
				AtendimentoResumoView.CriouAtendimentoPessoaNome,
		
				AtendimentoResumoView.UsuarioContaSistemaId,
				AtendimentoResumoView.UsuarioContaSistemaIdGuid,
				AtendimentoResumoView.UsuarioContaSistemaStatus,
		
				AtendimentoResumoView.PessoaId,
				AtendimentoResumoView.PessoaNome,
				AtendimentoResumoView.PessoaApelido,
				AtendimentoResumoView.PessoaEmail,

				AtendimentoResumoView.ProdutoSubList,
		
				AtendimentoResumoView.PessoaProspectId,
				AtendimentoResumoView.PessoaProspectIdGuid,
				AtendimentoResumoView.PessoaProspectDtInclusao,
				AtendimentoResumoView.PessoaProspectNome,
				left(AtendimentoResumoView.PessoaProspectEmailList,8000) as PessoaProspectEmailList,
				AtendimentoResumoView.PessoaProspectTelefoneList,
				AtendimentoResumoView.PessoaProspectCPF,
				AtendimentoResumoView.PessoaProspectTagList,
				AtendimentoResumoView.PessoaProspectSexo, 
				AtendimentoResumoView.PessoaProspectDtNascimento,
				AtendimentoResumoView.PessoaProspectProfissao, 
		
				AtendimentoResumoView.AtendimentoConvercaoVenda,
		
				AtendimentoResumoView.AtendimentoIdMotivacaoNaoConversaoVenda,
				AtendimentoResumoView.AtendimentoMotivacaoNaoConversaoVenda,

			
				AtendimentoResumoView.InteracaoPrimeiraId,
				AtendimentoResumoView.InteracaoPrimeiraDtFull,

				AtendimentoResumoView.InteracaoNegociacaoVendaUltimaId,
				AtendimentoResumoView.InteracaoNegociacaoVendaUltimaDtFull,

				AtendimentoResumoView.InteracaoUltimaId,
				AtendimentoResumoView.InteracaoUltimaDtFull,
				AtendimentoResumoView.InteracaoUltimaTipoValor,
				AtendimentoResumoView.InteracaoUltimaTipoValorAbreviado,
				AtendimentoResumoView.InteracaoUltimaDtUtilConsiderar,

				AtendimentoResumoView.AlarmeUltimoAtivoId,
				AtendimentoResumoView.AlarmeUltimoAtivoData,
				AtendimentoResumoView.AlarmeUltimoAtivoInteracaoTipoValor,

				AtendimentoResumoView.AlarmeProximoAtivoId,
				AtendimentoResumoView.AlarmeProximoAtivoData,
				AtendimentoResumoView.AlarmeProximoAtivoInteracaoTipoValor,

				AtendimentoResumoView.PessoaEnderecoUF1,
				AtendimentoResumoView.PessoaEnderecoCidade1,
				AtendimentoResumoView.PessoaEnderecoBairro1,
				AtendimentoResumoView.PessoaEnderecoLogradouro1,
				AtendimentoResumoView.PessoaEnderecoComplemento1,
				AtendimentoResumoView.PessoaEnderecoNumero1,
				AtendimentoResumoView.PessoaEnderecoCEP1,
				AtendimentoResumoView.PessoaEnderecoLatitude1,
				AtendimentoResumoView.PessoaEnderecoLongitude1,
				AtendimentoResumoView.PessoaEnderecoTipo1,

				AtendimentoResumoView.PessoaEnderecoUF2,
				AtendimentoResumoView.PessoaEnderecoCidade2,
				AtendimentoResumoView.PessoaEnderecoBairro2,
				AtendimentoResumoView.PessoaEnderecoLogradouro2,
				AtendimentoResumoView.PessoaEnderecoComplemento2,
				AtendimentoResumoView.PessoaEnderecoNumero2,
				AtendimentoResumoView.PessoaEnderecoCEP2,
				AtendimentoResumoView.PessoaEnderecoLatitude2,
				AtendimentoResumoView.PessoaEnderecoLongitude2,
				AtendimentoResumoView.PessoaEnderecoTipo2,

				AtendimentoResumoView.DtAtualizacaoAuto

				into #TabAtendimentoTemp

			From
				AtendimentoResumoView WITH (nolock)
					inner join
				@TableAlteracoes temp on temp.IdAtendimento = AtendimentoResumoView.Atendimentoid

			print 'END - select do (AtendimentoResumoView) e insert na tabela temporária  - ' + convert(varchar(200) ,CAST((dbo.GetDateCustom() - @dtInicio) as time(0)))
			set @dtInicio = dbo.GetDateCustom()

			if (ISNULL((Select top 1 Tab.Atendimentoid from #TabAtendimentoTemp Tab),0) > 0)
					begin
						if (@tipoProcessamento = 'completo')
							begin
								-- Exclui Todos os registros das conta sistema desabilitadas			
								-- Delete TabelaoAtendimento

								-- deleta todos os registros da tabela
								TRUNCATE TABLE TabelaoAtendimentoAux
		
								-- Desliga as constraints
								ALTER TABLE TabelaoAtendimentoAux NOCHECK CONSTRAINT ALL
			
								-- Desliga os índices
								ALTER INDEX All ON TabelaoAtendimentoAux DISABLE
								
								-- Delete o índice mas reconstroe abaixo
								--DROP INDEX [idxColumnStore] ON [dbo].[TabelaoAtendimento]
								
								-- Recria e habilita apenas o índice do id pois se n ocorre erro no insert
								-- Se faz necessário o try catch pois na interação en questão não é possível saber se está usando a tabela atual ou a renomeada
								if exists (SELECT * FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS WHERE CONSTRAINT_NAME = 'PK_TabelaoAtendimentoAux' AND TABLE_NAME = 'TabelaoAtendimentoAux' AND TABLE_SCHEMA ='dbo')
									begin
										ALTER INDEX PK_TabelaoAtendimentoAux ON TabelaoAtendimentoAux REBUILD
									end
								else
									begin
										ALTER INDEX PK_TabelaoAtendimento ON TabelaoAtendimentoAux REBUILD
									end

							end
						else
							begin
								---- Deleta os registros do tabelão que estão contidos na tabela acima
								with cte as 
								(
									select 
										TabelaoAtendimento.AtendimentoId
									from 
										TabelaoAtendimento with (nolock) 
									where exists (select temp.IdAtendimento from @TableAlteracoes temp where temp.IdAtendimento = TabelaoAtendimento.AtendimentoId)
								)
								delete from cte
							end

						
						print 'END - deletando registros tabelão - ' + convert(varchar(200) ,CAST((dbo.GetDateCustom() - @dtInicio) as time(0)))
						set @dtInicio = dbo.GetDateCustom()
					end

		end

	if (@isExecute = 1)
		begin
			set @iCount = (Select count(TabAux.Atendimentoid) from #TabAtendimentoTemp TabAux);
			declare @i int = 1;

			WHILE @i <= @iCount 
				BEGIN

						set @dtInicioAux = dbo.GetDateCustom()

						if (@tipoProcessamento = 'parcial' or @tipoProcessamento = 'parcial_completo')
							begin
								-- Irá selecionar e inserir todos os registros em uma tabela temporária
								-- para depois então excluir os registros do tabelão atendimento 
								-- e os inserir, se faz necessário para quando estiver gerando ã tabela ficar o menor tempo possível 
								-- com lock
								Insert into TabelaoAtendimento
								(
									DtInclusao,
									ContasistemaId,
									ContasistemaIdGuid,
		
									Atendimentoid,
									versionAtendimento,
									AtendimentoIdGuid,
									AtendimentoDtInclusao,
									AtendimentoDtInicio,
									AtendimentoDtConclusao,
									AtendimentoStatus,
									AtendimentoNegociacaoStatus,
									AtendimentoTipoDirecionamento,
									AtendimentoValorNegocio,
									AtendimentoComissaoNegocio,
		
									ProdutoId,
									ProdutoNome,
									ProdutoUF,
									ProdutoMarco,

									CanalId,
									CanalNome,
									CanalMeio,
		
									MidiaId,
									MidiaNome,
									MidiaTipoValor,

									IntegradoraExternaId,
									IntegradoraExternaIdGuid,
									IntegradoraExternaExtensaoLogo,
									IntegradoraExternaNome,
		
									PecaId,
									PecaNome,
		
									CampanhaMarketingId,
									CampanhaMarketingNome,
		
									GrupoPecaMarketingId,
									GrupoPecaMarketingNome,
		
									GrupoId,
									GrupoNome,
									GrupoHierarquia,
									GrupoHierarquiaTipo,
									GrupoTag,
		
									ClassificacaoId,
									ClassificacaoIdGuid,
									ClassificacaoValor,
									ClassificacaoValor2,
									ClassificacaoOrdem,

									ProspeccaoId,
									ProspeccaoNome,
		
									CampanhaId,
									CampanhaNome,
		
									CriouAtendimentoUsuarioContaSistemaId,
									CriouAtendimentoPessoaNome,
		
									UsuarioContaSistemaId,
									UsuarioContaSistemaIdGuid,
									UsuarioContaSistemaStatus,
		
									PessoaId,
									PessoaNome,
									PessoaApelido,
									PessoaEmail,

									ProdutoSubList,
		
									PessoaProspectId,
									PessoaProspectIdGuid,
									PessoaProspectDtInclusao,
									PessoaProspectNome,
									PessoaProspectEmailList,
									PessoaProspectTelefoneList,
									PessoaProspectCPF,
									PessoaProspectTagList,
									PessoaProspectSexo,
									PessoaProspectDtNascimento,
									PessoaProspectProfissao,
		
		
									AtendimentoConvercaoVenda,

									AtendimentoIdMotivacaoNaoConversaoVenda,
									AtendimentoMotivacaoNaoConversaoVenda,

									InteracaoPrimeiraId,
									InteracaoPrimeiraDtFull,

									InteracaoNegociacaoVendaUltimaId,
									InteracaoNegociacaoVendaUltimaDtFull,

									InteracaoUltimaId,
									InteracaoUltimaDtFull,
									InteracaoUltimaTipoValor,
									InteracaoUltimaTipoValorAbreviado,
									InteracaoUltimaDtUtilConsiderar,

									AlarmeUltimoAtivoId,
									AlarmeUltimoAtivoData,
									AlarmeUltimoAtivoInteracaoTipoValor,

									AlarmeProximoAtivoId,
									AlarmeProximoAtivoData,
									AlarmeProximoAtivoInteracaoTipoValor,

									PessoaEnderecoUF1,
									PessoaEnderecoCidade1,
									PessoaEnderecoBairro1,
									PessoaEnderecoLogradouro1,
									PessoaEnderecoComplemento1,
									PessoaEnderecoNumero1,
									PessoaEnderecoCEP1,
									PessoaEnderecoLatitude1,
									PessoaEnderecoLongitude1,
									PessoaEnderecoTipo1,

									PessoaEnderecoUF2,
									PessoaEnderecoCidade2,
									PessoaEnderecoBairro2,
									PessoaEnderecoLogradouro2,
									PessoaEnderecoComplemento2,
									PessoaEnderecoNumero2,
									PessoaEnderecoCEP2,
									PessoaEnderecoLatitude2,
									PessoaEnderecoLongitude2,
									PessoaEnderecoTipo2,

									DtAtualizacaoAuto
								)
								Select 
									@dtReferenciaUtilizarMaximo as DtInclusao,
									TabAtendimentoTemp.ContasistemaId,
									TabAtendimentoTemp.ContasistemaIdGuid,
					
									TabAtendimentoTemp.Atendimentoid,
									TabAtendimentoTemp.AtendimentoVersao,
									TabAtendimentoTemp.AtendimentoidGuid,
									TabAtendimentoTemp.AtendimentoDtInclusao,
									TabAtendimentoTemp.AtendimentoDtInicio,
									TabAtendimentoTemp.AtendimentoDtConclusao,
									TabAtendimentoTemp.AtendimentoStatus,
									TabAtendimentoTemp.AtendimentoNegociacaoStatus,
									TabAtendimentoTemp.AtendimentoTipoDirecionamento,
									TabAtendimentoTemp.AtendimentoValorNegocio,
									TabAtendimentoTemp.AtendimentoComissaoNegocio,
	
									TabAtendimentoTemp.ProdutoId,
									TabAtendimentoTemp.ProdutoNome,
									TabAtendimentoTemp.ProdutoUF,
									TabAtendimentoTemp.ProdutoMarco,
				
									TabAtendimentoTemp.CanalId,
									TabAtendimentoTemp.CanalNome,
									TabAtendimentoTemp.CanalMeio,
		
									TabAtendimentoTemp.MidiaId,
									TabAtendimentoTemp.MidiaNome,
									TabAtendimentoTemp.MidiaTipoValor,

									TabAtendimentoTemp.IntegradoraExternaId,
									TabAtendimentoTemp.IntegradoraExternaIdGuid,
									TabAtendimentoTemp.IntegradoraExternaExtensaoLogo,
									TabAtendimentoTemp.IntegradoraExternaNome,
		
									TabAtendimentoTemp.PecaId,
									TabAtendimentoTemp.PecaNome,
		
									TabAtendimentoTemp.CampanhaMarketingId,
									TabAtendimentoTemp.CampanhaMarketingNome,
		
									TabAtendimentoTemp.GrupoPecaMarketingId,
									TabAtendimentoTemp.GrupoPecaMarketingNome,
		
									TabAtendimentoTemp.GrupoId,
									TabAtendimentoTemp.GrupoNome,
									TabAtendimentoTemp.GrupoHierarquia,
									TabAtendimentoTemp.GrupoHierarquiaTipo,
									TabAtendimentoTemp.GrupoTag,
		
									TabAtendimentoTemp.ClassificacaoId,
									TabAtendimentoTemp.ClassificacaoIdGuid, 
									TabAtendimentoTemp.ClassificacaoValor,
									TabAtendimentoTemp.ClassificacaoValor2,
									TabAtendimentoTemp.ClassificacaoOrdem,

									TabAtendimentoTemp.ProspeccaoId,
									TabAtendimentoTemp.ProspeccaoNome,
		
									TabAtendimentoTemp.CampanhaId,
									TabAtendimentoTemp.CampanhaNome,
		
									TabAtendimentoTemp.CriouAtendimentoUsuarioContaSistemaId,
									TabAtendimentoTemp.CriouAtendimentoPessoaNome,
		
									TabAtendimentoTemp.UsuarioContaSistemaId,
									TabAtendimentoTemp.UsuarioContaSistemaIdGuid,
									TabAtendimentoTemp.UsuarioContaSistemaStatus,
		
									TabAtendimentoTemp.PessoaId,
									TabAtendimentoTemp.PessoaNome,
									TabAtendimentoTemp.PessoaApelido,
									TabAtendimentoTemp.PessoaEmail,

									TabAtendimentoTemp.ProdutoSubList,
		
									TabAtendimentoTemp.PessoaProspectId,
									TabAtendimentoTemp.PessoaProspectIdGuid,
									TabAtendimentoTemp.PessoaProspectDtInclusao,
									TabAtendimentoTemp.PessoaProspectNome,
									TabAtendimentoTemp.PessoaProspectEmailList,
									TabAtendimentoTemp.PessoaProspectTelefoneList,
									TabAtendimentoTemp.PessoaProspectCPF,
									TabAtendimentoTemp.PessoaProspectTagList,
									TabAtendimentoTemp.PessoaProspectSexo, 
									TabAtendimentoTemp.PessoaProspectDtNascimento,
									TabAtendimentoTemp.PessoaProspectProfissao, 
		
									TabAtendimentoTemp.AtendimentoConvercaoVenda,
		
									TabAtendimentoTemp.AtendimentoIdMotivacaoNaoConversaoVenda,
									TabAtendimentoTemp.AtendimentoMotivacaoNaoConversaoVenda,

									TabAtendimentoTemp.InteracaoPrimeiraId,
									TabAtendimentoTemp.InteracaoPrimeiraDtFull,

									TabAtendimentoTemp.InteracaoNegociacaoVendaUltimaId,
									TabAtendimentoTemp.InteracaoNegociacaoVendaUltimaDtFull,

									TabAtendimentoTemp.InteracaoUltimaId,
									TabAtendimentoTemp.InteracaoUltimaDtFull,
									TabAtendimentoTemp.InteracaoUltimaTipoValor,
									TabAtendimentoTemp.InteracaoUltimaTipoValorAbreviado,
									TabAtendimentoTemp.InteracaoUltimaDtUtilConsiderar,

									TabAtendimentoTemp.AlarmeUltimoAtivoId,
									TabAtendimentoTemp.AlarmeUltimoAtivoData,
									TabAtendimentoTemp.AlarmeUltimoAtivoInteracaoTipoValor,

									TabAtendimentoTemp.AlarmeProximoAtivoId,
									TabAtendimentoTemp.AlarmeProximoAtivoData,
									TabAtendimentoTemp.AlarmeProximoAtivoInteracaoTipoValor,

									TabAtendimentoTemp.PessoaEnderecoUF1,
									TabAtendimentoTemp.PessoaEnderecoCidade1,
									TabAtendimentoTemp.PessoaEnderecoBairro1,
									TabAtendimentoTemp.PessoaEnderecoLogradouro1,
									TabAtendimentoTemp.PessoaEnderecoComplemento1,
									TabAtendimentoTemp.PessoaEnderecoNumero1,
									TabAtendimentoTemp.PessoaEnderecoCEP1,
									TabAtendimentoTemp.PessoaEnderecoLatitude1,
									TabAtendimentoTemp.PessoaEnderecoLongitude1,
									TabAtendimentoTemp.PessoaEnderecoTipo1,

									TabAtendimentoTemp.PessoaEnderecoUF2,
									TabAtendimentoTemp.PessoaEnderecoCidade2,
									TabAtendimentoTemp.PessoaEnderecoBairro2,
									TabAtendimentoTemp.PessoaEnderecoLogradouro2,
									TabAtendimentoTemp.PessoaEnderecoComplemento2,
									TabAtendimentoTemp.PessoaEnderecoNumero2,
									TabAtendimentoTemp.PessoaEnderecoCEP2,
									TabAtendimentoTemp.PessoaEnderecoLatitude2,
									TabAtendimentoTemp.PessoaEnderecoLongitude2,
									TabAtendimentoTemp.PessoaEnderecoTipo2,

									TabAtendimentoTemp.DtAtualizacaoAuto

								From
									#TabAtendimentoTemp TabAtendimentoTemp   WITH (NOLOCK)
								where
									not exists (Select TabelaoAtendimento.AtendimentoId from TabelaoAtendimento with (nolock) where TabelaoAtendimento.AtendimentoId = TabAtendimentoTemp.AtendimentoId)
										and
									TabAtendimentoTemp.rownumber between @i and @i + @iQtdPorTransaction
							end
						else
							begin
								-- Irá selecionar e inserir todos os registros em uma tabela temporária
								-- para depois então excluir os registros do tabelão atendimento 
								-- e os inserir, se faz necessário para quando estiver gerando ã tabela ficar o menor tempo possível 
								-- com lock
								Insert into TabelaoAtendimentoAux
								(
									DtInclusao,
									ContasistemaId,
									ContasistemaIdGuid,
		
									Atendimentoid,
									versionAtendimento,
									AtendimentoIdGuid,
									AtendimentoDtInclusao,
									AtendimentoDtInicio,
									AtendimentoDtConclusao,
									AtendimentoStatus,
									AtendimentoNegociacaoStatus,
									AtendimentoTipoDirecionamento,
									AtendimentoValorNegocio,
									AtendimentoComissaoNegocio,
		
									ProdutoId,
									ProdutoNome,
									ProdutoUF,
									ProdutoMarco,

									CanalId,
									CanalNome,
									CanalMeio,
		
									MidiaId,
									MidiaNome,
									MidiaTipoValor,

									IntegradoraExternaId,
									IntegradoraExternaIdGuid,
									IntegradoraExternaExtensaoLogo,
									IntegradoraExternaNome,
		
									PecaId,
									PecaNome,
		
									CampanhaMarketingId,
									CampanhaMarketingNome,
		
									GrupoPecaMarketingId,
									GrupoPecaMarketingNome,
		
									GrupoId,
									GrupoNome,
									GrupoHierarquia,
									GrupoHierarquiaTipo,
									GrupoTag,
		
									ClassificacaoId,
									ClassificacaoIdGuid,
									ClassificacaoValor,
									ClassificacaoValor2,
									ClassificacaoOrdem,

									ProspeccaoId,
									ProspeccaoNome,
		
									CampanhaId,
									CampanhaNome,
		
									CriouAtendimentoUsuarioContaSistemaId,
									CriouAtendimentoPessoaNome,
		
									UsuarioContaSistemaId,
									UsuarioContaSistemaIdGuid,
									UsuarioContaSistemaStatus,
		
									PessoaId,
									PessoaNome,
									PessoaApelido,
									PessoaEmail,

									ProdutoSubList,
		
									PessoaProspectId,
									PessoaProspectIdGuid,
									PessoaProspectDtInclusao,
									PessoaProspectNome,
									PessoaProspectEmailList,
									PessoaProspectTelefoneList,
									PessoaProspectCPF,
									PessoaProspectTagList,
									PessoaProspectSexo,
									PessoaProspectDtNascimento,
									PessoaProspectProfissao,
		
		
									AtendimentoConvercaoVenda,

									AtendimentoIdMotivacaoNaoConversaoVenda,
									AtendimentoMotivacaoNaoConversaoVenda,

									InteracaoPrimeiraId,
									InteracaoPrimeiraDtFull,

									InteracaoNegociacaoVendaUltimaId,
									InteracaoNegociacaoVendaUltimaDtFull,

									InteracaoUltimaId,
									InteracaoUltimaDtFull,
									InteracaoUltimaTipoValor,
									InteracaoUltimaTipoValorAbreviado,
									InteracaoUltimaDtUtilConsiderar,

									AlarmeUltimoAtivoId,
									AlarmeUltimoAtivoData,
									AlarmeUltimoAtivoInteracaoTipoValor,

									AlarmeProximoAtivoId,
									AlarmeProximoAtivoData,
									AlarmeProximoAtivoInteracaoTipoValor,

									PessoaEnderecoUF1,
									PessoaEnderecoCidade1,
									PessoaEnderecoBairro1,
									PessoaEnderecoLogradouro1,
									PessoaEnderecoComplemento1,
									PessoaEnderecoNumero1,
									PessoaEnderecoCEP1,
									PessoaEnderecoLatitude1,
									PessoaEnderecoLongitude1,
									PessoaEnderecoTipo1,

									PessoaEnderecoUF2,
									PessoaEnderecoCidade2,
									PessoaEnderecoBairro2,
									PessoaEnderecoLogradouro2,
									PessoaEnderecoComplemento2,
									PessoaEnderecoNumero2,
									PessoaEnderecoCEP2,
									PessoaEnderecoLatitude2,
									PessoaEnderecoLongitude2,
									PessoaEnderecoTipo2,

									DtAtualizacaoAuto
								)
								Select 
									@dtReferenciaUtilizarMaximo as DtInclusao,
									TabAtendimentoTemp.ContasistemaId,
									TabAtendimentoTemp.ContasistemaIdGuid,
					
									TabAtendimentoTemp.Atendimentoid,
									TabAtendimentoTemp.AtendimentoVersao,
									TabAtendimentoTemp.AtendimentoidGuid,
									TabAtendimentoTemp.AtendimentoDtInclusao,
									TabAtendimentoTemp.AtendimentoDtInicio,
									TabAtendimentoTemp.AtendimentoDtConclusao,
									TabAtendimentoTemp.AtendimentoStatus,
									TabAtendimentoTemp.AtendimentoNegociacaoStatus,
									TabAtendimentoTemp.AtendimentoTipoDirecionamento,
									TabAtendimentoTemp.AtendimentoValorNegocio,
									TabAtendimentoTemp.AtendimentoComissaoNegocio,
	
									TabAtendimentoTemp.ProdutoId,
									TabAtendimentoTemp.ProdutoNome,
									TabAtendimentoTemp.ProdutoUF,
									TabAtendimentoTemp.ProdutoMarco,
				
									TabAtendimentoTemp.CanalId,
									TabAtendimentoTemp.CanalNome,
									TabAtendimentoTemp.CanalMeio,
		
									TabAtendimentoTemp.MidiaId,
									TabAtendimentoTemp.MidiaNome,
									TabAtendimentoTemp.MidiaTipoValor,

									TabAtendimentoTemp.IntegradoraExternaId,
									TabAtendimentoTemp.IntegradoraExternaIdGuid,
									TabAtendimentoTemp.IntegradoraExternaExtensaoLogo,
									TabAtendimentoTemp.IntegradoraExternaNome,
		
									TabAtendimentoTemp.PecaId,
									TabAtendimentoTemp.PecaNome,
		
									TabAtendimentoTemp.CampanhaMarketingId,
									TabAtendimentoTemp.CampanhaMarketingNome,
		
									TabAtendimentoTemp.GrupoPecaMarketingId,
									TabAtendimentoTemp.GrupoPecaMarketingNome,
		
									TabAtendimentoTemp.GrupoId,
									TabAtendimentoTemp.GrupoNome,
									TabAtendimentoTemp.GrupoHierarquia,
									TabAtendimentoTemp.GrupoHierarquiaTipo,
									TabAtendimentoTemp.GrupoTag,
		
									TabAtendimentoTemp.ClassificacaoId,
									TabAtendimentoTemp.ClassificacaoIdGuid, 
									TabAtendimentoTemp.ClassificacaoValor,
									TabAtendimentoTemp.ClassificacaoValor2,
									TabAtendimentoTemp.ClassificacaoOrdem,

									TabAtendimentoTemp.ProspeccaoId,
									TabAtendimentoTemp.ProspeccaoNome,
		
									TabAtendimentoTemp.CampanhaId,
									TabAtendimentoTemp.CampanhaNome,
		
									TabAtendimentoTemp.CriouAtendimentoUsuarioContaSistemaId,
									TabAtendimentoTemp.CriouAtendimentoPessoaNome,
		
									TabAtendimentoTemp.UsuarioContaSistemaId,
									TabAtendimentoTemp.UsuarioContaSistemaIdGuid,
									TabAtendimentoTemp.UsuarioContaSistemaStatus,
		
									TabAtendimentoTemp.PessoaId,
									TabAtendimentoTemp.PessoaNome,
									TabAtendimentoTemp.PessoaApelido,
									TabAtendimentoTemp.PessoaEmail,

									TabAtendimentoTemp.ProdutoSubList,
		
									TabAtendimentoTemp.PessoaProspectId,
									TabAtendimentoTemp.PessoaProspectIdGuid,
									TabAtendimentoTemp.PessoaProspectDtInclusao,
									TabAtendimentoTemp.PessoaProspectNome,
									TabAtendimentoTemp.PessoaProspectEmailList,
									TabAtendimentoTemp.PessoaProspectTelefoneList,
									TabAtendimentoTemp.PessoaProspectCPF,
									TabAtendimentoTemp.PessoaProspectTagList,
									TabAtendimentoTemp.PessoaProspectSexo, 
									TabAtendimentoTemp.PessoaProspectDtNascimento,
									TabAtendimentoTemp.PessoaProspectProfissao, 
		
									TabAtendimentoTemp.AtendimentoConvercaoVenda,
		
									TabAtendimentoTemp.AtendimentoIdMotivacaoNaoConversaoVenda,
									TabAtendimentoTemp.AtendimentoMotivacaoNaoConversaoVenda,

									TabAtendimentoTemp.InteracaoPrimeiraId,
									TabAtendimentoTemp.InteracaoPrimeiraDtFull,

									TabAtendimentoTemp.InteracaoNegociacaoVendaUltimaId,
									TabAtendimentoTemp.InteracaoNegociacaoVendaUltimaDtFull,

									TabAtendimentoTemp.InteracaoUltimaId,
									TabAtendimentoTemp.InteracaoUltimaDtFull,
									TabAtendimentoTemp.InteracaoUltimaTipoValor,
									TabAtendimentoTemp.InteracaoUltimaTipoValorAbreviado,
									TabAtendimentoTemp.InteracaoUltimaDtUtilConsiderar,

									TabAtendimentoTemp.AlarmeUltimoAtivoId,
									TabAtendimentoTemp.AlarmeUltimoAtivoData,
									TabAtendimentoTemp.AlarmeUltimoAtivoInteracaoTipoValor,

									TabAtendimentoTemp.AlarmeProximoAtivoId,
									TabAtendimentoTemp.AlarmeProximoAtivoData,
									TabAtendimentoTemp.AlarmeProximoAtivoInteracaoTipoValor,

									TabAtendimentoTemp.PessoaEnderecoUF1,
									TabAtendimentoTemp.PessoaEnderecoCidade1,
									TabAtendimentoTemp.PessoaEnderecoBairro1,
									TabAtendimentoTemp.PessoaEnderecoLogradouro1,
									TabAtendimentoTemp.PessoaEnderecoComplemento1,
									TabAtendimentoTemp.PessoaEnderecoNumero1,
									TabAtendimentoTemp.PessoaEnderecoCEP1,
									TabAtendimentoTemp.PessoaEnderecoLatitude1,
									TabAtendimentoTemp.PessoaEnderecoLongitude1,
									TabAtendimentoTemp.PessoaEnderecoTipo1,

									TabAtendimentoTemp.PessoaEnderecoUF2,
									TabAtendimentoTemp.PessoaEnderecoCidade2,
									TabAtendimentoTemp.PessoaEnderecoBairro2,
									TabAtendimentoTemp.PessoaEnderecoLogradouro2,
									TabAtendimentoTemp.PessoaEnderecoComplemento2,
									TabAtendimentoTemp.PessoaEnderecoNumero2,
									TabAtendimentoTemp.PessoaEnderecoCEP2,
									TabAtendimentoTemp.PessoaEnderecoLatitude2,
									TabAtendimentoTemp.PessoaEnderecoLongitude2,
									TabAtendimentoTemp.PessoaEnderecoTipo2,

									TabAtendimentoTemp.DtAtualizacaoAuto

								From
									#TabAtendimentoTemp TabAtendimentoTemp WITH (NOLOCK)
								where
									TabAtendimentoTemp.rownumber between @i and @i + @iQtdPorTransaction
							end

						print 'insert ('+convert(varchar(200),@i)+') até ('+convert(varchar(200),(@i + @iQtdPorTransaction))+') - '+ convert(varchar(200) ,CAST((dbo.GetDateCustom() - @dtInicioAux) as time(0)))
									
						set @i = @i + @iQtdPorTransaction + 1

				-- End do While
				END
			print 'END - insert no tabelão - ' + convert(varchar(200) ,CAST((dbo.GetDateCustom() - @dtInicio) as time(0)))
			set @dtInicio = dbo.GetDateCustom()
		
		end
		 
	if (@isExecute = 1 and @tipoProcessamento = 'completo')
		begin
			-- Liga as constraints
			--ALTER TABLE TabelaoAtendimento CHECK CONSTRAINT ALL
			
			-- Liga e Reconstroi os índices
			-- ONLINE = ON, permite o acesso ao dados sem bloqueio a tabela mas é mais demorado
			-- como a tabela é exclusiva setarei OFF nessa operação
			ALTER INDEX ALL ON TabelaoAtendimentoAux REBUILD PARTITION = ALL WITH (ONLINE = ON)
		end

	print 'END - geração dos índices - ' + convert(varchar(200) ,CAST((dbo.GetDateCustom() - @dtInicio) as time(0)))
	set @dtInicio = dbo.GetDateCustom()

	if (@isExecute = 1 and @tipoProcessamento = 'completo')
		begin
			EXEC sp_rename 'TabelaoAtendimento', 'TabelaoAtendimentoAuxOld2';
			EXEC sp_rename 'TabelaoAtendimentoAux', 'TabelaoAtendimento'; 
			EXEC sp_rename 'TabelaoAtendimentoAuxOld2', 'TabelaoAtendimentoAux';
		end

	print 'END - sp_rename ' + convert(varchar(200) ,CAST((dbo.GetDateCustom() - @dtInicio) as time(0)))
	set @dtInicio = dbo.GetDateCustom()

	if (@isExecute = 1 and @tipoProcessamento = 'completo')
		begin
			truncate table TabelaoAtendimentoAux
		end

	if (@isExecute = 1)
		begin
			if (@tipoProcessamento = 'parcial')
				begin
					set @versao = isnull((SELECT MAX(versao) from @TableAlteracoesAux), @versao)
					set @atendimentoId = isnull((select MAX(IdAtendimento) from @TableAlteracoesAux), @atendimentoId)

					set @objJson = JSON_MODIFY(JSON_MODIFY(@objJson,'$.parcialVersao', sys.fn_varbintohexstr(@versao)), '$.parcialAtendimentoId', @atendimentoId)
				end

			if (@tipoProcessamento = 'parcial_completo' or @tipoProcessamento = 'completo')
				begin
					set @versao = isnull((SELECT MAX(versao) from @TableAlteracoesAux), @versao)
					set @atendimentoId = isnull((select MAX(IdAtendimento) from @TableAlteracoesAux), @atendimentoId)

					set @objJson = JSON_MODIFY(JSON_MODIFY(@objJson,'$.parcialCompletoVersao', sys.fn_varbintohexstr(@versao)), '$.parcialCompletoAtendimentoId', @atendimentoId)
					set @objJson = JSON_MODIFY(JSON_MODIFY(@objJson,'$.parcialVersao', sys.fn_varbintohexstr(@versao)), '$.parcialAtendimentoId', @atendimentoId)
				end
					

			update TabelaoLog set TabelaoLog.Obj = @objJson where TabelaoLog.Nome = @BatchNome
		end

	Update 
		TabelaoLog 
	Set
		-- Adiciona 2 milesegundo desde a última execução para considerar todos atualizados desde a última atualização
		-- 2 pq é o mínimo que pode adicionar
		TabelaoLog.Data1 = @dtReferenciaUtilizarMaximo,
		TabelaoLog.Data2 = null,
		TabelaoLog.string1 = @tipoProcessamento,
		TabelaoLog.DtUltimaParcial = case when (@tipoProcessamento = 'parcial' OR @tipoProcessamento = 'parcial_completo') then dbo.GetDateCustom() else TabelaoLog.DtUltimaParcial end,
		TabelaoLog.DtUltimaCompleta = case when @tipoProcessamento = 'completo' then dbo.GetDateCustom() else TabelaoLog.DtUltimaCompleta end
	where
		TabelaoLog.Nome = @BatchNome

	print 'Total de: '+ convert(varchar(45), @iCount) + ' em ' + convert(varchar(200) ,CAST((dbo.GetDateCustom() - @dtInicioGeral) as time(0)));

CREATE procedure [dbo].[ProcGetAgenda] 
(
	@IsAdministradorDoSistema bit,
	@IdContaSistema int,
	@IdUsuarioContaSistemaExecutando int,
	@IdUsuarioContaSistemaFiltrando int,
	@AtendimentoIdGruposAtendimento varchar(max),
	@AlarmeDataInicio datetime,
	@AlarmeDataFim datetime,
	@SomenteNaoConcluido bit,
	@TrazerOsDoUsuario bit,
	@TrazerOsQueUsuarioSegue bit,
	@TrazerTodos bit,
	@InteracaoTipoIds varchar(max),
	
	@PageSize int,
	@PageNumber int,
	@AdicionarProximoRegistro bit,
	@AdicionarQtdRegistro bit
)
as
declare @FirstRow INT;
declare @LastRow INT;
declare @idUsuarioContaSistemaFiltrar int = null;

if @TrazerOsDoUsuario is null begin set @TrazerOsDoUsuario = 0 end
if @TrazerOsQueUsuarioSegue is null begin set @TrazerOsQueUsuarioSegue = 0 end
if @TrazerTodos is null begin set @TrazerTodos = 0 end

-- Caso ambos sejam false irá setar como padrão para trazer somente os do usuário
if @TrazerOsDoUsuario = 0 and @TrazerOsQueUsuarioSegue = 0 begin set @TrazerOsDoUsuario = 1 end 
set @InteracaoTipoIds = dbo.RetNullOrVarChar(@InteracaoTipoIds)

if @PageNumber = 0 begin set @PageNumber = 1 end

set	@FirstRow = (( @PageNumber - 1) * @PageSize)
set	@LastRow = @PageSize
if @AdicionarProximoRegistro <> 0 and @LastRow < 2147483647 begin set @LastRow += 1 end


declare @TableGruposId TABLE
(
	IdGrupo int
)

if @AtendimentoIdGruposAtendimento is not null
	begin
		set @TrazerTodos = 1

		insert @TableGruposId
		(
			IdGrupo
		)
		Select 
			OrderID 
		from 
			SplitIDs(@AtendimentoIdGruposAtendimento) TabSplit
				inner join
			Grupo with(nolock) on Grupo.Id = TabSplit.OrderID and Grupo.IdContaSistema = @IdContaSistema

	end

declare @TableInteracaoTipo TABLE
   (
		id int
   )

if @InteracaoTipoIds is not null
	begin
		insert @TableInteracaoTipo
			(
				id
			)
			Select 
				OrderID 
			from 
				SplitIDs(@InteracaoTipoIds) TabSplit
					inner join
				InteracaoTipo with(nolock) on InteracaoTipo.Id = TabSplit.OrderID and InteracaoTipo.IdContaSistema = @IdContaSistema
	end


if @IdUsuarioContaSistemaFiltrando is not null and @IdUsuarioContaSistemaFiltrando != @IdUsuarioContaSistemaExecutando
	begin
		set @idUsuarioContaSistemaFiltrar = @IdUsuarioContaSistemaFiltrando

		set @TrazerOsDoUsuario = 1
		set @TrazerOsQueUsuarioSegue = 0
		set	@TrazerTodos = 0
	end
else
	begin
		set @idUsuarioContaSistemaFiltrar = @IdUsuarioContaSistemaExecutando
	end;

with paginacao as  
(
	Select 
		row_number() over (order by Alarme.data asc) as 'RowNumber',
		Alarme.Id as IdAlarme,
		Alarme.IdSuperEntidade as IdSuperEntidade,
		Interacao.Id as IdInteracao,
		Interacao.IdInteracaoTipo as IdInteracaoTipo
		
	From
		Alarme with (nolock)
			inner join
		Atendimento with (nolock) on Atendimento.Id = Alarme.IdSuperEntidade
			inner join
		Interacao WITH (NOLOCK) on Interacao.IdAlarme = Alarme.Id
			inner join
		InteracaoTipo with (nolock) on Interacao.IdInteracaoTipo = InteracaoTipo.Id
			left outer join 
		-- se ele é adm e n quer listar somente os atendimentos dele n se faz necessario executar essa pesquisa
		PessoaProspectFidelizado WITH (NOLOCK) on (((@TrazerTodos = 1 or @idUsuarioContaSistemaFiltrar != @IdUsuarioContaSistemaExecutando) and @IsAdministradorDoSistema = 0) and PessoaProspectFidelizado.IdPessoaProspect = Atendimento.idPessoaProspect and PessoaProspectFidelizado.IdCampanha = Atendimento.idCampanha and PessoaProspectFidelizado.DtFimFidelizacao is null and PessoaProspectFidelizado.IdUsuarioContaSistema = @IdUsuarioContaSistemaExecutando)
				
	Where
		Alarme.IdContaSistema = @IdContaSistema
			and
		Atendimento.IdContaSistema = @IdContaSistema
			and
		Atendimento.StatusAtendimento = 'ATENDIDO'
			and
		(
			( (@TrazerOsDoUsuario = 1 or @TrazerTodos = 1) and (Atendimento.IdUsuarioContaSistemaAtendimento = @idUsuarioContaSistemaFiltrar))
				or
			( (@TrazerOsQueUsuarioSegue = 1 or @TrazerTodos = 1) and exists (Select AtendimentoSeguidor.IdUsuarioContaSistema from AtendimentoSeguidor with (nolock) where AtendimentoSeguidor.IdAtendimento = Atendimento.Id and AtendimentoSeguidor.IdUsuarioContaSistema = @idUsuarioContaSistemaFiltrar and AtendimentoSeguidor.Status = 'AT'))
				or
			(
				(
					@TrazerTodos = 1
						or
					@idUsuarioContaSistemaFiltrar != @IdUsuarioContaSistemaExecutando
				)
					and
				(
					(
						@IsAdministradorDoSistema = 1
							or
						exists (Select GrupoHierarquiaUsuarioContaSistema.id from GrupoHierarquiaUsuarioContaSistema WITH (NOLOCK) where GrupoHierarquiaUsuarioContaSistema.idUsuarioContaSistema = @IdUsuarioContaSistemaExecutando and (GrupoHierarquiaUsuarioContaSistema.IdGrupo = PessoaProspectFidelizado.IdGrupo or GrupoHierarquiaUsuarioContaSistema.IdGrupo = Atendimento.idGrupo))
					)
						and
					-- Se faz necessário para trazer apenas os atendimentos do usuário do filtro em questão
					(
						@idUsuarioContaSistemaFiltrar = @IdUsuarioContaSistemaExecutando
							or
						Atendimento.IdUsuarioContaSistemaAtendimento = @idUsuarioContaSistemaFiltrar
					)
				)
			)
		)
			and
		(
			@AtendimentoIdGruposAtendimento is null or EXISTS (Select TabGruposAux.IdGrupo from @TableGruposId TabGruposAux where TabGruposAux.IdGrupo = Atendimento.idGrupo)
		)
			and
		(
			@SomenteNaoConcluido = 0 or Alarme.Status = 'IN'
		)
			and
		(
			@AlarmeDataInicio is null or Alarme.Data >= @AlarmeDataInicio
		)
			and
		(
			@AlarmeDataFim is null or Alarme.Data <= @AlarmeDataFim
		) 
			and
		(
			@InteracaoTipoIds is null or Interacao.IdInteracaoTipo in (select TabAux.id from @TableInteracaoTipo TabAux)
		) 

),
paginacaoCount as  
(
	Select 
		paginacao.RowNumber,
		paginacao.IdAlarme,
		paginacao.IdSuperEntidade,
		paginacao.IdInteracao,
		paginacao.IdInteracaoTipo
	From
		paginacao  WITH (NOLOCK) 
		
	Order by
		paginacao.RowNumber asc
	OFFSET 
		@FirstRow ROWS
    FETCH NEXT 
		@LastRow ROWS ONLY
)
	select
		case when @AdicionarQtdRegistro = 1 then (Select count(paginacao.IdAlarme) from paginacao with (nolock)) end as RowTotal,
		paginacaoCount.RowNumber,

		Alarme.IdGuid as AlarmeIdGuid,
		Alarme.Status as AlarmeStatus,
		Alarme.Data as AlarmeData,
		Alarme.Realizado as AlarmeRealizado,
		Alarme.DataUltimoStatus as AlarmeDataUltimoStatus,

		Atendimento.Id as AtendimentoId,
		Atendimento.idGuid as AtendimentoIdGuid,
		ViewUsuarioContaSistemaDetalhadoAtendimento.PessoaNome as AtendimentoUsuarioNome,
		ViewUsuarioContaSistemaDetalhadoAtendimento.PessoaApelido as AtendimentoUsuarioApelido,
		ViewUsuarioContaSistemaDetalhadoAtendimento.UsuarioContaSistemaIdGuid as AtendimentoUsuarioIdGuid,
		ViewUsuarioContaSistemaDetalhadoAtendimento.UsuarioContaSistemaGuidCorrex as AtendimentoUsuarioIdGuidCorrex,

		Classificacao.Valor as Classificacao,
		Classificacao.Valor2 as ClassificacaoGrupo,
		Classificacao.IdGuid as ClassificacaoIdGuid,

		SuperEntidadePessoaProspect.StrGuid as PessoaProspectIdGuid,
		PessoaProspect.Nome as PessoaProspectNome,

		ViewUsuarioContaSistemaDetalhado.UsuarioContaSistemaIdGuid as AtorUsuarioContaSistemaIdGuid,
		ViewUsuarioContaSistemaDetalhado.PessoaNome as AtorUsuarioContaSistemaNome,
		ViewUsuarioContaSistemaDetalhado.PessoaApelido as AtorUsuarioContaSistemaApelido,
		ViewUsuarioContaSistemaDetalhado.UsuarioContaSistemaGuidCorrex as AtorUsuarioContaSistemaIdGuidCorrex,

		InteracaoTipo.IdGuid as InteracaoTipoIdGuid,
		InteracaoTipo.Tipo as InteracaoTipoTipo,
		InteracaoTipo.Valor as InteracaoTipoValor,

		Interacao.Id as InteracaoId,
		Interacao.IdGuid as InteracaoIdGuid,
		Interacao.DtInclusao as InteracaoDtInclusao,
		Interacao.DtConclusao as InteracaoDtConclusao,
		Interacao.DtInteracao as InteracaoDtInteracao,
		Interacao.Realizado as InteracaoRealizado,
		Interacao.IdUsuarioContaSistema as InteracaoIdUsuarioContaSistema,

		Produto.Nome as ProdutoNome


	from 
		paginacaoCount  with(nolock)
			inner join
		Alarme WITH (NOLOCK) on paginacaoCount.IdAlarme = Alarme.Id
			inner join
		Interacao WITH (NOLOCK) on Interacao.Id = paginacaoCount.IdInteracao
			inner join
		Atendimento WITH (NOLOCK) on Atendimento.id = paginacaoCount.IdSuperEntidade
			inner join
		SuperEntidade SuperEntidadePessoaProspect WITH (NOLOCK) on SuperEntidadePessoaProspect.Id = Atendimento.idPessoaProspect
			inner join
		PessoaProspect WITH (NOLOCK) on PessoaProspect.Id = Atendimento.idPessoaProspect
			left outer join
		ViewUsuarioContaSistemaDetalhado WITH (NOLOCK) on ViewUsuarioContaSistemaDetalhado.UsuarioContaSistemaId = Interacao.IdUsuarioContaSistema
			left outer join
		ViewUsuarioContaSistemaDetalhado ViewUsuarioContaSistemaDetalhadoAtendimento WITH (NOLOCK) on ViewUsuarioContaSistemaDetalhadoAtendimento.UsuarioContaSistemaId = Atendimento.IdUsuarioContaSistemaAtendimento
			left outer join
		InteracaoTipo with (nolock) on InteracaoTipo.Id = paginacaoCount.IdInteracaoTipo
			left outer join
		Classificacao with (nolock) on Classificacao.Id = Atendimento.idClassificacao
			left outer join
		Produto with (nolock) on Produto.Id = Atendimento.idProduto


	-- http://www.sommarskog.se/dyn-search.html
	OPTION (RECOMPILE);

CREATE procedure [dbo].[ProcGetAlertas] 
(
	@IdContaSistema int,
	@IdUsuarioContaSistema int,
	@AlarmeDataInicio datetime,
	@AlarmeDataFim datetime,
	@SomenteNaoConcluido bit,
	@TrazerOsDoUsuario bit,
	@TrazerOsQueUsuarioSegue bit,
	
	@PageSize int,
	@PageNumber int,
	@AdicionarProximoRegistro bit,
	@AdicionarQtdRegistro bit
)
as
declare @FirstRow INT;
declare @LastRow INT;


if @TrazerOsDoUsuario is null begin set @TrazerOsDoUsuario = 0 end
if @TrazerOsQueUsuarioSegue is null begin set @TrazerOsQueUsuarioSegue = 0 end

-- Caso ambos sejam false irá setar como padrão para trazer somente os do usuário
if @TrazerOsDoUsuario = 0 and @TrazerOsQueUsuarioSegue = 0 begin set @TrazerOsDoUsuario = 1 end 

if @PageNumber = 0 begin set @PageNumber = 1 end

set	@FirstRow = (( @PageNumber - 1) * @PageSize)
set	@LastRow = @PageSize
if @AdicionarProximoRegistro <> 0 and @LastRow < 2147483647 begin set @LastRow += 1 end;



with paginacao as  
(
	Select 
		row_number() over (order by Alarme.data asc) as 'RowNumber',
		Alarme.Id as IdAlarme
		
	From
		Alarme with (nolock)
			inner join
		Atendimento  with (nolock) on Atendimento.Id = Alarme.IdSuperEntidade

	Where
		Alarme.IdContaSistema = @IdContaSistema
			and
		Atendimento.IdContaSistema = @IdContaSistema
			and
		(
			(@TrazerOsDoUsuario = 1 and Atendimento.IdUsuarioContaSistemaAtendimento = @IdUsuarioContaSistema)
				or
			(@TrazerOsQueUsuarioSegue = 1 and exists (Select AtendimentoSeguidor.IdUsuarioContaSistema from AtendimentoSeguidor with (nolock) where AtendimentoSeguidor.IdAtendimento = Atendimento.Id and AtendimentoSeguidor.IdUsuarioContaSistema = @IdUsuarioContaSistema and AtendimentoSeguidor.Status = 'AT'))
		)
			and
		(
			@SomenteNaoConcluido = 0 or Alarme.Status = 'IN'
		)
			and
		(
			@AlarmeDataInicio is null or Alarme.Data >= @AlarmeDataInicio
		)
			and
		(
			@AlarmeDataFim is null or Alarme.Data <= @AlarmeDataFim
		) 
),
paginacaoCount as  
(
	Select 
		paginacao.RowNumber,
		paginacao.IdAlarme
	From
		paginacao  WITH (NOLOCK) 
		
	Order by
		paginacao.RowNumber asc
	OFFSET 
		@FirstRow ROWS
    FETCH NEXT 
		@LastRow ROWS ONLY
)
	select
		(Select count(paginacao.IdAlarme) from paginacao with (nolock) where @AdicionarQtdRegistro = 1) as RowTotal,
		paginacaoCount.RowNumber,
		paginacaoCount.IdAlarme as IdAlarme,
		TabelaoAlarme.UsuarioContaSistemaId as IdUsuarioContaSistemaFidelizado,
		TabelaoAlarme.PessoaNome as NomeUsuarioFidelizado,
		TabelaoAlarme.PessoaProspectNome as NomeProspect,

		TabelaoAlarme.InteracaoDtInclusao as DtInclusao,
		TabelaoAlarme.AtendimentoId as IdAtendimento,
		TabelaoAlarme.InteracaoTexto as Detalhe,
		TabelaoAlarme.InteracaoId as IdInteracao,
		TabelaoAlarme.InteracaoInteracaoTipo as Tipo,

		TabelaoAlarme.AlarmeStatus as AlarmeStatus,
		TabelaoAlarme.AlarmeData as DataAlarme
	from 
		paginacaoCount  with(nolock)
			inner join
		TabelaoAlarme WITH (NOLOCK) on paginacaoCount.IdAlarme = TabelaoAlarme.AlarmeId

	-- http://www.sommarskog.se/dyn-search.html
	OPTION (RECOMPILE);

CREATE procedure [dbo].[ProcGetAtendimentoChatNaoAtendidoParaRoleta] 
(
	@qtdPorVez int,
	@dtRecuperar datetime, 
	@dtRecuperarMaximo datetime
)
as

Select 
	top(@qtdPorVez)
	Atendimento.Id as AtendimentoId

From
	Atendimento with (nolock)
		inner join
	SuperEntidade with (nolock) on SuperEntidade.Id = Atendimento.Id
		inner join
	Canal with (nolock) on Canal.Id = Atendimento.IdCanalAtendimento

where
	Canal.Tipo = 'CHAT'
		and
	Atendimento.StatusAtendimento not in ('ENCERRADO', 'ATENDIDO')
		and
	(
		Atendimento.DataFimValidadeAtendimento < @dtRecuperar
			or
		-- Em alguns casos a DataFimValidadeAtendimento ficava nulo e sendo assim nunca era redirecionado
		(
			-- Em alguns casos quando o atendimento encontra-se encerrado e o mesmo prospect volta a solicitar atendimento
			-- a data de inclusão já pode ser muito maior dq a data de inclusão do atendimento
			-- sendo assim ocorria casos que antes do novo lead ser encaminhado ao CHAT
			-- O ATENDIMENTO já era encerrado nessa regra
			-- Foi mudado a regra acrescentando a DataInicioValidadeAtendimento, toda vez que um atendimento é reaberto ou 
			-- transferido essa data é zerada para a data atual para evitar esse problema de atendimentos muito antigos
			(
				Atendimento.DataFimValidadeAtendimento is null
					and
				SuperEntidade.DtInclusao < @dtRecuperarMaximo
			)
				and
			(
				Atendimento.DataInicioValidadeAtendimento is null
					or
				Atendimento.DataInicioValidadeAtendimento < @dtRecuperarMaximo
			)
		)
	);

CREATE procedure [dbo].[ProcGetAtendimentoDirecionarRoletaParaUsuario]
(
	@qtdAtendimentosPorVez int = 10,
	@qtdInteracaoFilaMaxPrioridade int = 20,
	@maxInteracaoFilaParaCancelar int = 35
)

as 
begin

declare @dtNowUtilizar datetime = dbo.GetDateCustom();
declare @horaNowConsiderar time = CONVERT(TIME(0), @dtNowUtilizar);
declare @dtInteracaoFilaRecuperarMax datetime = Dateadd(HOUR, -6, @dtNowUtilizar);

declare @dtInteracaoFilaRecuperarPrioridade datetime = Dateadd(MINUTE, -1, @dtNowUtilizar);

-- Até 4 vezes irá priorizar
-- Acima disso irá executar a cada @dtInteracaoFilaRecuperarPrioridade2
declare @qtdInteracaoFilaMaxPrioridade2 int = 4;
declare @dtInteracaoFilaRecuperarPrioridade2 datetime = Dateadd(MINUTE, -30, @dtNowUtilizar);

declare @statusAtendimentoAguardando varchar(40) = 'AGUARDANDOATENDIMENTO';
declare @tipoDirecionamentoRoleta varchar(20) = 'ROLETA';

declare @canalTipoChat  varchar(20) = 'CHAT';
declare @canalTipoAtivo  varchar(20) = 'ATIVO';
declare @tipoPrioridadeNaoConsiderarHorarioRoleta varchar(20) = 'FILACHAT';

-- SE FAZ NECESSÁRIO PARA EVITAR LER DADOS AINDA NÃO COMITADO
declare @dateConsiderar AS DATETIME = DATEADD(ss, -6, @dtNowUtilizar);

with paginacao as  
(
	Select 
		SuperEntidade.idContaSistema,
		Atendimento.Id,
		Atendimento.idCampanha,
		Atendimento.idPessoaProspect,
		Atendimento.IdCanalAtendimento,
		Canal.Nome as CanalNome,
		Campanha.Nome as CampanhaNome,
		CampanhaCanal.id as CampanhaCanalId,
		CampanhaCanal.TipoPrioridade as CampanhaCanalTipoPrioridade,
		ROW_NUMBER() 
					over (
						PARTITION BY Atendimento.IdContaSistema
						-- isso fará com que os atendimentos que não são de prospecção tenham prioridade
						order by Atendimento.idProspeccao, SuperEntidade.DtInclusao
					) AS RowNumber
	From
		Atendimento with (readpast)
			inner join
		Canal with (nolock) on Atendimento.IdCanalAtendimento = Canal.Id
			inner join
		SuperEntidade with (nolock) on SuperEntidade.Id = Atendimento.Id
			inner join
		Campanha with (nolock) on Campanha.Id = Atendimento.idCampanha
			inner join 
		ContaSistema with (nolock) on ContaSistema.Id = SuperEntidade.idContaSistema
			left outer join
		CampanhaCanal with (nolock) on CampanhaCanal.IdCanal = Canal.Id and CampanhaCanal.IdCampanha = Campanha.Id

		where
		--1 = 2 and
		(
			(
				Campanha.HoraInicioFuncionamentoRoleta is null
					or
				Campanha.HoraFinalFuncionamentoRoleta is null
			)
				or
			(
				@horaNowConsiderar between Campanha.HoraInicioFuncionamentoRoleta and Campanha.HoraFinalFuncionamentoRoleta
			)
			--	or
			--(
			--	CampanhaCanal.TipoPrioridade = @tipoPrioridadeNaoConsiderarHorarioRoleta
			--)
		) 
			and
		Campanha.Status = 'AT'
			and
		Canal.Tipo <> @canalTipoChat
			and
		Canal.Tipo <> @canalTipoAtivo -- or (Canal.Tipo = @canalTipoAtivo and Atendimento.IdUsuarioContaSistemaAtendimento is not null))
			and
		Atendimento.StatusAtendimento = @statusAtendimentoAguardando
			and
		Atendimento.TipoDirecionamento = @tipoDirecionamentoRoleta
			and
		(
			(
				Atendimento.QtdInteracaoFila <= @qtdInteracaoFilaMaxPrioridade2
					and
				(
					Atendimento.DataUltimaInteracaoFila is null
						or
					Atendimento.DataUltimaInteracaoFila <= @dtInteracaoFilaRecuperarPrioridade
				)
			)
				or
			(
				(
					Atendimento.QtdInteracaoFila >= @qtdInteracaoFilaMaxPrioridade2
						and
					Atendimento.QtdInteracaoFila <= @qtdInteracaoFilaMaxPrioridade
				)
					and
				(
					Atendimento.DataUltimaInteracaoFila is null
						or
					Atendimento.DataUltimaInteracaoFila <= @dtInteracaoFilaRecuperarPrioridade2
				)
			)
				or
			(
				(
					Atendimento.QtdInteracaoFila >= @qtdInteracaoFilaMaxPrioridade
						and
					Atendimento.QtdInteracaoFila <= @maxInteracaoFilaParaCancelar
				)
					and
				(
					Atendimento.DataUltimaInteracaoFila is null
						or
					Atendimento.DataUltimaInteracaoFila <= @dtInteracaoFilaRecuperarMax
				)
			)
		) 
			and
		SuperEntidade.DtInclusao < @dateConsiderar
)
	select * from paginacao  
	WHERE RowNumber <= @qtdAtendimentosPorVez

	OPTION (RECOMPILE);
end;

CREATE procedure [dbo].[ProcGetAtendimentoDirecionarUsuarioParaRoleta] 
(
	@qtdPorVez int
)
as

declare @dtNowUtilizar datetime = dbo.GetDateCustom();
declare @statusAtendimentoAguardando varchar(30) = 'AGUARDANDOATENDIMENTO';
declare @tipoDirecionamentoDireto varchar(10) = 'DIRETO';
declare @tipoDirecionamentoStatus varchar(15) = 'PROCESSANDO';
declare @canalTipoChat varchar(10) = 'CHAT';
declare @canalTipoAtivo varchar(10) = 'ATIVO';
declare @enumContaSistemaStatus varchar(2) = 'AT';
declare @horaNowConsiderar time = CONVERT(TIME(0), @dtNowUtilizar);

with paginacao as  
(
	Select 
		Atendimento.Id as AtendimentoId,
		Atendimento.IdUsuarioContaSistemaAtendimento as AtendimentoIdUsuarioContaSistemaAtendimento,
		Pessoa.Nome as AtendimentoUsuarioContaSistemaAtendimentoNome,
		Atendimento.idCampanha as AtendimentoIdCampanha,
		Atendimento.IdCanalAtendimento as AtendimentoIdCanalAtendimento,
		Atendimento.DataInicioValidadeAtendimento as AtendimentoDataInicioValidadeAtendimento,
		Atendimento.DataFimValidadeAtendimento as AtendimentoDataFimValidadeAtendimento,
		Atendimento.idContaSistema as ContaSistemaId,
		ROW_NUMBER() 
						over (
							PARTITION BY Atendimento.IdContaSistema
							-- isso fará com que os atendimentos que não são de prospecção tenham prioridade
							order by Atendimento.id
						) AS RowNumber
	
	From
		Atendimento 
			inner join
		ContaSistema with (nolock) on ContaSistema.Id = Atendimento.IdContaSistema
			inner join
		Campanha with (nolock) on Campanha.Id = Atendimento.idCampanha
			inner join
		Canal with (nolock) on Canal.Id = Atendimento.IdCanalAtendimento
			left outer join
		UsuarioContaSistema  with (nolock) on UsuarioContaSistema.Id = Atendimento.IdUsuarioContaSistemaAtendimento
			left outer join
		Pessoa with (nolock) on Pessoa.id = UsuarioContaSistema.IdPessoa

	where 	
		
		(
			(
				Campanha.HoraInicioFuncionamentoRoleta is null
					or
				Campanha.HoraFinalFuncionamentoRoleta is null
			)
				or
			(
				@horaNowConsiderar between Campanha.HoraInicioFuncionamentoRoleta and Campanha.HoraFinalFuncionamentoRoleta
			)
		) 
			and
		ContaSistema.Status = @enumContaSistemaStatus 
			and
		Canal.Tipo <> @canalTipoChat 
			and
		(Canal.Tipo <> @canalTipoAtivo or (Canal.Tipo = @canalTipoAtivo and Atendimento.IdUsuarioContaSistemaAtendimento is not null))
			and
		Atendimento.StatusAtendimento = @statusAtendimentoAguardando
			and
		Atendimento.TipoDirecionamento = @tipoDirecionamentoDireto
			and
		Atendimento.TipoDirecionamentoStatus = @tipoDirecionamentoStatus 
			and
		(
			Atendimento.DataFimValidadeAtendimento is not null
				and
			Atendimento.DataFimValidadeAtendimento < @dtNowUtilizar
		)
)
	select * from paginacao  
	WHERE RowNumber <= @qtdPorVez

	OPTION (RECOMPILE);

CREATE procedure [dbo].[ProcGetAtendimentoGrupoErrado]
	@idContaSistema as int,
	@idUsuarioContaSistema as int,
	@qtdPorVez as int
 as 
begin


	Select
		TOP (@qtdPorVez) 
			UsuarioContaSistema.idContaSistema, 
			Atendimento.id as idAtendimento, 
			Atendimento.idPessoaProspect as idPessoaProspect, 
			Atendimento.idCampanha, 
			Atendimento.idUsuarioContaSistemaAtendimento, 
			Atendimento.idGrupo

	from
		Atendimento with (nolock)
			inner join
		UsuarioContaSistema with (nolock) on Atendimento.IdUsuarioContaSistemaAtendimento = UsuarioContaSistema.Id
			inner join
		ContaSistema with (nolock) on ContaSistema.Id = UsuarioContaSistema.idContaSistema
			left outer join
		GrupoHierarquiaUsuarioContaSistema with (nolock) on Atendimento.idGrupo = GrupoHierarquiaUsuarioContaSistema.IdGrupo and Atendimento.IdUsuarioContaSistemaAtendimento = GrupoHierarquiaUsuarioContaSistema.IdUsuarioContaSistema
			left outer join
		UsuarioContaSistemaGrupo with (nolock) on UsuarioContaSistemaGrupo.IdUsuarioContaSistema = Atendimento.IdUsuarioContaSistemaAtendimento and UsuarioContaSistemaGrupo.IdGrupo = Atendimento.idGrupo and UsuarioContaSistemaGrupo.DtFim is null
			left outer join
		Grupo with (nolock) on Grupo.Id = Atendimento.idGrupo
	where
		--1 = 2
		--	and
		-- SE FAZ necessário para evitar que atendimentos que estão aguardnado atendimento e esteja nulo não seja afetado
		Atendimento.StatusAtendimento <> 'AGUARDANDOATENDIMENTO'
			and
		(
			@idContaSistema is null or UsuarioContaSistema.idContaSistema = @idContaSistema
		)
			and
		ContaSistema.Status = 'AT'
			and
		-- Se faz necessário para não recuperar atendimentos que estejam no grupo padrão já que se o grupo
		-- é o padrão provavelmente o usuário não está mais ativo ou o grupo do usuário não estão ativados
		(
			Atendimento.idGrupo is null
				or
			Grupo.Padrao = 0
		)
			and
		(
			@idUsuarioContaSistema is null or Atendimento.IdUsuarioContaSistemaAtendimento = @idUsuarioContaSistema
		)
			and
		(
			(
				Atendimento.idGrupo is null
					or
				Grupo.status <> 'AT'
			)
				or
			(
				GrupoHierarquiaUsuarioContaSistema.Id is null
					and
				UsuarioContaSistemaGrupo.id is null
			)
		)

	-- http://www.sommarskog.se/dyn-search.html
	OPTION (RECOMPILE);
end;

CREATE procedure [dbo].[ProcGetAtendimentoRoleta]
	@idContaSistema as int,
	@idUsuarioContaSistema as int,
	@dataDoAtendimento as datetime,
	@tipoCanal varchar(Max),
	@idProduto int,
	@idCampanha int,
	@idAtendimentosIgnorar varchar(max),
	@idAtendimentosPrevilegiar varchar(max),
	@sortBy varchar(60)
 as 
begin
	declare @TableAtendimentosIgnorar TABLE (Id INT)
	declare @TableAtendimentosPrevilegiar TABLE (Id INT)

	set @idAtendimentosIgnorar = dbo.RetNullOrVarChar(@idAtendimentosIgnorar)
	set @idAtendimentosPrevilegiar = dbo.RetNullOrVarChar(@idAtendimentosPrevilegiar)

	if @idAtendimentosIgnorar is not null
		begin
			insert @TableAtendimentosIgnorar (Id)
			select TabAux1.OrderID as Id from dbo.SplitIDs(@idAtendimentosIgnorar) TabAux1
		end

	if @idAtendimentosPrevilegiar is not null
		begin
			insert @TableAtendimentosPrevilegiar (Id)
			select TabAux2.OrderID from dbo.SplitIDs(@idAtendimentosPrevilegiar) TabAux2
		end


	Select
		top 1
		Atendimento.Id as AtendimentoId, 
		TabUsuarioPlantao.* 
	From
		[dbo].[GetCampanhaPlantaoUsuarioContaSistema] (@idContaSistema, @idUsuarioContaSistema, @dataDoAtendimento, @tipoCanal) TabUsuarioPlantao 
			inner join
		Atendimento with (nolock) on TabUsuarioPlantao.IdCampanha = Atendimento.idCampanha and TabUsuarioPlantao.idCanal = Atendimento.IdCanalAtendimento

	where
		Atendimento.idContaSistema = @idContaSistema
			and
		Atendimento.StatusAtendimento = 'AGUARDANDOATENDIMENTO'
			and
		Atendimento.TipoDirecionamento = 'ROLETA'
			and
		Atendimento.IdUsuarioContaSistemaAtendimento is null
			and
		(@idProduto is null or Atendimento.idProduto = @idProduto)
			and
		(@idCampanha is null or Atendimento.idCampanha = @idCampanha)
			and
		(
			TabUsuarioPlantao.QtdMaxCampanhaCanalAtendimentoSimultaneo is null
				or
			TabUsuarioPlantao.QtdMaxCampanhaCanalAtendimentoSimultaneo > TabUsuarioPlantao.QtdCampanhaCanalAtendimentoSimultaneo
		)
			and
		(
			TabUsuarioPlantao.QtdMaxCanalAtendimentoSimultaneo is null
				or
			TabUsuarioPlantao.QtdMaxCanalAtendimentoSimultaneo > TabUsuarioPlantao.QtdCanalAtendimentoSimultaneo
		)
			and
		(
			TabUsuarioPlantao.QtdMaxCampanhaAtendimentoSimultaneo is null
				or
			TabUsuarioPlantao.QtdMaxCampanhaAtendimentoSimultaneo > TabUsuarioPlantao.QtdCampanhaAtendimentoSimultaneo
		)
			and
		(
			@idAtendimentosIgnorar is null
				or
			not exists (Select TableAux.Id from @TableAtendimentosIgnorar TableAux where TableAux.Id = Atendimento.Id)
		)
			and
		(
			@idAtendimentosPrevilegiar is null
				or
			exists (Select TableAux.Id from @TableAtendimentosPrevilegiar TableAux where TableAux.Id = Atendimento.Id)
		)

	ORDER BY 
		CASE 
		WHEN @SortBy is null or @SortBy = 'id' THEN Atendimento.id else 1 END asc, 
		CASE WHEN @SortBy = 'dataultimainteracaofila' THEN Atendimento.DataUltimaInteracaoFila else 1 END asc

	-- http://www.sommarskog.se/dyn-search.html
	OPTION (RECOMPILE);
end;

-- Recupera os produtos e campanhas disponíveis para atendimento para facilitar a oferta ativa
CREATE procedure [dbo].[ProcGetAtendimentoRoletaProduto]
	@idContaSistema as int,
	@idUsuarioContaSistema as int,
	@dataDoAtendimento as datetime,
	@tipoCanal varchar(Max),
	@idAtendimentosIgnorar varchar(max),
	@idAtendimentosPrevilegiar varchar(max)
 as 
begin

	declare @TableAtendimentosIgnorar TABLE (Id INT)
	declare @TableAtendimentosPrevilegiar TABLE (Id INT)

	set @idAtendimentosIgnorar = dbo.RetNullOrVarChar(@idAtendimentosIgnorar)
	set @idAtendimentosPrevilegiar = dbo.RetNullOrVarChar(@idAtendimentosPrevilegiar)

	if @idAtendimentosIgnorar is not null
		begin
			insert @TableAtendimentosIgnorar (Id)
			select TabAux1.OrderID as Id from dbo.SplitIDs(@idAtendimentosIgnorar) TabAux1
		end

	if @idAtendimentosPrevilegiar is not null
		begin
			insert @TableAtendimentosPrevilegiar (Id)
			select TabAux2.OrderID from dbo.SplitIDs(@idAtendimentosPrevilegiar) TabAux2
		end


	Select
		distinct 
			Campanha.Nome as CampanhaNome,
			Campanha.id as CampanhaId,
			Campanha.GUID as CampanhaIdGuid,
			Produto.Nome as ProdutoNome,
			Produto.id as ProdutoId,
			Produto.GUID as ProdutoIdGuid
	From
		-- Se faz necessario atendimento para n correr risco de pegar atendimentos excluidos
		Atendimento  with (nolock)
			inner join
		Campanha with (nolock) on Atendimento.idCampanha = Campanha.Id
			inner join
		[dbo].[GetCampanhaPlantaoUsuarioContaSistema] (@idContaSistema, @idUsuarioContaSistema, @dataDoAtendimento, @tipoCanal) TabUsuarioPlantao on TabUsuarioPlantao.IdCampanha = Atendimento.idCampanha and TabUsuarioPlantao.idCanal = Atendimento.IdCanalAtendimento
			left outer join
		Produto with (nolock) on Produto.Id = Atendimento.idProduto
	where
		Atendimento.idContaSistema = @idContaSistema
			and
		Atendimento.StatusAtendimento = 'AGUARDANDOATENDIMENTO'
			and
		Atendimento.TipoDirecionamento = 'ROLETA'
			and
		Atendimento.IdUsuarioContaSistemaAtendimento is null
			and
		(
			TabUsuarioPlantao.QtdMaxCampanhaCanalAtendimentoSimultaneo is null
				or
			TabUsuarioPlantao.QtdMaxCampanhaCanalAtendimentoSimultaneo > TabUsuarioPlantao.QtdCampanhaCanalAtendimentoSimultaneo
		)
			and
		(
			TabUsuarioPlantao.QtdMaxCanalAtendimentoSimultaneo is null
				or
			TabUsuarioPlantao.QtdMaxCanalAtendimentoSimultaneo > TabUsuarioPlantao.QtdCanalAtendimentoSimultaneo
		)
			and
		(
			TabUsuarioPlantao.QtdMaxCampanhaAtendimentoSimultaneo is null
				or
			TabUsuarioPlantao.QtdMaxCampanhaAtendimentoSimultaneo > TabUsuarioPlantao.QtdCampanhaAtendimentoSimultaneo
		)
			and
		(
			@idAtendimentosIgnorar is null
				or
			not exists (Select TableAux.Id from @TableAtendimentosIgnorar TableAux where TableAux.Id = Atendimento.Id)
		)
			and
		(
			@idAtendimentosPrevilegiar is null
				or
			exists (Select TableAux.Id from @TableAtendimentosPrevilegiar TableAux where TableAux.Id = Atendimento.Id)
		)


	Order by
		Produto.Nome

	-- http://www.sommarskog.se/dyn-search.html
	OPTION (RECOMPILE);

end;

CREATE procedure [dbo].[ProcGetAtendimentos] 
(
	@IdContaSistema int,
	@IsAdministradorDoSistema bit,
	@IdUsuarioContaSistemaExecutando int,
	@IdAtendimento int,
	@CodigoOuTelefone varchar(15),
	@IdGuidAtendimento char(36),
	@KeyExterno varchar(200),
	@KeyMaxVendas varchar(50),
	@SomenteAtendimentoDoUsuario bit,
	@SomenteAtendimentoUsuarioContaSistemaExecutandoSegue bit,
	@ProspectNome varchar(150),
	@ProspectNomeComecaCom varchar(150),
	@ProspectEmail varchar(100),
	@StatusAtendimento varchar(1000),
	@StatusAtendimentoDiferente varchar(1000),
	@IdClassificacao int,
	@ClassificacaoGrupo varchar(150),
	@UsuarioNome varchar(150),
	@UsuarioNomeComecaCom varchar(150),
	@UsuarioEmail varchar(100),
	@AtendimentoIdMotivacaoNaoConversaoVenda int,
	@AtendimentoIdGruposAtendimento varchar(max),
	@UsuarioUltimoQueAtendeuEmail varchar(100),
	@IntervaloInclusaoDoAtendimentoInicio datetime,
	@IntervaloInclusaoDoAtendimentoFim datetime,
	@UltimaInteracaoProspectDataInicio datetime,
	@UltimaInteracaoProspectDataFim datetime,	
	@UltimaInteracaoUsuarioDataInicio datetime,
	@UltimaInteracaoUsuarioDataFim datetime,
	@IntervaloAtendimentoAtendidoInicio datetime,
	@IntervaloAtendimentoAtendidoFim datetime,	
	@UFProduto char(2),
	@idCampanha int,
	@idProduto int,
	@idCanal int,
	@IdUsuarioContaSistemaFiltro int,
	@TelefoneDDD varchar(2),
	@TelefoneNumero varchar(9),
	@ProspectCPF varchar(14),
	@UsarPesquisaComOr bit,
	@PessoaPropsectTag varchar(max),
	@IdsBookMarks varchar(max),

	@IdsMidias varchar(max),
	@IdsPecas varchar(max),

	-- Tem como objetivo ser usado junto com os filtros de interacao
	@InteracaoAtorPartida varchar(30),

	-- Tem como objetivo trazer atendimentos que não tiveram certo tipos de interação no período repassado @IntervaloInteracaoSemInicio e @IntervaloPendenciaFim
	@IdsInteracaoSemInteracaoTipo varchar(max),

	-- Tem como objetivo trazer atendimentos que tiveram certo tipos de interação no período repassado @IntervaloInteracaoComInicio e @IntervaloInteracaoComFim
	@IdsInteracaoComInteracaoTipo varchar(max),

	-- recupera apenas propsects que possuem telefone ou não, caso true e false
	@SomentePessoaPropsectComTelefone bit,
	-- recupera apenas propsects que possuem email ou não, caso true e false
	@SomentePessoaPropsectComEmail bit,

	-- quantidade de dias que o atendimento será perdido por falta de interacao
	@AtendimentoParaEncerrarQtdDiasMin int,
	@AtendimentoParaEncerrarQtdDiasMax int,

	-- atendimentos com alarmes para vencer entre o range repassado
	@IntervaloAlarmeInicio datetime,
	@IntervaloAlarmeFim datetime,	

	-- retornará atendimentos com pendências
	-- Será considerado pendências:
	--	* todos que se encerra no range repassado
	--	* todos sem agendamentos
	@IntervaloPendenciaInicio datetime,
	@IntervaloPendenciaFim datetime,

	-- Prazo em que determinado atendimento está sem interacao
	@IntervaloInteracaoSemInicio datetime,
	@IntervaloInteracaoSemFim datetime,

	-- Prazo em que determinado atendimento teve uma interação
	@IntervaloInteracaoComInicio datetime,
	@IntervaloInteracaoComFim datetime,

	-- atendimentos que não tem próximo passo
	@SomenteAtendimentosSemProximoPasso bit,

	-- prospects que deram aceite na política de privacidade
	@SomenteProspectPoliticaPrivacidadeAceite bit,

	-- prospects que deram aceite na política de privacidade
	@SomenteProspectAnonimizados bit,

	-- prospects que deram aceite na política de privacidade
	@idProspectPoliticaPrivacidadeAceite int,

	-- retorna apenas os ids, sem dados adicionais
	@SomenteId bit,
	
	@OrderBy varchar(100),
	@PageSize INT,
	@PageNumber INT,
	@AdicionarProximoRegistro bit,
	@AdicionarQtdRegistro bit
) 
as
declare @dtNow datetime = dbo.getDateCustom();
declare @FirstRow INT;
declare @LastRow INT;

if @PageNumber = 0 begin set @PageNumber = 1 end

set	@FirstRow = (( @PageNumber - 1) * @PageSize)
set	@LastRow = @PageSize
if @AdicionarProximoRegistro <> 0 and @LastRow < 2147483647 begin set @LastRow += 1 end;

declare @strIfNull as varchar(1) = 'æ'

-- Seta para evitar que sejam localizado string vazia, quando vazia setara null
set @KeyExterno = dbo.RetNullOrVarChar(@KeyExterno)
set @IdGuidAtendimento = dbo.RetNullOrVarChar(@IdGuidAtendimento)
set @KeyMaxVendas = dbo.RetNullOrVarChar(@KeyMaxVendas)
set @ProspectNome = dbo.GetNomeComLikeFormatado(dbo.RetVarCharIsNullOrWhiteSpace(@ProspectNome, @strIfNull))
set @ProspectNomeComecaCom = dbo.RetNullOrVarChar(@ProspectNomeComecaCom)
set @ProspectEmail = dbo.RetNullOrVarChar(@ProspectEmail)
set @StatusAtendimento = dbo.RetNullOrVarChar(@StatusAtendimento)
set @StatusAtendimentoDiferente = dbo.RetNullOrVarChar(@StatusAtendimentoDiferente)
set @AtendimentoIdGruposAtendimento = dbo.RetNullOrVarChar(@AtendimentoIdGruposAtendimento) 
set @UsuarioNome = dbo.RetVarCharIsNullOrWhiteSpace(@UsuarioNome, @strIfNull)
set @UsuarioNomeComecaCom = dbo.RetNullOrVarChar(@UsuarioNomeComecaCom)
set @UsuarioEmail = dbo.RetVarCharIsNullOrWhiteSpace(@UsuarioEmail, @strIfNull)
set @UsuarioUltimoQueAtendeuEmail = dbo.RetNullOrVarChar(@UsuarioUltimoQueAtendeuEmail)
set @UFProduto = dbo.RetNullOrVarChar(@UFProduto)
set @TelefoneDDD = dbo.RetNullOrVarChar(@TelefoneDDD)
set @TelefoneNumero = dbo.RetNullOrVarChar(@TelefoneNumero)
set @CodigoOuTelefone = dbo.RetNullOrVarChar(@CodigoOuTelefone)
set @ProspectCPF = dbo.RetNullOrVarChar(@ProspectCPF)
set @OrderBy = dbo.RetNullOrVarChar(@OrderBy)
set @ClassificacaoGrupo = dbo.RetNullOrVarChar(@ClassificacaoGrupo)
set @UsarPesquisaComOr = dbo.RetBitNotNull(@UsarPesquisaComOr, 0)
set @PessoaPropsectTag = dbo.RetNullOrVarChar(@PessoaPropsectTag)
set @IdsBookMarks = dbo.RetNullOrVarChar(@IdsBookMarks)
set @IdsMidias = dbo.RetNullOrVarChar(@IdsMidias)
set @IdsPecas = dbo.RetNullOrVarChar(@IdsPecas)
set @SomenteAtendimentosSemProximoPasso = dbo.RetBitNotNull(@SomenteAtendimentosSemProximoPasso, 0)
set @SomenteProspectAnonimizados = dbo.RetBitNotNull(@SomenteProspectAnonimizados, 0)

declare @IntervaloEncerrarFim datetime = case when @AtendimentoParaEncerrarQtdDiasMax is not null and @AtendimentoParaEncerrarQtdDiasMax >= 0 then dateadd(day, @AtendimentoParaEncerrarQtdDiasMax + 1, @dtNow) else null end
declare @IntervaloEncerrarInicio datetime = case when @IntervaloEncerrarFim is not null and @AtendimentoParaEncerrarQtdDiasMin > @AtendimentoParaEncerrarQtdDiasMax then @IntervaloEncerrarFim else dateadd(day, @AtendimentoParaEncerrarQtdDiasMin + 1, @dtNow) end

declare @QtdAtendimento int = 0;

declare @TableAtendimentosAux TABLE
   (
		idAtendimento int,
		idUsuarioContaSistemaAtendimento int
   )

declare @TableAtendimentoStatus TABLE
(
	StatusAtendimento varchar(100)
)

declare @TableAtendimentoStatusDiferente TABLE
(
	StatusAtendimento varchar(100)
)

declare @TablePessoaProspectTag TABLE
(
	IdTag int
)

declare @TableGruposId TABLE
(
	IdGrupo int
)

declare @TableBookMarks TABLE
(
	IdBookMark int,
	IdUsuarioContaSistema int
)

declare @TableMidias TABLE
(
	IdMidia int
)

declare @TablePecas TABLE
(
	IdPeca int
)


if @AtendimentoIdGruposAtendimento is not null
	begin
		insert @TableGruposId
		(
			IdGrupo
		)
		Select 
			OrderID 
		from 
			SplitIDs(@AtendimentoIdGruposAtendimento) TabSplit
				inner join
			Grupo with(nolock) on Grupo.Id = TabSplit.OrderID and Grupo.IdContaSistema = @IdContaSistema

	end


-- Caso alguns parâmetros sejam repassados deverá trazer somente atendimentos atendidos
if	@UltimaInteracaoUsuarioDataInicio  is not null or @UltimaInteracaoUsuarioDataFim is not null or
	@UltimaInteracaoProspectDataInicio is not null or @UltimaInteracaoProspectDataFim is not null or
	@SomenteAtendimentosSemProximoPasso = 1
	begin
		set @StatusAtendimento = 'ATENDIDO'
	end


if @IntervaloPendenciaFim is not null and @IntervaloPendenciaFim >= @dtNow
	begin

		insert @TableAtendimentosAux
		(
			idAtendimento
		)
		Select
				TabAux.idAtendimento
		From
			[GetAtendimentosPendentes](@IdContaSistema, @IdUsuarioContaSistemaExecutando, @IdUsuarioContaSistemaExecutando, @IntervaloPendenciaInicio, @IntervaloPendenciaFim, 1) TabAux
		-- não é mais necessário pois uso agora o exists
		--where
		--	-- Se faz necessário para não correr o risco de ter mais de um e trazer atendimento duplicado na query principal
		--	not exists (Select TabAux2.idAtendimento from @TableAtendimentosAux TabAux2 where TabAux2.idAtendimento = TabAux.idAtendimento)
	end

if @IntervaloAlarmeInicio is not null or @IntervaloAlarmeFim is not null
	begin

		insert @TableAtendimentosAux
		(
			idAtendimento
		)
		Select
				TabAux.idAtendimento
		From
			[GetAtendimentoCompromisso](@IdContaSistema, @IdUsuarioContaSistemaExecutando, @IdUsuarioContaSistemaExecutando, @IntervaloAlarmeInicio, @IntervaloAlarmeFim, 1) TabAux
		-- não é mais necessário pois uso agora o exists
		--where
		--	-- Se faz necessário para não correr o risco de ter mais de um e trazer atendimento duplicado na query principal
		--	not exists (Select TabAux2.idAtendimento from @TableAtendimentosAux TabAux2 where TabAux2.idAtendimento = TabAux.idAtendimento)
	end

if @IntervaloEncerrarFim is not null 
	begin

		insert @TableAtendimentosAux
		(
			idAtendimento
		)
		Select
				TabAux.AtendimentoId
		From
			[dbo].[GetAtendimentosEncerramentoAutomatico] (@IdContaSistema,	@IdUsuarioContaSistemaExecutando, @IdUsuarioContaSistemaExecutando,	@IntervaloEncerrarInicio, @IntervaloEncerrarFim, 999999, 'ANALITICO')  TabAux
		-- não é mais necessário pois uso agora o exists
		--where
		--	-- Se faz necessário para não correr o risco de ter mais de um e trazer atendimento duplicado na query principal
		--	not exists (Select TabAux2.idAtendimento from @TableAtendimentosAux TabAux2 where TabAux2.idAtendimento = TabAux.AtendimentoId)
	end


-- Caso seja repassado o status do atendimento irá inserir em uma tabela temporária para localizar abaixo
if @StatusAtendimento is not null 
	begin
		insert @TableAtendimentoStatus
		Select OrderID from SplitIDstring(@StatusAtendimento)

	end;

-- Caso seja repassado o status do atendimento irá inserir em uma tabela temporária para localizar abaixo
if @StatusAtendimentoDiferente is not null 
	begin
		insert @TableAtendimentoStatusDiferente
		Select OrderID from SplitIDstring(@StatusAtendimentoDiferente)

	end;

-- Caso seja repassado IDTAG da pessoaprospect
if @PessoaPropsectTag is not null 
	begin
		insert @TablePessoaProspectTag
		Select OrderID from SplitIDs(@PessoaPropsectTag)

	end;

if @IdsBookMarks is not null 
	begin
		insert @TableBookMarks (IdBookMark, IdUsuarioContaSistema)
		Select 
			OrderID,
			@IdUsuarioContaSistemaExecutando
		from 
			SplitIDs(@IdsBookMarks) TabAux
	end;

if @IdsMidias is not null 
	begin
		insert @TableMidias
		Select 
			OrderID
		from 
			SplitIDs(@IdsMidias) TabAux
	end;

if @IdsPecas is not null 
	begin
		insert @TablePecas
		Select 
			OrderID
		from
			SplitIDs(@IdsPecas)
	end;

-- se faz necessário pois caso esteja passando o id de um usuário seguinifica que não deve ser apenas os seus atendimentos
if @IdUsuarioContaSistemaFiltro is not null or @AtendimentoIdGruposAtendimento is not null
	begin
		set @SomenteAtendimentoDoUsuario = 0
		set @SomenteAtendimentoUsuarioContaSistemaExecutandoSegue = 0
	end;


with paginacao as  
(
	Select
		-- row_number() over (order by Atendimento.DtInicioAtendimento desc, atendimento.Id desc) as 'RowNumber',
		row_number() over (order by Atendimento.DtInicioAtendimento desc) as 'RowNumber',
		Atendimento.Id as idAtendimento,
		PessoaProspect.Id as idPessoaProspect,
		TabelaoAtendimento.AtendimentoId as idAtendimentoTabelaoAtendimento,
		Atendimento.idGuid
							
	From
		Atendimento WITH (NOLOCK) 
			inner join
		PessoaProspect  WITH (NOLOCK) on PessoaProspect.id = atendimento.idPessoaProspect
			left outer join
		TabelaoAtendimento WITH (NOLOCK) on Atendimento.id = TabelaoAtendimento.AtendimentoId
			left outer join
		-- Seleciona para verificar se o usuario que esta executando e adm da campanha, caso seja o mesmo podera visualizar os registros
		CampanhaAdministrador WITH (NOLOCK) on (@IsAdministradorDoSistema = 0 and CampanhaAdministrador.idCampanha = Atendimento.IdCampanha and CampanhaAdministrador.idUsuarioContaSistema = @IdUsuarioContaSistemaExecutando)
			left outer join
		AtendimentoSeguidor on AtendimentoSeguidor.IdAtendimento = Atendimento.Id and AtendimentoSeguidor.IdUsuarioContaSistema = @IdUsuarioContaSistemaExecutando and AtendimentoSeguidor.Status = 'AT'
			left outer join 
		-- se ele é adm e n quer listar somente os atendimentos dele n se faz necessario executar essa pesquisa
		PessoaProspectFidelizado WITH (NOLOCK) on ((@IsAdministradorDoSistema = 0 or @SomenteAtendimentoDoUsuario = 1) and PessoaProspectFidelizado.IdPessoaProspect = Atendimento.idPessoaProspect and PessoaProspectFidelizado.IdCampanha = Atendimento.idCampanha and PessoaProspectFidelizado.DtFimFidelizacao is null and PessoaProspectFidelizado.IdUsuarioContaSistema = @IdUsuarioContaSistemaExecutando)
	
	Where
		Atendimento.idContaSistema = @IdContaSistema 
			and
		(
			(
				(@SomenteAtendimentoDoUsuario = 0 or Atendimento.IdUsuarioContaSistemaAtendimento = @IdUsuarioContaSistemaExecutando)
			)
				and
			(
				(@SomenteAtendimentoUsuarioContaSistemaExecutandoSegue = 0 or AtendimentoSeguidor.IdUsuarioContaSistema = @IdUsuarioContaSistemaExecutando)
			)
				and
			(
				-- caso seja somente os do usuário n faz sentido fazer as verificações abaixo
				@SomenteAtendimentoDoUsuario = 1
					or

				@SomenteAtendimentoUsuarioContaSistemaExecutandoSegue = 1
					or

				AtendimentoSeguidor.id is not null
					or

				-- caso seja administrador do sistema não irá considerar a hierarquia de grupos
				@IsAdministradorDoSistema = 1
					or

				-- caso seja administraodr da campanha todos os atendimentos da mesmo o usuário poderá ver
				CampanhaAdministrador.Id is not null
					or

				-- O usuário detem a fidelização do prospect
				PessoaProspectFidelizado.id is not null
					or
				-- Usuário não está fidelizado a ninguém e o atendimento está para o prospect, nesse caso provavelmente aguardando para ser atendido

				Atendimento.IdUsuarioContaSistemaAtendimento = @IdUsuarioContaSistemaExecutando
					or

				exists (Select GrupoHierarquiaUsuarioContaSistema.id from GrupoHierarquiaUsuarioContaSistema WITH (NOLOCK) where GrupoHierarquiaUsuarioContaSistema.idUsuarioContaSistema = @IdUsuarioContaSistemaExecutando and (GrupoHierarquiaUsuarioContaSistema.IdGrupo = PessoaProspectFidelizado.IdGrupo or GrupoHierarquiaUsuarioContaSistema.IdGrupo = Atendimento.idGrupo))
			)
		)
			and
		(
			(
				@IntervaloPendenciaFim is null and 
				@IntervaloAlarmeInicio is null and 
				@IntervaloAlarmeFim is null and
				@IntervaloEncerrarFim is null
			) 
				or 
			exists (select TableAtendimentosAux.idAtendimento from @TableAtendimentosAux TableAtendimentosAux where TableAtendimentosAux.idAtendimento = Atendimento.Id)
		)
			and
		(
			@StatusAtendimentoDiferente is null or Atendimento.StatusAtendimento not in (Select TabAuxStatusDifernete.StatusAtendimento from @TableAtendimentoStatusDiferente TabAuxStatusDifernete)
		)	
			and
		(
			@AtendimentoIdMotivacaoNaoConversaoVenda is null or (Atendimento.IdMotivacaoNaoConversaoVenda = @AtendimentoIdMotivacaoNaoConversaoVenda and Atendimento.StatusAtendimento = 'ENCERRADO')
		)
			and
		(
			(@AtendimentoIdMotivacaoNaoConversaoVenda is not null or @StatusAtendimento is null) or Atendimento.StatusAtendimento in (Select TabAuxStatus.StatusAtendimento from @TableAtendimentoStatus TabAuxStatus)
		)
			and
		(
			@SomenteAtendimentoUsuarioContaSistemaExecutandoSegue = 0 or AtendimentoSeguidor.Id is not null
		)
			and	
		(
			@IdAtendimento is null or Atendimento.Id = @IdAtendimento
		)
			and	
		(
			@IdGuidAtendimento is null or Atendimento.idGuid = @IdGuidAtendimento
		)
			and
		(
			@KeyMaxVendas is null or exists (select id from PessoaProspectIntegracaoLog WITH (NOLOCK) where PessoaProspectIntegracaoLog.IdAtendimento = Atendimento.id and PessoaProspectIntegracaoLog.KeyMaxVendas = @KeyMaxVendas)
		)		
			and
		(
			@KeyExterno is null or exists (select id from PessoaProspectIntegracaoLog WITH (NOLOCK) where PessoaProspectIntegracaoLog.IdAtendimento = Atendimento.id and PessoaProspectIntegracaoLog.KeyExterno = @KeyExterno)
		)		
	
			and
		(
			@PessoaPropsectTag is null or exists (Select TabAuxTag.IdTag from @TablePessoaProspectTag TabAuxTag inner join PessoaProspectTag with (nolock) on TabAuxTag.IdTag = PessoaProspectTag.IdTag and Atendimento.idPessoaProspect = PessoaProspectTag.IdPessoaProspect)
		)
			and
		(
			@AtendimentoIdGruposAtendimento is null or EXISTS (Select TabGruposAux.IdGrupo from @TableGruposId TabGruposAux where  TabGruposAux.IdGrupo = Atendimento.idGrupo)
		)
			and
		(
			@IdsBookMarks is null or EXISTS (Select BookmarkSuperEntidade.IdBookmark from BookmarkSuperEntidade with (nolock) inner join @TableBookMarks TabAuxBookMarks on BookmarkSuperEntidade.IdSuperEntidade = Atendimento.Id and TabAuxBookMarks.IdBookMark = BookmarkSuperEntidade.IdBookmark and TabAuxBookMarks.IdUsuarioContaSistema = BookmarkSuperEntidade.IdUsuarioContaSistema)
		)
			and
		(
			@IdsMidias is null or EXISTS (Select TabMidias.IdMidia from @TableMidias TabMidias where TabMidias.IdMidia = Atendimento.idMidia)
		)
			and
		(
			@IdsPecas is null or EXISTS (Select TabPecas.IdPeca from @TablePecas TabPecas where TabPecas.IdPeca = Atendimento.idPeca)
		)
			and
		(
			@IdClassificacao is null or Atendimento.idClassificacao = @IdClassificacao
		)
			and
		(
			@ClassificacaoGrupo is null or TabelaoAtendimento.ClassificacaoValor2 = @ClassificacaoGrupo
		)
			and
		(
			@idCampanha is null or Atendimento.IdCampanha = @idCampanha
		)
			and
		(
			@idProduto is null or Atendimento.IdProduto = @idProduto
		)	
			and
		(
			@idCanal is null or Atendimento.IdCanalAtendimento = @idCanal
		)			
			and
		(
			@UFProduto is null or TabelaoAtendimento.ProdutoUF = @UFProduto
		)				
			and
		(
			(@UsuarioNome = @strIfNull and @UsuarioNomeComecaCom is null and @UsuarioEmail = @strIfNull)
				or
			exists (
						Select usuario.UsuarioContaSistemaId
						from
							ViewUsuarioContaSistemaDetalhado usuario with (nolock) 
						where
							usuario.UsuarioContaSistemaId = Atendimento.IdUsuarioContaSistemaAtendimento
								and
							(
								@UsuarioNome = @strIfNull or usuario.PessoaNome like '%'+ @UsuarioNome + '%'
							)
								and
							(
								@UsuarioNomeComecaCom is null or usuario.PessoaNome like @UsuarioNomeComecaCom +'%'
							)	
								and
							(
								@UsuarioEmail = @strIfNull or usuario.PessoaEmail like '%'+ @UsuarioEmail + '%'
							)
					)
		)
			and
		(
			@IntervaloInclusaoDoAtendimentoInicio is null or Atendimento.DtInclusao >= @IntervaloInclusaoDoAtendimentoInicio
		)
			and
		(
			@IntervaloInclusaoDoAtendimentoFim is null or Atendimento.DtInclusao <= @IntervaloInclusaoDoAtendimentoFim
		)				
			and
		(
			@UltimaInteracaoUsuarioDataInicio is null or Atendimento.InteracaoUsuarioUltimaDt >= @UltimaInteracaoUsuarioDataInicio
		)
			and
		(
			@UltimaInteracaoUsuarioDataFim is null or Atendimento.InteracaoUsuarioUltimaDt <= @UltimaInteracaoUsuarioDataFim
		)
			and
		(
			@IntervaloAtendimentoAtendidoInicio is null or Atendimento.DtInicioAtendimento >= @IntervaloAtendimentoAtendidoInicio
		)
			and
		(
			@IntervaloAtendimentoAtendidoFim is null or Atendimento.DtInicioAtendimento <= @IntervaloAtendimentoAtendidoFim
		)
			and
		-- Trás atendimentos sem agendamento e/ou próximo passo
		(
			@SomenteAtendimentosSemProximoPasso = 0
				or 
			(TabelaoAtendimento.AlarmeUltimoAtivoId is null or TabelaoAtendimento.AlarmeUltimoAtivoData < @dtNow)
		)
			and
		-- Trás atendimentos que possui ou não telefone
		(
			@SomentePessoaPropsectComTelefone is null
				or 
			(@SomentePessoaPropsectComTelefone = 1 and exists (Select top 1 PessoaProspectTelefone.id from PessoaProspectTelefone with (nolock) where PessoaProspectTelefone.IdPessoaProspect = Atendimento.idPessoaProspect) )
				or 
			(@SomentePessoaPropsectComTelefone = 0 and not exists (Select top 1 PessoaProspectTelefone.id from PessoaProspectTelefone with (nolock) where PessoaProspectTelefone.IdPessoaProspect = Atendimento.idPessoaProspect) )
		)
			and
		-- Trás atendimentos que possui ou não email
		(
			@SomentePessoaPropsectComEmail is null
				or 
			(@SomentePessoaPropsectComEmail = 1 and exists (Select top 1 PessoaProspectEmail.id from PessoaProspectEmail with (nolock) where PessoaProspectEmail.IdPessoaProspect = Atendimento.idPessoaProspect) )
				or 
			(@SomentePessoaPropsectComEmail = 0 and not exists (Select top 1 PessoaProspectEmail.id from PessoaProspectEmail with (nolock) where PessoaProspectEmail.IdPessoaProspect = Atendimento.idPessoaProspect) )
		)
			and
		-- Trás atendimentos que possui ou não email
		(
			@SomenteProspectPoliticaPrivacidadeAceite is null
				or 
			(@SomenteProspectPoliticaPrivacidadeAceite = 1 and exists (Select top 1 PoliticaDePrivacidadePessoaProspect.id from PoliticaDePrivacidadePessoaProspect with (nolock) where PoliticaDePrivacidadePessoaProspect.IdPessoaProspect = Atendimento.idPessoaProspect) )
				or 
			(@SomenteProspectPoliticaPrivacidadeAceite = 0 and not exists (Select top 1 PessoaProspectEmail.id from PessoaProspectEmail with (nolock) where PessoaProspectEmail.IdPessoaProspect = Atendimento.idPessoaProspect) )
		)
			and
		(
			@idProspectPoliticaPrivacidadeAceite is null or exists (Select top 1 PoliticaDePrivacidadePessoaProspect.id from PoliticaDePrivacidadePessoaProspect with (nolock) where PoliticaDePrivacidadePessoaProspect.IdPessoaProspect = Atendimento.idPessoaProspect and PoliticaDePrivacidadePessoaProspect.IdPoliticaDePrivacidade = @idProspectPoliticaPrivacidadeAceite)
		)	
			and
		(
			@SomenteProspectAnonimizados = 0 or PessoaProspect.IdUsuarioContaSistemaAnonimizado is not null
		)	
		-----------------------------------------------------------------
		-----------------------------------------------------------------
		---- .: Início :.
		---- Verifica se deverá ser usado o filtro usando Or ou And
		---- Em alguns campos específicos abaixo
		-----------------------------------------------------------------
		-----------------------------------------------------------------
			and
		(
			@UsarPesquisaComOr = 1
				or
			(
				(
					@IdUsuarioContaSistemaFiltro is null or PessoaProspectFidelizado.IdUsuarioContaSistema = @IdUsuarioContaSistemaFiltro OR Atendimento.IdUsuarioContaSistemaAtendimento = @IdUsuarioContaSistemaFiltro
				)
					and
				(
					--@ProspectNome = @strIfNull or PessoaProspect.Nome like'%'+ @ProspectNome + '%'
					-- está sendo usado PessoaProspect.idContaSistema = @IdContaSistema por causa do índice criado para nome e idContaSistema
					@ProspectNome = @strIfNull or (PessoaProspect.Nome like '%' + @ProspectNome and PessoaProspect.idContaSistema = @IdContaSistema)
				)
					and
				(
					-- está sendo usado PessoaProspect.idContaSistema = @IdContaSistema por causa do índice criado para nome e idContaSistema
					@ProspectNomeComecaCom is null or (PessoaProspect.Nome like @ProspectNomeComecaCom+'%' and PessoaProspect.idContaSistema = @IdContaSistema)
				)		
					and
				(
					--@ProspectEmail is null or  Exists ( Select id from  PessoaProspectEmail WITH (NOLOCK) where PessoaProspectEmail.IdPessoaProspect = Atendimento.idPessoaProspect and PessoaProspectEmail.Email like '%'+ @ProspectEmail + '%')
					--@ProspectEmail is null or  Exists ( Select id from  PessoaProspectEmail WITH (NOLOCK) where PessoaProspectEmail.IdPessoaProspect = Atendimento.idPessoaProspect and PessoaProspectEmail.Email like '%'+ @ProspectEmail + '%')
					@ProspectEmail is null or  Exists ( Select id from  PessoaProspectEmail WITH (NOLOCK) where PessoaProspectEmail.IdPessoaProspect = Atendimento.idPessoaProspect and PessoaProspectEmail.Email like @ProspectEmail + '%')
				)
					and
				(
					@ProspectCPF is null or  Exists ( Select id from  PessoaProspectDocumento WITH (NOLOCK) where PessoaProspectDocumento.IdPessoaProspect = Atendimento.idPessoaProspect and PessoaProspectDocumento.TipoDoc = 'CPF' and PessoaProspectDocumento.Doc = @ProspectCPF)
				)
					and
				(
					@TelefoneNumero is null or  Exists ( Select id from  PessoaProspectTelefone WITH (NOLOCK) where PessoaProspectTelefone.IdPessoaProspect = Atendimento.idPessoaProspect and PessoaProspectTelefone.Telefone = @TelefoneNumero)
				)
					and
				(
					@CodigoOuTelefone is null or ((Atendimento.Id = convert(bigint,@CodigoOuTelefone)) or Exists ( Select id from  PessoaProspectTelefone WITH (NOLOCK) where PessoaProspectTelefone.IdPessoaProspect = Atendimento.idPessoaProspect and PessoaProspectTelefone.Telefone = (select right(@CodigoOuTelefone,9))))
				)
			)
		)
			and
		(
			@UsarPesquisaComOr = 0
				or
			(
				@IdUsuarioContaSistemaFiltro is null 
					and
				@ProspectNome = @strIfNull
					and
				@ProspectNomeComecaCom is null 
					and 
				@ProspectEmail is null 
					and
				@ProspectCPF is null 
					and
				@TelefoneNumero is null
					and
				@CodigoOuTelefone is null
			)
				or
			(
				(
					@IdUsuarioContaSistemaFiltro is not null and (PessoaProspectFidelizado.IdUsuarioContaSistema = @IdUsuarioContaSistemaFiltro OR Atendimento.IdUsuarioContaSistemaAtendimento = @IdUsuarioContaSistemaFiltro)
				)
					or
				(
					--@ProspectNome <> @strIfNull and PessoaProspect.Nome like '%'+ @ProspectNome + '%'
					-- está sendo usado PessoaProspect.idContaSistema = @IdContaSistema por causa do índice criado para nome e idContaSistema
					@ProspectNome <> @strIfNull and PessoaProspect.Nome like '%' + @ProspectNome and PessoaProspect.idContaSistema = @IdContaSistema
				)
					or
				(
					-- está sendo usado PessoaProspect.idContaSistema = @IdContaSistema por causa do índice criado para nome e idContaSistema
					@ProspectNomeComecaCom is not null and PessoaProspect.Nome like @ProspectNomeComecaCom+'%' and PessoaProspect.idContaSistema = @IdContaSistema
				)		
					or
				(
--					@ProspectEmail is not null and  Exists ( Select id from  PessoaProspectEmail WITH (NOLOCK) where PessoaProspectEmail.IdPessoaProspect = Atendimento.idPessoaProspect and PessoaProspectEmail.Email like '%'+ @ProspectEmail +'%')
					@ProspectEmail is not null and  Exists ( Select id from  PessoaProspectEmail WITH (NOLOCK) where PessoaProspectEmail.IdPessoaProspect = Atendimento.idPessoaProspect and PessoaProspectEmail.Email like @ProspectEmail +'%')
				)
					or
				(
					@ProspectCPF is not null and  Exists ( Select id from  PessoaProspectDocumento WITH (NOLOCK) where PessoaProspectDocumento.IdPessoaProspect = Atendimento.idPessoaProspect and PessoaProspectDocumento.TipoDoc = 'CPF' and PessoaProspectDocumento.Doc = @ProspectCPF)
				)
					or
				(
					@TelefoneNumero is not null and  Exists ( Select id from  PessoaProspectTelefone WITH (NOLOCK) where PessoaProspectTelefone.IdPessoaProspect = Atendimento.idPessoaProspect and PessoaProspectTelefone.Telefone = @TelefoneNumero)
				)
					or
				(
					@CodigoOuTelefone is not null and ((Atendimento.Id = convert(bigint,@CodigoOuTelefone)) or Exists ( Select id from  PessoaProspectTelefone WITH (NOLOCK) where PessoaProspectTelefone.IdPessoaProspect = Atendimento.idPessoaProspect and PessoaProspectTelefone.Telefone = (select right(@CodigoOuTelefone,9))))
				)
			)
		)
		-----------------------------------------------------------------
		-----------------------------------------------------------------
		---- .: Fim :.
		-----------------------------------------------------------------
		-----------------------------------------------------------------
),
paginacaoCount as  
(
	Select
		paginacao.idAtendimentoTabelaoAtendimento,
		paginacao.idAtendimento,
		paginacao.idPessoaProspect,
		paginacao.idGuid,
		paginacao.RowNumber

	From
		paginacao WITH (NOLOCK)

	Order by
		paginacao.RowNumber asc
	OFFSET 
		@FirstRow ROWS
    FETCH NEXT 
		@LastRow ROWS ONLY
)
	select
		(Select count(paginacao.idAtendimento) from paginacao where @AdicionarQtdRegistro = 1) as RowTotal,
		paginacaoCount.RowNumber as RowNumber,

		paginacaoCount.idAtendimento as idAtendimento,
		paginacaoCount.idGuid as AtendimentoIdGuid,
		ViewUsuarioContaSistemaDetalhado.PessoaNome as UsuarioNome,
		ViewUsuarioContaSistemaDetalhado.PessoaApelido as UsuarioApelido,
		ViewUsuarioContaSistemaDetalhado.UsuarioContaSistemaGuidCorrex as UsuarioIdGuidUsuarioCorrex,
		Atendimento.IdUsuarioContaSistemaAtendimento as IdUsuarioContaSistema,


		Atendimento.idPessoaProspect as IdPessoaProspect,
		PessoaProspect.IdGuid as PessoaProspectIdGuid,
		PessoaProspect.Nome as ProspectNome,
		PessoaProspect.RegistroStatus as PessoaProspectRegistroStatus,
		TabelaoAtendimento.PessoaProspectEmailList As ProspectEmail,
		TabelaoAtendimento.PessoaProspectCPF as ProspectCPF,
		TabelaoAtendimento.PessoaProspectTelefoneList as ProspectTelefoneList,
		
		Atendimento.StatusAtendimento as AtendimentoStatus,
		Atendimento.RegistroStatus as AtendimentoRegistroStatus,
		Atendimento.negociacaoStatus as AtendimentoNegociacaoStatus,

		AtendimentoResumoView.CanalNome as CanalNome,
		Atendimento.IdCanalAtendimento as IdCanal,
		Atendimento.idMidia as IdMidia,
		AtendimentoResumoView.MidiaNome as MidiaNome,

		AtendimentoResumoView.IntegradoraExternaIdGuid as IntegradoraExternaIdGuid,
		AtendimentoResumoView.IntegradoraExternaExtensaoLogo as IntegradoraExternaExtensaoLogo,

		Atendimento.idGrupo as IdGrupo,
		AtendimentoResumoView.GrupoNome as GrupoNome,
		Atendimento.idClassificacao as IdClassificacao,
		AtendimentoResumoView.ClassificacaoIdGuid as ClassificacaoIdGuid,
		AtendimentoResumoView.ClassificacaoValor as ClassificacaoNome,
		AtendimentoResumoView.ClassificacaoValor2 as ClassificacaoValorNome2,
		AtendimentoResumoView.ClassificacaoOrdem as ClassificacaoOrdem,
		Atendimento.DtInclusao as AtendimentoDtInclusao,
		Atendimento.DtInicioAtendimento as AtendimentoDtInicio,
		
		AtendimentoResumoView.ProdutoNome as ProdutoNome,
		Atendimento.idProduto as IdProduto,

		AtendimentoResumoView.CampanhaNome  as CampanhaNome,
		TabelaoAtendimento.AtendimentoMotivacaoNaoConversaoVenda as AtendimentoMotivacaoNaoConversaoVenda,

		Atendimento.IdContaSistema as idContaSistema,
		AtendimentoResumoView.ContaSistemaIdGuid as ContaSistemaIdGuid,

		-- Interacção do propsect
		Atendimento.DtInicioAtendimento as DtUltimaInteracaoProspect,

		-- É diferente da última interação já que é calculado uma margem a mais considerando data de atendimento, etc...
		isnull(Atendimento.InteracaoUsuarioUltimaDt, isnull(Atendimento.DtInicioAtendimento, Atendimento.DtInclusao)) as InteracaoUltimaDtUtilConsiderar,
		-- se faz necessário para só trazer caso o registro esteja no tabelão
		(case when CampanhaConfiguracao.id is not null then DATEADD(day, CampanhaConfiguracao.ValorInt, isnull(Atendimento.InteracaoUsuarioUltimaDt, isnull(Atendimento.DtInicioAtendimento, Atendimento.DtInclusao)))  else null end) as AtendimentoDtExpiracao,
		(case when CampanhaConfiguracao.id is not null then CampanhaConfiguracao.ValorInt  else null end) as AtendimentoConfiguracaoQtdDiasExpiracao,
		
		-- Ultima interação do usuário
		AtendimentoResumoView.InteracaoUltimaDtFull as InteracaoUsuarioUltimaData,
		AtendimentoResumoView.InteracaoUltimaTipoValor as InteracaoUsuarioUltimaTipoValor,

		-- Alarme próximo
		AtendimentoResumoView.AlarmeProximoAtivoData as AlarmeProximoAtivoData,
		AtendimentoResumoView.AlarmeProximoAtivoInteracaoTipoValor as AlarmeProximoAtivoInteracaoTipoValor,

		-- Alarme último
		AtendimentoResumoView.AlarmeUltimoAtivoData as AlarmeUltimoAtivoData,
		AtendimentoResumoView.AlarmeUltimoAtivoInteracaoTipoValor as AlarmeUltimoAtivoInteracaoTipoValor,

		AtendimentoBookMarkView.BookmarkIdGuids as BookmarkIdGuids

	from 
		paginacaoCount with(nolock)
			left outer join
		Atendimento  with(nolock) on @SomenteId = 0 and paginacaoCount.idAtendimento = Atendimento.Id
			left outer join
		PessoaProspect  with(nolock) on @SomenteId = 0 and paginacaoCount.idPessoaProspect = PessoaProspect.Id
			left outer join
		ViewUsuarioContaSistemaDetalhado WITH (NOLOCK) on @SomenteId = 0 and ViewUsuarioContaSistemaDetalhado.UsuarioContaSistemaId = Atendimento.IdUsuarioContaSistemaAtendimento
			left outer join
		CampanhaCanal  WITH (NOLOCK) on @SomenteId = 0 and CampanhaCanal.IdCampanha = Atendimento.idCampanha and CampanhaCanal.IdCanal = Atendimento.IdCanalAtendimento and CampanhaCanal.UsarCanalNoAutoEncerrar = 1
			left outer join
		TabelaoAtendimento with(nolock) on @SomenteId = 0 and TabelaoAtendimento.AtendimentoId = paginacaoCount.idAtendimento 
			left outer join
		-- Se faz necessário verificar se existe o registro no tabelão já que depende de alguns dados dele para gerar as informações necessárias que serão utilizadas
		CampanhaConfiguracao WITH (NOLOCK) ON @SomenteId = 0 and CampanhaCanal.IdCampanha = CampanhaConfiguracao.IdCampanha and CampanhaConfiguracao.Tipo = 'ENCERRAR_ATENDIMENTO_SEM_FOLLOWUP' and CampanhaConfiguracao.ValorInt > 0 and Atendimento.StatusAtendimento = 'ATENDIDO'
			left outer join
		AtendimentoResumoView  WITH (NOLOCK) on @SomenteId = 0 and AtendimentoResumoView.Atendimentoid = paginacaoCount.idAtendimento
			left outer join
		AtendimentoBookMarkView with (nolock) on @SomenteId = 0 and paginacaoCount.idAtendimento = AtendimentoBookMarkView.idSuperEntidade and AtendimentoBookMarkView.IdUsuarioContaSistema = @IdUsuarioContaSistemaExecutando
	
	order by
		paginacaoCount.RowNumber ASC

	-- http://www.sommarskog.se/dyn-search.html
	OPTION (RECOMPILE);

CREATE procedure [dbo].[ProcGetAtendimentosAutoCancelar]
	@qtdAtendimentosPorVez as int,
	@MaximoInteracaoFilaParaCancelar as int
 as 
begin

	Select
		top (@qtdAtendimentosPorVez)
		Atendimento.Id as AtendimentoId,
		Atendimento.QtdInteracaoFila as AtendimentoQtdInteracaoFila,
		Canal.IdContaSistema as ContaSistemaId
	From
		Atendimento with (nolock)
			inner join
		Canal with (nolock) on Canal.Id = Atendimento.IdCanalAtendimento

	Where
		Atendimento.StatusAtendimento = 'AGUARDANDOATENDIMENTO'
			and
		Atendimento.TipoDirecionamento = 'ROLETA'
			and
		Atendimento.QtdInteracaoFila > @MaximoInteracaoFilaParaCancelar
			and
		Canal.Tipo <> 'ATIVO'

end;

CREATE procedure [dbo].[ProcGetAtendimentosPendenteAtendimento] 
(
	@idContaSistema int,
	@idUsuarioContaSistema int
)
as

declare @statusAtendimentoAguardando varchar(25) = 'AGUARDANDOATENDIMENTO';
declare @tipoCanalChat char(4) = 'CHAT';
declare @dtNow datetime = dbo.GetDateCustom();

Select
	*
from
	(
		Select 
			Atendimento.Id as AtendimentoId,
			AtendimentoResumoView.AtendimentoIdGuid as AtendimentoIdGuid,
			AtendimentoResumoView.PessoaProspectNome as ProspectNome,
			AtendimentoResumoView.PessoaProspectIdGuid as ProspectIdGuid,
			AtendimentoResumoView.ProdutoNome as ProdutoNome,
			AtendimentoResumoView.MidiaNome as MidiaNome,
			AtendimentoResumoView.PecaNome as PecaNome,
			isNull(Atendimento.DataInicioValidadeAtendimento, AtendimentoResumoView.AtendimentoDtInclusao) as AtendimentoDtPedidoDeAtendimento,
			Atendimento.DataFimValidadeAtendimento as AtendimentoDataFimValidadeAtendimento,
			AtendimentoResumoView.ContasistemaIdGuid as ContaSistemaIdGuid,
			AtendimentoResumoView.ContasistemaId as ContaSistemaId

		From
			Atendimento with (nolock)
				inner join
			AtendimentoResumoView with (nolock) on AtendimentoResumoView.Atendimentoid = Atendimento.Id
				inner join
			Canal with (nolock) on Canal.Id = Atendimento.IdCanalAtendimento 


		where
			Atendimento.IdUsuarioContaSistemaAtendimento = @idUsuarioContaSistema
				and
			(Canal.Tipo <> @tipoCanalChat)
				and
			Atendimento.StatusAtendimento = @statusAtendimentoAguardando
				and
			(
				Atendimento.DataFimValidadeAtendimento is null
					or
				Atendimento.DataFimValidadeAtendimento > @dtNow
			)		
	) TabAux
where
	-- segurança
	TabAux.ContaSistemaId = @idContaSistema
Order by
	TabAux.AtendimentoDtPedidoDeAtendimento desc

	OPTION (RECOMPILE);

CREATE procedure [dbo].[ProcGetCampanhaFilaAtendimento] 
(
	@IdContaSistema int,
	@IsAdministradorDoSistema bit,
	@IdUsuarioContaSistemaExecutando int,
	@IdCampanha int,
	@IdCampanhaCanal int,
	@IdPlantaoHorario int
)
as
select
	row_number() over (order by 
			UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal.Prioridade asc,
			UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal.DtInteracaoFila asc, 
			UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal.Id asc
		 ) as 'RowNumber',
	ViewUsuarioContaSistemaByCampanha.GrupoHierarquia,
	ViewUsuarioContaSistemaByCampanha.GrupoId,
	ViewUsuarioContaSistemaByCampanha.PessoaEmail,
	ViewUsuarioContaSistemaByCampanha.PessoaNome,
	ViewUsuarioContaSistemaByCampanha.PessoaApelido,
	ViewUsuarioContaSistemaByCampanha.UsuarioContaSistemaId,
	ViewUsuarioContaSistemaByCampanha.UsuarioContaSistemaFilaCanalOnLine, 
	ViewUsuarioContaSistemaByCampanha.UsuarioContaSistemaFilaCanalOffLine, 
	ViewUsuarioContaSistemaByCampanha.UsuarioContaSistemaFilaCanalTelefone,
	ViewUsuarioContaSistemaByCampanha.UsuarioContaSistemaFilaCanalWhatsApp, 
	ViewUsuarioContaSistemaByCampanha.UsuarioContaSistemaDtUltimaRequisicao,
	UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal.Prioridade,	
	UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal.DtInteracaoFila,	
	UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal.DtInclusao,
	UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal.IdCampanhaCanal,
	UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal.IdCampanhaGrupo,
	UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal.IdPlantaoHorario,
	UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal.Id,
	UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal.Obs 
From 
	ViewUsuarioContaSistemaByCampanha WITH (NOLOCK)
		inner join
	UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal  WITH (NOLOCK) 
		on 
			UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal.IdUsuarioContaSistema = ViewUsuarioContaSistemaByCampanha.UsuarioContaSistemaId and
			UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal.IdCampanhaGrupo = ViewUsuarioContaSistemaByCampanha.CampanhaGrupoId

where
	ViewUsuarioContaSistemaByCampanha.ContaSistemaId = @IdContaSistema and
	ViewUsuarioContaSistemaByCampanha.CampanhaId = @IdCampanha and
	UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal.IdCampanhaCanal = @IdCampanhaCanal and
	UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal.IdPlantaoHorario = @IdPlantaoHorario
	

Order by
	UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal.Prioridade asc,
	UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal.DtInteracaoFila asc, 
	UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal.Id asc;

CREATE procedure [dbo].[ProcGetCampanhasPermitida] 
(
@IdContaSistema int,
@IsAdministradorDoSistema as bit,
@IdUsuarioContaSistemaExecutando int,
@ProdutoUF VARCHAR(2),
@ProdutoID int,
@CampanhaNome  VARCHAR(300),
@CampanhaGrupoStatus  VARCHAR(2),
@GrupoStatus  VARCHAR(2),
@CampanhaStatus  VARCHAR(2),
@SomenteGrupoDoUsuarioAlocadoNaCampanha  bit
)
as

set @CampanhaGrupoStatus = dbo.RetNullOrVarChar(@CampanhaGrupoStatus)
set @CampanhaNome = dbo.RetNullOrVarChar(@CampanhaNome)
set @GrupoStatus = dbo.RetNullOrVarChar(@GrupoStatus)
set @CampanhaStatus = dbo.RetNullOrVarChar(@CampanhaStatus)
set @ProdutoUF = dbo.RetNullOrVarChar(@ProdutoUF)
set @SomenteGrupoDoUsuarioAlocadoNaCampanha = ISNULL(@SomenteGrupoDoUsuarioAlocadoNaCampanha, 0)

-- Alterado em 27/10/2020 Fabrício

Select
	Distinct
		Campanha.*
from 
	Campanha WITH (NOLOCK)
		left outer join
	CampanhaGrupo WITH (NOLOCK) on CampanhaGrupo.IdCampanha = Campanha.Id
		left outer join
	Grupo WITH (NOLOCK) ON Grupo.Id = CampanhaGrupo.IdGrupo
		left outer join
	ProdutoCampanha WITH (NOLOCK) ON ProdutoCampanha.IdCampanha = Campanha.Id
		left outer join
	Produto WITH (NOLOCK) ON Produto.Id = ProdutoCampanha.IdProduto
		left outer join
	---- Seleciona para verificar se o usuario que esta executando e adm da campanha, caso seja o mesmo podera visualizar os registros
	CampanhaAdministrador WITH (NOLOCK) on (@IsAdministradorDoSistema = 0 and CampanhaAdministrador.idCampanha = Campanha.Id and CampanhaAdministrador.idUsuarioContaSistema = @IdUsuarioContaSistemaExecutando)
		left outer join
	GetGrupoUsuarioTodosEInferiores(@IdUsuarioContaSistemaExecutando) GruposPermitidos on GruposPermitidos.Id = Grupo.Id

Where
	Campanha.IdContaSistema = @IdContaSistema
		and
	(
		@IsAdministradorDoSistema = 1		
			or
		GruposPermitidos.Id is not null
			or
		CampanhaAdministrador.Id is not null
	)
		and
	(
		@CampanhaGrupoStatus is null or CampanhaGrupo.Status = @CampanhaGrupoStatus
	)
		and
	(
		@CampanhaNome is null or Campanha.Nome like '%'+@CampanhaNome+'%'
	)	
		AND
	(
		@GrupoStatus is null or Grupo.Status = @GrupoStatus
	)
		AND
	(
		@CampanhaStatus is null or Campanha.Status = @CampanhaStatus
	)
		AND
	(
		@ProdutoUF is null or Produto.UF = @ProdutoUF
	)	
		AND
	(
		@ProdutoID is null or Produto.Id = @ProdutoID
	)
		AND
	(
		@SomenteGrupoDoUsuarioAlocadoNaCampanha = 0 or GruposPermitidos.IsUsuario = 1 or GruposPermitidos.IsAdministrador = 1
	)
Order By
	Campanha.Nome

-- http://www.sommarskog.se/dyn-search.html
OPTION (RECOMPILE);

CREATE procedure [dbo].[ProcGetClassificacaoAtendimentoResumo] 
(
	@IdContaSistema int,
	@IdAtendimento int
)
as
	begin
		declare @dtnow datetime = dbo.getDateCustom();
		
		declare @tableTemp table
		(
			ClassificacaoId int,
			InteracaoDtInclusao datetime,
			AtendimentoDtInicioAtendimento datetime,
			AtendimentoDtConclusaoAtendimento datetime,
			AtendimentoClassificacaoOrdem int

		)

		insert into @tableTemp
		select 
			InteracaoObj.JSONClassificacaoId as ClassificacaoId,
			Interacao.DtInclusao as InteracaoDtInclusao,

			Atendimento.DtInicioAtendimento as AtendimentoDtInicioAtendimento,
			Atendimento.DtConclusaoAtendimento as AtendimentoDtConclusaoAtendimento,

			Classificacao.Ordem as AtendimentoClassificacaoOrdem
		from 
			Atendimento with (nolock) 
				inner join
			Classificacao with (nolock) on Classificacao.Id = Atendimento.idClassificacao
				inner join
			Interacao with (nolock) on Interacao.IdSuperEntidade = Atendimento.Id
				left outer join
			InteracaoObj with (nolock) on InteracaoObj.Id = Interacao.Id

		where
				Interacao.IdSuperEntidade = @IdAtendimento
					and
				Interacao.IdContaSistema = @IdContaSistema
					and
				Interacao.ObjTipoSub = 'SuperCRM.DTO.InteracaoGeral.InteracaoGeralAtendimentoPipeLineDTO' 
					and
				(
					Interacao.DtInclusao >= Atendimento.DtInicioAtendimento
						and
					(
						Atendimento.DtConclusaoAtendimento is null
							or
						Interacao.DtInclusao <= Atendimento.DtConclusaoAtendimento
					)
				)

		SET NOCOUNT on

		Select 
			TabAux3.ClassificacaoId,
			TabAux3.ClassificacaoIdGuid,
			TabAux3.ClassificacaoOrdem,
			TabAux3.ClassificacaoValor,
			Sum(TabAux3.SecondosCorridos) as SecondosCorridosSum

		From
			(
				Select 
					TabAux2.*,
					(case when TabAux2.PreviousValue is null then TabAux2.AtendimentoDtInicioAtendimento else TabAux2.CurrentValue end) as DtInicio,
					isnull(TabAux2.NextValue, isnull(TabAux2.AtendimentoDtConclusaoAtendimento, @dtnow)) as DtFim,
					DATEDIFF
							(
								SECOND, 
								(case when TabAux2.PreviousValue is null then TabAux2.AtendimentoDtInicioAtendimento else TabAux2.CurrentValue end),
								isnull(TabAux2.NextValue, isnull(TabAux2.AtendimentoDtConclusaoAtendimento, @dtnow)) 
							) as SecondosCorridos

				from
				(
					Select 
						TabAux1.*,
						LAG(TabAux1.InteracaoDtInclusao) OVER (ORDER BY TabAux1.InteracaoDtInclusao) as PreviousValue,
						TabAux1.InteracaoDtInclusao as CurrentValue,
						Lead(TabAux1.InteracaoDtInclusao) OVER (ORDER BY TabAux1.InteracaoDtInclusao) as NextValue
					from
						(
							Select 
								Classificacao.Id as ClassificacaoId,
								Classificacao.IdGuid as ClassificacaoIdGuid,
								Classificacao.Ordem as ClassificacaoOrdem,
								Classificacao.Valor as ClassificacaoValor,

								TabAux0.InteracaoDtInclusao as InteracaoDtInclusao,

								TabAux0.AtendimentoDtInicioAtendimento as AtendimentoDtInicioAtendimento,
								TabAux0.AtendimentoDtConclusaoAtendimento as AtendimentoDtConclusaoAtendimento
							from
								@tableTemp TabAux0
									inner join
								Classificacao with (nolock) on Classificacao.Id = TabAux0.ClassificacaoId
							where
								Classificacao.Status = 'AT'
									and
								Classificacao.Ordem <= TabAux0.AtendimentoClassificacaoOrdem
			
						) TabAux1
				) TabAux2
			) TabAux3
		group by
			TabAux3.ClassificacaoId,
			TabAux3.ClassificacaoIdGuid,
			TabAux3.ClassificacaoOrdem,
			TabAux3.ClassificacaoValor

		-- http://www.sommarskog.se/dyn-search.html
		OPTION (RECOMPILE);
	end;

-- Processa os eventos antes do processamento
CREATE procedure [dbo].[ProcGetEventoProcessar]
(
	@TopRegistros int,
	@GrupoProcessamento varchar(100)
)
 as 
begin

declare @dateTimeNow AS DATETIME = dbo.GetDateCustom()
declare @timeNow AS time = @dateTimeNow
declare @processado as bit = 0
declare @status as char(3) = 'INC'

set @GrupoProcessamento = dbo.RetNullOrVarChar(@GrupoProcessamento) 


if @TopRegistros is null
	begin
		set @TopRegistros = 10000
	end

Select top (@TopRegistros)
	Evento.id as EventoID,
	Evento.AvisarAdmOnError,
	Evento.QtdTentativaProcessamento,
	Evento.ObjJson,
	Evento.ObjTipo,
	Evento.ObjAcaoType

From
	Evento (readpast)

Where
	Evento.Processado = @processado
		and
	Evento.Status = @status
		and
	Evento.DtValidadeInicio <= @dateTimeNow
		and
	(
		HrValidadeProcessamentoInicio is null
			or
		(
			HrValidadeProcessamentoInicio <= @timeNow
				and
			(HrValidadeProcessamentoFim is null or HrValidadeProcessamentoFim >= @timeNow)
		)
	)
		and
	(
		(@GrupoProcessamento is null and Evento.GrupoProcessamento is null)
			or
		(@GrupoProcessamento is not null and Evento.GrupoProcessamento = @GrupoProcessamento)
	)
	
order by
	Evento.id asc
	
-- http://www.sommarskog.se/dyn-search.html
	OPTION (RECOMPILE);

end;

CREATE procedure [dbo].[ProcGetExisteAtendimentoParaAtender]
(
	@idContaSistema int,
	@idUsuarioContaSistema int
)
 as 
begin

declare @dtNow as datetime = dbo.GetDateCustom();

Select 
	top 1
		Atendimento.Id,
		PessoaProspect.Nome as ProspectNome,
		Atendimento.DataFimValidadeAtendimento
From 
	Atendimento WITH (nolock)
		inner join
	PessoaProspect with (nolock) on PessoaProspect.Id = Atendimento.idPessoaProspect

where
	--1 = 2
	--	and
	Atendimento.IdContaSistema = @idContaSistema
		and
	Atendimento.IdUsuarioContaSistemaAtendimento = @idUsuarioContaSistema
		and
	Atendimento.StatusAtendimento = 'AGUARDANDOATENDIMENTO'
		and
	(Atendimento.DataFimValidadeAtendimento >= @dtNow or Atendimento.DataFimValidadeAtendimento is null)

Order by
	Atendimento.DataFimValidadeAtendimento,
	Atendimento.id
end;

CREATE procedure [dbo].[ProcGetExisteAtendimentoParaAtenderQtd]
	@idContaSistema int,
	@idUsuarioContaSistema int
as
begin
	declare @dtnow datetime = dbo.getDateCustom()

	Select 
		count(Atendimento.Id)
	From 
		Atendimento with (nolock)
			inner join
		Canal with (nolock) on Canal.id = Atendimento.IdCanalAtendimento

	where
		Atendimento.idContaSistema = @idContaSistema
			and
		Atendimento.IdUsuarioContaSistemaAtendimento = @idUsuarioContaSistema
			and
		Atendimento.StatusAtendimento = 'AGUARDANDOATENDIMENTO'
			and
		Canal.Tipo <> 'CHAT'
			and
		(Atendimento.DataFimValidadeAtendimento >= @dtnow  or Atendimento.DataFimValidadeAtendimento is null)

end;

CREATE procedure [dbo].[ProcGetLogAcoes] 
(
	@IdContaSistema int,
	@IsAdministradorDoSistema bit,
	@IdUsuarioContaSistemaExecutando int,
	@IdUsuarioContaSistema int,
	@IdUsuarioContaSistemaImpacou int,
	@TipoLog varchar(300),
	@TipoSubLog varchar(300),
	@DtInicio datetime,
	@DtFim datetime,

	@PageSize INT,
	@PageNumber INT,
	@AdicionarProximoRegistro bit
)
as
declare @FirstRow INT;
declare @LastRow INT;

if @PageNumber = 0 begin set @PageNumber = 1 end

set	@FirstRow = (( @PageNumber - 1) * @PageSize) + 1
set	@LastRow = ((@PageNumber - 1) * @PageSize) + @PageSize
if @AdicionarProximoRegistro <> 0 and @LastRow < 2147483647 begin set @LastRow += 1 end;

with paginacao as  
(
	Select 
		row_number() over (order by LogAcoes.id desc ) as 'RowNumber',
		LogAcoes.*,
		ContaSistema.Nome as ContaSistemaNome,
		ContaSistema.Guid as ContaSistemaIdGuid,

		UsuarioContaSistemaExecutou.UsuarioContaSistemaIdGuid as UsuarioIdGuid,
		UsuarioContaSistemaExecutou.UsuarioContaSistemaGuidCorrex as UsuarioIdGuidCorrex,
		UsuarioContaSistemaExecutou.PessoaNome as UsuarioNome,
		UsuarioContaSistemaExecutou.PessoaApelido as UsuarioApelido,
		UsuarioContaSistemaExecutou.PessoaEmail as UsuarioEmail,

		UsuarioContaSistemaImpactou.UsuarioContaSistemaIdGuid as UsuarioImpactouIdGuid,
		UsuarioContaSistemaImpactou.UsuarioContaSistemaGuidCorrex as UsuarioImpactouIdGuidCorrex,
		UsuarioContaSistemaImpactou.PessoaNome as UsuarioImpactouNome,
		UsuarioContaSistemaImpactou.PessoaApelido as UsuarioImpactouApelido,
		UsuarioContaSistemaImpactou.PessoaEmail as UsuarioImpactouEmail

	From
		LogAcoes WITH (NOLOCK)
			left outer join
		ViewUsuarioContaSistemaDetalhado UsuarioContaSistemaExecutou WITH (NOLOCK) on LogAcoes.IdUsuarioContaSistemaExecutou = UsuarioContaSistemaExecutou.UsuarioContaSistemaId
			left outer join
		ViewUsuarioContaSistemaDetalhado UsuarioContaSistemaImpactou WITH (NOLOCK) on LogAcoes.IdUsuarioContaSistemaImpactou = UsuarioContaSistemaImpactou.UsuarioContaSistemaId
			left outer join
		ContaSistema WITH (NOLOCK) on ContaSistema.Id = LogAcoes.IdContaSistema
	
	Where
		(
			@IdContaSistema is null or LogAcoes.IdContaSistema = @IdContaSistema
		)
			and
		(
			@IdUsuarioContaSistema is null or LogAcoes.IdUsuarioContaSistemaExecutou = @IdUsuarioContaSistema
		)
			and
		(
			@IdUsuarioContaSistemaImpacou is null or LogAcoes.IdUsuarioContaSistemaImpactou = @IdUsuarioContaSistemaImpacou
		)
			and
		(
			dbo.IsNullOrWhiteSpace(@TipoLog) = 1 or LogAcoes.Tipo = @TipoLog
		)		
			and
		(
			dbo.IsNullOrWhiteSpace(@TipoSubLog) = 1 or LogAcoes.TipoSub = @TipoSubLog
		)
			and
		(
			@DtInicio is null or LogAcoes.DtInclusao >= @DtInicio
		)
			and
		(
			@DtFim is null or LogAcoes.DtInclusao <= @DtFim
		)
)
	select * from paginacao  
	WHERE	RowNumber BETWEEN @FirstRow AND @LastRow
	ORDER BY RowNumber ASC

	-- http://www.sommarskog.se/dyn-search.html
	 OPTION (RECOMPILE);

CREATE procedure [dbo].[ProcGetNotificacaoGlobal] 
(
	@IdContaSistema int,
	@IdUsuarioContaSistema int,
	@IdMaiorQue int,

	@PageSize INT,
	@PageNumber INT,
	@AdicionarProximoRegistro bit
)
as
declare @dateNow datetime = dbo.GetDateCustom();
declare @FirstRow INT;
declare @LastRow INT;

if @PageNumber = 0 begin set @PageNumber = 1 end

set	@FirstRow = (( @PageNumber - 1) * @PageSize) + 1
set	@LastRow = ((@PageNumber - 1) * @PageSize) + @PageSize
if @AdicionarProximoRegistro <> 0 and @LastRow < 2147483647 begin set @LastRow += 1 end;

if @IdMaiorQue is null begin set @IdMaiorQue = 0 end;


with paginacao as  
(
	Select 
		row_number() over (order by AvisoStatus desc, NotificacaoGlobal.id desc) as 'RowNumber',
		NotificacaoGlobal.*

	From 
		NotificacaoGlobal with (nolock)

	where
		NotificacaoGlobal.IdContaSistema = @IdContaSistema
			and
		NotificacaoGlobal.IdUsuarioContaSistemaResponsavel = @IdUsuarioContaSistema
			and
		NotificacaoGlobal.Status <> 'CAN'
			and
		(NotificacaoGlobal.DtValidade is null or NotificacaoGlobal.DtValidade >= @dateNow)
)
	select * from paginacao  
	WHERE	RowNumber BETWEEN @FirstRow AND @LastRow
	ORDER BY RowNumber ASC

	-- http://www.sommarskog.se/dyn-search.html
	OPTION (RECOMPILE);

CREATE procedure [dbo].[ProcGetPendenciaProcessamento] 
(
	@idContaSistema int,
	@idUsuarioContaSistema int,
	@dtInicial datetime,
	@dtFinal datetime
)
as

-- Se faz necessário para não deixa de recuperar os registros que possam estar entre os milessegundos repassados
-- Retira os milessegundos
declare @dtInicialUtilizar datetime = DATEADD(ms, -DATEPART(ms, @dtInicial), @dtInicial)
-- Adiciona o máximo de milessegundos de uma data específica
declare @dtFinalUtilizar datetime = DATEADD(ms, -2, DATEADD(SECOND, 1 ,DATEADD(ms, -DATEPART(ms, @dtFinal), @dtFinal)))

Select 
	Tipo
From 
	PendenciaProcessamento WITH (nolock) 
where
	PendenciaProcessamento.IdContaSistema = @idContaSistema
		and
	PendenciaProcessamento.IdUsuarioContaSistema = @idUsuarioContaSistema
		and
	PendenciaProcessamento.DtPreProcessado >= @dtInicialUtilizar
		and
	PendenciaProcessamento.DtPreProcessado <= @dtFinalUtilizar
		and
	PendenciaProcessamento.Status = 'PROCESSADO'

Group by
	Tipo;

CREATE procedure [dbo].[ProcGetPendenciaProcessamentoProcessar]
(
	@TopRegistros int
)
 as 
begin

-- declare @dateNow AS DATETIME = dbo.GetDateCustom()
-- SE FAZ NECESSÁRIO PARA EVITAR LER DADOS AINDA NÃO COMITADO
-- não se faz mais necessário pois foi retirado o with nolock
-- declare @dateConsiderar AS DATETIME = DATEADD(ss, -1, @dateNow)
-- 
-- declare @dateConsiderar AS DATETIME = @dateNow

	if @TopRegistros is null
		begin
			set @TopRegistros = 10000
		end


	Select  
		PendenciaProcessamento.IdGuidContaSistema,
		PendenciaProcessamento.IdGuidUsuarioContaSistema,
		PendenciaProcessamento.IdContaSistema,
		PendenciaProcessamento.IdUsuarioContaSistema,
		Min(PendenciaProcessamento.Id) as MenorId,
		Max(PendenciaProcessamento.Id) as MaiorId,
		Min(PendenciaProcessamento.DtPreProcessado) as MenorDtPreProcessado,
		Max(PendenciaProcessamento.DtPreProcessado) as MaiorDtPreProcessado

	From
		PendenciaProcessamento WITH (nolock)
	
	Where
		PendenciaProcessamento.PreProcessado = 1
			and
		PendenciaProcessamento.Processado = 0
			and
		PendenciaProcessamento.Finalizado = 0
			and
		PendenciaProcessamento.Status = 'INCLUIDO'

	group by
		PendenciaProcessamento.IdGuidContaSistema,
		PendenciaProcessamento.IdGuidUsuarioContaSistema,
		PendenciaProcessamento.IdContaSistema,
		PendenciaProcessamento.IdUsuarioContaSistema

end;

-- Irá procurar por qualquer um dos parâmetros repassados
-- Se o @GuidPessoaProspect estiver preenchido irá desconsiderar os outros parâmetros
-- Número do telefone com DDD separado por ,
CREATE procedure [dbo].[ProcGetPessoaProspect] 
(
	@IdContaSistema int,
	@IsAdministradorDoSistema as bit,
	@IdUsuarioContaSistemaExecutando int,
	@IdUsuarioContaSistemaJaAtendeu int,
	@GuidPessoaProspect varchar(36),
	@CPF varchar(14),
	@NomeProspect varchar(150),
	@Email varchar(150),
	@Codigo varchar(50),
	@Telefones varchar(1000),
	
	@OrderBy varchar(100),
	
	@PageSize INT,
	@PageNumber INT,
	@AdicionarProximoRegistro bit
)
as
declare @FirstRow INT;
declare @LastRow INT;
declare @dtNow datetime = DATEADD(DAY, 1, dbo.GetDateCustom());

if @PageNumber = 0 begin set @PageNumber = 1 end

set	@FirstRow = (( @PageNumber - 1) * @PageSize) + 1
set	@LastRow = ((@PageNumber - 1) * @PageSize) + @PageSize
if @AdicionarProximoRegistro <> 0 and @LastRow < 2147483647 begin set @LastRow += 1 end

-- Seta para evitar que sejam localizado string vazia, quando vazia setara null
set @GuidPessoaProspect = dbo.RetNullOrVarChar(@GuidPessoaProspect)
set	@CPF = dbo.RetNullOrVarChar(@CPF)
set	@NomeProspect  = dbo.RetNullOrVarChar(@NomeProspect)
set @Email  = dbo.RetNullOrVarChar(@Email)
set @Codigo  = dbo.RetNullOrVarChar(@Codigo)
set @Telefones  = dbo.RetNullOrVarChar(@Telefones)

declare @tableTelefone table
(
	ddd varchar(2),
	numero varchar(20)
);

declare @tablePessoaProspectFiltro table
(
	id int,
	ProspectDtInclusao datetime,
	ProspectDtInicioFidelizacao datetime
);

declare @tablePessoaProspectReturn table
(
	id int,
	ProspectDtInclusao datetime,
	ProspectDtInicioFidelizacao datetime
);

if @Telefones is not null
	begin
		insert @tableTelefone (ddd, numero)
		select 
			SUBSTRING(TableTel.OrderID, 1, 2),
			SUBSTRING(TableTel.OrderID, 3, 50)
		from 
			dbo.SplitIDstring(@Telefones) TableTel

	end

-- Insere na tabela temporária as pessoas filtradas de acordo com os parâmetros repassados
insert @tablePessoaProspectFiltro (id, ProspectDtInclusao, ProspectDtInicioFidelizacao) 
Select 
	distinct
		PessoaProspect.Id,
		SuperEntidade.DtInclusao as ProspectDtInclusao,
		isnull(PessoaProspectFidelizado.DtInicioFidelizacao, @dtNow) as ProspectDtInicioFidelizacao
FROM 
	PessoaProspect WITH (NOLOCK)
		inner join
	SuperEntidade WITH (NOLOCK) on SuperEntidade.Id = PessoaProspect.Id
		left outer join
	PessoaProspectFidelizado with (nolock) on PessoaProspect.id = PessoaProspectFidelizado.Id and PessoaProspectFidelizado.DtFimFidelizacao is null

WHERE
	PessoaProspect.idContaSistema = @IdContaSistema
		and
	(
		(@Email is not null and exists (Select id from PessoaProspectEmail with (nolock) where PessoaProspectEmail.IdPessoaProspect = PessoaProspect.Id and PessoaProspectEmail.Email = @Email))
			or
		(@Telefones is not null and exists (Select id from PessoaProspectTelefone with (nolock) inner join @tableTelefone TabTel on PessoaProspectTelefone.IdPessoaProspect = PessoaProspect.Id and PessoaProspectTelefone.DDD = TabTel.ddd and PessoaProspectTelefone.Telefone = TabTel.numero where PessoaProspectTelefone.IdPessoaProspect = PessoaProspect.Id))
			or
		(@CPF is not null and exists (Select id from PessoaProspectDocumento with (nolock) where PessoaProspectDocumento.IdPessoaProspect = PessoaProspect.Id and PessoaProspectDocumento.Doc = @CPF and PessoaProspectDocumento.TipoDoc = 'CPF'))
			or
		(@GuidPessoaProspect is not null and SuperEntidade.StrGuid = @GuidPessoaProspect)
			or
		(@NomeProspect is not null and PessoaProspect.Nome like '%' + @NomeProspect + '%')
			or
		(@Codigo is not null and PessoaProspect.Codigo = @Codigo)
	)

	OPTION (RECOMPILE);

-- Caso não seja admim ou os parâmetros acima sejam repassados irá filtrar somente os que o usuário tenha permissão
-- Caso contrário irá retornar 
if (@IsAdministradorDoSistema is null or @IsAdministradorDoSistema = 0)
	begin
		if (@IdUsuarioContaSistemaExecutando is not null or @IdUsuarioContaSistemaJaAtendeu is not null)
			begin
				insert into @tablePessoaProspectReturn (id, ProspectDtInclusao, ProspectDtInicioFidelizacao) 
				select
					TabTempPessoaProspect.id,
					SuperEntidade.DtInclusao,
					isnull(PessoaProspectFidelizado.DtInicioFidelizacao, @dtNow) as DtInicioFidelizacao
				From
					@tablePessoaProspectFiltro TabTempPessoaProspect
						inner join
					PessoaProspectFidelizado with (nolock) on TabTempPessoaProspect.id = PessoaProspectFidelizado.Id
						inner join
					SuperEntidade with (nolock) on SuperEntidade.Id = TabTempPessoaProspect.id
				where 
					PessoaProspectFidelizado.DtFimFidelizacao is null
						and
					(
						PessoaProspectFidelizado.IdUsuarioContaSistema = @IdUsuarioContaSistemaExecutando
							or
						PessoaProspectFidelizado.IdUsuarioContaSistema = @IdUsuarioContaSistemaJaAtendeu
					)
			end
	end
else
	begin
		insert into @tablePessoaProspectReturn (id, ProspectDtInclusao, ProspectDtInicioFidelizacao) 
		Select 		
			tabAux.Id,
			tabAux.ProspectDtInclusao,
			tabAux.ProspectDtInicioFidelizacao 
		from @tablePessoaProspectFiltro tabAux
	end;

with paginacao as  
(
	Select
		row_number() over (order by Tab1.ProspectDtInicioFidelizacao asc, Tab1.ProspectDtInclusao asc, Tab1.Id asc) as 'RowNumber',
		Tab1.Id
	from
		@tablePessoaProspectReturn Tab1
)
	select * from paginacao  
	WHERE	RowNumber BETWEEN @FirstRow AND @LastRow
	ORDER BY RowNumber ASC

	OPTION (RECOMPILE);

CREATE procedure [dbo].[ProcGetPessoaProspectImportacao] 
(
	@IdContaSistema int,
	@Status varchar(30),

	@PageSize INT,
	@PageNumber INT,
	@AdicionarProximoRegistro bit
)
as
declare @FirstRow INT;
declare @LastRow INT;
declare @strConcatenador as varchar(2) = ', ';

if @PageNumber = 0 begin set @PageNumber = 1 end

set	@FirstRow = (( @PageNumber - 1) * @PageSize) + 1
set	@LastRow = ((@PageNumber - 1) * @PageSize) + @PageSize
if @AdicionarProximoRegistro <> 0 and @LastRow < 2147483647 begin set @LastRow += 1 end;

-- Seta para evitar que sejam localizado string vazia, quando vazia setara null
set @Status = dbo.RetNullOrVarChar(@Status);

with paginacao as  
(
	Select 
		row_number() over (order by PessoaProspectImportacao.id desc) as 'RowNumber',
		(
			Select
				Distinct STRING_AGG(Prospeccao.Nome + ' (' + FORMAT(Prospeccao.DtInclusao, 'dd/MM/yyyy HH:mm:ss') +')', @strConcatenador)
			From
				PessoaProspectOrigem with (nolock)
					inner join
				ProspeccaoPessoaProspectOrigem  with (nolock) on ProspeccaoPessoaProspectOrigem.IdPessoaProspectOrigem = PessoaProspectOrigem.id
					inner join
				Prospeccao with (nolock) on Prospeccao.Id = ProspeccaoPessoaProspectOrigem.IdProspeccao
			where 
				PessoaProspectOrigem.IdPessoaProspectImportacao = PessoaProspectImportacao.Id
		) as ProspeccoesRealizadas,
		PessoaProspectImportacao.*
		
	From
		PessoaProspectImportacao WITH (NOLOCK)
	
	Where
		PessoaProspectImportacao.idContaSistema = @IdContaSistema
			and
		(
			@Status is null or PessoaProspectImportacao.Status = @Status
		)
)

	select * from paginacao  
	WHERE	RowNumber BETWEEN @FirstRow AND @LastRow
	ORDER BY RowNumber ASC

	-- http://www.sommarskog.se/dyn-search.html
	OPTION (RECOMPILE);

CREATE procedure [dbo].[ProcGetProperties]
 @strJson  varchar(max)
as 
 
if ISJSON(@strJson) = 0
	begin
		DECLARE @msg VARCHAR(MAX) = FORMATMESSAGE('Erro na procedure (). O valor repassado não representa um JSON válido. ERAS1A2X11A. JSON: ', N'');
		THROW 51000, @msg, 1; 
	end

declare @midiaNome varchar(200) = 'midiaNome'
declare @campanhaNome varchar(200) = 'campanhaNome'
declare @pecaNome varchar(200) = 'pecaNome'
declare @produtoNome varchar(200) = 'produtoNome'
declare @integradoraExternaNome varchar(200) = 'integradoraExternaNome'
declare @integradoraExternaAgenciaNome varchar(200) = 'integradoraExternaAgenciaNome'
declare @prospeccaoNome varchar(200) = 'prospeccaoNome'
declare @canalNome varchar(200) = 'canalNome'

declare @tableReturn table
	(
		ContaSistemaId int,
		ContaSistemaIdGuid char(36),
		Tipo varchar(200),
		ChaveInt int,
		ChaveGuid varchar(36),
		ValorString varchar(max),
		ValorInt int,
		ValorDecimal decimal(18,2),
		ValorDateTime datetime,
		Achou bit
	);

--set @strJson = '{ "Properties" : [ { "Tipo":"midiaNome", "ChaveInt" : 5, "ChaveGuid" : "guiddddd", "ContaSistemaId" : 3, "ContaSistemaIdGuid" : "1212" }, { "Tipo":"midiaNome", "ChaveInt" : 12, "ContaSistemaId" : 3 }, { "Tipo":"pecaNome", "ChaveInt" : 6, "ContaSistemaId" : 3 }, { "Tipo":"pecaNome", "ChaveInt" : 18 }  ]}'


insert 
	into 
		@tableReturn 
		
		(
			ContaSistemaId,
			ContaSistemaIdGuid,
			Tipo,
			ChaveInt,
			ChaveGuid
		)
	
SELECT 
	*  
FROM 
	OPENJSON(@strJson, '$.Properties')  
	WITH
		(
			ContaSistemaId int '$.ContaSistemaId',
			ContaSistemaIdGuid char(36) '$.ContaSistemaIdGuid',
			tipo varchar(200) '$.Tipo',  
			chaveInt int '$.ChaveInt',
			chaveGuid varchar(36) '$.ChaveGuid'
		) 

if ((Select top 1 tipo from @tableReturn TabTemp where TabTemp.tipo = @campanhaNome) is not null)
	begin
		update @tableReturn 
			Set  valorString = Campanha.Nome, achou = 1
		From
			@tableReturn TabTemp
				inner join
			Campanha with (nolock) on (Campanha.Id = TabTemp.chaveInt or Campanha.GUID = TabTemp.chaveGuid)
		where
			TabTemp.tipo = @campanhaNome and TabTemp.ChaveInt = Campanha.Id
	end

if ((Select top 1 tipo from @tableReturn TabTemp where TabTemp.tipo = @midiaNome) is not null)
	begin
		update @tableReturn 
			Set  valorString = Midia.Nome, achou = 1
		From
			@tableReturn TabTemp
				inner join
			Midia with (nolock) on (Midia.Id = TabTemp.chaveInt or Midia.GUID = TabTemp.chaveGuid)
		where
			TabTemp.tipo = @midiaNome and TabTemp.ChaveInt = Midia.Id
	end

if ((Select top 1 tipo from @tableReturn TabTemp where TabTemp.tipo = @pecaNome) is not null)
	begin
		update @tableReturn 
			Set  valorString = Peca.Nome, achou = 1
		From
			@tableReturn TabTemp
				inner join
			Peca with (nolock) on (Peca.Id = TabTemp.chaveInt or Peca.GUID = TabTemp.chaveGuid)
		where
			TabTemp.tipo = @pecaNome and TabTemp.ChaveInt = Peca.Id
	end


if ((Select top 1 tipo from @tableReturn TabTemp where TabTemp.tipo = @integradoraExternaNome) is not null)
	begin
		update @tableReturn 
			Set  valorString = IntegradoraExterna.Nome, achou = 1
		From
			@tableReturn TabTemp
				inner join
			IntegradoraExterna with (nolock) on (IntegradoraExterna.Id = TabTemp.chaveInt or IntegradoraExterna.StrKey = TabTemp.chaveGuid)
		where
			TabTemp.tipo = @integradoraExternaNome and TabTemp.ChaveInt = IntegradoraExterna.Id
	end

if ((Select top 1 tipo from @tableReturn TabTemp where TabTemp.tipo = @integradoraExternaAgenciaNome) is not null)
	begin
		update @tableReturn 
			Set  valorString = IntegradoraExterna.Nome, achou = 1
		From
			@tableReturn TabTemp
				inner join
			IntegradoraExterna with (nolock) on (IntegradoraExterna.Id = TabTemp.chaveInt or IntegradoraExterna.StrKey = TabTemp.chaveGuid)
		where
			TabTemp.tipo = @integradoraExternaAgenciaNome and TabTemp.ChaveInt = IntegradoraExterna.Id
	end


if ((Select top 1 tipo from @tableReturn TabTemp where TabTemp.tipo = @prospeccaoNome) is not null)
	begin
		update @tableReturn 
			Set  valorString = Prospeccao.Nome, achou = 1
		From
			@tableReturn TabTemp
				inner join
			Prospeccao with (nolock) on (Prospeccao.Id = TabTemp.chaveInt or Prospeccao.IdGuid = TabTemp.chaveGuid)
		where
			TabTemp.tipo = @prospeccaoNome and TabTemp.ChaveInt = Prospeccao.Id
	end

if ((Select top 1 tipo from @tableReturn TabTemp where TabTemp.tipo = @produtoNome) is not null)
	begin
		update @tableReturn 
			Set  valorString = Produto.Nome, achou = 1
		From
			@tableReturn TabTemp
				inner join
			Produto with (nolock) on (Produto.Id = TabTemp.chaveInt or Produto.GUID = TabTemp.chaveGuid)
		where
			TabTemp.tipo = @produtoNome and TabTemp.ChaveInt = Produto.Id
	end

if ((Select top 1 tipo from @tableReturn TabTemp where TabTemp.tipo = @canalNome) is not null)
	begin
		update @tableReturn 
			Set  valorString = Canal.Nome, achou = 1
		From
			@tableReturn TabTemp
				inner join
			Canal with (nolock) on (Canal.Id = TabTemp.chaveInt or Canal.GUID = TabTemp.chaveGuid)
		where
			TabTemp.tipo = @canalNome and TabTemp.ChaveInt = Canal.Id
	end


Select * from @tableReturn;

CREATE procedure [dbo].[ProcGetReferencias] 
(
	@IdContaSistema int,
	@IdCanal int,
	@IdMidia int,
	@IdPeca int,
	@IdClassificacao int,
	@IdPoliticaDePrivacidade int,
	@IdProduto int,
	@IdCampanha int
)
AS
Begin
SELECT
	(case when @IdCanal is not null then (Select Canal.Id from Canal with (nolock) where Canal.id = @IdCanal and Canal.idContaSistema = @IdContaSistema) end) as IdCanal,
	(case when @IdMidia is not null then (Select Midia.Id from Midia with (nolock) where Midia.id = @IdMidia and Midia.idContaSistema = @IdContaSistema) end) as IdMidia,
	(case when @IdPeca is not null then (Select Peca.Id from Peca with (nolock) where Peca.id = @IdPeca and Peca.idMidia = @IdMidia) end) as IdPeca,
	(case when @IdClassificacao is not null then (Select Classificacao.Id from Classificacao with (nolock) where Classificacao.id = @IdClassificacao and Classificacao.idContaSistema = @IdContaSistema) end) as IdClassificacao,
	(case when @IdPoliticaDePrivacidade is not null then (Select PoliticaDePrivacidade.Id from PoliticaDePrivacidade with (nolock) where PoliticaDePrivacidade.id = @IdPoliticaDePrivacidade and PoliticaDePrivacidade.idContaSistema = @IdContaSistema) end) as IdPoliticaDePrivacidade,
	(case when @IdProduto is not null then (Select Produto.Id from Produto with (nolock) where Produto.id = @IdProduto and Produto.idContaSistema = @IdContaSistema) end) as IdProduto,
	(case when @IdCampanha is not null then (Select Campanha.Id from Campanha with (nolock) where Campanha.id = @IdCampanha and Campanha.idContaSistema = @IdContaSistema) end) as IdCampanha
END;

CREATE procedure [dbo].[ProcGetRemessaDCProcessamentoNaoConcluido] 
(
	@qtdRegistros int,
	@segundosSemProcessamento int,
	@atualizarDataProcessamento bit
)

as
begin
	declare @dtNow datetime = dbo.GetDateCustom();
	declare @dtConsiderar datetime = DATEADD(ss, -@segundosSemProcessamento, @dtNow);
	declare @tabTemp table (IdRemessa int);

	insert into @tabTemp
	Select
		top(@qtdRegistros) 
		RemessaDC.IdRemessa as IdRemessa
	From
		RemessaDC WITH (nolock)
	Where
		RemessaDC.StatusProcessamento <> 'CONCLUIDO'
			and
		RemessaDC.Status <> 'CONCLUIDO'
			and
		(
			RemessaDC.DtStatusProcessamento is null
				or
			RemessaDC.DtStatusProcessamento < @dtConsiderar
		)

	-- Caso positivo irá setar a data de processamento sendo a data atual para que não seja
	-- retornado os mesmos registros na próxima chamada
	if @atualizarDataProcessamento = 1
		begin
			Update 
				RemessaDC
			Set 
				DtStatusProcessamento = @dtNow,
				QtdStatusProcessamento = QtdStatusProcessamento + 1
			From
				RemessaDC WITH (READPAST)
					inner join
				@tabTemp TabTemp on TabTemp.IdRemessa = RemessaDC.IdRemessa
		end


	select TabeTemp.IdRemessa from @tabTemp as TabeTemp

	RETURN
end;

CREATE procedure [dbo].[ProcGetRemessaDCStatusNaoConcluido] 
(
	@qtdRegistros int,
	@segundosSemProcessamento int,
	@atualizarDataStatus bit
)

as
begin
	declare @dtNow datetime = dbo.GetDateCustom();
	declare @dtConsiderar datetime = DATEADD(ss, -@segundosSemProcessamento, @dtNow);
	declare @tabTemp table (IdRemessa int, IdInteracao int, IdAtendimento int, IdContaSistema int, IdUsuarioContaSistema int);

	insert into @tabTemp (IdRemessa, IdInteracao, IdAtendimento, IdContaSistema, IdUsuarioContaSistema)
	Select
		top(@qtdRegistros) 
		RemessaDC.IdRemessa as IdRemessa,
		Ligacao.IdInteracao as IdInteracao,
		Interacao.IdSuperEntidade as IdAtendimento,
		Remessa.IdContaSistema,
		Remessa.IdUsuarioContaSistema

	From
		RemessaDC with (nolock)
			inner join
		Remessa  with (nolock) on RemessaDC.IdRemessa = Remessa.Id
			left outer join
		Ligacao with (nolock) on RemessaDC.IdRemessa = Ligacao.IdRemessa
			left outer join 
		Interacao with (nolock) on Ligacao.IdInteracao = Interacao.Id

	Where
		RemessaDC.StatusProcessamento = 'CONCLUIDO'
			and
		RemessaDC.Status <> 'CONCLUIDO'
			and
		(
			RemessaDC.DtStatus is null
				or
			RemessaDC.DtStatus < @dtConsiderar
		)

	-- Caso positivo irá setar a data do status sendo a data atual para que não seja
	-- retornado os mesmos registros na próxima chamada
	if @atualizarDataStatus = 1
		begin
			Update 
				RemessaDC
			Set 
				DtStatus = @dtNow
			From
				RemessaDC  WITH (READPAST)
					inner join
				@tabTemp TabTemp on TabTemp.IdRemessa = RemessaDC.IdRemessa
		end


	select TabeTemp.* from @tabTemp as TabeTemp

	RETURN
end;

CREATE procedure [dbo].[ProcGetRemessaTVProcessamentoNaoConcluido] 
(
	@qtdRegistros int,
	@segundosSemProcessamento int,
	@atualizarDataProcessamento bit
)

as
begin
	declare @dtNow datetime = dbo.GetDateCustom();
	declare @dtConsiderar datetime = DATEADD(ss, -@segundosSemProcessamento, @dtNow);
	declare @tabTemp table (IdRemessa int);

	insert into @tabTemp
	Select
		top(@qtdRegistros) 
		RemessaTotalVoice.IdRemessa as IdRemessa
	From
		RemessaTotalVoice with (nolock)
	Where
		RemessaTotalVoice.StatusProcessamento <> 'CONCLUIDO'
			and
		RemessaTotalVoice.Status <> 'CONCLUIDO'
			and
		(
			RemessaTotalVoice.DtStatusProcessamento is null
				or
			RemessaTotalVoice.DtStatusProcessamento < @dtConsiderar
		)

	-- Caso positivo irá setar a data de processamento sendo a data atual para que não seja
	-- retornado os mesmos registros na próxima chamada
	if @atualizarDataProcessamento = 1
		begin
			Update 
				RemessaTotalVoice
			Set 
				DtStatusProcessamento = @dtNow,
				QtdStatusProcessamento = QtdStatusProcessamento + 1
			From
				RemessaTotalVoice with (nolock)
					inner join
				@tabTemp TabTemp on TabTemp.IdRemessa = RemessaTotalVoice.IdRemessa
		end

	select TabeTemp.IdRemessa from @tabTemp as TabeTemp

	RETURN
end;

CREATE procedure [dbo].[ProcGetRemessaTVStatusNaoConcluido] 
(
	@qtdRegistros int,
	@segundosSemProcessamento int,
	@atualizarDataStatus bit
)

as
begin
	declare @dtNow datetime = dbo.GetDateCustom();
	declare @dtConsiderar datetime = DATEADD(ss, -@segundosSemProcessamento, @dtNow);
	declare @tabTemp table (IdRemessa int, IdInteracao int, IdAtendimento int);

	insert into @tabTemp (IdRemessa, IdInteracao, IdAtendimento)
	Select
		top(@qtdRegistros) 
		RemessaTotalVoice.IdRemessa as IdRemessa,
		Ligacao.IdInteracao as IdInteracao,
		Interacao.IdSuperEntidade as IdAtendimento

	From
		RemessaTotalVoice with (nolock)
			inner join
		Remessa  with (nolock) on RemessaTotalVoice.IdRemessa = Remessa.Id
			left join
		Ligacao with (nolock) on RemessaTotalVoice.IdRemessa = Ligacao.IdRemessa
			left join 
		Interacao with (nolock) on Ligacao.IdInteracao = Interacao.Id

	Where
		RemessaTotalVoice.StatusProcessamento = 'CONCLUIDO'
			and
		RemessaTotalVoice.Status <> 'CONCLUIDO'
			and
		(
			RemessaTotalVoice.DtStatus is null
				or
			RemessaTotalVoice.DtStatus < @dtConsiderar
		)

	-- Caso positivo irá setar a data do status sendo a data atual para que não seja
	-- retornado os mesmos registros na próxima chamada
	if @atualizarDataStatus = 1
		begin
			Update 
				RemessaTotalVoice
			Set 
				DtStatus = @dtNow
			From
				RemessaTotalVoice  WITH (NOLOCK)
					inner join
				@tabTemp TabTemp on TabTemp.IdRemessa = RemessaTotalVoice.IdRemessa
		end


	select TabeTemp.* from @tabTemp as TabeTemp

	RETURN
end;

CREATE procedure [dbo].[ProcGetResumoNegocio] 
(
	@IdContaSistema int,
	@IdUsuarioContaSistema int
)
as

Select
	Classificacao.Id,
	Classificacao.IdGuid,
	Classificacao.Valor2 as ClassificacaoGrupo, 	
	Classificacao.Valor as ClassificacaoValor, 	
	Classificacao.Ordem as ClassificacaoOrdem, 
	ISNULL(Count(Atendimento.id),0) as QtdAtendimento,
	ISNULL(sum(dbo.ISZERO(Atendimento.ValorNegocio, Produto.ValorMedio)),0) as VolumeFinanceiro,
	ISNULL(sum((dbo.ISZERO(Atendimento.ComissaoNegocio, Produto.ComissaoMedio) * dbo.ISZERO(Atendimento.ValorNegocio, Produto.ValorMedio)) / 100),0) as ComissaoVolumeFinanceiro
From
	Classificacao WITH (nolock) 
		left outer join
	Atendimento WITH (nolock) on	Classificacao.Id = Atendimento.idClassificacao and 
									Atendimento.IdUsuarioContaSistemaAtendimento = @IdUsuarioContaSistema and 
									Atendimento.StatusAtendimento = 'ATENDIDO'
		left outer join
	Produto WITH (nolock) on Produto.id = Atendimento.idProduto
Where
	Classificacao.idContaSistema = @IdContaSistema

Group by
	Classificacao.Id,
	Classificacao.IdGuid,
	Classificacao.Valor2,
	Classificacao.Valor,
	Classificacao.Ordem,
	Classificacao.Status
having
	Classificacao.Status = 'AT'
		or
	Count(Atendimento.id) > 0

Order by
	Classificacao.Ordem;

CREATE procedure [dbo].[ProcGetTabelaoAtendimento] 
(
	@IdContaSistema int,
	@strArrayIdsAtendimentos varchar(max),
	@strArrayIdInteracaoTipo varchar(max),
	@PageSize int,
	@PageNumber int,
	@AdicionarProximoRegistro bit
)
as
	declare @FirstRow INT;
	declare @LastRow INT;

	if @PageNumber = 0 begin set @PageNumber = 1 end

	set	@FirstRow = (( @PageNumber - 1) * @PageSize) + 1
	set	@LastRow = ((@PageNumber - 1) * @PageSize) + @PageSize
	if @AdicionarProximoRegistro <> 0 and @LastRow < 2147483647 begin set @LastRow += 1 end

	declare @tableIdTabelao table (id int)
	declare @tableIdAtendimento table (idAtendimento int)
	declare @TableIdInteracaoTipo table	(IdInteracaoTipo int)


	insert into @tableIdAtendimento select TabAuxIds.OrderID from dbo.SplitIDs(@strArrayIdsAtendimentos) TabAuxIds;

	with paginacao as  
	(
		Select
			row_number() over (order by TabelaoAtendimento.AtendimentoId desc) as 'RowNumber',	
			TabelaoAtendimento.*,
			'' as Aux1,
			'' as Aux2,
			'' as Aux3
		from 
			TabelaoAtendimento with (nolock)
				inner join
			@tableIdAtendimento Tab2 on Tab2.idAtendimento = TabelaoAtendimento.AtendimentoId
		
		where
			TabelaoAtendimento.ContaSistemaId = @IdContaSistema
	)
	select 
		*,
		-- // Comentado dia 06/10/2021 até ajustar
		case when @strArrayIdInteracaoTipo is not null then [dbo].[GetInteracaoTextoList](paginacao.ContaSistemaId, paginacao.AtendimentoId, 'USUARIO', null, @strArrayIdInteracaoTipo) else null end as FollowUpsUsuario
		--null as FollowUpsUsuario
	from paginacao  
	WHERE	RowNumber BETWEEN @FirstRow AND @LastRow
	ORDER BY RowNumber ASC;

CREATE procedure [dbo].[ProcGetTabelaoInteracaoResumo] 
(
	@IdContaSistema int,
	@IsAdministradorDoSistema bit,
	@IdUsuarioContaSistemaExecutando int,
	@IdProduto int,
	@IdCampanha int,
	@dtInicioInclusao date,
	@dtFimInclusao date,
	@dtInicioInteracao date,
	@dtFimInteracao date,
	@dtInicioConclusao date,
	@dtFimConclusao date,
	@dtAtendimentoIncluidoInicio date,
	@dtAtendimentoIncluidoFim date,
	@dtAtendimentoAtendidoInicio date,
	@dtAtendimentoAtendidoFim date,
	@Realizado char(3),
	@AtorPartida varchar(20),
	@IdInteracaoTipo int,
	@StatusInteracaoTipo varchar(2),
	@InteracaoIds varchar(max)
)
as
	set	@Realizado = dbo.RetNullOrVarChar(@Realizado);
	set	@AtorPartida = dbo.RetNullOrVarChar(@AtorPartida);
	set	@StatusInteracaoTipo = dbo.RetNullOrVarChar(@StatusInteracaoTipo);
	set @InteracaoIds = dbo.RetNullOrVarChar(@InteracaoIds);

	declare @TableInteracaoId TABLE
	(
		Id int
	)

	if @InteracaoIds is not null 
		begin
			insert @TableInteracaoId (Id)
			Select 
				OrderID
			from 
				SplitIDs(@InteracaoIds) TabAux
		end;
	
	Select
		InteracaoTipo.Valor as InteracaoTipoValor,
		InteracaoTipo.ValorAbreviado as InteracaoTipoValorAbreviado,
		TabTemp.*
	from
		InteracaoTipo WITH (NOLOCK)
			left outer join
		(
			Select 
				TabelaoAtendimento.*,
				TabelaoInteracaoResumo.InteracaoAtorPartida,
				TabelaoInteracaoResumo.DtInteracao,
				TabelaoInteracaoResumo.DtInteracaoFull,
				TabelaoInteracaoResumo.DtInteracaoInclusao,
				TabelaoInteracaoResumo.DtInteracaoInclusaoFull,
				TabelaoInteracaoResumo.DtInteracaoConclusao,
				TabelaoInteracaoResumo.DtInteracaoConclusaoFull,
				TabelaoInteracaoResumo.IdInteracaoTipo,
				TabelaoInteracaoResumo.IdInteracao,
				TabelaoInteracaoResumo.Periodo,
				TabelaoInteracaoResumo.InteracaoRealizado,
				TabelaoInteracaoResumo.StrMidia,
				TabelaoInteracaoResumo.StrPeca,
				TabelaoInteracaoResumo.StrIntegradoraExterna,
				TabelaoInteracaoResumo.StrIntegradoraExternaAgencia,
				TabelaoInteracaoResumo.StrGrupoPecaMarketing,
				TabelaoInteracaoResumo.StrCampanhaMarketing,
				TabelaoInteracaoResumo.StrCanal,
				TabelaoInteracaoResumo.StrProdutoNome,

				TabelaoInteracaoResumo.UsuarioContaSistemaRealizouId,
				TabelaoInteracaoResumo.UsuarioContaSistemaIncluiuId,
				TabelaoInteracaoResumo.UsuarioContaSistemaRealizouNome,
				TabelaoInteracaoResumo.UsuarioContaSistemaRealizouApelido,
				TabelaoInteracaoResumo.UsuarioContaSistemaIncluiuNome
				
			from
				TabelaoInteracaoResumo WITH (NOLOCK)
					inner join
				TabelaoAtendimento WITH (NOLOCK) on TabelaoAtendimento.AtendimentoId = TabelaoInteracaoResumo.IdAtendimento
					LEFT OUTER JOIN 
				-- Selecionará todos grupos inferiores que por ventura o usuário em questão seja administrador
				GrupoHierarquiaUsuarioContaSistema WITH (NOLOCK) on (@IsAdministradorDoSistema = 0 and GrupoHierarquiaUsuarioContaSistema.idContaSistema = @IdContaSistema and GrupoHierarquiaUsuarioContaSistema.idUsuarioContaSistema = @IdUsuarioContaSistemaExecutando and GrupoHierarquiaUsuarioContaSistema.idGrupo = TabelaoAtendimento.GrupoId)	
					left outer join 
				---- Seleciona para verificar se o usuario que esta executando e adm da campanha, caso seja o mesmo podera visualizar os registros
				CampanhaAdministrador WITH (NOLOCK) on (@IsAdministradorDoSistema = 0 and CampanhaAdministrador.idCampanha = TabelaoAtendimento.CampanhaId and CampanhaAdministrador.idUsuarioContaSistema = @IdUsuarioContaSistemaExecutando)				
				
			where
				TabelaoInteracaoResumo.idContaSistema = @IdContaSistema
					and
				(
					@InteracaoIds is null or EXISTS (Select TabTemp.Id from @TableInteracaoId TabTemp where TabelaoInteracaoResumo.Id = TabTemp.Id)
				)
					and
				(@dtAtendimentoIncluidoInicio is null or TabelaoAtendimento.AtendimentoDtInclusao >= @dtAtendimentoIncluidoInicio)
					and
				(@dtAtendimentoIncluidoFim is null or TabelaoAtendimento.AtendimentoDtInclusao <= @dtAtendimentoIncluidoFim)
					and

				(@dtAtendimentoAtendidoInicio is null or TabelaoAtendimento.AtendimentoDtInicio >= @dtAtendimentoAtendidoInicio)
					and
				(@dtAtendimentoAtendidoFim is null or TabelaoAtendimento.AtendimentoDtInicio <= @dtAtendimentoAtendidoFim)
					and

				(@dtInicioInteracao is null or TabelaoInteracaoResumo.DtInteracao >= @dtInicioInteracao)
					and
				(@dtFimInteracao is null or TabelaoInteracaoResumo.DtInteracao <= @dtFimInteracao)
					and

				(@dtInicioInclusao is null or TabelaoInteracaoResumo.DtInteracaoInclusao >= @dtInicioInclusao)
					and
				(@dtFimInclusao is null or TabelaoInteracaoResumo.DtInteracaoInclusao <= @dtFimInclusao)
					and

				(@dtInicioConclusao is null or TabelaoInteracaoResumo.DtInteracaoConclusao >= @dtInicioConclusao)
					and
				(@dtFimConclusao is null or TabelaoInteracaoResumo.DtInteracaoConclusao <= @dtFimConclusao)
					and	

				(@Realizado is null or TabelaoInteracaoResumo.InteracaoRealizado = @Realizado)
					and

				(@AtorPartida is null or TabelaoInteracaoResumo.InteracaoAtorPartida = @AtorPartida)
					and

				(@IdProduto is null or TabelaoAtendimento.ProdutoId = @IdProduto)			
					and							

				(@IdInteracaoTipo is null or TabelaoInteracaoResumo.IdInteracaoTipo = @IdInteracaoTipo)			
					and		
				
				(@IdCampanha is null or TabelaoAtendimento.CampanhaId = @IdCampanha)			
					and		
				(
					-- caso seja administrador do sistema não irá considerar a hierarquia de grupos
					@IsAdministradorDoSistema = 1
						or
					CampanhaAdministrador.IdUsuarioContaSistema is not null
						or
					GrupoHierarquiaUsuarioContaSistema.Id is not null			
				)
				
		) TabTemp on TabTemp.IdInteracaoTipo = InteracaoTipo.Id
	Where 
		InteracaoTipo.IdContaSistema = @IdContaSistema
			and
		(@StatusInteracaoTipo is null or InteracaoTipo.Status = @StatusInteracaoTipo)			
			and		
		(@IdInteracaoTipo is null or InteracaoTipo.Id = @IdInteracaoTipo)		
			


	-- http://www.sommarskog.se/dyn-search.html
	OPTION (RECOMPILE);

CREATE procedure [dbo].[ProcGetTabelasRelacionadas] 
  @table varchar(256) -- use two part name convention
, @lvl int=0 -- do not change
, @ParentTable varchar(256)='' -- do not change
, @debug bit = 1
as
begin
	-- https://www.mssqltips.com/sqlservertip/4059/script-to-delete-data-from-sql-server-tables-with-foreign-key-constraints/
	set nocount on;
	declare @dbg bit;
	set @dbg=@debug;
	if object_id('tempdb..#tbl', 'U') is null
		create table  #tbl  (id int identity, tablename varchar(256), lvl int, ParentTable varchar(256));
	declare @curS cursor;
	if @lvl = 0
		insert into #tbl (tablename, lvl, ParentTable)
		select @table, @lvl, Null;
	else
		insert into #tbl (tablename, lvl, ParentTable)
		select @table, @lvl,@ParentTable;
	if @dbg=1	
		print replicate('----', @lvl) + 'lvl ' + cast(@lvl as varchar(10)) + ' = ' + @table;
	
	if not exists (select * from sys.foreign_keys where referenced_object_id = object_id(@table))
		return;
	else
	begin -- else
		set @ParentTable = @table;
		set @curS = cursor for
		select tablename=object_schema_name(parent_object_id)+'.'+object_name(parent_object_id)
		from sys.foreign_keys 
		where referenced_object_id = object_id(@table)
		and parent_object_id <> referenced_object_id; -- add this to prevent self-referencing which can create a indefinitive loop;

		open @curS;
		fetch next from @curS into @table;

		while @@fetch_status = 0
		begin --while
			set @lvl = @lvl+1;
			-- recursive call
			exec dbo.ProcGetTabelasRelacionadas @table, @lvl, @ParentTable, @dbg;
			set @lvl = @lvl-1;
			fetch next from @curS into @table;
		end --while
		close @curS;
		deallocate @curS;
	end -- else
	if @lvl = 0
		select * from #tbl;
	return;
end;

-- https://www.mssqltips.com/sqlservertip/4059/script-to-delete-data-from-sql-server-tables-with-foreign-key-constraints/
CREATE procedure [dbo].[ProcGetTabelasRelacionadasDelete]
  @tableDeleteName varchar(256), -- use two part name convention
  @distinctTable bit = 1
as
begin
	set nocount on

	if object_id('tempdb..#tmp') is not null
		drop table #tmp;
	create table  #tmp  (id int, tablename varchar(256), lvl int, ParentTable varchar(256));

	declare @tableDelName varchar(256)
	set @tableDelName = CONCAT('dbo.', @tableDeleteName)

	insert into #tmp 
	exec dbo.ProcGetTabelasRelacionadas @table = @tableDelName, @debug=0;


	declare @where varchar(max) ='where '+@tableDelName+'.id=@DeleteTableId' -- if @where clause is null or empty, it will delete tables as a whole with the right order
	declare @curFK cursor, @fk_object_id int;
	declare @sqlcmd varchar(max)='';
	declare @crlf char(2)=char(0x0d)+char(0x0a);
	declare @child varchar(256);
	declare @parent varchar(256);
	declare @lvl int;
	declare @id int;
	declare @i int;
	declare @t table (tablename varchar(128));
	declare @curT cursor;
	declare @tableTemp table (nameTable varchar(256));
	declare @tableDaVez varchar(256);
	
	if isnull(@where, '')= ''
		begin
			set @curT = cursor for select tablename, lvl from #tmp order by lvl desc
			open @curT;
			fetch next from @curT into @child, @lvl;
				while @@fetch_status = 0
					begin -- loop @curT
						if not exists (select 1 from @t where tablename=@child)
							insert into @t (tablename) values (@child);
						fetch next from @curT into @child, @lvl;

					end -- loop @curT
			close @curT;
			deallocate @curT;


			--select  @sqlcmd = @sqlcmd + 'delete from ' + tablename + @crlf from @t ;
			--print @sqlcmd;
		end
	else
		begin 
			declare curT cursor for
				select  lvl, id, tablename
				from #tmp
				order by lvl desc;

			open curT;
			fetch next from curT into  @lvl, @id, @tableDaVez;
				while @@FETCH_STATUS =0
					begin
						set @i=0;
						if @lvl =0
							begin -- this is the root level
								select @sqlcmd = 'delete from ' + tablename from #tmp where id = @id;
							end -- this is the roolt level

						while @i < @lvl
							begin -- while

								select top 1 @child=TableName, @parent=ParentTable from #tmp where id <= @id-@i and lvl <= @lvl-@i order by lvl desc, id desc;
								set @curFK = cursor for
								select object_id from sys.foreign_keys 
								where parent_object_id = object_id(@child)
								and referenced_object_id = object_id(@parent)

								open @curFK;
								fetch next from @curFk into @fk_object_id
									while @@fetch_status =0
										begin -- @curFK
											if @i=0
												set @sqlcmd = 'delete from ' + @child + @crlf +
												'from ' + @child + @crlf + 'inner join ' + @parent  ;
											else
												set @sqlcmd = @sqlcmd + @crlf + 'inner join ' + @parent ;

											;with c as 
											(
												select child = object_schema_name(fc.parent_object_id)+'.' + object_name(fc.parent_object_id), child_col=c.name
												, parent = object_schema_name(fc.referenced_object_id)+'.' + object_name(fc.referenced_object_id), parent_col=c2.name
												, rnk = row_number() over (order by (select null))
												from sys.foreign_key_columns fc
												inner join sys.columns c
												on fc.parent_column_id = c.column_id
												and fc.parent_object_id = c.object_id
												inner join sys.columns c2
												on fc.referenced_column_id = c2.column_id
												and fc.referenced_object_id = c2.object_id
												where fc.constraint_object_id=@fk_object_id
											)
												select @sqlcmd =@sqlcmd +  case rnk when 1 then ' on '  else ' and ' end 
												+ @child +'.'+ child_col +'='  +  @parent   +'.' + parent_col
												from c;
												fetch next from @curFK into @fk_object_id;
										end --@curFK
								close @curFK;
								deallocate @curFK;
								set @i = @i +1;
							end --while

						if (@distinctTable = 0 or not exists (select TabAux.nameTable from @tableTemp TabAux where TabAux.nameTable = @tableDaVez))
							begin
								insert @tableTemp (nameTable) values (@tableDaVez)
								
								print @sqlcmd + @crlf + @where + ';';
								print ' '

							end

						fetch next from curT into  @lvl, @id, @tableDaVez;
					end
			close curT;
			deallocate curT;
		end

		
end;

CREATE procedure [dbo].[ProcGetUsuarioContaSistema] 
(
	@IdContaSistema as int,
	@IsAdministradorSistema as bit,
	@IdUsuarioContaSistemaExecutando as int,
	@ConsiderarHierarquia as bit,
	@IdGrupoFiltro as int,
	@IdUsuarioContaSistemaFiltrar as int,
	@SomenteUsuarioContaSistemaAtivo as bit,
	@PessoaNome varchar(500),
	@PessoaEmail varchar(300),
	@RecuperarGrupoHierarquia as bit,

	@OrderBy varchar(100),
	@PageSize INT,
	@PageNumber INT,
	@AdicionarProximoRegistro bit	
)
as
declare @ConsiderarHierarquiaAux bit = 0;
declare @FirstRow INT;
declare @LastRow INT;

-- Se faz necessário para caso seja nulo retornará false ou 0									
set @ConsiderarHierarquia = dbo.RetBitNotNull(@ConsiderarHierarquia, 1)
set @AdicionarProximoRegistro = dbo.RetBitNotNull(@AdicionarProximoRegistro, 1)
set @SomenteUsuarioContaSistemaAtivo = dbo.RetBitNotNull(@SomenteUsuarioContaSistemaAtivo, 1)
set @IsAdministradorSistema = dbo.RetBitNotNull(@IsAdministradorSistema, 0)
set @RecuperarGrupoHierarquia = dbo.RetBitNotNull(@RecuperarGrupoHierarquia, 0)


set @PessoaNome = dbo.RetNullOrVarChar(@PessoaNome);
set @PessoaEmail = dbo.RetNullOrVarChar(@PessoaEmail);

if @PageNumber is null or @PageNumber = 0 begin set @PageNumber = 1 end;

set	@FirstRow = (( @PageNumber - 1) * @PageSize) + 1;
set	@LastRow = ((@PageNumber - 1) * @PageSize) + @PageSize;
if @AdicionarProximoRegistro <> 0 and @LastRow < 2147483647 begin set @LastRow += 1 end;


-- Tabela auxiliar onde será salvo os usuários inferiores
declare @TabAuxUsuariosInferioresByGrupo table(
												IdUsuarioContaSistema int NOT NULL,
												IdGrupo int);


-- Preenche a hierarquia de usuário
if	(
		(@IsAdministradorSistema = 0 and @ConsiderarHierarquia = 1) or
		@IdGrupoFiltro is not null
	) 
	begin
		-- Irá forçar a query a usar a hierarquia
		set @ConsiderarHierarquiaAux = 1;
	
		insert @TabAuxUsuariosInferioresByGrupo (IdUsuarioContaSistema, IdGrupo) 
		select 
			distinct tabAux.IdUsuarioContaSistema, tabAux.IdGrupo
		from 
			dbo.GetUsuarioContaSistemaInferior(@IdUsuarioContaSistemaExecutando) tabAux
		where
			@IdGrupoFiltro is null or tabAux.IdGrupo = @IdGrupoFiltro and
			@IdUsuarioContaSistemaFiltrar is null or tabAux.IdUsuarioContaSistema = @IdUsuarioContaSistemaFiltrar
	end;

with paginacao as  
(
	Select 
		row_number() over (order by Pessoa.Nome asc) as 'RowNumber',
		UsuarioContaSistema.idPerfilUsuario as PerfilUsuarioId,
		PerfilUsuario.Nome as PerfilUsuarioNome,
		PerfilUsuario.Administrador as PerfilUsuarioAdministrador,
		
		
		UsuarioContaSistema.IdContaSistema as ContaSistemaId,
		UsuarioContaSistema.Id as IdUsuarioContaSistema,
		UsuarioContaSistema.IdPessoa as IdPessoa,
		Pessoa.Guid as PessoaGuid,
		UsuarioContaSistema.GUID as UsuarioContaSistemaGuid,
		Pessoa.Nome as Nome,
		Pessoa.Apelido as Apelido,
		Pessoa.Email as Email,
		UsuarioContaSistema.DtUltimoAcesso as DtUltimoAcesso,
		UsuarioContaSistema.Status as Status,
		UsuarioContaSistema.DtExpiracao as DtExpiracao,
		case when @RecuperarGrupoHierarquia = 1 then dbo.GetGrupoUsuarioContaSistemaHierarquiaList(UsuarioContaSistema.Id,1,1,1) else null end as GrupoHierarquiaConcatenado
		 
	From
		UsuarioContaSistema WITH (NOLOCK)
			inner join
		Pessoa WITH (NOLOCK) on Pessoa.Id = UsuarioContaSistema.IdPessoa
			left outer join
		PerfilUsuario WITH (NOLOCK) on PerfilUsuario.id =  UsuarioContaSistema.idPerfilUsuario

	where
		UsuarioContaSistema.IdContaSistema = @IdContaSistema 
			and
		(
			@ConsiderarHierarquiaAux = 0
				or
			Exists (Select TabAux.IdGrupo from @TabAuxUsuariosInferioresByGrupo TabAux where TabAux.IdUsuarioContaSistema = UsuarioContaSistema.Id)
		)
			and
		(
			@SomenteUsuarioContaSistemaAtivo = 0 or UsuarioContaSistema.Status = 'AT'
		)
			and		
		(
			@IdUsuarioContaSistemaFiltrar is null or UsuarioContaSistema.Id = @IdUsuarioContaSistemaFiltrar
		)	
			and
		(
			@PessoaNome is null or Pessoa.Nome like '%'+@PessoaNome+'%'
		)
			and
		(
			@PessoaEmail is null or Pessoa.Email like '%'+@PessoaEmail+'%'
		)
)
	select paginacao.* from paginacao  
	WHERE	RowNumber BETWEEN @FirstRow AND @LastRow
	ORDER BY RowNumber ASC;

CREATE procedure [dbo].[ProcGetUsuarioContaSistemaBySocket] 
(
	@listIdGuidUsuarioContaSistema varchar(max)
)
as

BEGIN

set @listIdGuidUsuarioContaSistema = dbo.RetNullOrVarChar(@listIdGuidUsuarioContaSistema)

select ContaSistema.Status as ContaSistemaStatus, ContaSistema.StatusConta as ContaSistemaStatusConta,
       PerfilUsuario.Permissao as PerfilUsuarioPermissao, PerfilUsuario.Administrador as PerfilUsuarioAdministrador, UsuarioContaSistema.*
	from 
		UsuarioContaSistema
			inner join
		PerfilUsuario on UsuarioContaSistema.IdPerfilUsuario = PerfilUsuario.id
			inner join
		ContaSistema on UsuarioContaSistema.idContaSistema = ContaSistema.id
			inner join
		dbo.SplitIDstring(@listIdGuidUsuarioContaSistema) TableUsuarioContaSistema on UsuarioContaSistema.Guid = TableUsuarioContaSistema.OrderID
END;

-- @@condiderarCampanhaCanal se faz necessário para não trazer no distinct usuários duplicados
-- já que um usuário pode estar em grupos distintos na mesma campanha, horario
-- no caso do chat isso não é necessário
CREATE procedure [dbo].[ProcGetUsuarioContaSistemaPlantaoHorario] 
(
	@idContaSistema int,
	@idCampanha int,
	@idCanal int,
	@dtAtendimento datetime,
	@somenteOnFilaCanalOffLine bit,
	@somenteOnFilaCanalOnLine bit,
	@somenteOnFilaCanalTelefone bit,
	@somenteOnFilaCanalWhatsApp bit,
	@strCanalTipo varchar(20),
	@condiderarCampanhaCanal bit,
	@strIdsUsuarioContaSistema varchar(max)
)
as

set @strCanalTipo = dbo.RetNullOrVarChar(@strCanalTipo)
set @strIdsUsuarioContaSistema = dbo.RetNullOrVarChar(@strIdsUsuarioContaSistema)
set @condiderarCampanhaCanal = (case when @condiderarCampanhaCanal is null then 1 else @condiderarCampanhaCanal end)

declare @TableUsuarioContaSistemaIds TABLE
(
	Ids int
)

if @strIdsUsuarioContaSistema is not null 
	begin
		insert @TableUsuarioContaSistemaIds
		Select OrderID from SplitIDstring(@strIdsUsuarioContaSistema)
		OPTION (RECOMPILE);
	end;

Select
	Distinct 

		ContaSistema.Guid as ContaSistemaIdGuid,

		UsuarioContaSistema.GUID as UsuarioContaSistemaIdGuid,
		Usuario.GuidUsuarioCorrex as UsuarioContaSistemaIdGuidCorrex,
		UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal.IdUsuarioContaSistema as UsuarioContaSistemaId,
		Pessoa.Nome as UsuarioContaSistemaNome,
		Pessoa.Apelido as UsuarioContaSistemaApelido,
		Pessoa.Email as UsuarioContaSistemaEmail,

		Canal.GUID as CanalIdGuid,
		CampanhaCanal.IdCanal as CanalId,
		Canal.Nome as CanalNome,

		Campanha.GUID as CampanhaIdGuid,
		CampanhaCanal.IdCampanha as CampanhaId,
		Campanha.Nome as CampanhaNome,

		UsuarioContaSistema.DtUltimaRequisicao as UsuarioContaSistemaDtUltimaRequisicao,
		UsuarioContaSistema.FilaCanalOffLine as UsuarioContaSistemaFilaCanalOffLine,
		UsuarioContaSistema.FilaCanalOnLine as UsuarioContaSistemaFilaCanalOnLine,
		UsuarioContaSistema.FilaCanalTelefone as UsuarioContaSistemaFilaCanalTelefone,		
		UsuarioContaSistema.FilaCanalWhatsApp as UsuarioContaSistemaFilaCanalWhatsAp,

		case when @condiderarCampanhaCanal = 1 then UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal.Id else null end as UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanalId,
		case when @condiderarCampanhaCanal = 1 then UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal.DtInteracaoFila else null end as UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanalDtInteracaoFila,
		case when @condiderarCampanhaCanal = 1 then UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal.Prioridade else 999999 end as UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanalPrioridade,
		case when @condiderarCampanhaCanal = 1 then CampanhaGrupo.IdGrupo else null end as GrupoId,
		case when @condiderarCampanhaCanal = 1 then PlantaoHorario.IdPlantao else null end as PlantaoId,		
		case when @condiderarCampanhaCanal = 1 then PlantaoHorario.Id else null end as PlantaoHorarioId

From
	UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal with (nolock)
		inner join
	UsuarioContaSistema with (nolock) on UsuarioContaSistema.Id = UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal.IdUsuarioContaSistema
		inner join
	Usuario with (nolock) on Usuario.IdPessoa = UsuarioContaSistema.IdPessoa
		inner join
	ContaSistema with (nolock) on ContaSistema.Id = UsuarioContaSistema.IdContaSistema
		inner join
	Pessoa with (nolock) on UsuarioContaSistema.IdPessoa = Pessoa.Id
		inner join
	CampanhaCanal  with (nolock) on UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal.IdCampanhaCanal = CampanhaCanal.Id
		inner join
	Campanha  with (nolock) on Campanha.Id = CampanhaCanal.IdCampanha
		inner join
	Canal with (nolock) on CampanhaCanal.IdCanal = Canal.Id
		inner join
	PlantaoHorario with (nolock) on PlantaoHorario.Id = UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal.IdPlantaoHorario
		inner join
	Plantao with (nolock) on Plantao.Id = PlantaoHorario.IdPlantao
		inner join
	CampanhaGrupo with (nolock) on CampanhaGrupo.Id = UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal.IdCampanhaGrupo
		inner join
	Grupo with (nolock) on Grupo.Id = CampanhaGrupo.IdGrupo
		
where
	(
		@strIdsUsuarioContaSistema is null or exists (select tab.Ids from @TableUsuarioContaSistemaIds tab where UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal.IdUsuarioContaSistema = tab.Ids)
	)
		and
	UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal.Status = 'AT'
		and
	CampanhaGrupo.Status = 'AT'
		and
	Grupo.Status = 'AT'
		and
	UsuarioContaSistema.Status = 'AT'
		and
	Plantao.Status = 'AT'
		and
	(
		@idContaSistema is null or Campanha.IdContaSistema = @idContaSistema
	)
		and
	(
		@idCampanha is null or CampanhaCanal.IdCampanha = @idCampanha
	)
			and
	(
		@idCanal is null or CampanhaCanal.IdCanal = @idCanal
	)
		and
	(
		@strCanalTipo is null or Canal.Tipo = @strCanalTipo
	)
		and
	(
		Plantao.DtInicioValidade <= @dtAtendimento
			and
		(Plantao.DtFimValidade >= @dtAtendimento or Plantao.DtFimValidade is null)
	)

		and

	(
		PlantaoHorario.DtInicio <= @dtAtendimento
			and
		PlantaoHorario.DtFim >= @dtAtendimento
			and
		PlantaoHorario.Status = 'AT'
	)
		and
	(
		@somenteOnFilaCanalOffLine is null or @somenteOnFilaCanalOffLine = 0 or UsuarioContaSistema.FilaCanalOffLine = 1
	)
		and
	(
		@somenteOnFilaCanalOnLine is null or @somenteOnFilaCanalOnLine = 0 or UsuarioContaSistema.FilaCanalOnLine = 1
	)
		and
	(
		@somenteOnFilaCanalTelefone is null or @somenteOnFilaCanalTelefone = 0
			or 
		(
			UsuarioContaSistema.FilaCanalTelefone = 1
				and
			exists (Select PessoaTelefone.id from PessoaTelefone with (nolock) where PessoaTelefone.IdPessoa = UsuarioContaSistema.IdPessoa)
		)
	)
		and
	(
		@somenteOnFilaCanalWhatsApp is null or @somenteOnFilaCanalWhatsApp = 0
			or 
		(
			UsuarioContaSistema.FilaCanalWhatsApp = 1
				and
			exists (Select PessoaTelefone.id from PessoaTelefone with (nolock) where PessoaTelefone.IdPessoa = UsuarioContaSistema.IdPessoa)
		)
	)

	---- http://www.sommarskog.se/dyn-search.html
	OPTION (RECOMPILE);

CREATE procedure [dbo].[ProcGetUsuariosContaSistema]
 @IdContaSistema as int
 as 

if(@IdContaSistema is not null)
begin
	select Pessoa.Nome,Pessoa.Apelido,Pessoa.Email,PessoaFisica.Sexo,PerfilUsuario.Nome as Perfil,Pessoa.TipoPessoa,PessoaFisica.Creci,PessoaFisica.CPF
	,UsuarioContaSistema.QtdAcesso,UsuarioContaSistema.DtUltimoAcesso,UsuarioContaSistema.Status,Grupo.Nome as Grupo,
	PessoaFisica.DtNascimento,PessoaTelefone.DDD,PessoaTelefone.Telefone from UsuarioContaSistema
	left join UsuarioContaSistemaGrupo
		on UsuarioContaSistemaGrupo.idUsuarioContaSistema = UsuarioContaSistema.id
	and UsuarioContaSistemaGrupo.id = (
		select Max (UsuarioContaSistemaGrupo2.id)
		from UsuarioContaSistemaGrupo UsuarioContaSistemaGrupo2
			inner join Grupo
				on Grupo.id = UsuarioContaSistemaGrupo2.idGrupo
		where UsuarioContaSistemaGrupo2.idUsuarioContaSistema = UsuarioContaSistema.id
		and UsuarioContaSistemaGrupo2.DtFim is null
		and Grupo.Status = 'AT'
	)
	left join Grupo
		on Grupo.id = UsuarioContaSistemaGrupo.idGrupo
	inner join Pessoa
		on Pessoa.Id = UsuarioContaSistema.idPessoa
	left join PessoaFisica
		on PessoaFisica.idPessoa = Pessoa.id
	inner join PerfilUsuario
		on PerfilUsuario.id = UsuarioContaSistema.idPerfilUsuario
	left join PessoaTelefone
		on PessoaTelefone.idPessoa = Pessoa.id
	and PessoaTelefone.id = (
		select min (PessoaTelefone2.id)
		from PessoaTelefone PessoaTelefone2
		where PessoaTelefone2.idPessoa = Pessoa.id
	)
	Where UsuarioContaSistema.idContaSistema = @IdContaSistema order by Pessoa.Nome asc
end;

CREATE procedure [dbo].[ProcGrupoDesvincularCampanha] @IdContaSistema as int, @IdUsuarioContaSistemaExecutandoAcao as int, @idCampanha as int, @IdsGrupoVincular as varchar(max)
 as 
begin
	Declare @dtNow as datetime = dbo.GetDateCustom()

	Select
		CampanhaGrupo.Id as CampanhaGrupoId
			into 
		#TabAuxGruposDesvincular
	From 
		Grupo with (nolock)
			inner join
		SplitIDs(@IdsGrupoVincular) TabAux on TabAux.OrderID = Grupo.Id
			inner join
		CampanhaGrupo on CampanhaGrupo.IdGrupo = Grupo.Id and CampanhaGrupo.IdCampanha = @idCampanha
	Where
		Grupo.IdContaSistema = @IdContaSistema
			and
		exists (Select CampanhaGrupo.Id from CampanhaGrupo with (nolock) where CampanhaGrupo.IdCampanha = @idCampanha and CampanhaGrupo.IdGrupo = Grupo.Id)
		

	begin tran
		begin
			with cteUsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal as 
			(
				select 
					UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal.Id
				from 
					UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal with (nolock) 
				where
					exists (Select * from #TabAuxGruposDesvincular temp where temp.CampanhaGrupoId = UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal.IdCampanhaGrupo)
			)
			delete from cteUsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal
		end

		begin
			with cteCampanhaGrupo as 
			(
				select 
					CampanhaGrupo.Id
				from 
					CampanhaGrupo with (nolock) 
				where
					exists (Select * from #TabAuxGruposDesvincular temp where temp.CampanhaGrupoId = CampanhaGrupo.Id)
			)
			delete from cteCampanhaGrupo
		end
	commit
end;

CREATE procedure [dbo].[ProcGrupoVincularCampanha] @IdContaSistema as int, @IdUsuarioContaSistemaExecutandoAcao as int, @idCampanha as int, @IdsGrupoVincular as varchar(max)
 as 
begin
	Declare @dtNow as datetime = dbo.GetDateCustom()

	Select
		Grupo.Id
			into 
		#TabAuxGruposVincular
	From 
		Grupo with (nolock)
			inner join
		SplitIDs(@IdsGrupoVincular) TabAux on TabAux.OrderID = Grupo.Id
	Where
		Grupo.IdContaSistema = @IdContaSistema
			and
		Grupo.Status = 'AT'
			and
		not exists (Select CampanhaGrupo.Id from CampanhaGrupo with (nolock) where CampanhaGrupo.IdCampanha = @idCampanha and CampanhaGrupo.IdGrupo = Grupo.Id)

	begin tran
		insert into CampanhaGrupo (IdCampanha, IdGrupo, Status, DtInclusao, DtModificacao) 
		Select @idCampanha, TabAux.Id, 'AT', @dtNow, @dtNow from #TabAuxGruposVincular TabAux
	commit
end;

CREATE procedure [dbo].[ProcKillAll] @onlyLock bit = 1, @notKill varchar(800)
as
begin
	-- @notKill deve ser repassado como string separado por ,

	declare @kill varchar(8000) = '';
	declare @dbName varchar(800) = DB_NAME();

	if @onlyLock = 1
		begin

			SELECT @kill = @kill + 'kill ' + CONVERT(varchar(5), r.blocking_session_id) + ';' 
			from   
				sys.dm_exec_requests r WITH (NOLOCK) 
					JOIN 
				sys.dm_exec_sessions se WITH (NOLOCK) ON r.session_id = se.session_id 
			WHERE 
				se.database_id  = db_id(@dbName)
					and
				r.blocking_session_id > 0
					and
				(@notKill is null or r.blocking_session_id not in (Select * from SplitIDs(@notKill)))
			

		end
	else
		begin

			SELECT @kill = @kill + 'kill ' + CONVERT(varchar(5), session_id) + ';'  
			FROM sys.dm_exec_sessions
			WHERE database_id  = db_id(@dbName)
		end

	EXEC(@kill)
end;

CREATE procedure [dbo].[ProcLimpezaDeBase] 
as
	-- comentar
	-- return	

	declare @dtnow datetime = dbo.getDateCustom()
	declare @dtReferenciaUtilizarMaximo datetime = @dtnow
	declare @BatchNome varchar(1000) = 'Batch_LimpezaDeBase'
	declare @dtUltimaAtualizacao datetime
	declare @GerarTudo bit = 1
	declare @errorSys bit = 0
	declare @erroMsg varchar(max) = ''

	-- Retorna a data que começou a última atualização
	select @dtUltimaAtualizacao = Max(TabelaoLog.Data2) from TabelaoLog with (nolock) where TabelaoLog.Nome = @BatchNome group by TabelaoLog.Nome

	-- Se o processamento atual não for de gerar tudo e a data não for nula
	-- Subentende-se que no momento está sendo atualizado e não deve rodar 2 atualizações ao mesmo tempo
	-- testará tb se faz mais de 120 minutos que a ultima query executou nesse caso irá considerar que hove erro e executará 
	-- zerando a hora para não ter problemas
	if (@dtUltimaAtualizacao is not null and DATEDIFF(MI, @dtUltimaAtualizacao, dbo.GetDateCustom()) < 180)
		begin
			return
		end
	--else
	--	begin
	--		update TabelaoLog set TabelaoLog.Data2 = dbo.GetDateCustom(), TabelaoLog.bit1 = @GerarTudo where TabelaoLog.Nome = @BatchNome
	--	end
	-- deleta os alarme que por ventura não tem nenhum interação
	-- No momento (04/10/2019) todo o alarme obrigatoriamente deve está atrelado a uma interação
	
		begin
			with cte as 
			(
				select Alarme.id from Alarme with (nolock) where not exists (select Interacao.IdAlarme from Interacao with (nolock) where Interacao.IdAlarme = Alarme.Id)
			)
			delete from cte
				
		end


	
		begin
			delete 
				UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal 
			from
				UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal with(nolock)
					inner join
				UsuarioContaSistema with(nolock) on UsuarioContaSistema.Id = UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal.IdUsuarioContaSistema
					inner join
				ContaSistema with(nolock) on ContaSistema.Id = UsuarioContaSistema.IdContaSistema
					inner join
				Pessoa with(nolock) on Pessoa.Id = UsuarioContaSistema.IdPessoa

			where
				ContaSistema.Id not in (151, 3, 7, 15, 23, 5, 222, 436)
					and
				(
					Pessoa.Email like '%@anapro.com.br'
						or
					ContaSistema.Status <> 'AT'
						or
					UsuarioContaSistema.Status = 'DE'
				)
			
		end

	
		begin
			-- Ajusta para caso ocorra algum atendimento atendido e que a motivação da não conversão esteja setado como diferente de nulo
			update atendimento set IdMotivacaoNaoConversaoVenda = null where Atendimento.StatusAtendimento = 'ATENDIDO' and IdMotivacaoNaoConversaoVenda is not null

			-- Ajusta os atendimento que por ventura estão atendidos mas a data de início do atendimento 
			-- não foi setado, ocorrerá geralmente em atendimentos atualizados na mão
			update atendimento set Atendimento.DtInicioAtendimento = SuperEntidade.DtInclusao
			from 
				Atendimento with (nolock)
					inner join
				SuperEntidade with (nolock) on Atendimento.id = SuperEntidade.Id

			where 
				atendimento.DtInicioAtendimento is null 
					and 
				Atendimento.StatusAtendimento = 'ATENDIDO'	

			
		end

	
		begin
			-- Exclui todos os usuários dos plantão horario que por ventura não faz mais parte do grupo da campanha
			-- mas por algum motivo ainda está em algum plantão horário
			-- ocorreu isso algumas vezes, o usuário não estav mais em um grupo elegível na campanha
			-- mas estava no plantão horario
			delete UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal
			from 
				UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal  with (nolock) 
					inner join
				CampanhaGrupo  with (nolock) on CampanhaGrupo.Id = UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal.IdCampanhaGrupo
					inner join
				Grupo  with (nolock)  on Grupo.Id = CampanhaGrupo.IdGrupo 
					inner join
				UsuarioContaSistemaGrupo  with (nolock) on UsuarioContaSistemaGrupo.IdGrupo = Grupo.Id and UsuarioContaSistemaGrupo.IdUsuarioContaSistema = UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal.IdUsuarioContaSistema
			where
				UsuarioContaSistemaGrupo.DtFim is not null
					and
				Not exists (
								Select UsuarioContaSistemaGrupo.Id 
								from 
									UsuarioContaSistemaGrupo  with (nolock) 
										inner join
									UsuarioContaSistema  with (nolock) on UsuarioContaSistema.id = UsuarioContaSistemaGrupo.IdUsuarioContaSistema
								where 
									UsuarioContaSistema.Status = 'AT' and
									UsuarioContaSistemaGrupo.IdGrupo = Grupo.Id and 
									UsuarioContaSistemaGrupo.IdUsuarioContaSistema = UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal.IdUsuarioContaSistema and 
									UsuarioContaSistemaGrupo.DtFim is null
							)
					and
				Not exists (
								Select UsuarioContaSistemaGrupoAdm.Id 
								from 
									UsuarioContaSistemaGrupoAdm  with (nolock) 
										inner join
									UsuarioContaSistema  with (nolock) on UsuarioContaSistema.id = UsuarioContaSistemaGrupoAdm.IdUsuarioContaSistema
								where 
									UsuarioContaSistema.Status = 'AT' and
									UsuarioContaSistemaGrupoAdm.IdGrupo = Grupo.Id and 
									UsuarioContaSistemaGrupoAdm.IdUsuarioContaSistema = UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal.IdUsuarioContaSistema and 
									UsuarioContaSistemaGrupoAdm.DtFim is null
							)
			
		end

	-- desativado em 14/01/2021 timeout
	--
	--	begin
	--		select 
	--			Atendimento.Id as AtendimentoId,
	--			-- deve ser considerado a data do ultimo status já que é a mesma que deverá ser utilizada nos casos de comparação do último alarme ativo
	--			(Select top 1 Alarme.Id from Alarme  with (nolock)  where Alarme.IdSuperEntidade = Atendimento.id order by Alarme.DataUltimoStatus desc) as idAlarmeUltimo,
	--			-- deve ser considerado a data a qual o alarme será executado, para que possa ser considerado a ultima data que o atendimento possuia um próximo passo
	--			(Select top 1 Alarme.Id from Alarme  with (nolock)  where Alarme.IdSuperEntidade = Atendimento.id and Alarme.Status = 'IN' order by Alarme.Data asc) as idAlarmeProximoAtivo,
	--			-- deve ser considerado a data a qual o alarme será executado, para que possa ser considerado a ultima data que o atendimento possuia um próximo passo
	--			(Select top 1 Alarme.Id from Alarme  with (nolock)  where Alarme.IdSuperEntidade = Atendimento.id and Alarme.Status = 'IN' order by Alarme.Data desc) as IdAlarmeUltimoAtivo,
	--			(Select top 1 Interacao.Id from Interacao with (nolock)   where IdSuperEntidade = Atendimento.id and Interacao.InteracaoAtorPartida = 'USUARIO' order by Interacao.DtInclusao desc) as idInteracaoUsuarioUltima,
	--			(Select top 1 Interacao.Id from Interacao  with (nolock)  where IdSuperEntidade = Atendimento.id and Interacao.InteracaoAtorPartida = 'PROSPECT' order by Interacao.DtInclusao desc) as idInteracaoProspectUltima,
	--			(Select top 1 Interacao.Id from Interacao with (nolock)   where IdSuperEntidade = Atendimento.id and Interacao.InteracaoAtorPartida = 'AUTO' order by Interacao.DtInclusao desc) as idInteracaoAutoUltima
	--			--(Select top 1 Interacao.Id from Interacao with (nolock)  inner join InteracaoTipo with (nolock) on Interacao.IdInteracaoTipo = InteracaoTipo.Id  where IdSuperEntidade = Atendimento.id and InteracaoTipo.Tipo = 'NEGOCIACAOVENDA' order by Interacao.DtInteracao desc) as idInteracaoNegociacaoVendaUltima

	--			into #TempInteracao
	--		from
	--			Atendimento 
	--		where
	--			StatusAtendimento = 'atendido'
	--				and
	--			(
	--				-- deve ser considerado a data do ultimo status já que é a mesma que deverá ser utilizada nos casos de comparação do último alarme ativo
	--				Atendimento.idAlarmeUltimo <>		(Select top 1 Alarme.Id from Alarme with (nolock)   where Alarme.IdSuperEntidade = Atendimento.id order by Alarme.DataUltimoStatus desc) or
	--				-- deve ser considerado a data a qual o alarme será executado, para que possa ser considerado a ultima data que o atendimento possuia um próximo passo
	--				Atendimento.idAlarmeProximoAtivo <>	(Select top 1 Alarme.Id from Alarme with (nolock)   where Alarme.IdSuperEntidade = Atendimento.id and Alarme.Status = 'IN' order by Alarme.Data asc) or
	--				-- deve ser considerado a data a qual o alarme será executado, para que possa ser considerado a ultima data que o atendimento possuia um próximo passo
	--				Atendimento.IdAlarmeUltimoAtivo <>	(Select top 1 Alarme.Id from Alarme with (nolock)   where Alarme.IdSuperEntidade = Atendimento.id and Alarme.Status = 'IN' order by Alarme.Data desc) or
	--				Atendimento.idInteracaoUsuarioUltima <>	(Select top 1 Interacao.Id from Interacao with (nolock)   where IdSuperEntidade = Atendimento.id and Interacao.InteracaoAtorPartida = 'USUARIO' order by Interacao.DtInclusao desc) or
	--				Atendimento.idInteracaoProspectUltima <>	(Select top 1 Interacao.Id from Interacao with (nolock)   where IdSuperEntidade = Atendimento.id and Interacao.InteracaoAtorPartida = 'PROSPECT' order by Interacao.DtInclusao desc) or
	--				Atendimento.idInteracaoAutoUltima <>		(Select top 1 Interacao.Id from Interacao with (nolock)   where IdSuperEntidade = Atendimento.id and Interacao.InteracaoAtorPartida = 'AUTO' order by Interacao.DtInclusao desc) 
	--				--or Atendimento.idInteracaoNegociacaoVendaUltima <>	(Select top 1 Interacao.Id from Interacao with (nolock)  inner join InteracaoTipo with (nolock)  on Interacao.IdInteracaoTipo = InteracaoTipo.Id  where IdSuperEntidade = Atendimento.id and InteracaoTipo.Tipo = 'NEGOCIACAOVENDA' order by Interacao.DtInteracao desc)
	--			)


	--		-- Ajusta as referências do atendimento caso alguma esteja diferente da real
	--		update 
	--			Atendimento
	--			SET
	--				-- deve ser considerado a data do ultimo status já que é a mesma que deverá ser utilizada nos casos de comparação do último alarme ativo
	--					Atendimento.idAlarmeUltimo = TableTemp.idAlarmeUltimo,
	--					-- deve ser considerado a data a qual o alarme será executado, para que possa ser considerado a ultima data que o atendimento possuia um próximo passo
	--					Atendimento.idAlarmeProximoAtivo =	TableTemp.idAlarmeProximoAtivo,
	--					-- deve ser considerado a data a qual o alarme será executado, para que possa ser considerado a ultima data que o atendimento possuia um próximo passo
	--					Atendimento.IdAlarmeUltimoAtivo =	TableTemp.IdAlarmeUltimoAtivo,
	--					Atendimento.idInteracaoUsuarioUltima =	TableTemp.idInteracaoUsuarioUltima,
	--					Atendimento.idInteracaoProspectUltima =	TableTemp.idInteracaoProspectUltima,
	--					Atendimento.idInteracaoAutoUltima =	TableTemp.idInteracaoAutoUltima

	--		from
	--			Atendimento 
	--				inner join
	--			#TempInteracao as TableTemp on Atendimento.Id = TableTemp.AtendimentoId

	--		
	--	end

	-- desativado em 14/01/2021 - timeout
	--
	--	begin
	--		-- SE FAZ necessário antes de excluir as interações
	--		update TOP (100000) Atendimento
	--				set 
	--					Atendimento.IdInteracaoAutoUltima = null,
	--					Atendimento.IdInteracaoProspectUltima = null,
	--					Atendimento.IdInteracaoUsuarioUltima = null,

	--					Atendimento.IdAlarmeProximoAtivo = null,
	--					Atendimento.IdAlarmeUltimo = null,
	--					Atendimento.IdAlarmeUltimoAtivo = null,

	--					Atendimento.idInteracaoNegociacaoVendaUltima = null,
	--					StatusAtendimento = 'ENCERRADO', 
	--					DtConclusaoAtendimento = @dtnow
	--			from 
	--				Atendimento with (nolock)
	--					inner join
	--				ContaSistema   with (nolock) on ContaSistema.id = Atendimento.idContaSistema

	--			where
	--				ContaSistema.Status = 'DE'
	--					and
	--				(
	--					Atendimento.IdAlarmeProximoAtivo is not null or
	--					Atendimento.IdAlarmeUltimo is not null or
	--					Atendimento.IdAlarmeUltimoAtivo is not null or
	--					Atendimento.IdInteracaoAutoUltima is not null or
	--					Atendimento.IdInteracaoProspectUltima is not null or
	--					Atendimento.IdInteracaoUsuarioUltima is not null or
	--					Atendimento.idInteracaoNegociacaoVendaUltima is not null 
	--				)
	--					and
	--				-- Se faz necessário para atualizar apenas as que possuem interação
	--				exists (select Interacao.Id from Interacao with(nolock) where Interacao.IdSuperEntidade = Atendimento.Id)
									


	--		-- DELETA AS interações de contasistema desativados
	--		-- desativado em 25/10/2020 por constantemente levar a timeout
	--		--delete top (100000) from Interacao
	--		--	from
	--		--		Interacao with(nolock)
	--		--			inner join
	--		--		ContaSistema with(nolock) on ContaSistema.Id = Interacao.idContaSistema
	--		--			inner join
	--		--		Atendimento with(nolock) on Atendimento.id = Interacao.idSuperEntidade

	--		--	where 
	--		--		ContaSistema.Status = 'DE'
	--		--			and
	--		--		(
	--		--			Atendimento.IdAlarmeProximoAtivo is not null or
	--		--			Atendimento.IdAlarmeUltimo is not null or
	--		--			Atendimento.IdAlarmeUltimoAtivo is not null or
	--		--			Atendimento.IdInteracaoAutoUltima is not null or
	--		--			Atendimento.IdInteracaoProspectUltima is not null or
	--		--			Atendimento.IdInteracaoUsuarioUltima is not null or
	--		--			Atendimento.idInteracaoNegociacaoVendaUltima is not null 
	--		--		)

	--	
	--	end


	-- DELETA os telefones considerados inválidos caso IGNORAR_TELEFONE_INVALIDO esteja ligado
	
		--begin
		--	delete 
		--		PessoaProspectTelefone
		--	Where
		--		exists 
		--		(
		--			Select 
		--				ContaSistemaConfiguracao.Id
		--			From
		--				SuperEntidade with (nolock)
		--					inner join
		--				ContaSistemaConfiguracao  with (nolock) on ContaSistemaConfiguracao.IdContaSistema = SuperEntidade.idContaSistema
		--			where
		--				ContaSistemaConfiguracao.Tipo = 'IGNORAR_TELEFONE_INVALIDO' and 
		--				ContaSistemaConfiguracao.ValorInt = 1 and
		--				SuperEntidade.Id = PessoaProspectTelefone.IdPessoaProspect
		--		)
		--			and
		--		(
		--			PessoaProspectTelefone.Telefone like '%00000000%' or
		--			PessoaProspectTelefone.Telefone like '%11111111%' or
		--			PessoaProspectTelefone.Telefone like '%22222222%' or
		--			PessoaProspectTelefone.Telefone like '%33333333%' or
		--			PessoaProspectTelefone.Telefone like '%44444444%' or
		--			PessoaProspectTelefone.Telefone like '%55555555%' or
		--			PessoaProspectTelefone.Telefone like '%66666666%' or
		--			PessoaProspectTelefone.Telefone like '%77777777%' or
		--			PessoaProspectTelefone.Telefone like '%88888888%' or 
		--			PessoaProspectTelefone.Telefone like '%99999999%' 
		--		)
			
		--end




	
		begin

			-- desativado em 14/01/2021 timeout
			-- DELETA as oportunidades de negócio ATENDIMENTOS QUE PROVAVELMENTE SÃO TESTES
			--delete from SuperEntidade 
			--	from
			--		SuperEntidade with(nolock)
			--			inner join
			--		OportunidadeNegocio with(nolock) on SuperEntidade.id = OportunidadeNegocio.IdSuperEntidade
			--			inner join
			--		Atendimento with(nolock) on OportunidadeNegocio.idAtendimento = Atendimento.id
			--			inner join 
			--		pessoaprospect with(nolock) on Atendimento.idPessoaProspect = PessoaProspect.Id
			--			inner join
			--		PessoaProspectEmail with(nolock) on PessoaProspectEmail.IdPessoaProspect = PessoaProspect.Id
			--where 
			--	(PessoaProspect.Nome like '%anapro%' or PessoaProspectEmail.Email like '%anapro%')
			--		and
			--	SuperEntidade.idContaSistema not in (151, 3, 7, 15, 23, 5, 222)


			-- DELETA OS ATENDIMENTOS QUE PROVAVELMENTE SÃO TESTES
			UPDATE Atendimento SET RegistroStatus = 'DEL'
				from
					Atendimento with(nolock)
						inner join 
					pessoaprospect with(nolock) on Atendimento.idPessoaProspect = PessoaProspect.Id
						inner join
					PessoaProspectEmail with(nolock) on PessoaProspectEmail.IdPessoaProspect = PessoaProspect.Id
					
			where 
				(PessoaProspect.Nome like '%anapro%' or PessoaProspectEmail.Email like '%anapro%')
					and
				Atendimento.idContaSistema not in (151, 3, 7, 15, 23, 5, 222, 436)


			-- Deleta e-mails duplicados de um mesmo prospect
			--Delete PessoaProspectEmail
			--From 
			--	PessoaProspectEmail with(nolock)
			--		inner join
			--	(
			--		Select 
			--			PessoaProspectEmail.IdPessoaProspect,
			--			PessoaProspectEmail.Email,
			--			min(PessoaProspectEmail.Id) as MinIdEmailPessoaProspect
			--		From 
			--			PessoaProspectEmail with(nolock)
			--				inner join
			--			(
			--				Select 
			--					PessoaProspectEmail.IdPessoaProspect,
			--					PessoaProspectEmail.Email,
			--					count(PessoaProspectEmail.Id) as CountTotal
			--				From
			--					PessoaProspectEmail with(nolock)
			--				group by
			--					PessoaProspectEmail.IdPessoaProspect,
			--					PessoaProspectEmail.Email
			--				Having 
			--					count(PessoaProspectEmail.Id) > 1
			--			) TabAux on 
			--					TabAux.IdPessoaProspect = PessoaProspectEmail.IdPessoaProspect and 
			--					TabAux.Email = PessoaProspectEmail.Email

			--		Group by
			--			PessoaProspectEmail.IdPessoaProspect,
			--			PessoaProspectEmail.Email
			--	) Tab2 on
			--		Tab2.IdPessoaProspect = PessoaProspectEmail.IdPessoaProspect and
			--		Tab2.Email = PessoaProspectEmail.Email
			--where
			--	PessoaProspectEmail.id > Tab2.MinIdEmailPessoaProspect


			-- -- Deleta os emails que não são emails válidos
			--delete from PessoaProspectEmail 
			--where 
			--	(
			--		(email like '%.co' or email like '%.b' or email not like '%.%' or email not like '%@%')
			--			or
			--		(email like '%.com%' and (email not like '%.com.%' and email not like '%.com'))
			--	)



			---- Deleta telefones duplicados de um mesmo prospect
			--Delete PessoaProspectTelefone
			--From
			--	PessoaProspectTelefone with(nolock)
			--		inner join
			--	(
			--		Select 
			--			PessoaProspectTelefone.IdPessoaProspect,
			--			PessoaProspectTelefone.DDD,
			--			PessoaProspectTelefone.Telefone,
			--			min(PessoaProspectTelefone.Id) as MinIdTelefonePessoaProspect
			--		From 
			--			PessoaProspectTelefone with(nolock)
			--				inner join
			--			(
			--				Select 
			--					PessoaProspectTelefone.IdPessoaProspect,
			--					PessoaProspectTelefone.DDD,
			--					PessoaProspectTelefone.Telefone,
			--					count(PessoaProspectTelefone.Id) as CountTotal
			--				From
			--					PessoaProspectTelefone with(nolock)
			--				group by
			--					PessoaProspectTelefone.IdPessoaProspect,
			--					PessoaProspectTelefone.DDD,
			--					PessoaProspectTelefone.Telefone
			--				Having 
			--					count(PessoaProspectTelefone.Id) > 1
			--			) TabAux on 
			--					TabAux.IdPessoaProspect = PessoaProspectTelefone.IdPessoaProspect and 
			--					TabAux.DDD = PessoaProspectTelefone.DDD and 
			--					TabAux.Telefone = PessoaProspectTelefone.Telefone

			--		Group by
			--			PessoaProspectTelefone.IdPessoaProspect,
			--			PessoaProspectTelefone.DDD,
			--			PessoaProspectTelefone.Telefone
			--	) Tab2 on
			--		Tab2.IdPessoaProspect = PessoaProspectTelefone.IdPessoaProspect and
			--		Tab2.DDD = PessoaProspectTelefone.DDD and 
			--		Tab2.Telefone = PessoaProspectTelefone.Telefone
			--where
			--	PessoaProspectTelefone.id > Tab2.MinIdTelefonePessoaProspect


			-- http://portal.embratel.com.br/embratel/9-digito/
			-- Ajusta os telefones com 9 dígito que estão errados na base
			-- Em 29 de Julho de 2012 alterados os números móveis do DDD 11
			-- Em 25 de Agosto de 2013 alterados os números móveis dos DDDs 12, 13, 14, 15, 16, 17, 18 e 19;
			-- Em 27 de Outubro de 2013 alterados os números dos DDDs 21, 22, 24, 27 e 28;
			-- Em 02 de Novembro de 2014 alterados os números dos DDDs 91, 92, 93, 94, 95, 96, 97, 98 e 99;
			-- Em 31 de Maio de 2015 alterados os números dos DDDs 81, 82, 83, 84, 85, 86,87, 88 e 89;
			-- Em 11 de Outubro de 2015 alterados os DDDs 31, 32, 33, 34, 35, 37, 38, 71, 73, 74, 75, 77 e 79;
			-- Em 29 de maio de 2016 serão alterados os DDDs 61,62, 63, 64, 65, 66, 67, 68, 69;
			-- Em 06 de Novembro de 2016 serão alterados os DDDs 41, 42, 43, 44, 45, 46, 47, 48, 49, 51, 53, 54 e 55.
			--update PessoaProspectTelefone set  PessoaProspectTelefone.Telefone = '9'+ PessoaProspectTelefone.Telefone
			--from PessoaProspectTelefone 
			--where
			--	PessoaProspectTelefone.DDD in (61,62, 63, 64, 65, 66, 67, 68, 69, 11, 12, 13, 14, 15, 16, 17, 18, 19, 21, 22, 24, 27, 28, 91, 92, 93, 94, 95, 96, 97, 98,  99, 81, 82, 83, 84, 85, 86,87, 88, 89, 31, 32, 33, 34, 35, 37, 38, 71, 73, 74, 75, 77, 79,  41, 42, 43, 44, 45, 46, 47, 48, 49, 51, 53, 54, 55) and
			--	LEN(PessoaProspectTelefone.Telefone) <= 8 and
			--	SUBSTRING(PessoaProspectTelefone.Telefone, 1, 1) in ('8', '9')



			---- Ajusta os telefones
			--update PessoaProspectTelefone set DDD = replace(replace(replace(DDD, ' ', ''),'_',''),'-',''), Telefone = replace(replace(replace(replace(replace(Telefone, ' ', ''),'_',''),'-',''),')',''),'(','')
			-- where ISNUMERIC (DDD) = 0 or ISNUMERIC (Telefone) = 0

			---- delete os telefones que não são numéricos
			--delete from PessoaProspectTelefone where ISNUMERIC (DDD) = 0 or ISNUMERIC (Telefone) = 0

			---- deleta os telefones inválidos com ddd < 11
			--delete from PessoaProspectTelefone where cast(telefone as float) < 20000000

			-- deleta os endereços duplicados dos prospects
			--Delete PessoaProspectEndereco
			--From
			--	PessoaProspectEndereco with(nolock)
			--		inner join
			--	(
			--		Select 
			--			PessoaProspectEndereco.IdPessoaProspect,
			--			PessoaProspectEndereco.UF,
			--			PessoaProspectEndereco.IdCidade,
			--			PessoaProspectEndereco.IdBairro,
			--			PessoaProspectEndereco.Tipo,
			--			PessoaProspectEndereco.Logradouro,
			--			PessoaProspectEndereco.Complemento,
			--			PessoaProspectEndereco.Numero,
			--			PessoaProspectEndereco.CEP,
			--			min(PessoaProspectEndereco.Id) as MinIdEnderecoPessoaProspect
			--		From 
			--			PessoaProspectEndereco with(nolock) 
			--				inner join
			--			(
			--				Select 
			--					PessoaProspectEndereco.IdPessoaProspect,
			--					PessoaProspectEndereco.UF,
			--					PessoaProspectEndereco.IdCidade,
			--					PessoaProspectEndereco.IdBairro,
			--					PessoaProspectEndereco.Tipo,
			--					PessoaProspectEndereco.Logradouro,
			--					PessoaProspectEndereco.Complemento,
			--					PessoaProspectEndereco.Numero,
			--					PessoaProspectEndereco.CEP,
			--					count(PessoaProspectEndereco.Id) as CountTotal
			--				From
			--					PessoaProspectEndereco with(nolock) 
			--				group by
			--					PessoaProspectEndereco.IdPessoaProspect,
			--					PessoaProspectEndereco.UF,
			--					PessoaProspectEndereco.IdCidade,
			--					PessoaProspectEndereco.IdBairro,
			--					PessoaProspectEndereco.Tipo,
			--					PessoaProspectEndereco.Logradouro,
			--					PessoaProspectEndereco.Complemento,
			--					PessoaProspectEndereco.Numero,
			--					PessoaProspectEndereco.CEP
			--				Having 
			--					count(PessoaProspectEndereco.Id) > 1
			--			) TabAux on 
			--					TabAux.IdPessoaProspect = PessoaProspectEndereco.IdPessoaProspect and 
			--					TabAux.UF = PessoaProspectEndereco.UF and 
			--					TabAux.IdCidade = PessoaProspectEndereco.IdCidade and 
			--					TabAux.IdBairro = PessoaProspectEndereco.IdBairro and 
			--					TabAux.Tipo = PessoaProspectEndereco.Tipo and 
			--					TabAux.Logradouro = PessoaProspectEndereco.Logradouro and 
			--					TabAux.Complemento = PessoaProspectEndereco.Complemento and 
			--					TabAux.Numero = PessoaProspectEndereco.Numero and 
			--					TabAux.CEP = PessoaProspectEndereco.CEP

			--		Group by
			--			PessoaProspectEndereco.IdPessoaProspect,
			--			PessoaProspectEndereco.UF,
			--			PessoaProspectEndereco.IdCidade,
			--			PessoaProspectEndereco.IdBairro,
			--			PessoaProspectEndereco.Tipo,
			--			PessoaProspectEndereco.Logradouro,
			--			PessoaProspectEndereco.Complemento,
			--			PessoaProspectEndereco.Numero,
			--			PessoaProspectEndereco.CEP
			--	) Tab2 on
			--		Tab2.IdPessoaProspect = PessoaProspectEndereco.IdPessoaProspect and 
			--		Tab2.UF = PessoaProspectEndereco.UF and 
			--		Tab2.IdCidade = PessoaProspectEndereco.IdCidade and 
			--		Tab2.IdBairro = PessoaProspectEndereco.IdBairro and 
			--		Tab2.Tipo = PessoaProspectEndereco.Tipo and 
			--		Tab2.Logradouro = PessoaProspectEndereco.Logradouro and 
			--		Tab2.Complemento = PessoaProspectEndereco.Complemento and 
			--		Tab2.Numero = PessoaProspectEndereco.Numero and 
			--		Tab2.CEP = PessoaProspectEndereco.CEP
			--where
			--	PessoaProspectEndereco.id > Tab2.MinIdEnderecoPessoaProspect

			--DELETE FROM PessoaProspectEndereco 
			--WHERE ID IN (
			--SELECT A.Id FROM PessoaProspectEndereco A
			--JOIN (SELECT max(ID) AS id, IdPessoaProspect
			--FROM PessoaProspectEndereco PD1 WITH(NOLOCK)
			-- WHERE IdPessoaProspect IN (Select 
			--					PessoaProspectEndereco.IdPessoaProspect
			--				From
			--					PessoaProspectEndereco with(nolock) 
			--				group by
			--					PessoaProspectEndereco.IdPessoaProspect,
			--					PessoaProspectEndereco.UF,
			--					PessoaProspectEndereco.IdCidade,
			--					PessoaProspectEndereco.IdBairro,
			--					PessoaProspectEndereco.Tipo,
			--					PessoaProspectEndereco.Logradouro,
			--					PessoaProspectEndereco.Complemento,
			--					PessoaProspectEndereco.Numero,
			--					PessoaProspectEndereco.CEP
			--				Having 
			--					count(PessoaProspectEndereco.Id) > 1)
			--GROUP BY IdPessoaProspect) AS B
			--ON A.id != B.ID AND A.IdPessoaProspect = B.IdPessoaProspect
			--)
		end


		
	
		begin
			-- Desabilita todos os usuários de todas as contas inativas
			update UsuarioContaSistema set Status = 'DE', DtAtualizacao = @dtnow
			FROM
				UsuarioContaSistema with(nolock)
					INNER JOIN
				ContaSistema with(nolock) ON ContaSistema.Id = UsuarioContaSistema.IdContaSistema
			WHERE
				ContaSistema.Status = 'DE' AND UsuarioContaSistema.Status = 'AT'

			-- ENCERRA TODOS ATENDIMENTOS DE CONTA SISTEMAS NÃO ATIVAS
			-- OU DE USUÁRIOS DESAIVADOS DO SISTEMA
			update Atendimento set StatusAtendimento = 'ENCERRADO', DtConclusaoAtendimento = @dtnow
			FROM
				Atendimento with(nolock) 
					inner join
				ContaSistema with(nolock) on Atendimento.idContaSistema = ContaSistema.Id
					left outer join
				UsuarioContaSistema with(nolock) on UsuarioContaSistema.Id = Atendimento.IdUsuarioContaSistemaAtendimento

			where 
				StatusAtendimento <> 'ENCERRADO'
					AND
				(
					(
						UsuarioContaSistema.Id is not null
							and
						UsuarioContaSistema.Status = 'DE'
					)
				)
		
	end



	
	--	begin
	--		update PessoaProspectImportacao set PessoaProspectImportacao.Status = 'CANCELADO'
	--		from
	--			PessoaProspectImportacao with (nolock)
	--				inner join
	--			ContaSistema  with (nolock) on PessoaProspectImportacao.idContaSistema = ContaSistema.Id
	--		where
	--			ContaSistema.Status = 'DE'
	--				and
	--			PessoaProspectImportacao.Status not in ('PROCESSADO', 'CANCELADO')
	
	--		-- Deleta todas as Importações que não possui leads
	--		delete from PessoaProspectImportacao
	--		from 
	--			PessoaProspectImportacao with(nolock)
	--				inner join
	--			ContaSistema  with (nolock) on PessoaProspectImportacao.idContaSistema = ContaSistema.Id
	--		where
	--			not exists (
	--							Select 
	--								PessoaProspect.id 
	--							from 
	--								PessoaProspect with(nolock) 
	--									inner join
	--								PessoaProspectOrigemPessoaProspect with(nolock) on PessoaProspectOrigemPessoaProspect.idPessoaProspect = PessoaProspect.id
	--									inner join
	--								PessoaProspectOrigem with(nolock) on PessoaProspectOrigem.Id = PessoaProspectOrigemPessoaProspect.IdPessoaProspectOrigem
	--							where 
	--								PessoaProspectImportacao.Id = PessoaProspectOrigem.IdPessoaProspectImportacao
	--						)
	--				or
	--			ContaSistema.Status = 'DE'
					
		
	--end


	
	--	begin
	--		-- deleta antes de deletar os prospects abaixo
	--		delete from dbo.PessoaProspectOrigemPessoaProspect
	--		from
	--			dbo.PessoaProspectOrigemPessoaProspect with(nolock)
	--				inner join
	--			pessoaprospect with(nolock)  on PessoaProspectOrigemPessoaProspect.idpessoaprospect = pessoaprospect.id
	--				left outer  join
	--			superentidade with(nolock) on superentidade.id = pessoaprospect.id and superentidade.SuperEntidadeTipo = 'PESSOAPROSPECT'
	--		where superentidade.id is null

			
	--	end

	
		begin
			-- Deleta todas as superentidades do tipo pessoaprospect que não exista pessoaprospect
			-- provavelmente foram deletados
			-- se faz necessário deletar a composição antes para não ocorrer erro
			delete from SuperEntidade 
			where 
				SuperEntidadeTipo = 'PESSOAPROSPECT' 
					and
				Not exists (Select id from PessoaProspect with(nolock) where PessoaProspect.Id = SuperEntidade.Id)

			-- deleta os prospect que não estão inseridos na super entidade
			--delete from  pessoaprospect
			--	from 
			--	pessoaprospect with(nolock)
			--		left outer  join
			--	superentidade with(nolock) on superentidade.id = pessoaprospect.id and superentidade.SuperEntidadeTipo = 'PESSOAPROSPECT'

			--	where superentidade.id is null

			

		end

	
		begin
			-- deleta as oportunidades em superentidade que não existem em oportunidadenegocio
			delete from SuperEntidade 
			where 
				SuperEntidadeTipo = 'OPORTUNIDADENEGOCIO' 
					and
				Not exists (Select OportunidadeNegocio.IdSuperEntidade from OportunidadeNegocio with(nolock) where OportunidadeNegocio.IdSuperEntidade = SuperEntidade.Id)


	
				-- SETA A DATA DE CONCLUSAO DO ATENDIMENTO PARA A DATA ATUAL PARA TODOS ATENDIMENTOS CONCLUÍDOS 
			-- MAS QUE POR VENTURA A DATA DE CONCLUSÃO ESTEJA NULA
			update Atendimento set DtConclusaoAtendimento = @dtnow
			where Atendimento.StatusAtendimento = 'ENCERRADO' AND DtConclusaoAtendimento IS NULL

		
	end


		begin

			-- deleta todos os plantões que não estão mais ativos a pelo menos 10 dias
			delete Plantao
				from 
					Plantao with(nolock)
						inner join
					Campanha  with(nolock) on Campanha.Id = Plantao.IdCampanha
						inner join
					ContaSistema with(nolock) on ContaSistema.Id = Campanha.IdContaSistema
			where
				ContaSistema.Status = 'DE'
					OR
				(	
					Plantao.DtInicioValidade <= @dtnow
						and
					Plantao.DtFimValidade is not null
						and
					Plantao.DtFimValidade <= DATEADD(DAY, -10, @dtnow)
						AND
					NOT EXISTS (Select * from PlantaoHorario with(nolock) where PlantaoHorario.IdPlantao = Plantao.Id and PlantaoHorario.DtFim >= @dtnow)
				)
					or
				Plantao.Status <> 'AT'
					or
				Campanha.Status <> 'AT'



			-- deleta os plantões horários que não estão mais validos a pelo menos 10 dias
			-- OU que não esteja mais ativo
			-- OU campanha não ativa
			delete PlantaoHorario
				from 
					PlantaoHorario with(nolock)
						inner join 
					Plantao with(nolock) on PlantaoHorario.IdPlantao = Plantao.Id
						inner join
					Campanha with(nolock) on Campanha.Id = Plantao.IdCampanha
						inner join
					ContaSistema with(nolock) on ContaSistema.Id = Campanha.IdContaSistema
			where
				ContaSistema.Status = 'DE'
					OR
				(	
					PlantaoHorario.DtFim is not null
						and
					PlantaoHorario.DtFim <= DATEADD(DAY, -10, @dtnow)
				)
					or
				PlantaoHorario.Status <> 'AT'
					or
				Campanha.Status <> 'AT'

		
	end


	




	-- Não pode deletar pois relatorios q não tem conta sistema vinculado, principalmente do BI é mostrado para todos
	--
	--	begin

	--		delete RelatorioContaSistema
	--		from
	--			RelatorioContaSistema with (nolock)
	--				inner join
	--			ContaSistema  with (nolock) on ContaSistema.Id = RelatorioContaSistema.IdContaSistema
	--		where
	--			ContaSistema.Status = 'DE'

	--		
	--	end



-- Desativa todos os gatilhos de conta sistema desativado
update gatilho set Status = 'DE'
FROM Gatilho inner join ContaSistema on ContaSistema.id = Gatilho.IdContaSistema
where ContaSistema.Status = 'DE' and gatilho.Status <> 'DE'


-- Atualiza todos os gatilhos de execução como desativado
-- para as notificações que foram canceladas
Update GatilhoExecucao
	Set
		GatilhoExecucao.Status = 'DE',
		GatilhoExecucao.DtValidade = @dtnow,
		GatilhoExecucao.DtAlteracao = @dtnow
			
	from
		GatilhoExecucao with (nolock)
			inner join
		NotificacaoGlobal with (nolock) on GatilhoExecucao.StrGuid = NotificacaoGlobal.ReferenciaEntidadeCodigoStr and NotificacaoGlobal.ReferenciaEntidade = 'Gatilho'
	where
		NotificacaoGlobal.Status = 'CAN'


-- Deleta as pendencias de processamento
--truncate table PendenciaProcessamento 

-- Deleta todas as notificações com status cancelado
Delete 
		NotificacaoGlobal
	Where 
		NotificacaoGlobal.Status = 'CAN'


-- Deleta todos os gatilhos de execução desativados
Delete 
	from
		GatilhoExecucao
	where
		status = 'DE'


-- Deleta todos os gatilhos de execução que não existe notificação
Delete 
	from
		GatilhoExecucao
	where
		not exists (Select id from NotificacaoGlobal with(nolock) where GatilhoExecucao.StrGuid = NotificacaoGlobal.ReferenciaEntidadeCodigoStr)

---- Exclui todos os eventos processados
--truncate table evento

---- Exclui todos os eventos processados
--truncate table EventoPre


-- deleta as hashtags que por ventura sejam nulas ou vazias
delete from tag where valor is null or valor = '' or valor = ' ' or valor = '  ' or valor = '   '

-- ajusta retirando # de todas as tags que contem #
update 
	Tag 
		set Tag.Valor = REPLACE(Tag.valor,'#','')
	where 
		Tag.valor like '%#%' and 
		not exists (select TagAux.id from tag TagAux with (nolock) where TagAux.IdContaSistema = Tag.IdContaSistema and  TagAux.Tipo = Tag.Tipo and TagAux.Valor = REPLACE(Tag.valor,'#',''))

-- após ajuste exclui todas as tags que não foram ajustadas que contem #
delete from tag where Tag.valor like '%#%'


-- desativado em 14/01/2021 timeout
-- 18/05/2019
-- Achei alguns casos que por algo ainda desconhecido o atendimento fica com apontamentos para interaçoes a qual a interação nao pertence
-- ao atendimento.
-- Detectei em raros casos, isso pode gerar problema pois ao tentar excluir atendimentos que contem esse problema acaba que nao seja possível 
-- excluir já que as referencias dao problema
--
--	Update
--		Atendimento
--	Set 
--		Atendimento.idInteracaoAutoUltima = null,
--		Atendimento.IdInteracaoProspectUltima = null,
--		Atendimento.IdInteracaoUsuarioUltima = null,
--		Atendimento.idInteracaoNegociacaoVendaUltima = null
--	where 
--		exists
--			(
--				select 
--					AtendimentoAux.Id
--					--InteracaoAutoUltima.Id as idInteracaoAutoUltima, 
--					--InteracaoProspectUltima.Id as idInteracaoProspectUltima,  
--					--InteracaoUsuarioUltima.Id as idInteracaoUsuarioUltima
--				from 
--					Atendimento AtendimentoAux with (nolock)
--						left outer join
--					Interacao InteracaoAutoUltima  with (nolock) on InteracaoAutoUltima.Id = AtendimentoAux.idInteracaoAutoUltima and AtendimentoAux.id <> InteracaoAutoUltima.IdSuperEntidade
--						left outer join
--					Interacao InteracaoProspectUltima  with (nolock) on InteracaoProspectUltima.Id = AtendimentoAux.IdInteracaoProspectUltima and AtendimentoAux.id <> InteracaoProspectUltima.IdSuperEntidade
--						left outer join
--					Interacao InteracaoUsuarioUltima  with (nolock) on InteracaoUsuarioUltima.Id = AtendimentoAux.IdInteracaoUsuarioUltima and AtendimentoAux.id <> InteracaoUsuarioUltima.IdSuperEntidade
--						left outer join
--					Interacao InteracaoNegociacaoVendaUltima  with (nolock) on InteracaoNegociacaoVendaUltima.Id = AtendimentoAux.idInteracaoNegociacaoVendaUltima and AtendimentoAux.id <> InteracaoNegociacaoVendaUltima.IdSuperEntidade

--				where
--					AtendimentoAux.Id = Atendimento.Id
--						and
--					(
--						InteracaoAutoUltima.Id is not null
--							or
--						InteracaoProspectUltima.Id is not null
--							or
--						InteracaoUsuarioUltima.Id is not null
--							or
--						InteracaoNegociacaoVendaUltima.Id is not null
--					)
--			)
--

-- deleta os bookmarks de usuários desativados

	delete Bookmark
	from
		Bookmark with (nolock)
			inner join
		UsuarioContaSistema with (nolock) on UsuarioContaSistema.Id = Bookmark.IdUsuarioContaSistema
			inner join
		ContaSistema with (nolock) on ContaSistema.Id = Bookmark.IdContaSistema
	where
		UsuarioContaSistema.Status = 'DE'
			or
		ContaSistema.Status = 'DE'



	-- Deleta todos os usuários que estão como seguidor mas foram desativados do sistema
	delete from AtendimentoSeguidor
	where
		not exists (Select UsuarioContaSistema.Id from UsuarioContaSistema where Status = 'AT' and UsuarioContaSistema.Id = AtendimentoSeguidor.IdUsuarioContaSistema)


	---- Ajusta as mídias que estão sem integradora externa setado
	--exec [dbo].[ProcAjustarIntegradoraExternaMidia]


	---- Ajusta os canais de carteira corretor automaticamente nas campanhas que não existe tal canal setado
	--exec [ProcAjustarCanalCarteiraCorretorCampanha]


	---- Ajusta possíveis falhas de atualização do InteracaoUsuarioUltimaDt em atendimento
	--EXEC [dbo].[ProcAjustarInteracaoUsuarioUltimaDt]


	---- Exclui possíveis interações que não existe em interacaoObj mas existe em interacao
	--EXEC [dbo].[ProcExcluirInteracaoError]


Update 
	TabelaoLog 
Set
	-- Adiciona 2 milesegundo desde a última execução para considerar todos atualizados desde a última atualização
	-- 2 pq é o mínimo que pode adicionar
	TabelaoLog.Data1 = dbo.GetDateCustom(),
	TabelaoLog.Data2 = null,
	TabelaoLog.bit1 = 0,
	TabelaoLog.DtUltimaParcial = case when @GerarTudo = 0 then dbo.GetDateCustom() else TabelaoLog.DtUltimaParcial end,
	TabelaoLog.DtUltimaCompleta = case when @GerarTudo = 1 then dbo.GetDateCustom() else TabelaoLog.DtUltimaCompleta end
where
	TabelaoLog.Nome = @BatchNome;

CREATE procedure [dbo].[ProcLimpezaDeBaseContaDesativada] 
as
	-- comentar
	-- return	

	declare @dtnow datetime = dbo.getDateCustom()
	declare @dtReferenciaUtilizarMaximo datetime = @dtnow
	declare @BatchNome varchar(1000) = 'Batch_LimpezaDeBaseContaDesativada'
	declare @dtUltimaAtualizacao datetime
	declare @GerarTudo bit = 1
	declare @errorSys bit = 0
	declare @erroMsg varchar(max) = ''

	-- Retorna a data que começou a última atualização
	select @dtUltimaAtualizacao = Max(TabelaoLog.Data2) from TabelaoLog with (nolock) where TabelaoLog.Nome = @BatchNome group by TabelaoLog.Nome

	-- Se o processamento atual não for de gerar tudo e a data não for nula
	-- Subentende-se que no momento está sendo atualizado e não deve rodar 2 atualizações ao mesmo tempo
	-- testará tb se faz mais de 120 minutos que a ultima query executou nesse caso irá considerar que hove erro e executará 
	-- zerando a hora para não ter problemas
	if (@dtUltimaAtualizacao is not null and DATEDIFF(MI, @dtUltimaAtualizacao, dbo.GetDateCustom()) < 180)
		begin
			return
		end
	--else
	--	begin
	--		update TabelaoLog set TabelaoLog.Data2 = dbo.GetDateCustom() where TabelaoLog.Nome = @BatchNome
	--	end

			-- deleta todos os alarmes de contasistema desativado
			delete top (100000) alarme
			from 
				Alarme with (nolock)
					inner join
				SuperEntidade  with (nolock) on Alarme.idSuperEntidade = SuperEntidade.Id
					inner join
				ContaSistema   with (nolock) on SuperEntidade.idContaSistema = ContaSistema.Id
			where
				ContaSistema.Status = 'DE'



			-- seta null para que seja possível deletar o registro de PessoaProspectImportacaoTemp abaixo
			update PessoaProspectOrigemPessoaProspect set IdPessoaProspectImportacaoTemp = null
			from
				PessoaProspectOrigemPessoaProspect
					inner join
				PessoaProspect on PessoaProspect.Id = PessoaProspectOrigemPessoaProspect.IdPessoaProspect
					inner join
				ContaSistema  with (nolock) on ContaSistema.Id = PessoaProspect.idContaSistema

			where
				ContaSistema.Status = 'DE'
					and
				IdPessoaProspectImportacaoTemp is not null


			-- deleta as importações temporárias das conta sistemas desativadas
			delete top (100000) PessoaProspectImportacaoTemp
			from 
				PessoaProspectImportacaoTemp with (nolock)
					inner join
				PessoaProspectImportacao  with (nolock) on PessoaProspectImportacaoTemp.IdPessoaProspectImportacao = PessoaProspectImportacao.Id
					inner join
				ContaSistema  with (nolock) on ContaSistema.Id = PessoaProspectImportacao.idContaSistema
			where
				ContaSistema.Status = 'DE'


		delete top (100000) PessoaProspectFidelizado
				from 
					PessoaProspectFidelizado with(nolock)
						inner join 
					PessoaProspect with(nolock) on PessoaProspectFidelizado.IdPessoaProspect = PessoaProspect.Id
						inner join
					ContaSistema with(nolock) on PessoaProspect.IdContaSistema = ContaSistema.Id
				where
					ContaSistema.Status = 'DE'




		begin
			delete NotificacaoGlobal
			from 
				NotificacaoGlobal with (nolock)
					inner join
				ContaSistema  with (nolock) on contasistema.Id = NotificacaoGlobal.IdContaSistema

			where 
				ContaSistema.Status = 'DE'

			
		end

	
		begin

			DELETE Gatilho

			from
				Gatilho with (nolock)
					inner join
				ContaSistema with (nolock) on ContaSistema.Id = Gatilho.IdContaSistema
			where
				ContaSistema.Status = 'DE'

			
		end


	-- Exclui as integrações de contas desativadas
	exec [dbo].[ProcExcluirPessoaProspectIntegracaoLog]

	-- Exclui logs de empresas desativadas
	exec [dbo].[ProcExcluirLogAcoes]


Update 
	TabelaoLog 
Set
	-- Adiciona 2 milesegundo desde a última execução para considerar todos atualizados desde a última atualização
	-- 2 pq é o mínimo que pode adicionar
	TabelaoLog.Data1 = @dtReferenciaUtilizarMaximo,
	TabelaoLog.Data2 = null,
	TabelaoLog.bit1 = @GerarTudo,
	TabelaoLog.DtUltimaParcial = case when @GerarTudo = 0 then dbo.GetDateCustom() else TabelaoLog.DtUltimaParcial end,
	TabelaoLog.DtUltimaCompleta = case when @GerarTudo = 1 then dbo.GetDateCustom() else TabelaoLog.DtUltimaCompleta end
where
	TabelaoLog.Nome = @BatchNome;

-- =============================================
-- Author:      Camargo, Paulo Henrique
-- Create Date:  11/05/2022
-- Description: Executar comandos de limpeza 
-- de pessoa prospect que existem na rotina 
-- de limpeza de base
-- =============================================
--exec ProcLimpezaDeBasePessoaProspect
CREATE procedure [dbo].[ProcLimpezaDeBasePessoaProspect]

AS
BEGIN
	
	declare @dtnow datetime = dbo.getDateCustom()
	declare @dtReferenciaUtilizarMaximo datetime = @dtnow
	declare @BatchNome varchar(1000) = 'Batch_LimpezaDeBasePessoaProspect'
	declare @dtUltimaAtualizacao datetime
	declare @GerarTudo bit = 1
	declare @errorSys bit = 0
	declare @erroMsg varchar(max) = ''

	-- Retorna a data que começou a última atualização
	select @dtUltimaAtualizacao = Max(TabelaoLog.Data2) from TabelaoLog with (nolock) where TabelaoLog.Nome = @BatchNome group by TabelaoLog.Nome

	-- Se o processamento atual não for de gerar tudo e a data não for nula
	-- Subentende-se que no momento está sendo atualizado e não deve rodar 2 atualizações ao mesmo tempo
	-- testará tb se faz mais de 120 minutos que a ultima query executou nesse caso irá considerar que hove erro e executará 
	-- zerando a hora para não ter problemas
	if (@dtUltimaAtualizacao is not null and DATEDIFF(MI, @dtUltimaAtualizacao, dbo.GetDateCustom()) < 180)
		begin
			return
		end
	--else
	--	begin
	--		update TabelaoLog set TabelaoLog.Data2 = dbo.GetDateCustom(), TabelaoLog.bit1 = @GerarTudo where TabelaoLog.Nome = @BatchNome
	--	end


Delete PessoaProspectEmail
			From 
				PessoaProspectEmail with(nolock)
					inner join
				(
					Select 
						PessoaProspectEmail.IdPessoaProspect,
						PessoaProspectEmail.Email,
						min(PessoaProspectEmail.Id) as MinIdEmailPessoaProspect
					From 
						PessoaProspectEmail with(nolock)
							inner join
						(
							Select 
								PessoaProspectEmail.IdPessoaProspect,
								PessoaProspectEmail.Email,
								count(PessoaProspectEmail.Id) as CountTotal
							From
								PessoaProspectEmail with(nolock)
							group by
								PessoaProspectEmail.IdPessoaProspect,
								PessoaProspectEmail.Email
							Having 
								count(PessoaProspectEmail.Id) > 1
						) TabAux on 
								TabAux.IdPessoaProspect = PessoaProspectEmail.IdPessoaProspect and 
								TabAux.Email = PessoaProspectEmail.Email

					Group by
						PessoaProspectEmail.IdPessoaProspect,
						PessoaProspectEmail.Email
				) Tab2 on
					Tab2.IdPessoaProspect = PessoaProspectEmail.IdPessoaProspect and
					Tab2.Email = PessoaProspectEmail.Email
			where
				PessoaProspectEmail.id > Tab2.MinIdEmailPessoaProspect


			 -- Deleta os emails que não são emails válidos
			delete from PessoaProspectEmail 
			where 
				(
					(email like '%.co' or email like '%.b' or email not like '%.%' or email not like '%@%')
						or
					(email like '%.com%' and (email not like '%.com.%' and email not like '%.com'))
				)



			-- Deleta telefones duplicados de um mesmo prospect
			Delete PessoaProspectTelefone
			From
				PessoaProspectTelefone with(nolock)
					inner join
				(
					Select 
						PessoaProspectTelefone.IdPessoaProspect,
						PessoaProspectTelefone.DDD,
						PessoaProspectTelefone.Telefone,
						min(PessoaProspectTelefone.Id) as MinIdTelefonePessoaProspect
					From 
						PessoaProspectTelefone with(nolock)
							inner join
						(
							Select 
								PessoaProspectTelefone.IdPessoaProspect,
								PessoaProspectTelefone.DDD,
								PessoaProspectTelefone.Telefone,
								count(PessoaProspectTelefone.Id) as CountTotal
							From
								PessoaProspectTelefone with(nolock)
							group by
								PessoaProspectTelefone.IdPessoaProspect,
								PessoaProspectTelefone.DDD,
								PessoaProspectTelefone.Telefone
							Having 
								count(PessoaProspectTelefone.Id) > 1
						) TabAux on 
								TabAux.IdPessoaProspect = PessoaProspectTelefone.IdPessoaProspect and 
								TabAux.DDD = PessoaProspectTelefone.DDD and 
								TabAux.Telefone = PessoaProspectTelefone.Telefone

					Group by
						PessoaProspectTelefone.IdPessoaProspect,
						PessoaProspectTelefone.DDD,
						PessoaProspectTelefone.Telefone
				) Tab2 on
					Tab2.IdPessoaProspect = PessoaProspectTelefone.IdPessoaProspect and
					Tab2.DDD = PessoaProspectTelefone.DDD and 
					Tab2.Telefone = PessoaProspectTelefone.Telefone
			where
				PessoaProspectTelefone.id > Tab2.MinIdTelefonePessoaProspect

begin
			delete 
				PessoaProspectTelefone
			Where
				exists 
				(
					Select 
						ContaSistemaConfiguracao.Id
					From
						SuperEntidade with (nolock)
							inner join
						ContaSistemaConfiguracao  with (nolock) on ContaSistemaConfiguracao.IdContaSistema = SuperEntidade.idContaSistema
					where
						ContaSistemaConfiguracao.Tipo = 'IGNORAR_TELEFONE_INVALIDO' and 
						ContaSistemaConfiguracao.ValorInt = 1 and
						SuperEntidade.Id = PessoaProspectTelefone.IdPessoaProspect
				)
					and
				(
					PessoaProspectTelefone.Telefone like '%00000000%' or
					PessoaProspectTelefone.Telefone like '%11111111%' or
					PessoaProspectTelefone.Telefone like '%22222222%' or
					PessoaProspectTelefone.Telefone like '%33333333%' or
					PessoaProspectTelefone.Telefone like '%44444444%' or
					PessoaProspectTelefone.Telefone like '%55555555%' or
					PessoaProspectTelefone.Telefone like '%66666666%' or
					PessoaProspectTelefone.Telefone like '%77777777%' or
					PessoaProspectTelefone.Telefone like '%88888888%' or 
					PessoaProspectTelefone.Telefone like '%99999999%' 
				)
			
		end


    begin
			update PessoaProspectImportacao set PessoaProspectImportacao.Status = 'CANCELADO'
			from
				PessoaProspectImportacao with (nolock)
					inner join
				ContaSistema  with (nolock) on PessoaProspectImportacao.idContaSistema = ContaSistema.Id
			where
				ContaSistema.Status = 'DE'
					and
				PessoaProspectImportacao.Status not in ('PROCESSADO', 'CANCELADO')
	
			-- Deleta todas as Importações que não possui leads
			delete from PessoaProspectImportacao
			from 
				PessoaProspectImportacao with(nolock)
					inner join
				ContaSistema  with (nolock) on PessoaProspectImportacao.idContaSistema = ContaSistema.Id
			where
				not exists (
								Select 
									PessoaProspect.id 
								from 
									PessoaProspect with(nolock) 
										inner join
									PessoaProspectOrigemPessoaProspect with(nolock) on PessoaProspectOrigemPessoaProspect.idPessoaProspect = PessoaProspect.id
										inner join
									PessoaProspectOrigem with(nolock) on PessoaProspectOrigem.Id = PessoaProspectOrigemPessoaProspect.IdPessoaProspectOrigem
								where 
									PessoaProspectImportacao.Id = PessoaProspectOrigem.IdPessoaProspectImportacao
							)
					or
				ContaSistema.Status = 'DE'
					
		
	end

		delete from  pessoaprospect
				from 
				pessoaprospect with(nolock)
					left outer  join
				superentidade with(nolock) on superentidade.id = pessoaprospect.id and superentidade.SuperEntidadeTipo = 'PESSOAPROSPECT'

				where superentidade.id  is null


	
		begin
			-- deleta antes de deletar os prospects abaixo
			delete from dbo.PessoaProspectOrigemPessoaProspect
			from
				dbo.PessoaProspectOrigemPessoaProspect with(nolock)
					inner join
				pessoaprospect with(nolock)  on PessoaProspectOrigemPessoaProspect.idpessoaprospect = pessoaprospect.id
					left outer  join
				superentidade with(nolock) on superentidade.id = pessoaprospect.id and superentidade.SuperEntidadeTipo = 'PESSOAPROSPECT'
			where superentidade.id is null

			
		end

update PessoaProspectTelefone set  PessoaProspectTelefone.Telefone = '9'+ PessoaProspectTelefone.Telefone
			from PessoaProspectTelefone 
			where
				PessoaProspectTelefone.DDD in (61,62, 63, 64, 65, 66, 67, 68, 69, 11, 12, 13, 14, 15, 16, 17, 18, 19, 21, 22, 24, 27, 28, 91, 92, 93, 94, 95, 96, 97, 98,  99, 81, 82, 83, 84, 85, 86,87, 88, 89, 31, 32, 33, 34, 35, 37, 38, 71, 73, 74, 75, 77, 79,  41, 42, 43, 44, 45, 46, 47, 48, 49, 51, 53, 54, 55) and
				LEN(PessoaProspectTelefone.Telefone) <= 8 and
				SUBSTRING(PessoaProspectTelefone.Telefone, 1, 1) in ('8', '9')



			-- Ajusta os telefones
			update PessoaProspectTelefone set DDD = replace(replace(replace(DDD, ' ', ''),'_',''),'-',''), Telefone = replace(replace(replace(replace(replace(Telefone, ' ', ''),'_',''),'-',''),')',''),'(','')
			 where ISNUMERIC (DDD) = 0 or ISNUMERIC (Telefone) = 0

			-- delete os telefones que não são numéricos
			delete from PessoaProspectTelefone where ISNUMERIC (DDD) = 0 or ISNUMERIC (Telefone) = 0

			-- deleta os telefones inválidos com ddd < 11
			delete from PessoaProspectTelefone where cast(telefone as float) < 20000000	


			-- deleta os endereços duplicados dos prospects
			--Delete PessoaProspectEndereco
			--From
			--	PessoaProspectEndereco with(nolock)
			--		inner join
			--	(
			--		Select 
			--			PessoaProspectEndereco.IdPessoaProspect,
			--			PessoaProspectEndereco.UF,
			--			PessoaProspectEndereco.IdCidade,
			--			PessoaProspectEndereco.IdBairro,
			--			PessoaProspectEndereco.Tipo,
			--			PessoaProspectEndereco.Logradouro,
			--			PessoaProspectEndereco.Complemento,
			--			PessoaProspectEndereco.Numero,
			--			PessoaProspectEndereco.CEP,
			--			min(PessoaProspectEndereco.Id) as MinIdEnderecoPessoaProspect
			--		From 
			--			PessoaProspectEndereco with(nolock) 
			--				inner join
			--			(
			--				Select 
			--					PessoaProspectEndereco.IdPessoaProspect,
			--					PessoaProspectEndereco.UF,
			--					PessoaProspectEndereco.IdCidade,
			--					PessoaProspectEndereco.IdBairro,
			--					PessoaProspectEndereco.Tipo,
			--					PessoaProspectEndereco.Logradouro,
			--					PessoaProspectEndereco.Complemento,
			--					PessoaProspectEndereco.Numero,
			--					PessoaProspectEndereco.CEP,
			--					count(PessoaProspectEndereco.Id) as CountTotal
			--				From
			--					PessoaProspectEndereco with(nolock) 
			--				group by
			--					PessoaProspectEndereco.IdPessoaProspect,
			--					PessoaProspectEndereco.UF,
			--					PessoaProspectEndereco.IdCidade,
			--					PessoaProspectEndereco.IdBairro,
			--					PessoaProspectEndereco.Tipo,
			--					PessoaProspectEndereco.Logradouro,
			--					PessoaProspectEndereco.Complemento,
			--					PessoaProspectEndereco.Numero,
			--					PessoaProspectEndereco.CEP
			--				Having 
			--					count(PessoaProspectEndereco.Id) > 1
			--			) TabAux on 
			--					TabAux.IdPessoaProspect = PessoaProspectEndereco.IdPessoaProspect and 
			--					TabAux.UF = PessoaProspectEndereco.UF and 
			--					TabAux.IdCidade = PessoaProspectEndereco.IdCidade and 
			--					TabAux.IdBairro = PessoaProspectEndereco.IdBairro and 
			--					TabAux.Tipo = PessoaProspectEndereco.Tipo and 
			--					TabAux.Logradouro = PessoaProspectEndereco.Logradouro and 
			--					TabAux.Complemento = PessoaProspectEndereco.Complemento and 
			--					TabAux.Numero = PessoaProspectEndereco.Numero and 
			--					TabAux.CEP = PessoaProspectEndereco.CEP

			--		Group by
			--			PessoaProspectEndereco.IdPessoaProspect,
			--			PessoaProspectEndereco.UF,
			--			PessoaProspectEndereco.IdCidade,
			--			PessoaProspectEndereco.IdBairro,
			--			PessoaProspectEndereco.Tipo,
			--			PessoaProspectEndereco.Logradouro,
			--			PessoaProspectEndereco.Complemento,
			--			PessoaProspectEndereco.Numero,
			--			PessoaProspectEndereco.CEP
			--	) Tab2 on
			--		Tab2.IdPessoaProspect = PessoaProspectEndereco.IdPessoaProspect and 
			--		Tab2.UF = PessoaProspectEndereco.UF and 
			--		Tab2.IdCidade = PessoaProspectEndereco.IdCidade and 
			--		Tab2.IdBairro = PessoaProspectEndereco.IdBairro and 
			--		Tab2.Tipo = PessoaProspectEndereco.Tipo and 
			--		Tab2.Logradouro = PessoaProspectEndereco.Logradouro and 
			--		Tab2.Complemento = PessoaProspectEndereco.Complemento and 
			--		Tab2.Numero = PessoaProspectEndereco.Numero and 
			--		Tab2.CEP = PessoaProspectEndereco.CEP
			--where
			--	PessoaProspectEndereco.id > Tab2.MinIdEnderecoPessoaProspect

			DELETE FROM PessoaProspectEndereco 
			WHERE ID IN (
			SELECT A.Id FROM PessoaProspectEndereco A
			JOIN (SELECT max(ID) AS id, IdPessoaProspect
			FROM PessoaProspectEndereco PD1 WITH(NOLOCK)
			 WHERE IdPessoaProspect IN (Select 
								PessoaProspectEndereco.IdPessoaProspect
							From
								PessoaProspectEndereco with(nolock) 
							group by
								PessoaProspectEndereco.IdPessoaProspect,
								PessoaProspectEndereco.UF,
								PessoaProspectEndereco.IdCidade,
								PessoaProspectEndereco.IdBairro,
								PessoaProspectEndereco.Tipo,
								PessoaProspectEndereco.Logradouro,
								PessoaProspectEndereco.Complemento,
								PessoaProspectEndereco.Numero,
								PessoaProspectEndereco.CEP
							Having 
								count(PessoaProspectEndereco.Id) > 1)
			GROUP BY IdPessoaProspect) AS B
			ON A.id != B.ID AND A.IdPessoaProspect = B.IdPessoaProspect
			)


END

Update 
	TabelaoLog 
Set
	-- Adiciona 2 milesegundo desde a última execução para considerar todos atualizados desde a última atualização
	-- 2 pq é o mínimo que pode adicionar
	TabelaoLog.Data1 = @dtReferenciaUtilizarMaximo,
	TabelaoLog.Data2 = null,
	TabelaoLog.bit1 = 0,
	TabelaoLog.DtUltimaParcial =  dbo.GetDateCustom() ,
	TabelaoLog.DtUltimaCompleta =  dbo.GetDateCustom() 
where
	TabelaoLog.Nome = @BatchNome;

-- =============================================
-- Author:      Camargo, Paulo Henrique
-- Create Date:  11/05/2022
-- Description: Executar comandos de Truncate que
-- existem na rotina de limpeza de base
-- =============================================
CREATE procedure [dbo].[ProcLimpezaDeBaseTruncateTable]

AS
BEGIN

	declare @dtnow datetime = dbo.getDateCustom()
	declare @dtReferenciaUtilizarMaximo datetime = @dtnow
	declare @BatchNome varchar(1000) = 'Batch_LimpezaDeBaseTruncateTable'
	declare @dtUltimaAtualizacao datetime
	declare @GerarTudo bit = 1
	declare @errorSys bit = 0
	declare @erroMsg varchar(max) = ''
    
	select @dtUltimaAtualizacao = Max(TabelaoLog.Data2) from TabelaoLog with (nolock) where TabelaoLog.Nome = @BatchNome group by TabelaoLog.Nome

	-- Se o processamento atual não for de gerar tudo e a data não for nula
	-- Subentende-se que no momento está sendo atualizado e não deve rodar 2 atualizações ao mesmo tempo
	-- testará tb se faz mais de 120 minutos que a ultima query executou nesse caso irá considerar que hove erro e executará 
	-- zerando a hora para não ter problemas
	if (@dtUltimaAtualizacao is not null and DATEDIFF(MI, @dtUltimaAtualizacao, dbo.GetDateCustom()) < 180)
		begin
			return
		end
	
	-- Exclui todas as pendencias de processamento
	truncate table PendenciaProcessamento;
	-- Exclui todos os eventos processados
	truncate table evento;

	-- Exclui todos os eventos processados
	truncate table EventoPre;

	Update 
	TabelaoLog 
	Set
	-- Adiciona 2 milesegundo desde a última execução para considerar todos atualizados desde a última atualização
	-- 2 pq é o mínimo que pode adicionar
	TabelaoLog.Data1 = @dtReferenciaUtilizarMaximo,
	TabelaoLog.Data2 = null,
	TabelaoLog.bit1 = 0,
	TabelaoLog.DtUltimaParcial = case when @GerarTudo = 0 then dbo.GetDateCustom() else TabelaoLog.DtUltimaParcial end,
	TabelaoLog.DtUltimaCompleta = case when @GerarTudo = 1 then dbo.GetDateCustom() else TabelaoLog.DtUltimaCompleta end
where
	TabelaoLog.Nome = @BatchNome


END;

CREATE procedure [dbo].[ProcMergeAtendimento]
 @IdContaSistema as int,
 @IdUsuarioContaSistemaExecutou as int,
 @IdAtendimentoOld as int,
 @IdAtendimentoNew as int,
 @ExcluirNaHora as bit,
 @obs as varchar(max)
 as 
begin

declare @dateNow datetime = dbo.getdatecustom()
declare @dateNowVarchar varchar(50) = convert(varchar(50), @dateNow, 126)
declare @objVersaoInt int = 2019073118;
declare @objVersaoVarchar varchar(12) = '2019073118';

declare @mesclarProspect int = 1
declare @mesclarProspectLog varchar(500) = '';

declare @idPessoaProspectOldTest as int
declare @idPessoaProspectNewTest as int

declare @nomePessoaProspectOldTest as varchar(300)
declare @nomePessoaProspectNewTest as varchar(300)

declare @idAtendimentoOldTest as int
declare @idAtendimentoNewTest as int

declare @idUsuarioContaSistemaAtendimentoOld as int
declare @idUsuarioContaSistemaAtendimentoNew as int

declare @TabAuxInteracao table(id int, idContaSistema int, idSuperEntidade int, idInteracaoTipo int)

select @nomePessoaProspectNewTest = PessoaProspect.Nome, @idPessoaProspectOldTest = Atendimento.idPessoaProspect, @idAtendimentoOldTest = Atendimento.Id, @idUsuarioContaSistemaAtendimentoOld = Atendimento.IdUsuarioContaSistemaAtendimento from Atendimento WITH (NOLOCK) inner join PessoaProspect  WITH (NOLOCK) on PessoaProspect.id = Atendimento.idPessoaProspect where Atendimento.id = @IdAtendimentoOld and Atendimento.IdContaSistema = @IdContaSistema
select @nomePessoaProspectOldTest = PessoaProspect.Nome, @idPessoaProspectNewTest = Atendimento.idPessoaProspect, @idAtendimentoNewTest = Atendimento.Id, @idUsuarioContaSistemaAtendimentoNew = Atendimento.IdUsuarioContaSistemaAtendimento from Atendimento WITH (NOLOCK) inner join PessoaProspect  WITH (NOLOCK) on PessoaProspect.id = Atendimento.idPessoaProspect where Atendimento.id = @IdAtendimentoNew and Atendimento.IdContaSistema = @IdContaSistema

if(@idAtendimentoOldTest is not null and @idAtendimentoNewTest is not null and @idAtendimentoOldTest != @idAtendimentoNewTest)
	begin

		-- verifica se existe atendimentos para o mesmo prospect sendo atendido por outro usuário a qual torna a mesclagem de prospect idevida
		-- já que impactaria outros usuários em outros atendimentos
		-- poderia acontecer caso o prospect tivesse sendo atendido por mais de 3 usuários, se a mescalagem acontecesse poderia afetar os atendimentos dos outros usuários
		set @mesclarProspect =	(
									Select
										CASE when count(Atendimento.id) > 0 then 0 else 1 end
									From
										Atendimento with (nolock)
									Where
										-- Somente se são prospects diferentes
										@idPessoaProspectOldTest != @idPessoaProspectNewTest
											and
										Atendimento.IdContaSistema = @IdContaSistema
											and
										Atendimento.idPessoaProspect = @idPessoaProspectOldTest
											and
										Atendimento.Id not in (@idAtendimentoOldTest, @idAtendimentoNewTest)
											and
										Atendimento.StatusAtendimento = 'ATENDIDO'
											and
										Atendimento.IdUsuarioContaSistemaAtendimento not in (@idUsuarioContaSistemaAtendimentoOld, @idUsuarioContaSistemaAtendimentoNew)
								)




		update Alarme set Alarme.idSuperEntidade = @IdAtendimentoNew
		where Alarme.idSuperEntidade = @IdAtendimentoOld

		update Interacao set Interacao.IdSuperEntidade = @IdAtendimentoNew
		where Interacao.IdSuperEntidade = @IdAtendimentoOld

		update InteracaoObj set InteracaoObj.IdSuperEntidade = @IdAtendimentoNew, InteracaoObj.ObjJson = JSON_MODIFY(InteracaoObj.ObjJson, '$.Obj.IdSuperEntidade', @IdAtendimentoNew)
		where InteracaoObj.IdSuperEntidade = @IdAtendimentoOld

		update SuperEntidadeLog set SuperEntidadeLog.IdSuperEntidade = @IdAtendimentoNew
		where SuperEntidadeLog.IdSuperEntidade = @IdAtendimentoOld

		update OportunidadeNegocio set OportunidadeNegocio.IdAtendimento = @IdAtendimentoNew
		where OportunidadeNegocio.IdAtendimento = @IdAtendimentoOld

		update AtendimentoSeguidor set AtendimentoSeguidor.IdAtendimento = @IdAtendimentoNew
		where
			AtendimentoSeguidor.IdAtendimento = @IdAtendimentoOld

		-- Se faz necessário para evitar que quando vá excluir a interação não de problema 
		-- Pois o atendimento antigo pode conter interação que foi repassada para o novo
		update Atendimento set 
				Atendimento.IdInteracaoAutoUltima = null,
				Atendimento.IdInteracaoProspectUltima = null,
				Atendimento.IdInteracaoUsuarioUltima = null,
				Atendimento.idInteracaoNegociacaoVendaUltima = null
		where
			Atendimento.Id = @IdAtendimentoOld


		-- Caso seja para mesclar prospect
		if @mesclarProspect = 1 and @idPessoaProspectOldTest != @idPessoaProspectNewTest
			begin
				-- transfere os emails para o prospect do novo atendimento
				update PessoaProspectEmail set PessoaProspectEmail.IdPessoaProspect = @idPessoaProspectNewTest
				where
					PessoaProspectEmail.IdPessoaProspect = @idPessoaProspectOldTest
						and
					not exists (Select PessoaProspectEmailNew.id from PessoaProspectEmail PessoaProspectEmailNew where PessoaProspectEmailNew.IdPessoaProspect = @idPessoaProspectNewTest and PessoaProspectEmailNew.Email = PessoaProspectEmail.Email)

				
				-- transfere os telefones para o prospect do novo atendimento
				update PessoaProspectTelefone set PessoaProspectTelefone.IdPessoaProspect = @idPessoaProspectNewTest
				where
					PessoaProspectTelefone.IdPessoaProspect = @idPessoaProspectOldTest
						and
					not exists (Select PessoaProspectTelefoneNew.id from PessoaProspectTelefone PessoaProspectTelefoneNew where PessoaProspectTelefoneNew.IdPessoaProspect = @idPessoaProspectNewTest and PessoaProspectTelefoneNew.Telefone = PessoaProspectTelefone.Telefone)


				-- transfere os documentos para o prospect do novo atendimento
				update PessoaProspectDocumento set PessoaProspectDocumento.IdPessoaProspect = @idPessoaProspectNewTest
				where
					PessoaProspectDocumento.IdPessoaProspect = @idPessoaProspectOldTest
						and
					not exists (Select PessoaProspectDocumentoNew.id from PessoaProspectDocumento PessoaProspectDocumentoNew where PessoaProspectDocumentoNew.IdPessoaProspect = @idPessoaProspectNewTest and PessoaProspectDocumentoNew.Doc = PessoaProspectDocumento.Doc)

				
				-- transfere os documentos para o prospect do novo atendimento
				update PessoaProspectEndereco set PessoaProspectEndereco.IdPessoaProspect = @idPessoaProspectNewTest
				where
					PessoaProspectEndereco.IdPessoaProspect = @idPessoaProspectOldTest
						and
					not exists (Select PessoaProspectEnderecoNew.id from PessoaProspectEndereco PessoaProspectEnderecoNew where PessoaProspectEnderecoNew.IdPessoaProspect = @idPessoaProspectNewTest)


				-- transfere as tags para o prospect do novo atendimento
				update PessoaProspectTag set PessoaProspectTag.IdPessoaProspect = @idPessoaProspectNewTest
				where
					PessoaProspectTag.IdPessoaProspect = @idPessoaProspectOldTest
						and
					not exists (Select PessoaProspectTagNew.id from PessoaProspectTag PessoaProspectTagNew where PessoaProspectTagNew.IdPessoaProspect = @idPessoaProspectNewTest  and PessoaProspectTagNew.IdTag = PessoaProspectTag.IdTag)

				update PessoaProspectFidelizado set PessoaProspectFidelizado.DtFimFidelizacao = @dateNow
				where
					PessoaProspectFidelizado.IdPessoaProspect = @idPessoaProspectOldTest
						and
					PessoaProspectFidelizado.DtFimFidelizacao is null

				set @mesclarProspectLog = 'Os dados do Prospect ('+@nomePessoaProspectOldTest+') do atendimento ('+ CONVERT(varchar(15), @IdAtendimentoOld) +')  foram mesclados com os dados do Prospect ('+@nomePessoaProspectNewTest+') desse atendimento ('+ CONVERT(varchar(15), @IdAtendimentoNew) +'). '
											
			end


		-- salva um log
		INSERT INTO [dbo].[LogAcoes]
					(
					IdGuid
					,[IdContaSistema]
					,[IdUsuarioContaSistemaExecutou]
					,[Tipo]
					,[TipoSub]
					,[Texto]
					,[ValueOld]
					,[ValueNew]
					,[NomeMethod]
					,[DtInclusao]
					,[TabelaBD]
					,[TabelaBDChave]
					,[EnviarEmailAdministradorAnapro]
					,[IdUsuarioContaSistemaImpactou])
				VALUES (
					NEWID(),
					@IdContaSistema,
					@IdUsuarioContaSistemaExecutou,
					'Atendimento',
					'Atendimento_Mesclado',
					'Atendimento ('+ CONVERT(varchar(15), @IdAtendimentoOld) +') do Prospect ('+@nomePessoaProspectOldTest+') mesclado manualmente com atendimento ('+ CONVERT(varchar(15), @IdAtendimentoNew) +') do Prospect ('+@nomePessoaProspectNewTest+') e posteriormente o atendimento ('+ CONVERT(varchar(15), @IdAtendimentoOld) +') foi excluído. '+ @mesclarProspectLog + @obs,
					CONVERT(varchar(15), @IdAtendimentoOld),
					CONVERT(varchar(15), @IdAtendimentoNew),
					'ProcMergeAtendimento',
					@dateNow,
					'Atendimento',
					CONVERT(varchar(15), @IdAtendimentoOld),
					0,
					@idUsuarioContaSistemaAtendimentoOld)

		declare @stMensagemLog varchar(300) = 'Atendimento ('+CONVERT(varchar(15), @IdAtendimentoOld)+') mesclado com o atendimento ('+ CONVERT(varchar(15), @IdAtendimentoNew) +').'




		-- Insere os logs nos atendimentos informando sobre a mudança
		insert 
			into Interacao 
				(
					IdContaSistema,
					IdSuperEntidade,
					IdUsuarioContaSistema,
					DtInclusao,
					DtInteracao,
					Tipo,
					IdUsuarioContaSistemaRealizou,
					IdInteracaoTipo,
					InteracaoAtorPartida,
					DtConclusao,
					Realizado,
					IdGuid,
					ObjTipo,
					ObjTipoSub,
					ObjVersao,
					TipoCriacao
				)  OUTPUT inserted.Id, inserted.IdContaSistema, inserted.IdSuperEntidade, inserted.IdInteracaoTipo into @TabAuxInteracao
		Select
			Atendimento.IdContaSistema,
			Atendimento.Id as IdSuperEntidade,
			@IdUsuarioContaSistemaExecutou as IdUsuarioContaSistema,
			@dateNow as DtInclusao,
			@dateNow as DtInteracao,
			'INTERACAOGERAL' as Tipo,
			@IdUsuarioContaSistemaExecutou as IdUsuarioContaSistemaRealizou,
			InteracaoTipo.Id as IdInteracaoTipo,
			'USUARIO' as InteracaoAtorPartida,
			@dateNow as DtConclusao,
			1 as Realizado,
			NEWID() as idGuid,
			'SuperCRM.DTO.InteracaoGeral.InteracaoGeralPersistDTO' as ObjTipo,
			'SuperCRM.DTO.InteracaoGeral.InteracaoGeralLogDTO' as ObjTipoSub,
			@objVersaoInt as ObjVersao,
			'AUTO' as TipoCriacao

		From
			Atendimento with (nolock)
				inner join
			InteracaoTipo with (nolock) on InteracaoTipo.IdContaSistema = Atendimento.IdContaSistema and InteracaoTipo.Tipo = 'ATENDIMENTOMESCLADO' AND InteracaoTipo.Sistema = 1
		where
			Atendimento.id = @IdAtendimentoNew


		insert 
			into InteracaoObj
				(
					Id,
					IdContaSistema,
					IdSuperEntidade,
					ObjTipo,
					ObjVersao,
					ObjTipoSub,
					ObjJson
				)
			Select 
				TabAux.id,
				TabAux.idContaSistema,
				TabAux.idSuperEntidade,
				'SuperCRM.DTO.InteracaoGeral.InteracaoGeralPersistDTO' as ObjTipo,
				@objVersaoInt as ObjVersao,
				'SuperCRM.DTO.InteracaoGeral.InteracaoGeralLogDTO' as ObjTipoSub,
				N'{"Type":"SuperCRM.DTO.InteracaoGeral.InteracaoGeralPersistDTO",
					"Texto":"",
					"Versao":'+@objVersaoVarchar+',
					"VersaoObj":'+@objVersaoVarchar+',"InteracaoTipoSys":"LOG","ObjType":"SuperCRM.DTO.InteracaoGeral.InteracaoGeralLogDTO","Obj":{"$type":"SuperCRM.DTO.InteracaoGeral.InteracaoGeralLogDTO, SuperCRM",
					"AtorPartida":"USUARIO",
					"LogTipo":"ATENDIMENTO_MESCLADO",
					"Texto":"'+STRING_ESCAPE('Atendimento ('+ CONVERT(varchar(15), @IdAtendimentoOld) +') do Prospect ('+@nomePessoaProspectOldTest+') mesclado manualmente com atendimento ('+ CONVERT(varchar(15), @IdAtendimentoNew) +') do Prospect ('+@nomePessoaProspectNewTest+') e posteriormente o atendimento ('+ CONVERT(varchar(15), @IdAtendimentoOld) +') foi excluído. '+ @mesclarProspectLog + @obs,'json')+'",
					"IdUsuarioContaSistema":'+CONVERT(varchar(15),@IdUsuarioContaSistemaExecutou)+',
					"VariaveisTipadas":{},
					"Variaveis":{},
					"DtMigracao":null,
					"Versao":'+@objVersaoVarchar+',
					"InteracaoTipoId":'+convert(varchar(15),TabAux.idInteracaoTipo)+',
					"InteracaoTipoIdGuid":null,
					"Tipo":"LOG",
					"DtInclusao":"'+@dateNowVarchar+'",
					"TextoAutomatico":false,
					"IdContaSistema":'+convert(varchar(15),TabAux.idContaSistema)+',
					"IdSuperEntidade":'+convert(varchar(15),TabAux.idSuperEntidade)+',
					"TipoCriacao":"AUTO"}}' as ObjJson
			From
				@TabAuxInteracao TabAux


		if @ExcluirNaHora = 1
			begin
				exec dbo.ProcExcluirAtendimento @IdContaSistema,  @IdUsuarioContaSistemaExecutou, @IdAtendimentoOld, 1
			end
		else
			begin
				-- Elege o atendimento antigo para ser excluído
				exec dbo.ProcExcluirAtendimentoPreparacao @IdContaSistema,  @IdUsuarioContaSistemaExecutou, @stMensagemLog, @IdAtendimentoOld
			end


	end
end;

CREATE procedure [dbo].[ProcMidiaSubstituir]
(
	@IdContaSistema as int,
	@IdUsuarioContaSistema as int,
	@IdMidiaNovo as int,
	@IdMidiaVelho as int
)
as 
	declare @datenow AS DATETIME = dbo.GetDateCustom()
	declare @MidiaNovoExists as varchar(200)
	declare @MidiaVelhoExists as varchar(200)
	
	set @MidiaNovoExists = (select Midia.Nome from Midia with (nolock) where IdContaSistema = @IdContaSistema and id = @IdMidiaNovo)
	set @MidiaVelhoExists = (select Midia.Nome from Midia with (nolock) where IdContaSistema = @IdContaSistema and id = @IdMidiaVelho)
	
	IF (dbo.IsNullOrWhiteSpace(@MidiaNovoExists) = 0 and dbo.IsNullOrWhiteSpace(@MidiaVelhoExists) = 0)
		BEGIN

			begin tran
				-- Muda a referência dos produtos de todas as tabelas do antigo para o novo
				Update Prospeccao set IdMidia = @IdMidiaNovo where Prospeccao.IdMidia = @IdMidiaVelho and Prospeccao.IdContaSistema = @IdContaSistema
				Update Peca set IdMidia = @IdMidiaNovo where IdMidia = @IdMidiaVelho
				Update MidiaInvestimento set IdMidia = @IdMidiaNovo where IdMidia = @IdMidiaVelho
				Update Atendimento set IdMidia = @IdMidiaNovo where IdMidia = @IdMidiaVelho
				Update InteracaoMarketing set IdMidia = @IdMidiaNovo where IdMidia = @IdMidiaVelho
				Update TagAtalho set IdMidia = @IdMidiaNovo where IdMidia = @IdMidiaVelho

				-- Exclui a midia antigo
				Delete from Midia where id = @IdMidiaVelho
					
				-- Inclui um log
				Insert into LogAcoes 
				(
					LogAcoes.IdGuid,
					LogAcoes.DtInclusao,
					LogAcoes.EnviarEmailAdministradorAnapro,
					LogAcoes.IdContaSistema,
					LogAcoes.IdUsuarioContaSistemaExecutou,
					LogAcoes.IdUsuarioContaSistemaImpactou,
					LogAcoes.NomeMethod,
					LogAcoes.TabelaBD,
					LogAcoes.TabelaBDChave,
					LogAcoes.Texto,
					LogAcoes.Tipo,
					LogAcoes.TipoSub,
					LogAcoes.ValueNew,
					LogAcoes.ValueOld
				)
					values
				(
					NEWID(),
					@datenow,
					0,
					@IdContaSistema,
					@IdUsuarioContaSistema,
					null,
					'ProcMidiaSubstituir',
					'midia',
					@IdMidiaVelho,
					'A mídia (' + @MidiaVelhoExists + ') foi substituido pela midia (' + @MidiaNovoExists + '). A mídia ' + @MidiaVelhoExists + ' foi excluido do sistema.',
					'Midia',
					'Midia_substituida',
					@MidiaVelhoExists,
					@MidiaNovoExists
				)

			commit

		END
	Else
		BEGIN
			RAISERROR ('Mídia não existe.', 16, 1);
		END;

CREATE procedure [dbo].[ProcNotificacaoGlobalDesativar] 
(
	@id int,
	@strGuid varchar(36),
	@tipoNotificacao varchar(300),
	@identificacao varchar(300),
    @desativarRegerenciaEntidade bit
)
as
declare @dtnow datetime = dbo.getDateCustom()

-- Desativa todas notificações 
update NotificacaoGlobal
	set
		NotificacaoGlobal.Status = 'CAN',
		NotificacaoGlobal.DtUltimoStatus = @dtnow
	where
		NotificacaoGlobal.Status <> 'CAN'
			and
		(
			(
				(@tipoNotificacao is not null and @identificacao is not null)
					and 
				NotificacaoGlobal.TipoNotificacao = @tipoNotificacao
					and
				NotificacaoGlobal.Identificacao = @identificacao
			)
				or
			(
				(@id is not null and NotificacaoGlobal.Id = @id)
					or
				(@strGuid is not null and NotificacaoGlobal.StrGuid = @strGuid)
			)
		)
		OPTION (RECOMPILE);

-- Caso seja positivo
-- Desabilitará todos os gatilhos que as notificações estejam canceladas
if @DesativarRegerenciaEntidade = 1 
	begin
		Update GatilhoExecucao
			Set
				GatilhoExecucao.Status = 'DE',
				GatilhoExecucao.DtValidade = @dtnow,
				GatilhoExecucao.DtAlteracao = @dtnow
			
			from
				GatilhoExecucao with (nolock)
					inner join
				NotificacaoGlobal with (nolock) on GatilhoExecucao.StrGuid = NotificacaoGlobal.ReferenciaEntidadeCodigoStr and NotificacaoGlobal.ReferenciaEntidade = 'Gatilho'
			where
				NotificacaoGlobal.Status = 'CAN' and -- Se faz necessário para desabilitar somente as que foram caneladas
				GatilhoExecucao.Status <> 'DE'
					and
				(
					(
						(@tipoNotificacao is not null and @identificacao is not null)
							and 
						NotificacaoGlobal.TipoNotificacao = @tipoNotificacao
							and
						NotificacaoGlobal.Identificacao = @identificacao
					)
						or
					(
						(@id is not null and NotificacaoGlobal.Id = @id)
							or
						(@strGuid is not null and NotificacaoGlobal.StrGuid = @strGuid)
					)
				)
			OPTION (RECOMPILE);
				
	end

---- http://www.sommarskog.se/dyn-search.html
--OPTION (RECOMPILE);

-- Pré-processa os pendências de processamento de acordo com as regras de negocio
CREATE procedure [dbo].[ProcPendenciaProcessamentoPreProcessamento]
 as 
begin

declare @datenow AS DATETIME = dbo.GetDateCustomNoMilleseconds()
declare @dateConsiderarUsuarioContaSistemaAtivo AS DATETIME = DATEADD(MINUTE, -2, @datenow)

Select
	PendenciaProcessamento.Id
	into #TabAux
From
	PendenciaProcessamento with (READPAST) 
		inner join
	ContaSistema WITH (NOLOCK) on ContaSistema.Id = PendenciaProcessamento.IdContaSistema 
		inner join
	UsuarioContaSistema WITH (NOLOCK) on UsuarioContaSistema.Id = PendenciaProcessamento.IdUsuarioContaSistema 
	
Where
	PendenciaProcessamento.Status = 'INCLUIDO'
		and
	PendenciaProcessamento.DtInclusao <= @datenow
		and
	PendenciaProcessamento.PreProcessado = 0
		and
	(
		ContaSistema.Status <> 'AT'
			or
		UsuarioContaSistema.Status <> 'AT'
			or
		UsuarioContaSistema.DtUltimaRequisicao <= @dateConsiderarUsuarioContaSistemaAtivo
	)

-- Atualiza todos que não devem ser processados
Update 
	PendenciaProcessamento
		set 
			PendenciaProcessamento.Status = 'CANCELADO', 
			PendenciaProcessamento.PreProcessado = 1,
			PendenciaProcessamento.DtPreProcessado = @datenow,
			PendenciaProcessamento.Processado = 1, 
			PendenciaProcessamento.DtProcessado = @datenow,
			PendenciaProcessamento.Finalizado = 1,
			PendenciaProcessamento.QtdTentativaProcessamento = 1,
			PendenciaProcessamento.DtUltimaAtualizacao = @datenow
			
From
	PendenciaProcessamento with (READPAST) 
		inner join 
	#TabAux with (nolock) on PendenciaProcessamento.Id = #TabAux.Id

-- Atualiza todos que devem ser processados
update
	PendenciaProcessamento
		set
			PendenciaProcessamento.PreProcessado = 1,
			PendenciaProcessamento.DtPreProcessado = @datenow,
			PendenciaProcessamento.DtUltimaAtualizacao = @datenow
Where
	PendenciaProcessamento.Status = 'INCLUIDO'
		and
	PendenciaProcessamento.DtInclusao <= @datenow
		and
	PendenciaProcessamento.PreProcessado = 0
		and
	PendenciaProcessamento.DtValidadeInicioProcessamento <= @dateNow

end;

CREATE procedure [dbo].[ProcPodeEntrarNoChat] (@idContaSistema as int, @idUsuarioContaSistema as int)
as
	-- comentado em 24/06/2022, fazia locks infinitos no banco
	--Select cast(count(tab1.IdCampanha) as bit) from dbo.GetPlantaoChatUsuarioNow(@idContaSistema, @idUsuarioContaSistema, null, null, 0) as tab1
	declare @datenow AS DATETIME = dbo.GetDateCustom()
	declare @ret bit = 0

	select top 1

		@ret = cast(Campanha.Id as bit)
					
		from
			UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal WITH (NOLOCK)
				inner join
			UsuarioContaSistema  WITH (NOLOCK) on UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal.IdUsuarioContaSistema = UsuarioContaSistema.Id
				inner join
			CampanhaCanal  WITH (NOLOCK) on CampanhaCanal.id = UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal.idCampanhaCanal
				inner join
			Campanha WITH (NOLOCK) on Campanha.Id = CampanhaCanal.IdCampanha and Campanha.IdContaSistema = UsuarioContaSistema.IdContaSistema
				inner join
			Canal WITH (NOLOCK) on Canal.Id = CampanhaCanal.IdCanal and Canal.IdContaSistema = UsuarioContaSistema.IdContaSistema
				inner join  
			PlantaoHorario WITH (NOLOCK) on PlantaoHorario.id = UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal.idPlantaoHorario  
				inner join
			Plantao WITH (NOLOCK) on Plantao.IdCampanha = Campanha.Id

	where
		UsuarioContaSistema.IdContaSistema = @idContaSistema
			and
		UsuarioContaSistema.Id = @IdUsuarioContaSistema
			and
		Canal.Tipo = 'CHAT' and	
		Canal.Status = 'AT' and
		Campanha.Status = 'AT' and
		Plantao.Status = 'AT' and
		PlantaoHorario.Status = 'AT' and
		PlantaoHorario.DtInicio <= @datenow and 
		PlantaoHorario.DtFim >= @datenow and 
		(
			(
				Plantao.DtInicioValidade <= @datenow and
				Plantao.DtFimValidade is null
			)
				or
			(
				Plantao.DtInicioValidade <= @datenow and
				Plantao.DtFimValidade >= @datenow
			)
		)

		return isnull(@ret, 0);

-- Prepara as prospecções incluidas para serem prospectadas e encerra as já prospectadas
CREATE procedure [dbo].[ProcPrepararProspeccao]
as

declare @datenow AS DATETIME = dbo.GetDateCustom()


begin TRANSACTION 

	-- Encerra todas as prospecções que estão em processamento mas não existem mais prospects para prospectar
	update 
		Prospeccao 
	set 
		StatusProspeccao = 'CONCLUIDO'

	where
		Prospeccao.StatusProspeccao = 'PROCESSANDO' and
			Not exists 
		(
			Select 
				id 
			from
				ProspeccaoPessoaProspect with (nolock) 
			where
				ProspeccaoPessoaProspect.idProspeccao = Prospeccao.Id and
				ProspeccaoPessoaProspect.Status = 'INCLUIDO'
		)

	-- Insere os prospects a prospecção a serem prospectatados de acordo
	-- com as origens da prospecção
	Insert 
		into ProspeccaoPessoaProspect
		(
			IdPessoaProspect,
			IdAtendimento,
			IdProspeccao,
			IdPessoaProspectOrigemPessoaProspect,
			DtInclusao,
			DtStatus,
			Status
		)
				
		Select 
			Tab1.IdPessoaProspect,
			Tab1.IdAtendimento,
			Tab1.IdProspeccao as IdProspeccao,
			Tab1.idPessoaProspectOrigemPessoaProspect as idPessoaProspectOrigemPessoaProspect,
			@datenow as DtInclusao,
			@datenow as DtStatus,
			'INCLUIDO' as Status

		from
			(
				Select
					PessoaProspectOrigemPessoaProspect.IdPessoaProspect,
					PessoaProspectOrigemPessoaProspect.IdAtendimento,
					Prospeccao.id as IdProspeccao,
					min(PessoaProspectOrigemPessoaProspect.Id) as idPessoaProspectOrigemPessoaProspect

				From 
					Prospeccao WITH (NOLOCK)
						inner join
					ProspeccaoPessoaProspectOrigem WITH (NOLOCK) on ProspeccaoPessoaProspectOrigem.idProspeccao = Prospeccao.Id
						inner join
					PessoaProspectOrigem WITH (NOLOCK) on PessoaProspectOrigem.id = ProspeccaoPessoaProspectOrigem.IdPessoaProspectOrigem
						inner join
					PessoaProspectOrigemPessoaProspect WITH (NOLOCK) on PessoaProspectOrigemPessoaProspect.IdPessoaProspectOrigem = PessoaProspectOrigem.Id

				where 
					Prospeccao.Status = 'AT' and
					Prospeccao.StatusProspeccao = 'INCLUIDO' and
					Prospeccao.DtInicioProspeccao <= @datenow
				group by
					PessoaProspectOrigemPessoaProspect.IdPessoaProspect,
					PessoaProspectOrigemPessoaProspect.IdAtendimento,
					Prospeccao.id
			) Tab1


	-- Insere os prospects a prospecção a serem prospectatados de acordo
	-- seleciona os leads que contem as tags selecionadas
	-- usa as tags
	Insert 
		into ProspeccaoPessoaProspect
		(
			IdPessoaProspect,
			IdProspeccao,
			StrTag,
			DtInclusao,
			DtStatus,
			Status
		)
				
		Select 
			Tab1.IdPessoaProspect,
			Tab1.IdProspeccao as IdProspeccao,
			Tab1.StrTag as StrTag,
			@datenow as DtInclusao,
			@datenow as DtStatus,
			'INCLUIDO' as Status

		from
			(
				Select
					PessoaProspectTag.IdPessoaProspect,
					Prospeccao.id as IdProspeccao,
					min(Tag.Valor) as StrTag
				From 
					Prospeccao WITH (NOLOCK)
						inner join
					ProspeccaoTag WITH (NOLOCK) on ProspeccaoTag.IdProspeccao = Prospeccao.Id
						inner join
					Tag WITH (NOLOCK) on Tag.Valor = ProspeccaoTag.StrTag and Tag.IdContaSistema = Prospeccao.IdContaSistema and Tag.Tipo = 'TAGPROSPECT'
						inner join
					PessoaProspectTag WITH (NOLOCK) on PessoaProspectTag.IdTag = Tag.Id
				where 
					Prospeccao.Status = 'AT' and
					Prospeccao.StatusProspeccao = 'INCLUIDO' and
					Prospeccao.DtInicioProspeccao <= @datenow
				group by
					PessoaProspectTag.IdPessoaProspect,
					Prospeccao.id
			) Tab1
		where
			not exists (Select id from ProspeccaoPessoaProspect WITH (NOLOCK) where ProspeccaoPessoaProspect.idProspeccao = Tab1.idProspeccao and ProspeccaoPessoaProspect.IdPessoaProspect = Tab1.IdPessoaProspect)
	
	-- Seta a prospecção como processando
	Update 
			Prospeccao 
		set
			StatusProspeccao = 'PROCESSANDO',
			QtdProspectsTotal = (Select COUNT(id) from ProspeccaoPessoaProspect WITH (NOLOCK)  where ProspeccaoPessoaProspect.IdProspeccao = Prospeccao.Id)
		where 
			Prospeccao.Status = 'AT' and
			Prospeccao.StatusProspeccao = 'INCLUIDO' and
			Prospeccao.DtInicioProspeccao <= @datenow
					
commit;

CREATE procedure [dbo].[ProcProdutoSubstituir]
(
	@IdContaSistema as int,
	@IdUsuarioContaSistema as int,
	@IdProdutoNovo as int,
	@IdProdutoVelho as int
)
as 
	declare @datenow AS DATETIME = dbo.GetDateCustom()
	declare @ProdutoNovoExists as varchar(200)
	declare @ProdutoVelhoExists as varchar(200)
	
	set @ProdutoNovoExists = (select Produto.Nome from Produto with (nolock) where IdContaSistema = @IdContaSistema and id = @IdProdutoNovo)
	set @ProdutoVelhoExists = (select Produto.Nome from Produto with (nolock) where IdContaSistema = @IdContaSistema and id = @IdProdutoVelho)
	
	IF (dbo.IsNullOrWhiteSpace(@ProdutoNovoExists) = 0 and dbo.IsNullOrWhiteSpace(@ProdutoVelhoExists) = 0)
		BEGIN

			begin tran
				-- Muda a referência dos produtos de todas as tabelas do antigo para o novo
				Update Prospeccao set IdProduto = @IdProdutoNovo where Prospeccao.IdProduto = @IdProdutoVelho and Prospeccao.IdContaSistema = @IdContaSistema
				Update Atendimento set IdProduto = @IdProdutoNovo from Atendimento with (nolock) where Atendimento.IdProduto = @IdProdutoVelho and Atendimento.idContaSistema = @IdContaSistema
				Update ProdutoLog set IdProduto = @IdProdutoNovo where IdProduto = @IdProdutoVelho
				Update TagAtalho set IdProduto = @IdProdutoNovo where TagAtalho.IdProduto = @IdProdutoVelho and TagAtalho.IdContaSistema = @IdContaSistema
				Update OportunidadeNegocio set IdProduto = @IdProdutoNovo where IdProduto = @IdProdutoVelho
				delete ProdutoCampanha where IdProduto = @IdProdutoVelho
				Update PessoaProspectProdutoInteresse set IdProduto = @IdProdutoNovo where IdProduto = @IdProdutoVelho
				update ProdutoSub set IdProduto = @IdProdutoNovo where IdProduto = @IdProdutoVelho
				update ProdutoMarco set IdProduto = @IdProdutoNovo where IdProduto = @IdProdutoVelho
				update Interacao set IdProduto = @IdProdutoNovo where Interacao.IdContaSistema = @IdContaSistema and IdProduto = @IdProdutoVelho
				update ProdutoTag set IdProduto = @IdProdutoNovo where IdProduto = @IdProdutoVelho
				--update TabelaoAtendimento set ProdutoId = @IdProdutoNovo where ProdutoId = @IdProdutoVelho and TabelaoAtendimento.ContaSistemaId = @IdContaSistema

				-- Exclui o produto antigo
				Delete from Produto where id = @IdProdutoVelho and idContaSistema = @IdContaSistema
					
				-- Inclui um log
				Insert into ProdutoLog (idProduto, idUsuarioContaSistema, Descricao, DtInclusao) values (@IdProdutoNovo, @IdUsuarioContaSistema, 'O produto ' + @ProdutoVelhoExists + ' foi substituido por esse produto (' + @ProdutoNovoExists + '). O produto ' + @ProdutoVelhoExists + ' foi excluido do sistema.', @datenow) 
				
				-- Inclui um log
				Insert into LogAcoes 
				(
					LogAcoes.IdGuid,
					LogAcoes.DtInclusao,
					LogAcoes.EnviarEmailAdministradorAnapro,
					LogAcoes.IdContaSistema,
					LogAcoes.IdUsuarioContaSistemaExecutou,
					LogAcoes.IdUsuarioContaSistemaImpactou,
					LogAcoes.NomeMethod,
					LogAcoes.TabelaBD,
					LogAcoes.TabelaBDChave,
					LogAcoes.Texto,
					LogAcoes.Tipo,
					LogAcoes.TipoSub,
					LogAcoes.ValueNew,
					LogAcoes.ValueOld
				)
					values
				(
					NEWID(),
					@datenow,
					0,
					@IdContaSistema,
					@IdUsuarioContaSistema,
					null,
					'ProcProdutoSubstituir',
					'Produto',
					@IdProdutoVelho,
					'O produto (' + @ProdutoVelhoExists + ') foi substituido pela produto (' + @ProdutoNovoExists + '). O Produto ' + @ProdutoVelhoExists + ' foi excluido do sistema.',
					'Produto',
					'Produto_substituido',
					@ProdutoVelhoExists,
					@ProdutoNovoExists
				)
				
			commit
		END
	Else
		BEGIN
			RAISERROR ('Produto não existe.', 16, 1);
		END;

CREATE procedure [dbo].[ProcRegrasFidelizacaoAjustar] 

as

declare @dtnow datetime = dbo.getDateCustom()
-- *****************************************
-- *****************************************
-- Ajustes de fidelização
-- *****************************************
-- *****************************************

-- Se faz necessário para corrigir possíveis falhas
update
	Atendimento set Atendimento.DtInicioAtendimento = SuperEntidade.DtInclusao
from 
	Atendimento WITH (nolock)
		inner join
	SuperEntidade WITH (nolock) on SuperEntidade.Id = Atendimento.Id
where
	Atendimento.StatusAtendimento = 'ATENDIDO'
		and
	Atendimento.DtInicioAtendimento is null


-- SETA O fim de todas as fidelizações de usuários inativos
update 
	PessoaProspectFidelizado
		Set
			PessoaProspectFidelizado.DtFimFidelizacao = @dtnow
From
	PessoaProspectFidelizado WITH (nolock)
		inner join
	UsuarioContaSistema WITH (nolock) on UsuarioContaSistema.id = PessoaProspectFidelizado.IdUsuarioContaSistema
where 
	PessoaProspectFidelizado.DtFimFidelizacao is null
		and
	UsuarioContaSistema.Status = 'DE'


-- Deleta PessoaProspectFidelizado de contas sistemas desativada
delete from PessoaProspectFidelizado
from
	PessoaProspectFidelizado with (nolock)
		inner join
	PessoaProspect with (nolock) on PessoaProspect.Id = PessoaProspectFidelizado.IdPessoaProspect 
		inner join
	ContaSistema with (nolock) ON ContaSistema.Id = PessoaProspect.idContaSistema
WHERE 
	ContaSistema.Status = 'DE'


-- Seta o fim da fidelização de usuários que não possuem atendimentos
-- com a pessoaprospect em questão e para o usuário em questão
update 
	PessoaProspectFidelizado Set PessoaProspectFidelizado.DtFimFidelizacao = @dtnow
From
	PessoaProspectFidelizado with (nolock)
where 
	PessoaProspectFidelizado.DtFimFidelizacao is null
		and
	not exists
				 (	
					SELECT 
						Atendimento.ID 
					FROM 
						Atendimento WITH (NOLOCK) 
							inner join
						Campanha  WITH (NOLOCK) on Campanha.Id = Atendimento.idCampanha
					WHERE 
						Atendimento.idPessoaProspect = PessoaProspectFidelizado.IdPessoaProspect
							and
						Atendimento.IdUsuarioContaSistemaAtendimento = PessoaProspectFidelizado.IdUsuarioContaSistema
							and
						(
							Atendimento.idCampanha = PessoaProspectFidelizado.IdCampanha
								or
							(
								PessoaProspectFidelizado.IdRegraFidelizacao is not null
									and
								Campanha.IdRegraFidelizacao = PessoaProspectFidelizado.IdRegraFidelizacao
							)
						)
					)


-- Insere a fidelização para todos os atendimentos que estão sendo atendidos e não existe fidelização para o usuário
-- que está efetuando o atendimento
INSERT INTO PessoaProspectFidelizado 
	(
		IdPessoaProspect,
		IdUsuarioContaSistema,
		DtInclusao,
		DtInicioFidelizacao,
		Tipo,
		DtFimFidelizacao,
		IdCampanha,
		IdGrupo,
		IdRegraFidelizacao
	)
select 
	Atendimento.idPessoaProspect,
	Atendimento.IdUsuarioContaSistemaAtendimento,
	@dtnow,
	isnull(Atendimento.DtInicioAtendimento, SuperEntidade.DtInclusao),
	'ATENDIMENTO',
	NULL,
	Atendimento.idCampanha,
	Atendimento.idGrupo,
	Campanha.IdRegraFidelizacao
From
	Atendimento with (nolock)
		inner join
	SuperEntidade with (nolock) on Atendimento.Id = SuperEntidade.Id
		inner join
	ContaSistema with (nolock) on ContaSistema.id = Atendimento.idContaSistema and ContaSistema.Status = 'AT'
		inner join
	Campanha  with (nolock) on Campanha.id = Atendimento.idCampanha
where 
	Atendimento.IdUsuarioContaSistemaAtendimento is not null
		and
	Atendimento.StatusAtendimento = 'ATENDIDO'
		AND
	NOT EXISTS 
				(	
					SELECT 
						ID 
					FROM 
						PessoaProspectFidelizado WITH (NOLOCK) 
					WHERE 
						Atendimento.idPessoaProspect = PessoaProspectFidelizado.IdPessoaProspect
							and
						Atendimento.IdUsuarioContaSistemaAtendimento = PessoaProspectFidelizado.IdUsuarioContaSistema
							and
						PessoaProspectFidelizado.DtFimFidelizacao is null
							and
						(
							Atendimento.idCampanha = PessoaProspectFidelizado.IdCampanha
								or
							(
								PessoaProspectFidelizado.IdRegraFidelizacao is not null
									and
								Campanha.IdRegraFidelizacao = PessoaProspectFidelizado.IdRegraFidelizacao
							)
						)
				)

-- Retira o atendimento de usuários que por ventura não estão mais fidelizados mais o 
-- IdUsuarioContaSistemaAtendimento continua setado para o mesmo
begin tran
	UPDATE TOP(150)
		Atendimento SET IdUsuarioContaSistemaAtendimento = NULL
	From
		Atendimento with (nolock)
			inner join
		ContaSistema with (nolock) on ContaSistema.id = Atendimento.IdContaSistema
	where
		Atendimento.StatusAtendimento = 'ENCERRADO'
			AND
		Atendimento.IdUsuarioContaSistemaAtendimento is not null
			and
		NOT exists  (
						Select
							PessoaProspectFidelizado.Id
						from
							PessoaProspectFidelizado with (nolock)
						where
							PessoaProspectFidelizado.DtFimFidelizacao is null
								and
							PessoaProspectFidelizado.IdPessoaProspect = Atendimento.idPessoaProspect
								and
							PessoaProspectFidelizado.IdUsuarioContaSistema = Atendimento.IdUsuarioContaSistemaAtendimento
					)
commit;

CREATE procedure [dbo].[ProcRegrasFidelizacaoAplicar] 
(
	@QuantidadeDiasPadraoFidelizacao int
)

as

	declare @dateNow datetime = dbo.getdatecustom()
	declare @dateNowVarchar varchar(50) = convert(varchar(50), @dateNow, 126)
	declare @objVersaoInt int = 2019073118;
	declare @objVersaoVarchar varchar(12) = '2019073118';

	-- caso seja repassado nulo usar 31 dias como padrão
	declare @qtdDiasPadraoFidelizacao int = isnull(@QuantidadeDiasPadraoFidelizacao, 31)
	-- será usado nas datas de inclusão e finalização da fidelização
	declare @dtFimFidelizacao datetime = @dateNow
	-- data mínima, se faz necessário para não recuperar os encerrados no momento
	-- margem de segurança
	declare @dtConclusaoAtendimento datetime = DATEADD(minute, -10, @dateNow) 

	DECLARE @TableAlteracoes TABLE
	(
		IdPessoaProspectFidelizado int,
		IdAtendimento int,
		DtConclusaoAtendimento datetime,
		PessoaProspectFidelizadoId int,
		DtInicioFidelizacao datetime,
		QtdDiasFidelizacaoRegras varchar(8),
		QtdDiasFidelizadoAposEncerrado int,
		IdUsuarioContaSistema int,
		ContaSistemaId int
	);

	declare @TabAuxInteracao table(id int, idContaSistema int, idSuperEntidade int, idInteracaoTipo int)

	-- Seleciona e insere todas os atendimentos que foram encerrados e o prazo de fidelização 
	-- após o encerramento do atendimento já passou
	insert into @TableAlteracoes
			(
				IdPessoaProspectFidelizado,
				IdAtendimento,
				DtConclusaoAtendimento,
				PessoaProspectFidelizadoId,
				DtInicioFidelizacao,
				QtdDiasFidelizacaoRegras,
				QtdDiasFidelizadoAposEncerrado,
				IdUsuarioContaSistema,
				ContaSistemaId
			)
			select top 1000
				PessoaProspectFidelizado.Id as PessoaProspectFidelizadoId, 
				atendimento.Id as AtendimentoId,
				Atendimento.DtConclusaoAtendimento,
				PessoaProspectFidelizado.Id as PessoaProspectFidelizadoId,
				PessoaProspectFidelizado.DtInicioFidelizacao,
				isnull(CampanhaConfiguracao.ValorInt, @qtdDiasPadraoFidelizacao) as QtdDiasFidelizacaoRegras,
				DATEDIFF(day, Atendimento.DtConclusaoAtendimento, @dateNow) as QtdDiasFidelizadoAposEncerrado,
				PessoaProspectFidelizado.IdUsuarioContaSistema,
				atendimento.IdContaSistema as ContaSistemaId

			from 
				PessoaProspectFidelizado WITH (NOLOCK)
					inner join
				Atendimento  WITH (NOLOCK) on Atendimento.idPessoaProspect = PessoaProspectFidelizado.IdPessoaProspect and Atendimento.IdUsuarioContaSistemaAtendimento = PessoaProspectFidelizado.IdUsuarioContaSistema
					inner join
				Campanha WITH (NOLOCK) on Campanha.Id = Atendimento.idCampanha
					left outer join
				CampanhaConfiguracao with (nolock) on CampanhaConfiguracao.IdCampanha = Atendimento.idCampanha and CampanhaConfiguracao.Tipo = 'PRAZO_MANTER_FIDELIZACAO_APOS_ENCERRAMENTO'

			where
				(
					Atendimento.idCampanha = PessoaProspectFidelizado.IdCampanha
						or
					(
						Campanha.IdRegraFidelizacao is not null
							and						
						PessoaProspectFidelizado.IdRegraFidelizacao is not null
							and
						Campanha.IdRegraFidelizacao = PessoaProspectFidelizado.IdRegraFidelizacao
					)
				)
					and
				PessoaProspectFidelizado.DtFimFidelizacao is null
					and
				Atendimento.StatusAtendimento = 'ENCERRADO' 
					and
				Atendimento.DtConclusaoAtendimento < @dtConclusaoAtendimento
					and
				DATEDIFF(day, Atendimento.DtConclusaoAtendimento, @dtFimFidelizacao) >= isnull(CampanhaConfiguracao.ValorInt, @qtdDiasPadraoFidelizacao)


		-- Insere os logs nos atendimentos informando sobre a mudança
		insert 
			into Interacao 
				(
					IdContaSistema,
					IdSuperEntidade,
					IdUsuarioContaSistema,
					DtInclusao,
					DtInteracao,
					Tipo,
					IdUsuarioContaSistemaRealizou,
					IdInteracaoTipo,
					InteracaoAtorPartida,
					DtConclusao,
					Realizado,
					IdGuid,
					ObjTipo,
					ObjVersao,
					ObjTipoSub,
					TipoCriacao
				) OUTPUT inserted.Id, inserted.IdContaSistema, inserted.IdSuperEntidade, inserted.IdInteracaoTipo into @TabAuxInteracao
		Select 
			TabAux1.ContaSistemaId as IdContaSistema,
			TabAux1.IdAtendimento as IdSuperEntidade,
			null as IdUsuarioContaSistema,
			@dateNow as DtInclusao,
			@dateNow as DtInteracao,
			'INTERACAOGERAL' as Tipo,
			null as IdUsuarioContaSistemaRealizou,
			InteracaoTipo.Id as IdInteracaoTipo,
			'AUTO' as InteracaoAtorPartida,
			@dateNow as DtConclusao,
			1 as Realizado,
			NEWID() as idGuid,
			'SuperCRM.DTO.InteracaoGeral.InteracaoGeralPersistDTO' as ObjTipo,
			@objVersaoInt as ObjVersao,
			'SuperCRM.DTO.InteracaoGeral.InteracaoGeralLogDTO' as ObjTipoSub,
			'AUTO' as TipoCriacao

		From
			@TableAlteracoes TabAux1
				inner join
			InteracaoTipo with (nolock) on InteracaoTipo.IdContaSistema = TabAux1.ContaSistemaId and InteracaoTipo.Tipo = 'PROSPECTDESFIDELIZADO' AND InteracaoTipo.Sistema = 1

		insert 
			into InteracaoObj
				(
					Id,
					IdContaSistema,
					IdSuperEntidade,
					ObjTipo,
					ObjVersao,
					ObjTipoSub,
					ObjJson
				)
			Select distinct 
				TabAux.id,
				TabAux.idContaSistema,
				TabAux.idSuperEntidade,
				'SuperCRM.DTO.InteracaoGeral.InteracaoGeralPersistDTO' as ObjTipo,
				@objVersaoInt as ObjVersao,
				'SuperCRM.DTO.InteracaoGeral.InteracaoGeralLogDTO' as ObjTipoSub,
				N'{"Type":"SuperCRM.DTO.InteracaoGeral.InteracaoGeralPersistDTO",
				"Texto":"",
				"Versao":'+@objVersaoVarchar+',
				"VersaoObj":'+@objVersaoVarchar+',"InteracaoTipoSys":"LOG","ObjType":"SuperCRM.DTO.InteracaoGeral.InteracaoGeralLogDTO","Obj":{"$type":"SuperCRM.DTO.InteracaoGeral.InteracaoGeralLogDTO, SuperCRM",
				"AtorPartida":"AUTO",
				"LogTipo":"PROSPECT_DESFIDELIZACAO",
				"Texto":"'+STRING_ESCAPE('A fidelização do PROSPECT desse atendimento foi REMOVIDA do usuário ('+ Pessoa.Nome +') automaticamente pelo sistema após ('+ cast(TabAux1.QtdDiasFidelizadoAposEncerrado as varchar(10)) +') dia(s) do encerramento ('+ CONVERT(varchar(10), TabAux1.DtConclusaoAtendimento, 103)  +' ' + CONVERT(varchar(10), TabAux1.DtConclusaoAtendimento, 108) + ') desse atendimento de acordo com as regras aplicadas de ('+ TabAux1.QtdDiasFidelizacaoRegras +') dia(s).','json')+'",
				"IdUsuarioContaSistema":null,
				"VariaveisTipadas":{},
				"Variaveis":{},
				"DtMigracao":null,
				"Versao":'+@objVersaoVarchar+',
				"InteracaoTipoId":'+convert(varchar(15), TabAux.idInteracaoTipo)+',
				"InteracaoTipoIdGuid":null,
				"Tipo":"LOG",
				"DtInclusao":"'+@dateNowVarchar+'",
				"TextoAutomatico":false,
				"IdContaSistema":'+convert(varchar(15),UsuarioContaSistema.IdContaSistema)+',
				"IdSuperEntidade":'+convert(varchar(15),TabAux1.IdAtendimento)+',
				"TipoCriacao":"AUTO"}}' as ObjJson

			From
				@TabAuxInteracao TabAux
					inner join
				@TableAlteracoes TabAux1 on TabAux1.IdAtendimento = TabAux.idSuperEntidade
					inner join
				UsuarioContaSistema with (nolock) on TabAux1.IdUsuarioContaSistema = UsuarioContaSistema.Id
					inner join
				Pessoa with (nolock) on Pessoa.Id = UsuarioContaSistema.IdPessoa


		-- Atualiza a data fim da fidelização dos usuários em questão
		update 
			PessoaProspectFidelizado
				Set PessoaProspectFidelizado.DtFimFidelizacao = @dtFimFidelizacao
		where
			PessoaProspectFidelizado.Id in (select TabAux1.PessoaProspectFidelizadoId from @TableAlteracoes TabAux1)


		-- a partir de 13/05/2019 quando retirado a fidelização do usuário também retirará o usuário do atendimento
		update 
			atendimento
				Set atendimento.IdUsuarioContaSistemaAtendimento = null
			where
				atendimento.id in (Select TabAux.IdAtendimento from @TableAlteracoes TabAux);

CREATE procedure [dbo].[ProcRelatorioFichaDePesquisa] 
(
	@IdContaSistema as int,
	@IsAdministradorDoSistema as bit,
	@IdUsuarioContaSistemaExecutando int,
	@IdUsuarioContaSistemaPreencheu int,
	@IdUsuarioContaSistemaAtendeu int,
	@IdFichaPesquisa int,
	@DtInclusaoRespostaInicio datetime,
	@DtInclusaoRespostaFim datetime,
	@IdCampanha int,
	@IdCanal int,
	@IdProduto int,
	@IdPessoaProspect int,
	@IdAtendimento int,
	@DtAtendimentoInclusaoInicio datetime,
	@DtAtendimentoInclusaoFim datetime,
	@DtAtendimentoConclusaoInicio datetime,
	@DtAtendimentoConclusaoFim datetime,
	@UF varchar(2),
	@AtendimentoStatus varchar(50),
	@FichaPesquisaTipo varchar(50)
)
as

-- Cria a tebela temporaria com o objetivo de inserir o resultado analítico na mesma para que possa ser agrupado posteriormente
declare @temp Table
(
	TipoPergunta varchar(1000),
	TipoGrafico varchar(1000),
	IdPergunta int,
	IdResposta int,
	IdGuidPergunta char(36),
	IdGuidResposta char(36),
	PerguntaDescricao  varchar(1000),
	RespostaTextoResposta varchar(1000),
	AtendimentoId int
)

-- Cria a tabela temporária com o resultado esperado
declare @temp2 Table
(
	TipoPergunta varchar(1000),
	TipoGrafico varchar(1000),
	IdPergunta int,
	IdResposta int,
	IdGuidPergunta char(36),
	IdGuidResposta char(36),
	PerguntaDescricao  varchar(1000),
	RespostaTextoResposta varchar(1000),
	Total int,
	TotalAtendimentoPerguntaRespondido int
)

-- Insere na tabela temporária o resultado da pesquisa de forma analítica
insert into @temp
Select
	Pergunta.Tipo as TipoPergunta,
	Pergunta.TipoGrafico,
	RespostaFichaPesquisa.IdPergunta AS IdPergunta,
	RespostaFichaPesquisaResposta.IdResposta,
	Pergunta.idGuid AS IdGuidPergunta,
	Resposta.IdGuid as IdGuidResposta,
	Pergunta.Descricao as PerguntaDescricao,
	Resposta.TextoResposta as RespostaTextoResposta,
	TabelaoAtendimento.AtendimentoId as AtendimentoId
From
	RespostaFichaPesquisa WITH (NOLOCK)
		inner join
	RespostaFichaPesquisaResposta WITH (NOLOCK) on RespostaFichaPesquisaResposta.IdRespostaFichaPesquisa = RespostaFichaPesquisa.Id
		inner join
	Pergunta WITH (NOLOCK) on Pergunta.Id = RespostaFichaPesquisa.IdPergunta
		inner join
	FichaPesquisa WITH (NOLOCK)  on FichaPesquisa.Id = Pergunta.IdFichaPesquisa
		inner join 
	Resposta WITH (NOLOCK) on Resposta.Id = RespostaFichaPesquisaResposta.IdResposta
		LEFT OUTER JOIN
	TabelaoAtendimento WITH (NOLOCK) on TabelaoAtendimento.AtendimentoId = RespostaFichaPesquisa.IdAtendimento
		left outer join 
	-- Seleciona para verificar se o usuario que esta executando e adm da campanha, caso seja o mesmo podera visualizar os registros
	CampanhaAdministrador WITH (NOLOCK) on (@IsAdministradorDoSistema = 0 and CampanhaAdministrador.idCampanha = TabelaoAtendimento.CampanhaId and CampanhaAdministrador.idUsuarioContaSistema = @IdUsuarioContaSistemaExecutando)
		left outer join
	-- se ele é adm e n quer listar somente os atendimentos dele n se faz necessario executar essa pesquisa
	PessoaProspectFidelizado WITH (NOLOCK) on (@IsAdministradorDoSistema = 0 and PessoaProspectFidelizado.IdPessoaProspect = TabelaoAtendimento.PessoaProspectId and PessoaProspectFidelizado.IdCampanha = TabelaoAtendimento.CampanhaId and PessoaProspectFidelizado.DtFimFidelizacao is null)
		left outer join
	-- Selecionará todos grupos inferiores que por ventura o usuário em questão seja administrador e o prospect esteja fidelizado a algum usuario pertencente a esse grupo
	GrupoHierarquiaUsuarioContaSistema WITH (NOLOCK) on (@IsAdministradorDoSistema = 0 and GrupoHierarquiaUsuarioContaSistema.idContaSistema = @IdContaSistema and GrupoHierarquiaUsuarioContaSistema.idUsuarioContaSistema = @IdUsuarioContaSistemaExecutando and GrupoHierarquiaUsuarioContaSistema.IdGrupo = PessoaProspectFidelizado.IdGrupo)
Where
	TabelaoAtendimento.ContaSistemaId = @IdContaSistema
		and
	(
		-- caso seja administrador do sistema não irá considerar a hierarquia de grupos
		@IsAdministradorDoSistema = 1
			or
		-- caso seja administraodr da campanha todos os atendimentos da mesmo o usuário poderá ver
		CampanhaAdministrador.Id is not null
			or
		-- Caso o usuário seja administrador do grupo a qual o prospect encontra-se fidelizado
		GrupoHierarquiaUsuarioContaSistema.Id is not null
			or
		-- O usuário detem a fidelização do prospect
		PessoaProspectFidelizado.IdUsuarioContaSistema = @IdUsuarioContaSistemaExecutando
			or
		-- Usuário não está fidelizado a ninguém e o atendimento está para o prospect, nesse caso provavelmente aguardando para ser atendido
		(PessoaProspectFidelizado.Id is null and TabelaoAtendimento.UsuarioContaSistemaId = @IdUsuarioContaSistemaExecutando)
	)	
		and
	(
		 @IdUsuarioContaSistemaPreencheu is null or RespostaFichaPesquisaResposta.IdUsuarioContaSistema = @IdUsuarioContaSistemaPreencheu
	)
		and
	(
		 @IdUsuarioContaSistemaAtendeu is null or TabelaoAtendimento.UsuarioContaSistemaId = @IdUsuarioContaSistemaAtendeu
	)
		and
	(
		@IdFichaPesquisa is null or RespostaFichaPesquisa.IdFichaPesquisa = @IdFichaPesquisa
	)
		and
	(
		@DtInclusaoRespostaInicio is null or RespostaFichaPesquisaResposta.DtInclusao >= @DtInclusaoRespostaInicio
	)
		and
	(
		@DtInclusaoRespostaFim is null or RespostaFichaPesquisaResposta.DtInclusao <= @DtInclusaoRespostaFim
	)	
		and
	(
		@IdCampanha is null or TabelaoAtendimento.CampanhaId = @IdCampanha
	)	
		and
	(
		@IdCanal is null or TabelaoAtendimento.CanalId = @IdCanal
	)
		and
	(
		@IdProduto is null or TabelaoAtendimento.ProdutoId = @IdProduto
	)
		and
	(
		@DtAtendimentoInclusaoInicio is null or TabelaoAtendimento.AtendimentoDtInclusao >= @DtAtendimentoInclusaoInicio
	)
		and
	(
		@DtAtendimentoInclusaoFim is null or TabelaoAtendimento.AtendimentoDtInclusao <= @DtAtendimentoInclusaoFim
	)
		and
	(
		@DtAtendimentoConclusaoInicio is null or TabelaoAtendimento.AtendimentoDtConclusao >= @DtAtendimentoConclusaoInicio
	)
		and
	(
		@DtAtendimentoConclusaoFim is null or TabelaoAtendimento.AtendimentoDtConclusao <= @DtAtendimentoConclusaoFim
	)
		and
	(
		@IdAtendimento is null or TabelaoAtendimento.AtendimentoId = @IdAtendimento
	)	
		and
	(
		@IdPessoaProspect is null or TabelaoAtendimento.PessoaProspectId = @IdPessoaProspect
	)		
		and
	(
		dbo.IsNullOrWhiteSpace(@UF) = 1 or TabelaoAtendimento.ProdutoUF = @UF
	)
		and
	(
		dbo.IsNullOrWhiteSpace(@AtendimentoStatus) = 1 or TabelaoAtendimento.AtendimentoStatus = @AtendimentoStatus
	)
		and
	(
		dbo.IsNullOrWhiteSpace(@FichaPesquisaTipo) = 1 or RespostaFichaPesquisa.FichaPesquisaTipo = @FichaPesquisaTipo
	)

-- Insere na tabela temporária de retorno o valor analítico agrupado por resposta	
insert 
	into 
		@temp2
		
	select 
		TipoPergunta,
		TipoGrafico,
		IdPergunta,
		IdResposta,
		IdGuidPergunta,
		IdGuidResposta,
		PerguntaDescricao,
		RespostaTextoResposta,
		COUNT(IdPergunta) as Total,
		1
	from
		@temp
	Group by
		TipoPergunta,
		TipoGrafico,
		IdPergunta,
		IdResposta,
		IdGuidPergunta,
		IdGuidResposta,
		PerguntaDescricao,
		RespostaTextoResposta
	Order by
		IdPergunta,
		IdResposta

-- atualiza a tabela temporária agrupando a quantidade de atendimentos respondido por pergunta
update
	@temp2
set
	TotalAtendimentoPerguntaRespondido = (Select COUNT(distinct AtendimentoId) from @temp A where A.IdPergunta = IdPergunta) 

select * from @temp2;

CREATE procedure [dbo].[ProcRelatorioFichaDePesquisaAnalitico] 
(
	@IdContaSistema as int,
	@IsAdministradorDoSistema as bit,
	@IdUsuarioContaSistemaExecutando int,
	@IdUsuarioContaSistemaPreencheu int,
	@IdUsuarioContaSistemaAtendeu int,
	@IdFichaPesquisa int,
	@DtInclusaoRespostaInicio datetime,
	@DtInclusaoRespostaFim datetime,
	@IdCampanha int,
	@IdCanal int,
	@IdProduto int,
	@IdPessoaProspect int,
	@IdAtendimento int,
	@DtAtendimentoInclusaoInicio datetime,
	@DtAtendimentoInclusaoFim datetime,
	@DtAtendimentoConclusaoInicio datetime,
	@DtAtendimentoConclusaoFim datetime,
	@UF varchar(2),
	@AtendimentoStatus varchar(50),
	@FichaPesquisaTipo varchar(50)
)
as

-- Seta para evitar que sejam localizado string vazia, quando vazia setara null
set @AtendimentoStatus = dbo.RetNullOrVarChar(@AtendimentoStatus)
set @FichaPesquisaTipo = dbo.RetNullOrVarChar(@FichaPesquisaTipo)

Select
	Pergunta.Descricao as Pergunta,
	dbo.GetFichaPesquisaRespostaList(RespostaFichaPesquisa.Id) as Respostas,
	RespostaFichaPesquisa.FichaPesquisaTipo,
	TabelaoAtendimento.*


From
	FichaPesquisa WITH (NOLOCK)
		inner join
	Pergunta WITH (NOLOCK) on Pergunta.IdFichaPesquisa = FichaPesquisa.Id
		inner join
	RespostaFichaPesquisa WITH (NOLOCK) on RespostaFichaPesquisa.IdFichaPesquisa = FichaPesquisa.Id and RespostaFichaPesquisa.IdPergunta = Pergunta.Id
		left outer join
	TabelaoAtendimento WITH (NOLOCK) on TabelaoAtendimento.AtendimentoId = RespostaFichaPesquisa.IdAtendimento
		left outer join 
	-- Seleciona para verificar se o usuario que esta executando e adm da campanha, caso seja o mesmo podera visualizar os registros
	CampanhaAdministrador WITH (NOLOCK) on (@IsAdministradorDoSistema = 0 and CampanhaAdministrador.idCampanha = TabelaoAtendimento.CampanhaId and CampanhaAdministrador.idUsuarioContaSistema = @IdUsuarioContaSistemaExecutando)
		left outer join
	-- se ele é adm e n quer listar somente os atendimentos dele n se faz necessario executar essa pesquisa
	PessoaProspectFidelizado WITH (NOLOCK) on (@IsAdministradorDoSistema = 0 and PessoaProspectFidelizado.IdPessoaProspect = TabelaoAtendimento.PessoaProspectId and PessoaProspectFidelizado.IdCampanha = TabelaoAtendimento.CampanhaId and PessoaProspectFidelizado.DtFimFidelizacao is null)
		left outer join
	-- Selecionará todos grupos inferiores que por ventura o usuário em questão seja administrador e o prospect esteja fidelizado a algum usuario pertencente a esse grupo
	GrupoHierarquiaUsuarioContaSistema WITH (NOLOCK) on (@IsAdministradorDoSistema = 0 and GrupoHierarquiaUsuarioContaSistema.idContaSistema = @IdContaSistema and GrupoHierarquiaUsuarioContaSistema.idUsuarioContaSistema = @IdUsuarioContaSistemaExecutando and GrupoHierarquiaUsuarioContaSistema.IdGrupo = PessoaProspectFidelizado.IdGrupo)

Where
	FichaPesquisa.IdContaSistema = @IdContaSistema
		and
	(
		-- caso seja administrador do sistema não irá considerar a hierarquia de grupos
		@IsAdministradorDoSistema = 1
			or
		-- caso seja administraodr da campanha todos os atendimentos da mesmo o usuário poderá ver
		CampanhaAdministrador.Id is not null
			or
		-- Caso o usuário seja administrador do grupo a qual o prospect encontra-se fidelizado
		GrupoHierarquiaUsuarioContaSistema.Id is not null
			or
		-- O usuário detem a fidelização do prospect
		PessoaProspectFidelizado.IdUsuarioContaSistema = @IdUsuarioContaSistemaExecutando
			or
		-- Usuário não está fidelizado a ninguém e o atendimento está para o prospect, nesse caso provavelmente aguardando para ser atendido
		(PessoaProspectFidelizado.Id is null and TabelaoAtendimento.UsuarioContaSistemaId = @IdUsuarioContaSistemaExecutando)
	)	
		and
	(
		 @IdUsuarioContaSistemaAtendeu is null or TabelaoAtendimento.UsuarioContaSistemaId = @IdUsuarioContaSistemaAtendeu
	)
		and
	(
		@IdFichaPesquisa is null or RespostaFichaPesquisa.IdFichaPesquisa = @IdFichaPesquisa
	)
		and
	(
		@IdCampanha is null or TabelaoAtendimento.CampanhaId = @IdCampanha
	)	
		and
	(
		@IdCanal is null or TabelaoAtendimento.CanalId = @IdCanal
	)
		and
	(
		@IdProduto is null or TabelaoAtendimento.ProdutoId = @IdProduto
	)
		and
	(
		@DtAtendimentoInclusaoInicio is null or TabelaoAtendimento.AtendimentoDtInclusao >= @DtAtendimentoInclusaoInicio
	)
		and
	(
		@DtAtendimentoInclusaoFim is null or TabelaoAtendimento.AtendimentoDtInclusao<= @DtAtendimentoInclusaoFim
	)
		and
	(
		@DtAtendimentoConclusaoInicio is null or TabelaoAtendimento.AtendimentoDtConclusao >= @DtAtendimentoConclusaoInicio
	)
		and
	(
		@DtAtendimentoConclusaoFim is null or TabelaoAtendimento.AtendimentoDtConclusao<= @DtAtendimentoConclusaoFim
	)
		and
	(
		@IdAtendimento is null or TabelaoAtendimento.AtendimentoId = @IdAtendimento
	)	
		and
	(
		@IdPessoaProspect is null or TabelaoAtendimento.PessoaProspectId = @IdPessoaProspect
	)		
		and
	(
		@AtendimentoStatus is null or TabelaoAtendimento.AtendimentoStatus = @AtendimentoStatus
	)
		and
	(
		@FichaPesquisaTipo is null or RespostaFichaPesquisa.FichaPesquisaTipo = @FichaPesquisaTipo
	)
		and
	(
		(
			@DtInclusaoRespostaInicio is null and 
			@DtInclusaoRespostaFim is null
		)
			or
		(
			RespostaFichaPesquisa.id in 
										(
											Select RespostaFichaPesquisaResposta.IdRespostaFichaPesquisa
											from RespostaFichaPesquisaResposta with (nolock) 
											where 
												RespostaFichaPesquisaResposta.IdRespostaFichaPesquisa = RespostaFichaPesquisa.Id
													and
												(
													(
														@DtInclusaoRespostaInicio is null or RespostaFichaPesquisaResposta.DtInclusao >= @DtInclusaoRespostaInicio
													)
														and
													(
														@DtInclusaoRespostaFim is null or RespostaFichaPesquisaResposta.DtInclusao <= @DtInclusaoRespostaFim
													)
												)
										)
		)
	)

order by
	TabelaoAtendimento.AtendimentoId

-- http://www.sommarskog.se/dyn-search.html
OPTION (RECOMPILE);

CREATE procedure [dbo].[ProcRelatorioFichaDePesquisaGroup] 
(
	@IdContaSistema as int,
	@IsAdministradorDoSistema as bit,
	@IdUsuarioContaSistemaExecutando int,
	@IdUsuarioContaSistemaPreencheu int,
	@IdUsuarioContaSistemaAtendeu int,
	@IdFichaPesquisa int,
	@DtInclusaoRespostaInicio date,
	@DtInclusaoRespostaFim date,
	@IdCampanha int,
	@IdCanal int,
	@IdProduto int,
	@IdPessoaProspect int,
	@IdAtendimento int,
	@DtAtendimentoInclusaoInicio date,
	@DtAtendimentoInclusaoFim date,
	@DtAtendimentoConclusaoInicio date,
	@DtAtendimentoConclusaoFim date,
	@UF varchar(2),
	@AtendimentoStatus varchar(50),
	@FichaPesquisaTipo varchar(50)
)
as

Select
	TabelaoAtendimento.PessoaId as PessoaID,
	TabelaoAtendimento.CampanhaId as CampanhaID,
	TabelaoAtendimento.ProdutoId as ProdutoID,
	TabelaoAtendimento.ProdutoUF as ProdutoUF,
	Pergunta.Id AS PerguntaID,
	
	TabelaoAtendimento.PessoaNome as NomePessoa,
	TabelaoAtendimento.CampanhaNome as CampanhaNome,
	TabelaoAtendimento.ProdutoNome as ProdutoNome,
	Pergunta.Descricao as PerguntaDescricao,
	TabelaoAtendimento.GrupoNome as GrupoNome,
	DATEADD(month, DATEDIFF(month, 0, RespostaFichaPesquisaResposta.DtInclusao), 0) as DtRespondido,
	
	AVG(Resposta.peso) as MediaPesoRespostas,
	COUNT(RespostaFichaPesquisaResposta.id) as QtdRespostas	
	
From
	RespostaFichaPesquisa WITH (NOLOCK)
		inner join
	RespostaFichaPesquisaResposta WITH (NOLOCK) on RespostaFichaPesquisaResposta.IdRespostaFichaPesquisa = RespostaFichaPesquisa.Id
		inner join
	Pergunta WITH (NOLOCK) on Pergunta.Id = RespostaFichaPesquisa.IdPergunta
		inner join
	Resposta WITH (NOLOCK) on Resposta.Id = RespostaFichaPesquisaResposta.IdResposta
		LEFT OUTER JOIN
	TabelaoAtendimento WITH (NOLOCK) on TabelaoAtendimento.AtendimentoId = RespostaFichaPesquisa.IdAtendimento
		left outer join 
	-- Seleciona para verificar se o usuario que esta executando e adm da campanha, caso seja o mesmo podera visualizar os registros
	CampanhaAdministrador WITH (NOLOCK) on (@IsAdministradorDoSistema = 0 and CampanhaAdministrador.idCampanha = TabelaoAtendimento.CampanhaId and CampanhaAdministrador.idUsuarioContaSistema = @IdUsuarioContaSistemaExecutando)
		left outer join
	-- se ele é adm e n quer listar somente os atendimentos dele n se faz necessario executar essa pesquisa
	PessoaProspectFidelizado WITH (NOLOCK) on (@IsAdministradorDoSistema = 0 and PessoaProspectFidelizado.IdPessoaProspect = TabelaoAtendimento.PessoaProspectId and PessoaProspectFidelizado.IdCampanha = TabelaoAtendimento.CampanhaId and PessoaProspectFidelizado.DtFimFidelizacao is null)
		left outer join
	-- Selecionará todos grupos inferiores que por ventura o usuário em questão seja administrador e o prospect esteja fidelizado a algum usuario pertencente a esse grupo
	GrupoHierarquiaUsuarioContaSistema WITH (NOLOCK) on (@IsAdministradorDoSistema = 0 and GrupoHierarquiaUsuarioContaSistema.idContaSistema = @IdContaSistema and GrupoHierarquiaUsuarioContaSistema.idUsuarioContaSistema = @IdUsuarioContaSistemaExecutando and GrupoHierarquiaUsuarioContaSistema.IdGrupo = PessoaProspectFidelizado.IdGrupo)
Where
	TabelaoAtendimento.ContaSistemaId = @IdContaSistema
		and
	(
		@IsAdministradorDoSistema = 1
		or
		-- caso seja administrador do sistema não irá considerar a hierarquia de grupos
		@IsAdministradorDoSistema = 1
			or
		-- caso seja administraodr da campanha todos os atendimentos da mesmo o usuário poderá ver
		CampanhaAdministrador.Id is not null
			or
		-- Caso o usuário seja administrador do grupo a qual o prospect encontra-se fidelizado
		GrupoHierarquiaUsuarioContaSistema.Id is not null
			or
		-- O usuário detem a fidelização do prospect
		PessoaProspectFidelizado.IdUsuarioContaSistema = @IdUsuarioContaSistemaExecutando
			or
		-- Usuário não está fidelizado a ninguém e o atendimento está para o prospect, nesse caso provavelmente aguardando para ser atendido
		(PessoaProspectFidelizado.Id is null and TabelaoAtendimento.UsuarioContaSistemaId = @IdUsuarioContaSistemaExecutando)
	)	
		and
	(
		 @IdUsuarioContaSistemaPreencheu is null or RespostaFichaPesquisaResposta.IdUsuarioContaSistema = @IdUsuarioContaSistemaPreencheu
	)
		and
	(
		 @IdUsuarioContaSistemaAtendeu is null or TabelaoAtendimento.UsuarioContaSistemaId = @IdUsuarioContaSistemaAtendeu
	)
		and
	(
		@IdFichaPesquisa is null or RespostaFichaPesquisa.IdFichaPesquisa = @IdFichaPesquisa
	)
		and
	(
		@DtInclusaoRespostaInicio is null or RespostaFichaPesquisaResposta.DtInclusao >= @DtInclusaoRespostaInicio
	)
		and
	(
		@DtInclusaoRespostaFim is null or RespostaFichaPesquisaResposta.DtInclusao <= @DtInclusaoRespostaFim
	)	
		and
	(
		@IdCampanha is null or TabelaoAtendimento.CampanhaId = @IdCampanha
	)	
		and
	(
		@IdCanal is null or TabelaoAtendimento.CanalId = @IdCanal
	)
		and
	(
		@IdProduto is null or TabelaoAtendimento.ProdutoId = @IdProduto
	)
		and
	(
		@DtAtendimentoInclusaoInicio is null or TabelaoAtendimento.AtendimentoDtInclusao >= @DtAtendimentoInclusaoInicio
	)
		and
	(
		@DtAtendimentoInclusaoFim is null or TabelaoAtendimento.AtendimentoDtInclusao <= @DtAtendimentoInclusaoFim
	)
		and
	(
		@DtAtendimentoConclusaoInicio is null or TabelaoAtendimento.AtendimentoDtConclusao >= @DtAtendimentoConclusaoInicio
	)
		and
	(
		@DtAtendimentoConclusaoFim is null or TabelaoAtendimento.AtendimentoDtConclusao <= @DtAtendimentoConclusaoFim
	)
		and
	(
		@IdAtendimento is null or TabelaoAtendimento.AtendimentoId = @IdAtendimento
	)	
		and
	(
		@IdPessoaProspect is null or TabelaoAtendimento.PessoaProspectId = @IdPessoaProspect
	)		
		and
	(
		dbo.IsNullOrWhiteSpace(@AtendimentoStatus) = 1 or TabelaoAtendimento.AtendimentoStatus = @AtendimentoStatus
	)
		and
	(
		dbo.IsNullOrWhiteSpace(@FichaPesquisaTipo) = 1 or exists (Select id from FichaPesquisaTipo WITH (NOLOCK) where Tipo = @FichaPesquisaTipo and IdFichaPesquisa = RespostaFichaPesquisa.IdFichaPesquisa)
	)

GROUP BY
	TabelaoAtendimento.PessoaId,
	TabelaoAtendimento.CampanhaId,
	TabelaoAtendimento.ProdutoId,
	TabelaoAtendimento.ProdutoUF,
	Pergunta.Id,
	
	TabelaoAtendimento.PessoaNome,
	TabelaoAtendimento.CampanhaNome,
	TabelaoAtendimento.ProdutoNome,
	Pergunta.Descricao,
	TabelaoAtendimento.GrupoNome,
	DATEADD(month, DATEDIFF(month, 0, RespostaFichaPesquisaResposta.DtInclusao), 0);

CREATE procedure [dbo].[ProcRelatorioOportunidadePorAtendimentoConversao]
 @IdContaSistema as int,
 @IsAdministradorDoSistema as bit,
 @IdUsuarioContaSistemaExecutando int,
 @IdUsuarioContaSistemaFiltrado int,
 @IdCampanha int,
 @IdCanal int,
 @CanalMeio varchar(20),
 @idOportunidadeNegocioTipo int,
 @DtOportunidadeInicio datetime,
 @DtOportunidadeFim datetime,
 @DtAtendimentoInicio datetime,
 @DtAtendimentoFim datetime,
 @DtAtendimentoInclusaoInicio datetime,
 @DtAtendimentoInclusaoFim datetime,
 @AtendimentoStatus varchar(50),
 @AtendimentoCodigo int,
 @ProdutoUF varchar(2),
 @ProdutoId int,
 @ProdutoSubId int,
 @TipoConversao varchar(30),
 @ProspectHashTag  varchar(max),
 @ProspeccaoId int
 
 as 


set @CanalMeio = dbo.RetNullOrVarChar(@CanalMeio)
set @AtendimentoStatus = dbo.RetNullOrVarChar(@AtendimentoStatus)
set @ProdutoUF = dbo.RetNullOrVarChar(@ProdutoUF)
set @TipoConversao = dbo.RetNullOrVarChar(@TipoConversao)
set @ProspectHashTag = dbo.RetNullOrVarChar(@ProspectHashTag)

declare @TableHash table(
	Valor varchar(max)
);

-- irá inserir na tabela as hashs pesquisadas
insert into @TableHash (Valor) select TableTag.OrderID from dbo.SplitIDstring(@ProspectHashTag) TableTag;	

begin

	Select
		TabelaoAtendimento.*
	From
		TabelaoAtendimento  WITH (NOLOCK)
			left outer join
		---- Seleciona para verificar se o usuario que esta executando e adm da campanha, caso seja o mesmo podera visualizar os registros
		CampanhaAdministrador WITH (NOLOCK) on (@IsAdministradorDoSistema = 0 and CampanhaAdministrador.idCampanha = TabelaoAtendimento.CampanhaId and CampanhaAdministrador.idUsuarioContaSistema = @IdUsuarioContaSistemaExecutando)
			left outer join
		PessoaProspectFidelizado WITH (NOLOCK) on (@IsAdministradorDoSistema = 0 and PessoaProspectFidelizado.IdPessoaProspect = TabelaoAtendimento.PessoaProspectId and PessoaProspectFidelizado.IdCampanha = TabelaoAtendimento.CampanhaId and PessoaProspectFidelizado.DtFimFidelizacao is null)
		--	left outer join
		-- Selecionará todos grupos inferiores que por ventura o usuário em questão seja administrador e o prospect esteja fidelizado a algum usuario pertencente a esse grupo
		-- GrupoHierarquiaUsuarioContaSistema WITH (NOLOCK) on (@IsAdministradorDoSistema = 0 and GrupoHierarquiaUsuarioContaSistema.idContaSistema = @IdContaSistema and GrupoHierarquiaUsuarioContaSistema.idUsuarioContaSistema = @IdUsuarioContaSistemaExecutando and (GrupoHierarquiaUsuarioContaSistema.IdGrupo = PessoaProspectFidelizado.IdGrupo or GrupoHierarquiaUsuarioContaSistema.IdGrupo = TabelaoAtendimento.GrupoId))
	where
		TabelaoAtendimento.ContaSistemaId = @IdContaSistema

			and
		(
			-- caso seja administrador do sistema não irá considerar a hierarquia de grupos
			@IsAdministradorDoSistema = 1
				or

			-- caso seja administraodr da campanha todos os atendimentos da mesmo o usuário poderá ver
			CampanhaAdministrador.Id is not null
				or

			-- O usuário detem a fidelização do prospect
			PessoaProspectFidelizado.IdUsuarioContaSistema = @IdUsuarioContaSistemaExecutando
				or
			-- Usuário não está fidelizado a ninguém e o atendimento está para o prospect, nesse caso provavelmente aguardando para ser atendido
			(PessoaProspectFidelizado.Id is null and TabelaoAtendimento.UsuarioContaSistemaId = @IdUsuarioContaSistemaExecutando)
	
				or

			exists (Select GrupoHierarquiaUsuarioContaSistema.id from GrupoHierarquiaUsuarioContaSistema WITH (NOLOCK) where GrupoHierarquiaUsuarioContaSistema.idUsuarioContaSistema = @IdUsuarioContaSistemaExecutando and (GrupoHierarquiaUsuarioContaSistema.IdGrupo = PessoaProspectFidelizado.IdGrupo or GrupoHierarquiaUsuarioContaSistema.IdGrupo = TabelaoAtendimento.GrupoId))
		)

			and
		(
			@DtAtendimentoInicio is null or TabelaoAtendimento.AtendimentoDtInicio >= @DtAtendimentoInicio
		)	
			and
		(
			@DtAtendimentoFim is null or TabelaoAtendimento.AtendimentoDtInicio <= @DtAtendimentoFim
		)
			and
		(
			@DtAtendimentoInclusaoInicio is null or TabelaoAtendimento.AtendimentoDtInclusao >= @DtAtendimentoInclusaoInicio
		)	
			and
		(
			@DtAtendimentoInclusaoFim is null or TabelaoAtendimento.AtendimentoDtInclusao <= @DtAtendimentoInclusaoFim
		)
			and
		(
			@AtendimentoStatus is null or TabelaoAtendimento.AtendimentoStatus = @AtendimentoStatus
		)
			and
		(
			@AtendimentoCodigo is null or TabelaoAtendimento.AtendimentoId = @AtendimentoCodigo
		) 					
			and
		(
			@IdUsuarioContaSistemaFiltrado is null or TabelaoAtendimento.UsuarioContaSistemaId = @IdUsuarioContaSistemaFiltrado
		)
			and
		(
			@ProdutoId is null or TabelaoAtendimento.ProdutoId = @ProdutoId
		)
			and
		(
			@ProdutoSubId is null or exists (Select id from AtendimentoSubProduto  WITH (NOLOCK)  where AtendimentoSubProduto.IdAtendimento = TabelaoAtendimento.AtendimentoId and AtendimentoSubProduto.IdProdutoSub = @ProdutoSubId)
		)		
			and
		(
			@ProdutoUF is null or TabelaoAtendimento.ProdutoUF = @ProdutoUF
		)
			and
		(
			@IdCampanha is null or TabelaoAtendimento.CampanhaId = @IdCampanha
		)
			and
		(
			@IdCanal is null or TabelaoAtendimento.CanalId = @IdCanal
		)
			and
		(
			@CanalMeio is null or TabelaoAtendimento.CanalMeio = @CanalMeio
		)
			and
		(
			@ProspectHashTag is null or exists (Select PessoaProspectTag.IdTag from PessoaProspectTag  WITH (NOLOCK) INNER JOIN Tag WITH (NOLOCK) ON PessoaProspectTag.IdTag = Tag.Id inner join @TableHash TableHash on TableHash.Valor = Tag.Valor where PessoaProspectTag.IdPessoaProspect = TabelaoAtendimento.PessoaProspectId)		
		)
			and
		(
			@ProspeccaoId is null or TabelaoAtendimento.ProspeccaoId = @ProspeccaoId
		)


	-- http://www.sommarskog.se/dyn-search.html
	OPTION (RECOMPILE);
end;

CREATE procedure [dbo].[ProcSetPendenciaProcessamentoProcessar]
(
	@json varchar(max)
)
 as 
begin

declare @dtNow datetime = dbo.GetDateCustomNoMilleseconds()

-- { IdUsuarioContaSistema = t.IdUsuarioContaSistema, MenorDtPreProcessado = t.MenorDtPreProcessado, MaiorDtPreProcessado = t.MaiorDtPreProcessado }
SELECT *
	into #TabAux  
FROM OPENJSON(@json)  
  WITH (
			IdUsuarioContaSistema int '$.IdUsuarioContaSistema',
			MenorId int '$.MenorId',
			MaiorId int '$.MaiorId',
			MenorDtPreProcessado datetime '$.MenorDtPreProcessado',
			MaiorDtPreProcessado datetime '$.MaiorDtPreProcessado'
		)  

update 
	PendenciaProcessamento
		set
			PendenciaProcessamento.DtUltimaAtualizacao =  @dtNow,
			PendenciaProcessamento.DtProcessado = isnull(PendenciaProcessamento.DtProcessado, @dtNow),
			PendenciaProcessamento.DtAvisado = @dtNow,
			PendenciaProcessamento.PreProcessado = 1,
			PendenciaProcessamento.Processado = 1,
			PendenciaProcessamento.Finalizado = 1,
			PendenciaProcessamento.Status = 'PROCESSADO',
			PendenciaProcessamento.QtdAtualizacao = PendenciaProcessamento.QtdAtualizacao + 1,
			PendenciaProcessamento.QtdTentativaProcessamento = PendenciaProcessamento.QtdTentativaProcessamento + 1
From
	PendenciaProcessamento WITH (nolock)
		inner join
	#TabAux TabAux with (nolock) on 
			PendenciaProcessamento.IdUsuarioContaSistema = TabAux.IdUsuarioContaSistema and 
			PendenciaProcessamento.Id between TabAux.MenorId and TabAux.MaiorId and
			PendenciaProcessamento.DtPreProcessado between TabAux.MenorDtPreProcessado and TabAux.MaiorDtPreProcessado

where 
	PendenciaProcessamento.PreProcessado = 1
		and
	PendenciaProcessamento.Processado = 0
		and
	PendenciaProcessamento.Status = 'INCLUIDO'

end;

CREATE procedure [dbo].[ProcSetRegraFidelizacaoCampanha] (@idContaSistema as int, @idCampanha as int, @idRegraFidelizacao as int)
as

Update 
	PessoaProspectFidelizado
Set 
	PessoaProspectFidelizado.IdRegraFidelizacao = @idRegraFidelizacao
From 
	PessoaProspectFidelizado with (nolock)
		inner join
	Campanha  with (nolock) on Campanha.id = PessoaProspectFidelizado.IdCampanha

where
	Campanha.IdContaSistema = @idContaSistema
		and
	PessoaProspectFidelizado.DtFimFidelizacao is null
		and
	PessoaProspectFidelizado.IdCampanha = @idCampanha;

CREATE procedure [dbo].[ProcSetUsuarioContaSistemaUltimaRequisicao]
 @IdsUsuarioContaSistema  varchar(max)

as 
 
declare @TableIds table(
	IdUsuarioContaSistema int
);

declare @dtNow datetime = dbo.GetDateCustomNoMilleseconds()

-- Irá inserir na tabela os ids pesquisadas
insert into @TableIds (IdUsuarioContaSistema) select TableTag.OrderID from dbo.SplitIDs(@IdsUsuarioContaSistema) TableTag;	

begin
	Update 
		UsuarioContaSistema
	Set
		UsuarioContaSistema.DtUltimaRequisicao = @dtNow
	From 
		UsuarioContaSistema	with (nolock)
			inner join
		@TableIds TabAux on TabAux.IdUsuarioContaSistema = UsuarioContaSistema.Id

	OPTION (RECOMPILE)
end;

CREATE procedure [dbo].[ProcUsuarioAnaproDesativar] 

as
	begin

		-- desabilita usuários das contas anapro que não estão mais ativos como funcionários do ANAPRO
		update UsuarioContaSistema set UsuarioContaSistema.Status = 'DE'
		from 
			UsuarioContaSistema 
				inner join 
			Pessoa on Pessoa.Id = UsuarioContaSistema.IdPessoa
		where 
			IdContaSistema in (3, 151, 222) and 
			Status = 'AT' and
			Pessoa.Email not in ('wisedf@gmail.com', 'wisedf@hotmail.com','admin@anapro.com.br','desenvolvimento@anapro.com.br', 'cliente@anapro.com.br') and
			Pessoa.Email not in (
									'ademar.santana@isibr.com.br',
									'anael.almeida@anapro.com.br',
									'analistas.credito@isibr.com.br',
									'andre.torres@anapro.com.br',
									'atendimento@anapro.com.br',
									'carolina.vargas@anapro.com.br',
									'bruno@anapro.com.br',
									'camilap@anapro.com.br',
									'carlos@anapro.com.br',
									'charles@anapro.com.br',
									'contratodigital@anapro.com.br',
									'dhiego@anapro.com.br',
									'driveconsultoria@anapro.com.br',
									'edson@anapro.com.br',
									'emily.souza@anapro.com.br',
									'fabricio@anapro.com.br',
									'felipe.cavalcante@anapro.com.br',
									'fernanda@anapro.com.br',
									'gabriel@anapro.com.br',
									'gabrielmorais@anapro.com.br',
									'moraisgabriel@anapro.com.br',
									'gabriela@anapro.com.br',
									'gabrielle@anapro.com.br',
									'gerson@anapro.com.br',
									'giovana@anapro.com.br',
									'guilherme@anapro.com.br',
									'helder@anapro.com.br',
									'helder@isibr.com.br',
									'henrique.zelioli@anapro.com.br',
									'henrique.elioli@anapro.com.br',
									'hugo@anapro.com.br',
									'igor.alves@anapro.com.br',
									'infra@anapro.com.br',
									'isabela@anapro.com.br',
									'jeduardo@anapro.com.br',
									'joao.victor@anapro.com.br',
									'joao.pedro@anapro.com.br',
									'junior@isibr.com.br',
									'junior@anapro.com.br',
									'jessica@anapro.com.br',
									'lana@anapro.com.br',
									'laryssa@anapro.com.br',
									'leandro.silva@anapro.com.br',
									'leonardo@anapro.com.br',
									'leticia.oliveira@anapro.com.br',
									'lucas.lopes@anapro.com.br',
									'lucas.barros@anapro.com.br',
									'luiz@anapro.com.br',
									'marcelo.junior@anapro.com.br',
									'marcelo.cardozo@isibr.com.br',
									'marcos.teixeira@isibr.com.br',
									'midias@anapro.com.br',
									'matheus@anapro.com.br',
									'mayara@anapro.com.br',
									'michelle@anapro.com.br',
									'milaine.almeida@anapro.com.br',
									'millena.saraiva@anapro.com.br',
									'osmar@anapro.com.br',
									'otavio@anapro.com.br',
									'paula.cannas@isibr.com.br',
									'ptroyano@isibr.com.br',
									'pedro.henrique@anapro.com.br',
									'priscilla.goes@anapro.com.br',
									'rafael.mendes@anapro.com.br',
									'rafael.santiago@anapro.com.br',
									'rafael.aquino@anapro.com.br',
									'ricardo@anapro.com.br',
									'rgomes@isibr.com.br',
									'rodrigo.italiano@anapro.com.br',
									'rodrigo.alves@anapro.com.br',
									'ronaldo@anapro.com.br',
									'rubens.torres@isibr.com.br',
									'secretaria.vendas@isibr.com.br',
									'suporte1@anapro.com.br',
									'suporte2@anapro.com.br',
									'suporte3@anapro.com.br',
									'thamyres@anapro.com.br',
									'treinamento@anapro.com.br',
									'viniciusrodrigues@anapro.com.br',
									'vitor@anapro.com.br',
									'walen@anapro.com.br',
									'wania.moraes@isibr.com.br',
									'william@anapro.com.br'
							)

		-- desabilita qualquer usuário @anapro de qualquer conta a qual o usuário não está mais trabalhando no ANAPRO
		update UsuarioContaSistema set UsuarioContaSistema.Status = 'DE'
		from 
			UsuarioContaSistema 
				inner join 
			Pessoa on Pessoa.Id = UsuarioContaSistema.IdPessoa
		where 
			IdContaSistema NOT in (3, 151, 222) and 
			Status = 'AT' and
			Pessoa.Email like '%@anapro.com.br' and
			Pessoa.Email not in ('wisedf@gmail.com', 'wisedf@hotmail.com','admin@anapro.com.br','desenvolvimento@anapro.com.br', 'cliente@anapro.com.br') and
			Pessoa.Email not in (
									'ademar.santana@isibr.com.br',
									'anael.almeida@anapro.com.br',
									'analistas.credito@isibr.com.br',
									'andre.torres@anapro.com.br',
									'atendimento@anapro.com.br',
									'carolina.vargas@anapro.com.br',
									'bruno@anapro.com.br',
									'camilap@anapro.com.br',
									'carlos@anapro.com.br',
									'charles@anapro.com.br',
									'contratodigital@anapro.com.br',
									'dhiego@anapro.com.br',
									'driveconsultoria@anapro.com.br',
									'edson@anapro.com.br',
									'emily.souza@anapro.com.br',
									'fabricio@anapro.com.br',
									'felipe.cavalcante@anapro.com.br',
									'fernanda@anapro.com.br',
									'gabriel@anapro.com.br',
									'gabrielmorais@anapro.com.br',
									'moraisgabriel@anapro.com.br',
									'gabriela@anapro.com.br',
									'gabrielle@anapro.com.br',
									'gerson@anapro.com.br',
									'giovana@anapro.com.br',
									'guilherme@anapro.com.br',
									'helder@anapro.com.br',
									'helder@isibr.com.br',
									'henrique.zelioli@anapro.com.br',
									'henrique.elioli@anapro.com.br',
									'hugo@anapro.com.br',
									'igor.alves@anapro.com.br',
									'infra@anapro.com.br',
									'isabela@anapro.com.br',
									'jeduardo@anapro.com.br',
									'joao.victor@anapro.com.br',
									'joao.pedro@anapro.com.br',
									'junior@isibr.com.br',
									'junior@anapro.com.br',
									'jessica@anapro.com.br',
									'lana@anapro.com.br',
									'laryssa@anapro.com.br',
									'leandro.silva@anapro.com.br',
									'leonardo@anapro.com.br',
									'leticia.oliveira@anapro.com.br',
									'lucas.lopes@anapro.com.br',
									'lucas.barros@anapro.com.br',
									'luiz@anapro.com.br',
									'marcelo.junior@anapro.com.br',
									'marcelo.cardozo@isibr.com.br',
									'marcos.teixeira@isibr.com.br',
									'midias@anapro.com.br',
									'matheus@anapro.com.br',
									'mayara@anapro.com.br',
									'michelle@anapro.com.br',
									'milaine.almeida@anapro.com.br',
									'millena.saraiva@anapro.com.br',
									'osmar@anapro.com.br',
									'otavio@anapro.com.br',
									'paula.cannas@isibr.com.br',
									'ptroyano@isibr.com.br',
									'pedro.henrique@anapro.com.br',
									'priscilla.goes@anapro.com.br',
									'rafael.mendes@anapro.com.br',
									'rafael.santiago@anapro.com.br',
									'rafael.aquino@anapro.com.br',
									'ricardo@anapro.com.br',
									'rgomes@isibr.com.br',
									'rodrigo.italiano@anapro.com.br',
									'rodrigo.alves@anapro.com.br',
									'ronaldo@anapro.com.br',
									'rubens.torres@isibr.com.br',
									'secretaria.vendas@isibr.com.br',
									'suporte1@anapro.com.br',
									'suporte2@anapro.com.br',
									'suporte3@anapro.com.br',
									'thamyres@anapro.com.br',
									'treinamento@anapro.com.br',
									'viniciusrodrigues@anapro.com.br',
									'vitor@anapro.com.br',
									'walen@anapro.com.br',
									'wania.moraes@isibr.com.br',
									'william@anapro.com.br'
							)
	end;

-- Irá alocar automaticamente os usuários de um grupo que participa da campanha
-- em um canal onde o mesmo está setado como padrão na campanha
CREATE procedure [dbo].[ProcUsuarioContaSistemaDesativar]
	@idContaSistema as int,
	@idUsuarioContaSistema as int
 as 
begin
	declare @dtnow datetime = dbo.getDateCustom()

	-- seta o status do usuário para desativado e volta o mesmo para o perfil padrão da empresa
	update 
		UsuarioContaSistema set Status = 'DE',
		idPerfilUsuario = (select PerfilUsuario.id from PerfilUsuario with (nolock) where idContaSistema = @idContaSistema and PerfilUsuario.Padrao = 1),
		DtAtualizacao = @dtnow
	where 
		id = @idUsuarioContaSistema and 
		IdContaSistema = @idContaSistema

	-- desfideliza qualquer prospect que esteja fidelizado ao mesmo
	update PessoaProspectFidelizado set DtFimFidelizacao = @dtnow
	from
		PessoaProspectFidelizado with (nolock)
			inner join
		UsuarioContaSistema with (nolock) on PessoaProspectFidelizado.IdUsuarioContaSistema = UsuarioContaSistema.Id
	where 
		PessoaProspectFidelizado.IdUsuarioContaSistema = @idUsuarioContaSistema and 
		PessoaProspectFidelizado.DtFimFidelizacao is null and 
		UsuarioContaSistema.IdContaSistema = @idContaSistema

	-- encerra qualquer atendimento que esteja aberto para o usuário em questão
	update 
		Atendimento set StatusAtendimento = 'ENCERRADO', 
		DtConclusaoAtendimento = @dtnow, 
		IdUsuarioContaSistemaAtendimento = null,
		negociacaoStatus = case when negociacaoStatus <> 'GANHO' then 'PERDIDO' ELSE 'GANHO' end
	from
		Atendimento with (nolock)
	where 
		Atendimento.IdUsuarioContaSistemaAtendimento = @idUsuarioContaSistema and
		Atendimento.idContaSistema = @idContaSistema and
		Atendimento.StatusAtendimento <> 'ENCERRADO'


	-- Retira o usuário de todos os grupos
	update 
		UsuarioContaSistemaGrupo 
	set 
		DtFim = @dtnow
	from
		UsuarioContaSistemaGrupo with (nolock)
			inner join
		UsuarioContaSistema  with (nolock)on UsuarioContaSistema.Id = UsuarioContaSistemaGrupo.IdUsuarioContaSistema
	where
		UsuarioContaSistemaGrupo.IdUsuarioContaSistema = @idUsuarioContaSistema and
		UsuarioContaSistema.IdContaSistema = @idContaSistema and
		(UsuarioContaSistemaGrupo.DtFim is null or UsuarioContaSistemaGrupo.DtFim > @dtnow)


	-- Retira o usuário de todos os que é adm
	update 
		UsuarioContaSistemaGrupoAdm 
	set 
		DtFim = @dtnow
	from
		UsuarioContaSistemaGrupoAdm with (nolock)
			inner join
		UsuarioContaSistema with (nolock) on UsuarioContaSistema.Id = UsuarioContaSistemaGrupoAdm.IdUsuarioContaSistema
	where
		UsuarioContaSistemaGrupoAdm.IdUsuarioContaSistema = @idUsuarioContaSistema and
		UsuarioContaSistema.IdContaSistema = @idContaSistema and
		(UsuarioContaSistemaGrupoAdm.DtFim is null or UsuarioContaSistemaGrupoAdm.DtFim > @dtnow)

	-- retira o usuário de todos os plantões
	delete from UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal 
	from
		UsuarioContaSistema with (nolock)
			inner join
		UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal with (nolock) on UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal.IdUsuarioContaSistema = UsuarioContaSistema.Id	
	where 
		UsuarioContaSistemaCampanhaGrupoPlantaoHorarioCanal.IdUsuarioContaSistema = @idUsuarioContaSistema and
		UsuarioContaSistema.IdContaSistema = @idContaSistema

	-- retira o usuário de todos as campanhas que por ventura possa ser admim
	delete from CampanhaAdministrador 
	from
		UsuarioContaSistema with (nolock)
			inner join
		CampanhaAdministrador with (nolock) on CampanhaAdministrador.IdUsuarioContaSistema = UsuarioContaSistema.Id	
	where 
		CampanhaAdministrador.IdUsuarioContaSistema = @idUsuarioContaSistema and
		UsuarioContaSistema.IdContaSistema = @idContaSistema


	-- Deleta todos os usuários que estão como seguidor mas foram desativados do sistema
	delete 
		from 
			AtendimentoSeguidor 
	where
		AtendimentoSeguidor.IdUsuarioContaSistema = @idUsuarioContaSistema

	-- gera a hierarquia do usuário
	exec ProcGerarGrupoHierarquiaUsuarioContaSistema @idContaSistema, @idUsuarioContaSistema
end;

CREATE procedure [dbo].[ProcUsuarioContaSistemaPodeAcessarAtendimento] 
(
	@IdContaSistema int,
	@IsAdministradorDoSistema bit,
	@IdUsuarioContaSistemaExecutando int,
	@IdAtendimento int,
	@IdUsuarioContaSistemaVerificado int
)
AS
	
	Select 
		cast(COUNT(Atendimento.id) as bit) AS PodeAcessar
		
	From
		Atendimento WITH (NOLOCK)
			left outer join 
		---- Seleciona para verificar se o usuario que esta executando e adm da campanha, caso seja o mesmo podera visualizar os registros
		CampanhaAdministrador WITH (NOLOCK) on CampanhaAdministrador.idCampanha = Atendimento.IdCampanha and CampanhaAdministrador.idUsuarioContaSistema = @IdUsuarioContaSistemaVerificado
			left outer join 
		-- se ele é adm e n quer listar somente os atendimentos dele n se faz necessario executar essa pesquisa
		PessoaProspectFidelizado WITH (NOLOCK) on PessoaProspectFidelizado.IdPessoaProspect = Atendimento.idPessoaProspect and PessoaProspectFidelizado.IdCampanha = Atendimento.idCampanha and PessoaProspectFidelizado.DtFimFidelizacao is null and PessoaProspectFidelizado.IdUsuarioContaSistema = @IdUsuarioContaSistemaVerificado
			left outer join
		AtendimentoSeguidor WITH (NOLOCK) on AtendimentoSeguidor.idAtendimento = Atendimento.id and AtendimentoSeguidor.IdUsuarioContaSistema = @IdUsuarioContaSistemaVerificado and AtendimentoSeguidor.Status = 'AT'
	Where
		Atendimento.idContaSistema = @IdContaSistema
			and
		Atendimento.id = @IdAtendimento
			and
		(
			(
				-- caso seja administrador do sistema não irá considerar a hierarquia de grupos
				@IsAdministradorDoSistema = 1
					or
				-- caso seja administraodr da campanha todos os atendimentos da mesmo o usuário poderá ver
				CampanhaAdministrador.Id is not null
					or
				-- O usuário detem a fidelização do prospect
				PessoaProspectFidelizado.id is not null
					or
				-- Usuário não está fidelizado a ninguém e o atendimento está para o prospect, nesse caso provavelmente aguardando para ser atendido
				Atendimento.IdUsuarioContaSistemaAtendimento = @IdUsuarioContaSistemaExecutando
					or
				exists (Select GrupoHierarquiaUsuarioContaSistema.id from GrupoHierarquiaUsuarioContaSistema WITH (NOLOCK) where GrupoHierarquiaUsuarioContaSistema.idUsuarioContaSistema = @IdUsuarioContaSistemaExecutando and (GrupoHierarquiaUsuarioContaSistema.IdGrupo = PessoaProspectFidelizado.IdGrupo or GrupoHierarquiaUsuarioContaSistema.IdGrupo = Atendimento.idGrupo))
					or
				AtendimentoSeguidor.Id is not null
			)
		);

-- Verifica se o prospect em questão encontra-se fidelizado aó usuário repassado ou algum inferior
-- Caso encontra-se retornará 1 ou True
CREATE procedure [dbo].[ProcUsuarioContaSistemaPodeAcessarProspectFidelizado](
	@IdContaSistema as int,
	@IsAdministradorDoSistema as bit,
	@IdUsuarioContaSistemaVerificado int, 
	@idPessoaProspect int
)

as
	Select 
		cast(COUNT(PessoaProspect.id) as bit) AS PodeAcessar
		
	From
		PessoaProspect WITH (NOLOCK)
			left outer join
		PessoaProspectFidelizado WITH (NOLOCK) on PessoaProspectFidelizado.IdPessoaProspect = PessoaProspect.Id and PessoaProspectFidelizado.DtFimFidelizacao is null
			left outer join
		---- Seleciona para verificar se o usuario que esta executando e adm da campanha, caso seja o mesmo podera visualizar os registros
		CampanhaAdministrador WITH (NOLOCK) on CampanhaAdministrador.idCampanha = PessoaProspectFidelizado.IdCampanha and CampanhaAdministrador.idUsuarioContaSistema = @IdUsuarioContaSistemaVerificado
			left outer join
		-- Selecionará todos grupos inferiores que por ventura o usuário em questão seja administrador e o prospect esteja fidelizado a algum usuario pertencente a esse grupo
		GrupoHierarquiaUsuarioContaSistema WITH (NOLOCK) on GrupoHierarquiaUsuarioContaSistema.idContaSistema = PessoaProspect.IdContaSistema and GrupoHierarquiaUsuarioContaSistema.idUsuarioContaSistema = @IdUsuarioContaSistemaVerificado and GrupoHierarquiaUsuarioContaSistema.IdGrupo = PessoaProspectFidelizado.IdGrupo
			left outer join
		AtendimentoSeguidor WITH (NOLOCK) on AtendimentoSeguidor.IdPessoaProspect = PessoaProspect.id and AtendimentoSeguidor.IdUsuarioContaSistema = @IdUsuarioContaSistemaVerificado and AtendimentoSeguidor.Status = 'AT'
	Where
		PessoaProspect.id = @idPessoaProspect
			and
		PessoaProspect.IdContaSistema = @IdContaSistema
			and
		(
			(
				-- caso seja administrador do sistema não irá considerar a hierarquia de grupos
				@IsAdministradorDoSistema = 1
					or
				-- caso seja administraodr da campanha todos os atendimentos da mesmo o usuário poderá ver
				CampanhaAdministrador.Id is not null
					or
				-- Caso o usuário seja administrador do grupo a qual o prospect encontra-se fidelizado
				GrupoHierarquiaUsuarioContaSistema.Id is not null
					or
				-- O usuário detem a fidelização do prospect
				PessoaProspectFidelizado.IdUsuarioContaSistema = @IdUsuarioContaSistemaVerificado
					or
				-- Usuário não está fidelizado a ninguém e o atendimento está para o prospect, nesse caso provavelmente aguardando para ser atendido
				PessoaProspectFidelizado.Id is null
					or
				AtendimentoSeguidor.Id is not null
			)
		);

CREATE procedure [dbo].[ProcUsuarioContaSistemaPodeAcessarUsuario] 
(
	@IdContaSistema int,
	@IsAdministradorDoSistema bit,
	@IdUsuarioContaSistemaExecutando int,
	@IdUsuarioContaSistemaVerificado int
)
AS
	
	Select top 1
		cast(COUNT(UsuarioContaSistema.id) as bit) AS PodeAcessar
		
	From
		UsuarioContaSistema WITH (NOLOCK)
			left outer join
		dbo.GetUsuarioContaSistemaInferior(@IdUsuarioContaSistemaExecutando) UsuariosInferior on UsuariosInferior.IdUsuarioContaSistema = @IdUsuarioContaSistemaVerificado
	where
		UsuarioContaSistema.IdContaSistema = @IdContaSistema
			and
		(
			@IsAdministradorDoSistema = 1
				or
			UsuarioContaSistema.Id = @IdUsuarioContaSistemaVerificado
		);

CREATE procedure [dbo].[ReconstruirIndicesFragmentados]
(
  @Tabela SYSNAME = NULL,
  @FragmentacaoMinima TINYINT,
  @AtualizarEstatisticas bit
)
AS
BEGIN
  DECLARE @Comando VARCHAR(800),
          @NomeIndice SYSNAME,
          @NomeTabela SYSNAME,
          @TotalIndices INT,
          @LinhasAfetadas INT;

  SET NOCOUNT ON;
  

if @AtualizarEstatisticas = 1
	begin
		EXEC sp_updatestats;
	end

-- SELECT a.index_id, name, avg_fragmentation_in_percent
--FROM sys.dm_db_index_physical_stats (DB_ID(N'SuperCRMDBRelease'), null, NULL, NULL, NULL) AS a
--    JOIN sys.indexes AS b ON a.object_id = b.object_id AND a.index_id = b.index_id; 

  -- A tabela informada existe?
  IF @Tabela IS NOT NULL
  BEGIN
    IF (SELECT COUNT(*) FROM sys.tables WHERE name = @Tabela) = 0
    BEGIN
	  RAISERROR('A tabela ''%s'' não existe no banco de dados.',
	            16, 1, @Tabela);
	  RETURN(-1);
    END;
  END;

  -- O percentual de fragmentação deve estar entre 1 e 100
  IF NOT @FragmentacaoMinima BETWEEN 1 AND 100
  BEGIN
    RAISERROR('O percentual de fragmentação deve ser entre 1 e 100.',
              16, 1);
    RETURN(-1);
  END;

  SELECT OBJECT_NAME(STA.object_id) AS objeto_nome,
         OBJECT_SCHEMA_NAME(STA.object_id) AS schema_nome,
         IDX.name AS indice_nome,
         IDX.type AS indice_tipo,
         STA.avg_fragmentation_in_percent AS percentual_fragmentado,
         STA.page_count,
         IDX.is_unique,
         IDX.is_primary_key
    INTO dbo.#InfoIndices
    FROM sys.dm_db_index_physical_stats(DB_ID(),
                                        NULL,
                                        NULL,
                                        NULL,
                                        NULL) AS STA
   INNER JOIN sys.indexes AS IDX
      ON IDX.index_id = STA.index_id AND IDX.object_id = STA.object_id
   WHERE STA.avg_fragmentation_in_percent >= @FragmentacaoMinima
     AND STA.index_type_desc <> 'HEAP'
     AND STA.page_count > 80
     AND (@Tabela IS NULL OR OBJECT_NAME(STA.object_id) = @Tabela);

  SELECT indice_nome,
         indice_tipo,
         objeto_nome,
         'ALTER INDEX ' +
         CASE
           WHEN indice_nome IS NULL THEN
             'ALL'
           ELSE
             QUOTENAME(indice_nome)
         END + ' ON ' + QUOTENAME(schema_nome) + '.' +
         QUOTENAME(objeto_nome) +
         ' REBUILD WITH (MAXDOP = 1, SORT_IN_TEMPDB = ON, ONLINE = ON);' AS Comando
   INTO dbo.#AlterIndex
   FROM dbo.#InfoIndices;

  SELECT @LinhasAfetadas = @@ROWCOUNT,
         @TotalIndices = 0;	

  WHILE @LinhasAfetadas > 0
  BEGIN
    SELECT TOP(1)
           @Comando = Comando,
           @NomeIndice = indice_nome,
           @NomeTabela = objeto_nome,
           @TotalIndices += 1
      FROM dbo.#AlterIndex
     ORDER BY indice_tipo, indice_nome;

    EXECUTE(@Comando);

    RAISERROR('O índice ''%s'' do objeto ''%s'' foi desfragmentado com sucesso.',
              0, 1, @NomeIndice, @NomeTabela) WITH NOWAIT; 

    DELETE Tabela
      FROM (SELECT TOP(1) *
              FROM dbo.#AlterIndex
             ORDER BY indice_tipo, indice_nome) AS Tabela;

    SET @LinhasAfetadas = @@ROWCOUNT;
  END;

  RAISERROR('Total de índices desfragmentados: %d', 0, 1, @TotalIndices);
END;

-- caso @val seja nulo retornará o @valPadrao
-- caso @valpadrao tb seja nulo retornará 0
CREATE function [dbo].[RetBitNotNull](@val int, @valPadrao bit)
returns bit
as

begin
declare @ret bit

if @val is null
	if @valPadrao is null
		begin
			set @ret = 0
		end
	else
		begin
			set @ret = @valPadrao
		end
else
	set @ret = @val

return @ret
end;

-- retira os acentos repassados
CREATE function [dbo].[RetirarAcento](@val varchar(max))
returns varchar(max)
as

begin
return (select @val collate sql_latin1_general_cp1251_ci_as)
end;

CREATE function [dbo].[RetirarCaracteresXml](@val varchar(max))
returns varchar(max)
as

begin

return REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@val,NCHAR(1),N'?'),NCHAR(2),N'?'),NCHAR(3),N'?'),NCHAR(4),N'?'),NCHAR(5),N'?'),NCHAR(6),N'?'),NCHAR(7),N'?'),NCHAR(8),N'?'),NCHAR(11),N'?'),NCHAR(12),N'?'),NCHAR(14),N'?'),NCHAR(15),N'?'),NCHAR(16),N'?'),NCHAR(17),N'?'),NCHAR(18),N'?'),NCHAR(19),N'?'),NCHAR(20),N'?'),NCHAR(21),N'?'),NCHAR(22),N'?'),NCHAR(23),N'?'),NCHAR(24),N'?'),NCHAR(25),N'?'),NCHAR(26),N'?'),NCHAR(27),N'?'),NCHAR(28),N'?'),NCHAR(29),N'?'),NCHAR(30),N'?'),NCHAR(31),N'?') 
end;

CREATE function [dbo].[RetNullOrVarChar](@texto varchar(max))
returns varchar(max)
as

begin
declare @ret varchar(max)

if LEN(LTRIM(RTRIM(@texto))) > 0
	set @ret = @texto
else
	set @ret = NULL

return @ret
end;

-- Retorna um varchar específico caso a string repassada seja nula ou vazia
CREATE function [dbo].[RetVarCharIsNullOrWhiteSpace](@texto varchar(max), @textoRet varchar(max))
returns varchar(max)
as

begin
declare @ret varchar(max)

if LEN(LTRIM(RTRIM(@texto))) > 0
	set @ret = @texto
else
	set @ret = @textoRet

return @ret
end;

CREATE function [dbo].[SomenteCEP](@strAlphaNumeric VARCHAR(max), @retNullIfNullOrEmpty bit)
RETURNS VARCHAR(max)
AS
BEGIN
	declare @cep varchar(max) = dbo.SomenteNumeros(@strAlphaNumeric)
	declare @return varchar(8) = '';

	if @cep is not null and @cep <> '0' and LEN(@cep) >= 8
		begin
			-- se faz necessário para retirar os zeros do inicio caso exista
			set @cep = TRY_CONVERT(bigint, @cep)

			if len(@cep) = 8
				begin
					set @return = @cep
				end
		end

	RETURN case when @return is null or @return = '' and @retNullIfNullOrEmpty = 1 then null else @return end
END;

CREATE function [dbo].[SomenteCNPJ](@strAlphaNumeric VARCHAR(max), @retNullIfNullOrEmpty bit)
RETURNS varchar(14) -- 1 = válido, 0 = inválido
BEGIN
 
	declare @INDICE INT
	declare @SOMA INT
	declare @DIG1 INT
	declare @DIG2 INT
	declare @VAR1 INT
	declare @VAR2 INT
	declare @CNPJ char(14) = NULL
	
	SET @strAlphaNumeric = [dbo].[SomenteNumeros](@strAlphaNumeric)
 
    SET @SOMA = 0
    SET @INDICE = 1
    SET @VAR1 = 5 /* 1a Parte do Algorítimo começando de "5" */

	if @strAlphaNumeric is not null and @strAlphaNumeric <> '0' and len(@strAlphaNumeric) >= 8
		begin
			if len(@strAlphaNumeric) <> 14
				begin
					set @strAlphaNumeric = TRY_CONVERT(bigint, @strAlphaNumeric)

					if len(@strAlphaNumeric) > 14
						begin
							set @strAlphaNumeric = null
						end
					else
						begin
							while len(@strAlphaNumeric) < 14
								set @strAlphaNumeric = '0' + @strAlphaNumeric
						end
				end

				if @strAlphaNumeric is not null and len(@strAlphaNumeric) = 14
					begin

						WHILE ( @INDICE < = 4 )
							BEGIN
								SET @SOMA = @SOMA + CONVERT(INT, SUBSTRING(@strAlphaNumeric, @INDICE, 1)) * @VAR1
								SET @INDICE = @INDICE + 1 /* Navegando um-a-um até < = 4, as quatro primeira posições */
								SET @VAR1 = @VAR1 - 1       /* subtraindo o algorítimo de 5 até 2 */
							END
 
       
						SET @VAR2 = 9
						WHILE ( @INDICE <= 12 )
							BEGIN
								SET @SOMA = @SOMA + CONVERT(INT, SUBSTRING(@strAlphaNumeric, @INDICE, 1)) * @VAR2
								SET @INDICE = @INDICE + 1
								SET @VAR2 = @VAR2 - 1            
							END
 
						SET @DIG1 = ( @SOMA % 11 )
 
 
					   /* SE O RESTO DA DIVISÃO FOR < 2, O DIGITO = 0 */
						IF @DIG1 < 2
							SET @DIG1 = 0;
						ELSE /* SE O RESTO DA DIVISÃO NÃO FOR < 2*/
							SET @DIG1 = 11 - ( @SOMA % 11 );
 
 
						SET @INDICE = 1
						SET @SOMA = 0
						SET @VAR1 = 6 /* 2a Parte do Algorítimo começando de "6" */
 
						WHILE ( @INDICE <= 5 )
							BEGIN
								SET @SOMA = @SOMA + CONVERT(INT, SUBSTRING(@strAlphaNumeric, @INDICE, 1)) * @VAR1
								SET @INDICE = @INDICE + 1 /* Navegando um-a-um até < = 5, as quatro primeira posições */
								SET @VAR1 = @VAR1 - 1       /* subtraindo o algorítimo de 6 até 2 */
							END
 
 
 
						/* CÁLCULO DA 2ª PARTE DO ALGORÍTIOM 98765432 */
						SET @VAR2 = 9
						WHILE ( @INDICE <= 13 )
							BEGIN
								SET @SOMA = @SOMA + CONVERT(INT, SUBSTRING(@strAlphaNumeric, @INDICE, 1)) * @VAR2
								SET @INDICE = @INDICE + 1
								SET @VAR2 = @VAR2 - 1            
							END
 
 
						SET @DIG2 = ( @SOMA % 11 )
 
 
					   /* SE O RESTO DA DIVISÃO FOR < 2, O DIGITO = 0 */
 
						IF @DIG2 < 2
							SET @DIG2 = 0;
 
						ELSE /* SE O RESTO DA DIVISÃO NÃO FOR < 2*/
							SET @DIG2 = 11 - ( @SOMA % 11 );
 
 
						IF ( @DIG1 = SUBSTRING(@strAlphaNumeric, LEN(@strAlphaNumeric) - 1, 1) ) AND ( @DIG2 = SUBSTRING(@strAlphaNumeric, LEN(@strAlphaNumeric), 1) )
							SET @CNPJ = @strAlphaNumeric

					end
		end
 
 
 
    RETURN case when @CNPJ is null and @retNullIfNullOrEmpty = 0 then '' else @CNPJ end
    
END;

--select top 1 cep from CEPLogradouro where [dbo].[SomenteCEP](cep, 1) <> cep

CREATE function [dbo].[SomenteCPF](@strAlphaNumeric VARCHAR(max), @retNullIfNullOrEmpty bit)
RETURNS varchar(11) -- 1 = válido, 0 = inválido
BEGIN
 
    declare @Contador_1 INT
    declare @Contador_2 INT
    declare @Digito_1 INT = 0
    declare @Digito_2 INT
    declare @Nr_Documento VARCHAR(MAX) = null
	declare @Nr_Documento_Aux VARCHAR(MAX) = null
 
    -- Remove espaços em branco
	set @Nr_Documento = [dbo].[SomenteNumeros](@strAlphaNumeric)

	if @Nr_Documento is not null and @Nr_Documento <> '0' and len(@Nr_Documento) >= 5
		begin
			if len(@Nr_Documento) <> 11
				begin
					set @Nr_Documento = TRY_CONVERT(bigint, @Nr_Documento)

					if len(@Nr_Documento) > 11
						begin
							set @Nr_Documento = null
						end
					else
						begin
							while len(@Nr_Documento) < 11
								set @Nr_Documento = '0'+@Nr_Documento
						end
				end


			if @Nr_Documento is not null and len(@Nr_Documento) = 11
				begin

					-- Remove os números que funcionam como validação para CPF, pois eles "passam" pela regra de validação
					IF (@Nr_Documento IN ('00000000000', '11111111111', '22222222222', '33333333333', '44444444444', '55555555555', '66666666666', '77777777777', '88888888888', '99999999999', '12345678909'))
						begin
							set @Nr_Documento = null
						end
					else
						begin
						    set @Nr_Documento_Aux = @Nr_Documento

							-- Cálculo do segundo dígito
							SET @Nr_Documento_Aux = SUBSTRING(@Nr_Documento_Aux, 1, 9)

							SET @Contador_1 = 2

							WHILE (@Contador_1 < = 10)
								begin 
									SET @Digito_1 = @Digito_1 + (@Contador_1 * CAST(SUBSTRING(@Nr_Documento_Aux, 11 - @Contador_1, 1) as int))
									SET @Contador_1 = @Contador_1 + 1
								end 

							SET @Digito_1 = @Digito_1 - (@Digito_1/11)*11

							IF (@Digito_1 <= 1)
								SET @Digito_1 = 0
							ELSE 
								SET @Digito_1 = 11 - @Digito_1

							
							SET @Nr_Documento_Aux = @Nr_Documento_Aux + CAST(@Digito_1 AS VARCHAR(1))


							IF (@Nr_Documento_Aux <> SUBSTRING(@Nr_Documento, 1, 10))
								begin
									set @Nr_Documento = null
								end
							ELSE 
								begin
        
									-- Cálculo do segundo dígito
									SET @Digito_2 = 0
									SET @Contador_2 = 2

									WHILE (@Contador_2 < = 11)
										BEGIN 
											SET @Digito_2 = @Digito_2 + (@Contador_2 * CAST(SUBSTRING(@Nr_Documento_Aux, 12 - @Contador_2, 1) AS INT))
											SET @Contador_2 = @Contador_2 + 1
										end 

									SET @Digito_2 = @Digito_2 - (@Digito_2/11)*11

									IF (@Digito_2 < 2)
										SET @Digito_2 = 0
									ELSE 
										SET @Digito_2 = 11 - @Digito_2

									SET @Nr_Documento_Aux = @Nr_Documento_Aux + CAST(@Digito_2 AS VARCHAR(1))

									IF (@Nr_Documento_Aux <> @Nr_Documento)
										set @Nr_Documento = null
								end

						end

				end
		end 

    RETURN case when @Nr_Documento is null and @retNullIfNullOrEmpty = 0 then '' else @Nr_Documento end
    
END;

CREATE function [dbo].[SomenteCPFORCNPJ](@strAlphaNumeric VARCHAR(max), @retNullIfNullOrEmpty bit)
RETURNS varchar(14)
BEGIN

	declare @cpfCnpj varchar(14) = null
	
	if @strAlphaNumeric is not null and len(@strAlphaNumeric) > 5
		begin
			set @strAlphaNumeric = [dbo].[SomenteNumeros](@strAlphaNumeric)

			if @strAlphaNumeric is not null and @strAlphaNumeric <> '0' and len(TRY_CONVERT(bigint, @strAlphaNumeric)) > 5
				begin
					-- faço isso para caso tenha menos ou igual a 11
					-- privilegiar validar CPF para ficar mais rápido a função
					if len(@strAlphaNumeric) <= 11
						begin
							set @cpfCnpj = [dbo].SomenteCPF(@strAlphaNumeric, 1)
						end

					if @cpfCnpj is null
						begin
							set @cpfCnpj = [dbo].SomenteCNPJ(@strAlphaNumeric, 1)
						end

					if @cpfCnpj is null
						begin
							set @cpfCnpj = [dbo].SomenteCPF(@strAlphaNumeric, 1)
						end
						
				end
		end
	


    RETURN case when @cpfCnpj is null and @retNullIfNullOrEmpty = 0 then '' else @cpfCnpj end
    
END;

CREATE function [dbo].[SomenteDDD] (@DDD VARCHAR(30), @Nr_TelelefoneFull VARCHAR(max), @retNullIfNullOrEmpty bit)
RETURNS smallint
AS
BEGIN
		declare @ddd_valido int = [dbo].[ValidaDDD] (@DDD)

		--SE O DDD FOR INVALIDO TENTA EXTRAIR DO TELEFONE
		IF(@ddd_valido is null and @Nr_TelelefoneFull is not null)

			BEGIN
				--RETIRA PONTUAÇÃO
				set @Nr_TelelefoneFull = [dbo].[SomenteNumeros] (@Nr_TelelefoneFull)

				if @Nr_TelelefoneFull <> '0'
					begin
						-- CONVERTE PARA BIGINT
						set @Nr_TelelefoneFull = TRY_CONVERT(bigint, @Nr_TelelefoneFull)

						-- Verifica a quantidade de digitos e pega o DDD
						SET @Nr_TelelefoneFull = (CASE 
												WHEN LEN(@Nr_TelelefoneFull) = 10 THEN LEFT(@Nr_TelelefoneFull,2)
												WHEN LEN(@Nr_TelelefoneFull) = 11 THEN LEFT(@Nr_TelelefoneFull,2) 
												ELSE NULL
												END)
 
						if @Nr_TelelefoneFull is not null
							begin
								set @ddd_valido = [dbo].[ValidaDDD] (@Nr_TelelefoneFull)
							end 
					end
			END
        
	--SE O DDD JÁ FOR VALIDO RETORNA O PROPRIO DDD
	RETURN case when @ddd_valido is null and @retNullIfNullOrEmpty = 0 then '' else @ddd_valido end
	 
END;

CREATE function [dbo].[SomenteNumeros]
(@strAlphaNumeric VARCHAR(max))
RETURNS VARCHAR(max)
AS
BEGIN
DECLARE @intAlpha INT
SET @intAlpha = PATINDEX('%[^0-9]%', @strAlphaNumeric)
BEGIN
WHILE @intAlpha > 0
BEGIN
SET @strAlphaNumeric = STUFF(@strAlphaNumeric, @intAlpha, 1, '' )
SET @intAlpha = PATINDEX('%[^0-9]%', @strAlphaNumeric )
END
END
RETURN ISNULL(@strAlphaNumeric,0)
END;

CREATE function [dbo].[SomenteTelefone] (@Nr_TelelefoneFull  VARCHAR(max), @retNullIfNullOrEmpty bit)
RETURNS varchar(9)
AS
BEGIN
		declare @TELEFONE_VALIDO bigint = [dbo].[ValidaTelefone] (@Nr_TelelefoneFull)

		IF(@TELEFONE_VALIDO is not null)
			BEGIN

				-- Verifica a quantidade de digitos e pega o TELEFONE
				SET @TELEFONE_VALIDO = (CASE
										WHEN @TELEFONE_VALIDO >= 1000000 and @TELEFONE_VALIDO <= 999999999 THEN @TELEFONE_VALIDO -- 7 a 9 dígitos
										WHEN @TELEFONE_VALIDO >= 1000000000 and @TELEFONE_VALIDO <= 9999999999 THEN RIGHT(@TELEFONE_VALIDO, 8) -- 10 DIGITOS
										WHEN @TELEFONE_VALIDO >= 10000000000 and @TELEFONE_VALIDO <= 99999999999 THEN RIGHT(@TELEFONE_VALIDO,9)  -- 11 DIGITOS
										ELSE NULL
										END)
 

				if (left(@TELEFONE_VALIDO, 1) != '1')
					begin
						SET @TELEFONE_VALIDO = (CASE 
										WHEN @TELEFONE_VALIDO >= 60000000 and @TELEFONE_VALIDO <= 99999999 and left(@TELEFONE_VALIDO,1) in (6,7,8,9) THEN CONCAT('9', @TELEFONE_VALIDO)
										WHEN @TELEFONE_VALIDO >= 2000000 and @TELEFONE_VALIDO <= 6999999 and left(@TELEFONE_VALIDO,1) in (2,3,4,5,6) THEN CONCAT('3', @TELEFONE_VALIDO)
										ELSE @TELEFONE_VALIDO
										END)
					end
				ELSE
					BEGIN
						SET @TELEFONE_VALIDO = NULL
					END	

			END

        
	RETURN case when @TELEFONE_VALIDO is null and @retNullIfNullOrEmpty = 0 then '' else @TELEFONE_VALIDO end
	 
END;

CREATE procedure dbo.sp_alterdiagram
	(
		@diagramname 	sysname,
		@owner_id	int	= null,
		@version 	int,
		@definition 	varbinary(max)
	)
	WITH EXECUTE AS 'dbo'
	AS
	BEGIN
		set nocount on
	
		declare @theId 			int
		declare @retval 		int
		declare @IsDbo 			int
		
		declare @UIDFound 		int
		declare @DiagId			int
		declare @ShouldChangeUID	int
	
		if(@diagramname is null)
		begin
			RAISERROR ('Invalid ARG', 16, 1)
			return -1
		end
	
		execute as caller;
		select @theId = DATABASE_PRINCIPAL_ID();	 
		select @IsDbo = IS_MEMBER(N'db_owner'); 
		if(@owner_id is null)
			select @owner_id = @theId;
		revert;
	
		select @ShouldChangeUID = 0
		select @DiagId = diagram_id, @UIDFound = principal_id from dbo.sysdiagrams where principal_id = @owner_id and name = @diagramname 
		
		if(@DiagId IS NULL or (@IsDbo = 0 and @theId <> @UIDFound))
		begin
			RAISERROR ('Diagram does not exist or you do not have permission.', 16, 1);
			return -3
		end
	
		if(@IsDbo <> 0)
		begin
			if(@UIDFound is null or USER_NAME(@UIDFound) is null) -- invalid principal_id
			begin
				select @ShouldChangeUID = 1 ;
			end
		end

		-- update dds data			
		update dbo.sysdiagrams set definition = @definition where diagram_id = @DiagId ;

		-- change owner
		if(@ShouldChangeUID = 1)
			update dbo.sysdiagrams set principal_id = @theId where diagram_id = @DiagId ;

		-- update dds version
		if(@version is not null)
			update dbo.sysdiagrams set version = @version where diagram_id = @DiagId ;

		return 0
	END;

CREATE procedure [dbo].[sp_BlitzWho] 
	@Help TINYINT = 0
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	IF @Help = 1
		PRINT '
sp_BlitzWho from http://FirstResponderKit.org

This script gives you a snapshot of everything currently executing on your SQL Server.

To learn more, visit http://FirstResponderKit.org where you can download new
versions for free, watch training videos on how it works, get more info on
the findings, contribute your own code, and more.

Known limitations of this version:
 - Only Microsoft-supported versions of SQL Server. Sorry, 2005 and 2000.
   
MIT License

Copyright (c) 2016 Brent Ozar Unlimited

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
';

/* Get the major and minor build numbers */
DECLARE  @ProductVersion NVARCHAR(128)
		,@ProductVersionMajor DECIMAL(10,2)
		,@ProductVersionMinor DECIMAL(10,2)
		,@EnhanceFlag BIT = 0
		,@StringToExecute NVARCHAR(MAX)
		,@EnhanceSQL NVARCHAR(MAX) = 
					N'[query_stats].last_dop,
					  [query_stats].min_dop,
					  [query_stats].max_dop,
					  [query_stats].last_grant_kb,
					  [query_stats].min_grant_kb,
					  [query_stats].max_grant_kb,
					  [query_stats].last_used_grant_kb,
					  [query_stats].min_used_grant_kb,
					  [query_stats].max_used_grant_kb,
					  [query_stats].last_ideal_grant_kb,
					  [query_stats].min_ideal_grant_kb,
					  [query_stats].max_ideal_grant_kb,
					  [query_stats].last_reserved_threads,
					  [query_stats].min_reserved_threads,
					  [query_stats].max_reserved_threads,
					  [query_stats].last_used_threads,
					  [query_stats].min_used_threads,
					  [query_stats].max_used_threads,'

SET @ProductVersion = CAST(SERVERPROPERTY('ProductVersion') AS NVARCHAR(128));
SELECT @ProductVersionMajor = SUBSTRING(@ProductVersion, 1,CHARINDEX('.', @ProductVersion) + 1 ),
@ProductVersionMinor = PARSENAME(CONVERT(VARCHAR(32), @ProductVersion), 2)



IF @ProductVersionMajor > 9 and @ProductVersionMajor < 11
BEGIN
SET @StringToExecute = N'
					    SELECT  GETDATE() AS [run_date] ,
			            CONVERT(VARCHAR, DATEADD(ms, [r].[total_elapsed_time], 0), 114) AS [elapsed_time] ,
			            [s].[session_id] ,
			            [wt].[wait_info] ,
			            [s].[status] ,
			            ISNULL(SUBSTRING([dest].[text],
			                             ( [query_stats].[statement_start_offset] / 2 ) + 1,
			                             ( ( CASE [query_stats].[statement_end_offset]
			                                   WHEN -1 THEN DATALENGTH([dest].[text])
			                                   ELSE [query_stats].[statement_end_offset]
			                                 END - [query_stats].[statement_start_offset] )
			                               / 2 ) + 1), [dest].[text]) AS [query_text] ,
			            [derp].[query_plan] ,
			            [qmg].[query_cost] ,
					    [r].[blocking_session_id] ,
			            [r].[cpu_time] AS [request_cpu_time],
			            [r].[logical_reads] AS [request_logical_reads],
			            [r].[writes] AS [request_writes],
			            [r].[reads] AS [request_physical_reads] ,
			            [s].[cpu_time] AS [session_cpu],
			            [s].[logical_reads] AS [session_logical_reads],
			            [s].[reads] AS [session_physical_reads] ,
			            [s].[writes] AS [session_writes],
			            [s].[memory_usage] ,
			            [r].[estimated_completion_time] ,
			            [r].[deadlock_priority] ,
			            CASE [s].[transaction_isolation_level]
			              WHEN 0 THEN ''Unspecified''
			              WHEN 1 THEN ''Read Uncommitted''
			              WHEN 2 THEN ''Read Committed''
			              WHEN 3 THEN ''Repeatable Read''
			              WHEN 4 THEN ''Serializable''
			              WHEN 5 THEN ''Snapshot''
			              ELSE ''WHAT HAVE YOU DONE?''
			            END AS [transaction_isolation_level] ,
			            [r].[open_transaction_count] ,
			            [qmg].[dop] AS [degree_of_parallelism] ,
			            [qmg].[request_time] ,
			            COALESCE(CAST([qmg].[grant_time] AS VARCHAR), ''N/A'') AS [grant_time] ,
			            [qmg].[requested_memory_kb] ,
			            [qmg].[granted_memory_kb] AS [grant_memory_kb],
			            CASE WHEN [qmg].[grant_time] IS NULL THEN ''N/A''
                             WHEN [qmg].[requested_memory_kb] < [qmg].[granted_memory_kb]
			                 THEN ''Query Granted Less Than Query Requested''
			                 ELSE ''Memory Request Granted''
			            END AS [is_request_granted] ,
			            [qmg].[required_memory_kb] ,
			            [qmg].[used_memory_kb] ,
			            [qmg].[ideal_memory_kb] ,
			            [qmg].[is_small] ,
			            [qmg].[timeout_sec] ,
			            [qmg].[resource_semaphore_id] ,
			            COALESCE(CAST([qmg].[wait_order] AS VARCHAR), ''N/A'') AS [wait_order] ,
			            COALESCE(CAST([qmg].[wait_time_ms] AS VARCHAR),
			                     ''N/A'') AS [wait_time_ms] ,
			            CASE [qmg].[is_next_candidate]
			              WHEN 0 THEN ''No''
			              WHEN 1 THEN ''Yes''
			              ELSE ''N/A''
			            END AS [next_candidate_for_memory_grant] ,
			            [qrs].[target_memory_kb] ,
			            COALESCE(CAST([qrs].[max_target_memory_kb] AS VARCHAR),
			                     ''Small Query Resource Semaphore'') AS [max_target_memory_kb] ,
			            [qrs].[total_memory_kb] ,
			            [qrs].[available_memory_kb] ,
			            [qrs].[granted_memory_kb] ,
			            [qrs].[used_memory_kb] ,
			            [qrs].[grantee_count] ,
			            [qrs].[waiter_count] ,
			            [qrs].[timeout_error_count] ,
			            COALESCE(CAST([qrs].[forced_grant_count] AS VARCHAR),
			                     ''Small Query Resource Semaphore'') AS [forced_grant_count],
					    [s].[nt_domain] ,
			            [s].[host_name] ,
			            [s].[login_name] ,
			            [s].[nt_user_name] ,
			            [s].[program_name] ,
			            [s].[client_interface_name] ,
			            [s].[login_time] ,
			            [r].[start_time] 
			    FROM    [sys].[dm_exec_sessions] AS [s]
			    INNER JOIN    [sys].[dm_exec_requests] AS [r]
			    ON      [r].[session_id] = [s].[session_id]
			    LEFT JOIN ( SELECT DISTINCT
			                        [wait].[session_id] ,
			                        ( SELECT    [waitwait].[wait_type] + N'' (''
			                                    + CAST(SUM([waitwait].[wait_duration_ms]) AS NVARCHAR(128))
			                                    + N'' ms) ''
			                          FROM      [sys].[dm_os_waiting_tasks] AS [waitwait]
			                          WHERE     [waitwait].[session_id] = [wait].[session_id]
			                          GROUP BY  [waitwait].[wait_type]
			                          ORDER BY  SUM([waitwait].[wait_duration_ms]) DESC
			                        FOR
			                          XML PATH('''') ) AS [wait_info]
			                FROM    [sys].[dm_os_waiting_tasks] AS [wait] ) AS [wt]
			    ON      [s].[session_id] = [wt].[session_id]
			    LEFT JOIN [sys].[dm_exec_query_stats] AS [query_stats]
			    ON      [r].[sql_handle] = [query_stats].[sql_handle]
						AND [r].[plan_handle] = [query_stats].[plan_handle]
			            AND [r].[statement_start_offset] = [query_stats].[statement_start_offset]
			            AND [r].[statement_end_offset] = [query_stats].[statement_end_offset]
			    LEFT JOIN [sys].[dm_exec_query_memory_grants] [qmg]
			    ON      [r].[session_id] = [qmg].[session_id]
						AND [r].[request_id] = [qmg].[request_id]
			    LEFT JOIN [sys].[dm_exec_query_resource_semaphores] [qrs]
			    ON      [qmg].[resource_semaphore_id] = [qrs].[resource_semaphore_id]
					    AND [qmg].[pool_id] = [qrs].[pool_id]
			    OUTER APPLY [sys].[dm_exec_sql_text]([r].[sql_handle]) AS [dest]
			    OUTER APPLY [sys].[dm_exec_query_plan]([r].[plan_handle]) AS [derp]
			    WHERE   [r].[session_id] <> @@SPID
			            AND [s].[status] <> ''sleeping''
			    ORDER BY 2 DESC;
			    '
END
IF @ProductVersionMajor >= 11 
BEGIN
SELECT @EnhanceFlag = 
	    CASE WHEN @ProductVersionMajor = 11 AND @ProductVersionMinor >= 6020 THEN 1
		     WHEN @ProductVersionMajor = 12 AND @ProductVersionMinor >= 5000 THEN 1
		     WHEN @ProductVersionMajor = 13 AND	@ProductVersionMinor >= 1601 THEN 1
		     ELSE 0 
	    END

SELECT @StringToExecute = N'
					    SELECT  GETDATE() AS [run_date] ,
			            CONVERT(VARCHAR, DATEADD(ms, [r].[total_elapsed_time], 0), 114) AS [elapsed_time] ,
			            [s].[session_id] ,
			            [wt].[wait_info] ,
			            [s].[status] ,
			            ISNULL(SUBSTRING([dest].[text],
			                             ( [query_stats].[statement_start_offset] / 2 ) + 1,
			                             ( ( CASE [query_stats].[statement_end_offset]
			                                   WHEN -1 THEN DATALENGTH([dest].[text])
			                                   ELSE [query_stats].[statement_end_offset]
			                                 END - [query_stats].[statement_start_offset] )
			                               / 2 ) + 1), [dest].[text]) AS [query_text] ,
			            [derp].[query_plan] ,
			            [qmg].[query_cost] ,
					    [r].[blocking_session_id] ,
			            [r].[cpu_time] AS [request_cpu_time],
			            [r].[logical_reads] AS [request_logical_reads],
			            [r].[writes] AS [request_writes],
			            [r].[reads] AS [request_physical_reads] ,
			            [s].[cpu_time] AS [session_cpu],
			            [s].[logical_reads] AS [session_logical_reads],
			            [s].[reads] AS [session_physical_reads] ,
			            [s].[writes] AS [session_writes],
			            [s].[memory_usage] ,
			            [r].[estimated_completion_time] ,
			            [r].[deadlock_priority] ,'
					    + 
					    CASE @EnhanceFlag
					    WHEN 1 THEN @EnhanceSQL
					    ELSE N'' END +
					    N'CASE [s].[transaction_isolation_level]
			              WHEN 0 THEN ''Unspecified''
			              WHEN 1 THEN ''Read Uncommitted''
			              WHEN 2 THEN ''Read Committed''
			              WHEN 3 THEN ''Repeatable Read''
			              WHEN 4 THEN ''Serializable''
			              WHEN 5 THEN ''Snapshot''
			              ELSE ''WHAT HAVE YOU DONE?''
			            END AS [transaction_isolation_level] ,
			            [r].[open_transaction_count] ,
			            [qmg].[dop] AS [degree_of_parallelism] ,
			            [qmg].[request_time] ,
			            COALESCE(CAST([qmg].[grant_time] AS VARCHAR), ''Memory Not Granted'') AS [grant_time] ,
			            [qmg].[requested_memory_kb] ,
			            [qmg].[granted_memory_kb] AS [grant_memory_kb],
			            CASE WHEN [qmg].[grant_time] IS NULL THEN ''N/A''
                             WHEN [qmg].[requested_memory_kb] < [qmg].[granted_memory_kb]
			                 THEN ''Query Granted Less Than Query Requested''
			                 ELSE ''Memory Request Granted''
			            END AS [is_request_granted] ,
			            [qmg].[required_memory_kb] ,
			            [qmg].[used_memory_kb] ,
			            [qmg].[ideal_memory_kb] ,
			            [qmg].[is_small] ,
			            [qmg].[timeout_sec] ,
			            [qmg].[resource_semaphore_id] ,
			            COALESCE(CAST([qmg].[wait_order] AS VARCHAR), ''N/A'') AS [wait_order] ,
			            COALESCE(CAST([qmg].[wait_time_ms] AS VARCHAR),
			                     ''N/A'') AS [wait_time_ms] ,
			            CASE [qmg].[is_next_candidate]
			              WHEN 0 THEN ''No''
			              WHEN 1 THEN ''Yes''
			              ELSE ''N/A''
			            END AS [next_candidate_for_memory_grant] ,
			            [qrs].[target_memory_kb] ,
			            COALESCE(CAST([qrs].[max_target_memory_kb] AS VARCHAR),
			                     ''Small Query Resource Semaphore'') AS [max_target_memory_kb] ,
			            [qrs].[total_memory_kb] ,
			            [qrs].[available_memory_kb] ,
			            [qrs].[granted_memory_kb] ,
			            [qrs].[used_memory_kb] ,
			            [qrs].[grantee_count] ,
			            [qrs].[waiter_count] ,
			            [qrs].[timeout_error_count] ,
			            COALESCE(CAST([qrs].[forced_grant_count] AS VARCHAR),
			                     ''Small Query Resource Semaphore'') AS [forced_grant_count],
					    [s].[nt_domain] ,
			            [s].[host_name] ,
			            [s].[login_name] ,
			            [s].[nt_user_name] ,
			            [s].[program_name] ,
			            [s].[client_interface_name] ,
			            [s].[login_time] ,
			            [r].[start_time] 
			    FROM    [sys].[dm_exec_sessions] AS [s]
			    INNER JOIN    [sys].[dm_exec_requests] AS [r]
			    ON      [r].[session_id] = [s].[session_id]
			    LEFT JOIN ( SELECT DISTINCT
			                        [wait].[session_id] ,
			                        ( SELECT    [waitwait].[wait_type] + N'' (''
			                                    + CAST(SUM([waitwait].[wait_duration_ms]) AS NVARCHAR(128))
			                                    + N'' ms) ''
			                          FROM      [sys].[dm_os_waiting_tasks] AS [waitwait]
			                          WHERE     [waitwait].[session_id] = [wait].[session_id]
			                          GROUP BY  [waitwait].[wait_type]
			                          ORDER BY  SUM([waitwait].[wait_duration_ms]) DESC
			                        FOR
			                          XML PATH('''') ) AS [wait_info]
			                FROM    [sys].[dm_os_waiting_tasks] AS [wait] ) AS [wt]
			    ON      [s].[session_id] = [wt].[session_id]
			    LEFT JOIN [sys].[dm_exec_query_stats] AS [query_stats]
			    ON      [r].[sql_handle] = [query_stats].[sql_handle]
						AND [r].[plan_handle] = [query_stats].[plan_handle]
			            AND [r].[statement_start_offset] = [query_stats].[statement_start_offset]
			            AND [r].[statement_end_offset] = [query_stats].[statement_end_offset]
			    LEFT JOIN [sys].[dm_exec_query_memory_grants] [qmg]
			    ON      [r].[session_id] = [qmg].[session_id]
						AND [r].[request_id] = [qmg].[request_id]
			    LEFT JOIN [sys].[dm_exec_query_resource_semaphores] [qrs]
			    ON      [qmg].[resource_semaphore_id] = [qrs].[resource_semaphore_id]
					    AND [qmg].[pool_id] = [qrs].[pool_id]
			    OUTER APPLY [sys].[dm_exec_sql_text]([r].[sql_handle]) AS [dest]
			    OUTER APPLY [sys].[dm_exec_query_plan]([r].[plan_handle]) AS [derp]
			    WHERE   [r].[session_id] <> @@SPID
			            AND [s].[status] <> ''sleeping''
			    ORDER BY 2 DESC;
			    '

END 

EXEC(@StringToExecute);

END;

CREATE procedure dbo.sp_creatediagram
	(
		@diagramname 	sysname,
		@owner_id		int	= null, 	
		@version 		int,
		@definition 	varbinary(max)
	)
	WITH EXECUTE AS 'dbo'
	AS
	BEGIN
		set nocount on
	
		declare @theId int
		declare @retval int
		declare @IsDbo	int
		declare @userName sysname
		if(@version is null or @diagramname is null)
		begin
			RAISERROR (N'E_INVALIDARG', 16, 1);
			return -1
		end
	
		execute as caller;
		select @theId = DATABASE_PRINCIPAL_ID(); 
		select @IsDbo = IS_MEMBER(N'db_owner');
		revert; 
		
		if @owner_id is null
		begin
			select @owner_id = @theId;
		end
		else
		begin
			if @theId <> @owner_id
			begin
				if @IsDbo = 0
				begin
					RAISERROR (N'E_INVALIDARG', 16, 1);
					return -1
				end
				select @theId = @owner_id
			end
		end
		-- next 2 line only for test, will be removed after define name unique
		if EXISTS(select diagram_id from dbo.sysdiagrams where principal_id = @theId and name = @diagramname)
		begin
			RAISERROR ('The name is already used.', 16, 1);
			return -2
		end
	
		insert into dbo.sysdiagrams(name, principal_id , version, definition)
				VALUES(@diagramname, @theId, @version, @definition) ;
		
		select @retval = @@IDENTITY 
		return @retval
	END;

CREATE PROCEDURE [dbo].[sp_dashboards_atendimentos_conversoes]
(
	@ContaSistemaId						int = 0,
	@DtInicio							as date = null,
	@DtFim								as date = null
)
AS
BEGIN

    SET NOCOUNT ON

	if @DtInicio is null begin
		set @DtInicio = DATEADD(MONTH, -3, dbo.GetDateCustom())
	end

	if @DtFim is null begin
		set @DtFim = dbo.GetDateCustom()
	end

	DECLARE	@tResult table(
		mes											int not null,
		ano											int not null,
		mesAno										char(7) null,
		dtMesAno									date null,

		UsuarioContaSistemaAtendendoId				int null,
		UsuarioContaSistemaAtendendoNome			varchar(200) null,

		CanalId										int null,
		CanalNome									varchar(300) null,

		MidiaId										int null,
		MidiaNome									varchar(500) null,

		AtendimentoStatus							varchar(100) not null,

		AtendimentoConvercaoVenda					bit not null,

		MotivacaoNaoConversaoVendaId				int null,
		MotivacaoNaoConversaoVendaNome				varchar(500) null,

		AtendimentoConvercaoVendaComputado			varchar(100) null,

		qtdTotal									int not null default 0
	)

	IF @ContaSistemaId <> 0 BEGIN

		INSERT
		INTO	@tResult(
					mes,
					ano,
					UsuarioContaSistemaAtendendoId,
					UsuarioContaSistemaAtendendoNome,
					CanalId,
					CanalNome,
					MidiaId,
					MidiaNome,
					AtendimentoStatus,
					AtendimentoConvercaoVenda,
					MotivacaoNaoConversaoVendaId,
					MotivacaoNaoConversaoVendaNome,
					AtendimentoConvercaoVendaComputado,
					qtdTotal
				)
		SELECT		MONTH(AtendimentoDtConclusao),
					YEAR(AtendimentoDtConclusao),
					UsuarioContaSistemaAtendendoId,
					UsuarioContaSistemaAtendendoNome,
					CanalId,
					CanalNome,
					MidiaId,
					MidiaNome,
					AtendimentoStatus,
					AtendimentoConvercaoVenda,
					MotivacaoNaoConversaoVendaId,
					MotivacaoNaoConversaoVendaNome,
					AtendimentoConvercaoVendaComputado,
					count(*)
		FROM		dbo.v_dashboards_atendimentos as vda
		WHERE		vda.ContaSistemaId = @ContaSistemaId and
					--AtendimentoDtInclusao >= DATEADD(YEAR, -3, GETDATE())
					AtendimentoDtConclusao Between @DtInicio and @DtFim
		GROUP BY	MONTH(AtendimentoDtConclusao),
					YEAR(AtendimentoDtConclusao),
					UsuarioContaSistemaAtendendoId,
					UsuarioContaSistemaAtendendoNome,
					CanalId,
					CanalNome,
					MidiaId,
					MidiaNome,
					AtendimentoStatus,
					AtendimentoConvercaoVenda,
					MotivacaoNaoConversaoVendaId,
					MotivacaoNaoConversaoVendaNome,
					AtendimentoConvercaoVendaComputado

		-- Usuarios
		UPDATE		@tResult
		SET			UsuarioContaSistemaAtendendoId = 0,
					UsuarioContaSistemaAtendendoNome = '* Nenhum'
		WHERE		UsuarioContaSistemaAtendendoId IS NULL


		-- Canais
		UPDATE		@tResult
		SET			CanalId = 0,
					CanalNome = '* Nenhum'
		WHERE		CanalId IS NULL

		-- Midias
		UPDATE		@tResult
		SET			MidiaId = 0,
					MidiaNome = '* Nenhum'
		WHERE		MidiaId IS NULL

		-- MotivacaoNaoConversao
		UPDATE		@tResult
		SET			MotivacaoNaoConversaoVendaId = 0,
					MotivacaoNaoConversaoVendaNome = '* Nenhum'
		WHERE		MotivacaoNaoConversaoVendaId IS NULL


		-- Mes e Ano
		UPDATE		@tResult
		SET			mesAno = (CASE WHEN mes<10 THEN '0' + CAST(mes as varchar(1)) ELSE CAST(mes as varchar(2)) END) + '/' + CAST(ano as varchar(4))

		UPDATE		@tResult
		SET			dtMesAno = CAST('01/' + mesAno as date)

	END

	-- Final Result
    SELECT		*
	FROM		@tResult
	ORDER BY	ano, mes	

END;

-- =============================================
-- Author:      Ricardo
-- Create Date: 02/08/2022
-- Description: Proc de apoio à dashboards
-- =============================================
CREATE PROCEDURE [dbo].[sp_dashboards_atendimentos_usuarios_grupos]
(
	@ContaSistemaId						int = 0,
	@DtInicio							as date = null,
	@DtFim								as date = null
)
AS
BEGIN

    SET NOCOUNT ON

	if @DtInicio is null begin
		set @DtInicio = DATEADD(MONTH, -3, dbo.GetDateCustom())
	end

	if @DtFim is null begin
		set @DtFim = dbo.GetDateCustom()
	end

	DECLARE	@tResult table(
		mes											int not null,
		ano											int not null,
		mesAno										char(7) null,
		dtMesAno									date null,

		UsuarioContaSistemaIdCriouAtendimento		int null,
		UsuarioContaSistemaNomeCriouAtendimento		varchar(200) null,

		GrupoId										int null,
		GrupoNome									varchar(60) null,

		CanalId										int null,
		CanalNome									varchar(300) null,

		MidiaId										int null,
		MidiaNome									varchar(500) null,

		ClassificacaoFaseId							int not null,
		ClassificacaoFaseNome						varchar(200) not null,

		QtdDiasSemInteracao							int null,

		QtdAtendimentoSemInteracao_1_5				int not null default 0,
		QtdAtendimentoSemInteracao_6_10				int not null default 0,
		QtdAtendimentoSemInteracao_mais_11			int not null default 0,

		qtdTotal									int not null default 0
	)

	IF @ContaSistemaId <> 0 BEGIN

		INSERT
		INTO	@tResult(
					mes,
					ano,
					UsuarioContaSistemaIdCriouAtendimento,
					UsuarioContaSistemaNomeCriouAtendimento,
					GrupoId,
					GrupoNome,
					CanalId,
					CanalNome,
					MidiaId,
					MidiaNome,
					ClassificacaoFaseId,
					ClassificacaoFaseNome,
					qtdTotal
				)
		SELECT		MONTH(AtendimentoDtInclusao),
					YEAR(AtendimentoDtInclusao),
					UsuarioContaSistemaAtendendoId,
					UsuarioContaSistemaAtendendoNome,
					GrupoId,
					GrupoNome,
					CanalId,
					CanalNome,
					MidiaId,
					MidiaNome,
					ClassificacaoFaseId,
					ClassificacaoFaseNome,
					count(*)

		FROM		dbo.[function_dashboards_atendimentos] (@ContaSistemaId,@DtInicio,@DtFim)  as vda
		GROUP BY	MONTH(AtendimentoDtInclusao),
					YEAR(AtendimentoDtInclusao),
					UsuarioContaSistemaAtendendoId,
					UsuarioContaSistemaAtendendoNome,
					GrupoId,
					GrupoNome,
					CanalId,
					CanalNome,
					MidiaId,
					MidiaNome,
					ClassificacaoFaseId,
					ClassificacaoFaseNome

		-- Usuarios
		UPDATE		@tResult
		SET			UsuarioContaSistemaIdCriouAtendimento = 0,
					UsuarioContaSistemaNomeCriouAtendimento = '* Nenhum'
		WHERE		UsuarioContaSistemaIdCriouAtendimento IS NULL

		-- Grupos
		UPDATE		@tResult
		SET			GrupoId = 0,
					GrupoNome = '* Nenhum'
		WHERE		GrupoId IS NULL

		-- Canais
		UPDATE		@tResult
		SET			CanalId = 0,
					CanalNome = '* Nenhum'
		WHERE		CanalId IS NULL

		-- Midias
		UPDATE		@tResult
		SET			MidiaId = 0,
					MidiaNome = '* Nenhum'
		WHERE		MidiaId IS NULL

		-- Mes e Ano
		UPDATE		@tResult
		SET			mesAno = (CASE WHEN mes<10 THEN '0' + CAST(mes as varchar(1)) ELSE CAST(mes as varchar(2)) END) + '/' + CAST(ano as varchar(4))

		UPDATE		@tResult
		SET			dtMesAno = CAST('01/' + mesAno as date)

		UPDATE		@tResult
		SET			QtdAtendimentoSemInteracao_1_5 = ( 
											SELECT		count(*)
											FROM		dbo.v_dashboards_atendimentos as v
											WHERE		v.ContaSistemaId = @ContaSistemaId and
														v.AtendimentoDtInclusao Between @DtInicio and @DtFim and
														MONTH(v.AtendimentoDtInclusao) = r.mes and
														YEAR(v.AtendimentoDtInclusao) = r.ano and
														v.GrupoId = r.GrupoId and
														v.CanalId = r.CanalId and
														( v.MidiaId = r.MidiaId OR (r.MidiaId=0 AND v.MidiaId IS NULL )) and
														v.ClassificacaoFaseId = r.ClassificacaoFaseId and
														v.UsuarioContaSistemaAtendendoId != 0 and
														v.UsuarioContaSistemaAtendendoId = r.UsuarioContaSistemaIdCriouAtendimento and
														v.AtendimentoQtdDiasSemInteracao between 1 and 5
										),
					QtdAtendimentoSemInteracao_6_10 = ( 
											SELECT		count(*)
											FROM		dbo.v_dashboards_atendimentos as v
											WHERE		v.ContaSistemaId = @ContaSistemaId and
														v.AtendimentoDtInclusao Between @DtInicio and @DtFim and
														MONTH(v.AtendimentoDtInclusao) = r.mes and
														YEAR(v.AtendimentoDtInclusao) = r.ano and
														v.GrupoId = r.GrupoId and
														v.CanalId = r.CanalId and
														( v.MidiaId = r.MidiaId OR (r.MidiaId=0 AND v.MidiaId IS NULL )) and
														v.ClassificacaoFaseId = r.ClassificacaoFaseId and
														v.UsuarioContaSistemaAtendendoId != 0 and
														v.UsuarioContaSistemaAtendendoId = r.UsuarioContaSistemaIdCriouAtendimento and
														v.AtendimentoQtdDiasSemInteracao between 6 and 10
										),
					QtdAtendimentoSemInteracao_mais_11 = ( 
											SELECT		count(*)
											FROM		dbo.v_dashboards_atendimentos as v
											WHERE		v.ContaSistemaId = @ContaSistemaId and
														v.AtendimentoDtInclusao Between @DtInicio and @DtFim and
														MONTH(v.AtendimentoDtInclusao) = r.mes and
														YEAR(v.AtendimentoDtInclusao) = r.ano and
														v.GrupoId = r.GrupoId and
														v.CanalId = r.CanalId and
														( v.MidiaId = r.MidiaId OR (r.MidiaId=0 AND v.MidiaId IS NULL )) and
														v.ClassificacaoFaseId = r.ClassificacaoFaseId and
														v.UsuarioContaSistemaAtendendoId != 0 and
														v.UsuarioContaSistemaAtendendoId = r.UsuarioContaSistemaIdCriouAtendimento and
														v.AtendimentoQtdDiasSemInteracao > 10
										)

		FROM		@tResult as r


	END

	-- Final Result
    SELECT		*
	FROM		@tResult
	ORDER BY	ano, mes	

END;

-- exec sp_dashboards_interacoes

CREATE PROCEDURE [dbo].[sp_dashboards_interacoes]
(
	@ContaSistemaId						int = 0,
	@DtInicio							as date = null,
	@DtFim								as date = null
)
AS
BEGIN

    SET NOCOUNT ON

	if @DtInicio is null begin
		set @DtInicio = DATEADD(MONTH, -3, dbo.GetDateCustom())
	end

	if @DtFim is null begin
		set @DtFim = dbo.GetDateCustom()
	end

	DECLARE	@tResult table(
		mes											int not null,
		ano											int not null,
		mesAno										char(7) null,
		dtMesAno									date null,

		UsuarioContaSistemaIncluiuId				int null,
		UsuarioContaSistemaIncluiuNome				varchar(200) null,

		IdInteracaoTipo								int null,
		InteracaoTipoNome							varchar(60) null,

		InteracoesVendasNaoRealizadas				int null,
		InteracoesVendasRealizadas					int null,

		qtdTotal									int not null default 0
	)

	DECLARE	@tCountInteracoes table(
		mes											int not null,
		ano											int not null,

		InteracoesVendasNaoRealizadas				int null,
		InteracoesVendasRealizadas					int null
	)
	

	IF @ContaSistemaId <> 0 BEGIN

		INSERT
		INTO	@tResult(
					mes,
					ano,
					UsuarioContaSistemaIncluiuId,
					UsuarioContaSistemaIncluiuNome,
					IdInteracaoTipo,
					InteracaoTipoNome,
					qtdTotal
				)
		SELECT		MONTH(DtInteracaoInclusao),
					YEAR(DtInteracaoInclusao),
					UsuarioContaSistemaIncluiuId,
					UsuarioContaSistemaIncluiuNome,
					IdInteracaoTipo,
					InteracaoTipoNome,
					count(*)
		FROM		dbo.v_dashboards_interacoes as vda with(nolock)
		WHERE		vda.ContaSistemaId = @ContaSistemaId
					and DtInteracaoInclusao between @DtInicio and @DtFim
		GROUP BY	MONTH(DtInteracaoInclusao),
					YEAR(DtInteracaoInclusao),
					UsuarioContaSistemaIncluiuId,
					UsuarioContaSistemaIncluiuNome,
					IdInteracaoTipo,
					InteracaoTipoNome

		INSERT
		INTO		@tCountInteracoes(mes, ano)
		SELECT		DISTINCT t.mes, t.ano
		FROM		@tResult as t

		-- Usuarios
		UPDATE		@tResult
		SET			UsuarioContaSistemaIncluiuId = 0,
					UsuarioContaSistemaIncluiuNome = '* Nenhum'
		WHERE		UsuarioContaSistemaIncluiuId IS NULL

		-- Mes e Ano
		UPDATE		@tResult
		SET			mesAno = (CASE WHEN mes<10 THEN '0' + CAST(mes as varchar(1)) ELSE CAST(mes as varchar(2)) END) + '/' + CAST(ano as varchar(4))

		UPDATE		@tResult
		SET			dtMesAno = CAST('01/' + mesAno as date)

		update		@tCountInteracoes
		SET			InteracoesVendasNaoRealizadas = dbo.CountInteracoesAtendimentosSemVenda(
														@ContaSistemaId,
														t.mes,
														t.ano
													),
					InteracoesVendasRealizadas = dbo.CountInteracoesAtendimentosComVenda(
														@ContaSistemaId,
														t.mes,
														t.ano
													)
		FROM		@tCountInteracoes AS t


		UPDATE		@tResult
		SET			InteracoesVendasNaoRealizadas = i.InteracoesVendasNaoRealizadas,
					InteracoesVendasRealizadas = i.InteracoesVendasRealizadas
		FROM		@tResult as t
						INNER JOIN @tCountInteracoes as i on
							t.mes = i.mes and
							t.ano = i.ano
		
	END

	-- Final Result
    SELECT		*
	FROM		@tResult
	ORDER BY	ano, mes	

END;

CREATE procedure dbo.sp_dropdiagram
	(
		@diagramname 	sysname,
		@owner_id	int	= null
	)
	WITH EXECUTE AS 'dbo'
	AS
	BEGIN
		set nocount on
		declare @theId 			int
		declare @IsDbo 			int
		
		declare @UIDFound 		int
		declare @DiagId			int
	
		if(@diagramname is null)
		begin
			RAISERROR ('Invalid value', 16, 1);
			return -1
		end
	
		EXECUTE AS CALLER;
		select @theId = DATABASE_PRINCIPAL_ID();
		select @IsDbo = IS_MEMBER(N'db_owner'); 
		if(@owner_id is null)
			select @owner_id = @theId;
		REVERT; 
		
		select @DiagId = diagram_id, @UIDFound = principal_id from dbo.sysdiagrams where principal_id = @owner_id and name = @diagramname 
		if(@DiagId IS NULL or (@IsDbo = 0 and @UIDFound <> @theId))
		begin
			RAISERROR ('Diagram does not exist or you do not have permission.', 16, 1)
			return -3
		end
	
		delete from dbo.sysdiagrams where diagram_id = @DiagId;
	
		return 0;
	END;

CREATE procedure dbo.sp_helpdiagramdefinition
	(
		@diagramname 	sysname,
		@owner_id	int	= null 		
	)
	WITH EXECUTE AS N'dbo'
	AS
	BEGIN
		set nocount on

		declare @theId 		int
		declare @IsDbo 		int
		declare @DiagId		int
		declare @UIDFound	int
	
		if(@diagramname is null)
		begin
			RAISERROR (N'E_INVALIDARG', 16, 1);
			return -1
		end
	
		execute as caller;
		select @theId = DATABASE_PRINCIPAL_ID();
		select @IsDbo = IS_MEMBER(N'db_owner');
		if(@owner_id is null)
			select @owner_id = @theId;
		revert; 
	
		select @DiagId = diagram_id, @UIDFound = principal_id from dbo.sysdiagrams where principal_id = @owner_id and name = @diagramname;
		if(@DiagId IS NULL or (@IsDbo = 0 and @UIDFound <> @theId ))
		begin
			RAISERROR ('Diagram does not exist or you do not have permission.', 16, 1);
			return -3
		end

		select version, definition FROM dbo.sysdiagrams where diagram_id = @DiagId ; 
		return 0
	END;

CREATE procedure dbo.sp_helpdiagrams
	(
		@diagramname sysname = NULL,
		@owner_id int = NULL
	)
	WITH EXECUTE AS N'dbo'
	AS
	BEGIN
		DECLARE @user sysname
		DECLARE @dboLogin bit
		EXECUTE AS CALLER;
			SET @user = USER_NAME();
			SET @dboLogin = CONVERT(bit,IS_MEMBER('db_owner'));
		REVERT;
		SELECT
			[Database] = DB_NAME(),
			[Name] = name,
			[ID] = diagram_id,
			[Owner] = USER_NAME(principal_id),
			[OwnerID] = principal_id
		FROM
			sysdiagrams
		WHERE
			(@dboLogin = 1 OR USER_NAME(principal_id) = @user) AND
			(@diagramname IS NULL OR name = @diagramname) AND
			(@owner_id IS NULL OR principal_id = @owner_id)
		ORDER BY
			4, 5, 1
	END;

CREATE procedure [dbo].[sp_io]
AS
SELECT TOP 10
creation_time
, last_execution_time
, total_logical_reads AS [LogicalReads] , total_logical_writes AS [LogicalWrites] , execution_count
, total_logical_reads+total_logical_writes AS [AggIO] , (total_logical_reads+total_logical_writes)/(execution_count+0.0) AS [AvgIO] , st.TEXT
, DB_NAME(st.dbid) AS database_name
, st.objectid AS OBJECT_ID
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(sql_handle) st
WHERE total_logical_reads+total_logical_writes > 0
AND sql_handle IS NOT NULL
ORDER BY [AggIO] DESC;

CREATE procedure [dbo].[sp_lock1] 
WITH RECOMPILE
AS
	SELECT TOP 10 
		r.session_id, 
		r.plan_handle,      
		r.sql_handle, 
		r.request_id,      
		r.start_time, 
		r.status,      
		r.command, 
		r.database_id,      
		r.user_id, 
		r.wait_type,      
		r.wait_time, 
		r.last_wait_type,      
		r.wait_resource, 
		r.total_elapsed_time,      
		r.cpu_time, 
		r.transaction_isolation_level,      
		r.row_count, 
		st.text  
	FROM 
		sys.dm_exec_requests r  
			CROSS APPLY 
		sys.dm_exec_sql_text(r.sql_handle) as st  
	WHERE 
		r.blocking_session_id = 0       and 
		r.session_id in       (SELECT distinct(blocking_session_id)           FROM sys.dm_exec_requests)  
		
	GROUP BY 
		r.session_id, 
		r.plan_handle,      
		r.sql_handle, 
		r.request_id,      
		r.start_time, 
		r.status,      
		r.command, 
		r.database_id,      
		r.user_id, 
		r.wait_type,      
		r.wait_time, 
		r.last_wait_type,      
		r.wait_resource, 
		r.total_elapsed_time,      
		r.cpu_time, 
		r.transaction_isolation_level,      
		r.row_count, st.text  
	
	ORDER BY 
		r.total_elapsed_time desc;

CREATE procedure sp_lock3
AS
/***************************************************************************************************** 
Use sp_who3 to first view the current system load and to identify a session, users, sessions and/or 
processes in an instance of the SQL Server by using the latest DMVs and T-SQL features.
   
Create by @ronascentes Date: 31-Jul-2011
https://github.com/ronascentes/sql-tools/edit/master/sp_who3
*******************************************************************************************/
BEGIN
	SET NOCOUNT ON;
    SELECT  r.blocking_session_id,
            dtlbl.request_type AS blocking_request_type,
            destbl.[text] AS blocking_sql,
            DB_NAME(dtl.resource_database_id) AS db_name,
            dtl.request_session_id AS waiting_session_id,  
            dowt.resource_description,
            r.wait_type,
            dowt.wait_duration_ms,
            dtl.resource_associated_entity_id AS waiting_associated_entity,
            dtl.resource_type AS waiting_resource_type,
            dtl.request_type AS waiting_request_type,
            waiting_sql = SUBSTRING(s.text,
                            (CASE WHEN r.statement_start_offset = 0 THEN 0 ELSE r.statement_start_offset/2 END),
                            (CASE WHEN r.statement_end_offset = -1 THEN DATALENGTH(s.text) ELSE r.statement_end_offset/2 END - (
                            CASE WHEN r.statement_start_offset = 0 THEN 0 ELSE r.statement_start_offset/2 END)))
    FROM    sys.dm_tran_locks (NOLOCK) AS dtl
    JOIN    sys.dm_os_waiting_tasks (NOLOCK) AS dowt ON dtl.lock_owner_address = dowt.resource_address
    JOIN    sys.dm_exec_requests (NOLOCK) AS r ON r.session_id = dtl.request_session_id
    CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) AS s
    LEFT JOIN sys.dm_exec_requests (NOLOCK) derbl ON derbl.session_id = dowt.blocking_session_id
    OUTER APPLY sys.dm_exec_sql_text(derbl.sql_handle) AS destbl
    LEFT JOIN sys.dm_tran_locks (NOLOCK) AS dtlbl  ON derbl.session_id = dtlbl.request_session_id;
END;

CREATE procedure dbo.sp_renamediagram
	(
		@diagramname 		sysname,
		@owner_id		int	= null,
		@new_diagramname	sysname
	
	)
	WITH EXECUTE AS 'dbo'
	AS
	BEGIN
		set nocount on
		declare @theId 			int
		declare @IsDbo 			int
		
		declare @UIDFound 		int
		declare @DiagId			int
		declare @DiagIdTarg		int
		declare @u_name			sysname
		if((@diagramname is null) or (@new_diagramname is null))
		begin
			RAISERROR ('Invalid value', 16, 1);
			return -1
		end
	
		EXECUTE AS CALLER;
		select @theId = DATABASE_PRINCIPAL_ID();
		select @IsDbo = IS_MEMBER(N'db_owner'); 
		if(@owner_id is null)
			select @owner_id = @theId;
		REVERT;
	
		select @u_name = USER_NAME(@owner_id)
	
		select @DiagId = diagram_id, @UIDFound = principal_id from dbo.sysdiagrams where principal_id = @owner_id and name = @diagramname 
		if(@DiagId IS NULL or (@IsDbo = 0 and @UIDFound <> @theId))
		begin
			RAISERROR ('Diagram does not exist or you do not have permission.', 16, 1)
			return -3
		end
	
		-- if((@u_name is not null) and (@new_diagramname = @diagramname))	-- nothing will change
		--	return 0;
	
		if(@u_name is null)
			select @DiagIdTarg = diagram_id from dbo.sysdiagrams where principal_id = @theId and name = @new_diagramname
		else
			select @DiagIdTarg = diagram_id from dbo.sysdiagrams where principal_id = @owner_id and name = @new_diagramname
	
		if((@DiagIdTarg is not null) and  @DiagId <> @DiagIdTarg)
		begin
			RAISERROR ('The name is already used.', 16, 1);
			return -2
		end		
	
		if(@u_name is null)
			update dbo.sysdiagrams set [name] = @new_diagramname, principal_id = @theId where diagram_id = @DiagId
		else
			update dbo.sysdiagrams set [name] = @new_diagramname where diagram_id = @DiagId
		return 0
	END;

CREATE procedure sp_spid (@spid as int)
as
declare @sql varbinary(max)
select @sql=sql_handle 
from sys.sysprocesses
where spid=@spid
select text from sys.dm_exec_sql_text(@sql);

CREATE procedure dbo.sp_upgraddiagrams
	AS
	BEGIN
		IF OBJECT_ID(N'dbo.sysdiagrams') IS NOT NULL
			return 0;
	
		CREATE TABLE dbo.sysdiagrams
		(
			name sysname NOT NULL,
			principal_id int NOT NULL,	-- we may change it to varbinary(85)
			diagram_id int PRIMARY KEY IDENTITY,
			version int,
	
			definition varbinary(max)
			CONSTRAINT UK_principal_name UNIQUE
			(
				principal_id,
				name
			)
		);


		/* Add this if we need to have some form of extended properties for diagrams */
		/*
		IF OBJECT_ID(N'dbo.sysdiagram_properties') IS NULL
		BEGIN
			CREATE TABLE dbo.sysdiagram_properties
			(
				diagram_id int,
				name sysname,
				value varbinary(max) NOT NULL
			)
		END
		*/

		IF OBJECT_ID(N'dbo.dtproperties') IS NOT NULL
		begin
			insert into dbo.sysdiagrams
			(
				[name],
				[principal_id],
				[version],
				[definition]
			)
			select	 
				convert(sysname, dgnm.[uvalue]),
				DATABASE_PRINCIPAL_ID(N'dbo'),			-- will change to the sid of sa
				0,							-- zero for old format, dgdef.[version],
				dgdef.[lvalue]
			from dbo.[dtproperties] dgnm
				inner join dbo.[dtproperties] dggd on dggd.[property] = 'DtgSchemaGUID' and dggd.[objectid] = dgnm.[objectid]	
				inner join dbo.[dtproperties] dgdef on dgdef.[property] = 'DtgSchemaDATA' and dgdef.[objectid] = dgnm.[objectid]
				
			where dgnm.[property] = 'DtgSchemaNAME' and dggd.[uvalue] like N'_EA3E6268-D998-11CE-9454-00AA00A3F36E_' 
			return 2;
		end
		return 1;
	END;

CREATE procedure [dbo].[sp_who3] @x NVARCHAR(128) = NULL 
WITH RECOMPILE
AS
-- https://social.technet.microsoft.com/wiki/pt-br/contents/articles/31159.sql-server-sp-who3.aspx
--sp_who3 null - quem (sessão) está ativo; 
--sp_who3 1 or 'memory'  - quem está consumindo mais memória; 
--sp_who3 2 or 'cpu'  - quem está consumindo mais processamento (top 10);
--sp_who3 3 or 'count'  - quem está conectado e com quantas sessões abertas; 
--sp_who3 4 or 'idle'  - quem está inativo mas possui transações abertas; 
--sp_who3 5 or 'tempdb' - quem está rodando tarefas que usam o tempdb (top 5); e, 
--sp_who3 6 or 'block' - quem está liderando bloqueios.
/****************************************************************************************** 
   This is a current activity query used to identify what processes are currently running 
   on the processors.  Use to first view the current system load and to identify a session 
   of interest such as blocking, waiting and granted memory.  You should execute the query 
   several times to identify if a query is increasing it's I/O, CPU time or memory granted.
   
   *Revision History
   - 31-Jul-2011 (Rodrigo): Initial development
   - 12-Apr-2012 (Rodrigo): Enhanced sql_text, object_name outputs;
								  Added NOLOCK hints and RECOMPILE option;
								  Added BlkBy column;
								  Removed dead-code.
   - 03-Nov-2014 (Rodrigo): Added program_name and open_transaction_count	column
   - 10-Nov-2014 (Rodrigo): Added granted_memory_GB
   - 03-Nov-2015 (Rodrigo): Added parameters to show memory and cpu information
   - 12-Nov-2015 (Rodrigo): Added query to get IO info
   - 17-Nov-2015 (Rodrigo): Changed the logic and addedd new parameters
   - 18-Nov-2015 (Rodrigo): Added help content
*******************************************************************************************/
BEGIN
	SET NOCOUNT ON;
	IF @x IS NULL
		BEGIN
			SELECT r.session_id, r.blocking_session_id AS BlkBy, 
							   CAST(((DATEDIFF(s,start_time,GetDate()))/3600) as varchar) + ' hour(s), '
					+ CAST((DATEDIFF(s,start_time,GetDate())%3600)/60 as varchar) + 'min, '
					+ CAST((DATEDIFF(s,start_time,GetDate())%60) as varchar) + ' sec' as running_time,
					object_name = OBJECT_SCHEMA_NAME(s.objectid,s.dbid) + '.' + OBJECT_NAME(s.objectid, s.dbid),


				   sql_text = SUBSTRING	(s.text,r.statement_start_offset/2,
						(CASE WHEN r.statement_end_offset = -1 THEN LEN(CONVERT(nvarchar(MAX), s.text)) * 2
							ELSE r.statement_end_offset	END - r.statement_start_offset)/2),

					program_name = se.program_name,
					se.host_name, se.login_name,


					r.cpu_time,	start_time, percent_complete, r.open_transaction_count AS open_tran_count,		
					CAST((estimated_completion_time/3600000) as varchar) + ' hour(s), '
					+ CAST((estimated_completion_time %3600000)/60000 as varchar) + 'min, '
					+ CAST((estimated_completion_time %60000)/1000 as varchar) + ' sec' as est_time_to_go,
					dateadd(second,estimated_completion_time/1000, getdate()) as est_completion_time,
					r.status, r.command,
			
			
			
					Db_name(r.database_id) AS dbname, 
					r.open_transaction_count AS NoOfOpenTran, r.wait_type,
					CAST(ROUND((r.granted_query_memory / 128.0)  / 1024,2) AS NUMERIC(10,2))AS granted_memory_GB,
				   
 				   p.query_plan AS query_plan
			FROM   sys.dm_exec_requests r WITH (NOLOCK) 
			JOIN sys.dm_exec_sessions se WITH (NOLOCK)
				ON r.session_id = se.session_id 
			OUTER APPLY sys.dm_exec_sql_text(r.sql_handle) s 
			OUTER APPLY sys.dm_exec_query_plan(r.plan_handle) p 
			WHERE  r.session_id <> @@SPID AND se.is_user_process = 1;
		END
	ELSE IF @x = '1'  OR @x = 'memory'
		BEGIN
			-- who is consuming the memory
			SELECT session_id, granted_memory_kb FROM sys.dm_exec_query_memory_grants WITH (NOLOCK) ORDER BY 1 DESC;
		END
	ELSE IF @x = '2'  OR @x = 'cpu'
		BEGIN
			-- who has cached plans that consumed the most cumulative CPU (top 10)
			SELECT TOP 10 
							ObjectName = OBJECT_SCHEMA_NAME(t.objectid,t.dbid) + '.' + OBJECT_NAME(t.objectid, t.dbid),
							sql_text = SUBSTRING (t.text, qs.statement_start_offset/2,
										(CASE WHEN qs.statement_end_offset = -1 THEN LEN(CONVERT(nvarchar(MAX), t.text)) * 2
										ELSE qs.statement_end_offset END - qs.statement_start_offset)/2),
							
							qs.execution_count AS [Executions], qs.total_worker_time AS [Total CPU Time],
							qs.total_physical_reads AS [Disk Reads (worst reads)],	qs.total_elapsed_time AS [Duration], 
							qs.total_worker_time/qs.execution_count AS [Avg CPU Time],qs.plan_generation_num,
								qs.creation_time AS [Data Cached], qp.query_plan, DatabaseName = DB_Name(t.dbid)
			FROM sys.dm_exec_query_stats qs WITH(NOLOCK) 
			CROSS APPLY sys.dm_exec_sql_text(plan_handle) AS t
			CROSS APPLY sys.dm_exec_query_plan(plan_handle) AS qp 
			ORDER BY DatabaseName, qs.total_worker_time DESC;
		END
	ELSE IF @x = '3'  OR @x = 'count'
		BEGIN
			-- who is connected and how many sessions it has 
			SELECT login_name, [program_name],No_of_Connections = COUNT(session_id)
			FROM sys.dm_exec_sessions WITH (NOLOCK)
			WHERE session_id > 50 GROUP BY login_name, [program_name] ORDER BY COUNT(session_id) DESC
		END
	ELSE IF @x = '4'  OR @x = 'idle'
		BEGIN
			-- who is idle that have open transactions
			SELECT s.session_id, login_name, login_time, host_name, host_process_id, status FROM sys.dm_exec_sessions AS s WITH (NOLOCK)
			WHERE EXISTS (SELECT * FROM sys.dm_tran_session_transactions AS t WHERE t.session_id = s.session_id)
			AND NOT EXISTS (SELECT * FROM sys.dm_exec_requests AS r WHERE r.session_id = s.session_id)
		END
	ELSE IF @x = '5' OR @x = 'tempdb'
		BEGIN
			-- who is running tasks that use tempdb (top 5)
			SELECT TOP 5 session_id, request_id,  user_objects_alloc_page_count + internal_objects_alloc_page_count as task_alloc
			FROM    tempdb.sys.dm_db_task_space_usage  WITH (NOLOCK)
			WHERE   session_id > 50 ORDER BY user_objects_alloc_page_count + internal_objects_alloc_page_count DESC
		END
	ELSE IF @x = '6' OR @x = 'block'
		BEGIN
			-- who is blocking
			SELECT DB_NAME(lok.resource_database_id) as db_name,lok.resource_description,lok.request_type,lok.request_status,lok.request_owner_type
			,wat.session_id as wait_session_id,wat.wait_duration_ms,wat.wait_type,wat.blocking_session_id
			FROM  sys.dm_tran_locks lok WITH (NOLOCK) JOIN sys.dm_os_waiting_tasks wat WITH (NOLOCK) ON lok.lock_owner_address = wat.resource_address 
		END
	ELSE IF @x = '0' OR @x = 'help'
		BEGIN
			DECLARE @text NVARCHAR(4000);
			DECLARE @NewLineChar AS CHAR(2) = CHAR(13) + CHAR(10);
			SET @text = N'Synopsis:' + @NewLineChar +
						N'Who is currently running on my system?'  + @NewLineChar +
						N'-------------------------------------------------------------------------------------------------------------------------------------'  + @NewLineChar +
						N'Description:'  + @NewLineChar +
						N'The first area to look at on a system running SQL Server is the utilization of hardware resources, the core of which are memory,' + @NewLineChar +
						N'storage, CPU and long blockings. Use sp_who3 to first view the current system load and to identify a session of interest.' + @NewLineChar +
						N'You should execute the query several times to identify which session id is most consuming teh system resources.' + @NewLineChar +
						N'-------------------------------------------------------------------------------------------------------------------------------------' + @NewLineChar +
						N'Parameters:'  + @NewLineChar +
						N'sp_who3 null				- who is active;' + @NewLineChar +
						N'sp_who3 1 or ''memory''  	- who is consuming the memory;' + @NewLineChar +
						N'sp_who3 2 or ''cpu''  	- who has cached plans that consumed the most cumulative CPU (top 10);'+ @NewLineChar +
						N'sp_who3 3 or ''count''  	- who is connected and how many sessions it has;'+ @NewLineChar +
						N'sp_who3 4 or ''idle'' 	- who is idle that has open transactions;'+ @NewLineChar +
						N'sp_who3 5 or ''tempdb'' 	- who is running tasks that use tempdb (top 5); and,'+ @NewLineChar +
						N'sp_who3 6 or ''block'' 	- who is blocking.'
			PRINT @text;
		END
END;

/*********************************************************************************************
Who Is Active? v11.30 (2017-12-10)
(C) 2007-2017, Adam Machanic

Feedback: mailto:adam@dataeducation.com
Updates: http://whoisactive.com
Blog: http://dataeducation.com

License: 
	Who is Active? is free to download and use for personal, educational, and internal 
	corporate purposes, provided that this header is preserved. Redistribution or sale 
	of Who is Active?, in whole or in part, is prohibited without the author's express 
	written consent.
*********************************************************************************************/
CREATE PROC dbo.sp_WhoIsActive
(
--~
	--Filters--Both inclusive and exclusive
	--Set either filter to '' to disable
	--Valid filter types are: session, program, database, login, and host
	--Session is a session ID, and either 0 or '' can be used to indicate "all" sessions
	--All other filter types support % or _ as wildcards
	@filter sysname = '',
	@filter_type VARCHAR(10) = 'session',
	@not_filter sysname = '',
	@not_filter_type VARCHAR(10) = 'session',

	--Retrieve data about the calling session?
	@show_own_spid BIT = 0,

	--Retrieve data about system sessions?
	@show_system_spids BIT = 0,

	--Controls how sleeping SPIDs are handled, based on the idea of levels of interest
	--0 does not pull any sleeping SPIDs
	--1 pulls only those sleeping SPIDs that also have an open transaction
	--2 pulls all sleeping SPIDs
	@show_sleeping_spids TINYINT = 1,

	--If 1, gets the full stored procedure or running batch, when available
	--If 0, gets only the actual statement that is currently running in the batch or procedure
	@get_full_inner_text BIT = 0,

	--Get associated query plans for running tasks, if available
	--If @get_plans = 1, gets the plan based on the request's statement offset
	--If @get_plans = 2, gets the entire plan based on the request's plan_handle
	@get_plans TINYINT = 0,

	--Get the associated outer ad hoc query or stored procedure call, if available
	@get_outer_command BIT = 0,

	--Enables pulling transaction log write info and transaction duration
	@get_transaction_info BIT = 0,

	--Get information on active tasks, based on three interest levels
	--Level 0 does not pull any task-related information
	--Level 1 is a lightweight mode that pulls the top non-CXPACKET wait, giving preference to blockers
	--Level 2 pulls all available task-based metrics, including: 
	--number of active tasks, current wait stats, physical I/O, context switches, and blocker information
	@get_task_info TINYINT = 1,

	--Gets associated locks for each request, aggregated in an XML format
	@get_locks BIT = 0,

	--Get average time for past runs of an active query
	--(based on the combination of plan handle, sql handle, and offset)
	@get_avg_time BIT = 0,

	--Get additional non-performance-related information about the session or request
	--text_size, language, date_format, date_first, quoted_identifier, arithabort, ansi_null_dflt_on, 
	--ansi_defaults, ansi_warnings, ansi_padding, ansi_nulls, concat_null_yields_null, 
	--transaction_isolation_level, lock_timeout, deadlock_priority, row_count, command_type
	--
	--If a SQL Agent job is running, an subnode called agent_info will be populated with some or all of
	--the following: job_id, job_name, step_id, step_name, msdb_query_error (in the event of an error)
	--
	--If @get_task_info is set to 2 and a lock wait is detected, a subnode called block_info will be
	--populated with some or all of the following: lock_type, database_name, object_id, file_id, hobt_id, 
	--applock_hash, metadata_resource, metadata_class_id, object_name, schema_name
	@get_additional_info BIT = 0,

	--Walk the blocking chain and count the number of 
	--total SPIDs blocked all the way down by a given session
	--Also enables task_info Level 1, if @get_task_info is set to 0
	@find_block_leaders BIT = 0,

	--Pull deltas on various metrics
	--Interval in seconds to wait before doing the second data pull
	@delta_interval TINYINT = 0,

	--List of desired output columns, in desired order
	--Note that the final output will be the intersection of all enabled features and all 
	--columns in the list. Therefore, only columns associated with enabled features will 
	--actually appear in the output. Likewise, removing columns from this list may effectively
	--disable features, even if they are turned on
	--
	--Each element in this list must be one of the valid output column names. Names must be
	--delimited by square brackets. White space, formatting, and additional characters are
	--allowed, as long as the list contains exact matches of delimited valid column names.
	@output_column_list VARCHAR(8000) = '[dd%][session_id][sql_text][sql_command][login_name][wait_info][tasks][tran_log%][cpu%][temp%][block%][reads%][writes%][context%][physical%][query_plan][locks][%]',

	--Column(s) by which to sort output, optionally with sort directions. 
		--Valid column choices:
		--session_id, physical_io, reads, physical_reads, writes, tempdb_allocations, 
		--tempdb_current, CPU, context_switches, used_memory, physical_io_delta, reads_delta, 
		--physical_reads_delta, writes_delta, tempdb_allocations_delta, tempdb_current_delta, 
		--CPU_delta, context_switches_delta, used_memory_delta, tasks, tran_start_time, 
		--open_tran_count, blocking_session_id, blocked_session_count, percent_complete, 
		--host_name, login_name, database_name, start_time, login_time, program_name
		--
		--Note that column names in the list must be bracket-delimited. Commas and/or white
		--space are not required. 
	@sort_order VARCHAR(500) = '[start_time] ASC',

	--Formats some of the output columns in a more "human readable" form
	--0 disables outfput format
	--1 formats the output for variable-width fonts
	--2 formats the output for fixed-width fonts
	@format_output TINYINT = 1,

	--If set to a non-blank value, the script will attempt to insert into the specified 
	--destination table. Please note that the script will not verify that the table exists, 
	--or that it has the correct schema, before doing the insert.
	--Table can be specified in one, two, or three-part format
	@destination_table VARCHAR(4000) = '',

	--If set to 1, no data collection will happen and no result set will be returned; instead,
	--a CREATE TABLE statement will be returned via the @schema parameter, which will match 
	--the schema of the result set that would be returned by using the same collection of the
	--rest of the parameters. The CREATE TABLE statement will have a placeholder token of 
	--<table_name> in place of an actual table name.
	@return_schema BIT = 0,
	@schema VARCHAR(MAX) = NULL OUTPUT,

	--Help! What do I do?
	@help BIT = 0
--~
)
/*
OUTPUT COLUMNS
--------------
Formatted/Non:	[session_id] [smallint] NOT NULL
	Session ID (a.k.a. SPID)

Formatted:		[dd hh:mm:ss.mss] [varchar](15) NULL
Non-Formatted:	<not returned>
	For an active request, time the query has been running
	For a sleeping session, time since the last batch completed

Formatted:		[dd hh:mm:ss.mss (avg)] [varchar](15) NULL
Non-Formatted:	[avg_elapsed_time] [int] NULL
	(Requires @get_avg_time option)
	How much time has the active portion of the query taken in the past, on average?

Formatted:		[physical_io] [varchar](30) NULL
Non-Formatted:	[physical_io] [bigint] NULL
	Shows the number of physical I/Os, for active requests

Formatted:		[reads] [varchar](30) NULL
Non-Formatted:	[reads] [bigint] NULL
	For an active request, number of reads done for the current query
	For a sleeping session, total number of reads done over the lifetime of the session

Formatted:		[physical_reads] [varchar](30) NULL
Non-Formatted:	[physical_reads] [bigint] NULL
	For an active request, number of physical reads done for the current query
	For a sleeping session, total number of physical reads done over the lifetime of the session

Formatted:		[writes] [varchar](30) NULL
Non-Formatted:	[writes] [bigint] NULL
	For an active request, number of writes done for the current query
	For a sleeping session, total number of writes done over the lifetime of the session

Formatted:		[tempdb_allocations] [varchar](30) NULL
Non-Formatted:	[tempdb_allocations] [bigint] NULL
	For an active request, number of TempDB writes done for the current query
	For a sleeping session, total number of TempDB writes done over the lifetime of the session

Formatted:		[tempdb_current] [varchar](30) NULL
Non-Formatted:	[tempdb_current] [bigint] NULL
	For an active request, number of TempDB pages currently allocated for the query
	For a sleeping session, number of TempDB pages currently allocated for the session

Formatted:		[CPU] [varchar](30) NULL
Non-Formatted:	[CPU] [int] NULL
	For an active request, total CPU time consumed by the current query
	For a sleeping session, total CPU time consumed over the lifetime of the session

Formatted:		[context_switches] [varchar](30) NULL
Non-Formatted:	[context_switches] [bigint] NULL
	Shows the number of context switches, for active requests

Formatted:		[used_memory] [varchar](30) NOT NULL
Non-Formatted:	[used_memory] [bigint] NOT NULL
	For an active request, total memory consumption for the current query
	For a sleeping session, total current memory consumption

Formatted:		[physical_io_delta] [varchar](30) NULL
Non-Formatted:	[physical_io_delta] [bigint] NULL
	(Requires @delta_interval option)
	Difference between the number of physical I/Os reported on the first and second collections. 
	If the request started after the first collection, the value will be NULL

Formatted:		[reads_delta] [varchar](30) NULL
Non-Formatted:	[reads_delta] [bigint] NULL
	(Requires @delta_interval option)
	Difference between the number of reads reported on the first and second collections. 
	If the request started after the first collection, the value will be NULL

Formatted:		[physical_reads_delta] [varchar](30) NULL
Non-Formatted:	[physical_reads_delta] [bigint] NULL
	(Requires @delta_interval option)
	Difference between the number of physical reads reported on the first and second collections. 
	If the request started after the first collection, the value will be NULL

Formatted:		[writes_delta] [varchar](30) NULL
Non-Formatted:	[writes_delta] [bigint] NULL
	(Requires @delta_interval option)
	Difference between the number of writes reported on the first and second collections. 
	If the request started after the first collection, the value will be NULL

Formatted:		[tempdb_allocations_delta] [varchar](30) NULL
Non-Formatted:	[tempdb_allocations_delta] [bigint] NULL
	(Requires @delta_interval option)
	Difference between the number of TempDB writes reported on the first and second collections. 
	If the request started after the first collection, the value will be NULL

Formatted:		[tempdb_current_delta] [varchar](30) NULL
Non-Formatted:	[tempdb_current_delta] [bigint] NULL
	(Requires @delta_interval option)
	Difference between the number of allocated TempDB pages reported on the first and second 
	collections. If the request started after the first collection, the value will be NULL

Formatted:		[CPU_delta] [varchar](30) NULL
Non-Formatted:	[CPU_delta] [int] NULL
	(Requires @delta_interval option)
	Difference between the CPU time reported on the first and second collections. 
	If the request started after the first collection, the value will be NULL

Formatted:		[context_switches_delta] [varchar](30) NULL
Non-Formatted:	[context_switches_delta] [bigint] NULL
	(Requires @delta_interval option)
	Difference between the context switches count reported on the first and second collections
	If the request started after the first collection, the value will be NULL

Formatted:		[used_memory_delta] [varchar](30) NULL
Non-Formatted:	[used_memory_delta] [bigint] NULL
	Difference between the memory usage reported on the first and second collections
	If the request started after the first collection, the value will be NULL

Formatted:		[tasks] [varchar](30) NULL
Non-Formatted:	[tasks] [smallint] NULL
	Number of worker tasks currently allocated, for active requests

Formatted/Non:	[status] [varchar](30) NOT NULL
	Activity status for the session (running, sleeping, etc)

Formatted/Non:	[wait_info] [nvarchar](4000) NULL
	Aggregates wait information, in the following format:
		(Ax: Bms/Cms/Dms)E
	A is the number of waiting tasks currently waiting on resource type E. B/C/D are wait
	times, in milliseconds. If only one thread is waiting, its wait time will be shown as B.
	If two tasks are waiting, each of their wait times will be shown (B/C). If three or more 
	tasks are waiting, the minimum, average, and maximum wait times will be shown (B/C/D).
	If wait type E is a page latch wait and the page is of a "special" type (e.g. PFS, GAM, SGAM), 
	the page type will be identified.
	If wait type E is CXPACKET, the nodeId from the query plan will be identified

Formatted/Non:	[locks] [xml] NULL
	(Requires @get_locks option)
	Aggregates lock information, in XML format.
	The lock XML includes the lock mode, locked object, and aggregates the number of requests. 
	Attempts are made to identify locked objects by name

Formatted/Non:	[tran_start_time] [datetime] NULL
	(Requires @get_transaction_info option)
	Date and time that the first transaction opened by a session caused a transaction log 
	write to occur.

Formatted/Non:	[tran_log_writes] [nvarchar](4000) NULL
	(Requires @get_transaction_info option)
	Aggregates transaction log write information, in the following format:
	A:wB (C kB)
	A is a database that has been touched by an active transaction
	B is the number of log writes that have been made in the database as a result of the transaction
	C is the number of log kilobytes consumed by the log records

Formatted:		[open_tran_count] [varchar](30) NULL
Non-Formatted:	[open_tran_count] [smallint] NULL
	Shows the number of open transactions the session has open

Formatted:		[sql_command] [xml] NULL
Non-Formatted:	[sql_command] [nvarchar](max) NULL
	(Requires @get_outer_command option)
	Shows the "outer" SQL command, i.e. the text of the batch or RPC sent to the server, 
	if available

Formatted:		[sql_text] [xml] NULL
Non-Formatted:	[sql_text] [nvarchar](max) NULL
	Shows the SQL text for active requests or the last statement executed
	for sleeping sessions, if available in either case.
	If @get_full_inner_text option is set, shows the full text of the batch.
	Otherwise, shows only the active statement within the batch.
	If the query text is locked, a special timeout message will be sent, in the following format:
		<timeout_exceeded />
	If an error occurs, an error message will be sent, in the following format:
		<error message="message" />

Formatted/Non:	[query_plan] [xml] NULL
	(Requires @get_plans option)
	Shows the query plan for the request, if available.
	If the plan is locked, a special timeout message will be sent, in the following format:
		<timeout_exceeded />
	If an error occurs, an error message will be sent, in the following format:
		<error message="message" />

Formatted/Non:	[blocking_session_id] [smallint] NULL
	When applicable, shows the blocking SPID

Formatted:		[blocked_session_count] [varchar](30) NULL
Non-Formatted:	[blocked_session_count] [smallint] NULL
	(Requires @find_block_leaders option)
	The total number of SPIDs blocked by this session,
	all the way down the blocking chain.

Formatted:		[percent_complete] [varchar](30) NULL
Non-Formatted:	[percent_complete] [real] NULL
	When applicable, shows the percent complete (e.g. for backups, restores, and some rollbacks)

Formatted/Non:	[host_name] [sysname] NOT NULL
	Shows the host name for the connection

Formatted/Non:	[login_name] [sysname] NOT NULL
	Shows the login name for the connection

Formatted/Non:	[database_name] [sysname] NULL
	Shows the connected database

Formatted/Non:	[program_name] [sysname] NULL
	Shows the reported program/application name

Formatted/Non:	[additional_info] [xml] NULL
	(Requires @get_additional_info option)
	Returns additional non-performance-related session/request information
	If the script finds a SQL Agent job running, the name of the job and job step will be reported
	If @get_task_info = 2 and the script finds a lock wait, the locked object will be reported

Formatted/Non:	[start_time] [datetime] NOT NULL
	For active requests, shows the time the request started
	For sleeping sessions, shows the time the last batch completed

Formatted/Non:	[login_time] [datetime] NOT NULL
	Shows the time that the session connected

Formatted/Non:	[request_id] [int] NULL
	For active requests, shows the request_id
	Should be 0 unless MARS is being used

Formatted/Non:	[collection_time] [datetime] NOT NULL
	Time that this script's final SELECT ran
*/
AS
BEGIN;
	SET NOCOUNT ON; 
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	SET QUOTED_IDENTIFIER ON;
	SET ANSI_PADDING ON;
	SET CONCAT_NULL_YIELDS_NULL ON;
	SET ANSI_WARNINGS ON;
	SET NUMERIC_ROUNDABORT OFF;
	SET ARITHABORT ON;

	IF
		@filter IS NULL
		OR @filter_type IS NULL
		OR @not_filter IS NULL
		OR @not_filter_type IS NULL
		OR @show_own_spid IS NULL
		OR @show_system_spids IS NULL
		OR @show_sleeping_spids IS NULL
		OR @get_full_inner_text IS NULL
		OR @get_plans IS NULL
		OR @get_outer_command IS NULL
		OR @get_transaction_info IS NULL
		OR @get_task_info IS NULL
		OR @get_locks IS NULL
		OR @get_avg_time IS NULL
		OR @get_additional_info IS NULL
		OR @find_block_leaders IS NULL
		OR @delta_interval IS NULL
		OR @format_output IS NULL
		OR @output_column_list IS NULL
		OR @sort_order IS NULL
		OR @return_schema IS NULL
		OR @destination_table IS NULL
		OR @help IS NULL
	BEGIN;
		RAISERROR('Input parameters cannot be NULL', 16, 1);
		RETURN;
	END;
	
	IF @filter_type NOT IN ('session', 'program', 'database', 'login', 'host')
	BEGIN;
		RAISERROR('Valid filter types are: session, program, database, login, host', 16, 1);
		RETURN;
	END;
	
	IF @filter_type = 'session' AND @filter LIKE '%[^0123456789]%'
	BEGIN;
		RAISERROR('Session filters must be valid integers', 16, 1);
		RETURN;
	END;
	
	IF @not_filter_type NOT IN ('session', 'program', 'database', 'login', 'host')
	BEGIN;
		RAISERROR('Valid filter types are: session, program, database, login, host', 16, 1);
		RETURN;
	END;
	
	IF @not_filter_type = 'session' AND @not_filter LIKE '%[^0123456789]%'
	BEGIN;
		RAISERROR('Session filters must be valid integers', 16, 1);
		RETURN;
	END;
	
	IF @show_sleeping_spids NOT IN (0, 1, 2)
	BEGIN;
		RAISERROR('Valid values for @show_sleeping_spids are: 0, 1, or 2', 16, 1);
		RETURN;
	END;
	
	IF @get_plans NOT IN (0, 1, 2)
	BEGIN;
		RAISERROR('Valid values for @get_plans are: 0, 1, or 2', 16, 1);
		RETURN;
	END;

	IF @get_task_info NOT IN (0, 1, 2)
	BEGIN;
		RAISERROR('Valid values for @get_task_info are: 0, 1, or 2', 16, 1);
		RETURN;
	END;

	IF @format_output NOT IN (0, 1, 2)
	BEGIN;
		RAISERROR('Valid values for @format_output are: 0, 1, or 2', 16, 1);
		RETURN;
	END;
	
	IF @help = 1
	BEGIN;
		DECLARE 
			@header VARCHAR(MAX),
			@params VARCHAR(MAX),
			@outputs VARCHAR(MAX);

		SELECT 
			@header =
				REPLACE
				(
					REPLACE
					(
						CONVERT
						(
							VARCHAR(MAX),
							SUBSTRING
							(
								t.text, 
								CHARINDEX('/' + REPLICATE('*', 93), t.text) + 94,
								CHARINDEX(REPLICATE('*', 93) + '/', t.text) - (CHARINDEX('/' + REPLICATE('*', 93), t.text) + 94)
							)
						),
						CHAR(13)+CHAR(10),
						CHAR(13)
					),
					'	',
					''
				),
			@params =
				CHAR(13) +
					REPLACE
					(
						REPLACE
						(
							CONVERT
							(
								VARCHAR(MAX),
								SUBSTRING
								(
									t.text, 
									CHARINDEX('--~', t.text) + 5, 
									CHARINDEX('--~', t.text, CHARINDEX('--~', t.text) + 5) - (CHARINDEX('--~', t.text) + 5)
								)
							),
							CHAR(13)+CHAR(10),
							CHAR(13)
						),
						'	',
						''
					),
				@outputs = 
					CHAR(13) +
						REPLACE
						(
							REPLACE
							(
								REPLACE
								(
									CONVERT
									(
										VARCHAR(MAX),
										SUBSTRING
										(
											t.text, 
											CHARINDEX('OUTPUT COLUMNS'+CHAR(13)+CHAR(10)+'--------------', t.text) + 32,
											CHARINDEX('*/', t.text, CHARINDEX('OUTPUT COLUMNS'+CHAR(13)+CHAR(10)+'--------------', t.text) + 32) - (CHARINDEX('OUTPUT COLUMNS'+CHAR(13)+CHAR(10)+'--------------', t.text) + 32)
										)
									),
									CHAR(9),
									CHAR(255)
								),
								CHAR(13)+CHAR(10),
								CHAR(13)
							),
							'	',
							''
						) +
						CHAR(13)
		FROM sys.dm_exec_requests AS r
		CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) AS t
		WHERE
			r.session_id = @@SPID;

		WITH
		a0 AS
		(SELECT 1 AS n UNION ALL SELECT 1),
		a1 AS
		(SELECT 1 AS n FROM a0 AS a, a0 AS b),
		a2 AS
		(SELECT 1 AS n FROM a1 AS a, a1 AS b),
		a3 AS
		(SELECT 1 AS n FROM a2 AS a, a2 AS b),
		a4 AS
		(SELECT 1 AS n FROM a3 AS a, a3 AS b),
		numbers AS
		(
			SELECT TOP(LEN(@header) - 1)
				ROW_NUMBER() OVER
				(
					ORDER BY (SELECT NULL)
				) AS number
			FROM a4
			ORDER BY
				number
		)
		SELECT
			RTRIM(LTRIM(
				SUBSTRING
				(
					@header,
					number + 1,
					CHARINDEX(CHAR(13), @header, number + 1) - number - 1
				)
			)) AS [------header---------------------------------------------------------------------------------------------------------------]
		FROM numbers
		WHERE
			SUBSTRING(@header, number, 1) = CHAR(13);

		WITH
		a0 AS
		(SELECT 1 AS n UNION ALL SELECT 1),
		a1 AS
		(SELECT 1 AS n FROM a0 AS a, a0 AS b),
		a2 AS
		(SELECT 1 AS n FROM a1 AS a, a1 AS b),
		a3 AS
		(SELECT 1 AS n FROM a2 AS a, a2 AS b),
		a4 AS
		(SELECT 1 AS n FROM a3 AS a, a3 AS b),
		numbers AS
		(
			SELECT TOP(LEN(@params) - 1)
				ROW_NUMBER() OVER
				(
					ORDER BY (SELECT NULL)
				) AS number
			FROM a4
			ORDER BY
				number
		),
		tokens AS
		(
			SELECT 
				RTRIM(LTRIM(
					SUBSTRING
					(
						@params,
						number + 1,
						CHARINDEX(CHAR(13), @params, number + 1) - number - 1
					)
				)) AS token,
				number,
				CASE
					WHEN SUBSTRING(@params, number + 1, 1) = CHAR(13) THEN number
					ELSE COALESCE(NULLIF(CHARINDEX(',' + CHAR(13) + CHAR(13), @params, number), 0), LEN(@params)) 
				END AS param_group,
				ROW_NUMBER() OVER
				(
					PARTITION BY
						CHARINDEX(',' + CHAR(13) + CHAR(13), @params, number),
						SUBSTRING(@params, number+1, 1)
					ORDER BY 
						number
				) AS group_order
			FROM numbers
			WHERE
				SUBSTRING(@params, number, 1) = CHAR(13)
		),
		parsed_tokens AS
		(
			SELECT
				MIN
				(
					CASE
						WHEN token LIKE '@%' THEN token
						ELSE NULL
					END
				) AS parameter,
				MIN
				(
					CASE
						WHEN token LIKE '--%' THEN RIGHT(token, LEN(token) - 2)
						ELSE NULL
					END
				) AS description,
				param_group,
				group_order
			FROM tokens
			WHERE
				NOT 
				(
					token = '' 
					AND group_order > 1
				)
			GROUP BY
				param_group,
				group_order
		)
		SELECT
			CASE
				WHEN description IS NULL AND parameter IS NULL THEN '-------------------------------------------------------------------------'
				WHEN param_group = MAX(param_group) OVER() THEN parameter
				ELSE COALESCE(LEFT(parameter, LEN(parameter) - 1), '')
			END AS [------parameter----------------------------------------------------------],
			CASE
				WHEN description IS NULL AND parameter IS NULL THEN '----------------------------------------------------------------------------------------------------------------------'
				ELSE COALESCE(description, '')
			END AS [------description-----------------------------------------------------------------------------------------------------]
		FROM parsed_tokens
		ORDER BY
			param_group, 
			group_order;
		
		WITH
		a0 AS
		(SELECT 1 AS n UNION ALL SELECT 1),
		a1 AS
		(SELECT 1 AS n FROM a0 AS a, a0 AS b),
		a2 AS
		(SELECT 1 AS n FROM a1 AS a, a1 AS b),
		a3 AS
		(SELECT 1 AS n FROM a2 AS a, a2 AS b),
		a4 AS
		(SELECT 1 AS n FROM a3 AS a, a3 AS b),
		numbers AS
		(
			SELECT TOP(LEN(@outputs) - 1)
				ROW_NUMBER() OVER
				(
					ORDER BY (SELECT NULL)
				) AS number
			FROM a4
			ORDER BY
				number
		),
		tokens AS
		(
			SELECT 
				RTRIM(LTRIM(
					SUBSTRING
					(
						@outputs,
						number + 1,
						CASE
							WHEN 
								COALESCE(NULLIF(CHARINDEX(CHAR(13) + 'Formatted', @outputs, number + 1), 0), LEN(@outputs)) < 
								COALESCE(NULLIF(CHARINDEX(CHAR(13) + CHAR(255) COLLATE Latin1_General_Bin2, @outputs, number + 1), 0), LEN(@outputs))
								THEN COALESCE(NULLIF(CHARINDEX(CHAR(13) + 'Formatted', @outputs, number + 1), 0), LEN(@outputs)) - number - 1
							ELSE
								COALESCE(NULLIF(CHARINDEX(CHAR(13) + CHAR(255) COLLATE Latin1_General_Bin2, @outputs, number + 1), 0), LEN(@outputs)) - number - 1
						END
					)
				)) AS token,
				number,
				COALESCE(NULLIF(CHARINDEX(CHAR(13) + 'Formatted', @outputs, number + 1), 0), LEN(@outputs)) AS output_group,
				ROW_NUMBER() OVER
				(
					PARTITION BY 
						COALESCE(NULLIF(CHARINDEX(CHAR(13) + 'Formatted', @outputs, number + 1), 0), LEN(@outputs))
					ORDER BY
						number
				) AS output_group_order
			FROM numbers
			WHERE
				SUBSTRING(@outputs, number, 10) = CHAR(13) + 'Formatted'
				OR SUBSTRING(@outputs, number, 2) = CHAR(13) + CHAR(255) COLLATE Latin1_General_Bin2
		),
		output_tokens AS
		(
			SELECT 
				*,
				CASE output_group_order
					WHEN 2 THEN MAX(CASE output_group_order WHEN 1 THEN token ELSE NULL END) OVER (PARTITION BY output_group)
					ELSE ''
				END COLLATE Latin1_General_Bin2 AS column_info
			FROM tokens
		)
		SELECT
			CASE output_group_order
				WHEN 1 THEN '-----------------------------------'
				WHEN 2 THEN 
					CASE
						WHEN CHARINDEX('Formatted/Non:', column_info) = 1 THEN
							SUBSTRING(column_info, CHARINDEX(CHAR(255) COLLATE Latin1_General_Bin2, column_info)+1, CHARINDEX(']', column_info, CHARINDEX(CHAR(255) COLLATE Latin1_General_Bin2, column_info)+2) - CHARINDEX(CHAR(255) COLLATE Latin1_General_Bin2, column_info))
						ELSE
							SUBSTRING(column_info, CHARINDEX(CHAR(255) COLLATE Latin1_General_Bin2, column_info)+2, CHARINDEX(']', column_info, CHARINDEX(CHAR(255) COLLATE Latin1_General_Bin2, column_info)+2) - CHARINDEX(CHAR(255) COLLATE Latin1_General_Bin2, column_info)-1)
					END
				ELSE ''
			END AS formatted_column_name,
			CASE output_group_order
				WHEN 1 THEN '-----------------------------------'
				WHEN 2 THEN 
					CASE
						WHEN CHARINDEX('Formatted/Non:', column_info) = 1 THEN
							SUBSTRING(column_info, CHARINDEX(']', column_info)+2, LEN(column_info))
						ELSE
							SUBSTRING(column_info, CHARINDEX(']', column_info)+2, CHARINDEX('Non-Formatted:', column_info, CHARINDEX(']', column_info)+2) - CHARINDEX(']', column_info)-3)
					END
				ELSE ''
			END AS formatted_column_type,
			CASE output_group_order
				WHEN 1 THEN '---------------------------------------'
				WHEN 2 THEN 
					CASE
						WHEN CHARINDEX('Formatted/Non:', column_info) = 1 THEN ''
						ELSE
							CASE
								WHEN SUBSTRING(column_info, CHARINDEX(CHAR(255) COLLATE Latin1_General_Bin2, column_info, CHARINDEX('Non-Formatted:', column_info))+1, 1) = '<' THEN
									SUBSTRING(column_info, CHARINDEX(CHAR(255) COLLATE Latin1_General_Bin2, column_info, CHARINDEX('Non-Formatted:', column_info))+1, CHARINDEX('>', column_info, CHARINDEX(CHAR(255) COLLATE Latin1_General_Bin2, column_info, CHARINDEX('Non-Formatted:', column_info))+1) - CHARINDEX(CHAR(255) COLLATE Latin1_General_Bin2, column_info, CHARINDEX('Non-Formatted:', column_info)))
								ELSE
									SUBSTRING(column_info, CHARINDEX(CHAR(255) COLLATE Latin1_General_Bin2, column_info, CHARINDEX('Non-Formatted:', column_info))+1, CHARINDEX(']', column_info, CHARINDEX(CHAR(255) COLLATE Latin1_General_Bin2, column_info, CHARINDEX('Non-Formatted:', column_info))+1) - CHARINDEX(CHAR(255) COLLATE Latin1_General_Bin2, column_info, CHARINDEX('Non-Formatted:', column_info)))
							END
					END
				ELSE ''
			END AS unformatted_column_name,
			CASE output_group_order
				WHEN 1 THEN '---------------------------------------'
				WHEN 2 THEN 
					CASE
						WHEN CHARINDEX('Formatted/Non:', column_info) = 1 THEN ''
						ELSE
							CASE
								WHEN SUBSTRING(column_info, CHARINDEX(CHAR(255) COLLATE Latin1_General_Bin2, column_info, CHARINDEX('Non-Formatted:', column_info))+1, 1) = '<' THEN ''
								ELSE
									SUBSTRING(column_info, CHARINDEX(']', column_info, CHARINDEX('Non-Formatted:', column_info))+2, CHARINDEX('Non-Formatted:', column_info, CHARINDEX(']', column_info)+2) - CHARINDEX(']', column_info)-3)
							END
					END
				ELSE ''
			END AS unformatted_column_type,
			CASE output_group_order
				WHEN 1 THEN '----------------------------------------------------------------------------------------------------------------------'
				ELSE REPLACE(token, CHAR(255) COLLATE Latin1_General_Bin2, '')
			END AS [------description-----------------------------------------------------------------------------------------------------]
		FROM output_tokens
		WHERE
			NOT 
			(
				output_group_order = 1 
				AND output_group = LEN(@outputs)
			)
		ORDER BY
			output_group,
			CASE output_group_order
				WHEN 1 THEN 99
				ELSE output_group_order
			END;

		RETURN;
	END;

	WITH
	a0 AS
	(SELECT 1 AS n UNION ALL SELECT 1),
	a1 AS
	(SELECT 1 AS n FROM a0 AS a, a0 AS b),
	a2 AS
	(SELECT 1 AS n FROM a1 AS a, a1 AS b),
	a3 AS
	(SELECT 1 AS n FROM a2 AS a, a2 AS b),
	a4 AS
	(SELECT 1 AS n FROM a3 AS a, a3 AS b),
	numbers AS
	(
		SELECT TOP(LEN(@output_column_list))
			ROW_NUMBER() OVER
			(
				ORDER BY (SELECT NULL)
			) AS number
		FROM a4
		ORDER BY
			number
	),
	tokens AS
	(
		SELECT 
			'|[' +
				SUBSTRING
				(
					@output_column_list,
					number + 1,
					CHARINDEX(']', @output_column_list, number) - number - 1
				) + '|]' AS token,
			number
		FROM numbers
		WHERE
			SUBSTRING(@output_column_list, number, 1) = '['
	),
	ordered_columns AS
	(
		SELECT
			x.column_name,
			ROW_NUMBER() OVER
			(
				PARTITION BY
					x.column_name
				ORDER BY
					tokens.number,
					x.default_order
			) AS r,
			ROW_NUMBER() OVER
			(
				ORDER BY
					tokens.number,
					x.default_order
			) AS s
		FROM tokens
		JOIN
		(
			SELECT '[session_id]' AS column_name, 1 AS default_order
			UNION ALL
			SELECT '[dd hh:mm:ss.mss]', 2
			WHERE
				@format_output IN (1, 2)
			UNION ALL
			SELECT '[dd hh:mm:ss.mss (avg)]', 3
			WHERE
				@format_output IN (1, 2)
				AND @get_avg_time = 1
			UNION ALL
			SELECT '[avg_elapsed_time]', 4
			WHERE
				@format_output = 0
				AND @get_avg_time = 1
			UNION ALL
			SELECT '[physical_io]', 5
			WHERE
				@get_task_info = 2
			UNION ALL
			SELECT '[reads]', 6
			UNION ALL
			SELECT '[physical_reads]', 7
			UNION ALL
			SELECT '[writes]', 8
			UNION ALL
			SELECT '[tempdb_allocations]', 9
			UNION ALL
			SELECT '[tempdb_current]', 10
			UNION ALL
			SELECT '[CPU]', 11
			UNION ALL
			SELECT '[context_switches]', 12
			WHERE
				@get_task_info = 2
			UNION ALL
			SELECT '[used_memory]', 13
			UNION ALL
			SELECT '[physical_io_delta]', 14
			WHERE
				@delta_interval > 0	
				AND @get_task_info = 2
			UNION ALL
			SELECT '[reads_delta]', 15
			WHERE
				@delta_interval > 0
			UNION ALL
			SELECT '[physical_reads_delta]', 16
			WHERE
				@delta_interval > 0
			UNION ALL
			SELECT '[writes_delta]', 17
			WHERE
				@delta_interval > 0
			UNION ALL
			SELECT '[tempdb_allocations_delta]', 18
			WHERE
				@delta_interval > 0
			UNION ALL
			SELECT '[tempdb_current_delta]', 19
			WHERE
				@delta_interval > 0
			UNION ALL
			SELECT '[CPU_delta]', 20
			WHERE
				@delta_interval > 0
			UNION ALL
			SELECT '[context_switches_delta]', 21
			WHERE
				@delta_interval > 0
				AND @get_task_info = 2
			UNION ALL
			SELECT '[used_memory_delta]', 22
			WHERE
				@delta_interval > 0
			UNION ALL
			SELECT '[tasks]', 23
			WHERE
				@get_task_info = 2
			UNION ALL
			SELECT '[status]', 24
			UNION ALL
			SELECT '[wait_info]', 25
			WHERE
				@get_task_info > 0
				OR @find_block_leaders = 1
			UNION ALL
			SELECT '[locks]', 26
			WHERE
				@get_locks = 1
			UNION ALL
			SELECT '[tran_start_time]', 27
			WHERE
				@get_transaction_info = 1
			UNION ALL
			SELECT '[tran_log_writes]', 28
			WHERE
				@get_transaction_info = 1
			UNION ALL
			SELECT '[open_tran_count]', 29
			UNION ALL
			SELECT '[sql_command]', 30
			WHERE
				@get_outer_command = 1
			UNION ALL
			SELECT '[sql_text]', 31
			UNION ALL
			SELECT '[query_plan]', 32
			WHERE
				@get_plans >= 1
			UNION ALL
			SELECT '[blocking_session_id]', 33
			WHERE
				@get_task_info > 0
				OR @find_block_leaders = 1
			UNION ALL
			SELECT '[blocked_session_count]', 34
			WHERE
				@find_block_leaders = 1
			UNION ALL
			SELECT '[percent_complete]', 35
			UNION ALL
			SELECT '[host_name]', 36
			UNION ALL
			SELECT '[login_name]', 37
			UNION ALL
			SELECT '[database_name]', 38
			UNION ALL
			SELECT '[program_name]', 39
			UNION ALL
			SELECT '[additional_info]', 40
			WHERE
				@get_additional_info = 1
			UNION ALL
			SELECT '[start_time]', 41
			UNION ALL
			SELECT '[login_time]', 42
			UNION ALL
			SELECT '[request_id]', 43
			UNION ALL
			SELECT '[collection_time]', 44
		) AS x ON 
			x.column_name LIKE token ESCAPE '|'
	)
	SELECT
		@output_column_list =
			STUFF
			(
				(
					SELECT
						',' + column_name as [text()]
					FROM ordered_columns
					WHERE
						r = 1
					ORDER BY
						s
					FOR XML
						PATH('')
				),
				1,
				1,
				''
			);
	
	IF COALESCE(RTRIM(@output_column_list), '') = ''
	BEGIN;
		RAISERROR('No valid column matches found in @output_column_list or no columns remain due to selected options.', 16, 1);
		RETURN;
	END;
	
	IF @destination_table <> ''
	BEGIN;
		SET @destination_table = 
			--database
			COALESCE(QUOTENAME(PARSENAME(@destination_table, 3)) + '.', '') +
			--schema
			COALESCE(QUOTENAME(PARSENAME(@destination_table, 2)) + '.', '') +
			--table
			COALESCE(QUOTENAME(PARSENAME(@destination_table, 1)), '');
			
		IF COALESCE(RTRIM(@destination_table), '') = ''
		BEGIN;
			RAISERROR('Destination table not properly formatted.', 16, 1);
			RETURN;
		END;
	END;

	WITH
	a0 AS
	(SELECT 1 AS n UNION ALL SELECT 1),
	a1 AS
	(SELECT 1 AS n FROM a0 AS a, a0 AS b),
	a2 AS
	(SELECT 1 AS n FROM a1 AS a, a1 AS b),
	a3 AS
	(SELECT 1 AS n FROM a2 AS a, a2 AS b),
	a4 AS
	(SELECT 1 AS n FROM a3 AS a, a3 AS b),
	numbers AS
	(
		SELECT TOP(LEN(@sort_order))
			ROW_NUMBER() OVER
			(
				ORDER BY (SELECT NULL)
			) AS number
		FROM a4
		ORDER BY
			number
	),
	tokens AS
	(
		SELECT 
			'|[' +
				SUBSTRING
				(
					@sort_order,
					number + 1,
					CHARINDEX(']', @sort_order, number) - number - 1
				) + '|]' AS token,
			SUBSTRING
			(
				@sort_order,
				CHARINDEX(']', @sort_order, number) + 1,
				COALESCE(NULLIF(CHARINDEX('[', @sort_order, CHARINDEX(']', @sort_order, number)), 0), LEN(@sort_order)) - CHARINDEX(']', @sort_order, number)
			) AS next_chunk,
			number
		FROM numbers
		WHERE
			SUBSTRING(@sort_order, number, 1) = '['
	),
	ordered_columns AS
	(
		SELECT
			x.column_name +
				CASE
					WHEN tokens.next_chunk LIKE '%asc%' THEN ' ASC'
					WHEN tokens.next_chunk LIKE '%desc%' THEN ' DESC'
					ELSE ''
				END AS column_name,
			ROW_NUMBER() OVER
			(
				PARTITION BY
					x.column_name
				ORDER BY
					tokens.number
			) AS r,
			tokens.number
		FROM tokens
		JOIN
		(
			SELECT '[session_id]' AS column_name
			UNION ALL
			SELECT '[physical_io]'
			UNION ALL
			SELECT '[reads]'
			UNION ALL
			SELECT '[physical_reads]'
			UNION ALL
			SELECT '[writes]'
			UNION ALL
			SELECT '[tempdb_allocations]'
			UNION ALL
			SELECT '[tempdb_current]'
			UNION ALL
			SELECT '[CPU]'
			UNION ALL
			SELECT '[context_switches]'
			UNION ALL
			SELECT '[used_memory]'
			UNION ALL
			SELECT '[physical_io_delta]'
			UNION ALL
			SELECT '[reads_delta]'
			UNION ALL
			SELECT '[physical_reads_delta]'
			UNION ALL
			SELECT '[writes_delta]'
			UNION ALL
			SELECT '[tempdb_allocations_delta]'
			UNION ALL
			SELECT '[tempdb_current_delta]'
			UNION ALL
			SELECT '[CPU_delta]'
			UNION ALL
			SELECT '[context_switches_delta]'
			UNION ALL
			SELECT '[used_memory_delta]'
			UNION ALL
			SELECT '[tasks]'
			UNION ALL
			SELECT '[tran_start_time]'
			UNION ALL
			SELECT '[open_tran_count]'
			UNION ALL
			SELECT '[blocking_session_id]'
			UNION ALL
			SELECT '[blocked_session_count]'
			UNION ALL
			SELECT '[percent_complete]'
			UNION ALL
			SELECT '[host_name]'
			UNION ALL
			SELECT '[login_name]'
			UNION ALL
			SELECT '[database_name]'
			UNION ALL
			SELECT '[start_time]'
			UNION ALL
			SELECT '[login_time]'
			UNION ALL
			SELECT '[program_name]'
		) AS x ON 
			x.column_name LIKE token ESCAPE '|'
	)
	SELECT
		@sort_order = COALESCE(z.sort_order, '')
	FROM
	(
		SELECT
			STUFF
			(
				(
					SELECT
						',' + column_name as [text()]
					FROM ordered_columns
					WHERE
						r = 1
					ORDER BY
						number
					FOR XML
						PATH('')
				),
				1,
				1,
				''
			) AS sort_order
	) AS z;

	CREATE TABLE #sessions
	(
		recursion SMALLINT NOT NULL,
		session_id SMALLINT NOT NULL,
		request_id INT NOT NULL,
		session_number INT NOT NULL,
		elapsed_time INT NOT NULL,
		avg_elapsed_time INT NULL,
		physical_io BIGINT NULL,
		reads BIGINT NULL,
		physical_reads BIGINT NULL,
		writes BIGINT NULL,
		tempdb_allocations BIGINT NULL,
		tempdb_current BIGINT NULL,
		CPU INT NULL,
		thread_CPU_snapshot BIGINT NULL,
		context_switches BIGINT NULL,
		used_memory BIGINT NOT NULL, 
		tasks SMALLINT NULL,
		status VARCHAR(30) NOT NULL,
		wait_info NVARCHAR(4000) NULL,
		locks XML NULL,
		transaction_id BIGINT NULL,
		tran_start_time DATETIME NULL,
		tran_log_writes NVARCHAR(4000) NULL,
		open_tran_count SMALLINT NULL,
		sql_command XML NULL,
		sql_handle VARBINARY(64) NULL,
		statement_start_offset INT NULL,
		statement_end_offset INT NULL,
		sql_text XML NULL,
		plan_handle VARBINARY(64) NULL,
		query_plan XML NULL,
		blocking_session_id SMALLINT NULL,
		blocked_session_count SMALLINT NULL,
		percent_complete REAL NULL,
		host_name sysname NULL,
		login_name sysname NOT NULL,
		database_name sysname NULL,
		program_name sysname NULL,
		additional_info XML NULL,
		start_time DATETIME NOT NULL,
		login_time DATETIME NULL,
		last_request_start_time DATETIME NULL,
		PRIMARY KEY CLUSTERED (session_id, request_id, recursion) WITH (IGNORE_DUP_KEY = ON),
		UNIQUE NONCLUSTERED (transaction_id, session_id, request_id, recursion) WITH (IGNORE_DUP_KEY = ON)
	);

	IF @return_schema = 0
	BEGIN;
		--Disable unnecessary autostats on the table
		CREATE STATISTICS s_session_id ON #sessions (session_id)
		WITH SAMPLE 0 ROWS, NORECOMPUTE;
		CREATE STATISTICS s_request_id ON #sessions (request_id)
		WITH SAMPLE 0 ROWS, NORECOMPUTE;
		CREATE STATISTICS s_transaction_id ON #sessions (transaction_id)
		WITH SAMPLE 0 ROWS, NORECOMPUTE;
		CREATE STATISTICS s_session_number ON #sessions (session_number)
		WITH SAMPLE 0 ROWS, NORECOMPUTE;
		CREATE STATISTICS s_status ON #sessions (status)
		WITH SAMPLE 0 ROWS, NORECOMPUTE;
		CREATE STATISTICS s_start_time ON #sessions (start_time)
		WITH SAMPLE 0 ROWS, NORECOMPUTE;
		CREATE STATISTICS s_last_request_start_time ON #sessions (last_request_start_time)
		WITH SAMPLE 0 ROWS, NORECOMPUTE;
		CREATE STATISTICS s_recursion ON #sessions (recursion)
		WITH SAMPLE 0 ROWS, NORECOMPUTE;

		DECLARE @recursion SMALLINT;
		SET @recursion = 
			CASE @delta_interval
				WHEN 0 THEN 1
				ELSE -1
			END;

		DECLARE @first_collection_ms_ticks BIGINT;
		DECLARE @last_collection_start DATETIME;
		DECLARE @sys_info BIT;
		SET @sys_info = ISNULL(CONVERT(BIT, SIGN(OBJECT_ID('sys.dm_os_sys_info'))), 0);

		--Used for the delta pull
		REDO:;
		
		IF 
			@get_locks = 1 
			AND @recursion = 1
			AND @output_column_list LIKE '%|[locks|]%' ESCAPE '|'
		BEGIN;
			SELECT
				y.resource_type,
				y.database_name,
				y.object_id,
				y.file_id,
				y.page_type,
				y.hobt_id,
				y.allocation_unit_id,
				y.index_id,
				y.schema_id,
				y.principal_id,
				y.request_mode,
				y.request_status,
				y.session_id,
				y.resource_description,
				y.request_count,
				s.request_id,
				s.start_time,
				CONVERT(sysname, NULL) AS object_name,
				CONVERT(sysname, NULL) AS index_name,
				CONVERT(sysname, NULL) AS schema_name,
				CONVERT(sysname, NULL) AS principal_name,
				CONVERT(NVARCHAR(2048), NULL) AS query_error
			INTO #locks
			FROM
			(
				SELECT
					sp.spid AS session_id,
					CASE sp.status
						WHEN 'sleeping' THEN CONVERT(INT, 0)
						ELSE sp.request_id
					END AS request_id,
					CASE sp.status
						WHEN 'sleeping' THEN sp.last_batch
						ELSE COALESCE(req.start_time, sp.last_batch)
					END AS start_time,
					sp.dbid
				FROM sys.sysprocesses AS sp
				OUTER APPLY
				(
					SELECT TOP(1)
						CASE
							WHEN 
							(
								sp.hostprocess > ''
								OR r.total_elapsed_time < 0
							) THEN
								r.start_time
							ELSE
								DATEADD
								(
									ms, 
									1000 * (DATEPART(ms, DATEADD(second, -(r.total_elapsed_time / 1000), GETDATE())) / 500) - DATEPART(ms, DATEADD(second, -(r.total_elapsed_time / 1000), GETDATE())), 
									DATEADD(second, -(r.total_elapsed_time / 1000), GETDATE())
								)
						END AS start_time
					FROM sys.dm_exec_requests AS r
					WHERE
						r.session_id = sp.spid
						AND r.request_id = sp.request_id
				) AS req
				WHERE
					--Process inclusive filter
					1 =
						CASE
							WHEN @filter <> '' THEN
								CASE @filter_type
									WHEN 'session' THEN
										CASE
											WHEN
												CONVERT(SMALLINT, @filter) = 0
												OR sp.spid = CONVERT(SMALLINT, @filter)
													THEN 1
											ELSE 0
										END
									WHEN 'program' THEN
										CASE
											WHEN sp.program_name LIKE @filter THEN 1
											ELSE 0
										END
									WHEN 'login' THEN
										CASE
											WHEN sp.loginame LIKE @filter THEN 1
											ELSE 0
										END
									WHEN 'host' THEN
										CASE
											WHEN sp.hostname LIKE @filter THEN 1
											ELSE 0
										END
									WHEN 'database' THEN
										CASE
											WHEN DB_NAME(sp.dbid) LIKE @filter THEN 1
											ELSE 0
										END
									ELSE 0
								END
							ELSE 1
						END
					--Process exclusive filter
					AND 0 =
						CASE
							WHEN @not_filter <> '' THEN
								CASE @not_filter_type
									WHEN 'session' THEN
										CASE
											WHEN sp.spid = CONVERT(SMALLINT, @not_filter) THEN 1
											ELSE 0
										END
									WHEN 'program' THEN
										CASE
											WHEN sp.program_name LIKE @not_filter THEN 1
											ELSE 0
										END
									WHEN 'login' THEN
										CASE
											WHEN sp.loginame LIKE @not_filter THEN 1
											ELSE 0
										END
									WHEN 'host' THEN
										CASE
											WHEN sp.hostname LIKE @not_filter THEN 1
											ELSE 0
										END
									WHEN 'database' THEN
										CASE
											WHEN DB_NAME(sp.dbid) LIKE @not_filter THEN 1
											ELSE 0
										END
									ELSE 0
								END
							ELSE 0
						END
					AND 
					(
						@show_own_spid = 1
						OR sp.spid <> @@SPID
					)
					AND 
					(
						@show_system_spids = 1
						OR sp.hostprocess > ''
					)
					AND sp.ecid = 0
			) AS s
			INNER HASH JOIN
			(
				SELECT
					x.resource_type,
					x.database_name,
					x.object_id,
					x.file_id,
					CASE
						WHEN x.page_no = 1 OR x.page_no % 8088 = 0 THEN 'PFS'
						WHEN x.page_no = 2 OR x.page_no % 511232 = 0 THEN 'GAM'
						WHEN x.page_no = 3 OR (x.page_no - 1) % 511232 = 0 THEN 'SGAM'
						WHEN x.page_no = 6 OR (x.page_no - 6) % 511232 = 0 THEN 'DCM'
						WHEN x.page_no = 7 OR (x.page_no - 7) % 511232 = 0 THEN 'BCM'
						WHEN x.page_no IS NOT NULL THEN '*'
						ELSE NULL
					END AS page_type,
					x.hobt_id,
					x.allocation_unit_id,
					x.index_id,
					x.schema_id,
					x.principal_id,
					x.request_mode,
					x.request_status,
					x.session_id,
					x.request_id,
					CASE
						WHEN COALESCE(x.object_id, x.file_id, x.hobt_id, x.allocation_unit_id, x.index_id, x.schema_id, x.principal_id) IS NULL THEN NULLIF(resource_description, '')
						ELSE NULL
					END AS resource_description,
					COUNT(*) AS request_count
				FROM
				(
					SELECT
						tl.resource_type +
							CASE
								WHEN tl.resource_subtype = '' THEN ''
								ELSE '.' + tl.resource_subtype
							END AS resource_type,
						COALESCE(DB_NAME(tl.resource_database_id), N'(null)') AS database_name,
						CONVERT
						(
							INT,
							CASE
								WHEN tl.resource_type = 'OBJECT' THEN tl.resource_associated_entity_id
								WHEN tl.resource_description LIKE '%object_id = %' THEN
									(
										SUBSTRING
										(
											tl.resource_description, 
											(CHARINDEX('object_id = ', tl.resource_description) + 12), 
											COALESCE
											(
												NULLIF
												(
													CHARINDEX(',', tl.resource_description, CHARINDEX('object_id = ', tl.resource_description) + 12),
													0
												), 
												DATALENGTH(tl.resource_description)+1
											) - (CHARINDEX('object_id = ', tl.resource_description) + 12)
										)
									)
								ELSE NULL
							END
						) AS object_id,
						CONVERT
						(
							INT,
							CASE 
								WHEN tl.resource_type = 'FILE' THEN CONVERT(INT, tl.resource_description)
								WHEN tl.resource_type IN ('PAGE', 'EXTENT', 'RID') THEN LEFT(tl.resource_description, CHARINDEX(':', tl.resource_description)-1)
								ELSE NULL
							END
						) AS file_id,
						CONVERT
						(
							INT,
							CASE
								WHEN tl.resource_type IN ('PAGE', 'EXTENT', 'RID') THEN 
									SUBSTRING
									(
										tl.resource_description, 
										CHARINDEX(':', tl.resource_description) + 1, 
										COALESCE
										(
											NULLIF
											(
												CHARINDEX(':', tl.resource_description, CHARINDEX(':', tl.resource_description) + 1), 
												0
											), 
											DATALENGTH(tl.resource_description)+1
										) - (CHARINDEX(':', tl.resource_description) + 1)
									)
								ELSE NULL
							END
						) AS page_no,
						CASE
							WHEN tl.resource_type IN ('PAGE', 'KEY', 'RID', 'HOBT') THEN tl.resource_associated_entity_id
							ELSE NULL
						END AS hobt_id,
						CASE
							WHEN tl.resource_type = 'ALLOCATION_UNIT' THEN tl.resource_associated_entity_id
							ELSE NULL
						END AS allocation_unit_id,
						CONVERT
						(
							INT,
							CASE
								WHEN
									/*TODO: Deal with server principals*/ 
									tl.resource_subtype <> 'SERVER_PRINCIPAL' 
									AND tl.resource_description LIKE '%index_id or stats_id = %' THEN
									(
										SUBSTRING
										(
											tl.resource_description, 
											(CHARINDEX('index_id or stats_id = ', tl.resource_description) + 23), 
											COALESCE
											(
												NULLIF
												(
													CHARINDEX(',', tl.resource_description, CHARINDEX('index_id or stats_id = ', tl.resource_description) + 23), 
													0
												), 
												DATALENGTH(tl.resource_description)+1
											) - (CHARINDEX('index_id or stats_id = ', tl.resource_description) + 23)
										)
									)
								ELSE NULL
							END 
						) AS index_id,
						CONVERT
						(
							INT,
							CASE
								WHEN tl.resource_description LIKE '%schema_id = %' THEN
									(
										SUBSTRING
										(
											tl.resource_description, 
											(CHARINDEX('schema_id = ', tl.resource_description) + 12), 
											COALESCE
											(
												NULLIF
												(
													CHARINDEX(',', tl.resource_description, CHARINDEX('schema_id = ', tl.resource_description) + 12), 
													0
												), 
												DATALENGTH(tl.resource_description)+1
											) - (CHARINDEX('schema_id = ', tl.resource_description) + 12)
										)
									)
								ELSE NULL
							END 
						) AS schema_id,
						CONVERT
						(
							INT,
							CASE
								WHEN tl.resource_description LIKE '%principal_id = %' THEN
									(
										SUBSTRING
										(
											tl.resource_description, 
											(CHARINDEX('principal_id = ', tl.resource_description) + 15), 
											COALESCE
											(
												NULLIF
												(
													CHARINDEX(',', tl.resource_description, CHARINDEX('principal_id = ', tl.resource_description) + 15), 
													0
												), 
												DATALENGTH(tl.resource_description)+1
											) - (CHARINDEX('principal_id = ', tl.resource_description) + 15)
										)
									)
								ELSE NULL
							END
						) AS principal_id,
						tl.request_mode,
						tl.request_status,
						tl.request_session_id AS session_id,
						tl.request_request_id AS request_id,

						/*TODO: Applocks, other resource_descriptions*/
						RTRIM(tl.resource_description) AS resource_description,
						tl.resource_associated_entity_id
						/*********************************************/
					FROM 
					(
						SELECT 
							request_session_id,
							CONVERT(VARCHAR(120), resource_type) COLLATE Latin1_General_Bin2 AS resource_type,
							CONVERT(VARCHAR(120), resource_subtype) COLLATE Latin1_General_Bin2 AS resource_subtype,
							resource_database_id,
							CONVERT(VARCHAR(512), resource_description) COLLATE Latin1_General_Bin2 AS resource_description,
							resource_associated_entity_id,
							CONVERT(VARCHAR(120), request_mode) COLLATE Latin1_General_Bin2 AS request_mode,
							CONVERT(VARCHAR(120), request_status) COLLATE Latin1_General_Bin2 AS request_status,
							request_request_id
						FROM sys.dm_tran_locks
					) AS tl
				) AS x
				GROUP BY
					x.resource_type,
					x.database_name,
					x.object_id,
					x.file_id,
					CASE
						WHEN x.page_no = 1 OR x.page_no % 8088 = 0 THEN 'PFS'
						WHEN x.page_no = 2 OR x.page_no % 511232 = 0 THEN 'GAM'
						WHEN x.page_no = 3 OR (x.page_no - 1) % 511232 = 0 THEN 'SGAM'
						WHEN x.page_no = 6 OR (x.page_no - 6) % 511232 = 0 THEN 'DCM'
						WHEN x.page_no = 7 OR (x.page_no - 7) % 511232 = 0 THEN 'BCM'
						WHEN x.page_no IS NOT NULL THEN '*'
						ELSE NULL
					END,
					x.hobt_id,
					x.allocation_unit_id,
					x.index_id,
					x.schema_id,
					x.principal_id,
					x.request_mode,
					x.request_status,
					x.session_id,
					x.request_id,
					CASE
						WHEN COALESCE(x.object_id, x.file_id, x.hobt_id, x.allocation_unit_id, x.index_id, x.schema_id, x.principal_id) IS NULL THEN NULLIF(resource_description, '')
						ELSE NULL
					END
			) AS y ON
				y.session_id = s.session_id
				AND y.request_id = s.request_id
			OPTION (HASH GROUP);

			--Disable unnecessary autostats on the table
			CREATE STATISTICS s_database_name ON #locks (database_name)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_object_id ON #locks (object_id)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_hobt_id ON #locks (hobt_id)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_allocation_unit_id ON #locks (allocation_unit_id)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_index_id ON #locks (index_id)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_schema_id ON #locks (schema_id)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_principal_id ON #locks (principal_id)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_request_id ON #locks (request_id)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_start_time ON #locks (start_time)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_resource_type ON #locks (resource_type)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_object_name ON #locks (object_name)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_schema_name ON #locks (schema_name)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_page_type ON #locks (page_type)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_request_mode ON #locks (request_mode)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_request_status ON #locks (request_status)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_resource_description ON #locks (resource_description)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_index_name ON #locks (index_name)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_principal_name ON #locks (principal_name)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
		END;
		
		DECLARE 
			@sql VARCHAR(MAX), 
			@sql_n NVARCHAR(MAX);

		SET @sql = 
			CONVERT(VARCHAR(MAX), '') +
			'DECLARE @blocker BIT;
			SET @blocker = 0;
			DECLARE @i INT;
			SET @i = 2147483647;

			DECLARE @sessions TABLE
			(
				session_id SMALLINT NOT NULL,
				request_id INT NOT NULL,
				login_time DATETIME,
				last_request_end_time DATETIME,
				status VARCHAR(30),
				statement_start_offset INT,
				statement_end_offset INT,
				sql_handle BINARY(20),
				host_name NVARCHAR(128),
				login_name NVARCHAR(128),
				program_name NVARCHAR(128),
				database_id SMALLINT,
				memory_usage INT,
				open_tran_count SMALLINT, 
				' +
				CASE
					WHEN 
					(
						@get_task_info <> 0 
						OR @find_block_leaders = 1 
					) THEN
						'wait_type NVARCHAR(32),
						wait_resource NVARCHAR(256),
						wait_time BIGINT, 
						'
					ELSE 
						''
				END +
				'blocked SMALLINT,
				is_user_process BIT,
				cmd VARCHAR(32),
				PRIMARY KEY CLUSTERED (session_id, request_id) WITH (IGNORE_DUP_KEY = ON)
			);

			DECLARE @blockers TABLE
			(
				session_id INT NOT NULL PRIMARY KEY WITH (IGNORE_DUP_KEY = ON)
			);

			BLOCKERS:;

			INSERT @sessions
			(
				session_id,
				request_id,
				login_time,
				last_request_end_time,
				status,
				statement_start_offset,
				statement_end_offset,
				sql_handle,
				host_name,
				login_name,
				program_name,
				database_id,
				memory_usage,
				open_tran_count, 
				' +
				CASE
					WHEN 
					(
						@get_task_info <> 0
						OR @find_block_leaders = 1 
					) THEN
						'wait_type,
						wait_resource,
						wait_time, 
						'
					ELSE
						''
				END +
				'blocked,
				is_user_process,
				cmd 
			)
			SELECT TOP(@i)
				spy.session_id,
				spy.request_id,
				spy.login_time,
				spy.last_request_end_time,
				spy.status,
				spy.statement_start_offset,
				spy.statement_end_offset,
				spy.sql_handle,
				spy.host_name,
				spy.login_name,
				spy.program_name,
				spy.database_id,
				spy.memory_usage,
				spy.open_tran_count,
				' +
				CASE
					WHEN 
					(
						@get_task_info <> 0  
						OR @find_block_leaders = 1 
					) THEN
						'spy.wait_type,
						CASE
							WHEN
								spy.wait_type LIKE N''PAGE%LATCH_%''
								OR spy.wait_type = N''CXPACKET''
								OR spy.wait_type LIKE N''LATCH[_]%''
								OR spy.wait_type = N''OLEDB'' THEN
									spy.wait_resource
							ELSE
								NULL
						END AS wait_resource,
						spy.wait_time, 
						'
					ELSE
						''
				END +
				'spy.blocked,
				spy.is_user_process,
				spy.cmd
			FROM
			(
				SELECT TOP(@i)
					spx.*, 
					' +
					CASE
						WHEN 
						(
							@get_task_info <> 0 
							OR @find_block_leaders = 1 
						) THEN
							'ROW_NUMBER() OVER
							(
								PARTITION BY
									spx.session_id,
									spx.request_id
								ORDER BY
									CASE
										WHEN spx.wait_type LIKE N''LCK[_]%'' THEN 
											1
										ELSE
											99
									END,
									spx.wait_time DESC,
									spx.blocked DESC
							) AS r 
							'
						ELSE 
							'1 AS r 
							'
					END +
				'FROM
				(
					SELECT TOP(@i)
						sp0.session_id,
						sp0.request_id,
						sp0.login_time,
						sp0.last_request_end_time,
						LOWER(sp0.status) AS status,
						CASE
							WHEN sp0.cmd = ''CREATE INDEX'' THEN
								0
							ELSE
								sp0.stmt_start
						END AS statement_start_offset,
						CASE
							WHEN sp0.cmd = N''CREATE INDEX'' THEN
								-1
							ELSE
								COALESCE(NULLIF(sp0.stmt_end, 0), -1)
						END AS statement_end_offset,
						sp0.sql_handle,
						sp0.host_name,
						sp0.login_name,
						sp0.program_name,
						sp0.database_id,
						sp0.memory_usage,
						sp0.open_tran_count, 
						' +
						CASE
							WHEN 
							(
								@get_task_info <> 0 
								OR @find_block_leaders = 1 
							) THEN
								'CASE
									WHEN sp0.wait_time > 0 AND sp0.wait_type <> N''CXPACKET'' THEN
										sp0.wait_type
									ELSE
										NULL
								END AS wait_type,
								CASE
									WHEN sp0.wait_time > 0 AND sp0.wait_type <> N''CXPACKET'' THEN 
										sp0.wait_resource
									ELSE
										NULL
								END AS wait_resource,
								CASE
									WHEN sp0.wait_type <> N''CXPACKET'' THEN
										sp0.wait_time
									ELSE
										0
								END AS wait_time, 
								'
							ELSE
								''
						END +
						'sp0.blocked,
						sp0.is_user_process,
						sp0.cmd
					FROM
					(
						SELECT TOP(@i)
							sp1.session_id,
							sp1.request_id,
							sp1.login_time,
							sp1.last_request_end_time,
							sp1.status,
							sp1.cmd,
							sp1.stmt_start,
							sp1.stmt_end,
							MAX(NULLIF(sp1.sql_handle, 0x00)) OVER (PARTITION BY sp1.session_id, sp1.request_id) AS sql_handle,
							sp1.host_name,
							MAX(sp1.login_name) OVER (PARTITION BY sp1.session_id, sp1.request_id) AS login_name,
							sp1.program_name,
							sp1.database_id,
							MAX(sp1.memory_usage)  OVER (PARTITION BY sp1.session_id, sp1.request_id) AS memory_usage,
							MAX(sp1.open_tran_count)  OVER (PARTITION BY sp1.session_id, sp1.request_id) AS open_tran_count,
							sp1.wait_type,
							sp1.wait_resource,
							sp1.wait_time,
							sp1.blocked,
							sp1.hostprocess,
							sp1.is_user_process
						FROM
						(
							SELECT TOP(@i)
								sp2.spid AS session_id,
								CASE sp2.status
									WHEN ''sleeping'' THEN
										CONVERT(INT, 0)
									ELSE
										sp2.request_id
								END AS request_id,
								MAX(sp2.login_time) AS login_time,
								MAX(sp2.last_batch) AS last_request_end_time,
								MAX(CONVERT(VARCHAR(30), RTRIM(sp2.status)) COLLATE Latin1_General_Bin2) AS status,
								MAX(CONVERT(VARCHAR(32), RTRIM(sp2.cmd)) COLLATE Latin1_General_Bin2) AS cmd,
								MAX(sp2.stmt_start) AS stmt_start,
								MAX(sp2.stmt_end) AS stmt_end,
								MAX(sp2.sql_handle) AS sql_handle,
								MAX(CONVERT(sysname, RTRIM(sp2.hostname)) COLLATE SQL_Latin1_General_CP1_CI_AS) AS host_name,
								MAX(CONVERT(sysname, RTRIM(sp2.loginame)) COLLATE SQL_Latin1_General_CP1_CI_AS) AS login_name,
								MAX
								(
									CASE
										WHEN blk.queue_id IS NOT NULL THEN
											N''Service Broker
												database_id: '' + CONVERT(NVARCHAR, blk.database_id) +
												N'' queue_id: '' + CONVERT(NVARCHAR, blk.queue_id)
										ELSE
											CONVERT
											(
												sysname,
												RTRIM(sp2.program_name)
											)
									END COLLATE SQL_Latin1_General_CP1_CI_AS
								) AS program_name,
								MAX(sp2.dbid) AS database_id,
								MAX(sp2.memusage) AS memory_usage,
								MAX(sp2.open_tran) AS open_tran_count,
								RTRIM(sp2.lastwaittype) AS wait_type,
								RTRIM(sp2.waitresource) AS wait_resource,
								MAX(sp2.waittime) AS wait_time,
								COALESCE(NULLIF(sp2.blocked, sp2.spid), 0) AS blocked,
								MAX
								(
									CASE
										WHEN blk.session_id = sp2.spid THEN
											''blocker''
										ELSE
											RTRIM(sp2.hostprocess)
									END
								) AS hostprocess,
								CONVERT
								(
									BIT,
									MAX
									(
										CASE
											WHEN sp2.hostprocess > '''' THEN
												1
											ELSE
												0
										END
									)
								) AS is_user_process
							FROM
							(
								SELECT TOP(@i)
									session_id,
									CONVERT(INT, NULL) AS queue_id,
									CONVERT(INT, NULL) AS database_id
								FROM @blockers

								UNION ALL

								SELECT TOP(@i)
									CONVERT(SMALLINT, 0),
									CONVERT(INT, NULL) AS queue_id,
									CONVERT(INT, NULL) AS database_id
								WHERE
									@blocker = 0

								UNION ALL

								SELECT TOP(@i)
									CONVERT(SMALLINT, spid),
									queue_id,
									database_id
								FROM sys.dm_broker_activated_tasks
								WHERE
									@blocker = 0
							) AS blk
							INNER JOIN sys.sysprocesses AS sp2 ON
								sp2.spid = blk.session_id
								OR
								(
									blk.session_id = 0
									AND @blocker = 0
								)
							' +
							CASE 
								WHEN 
								(
									@get_task_info = 0 
									AND @find_block_leaders = 0
								) THEN
									'WHERE
										sp2.ecid = 0 
									' 
								ELSE
									''
							END +
							'GROUP BY
								sp2.spid,
								CASE sp2.status
									WHEN ''sleeping'' THEN
										CONVERT(INT, 0)
									ELSE
										sp2.request_id
								END,
								RTRIM(sp2.lastwaittype),
								RTRIM(sp2.waitresource),
								COALESCE(NULLIF(sp2.blocked, sp2.spid), 0)
						) AS sp1
					) AS sp0
					WHERE
						@blocker = 1
						OR
						(1=1 
						' +
							--inclusive filter
							CASE
								WHEN @filter <> '' THEN
									CASE @filter_type
										WHEN 'session' THEN
											CASE
												WHEN CONVERT(SMALLINT, @filter) <> 0 THEN
													'AND sp0.session_id = CONVERT(SMALLINT, @filter) 
													'
												ELSE
													''
											END
										WHEN 'program' THEN
											'AND sp0.program_name LIKE @filter 
											'
										WHEN 'login' THEN
											'AND sp0.login_name LIKE @filter 
											'
										WHEN 'host' THEN
											'AND sp0.host_name LIKE @filter 
											'
										WHEN 'database' THEN
											'AND DB_NAME(sp0.database_id) LIKE @filter 
											'
										ELSE
											''
									END
								ELSE
									''
							END +
							--exclusive filter
							CASE
								WHEN @not_filter <> '' THEN
									CASE @not_filter_type
										WHEN 'session' THEN
											CASE
												WHEN CONVERT(SMALLINT, @not_filter) <> 0 THEN
													'AND sp0.session_id <> CONVERT(SMALLINT, @not_filter) 
													'
												ELSE
													''
											END
										WHEN 'program' THEN
											'AND sp0.program_name NOT LIKE @not_filter 
											'
										WHEN 'login' THEN
											'AND sp0.login_name NOT LIKE @not_filter 
											'
										WHEN 'host' THEN
											'AND sp0.host_name NOT LIKE @not_filter 
											'
										WHEN 'database' THEN
											'AND DB_NAME(sp0.database_id) NOT LIKE @not_filter 
											'
										ELSE
											''
									END
								ELSE
									''
							END +
							CASE @show_own_spid
								WHEN 1 THEN
									''
								ELSE
									'AND sp0.session_id <> @@spid 
									'
							END +
							CASE 
								WHEN @show_system_spids = 0 THEN
									'AND sp0.hostprocess > '''' 
									' 
								ELSE
									''
							END +
							CASE @show_sleeping_spids
								WHEN 0 THEN
									'AND sp0.status <> ''sleeping'' 
									'
								WHEN 1 THEN
									'AND
									(
										sp0.status <> ''sleeping''
										OR sp0.open_tran_count > 0
									)
									'
								ELSE
									''
							END +
						')
				) AS spx
			) AS spy
			WHERE
				spy.r = 1; 
			' + 
			CASE @recursion
				WHEN 1 THEN 
					'IF @@ROWCOUNT > 0
					BEGIN;
						INSERT @blockers
						(
							session_id
						)
						SELECT TOP(@i)
							blocked
						FROM @sessions
						WHERE
							NULLIF(blocked, 0) IS NOT NULL

						EXCEPT

						SELECT TOP(@i)
							session_id
						FROM @sessions; 
						' +

						CASE
							WHEN
							(
								@get_task_info > 0
								OR @find_block_leaders = 1
							) THEN
								'IF @@ROWCOUNT > 0
								BEGIN;
									SET @blocker = 1;
									GOTO BLOCKERS;
								END; 
								'
							ELSE 
								''
						END +
					'END; 
					'
				ELSE 
					''
			END +
			'SELECT TOP(@i)
				@recursion AS recursion,
				x.session_id,
				x.request_id,
				DENSE_RANK() OVER
				(
					ORDER BY
						x.session_id
				) AS session_number,
				' +
				CASE
					WHEN @output_column_list LIKE '%|[dd hh:mm:ss.mss|]%' ESCAPE '|' THEN 
						'x.elapsed_time '
					ELSE 
						'0 '
				END + 
					'AS elapsed_time, 
					' +
				CASE
					WHEN
						(
							@output_column_list LIKE '%|[dd hh:mm:ss.mss (avg)|]%' ESCAPE '|' OR 
							@output_column_list LIKE '%|[avg_elapsed_time|]%' ESCAPE '|'
						)
						AND @recursion = 1
							THEN 
								'x.avg_elapsed_time / 1000 '
					ELSE 
						'NULL '
				END + 
					'AS avg_elapsed_time, 
					' +
				CASE
					WHEN 
						@output_column_list LIKE '%|[physical_io|]%' ESCAPE '|'
						OR @output_column_list LIKE '%|[physical_io_delta|]%' ESCAPE '|'
							THEN 
								'x.physical_io '
					ELSE 
						'NULL '
				END + 
					'AS physical_io, 
					' +
				CASE
					WHEN 
						@output_column_list LIKE '%|[reads|]%' ESCAPE '|'
						OR @output_column_list LIKE '%|[reads_delta|]%' ESCAPE '|'
							THEN 
								'x.reads '
					ELSE 
						'0 '
				END + 
					'AS reads, 
					' +
				CASE
					WHEN 
						@output_column_list LIKE '%|[physical_reads|]%' ESCAPE '|'
						OR @output_column_list LIKE '%|[physical_reads_delta|]%' ESCAPE '|'
							THEN 
								'x.physical_reads '
					ELSE 
						'0 '
				END + 
					'AS physical_reads, 
					' +
				CASE
					WHEN 
						@output_column_list LIKE '%|[writes|]%' ESCAPE '|'
						OR @output_column_list LIKE '%|[writes_delta|]%' ESCAPE '|'
							THEN 
								'x.writes '
					ELSE 
						'0 '
				END + 
					'AS writes, 
					' +
				CASE
					WHEN 
						@output_column_list LIKE '%|[tempdb_allocations|]%' ESCAPE '|'
						OR @output_column_list LIKE '%|[tempdb_allocations_delta|]%' ESCAPE '|'
							THEN 
								'x.tempdb_allocations '
					ELSE 
						'0 '
				END + 
					'AS tempdb_allocations, 
					' +
				CASE
					WHEN 
						@output_column_list LIKE '%|[tempdb_current|]%' ESCAPE '|'
						OR @output_column_list LIKE '%|[tempdb_current_delta|]%' ESCAPE '|'
							THEN 
								'x.tempdb_current '
					ELSE 
						'0 '
				END + 
					'AS tempdb_current, 
					' +
				CASE
					WHEN 
						@output_column_list LIKE '%|[CPU|]%' ESCAPE '|'
						OR @output_column_list LIKE '%|[CPU_delta|]%' ESCAPE '|'
							THEN
								'x.CPU '
					ELSE
						'0 '
				END + 
					'AS CPU, 
					' +
				CASE
					WHEN 
						@output_column_list LIKE '%|[CPU_delta|]%' ESCAPE '|'
						AND @get_task_info = 2
						AND @sys_info = 1
							THEN 
								'x.thread_CPU_snapshot '
					ELSE 
						'0 '
				END + 
					'AS thread_CPU_snapshot, 
					' +
				CASE
					WHEN 
						@output_column_list LIKE '%|[context_switches|]%' ESCAPE '|'
						OR @output_column_list LIKE '%|[context_switches_delta|]%' ESCAPE '|'
							THEN 
								'x.context_switches '
					ELSE 
						'NULL '
				END + 
					'AS context_switches, 
					' +
				CASE
					WHEN 
						@output_column_list LIKE '%|[used_memory|]%' ESCAPE '|'
						OR @output_column_list LIKE '%|[used_memory_delta|]%' ESCAPE '|'
							THEN 
								'x.used_memory '
					ELSE 
						'0 '
				END + 
					'AS used_memory, 
					' +
				CASE
					WHEN 
						@output_column_list LIKE '%|[tasks|]%' ESCAPE '|'
						AND @recursion = 1
							THEN 
								'x.tasks '
					ELSE 
						'NULL '
				END + 
					'AS tasks, 
					' +
				CASE
					WHEN 
						(
							@output_column_list LIKE '%|[status|]%' ESCAPE '|' 
							OR @output_column_list LIKE '%|[sql_command|]%' ESCAPE '|'
						)
						AND @recursion = 1
							THEN 
								'x.status '
					ELSE 
						''''' '
				END + 
					'AS status, 
					' +
				CASE
					WHEN 
						@output_column_list LIKE '%|[wait_info|]%' ESCAPE '|' 
						AND @recursion = 1
							THEN 
								CASE @get_task_info
									WHEN 2 THEN
										'COALESCE(x.task_wait_info, x.sys_wait_info) '
									ELSE
										'x.sys_wait_info '
								END
					ELSE 
						'NULL '
				END + 
					'AS wait_info, 
					' +
				CASE
					WHEN 
						(
							@output_column_list LIKE '%|[tran_start_time|]%' ESCAPE '|' 
							OR @output_column_list LIKE '%|[tran_log_writes|]%' ESCAPE '|' 
						)
						AND @recursion = 1
							THEN 
								'x.transaction_id '
					ELSE 
						'NULL '
				END + 
					'AS transaction_id, 
					' +
				CASE
					WHEN 
						@output_column_list LIKE '%|[open_tran_count|]%' ESCAPE '|' 
						AND @recursion = 1
							THEN 
								'x.open_tran_count '
					ELSE 
						'NULL '
				END + 
					'AS open_tran_count, 
					' +
				CASE
					WHEN 
						@output_column_list LIKE '%|[sql_text|]%' ESCAPE '|' 
						AND @recursion = 1
							THEN 
								'x.sql_handle '
					ELSE 
						'NULL '
				END + 
					'AS sql_handle, 
					' +
				CASE
					WHEN 
						(
							@output_column_list LIKE '%|[sql_text|]%' ESCAPE '|' 
							OR @output_column_list LIKE '%|[query_plan|]%' ESCAPE '|' 
						)
						AND @recursion = 1
							THEN 
								'x.statement_start_offset '
					ELSE 
						'NULL '
				END + 
					'AS statement_start_offset, 
					' +
				CASE
					WHEN 
						(
							@output_column_list LIKE '%|[sql_text|]%' ESCAPE '|' 
							OR @output_column_list LIKE '%|[query_plan|]%' ESCAPE '|' 
						)
						AND @recursion = 1
							THEN 
								'x.statement_end_offset '
					ELSE 
						'NULL '
				END + 
					'AS statement_end_offset, 
					' +
				'NULL AS sql_text, 
					' +
				CASE
					WHEN 
						@output_column_list LIKE '%|[query_plan|]%' ESCAPE '|' 
						AND @recursion = 1
							THEN 
								'x.plan_handle '
					ELSE 
						'NULL '
				END + 
					'AS plan_handle, 
					' +
				CASE
					WHEN 
						@output_column_list LIKE '%|[blocking_session_id|]%' ESCAPE '|' 
						AND @recursion = 1
							THEN 
								'NULLIF(x.blocking_session_id, 0) '
					ELSE 
						'NULL '
				END + 
					'AS blocking_session_id, 
					' +
				CASE
					WHEN 
						@output_column_list LIKE '%|[percent_complete|]%' ESCAPE '|'
						AND @recursion = 1
							THEN 
								'x.percent_complete '
					ELSE 
						'NULL '
				END + 
					'AS percent_complete, 
					' +
				CASE
					WHEN 
						@output_column_list LIKE '%|[host_name|]%' ESCAPE '|' 
						AND @recursion = 1
							THEN 
								'x.host_name '
					ELSE 
						''''' '
				END + 
					'AS host_name, 
					' +
				CASE
					WHEN 
						@output_column_list LIKE '%|[login_name|]%' ESCAPE '|' 
						AND @recursion = 1
							THEN 
								'x.login_name '
					ELSE 
						''''' '
				END + 
					'AS login_name, 
					' +
				CASE
					WHEN 
						@output_column_list LIKE '%|[database_name|]%' ESCAPE '|' 
						AND @recursion = 1
							THEN 
								'DB_NAME(x.database_id) '
					ELSE 
						'NULL '
				END + 
					'AS database_name, 
					' +
				CASE
					WHEN 
						@output_column_list LIKE '%|[program_name|]%' ESCAPE '|' 
						AND @recursion = 1
							THEN 
								'x.program_name '
					ELSE 
						''''' '
				END + 
					'AS program_name, 
					' +
				CASE
					WHEN
						@output_column_list LIKE '%|[additional_info|]%' ESCAPE '|'
						AND @recursion = 1
							THEN
								'(
									SELECT TOP(@i)
										x.text_size,
										x.language,
										x.date_format,
										x.date_first,
										CASE x.quoted_identifier
											WHEN 0 THEN ''OFF''
											WHEN 1 THEN ''ON''
										END AS quoted_identifier,
										CASE x.arithabort
											WHEN 0 THEN ''OFF''
											WHEN 1 THEN ''ON''
										END AS arithabort,
										CASE x.ansi_null_dflt_on
											WHEN 0 THEN ''OFF''
											WHEN 1 THEN ''ON''
										END AS ansi_null_dflt_on,
										CASE x.ansi_defaults
											WHEN 0 THEN ''OFF''
											WHEN 1 THEN ''ON''
										END AS ansi_defaults,
										CASE x.ansi_warnings
											WHEN 0 THEN ''OFF''
											WHEN 1 THEN ''ON''
										END AS ansi_warnings,
										CASE x.ansi_padding
											WHEN 0 THEN ''OFF''
											WHEN 1 THEN ''ON''
										END AS ansi_padding,
										CASE ansi_nulls
											WHEN 0 THEN ''OFF''
											WHEN 1 THEN ''ON''
										END AS ansi_nulls,
										CASE x.concat_null_yields_null
											WHEN 0 THEN ''OFF''
											WHEN 1 THEN ''ON''
										END AS concat_null_yields_null,
										CASE x.transaction_isolation_level
											WHEN 0 THEN ''Unspecified''
											WHEN 1 THEN ''ReadUncomitted''
											WHEN 2 THEN ''ReadCommitted''
											WHEN 3 THEN ''Repeatable''
											WHEN 4 THEN ''Serializable''
											WHEN 5 THEN ''Snapshot''
										END AS transaction_isolation_level,
										x.lock_timeout,
										x.deadlock_priority,
										x.row_count,
										x.command_type, 
										' +
										CASE
											WHEN OBJECT_ID('master.dbo.fn_varbintohexstr') IS NOT NULL THEN
												'master.dbo.fn_varbintohexstr(x.sql_handle) AS sql_handle,
												master.dbo.fn_varbintohexstr(x.plan_handle) AS plan_handle,'
											ELSE
												'CONVERT(VARCHAR(256), x.sql_handle, 1) AS sql_handle,
												CONVERT(VARCHAR(256), x.plan_handle, 1) AS plan_handle,'
										END +
										'
										' +
										CASE
											WHEN @output_column_list LIKE '%|[program_name|]%' ESCAPE '|' THEN
												'(
													SELECT TOP(1)
														CONVERT(uniqueidentifier, CONVERT(XML, '''').value(''xs:hexBinary( substring(sql:column("agent_info.job_id_string"), 0) )'', ''binary(16)'')) AS job_id,
														agent_info.step_id,
														(
															SELECT TOP(1)
																NULL
															FOR XML
																PATH(''job_name''),
																TYPE
														),
														(
															SELECT TOP(1)
																NULL
															FOR XML
																PATH(''step_name''),
																TYPE
														)
													FROM
													(
														SELECT TOP(1)
															SUBSTRING(x.program_name, CHARINDEX(''0x'', x.program_name) + 2, 32) AS job_id_string,
															SUBSTRING(x.program_name, CHARINDEX('': Step '', x.program_name) + 7, CHARINDEX('')'', x.program_name, CHARINDEX('': Step '', x.program_name)) - (CHARINDEX('': Step '', x.program_name) + 7)) AS step_id
														WHERE
															x.program_name LIKE N''SQLAgent - TSQL JobStep (Job 0x%''
													) AS agent_info
													FOR XML
														PATH(''agent_job_info''),
														TYPE
												),
												'
											ELSE ''
										END +
										CASE
											WHEN @get_task_info = 2 THEN
												'CONVERT(XML, x.block_info) AS block_info, 
												'
											ELSE
												''
										END + '
										x.host_process_id,
										x.group_id
									FOR XML
										PATH(''additional_info''),
										TYPE
								) '
					ELSE
						'NULL '
				END + 
					'AS additional_info, 
				x.start_time, 
					' +
				CASE
					WHEN
						@output_column_list LIKE '%|[login_time|]%' ESCAPE '|'
						AND @recursion = 1
							THEN
								'x.login_time '
					ELSE 
						'NULL '
				END + 
					'AS login_time, 
				x.last_request_start_time
			FROM
			(
				SELECT TOP(@i)
					y.*,
					CASE
						WHEN DATEDIFF(hour, y.start_time, GETDATE()) > 576 THEN
							DATEDIFF(second, GETDATE(), y.start_time)
						ELSE DATEDIFF(ms, y.start_time, GETDATE())
					END AS elapsed_time,
					COALESCE(tempdb_info.tempdb_allocations, 0) AS tempdb_allocations,
					COALESCE
					(
						CASE
							WHEN tempdb_info.tempdb_current < 0 THEN 0
							ELSE tempdb_info.tempdb_current
						END,
						0
					) AS tempdb_current, 
					' +
					CASE
						WHEN 
							(
								@get_task_info <> 0
								OR @find_block_leaders = 1
							) THEN
								'N''('' + CONVERT(NVARCHAR, y.wait_duration_ms) + N''ms)'' +
									y.wait_type +
										CASE
											WHEN y.wait_type LIKE N''PAGE%LATCH_%'' THEN
												N'':'' +
												COALESCE(DB_NAME(CONVERT(INT, LEFT(y.resource_description, CHARINDEX(N'':'', y.resource_description) - 1))), N''(null)'') +
												N'':'' +
												SUBSTRING(y.resource_description, CHARINDEX(N'':'', y.resource_description) + 1, LEN(y.resource_description) - CHARINDEX(N'':'', REVERSE(y.resource_description)) - CHARINDEX(N'':'', y.resource_description)) +
												N''('' +
													CASE
														WHEN
															CONVERT(INT, RIGHT(y.resource_description, CHARINDEX(N'':'', REVERSE(y.resource_description)) - 1)) = 1 OR
															CONVERT(INT, RIGHT(y.resource_description, CHARINDEX(N'':'', REVERSE(y.resource_description)) - 1)) % 8088 = 0
																THEN 
																	N''PFS''
														WHEN
															CONVERT(INT, RIGHT(y.resource_description, CHARINDEX(N'':'', REVERSE(y.resource_description)) - 1)) = 2 OR
															CONVERT(INT, RIGHT(y.resource_description, CHARINDEX(N'':'', REVERSE(y.resource_description)) - 1)) % 511232 = 0
																THEN 
																	N''GAM''
														WHEN
															CONVERT(INT, RIGHT(y.resource_description, CHARINDEX(N'':'', REVERSE(y.resource_description)) - 1)) = 3 OR
															(CONVERT(INT, RIGHT(y.resource_description, CHARINDEX(N'':'', REVERSE(y.resource_description)) - 1)) - 1) % 511232 = 0
																THEN
																	N''SGAM''
														WHEN
															CONVERT(INT, RIGHT(y.resource_description, CHARINDEX(N'':'', REVERSE(y.resource_description)) - 1)) = 6 OR
															(CONVERT(INT, RIGHT(y.resource_description, CHARINDEX(N'':'', REVERSE(y.resource_description)) - 1)) - 6) % 511232 = 0 
																THEN 
																	N''DCM''
														WHEN
															CONVERT(INT, RIGHT(y.resource_description, CHARINDEX(N'':'', REVERSE(y.resource_description)) - 1)) = 7 OR
															(CONVERT(INT, RIGHT(y.resource_description, CHARINDEX(N'':'', REVERSE(y.resource_description)) - 1)) - 7) % 511232 = 0 
																THEN 
																	N''BCM''
														ELSE 
															N''*''
													END +
												N'')''
											WHEN y.wait_type = N''CXPACKET'' THEN
												N'':'' + SUBSTRING(y.resource_description, CHARINDEX(N''nodeId'', y.resource_description) + 7, 4)
											WHEN y.wait_type LIKE N''LATCH[_]%'' THEN
												N'' ['' + LEFT(y.resource_description, COALESCE(NULLIF(CHARINDEX(N'' '', y.resource_description), 0), LEN(y.resource_description) + 1) - 1) + N'']''
											WHEN
												y.wait_type = N''OLEDB''
												AND y.resource_description LIKE N''%(SPID=%)'' THEN
													N''['' + LEFT(y.resource_description, CHARINDEX(N''(SPID='', y.resource_description) - 2) +
														N'':'' + SUBSTRING(y.resource_description, CHARINDEX(N''(SPID='', y.resource_description) + 6, CHARINDEX(N'')'', y.resource_description, (CHARINDEX(N''(SPID='', y.resource_description) + 6)) - (CHARINDEX(N''(SPID='', y.resource_description) + 6)) + '']''
											ELSE
												N''''
										END COLLATE Latin1_General_Bin2 AS sys_wait_info, 
										'
							ELSE
								''
						END +
						CASE
							WHEN @get_task_info = 2 THEN
								'tasks.physical_io,
								tasks.context_switches,
								tasks.tasks,
								tasks.block_info,
								tasks.wait_info AS task_wait_info,
								tasks.thread_CPU_snapshot,
								'
							ELSE
								'' 
					END +
					CASE 
						WHEN NOT (@get_avg_time = 1 AND @recursion = 1) THEN
							'CONVERT(INT, NULL) '
						ELSE 
							'qs.total_elapsed_time / qs.execution_count '
					END + 
						'AS avg_elapsed_time 
				FROM
				(
					SELECT TOP(@i)
						sp.session_id,
						sp.request_id,
						COALESCE(r.logical_reads, s.logical_reads) AS reads,
						COALESCE(r.reads, s.reads) AS physical_reads,
						COALESCE(r.writes, s.writes) AS writes,
						COALESCE(r.CPU_time, s.CPU_time) AS CPU,
						sp.memory_usage + COALESCE(r.granted_query_memory, 0) AS used_memory,
						LOWER(sp.status) AS status,
						COALESCE(r.sql_handle, sp.sql_handle) AS sql_handle,
						COALESCE(r.statement_start_offset, sp.statement_start_offset) AS statement_start_offset,
						COALESCE(r.statement_end_offset, sp.statement_end_offset) AS statement_end_offset,
						' +
						CASE
							WHEN 
							(
								@get_task_info <> 0
								OR @find_block_leaders = 1 
							) THEN
								'sp.wait_type COLLATE Latin1_General_Bin2 AS wait_type,
								sp.wait_resource COLLATE Latin1_General_Bin2 AS resource_description,
								sp.wait_time AS wait_duration_ms, 
								'
							ELSE
								''
						END +
						'NULLIF(sp.blocked, 0) AS blocking_session_id,
						r.plan_handle,
						NULLIF(r.percent_complete, 0) AS percent_complete,
						sp.host_name,
						sp.login_name,
						sp.program_name,
						s.host_process_id,
						COALESCE(r.text_size, s.text_size) AS text_size,
						COALESCE(r.language, s.language) AS language,
						COALESCE(r.date_format, s.date_format) AS date_format,
						COALESCE(r.date_first, s.date_first) AS date_first,
						COALESCE(r.quoted_identifier, s.quoted_identifier) AS quoted_identifier,
						COALESCE(r.arithabort, s.arithabort) AS arithabort,
						COALESCE(r.ansi_null_dflt_on, s.ansi_null_dflt_on) AS ansi_null_dflt_on,
						COALESCE(r.ansi_defaults, s.ansi_defaults) AS ansi_defaults,
						COALESCE(r.ansi_warnings, s.ansi_warnings) AS ansi_warnings,
						COALESCE(r.ansi_padding, s.ansi_padding) AS ansi_padding,
						COALESCE(r.ansi_nulls, s.ansi_nulls) AS ansi_nulls,
						COALESCE(r.concat_null_yields_null, s.concat_null_yields_null) AS concat_null_yields_null,
						COALESCE(r.transaction_isolation_level, s.transaction_isolation_level) AS transaction_isolation_level,
						COALESCE(r.lock_timeout, s.lock_timeout) AS lock_timeout,
						COALESCE(r.deadlock_priority, s.deadlock_priority) AS deadlock_priority,
						COALESCE(r.row_count, s.row_count) AS row_count,
						COALESCE(r.command, sp.cmd) AS command_type,
						COALESCE
						(
							CASE
								WHEN
								(
									s.is_user_process = 0
									AND r.total_elapsed_time >= 0
								) THEN
									DATEADD
									(
										ms,
										1000 * (DATEPART(ms, DATEADD(second, -(r.total_elapsed_time / 1000), GETDATE())) / 500) - DATEPART(ms, DATEADD(second, -(r.total_elapsed_time / 1000), GETDATE())),
										DATEADD(second, -(r.total_elapsed_time / 1000), GETDATE())
									)
							END,
							NULLIF(COALESCE(r.start_time, sp.last_request_end_time), CONVERT(DATETIME, ''19000101'', 112)),
							sp.login_time
						) AS start_time,
						sp.login_time,
						CASE
							WHEN s.is_user_process = 1 THEN
								s.last_request_start_time
							ELSE
								COALESCE
								(
									DATEADD
									(
										ms,
										1000 * (DATEPART(ms, DATEADD(second, -(r.total_elapsed_time / 1000), GETDATE())) / 500) - DATEPART(ms, DATEADD(second, -(r.total_elapsed_time / 1000), GETDATE())),
										DATEADD(second, -(r.total_elapsed_time / 1000), GETDATE())
									),
									s.last_request_start_time
								)
						END AS last_request_start_time,
						r.transaction_id,
						sp.database_id,
						sp.open_tran_count,
						' +
							CASE
								WHEN EXISTS
								(
									SELECT
										*
									FROM sys.all_columns AS ac
									WHERE
										ac.object_id = OBJECT_ID('sys.dm_exec_sessions')
										AND ac.name = 'group_id'
								)
									THEN 's.group_id'
								ELSE 'CONVERT(INT, NULL) AS group_id'
							END + '
					FROM @sessions AS sp
					LEFT OUTER LOOP JOIN sys.dm_exec_sessions AS s ON
						s.session_id = sp.session_id
						AND s.login_time = sp.login_time
					LEFT OUTER LOOP JOIN sys.dm_exec_requests AS r ON
						sp.status <> ''sleeping''
						AND r.session_id = sp.session_id
						AND r.request_id = sp.request_id
						AND
						(
							(
								s.is_user_process = 0
								AND sp.is_user_process = 0
							)
							OR
							(
								r.start_time = s.last_request_start_time
								AND s.last_request_end_time <= sp.last_request_end_time
							)
						)
				) AS y
				' + 
				CASE 
					WHEN @get_task_info = 2 THEN
						CONVERT(VARCHAR(MAX), '') +
						'LEFT OUTER HASH JOIN
						(
							SELECT TOP(@i)
								task_nodes.task_node.value(''(session_id/text())[1]'', ''SMALLINT'') AS session_id,
								task_nodes.task_node.value(''(request_id/text())[1]'', ''INT'') AS request_id,
								task_nodes.task_node.value(''(physical_io/text())[1]'', ''BIGINT'') AS physical_io,
								task_nodes.task_node.value(''(context_switches/text())[1]'', ''BIGINT'') AS context_switches,
								task_nodes.task_node.value(''(tasks/text())[1]'', ''INT'') AS tasks,
								task_nodes.task_node.value(''(block_info/text())[1]'', ''NVARCHAR(4000)'') AS block_info,
								task_nodes.task_node.value(''(waits/text())[1]'', ''NVARCHAR(4000)'') AS wait_info,
								task_nodes.task_node.value(''(thread_CPU_snapshot/text())[1]'', ''BIGINT'') AS thread_CPU_snapshot
							FROM
							(
								SELECT TOP(@i)
									CONVERT
									(
										XML,
										REPLACE
										(
											CONVERT(NVARCHAR(MAX), tasks_raw.task_xml_raw) COLLATE Latin1_General_Bin2,
											N''</waits></tasks><tasks><waits>'',
											N'', ''
										)
									) AS task_xml
								FROM
								(
									SELECT TOP(@i)
										CASE waits.r
											WHEN 1 THEN
												waits.session_id
											ELSE
												NULL
										END AS [session_id],
										CASE waits.r
											WHEN 1 THEN
												waits.request_id
											ELSE
												NULL
										END AS [request_id],											
										CASE waits.r
											WHEN 1 THEN
												waits.physical_io
											ELSE
												NULL
										END AS [physical_io],
										CASE waits.r
											WHEN 1 THEN
												waits.context_switches
											ELSE
												NULL
										END AS [context_switches],
										CASE waits.r
											WHEN 1 THEN
												waits.thread_CPU_snapshot
											ELSE
												NULL
										END AS [thread_CPU_snapshot],
										CASE waits.r
											WHEN 1 THEN
												waits.tasks
											ELSE
												NULL
										END AS [tasks],
										CASE waits.r
											WHEN 1 THEN
												waits.block_info
											ELSE
												NULL
										END AS [block_info],
										REPLACE
										(
											REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
											REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
											REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
												CONVERT
												(
													NVARCHAR(MAX),
													N''('' +
														CONVERT(NVARCHAR, num_waits) + N''x: '' +
														CASE num_waits
															WHEN 1 THEN
																CONVERT(NVARCHAR, min_wait_time) + N''ms''
															WHEN 2 THEN
																CASE
																	WHEN min_wait_time <> max_wait_time THEN
																		CONVERT(NVARCHAR, min_wait_time) + N''/'' + CONVERT(NVARCHAR, max_wait_time) + N''ms''
																	ELSE
																		CONVERT(NVARCHAR, max_wait_time) + N''ms''
																END
															ELSE
																CASE
																	WHEN min_wait_time <> max_wait_time THEN
																		CONVERT(NVARCHAR, min_wait_time) + N''/'' + CONVERT(NVARCHAR, avg_wait_time) + N''/'' + CONVERT(NVARCHAR, max_wait_time) + N''ms''
																	ELSE 
																		CONVERT(NVARCHAR, max_wait_time) + N''ms''
																END
														END +
													N'')'' + wait_type COLLATE Latin1_General_Bin2
												),
												NCHAR(31),N''?''),NCHAR(30),N''?''),NCHAR(29),N''?''),NCHAR(28),N''?''),NCHAR(27),N''?''),NCHAR(26),N''?''),NCHAR(25),N''?''),NCHAR(24),N''?''),NCHAR(23),N''?''),NCHAR(22),N''?''),
												NCHAR(21),N''?''),NCHAR(20),N''?''),NCHAR(19),N''?''),NCHAR(18),N''?''),NCHAR(17),N''?''),NCHAR(16),N''?''),NCHAR(15),N''?''),NCHAR(14),N''?''),NCHAR(12),N''?''),
												NCHAR(11),N''?''),NCHAR(8),N''?''),NCHAR(7),N''?''),NCHAR(6),N''?''),NCHAR(5),N''?''),NCHAR(4),N''?''),NCHAR(3),N''?''),NCHAR(2),N''?''),NCHAR(1),N''?''),
											NCHAR(0),
											N''''
										) AS [waits]
									FROM
									(
										SELECT TOP(@i)
											w1.*,
											ROW_NUMBER() OVER
											(
												PARTITION BY
													w1.session_id,
													w1.request_id
												ORDER BY
													w1.block_info DESC,
													w1.num_waits DESC,
													w1.wait_type
											) AS r
										FROM
										(
											SELECT TOP(@i)
												task_info.session_id,
												task_info.request_id,
												task_info.physical_io,
												task_info.context_switches,
												task_info.thread_CPU_snapshot,
												task_info.num_tasks AS tasks,
												CASE
													WHEN task_info.runnable_time IS NOT NULL THEN
														''RUNNABLE''
													ELSE
														wt2.wait_type
												END AS wait_type,
												NULLIF(COUNT(COALESCE(task_info.runnable_time, wt2.waiting_task_address)), 0) AS num_waits,
												MIN(COALESCE(task_info.runnable_time, wt2.wait_duration_ms)) AS min_wait_time,
												AVG(COALESCE(task_info.runnable_time, wt2.wait_duration_ms)) AS avg_wait_time,
												MAX(COALESCE(task_info.runnable_time, wt2.wait_duration_ms)) AS max_wait_time,
												MAX(wt2.block_info) AS block_info
											FROM
											(
												SELECT TOP(@i)
													t.session_id,
													t.request_id,
													SUM(CONVERT(BIGINT, t.pending_io_count)) OVER (PARTITION BY t.session_id, t.request_id) AS physical_io,
													SUM(CONVERT(BIGINT, t.context_switches_count)) OVER (PARTITION BY t.session_id, t.request_id) AS context_switches, 
													' +
													CASE
														WHEN 
															@output_column_list LIKE '%|[CPU_delta|]%' ESCAPE '|'
															AND @sys_info = 1
															THEN
																'SUM(tr.usermode_time + tr.kernel_time) OVER (PARTITION BY t.session_id, t.request_id) '
														ELSE
															'CONVERT(BIGINT, NULL) '
													END + 
														' AS thread_CPU_snapshot, 
													COUNT(*) OVER (PARTITION BY t.session_id, t.request_id) AS num_tasks,
													t.task_address,
													t.task_state,
													CASE
														WHEN
															t.task_state = ''RUNNABLE''
															AND w.runnable_time > 0 THEN
																w.runnable_time
														ELSE
															NULL
													END AS runnable_time
												FROM sys.dm_os_tasks AS t
												CROSS APPLY
												(
													SELECT TOP(1)
														sp2.session_id
													FROM @sessions AS sp2
													WHERE
														sp2.session_id = t.session_id
														AND sp2.request_id = t.request_id
														AND sp2.status <> ''sleeping''
												) AS sp20
												LEFT OUTER HASH JOIN
												( 
												' +
													CASE
														WHEN @sys_info = 1 THEN
															'SELECT TOP(@i)
																(
																	SELECT TOP(@i)
																		ms_ticks
																	FROM sys.dm_os_sys_info
																) -
																	w0.wait_resumed_ms_ticks AS runnable_time,
																w0.worker_address,
																w0.thread_address,
																w0.task_bound_ms_ticks
															FROM sys.dm_os_workers AS w0
															WHERE
																w0.state = ''RUNNABLE''
																OR @first_collection_ms_ticks >= w0.task_bound_ms_ticks'
														ELSE
															'SELECT
																CONVERT(BIGINT, NULL) AS runnable_time,
																CONVERT(VARBINARY(8), NULL) AS worker_address,
																CONVERT(VARBINARY(8), NULL) AS thread_address,
																CONVERT(BIGINT, NULL) AS task_bound_ms_ticks
															WHERE
																1 = 0'
														END +
												'
												) AS w ON
													w.worker_address = t.worker_address 
												' +
												CASE
													WHEN
														@output_column_list LIKE '%|[CPU_delta|]%' ESCAPE '|'
														AND @sys_info = 1
														THEN
															'LEFT OUTER HASH JOIN sys.dm_os_threads AS tr ON
																tr.thread_address = w.thread_address
																AND @first_collection_ms_ticks >= w.task_bound_ms_ticks
															'
													ELSE
														''
												END +
											') AS task_info
											LEFT OUTER HASH JOIN
											(
												SELECT TOP(@i)
													wt1.wait_type,
													wt1.waiting_task_address,
													MAX(wt1.wait_duration_ms) AS wait_duration_ms,
													MAX(wt1.block_info) AS block_info
												FROM
												(
													SELECT DISTINCT TOP(@i)
														wt.wait_type +
															CASE
																WHEN wt.wait_type LIKE N''PAGE%LATCH_%'' THEN
																	'':'' +
																	COALESCE(DB_NAME(CONVERT(INT, LEFT(wt.resource_description, CHARINDEX(N'':'', wt.resource_description) - 1))), N''(null)'') +
																	N'':'' +
																	SUBSTRING(wt.resource_description, CHARINDEX(N'':'', wt.resource_description) + 1, LEN(wt.resource_description) - CHARINDEX(N'':'', REVERSE(wt.resource_description)) - CHARINDEX(N'':'', wt.resource_description)) +
																	N''('' +
																		CASE
																			WHEN
																				CONVERT(INT, RIGHT(wt.resource_description, CHARINDEX(N'':'', REVERSE(wt.resource_description)) - 1)) = 1 OR
																				CONVERT(INT, RIGHT(wt.resource_description, CHARINDEX(N'':'', REVERSE(wt.resource_description)) - 1)) % 8088 = 0
																					THEN 
																						N''PFS''
																			WHEN
																				CONVERT(INT, RIGHT(wt.resource_description, CHARINDEX(N'':'', REVERSE(wt.resource_description)) - 1)) = 2 OR
																				CONVERT(INT, RIGHT(wt.resource_description, CHARINDEX(N'':'', REVERSE(wt.resource_description)) - 1)) % 511232 = 0 
																					THEN 
																						N''GAM''
																			WHEN
																				CONVERT(INT, RIGHT(wt.resource_description, CHARINDEX(N'':'', REVERSE(wt.resource_description)) - 1)) = 3 OR
																				(CONVERT(INT, RIGHT(wt.resource_description, CHARINDEX(N'':'', REVERSE(wt.resource_description)) - 1)) - 1) % 511232 = 0 
																					THEN 
																						N''SGAM''
																			WHEN
																				CONVERT(INT, RIGHT(wt.resource_description, CHARINDEX(N'':'', REVERSE(wt.resource_description)) - 1)) = 6 OR
																				(CONVERT(INT, RIGHT(wt.resource_description, CHARINDEX(N'':'', REVERSE(wt.resource_description)) - 1)) - 6) % 511232 = 0 
																					THEN 
																						N''DCM''
																			WHEN
																				CONVERT(INT, RIGHT(wt.resource_description, CHARINDEX(N'':'', REVERSE(wt.resource_description)) - 1)) = 7 OR
																				(CONVERT(INT, RIGHT(wt.resource_description, CHARINDEX(N'':'', REVERSE(wt.resource_description)) - 1)) - 7) % 511232 = 0
																					THEN 
																						N''BCM''
																			ELSE
																				N''*''
																		END +
																	N'')''
																WHEN wt.wait_type = N''CXPACKET'' THEN
																	N'':'' + SUBSTRING(wt.resource_description, CHARINDEX(N''nodeId'', wt.resource_description) + 7, 4)
																WHEN wt.wait_type LIKE N''LATCH[_]%'' THEN
																	N'' ['' + LEFT(wt.resource_description, COALESCE(NULLIF(CHARINDEX(N'' '', wt.resource_description), 0), LEN(wt.resource_description) + 1) - 1) + N'']''
																ELSE 
																	N''''
															END COLLATE Latin1_General_Bin2 AS wait_type,
														CASE
															WHEN
															(
																wt.blocking_session_id IS NOT NULL
																AND wt.wait_type LIKE N''LCK[_]%''
															) THEN
																(
																	SELECT TOP(@i)
																		x.lock_type,
																		REPLACE
																		(
																			REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
																			REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
																			REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
																				DB_NAME
																				(
																					CONVERT
																					(
																						INT,
																						SUBSTRING(wt.resource_description, NULLIF(CHARINDEX(N''dbid='', wt.resource_description), 0) + 5, COALESCE(NULLIF(CHARINDEX(N'' '', wt.resource_description, CHARINDEX(N''dbid='', wt.resource_description) + 5), 0), LEN(wt.resource_description) + 1) - CHARINDEX(N''dbid='', wt.resource_description) - 5)
																					)
																				),
																				NCHAR(31),N''?''),NCHAR(30),N''?''),NCHAR(29),N''?''),NCHAR(28),N''?''),NCHAR(27),N''?''),NCHAR(26),N''?''),NCHAR(25),N''?''),NCHAR(24),N''?''),NCHAR(23),N''?''),NCHAR(22),N''?''),
																				NCHAR(21),N''?''),NCHAR(20),N''?''),NCHAR(19),N''?''),NCHAR(18),N''?''),NCHAR(17),N''?''),NCHAR(16),N''?''),NCHAR(15),N''?''),NCHAR(14),N''?''),NCHAR(12),N''?''),
																				NCHAR(11),N''?''),NCHAR(8),N''?''),NCHAR(7),N''?''),NCHAR(6),N''?''),NCHAR(5),N''?''),NCHAR(4),N''?''),NCHAR(3),N''?''),NCHAR(2),N''?''),NCHAR(1),N''?''),
																			NCHAR(0),
																			N''''
																		) AS database_name,
																		CASE x.lock_type
																			WHEN N''objectlock'' THEN
																				SUBSTRING(wt.resource_description, NULLIF(CHARINDEX(N''objid='', wt.resource_description), 0) + 6, COALESCE(NULLIF(CHARINDEX(N'' '', wt.resource_description, CHARINDEX(N''objid='', wt.resource_description) + 6), 0), LEN(wt.resource_description) + 1) - CHARINDEX(N''objid='', wt.resource_description) - 6)
																			ELSE
																				NULL
																		END AS object_id,
																		CASE x.lock_type
																			WHEN N''filelock'' THEN
																				SUBSTRING(wt.resource_description, NULLIF(CHARINDEX(N''fileid='', wt.resource_description), 0) + 7, COALESCE(NULLIF(CHARINDEX(N'' '', wt.resource_description, CHARINDEX(N''fileid='', wt.resource_description) + 7), 0), LEN(wt.resource_description) + 1) - CHARINDEX(N''fileid='', wt.resource_description) - 7)
																			ELSE
																				NULL
																		END AS file_id,
																		CASE
																			WHEN x.lock_type in (N''pagelock'', N''extentlock'', N''ridlock'') THEN
																				SUBSTRING(wt.resource_description, NULLIF(CHARINDEX(N''associatedObjectId='', wt.resource_description), 0) + 19, COALESCE(NULLIF(CHARINDEX(N'' '', wt.resource_description, CHARINDEX(N''associatedObjectId='', wt.resource_description) + 19), 0), LEN(wt.resource_description) + 1) - CHARINDEX(N''associatedObjectId='', wt.resource_description) - 19)
																			WHEN x.lock_type in (N''keylock'', N''hobtlock'', N''allocunitlock'') THEN
																				SUBSTRING(wt.resource_description, NULLIF(CHARINDEX(N''hobtid='', wt.resource_description), 0) + 7, COALESCE(NULLIF(CHARINDEX(N'' '', wt.resource_description, CHARINDEX(N''hobtid='', wt.resource_description) + 7), 0), LEN(wt.resource_description) + 1) - CHARINDEX(N''hobtid='', wt.resource_description) - 7)
																			ELSE
																				NULL
																		END AS hobt_id,
																		CASE x.lock_type
																			WHEN N''applicationlock'' THEN
																				SUBSTRING(wt.resource_description, NULLIF(CHARINDEX(N''hash='', wt.resource_description), 0) + 5, COALESCE(NULLIF(CHARINDEX(N'' '', wt.resource_description, CHARINDEX(N''hash='', wt.resource_description) + 5), 0), LEN(wt.resource_description) + 1) - CHARINDEX(N''hash='', wt.resource_description) - 5)
																			ELSE
																				NULL
																		END AS applock_hash,
																		CASE x.lock_type
																			WHEN N''metadatalock'' THEN
																				SUBSTRING(wt.resource_description, NULLIF(CHARINDEX(N''subresource='', wt.resource_description), 0) + 12, COALESCE(NULLIF(CHARINDEX(N'' '', wt.resource_description, CHARINDEX(N''subresource='', wt.resource_description) + 12), 0), LEN(wt.resource_description) + 1) - CHARINDEX(N''subresource='', wt.resource_description) - 12)
																			ELSE
																				NULL
																		END AS metadata_resource,
																		CASE x.lock_type
																			WHEN N''metadatalock'' THEN
																				SUBSTRING(wt.resource_description, NULLIF(CHARINDEX(N''classid='', wt.resource_description), 0) + 8, COALESCE(NULLIF(CHARINDEX(N'' dbid='', wt.resource_description) - CHARINDEX(N''classid='', wt.resource_description), 0), LEN(wt.resource_description) + 1) - 8)
																			ELSE
																				NULL
																		END AS metadata_class_id
																	FROM
																	(
																		SELECT TOP(1)
																			LEFT(wt.resource_description, CHARINDEX(N'' '', wt.resource_description) - 1) COLLATE Latin1_General_Bin2 AS lock_type
																	) AS x
																	FOR XML
																		PATH('''')
																)
															ELSE NULL
														END AS block_info,
														wt.wait_duration_ms,
														wt.waiting_task_address
													FROM
													(
														SELECT TOP(@i)
															wt0.wait_type COLLATE Latin1_General_Bin2 AS wait_type,
															wt0.resource_description COLLATE Latin1_General_Bin2 AS resource_description,
															wt0.wait_duration_ms,
															wt0.waiting_task_address,
															CASE
																WHEN wt0.blocking_session_id = p.blocked THEN
																	wt0.blocking_session_id
																ELSE
																	NULL
															END AS blocking_session_id
														FROM sys.dm_os_waiting_tasks AS wt0
														CROSS APPLY
														(
															SELECT TOP(1)
																s0.blocked
															FROM @sessions AS s0
															WHERE
																s0.session_id = wt0.session_id
																AND COALESCE(s0.wait_type, N'''') <> N''OLEDB''
																AND wt0.wait_type <> N''OLEDB''
														) AS p
													) AS wt
												) AS wt1
												GROUP BY
													wt1.wait_type,
													wt1.waiting_task_address
											) AS wt2 ON
												wt2.waiting_task_address = task_info.task_address
												AND wt2.wait_duration_ms > 0
												AND task_info.runnable_time IS NULL
											GROUP BY
												task_info.session_id,
												task_info.request_id,
												task_info.physical_io,
												task_info.context_switches,
												task_info.thread_CPU_snapshot,
												task_info.num_tasks,
												CASE
													WHEN task_info.runnable_time IS NOT NULL THEN
														''RUNNABLE''
													ELSE
														wt2.wait_type
												END
										) AS w1
									) AS waits
									ORDER BY
										waits.session_id,
										waits.request_id,
										waits.r
									FOR XML
										PATH(N''tasks''),
										TYPE
								) AS tasks_raw (task_xml_raw)
							) AS tasks_final
							CROSS APPLY tasks_final.task_xml.nodes(N''/tasks'') AS task_nodes (task_node)
							WHERE
								task_nodes.task_node.exist(N''session_id'') = 1
						) AS tasks ON
							tasks.session_id = y.session_id
							AND tasks.request_id = y.request_id 
						'
					ELSE
						''
				END +
				'LEFT OUTER HASH JOIN
				(
					SELECT TOP(@i)
						t_info.session_id,
						COALESCE(t_info.request_id, -1) AS request_id,
						SUM(t_info.tempdb_allocations) AS tempdb_allocations,
						SUM(t_info.tempdb_current) AS tempdb_current
					FROM
					(
						SELECT TOP(@i)
							tsu.session_id,
							tsu.request_id,
							tsu.user_objects_alloc_page_count +
								tsu.internal_objects_alloc_page_count AS tempdb_allocations,
							tsu.user_objects_alloc_page_count +
								tsu.internal_objects_alloc_page_count -
								tsu.user_objects_dealloc_page_count -
								tsu.internal_objects_dealloc_page_count AS tempdb_current
						FROM sys.dm_db_task_space_usage AS tsu
						CROSS APPLY
						(
							SELECT TOP(1)
								s0.session_id
							FROM @sessions AS s0
							WHERE
								s0.session_id = tsu.session_id
						) AS p

						UNION ALL

						SELECT TOP(@i)
							ssu.session_id,
							NULL AS request_id,
							ssu.user_objects_alloc_page_count +
								ssu.internal_objects_alloc_page_count AS tempdb_allocations,
							ssu.user_objects_alloc_page_count +
								ssu.internal_objects_alloc_page_count -
								ssu.user_objects_dealloc_page_count -
								ssu.internal_objects_dealloc_page_count AS tempdb_current
						FROM sys.dm_db_session_space_usage AS ssu
						CROSS APPLY
						(
							SELECT TOP(1)
								s0.session_id
							FROM @sessions AS s0
							WHERE
								s0.session_id = ssu.session_id
						) AS p
					) AS t_info
					GROUP BY
						t_info.session_id,
						COALESCE(t_info.request_id, -1)
				) AS tempdb_info ON
					tempdb_info.session_id = y.session_id
					AND tempdb_info.request_id =
						CASE
							WHEN y.status = N''sleeping'' THEN
								-1
							ELSE
								y.request_id
						END
				' +
				CASE 
					WHEN 
						NOT 
						(
							@get_avg_time = 1 
							AND @recursion = 1
						) THEN 
							''
					ELSE
						'LEFT OUTER HASH JOIN
						(
							SELECT TOP(@i)
								*
							FROM sys.dm_exec_query_stats
						) AS qs ON
							qs.sql_handle = y.sql_handle
							AND qs.plan_handle = y.plan_handle
							AND qs.statement_start_offset = y.statement_start_offset
							AND qs.statement_end_offset = y.statement_end_offset
						'
				END + 
			') AS x
			OPTION (KEEPFIXED PLAN, OPTIMIZE FOR (@i = 1)); ';

		SET @sql_n = CONVERT(NVARCHAR(MAX), @sql);

		SET @last_collection_start = GETDATE();

		IF 
			@recursion = -1
			AND @sys_info = 1
		BEGIN;
			SELECT
				@first_collection_ms_ticks = ms_ticks
			FROM sys.dm_os_sys_info;
		END;

		INSERT #sessions
		(
			recursion,
			session_id,
			request_id,
			session_number,
			elapsed_time,
			avg_elapsed_time,
			physical_io,
			reads,
			physical_reads,
			writes,
			tempdb_allocations,
			tempdb_current,
			CPU,
			thread_CPU_snapshot,
			context_switches,
			used_memory,
			tasks,
			status,
			wait_info,
			transaction_id,
			open_tran_count,
			sql_handle,
			statement_start_offset,
			statement_end_offset,		
			sql_text,
			plan_handle,
			blocking_session_id,
			percent_complete,
			host_name,
			login_name,
			database_name,
			program_name,
			additional_info,
			start_time,
			login_time,
			last_request_start_time
		)
		EXEC sp_executesql 
			@sql_n,
			N'@recursion SMALLINT, @filter sysname, @not_filter sysname, @first_collection_ms_ticks BIGINT',
			@recursion, @filter, @not_filter, @first_collection_ms_ticks;

		--Collect transaction information?
		IF
			@recursion = 1
			AND
			(
				@output_column_list LIKE '%|[tran_start_time|]%' ESCAPE '|'
				OR @output_column_list LIKE '%|[tran_log_writes|]%' ESCAPE '|' 
			)
		BEGIN;	
			DECLARE @i INT;
			SET @i = 2147483647;

			UPDATE s
			SET
				tran_start_time =
					CONVERT
					(
						DATETIME,
						LEFT
						(
							x.trans_info,
							NULLIF(CHARINDEX(NCHAR(254) COLLATE Latin1_General_Bin2, x.trans_info) - 1, -1)
						),
						121
					),
				tran_log_writes =
					RIGHT
					(
						x.trans_info,
						LEN(x.trans_info) - CHARINDEX(NCHAR(254) COLLATE Latin1_General_Bin2, x.trans_info)
					)
			FROM
			(
				SELECT TOP(@i)
					trans_nodes.trans_node.value('(session_id/text())[1]', 'SMALLINT') AS session_id,
					COALESCE(trans_nodes.trans_node.value('(request_id/text())[1]', 'INT'), 0) AS request_id,
					trans_nodes.trans_node.value('(trans_info/text())[1]', 'NVARCHAR(4000)') AS trans_info				
				FROM
				(
					SELECT TOP(@i)
						CONVERT
						(
							XML,
							REPLACE
							(
								CONVERT(NVARCHAR(MAX), trans_raw.trans_xml_raw) COLLATE Latin1_General_Bin2, 
								N'</trans_info></trans><trans><trans_info>', N''
							)
						)
					FROM
					(
						SELECT TOP(@i)
							CASE u_trans.r
								WHEN 1 THEN u_trans.session_id
								ELSE NULL
							END AS [session_id],
							CASE u_trans.r
								WHEN 1 THEN u_trans.request_id
								ELSE NULL
							END AS [request_id],
							CONVERT
							(
								NVARCHAR(MAX),
								CASE
									WHEN u_trans.database_id IS NOT NULL THEN
										CASE u_trans.r
											WHEN 1 THEN COALESCE(CONVERT(NVARCHAR, u_trans.transaction_start_time, 121) + NCHAR(254), N'')
											ELSE N''
										END + 
											REPLACE
											(
												REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
												REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
												REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
													CONVERT(VARCHAR(128), COALESCE(DB_NAME(u_trans.database_id), N'(null)')),
													NCHAR(31),N'?'),NCHAR(30),N'?'),NCHAR(29),N'?'),NCHAR(28),N'?'),NCHAR(27),N'?'),NCHAR(26),N'?'),NCHAR(25),N'?'),NCHAR(24),N'?'),NCHAR(23),N'?'),NCHAR(22),N'?'),
													NCHAR(21),N'?'),NCHAR(20),N'?'),NCHAR(19),N'?'),NCHAR(18),N'?'),NCHAR(17),N'?'),NCHAR(16),N'?'),NCHAR(15),N'?'),NCHAR(14),N'?'),NCHAR(12),N'?'),
													NCHAR(11),N'?'),NCHAR(8),N'?'),NCHAR(7),N'?'),NCHAR(6),N'?'),NCHAR(5),N'?'),NCHAR(4),N'?'),NCHAR(3),N'?'),NCHAR(2),N'?'),NCHAR(1),N'?'),
												NCHAR(0),
												N'?'
											) +
											N': ' +
										CONVERT(NVARCHAR, u_trans.log_record_count) + N' (' + CONVERT(NVARCHAR, u_trans.log_kb_used) + N' kB)' +
										N','
									ELSE
										N'N/A,'
								END COLLATE Latin1_General_Bin2
							) AS [trans_info]
						FROM
						(
							SELECT TOP(@i)
								trans.*,
								ROW_NUMBER() OVER
								(
									PARTITION BY
										trans.session_id,
										trans.request_id
									ORDER BY
										trans.transaction_start_time DESC
								) AS r
							FROM
							(
								SELECT TOP(@i)
									session_tran_map.session_id,
									session_tran_map.request_id,
									s_tran.database_id,
									COALESCE(SUM(s_tran.database_transaction_log_record_count), 0) AS log_record_count,
									COALESCE(SUM(s_tran.database_transaction_log_bytes_used), 0) / 1024 AS log_kb_used,
									MIN(s_tran.database_transaction_begin_time) AS transaction_start_time
								FROM
								(
									SELECT TOP(@i)
										*
									FROM sys.dm_tran_active_transactions
									WHERE
										transaction_begin_time <= @last_collection_start
								) AS a_tran
								INNER HASH JOIN
								(
									SELECT TOP(@i)
										*
									FROM sys.dm_tran_database_transactions
									WHERE
										database_id < 32767
								) AS s_tran ON
									s_tran.transaction_id = a_tran.transaction_id
								LEFT OUTER HASH JOIN
								(
									SELECT TOP(@i)
										*
									FROM sys.dm_tran_session_transactions
								) AS tst ON
									s_tran.transaction_id = tst.transaction_id
								CROSS APPLY
								(
									SELECT TOP(1)
										s3.session_id,
										s3.request_id
									FROM
									(
										SELECT TOP(1)
											s1.session_id,
											s1.request_id
										FROM #sessions AS s1
										WHERE
											s1.transaction_id = s_tran.transaction_id
											AND s1.recursion = 1
											
										UNION ALL
									
										SELECT TOP(1)
											s2.session_id,
											s2.request_id
										FROM #sessions AS s2
										WHERE
											s2.session_id = tst.session_id
											AND s2.recursion = 1
									) AS s3
									ORDER BY
										s3.request_id
								) AS session_tran_map
								GROUP BY
									session_tran_map.session_id,
									session_tran_map.request_id,
									s_tran.database_id
							) AS trans
						) AS u_trans
						FOR XML
							PATH('trans'),
							TYPE
					) AS trans_raw (trans_xml_raw)
				) AS trans_final (trans_xml)
				CROSS APPLY trans_final.trans_xml.nodes('/trans') AS trans_nodes (trans_node)
			) AS x
			INNER HASH JOIN #sessions AS s ON
				s.session_id = x.session_id
				AND s.request_id = x.request_id
			OPTION (OPTIMIZE FOR (@i = 1));
		END;

		--Variables for text and plan collection
		DECLARE	
			@session_id SMALLINT,
			@request_id INT,
			@sql_handle VARBINARY(64),
			@plan_handle VARBINARY(64),
			@statement_start_offset INT,
			@statement_end_offset INT,
			@start_time DATETIME,
			@database_name sysname;

		IF 
			@recursion = 1
			AND @output_column_list LIKE '%|[sql_text|]%' ESCAPE '|'
		BEGIN;
			DECLARE sql_cursor
			CURSOR LOCAL FAST_FORWARD
			FOR 
				SELECT 
					session_id,
					request_id,
					sql_handle,
					statement_start_offset,
					statement_end_offset
				FROM #sessions
				WHERE
					recursion = 1
					AND sql_handle IS NOT NULL
			OPTION (KEEPFIXED PLAN);

			OPEN sql_cursor;

			FETCH NEXT FROM sql_cursor
			INTO 
				@session_id,
				@request_id,
				@sql_handle,
				@statement_start_offset,
				@statement_end_offset;

			--Wait up to 5 ms for the SQL text, then give up
			SET LOCK_TIMEOUT 5;

			WHILE @@FETCH_STATUS = 0
			BEGIN;
				BEGIN TRY;
					UPDATE s
					SET
						s.sql_text =
						(
							SELECT
								REPLACE
								(
									REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
									REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
									REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
										N'--' + NCHAR(13) + NCHAR(10) +
										CASE 
											WHEN @get_full_inner_text = 1 THEN est.text
											WHEN LEN(est.text) < (@statement_end_offset / 2) + 1 THEN est.text
											WHEN SUBSTRING(est.text, (@statement_start_offset/2), 2) LIKE N'[a-zA-Z0-9][a-zA-Z0-9]' THEN est.text
											ELSE
												CASE
													WHEN @statement_start_offset > 0 THEN
														SUBSTRING
														(
															est.text,
															((@statement_start_offset/2) + 1),
															(
																CASE
																	WHEN @statement_end_offset = -1 THEN 2147483647
																	ELSE ((@statement_end_offset - @statement_start_offset)/2) + 1
																END
															)
														)
													ELSE RTRIM(LTRIM(est.text))
												END
										END +
										NCHAR(13) + NCHAR(10) + N'--' COLLATE Latin1_General_Bin2,
										NCHAR(31),N'?'),NCHAR(30),N'?'),NCHAR(29),N'?'),NCHAR(28),N'?'),NCHAR(27),N'?'),NCHAR(26),N'?'),NCHAR(25),N'?'),NCHAR(24),N'?'),NCHAR(23),N'?'),NCHAR(22),N'?'),
										NCHAR(21),N'?'),NCHAR(20),N'?'),NCHAR(19),N'?'),NCHAR(18),N'?'),NCHAR(17),N'?'),NCHAR(16),N'?'),NCHAR(15),N'?'),NCHAR(14),N'?'),NCHAR(12),N'?'),
										NCHAR(11),N'?'),NCHAR(8),N'?'),NCHAR(7),N'?'),NCHAR(6),N'?'),NCHAR(5),N'?'),NCHAR(4),N'?'),NCHAR(3),N'?'),NCHAR(2),N'?'),NCHAR(1),N'?'),
									NCHAR(0),
									N''
								) AS [processing-instruction(query)]
							FOR XML
								PATH(''),
								TYPE
						),
						s.statement_start_offset = 
							CASE 
								WHEN LEN(est.text) < (@statement_end_offset / 2) + 1 THEN 0
								WHEN SUBSTRING(CONVERT(VARCHAR(MAX), est.text), (@statement_start_offset/2), 2) LIKE '[a-zA-Z0-9][a-zA-Z0-9]' THEN 0
								ELSE @statement_start_offset
							END,
						s.statement_end_offset = 
							CASE 
								WHEN LEN(est.text) < (@statement_end_offset / 2) + 1 THEN -1
								WHEN SUBSTRING(CONVERT(VARCHAR(MAX), est.text), (@statement_start_offset/2), 2) LIKE '[a-zA-Z0-9][a-zA-Z0-9]' THEN -1
								ELSE @statement_end_offset
							END
					FROM 
						#sessions AS s,
						(
							SELECT TOP(1)
								text
							FROM
							(
								SELECT 
									text, 
									0 AS row_num
								FROM sys.dm_exec_sql_text(@sql_handle)
								
								UNION ALL
								
								SELECT 
									NULL,
									1 AS row_num
							) AS est0
							ORDER BY
								row_num
						) AS est
					WHERE 
						s.session_id = @session_id
						AND s.request_id = @request_id
						AND s.recursion = 1
					OPTION (KEEPFIXED PLAN);
				END TRY
				BEGIN CATCH;
					UPDATE s
					SET
						s.sql_text = 
							CASE ERROR_NUMBER() 
								WHEN 1222 THEN '<timeout_exceeded />'
								ELSE '<error message="' + ERROR_MESSAGE() + '" />'
							END
					FROM #sessions AS s
					WHERE 
						s.session_id = @session_id
						AND s.request_id = @request_id
						AND s.recursion = 1
					OPTION (KEEPFIXED PLAN);
				END CATCH;

				FETCH NEXT FROM sql_cursor
				INTO
					@session_id,
					@request_id,
					@sql_handle,
					@statement_start_offset,
					@statement_end_offset;
			END;

			--Return this to the default
			SET LOCK_TIMEOUT -1;

			CLOSE sql_cursor;
			DEALLOCATE sql_cursor;
		END;

		IF 
			@get_outer_command = 1 
			AND @recursion = 1
			AND @output_column_list LIKE '%|[sql_command|]%' ESCAPE '|'
		BEGIN;
			DECLARE @buffer_results TABLE
			(
				EventType VARCHAR(30),
				Parameters INT,
				EventInfo NVARCHAR(4000),
				start_time DATETIME,
				session_number INT IDENTITY(1,1) NOT NULL PRIMARY KEY
			);

			DECLARE buffer_cursor
			CURSOR LOCAL FAST_FORWARD
			FOR 
				SELECT 
					session_id,
					MAX(start_time) AS start_time
				FROM #sessions
				WHERE
					recursion = 1
				GROUP BY
					session_id
				ORDER BY
					session_id
				OPTION (KEEPFIXED PLAN);

			OPEN buffer_cursor;

			FETCH NEXT FROM buffer_cursor
			INTO 
				@session_id,
				@start_time;

			WHILE @@FETCH_STATUS = 0
			BEGIN;
				BEGIN TRY;
					--In SQL Server 2008, DBCC INPUTBUFFER will throw 
					--an exception if the session no longer exists
					INSERT @buffer_results
					(
						EventType,
						Parameters,
						EventInfo
					)
					EXEC sp_executesql
						N'DBCC INPUTBUFFER(@session_id) WITH NO_INFOMSGS;',
						N'@session_id SMALLINT',
						@session_id;

					UPDATE br
					SET
						br.start_time = @start_time
					FROM @buffer_results AS br
					WHERE
						br.session_number = 
						(
							SELECT MAX(br2.session_number)
							FROM @buffer_results br2
						);
				END TRY
				BEGIN CATCH
				END CATCH;

				FETCH NEXT FROM buffer_cursor
				INTO 
					@session_id,
					@start_time;
			END;

			UPDATE s
			SET
				sql_command = 
				(
					SELECT 
						REPLACE
						(
							REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
							REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
							REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
								CONVERT
								(
									NVARCHAR(MAX),
									N'--' + NCHAR(13) + NCHAR(10) + br.EventInfo + NCHAR(13) + NCHAR(10) + N'--' COLLATE Latin1_General_Bin2
								),
								NCHAR(31),N'?'),NCHAR(30),N'?'),NCHAR(29),N'?'),NCHAR(28),N'?'),NCHAR(27),N'?'),NCHAR(26),N'?'),NCHAR(25),N'?'),NCHAR(24),N'?'),NCHAR(23),N'?'),NCHAR(22),N'?'),
								NCHAR(21),N'?'),NCHAR(20),N'?'),NCHAR(19),N'?'),NCHAR(18),N'?'),NCHAR(17),N'?'),NCHAR(16),N'?'),NCHAR(15),N'?'),NCHAR(14),N'?'),NCHAR(12),N'?'),
								NCHAR(11),N'?'),NCHAR(8),N'?'),NCHAR(7),N'?'),NCHAR(6),N'?'),NCHAR(5),N'?'),NCHAR(4),N'?'),NCHAR(3),N'?'),NCHAR(2),N'?'),NCHAR(1),N'?'),
							NCHAR(0),
							N''
						) AS [processing-instruction(query)]
					FROM @buffer_results AS br
					WHERE 
						br.session_number = s.session_number
						AND br.start_time = s.start_time
						AND 
						(
							(
								s.start_time = s.last_request_start_time
								AND EXISTS
								(
									SELECT *
									FROM sys.dm_exec_requests r2
									WHERE
										r2.session_id = s.session_id
										AND r2.request_id = s.request_id
										AND r2.start_time = s.start_time
								)
							)
							OR 
							(
								s.request_id = 0
								AND EXISTS
								(
									SELECT *
									FROM sys.dm_exec_sessions s2
									WHERE
										s2.session_id = s.session_id
										AND s2.last_request_start_time = s.last_request_start_time
								)
							)
						)
					FOR XML
						PATH(''),
						TYPE
				)
			FROM #sessions AS s
			WHERE
				recursion = 1
			OPTION (KEEPFIXED PLAN);

			CLOSE buffer_cursor;
			DEALLOCATE buffer_cursor;
		END;

		IF 
			@get_plans >= 1 
			AND @recursion = 1
			AND @output_column_list LIKE '%|[query_plan|]%' ESCAPE '|'
		BEGIN;
			DECLARE @live_plan BIT;
			SET @live_plan = ISNULL(CONVERT(BIT, SIGN(OBJECT_ID('sys.dm_exec_query_statistics_xml'))), 0)

			DECLARE plan_cursor
			CURSOR LOCAL FAST_FORWARD
			FOR 
				SELECT
					session_id,
					request_id,
					plan_handle,
					statement_start_offset,
					statement_end_offset
				FROM #sessions
				WHERE
					recursion = 1
					AND plan_handle IS NOT NULL
			OPTION (KEEPFIXED PLAN);

			OPEN plan_cursor;

			FETCH NEXT FROM plan_cursor
			INTO 
				@session_id,
				@request_id,
				@plan_handle,
				@statement_start_offset,
				@statement_end_offset;

			--Wait up to 5 ms for a query plan, then give up
			SET LOCK_TIMEOUT 5;

			WHILE @@FETCH_STATUS = 0
			BEGIN;
				DECLARE @query_plan XML;
				IF @live_plan = 1
				BEGIN;
					BEGIN TRY;
						SELECT
							@query_plan = x.query_plan
						FROM sys.dm_exec_query_statistics_xml(@session_id) AS x;

						IF 
							@query_plan IS NOT NULL
							AND EXISTS
							(
								SELECT
									*
								FROM sys.dm_exec_requests AS r
								WHERE
									r.session_id = @session_id
									AND r.request_id = @request_id
									AND r.plan_handle = @plan_handle
									AND r.statement_start_offset = @statement_start_offset
									AND r.statement_end_offset = @statement_end_offset
							)
						BEGIN;
							UPDATE s
							SET
								s.query_plan = @query_plan
							FROM #sessions AS s
							WHERE 
								s.session_id = @session_id
								AND s.request_id = @request_id
								AND s.recursion = 1
							OPTION (KEEPFIXED PLAN);
						END;
					END TRY
					BEGIN CATCH;
						SET @query_plan = NULL;
					END CATCH;
				END;

				IF @query_plan IS NULL
				BEGIN;
					BEGIN TRY;
						UPDATE s
						SET
							s.query_plan =
							(
								SELECT
									CONVERT(xml, query_plan)
								FROM sys.dm_exec_text_query_plan
								(
									@plan_handle, 
									CASE @get_plans
										WHEN 1 THEN
											@statement_start_offset
										ELSE
											0
									END, 
									CASE @get_plans
										WHEN 1 THEN
											@statement_end_offset
										ELSE
											-1
									END
								)
							)
						FROM #sessions AS s
						WHERE 
							s.session_id = @session_id
							AND s.request_id = @request_id
							AND s.recursion = 1
						OPTION (KEEPFIXED PLAN);
					END TRY
					BEGIN CATCH;
						IF ERROR_NUMBER() = 6335
						BEGIN;
							UPDATE s
							SET
								s.query_plan =
								(
									SELECT
										N'--' + NCHAR(13) + NCHAR(10) + 
										N'-- Could not render showplan due to XML data type limitations. ' + NCHAR(13) + NCHAR(10) + 
										N'-- To see the graphical plan save the XML below as a .SQLPLAN file and re-open in SSMS.' + NCHAR(13) + NCHAR(10) +
										N'--' + NCHAR(13) + NCHAR(10) +
											REPLACE(qp.query_plan, N'<RelOp', NCHAR(13)+NCHAR(10)+N'<RelOp') + 
											NCHAR(13) + NCHAR(10) + N'--' COLLATE Latin1_General_Bin2 AS [processing-instruction(query_plan)]
									FROM sys.dm_exec_text_query_plan
									(
										@plan_handle, 
										CASE @get_plans
											WHEN 1 THEN
												@statement_start_offset
											ELSE
												0
										END, 
										CASE @get_plans
											WHEN 1 THEN
												@statement_end_offset
											ELSE
												-1
										END
									) AS qp
									FOR XML
										PATH(''),
										TYPE
								)
							FROM #sessions AS s
							WHERE 
								s.session_id = @session_id
								AND s.request_id = @request_id
								AND s.recursion = 1
							OPTION (KEEPFIXED PLAN);
						END;
						ELSE
						BEGIN;
							UPDATE s
							SET
								s.query_plan = 
									CASE ERROR_NUMBER() 
										WHEN 1222 THEN '<timeout_exceeded />'
										ELSE '<error message="' + ERROR_MESSAGE() + '" />'
									END
							FROM #sessions AS s
							WHERE 
								s.session_id = @session_id
								AND s.request_id = @request_id
								AND s.recursion = 1
							OPTION (KEEPFIXED PLAN);
						END;
					END CATCH;
				END;

				FETCH NEXT FROM plan_cursor
				INTO
					@session_id,
					@request_id,
					@plan_handle,
					@statement_start_offset,
					@statement_end_offset;
			END;

			--Return this to the default
			SET LOCK_TIMEOUT -1;

			CLOSE plan_cursor;
			DEALLOCATE plan_cursor;
		END;

		IF 
			@get_locks = 1 
			AND @recursion = 1
			AND @output_column_list LIKE '%|[locks|]%' ESCAPE '|'
		BEGIN;
			DECLARE locks_cursor
			CURSOR LOCAL FAST_FORWARD
			FOR 
				SELECT DISTINCT
					database_name
				FROM #locks
				WHERE
					EXISTS
					(
						SELECT *
						FROM #sessions AS s
						WHERE
							s.session_id = #locks.session_id
							AND recursion = 1
					)
					AND database_name <> '(null)'
				OPTION (KEEPFIXED PLAN);

			OPEN locks_cursor;

			FETCH NEXT FROM locks_cursor
			INTO 
				@database_name;

			WHILE @@FETCH_STATUS = 0
			BEGIN;
				BEGIN TRY;
					SET @sql_n = CONVERT(NVARCHAR(MAX), '') +
						'UPDATE l ' +
						'SET ' +
							'object_name = ' +
								'REPLACE ' +
								'( ' +
									'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
									'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
									'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
										'o.name COLLATE Latin1_General_Bin2, ' +
										'NCHAR(31),N''?''),NCHAR(30),N''?''),NCHAR(29),N''?''),NCHAR(28),N''?''),NCHAR(27),N''?''),NCHAR(26),N''?''),NCHAR(25),N''?''),NCHAR(24),N''?''),NCHAR(23),N''?''),NCHAR(22),N''?''), ' +
										'NCHAR(21),N''?''),NCHAR(20),N''?''),NCHAR(19),N''?''),NCHAR(18),N''?''),NCHAR(17),N''?''),NCHAR(16),N''?''),NCHAR(15),N''?''),NCHAR(14),N''?''),NCHAR(12),N''?''), ' +
										'NCHAR(11),N''?''),NCHAR(8),N''?''),NCHAR(7),N''?''),NCHAR(6),N''?''),NCHAR(5),N''?''),NCHAR(4),N''?''),NCHAR(3),N''?''),NCHAR(2),N''?''),NCHAR(1),N''?''), ' +
									'NCHAR(0), ' +
									N''''' ' +
								'), ' +
							'index_name = ' +
								'REPLACE ' +
								'( ' +
									'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
									'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
									'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
										'i.name COLLATE Latin1_General_Bin2, ' +
										'NCHAR(31),N''?''),NCHAR(30),N''?''),NCHAR(29),N''?''),NCHAR(28),N''?''),NCHAR(27),N''?''),NCHAR(26),N''?''),NCHAR(25),N''?''),NCHAR(24),N''?''),NCHAR(23),N''?''),NCHAR(22),N''?''), ' +
										'NCHAR(21),N''?''),NCHAR(20),N''?''),NCHAR(19),N''?''),NCHAR(18),N''?''),NCHAR(17),N''?''),NCHAR(16),N''?''),NCHAR(15),N''?''),NCHAR(14),N''?''),NCHAR(12),N''?''), ' +
										'NCHAR(11),N''?''),NCHAR(8),N''?''),NCHAR(7),N''?''),NCHAR(6),N''?''),NCHAR(5),N''?''),NCHAR(4),N''?''),NCHAR(3),N''?''),NCHAR(2),N''?''),NCHAR(1),N''?''), ' +
									'NCHAR(0), ' +
									N''''' ' +
								'), ' +
							'schema_name = ' +
								'REPLACE ' +
								'( ' +
									'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
									'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
									'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
										's.name COLLATE Latin1_General_Bin2, ' +
										'NCHAR(31),N''?''),NCHAR(30),N''?''),NCHAR(29),N''?''),NCHAR(28),N''?''),NCHAR(27),N''?''),NCHAR(26),N''?''),NCHAR(25),N''?''),NCHAR(24),N''?''),NCHAR(23),N''?''),NCHAR(22),N''?''), ' +
										'NCHAR(21),N''?''),NCHAR(20),N''?''),NCHAR(19),N''?''),NCHAR(18),N''?''),NCHAR(17),N''?''),NCHAR(16),N''?''),NCHAR(15),N''?''),NCHAR(14),N''?''),NCHAR(12),N''?''), ' +
										'NCHAR(11),N''?''),NCHAR(8),N''?''),NCHAR(7),N''?''),NCHAR(6),N''?''),NCHAR(5),N''?''),NCHAR(4),N''?''),NCHAR(3),N''?''),NCHAR(2),N''?''),NCHAR(1),N''?''), ' +
									'NCHAR(0), ' +
									N''''' ' +
								'), ' +
							'principal_name = ' + 
								'REPLACE ' +
								'( ' +
									'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
									'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
									'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
										'dp.name COLLATE Latin1_General_Bin2, ' +
										'NCHAR(31),N''?''),NCHAR(30),N''?''),NCHAR(29),N''?''),NCHAR(28),N''?''),NCHAR(27),N''?''),NCHAR(26),N''?''),NCHAR(25),N''?''),NCHAR(24),N''?''),NCHAR(23),N''?''),NCHAR(22),N''?''), ' +
										'NCHAR(21),N''?''),NCHAR(20),N''?''),NCHAR(19),N''?''),NCHAR(18),N''?''),NCHAR(17),N''?''),NCHAR(16),N''?''),NCHAR(15),N''?''),NCHAR(14),N''?''),NCHAR(12),N''?''), ' +
										'NCHAR(11),N''?''),NCHAR(8),N''?''),NCHAR(7),N''?''),NCHAR(6),N''?''),NCHAR(5),N''?''),NCHAR(4),N''?''),NCHAR(3),N''?''),NCHAR(2),N''?''),NCHAR(1),N''?''), ' +
									'NCHAR(0), ' +
									N''''' ' +
								') ' +
						'FROM #locks AS l ' +
						'LEFT OUTER JOIN ' + QUOTENAME(@database_name) + '.sys.allocation_units AS au ON ' +
							'au.allocation_unit_id = l.allocation_unit_id ' +
						'LEFT OUTER JOIN ' + QUOTENAME(@database_name) + '.sys.partitions AS p ON ' +
							'p.hobt_id = ' +
								'COALESCE ' +
								'( ' +
									'l.hobt_id, ' +
									'CASE ' +
										'WHEN au.type IN (1, 3) THEN au.container_id ' +
										'ELSE NULL ' +
									'END ' +
								') ' +
						'LEFT OUTER JOIN ' + QUOTENAME(@database_name) + '.sys.partitions AS p1 ON ' +
							'l.hobt_id IS NULL ' +
							'AND au.type = 2 ' +
							'AND p1.partition_id = au.container_id ' +
						'LEFT OUTER JOIN ' + QUOTENAME(@database_name) + '.sys.objects AS o ON ' +
							'o.object_id = COALESCE(l.object_id, p.object_id, p1.object_id) ' +
						'LEFT OUTER JOIN ' + QUOTENAME(@database_name) + '.sys.indexes AS i ON ' +
							'i.object_id = COALESCE(l.object_id, p.object_id, p1.object_id) ' +
							'AND i.index_id = COALESCE(l.index_id, p.index_id, p1.index_id) ' +
						'LEFT OUTER JOIN ' + QUOTENAME(@database_name) + '.sys.schemas AS s ON ' +
							's.schema_id = COALESCE(l.schema_id, o.schema_id) ' +
						'LEFT OUTER JOIN ' + QUOTENAME(@database_name) + '.sys.database_principals AS dp ON ' +
							'dp.principal_id = l.principal_id ' +
						'WHERE ' +
							'l.database_name = @database_name ' +
						'OPTION (KEEPFIXED PLAN); ';
					
					EXEC sp_executesql
						@sql_n,
						N'@database_name sysname',
						@database_name;
				END TRY
				BEGIN CATCH;
					UPDATE #locks
					SET
						query_error = 
							REPLACE
							(
								REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
								REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
								REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
									CONVERT
									(
										NVARCHAR(MAX), 
										ERROR_MESSAGE() COLLATE Latin1_General_Bin2
									),
									NCHAR(31),N'?'),NCHAR(30),N'?'),NCHAR(29),N'?'),NCHAR(28),N'?'),NCHAR(27),N'?'),NCHAR(26),N'?'),NCHAR(25),N'?'),NCHAR(24),N'?'),NCHAR(23),N'?'),NCHAR(22),N'?'),
									NCHAR(21),N'?'),NCHAR(20),N'?'),NCHAR(19),N'?'),NCHAR(18),N'?'),NCHAR(17),N'?'),NCHAR(16),N'?'),NCHAR(15),N'?'),NCHAR(14),N'?'),NCHAR(12),N'?'),
									NCHAR(11),N'?'),NCHAR(8),N'?'),NCHAR(7),N'?'),NCHAR(6),N'?'),NCHAR(5),N'?'),NCHAR(4),N'?'),NCHAR(3),N'?'),NCHAR(2),N'?'),NCHAR(1),N'?'),
								NCHAR(0),
								N''
							)
					WHERE 
						database_name = @database_name
					OPTION (KEEPFIXED PLAN);
				END CATCH;

				FETCH NEXT FROM locks_cursor
				INTO
					@database_name;
			END;

			CLOSE locks_cursor;
			DEALLOCATE locks_cursor;

			CREATE CLUSTERED INDEX IX_SRD ON #locks (session_id, request_id, database_name);

			UPDATE s
			SET 
				s.locks =
				(
					SELECT 
						REPLACE
						(
							REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
							REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
							REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
								CONVERT
								(
									NVARCHAR(MAX), 
									l1.database_name COLLATE Latin1_General_Bin2
								),
								NCHAR(31),N'?'),NCHAR(30),N'?'),NCHAR(29),N'?'),NCHAR(28),N'?'),NCHAR(27),N'?'),NCHAR(26),N'?'),NCHAR(25),N'?'),NCHAR(24),N'?'),NCHAR(23),N'?'),NCHAR(22),N'?'),
								NCHAR(21),N'?'),NCHAR(20),N'?'),NCHAR(19),N'?'),NCHAR(18),N'?'),NCHAR(17),N'?'),NCHAR(16),N'?'),NCHAR(15),N'?'),NCHAR(14),N'?'),NCHAR(12),N'?'),
								NCHAR(11),N'?'),NCHAR(8),N'?'),NCHAR(7),N'?'),NCHAR(6),N'?'),NCHAR(5),N'?'),NCHAR(4),N'?'),NCHAR(3),N'?'),NCHAR(2),N'?'),NCHAR(1),N'?'),
							NCHAR(0),
							N''
						) AS [Database/@name],
						MIN(l1.query_error) AS [Database/@query_error],
						(
							SELECT 
								l2.request_mode AS [Lock/@request_mode],
								l2.request_status AS [Lock/@request_status],
								COUNT(*) AS [Lock/@request_count]
							FROM #locks AS l2
							WHERE 
								l1.session_id = l2.session_id
								AND l1.request_id = l2.request_id
								AND l2.database_name = l1.database_name
								AND l2.resource_type = 'DATABASE'
							GROUP BY
								l2.request_mode,
								l2.request_status
							FOR XML
								PATH(''),
								TYPE
						) AS [Database/Locks],
						(
							SELECT
								COALESCE(l3.object_name, '(null)') AS [Object/@name],
								l3.schema_name AS [Object/@schema_name],
								(
									SELECT
										l4.resource_type AS [Lock/@resource_type],
										l4.page_type AS [Lock/@page_type],
										l4.index_name AS [Lock/@index_name],
										CASE 
											WHEN l4.object_name IS NULL THEN l4.schema_name
											ELSE NULL
										END AS [Lock/@schema_name],
										l4.principal_name AS [Lock/@principal_name],
										l4.resource_description AS [Lock/@resource_description],
										l4.request_mode AS [Lock/@request_mode],
										l4.request_status AS [Lock/@request_status],
										SUM(l4.request_count) AS [Lock/@request_count]
									FROM #locks AS l4
									WHERE 
										l4.session_id = l3.session_id
										AND l4.request_id = l3.request_id
										AND l3.database_name = l4.database_name
										AND COALESCE(l3.object_name, '(null)') = COALESCE(l4.object_name, '(null)')
										AND COALESCE(l3.schema_name, '') = COALESCE(l4.schema_name, '')
										AND l4.resource_type <> 'DATABASE'
									GROUP BY
										l4.resource_type,
										l4.page_type,
										l4.index_name,
										CASE 
											WHEN l4.object_name IS NULL THEN l4.schema_name
											ELSE NULL
										END,
										l4.principal_name,
										l4.resource_description,
										l4.request_mode,
										l4.request_status
									FOR XML
										PATH(''),
										TYPE
								) AS [Object/Locks]
							FROM #locks AS l3
							WHERE 
								l3.session_id = l1.session_id
								AND l3.request_id = l1.request_id
								AND l3.database_name = l1.database_name
								AND l3.resource_type <> 'DATABASE'
							GROUP BY 
								l3.session_id,
								l3.request_id,
								l3.database_name,
								COALESCE(l3.object_name, '(null)'),
								l3.schema_name
							FOR XML
								PATH(''),
								TYPE
						) AS [Database/Objects]
					FROM #locks AS l1
					WHERE
						l1.session_id = s.session_id
						AND l1.request_id = s.request_id
						AND l1.start_time IN (s.start_time, s.last_request_start_time)
						AND s.recursion = 1
					GROUP BY 
						l1.session_id,
						l1.request_id,
						l1.database_name
					FOR XML
						PATH(''),
						TYPE
				)
			FROM #sessions s
			OPTION (KEEPFIXED PLAN);
		END;

		IF 
			@find_block_leaders = 1
			AND @recursion = 1
			AND @output_column_list LIKE '%|[blocked_session_count|]%' ESCAPE '|'
		BEGIN;
			WITH
			blockers AS
			(
				SELECT
					session_id,
					session_id AS top_level_session_id,
					CONVERT(VARCHAR(8000), '.' + CONVERT(VARCHAR(8000), session_id) + '.') AS the_path
				FROM #sessions
				WHERE
					recursion = 1

				UNION ALL

				SELECT
					s.session_id,
					b.top_level_session_id,
					CONVERT(VARCHAR(8000), b.the_path + CONVERT(VARCHAR(8000), s.session_id) + '.') AS the_path
				FROM blockers AS b
				JOIN #sessions AS s ON
					s.blocking_session_id = b.session_id
					AND s.recursion = 1
					AND b.the_path NOT LIKE '%.' + CONVERT(VARCHAR(8000), s.session_id) + '.%' COLLATE Latin1_General_Bin2
			)
			UPDATE s
			SET
				s.blocked_session_count = x.blocked_session_count
			FROM #sessions AS s
			JOIN
			(
				SELECT
					b.top_level_session_id AS session_id,
					COUNT(*) - 1 AS blocked_session_count
				FROM blockers AS b
				GROUP BY
					b.top_level_session_id
			) x ON
				s.session_id = x.session_id
			WHERE
				s.recursion = 1;
		END;

		IF
			@get_task_info = 2
			AND @output_column_list LIKE '%|[additional_info|]%' ESCAPE '|'
			AND @recursion = 1
		BEGIN;
			CREATE TABLE #blocked_requests
			(
				session_id SMALLINT NOT NULL,
				request_id INT NOT NULL,
				database_name sysname NOT NULL,
				object_id INT,
				hobt_id BIGINT,
				schema_id INT,
				schema_name sysname NULL,
				object_name sysname NULL,
				query_error NVARCHAR(2048),
				PRIMARY KEY (database_name, session_id, request_id)
			);

			CREATE STATISTICS s_database_name ON #blocked_requests (database_name)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_schema_name ON #blocked_requests (schema_name)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_object_name ON #blocked_requests (object_name)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_query_error ON #blocked_requests (query_error)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
		
			INSERT #blocked_requests
			(
				session_id,
				request_id,
				database_name,
				object_id,
				hobt_id,
				schema_id
			)
			SELECT
				session_id,
				request_id,
				database_name,
				object_id,
				hobt_id,
				CONVERT(INT, SUBSTRING(schema_node, CHARINDEX(' = ', schema_node) + 3, LEN(schema_node))) AS schema_id
			FROM
			(
				SELECT
					session_id,
					request_id,
					agent_nodes.agent_node.value('(database_name/text())[1]', 'sysname') AS database_name,
					agent_nodes.agent_node.value('(object_id/text())[1]', 'int') AS object_id,
					agent_nodes.agent_node.value('(hobt_id/text())[1]', 'bigint') AS hobt_id,
					agent_nodes.agent_node.value('(metadata_resource/text()[.="SCHEMA"]/../../metadata_class_id/text())[1]', 'varchar(100)') AS schema_node
				FROM #sessions AS s
				CROSS APPLY s.additional_info.nodes('//block_info') AS agent_nodes (agent_node)
				WHERE
					s.recursion = 1
			) AS t
			WHERE
				t.database_name IS NOT NULL
				AND
				(
					t.object_id IS NOT NULL
					OR t.hobt_id IS NOT NULL
					OR t.schema_node IS NOT NULL
				);
			
			DECLARE blocks_cursor
			CURSOR LOCAL FAST_FORWARD
			FOR
				SELECT DISTINCT
					database_name
				FROM #blocked_requests;
				
			OPEN blocks_cursor;
			
			FETCH NEXT FROM blocks_cursor
			INTO 
				@database_name;
			
			WHILE @@FETCH_STATUS = 0
			BEGIN;
				BEGIN TRY;
					SET @sql_n = 
						CONVERT(NVARCHAR(MAX), '') +
						'UPDATE b ' +
						'SET ' +
							'b.schema_name = ' +
								'REPLACE ' +
								'( ' +
									'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
									'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
									'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
										's.name COLLATE Latin1_General_Bin2, ' +
										'NCHAR(31),N''?''),NCHAR(30),N''?''),NCHAR(29),N''?''),NCHAR(28),N''?''),NCHAR(27),N''?''),NCHAR(26),N''?''),NCHAR(25),N''?''),NCHAR(24),N''?''),NCHAR(23),N''?''),NCHAR(22),N''?''), ' +
										'NCHAR(21),N''?''),NCHAR(20),N''?''),NCHAR(19),N''?''),NCHAR(18),N''?''),NCHAR(17),N''?''),NCHAR(16),N''?''),NCHAR(15),N''?''),NCHAR(14),N''?''),NCHAR(12),N''?''), ' +
										'NCHAR(11),N''?''),NCHAR(8),N''?''),NCHAR(7),N''?''),NCHAR(6),N''?''),NCHAR(5),N''?''),NCHAR(4),N''?''),NCHAR(3),N''?''),NCHAR(2),N''?''),NCHAR(1),N''?''), ' +
									'NCHAR(0), ' +
									N''''' ' +
								'), ' +
							'b.object_name = ' +
								'REPLACE ' +
								'( ' +
									'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
									'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
									'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
										'o.name COLLATE Latin1_General_Bin2, ' +
										'NCHAR(31),N''?''),NCHAR(30),N''?''),NCHAR(29),N''?''),NCHAR(28),N''?''),NCHAR(27),N''?''),NCHAR(26),N''?''),NCHAR(25),N''?''),NCHAR(24),N''?''),NCHAR(23),N''?''),NCHAR(22),N''?''), ' +
										'NCHAR(21),N''?''),NCHAR(20),N''?''),NCHAR(19),N''?''),NCHAR(18),N''?''),NCHAR(17),N''?''),NCHAR(16),N''?''),NCHAR(15),N''?''),NCHAR(14),N''?''),NCHAR(12),N''?''), ' +
										'NCHAR(11),N''?''),NCHAR(8),N''?''),NCHAR(7),N''?''),NCHAR(6),N''?''),NCHAR(5),N''?''),NCHAR(4),N''?''),NCHAR(3),N''?''),NCHAR(2),N''?''),NCHAR(1),N''?''), ' +
									'NCHAR(0), ' +
									N''''' ' +
								') ' +
						'FROM #blocked_requests AS b ' +
						'LEFT OUTER JOIN ' + QUOTENAME(@database_name) + '.sys.partitions AS p ON ' +
							'p.hobt_id = b.hobt_id ' +
						'LEFT OUTER JOIN ' + QUOTENAME(@database_name) + '.sys.objects AS o ON ' +
							'o.object_id = COALESCE(p.object_id, b.object_id) ' +
						'LEFT OUTER JOIN ' + QUOTENAME(@database_name) + '.sys.schemas AS s ON ' +
							's.schema_id = COALESCE(o.schema_id, b.schema_id) ' +
						'WHERE ' +
							'b.database_name = @database_name; ';
					
					EXEC sp_executesql
						@sql_n,
						N'@database_name sysname',
						@database_name;
				END TRY
				BEGIN CATCH;
					UPDATE #blocked_requests
					SET
						query_error = 
							REPLACE
							(
								REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
								REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
								REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
									CONVERT
									(
										NVARCHAR(MAX), 
										ERROR_MESSAGE() COLLATE Latin1_General_Bin2
									),
									NCHAR(31),N'?'),NCHAR(30),N'?'),NCHAR(29),N'?'),NCHAR(28),N'?'),NCHAR(27),N'?'),NCHAR(26),N'?'),NCHAR(25),N'?'),NCHAR(24),N'?'),NCHAR(23),N'?'),NCHAR(22),N'?'),
									NCHAR(21),N'?'),NCHAR(20),N'?'),NCHAR(19),N'?'),NCHAR(18),N'?'),NCHAR(17),N'?'),NCHAR(16),N'?'),NCHAR(15),N'?'),NCHAR(14),N'?'),NCHAR(12),N'?'),
									NCHAR(11),N'?'),NCHAR(8),N'?'),NCHAR(7),N'?'),NCHAR(6),N'?'),NCHAR(5),N'?'),NCHAR(4),N'?'),NCHAR(3),N'?'),NCHAR(2),N'?'),NCHAR(1),N'?'),
								NCHAR(0),
								N''
							)
					WHERE
						database_name = @database_name;
				END CATCH;

				FETCH NEXT FROM blocks_cursor
				INTO
					@database_name;
			END;
			
			CLOSE blocks_cursor;
			DEALLOCATE blocks_cursor;
			
			UPDATE s
			SET
				additional_info.modify
				('
					insert <schema_name>{sql:column("b.schema_name")}</schema_name>
					as last
					into (/additional_info/block_info)[1]
				')
			FROM #sessions AS s
			INNER JOIN #blocked_requests AS b ON
				b.session_id = s.session_id
				AND b.request_id = s.request_id
				AND s.recursion = 1
			WHERE
				b.schema_name IS NOT NULL;

			UPDATE s
			SET
				additional_info.modify
				('
					insert <object_name>{sql:column("b.object_name")}</object_name>
					as last
					into (/additional_info/block_info)[1]
				')
			FROM #sessions AS s
			INNER JOIN #blocked_requests AS b ON
				b.session_id = s.session_id
				AND b.request_id = s.request_id
				AND s.recursion = 1
			WHERE
				b.object_name IS NOT NULL;

			UPDATE s
			SET
				additional_info.modify
				('
					insert <query_error>{sql:column("b.query_error")}</query_error>
					as last
					into (/additional_info/block_info)[1]
				')
			FROM #sessions AS s
			INNER JOIN #blocked_requests AS b ON
				b.session_id = s.session_id
				AND b.request_id = s.request_id
				AND s.recursion = 1
			WHERE
				b.query_error IS NOT NULL;
		END;

		IF
			@output_column_list LIKE '%|[program_name|]%' ESCAPE '|'
			AND @output_column_list LIKE '%|[additional_info|]%' ESCAPE '|'
			AND @recursion = 1
			AND DB_ID('msdb') IS NOT NULL
		BEGIN;
			SET @sql_n =
				N'BEGIN TRY;
					DECLARE @job_name sysname;
					SET @job_name = NULL;
					DECLARE @step_name sysname;
					SET @step_name = NULL;

					SELECT
						@job_name = 
							REPLACE
							(
								REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
								REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
								REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
									j.name,
									NCHAR(31),N''?''),NCHAR(30),N''?''),NCHAR(29),N''?''),NCHAR(28),N''?''),NCHAR(27),N''?''),NCHAR(26),N''?''),NCHAR(25),N''?''),NCHAR(24),N''?''),NCHAR(23),N''?''),NCHAR(22),N''?''),
									NCHAR(21),N''?''),NCHAR(20),N''?''),NCHAR(19),N''?''),NCHAR(18),N''?''),NCHAR(17),N''?''),NCHAR(16),N''?''),NCHAR(15),N''?''),NCHAR(14),N''?''),NCHAR(12),N''?''),
									NCHAR(11),N''?''),NCHAR(8),N''?''),NCHAR(7),N''?''),NCHAR(6),N''?''),NCHAR(5),N''?''),NCHAR(4),N''?''),NCHAR(3),N''?''),NCHAR(2),N''?''),NCHAR(1),N''?''),
								NCHAR(0),
								N''?''
							),
						@step_name = 
							REPLACE
							(
								REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
								REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
								REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
									s.step_name,
									NCHAR(31),N''?''),NCHAR(30),N''?''),NCHAR(29),N''?''),NCHAR(28),N''?''),NCHAR(27),N''?''),NCHAR(26),N''?''),NCHAR(25),N''?''),NCHAR(24),N''?''),NCHAR(23),N''?''),NCHAR(22),N''?''),
									NCHAR(21),N''?''),NCHAR(20),N''?''),NCHAR(19),N''?''),NCHAR(18),N''?''),NCHAR(17),N''?''),NCHAR(16),N''?''),NCHAR(15),N''?''),NCHAR(14),N''?''),NCHAR(12),N''?''),
									NCHAR(11),N''?''),NCHAR(8),N''?''),NCHAR(7),N''?''),NCHAR(6),N''?''),NCHAR(5),N''?''),NCHAR(4),N''?''),NCHAR(3),N''?''),NCHAR(2),N''?''),NCHAR(1),N''?''),
								NCHAR(0),
								N''?''
							)
					FROM msdb.dbo.sysjobs AS j
					INNER JOIN msdb.dbo.sysjobsteps AS s ON
						j.job_id = s.job_id
					WHERE
						j.job_id = @job_id
						AND s.step_id = @step_id;

					IF @job_name IS NOT NULL
					BEGIN;
						UPDATE s
						SET
							additional_info.modify
							(''
								insert text{sql:variable("@job_name")}
								into (/additional_info/agent_job_info/job_name)[1]
							'')
						FROM #sessions AS s
						WHERE 
							s.session_id = @session_id
							AND s.recursion = 1
						OPTION (KEEPFIXED PLAN);
						
						UPDATE s
						SET
							additional_info.modify
							(''
								insert text{sql:variable("@step_name")}
								into (/additional_info/agent_job_info/step_name)[1]
							'')
						FROM #sessions AS s
						WHERE 
							s.session_id = @session_id
							AND s.recursion = 1
						OPTION (KEEPFIXED PLAN);
					END;
				END TRY
				BEGIN CATCH;
					DECLARE @msdb_error_message NVARCHAR(256);
					SET @msdb_error_message = ERROR_MESSAGE();
				
					UPDATE s
					SET
						additional_info.modify
						(''
							insert <msdb_query_error>{sql:variable("@msdb_error_message")}</msdb_query_error>
							as last
							into (/additional_info/agent_job_info)[1]
						'')
					FROM #sessions AS s
					WHERE 
						s.session_id = @session_id
						AND s.recursion = 1
					OPTION (KEEPFIXED PLAN);
				END CATCH;'

			DECLARE @job_id UNIQUEIDENTIFIER;
			DECLARE @step_id INT;

			DECLARE agent_cursor
			CURSOR LOCAL FAST_FORWARD
			FOR 
				SELECT
					s.session_id,
					agent_nodes.agent_node.value('(job_id/text())[1]', 'uniqueidentifier') AS job_id,
					agent_nodes.agent_node.value('(step_id/text())[1]', 'int') AS step_id
				FROM #sessions AS s
				CROSS APPLY s.additional_info.nodes('//agent_job_info') AS agent_nodes (agent_node)
				WHERE
					s.recursion = 1
			OPTION (KEEPFIXED PLAN);
			
			OPEN agent_cursor;

			FETCH NEXT FROM agent_cursor
			INTO 
				@session_id,
				@job_id,
				@step_id;

			WHILE @@FETCH_STATUS = 0
			BEGIN;
				EXEC sp_executesql
					@sql_n,
					N'@job_id UNIQUEIDENTIFIER, @step_id INT, @session_id SMALLINT',
					@job_id, @step_id, @session_id

				FETCH NEXT FROM agent_cursor
				INTO 
					@session_id,
					@job_id,
					@step_id;
			END;

			CLOSE agent_cursor;
			DEALLOCATE agent_cursor;
		END; 
		
		IF 
			@delta_interval > 0 
			AND @recursion <> 1
		BEGIN;
			SET @recursion = 1;

			DECLARE @delay_time CHAR(12);
			SET @delay_time = CONVERT(VARCHAR, DATEADD(second, @delta_interval, 0), 114);
			WAITFOR DELAY @delay_time;

			GOTO REDO;
		END;
	END;

	SET @sql = 
		--Outer column list
		CONVERT
		(
			VARCHAR(MAX),
			CASE
				WHEN 
					@destination_table <> '' 
					AND @return_schema = 0 
						THEN 'INSERT ' + @destination_table + ' '
				ELSE ''
			END +
			'SELECT ' +
				@output_column_list + ' ' +
			CASE @return_schema
				WHEN 1 THEN 'INTO #session_schema '
				ELSE ''
			END
		--End outer column list
		) + 
		--Inner column list
		CONVERT
		(
			VARCHAR(MAX),
			'FROM ' +
			'( ' +
				'SELECT ' +
					'session_id, ' +
					--[dd hh:mm:ss.mss]
					CASE
						WHEN @format_output IN (1, 2) THEN
							'CASE ' +
								'WHEN elapsed_time < 0 THEN ' +
									'RIGHT ' +
									'( ' +
										'REPLICATE(''0'', max_elapsed_length) + CONVERT(VARCHAR, (-1 * elapsed_time) / 86400), ' +
										'max_elapsed_length ' +
									') + ' +
										'RIGHT ' +
										'( ' +
											'CONVERT(VARCHAR, DATEADD(second, (-1 * elapsed_time), 0), 120), ' +
											'9 ' +
										') + ' +
										'''.000'' ' +
								'ELSE ' +
									'RIGHT ' +
									'( ' +
										'REPLICATE(''0'', max_elapsed_length) + CONVERT(VARCHAR, elapsed_time / 86400000), ' +
										'max_elapsed_length ' +
									') + ' +
										'RIGHT ' +
										'( ' +
											'CONVERT(VARCHAR, DATEADD(second, elapsed_time / 1000, 0), 120), ' +
											'9 ' +
										') + ' +
										'''.'' + ' + 
										'RIGHT(''000'' + CONVERT(VARCHAR, elapsed_time % 1000), 3) ' +
							'END AS [dd hh:mm:ss.mss], '
						ELSE
							''
					END +
					--[dd hh:mm:ss.mss (avg)] / avg_elapsed_time
					CASE 
						WHEN  @format_output IN (1, 2) THEN 
							'RIGHT ' +
							'( ' +
								'''00'' + CONVERT(VARCHAR, avg_elapsed_time / 86400000), ' +
								'2 ' +
							') + ' +
								'RIGHT ' +
								'( ' +
									'CONVERT(VARCHAR, DATEADD(second, avg_elapsed_time / 1000, 0), 120), ' +
									'9 ' +
								') + ' +
								'''.'' + ' +
								'RIGHT(''000'' + CONVERT(VARCHAR, avg_elapsed_time % 1000), 3) AS [dd hh:mm:ss.mss (avg)], '
						ELSE
							'avg_elapsed_time, '
					END +
					--physical_io
					CASE @format_output
						WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, physical_io))) OVER() - LEN(CONVERT(VARCHAR, physical_io))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, physical_io), 1), 19)) AS '
						WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, physical_io), 1), 19)) AS '
						ELSE ''
					END + 'physical_io, ' +
					--reads
					CASE @format_output
						WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, reads))) OVER() - LEN(CONVERT(VARCHAR, reads))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, reads), 1), 19)) AS '
						WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, reads), 1), 19)) AS '
						ELSE ''
					END + 'reads, ' +
					--physical_reads
					CASE @format_output
						WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, physical_reads))) OVER() - LEN(CONVERT(VARCHAR, physical_reads))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, physical_reads), 1), 19)) AS '
						WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, physical_reads), 1), 19)) AS '
						ELSE ''
					END + 'physical_reads, ' +
					--writes
					CASE @format_output
						WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, writes))) OVER() - LEN(CONVERT(VARCHAR, writes))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, writes), 1), 19)) AS '
						WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, writes), 1), 19)) AS '
						ELSE ''
					END + 'writes, ' +
					--tempdb_allocations
					CASE @format_output
						WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, tempdb_allocations))) OVER() - LEN(CONVERT(VARCHAR, tempdb_allocations))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, tempdb_allocations), 1), 19)) AS '
						WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, tempdb_allocations), 1), 19)) AS '
						ELSE ''
					END + 'tempdb_allocations, ' +
					--tempdb_current
					CASE @format_output
						WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, tempdb_current))) OVER() - LEN(CONVERT(VARCHAR, tempdb_current))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, tempdb_current), 1), 19)) AS '
						WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, tempdb_current), 1), 19)) AS '
						ELSE ''
					END + 'tempdb_current, ' +
					--CPU
					CASE @format_output
						WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, CPU))) OVER() - LEN(CONVERT(VARCHAR, CPU))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, CPU), 1), 19)) AS '
						WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, CPU), 1), 19)) AS '
						ELSE ''
					END + 'CPU, ' +
					--context_switches
					CASE @format_output
						WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, context_switches))) OVER() - LEN(CONVERT(VARCHAR, context_switches))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, context_switches), 1), 19)) AS '
						WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, context_switches), 1), 19)) AS '
						ELSE ''
					END + 'context_switches, ' +
					--used_memory
					CASE @format_output
						WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, used_memory))) OVER() - LEN(CONVERT(VARCHAR, used_memory))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, used_memory), 1), 19)) AS '
						WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, used_memory), 1), 19)) AS '
						ELSE ''
					END + 'used_memory, ' +
					CASE
						WHEN @output_column_list LIKE '%|_delta|]%' ESCAPE '|' THEN
							--physical_io_delta			
							'CASE ' +
								'WHEN ' +
									'first_request_start_time = last_request_start_time ' + 
									'AND num_events = 2 ' +
									'AND physical_io_delta >= 0 ' +
										'THEN ' +
										CASE @format_output
											WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, physical_io_delta))) OVER() - LEN(CONVERT(VARCHAR, physical_io_delta))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, physical_io_delta), 1), 19)) ' 
											WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, physical_io_delta), 1), 19)) '
											ELSE 'physical_io_delta '
										END +
								'ELSE NULL ' +
							'END AS physical_io_delta, ' +
							--reads_delta
							'CASE ' +
								'WHEN ' +
									'first_request_start_time = last_request_start_time ' + 
									'AND num_events = 2 ' +
									'AND reads_delta >= 0 ' +
										'THEN ' +
										CASE @format_output
											WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, reads_delta))) OVER() - LEN(CONVERT(VARCHAR, reads_delta))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, reads_delta), 1), 19)) '
											WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, reads_delta), 1), 19)) '
											ELSE 'reads_delta '
										END +
								'ELSE NULL ' +
							'END AS reads_delta, ' +
							--physical_reads_delta
							'CASE ' +
								'WHEN ' +
									'first_request_start_time = last_request_start_time ' + 
									'AND num_events = 2 ' +
									'AND physical_reads_delta >= 0 ' +
										'THEN ' +
										CASE @format_output
											WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, physical_reads_delta))) OVER() - LEN(CONVERT(VARCHAR, physical_reads_delta))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, physical_reads_delta), 1), 19)) '
											WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, physical_reads_delta), 1), 19)) '
											ELSE 'physical_reads_delta '
										END + 
								'ELSE NULL ' +
							'END AS physical_reads_delta, ' +
							--writes_delta
							'CASE ' +
								'WHEN ' +
									'first_request_start_time = last_request_start_time ' + 
									'AND num_events = 2 ' +
									'AND writes_delta >= 0 ' +
										'THEN ' +
										CASE @format_output
											WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, writes_delta))) OVER() - LEN(CONVERT(VARCHAR, writes_delta))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, writes_delta), 1), 19)) '
											WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, writes_delta), 1), 19)) '
											ELSE 'writes_delta '
										END + 
								'ELSE NULL ' +
							'END AS writes_delta, ' +
							--tempdb_allocations_delta
							'CASE ' +
								'WHEN ' +
									'first_request_start_time = last_request_start_time ' + 
									'AND num_events = 2 ' +
									'AND tempdb_allocations_delta >= 0 ' +
										'THEN ' +
										CASE @format_output
											WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, tempdb_allocations_delta))) OVER() - LEN(CONVERT(VARCHAR, tempdb_allocations_delta))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, tempdb_allocations_delta), 1), 19)) '
											WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, tempdb_allocations_delta), 1), 19)) '
											ELSE 'tempdb_allocations_delta '
										END + 
								'ELSE NULL ' +
							'END AS tempdb_allocations_delta, ' +
							--tempdb_current_delta
							--this is the only one that can (legitimately) go negative 
							'CASE ' +
								'WHEN ' +
									'first_request_start_time = last_request_start_time ' + 
									'AND num_events = 2 ' +
										'THEN ' +
										CASE @format_output
											WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, tempdb_current_delta))) OVER() - LEN(CONVERT(VARCHAR, tempdb_current_delta))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, tempdb_current_delta), 1), 19)) '
											WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, tempdb_current_delta), 1), 19)) '
											ELSE 'tempdb_current_delta '
										END + 
								'ELSE NULL ' +
							'END AS tempdb_current_delta, ' +
							--CPU_delta
							'CASE ' +
								'WHEN ' +
									'first_request_start_time = last_request_start_time ' + 
									'AND num_events = 2 ' +
										'THEN ' +
											'CASE ' +
												'WHEN ' +
													'thread_CPU_delta > CPU_delta ' +
													'AND thread_CPU_delta > 0 ' +
														'THEN ' +
															CASE @format_output
																WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, thread_CPU_delta + CPU_delta))) OVER() - LEN(CONVERT(VARCHAR, thread_CPU_delta))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, thread_CPU_delta), 1), 19)) '
																WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, thread_CPU_delta), 1), 19)) '
																ELSE 'thread_CPU_delta '
															END + 
												'WHEN CPU_delta >= 0 THEN ' +
													CASE @format_output
														WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, thread_CPU_delta + CPU_delta))) OVER() - LEN(CONVERT(VARCHAR, CPU_delta))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, CPU_delta), 1), 19)) '
														WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, CPU_delta), 1), 19)) '
														ELSE 'CPU_delta '
													END + 
												'ELSE NULL ' +
											'END ' +
								'ELSE ' +
									'NULL ' +
							'END AS CPU_delta, ' +
							--context_switches_delta
							'CASE ' +
								'WHEN ' +
									'first_request_start_time = last_request_start_time ' + 
									'AND num_events = 2 ' +
									'AND context_switches_delta >= 0 ' +
										'THEN ' +
										CASE @format_output
											WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, context_switches_delta))) OVER() - LEN(CONVERT(VARCHAR, context_switches_delta))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, context_switches_delta), 1), 19)) '
											WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, context_switches_delta), 1), 19)) '
											ELSE 'context_switches_delta '
										END + 
								'ELSE NULL ' +
							'END AS context_switches_delta, ' +
							--used_memory_delta
							'CASE ' +
								'WHEN ' +
									'first_request_start_time = last_request_start_time ' + 
									'AND num_events = 2 ' +
									'AND used_memory_delta >= 0 ' +
										'THEN ' +
										CASE @format_output
											WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, used_memory_delta))) OVER() - LEN(CONVERT(VARCHAR, used_memory_delta))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, used_memory_delta), 1), 19)) '
											WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, used_memory_delta), 1), 19)) '
											ELSE 'used_memory_delta '
										END + 
								'ELSE NULL ' +
							'END AS used_memory_delta, '
						ELSE ''
					END +
					--tasks
					CASE @format_output
						WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, tasks))) OVER() - LEN(CONVERT(VARCHAR, tasks))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, tasks), 1), 19)) AS '
						WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, tasks), 1), 19)) '
						ELSE ''
					END + 'tasks, ' +
					'status, ' +
					'wait_info, ' +
					'locks, ' +
					'tran_start_time, ' +
					'LEFT(tran_log_writes, LEN(tran_log_writes) - 1) AS tran_log_writes, ' +
					--open_tran_count
					CASE @format_output
						WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, open_tran_count))) OVER() - LEN(CONVERT(VARCHAR, open_tran_count))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, open_tran_count), 1), 19)) AS '
						WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, open_tran_count), 1), 19)) AS '
						ELSE ''
					END + 'open_tran_count, ' +
					--sql_command
					CASE @format_output 
						WHEN 0 THEN 'REPLACE(REPLACE(CONVERT(NVARCHAR(MAX), sql_command), ''<?query --''+CHAR(13)+CHAR(10), ''''), CHAR(13)+CHAR(10)+''--?>'', '''') AS '
						ELSE ''
					END + 'sql_command, ' +
					--sql_text
					CASE @format_output 
						WHEN 0 THEN 'REPLACE(REPLACE(CONVERT(NVARCHAR(MAX), sql_text), ''<?query --''+CHAR(13)+CHAR(10), ''''), CHAR(13)+CHAR(10)+''--?>'', '''') AS '
						ELSE ''
					END + 'sql_text, ' +
					'query_plan, ' +
					'blocking_session_id, ' +
					--blocked_session_count
					CASE @format_output
						WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, blocked_session_count))) OVER() - LEN(CONVERT(VARCHAR, blocked_session_count))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, blocked_session_count), 1), 19)) AS '
						WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, blocked_session_count), 1), 19)) AS '
						ELSE ''
					END + 'blocked_session_count, ' +
					--percent_complete
					CASE @format_output
						WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, CONVERT(MONEY, percent_complete), 2))) OVER() - LEN(CONVERT(VARCHAR, CONVERT(MONEY, percent_complete), 2))) + CONVERT(CHAR(22), CONVERT(MONEY, percent_complete), 2)) AS '
						WHEN 2 THEN 'CONVERT(VARCHAR, CONVERT(CHAR(22), CONVERT(MONEY, blocked_session_count), 1)) AS '
						ELSE ''
					END + 'percent_complete, ' +
					'host_name, ' +
					'login_name, ' +
					'database_name, ' +
					'program_name, ' +
					'additional_info, ' +
					'start_time, ' +
					'login_time, ' +
					'CASE ' +
						'WHEN status = N''sleeping'' THEN NULL ' +
						'ELSE request_id ' +
					'END AS request_id, ' +
					'GETDATE() AS collection_time '
		--End inner column list
		) +
		--Derived table and INSERT specification
		CONVERT
		(
			VARCHAR(MAX),
				'FROM ' +
				'( ' +
					'SELECT TOP(2147483647) ' +
						'*, ' +
						'CASE ' +
							'MAX ' +
							'( ' +
								'LEN ' +
								'( ' +
									'CONVERT ' +
									'( ' +
										'VARCHAR, ' +
										'CASE ' +
											'WHEN elapsed_time < 0 THEN ' +
												'(-1 * elapsed_time) / 86400 ' +
											'ELSE ' +
												'elapsed_time / 86400000 ' +
										'END ' +
									') ' +
								') ' +
							') OVER () ' +
								'WHEN 1 THEN 2 ' +
								'ELSE ' +
									'MAX ' +
									'( ' +
										'LEN ' +
										'( ' +
											'CONVERT ' +
											'( ' +
												'VARCHAR, ' +
												'CASE ' +
													'WHEN elapsed_time < 0 THEN ' +
														'(-1 * elapsed_time) / 86400 ' +
													'ELSE ' +
														'elapsed_time / 86400000 ' +
												'END ' +
											') ' +
										') ' +
									') OVER () ' +
						'END AS max_elapsed_length, ' +
						CASE
							WHEN @output_column_list LIKE '%|_delta|]%' ESCAPE '|' THEN
								'MAX(physical_io * recursion) OVER (PARTITION BY session_id, request_id) + ' +
									'MIN(physical_io * recursion) OVER (PARTITION BY session_id, request_id) AS physical_io_delta, ' +
								'MAX(reads * recursion) OVER (PARTITION BY session_id, request_id) + ' +
									'MIN(reads * recursion) OVER (PARTITION BY session_id, request_id) AS reads_delta, ' +
								'MAX(physical_reads * recursion) OVER (PARTITION BY session_id, request_id) + ' +
									'MIN(physical_reads * recursion) OVER (PARTITION BY session_id, request_id) AS physical_reads_delta, ' +
								'MAX(writes * recursion) OVER (PARTITION BY session_id, request_id) + ' +
									'MIN(writes * recursion) OVER (PARTITION BY session_id, request_id) AS writes_delta, ' +
								'MAX(tempdb_allocations * recursion) OVER (PARTITION BY session_id, request_id) + ' +
									'MIN(tempdb_allocations * recursion) OVER (PARTITION BY session_id, request_id) AS tempdb_allocations_delta, ' +
								'MAX(tempdb_current * recursion) OVER (PARTITION BY session_id, request_id) + ' +
									'MIN(tempdb_current * recursion) OVER (PARTITION BY session_id, request_id) AS tempdb_current_delta, ' +
								'MAX(CPU * recursion) OVER (PARTITION BY session_id, request_id) + ' +
									'MIN(CPU * recursion) OVER (PARTITION BY session_id, request_id) AS CPU_delta, ' +
								'MAX(thread_CPU_snapshot * recursion) OVER (PARTITION BY session_id, request_id) + ' +
									'MIN(thread_CPU_snapshot * recursion) OVER (PARTITION BY session_id, request_id) AS thread_CPU_delta, ' +
								'MAX(context_switches * recursion) OVER (PARTITION BY session_id, request_id) + ' +
									'MIN(context_switches * recursion) OVER (PARTITION BY session_id, request_id) AS context_switches_delta, ' +
								'MAX(used_memory * recursion) OVER (PARTITION BY session_id, request_id) + ' +
									'MIN(used_memory * recursion) OVER (PARTITION BY session_id, request_id) AS used_memory_delta, ' +
								'MIN(last_request_start_time) OVER (PARTITION BY session_id, request_id) AS first_request_start_time, '
							ELSE ''
						END +
						'COUNT(*) OVER (PARTITION BY session_id, request_id) AS num_events ' +
					'FROM #sessions AS s1 ' +
					CASE 
						WHEN @sort_order = '' THEN ''
						ELSE
							'ORDER BY ' +
								@sort_order
					END +
				') AS s ' +
				'WHERE ' +
					's.recursion = 1 ' +
			') x ' +
			'OPTION (KEEPFIXED PLAN); ' +
			'' +
			CASE @return_schema
				WHEN 1 THEN
					'SET @schema = ' +
						'''CREATE TABLE <table_name> ( '' + ' +
							'STUFF ' +
							'( ' +
								'( ' +
									'SELECT ' +
										''','' + ' +
										'QUOTENAME(COLUMN_NAME) + '' '' + ' +
										'DATA_TYPE + ' + 
										'CASE ' +
											'WHEN DATA_TYPE LIKE ''%char'' THEN ''('' + COALESCE(NULLIF(CONVERT(VARCHAR, CHARACTER_MAXIMUM_LENGTH), ''-1''), ''max'') + '') '' ' +
											'ELSE '' '' ' +
										'END + ' +
										'CASE IS_NULLABLE ' +
											'WHEN ''NO'' THEN ''NOT '' ' +
											'ELSE '''' ' +
										'END + ''NULL'' AS [text()] ' +
									'FROM tempdb.INFORMATION_SCHEMA.COLUMNS ' +
									'WHERE ' +
										'TABLE_NAME = (SELECT name FROM tempdb.sys.objects WHERE object_id = OBJECT_ID(''tempdb..#session_schema'')) ' +
										'ORDER BY ' +
											'ORDINAL_POSITION ' +
									'FOR XML ' +
										'PATH('''') ' +
								'), + ' +
								'1, ' +
								'1, ' +
								''''' ' +
							') + ' +
						''')''; ' 
				ELSE ''
			END
		--End derived table and INSERT specification
		);

	SET @sql_n = CONVERT(NVARCHAR(MAX), @sql);

	EXEC sp_executesql
		@sql_n,
		N'@schema VARCHAR(MAX) OUTPUT',
		@schema OUTPUT;
END;

CREATE function [dbo].[SplitIDs] (@OrderList VARCHAR(max))
returns table
as 
return 
(
	select CAST(value as int) as OrderID from STRING_SPLIT(@OrderList,',')
)

--ALTER function [dbo].[SplitIDs] ( @OrderList VARCHAR(max))

--RETURNS @ParsedList table (OrderID int)
--AS
--BEGIN
--	DECLARE @OrderID varchar(10), @Pos int
--	SET @OrderList = LTRIM(RTRIM(@OrderList))+ ','
--	SET @Pos = CHARINDEX(',', @OrderList, 1)
--	IF REPLACE(@OrderList, ',', '') <> ''
--		BEGIN
--			WHILE @Pos > 0
--				BEGIN
--					SET @OrderID = LTRIM(RTRIM(LEFT(@OrderList, @Pos - 1)))
					
--					IF @OrderID <> ''
--						BEGIN
--							INSERT INTO @ParsedList (OrderID) VALUES (CAST(@OrderID AS bigint)) --Use Appropriate conversion
--						END
					
--					SET @OrderList = RIGHT(@OrderList, LEN(@OrderList) - @Pos)
--					SET @Pos = CHARINDEX(',', @OrderList, 1)
--				END
--		END	
--	RETURN
--END;

CREATE function [dbo].[SplitIDstring] (@OrderList VARCHAR(max))
returns table
as 
return 
(
	select value as OrderID from STRING_SPLIT(@OrderList,',')
)

--ALTER function [dbo].[SplitIDstring] ( @OrderList varchar(max))

--RETURNS @ParsedList table (OrderID VARCHAR(max))
--AS
--BEGIN
--	DECLARE @OrderID varchar(max), @Pos int
--	SET @OrderList = LTRIM(RTRIM(@OrderList))+ ','
--	SET @Pos = CHARINDEX(',', @OrderList, 1)
--	IF REPLACE(@OrderList, ',', '') <> ''
--		BEGIN
--			WHILE @Pos > 0
--				BEGIN
--					SET @OrderID = LTRIM(RTRIM(LEFT(@OrderList, @Pos - 1)))
					
--					IF @OrderID <> ''
--						BEGIN
--							INSERT INTO @ParsedList (OrderID) VALUES (CAST(@OrderID AS VARCHAR(max))) --Use Appropriate conversion
--						END
					
--					SET @OrderList = RIGHT(@OrderList, LEN(@OrderList) - @Pos)
--					SET @Pos = CHARINDEX(',', @OrderList, 1)
--				END
--		END	
--	RETURN
--END;

CREATE function [dbo].[SplitIDstringDelimitador] (@OrderList VARCHAR(max), @delimitador varchar(10))
returns table
as 
return 
(
	select value as OrderID from STRING_SPLIT(@OrderList,@delimitador)
);

-- Exemplo:
--<ArrayOfInt>
--  <int>432726</int>
--  <int>432722</int>
--  <int>2107</int>
--</ArrayOfInt>
CREATE function [dbo].[SplitIDsXml] (@XMLDoc XML)
returns table
as
	return 
	(
		-- http://sqlwithmanoj.com/2011/07/13/select-or-query-nodes-in-hierarchial-or-nested-xml/
		-- http://blogs.msdn.com/b/simonince/archive/2009/04/24/flattening-xml-data-in-sql-server.aspx
		-- https://www.simple-talk.com/sql/learn-sql-server/sql-server-xml-questions-you-were-too-shy-to-ask/
		SELECT
			Tab.Col.value('text()[1]', 'int') as ValInt
		FROM
			@XMLDoc.nodes('/*/*') Tab(Col)
	);

CREATE function [dbo].[ValidaDDD] (@DDD  VARCHAR(max))
RETURNS smallint
AS
BEGIN
    
    DECLARE @DDD_Valida int = null

	SET @DDD = [dbo].[SomenteNumeros] (@DDD)

	if @DDD <> '0'
		begin
			set @DDD_Valida = convert(smallint, @DDD)

			IF @DDD_Valida is not null 
				begin 
					SET @DDD_Valida = (CASE 
											WHEN @DDD_Valida > 9 and @DDD_Valida < 100 THEN @DDD
											ELSE NULL
											END)

					if @DDD_Valida is null or @DDD_Valida IN (10,20,23,25,26,29,30,36,39,40,50,52,56,57,58,59,60,70,72,76,78,80,90)
						begin 
							SET @DDD_Valida = NULL
						end
				end
		end
        

    RETURN @DDD_Valida 
    
END;

CREATE function [dbo].[ValidaTelefone] (@TELEFONE  VARCHAR(max))
RETURNS bigint
AS
BEGIN
    
    DECLARE @TELEFONE_Valida bigint = null

	SET @TELEFONE = [dbo].[SomenteNumeros] (@TELEFONE)

	if @TELEFONE <> '0'
		begin
			set @TELEFONE_Valida = try_convert(bigint, @TELEFONE)

			IF @TELEFONE_Valida is not null and @TELEFONE_Valida > 2000000 and @TELEFONE_Valida < 99999999999
				begin 
					if	@TELEFONE_Valida like '%99999999' or
						@TELEFONE_Valida like '%88888888' or
						@TELEFONE_Valida like '%77777777' or 
						@TELEFONE_Valida like '%66666666' or
						@TELEFONE_Valida like '%55555555' or
						@TELEFONE_Valida like '%44444444' or
						@TELEFONE_Valida like '%33333333' or
						@TELEFONE_Valida like '%12345678' or
						@TELEFONE_Valida like '%22222222'

						begin 
							SET @TELEFONE_Valida = NULL
						end
				end
			else
				begin
					set @TELEFONE_Valida = null
				end
		end
        

    RETURN @TELEFONE_Valida 
    
END;
