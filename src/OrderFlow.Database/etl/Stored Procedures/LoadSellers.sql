CREATE PROCEDURE etl.LoadSellers
    @SourceFile nvarchar(260) = N'/data/olist/olist_sellers_dataset.csv'
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
            @LoadName = N'stg.Sellers',
            @SourceFile = @SourceFile,
            @LoadRunId = @LoadRunId OUTPUT;

        SET @BulkSql = N'
            BULK INSERT stg.SellersFile
            FROM ' + QUOTENAME(@SourceFile, '''') + N'
            WITH (
                FORMAT = ''CSV'',
                FIRSTROW = 2
            );';

        DELETE FROM stg.SellersFile;

        EXEC sys.sp_executesql @BulkSql;

        BEGIN TRANSACTION;

        DELETE FROM stg.Sellers;

        INSERT INTO stg.Sellers (seller_id, seller_zip_code_prefix, seller_city, seller_state, LoadRunId)
        SELECT seller_id, seller_zip_code_prefix, seller_city, seller_state, @LoadRunId
        FROM stg.SellersFile;

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