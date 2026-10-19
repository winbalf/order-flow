CREATE PROCEDURE etl.LoadGeolocation
    @SourceFile nvarchar(260) = N'/data/olist/olist_geolocation_dataset.csv'
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
            @LoadName = N'stg.Geolocation',
            @SourceFile = @SourceFile,
            @LoadRunId = @LoadRunId OUTPUT;

        SET @BulkSql = N'
            BULK INSERT stg.GeolocationFile
            FROM ' + QUOTENAME(@SourceFile, '''') + N'
            WITH (
                FORMAT = ''CSV'',
                FIRSTROW = 2
            );';

        DELETE FROM stg.GeolocationFile;

        EXEC sys.sp_executesql @BulkSql;

        BEGIN TRANSACTION;

        DELETE FROM stg.Geolocation;

        INSERT INTO stg.Geolocation (geolocation_zip_code_prefix, geolocation_lat, geolocation_lng, geolocation_city, geolocation_state, LoadRunId)
        SELECT geolocation_zip_code_prefix, geolocation_lat, geolocation_lng, geolocation_city, geolocation_state, @LoadRunId
        FROM stg.GeolocationFile;

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