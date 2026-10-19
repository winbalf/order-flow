CREATE PROCEDURE etl.LoadOrders
    @SourceFile nvarchar(260) = N'/data/olist/olist_orders_dataset.csv'
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
            @LoadName = N'stg.Orders',
            @SourceFile = @SourceFile,
            @LoadRunId = @LoadRunId OUTPUT;

        SET @BulkSql = N'
            BULK INSERT stg.OrdersFile
            FROM ' + QUOTENAME(@SourceFile, '''') + N'
            WITH (
                FORMAT = ''CSV'',
                FIRSTROW = 2
            );';

        DELETE FROM stg.OrdersFile;

        EXEC sys.sp_executesql @BulkSql;

        BEGIN TRANSACTION;

        DELETE FROM stg.Orders;

        INSERT INTO stg.Orders (order_id, customer_id, order_status, order_purchase_timestamp, order_approved_at, order_delivered_carrier_date, order_delivered_customer_date, order_estimated_delivery_date, LoadRunId)
        SELECT order_id, customer_id, order_status, order_purchase_timestamp, order_approved_at, order_delivered_carrier_date, order_delivered_customer_date, order_estimated_delivery_date, @LoadRunId
        FROM stg.OrdersFile;

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