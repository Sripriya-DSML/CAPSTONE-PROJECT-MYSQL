use ecomm;
-- Data Cleaning:
-- Handling Missing Values and Outliers:
-- Impute mean for the following columns, and round off to the nearest integer if required:

-- Impute mean for warehouseToHome column
SELECT ROUND(AVG(WarehouseToHome)) INTO @mean_WarehouseToHome
FROM customer_churn
WHERE WarehouseToHome IS NOT NULL;
-- Use the variable in update
SET SQL_SAFE_UPDATES = 0;
UPDATE customer_churn
SET WarehouseToHome = @mean_WarehouseToHome
WHERE WarehouseToHome IS NULL;

-- Impute mean for HourSpendOnApp column
SELECT ROUND(AVG(HourSpendOnApp)) INTO @mean_HourSpendOnApp
FROM customer_churn
WHERE HourSpendOnApp IS NOT NULL;
-- Use the variable in update
SELECT HourSpendOnApp FROM customer_churn;
SET SQL_SAFE_UPDATES = 0;
UPDATE customer_churn
SET HourSpendOnApp = @mean_HourSpendOnApp
WHERE HourSpendOnApp IS NULL;
SELECT HourSpendOnApp FROM customer_chur;

-- Impute mean for OrderAmountHikeFromlastYear column
SELECT ROUND(AVG(OrderAmountHikeFromlastYear)) INTO @mean_OrderAmountHikeFromlastYear
FROM customer_churn
WHERE OrderAmountHikeFromlastYear IS NOT NULL;
-- Use the variable in update
SELECT OrderAmountHikeFromlastYear FROM customer_churn;
UPDATE customer_churn
SET OrderAmountHikeFromlastYear = @mean_OrderAmountHikeFromlastYear
WHERE OrderAmountHikeFromlastYear IS NULL;
SELECT OrderAmountHikeFromlastYear FROM customer_churn;

-- Impute mean for DaySinceLastOrder column
SELECT ROUND(AVG(DaySinceLastOrder)) INTO @mean_DaySinceLastOrder
FROM customer_churn
WHERE DaySinceLastOrder IS NOT NULL;
-- Use the variable in update
SELECT DaySinceLastOrder FROM customer_churn;
UPDATE customer_churn
SET DaySinceLastOrder = @mean_DaySinceLastOrder
WHERE DaySinceLastOrder IS NULL;
SELECT DaySinceLastOrder FROM customer_churn;

-- Impute mode for the following columns: Tenure, CouponUsed, OrderCount
	
SELECT Tenure FROM customer_churn;
UPDATE customer_churn
SET Tenure = (
    SELECT Tenure FROM (
        SELECT Tenure
        FROM customer_churn
        WHERE Tenure IS NOT NULL
        GROUP BY Tenure
        ORDER BY COUNT(*) DESC
        LIMIT 1
    ) AS mode_value
)
WHERE Tenure IS NULL;
SELECT Tenure FROM customer_churn;

SELECT CouponUsed FROM customer_churn;
UPDATE customer_churn
SET CouponUsed = (
    SELECT CouponUsed FROM (
        SELECT CouponUsed
        FROM customer_churn
        WHERE CouponUsed IS NOT NULL
        GROUP BY CouponUsed
        ORDER BY COUNT(*) DESC
        LIMIT 1
    ) AS mode_value
)
WHERE CouponUsed IS NULL;
SELECT CouponUsed FROM customer_churn;

SELECT OrderCount FROM customer_churn;
UPDATE customer_churn
SET OrderCount = (
    SELECT OrderCount FROM (
        SELECT OrderCount
        FROM customer_churn
        WHERE OrderCount IS NOT NULL
        GROUP BY OrderCount
        ORDER BY COUNT(*) DESC
        LIMIT 1
    ) AS mode_value
)
WHERE OrderCount IS NULL;
SELECT OrderCount FROM customer_churn;

-- Handle outliers in the 'WarehouseToHome' column by deleting rows where the values are greater than 100.
DELETE FROM customer_churn WHERE WarehouseToHome > 100;
SELECT WarehouseToHome FROM customer_churn;

-- Dealing with Inconsistencies:

--  Replace occurrences of “Phone” in the 'PreferredLoginDevice' column 
UPDATE customer_churn
SET PreferredLoginDevice = 'Mobile Phone'
WHERE PreferredLoginDevice = 'Phone';

-- Replace “Mobile” in the 'PreferedOrderCat' column with “Mobile Phone” to ensure uniformity.
UPDATE customer_churn
SET PreferedOrderCat = 'Mobile Phone'
WHERE PreferedOrderCat = 'Mobile';
SELECT * FROM customer_churn;

-- Standardize payment mode values: Replace "COD" with "Cash on Delivery"
UPDATE customer_churn
SET PreferredPaymentMode = 'Cash on Delivery'
WHERE PreferredPaymentMode = 'COD';
SELECT * FROM customer_churn;
-- "CC" with "Credit Card" in the PreferredPaymentMode column.
UPDATE customer_churn
SET PreferredPaymentMode = 'Credit Card'
WHERE PreferredPaymentMode = 'CC';

-- Data Transformation:
-- Column Renaming:
-- Rename the column "PreferedOrderCat" to "PreferredOrderCat".
ALTER TABLE customer_churn
CHANGE PreferedOrderCat PreferredOrderCat VARCHAR(255);
-- Rename the column "HourSpendOnApp" to "HoursSpentOnApp".
ALTER TABLE customer_churn
CHANGE HourSpendOnApp HoursSpentOnApp INT;

-- Creating New Columns:
-- Create a new column named ‘ComplaintReceived’ with values "Yes" if the corresponding value in the ‘Complain’ is 1, and "No" otherwise.

--  add new column ‘ComplaintReceived’
ALTER TABLE customer_churn ADD ComplaintReceived VARCHAR(3);
UPDATE customer_churn
SET ComplaintReceived = CASE
    WHEN Complain = 1 THEN 'Yes'
    ELSE 'No'
END;
SELECT ComplaintReceived FROM customer_churn;

-- Create a new column named 'ChurnStatus'. Set its value to “Churned” if the corresponding value in the 'Churn' column is 1, else assign “Active”.
--  add new column ‘ChurnStatus’
ALTER TABLE customer_churn ADD ChurnStatus VARCHAR(10);

UPDATE customer_churn
SET ChurnStatus = CASE
    WHEN Churn = 1 THEN 'Churned'
    ELSE 'Active'
END;

-- Column Dropping:
-- Drop the columns "Churn" and "Complain" from the table.
ALTER TABLE customer_churn
DROP COLUMN Churn,
DROP COLUMN Complain;

-- Data Exploration and Analysis:
-- Retrieve the count of churned and active customers from the dataset.
SELECT ChurnStatus, COUNT(*) AS customer_count
FROM customer_churn
GROUP BY ChurnStatus;

-- Display the average tenure and total cashback amount of customers who churned.
SELECT AVG(Tenure) AS avg_tenure,SUM(CashbackAmount) AS total_cashback
FROM customer_churn WHERE ChurnStatus = 'Churned';

-- Determine the percentage of churned customers who complained.
SELECT ROUND((COUNT(*) * 100.0) / (SELECT COUNT(*) FROM customer_churn WHERE ChurnStatus = 'Churned'), 2
    ) AS percent_complained
FROM customer_churn WHERE ChurnStatus = 'Churned' AND ComplaintReceived = 'Yes';

-- Find the gender distribution of customers who complained.
SELECT Gender, COUNT(*) AS count FROM customer_churn
WHERE ComplaintReceived = 'Yes'GROUP BY Gender;

-- Identify the city tier with the highest number of churned customers whose preferred order category is Laptop & Accessory.
SELECT CityTier, COUNT(*) AS churned_customers
FROM customer_churn
WHERE ChurnStatus = 'Churned'
  AND PreferredOrderCat = 'Laptop & Accessory'
GROUP BY CityTier
ORDER BY churned_customers DESC
LIMIT 1;

-- Identify the most preferred payment mode among active customers.
SELECT PreferredPaymentMode, COUNT(*) AS total
FROM customer_churn
WHERE ChurnStatus = 'Active'
GROUP BY PreferredPaymentMode
ORDER BY total DESC
LIMIT 1;

-- Calculate the total order amount hike from last year for customers who are single and prefer mobile phones for ordering.
SELECT SUM(OrderAmountHikeFromlastYear) AS total_hike
FROM customer_churn
WHERE MaritalStatus = 'Single' AND PreferredOrderCat = 'Mobile Phone';

-- Find the average number of devices registered among customers who used UPI as their preferred payment mode.
SELECT ROUND(AVG(NumberOfDeviceRegistered), 2) AS avg_devices
FROM customer_churn
WHERE PreferredPaymentMode = 'UPI';

-- Determine the city tier with the highest number of customers.
SELECT CityTier, COUNT(*) AS total_customers
FROM customer_churn GROUP BY CityTier
ORDER BY total_customers DESC LIMIT 1;

-- Identify the gender that utilized the highest number of coupons.
SELECT Gender, SUM(CouponUsed) AS total_coupons
FROM customer_churn GROUP BY Gender
ORDER BY total_coupons DESC LIMIT 1;

-- List the number of customers and the maximum hours spent on the app in each preferred order category.
SELECT PreferredOrderCat,
       COUNT(*) AS customer_count,
       MAX(HoursSpentOnApp) AS max_hours
FROM customer_churn
GROUP BY PreferredOrderCat;

-- Calculate the total order count for customers who prefer using credit cards and have the maximum satisfaction score.
SELECT SUM(OrderCount) AS total_order_count
FROM customer_churn
WHERE PreferredPaymentMode = 'Credit Card' AND SatisfactionScore = (SELECT MAX(SatisfactionScore) FROM customer_churn);

-- How many customers are there who spent only one hour on the app and days since their last order was more than 5?
SELECT COUNT(*) AS customer_count
FROM customer_churn WHERE HoursSpentOnApp = 1 AND DaySinceLastOrder > 5;

-- What is the average satisfaction score of customers who have complained?
SELECT ROUND(AVG(SatisfactionScore), 2) AS avg_satisfaction
FROM customer_churn
WHERE ComplaintReceived = 'Yes';

-- List the preferred order category among customers who used more than 5 coupons.
SELECT PreferredOrderCat, COUNT(*) AS customer_count
FROM customer_churn
WHERE CouponUsed > 5
GROUP BY PreferredOrderCat
ORDER BY customer_count DESC;

-- List the top 3 preferred order categories with the highest average cashback amount.
SELECT PreferredOrderCat, ROUND(AVG(CashbackAmount), 2) AS avg_cashback
FROM customer_churn
GROUP BY PreferredOrderCat
ORDER BY avg_cashback DESC
LIMIT 3;

-- Find the preferred payment modes of customers whose average tenure is 10 months and have placed more than 500 orders.
SELECT PreferredPaymentMode, COUNT(*) AS customer_count
FROM customer_churn
WHERE Tenure = 10 AND OrderCount > 500
GROUP BY PreferredPaymentMode;

-- Categorize customers based on their distance from the warehouse to home such as 'Very Close Distance' for distances <=5km, 'Close Distance' for <=10km,
-- 'Moderate Distance' for <=15km, and 'Far Distance' for >15km. Then, display the churn status breakdown for each distance category.
SELECT 
    CASE 
        WHEN WarehouseToHome <= 5 THEN 'Very Close Distance'
        WHEN WarehouseToHome <= 10 THEN 'Close Distance'
        WHEN WarehouseToHome <= 15 THEN 'Moderate Distance'
        ELSE 'Far Distance'
    END AS DistanceCategory,
    ChurnStatus,
    COUNT(*) AS customer_count
FROM customer_churn
GROUP BY DistanceCategory, ChurnStatus
ORDER BY DistanceCategory, ChurnStatus;

-- List the customer’s order details who are married, live in City Tier-1, and their order counts are more than the average number of orders placed by all customers.
SELECT * FROM customer_churn
WHERE MaritalStatus = 'Married'AND CityTier = 1
  AND OrderCount > (
      SELECT AVG(OrderCount)
      FROM customer_churn
  );

-- a) Create a ‘customer_returns’ table in the ‘ecomm’ database and insert the following data:

CREATE TABLE customer_returns (
    ReturnID INT PRIMARY KEY,
    CustomerID INT,
    ReturnDate DATE,
    RefundAmount DECIMAL(10,2)
);

-- Insert the data into table
INSERT INTO customer_returns (ReturnID, CustomerID, ReturnDate, RefundAmount) VALUES
(1001, 50022, '2023-01-01', 2130),
(1002, 50316, '2023-01-23', 2000),
(1003, 51099, '2023-02-14', 2290),
(1004, 52321, '2023-03-08', 2510),
(1005, 52928, '2023-03-20', 3000),
(1006, 53749, '2023-04-17', 1740),
(1007, 54206, '2023-04-21', 3250),
(1008, 54838, '2023-04-30', 1990);

-- b) Display the return details along with the customer details of those who have churned and have made complaints.
SELECT 
    r.ReturnID,
    r.CustomerID,
    r.ReturnDate,
    r.RefundAmount,
    c.*
FROM customer_returns r
JOIN customer_churn c ON r.CustomerID = c.CustomerID
WHERE c.ChurnStatus = 'Churned'
  AND c.ComplaintReceived = 'Yes';




