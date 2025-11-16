# Customer Segmentation & RFM Analysis for ShopNow E-commerce

**Author:** Lê Gia Bảo

**Date:** November 2025

**Tools Used:** SQL Server

## 📑 Table of Contents
[📌 1. Background & Overview](#background-overview)<br>
[📂 2. Dataset Description & Data Structure](#dataset-description--data-structure)<br>
[🧮 3. Apply RFM Model](#apply-rfm-model)<br>
[💰 4. Calculate Customer Lifetime Value (CLV)](#calculate-customer-lifetime-value-clv)

## Background & Overview

### Objective ###

📖 **What is this project about?**  

ShopNow has thousands of customers and orders each year. They want to leverage historical data to:

- Gain deeper insights into customer behavior
- Segment buyers to personalize marketing campaigns
- Optimize customer lifetime and maximize revenue

## ❓ Business Questions

✔️ Who are the best customers? (**RFM Analysis**) 
✔️ What is the **Customer Lifetime Value (CLV)**?

👤 **Who is this project for?**  

✔️ Marketing & Sales Department  
✔️ Business Managers

### RFM Analysis Overview  

**🔎 Why use RFM?**  
RFM (Recency, Frequency, Monetary) is a customer analysis method that evaluates purchasing behavior. In this approach, each customer receives a score based on the three RFM components. These scores are then used to group customers into segments, helping businesses identify target audiences for focused marketing and sales strategies.

- **Recency**: Indicates how much time has passed since the customer’s most recent purchase.  
- **Frequency**: Reflects how often the customer makes purchases.  
- **Monetary**: Measures the total amount the customer has spent.

Using RFM allows businesses to segment customers based on their value and apply these insights to improve marketing activities and enhance customer engagement.

### ❓ **What is CLV?**

**Customer Lifetime Value (CLV)** is the **total value a customer brings to a business over their entire purchasing "lifecycle"**.

---

## 🧮 **Simple Formula to Calculate CLV**:

CLV = Average Order Value × Purchase Frequency

Where:

- **Average Order Value (AOV)** = Total Revenue ÷ Number of Orders  
- **Purchase Frequency (F)** = Total Orders per Customer ÷ Total Number of Customers

> ✅ This simple formula is enough to create a strategic map of customer value when cost or recurring revenue data is not available.

## Dataset Description & Data Structure

The dataset contains transactional data from **ShopNow**, covering the period from **2019 to 2024**.  
It includes over **5,000 orders from 500 customers**, providing a realistic structure for customer segmentation analysis.

### Dataset Columns

| Column Name        | Description                                      |
|-------------------|--------------------------------------------------|
| `order_id`         | Unique identifier for each order                |
| `customer_id`      | Unique identifier for each customer             |
| `order_date`       | Date when the order was placed                  |
| `amount`           | Value of the order                              |
| `product_id`       | Product code                                    |
| `product_category` | Product category (e.g., Fashion, Books, etc.)  |

## Apply RFM Model

#### 🛠 Step 1. Connect and load dataset

1. Connect to the newly created database  
2. Right-click on the database → **Tasks → Import Flat File...**  
3. Select **Source file**: Choose your CSV/flat file.  
4. Select **Destination**: Choose the database newly created and table name (can create a new table).  
5. Review **Data Types** for each column (SSMS will suggest automatically).  
6. Click **Finish** → The data will be imported into the table.

#### 🛠 Step 2. Calculate RFM Score

1. Calculate **Recency** (the number of days since the most recent purchase compared to the analysis date)  
2. Calculate **Frequency** (the total number of orders per customer)  
3. Calculate **Monetary** (the total spending of each customer)  
4. Score each factor on a scale of 1–5  
5. Assign **segments**: Champions, Loyal, Potential, At Risk, Lost , Other

```sql
DECLARE @AnalysisDate DATE;
SET @AnalysisDate = (
    SELECT DATEADD(day, 1, MAX(order_date))
    FROM ecommerce_orders
);

WITH RFM_CTE AS (
    SELECT
        customer_id,
        DATEDIFF(day, MAX(order_date), @AnalysisDate) AS Recency,  -- Days since last purchase
        COUNT(DISTINCT order_id) AS Frequency,                     -- Total number of orders
        SUM(amount) AS Monetary                                    -- Total spending
    FROM ecommerce_orders
    GROUP BY customer_id
),

RFM_Scored AS (
    SELECT
        customer_id,
        Recency,
        Frequency,
        Monetary,
        NTILE(5) OVER (ORDER BY Recency DESC) AS R_Score,    -- Lower recency = higher score
        NTILE(5) OVER (ORDER BY Frequency ASC) AS F_Score,   -- Higher frequency = higher score
        NTILE(5) OVER (ORDER BY Monetary ASC) AS M_Score     -- Higher monetary = higher score
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
SELECT *
FROM Customer_Segmented
ORDER BY customer_id
```

### 🔍 Summary of the RFM SQL Logic

- **Set Analysis Date:** Use the day after the latest order to measure Recency.
- **Calculate RFM (RFM_CTE):**
  - `Recency` = Days since last purchase  
  - `Frequency` = Number of orders  
  - `Monetary` = Total spending  
- **Score R, F, M (RFM_Scored):**  
  Use `NTILE(5)` to assign scores from 1–5.

  **Segmentation Rules:**
  - **555 → Champions**
  - **High R & High F → Loyal Customers**
  - **High R but lower F → Potential Loyalists**
  - **Low R & High F → At Risk**
  - **Low R & Low F → Lost Customers**
  - R and F reflect the customer's actual behavior (how often they buy and how recently they returned), while M only represents the **transaction value**, which can fluctuate significantly and does not indicate engagement or loyalty.


- **Segment Customers (Customer_Segmented):**  
  Based on RFM scores → **Champions, Loyal Customers, Potential Loyalists, At Risk, Lost**.
- **Return Final Table:**  
  Includes RFM values, RFM score, and customer segment.

  <img width="1546" height="714" alt="image" src="https://github.com/user-attachments/assets/e280d8e8-81dc-4c88-af9e-dd7df2e47953" />

  ## 🔍 **INSIGHTS from RFM Analysis**

### 🏆 **Champions – Best Customers**
- Most recent transactions (low Recency)
- High purchasing frequency
- High total spending
- 👉 Should receive **exclusive offers, personalized campaigns, and strong retention strategies**

### 🫶 **Loyal Customers**
- High Frequency, good Recency and Monetary levels
- 👉 Ideal for **Upsell & increasing Average Order Value**

### 🧨 **At Risk Customers**
- Haven’t returned for a long time, medium spending
- 👉 Should receive **win-back promotions or reminder campaigns**

### ⚠️ **Lost Customers**
- Very old transactions, low frequency, low spending
- 👉 Can be **ignored or targeted with selective remarketing**

## 🎯 **Actionable Strategy**

| Segment     | Action Strategy |
|-------------|------------------|
| **Champions** | VIP offers, retention programs, appreciation campaigns |
| **Loyal**      | Upsell, upgrades, loyalty programs |
| **Potential**  | Limited-time promotions, incentives to encourage return |
| **At Risk**    | Reminder emails, win-back discounts |
| **Lost**       | Remarketing or shifting focus to other segments |


## Calculate Customer Lifetime Value (CLV)

# Steps to Calculate CLV in SQL

## 1. Total Customers (`Total_Customers`)
- Count unique customers to calculate relative purchase frequency.

## 2. Calculate CLV per Customer (`CLV_Calc`)
- Use `Customer_Segmented` (RFM + customer segment).

**Key metrics:**
- `avg_order_value` = Monetary / Frequency  
- `purchase_frequency` = Frequency / Total_Customers  
- `CLV` = avg_order_value * purchase_frequency

```sql
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
```
<img width="1546" height="541" alt="image" src="https://github.com/user-attachments/assets/db023610-19b7-487b-a08c-6837f20ebd7d" />

## 📊 INSIGHTS from CLV Analysis

### 💰 Who are the most valuable customers?

- **Champions** group has the highest CLV (~$8–9)  
- Customers with **high purchase frequency and high order value** are the "golden" ones

### ⚠️ Who are the potential but underutilized customers?

- **Potential** group has fairly high order value (~$240–250) but low frequency → Can trigger repeat purchases  
- **Strategy:** Offer vouchers or incentives to encourage early repeat purchases

### 🧨 Who are the hard-to-engage customers?

- **At Risk** group has low CLV + low frequency → Requires selective remarketing
