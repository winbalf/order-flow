CREATE TABLE dw.DimSeller
(
    SellerKey int IDENTITY(1, 1) NOT NULL,
    SellerId nvarchar(32) NOT NULL,
    ZipPrefix nvarchar(8) NULL,
    City nvarchar(100) NULL,
    State nvarchar(20) NULL,
    CONSTRAINT PK_DimSeller PRIMARY KEY CLUSTERED (SellerKey),
    CONSTRAINT UQ_DimSeller_SellerId UNIQUE (SellerId)
);