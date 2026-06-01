# ==============================================================================
# Project: R-Based Forecasting Project Using TÜİK Data
# Script: plots.R
# Purpose: Generate and save exploratory and final forecast plots under outputs/figures/
# Author: Rabia Erkış
# ==============================================================================

library(forecast)

# Veriyi projenin hafızasından tekrar çağırıyoruz
tourism_ts_clean <- forecast::na.interp(tourism_ts)
fig_dir <- "outputs/figures/"

cat("--- Generating Actual Series Plot ---\n")
png(filename = paste0(fig_dir, "actual_series_plot.png"), width = 800, height = 500)
plot(tourism_ts_clean, 
     main = "Quarterly Departing Visitors from Turkey (2012 - 2026)",
     xlab = "Year", ylab = "Number of Visitors", col = "darkblue", lwd = 2, type = "b")
grid()
dev.off()

cat("--- Generating Superior Model (WMA) Forecast Plot ---\n")
# Kazanan Ağırlıklı Hareketli Ortalama modelinin tahmin değerini serinin sonuna ekleyip çizdiriyoruz
next_forecast_val <- 3081775
extended_series <- ts(c(as.numeric(tourism_ts_clean), next_forecast_val), start = start(tourism_ts_clean), frequency = 4)

png(filename = paste0(fig_dir, "final_forecast_plot.png"), width = 800, height = 500)
plot(tourism_ts_clean, xlim = c(2012, 2027), ylim = c(0, max(extended_series) * 1.1),
     main = "Final Forecast for 2026 Q2 Using Superior WMA Method",
     xlab = "Year", ylab = "Number of Visitors", col = "darkblue", lwd = 2, type = "b")
# Tahmin noktasını kırmızı bir yıldızla işaretleyelim
points(2026.25, next_forecast_val, col = "red", pch = 19, cex = 2)
lines(c(2026.0, 2026.25), c(tail(tourism_ts_clean, 1), next_forecast_val), col = "red", lwd = 2, lty = 2)
text(2026.25, next_forecast_val, labels = " 2026 Q2 Forecast\n (3,081,775)", pos = 3, col = "red", font = 2)
grid()
dev.off()

cat("All plots successfully saved to outputs/figures/ folder!\n")