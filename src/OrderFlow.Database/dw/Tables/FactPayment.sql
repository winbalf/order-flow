
CREATE TABLE dw.FactPayment
(
    OrderId nvarchar(32) NOT NULL,
    PaymentSequential int NOT NULL,
    CustomerKey int NOT NULL,
    PurchaseDateKey int NOT NULL,
    PaymentType nvarchar(20) NOT NULL,
    Installments int NOT NULL,
    PaymentValue decimal(18, 2) NOT NULL,
    CONSTRAINT PK_FactPayment PRIMARY KEY CLUSTERED (OrderId, PaymentSequential),
    CONSTRAINT FK_FactPayment_Customer FOREIGN KEY (CustomerKey) REFERENCES dw.DimCustomer (CustomerKey),
    CONSTRAINT FK_FactPayment_PurchaseDate FOREIGN KEY (PurchaseDateKey) REFERENCES dw.DimDate (DateKey)
);