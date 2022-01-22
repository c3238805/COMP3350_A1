Use Pizzeria
go

DECLARE @NewOrderItemsTemp AS newOrderItems
INSERT INTO @NewOrderItemsTemp VALUES ('M0001', 2);		--order items from menuItem, and how quantity of items
INSERT INTO @NewOrderItemsTemp VALUES ('M0005', 1);

EXEC usp_createCustomerOrder 'C0000001', @NewOrderItemsTemp, NULL, 'Walk-In', 'Pick Up', NULL, '2021-03-22 12:30:22', '2021-03-22 12:45:30', '2021-03-22 12:46:00', '15428963', 'E0001'
GO
