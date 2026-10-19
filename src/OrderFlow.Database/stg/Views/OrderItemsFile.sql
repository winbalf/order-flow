CREATE TABLE stg.OrderItemsFile
(
    order_id nvarchar(4000) NULL,
    order_item_id nvarchar(4000) NULL,
    product_id nvarchar(4000) NULL,
    seller_id nvarchar(4000) NULL,
    shipping_limit_date nvarchar(4000) NULL,
    price nvarchar(4000) NULL,
    freight_value nvarchar(4000) NULL
);