CREATE TABLE stg.OrderPayments
(
    order_id nvarchar(max) NULL,
    payment_sequential nvarchar(max) NULL,
    payment_type nvarchar(max) NULL,
    payment_installments nvarchar(max) NULL,
    payment_value nvarchar(max) NULL,
    LoadRunId int NOT NULL CONSTRAINT DF_stg_OrderPayments_LoadRunId DEFAULT (0)
);