TÜİK Forecasting Project

1. Project Overview

This project presents an automated, reproducible, and rigorous quantitative time-series forecasting pipeline built to analyze and predict tourism demand returns in Turkey. Utilizing official macroeconomic time-series data from the Turkish Statistical Institute (TÜİK), this study implements, evaluates, and competes ten diverse quantitative forecasting methods. The objective is to forecast the returning citizens' mobility patterns into Turkey, ensuring robust decision-making and strategic alignment for transportation planning, macroeconomic budgeting, and civil hospitality industries.

2. Data Source and TÜİK Connection

All historical observations were dynamically retrieved from the TÜİK Data Portal API using the R wrapper package tuikr. This programmatic connection guarantees complete data integrity and reproducibility, completely avoiding any manual file downloads, manual edits, or external spreadsheet handling.

TÜİK Data Set Name: Tourism Statistics / Number of Arriving Citizens 

TÜİK Theme/Category: Tourism (Theme 14)

TÜİK Table Name: Arriving Citizens by Purpose of Visit

TÜİK Dataflow ID: Dynamically retrieved via tuikr::statistical_tables(theme = 14)

Selected Variable: Total Number of Arriving Citizens (computed programmatically by aggregating trip purposes)

Data Frequency: Quarterly (4 observations per fiscal year)

Time Coverage: 2012 Q1 – 2026 Q1 (57 consecutive quarters)

Latest Available Observation: 2,936,279 citizens (2026 Q1 - January–March 2026)

Forecast Target Period: 2026 Q2 (April–June 2026)

Date of Data Access: 2026-06-02

R Package Used for Data Access: tuikr

Package Source: https://github.com/emraher/tuikr

3. Research Objective

The variable being forecasted is the Total Number of Arriving Citizens back to Turkey on a quarterly basis. In the field of Management Information Systems (MIS) and macroeconomics, understanding outbound-inbound citizens' return velocity is highly meaningful for:

Infrastructure Budgeting: Ensuring adequate capacity at border gates, international airports, and custom security checkpoints.

Transportation Logistics: Optimization of flight scheduling, national railway runs, and highway transit load management during peak periods.

Foreign Exchange Reserves Planning: Estimating average resident expenditure patterns and returning currency velocity to assist central banking predictions.

4. Use of TÜİK Data in R

The data imported via tuikr was regulated directly inside R for quantitative forecasting. No manual pre-processing was conducted.

Temporal Setup: The raw tabular outputs were converted into a continuous quarterly time-series object (ts_data) starting in 2012 Q1 with a frequency of 4.

R-Based Structural Adjustment: Due to the hierarchical nature of TÜİK's spreadsheet tables, structural year constraints were filled down programmatically across quarterly rows using the vector operation tidyr::fill().

Imputation of Pandemic Shock: The historical observations for 2020 Q2 contained structural missingness ($NA$) due to international border closures during the COVID-19 pandemic. To prevent downstream algorithmic bias and maintain structural seasonal indices, a robust seasonally-aware interpolation was executed using forecast::na.interp(), successfully reconstructing the baseline timeline.

5. Exploratory Time Series Analysis

A comprehensive exploratory analysis of the processed series reveals three dominant components:

Trend: A strong, long-term linear upward trend representing the steady integration of Turkish citizens into global travel and rising disposable household incomes over the last decade.

Seasonality: High, deterministic seasonality is present. Arriving citizen volume systematically peaks during the third quarter (Q3 - Summer vacation season) due to academic holidays and annual leaves, while hitting its local minimums in the first quarter (Q1 - Winter season).

Structural Break: The severe drop in 2020 Q2 acts as an external economic shock, which represents an artificial intervention on the baseline growth curve rather than a typical cyclical shift.

6. Forecasting Methods Applied

To secure maximum accuracy, ten distinct quantitative time-series models were successfully compiled and compared:

Naïve Forecasting: Applicable as a robust, random-walk baseline model.

Moving Average (MA, k=4): Applicable to smooth out local quarterly fluctuations using equal weights.

Weighted Moving Average (WMA): Applicable; assigns step-increasing weights ($0.1, 0.2, 0.3, 0.4$) to favor recent observation velocities.

Exponential Smoothing (SES): Applicable but structurally struggles with series containing strong linear trends.

Trend-Adjusted Exponential Smoothing (Holt's Linear): Applicable due to the visible upward linear trend.

Linear Trend Projection: Applicable using ordinary least squares (OLS) regression over a chronological time index.

Seasonal Indices: Applicable due to the high seasonality index of quarterly tourism.

Additive Decomposition: Applicable to isolate seasonal trends, assuming a constant seasonal amplitude.

Multiplicative Decomposition: Applicable as seasonal amplitude variations scale alongside the overall trend level.

Regression with Trend and Seasonal Dummy Variables: Applicable using OLS with deterministic quarterly dummies and a time-trend variable.

7. Forecast Accuracy Comparison

All models were trained on the historical baseline (2012 Q1 - 2025 Q1) and evaluated out-of-sample against the test partition (2025 Q2 - 2026 Q1). The empirical accuracy comparison is presented below:

Method

Bias

MAD

MSE

MAPE (%)

RSFE

Tracking Signal

Next-Period Forecast (2026 Q2)

Naïve Forecasting

435,532

435,532

$2.55 \times 10^{11}$

14.84

1,742,126

4.00

2,936,279

Moving Average (k=4)

140,563

163,551

$3.46 \times 10^{10}$

5.39

562,253

3.44

3,059,352

Weighted Moving Average

83,912

104,821

$\mathbf{1.62 \times 10^{10}}$

3.53

257,810

2.46

3,081,775

Exponential Smoothing

435,528

435,528

$2.55 \times 10^{11}$

14.84

1,742,112

4.00

2,936,282

Trend-Adjusted Exponential

239,812

251,404

$7.82 \times 10^{10}$

8.77

959,248

3.82

3,009,797

Linear Trend Projection

-862,114

862,114

$8.90 \times 10^{11}$

27.80

-3,448,456

-4.00

1,611,861

Seasonal Indices

-1,114,205

1,114,205

$1.41 \times 10^{12}$

36.19

-4,456,820

-4.00

2,082,442

Additive Decomposition

-858,402

858,402

$8.84 \times 10^{11}$

27.71

-3,433,608

-4.00

1,681,314

Multiplicative Decomposition

-857,910

857,910

$8.82 \times 10^{11}$

27.70

-3,431,640

-4.00

1,668,421

Regression with Seasonal Dummies

-861,405

861,405

$8.89 \times 10^{11}$

27.79

-3,445,620

-4.00

2,509,049

8. Selection of the Superior Method

The Weighted Moving Average (WMA) is selected as the superior forecasting method based on both quantitative metrics and theoretical suitability:

Quantitative Performance: WMA outperformed all other candidate models by achieving an incredibly low Mean Absolute Percentage Error (3.53% MAPE). Its Tracking Signal (2.46) is well within the acceptable control boundaries (between $-4.0$ and $+4.0$), demonstrating no systematic under-forecasting bias.

Theoretical Suitability: Long-term deterministic models (such as Linear Trend, Decomposition, and Seasonal Dummies Regression) suffered higher error rates (~27%). This is economically justified: the massive historical pandemic shock of 2020 permanently distorted the long-term OLS slope parameters and global seasonal constants. Since WMA utilizes a rolling boundary and assigns step-increasing weights ($0.1, 0.2, 0.3, 0.4$) favoring the most recent periods, it successfully isolates the post-pandemic recovery pace (2024–2026), filtering out historical anomalies.

9. Final Next-Period Forecast

Using the selected superior Weighted Moving Average model applied over the entire available dataset, the final projection is established:

Selected Superior Method: Weighted Moving Average (WMA)

Date of Data Access: 2026-06-02

Latest Available TÜİK Observation: 2,936,279 citizens (2026 Q1)

Forecast Target Period: 2026 Q2 (April–June 2026)

Forecasted Value: 3,081,775 returning citizens

10. Interpretation of Results

The forecasted value of 3,081,775 individuals returning to Turkey in 2026 Q2 represents a stable, robust continuation of Turkey’s post-pandemic travel growth. Statistically, this value projects an upward rise from the winter minimum of Q1 (2,936,279) as the weather warms and seasonal business/family commutes accelerate, confirming high traveler confidence and robust domestic consumption.

11. Limitations

Geopolitical Volatility: Regional political disputes, sudden aviation fuel crises, or currency fluctuations can instantly alter international travel habits.

Historical Structural Breaks: Retrospective models carry legacy biases from extreme black-swan events (such as the 2020 border shutdowns) which can skew OLS calculations unless localized smoothing is applied.

12. Reproducibility

The entire pipeline is fully automated and reproducible:

Clone this repository locally.

Open the project inside RStudio.

Run renv::restore() to automatically download and sync the exact R library versions.

Run the code inside forecasting_project.Rmd or click Knit to automatically pull real-time TÜİK data via API, execute all 10 models, update local tables under outputs/tables/, generate the 12 plots under outputs/figures/, and render the final HTML dashboard.

13. Repository Structure

tuik-forecasting-project/
├── README.md                           # Main GitHub documentation page (You are here)
├── forecasting_project.Rmd             # Primary R Markdown analysis notebook
├── forecasting_project.html            # Rendered HTML dashboard output
├── renv.lock                           # Package environment configuration lockfile
├── .gitignore                          # Excluded local system paths
├── R/
│   ├── data_import.R                   # API data extraction
│   ├── forecasting_methods.R           # Model workflows
│   └── plots.R                         # Code generating the 12 required figures
└── outputs/
    ├── tables/
    │   ├── accuracy_comparison.csv     # Model error metrics table
    │   └── final_forecast.csv          # Next-period forecast summary
    └── figures/
        ├── actual_series_plot.png
        ├── naive_forecast_plot.png
        ├── moving_average_plot.png
        ├── weighted_moving_average_plot.png
        ├── exponential_smoothing_plot.png
        ├── trend_adjusted_smoothing_plot.png
        ├── trend_projection_plot.png
        ├── seasonal_indices_plot.png
        ├── additive_decomposition_plot.png
        ├── multiplicative_decomposition_plot.png
        ├── regression_seasonal_dummy_plot.png
        └── superior_method_plot.png    # Final forecast visualization


14. Author

Student Name: Rabia Erkış

Student Number: 138723017


