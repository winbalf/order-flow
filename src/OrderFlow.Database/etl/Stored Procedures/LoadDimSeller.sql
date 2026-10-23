CREATE PROCEDURE etl.LoadDimSeller
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

        CREATE TABLE #SellerSource
        (
            SellerId nvarchar(32) NOT NULL PRIMARY KEY,
            ZipPrefix nvarchar(8) NULL,
            City nvarchar(100) NULL,
            State nvarchar(20) NULL
        );

        ;WITH SourceRows AS (
            SELECT
                LEFT(sellers.seller_id, 32) AS SellerId,
                LEFT(sellers.seller_zip_code_prefix, 8) AS ZipPrefix,
                LEFT(sellers.seller_city, 100) AS City,
                LEFT(sellers.seller_state, 20) AS State,
                ROW_NUMBER() OVER (
                    PARTITION BY sellers.seller_id
                    ORDER BY sellers.seller_zip_code_prefix, sellers.seller_city, sellers.seller_state
                ) AS RowNumber
            FROM stg.Sellers AS sellers
            WHERE sellers.seller_id IS NOT NULL
              AND sellers.seller_id <> N''
        )
        INSERT INTO #SellerSource (SellerId, ZipPrefix, City, State)
        SELECT SellerId, ZipPrefix, City, State
        FROM SourceRows
        WHERE RowNumber = 1;

        UPDATE target
        SET
            ZipPrefix = source.ZipPrefix,
            City = source.City,
            State = source.State
        FROM dw.DimSeller AS target
        INNER JOIN #SellerSource AS source
            ON source.SellerId = target.SellerId
        WHERE target.SellerKey <> -1
          AND NOT EXISTS (
                SELECT target.ZipPrefix, target.City, target.State
                INTERSECT
                SELECT source.ZipPrefix, source.City, source.State
            );

        INSERT INTO dw.DimSeller (SellerId, ZipPrefix, City, State)
        SELECT source.SellerId, source.ZipPrefix, source.City, source.State
        FROM #SellerSource AS source
        WHERE NOT EXISTS (
            SELECT 1
            FROM dw.DimSeller AS existing
            WHERE existing.SellerId = source.SellerId
        );

        IF @OwnTransaction = 1
            COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @OwnTransaction = 1 AND @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;