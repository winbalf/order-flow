CREATE TABLE stg.OrdersFile
(
    order_id nvarchar(4000) NULL,
    customer_id nvarchar(4000) NULL,
    order_status nvarchar(4000) NULL,
    order_purchase_timestamp nvarchar(4000) NULL,
    order_approved_at nvarchar(4000) NULL,
    order_delivered_carrier_date nvarchar(4000) NULL,
    order_delivered_customer_date nvarchar(4000) NULL,
    order_estimated_delivery_date nvarchar(4000) NULL
);