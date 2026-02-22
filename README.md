# 📊 Bank Marketing Campaign – Term Deposit Prediction

## 📌 Project Overview
This project analyzes the **Bank Marketing Campaign dataset** to understand customer behavior and predict subscription to term deposits.  
The workflow includes **data cleaning, feature engineering, exploratory data analysis (EDA), and hypothesis testing** using **SAS programming**.

---

## 🎯 Objectives
- Handle missing values and inconsistencies in categorical and numeric variables.
- Apply **mode imputation** for categorical features and **median imputation** for age.
- Cap outliers in variables such as balance, duration, campaign, and previous contacts.
- Perform **EDA** to explore relationships between customer attributes and deposit subscription.
- Engineer new features (e.g., Age Group, Job Simplification, Loan Indicators, Contact History).
- Test hypotheses on factors influencing customer subscription decisions.

---

## 🛠️ Tools & Techniques
- **SAS Studio** – Data preparation, statistical analysis, and visualization.
- **PROC FREQ, PROC MEANS, PROC CORR** – Frequency analysis, summary statistics, and correlation.
- **Feature Engineering** – Age grouping, job simplification, log transformations, loan indicators, contact history.
- **Hypothesis Testing** – Chi-square tests for categorical associations with deposit subscription.

---

## 📂 Key Steps
1. **Data Cleaning**
   - Mode imputation for categorical variables (`job`, `housing`, `education`).
   - Median imputation for missing ages.
   - Outlier capping for balance, duration, campaign, pdays, and previous contacts.

2. **Exploratory Data Analysis (EDA)**
   - Correlation matrix for numeric variables.
   - Boxplots comparing numeric features against deposit subscription.
   - Chi-square tests for categorical features vs target variable.

3. **Feature Engineering**
   - Age groups: Young, Middle, Senior.
   - Simplified job categories (Manual/Service, Professional, Non-Employed, Owner).
   - Loan indicator (`Has_Loan`).
   - Contact history (`contacted_before`, `total_contacts`).
   - Log transformation for balance to reduce skewness.

4. **Hypothesis Testing**
   - Age group affects subscription.
   - Marital status influences subscription.
   - Previous contact increases likelihood of subscription.
   - Total contacts impact subscription rates.
   - Loan status affects subscription.
   - Job type influences subscription.

---

## ✅ Outcomes
- Cleaned and prepared dataset for predictive modelling.
- Identified key customer attributes influencing deposit subscription.
- Generated actionable insights for marketing strategies:
  ## 🔑 Key Insights from Analysis
  - 📊 **Age Group** → Younger customers are most likely to subscribe.  
  - 💍 **Marital Status** → Singles show the highest subscription rates.  
  - 📞 **Contact History** → Previously contacted customers are far more likely to subscribe.  
  - 🔄 **Total Contacts** → More contacts slightly increase likelihood, but prior contact matters more.  
  - 💳 **Loan Status** → Customers with loans are less likely to subscribe.  
  - 👔 **Job Type** → Professionals and non-employed groups subscribe more; manual/service and self-employed groups subscribe less.  

---

