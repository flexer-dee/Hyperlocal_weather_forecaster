# ==============================================================================
# PHASE 2: TEMPORAL BIAS CORRECTION VIA QUANTILE MAPPING (QM)
# ==============================================================================
library(tidyverse)
library(jsonlite)

# 1. Load the 1D Time-Series Data
chirps_raw <- read_csv("data/gee_chirps_nairobi.csv")

# Clean the dates
chirps_raw <- chirps_raw %>% 
  mutate(clean_date = as.Date(substr(date, 1, 10)))

# 2. DYNAMIC TEMPORAL SYNC
# Extract the most recent 365 days available in your specific CHIRPS dataset
target_dates <- tail(sort(unique(chirps_raw$clean_date)), 365)
start_date <- min(target_dates)
end_date <- max(target_dates)

message("Fetching ground truth telemetry for exact CHIRPS date range: ", start_date, " to ", end_date)

# Dynamically query the Open-Meteo API to match these exact dates perfectly
api_url <- paste0("https://archive-api.open-meteo.com/v1/archive?latitude=-1.308&longitude=36.812&start_date=",
                  start_date, "&end_date=", end_date,
                  "&daily=temperature_2m_mean,precipitation_sum&timezone=Africa%2FNairobi")

response <- fromJSON(api_url)

# Format the dynamic ground truth
ground_truth <- tibble(
  date = as.Date(response$daily$time),
  temperature_c = response$daily$temperature_2m_mean,
  precipitation_mm = response$daily$precipitation_sum
)

# Filter CHIRPS to match the exact 365-day extraction window
chirps_filtered <- chirps_raw %>% 
  filter(clean_date %in% ground_truth$date)

# 3. Execute Quantile Mapping (QM)
# This maps the CDF of the CHIRPS proxy onto the CDF of the ground observation data[cite: 1].
message("Applying Quantile Mapping to align probability distributions...")

# Calculate empirical CDF of the uncorrected CHIRPS estimate
chirps_ecdf <- ecdf(chirps_filtered$precipitation)

# Map the probabilities to the exact quantiles of the localized ground truth
corrected_precip <- quantile(ground_truth$precipitation_mm, 
                             probs = chirps_ecdf(chirps_filtered$precipitation), 
                             na.rm = TRUE)

# 4. Extract the Final Calibrated Time-Series
final_calibrated_data <- tibble(
  date = ground_truth$date,
  precipitation_mm = as.numeric(corrected_precip),
  temperature_c = ground_truth$temperature_c # Carry forward for the SVR model
)

write_csv(final_calibrated_data, "data/calibrated_training_data.csv")
message("Quantile Mapping complete! Pristine 1D dataset saved for Markov training.")