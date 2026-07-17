# 🌤️ Hyper-Local Predictive Weather Architecture (Madaraka Region)

A full-stack, machine-learning-driven meteorological forecasting dashboard. This project bridges a rigorous statistical data science pipeline (R) with a high-performance REST API (Python) and a dynamic, interactive frontend (React). 

Designed specifically for the microclimate of Nairobi (Madaraka / Strathmore University region), this architecture abandons generic global APIs in favor of hyper-local predictive modeling.

---

## 🏗️ The Engineering Pipeline

This project is built across three distinct computational tiers:

### 1. Data Extraction & Spatial Analysis (R & GEE)
*   **Google Earth Engine (GEE):** Automated extraction of high-resolution **CHIRPS** (Climate Hazards Group InfraRed Precipitation with Station data) satellite rasters for the specific target coordinates.
*   **Bias Correction:** Applied **1-Dimensional Quantile Mapping (QM)** to calibrate the satellite proxy telemetry against local ground-truth station data fetched via the Open-Meteo API.

### 2. Machine Learning Models (R)
*   **Support Vector Regression (SVR):** Engineered to forecast continuous precipitation (mm) using historical lags and current thermal covariates.
*   **Markov Chain Classifier:** Computes transition probabilities to classify the continuous rainfall predictions into strict discrete states: `Clear`, `Rain`, and `Storm`.
*   *Models are serialized as highly portable `.rds` objects for production deployment.*

### 3. Backend & Frontend Integration (Python & React)
*   **FastAPI Bridge:** A Python server utilizing the `rpy2` library to load the serialized R models into memory, allowing native execution of R prediction functions via RESTful JSON endpoints.
*   **Glassmorphism UI:** A Vite-bootstrapped React application featuring interactive thermal simulation, seamless state-driven background transitions, and continuous temporal trendlines rendered with **Recharts**.

---

## 🛠️ Tech Stack

**Data Science & Modeling**
*   `R` (stats, e1071, rgee)
*   Google Earth Engine API
*   Open-Meteo API

**Backend**
*   `Python 3.x`
*   `FastAPI` & `Uvicorn`
*   `rpy2` (R-to-Python bridging)

**Frontend**
*   `React` (Vite)
*   `Recharts` (Data Visualization)
*   Vanilla CSS (Glassmorphism, CSS Animations)

---

## 📂 Project Structure

```text
HYPERLOCAL FORECASTING/
├── data/                         # Calibrated datasets & serialized R models (.rds)
├── src/                          # React frontend components and assets
├── 01_data_extraction.R          # GEE CHIRPS extraction script
├── 02_bias_correction.R          # Quantile Mapping & telemetry calibration
├── 03_markov_models.R            # Discrete state transition training
├── 04_svr_forecasting.R          # Support Vector Regression training
├── main.py                       # FastAPI server bridging R models
├── package.json                  # Frontend dependencies
└── vite.config.js                # Vite build configuration