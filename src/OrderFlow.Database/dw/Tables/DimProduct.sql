CREATE TABLE dw.DimProduct
(
    ProductKey int IDENTITY(1, 1) NOT NULL,
    ProductId nvarchar(32) NOT NULL,
    CategoryNameEnglish nvarchar(100) NULL,
    WeightG int NULL,
    LengthCm int NULL,
    HeightCm int NULL,
    WidthCm int NULL,
    CONSTRAINT PK_DimProduct PRIMARY KEY CLUSTERED (ProductKey),
    CONSTRAINT UQ_DimProduct_ProductId UNIQUE (ProductId)
);