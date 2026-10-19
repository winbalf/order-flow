CREATE TABLE stg.Orders
(
    order_id nvarchar(max) NULL,
    customer_id nvarchar(max) NULL,
    order_status nvarchar(max) NULL,
    order_purchase_timestamp nvarchar(max) NULL,
    order_approved_at nvarchar(max) NULL,
    order_delivered_carrier_date nvarchar(max) NULL,
    order_delivered_customer_date nvarchar(max) NULL,
    order_estimated_delivery_date nvarchar(max) NULL,
    LoadRunId int NOT NULL CONSTRAINT DF_stg_Orders_LoadRunId DEFAULT (0)
);