// src/utils/weatherAssets.js

// 1. Import the specific assets retained for the Markov Chain states
import clearDay from '../assets/clear day.jpg';
import clearNight from '../assets/clear night.jpg';
import rainDay from '../assets/rain day.jpg';
import rainNight from '../assets/rain night.jpg';
import stormDay from '../assets/storm day.jpg';
import stormNight from '../assets/storm night.jpg';

/**
 * 2. Translates the custom FastAPI prediction state into the correct UI asset.
 * 
 * @param {string} forecastState - The output from the backend: "Clear", "Rain", or "Storm".
 * @param {boolean} isDaytime - Boolean calculating if the local time is between 06:00 and 18:30.
 * @returns {string} The imported image path.
 */
export const getBackgroundAsset = (forecastState, isDaytime) => {
  const assets = {
    Clear: { day: clearDay, night: clearNight },
    Rain: { day: rainDay, night: rainNight },
    Storm: { day: stormDay, night: stormNight }
  };

  // Fallback to clear day if the backend state is missing or loading
  if (!assets[forecastState]) {
    console.warn(`Unrecognized forecast state: ${forecastState}`);
    return clearDay; 
  }
  
  return isDaytime ? assets[forecastState].day : assets[forecastState].night;
};