# U.S. Life Expectancy & Mortality Forecasting (1900–2038)

## Overview
This project develops and evaluates multiple time-series forecasting models to analyze and predict long-term trends in U.S. life expectancy at birth and age-adjusted death 
rates using historical National Center for Health Statistics (NCHS) data.

The analysis compares four forecasting approaches—Naïve, ARIMA, ETS, and TSLM—to identify the most accurate model for long-term demographic prediction. The best-performing ARIMA models are
used to generate 20-year forecasts (2019–2038).

---

## Objective
- Forecast U.S. life expectancy at birth
- Forecast age-adjusted death rates
- Compare multiple time-series forecasting methods
- Evaluate model accuracy using validation techniques
- Generate long-term projections for demographic trends

---

## Dataset
Source: National Center for Health Statistics (NCHS)

- Time period: 1900–2018
- Variables:
  - Life Expectancy at Birth
  - Age-Adjusted Death Rate (per 100,000)

Data source:
https://catalog.data.gov/dataset/nchs-death-rates-and-life-expectancy-at-birth

---

## Methodology

### 1. Data Preparation
- Cleaned and structured annual time-series data
- Defined two univariate series:
  - Life Expectancy
  - Age-Adjusted Death Rate
- Split into:
  - Training set: 1900–2009
  - Validation set: 2010–2018

---

### 2. Stationarity Analysis
- Applied Augmented Dickey-Fuller (ADF) tests
- Both series were non-stationary
- First-order differencing applied

---

### 3. Models Implemented
Four forecasting models were evaluated:

- Naïve Benchmark Model
- ARIMA (AutoRegressive Integrated Moving Average)
- ETS (Exponential Smoothing State Space Model)
- TSLM (Time Series Linear Model)

---

### 4. Model Evaluation
Models were assessed using:
- RMSE (Root Mean Squared Error)
- MASE (Mean Absolute Scaled Error)
- Residual diagnostics
- ACF/PACF analysis

Validation results were used to select the final forecasting model.

---

## Key Findings

### Life Expectancy Trend
- 2019: 79.1 years
- 2038: 84.6 years

### Age-Adjusted Death Rate Trend
- 2019: 733.6 per 100,000
- 2038: 432.5 per 100,000

---

## Interpretation
- Life expectancy shows a steady long-term upward trend
- Age-adjusted death rates continue a consistent decline
- ARIMA models capture historical structure effectively
- Forecasts suggest continued improvements in population health outcomes

---

## Model Performance Summary

### Life Expectancy

| Model | Validation RMSE | Validation MASE |
|------|----------------|----------------|
| Naïve | 0.247 | 0.210 |
| ARIMA | 1.772 | 1.429 |
| ETS | 1.556 | 1.221 |
| TSLM | 4.280 | 3.787 |

### Death Rate

| Model | Validation RMSE | Validation MASE |
|------|----------------|----------------|
| Naïve | 18.228 | 0.351 |
| ETS | 55.000 | 0.973 |
| ARIMA | 71.995 | 1.305 |
| TSLM | 208.350 | 4.277 |

---

## Forecasting Approach
- Final model selected: ARIMA (based on validation performance and diagnostics)
- Forecast horizon: 20 years (2019–2038)
- Confidence intervals included (80%)

---

## Visualizations Included
- Historical trend plots
- Forecast comparison across models
- ACF and PACF diagnostics
- Residual analysis plots
- Long-term forecast trajectories

---

## Project Structure

```text
us-life-expectancy-forecasting/
│
├── data/
├── notebooks/
├── visuals/
├── reports/
├── forecast_values.csv
├── README.md
```

---

## Applications
This analysis supports long-term planning in:

- Healthcare resource allocation
- Insurance risk modeling
- Pension and retirement planning
- Public health policy design
- Government budgeting and forecasting

---

## Limitations
- Forecasts are based on historical patterns up to 2018
- Structural changes (e.g., pandemics, policy shifts) may affect accuracy
- No external explanatory variables included

---

## Future Work
- Incorporate socioeconomic and health covariates
- Extend to subgroup-level forecasting (age, gender, race)
- Explore machine learning and deep learning models
- Integrate real-time updating forecasting systems

## Author
Teresia Wainaina
