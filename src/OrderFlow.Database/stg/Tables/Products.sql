CREATE TABLE stg.Products
(
    product_id nvarchar(max) NULL,
    product_category_name nvarchar(max) NULL,
    product_name_lenght nvarchar(max) NULL,
    product_description_lenght nvarchar(max) NULL,
    product_photos_qty nvarchar(max) NULL,
    product_weight_g nvarchar(max) NULL,
    product_length_cm nvarchar(max) NULL,
    product_height_cm nvarchar(max) NULL,
    product_width_cm nvarchar(max) NULL,
    LoadRunId int NOT NULL CONSTRAINT DF_stg_Products_LoadRunId DEFAULT (0)
);