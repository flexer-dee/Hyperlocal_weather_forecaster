import React, { useState, useEffect } from 'react';
import { getBackgroundAsset } from './utils/weatherAssets';
import { LineChart, Line, XAxis, Tooltip, ResponsiveContainer } from 'recharts';
import './App.css';

function App() {
  // Input state for our ML model (simulating current temp to predict tomorrow's rain)
  const [temperature, setTemperature] = useState(24.0); 
  const [forecast, setForecast] = useState({ forecast_mm: 0, forecast_state: 'Clear' });
  const [isLoading, setIsLoading] = useState(true);
  const [weatherAlert, setWeatherAlert] = useState(null);

  // Determine daytime for the background asset toggle (06:00 to 18:30)
  const hour = new Date().getHours();
  const isDaytime = hour >= 6 && hour < 18;

  useEffect(() => {
    const fetchForecast = async () => {
      setIsLoading(true);
      try {
        const response = await fetch('http://localhost:8000/api/weather/forecast', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ temperature_c: temperature })
        });
        
        if (!response.ok) throw new Error('Failed to fetch from local ML model');
        
        const data = await response.json();
        setForecast(data);

        // Retained your Severe Weather Alert logic, now triggered by the SVR output
        if (data.forecast_state === 'Storm') {
          setWeatherAlert("⚠️ Severe Weather Alert: Heavy storm conditions expected.");
        } else {
          setWeatherAlert(null);
        }
      } catch (err) {
        console.error(err);
      } finally {
        setIsLoading(false);
      }
    };

    // Debounce the fetch so the Python backend isn't spammed while dragging the slider
    const timeoutId = setTimeout(() => fetchForecast(), 300);
    return () => clearTimeout(timeoutId);
  }, [temperature]);

  // Chart data structure mapping the transition
  const chartData = [
    { time: 'Current', value: temperature, type: 'Temp (°C)' },
    { time: 'Forecast', value: forecast.forecast_mm, type: 'Rain (mm)' }
  ];

  // Your retained custom tooltip
  const CustomTooltip = ({ active, payload, label }) => {
    if (active && payload && payload.length) {
      return (
        <div className="custom-tooltip" style={{ backgroundColor: 'rgba(0,0,0,0.8)', padding: '10px', borderRadius: '5px', color: '#fff' }}>
          <p className="label">{`${label}`}</p>
          <p className="temp">{`${payload[0].value} ${payload[0].payload.type}`}</p>
        </div>
      );
    }
    return null;
  };

  const backgroundImage = getBackgroundAsset(forecast.forecast_state, isDaytime);

  return (
    <div 
      className="app" 
      style={{ 
        backgroundImage: `url(${backgroundImage})`, 
        backgroundSize: 'cover', 
        backgroundPosition: 'center', 
        transition: 'background-image 0.8s ease-in-out', 
        minHeight: '100vh',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center'
      }}
    >
      <main style={{ width: '100%', maxWidth: '600px', margin: '0 auto' }}>
        
        {weatherAlert && (
          <div className="alert-banner" style={{ background: 'rgba(255, 0, 0, 0.7)', padding: '10px', borderRadius: '8px', marginBottom: '20px', textAlign: 'center', color: 'white', animation: 'pulse 2s infinite' }}>
            {weatherAlert}
          </div>
        )}

        <div className="weather-display" style={{ background: 'rgba(255, 255, 255, 0.1)', backdropFilter: 'blur(10px)', padding: '2rem', borderRadius: '15px', color: 'white' }}>
          
          <div className="location-box">
            <div className="location" style={{ fontSize: '1.5rem', fontWeight: 'bold' }}>Nairobi, near Strathmore University</div>
            <div className="date">{new Date().toLocaleDateString('en-US', { weekday: 'short', day: 'numeric', month: 'short', year: 'numeric' })}</div>
          </div>

          {/* Real-time temperature simulator */}
          <div style={{ margin: '30px 0' }}>
            <label>Simulate Current Temperature: <strong>{temperature}°C</strong></label>
            <input 
              type="range" min="10" max="40" step="0.5" value={temperature} 
              onChange={(e) => setTemperature(parseFloat(e.target.value))}
              style={{ width: '100%', marginTop: '10px', cursor: 'pointer' }}
            />
          </div>

          <div className="weather-box" style={{ textAlign: 'center', margin: '20px 0' }}>
            <div className="temp" style={{ fontSize: '4rem', fontWeight: 'bold' }}>
              {isLoading ? '...' : `${forecast.forecast_mm} mm`}
            </div>
            <div className="weather-condition" style={{ fontSize: '1.5rem' }}>
              {isLoading ? 'Calculating...' : forecast.forecast_state}
            </div>
          </div>

          <div className="chart-container" style={{ height: '250px', marginTop: '30px', width: '100%' }}>
            <h3 style={{ textAlign: 'center', marginBottom: '20px' }}>Predictive Trend</h3>
            <ResponsiveContainer width="100%" height="100%">
              <LineChart data={chartData}>
                {/* 
                  Configured the layout focus strictly on the x axis. 
                  Padding, heavy stroke width, and bold ticks anchor the visual scaling horizontally.
                */}
                <XAxis 
                  dataKey="time" 
                  stroke="#ffffff" 
                  tick={{ fill: '#ffffff', fontSize: 16, fontWeight: 'bold' }} 
                  tickMargin={15}
                  padding={{ left: 50, right: 50 }}
                  axisLine={{ stroke: '#ffffff', strokeWidth: 3 }}
                />
                <Tooltip content={<CustomTooltip />} cursor={{ stroke: 'rgba(255,255,255,0.4)', strokeWidth: 2 }} />
                <Line type="monotone" dataKey="value" stroke="#4dabf7" strokeWidth={4} dot={{ r: 8, fill: '#fff', stroke: '#4dabf7', strokeWidth: 2 }} />
              </LineChart>
            </ResponsiveContainer>
          </div>
          
        </div>
      </main>
    </div>
  );
}

export default App;