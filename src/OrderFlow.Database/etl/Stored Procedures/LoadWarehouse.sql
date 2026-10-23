CREATE PROCEDURE etl.LoadWarehouse
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        EXEC etl.LoadDimDate;
        EXEC etl.LoadDimProduct;
        EXEC etl.LoadDimSeller;
        EXEC etl.LoadDimCustomer;
        EXEC etl.LoadFactOrderItem;
        EXEC etl.LoadFactPayment;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;