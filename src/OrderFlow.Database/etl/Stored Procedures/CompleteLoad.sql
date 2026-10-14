CREATE PROCEDURE etl.CompleteLoad
    @LoadRunId int,
    @RowsStaged int
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE audit.LoadRun
    SET Status = N'Succeeded',
        EndedAt = SYSUTCDATETIME(),
        RowsStaged = @RowsStaged,
        ErrorMessage = NULL
    WHERE LoadRunId = @LoadRunId;
    IF @@ROWCOUNT = 0
        THROW 50001, 'LoadRunId was not found.', 1;
END;