CREATE PROCEDURE etl.LoadProductCategory
    @SourceFile nvarchar(260) = N'/data/sample/product_category_name_translation.csv'
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
            @LoadName = N'stg.ProductCategory',
            @SourceFile = @SourceFile,
            @LoadRunId = @LoadRunId OUTPUT;

        SET @BulkSql = N'
            BULK INSERT stg.ProductCategoryFile
            FROM ' + QUOTENAME(@SourceFile, '''') + N'
            WITH (
                FORMAT = ''CSV'',
                FIRSTROW = 2
            );';

        DELETE FROM stg.ProductCategoryFile;

        EXEC sys.sp_executesql @BulkSql;

        BEGIN TRANSACTION;

        DELETE FROM stg.ProductCategory;

        INSERT INTO stg.ProductCategory (product_category_name, product_category_name_english, LoadRunId)
        SELECT product_category_name, product_category_name_english, @LoadRunId
        FROM stg.ProductCategoryFile;

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