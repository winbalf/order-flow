CREATE TABLE stg.Customers
(
    customer_id nvarchar(max) NULL,
    customer_unique_id nvarchar(max) NULL,
    customer_zip_code_prefix nvarchar(max) NULL,
    customer_city nvarchar(max) NULL,
    customer_state nvarchar(max) NULL,
    LoadRunId int NOT NULL CONSTRAINT DF_stg_Customers_LoadRunId DEFAULT (0)
);