import React, { useState, useEffect, useRef } from 'react';
import { Play, Pause, Square, Zap, Trophy, Calendar, TrendingUp, Flame, MapPin } from 'lucide-react';
import { MapContainer, TileLayer, Polyline, Marker, useMap } from 'react-leaflet';
import 'leaflet/dist/leaflet.css';
import L from 'leaflet';
import { useApp } from '../context/AppContext.jsx';
import { calculateDistance } from '../utils/geo.js';
import './Running.css';

// Fix for default Leaflet markers in React
delete L.Icon.Default.prototype._getIconUrl;
L.Icon.Default.mergeOptions({
  iconRetinaUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon-2x.png',
  iconUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png',
  shadowUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png',
});

// Custom markers
const startIcon = new L.Icon({
  iconUrl: 'https://raw.githubusercontent.com/pointhi/leaflet-color-markers/master/img/marker-icon-green.png',
  shadowUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/0.7.7/images/marker-shadow.png',
  iconSize: [25, 41],
  iconAnchor: [12, 41],
  popupAnchor: [1, -34],
  shadowSize: [41, 41]
});

const currentIcon = new L.Icon({
  iconUrl: 'https://raw.githubusercontent.com/pointhi/leaflet-color-markers/master/img/marker-icon-red.png',
  shadowUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/0.7.7/images/marker-shadow.png',
  iconSize: [25, 41],
  iconAnchor: [12, 41],
  popupAnchor: [1, -34],
  shadowSize: [41, 41]
});

// Component to dynamically update map view based on current position
function MapUpdater({ position }) {
  const map = useMap();
  useEffect(() => {
    if (position && position.length === 2) {
      map.setView(position, map.getZoom(), { animate: true });
    }
  }, [position, map]);
  return null;
}

export default function Running() {
  const { state, dispatch, addToast } = useApp();
  const { running } = state;
  const [activeTab, setActiveTab] = useState('tracker');
  const [elapsedSeconds, setElapsedSeconds] = useState(0);
  const [currentPosition, setCurrentPosition] = useState(null); // [lat, lng]
  
  const intervalRef = useRef(null);
  const geoWatchRef = useRef(null);

  // Initialize location on mount
  useEffect(() => {
    if ("geolocation" in navigator) {
      navigator.geolocation.getCurrentPosition(
        (pos) => setCurrentPosition([pos.coords.latitude, pos.coords.longitude]),
        (err) => console.error("Geolocation error:", err),
        { enableHighAccuracy: true }
      );
    }
  }, []);

  // Timer and Geolocation Tracking
  useEffect(() => {
    if (running.isTracking) {
      // 1. Start the timer
      intervalRef.current = setInterval(() => {
        setElapsedSeconds(prev => {
          const newElapsed = prev + 1;
          
          // Update the UI via dispatch (distance is calculated by geoWatch)
          const dist = running.currentRun.distance;
          const mins = Math.floor(newElapsed / 60);
          const pace = dist > 0 ? `${Math.floor((newElapsed / 60) / dist)}:${String(Math.floor((newElapsed / dist) % 60)).padStart(2, '0')}` : '0:00';
          const speed = dist > 0 ? +(dist / (newElapsed / 3600)).toFixed(1) : 0;
          const calories = Math.floor(dist * 62);

          dispatch({
            type: 'UPDATE_CURRENT_RUN',
            payload: { duration: newElapsed, pace, speed, calories }
          });
          
          return newElapsed;
        });
      }, 1000);

      // 2. Start GPS Tracking
      if ("geolocation" in navigator) {
        geoWatchRef.current = navigator.geolocation.watchPosition(
          (pos) => {
            const newCoord = [pos.coords.latitude, pos.coords.longitude];
            setCurrentPosition(newCoord);

            const path = running.currentRun.routePath || [];
            let newDist = running.currentRun.distance;

            // If we have previous points, calculate distance from the last point
            if (path.length > 0) {
              const lastCoord = path[path.length - 1];
              const addedDist = calculateDistance(lastCoord, newCoord);
              if (addedDist > 0.005) { // Only update if moved more than 5 meters to prevent GPS jitter
                newDist += addedDist;
              }
            }

            // Append new coordinate
            const newPath = [...path, newCoord];
            
            dispatch({
              type: 'UPDATE_CURRENT_RUN',
              payload: { routePath: newPath, distance: +newDist.toFixed(3) }
            });
          },
          (err) => {
            addToast('error', 'Location tracking error: ' + err.message);
          },
          { enableHighAccuracy: true, maximumAge: 0, timeout: 5000 }
        );
      }
    } else {
      clearInterval(intervalRef.current);
      if (geoWatchRef.current !== null) {
        navigator.geolocation.clearWatch(geoWatchRef.current);
      }
    }

    return () => {
      clearInterval(intervalRef.current);
      if (geoWatchRef.current !== null) {
        navigator.geolocation.clearWatch(geoWatchRef.current);
      }
    };
  }, [running.isTracking, running.currentRun.routePath, running.currentRun.distance, dispatch, addToast]);

  const toggleTracking = () => {
    if (!running.isTracking) {
      if (!("geolocation" in navigator)) {
        addToast('error', 'Geolocation is not supported by your browser');
        return;
      }
      addToast('info', 'Run tracking started! 🏃‍♂️');
    }
    dispatch({ type: 'TOGGLE_RUN_TRACKING' });
  };

  const stopRun = () => {
    if (running.currentRun.distance > 0) {
      dispatch({
        type: 'ADD_RUN',
        payload: {
          id: Date.now(),
          date: new Date().toISOString().split('T')[0],
          distance: +running.currentRun.distance.toFixed(2),
          duration: formatTime(running.currentRun.duration),
          pace: running.currentRun.pace,
          calories: running.currentRun.calories,
          route: 'Live Run',
        },
      });
      addToast('success', `Run saved! ${running.currentRun.distance.toFixed(2)} km in ${formatTime(running.currentRun.duration)} 🎉`);
    }
    dispatch({ type: 'TOGGLE_RUN_TRACKING' });
    dispatch({ type: 'UPDATE_CURRENT_RUN', payload: { distance: 0, duration: 0, pace: '0:00', calories: 0, speed: 0, routePath: [] } });
    setElapsedSeconds(0);
  };

  const formatTime = (totalSecs) => {
    const mins = Math.floor(totalSecs / 60);
    const secs = totalSecs % 60;
    return `${mins}:${String(secs).padStart(2, '0')}`;
  };

  return (
    <div className="running-page" id="running-page">
      <div className="page-header">
        <h1>Running Tracker</h1>
        <p>Track your runs and set new records with live GPS</p>
      </div>

      <div className="tabs">
        <button className={`tab ${activeTab === 'tracker' ? 'active' : ''}`} onClick={() => setActiveTab('tracker')}>Live Tracker</button>
        <button className={`tab ${activeTab === 'history' ? 'active' : ''}`} onClick={() => setActiveTab('history')}>Run History</button>
        <button className={`tab ${activeTab === 'records' ? 'active' : ''}`} onClick={() => setActiveTab('records')}>Records</button>
      </div>

      {activeTab === 'tracker' && (
        <div className="dashboard-grid">
          <div className="span-8">
            <div className="glass-card glass-card--no-hover animate-fade-in-up running__map-card" style={{ opacity: 0 }}>
              
              {/* Interactive World Map */}
              <div className="running__map">
                {currentPosition ? (
                  <MapContainer 
                    center={currentPosition} 
                    zoom={15} 
                    style={{ height: '100%', width: '100%', borderRadius: 'inherit' }}
                    zoomControl={false}
                  >
                    <TileLayer
                      url="https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png"
                      attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OSM</a> contributors'
                    />
                    
                    {running.isTracking && <MapUpdater position={currentPosition} />}
                    
                    {/* The Route Polyline */}
                    {running.currentRun.routePath && running.currentRun.routePath.length > 0 && (
                      <Polyline 
                        positions={running.currentRun.routePath} 
                        color="#00d2d3" 
                        weight={5} 
                        opacity={0.8}
                      />
                    )}

                    {/* Start Marker */}
                    {running.currentRun.routePath && running.currentRun.routePath.length > 0 && (
                      <Marker position={running.currentRun.routePath[0]} icon={startIcon} />
                    )}

                    {/* Current Position Marker */}
                    <Marker position={currentPosition} icon={running.isTracking ? currentIcon : startIcon} />
                  </MapContainer>
                ) : (
                  <div className="running__map-placeholder">
                    <MapPin size={48} className="running__map-icon" />
                    <p>Requesting location permissions...</p>
                  </div>
                )}
              </div>

              {/* Live Stats Overlay */}
              <div className="running__live-stats">
                <div className="running__live-stat">
                  <span className="running__live-value">{running.currentRun.distance.toFixed(2)}</span>
                  <span className="running__live-label">km</span>
                </div>
                <div className="running__live-divider" />
                <div className="running__live-stat">
                  <span className="running__live-value">{running.currentRun.pace}</span>
                  <span className="running__live-label">min/km</span>
                </div>
                <div className="running__live-divider" />
                <div className="running__live-stat">
                  <span className="running__live-value">{formatTime(running.currentRun.duration)}</span>
                  <span className="running__live-label">time</span>
                </div>
                <div className="running__live-divider" />
                <div className="running__live-stat">
                  <span className="running__live-value">{running.currentRun.calories}</span>
                  <span className="running__live-label">kcal</span>
                </div>
              </div>

              {/* Controls */}
              <div className="running__controls">
                {!running.isTracking ? (
                  <button className="running__start-btn" onClick={toggleTracking} id="start-run-btn" disabled={!currentPosition}>
                    <Play size={28} />
                  </button>
                ) : (
                  <>
                    <button className="running__control-btn running__pause-btn" onClick={toggleTracking}>
                      <Pause size={22} />
                    </button>
                    <button className="running__control-btn running__stop-btn" onClick={stopRun} id="stop-run-btn">
                      <Square size={22} />
                    </button>
                  </>
                )}
              </div>
            </div>
          </div>

          <div className="span-4">
            <div className="glass-card glass-card--no-hover animate-fade-in-up" style={{ animationDelay: '0.1s', opacity: 0 }}>
              <h3 className="section-title" style={{ marginBottom: 'var(--spacing-md)' }}>
                <Zap size={18} /> Current Speed
              </h3>
              <div className="running__speed-display">
                <span className="running__speed-value">{running.currentRun.speed}</span>
                <span className="running__speed-unit">km/h</span>
              </div>
            </div>

            <div className="glass-card glass-card--no-hover animate-fade-in-up" style={{ animationDelay: '0.15s', opacity: 0, marginTop: 'var(--spacing-md)' }}>
              <h3 className="section-title" style={{ marginBottom: 'var(--spacing-md)' }}>
                <Trophy size={18} /> Personal Records
              </h3>
              <div className="running__records">
                {Object.entries(running.personalRecords).map(([key, val]) => (
                  <div key={key} className="running__record-item">
                    <span className="running__record-label">
                      {key.replace(/([A-Z])/g, ' $1').replace(/^./, s => s.toUpperCase())}
                    </span>
                    <span className="running__record-value">{val}</span>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>
      )}

      {/* History and Records tabs remain unchanged... */}
      {activeTab === 'history' && (
        <div className="running__history animate-fade-in">
          <div className="glass-card glass-card--no-hover">
            <h3 className="section-title" style={{ marginBottom: 'var(--spacing-md)' }}>
              <Calendar size={18} /> Run History
            </h3>
            <div className="running__history-list">
              {running.history.map((run, i) => (
                <div key={run.id} className="running__history-card animate-fade-in-up" style={{ animationDelay: `${i * 0.05}s`, opacity: 0 }}>
                  <div className="running__history-date">
                    <span className="running__history-day">{new Date(run.date).getDate()}</span>
                    <span className="running__history-month">{new Date(run.date).toLocaleString('default', { month: 'short' })}</span>
                  </div>
                  <div className="running__history-info">
                    <span className="running__history-route">{run.route}</span>
                    <span className="running__history-meta">{run.distance} km · {run.duration} · {run.pace} min/km</span>
                  </div>
                  <div className="running__history-calories">
                    <Flame size={14} />
                    {run.calories} kcal
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      )}

      {activeTab === 'records' && (
        <div className="dashboard-grid animate-fade-in">
          <div className="span-6">
            <div className="glass-card glass-card--no-hover">
              <h3 className="section-title" style={{ marginBottom: 'var(--spacing-md)' }}>
                <Trophy size={18} /> Personal Bests
              </h3>
              <div className="running__records-grid">
                {Object.entries(running.personalRecords).map(([key, val]) => (
                  <div key={key} className="running__record-card">
                    <span className="running__record-big-value">{val}</span>
                    <span className="running__record-big-label">
                      {key.replace(/([A-Z])/g, ' $1').replace(/^./, s => s.toUpperCase())}
                    </span>
                  </div>
                ))}
              </div>
            </div>
          </div>
          <div className="span-6">
            <div className="glass-card glass-card--no-hover">
              <h3 className="section-title" style={{ marginBottom: 'var(--spacing-md)' }}>
                <TrendingUp size={18} /> Monthly Distance
              </h3>
              <div className="running__monthly-chart">
                <svg viewBox="0 0 340 120" className="running__monthly-svg">
                  <defs>
                    <linearGradient id="monthlyGrad" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="0%" stopColor="#00d2d3" stopOpacity="0.4" />
                      <stop offset="100%" stopColor="#00d2d3" stopOpacity="0" />
                    </linearGradient>
                  </defs>
                  {running.monthlyDistance.map((val, i) => {
                    const max = Math.max(...running.monthlyDistance);
                    const barH = (val / max) * 90;
                    const x = i * 28 + 4;
                    return (
                      <g key={i}>
                        <rect x={x} y={110 - barH} width="20" height={barH} rx="4" fill="url(#monthlyGrad)" stroke="#00d2d3" strokeWidth="1" />
                        <text x={x + 10} y={108 - barH - 4} textAnchor="middle" fill="var(--color-on-surface-variant)" fontSize="8" fontFamily="Inter">{val}</text>
                      </g>
                    );
                  })}
                </svg>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
