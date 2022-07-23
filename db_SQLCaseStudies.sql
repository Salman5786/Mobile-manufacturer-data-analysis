SELECT * FROM DIM_CUSTOMER
SELECT * FROM DIM_DATE
SELECT * FROM DIM_LOCATION
SELECT * FROM DIM_MANUFACTURER
SELECT * FROM DIM_MODEL
SELECT * FROM FACT_TRANSACTIONS

--Questions:

--Write queries to find out the following:

--1. List all the states in which we have customers who have bought cellphones from 2005 till today.

SELECT DISTINCT
State
FROM FACT_TRANSACTIONS INNER JOIN DIM_LOCATION ON FACT_TRANSACTIONS.IDLocation = DIM_LOCATION.IDLocation
WHERE YEAR(Date) >= '2005';

--2. What state in the US is buying more 'Samsung' cell phones?

SELECT 
State
FROM FACT_TRANSACTIONS INNER JOIN DIM_LOCATION ON FACT_TRANSACTIONS.IDLocation = DIM_LOCATION.IDLocation
WHERE Country = 'US' AND IDModel IN (SELECT 
                                     IDModel
                                     FROM DIM_MODEL INNER JOIN DIM_MANUFACTURER ON DIM_MODEL.IDManufacturer = DIM_MANUFACTURER.IDManufacturer
                                     WHERE Manufacturer_Name = 'Samsung')
GROUP BY State
ORDER BY SUM(Quantity) DESC;

--3. Show the number of transactions for each model per zip code per state.

SELECT 
FACT_TRANSACTIONS.IDModel, Model_Name, ZipCode, State, COUNT(Date) AS [Number of Transactions]
FROM FACT_TRANSACTIONS INNER JOIN DIM_LOCATION ON FACT_TRANSACTIONS.IDLocation = DIM_LOCATION.IDLocation
                       LEFT JOIN DIM_MODEL ON FACT_TRANSACTIONS.IDModel = DIM_MODEL.IDModel
GROUP BY FACT_TRANSACTIONS.IDModel, Model_Name, ZipCode, State;

--4. Show the cheapest cellphone

SELECT TOP 1
Model_Name, Manufacturer_Name, Unit_price
FROM DIM_MODEL INNER JOIN DIM_MANUFACTURER ON DIM_MODEL.IDManufacturer = DIM_MANUFACTURER.IDManufacturer
ORDER BY Unit_price;

--5. Find out the average price for each model in the top5 manufacturers in terms of sales quantity and order by average price.

SELECT 
IDManufacturer, FACT_TRANSACTIONS.IDModel, AVG(TotalPrice) AS [Average Price]
FROM FACT_TRANSACTIONS INNER JOIN DIM_MODEL ON FACT_TRANSACTIONS.IDModel = DIM_MODEL.IDModel
WHERE IDManufacturer IN (SELECT TOP 5
                                   DIM_MODEL.IDManufacturer
                                   FROM FACT_TRANSACTIONS INNER JOIN DIM_MODEL ON FACT_TRANSACTIONS.IDModel = DIM_MODEL.IDModel
						                                  LEFT JOIN DIM_MANUFACTURER ON DIM_MODEL.IDManufacturer = DIM_MANUFACTURER.IDManufacturer
						           GROUP BY DIM_MODEL.IDManufacturer
						           ORDER BY SUM(Quantity) DESC)
GROUP BY IDManufacturer, FACT_TRANSACTIONS.IDModel
ORDER BY [Average Price];

--6. List the names of the customers and the average amount spent in 2009, where the average is higher than 500

SELECT 
Customer_Name, AVG(TotalPrice) AS [Average Amount Spent in 2009] 
FROM FACT_TRANSACTIONS INNER JOIN DIM_CUSTOMER ON FACT_TRANSACTIONS.IDCustomer = DIM_CUSTOMER.IDCustomer
WHERE YEAR(Date) = '2009'
GROUP BY Customer_Name
HAVING AVG(TotalPrice) > 500;

--7. List if there is any model that was in the top 5 in terms of quantity, simultaneously in 2008, 2009 and 2010

SELECT *
FROM (
SELECT TOP 5
FACT_TRANSACTIONS.IDModel, Model_Name
FROM FACT_TRANSACTIONS LEFT JOIN DIM_MODEL ON FACT_TRANSACTIONS.IDModel = DIM_MODEL.IDModel
WHERE YEAR(Date) = '2008'
GROUP BY FACT_TRANSACTIONS.IDModel, Model_Name
ORDER BY SUM(Quantity) DESC) AS [T1] 
INTERSECT
SELECT *
FROM (
SELECT TOP 5
FACT_TRANSACTIONS.IDModel, Model_Name
FROM FACT_TRANSACTIONS LEFT JOIN DIM_MODEL ON FACT_TRANSACTIONS.IDModel = DIM_MODEL.IDModel
WHERE YEAR(Date) = '2009'
GROUP BY FACT_TRANSACTIONS.IDModel, Model_Name
ORDER BY SUM(Quantity) DESC) AS [T2] 
INTERSECT
SELECT *
FROM (
SELECT TOP 5
FACT_TRANSACTIONS.IDModel, Model_Name
FROM FACT_TRANSACTIONS LEFT JOIN DIM_MODEL ON FACT_TRANSACTIONS.IDModel = DIM_MODEL.IDModel
WHERE YEAR(Date) = '2010'
GROUP BY FACT_TRANSACTIONS.IDModel, Model_Name
ORDER BY SUM(Quantity) DESC) AS [T3];

--8. Show the manufacturer with the 2nd top sales in the year of 2009 and the manufacturer with the 2nd top sales in the year of 2010.

SELECT
'2009' AS [2nd Top Sales in the Year of], Manufacturer_Name
FROM(SELECT
     ROW_NUMBER() OVER(ORDER BY SUM(Quantity) DESC) AS [RowNumber], Manufacturer_Name
     FROM FACT_TRANSACTIONS INNER JOIN DIM_MODEL ON FACT_TRANSACTIONS.IDModel = DIM_MODEL.IDModel
	                        LEFT JOIN DIM_MANUFACTURER ON DIM_MODEL.IDManufacturer = DIM_MANUFACTURER.IDManufacturer
     WHERE YEAR(Date) = '2009'
     GROUP BY Manufacturer_Name) AS [T1]
WHERE [RowNumber] = '2'
UNION ALL
SELECT
'2010' AS [2nd Top Sales in the Year of], Manufacturer_Name
FROM(SELECT
     ROW_NUMBER() OVER(ORDER BY SUM(Quantity) DESC) AS [RowNumber], Manufacturer_Name
     FROM FACT_TRANSACTIONS INNER JOIN DIM_MODEL ON FACT_TRANSACTIONS.IDModel = DIM_MODEL.IDModel
	                        LEFT JOIN DIM_MANUFACTURER ON DIM_MODEL.IDManufacturer = DIM_MANUFACTURER.IDManufacturer
      WHERE YEAR(Date) = '2010'
      GROUP BY Manufacturer_Name) AS [T2]
WHERE [RowNumber] = '2';

--9. Show the manufacturers that sold cellphone in 2010 but didn’t in 2009.

SELECT
Manufacturer_Name
FROM FACT_TRANSACTIONS INNER JOIN DIM_MODEL ON FACT_TRANSACTIONS.IDModel = DIM_MODEL.IDModel
	                   LEFT JOIN DIM_MANUFACTURER ON DIM_MODEL.IDManufacturer = DIM_MANUFACTURER.IDManufacturer
WHERE YEAR(Date) = '2010' AND Manufacturer_Name NOT IN (SELECT
                                                        Manufacturer_Name
                                                        FROM FACT_TRANSACTIONS INNER JOIN DIM_MODEL ON FACT_TRANSACTIONS.IDModel = DIM_MODEL.IDModel
	                                                                           LEFT JOIN DIM_MANUFACTURER ON DIM_MODEL.IDManufacturer = DIM_MANUFACTURER.IDManufacturer
                                                        WHERE YEAR(Date) = '2009'
                                                        GROUP BY Manufacturer_Name)
GROUP BY Manufacturer_Name;

                                                            --OR--

SELECT
Manufacturer_Name
FROM FACT_TRANSACTIONS INNER JOIN DIM_MODEL ON FACT_TRANSACTIONS.IDModel = DIM_MODEL.IDModel
	                   LEFT JOIN DIM_MANUFACTURER ON DIM_MODEL.IDManufacturer = DIM_MANUFACTURER.IDManufacturer
WHERE YEAR(Date) = '2010'
GROUP BY Manufacturer_Name
EXCEPT
SELECT
Manufacturer_Name
FROM FACT_TRANSACTIONS INNER JOIN DIM_MODEL ON FACT_TRANSACTIONS.IDModel = DIM_MODEL.IDModel
	                   LEFT JOIN DIM_MANUFACTURER ON DIM_MODEL.IDManufacturer = DIM_MANUFACTURER.IDManufacturer
WHERE YEAR(Date) = '2009'
GROUP BY Manufacturer_Name;

--10. Find top 100 customers and their average spend, average quantity by each year. Also find the percentage of change in their spend.

SELECT TOP 100
Customer_Name, Year, AverageSpend, AverageQuantity, Difference/PreviousSpend * 100 AS [% of Change in Spend]
FROM(SELECT 
     Customer_Name, YEAR(Date) AS [Year], AVG(TotalPrice) AS [AverageSpend], AVG(Quantity) AS [AverageQuantity],
	 AVG(TotalPrice) - LAG(AVG(TotalPrice)) OVER (PARTITION BY Customer_Name ORDER BY YEAR(Date)) AS [Difference],
	 LAG(AVG(TotalPrice)) OVER (PARTITION BY Customer_Name ORDER BY YEAR(Date)) AS [PreviousSpend]
     FROM DIM_CUSTOMER INNER JOIN FACT_TRANSACTIONS ON DIM_CUSTOMER.IDCustomer = FACT_TRANSACTIONS.IDCustomer
	 GROUP BY Customer_Name, YEAR(Date)) AS [T1]
ORDER BY AverageSpend DESC, AverageQuantity DESC;










