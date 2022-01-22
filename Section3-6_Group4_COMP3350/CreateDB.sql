CREATE DATABASE Pizzeria
go

USE Pizzeria
go


-- Table Creation

CREATE TABLE Customer(
  customerID CHAR(8) PRIMARY KEY,
  name VARCHAR(50) NOT NULL,
  email VARCHAR(255),
  password VARCHAR(255)
)
go

CREATE TABLE DiscountProgram(
  discountCode VARCHAR(8) PRIMARY KEY,
  Description VARCHAR(255),
  StartDate DATE NOT NULL,
  EndDate DATE NOT NULL,
  Requirement VARCHAR(255),
  discountPercentage FLOAT NOT NULL
)
go

-- All is not null because all information is critical for Shift
CREATE TABLE Shift(
  ShiftID CHAR(5) PRIMARY KEY,
  startDate DATE NOT NULL,
  startTime TIME NOT NULL,
  endDate DATE NOT NULL,
  endTime TIME NOT NULL
)
go

CREATE TABLE Ingredient(
  ingredientCode CHAR(5) PRIMARY KEY,
  name VARCHAR(20) NOT NULL,
  type VARCHAR(20) NOT NULL CHECK (type IN ('Topping', 'Base', 'Sauce')),
  Description VARCHAR(255),
  stock_level INTEGER NOT NULL,
  stock_level_at_stocktake INTEGER NOT NULL,
  date_Last_Stock_Taken DATE,
  suggest_Stock_Level INTEGER,
  reorder_level INTEGER
  --Assumption: Stock_level integer represents amount needed to make 1 regular pizza with that ingredient. Large pizza requires 2
)
go

CREATE TABLE MenuItem(
  itemCode CHAR(5) PRIMARY KEY,
  name VARCHAR(20) NOT NULL,
  size VARCHAR(20) NOT NULL CHECK(size IN ('Regular', 'Large')),
  price MONEY NOT NULL
)
go

CREATE TABLE RecipeBook(
  itemCode CHAR(5) NOT NULL REFERENCES MenuItem(itemCode),
  ingredientCode CHAR(5) NOT NULL REFERENCES Ingredient(ingredientCode),
  QTY INTEGER NOT NULL
)
go

CREATE TABLE Supplier(
  SupplierID CHAR(5) PRIMARY KEY,
  Name VARCHAR(50) NOT NULL,
  contact CHAR(10) NOT NULL UNIQUE -- Supplier phone number
)
go

CREATE TABLE SupplierInventory(
  SupplierID CHAR(5) NOT NULL REFERENCES Supplier(SupplierID),
  ingredientCode CHAR(5) NOT NULL REFERENCES Ingredient(ingredientCode)
)
go

-- Employee has a lot of NOT NULL's because I would consider all of this required information for an employee
CREATE TABLE Employee(
  EmployeeNo CHAR(5) PRIMARY KEY,
  FirstName VARCHAR(20) NOT NULL,
  LastName VARCHAR(20) NOT NULL,
  postalAddress VARCHAR(255) NOT NULL,
  contactNo VARCHAR(10) NOT NULL UNIQUE,
  paymentRate MONEY NOT NULL,
  Status VARCHAR(20) NOT NULL CHECK(Status IN ('Hired','No Longer Working')),
  Description VARCHAR(255)
)
go

CREATE TABLE EmployeeBank(
  EmployeeNo CHAR(5) PRIMARY KEY REFERENCES Employee(EmployeeNo),
  BankName VARCHAR(255) NOT NULL,
  BankCode CHAR(6) NOT NULL,
  accountNo CHAR(10) NOT NULL UNIQUE,
  TaxFileNumber CHAR(9) NOT NULL UNIQUE
)
go

CREATE TABLE ShiftRecord(
  EmployeeNo CHAR(5) REFERENCES Employee(employeeNo),
  ShiftID CHAR(5) REFERENCES Shift(ShiftID)
)
go

CREATE TABLE StoreStaff(
  employeeNo CHAR(5),
  HoursWorked INT NOT NULL CHECK (HoursWorked >= 0), -- Hours worked this week
  PRIMARY KEY(employeeNo),
  FOREIGN KEY(employeeNo) REFERENCES Employee(employeeNo)
)
go

CREATE TABLE PaymentRecord(
  employeeNo CHAR(5),
  amount MONEY NOT NULL,
  payDate DATE NOT NULL,
  FOREIGN KEY(employeeNo) REFERENCES Employee(employeeNo)
)
go

-- This is done late because of the references to MenuItem and Discount Program
CREATE TABLE OrderUp( -- Order changed to OrderUp because Order was a keyword in SQL, caused errors
  OrderID INTEGER PRIMARY KEY,
  customerID CHAR (8) NOT NULL,
  EmployeeID CHAR (5) NOT NULL,
  discountCode VARCHAR(8),
  dateTimeOrdered DATETIME,
  DeliveryType VARCHAR(50) NOT NULL CHECK(DeliveryType IN ('Pick Up', 'Delivery')), -- Constraining DeliveryType to only acceptable inputs
  OrderType VARCHAR(50) NOT NULL CHECK(OrderType IN ('Walk-In', 'Phone', 'Online')), -- Constraining OrderType to only acceptable inputs
  PaymentType VARCHAR(50) NOT NULL CHECK(PaymentType IN ('Cash', 'Card')), -- Constraining PaymentType to only acceptable inputs
  DateTimeOrderNeedsFulfilling DATETIME,
  DateTimeOrderComplete DATETIME,
  FOREIGN KEY (EmployeeID) REFERENCES Employee(employeeNo) ON UPDATE CASCADE ON DELETE NO ACTION,
  FOREIGN KEY (customerID) REFERENCES Customer(customerID) ON UPDATE CASCADE ON DELETE NO ACTION,
  FOREIGN KEY (discountCode) REFERENCES DiscountProgram(discountCode) ON UPDATE CASCADE ON DELETE NO ACTION
)
go

CREATE TABLE OrderItems(
  OrderID INTEGER NOT NULL REFERENCES OrderUp(OrderID),
  itemCode CHAR(5) NOT NULL REFERENCES MenuItem(itemCode),
  quantity INTEGER NOT NULL CHECK (quantity >= 0)
)
go

CREATE TABLE OrderPayment(
  PaymentID CHAR(8) PRIMARY KEY ,
  OrderID INTEGER NOT NULL REFERENCES OrderUp(OrderID),
  discountAmount MONEY,
  subtotal MONEY NOT NULL,
  Tax MONEY NOT NULL,
  Total MONEY NOT NULL
)
go

CREATE TABLE Driver(
  employeeNo CHAR(5),
  driverLicense VARCHAR(8),
  PRIMARY KEY(employeeNo),
  FOREIGN KEY(employeeNo) REFERENCES Employee(employeeNo)
)
go

CREATE TABLE DriverDeliveries( --tracking the deliveries drivers deliver since they're paid by delivery
  employeeNo CHAR(5) REFERENCES Employee(employeeNo),
  OrderID INTEGER REFERENCES OrderUp(OrderID)
)
go

CREATE TABLE PhoneOrder(
  OrderID INTEGER PRIMARY KEY REFERENCES OrderUp(OrderID),
  phoneNo CHAR(10) NOT NUll
)
go

CREATE TABLE WalkIn(
  OrderID INTEGER PRIMARY KEY REFERENCES OrderUp(OrderID),
  name VARCHAR(50)
)
go

CREATE TABLE OnlineOrder(
  OrderID INTEGER PRIMARY KEY REFERENCES OrderUp(OrderID),
  email VARCHAR(255) NOT NULL,
  password VARCHAR(255) --assume that the passwords here are encrypted, though in example data they won't be
)
go

CREATE TABLE PreOrder(
  OrderID INTEGER PRIMARY KEY REFERENCES OrderUp(OrderID),
  pickUpDeliveryTime DATETIME NOT NULL
)
go

CREATE TABLE CardPayment(
  OrderID INTEGER PRIMARY KEY REFERENCES OrderUp(OrderID),
  CardNo CHAR(10) NOT NULL,
  ExpiryDate DATE NOT NULL,
  PaymentApprovalNo CHAR(8) NOT NULL
)
go

CREATE TABLE CashPayment(
  OrderID INTEGER PRIMARY KEY REFERENCES OrderUp(OrderID),
  AmountPaid MONEY NOT NULL,
  ChangeRemainder MONEY
)
go

CREATE TABLE Pickup(
  OrderID INTEGER PRIMARY KEY REFERENCES OrderUp(OrderID),
  expectedDateTimeCompletion DATETIME NOT NULL,
  DateTimeCompleted DATETIME
)
go

CREATE TABLE Delivery(
  OrderID INTEGER PRIMARY KEY REFERENCES OrderUp(OrderID),
  Driver CHAR(5) NOT NULL REFERENCES Employee(employeeNo),
  address VARCHAR(255) NOT NULL
)
go

-- Example Data Section --

-- Customers
INSERT INTO Customer VALUES ('C0000001', 'Michael Sheedy', 'example@email.com', 'examplePassword1');
INSERT INTO Customer VALUES ('C0000002', 'Jenny Zeng', 'example2@email.com', 'examplePassword2');
INSERT INTO Customer VALUES ('C0000003', 'John Smith', NULL, NULL);
INSERT INTO Customer VALUES ('C0000004', 'Jane Doe', NULL, NULL);
go

-- DiscountCodes
INSERT INTO DiscountProgram (discountCode, Description, StartDate, EndDate, discountPercentage)
VALUES ('EZ25POFF', '25 Percent off', '2021-03-22', '2021-04-04','0.25'); -- this is necessary because it didn't need a Requirement
INSERT INTO DiscountProgram VALUES ('10OFFSTD', '10% Off', '2021-03-26', '2021-03-28', 'Students only', '0.10');
go

-- Shifts
INSERT INTO Shift VALUES ('S0001', '2021-03-22', '08:30:00', '2021-03-22', '16:30:00');
INSERT INTO Shift VALUES ('S0002', '2021-03-22', '14:30:00', '2021-03-22', '22:30:00');
INSERT INTO Shift VALUES ('S0003', '2021-03-23', '12:00:00', '2021-03-23', '20:00:00');
INSERT INTO Shift VALUES ('S0004', '2021-03-23', '14:00:00', '2021-03-23', '22:00:00');
go

-- ingredients
-- assumption: all stock checking is done on Sunday
INSERT INTO Ingredient VALUES ('I0001', 'Mozzarella', 'Topping', 'Basic Cheese Topping', 50, 75, '2021-03-21', 150, 20);
INSERT INTO Ingredient VALUES ('I0002', 'Ham', 'Topping', 'Diced Ham', 30, 67, '2021-03-21', 150, 30);
INSERT INTO Ingredient VALUES ('I0003', 'Dough', 'Base', 'Basic Pizza Dough used for most Pizzas', 80, 97, '2021-03-21', 200, 60);
INSERT INTO Ingredient VALUES ('I0004', 'GF Dough', 'Base', 'Gluten Free Dough for Gluten Intolerance', 30, 42, '2021-03-21', 60, 10); -- added but ultimately unused within the assessment
INSERT INTO Ingredient VALUES ('I0005', 'Tomato Marinara', 'Sauce', 'Basic Tomato Marinara with Oregano', 70, 93, '2021-03-21', 200, 60);
INSERT INTO Ingredient VALUES ('I0006', 'BBQ Sauce', 'Sauce', 'BBQ Pizza Sauce', 56, 71, '2021-03-21', 150, 40);
INSERT INTO Ingredient VALUES ('I0007', 'Pineapple', 'Topping', 'Diced Pineapple', 0, 30, '2021-03-21', 100, 25); -- 0 Pineapples left for to use as example for Business Rule Section 5
INSERT INTO Ingredient VALUES ('I0008', 'Pepperoni', 'Topping', 'Small Pepperoni Slices', 30, 50, '2021-03-21', 100, 35);
INSERT INTO Ingredient VALUES ('I0009', 'Onions', 'Topping', 'Finely Diced Onions', 25, 38, '2021-03-21', 75, 35);
INSERT INTO Ingredient VALUES ('I0010', 'Bacon', 'Topping', 'Diced Bacon', 40, 54, '2021-03-21', 150, 40);
INSERT INTO Ingredient VALUES ('I0011', 'Eggs', 'Topping', 'Whole Eggs for Aussie Pizzas', 20, 32, '2021-03-21', 64, 16);
go

--Menu Items
INSERT INTO MenuItem VALUES ('M0001', 'Ham and Cheese', 'Regular', 15.00);
INSERT INTO MenuItem VALUES ('M0002', 'Ham and Cheese', 'Large', 20.00);
INSERT INTO MenuItem VALUES ('M0003', 'Hawaiian', 'Regular', 16.00);
INSERT INTO MenuItem VALUES ('M0004', 'Hawaiian', 'Large', 21.00);
INSERT INTO MenuItem VALUES ('M0005', 'Pepperoni Pizza', 'Regular', 15.00);
INSERT INTO MenuItem VALUES ('M0006', 'Pepperoni Pizza', 'Large', 18.00);
INSERT INTO MenuItem VALUES ('M0007', 'Aussie', 'Regular', 20.00);
INSERT INTO MenuItem VALUES ('M0008', 'Aussie', 'Large', 25.00);
go

--Recipe Book
-- Regular Ham and Cheese
INSERT INTO RecipeBook VALUES ('M0001', 'I0003', 1);
INSERT INTO RecipeBook VALUES ('M0001', 'I0005', 1);
INSERT INTO RecipeBook VALUES ('M0001', 'I0001', 1);
INSERT INTO RecipeBook VALUES ('M0001', 'I0002', 1);

-- Large Ham and Cheese
INSERT INTO RecipeBook VALUES ('M0002', 'I0003', 2);
INSERT INTO RecipeBook VALUES ('M0002', 'I0005', 2);
INSERT INTO RecipeBook VALUES ('M0002', 'I0001', 2);
INSERT INTO RecipeBook VALUES ('M0002', 'I0002', 2);

-- Regular Hawaiian
INSERT INTO RecipeBook VALUES ('M0003', 'I0003', 1);
INSERT INTO RecipeBook VALUES ('M0003', 'I0005', 1);
INSERT INTO RecipeBook VALUES ('M0003', 'I0001', 1);
INSERT INTO RecipeBook VALUES ('M0003', 'I0002', 1);
INSERT INTO RecipeBook VALUES ('M0003', 'I0007', 1);

-- Large Hawaiian
INSERT INTO RecipeBook VALUES ('M0004', 'I0003', 2);
INSERT INTO RecipeBook VALUES ('M0004', 'I0005', 2);
INSERT INTO RecipeBook VALUES ('M0004', 'I0001', 2);
INSERT INTO RecipeBook VALUES ('M0004', 'I0002', 2);
INSERT INTO RecipeBook VALUES ('M0004', 'I0007', 2);

-- Regular Pepperoni Pizza
INSERT INTO RecipeBook VALUES ('M0005', 'I0003', 1);
INSERT INTO RecipeBook VALUES ('M0005', 'I0005', 1);
INSERT INTO RecipeBook VALUES ('M0005', 'I0001', 1);
INSERT INTO RecipeBook VALUES ('M0005', 'I0008', 1);

-- Large Pepperoni Pizza
INSERT INTO RecipeBook VALUES ('M0006', 'I0003', 2);
INSERT INTO RecipeBook VALUES ('M0006', 'I0005', 2);
INSERT INTO RecipeBook VALUES ('M0006', 'I0001', 2);
INSERT INTO RecipeBook VALUES ('M0006', 'I0008', 2);

-- Regular Aussie
INSERT INTO RecipeBook VALUES ('M0007', 'I0003', 1);
INSERT INTO RecipeBook VALUES ('M0007', 'I0005', 1);
INSERT INTO RecipeBook VALUES ('M0007', 'I0001', 1);
INSERT INTO RecipeBook VALUES ('M0007', 'I0010', 1);
INSERT INTO RecipeBook VALUES ('M0007', 'I0011', 1);

-- Large Aussie
INSERT INTO RecipeBook VALUES ('M0008', 'I0003', 2);
INSERT INTO RecipeBook VALUES ('M0008', 'I0005', 2);
INSERT INTO RecipeBook VALUES ('M0008', 'I0001', 2);
INSERT INTO RecipeBook VALUES ('M0008', 'I0010', 2);
INSERT INTO RecipeBook VALUES ('M0008', 'I0011', 2);
go

-- Employee
INSERT INTO Employee (EmployeeNo, FirstName, LastName, postalAddress, contactNo, paymentRate, Status)
VALUES ('E0001', 'Dennis', 'Mennis', '1 Example Street, Boolgara', '0412127926', 21.25, 'Hired');
INSERT INTO Employee (EmployeeNo, FirstName, LastName, postalAddress, contactNo, paymentRate, Status)
VALUES ('E0002', 'Jane', 'Tirane', '20 Test Avenue, Loranga', '0416242226', 15.50, 'Hired');
INSERT INTO Employee (EmployeeNo, FirstName, LastName, postalAddress, contactNo, paymentRate, Status)
VALUES ('E0003', 'Rob', 'Buckyon', '3 Example Street, Boolgara', '0416546626', 20.00, 'Hired');
INSERT INTO Employee (EmployeeNo, FirstName, LastName, postalAddress, contactNo, paymentRate, Status)
VALUES ('E0004', 'Michelle', 'Rochelle', '10 Example Street, Boolgara', '0416826626', 9.50, 'No Longer Working');
go

-- EmployeeBank
INSERT INTO EmployeeBank VALUES ('E0001', 'Commonwealth Bank of Australia', '111222', '1234567890', '123456789');
INSERT INTO EmployeeBank VALUES ('E0002', 'Newcastle Permanent', '222111', '1234565890', '123789456');
INSERT INTO EmployeeBank VALUES ('E0003', 'Commonwealth Bank of Australia', '111222', '1230456789', '748428965');
go

--StoreStaff
INSERT INTO StoreStaff VALUES ('E0001', 8);
INSERT INTO StoreStaff VALUES ('E0002', 12);
go

--Driver
INSERT INTO Driver VALUES ('E0003', '16376728');
go

--ShiftRecord
INSERT INTO ShiftRecord VALUES ('E0001', 'S0001');
INSERT INTO ShiftRecord VALUES ('E0002', 'S0001');
INSERT INTO ShiftRecord VALUES ('E0003', 'S0001');
INSERT INTO ShiftRecord VALUES ('E0001', 'S0003');
INSERT INTO ShiftRecord VALUES ('E0004', 'S0004');
go

--PaymentRecord
INSERT INTO PaymentRecord VALUES ('E0001', 450.00, '2021-03-14');
INSERT INTO PaymentRecord VALUES ('E0002', 320.55, '2021-03-14');
INSERT INTO PaymentRecord VALUES ('E0003', 580.75, '2021-03-14');
go

-- Supplier
INSERT INTO Supplier VALUES ('SU001', 'Jims Meats', '0462753892');
INSERT INTO Supplier VALUES ('SU002', 'Sauces R Us', '0465223332');
INSERT INTO Supplier VALUES ('SU003', 'The Dough Boys', '0464233232');
go

-- SupplierInventory
-- Jims Meats
INSERT INTO SupplierInventory VALUES ('SU001', 'I0002');
INSERT INTO SupplierInventory VALUES ('SU001', 'I0008');
INSERT INTO SupplierInventory VALUES ('SU001', 'I0010');

--Sauces R us
INSERT INTO SupplierInventory VALUES ('SU002', 'I0005');
INSERT INTO SupplierInventory VALUES ('SU002', 'I0006');

--The Dough Boys
INSERT INTO SupplierInventory VALUES ('SU002', 'I0003');
INSERT INTO SupplierInventory VALUES ('SU002', 'I0004');
