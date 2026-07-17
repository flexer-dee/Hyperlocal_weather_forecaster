# ==============================================================================
# PHASE 1: ACQUIRE REAL DEM & HISTORICAL STATION TELEMETRY (BULLETPROOF)
# ==============================================================================
library(tidyverse)
library(sf)
library(raster)
library(terra)
library(geodata)
library(jsonlite)

# 1. Download Authentic SRTM Elevation Data
message("Downloading authentic SRTM elevation data for Nairobi...")

# geodata downloads the specific high-res DEM tile for these exact coordinates
raw_dem <- elevation_3s(lon = 36.812, lat = -1.308, path = tempdir())

# Crop the massive tile specifically to the Madaraka / Strathmore bounds
madaraka_extent <- ext(36.80, 36.83, -1.32, -1.29)
real_dem_cropped <- crop(raw_dem, madaraka_extent)

# Convert the modern 'terra' object back to a legacy 'raster' object for RFmerge
final_dem <- raster(real_dem_cropped)

writeRaster(final_dem, filename = "data/nairobi_dem.tif", format = "GTiff", overwrite = TRUE)
message("Authentic DEM successfully downloaded and written to disk.")

# 2. Download Authentic Ground Telemetry (Direct via Open-Meteo Archive API)
message("Fetching historical ground telemetry via API...")

api_url <- "https://archive-api.open-meteo.com/v1/archive?latitude=-1.308&longitude=36.812&start_date=2023-01-01&end_date=2023-12-31&daily=temperature_2m_mean,precipitation_sum&timezone=Africa%2FNairobi"

response <- fromJSON(api_url)

real_telemetry <- tibble(
  date = as.Date(response$daily$time),
  latitude = -1.308,
  longitude = 36.812,
  temperature_c = response$daily$temperature_2m_mean,
  precipitation_mm = response$daily$precipitation_sum
)

write_csv(real_telemetry, "data/local_station_telemetry.csv")
message("Authentic localized telemetry written to disk. Ready for Phase 2.")