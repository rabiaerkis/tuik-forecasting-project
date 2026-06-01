# ==============================================================================
# Project: R-Based Forecasting Project Using TÜİK Data
# Script: data_import.R
# Purpose: Dynamically search, fetch, clean, and transform the 
#          Quarterly Tourism data into a reproducible R time series object.
# Author: Rabia Erkış
# ==============================================================================

library(tuikr)
library(httr)
library(readxl)
library(dplyr)
library(tidyr)

cat("--- Step 1: Searching Catalog and Locating Target Table URL ---\n")

# 1. Tüm temaları tarayıp katalog oluşturuyoruz (Önceki başarılı arama adımımız)
all_themes_tables <- data.frame()
for(i in 1:14) {
  try({
    t <- tuikr::statistical_tables(theme = i)
    if(nrow(t) > 0) { all_themes_tables <- rbind(all_themes_tables, t) }
  }, silent = TRUE)
}

# 2. Katalog içinden nokta atışı "Purpose of Visit" tablomuzu yakalıyoruz
target_row <- all_themes_tables[grep("Purpose of Visit", all_themes_tables$table_name, ignore.case = TRUE), ]
target_url <- target_row$table_url[1]

cat("Target URL successfully retrieved dynamically!\n")

cat("--- Step 2: Fetching Data into Memory Buffer ---\n")

# 3. Sunucu engelini aşarak içeriği doğrudan binary akış olarak çekiyoruz
response <- httr::GET(
  target_url, 
  user_agent("Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
)

# 4. Gelen veriyi geçici bir Excel dosyasına yazıyoruz
temp_clean <- tempfile(fileext = ".xls")
writeBin(httr::content(response, "raw"), temp_clean)

# 5. Başlık karmaşasından kurtulmak için ilk 3 satırı atlayarak okuyoruz
raw_excel <- read_excel(temp_clean, sheet = 1, skip = 3)

cat("--- Step 3: R-Based Data Cleaning and Adjustments ---\n")

# 6. Hocanın istediği R-tabanlı temizlik ve forward-fill adımları
cleaned_data <- raw_excel %>%
  select(Yil_Ham = 1, Ceyrek = 2, Toplam = 3) %>%
  filter(!is.na(Ceyrek)) %>%
  mutate(Yil = ifelse(stringr::str_detect(Yil_Ham, "^[0-9]{4}$"), Yil_Ham, NA)) %>%
  fill(Yil, .direction = "down") %>%
  filter(Ceyrek %in% c("I", "II", "III", "IV")) %>%
  mutate(Toplam = as.numeric(Toplam)) %>%
  select(Yil, Ceyrek, Toplam) %>%
  arrange(Yil, Ceyrek)

# Çeyrekleri numerik formata getiriyoruz
cleaned_data <- cleaned_data %>%
  mutate(Ceyrek_Num = case_when(
    Ceyrek == "I"   ~ 1,
    Ceyrek == "II"  ~ 2,
    Ceyrek == "III" ~ 3,
    Ceyrek == "IV"  ~ 4
  ))

# Temiz verinin ilk 12 satırını konsola basalım
print(head(cleaned_data, 12))

cat("--- Step 4: Transforming into Time Series (ts) Object ---\n")

# 7. İlk gözlem tarihini dinamik alıp resmi çeyreklik zaman serimizi kuruyoruz
start_year <- as.numeric(cleaned_data$Yil[1])
start_quarter <- cleaned_data$Ceyrek_Num[1]

tourism_ts <- ts(cleaned_data$Toplam, start = c(start_year, start_quarter), frequency = 4)

# Nihai zaman serisi matrisini ekranda görelim
print(tourism_ts)
