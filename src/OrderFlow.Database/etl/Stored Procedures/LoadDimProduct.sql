CREATE PROCEDURE etl.LoadDimProduct
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

        CREATE TABLE #ProductSource
        (
            ProductId nvarchar(32) NOT NULL PRIMARY KEY,
            CategoryNameEnglish nvarchar(100) NULL,
            WeightG int NULL,
            LengthCm int NULL,
            HeightCm int NULL,
            WidthCm int NULL
        );

        ;WITH SourceRows AS (
            SELECT
                LEFT(products.product_id, 32) AS ProductId,
                LEFT(categories.product_category_name_english, 100) AS CategoryNameEnglish,
                TRY_CAST(products.product_weight_g AS int) AS WeightG,
                TRY_CAST(products.product_length_cm AS int) AS LengthCm,
                TRY_CAST(products.product_height_cm AS int) AS HeightCm,
                TRY_CAST(products.product_width_cm AS int) AS WidthCm,
                ROW_NUMBER() OVER (
                    PARTITION BY products.product_id
                    ORDER BY categories.product_category_name_english
                ) AS RowNumber
            FROM stg.Products AS products
            LEFT JOIN stg.ProductCategory AS categories
                ON categories.product_category_name = products.product_category_name
            WHERE products.product_id IS NOT NULL
              AND products.product_id <> N''
        )
        INSERT INTO #ProductSource (ProductId, CategoryNameEnglish, WeightG, LengthCm, HeightCm, WidthCm)
        SELECT ProductId, CategoryNameEnglish, WeightG, LengthCm, HeightCm, WidthCm
        FROM SourceRows
        WHERE RowNumber = 1;

        UPDATE target
        SET
            CategoryNameEnglish = source.CategoryNameEnglish,
            WeightG = source.WeightG,
            LengthCm = source.LengthCm,
            HeightCm = source.HeightCm,
            WidthCm = source.WidthCm
        FROM dw.DimProduct AS target
        INNER JOIN #ProductSource AS source
            ON source.ProductId = target.ProductId
        WHERE target.ProductKey <> -1
          AND NOT EXISTS (
                SELECT target.CategoryNameEnglish, target.WeightG, target.LengthCm, target.HeightCm, target.WidthCm
                INTERSECT
                SELECT source.CategoryNameEnglish, source.WeightG, source.LengthCm, source.HeightCm, source.WidthCm
            );

        INSERT INTO dw.DimProduct (ProductId, CategoryNameEnglish, WeightG, LengthCm, HeightCm, WidthCm)
        SELECT
            source.ProductId,
            source.CategoryNameEnglish,
            source.WeightG,
            source.LengthCm,
            source.HeightCm,
            source.WidthCm
        FROM #ProductSource AS source
        WHERE NOT EXISTS (
            SELECT 1
            FROM dw.DimProduct AS existing
            WHERE existing.ProductId = source.ProductId
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