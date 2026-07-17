# ==============================================================================
# PHASE 5: FASTAPI BACKEND & R-MODEL INTEGRATION
# ==============================================================================

import os
# Force Windows to locate the R 4.5.3 DLLs before rpy2 initializes
os.environ['PATH'] = r'C:\Program Files\R\R-4.5.3\bin\x64;' + os.environ.get('PATH', '')

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import rpy2.robjects as robjects
from rpy2.robjects.packages import importr
import pandas as pd
from pydantic import BaseModel

# Import base R packages required for prediction
base = importr('base')
stats = importr('stats')
e1071 = importr('e1071') # Required for SVR predict

app = FastAPI(title="Local Meteorological API")

# Configure CORS so your React application can communicate freely
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], 
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 1. Load the Serialized R Models into Memory on Startup
try:
    readRDS = robjects.r['readRDS']
    markov_matrix = readRDS('data/markov_transition_matrix.rds')
    svr_model = readRDS('data/svr_precipitation_model.rds')
    
    # Because global conversion is active, this automatically loads as a Pandas DataFrame!
    latest_state = readRDS('data/latest_forecast_state.rds')
except Exception as e:
    print(f"Error loading R models: {e}")

# 2. Define Pydantic Schemas for Input Validation
class ForecastRequest(BaseModel):
    temperature_c: float

# 3. Endpoint: Markov Chain Transition Probabilities
@app.get("/api/weather/transitions")
async def get_transition_probabilities():
    """
    Returns the Markov Chain transition matrix for the React UI background shifts.
    """
    try:
        # Extract the matrix values from the rpy2 object
        matrix_array = tuple(markov_matrix)
        
        # The 3x3 matrix corresponds to: Clear, Rain, Storm
        response_payload = {
            "current_state_clear": {"to_clear": matrix_array[0], "to_rain": matrix_array[3], "to_storm": matrix_array[6]},
            "current_state_rain": {"to_clear": matrix_array[1], "to_rain": matrix_array[4], "to_storm": matrix_array[7]},
            "current_state_storm": {"to_clear": matrix_array[2], "to_rain": matrix_array[5], "to_storm": matrix_array[8]}
        }
        return {"status": "success", "transitions": response_payload}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# 4. Endpoint: SVR Recursive Forecast
@app.post("/api/weather/forecast")
async def generate_forecast(request: ForecastRequest):
    try:
        # Access R columns using .rx2('column_name')
        # This is the native rpy2 way to access R data frames
        lag1 = float(latest_state.rx2('precipitation_mm')[0])
        lag2 = float(latest_state.rx2('lag_1')[0])
        lag3 = float(latest_state.rx2('lag_2')[0])
        temp = float(request.temperature_c)
        
        # Build the R DataFrame for prediction
        r_df = robjects.DataFrame({
            'lag_1': robjects.FloatVector([lag1]),
            'lag_2': robjects.FloatVector([lag2]),
            'lag_3': robjects.FloatVector([lag3]),
            'temperature_c': robjects.FloatVector([temp])
        })
        
        # Predict
        prediction_r = stats.predict(svr_model, r_df)
        predicted_precip = max(0.0, float(prediction_r[0]))
        
        # Categorize
        predicted_state = "Clear"
        if 0.5 <= predicted_precip < 15:
            predicted_state = "Rain"
        elif predicted_precip >= 15:
            predicted_state = "Storm"
            
        return {
            "status": "success",
            "forecast_mm": round(predicted_precip, 2),
            "forecast_state": predicted_state
        }
    except Exception as e:
        print(f"Prediction Error: {e}") 
        raise HTTPException(status_code=500, detail=str(e))