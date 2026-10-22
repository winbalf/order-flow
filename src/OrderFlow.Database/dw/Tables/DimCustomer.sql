CREATE TABLE dw.DimCustomer
(
    CustomerKey int IDENTITY(1, 1) NOT NULL,
    CustomerUniqueId nvarchar(32) NOT NULL,
    ZipPrefix nvarchar(8) NULL,
    City nvarchar(100) NULL,
    State nvarchar(20) NULL,
    ValidFrom datetime2(0) NOT NULL,
    ValidTo datetime2(0) NULL,
    IsCurrent bit NOT NULL,
    CONSTRAINT PK_DimCustomer PRIMARY KEY CLUSTERED (CustomerKey)
);
GO

CREATE UNIQUE NONCLUSTERED INDEX UX_DimCustomer_Current
    ON dw.DimCustomer (CustomerUniqueId)
    WHERE IsCurrent = 1;