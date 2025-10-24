CREATE TABLE dbo._partition_functions (
    _DatabaseID             int           NOT NULL CONSTRAINT FK__partition_functions__DatabaseID REFERENCES dbo.[Database] (_DatabaseID),
    _CollectionDate         datetime2     NOT NULL,
    --
    [name]                  nvarchar(128) NOT NULL,
    function_id             int           NOT NULL,
    [type]                  char(2)       NOT NULL,
    [type_desc]             nvarchar(60)      NULL,
    fanout                  int           NOT NULL,
    boundary_value_on_right bit           NOT NULL,
    is_system               bit           NOT NULL,
    create_date             datetime      NOT NULL,
    modify_date             datetime      NOT NULL,

    INDEX CIX__partition_functions__DatabaseID_function_id UNIQUE CLUSTERED (_DatabaseID, function_id),
);
GO