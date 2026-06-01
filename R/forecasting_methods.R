# ==============================================================================
# Project: R-Based Forecasting Project Using TÜİK Data
# Script: forecasting_methods.R
# Purpose: Apply 10 mandatory forecasting methods and compute all accuracy metrics
# Author: Rabia Erkış
# ==============================================================================

library(forecast)
library(dplyr)

cat("--- Step 1: Defining Accuracy and Tracking Signal Function ---\n")

# Hocanın istediği 7 zorunlu metrik ve izleme sinyalini hesaplayan fonksiyon
calculate_metrics <- function(actual, forecast_values) {
  errors <- actual - forecast_values
  
  bias <- mean(errors, na.rm = TRUE)
  mad <- mean(abs(errors), na.rm = TRUE)
  mse <- mean(errors^2, na.rm = TRUE)
  mape <- mean(abs(errors / actual), na.rm = TRUE) * 100
  rsfe <- sum(errors, na.rm = TRUE)
  
  tracking_signal <- if(mad == 0) { 0 } else { rsfe / mad }
  
  return(list(Bias = bias, MAD = mad, MSE = mse, MAPE = mape, RSFE = rsfe, TS = tracking_signal))
}

cat("--- Step 2: Preparing Data Split for Evaluation ---\n")
tourism_ts_clean <- forecast::na.interp(tourism_ts)

# Son 4 çeyreği (1 yılı) test/kıyaslama için ayırıyoruz
train_series <- window(tourism_ts_clean, end = c(2025, 1))
test_actuals <- window(tourism_ts_clean, start = c(2025, 2))
h_val <- length(test_actuals)

# Karşılaştırma tablosunu depolayacağımız boş matris
comparison_matrix <- data.frame(
  Method = c("Naïve Forecasting", "Moving Average", "Weighted Moving Average", 
             "Exponential Smoothing", "Trend-Adjusted Exponential Smoothing", 
             "Linear Trend Projection", "Seasonal Indices", "Additive Decomposition", 
             "Multiplicative Decomposition", "Regression with Trend and Seasonal Dummies"),
  Bias = NA, MAD = NA, MSE = NA, MAPE = NA, RSFE = NA, Tracking_Signal = NA, Next_Period_Forecast = NA
)

# ==============================================================================
# 1. Naïve Forecasting
# ==============================================================================
naive_model <- naive(train_series, h = h_val)
m1 <- calculate_metrics(test_actuals, naive_model$mean)
comparison_matrix[1, 2:7] <- c(m1$Bias, m1$MAD, m1$MSE, m1$MAPE, m1$RSFE, m1$TS)
comparison_matrix[1, 8] <- tail(naive(tourism_ts_clean, h = 1)$mean, 1)

# ==============================================================================
# 2. Moving Average (k = 4, Çeyreklik pencere)
# ==============================================================================
ma_fitted <- stats::filter(train_series, rep(1/4, 4), sides = 1)
ma_forecast <- rep(tail(ma_fitted[!is.na(ma_fitted)], 1), h_val)
m2 <- calculate_metrics(test_actuals, ma_forecast)
comparison_matrix[2, 2:7] <- c(m2$Bias, m2$MAD, m2$MSE, m2$MAPE, m2$RSFE, m2$TS)
comparison_matrix[2, 8] <- tail(stats::filter(tourism_ts_clean, rep(1/4, 4), sides = 1), 1)

# ==============================================================================
# 3. Weighted Moving Average
# ==============================================================================
weights <- c(0.1, 0.2, 0.3, 0.4)
wma_fitted <- stats::filter(train_series, weights, sides = 1)
wma_forecast <- rep(tail(wma_fitted[!is.na(wma_fitted)], 1), h_val)
m3 <- calculate_metrics(test_actuals, wma_forecast)
comparison_matrix[3, 2:7] <- c(m3$Bias, m3$MAD, m3$MSE, m3$MAPE, m3$RSFE, m3$TS)
comparison_matrix[3, 8] <- tail(stats::filter(tourism_ts_clean, weights, sides = 1), 1)

# ==============================================================================
# 4. Exponential Smoothing (Simple SES)
# ==============================================================================
ses_model <- ses(train_series, h = h_val)
m4 <- calculate_metrics(test_actuals, ses_model$mean)
comparison_matrix[4, 2:7] <- c(m4$Bias, m4$MAD, m4$MSE, m4$MAPE, m4$RSFE, m4$TS)
comparison_matrix[4, 8] <- tail(ses(tourism_ts_clean, h = 1)$mean, 1)

# ==============================================================================
# 5. Trend-Adjusted Exponential Smoothing (Holt's Linear)
# ==============================================================================
holt_model <- holt(train_series, h = h_val)
m5 <- calculate_metrics(test_actuals, holt_model$mean)
comparison_matrix[5, 2:7] <- c(m5$Bias, m5$MAD, m5$MSE, m5$MAPE, m5$RSFE, m5$TS)
comparison_matrix[5, 8] <- tail(holt(tourism_ts_clean, h = 1)$mean, 1)

# ==============================================================================
# 6. Linear Trend Projection
# ==============================================================================
time_train <- 1:length(train_series)
time_test <- (length(train_series) + 1):(length(train_series) + h_val)
lm_trend <- lm(train_series ~ time_train)
lm_forecast <- predict(lm_trend, newdata = data.frame(time_train = time_test))
m6 <- calculate_metrics(test_actuals, lm_forecast)
comparison_matrix[6, 2:7] <- c(m6$Bias, m6$MAD, m6$MSE, m6$MAPE, m6$RSFE, m6$TS)
lm_final <- lm(tourism_ts_clean ~ seq_along(tourism_ts_clean))
comparison_matrix[6, 8] <- predict(lm_final, newdata = data.frame(tourism_ts_clean = length(tourism_ts_clean) + 1))[1]

# ==============================================================================
# 7. Seasonal Indices
# ==============================================================================
decomp_indices <- decompose(train_series, type = "multiplicative")
seasonal_pattern <- decomp_indices$figure
m7_forecast <- rep(seasonal_pattern, length.out = h_val) * mean(train_series)
m7 <- calculate_metrics(test_actuals, m7_forecast)
comparison_matrix[7, 2:7] <- c(m7$Bias, m7$MAD, m7$MSE, m7$MAPE, m7$RSFE, m7$TS)
comparison_matrix[7, 8] <- seasonal_pattern[2] * mean(tourism_ts_clean)

# ==============================================================================
# 8. Additive Decomposition (Hatanın Çözüldüğü Kısım)
# ==============================================================================
add_decomp <- decompose(train_series, type = "additive")
# Trend bileşenindeki NA değerlerini enterpole edip doğrusal tahmin yapıyoruz
trend_clean <- na.interp(add_decomp$trend)
lm_add_trend <- lm(trend_clean ~ time_train)
trend_forecast <- predict(lm_add_trend, newdata = data.frame(time_train = time_test))
seasonal_forecast <- rep(add_decomp$seasonal, length.out = h_val)
# Trend + Mevsimsellik birleşimi
add_decomp_forecast <- trend_forecast + seasonal_forecast

m8 <- calculate_metrics(test_actuals, add_decomp_forecast)
comparison_matrix[8, 2:7] <- c(m8$Bias, m8$MAD, m8$MSE, m8$MAPE, m8$RSFE, m8$TS)

# Nihai 2026 Q2 tahmini
final_add_decomp <- decompose(tourism_ts_clean, type = "additive")
final_trend_clean <- na.interp(final_add_decomp$trend)
lm_final_trend <- lm(final_trend_clean ~ seq_along(tourism_ts_clean))
next_trend <- predict(lm_final_trend, newdata = data.frame(tourism_ts_clean = length(tourism_ts_clean) + 1))
comparison_matrix[8, 8] <- next_trend + final_add_decomp$seasonal[2]

# ==============================================================================
# 9. Multiplicative Decomposition (Hatanın Çözüldüğü Kısım)
# ==============================================================================
mult_decomp <- decompose(train_series, type = "multiplicative")
trend_mult_clean <- na.interp(mult_decomp$trend)
lm_mult_trend <- lm(trend_mult_clean ~ time_train)
trend_mult_forecast <- predict(lm_mult_trend, newdata = data.frame(time_train = time_test))
seasonal_mult_forecast <- rep(mult_decomp$seasonal, length.out = h_val)
# Trend * Mevsimsellik birleşimi
mult_decomp_forecast <- trend_mult_forecast * seasonal_mult_forecast

m9 <- calculate_metrics(test_actuals, mult_decomp_forecast)
comparison_matrix[9, 2:7] <- c(m9$Bias, m9$MAD, m9$MSE, m9$MAPE, m9$RSFE, m9$TS)

# Nihai 2026 Q2 tahmini
final_mult_decomp <- decompose(tourism_ts_clean, type = "multiplicative")
final_trend_mult_clean <- na.interp(final_mult_decomp$trend)
lm_final_mult_trend <- lm(final_trend_mult_clean ~ seq_along(tourism_ts_clean))
next_mult_trend <- predict(lm_final_mult_trend, newdata = data.frame(tourism_ts_clean = length(tourism_ts_clean) + 1))
comparison_matrix[9, 8] <- next_mult_trend * final_mult_decomp$seasonal[2]

# ==============================================================================
# 10. Regression with Trend and Seasonal Dummy Variables
# ==============================================================================
tslm_model <- tslm(train_series ~ trend + season)
tslm_forecast <- forecast(tslm_model, h = h_val)
m10 <- calculate_metrics(test_actuals, tslm_forecast$mean)
comparison_matrix[10, 2:7] <- c(m10$Bias, m10$MAD, m10$MSE, m10$MAPE, m10$RSFE, m10$TS)
tslm_final <- tslm(tourism_ts_clean ~ trend + season)
comparison_matrix[10, 8] <- tail(forecast(tslm_final, h = 1)$mean, 1)

# ==============================================================================
# Final Output Saving
# ==============================================================================
write.csv(comparison_matrix, "outputs/tables/accuracy_comparison.csv", row.names = FALSE)
cat("\n--- All 10 models evaluated successfully! Kıyaslama tablosu kaydedildi. ---\n")
print(comparison_matrix[, c("Method", "MAPE", "Tracking_Signal", "Next_Period_Forecast")])