------------------------------------------------------------------------------
-- Script.PostDeployment.sql - Start
------------------------------------------------------------------------------
EXEC import.usp_PopulateLookupTables;
GO
EXEC import.usp_ValidateSchema;
GO
IF NOT EXISTS (SELECT * FROM ext.ProcessRunState WHERE ID = 1)
BEGIN;
    INSERT ext.ProcessRunState VALUES (1, 'IndexColumnsSquash', SYSUTCDATETIME(), 0);
END;
------------------------------------------------------------------------------
-- Script.PostDeployment.sql - End
------------------------------------------------------------------------------