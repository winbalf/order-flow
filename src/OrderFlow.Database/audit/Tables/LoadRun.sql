CREATE TABLE audit.LoadRun
(
    LoadRunId int IDENTITY(1, 1) NOT NULL,
    LoadName nvarchar(128) NOT NULL,
    SourceFile nvarchar(260) NOT NULL,
    StartedAt datetime2 NOT NULL,
    EndedAt datetime2 NULL,
    Status nvarchar(20) NOT NULL,
    RowsStaged int NULL,
    ErrorMessage nvarchar(4000) NULL,
    CONSTRAINT PK_LoadRun PRIMARY KEY CLUSTERED (LoadRunId),
    CONSTRAINT CK_LoadRun_Status CHECK (Status IN (N'Running', N'Succeeded', N'Failed'))
);