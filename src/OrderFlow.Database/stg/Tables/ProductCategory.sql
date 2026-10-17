CREATE TABLE stg.ProductCategory
(
    product_category_name nvarchar(200) NULL,
    product_category_name_english nvarchar(200) NULL,
    LoadRunId int NOT NULL CONSTRAINT DF_stg_ProductCategory_LoadRunId DEFAULT (0)
);