CREATE PROC dbo.usp_Raiserror (
    @msg nvarchar(2047),
    @ts datetime2 = NULL,
    @rc bigint = NULL,
    @s1 nvarchar(1000) = NULL,
    @s2 nvarchar(1000) = NULL,
    @s3 nvarchar(1000) = NULL
)
AS
BEGIN;
    INSERT import.[Log] (_InstanceID, _DatabaseID, [Message], TimeStart, [RowCount], String1, String2, String3)
    VALUES (CONVERT(int, SESSION_CONTEXT(N'_InstanceID')), CONVERT(int, SESSION_CONTEXT(N'_DatabaseID')), @msg, @ts, @rc, @s1, @s2, @s3);

    IF (SESSION_CONTEXT(N'Verbose') = 0) RETURN;

    SET @msg = @msg
        + IIF(@rc IS NOT NULL, CONCAT(' (',FORMAT(@rc,'N0'),' rows)'), '')
        -- Known limitation: this will not work correctly for durations longer than 24 hours, but that is not expected in this context
        + IIF(@ts IS NOT NULL, CONCAT(' [',FORMAT(DATEADD(MICROSECOND, DATEDIFF(MICROSECOND, @ts, SYSUTCDATETIME()), CONVERT(datetime2, '0001-01-01')), 'HH:mm:ss.fffffff'),']'), '')

    RAISERROR(@msg,0,1,@s1,@s2,@s3) WITH NOWAIT;
END;