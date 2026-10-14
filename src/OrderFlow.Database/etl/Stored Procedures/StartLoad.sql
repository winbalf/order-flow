CREATE PROCEDURE etl.StartLoad
    @LoadName nvarchar(128),
    @SourceFile nvarchar(260),
    @LoadRunId int OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO audit.LoadRun (LoadName, SourceFile, StartedAt, Status)
    VALUES (@LoadName, @SourceFile, SYSUTCDATETIME(), N'Running');
    SET @LoadRunId = SCOPE_IDENTITY();
END;