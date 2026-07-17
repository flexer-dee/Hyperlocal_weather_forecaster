# ==============================================================================
# PHASE 4: TUNED SUPPORT VECTOR REGRESSION (SVR) FORECASTING
# ==============================================================================
library(tidyverse)
library(e1071)

# 1. Load the Calibrated Time-Series Dataset
calibrated_df <- read_csv("data/calibrated_training_data.csv")

# 2. Feature Engineering: Constructing Time-Series Lags
model_data <- calibrated_df %>%
  mutate(
    lag_1 = lag(precipitation_mm, 1),
    lag_2 = lag(precipitation_mm, 2),
    lag_3 = lag(precipitation_mm, 3)
  ) %>%
  drop_na()

# Sequential split: 80% Training, 20% Validation
split_idx <- round(nrow(model_data) * 0.8)
train_data <- model_data[1:split_idx, ]
test_data  <- model_data[(split_idx + 1):nrow(model_data), ]

# 3. Hyperparameter Grid Search via 10-Fold Cross-Validation
message("Initiating 10-fold cross-validation grid search. This may take a moment...")

# The tune() function tests every combination of the ranges provided
tune_result <- tune(
  svm,
  precipitation_mm ~ lag_1 + lag_2 + lag_3 + temperature_c,
  data = train_data,
  type = "eps-regression",
  kernel = "radial",
  ranges = list(
    cost = c(0.1, 1, 10, 100),         # Regularization penalty
    epsilon = c(0.01, 0.05, 0.1, 0.5), # Width of the margin of error
    gamma = c(0.01, 0.1, 0.25)         # RBF kernel influence radius
  ),
  tunecontrol = tune.control(cross = 10)
)

# Output the optimal parameter combination found by the grid search
cat("\n--- Optimal Hyperparameters Found ---\n")
print(tune_result$best.parameters)

# 4. Extract and Evaluate the Best Model
best_svr_model <- tune_result$best.model

# Test the optimized model against the unseen 20% holdout data
predictions <- predict(best_svr_model, test_data)

evaluation_metrics <- test_data %>%
  mutate(predicted_mm = as.numeric(predictions))

# Calculate error metrics mathematically
rmse <- sqrt(mean((evaluation_metrics$precipitation_mm - evaluation_metrics$predicted_mm)^2))
mae <- mean(abs(evaluation_metrics$precipitation_mm - evaluation_metrics$predicted_mm))

cat("\n--- Tuned SVR Evaluation Metrics ---\n")
cat("Root Mean Squared Error (RMSE):", round(rmse, 3), "mm\n")
cat("Mean Absolute Error (MAE):     ", round(mae, 3), "mm\n\n")

# 5. Serialize the Optimized Model for FastAPI Integration
saveRDS(best_svr_model, "data/svr_precipitation_model.rds")

# Extract the final initial state vector for recursive Python forecasting
latest_state <- model_data %>% 
  tail(1) %>% 
  select(precipitation_mm, lag_1, lag_2, temperature_c)

saveRDS(latest_state, "data/latest_forecast_state.rds")
message("Tuned SVR model and operational state serialized successfully!")