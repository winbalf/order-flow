CREATE PROCEDURE etl.LoadFactOrderItem
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

        CREATE TABLE #ItemSource
        (
            OrderId nvarchar(32) NOT NULL,
            OrderItemId int NOT NULL,
            CustomerKey int NOT NULL,
            ProductKey int NOT NULL,
            SellerKey int NOT NULL,
            PurchaseDateKey int NOT NULL,
            ApprovedDateKey int NOT NULL,
            CarrierDateKey int NOT NULL,
            DeliveredDateKey int NOT NULL,
            EstimatedDateKey int NOT NULL,
            CustomerId nvarchar(32) NOT NULL,
            Price decimal(18, 2) NOT NULL,
            FreightValue decimal(18, 2) NOT NULL,
            OrderStatus nvarchar(20) NOT NULL,
            PRIMARY KEY (OrderId, OrderItemId)
        );

        ;WITH Parsed AS (
            SELECT
                LEFT(items.order_id, 32) AS OrderId,
                TRY_CAST(items.order_item_id AS int) AS OrderItemId,
                TRY_CAST(items.price AS decimal(18, 2)) AS Price,
                TRY_CAST(items.freight_value AS decimal(18, 2)) AS FreightValue,
                items.product_id,
                items.seller_id,
                orders.customer_id,
                orders.order_status,
                orders.order_purchase_timestamp,
                orders.order_approved_at,
                orders.order_delivered_carrier_date,
                orders.order_delivered_customer_date,
                orders.order_estimated_delivery_date,
                customers.customer_unique_id
            FROM stg.OrderItems AS items
            LEFT JOIN stg.Orders AS orders
                ON orders.order_id = items.order_id
            LEFT JOIN stg.Customers AS customers
                ON customers.customer_id = orders.customer_id
            WHERE items.order_id IS NOT NULL
              AND items.order_id <> N''
              AND TRY_CAST(items.order_item_id AS int) IS NOT NULL
              AND TRY_CAST(items.price AS decimal(18, 2)) IS NOT NULL
              AND TRY_CAST(items.freight_value AS decimal(18, 2)) IS NOT NULL
        ),
        Deduped AS (
            SELECT
                Parsed.*,
                ROW_NUMBER() OVER (
                    PARTITION BY Parsed.OrderId, Parsed.OrderItemId
                    ORDER BY Parsed.OrderId
                ) AS RowNumber
            FROM Parsed
        )
        INSERT INTO #ItemSource
        (
            OrderId, OrderItemId, CustomerKey, ProductKey, SellerKey,
            PurchaseDateKey, ApprovedDateKey, CarrierDateKey, DeliveredDateKey, EstimatedDateKey,
            CustomerId, Price, FreightValue, OrderStatus
        )
        SELECT
            rows.OrderId,
            rows.OrderItemId,
            ISNULL(customers.CustomerKey, -1),
            ISNULL(products.ProductKey, -1),
            ISNULL(sellers.SellerKey, -1),
            ISNULL(purchaseDate.DateKey, -1),
            ISNULL(approvedDate.DateKey, -1),
            ISNULL(carrierDate.DateKey, -1),
            ISNULL(deliveredDate.DateKey, -1),
            ISNULL(estimatedDate.DateKey, -1),
            ISNULL(LEFT(rows.customer_id, 32), N'UNKNOWN'),
            rows.Price,
            rows.FreightValue,
            ISNULL(LEFT(rows.order_status, 20), N'unknown')
        FROM Deduped AS rows
        LEFT JOIN dw.DimCustomer AS customers
            ON customers.CustomerUniqueId = rows.customer_unique_id
           AND customers.IsCurrent = 1
           AND customers.CustomerKey <> -1
        LEFT JOIN dw.DimProduct AS products
            ON products.ProductId = rows.product_id
           AND products.ProductKey <> -1
        LEFT JOIN dw.DimSeller AS sellers
            ON sellers.SellerId = rows.seller_id
           AND sellers.SellerKey <> -1
        LEFT JOIN dw.DimDate AS purchaseDate
            ON purchaseDate.DateKey = TRY_CONVERT(int, CONVERT(char(8), TRY_CONVERT(date, rows.order_purchase_timestamp), 112))
           AND purchaseDate.DateKey <> -1
        LEFT JOIN dw.DimDate AS approvedDate
            ON approvedDate.DateKey = TRY_CONVERT(int, CONVERT(char(8), TRY_CONVERT(date, rows.order_approved_at), 112))
           AND approvedDate.DateKey <> -1
        LEFT JOIN dw.DimDate AS carrierDate
            ON carrierDate.DateKey = TRY_CONVERT(int, CONVERT(char(8), TRY_CONVERT(date, rows.order_delivered_carrier_date), 112))
           AND carrierDate.DateKey <> -1
        LEFT JOIN dw.DimDate AS deliveredDate
            ON deliveredDate.DateKey = TRY_CONVERT(int, CONVERT(char(8), TRY_CONVERT(date, rows.order_delivered_customer_date), 112))
           AND deliveredDate.DateKey <> -1
        LEFT JOIN dw.DimDate AS estimatedDate
            ON estimatedDate.DateKey = TRY_CONVERT(int, CONVERT(char(8), TRY_CONVERT(date, rows.order_estimated_delivery_date), 112))
           AND estimatedDate.DateKey <> -1
        WHERE rows.RowNumber = 1;

        INSERT INTO dw.FactOrderItem
        (
            OrderId, OrderItemId, CustomerKey, ProductKey, SellerKey,
            PurchaseDateKey, ApprovedDateKey, CarrierDateKey, DeliveredDateKey, EstimatedDateKey,
            CustomerId, Price, FreightValue, OrderStatus
        )
        SELECT
            source.OrderId, source.OrderItemId, source.CustomerKey, source.ProductKey, source.SellerKey,
            source.PurchaseDateKey, source.ApprovedDateKey, source.CarrierDateKey, source.DeliveredDateKey, source.EstimatedDateKey,
            source.CustomerId, source.Price, source.FreightValue, source.OrderStatus
        FROM #ItemSource AS source
        WHERE NOT EXISTS (
            SELECT 1
            FROM dw.FactOrderItem AS existing
            WHERE existing.OrderId = source.OrderId
              AND existing.OrderItemId = source.OrderItemId
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