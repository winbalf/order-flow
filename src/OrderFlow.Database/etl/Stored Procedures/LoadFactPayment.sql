CREATE PROCEDURE etl.LoadFactPayment
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

        CREATE TABLE #PaymentSource
        (
            OrderId nvarchar(32) NOT NULL,
            PaymentSequential int NOT NULL,
            CustomerKey int NOT NULL,
            PurchaseDateKey int NOT NULL,
            PaymentType nvarchar(20) NOT NULL,
            Installments int NOT NULL,
            PaymentValue decimal(18, 2) NOT NULL,
            PRIMARY KEY (OrderId, PaymentSequential)
        );

        ;WITH Parsed AS (
            SELECT
                LEFT(payments.order_id, 32) AS OrderId,
                TRY_CAST(payments.payment_sequential AS int) AS PaymentSequential,
                TRY_CAST(payments.payment_installments AS int) AS Installments,
                TRY_CAST(payments.payment_value AS decimal(18, 2)) AS PaymentValue,
                payments.payment_type,
                orders.order_purchase_timestamp,
                customers.customer_unique_id
            FROM stg.OrderPayments AS payments
            LEFT JOIN stg.Orders AS orders
                ON orders.order_id = payments.order_id
            LEFT JOIN stg.Customers AS customers
                ON customers.customer_id = orders.customer_id
            WHERE payments.order_id IS NOT NULL
              AND payments.order_id <> N''
              AND TRY_CAST(payments.payment_sequential AS int) IS NOT NULL
              AND TRY_CAST(payments.payment_installments AS int) IS NOT NULL
              AND TRY_CAST(payments.payment_value AS decimal(18, 2)) IS NOT NULL
        ),
        Deduped AS (
            SELECT
                Parsed.*,
                ROW_NUMBER() OVER (
                    PARTITION BY Parsed.OrderId, Parsed.PaymentSequential
                    ORDER BY Parsed.OrderId
                ) AS RowNumber
            FROM Parsed
        )
        INSERT INTO #PaymentSource
        (
            OrderId, PaymentSequential, CustomerKey, PurchaseDateKey,
            PaymentType, Installments, PaymentValue
        )
        SELECT
            rows.OrderId,
            rows.PaymentSequential,
            ISNULL(customers.CustomerKey, -1),
            ISNULL(purchaseDate.DateKey, -1),
            ISNULL(LEFT(rows.payment_type, 20), N'unknown'),
            rows.Installments,
            rows.PaymentValue
        FROM Deduped AS rows
        LEFT JOIN dw.DimCustomer AS customers
            ON customers.CustomerUniqueId = rows.customer_unique_id
           AND customers.IsCurrent = 1
           AND customers.CustomerKey <> -1
        LEFT JOIN dw.DimDate AS purchaseDate
            ON purchaseDate.DateKey = TRY_CONVERT(int, CONVERT(char(8), TRY_CONVERT(date, rows.order_purchase_timestamp), 112))
           AND purchaseDate.DateKey <> -1
        WHERE rows.RowNumber = 1;

        INSERT INTO dw.FactPayment
        (
            OrderId, PaymentSequential, CustomerKey, PurchaseDateKey,
            PaymentType, Installments, PaymentValue
        )
        SELECT
            source.OrderId,
            source.PaymentSequential,
            source.CustomerKey,
            source.PurchaseDateKey,
            source.PaymentType,
            source.Installments,
            source.PaymentValue
        FROM #PaymentSource AS source
        WHERE NOT EXISTS (
            SELECT 1
            FROM dw.FactPayment AS existing
            WHERE existing.OrderId = source.OrderId
              AND existing.PaymentSequential = source.PaymentSequential
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