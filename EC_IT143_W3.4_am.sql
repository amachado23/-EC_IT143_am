/******************************************************************************
NAME: EC_IT143_W3.4_am.sql
PURPOSE: Answer eight questions from the W3.3 AdventureWorks discussion.

MODIFICATION LOG:
Ver   Date         Author               Description
----- ------------ -------------------- ---------------------------------------
1.0   11/14/2026   Alexsander Machado   Built this script for EC IT143 W3.4.

RUNTIME:
Run time 12 seconds .

NOTES:
Run in SSMS against the full AdventureWorks2022 OLTP sample database.
If restored under another name, update the USE statement before running.
Each question includes its original author and question number from W3.3.
The queries read data and return eight result sets.
******************************************************************************/

USE [AdventureWorks2022];
GO

SET NOCOUNT ON;

-- Q1 | Marginal complexity | Dmytro Ivanytskyi, W3.3 Q1
-- Q1: What is the total number of products that have a color of 'Black'?
-- A1: Count product rows whose Color is Black.
SELECT COUNT(*) AS BlackProductCount
FROM Production.Product AS p
WHERE p.Color = N'Black';

-- Q2 | Marginal complexity | Jonathan Obodai Squire, W3.3 Q1
-- Q2: How many employees are currently designated as salaried employees?
-- A2: Count employees with both the current and salaried flags set.
SELECT COUNT(*) AS CurrentSalariedEmployeeCount
FROM HumanResources.Employee AS e
WHERE e.CurrentFlag = 1
    AND e.SalariedFlag = 1;

-- Q3 | Moderate complexity | Elie Flaurice Dieudonne, W3.3 Q3
-- Q3: Which product subcategories contain the greatest number of products?
--     Please show each subcategory name and its product count, including
--     only subcategories that have at least one product.
-- A3: Join products to their subcategories and rank the counts high to low.
SELECT
    ps.Name AS SubcategoryName,
    COUNT(*) AS ProductCount
FROM Production.ProductSubcategory AS ps
INNER JOIN Production.Product AS p
    ON p.ProductSubcategoryID = ps.ProductSubcategoryID
GROUP BY ps.ProductSubcategoryID, ps.Name
ORDER BY ProductCount DESC, SubcategoryName;

-- Q4 | Moderate complexity | Dmytro Ivanytskyi, W3.3 Q3
-- Q4: I am analyzing our sales performance. Which five products generated
--     the highest total revenue, calculated as order quantity multiplied
--     by unit price?
-- A4: Sum quantity times unit price for each product before discounts.
SELECT TOP (5)
    p.ProductID,
    p.Name AS ProductName,
    SUM(sod.OrderQty * sod.UnitPrice) AS TotalRevenue
FROM Sales.SalesOrderDetail AS sod
INNER JOIN Production.Product AS p
    ON p.ProductID = sod.ProductID
GROUP BY p.ProductID, p.Name
ORDER BY TotalRevenue DESC, p.ProductID;

-- Q5 | Increased complexity | Jose Valderrama Almanza, W3.3 Q5
-- Q5: Imagine I am a sales manager preparing a business report. I want to
--     understand how our product categories performed during 2013. Can you
--     show me the total quantity sold and total sales revenue for each
--     product category?
-- A5: Sum quantities and line totals by category for orders placed in 2013.
--     Revenue is assumed to include line discounts and exclude tax and
--     freight. Categories without sales in 2013 show zero.
WITH CategorySales AS (
    SELECT
        ps.ProductCategoryID,
        SUM(sod.OrderQty) AS TotalQuantitySold,
        SUM(sod.LineTotal) AS TotalSalesRevenue
    FROM Sales.SalesOrderHeader AS soh
    INNER JOIN Sales.SalesOrderDetail AS sod
        ON sod.SalesOrderID = soh.SalesOrderID
    INNER JOIN Production.Product AS p
        ON p.ProductID = sod.ProductID
    INNER JOIN Production.ProductSubcategory AS ps
        ON ps.ProductSubcategoryID = p.ProductSubcategoryID
    WHERE soh.OrderDate >= '20130101'
        AND soh.OrderDate < '20140101'
    GROUP BY ps.ProductCategoryID
)
SELECT
    pc.Name AS ProductCategory,
    COALESCE(cs.TotalQuantitySold, 0) AS TotalQuantitySold,
    COALESCE(cs.TotalSalesRevenue, 0) AS TotalSalesRevenue
FROM Production.ProductCategory AS pc
LEFT JOIN CategorySales AS cs
    ON cs.ProductCategoryID = pc.ProductCategoryID
ORDER BY TotalSalesRevenue DESC, ProductCategory;

-- Q6 | Increased complexity | John Allotey, W3.3 Q6
-- Q6: The sales team wants to compare the performance of our sales
--     territories. Using the latest year of sales data, can you show the
--     number of orders, total sales, and average amount spent per order for
--     each territory? This will help the team see which areas are doing
--     well and which need to improve.
-- A6: Use the latest calendar year with orders, even if it is partial.
--     Measure customer spending using TotalDue, which includes tax and freight.
--     Territories without orders show zero sales and a NULL average.
DECLARE @LatestOrderYear int;

SELECT @LatestOrderYear = YEAR(MAX(soh.OrderDate))
FROM Sales.SalesOrderHeader AS soh;

SELECT
    @LatestOrderYear AS SalesYear,
    st.Name AS TerritoryName,
    COUNT(soh.SalesOrderID) AS OrderCount,
    COALESCE(SUM(soh.TotalDue), 0) AS TotalSales,
    AVG(soh.TotalDue) AS AverageAmountPerOrder
FROM Sales.SalesTerritory AS st
LEFT JOIN Sales.SalesOrderHeader AS soh
    ON soh.TerritoryID = st.TerritoryID
    AND soh.OrderDate >= DATEFROMPARTS(@LatestOrderYear, 1, 1)
    AND soh.OrderDate < DATEFROMPARTS(@LatestOrderYear + 1, 1, 1)
GROUP BY st.TerritoryID, st.Name
ORDER BY TotalSales DESC, TerritoryName;

-- Q7 | Metadata | Jonathan Obodai Squire, W3.3 Q7
-- Q7: How many columns in the AdventureWorks database use the money data type
--     across all tables and views in every schema?
-- A7: Count visible columns reported as money in INFORMATION_SCHEMA.COLUMNS.
SELECT COUNT(*) AS MoneyColumnCount
FROM INFORMATION_SCHEMA.COLUMNS AS c
WHERE c.DATA_TYPE = N'money';

-- Q8 | Metadata | John Allotey, W3.3 Q8
-- Q8: Using the INFORMATION_SCHEMA.COLUMNS view, what are the column names,
--     data types, and default values in the Production.Product table?
-- A8: Return the requested metadata in the table's column order.
SELECT
    c.COLUMN_NAME AS ColumnName,
    c.DATA_TYPE AS DataType,
    c.COLUMN_DEFAULT AS DefaultValue
FROM INFORMATION_SCHEMA.COLUMNS AS c
WHERE c.TABLE_SCHEMA = N'Production'
    AND c.TABLE_NAME = N'Product'
ORDER BY c.ORDINAL_POSITION;
