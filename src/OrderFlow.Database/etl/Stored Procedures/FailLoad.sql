CREATE PROCEDURE etl.FailLoad
    @LoadRunId int,
    @ErrorMessage nvarchar(4000)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE audit.LoadRun
    SET Status = N'Failed',
        EndedAt = SYSUTCDATETIME(),
        ErrorMessage = @ErrorMessage
    WHERE LoadRunId = @LoadRunId;
    IF @@ROWCOUNT = 0
        THROW 50002, 'LoadRunId was not found.', 1;
END;