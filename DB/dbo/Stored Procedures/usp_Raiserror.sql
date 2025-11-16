CREATE PROC dbo.usp_Raiserror (
	@msg nvarchar(2047),
	@ts datetime2 = NULL,
	@rc bigint = NULL,
	@s1 nvarchar(1000) = NULL,
	@s2 nvarchar(1000) = NULL
)
AS
BEGIN;
	IF (SESSION_CONTEXT(N'Verbose') = 0) RETURN;
	SET @msg = @msg
		+ IIF(@rc IS NOT NULL, CONCAT(' (',FORMAT(@rc,'N0'),' rows)'), '')
		+ IIF(@ts IS NOT NULL, CONCAT(' [',FORMAT(DATEADD(MICROSECOND, DATEDIFF(MICROSECOND, @ts, SYSUTCDATETIME()), CONVERT(datetime2, '0001-01-01')), 'HH:mm:ss.fffffff'),']'), '')
	RAISERROR(@msg,0,1,@s1,@s2) WITH NOWAIT;
END;
GO