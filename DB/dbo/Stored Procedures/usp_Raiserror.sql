CREATE PROC dbo.usp_Raiserror (
    @EventType varchar(5),
    @ActionName nvarchar(100),
    @Scope1 nvarchar(2047) = NULL,
    @Scope2 nvarchar(2047) = NULL,
    @DetailMessage nvarchar(2047) = NULL,
    @ts datetime2 = NULL OUTPUT,
    @rc bigint = NULL
)
AS
BEGIN;
    DECLARE @ExecutionID uniqueidentifier = TRY_CONVERT(uniqueidentifier, SESSION_CONTEXT(N'ExecutionID')),
            @InputTs datetime2 = @ts,
            @Now datetime2 = SYSUTCDATETIME(),
            @Verbose bit = COALESCE(TRY_CONVERT(bit, SESSION_CONTEXT(N'Verbose')), 0),
            @RowsSuffix nvarchar(64) = N'',
            @DurationSuffix nvarchar(64) = N'',
            @OutputMessage nvarchar(2047);

    IF (@ExecutionID IS NULL)
    BEGIN;
        SET @ExecutionID = NEWID();
        EXEC sys.sp_set_session_context @key = N'ExecutionID', @value = @ExecutionID;
    END;

    IF (@EventType NOT IN ('Start', 'Done', 'Error'))
    BEGIN;
        THROW 51000, 'Parameter @EventType must be one of Start, Done, or Error', 1;
    END;

    IF (NULLIF(LTRIM(RTRIM(@ActionName)), N'') IS NULL)
    BEGIN;
        THROW 51000, 'Parameter @ActionName is required', 1;
    END;

    INSERT import.[Log] (ExecutionID, EventType, ActionName, Scope1, Scope2, DetailMessage, StartTime, AffectedRowCount, NestLevel, _InstanceID, _DatabaseID)
    VALUES (
        @ExecutionID,
        @EventType,
        @ActionName,
        @Scope1,
        @Scope2,
        @DetailMessage,
        IIF(@EventType IN ('Done', 'Error'), @InputTs, NULL),
        @rc,
        @@NESTLEVEL-1, -- Subtracting 1 from @@NESTLEVEL since calling this proc adds a level to the nesting
        CONVERT(int, SESSION_CONTEXT(N'_InstanceID')),
        CONVERT(int, SESSION_CONTEXT(N'_DatabaseID'))
    );

    IF (@Verbose = 1)
    BEGIN;
        SET @OutputMessage = CONCAT(
            IIF(@Scope1 IS NOT NULL, CONCAT('[', @Scope1, ']'), ''),
            IIF(@Scope2 IS NOT NULL, CONCAT(IIF(@Scope1 IS NOT NULL, ' ', ''), '[', @Scope2, ']'), ''),
            IIF(@Scope1 IS NOT NULL OR @Scope2 IS NOT NULL, ' ', ''),
            @EventType, ': ', @ActionName,
            IIF(@EventType = 'Error' AND @DetailMessage IS NOT NULL, CONCAT(' - ', @DetailMessage), '')
        );

        SET @OutputMessage = LEFT(@OutputMessage, 2047);

        SET @RowsSuffix = IIF(@rc IS NOT NULL, CONCAT(' (', FORMAT(@rc, 'N0'), ' rows)'), '');
        SET @DurationSuffix = IIF(
            @EventType IN ('Done', 'Error') AND @InputTs IS NOT NULL,
            CONCAT(' [', FORMAT(DATEADD(MICROSECOND, DATEDIFF(MICROSECOND, @InputTs, @Now), CONVERT(datetime2, '0001-01-01')), 'HH:mm:ss.fffffff'), ']'),
            ''
        );

        SET @OutputMessage = LEFT(@OutputMessage + @RowsSuffix + @DurationSuffix, 2047);

        RAISERROR(N'%s', 0, 1, @OutputMessage) WITH NOWAIT;
    END;

    IF (@EventType = 'Start')
    BEGIN;
        SET @ts = @Now;
    END;
    ELSE
    BEGIN;
        SET @ts = @InputTs;
    END;
END;