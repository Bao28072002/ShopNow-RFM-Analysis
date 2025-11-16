USE master;
GO

ALTER DATABASE SQL_Project SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
GO

DROP DATABASE IF EXISTS SQL_Project;
GO

CREATE DATABASE SQL_Project;
GO
USE SQL_Project;
GO

SELECT TOP 10 * 
FROM dbo.Ecommerce_orders;

DECLARE @AnalysisDate DATE;
SET @AnalysisDate = (
    SELECT DATEADD(day, 1, MAX(order_date))
    FROM ecommerce_orders
);

WITH RFM_CTE AS (
    SELECT
        customer_id,
        DATEDIFF(day, MAX(order_date), @AnalysisDate) AS Recency,  
        COUNT(DISTINCT order_id) AS Frequency,                     
        SUM(amount) AS Monetary                                     
    FROM ecommerce_orders
    GROUP BY customer_id
),
RFM_Scored AS (
    SELECT
        customer_id,
        Recency,
        Frequency,
        Monetary,
        NTILE(5) OVER (ORDER BY Recency DESC) AS R_Score,     
        NTILE(5) OVER (ORDER BY Frequency ASC) AS F_Score,     
        NTILE(5) OVER (ORDER BY Monetary ASC) AS M_Score       
    FROM RFM_CTE
),
Customer_Segmented AS (
    SELECT
        customer_id,
        Recency,
        Frequency,
        Monetary,
        R_Score,
        F_Score,
        M_Score,
        CONCAT(R_Score, F_Score, M_Score) AS RFM_Score,
        CASE
            WHEN CONCAT(R_Score, F_Score, M_Score) = '555' THEN 'Champions'
            WHEN R_Score >= 4 AND F_Score >= 4 THEN 'Loyal Customers'
            WHEN R_Score >= 4 AND F_Score <= 3 THEN 'Potential Loyalists'
            WHEN R_Score <= 2 AND F_Score >= 4 THEN 'At Risk Customers'
            WHEN R_Score <= 2 AND F_Score <= 2 THEN 'Lost Customers'
            ELSE 'Others'
        END AS Customer_Segment
    FROM RFM_Scored
)
-------------------------------
--SELECT *
--FROM Customer_Segmented
--ORDER BY customer_id
-------------------------------
,
 Total_Customers AS (
    SELECT COUNT(DISTINCT customer_id) AS total_customers
    FROM ecommerce_orders
)

, CLV_Calc AS (
    SELECT
        c.customer_id,
        c.Recency,
        c.Frequency,
        c.Monetary,
        c.R_Score,
        c.F_Score,
        c.M_Score,
        c.RFM_Score,
        c.Customer_Segment,
        CAST(c.Monetary * 1.0 / NULLIF(c.Frequency,0) AS DECIMAL(10,2)) AS avg_order_value,
        CAST(c.Frequency * 1.0 / t.total_customers AS DECIMAL(10,3)) AS purchase_frequency,
        CAST(
            (c.Monetary * 1.0 / NULLIF(c.Frequency,0)) * (c.Frequency * 1.0 / t.total_customers)
            AS DECIMAL(10,2)
        ) AS CLV
    FROM Customer_Segmented c
    CROSS JOIN Total_Customers t
)

SELECT *
FROM CLV_Calc
ORDER BY 
    CASE Customer_Segment
        WHEN 'Champions' THEN 1
        WHEN 'Loyal Customers' THEN 2
        WHEN 'Potential Loyalists' THEN 3
        WHEN 'At Risk Customers' THEN 4
        WHEN 'Lost Customers' THEN 5
        ELSE 6
    END,
    CLV DESC;







