CREATE PROCEDURE etl.LoadDimCustomer
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @OwnTransaction bit = 0;
    DECLARE @ChangedAt datetime2(0) = CONVERT(datetime2(0), SYSUTCDATETIME());

    BEGIN TRY
        IF @@TRANCOUNT = 0
        BEGIN
            DELETE FROM etl.CustomerChange;

            BULK INSERT etl.CustomerChange
            FROM '/data/sample/customer_changes.csv'
            WITH (
                FORMAT = 'CSV',
                FIRSTROW = 2
            );
        END;

        IF @@TRANCOUNT = 0
        BEGIN
            BEGIN TRANSACTION;
            SET @OwnTransaction = 1;
        END;

        CREATE TABLE #CustomerSource
        (
            CustomerUniqueId nvarchar(32) NOT NULL PRIMARY KEY,
            ZipPrefix nvarchar(8) NULL,
            City nvarchar(100) NULL,
            State nvarchar(20) NULL
        );

        CREATE TABLE #CustomerChange
        (
            CustomerUniqueId nvarchar(32) NOT NULL PRIMARY KEY,
            ZipPrefix nvarchar(8) NULL,
            City nvarchar(100) NULL,
            State nvarchar(20) NULL
        );

        ;WITH SourceRows AS (
            SELECT
                LEFT(customers.customer_unique_id, 32) AS CustomerUniqueId,
                LEFT(customers.customer_zip_code_prefix, 8) AS ZipPrefix,
                LEFT(customers.customer_city, 100) AS City,
                LEFT(customers.customer_state, 20) AS State,
                ROW_NUMBER() OVER (
                    PARTITION BY customers.customer_unique_id
                    ORDER BY
                        TRY_CONVERT(datetime2(0), orders.order_purchase_timestamp) DESC,
                        customers.customer_id DESC
                ) AS RowNumber
            FROM stg.Customers AS customers
            LEFT JOIN stg.Orders AS orders
                ON orders.customer_id = customers.customer_id
            WHERE customers.customer_unique_id IS NOT NULL
              AND customers.customer_unique_id <> N''
        )
        INSERT INTO #CustomerSource (CustomerUniqueId, ZipPrefix, City, State)
        SELECT CustomerUniqueId, ZipPrefix, City, State
        FROM SourceRows
        WHERE RowNumber = 1;

        ;WITH ChangeRows AS (
            SELECT
                LEFT(changes.customer_unique_id, 32) AS CustomerUniqueId,
                LEFT(changes.customer_zip_code_prefix, 8) AS ZipPrefix,
                LEFT(changes.customer_city, 100) AS City,
                LEFT(changes.customer_state, 20) AS State,
                ROW_NUMBER() OVER (
                    PARTITION BY changes.customer_unique_id
                    ORDER BY changes.customer_city, changes.customer_state, changes.customer_zip_code_prefix
                ) AS RowNumber
            FROM etl.CustomerChange AS changes
            WHERE changes.customer_unique_id IS NOT NULL
              AND changes.customer_unique_id <> N''
        )
        INSERT INTO #CustomerChange (CustomerUniqueId, ZipPrefix, City, State)
        SELECT CustomerUniqueId, ZipPrefix, City, State
        FROM ChangeRows
        WHERE RowNumber = 1;

        UPDATE source
        SET
            ZipPrefix = change.ZipPrefix,
            City = change.City,
            State = change.State
        FROM #CustomerSource AS source
        INNER JOIN #CustomerChange AS change
            ON change.CustomerUniqueId = source.CustomerUniqueId;

        INSERT INTO #CustomerSource (CustomerUniqueId, ZipPrefix, City, State)
        SELECT
            change.CustomerUniqueId,
            change.ZipPrefix,
            change.City,
            change.State
        FROM #CustomerChange AS change
        WHERE NOT EXISTS (
            SELECT 1
            FROM #CustomerSource AS source
            WHERE source.CustomerUniqueId = change.CustomerUniqueId
        );

        UPDATE target
        SET
            IsCurrent = 0,
            ValidTo = @ChangedAt
        FROM dw.DimCustomer AS target
        INNER JOIN #CustomerSource AS source
            ON source.CustomerUniqueId = target.CustomerUniqueId
        WHERE target.IsCurrent = 1
          AND target.CustomerKey <> -1
          AND NOT EXISTS (
                SELECT target.ZipPrefix, target.City, target.State
                INTERSECT
                SELECT source.ZipPrefix, source.City, source.State
            );

        INSERT INTO dw.DimCustomer
            (CustomerUniqueId, ZipPrefix, City, State, ValidFrom, ValidTo, IsCurrent)
        SELECT
            source.CustomerUniqueId,
            source.ZipPrefix,
            source.City,
            source.State,
            @ChangedAt,
            NULL,
            1
        FROM #CustomerSource AS source
        WHERE NOT EXISTS (
            SELECT 1
            FROM dw.DimCustomer AS existing
            WHERE existing.CustomerUniqueId = source.CustomerUniqueId
              AND existing.IsCurrent = 1
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