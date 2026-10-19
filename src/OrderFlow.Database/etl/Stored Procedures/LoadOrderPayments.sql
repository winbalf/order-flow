CREATE PROCEDURE etl.LoadOrderPayments
    @SourceFile nvarchar(260) = N'/data/olist/olist_order_payments_dataset.csv'
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @LoadRunId int;
    DECLARE @RowsStaged int;
    DECLARE @ErrorMessage nvarchar(4000);
    DECLARE @BulkSql nvarchar(max);

    BEGIN TRY
        EXEC etl.StartLoad
            @LoadName = N'stg.OrderPayments',
            @SourceFile = @SourceFile,
            @LoadRunId = @LoadRunId OUTPUT;

        SET @BulkSql = N'
            BULK INSERT stg.OrderPaymentsFile
            FROM ' + QUOTENAME(@SourceFile, '''') + N'
            WITH (
                FORMAT = ''CSV'',
                FIRSTROW = 2
            );';

        DELETE FROM stg.OrderPaymentsFile;

        EXEC sys.sp_executesql @BulkSql;

        BEGIN TRANSACTION;

        DELETE FROM stg.OrderPayments;

        INSERT INTO stg.OrderPayments (order_id, payment_sequential, payment_type, payment_installments, payment_value, LoadRunId)
        SELECT order_id, payment_sequential, payment_type, payment_installments, payment_value, @LoadRunId
        FROM stg.OrderPaymentsFile;

        SET @RowsStaged = @@ROWCOUNT;

        COMMIT TRANSACTION;

        EXEC etl.CompleteLoad
            @LoadRunId = @LoadRunId,
            @RowsStaged = @RowsStaged;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        IF @LoadRunId IS NOT NULL
        BEGIN
            SET @ErrorMessage = ERROR_MESSAGE();
            EXEC etl.FailLoad
                @LoadRunId = @LoadRunId,
                @ErrorMessage = @ErrorMessage;
        END;

        THROW;
    END CATCH
END;