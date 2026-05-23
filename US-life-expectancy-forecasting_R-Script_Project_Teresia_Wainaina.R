# ================================================

# Time Series Forecast of U.S. Life Expectancy & Age-Adjusted Death Rates
# Teresia Wainaina | Master of Science in Business Analytics
# 
# ================================================
setwd("C:/Users/Teresia/OneDrive - The University of South Dakota/SEM 3 2026/DSCI 725-DM for CA/Project DM")
getwd()

# 1. CREATE OUTPUT FOLDER (all results will be saved here)
output_dir <- "DSCI725_Project_Output"
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
  cat("✅ Created output folder:", output_dir, "\n")
} else {
  cat("✅ Output folder already exists:", output_dir, "\n")
}

# All files will be saved with full path: output_dir/filename

# Install & load packages (run once)
install.packages(c("readr", "dplyr", "forecast", "ggplot2", "tseries", "flextable", "officer"), quiet = TRUE)
library(readr)
library(dplyr)
library(forecast)
library(ggplot2)
library(tseries)
library(flextable)
library(officer)

# Function to save flextable outputs
save_ft <- function(ft, filename) {
  save_as_docx(ft, path = file.path(output_dir, paste0(filename, ".docx")))
  save_as_html(ft, path = file.path(output_dir, paste0(filename, ".html")))
}

cat("✅ Packages loaded. Starting full project pipeline...\n\n")

# ================================================
# WEEK 11: Data Acquisition & Cleaning + EDA
# ================================================

data_raw <- read_csv("NCHS_-_Death_rates_and_life_expectancy_at_birth.csv")

national <- data_raw %>%
  filter(Race == "All Races", Sex == "Both Sexes") %>%
  select(Year, 
         Life_Expectancy = `Average Life Expectancy (Years)`,
         Death_Rate = `Age-adjusted Death Rate`)

life_ts  <- ts(national$Life_Expectancy, start = 1900, frequency = 1)
death_ts <- ts(national$Death_Rate,      start = 1900, frequency = 1)

# Save cleaned data
save(life_ts, death_ts, national, 
     file = file.path(output_dir, "DSCI725_Cleaned_Data.RData"))

# EDA tables
eda_life <- data.frame(
  Statistic = c("Min", "Q1", "Median", "Mean", "Q3", "Max", "SD"),
  Value = c(min(life_ts), quantile(life_ts, 0.25), median(life_ts),
            mean(life_ts), quantile(life_ts, 0.75), max(life_ts), sd(life_ts))
) %>% flextable() %>% set_caption("Summary Statistics – Life Expectancy (1900–2018)")

eda_death <- data.frame(
  Statistic = c("Min", "Q1", "Median", "Mean", "Q3", "Max", "SD"),
  Value = c(min(death_ts), quantile(death_ts, 0.25), median(death_ts),
            mean(death_ts), quantile(death_ts, 0.75), max(death_ts), sd(death_ts))
) %>% flextable() %>% set_caption("Summary Statistics – Death Rate (1900–2018)")

eda_life
eda_death

save_ft(eda_life, "eda_life_expectancy")
save_ft(eda_death, "eda_death_rate")

# EDA plots
p1 <- autoplot(life_ts) + ggtitle("U.S. Life Expectancy at Birth (1900–2018)") + ylab("Years") + theme_minimal()
p2 <- autoplot(death_ts) + ggtitle("U.S. Age-Adjusted Death Rate (1900–2018)") + ylab("Deaths per 100,000") + theme_minimal()

print(p1)
print(p2)

# Export EDA plots
ggsave(file.path(output_dir, "life_expectancy_eda.png"), p1, width = 10, height = 6, dpi = 300)
ggsave(file.path(output_dir, "death_rate_eda.png"),     p2, width = 10, height = 6, dpi = 300)

cat("✅ Week 11 complete – files saved in", output_dir, "\n")

# ================================================
# WEEK 12: Data Splitting + Stationarity + Decomposition
# ================================================

train_life  <- window(life_ts,  end = 2009)
test_life   <- window(life_ts,  start = 2010)
train_death <- window(death_ts, end = 2009)
test_death  <- window(death_ts, start = 2010)

# ADF Table (from your exact run)
adf_table <- data.frame(
  Series                    = c("Life Expectancy", "Age-Adjusted Death Rate"),
  `Dickey-Fuller Statistic` = c(-2.2371, -1.6572),
  Lag                       = c(4, 4),
  `p-value`                 = c(0.4783, 0.7188),
  Interpretation            = c("Non-stationary – differencing required",
                                "Non-stationary – differencing required")
) %>% flextable() %>% set_caption("Augmented Dickey-Fuller Test (Training Data 1900–2009)")

adf_table

save_ft(adf_table, "adf_test_results")

# Differencing
diff_life_train  <- diff(train_life, differences = 1)
diff_death_train <- diff(train_death, differences = 1)

# Decomposition (5-year MA trend for annual data)
trend_life  <- ma(life_ts,  order = 5, centre = TRUE)
trend_death <- ma(death_ts, order = 5, centre = TRUE)

p_decomp_life <- autoplot(life_ts, series = "Observed") +
  autolayer(trend_life, series = "Trend (5-yr MA)") +
  ggtitle("Decomposition – Life Expectancy") + ylab("Years") + theme_minimal()

p_decomp_death <- autoplot(death_ts, series = "Observed") +
  autolayer(trend_death, series = "Trend (5-yr MA)") +
  ggtitle("Decomposition – Death Rate") + ylab("Deaths per 100,000") + theme_minimal()

print(p_decomp_life)
print(p_decomp_death)

# Export decomposition plots
ggsave(file.path(output_dir, "decomposition_life.png"), p_decomp_life, width = 10, height = 6, dpi = 300)
ggsave(file.path(output_dir, "decomposition_death.png"), p_decomp_death, width = 10, height = 6, dpi = 300)

save(train_life, test_life, train_death, test_death, trend_life, trend_death,
     file = file.path(output_dir, "DSCI725_Split_Data.RData"))

cat("✅ Week 12 complete – files saved in", output_dir, "\n")

# ================================================
# WEEK 13: ACF/PACF + Model Development + Tuning
# ================================================

# ACF/PACF
# TRAINING ACF/PACF
png(file.path(output_dir, "acf_pacf_training.png"), width = 1200, height = 900)

par(
  mfrow = c(2,2),
  mar = c(5,5,4,2),   # bigger margins (bottom, left, top, right)
  oma = c(0,0,3,0)    # outer margin for main title
)

Acf(train_life, main = "ACF: Life Expectancy (Training)")
Pacf(train_life, main = "PACF: Life Expectancy (Training)")
Acf(train_death, main = "ACF: Death Rate (Training)")
Pacf(train_death, main = "PACF: Death Rate (Training)")

mtext("ACF & PACF – Training Data (1900–2009)", outer = TRUE, cex = 1.5, font = 2)

dev.off()

# DIFFERENCED ACF/PACF
png(file.path(output_dir, "acf_pacf_differenced.png"), width = 1200, height = 900)

par(
  mfrow = c(2,2),
  mar = c(5,5,4,2),
  oma = c(0,0,3,0)
)

Acf(diff_life_train, main = "ACF: Differenced Life Expectancy")
Pacf(diff_life_train, main = "PACF: Differenced Life Expectancy")
Acf(diff_death_train, main = "ACF: Differenced Death Rate")
Pacf(diff_death_train, main = "PACF: Differenced Death Rate")

mtext("ACF & PACF – Differenced Series", outer = TRUE, cex = 1.5, font = 2)

dev.off()

# Models
fit_naive_life  <- naive(train_life,  h = length(test_life))
fit_naive_death <- naive(train_death, h = length(test_death))

fit_arima_life  <- auto.arima(train_life,  d = 1, stepwise = TRUE, approximation = FALSE)
fit_arima_death <- auto.arima(train_death, d = 1, stepwise = TRUE, approximation = FALSE)

fit_ets_life    <- ets(train_life)
fit_ets_death   <- ets(train_death)

fit_tslm_life   <- tslm(train_life ~ trend)
fit_tslm_death  <- tslm(train_death ~ trend)

# Validation forecasts
fc_naive_life  <- forecast(fit_naive_life,  h = length(test_life))
fc_arima_life  <- forecast(fit_arima_life,  h = length(test_life))
fc_ets_life    <- forecast(fit_ets_life,    h = length(test_life))
fc_tslm_life   <- forecast(fit_tslm_life,   h = length(test_life))

fc_naive_death <- forecast(fit_naive_death, h = length(test_death))
fc_arima_death <- forecast(fit_arima_death, h = length(test_death))
fc_ets_death   <- forecast(fit_ets_death,   h = length(test_death))
fc_tslm_death  <- forecast(fit_tslm_death,  h = length(test_death))

save(fit_naive_life, fit_arima_life, fit_ets_life, fit_tslm_life,
     fit_naive_death, fit_arima_death, fit_ets_death, fit_tslm_death,
     fc_naive_life, fc_arima_life, fc_ets_life, fc_tslm_life,
     fc_naive_death, fc_arima_death, fc_ets_death, fc_tslm_death,
     file = file.path(output_dir, "DSCI725_Models_Week13.RData"))

cat("✅ Week 13 complete – files saved in", output_dir, "\n")

# ================================================
# WEEK 14: Evaluation, Residuals, Forecast, Visualization + Exports
# ================================================


# FIXED Accuracy Table Function (uses forecast objects for test accuracy)
create_accuracy_table <- function(train_actual, test_actual, 
                                  fc_naive, fc_arima, fc_ets, fc_tslm, 
                                  series_name) {
  
  acc_naive_test <- accuracy(fc_naive, test_actual)
  acc_arima_test <- accuracy(fc_arima, test_actual)
  acc_ets_test   <- accuracy(fc_ets,   test_actual)
  acc_tslm_test  <- accuracy(fc_tslm,  test_actual)
  
  train_naive <- accuracy(naive(train_actual))
  train_arima <- accuracy(fc_arima$model)
  train_ets   <- accuracy(fc_ets$model)
  train_tslm  <- accuracy(fc_tslm$model)
  
  table_data <- data.frame(
    Model        = c("Naïve", "ARIMA", "ETS", "TSLM"),
    `Train RMSE` = c(round(train_naive["Training set","RMSE"], 3),
                     round(train_arima["Training set","RMSE"], 3),
                     round(train_ets["Training set","RMSE"], 3),
                     round(train_tslm["Training set","RMSE"], 3)),
    `Train MASE` = c(round(train_naive["Training set","MASE"], 3),
                     round(train_arima["Training set","MASE"], 3),
                     round(train_ets["Training set","MASE"], 3),
                     round(train_tslm["Training set","MASE"], 3)),
    `Val RMSE`   = c(round(acc_naive_test["Test set","RMSE"], 3),
                     round(acc_arima_test["Test set","RMSE"], 3),
                     round(acc_ets_test["Test set","RMSE"], 3),
                     round(acc_tslm_test["Test set","RMSE"], 3)),
    `Val MASE`   = c(round(acc_naive_test["Test set","MASE"], 3),
                     round(acc_arima_test["Test set","MASE"], 3),
                     round(acc_ets_test["Test set","MASE"], 3),
                     round(acc_tslm_test["Test set","MASE"], 3))
  )
  
  flextable(table_data) %>%
    set_caption(paste("Model Accuracy –", series_name, "(Training vs Validation 2010–2018)")) %>%
    bold(j = 1) %>% autofit()
}

acc_life <- create_accuracy_table(train_life, test_life,
                                  fc_naive_life, fc_arima_life, fc_ets_life, fc_tslm_life,
                                  "U.S. Life Expectancy at Birth")
acc_death <- create_accuracy_table(train_death, test_death,
                                   fc_naive_death, fc_arima_death, fc_ets_death, fc_tslm_death,
                                   "U.S. Age-Adjusted Death Rate")

acc_life
acc_death

save_ft(acc_life, "model_accuracy_life")
save_ft(acc_death, "model_accuracy_death")

# Residual Diagnostics
checkresiduals(fit_arima_life,  main = "Residual Diagnostics – Life Expectancy (ARIMA)")
checkresiduals(fit_arima_death, main = "Residual Diagnostics – Death Rate (ARIMA)")

# 20-Year Forecast Table
h_forecast <- 20
fc_long_life  <- forecast(fit_arima_life,  h = h_forecast)
fc_long_death <- forecast(fit_arima_death, h = h_forecast)

forecast_table <- data.frame(
  Year               = 2019:2038,
  `Life Expectancy`  = round(fc_long_life$mean, 1),
  `Lower 80%`        = round(fc_long_life$lower[,1], 1),
  `Upper 80%`        = round(fc_long_life$upper[,1], 1),
  `Death Rate`       = round(fc_long_death$mean, 1),
  `Lower 80%`        = round(fc_long_death$lower[,1], 1),
  `Upper 80%`        = round(fc_long_death$upper[,1], 1)
) %>% flextable() %>% set_caption("20-Year Ahead Forecast (2019–2038) – Best ARIMA Models")

forecast_table

save_ft(forecast_table, "20_year_forecast")

# Model Comparison Plots
p_life <- autoplot(life_ts, series = "Observed") +
  autolayer(fitted(fit_arima_life), series = "ARIMA (Best)") +
  autolayer(fc_long_life, series = "ARIMA Forecast") +
  autolayer(fc_naive_life, series = "Naïve") +
  autolayer(fc_ets_life, series = "ETS") +
  autolayer(fc_tslm_life, series = "TSLM") +
  ggtitle("Life Expectancy – Model Comparison & 20-Year Forecast") +
  ylab("Years") + xlab("Year") + theme_minimal() + theme(legend.position = "bottom")

p_death <- autoplot(death_ts, series = "Observed") +
  autolayer(fitted(fit_arima_death), series = "ARIMA (Best)") +
  autolayer(fc_long_death, series = "ARIMA Forecast") +
  autolayer(fc_naive_death, series = "Naïve") +
  autolayer(fc_ets_death, series = "ETS") +
  autolayer(fc_tslm_death, series = "TSLM") +
  ggtitle("Death Rate – Model Comparison & 20-Year Forecast") +
  ylab("Deaths per 100,000") + xlab("Year") + theme_minimal() + theme(legend.position = "bottom")

print(p_life)
print(p_death)

# Export ALL visualizations to the output folder
ggsave(file.path(output_dir, "life_expectancy_model_comparison.png"), p_life,  width = 10, height = 6, dpi = 300)
ggsave(file.path(output_dir, "death_rate_model_comparison.png"),     p_death, width = 10, height = 6, dpi = 300)

png(file.path(output_dir, "residuals_life.png"),  width = 800, height = 600)
checkresiduals(fit_arima_life)
dev.off()

png(file.path(output_dir, "residuals_death.png"), width = 800, height = 600)
checkresiduals(fit_arima_death)
dev.off()

# Save final results
save.image(file.path(output_dir, "DSCI725_Full_Project_Objects.RData"))

cat("\n🎉 FULL PROJECT COMPLETE!\n")
cat("✅ All tables, plots, and RData files saved in folder:", output_dir, "\n")
cat("Files created:\n")
list.files(output_dir, full.names = TRUE)

write.csv(national, file.path(output_dir, "cleaned_dataset.csv"), row.names = FALSE)

forecast_df <- data.frame(
  Year = 2019:2038,
  Life_Expectancy = fc_long_life$mean,
  Death_Rate = fc_long_death$mean
)

write.csv(forecast_df, file.path(output_dir, "forecast_values.csv"), row.names = FALSE)





