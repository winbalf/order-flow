CREATE PROCEDURE etl.LoadDimDate
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @OwnTransaction bit = 0;

    BEGIN TRY
        IF @@TRANCOUNT = 0
        BEGIN
            BEGIN TRANSACTION;
            SET @OwnTransaction = 1;
        END;

        ;WITH DayNumbers AS (
            SELECT 0 AS DayOffset
            UNION ALL
            SELECT DayOffset + 1
            FROM DayNumbers
            WHERE DayOffset < DATEDIFF(day, CONVERT(date, '20160101'), CONVERT(date, '20181231'))
        )
        INSERT INTO dw.DimDate (DateKey, FullDate, Year, Month, MonthName)
        SELECT
            CONVERT(int, CONVERT(char(8), calendar.FullDate, 112)),
            calendar.FullDate,
            CONVERT(smallint, YEAR(calendar.FullDate)),
            CONVERT(tinyint, MONTH(calendar.FullDate)),
            DATENAME(month, calendar.FullDate)
        FROM DayNumbers AS numbers
        CROSS APPLY (
            SELECT DATEADD(day, numbers.DayOffset, CONVERT(date, '20160101')) AS FullDate
        ) AS calendar
        WHERE NOT EXISTS (
            SELECT 1
            FROM dw.DimDate AS existing
            WHERE existing.DateKey = CONVERT(int, CONVERT(char(8), calendar.FullDate, 112))
        )
        OPTION (MAXRECURSION 0);

        IF @OwnTransaction = 1
            COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @OwnTransaction = 1 AND @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;