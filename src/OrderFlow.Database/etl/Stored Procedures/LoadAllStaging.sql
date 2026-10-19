CREATE PROCEDURE etl.LoadAllStaging
AS
BEGIN
    SET NOCOUNT ON;

    EXEC etl.LoadProductCategory;
    EXEC etl.LoadCustomers;
    EXEC etl.LoadGeolocation;
    EXEC etl.LoadOrderItems;
    EXEC etl.LoadOrderPayments;
    EXEC etl.LoadOrderReviews;
    EXEC etl.LoadOrders;
    EXEC etl.LoadProducts;
    EXEC etl.LoadSellers;
END;