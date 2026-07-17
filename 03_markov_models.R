# ==============================================================================
# PHASE 3: CLIMATE-CONDITIONED MARKOV CHAINS (STATE TRANSITIONS)
# ==============================================================================
library(tidyverse)
library(markovchain)

# 1. Load Calibrated Hyper-Local Data
# This reads the pristine 1D output from our Quantile Mapping bias correction
calibrated_df <- read_csv("data/calibrated_training_data.csv")

# 2. Define Discrete Weather States for the React UI
# We categorize continuous rainfall (mm) into states for your App.css logic
weather_data <- calibrated_df %>%
  mutate(
    state = case_when(
      precipitation_mm < 0.5 ~ "Clear",
      precipitation_mm >= 0.5 & precipitation_mm < 15 ~ "Rain",
      precipitation_mm >= 15 ~ "Storm"
    ),
    state = factor(state, levels = c("Clear", "Rain", "Storm"))
  )

# Extract the sequential vector of historical daily states
state_sequence <- as.character(weather_data$state)

# 3. Fit the Maximum Likelihood Markov Chain Model
# This calculates the transition probabilities: P(next_state | current_state)
mc_model <- markovchainFit(data = state_sequence, method = "mle")

# Display the Transition Probability Matrix
cat("\nHyper-Local Transition Probability Matrix:\n")
print(mc_model$estimate)

# 4. Serialize for Python/FastAPI Integration
# This matrix will be loaded by your backend to stream real-time JSON 
# probability payloads to your React UI
saveRDS(mc_model$estimate, "data/markov_transition_matrix.rds")
message("\nMarkov Chain model trained and serialized successfully!")