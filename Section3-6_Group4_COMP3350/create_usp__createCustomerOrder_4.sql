USE Pizzeria
go


DROP PROC IF EXISTS usp_createCustomerOrder
DROP TYPE IF EXISTS newOrderItems

--usp_createCustomerOrder
--This stored procedure creates a new customer order. The sales tax is 10% of order amount.
------------------------------------------------------
CREATE TYPE newOrderItems AS TABLE
(
		itemCode CHAR(5) PRIMARY KEY,
		qty INTEGER NOT NULL
);
GO


-------------------------------------------------------

CREATE PROCEDURE usp_createCustomerOrder (
						@CustID 				CHAR(8), --NOT NULL
						@Order 					newOrderItems READONLY,
						@DiscountCode 			CHAR(8),
						@OrderType 				VARCHAR(50), --NOT NULL
						@DeliveryMode 			VARCHAR(50), --NOT NULL
						@DeliveryAddress 		VARCHAR(50),
						@OrderDateTime 			DATETIME, --NOT NULL
						@FulfillDateTime 		DATETIME, --NOT NULL
						@CompleteDateTime 		DATETIME, --NOT NULL
						@PaymentConfirmation	CHAR(8), -- NOT NULL
						@employeeID				CHAR(5)) AS -- NOT NULL
BEGIN

	--Checking if CustomerID is Null or Invalid (not in Customer Table)
	DECLARE @ValidChecker AS INTEGER = (SELECT COUNT(c.customerID) FROM Customer c WHERE c.customerID = @CustID);
	IF (@CustID IS NULL OR @ValidChecker = 0)
		BEGIN
			RAISERROR('CustomerID is Null or Invalid (not in Database)', 15, 1)
		END

	-- We now need to check if all the itemIDs in @Order are valid
	DECLARE @ItemCheck AS INTEGER = (SELECT COUNT(oi.itemCode) FROM @Order oi);
	DECLARE @ItemCheck2 AS INTEGER = (SELECT COUNT(mi.itemCode) FROM MenuItem mi, @Order oi WHERE mi.itemCode = oi.itemCode)

	IF (@ItemCheck != @ItemCheck2)
		BEGIN
				RAISERROR('Incorrect MenuItem Code given', 15, 1)
		END

	--Checking if DiscountCode is not Null and Invalid (not a DiscountCode in table)
	SET @ValidChecker = (SELECT COUNT(d.discountCode) FROM DiscountProgram d WHERE d.discountCode = @DiscountCode);
	IF (@DiscountCode IS NOT NULL AND @ValidChecker = 0)
		BEGIN
			RAISERROR('Discount is Invalid (not in Database)', 15, 1)
		END

	--Checking if OrderType is Valid (i.e is Walk-In, Online, or Phone)
	IF (@OrderType != 'Walk-In' AND @OrderType != 'Online' AND @OrderType != 'Phone')
		BEGIN
			RAISERROR('OrderType invalid (must be Walk-In, Online, or Phone)', 15, 1)
		END

	--Checking if DeliveryMode is Valid (i.e is Pick Up or Delivery)
	IF (@DeliveryMode != 'Pick Up' AND @DeliveryMode != 'Delivery')
		BEGIN
			RAISERROR('DeliveryMode invalid (must be Pick Up or Delivery)', 15, 1)
		END

	-- Checking if Delivery Address is Null when it shouldn't be
	IF (@DeliveryMode = 'Delivery' AND @DeliveryAddress IS NULL)
		BEGIN
				RAISERROR('Order Type is Delivery but no Address Given', 15, 1)
		END

	-- Checking if the DATETIME Values are all not null
	IF (@OrderDateTime IS NULL)
		BEGIN
				RAISERROR('OrderDateTime cannot be Null', 15, 1)
		END

	IF (@FulfillDateTime IS NULL)
		BEGIN
				RAISERROR('FulfillDateTime cannot be Null', 15, 1)
		END
	IF (@CompleteDateTime IS NULL)
		BEGIN
				RAISERROR('CompleteDateTime cannot be Null', 15, 1)
		END

	-- Checking if the Payment Confirmation Number is not Null
	IF (@PaymentConfirmation IS NULL)
		BEGIN
				RAISERROR('PaymentConfirmation cannot be Null', 15, 1)
		END

	--Checking if EmployeeNo is not Null or Invalid (not an Employee on the Table)
	SET @ValidChecker = (SELECT COUNT(e.EmployeeNo) FROM Employee e WHERE e.EmployeeNo = @employeeID);
	IF (@employeeID IS NULL OR @ValidChecker = 0)
		BEGIN
			RAISERROR('EmployeeNo is Null or not in the Database', 15, 1)
		END


	--Insert Ingredient Check Here

	DECLARE @IngredientCheck TABLE(
									ingredientCode CHAR(5)
									);

	DECLARE @StockCheckMid TABLE(
									IngredientCode CHAR(5),
									IngredientNeed INTEGER,
									IngredientQty INTEGER,
									StockLevel INTEGER
									);

	WITH stockCheck AS(
	SELECT i.ingredientCode AS IngredientCode, re.QTY AS IngredientNeed, oi.qty AS IngredientQty, i.stock_level as StockLevel
	FROM Ingredient i,RecipeBook re, @Order oi
	WHERE oi.itemCode = re.itemCode and i.ingredientCode = re.ingredientCode)
	-- now to collapse Ingredients together
	INSERT INTO @StockCheckMid
	SELECT * FROM stockCheck

	;WITH stockCheckFinal AS(
	SELECT IngredientCode, SUM(IngredientNeed*IngredientQty) as total, StockLevel
	FROM @StockCheckMid
	GROUP BY IngredientCode, StockLevel)

	-- insert ingredientCode into IngredientCheck Table
	INSERT INTO @IngredientCheck (ingredientCode)
	SELECT scf.IngredientCode
	FROM stockCheckFinal scf
	WHERE (scf.total > scf.StockLevel)



	IF ((SELECT COUNT(*) FROM @IngredientCheck) > 0)
		BEGIN
			RAISERROR('Not enough Ingredients to fulfill this order!', 15, 1)
		END
	ELSE
		BEGIN
			-- Remove Ingredients from StockLevel

			DECLARE @StockTakeMid TABLE(
									IngredientCode CHAR(5),
									IngredientNeed INTEGER,
									IngredientQty INTEGER,
									StockLevel INTEGER
									);

			DECLARE @StockTakeComplete TABLE(
									IngredientCode CHAR(5),
									StockDeplete INTEGER,
									Stock INTEGER
									);

			WITH stockTake AS(
			SELECT i.ingredientCode AS IngredientCode, re.QTY AS IngredientNeed, oi.qty AS IngredientQty, i.stock_level as StockLevel
			FROM Ingredient i,RecipeBook re, @Order oi
			WHERE oi.itemCode = re.itemCode and i.ingredientCode = re.ingredientCode)
			-- now to collapse Ingredients together
			INSERT INTO @StockTakeMid
			SELECT * FROM stockTake

			;WITH stockTakeFinal AS(
			SELECT IngredientCode, SUM(IngredientNeed*IngredientQty) as total, StockLevel as Stock
			FROM @StockTakeMid
			GROUP BY IngredientCode, StockLevel)

			INSERT INTO @StockTakeComplete
			SELECT * FROM stockTakeFinal

			UPDATE Ingredient
			SET stock_level = (SELECT (st.Stock - st.StockDeplete) as newTotal) 
			FROM @StockTakeComplete st, Ingredient i 
			WHERE st.IngredientCode = i.ingredientCode
			

		END

	-- End Ingredient Check

	

	--------------------------------------------------------------------------
	DECLARE @OrderNo AS INTEGER = (SELECT COUNT(o.OrderID) FROM OrderUp o);
	SET @OrderNo = @OrderNo + 1; -- If all the above data is correct input, then we can assign an order number and start inserting into database tables

	DECLARE @Subtotal MONEY = (SELECT SUM(oi.qty * m.price) as subtotal
	FROM @order oi, MenuItem m
	WHERE oi.itemCode = m.itemCode)

	DECLARE @DiscountPercent FLOAT = 0;

	IF (@DiscountCode IS NULL)
		BEGIN
			SET @DiscountPercent = 0;
		END
	ELSE
		BEGIN
			SET @DiscountPercent = (SELECT d.discountPercentage FROM DiscountProgram d WHERE @DiscountCode = d.discountCode);
		END

	DECLARE @DiscountAmount MONEY = @Subtotal*@DiscountPercent;

	DECLARE @Total MONEY = @Subtotal - @DiscountAmount;

	DECLARE @Tax MONEY = @Subtotal*0.1;

	SET @Total = @Total+@Tax

	



	INSERT INTO OrderUp -- Putting the order record into the system
	VALUES(@OrderNo,@CustID,@employeeID,@DiscountCode,@OrderDateTime,@DeliveryMode,@OrderType,'Card',@FulfillDateTime,@CompleteDateTime);


	IF (@DeliveryMode = 'Delivery') 
		BEGIN
			DECLARE @Driver CHAR(5) = (SELECT TOP 1 d.EmployeeNo FROM Driver d ORDER BY NEWID());
			INSERT INTO Delivery VALUES(@OrderNo,@Driver,@DeliveryAddress);
			INSERT INTO DriverDeliveries VALUES (@Driver, @OrderNo);
		END
			
	INSERT INTO OrderPayment VALUES(@PaymentConfirmation,@OrderNo,@DiscountAmount,@Subtotal,@Tax,@Total);
	DECLARE @name VARCHAR(50) = (SELECT name FROM Customer WHERE customerID = @CustID);
	IF (@OrderType = 'Walk-In')
		BEGIN	
			
			INSERT INTO WalkIn VALUES (@OrderNo, @name);
		END

	ELSE IF (@OrderType = 'Phone')
		BEGIN	
			INSERT INTO PhoneOrder VALUES (@OrderNo,'0437665827');	-- set phone number as default 0437665827
		END

	ELSE IF (@OrderType = 'Online')
	BEGIN	
		INSERT INTO OnlineOrder (OrderID, email) VALUES (@OrderNo, 'placeholder@email.com');		
	END

	-- Finally, to add the order items into table OrderItems

	DECLARE @FinalOrder TABLE(
					OrderID INTEGER,
					ItemCode CHAR(5),
					quantity INTEGER
					);

	INSERT INTO @FinalOrder (ItemCode, quantity)
	SELECT * FROM @Order

	UPDATE @FinalOrder
	SET OrderID = @OrderNo

	-- and now to add it to OrderItems
	INSERT INTO OrderItems
	SELECT * FROM @FinalOrder
						

	SELECT @OrderNo AS 'Your Order Number';

	SELECT ou.OrderID, ou.customerID, ou.EmployeeID, ou.discountCode, ou.dateTimeOrdered, ou.DeliveryType, ou.OrderType, ou.PaymentType, ou.DateTimeOrderNeedsFulfilling, ou.DateTimeOrderComplete, op.PaymentID, op.discountAmount, op.subtotal, op.Tax, op.Total
	FROM OrderUp ou, OrderPayment op
	WHERE ou.OrderID = op.OrderID AND ou.OrderID = @OrderNo

END
GO


