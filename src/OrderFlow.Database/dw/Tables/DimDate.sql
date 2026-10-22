CREATE TABLE dw.DimDate
(
    DateKey int NOT NULL,
    FullDate date NULL,
    Year smallint NULL,
    Month tinyint NULL,
    MonthName nvarchar(20) NULL,
    CONSTRAINT PK_DimDate PRIMARY KEY CLUSTERED (DateKey)
);