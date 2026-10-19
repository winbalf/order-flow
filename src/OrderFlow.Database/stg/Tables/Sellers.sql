CREATE TABLE stg.Sellers
(
    seller_id nvarchar(max) NULL,
    seller_zip_code_prefix nvarchar(max) NULL,
    seller_city nvarchar(max) NULL,
    seller_state nvarchar(max) NULL,
    LoadRunId int NOT NULL CONSTRAINT DF_stg_Sellers_LoadRunId DEFAULT (0)
);