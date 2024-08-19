IF (OBJECT_ID('dbo.sysreplservers') IS NOT NULL)
BEGIN;
    SELECT _CollectionDate = SYSUTCDATETIME(), * FROM dbo.sysreplservers;
END;