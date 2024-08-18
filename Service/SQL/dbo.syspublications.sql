IF (OBJECT_ID('dbo.syspublications') IS NOT NULL)
BEGIN;
	SELECT _CollectionDate = SYSUTCDATETIME(), * FROM dbo.syspublications;
END;