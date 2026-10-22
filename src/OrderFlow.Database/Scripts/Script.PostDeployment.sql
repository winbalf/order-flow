ALTER DATABASE CURRENT SET COMPATIBILITY_LEVEL = 170;

IF NOT EXISTS (SELECT 1 FROM dw.DimDate WHERE DateKey = -1)
    INSERT INTO dw.DimDate (DateKey, FullDate, Year, Month, MonthName)
    VALUES (-1, NULL, NULL, NULL, N'Unknown');

IF NOT EXISTS (SELECT 1 FROM dw.DimCustomer WHERE CustomerKey = -1)
BEGIN
    SET IDENTITY_INSERT dw.DimCustomer ON;

    INSERT INTO dw.DimCustomer
        (CustomerKey, CustomerUniqueId, ZipPrefix, City, State, ValidFrom, ValidTo, IsCurrent)
    VALUES
        (-1, N'UNKNOWN', NULL, N'Unknown', N'Unknown', '19000101', NULL, 1);

    SET IDENTITY_INSERT dw.DimCustomer OFF;
END;

IF NOT EXISTS (SELECT 1 FROM dw.DimProduct WHERE ProductKey = -1)
BEGIN
    SET IDENTITY_INSERT dw.DimProduct ON;

    INSERT INTO dw.DimProduct
        (ProductKey, ProductId, CategoryNameEnglish, WeightG, LengthCm, HeightCm, WidthCm)
    VALUES
        (-1, N'UNKNOWN', N'Unknown', NULL, NULL, NULL, NULL);

    SET IDENTITY_INSERT dw.DimProduct OFF;
END;

IF NOT EXISTS (SELECT 1 FROM dw.DimSeller WHERE SellerKey = -1)
BEGIN
    SET IDENTITY_INSERT dw.DimSeller ON;

    INSERT INTO dw.DimSeller
        (SellerKey, SellerId, ZipPrefix, City, State)
    VALUES
        (-1, N'UNKNOWN', NULL, N'Unknown', N'Unknown');

    SET IDENTITY_INSERT dw.DimSeller OFF;
END;