CREATE PROCEDURE import.usp_ValidateSchema
AS
BEGIN;
    SET NOCOUNT ON;

    CREATE TABLE #naming_issues (
        SmellDesc       nvarchar(200)   NOT NULL,
        ObjectName      nvarchar(128)   NOT NULL,
        TypeDesc        nvarchar(60)    NOT NULL,
        CurrentName     nvarchar(128)   NOT NULL,
        ProperName      nvarchar(128)   NOT NULL,
        RenameScript    nvarchar(500)       NULL,
    );
    ------------------------------------------------------------------------------
    
    ------------------------------------------------------------------------------
    -- Check default constraint names
    INSERT INTO #naming_issues (SmellDesc, ObjectName, TypeDesc, CurrentName, ProperName, RenameScript)
    SELECT SmellDesc = 'BAD_CONSTRAINT_NAME', ObjectName = OBJECT_NAME(dc.parent_object_id), TypeDesc = dc.[type_desc], CurrentName = dc.[name], n.ProperName
        , RenameScript = CONCAT('EXEC sp_rename N''', SCHEMA_NAME(dc.[schema_id]), '.', dc.[name], ''', N''', n.ProperName, ''', N''OBJECT'';')
    FROM sys.default_constraints dc
        CROSS APPLY (
            SELECT ProperName = CONCAT_WS(N'_', 'DF', OBJECT_NAME(dc.parent_object_id), COL_NAME(dc.parent_object_id, dc.parent_column_id))
        ) n
    WHERE dc.is_ms_shipped = 0
        AND dc.[name] COLLATE SQL_Latin1_General_CP1_CS_AS <> n.ProperName COLLATE SQL_Latin1_General_CP1_CS_AS

    -- Check FK names
    INSERT INTO #naming_issues (SmellDesc, ObjectName, TypeDesc, CurrentName, ProperName, RenameScript)
    SELECT SmellDesc = 'BAD_CONSTRAINT_NAME', ObjectName = OBJECT_NAME(fk.parent_object_id), TypeDesc = fk.[type_desc], CurrentName = fk.[name], n.ProperName
        , RenameScript = CONCAT('EXEC sp_rename N''', SCHEMA_NAME(fk.[schema_id]), '.', fk.[name], ''', N''', n.ProperName, ''', N''OBJECT'';')
    FROM sys.foreign_keys fk
        CROSS APPLY (
            SELECT Cols = STRING_AGG(COL_NAME(fkc.parent_object_id, fkc.parent_column_id), N'_') WITHIN GROUP (ORDER BY fkc.constraint_column_id)
            FROM sys.foreign_key_columns fkc
            WHERE fkc.constraint_object_id = fk.[object_id]
        ) x
        CROSS APPLY (
            SELECT ProperName = CONCAT_WS('_', 'FK', OBJECT_NAME(fk.parent_object_id), x.Cols)
        ) n
    WHERE fk.[name] COLLATE SQL_Latin1_General_CP1_CS_AS <> n.ProperName COLLATE SQL_Latin1_General_CP1_CS_AS

    -- Check index names
    INSERT INTO #naming_issues (SmellDesc, ObjectName, TypeDesc, CurrentName, ProperName, RenameScript)
    SELECT SmellDesc = 'BAD_CONSTRAINT_NAME', ObjectName = o.[name], TypeDesc = COALESCE(kc.[type_desc], 'INDEX'), CurrentName = i.[name], n.ProperName
        , RenameScript = CONCAT('EXEC sp_rename N''', SCHEMA_NAME(o.[schema_id]), '.', o.[name], '.', i.[name], ''', N''', n.ProperName, ''', N''INDEX'';')
    FROM sys.objects o
        JOIN sys.indexes i ON i.[object_id] = o.[object_id]
        LEFT JOIN sys.key_constraints kc ON kc.parent_object_id = i.[object_id] AND kc.unique_index_id = i.index_id
        CROSS APPLY (
            SELECT Cols = STRING_AGG(COL_NAME(ic.[object_id], ic.column_id), N'_') WITHIN GROUP (ORDER BY ic.key_ordinal, ic.index_column_id)
            FROM sys.index_columns ic
            WHERE ic.[object_id] = i.[object_id]
                AND ic.index_id = i.index_id
                AND ic.is_included_column = 0
        ) x
        CROSS APPLY (
            SELECT ProperName = CONCAT_WS(N'_', IIF(i.[type] = 1, 'C', '') + CASE WHEN i.is_primary_key = 1 THEN 'PK' WHEN i.is_unique_constraint = 1 THEN 'UQ' ELSE 'IX' END, o.[name], x.Cols)
        ) n
    WHERE o.is_ms_shipped = 0
        AND i.[name] COLLATE SQL_Latin1_General_CP1_CS_AS <> n.ProperName COLLATE SQL_Latin1_General_CP1_CS_AS

    IF EXISTS (SELECT * FROM #naming_issues)
    BEGIN;
        SELECT * FROM #naming_issues;
        THROW 51000, 'Schema object naming issues detected', 1;
    END;
    ------------------------------------------------------------------------------
    
    ------------------------------------------------------------------------------
    CREATE TABLE #issues (
        SmellDesc       nvarchar(200)   NOT NULL,
        ObjectName      nvarchar(128)   NOT NULL,
        ColumnName      nvarchar(128)       NULL,
        DataType        nvarchar(128)       NULL,
    );
    ------------------------------------------------------------------------------
    
    ------------------------------------------------------------------------------
    -- Check for heaps
    INSERT INTO #issues (SmellDesc, ObjectName)
    SELECT SmellDesc = 'HEAP'
        , ObjectName = o.[name]
    FROM sys.objects o
        JOIN sys.indexes i ON i.[object_id] = o.[object_id]
    WHERE o.is_ms_shipped = 0
        AND i.[type] = 0;
    ------------------------------------------------------------------------------
    
    ------------------------------------------------------------------------------
    -- Check for columns missing constraints
    ------------------------------------------------------------------------------
    -- Common columns missing default constraints
    INSERT INTO #issues (SmellDesc, ObjectName, ColumnName)
    SELECT SmellDesc = 'MISSING_DEFAULT_CONSTRAINT'
        , ObjectName = t.[name]
        , ColumnName = c.[name]
    FROM sys.tables t
        JOIN sys.columns c ON c.[object_id] = t.[object_id]
    WHERE t.is_ms_shipped = 0 AND t.temporal_type_desc <> 'HISTORY_TABLE'
        AND c.[name] IN ('_ModifyDate', '_InsertDate')
        AND c.default_object_id = 0

    -- Common columns missing FK constraints
    INSERT INTO #issues (SmellDesc, ObjectName, ColumnName)
    SELECT SmellDesc = 'MISSING_FOREIGN_KEY_CONSTRAINT'
        , ObjectName = t.[name]
        , ColumnName = c.[name]
    FROM sys.tables t
        JOIN sys.columns c ON c.[object_id] = t.[object_id]
    WHERE t.is_ms_shipped = 0 AND t.temporal_type_desc <> 'HISTORY_TABLE'
        AND c.[name] IN ('_ColumnID','_DatabaseID','_IndexID','_InstanceID','_ObjectDefinitionID','_ObjectID','_ParentColumnID','_ParentObjectID','_ReferencedColumnID','_ReferencedIndexID','_ReferencedObjectID')
        AND NOT EXISTS (
            SELECT *
            FROM sys.foreign_key_columns fkc
            WHERE fkc.parent_object_id = t.[object_id]
                AND fkc.parent_column_id = c.column_id
        );
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    -- Other
    ------------------------------------------------------------------------------
    -- Usage of datetime datatype on non-synced columns
    INSERT INTO #issues (SmellDesc, ObjectName, ColumnName, DataType)
    SELECT SmellDesc = 'DATETIME_DATATYPE_USED'
        , ObjectName = t.[name]
        , ColumnName = c.[name]
        , DataType = TYPE_NAME(c.system_type_id)
    FROM sys.tables t
        JOIN sys.columns c ON c.[object_id] = t.[object_id]
    WHERE TYPE_NAME(c.system_type_id) = 'datetime'
        AND NOT (t.[name] LIKE '[_]%' AND c.[name] NOT LIKE '[_]%')

    -- TVP's with sql_variant are not supported by the import process which uses System.Data.Common.DbDataAdapter.Fill
    INSERT INTO #issues (SmellDesc, ObjectName, ColumnName, DataType)
    SELECT SmellDesc = 'SQL_VARIANT_DATATYPE_USED_IN_TVP'
        , ObjectName = t.[name]
        , ColumnName = c.[name]
        , DataType = TYPE_NAME(c.system_type_id)
    FROM sys.table_types t
        JOIN sys.objects o ON o.[object_id] = t.type_table_object_id
        JOIN sys.columns c ON c.[object_id] = o.[object_id]
    WHERE TYPE_NAME(c.system_type_id) = 'sql_variant'
        AND EXISTS (SELECT * FROM import.SyncObject so WHERE so.ImportType = t.[name]);
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
    IF EXISTS (SELECT * FROM #issues)
    BEGIN;
        SELECT * FROM #issues;
        THROW 51000, 'Schema issues detected', 1;
    END;
    ------------------------------------------------------------------------------

    ------------------------------------------------------------------------------
END;
GO
