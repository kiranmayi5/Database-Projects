-- Create the database only if it doesn't exist
DROP DATABASE IF EXISTS final_dw;
CREATE DATABASE final_dw;
USE final_dw;

-- Create Dimension Tables
CREATE TABLE DimEmployee (
    EmployeeID INT PRIMARY KEY,
    LastName VARCHAR(20) NOT NULL,
    FirstName VARCHAR(10) NOT NULL,
    Title VARCHAR(30),
    TitleOfCourtesy VARCHAR(25),
    BirthDate DATE,
    HireDate DATE
);

CREATE TABLE DimCustomer (
    CustomerID CHAR(5) PRIMARY KEY,
    CompanyName VARCHAR(40) NOT NULL,
    ContactName VARCHAR(30),
    ContactTitle VARCHAR(30),
    Address VARCHAR(60),
    City VARCHAR(15),
    Region VARCHAR(15),
    PostalCode VARCHAR(10),
    Country VARCHAR(15)
);

CREATE TABLE DimProduct (
    ProductID INT PRIMARY KEY,
    ProductName VARCHAR(40) NOT NULL,
    SupplierID INT,
    CategoryID INT,
    QuantityPerUnit VARCHAR(20),
    UnitPrice DECIMAL(9,2) DEFAULT 0,
    Discontinued BIT DEFAULT 0
);

CREATE TABLE DimCategories (
    CategoryID INT PRIMARY KEY,
    CategoryName VARCHAR(40) NOT NULL
);

-- Create Fact Tables
CREATE TABLE FactOrder (
    OrderID INT PRIMARY KEY,
    EmployeeID INT,
    CustomerID CHAR(5),
    OrderDate DATE,
    Freight DECIMAL(9,2) DEFAULT 0,
    ShipName VARCHAR(40),
    ShipAddress VARCHAR(60),
    ShipCity VARCHAR(15),
    ShipRegion VARCHAR(15),
    ShipPostalCode VARCHAR(10),
    ShipCountry VARCHAR(15),
    FOREIGN KEY (EmployeeID) REFERENCES DimEmployee(EmployeeID),
    FOREIGN KEY (CustomerID) REFERENCES DimCustomer(CustomerID)
);

CREATE TABLE FactOrderDetails (
    OrderID INT,
    ProductID INT,
    UnitPrice DECIMAL(9,2) DEFAULT 0,
    Quantity SMALLINT DEFAULT 1,
    Discount REAL DEFAULT 0,
    FOREIGN KEY (OrderID) REFERENCES FactOrder(OrderID),
    FOREIGN KEY (ProductID) REFERENCES DimProduct(ProductID)
);

CREATE TABLE FactProductStock (
    StockID INT AUTO_INCREMENT PRIMARY KEY,
    ProductID INT,
    UnitsInStock SMALLINT DEFAULT 0,
    UnitsOnOrder SMALLINT DEFAULT 0,
    ReorderLevel SMALLINT DEFAULT 0,
    FOREIGN KEY (ProductID) REFERENCES DimProduct(ProductID)
);


-- Insert Data into Dimension Tables
INSERT INTO DimEmployee (EmployeeID, LastName, FirstName, Title, TitleOfCourtesy, BirthDate, HireDate)
SELECT EmployeeID, LastName, FirstName, Title, TitleOfCourtesy, STR_TO_DATE(BirthDate, "%m/%d/%Y"), STR_TO_DATE(HireDate, "%m/%d/%Y")
FROM cis467_final_project.Employees;

INSERT INTO DimCustomer (CustomerID, CompanyName, ContactName, ContactTitle, Address, City, Region, PostalCode, Country)
SELECT CustomerID, CompanyName, ContactName, ContactTitle, Address, City, Region, PostalCode, Country
FROM cis467_final_project.Customers;

INSERT INTO DimProduct (ProductID, ProductName, SupplierID, CategoryID, QuantityPerUnit, UnitPrice, Discontinued)
SELECT ProductID, ProductName, SupplierID, CategoryID, QuantityPerUnit, UnitPrice, Discontinued
FROM cis467_final_project.Products;

INSERT INTO DimCategories (CategoryID, CategoryName)
SELECT CategoryID, CategoryName
FROM cis467_final_project.Categories;

-- Insert Data into Fact Tables
INSERT INTO FactOrder (OrderID, EmployeeID, CustomerID, OrderDate, Freight, ShipName, ShipAddress, ShipCity, ShipRegion, ShipPostalCode, ShipCountry)
SELECT o.OrderID, o.EmployeeID, o.CustomerID, STR_TO_DATE(o.OrderDate, '%m/%d/%Y'), 
       o.Freight, o.ShipName, o.ShipAddress, o.ShipCity, o.ShipRegion, o.ShipPostalCode, o.ShipCountry
FROM cis467_final_project.Orders o;

INSERT INTO FactOrderDetails (OrderID, ProductID, UnitPrice, Quantity, Discount)
SELECT od.OrderID, od.ProductID, od.UnitPrice, od.Quantity, od.Discount
FROM cis467_final_project.Order_Details od;

INSERT INTO FactProductStock (ProductID, UnitsInStock, UnitsOnOrder, ReorderLevel)
SELECT p.ProductID, p.UnitsInStock, p.UnitsOnOrder, p.ReorderLevel
FROM cis467_final_project.Products p;

-- 1.1 Total Revenue & Monthly Sales Trend
SELECT DATE_FORMAT(OrderDate, '%Y-%m') AS Month, 
       SUM(UnitPrice * Quantity * (1 - Discount)) AS TotalRevenue
FROM FactOrderDetails od
JOIN FactOrder o ON od.OrderID = o.OrderID
GROUP BY Month
ORDER BY Month;

-- 1.2 Year Over Year Revenue Growth Analysis
WITH RevenueByYear AS (
    SELECT YEAR(OrderDate) AS OrderYear, 
           SUM(UnitPrice * Quantity * (1 - Discount)) AS TotalRevenue
    FROM FactOrderDetails od
    JOIN FactOrder o ON od.OrderID = o.OrderID
    GROUP BY OrderYear
)
SELECT OrderYear, 
       TotalRevenue, 
       LAG(TotalRevenue, 1) OVER (ORDER BY OrderYear) AS PreviousYearRevenue,
       ROUND(((TotalRevenue - LAG(TotalRevenue, 1) OVER (ORDER BY OrderYear)) / 
       LAG(TotalRevenue, 1) OVER (ORDER BY OrderYear)) * 100, 2) AS YoY_Growth_Percentage
FROM RevenueByYear;

-- 1.3 Monthly Revenue Trends with Moving Average
WITH MonthlyRevenue AS (
    SELECT DATE_FORMAT(OrderDate, '%Y-%m') AS Month, 
           SUM(UnitPrice * Quantity * (1 - Discount)) AS TotalRevenue
    FROM FactOrderDetails od
    JOIN FactOrder o ON od.OrderID = o.OrderID
    GROUP BY Month
)
SELECT Month, 
       TotalRevenue, 
       ROUND(AVG(TotalRevenue) OVER (ORDER BY Month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) AS MovingAvg_3Months
FROM MonthlyRevenue;

-- 2.1 Top 5 Highest Revenue-Generating Products
SELECT p.ProductName, 
       SUM(od.UnitPrice * od.Quantity) AS TotalRevenue,
       COUNT(od.OrderID) AS TotalOrders
FROM FactOrderDetails od
JOIN DimProduct p ON od.ProductID = p.ProductID
GROUP BY p.ProductName
ORDER BY TotalRevenue DESC
LIMIT 5;

-- 2.2 Most Consistently Selling Products
WITH ProductSales AS (
    SELECT p.ProductID, p.ProductName, 
           MONTH(OrderDate) AS SaleMonth, 
           SUM(od.Quantity) AS TotalSold
    FROM FactOrderDetails od
    JOIN FactOrder o ON od.OrderID = o.OrderID
    JOIN DimProduct p ON od.ProductID = p.ProductID
    GROUP BY p.ProductID, p.ProductName, SaleMonth
)
SELECT ProductID, ProductName, 
       ROUND(STDDEV(TotalSold), 2) AS SalesVolatility, 
       AVG(TotalSold) AS AvgMonthlySales
FROM ProductSales
GROUP BY ProductID, ProductName
ORDER BY SalesVolatility ASC;

-- 3.1 Customer Segmentation by Total Spend
SELECT c.CustomerID, c.CompanyName, 
       SUM(od.UnitPrice * od.Quantity) AS TotalSpent,
       CASE 
           WHEN SUM(od.UnitPrice * od.Quantity) > 5000 THEN 'High-Value'
           WHEN SUM(od.UnitPrice * od.Quantity) BETWEEN 2000 AND 5000 THEN 'Mid-Value'
           ELSE 'Low-Value'
       END AS CustomerSegment
FROM FactOrderDetails od
JOIN FactOrder o ON od.OrderID = o.OrderID
JOIN DimCustomer c ON o.CustomerID = c.CustomerID
GROUP BY c.CustomerID, c.CompanyName
ORDER BY TotalSpent DESC;

-- 3.2 High Churn Risk Customers
WITH CustomerOrderFrequency AS (
    SELECT c.CustomerID, c.CompanyName,
           COUNT(DISTINCT o.OrderID) AS TotalOrders,
           MAX(OrderDate) AS LastOrderDate,
           DATEDIFF(CURDATE(), MAX(OrderDate)) AS DaysSinceLastOrder
    FROM FactOrder o
    JOIN DimCustomer c ON o.CustomerID = c.CustomerID
    GROUP BY c.CustomerID, c.CompanyName
)
SELECT CustomerID, CompanyName, TotalOrders, DaysSinceLastOrder,
       CASE 
           WHEN DaysSinceLastOrder > 365 THEN 'High Risk'
           WHEN DaysSinceLastOrder BETWEEN 180 AND 365 THEN 'Medium Risk'
           ELSE 'Low Risk'
       END AS ChurnRiskCategory
FROM CustomerOrderFrequency
ORDER BY DaysSinceLastOrder DESC;


-- 4. Regional Sales Distribution
SELECT ShipCity, ShipRegion, ShipCountry, 
       SUM(od.UnitPrice * od.Quantity) AS TotalSales
FROM FactOrderDetails od
JOIN FactOrder o ON od.OrderID = o.OrderID
GROUP BY ShipCity, ShipRegion, ShipCountry
ORDER BY TotalSales DESC;

-- 5. Employee Sales Performance over Time
WITH EmployeeSales AS (
    SELECT e.EmployeeID, 
           CONCAT(e.FirstName, ' ', e.LastName) AS EmployeeName,
           YEAR(OrderDate) AS OrderYear,
           SUM(od.UnitPrice * od.Quantity) AS TotalSales
    FROM FactOrderDetails od
    JOIN FactOrder o ON od.OrderID = o.OrderID
    JOIN DimEmployee e ON o.EmployeeID = e.EmployeeID
    GROUP BY e.EmployeeID, EmployeeName, OrderYear
)
SELECT EmployeeID, EmployeeName, OrderYear, TotalSales, 
       LAG(TotalSales) OVER (PARTITION BY EmployeeID ORDER BY OrderYear) AS PreviousYearSales,
       ROUND(((TotalSales - LAG(TotalSales) OVER (PARTITION BY EmployeeID ORDER BY OrderYear)) /
       LAG(TotalSales) OVER (PARTITION BY EmployeeID ORDER BY OrderYear)) * 100, 2) AS YoY_Growth
FROM EmployeeSales;
