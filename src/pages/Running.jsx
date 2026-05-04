import React, { useState, useEffect, useRef } from 'react';
import { Play, Pause, Square, MapPin, Clock, Zap, Flame, Trophy, Calendar, TrendingUp } from 'lucide-react';
import { useApp } from '../context/AppContext.jsx';
import StatCard from '../components/StatCard.jsx';
import './Running.css';

export default function Running() {
  const { state, dispatch, addToast } = useApp();
  const { running } = state;
  const [activeTab, setActiveTab] = useState('tracker');
  const [elapsedSeconds, setElapsedSeconds] = useState(0);
  const intervalRef = useRef(null);

  // Simulated live run tracking
  useEffect(() => {
    if (running.isTracking) {
      intervalRef.current = setInterval(() => {
        setElapsedSeconds(prev => prev + 1);
        const newDistance = +(running.currentRun.distance + 0.003).toFixed(3);
        const mins = Math.floor((elapsedSeconds + 1) / 60);
        const secs = (elapsedSeconds + 1) % 60;
        const pace = newDistance > 0 ? `${Math.floor((elapsedSeconds + 1) / 60 / newDistance)}:${String(Math.floor((elapsedSeconds + 1) / newDistance % 60)).padStart(2, '0')}` : '0:00';
        dispatch({
          type: 'UPDATE_CURRENT_RUN',
          payload: {
            distance: newDistance,
            duration: elapsedSeconds + 1,
            pace,
            calories: Math.floor(newDistance * 62),
            speed: +(newDistance / ((elapsedSeconds + 1) / 3600)).toFixed(1),
          },
        });
      }, 1000);
    } else {
      clearInterval(intervalRef.current);
    }
    return () => clearInterval(intervalRef.current);
  }, [running.isTracking, elapsedSeconds]);

  const toggleTracking = () => {
    if (!running.isTracking) {
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
    dispatch({ type: 'UPDATE_CURRENT_RUN', payload: { distance: 0, duration: 0, pace: '0:00', calories: 0, speed: 0 } });
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
        <p>Track your runs and set new records</p>
      </div>

      {/* Tabs */}
      <div className="tabs">
        <button className={`tab ${activeTab === 'tracker' ? 'active' : ''}`} onClick={() => setActiveTab('tracker')}>Live Tracker</button>
        <button className={`tab ${activeTab === 'history' ? 'active' : ''}`} onClick={() => setActiveTab('history')}>Run History</button>
        <button className={`tab ${activeTab === 'records' ? 'active' : ''}`} onClick={() => setActiveTab('records')}>Records</button>
      </div>

      {activeTab === 'tracker' && (
        <div className="dashboard-grid">
          {/* Map Area */}
          <div className="span-8">
            <div className="glass-card glass-card--no-hover animate-fade-in-up running__map-card" style={{ opacity: 0 }}>
              <div className="running__map">
                <div className="running__map-placeholder">
                  <MapPin size={48} className="running__map-icon" />
                  <p>{running.isTracking ? 'Tracking your route...' : 'Start a run to see your route'}</p>
                  {running.isTracking && (
                    <div className="running__map-pulse" />
                  )}
                  {/* Simulated route visualization */}
                  <svg className="running__route-svg" viewBox="0 0 400 250">
                    <defs>
                      <linearGradient id="routeGrad" x1="0%" y1="0%" x2="100%" y2="0%">
                        <stop offset="0%" stopColor="#6c5ce7" />
                        <stop offset="100%" stopColor="#00d2d3" />
                      </linearGradient>
                    </defs>
                    <path
                      d="M30,200 Q80,180 120,150 Q160,120 200,130 Q240,140 280,100 Q320,60 370,50"
                      fill="none"
                      stroke="url(#routeGrad)"
                      strokeWidth="3"
                      strokeLinecap="round"
                      strokeDasharray={running.isTracking ? '8 4' : '0'}
                      className={running.isTracking ? 'running__route-animated' : ''}
                    />
                    <circle cx="30" cy="200" r="6" fill="#43e97b" />
                    {running.isTracking && (
                      <circle cx="370" cy="50" r="6" fill="#ff6b6b" className="running__dot-pulse" />
                    )}
                  </svg>
                </div>
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
                  <button className="running__start-btn" onClick={toggleTracking} id="start-run-btn">
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

          {/* Side Stats */}
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
