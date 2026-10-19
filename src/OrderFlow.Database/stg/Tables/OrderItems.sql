CREATE TABLE stg.OrderItems
(
    order_id nvarchar(max) NULL,
    order_item_id nvarchar(max) NULL,
    product_id nvarchar(max) NULL,
    seller_id nvarchar(max) NULL,
    shipping_limit_date nvarchar(max) NULL,
    price nvarchar(max) NULL,
    freight_value nvarchar(max) NULL,
    LoadRunId int NOT NULL CONSTRAINT DF_stg_OrderItems_LoadRunId DEFAULT (0)
);