# **Retail Data Warehouse & SQL Analytics**

## 📌 **Project Overview**
This project builds a **Retail Data Warehouse** for comprehensive analytics using **SQL**. It consolidates data from multiple sources to provide insights into **revenue, customer behavior, product performance, and employee sales trends**.

## 🎯 **Business Problem Statement**
Retail businesses face challenges in **tracking revenue trends, identifying high-value customers, managing stock efficiently, and optimizing employee performance**. This project demonstrates how a **structured data warehouse** enables data-driven decision-making through SQL-based analytics.

## 📂 **Data Sources & Schema**
- **FactOrder**: Order transactions including employee, customer, shipping, and revenue details.
- **FactOrderDetails**: Order line items with pricing, discounts, and quantity.
- **FactProductStock**: Inventory data including stock levels and reorder information.
- **DimCustomer**: Customer details including segmentation and location.
- **DimProduct**: Product catalog information including category and supplier details.
- **DimEmployee**: Employee records for tracking sales performance.
- **DimCategories**: Product category classification.

## 🛠 **Tech Stack & Tools**
- **SQL:** MySQL / MySQLWorkBench for **data modeling, ETL, and analysis**

## 🔍 **Key Business Insights**
This project includes SQL queries to analyze:

### **1️⃣ Revenue & Growth Trends**
- **Total Revenue & Monthly Sales Trend**: Identifies peak sales months and helps in demand forecasting.
- **Year-over-Year Revenue Growth Analysis**: Measures annual growth and identifies peak years.

### **2️⃣ Product Performance**
- **Top 5 Best-Selling Products**: Identifies high-performing products for inventory planning.
- **Most Consistently Selling Products (Low Volatility)**: Finds products with stable demand for consistent stocking.

### **3️⃣ Customer Analytics**
- **Customer Segmentation by Total Spend**: Classifies customers based on spending for targeted marketing.
- **Identifying High Churn Risk Customers**: Flags customers at risk of churn for proactive engagement.

### **4️⃣ Regional Sales Performance**
- **Sales Distribution by Region**: Helps allocate inventory and marketing resources by region.

### **5️⃣ Employee Performance Analytics**
- **Employee Sales Performance Over Time**: Tracks top-performing employees for incentives and training.

For detailed SQL queries, refer to the **queries.sql** file.

---
🚀 *This project showcases advanced SQL-driven analytics for retail business intelligence.*
