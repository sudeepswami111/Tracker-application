import React from 'react';
import { Heart, Moon, Droplets, Scale, Activity, Thermometer, Wind, Plus, Minus, TrendingUp } from 'lucide-react';
import { useApp } from '../context/AppContext.jsx';
import ProgressRing from '../components/ProgressRing.jsx';
import './Health.css';

export default function Health() {
  const { state, dispatch, addToast } = useApp();
  const { health } = state;

  const addWater = () => {
    dispatch({ type: 'ADD_WATER' });
    if (health.water.current + 1 >= health.water.goal) {
      addToast('streak', 'Hydration goal reached! 💧🎉');
    } else {
      addToast('info', 'Glass of water logged! 💧');
    }
  };

  return (
    <div className="health-page" id="health-page">
      <div className="page-header">
        <h1>Health Monitor</h1>
        <p>Track your vitals and wellness metrics</p>
      </div>

      <div className="dashboard-grid">
        {/* Heart Rate */}
        <div className="span-4">
          <div className="glass-card glass-card--no-hover animate-fade-in-up health__heart-card" style={{ opacity: 0 }}>
            <div className="section-header">
              <h3 className="section-title"><Heart size={18} /> Heart Rate</h3>
              <span className="badge badge--coral">Live</span>
            </div>
            <div className="health__heart-display">
              <div className="health__heart-bpm">
                <Heart size={28} className="health__heart-icon" />
                <span className="health__heart-value">{health.heartRate.current}</span>
                <span className="health__heart-unit">BPM</span>
              </div>
              <div className="health__heart-info">
                <div className="health__heart-info-item">
                  <span className="text-muted">Resting</span>
                  <span className="text-stat">{health.heartRate.resting}</span>
                </div>
                <div className="health__heart-info-item">
                  <span className="text-muted">Max</span>
                  <span className="text-stat">{health.heartRate.max}</span>
                </div>
              </div>
            </div>
            <div className="health__heart-zones">
              {health.heartRate.zones.map(zone => (
                <div key={zone.name} className="health__zone-bar">
                  <span className="health__zone-name">{zone.name}</span>
                  <div className="health__zone-track">
                    <div
                      className="health__zone-fill"
                      style={{
                        width: `${(parseInt(zone.time) / 24) * 100}%`,
                        background: zone.color,
                      }}
                    />
                  </div>
                  <span className="health__zone-time">{zone.time}</span>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* Sleep */}
        <div className="span-4">
          <div className="glass-card glass-card--no-hover animate-fade-in-up" style={{ animationDelay: '0.05s', opacity: 0 }}>
            <div className="section-header">
              <h3 className="section-title"><Moon size={18} /> Sleep</h3>
            </div>
            <div className="health__sleep-ring">
              <ProgressRing
                size={140}
                strokeWidth={12}
                progress={health.sleep.quality}
                color="#4facfe"
                label={`${health.sleep.hours}h`}
                sublabel={`${health.sleep.quality}% quality`}
                fontSize="1.5rem"
              />
            </div>
            <div className="health__sleep-stages">
              <div className="health__sleep-stage">
                <div className="health__stage-dot" style={{ background: '#6c5ce7' }} />
                <span className="health__stage-name">Deep</span>
                <span className="health__stage-value">{health.sleep.deep}h</span>
              </div>
              <div className="health__sleep-stage">
                <div className="health__stage-dot" style={{ background: '#4facfe' }} />
                <span className="health__stage-name">Light</span>
                <span className="health__stage-value">{health.sleep.light}h</span>
              </div>
              <div className="health__sleep-stage">
                <div className="health__stage-dot" style={{ background: '#f093fb' }} />
                <span className="health__stage-name">REM</span>
                <span className="health__stage-value">{health.sleep.rem}h</span>
              </div>
              <div className="health__sleep-stage">
                <div className="health__stage-dot" style={{ background: 'var(--color-on-surface-variant)' }} />
                <span className="health__stage-name">Awake</span>
                <span className="health__stage-value">{health.sleep.awake}h</span>
              </div>
            </div>

            {/* Weekly sleep mini chart */}
            <div className="health__sleep-chart">
              {health.sleep.weeklyData.map((hours, i) => {
                const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                const height = (hours / 10) * 100;
                return (
                  <div key={i} className="health__sleep-bar-container">
                    <div className="health__sleep-bar" style={{ height: `${height}%`, background: hours >= 7 ? '#4facfe' : '#ff6b6b' }} />
                    <span className="health__sleep-bar-label">{days[i]}</span>
                  </div>
                );
              })}
            </div>
          </div>
        </div>

        {/* Water Intake */}
        <div className="span-4">
          <div className="glass-card glass-card--no-hover animate-fade-in-up" style={{ animationDelay: '0.1s', opacity: 0 }}>
            <div className="section-header">
              <h3 className="section-title"><Droplets size={18} /> Water Intake</h3>
              <span className="badge badge--primary">{health.water.current}/{health.water.goal}</span>
            </div>
            <div className="health__water-display">
              <div className="health__water-glasses">
                {Array.from({ length: health.water.goal }, (_, i) => (
                  <div
                    key={i}
                    className={`health__water-glass ${i < health.water.current ? 'health__water-glass--filled' : ''}`}
                  >
                    <Droplets size={16} />
                  </div>
                ))}
              </div>
              <button
                className="btn btn-primary"
                onClick={addWater}
                id="add-water-btn"
                disabled={health.water.current >= 12}
                style={{ marginTop: 'var(--spacing-md)' }}
              >
                <Plus size={16} /> Add Glass
              </button>
            </div>

            <div className="health__water-weekly">
              <span className="text-label text-muted" style={{ marginBottom: '8px', display: 'block' }}>This Week</span>
              <div className="health__water-bars">
                {health.water.history.map((val, i) => {
                  const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                  return (
                    <div key={i} className="health__water-bar-col">
                      <div className="health__water-bar-track">
                        <div
                          className="health__water-bar-fill"
                          style={{ height: `${(val / health.water.goal) * 100}%` }}
                        />
                      </div>
                      <span className="health__water-bar-label">{days[i]}</span>
                    </div>
                  );
                })}
              </div>
            </div>
          </div>
        </div>

        {/* Weight & BMI */}
        <div className="span-6">
          <div className="glass-card glass-card--no-hover animate-fade-in-up" style={{ animationDelay: '0.15s', opacity: 0 }}>
            <div className="section-header">
              <h3 className="section-title"><Scale size={18} /> Weight Trend</h3>
              <span className="badge badge--success">-{(health.weight.history[0] - health.weight.current).toFixed(1)} kg</span>
            </div>
            <div className="health__weight-stats">
              <div className="health__weight-current">
                <span className="health__weight-big">{health.weight.current}</span>
                <span className="text-muted">kg</span>
              </div>
              <div className="health__weight-meta">
                <div>
                  <span className="text-muted">Target</span>
                  <span className="text-stat"> {health.weight.target} kg</span>
                </div>
                <div>
                  <span className="text-muted">BMI</span>
                  <span className="text-stat"> {health.weight.bmi}</span>
                </div>
              </div>
            </div>
            <div className="health__weight-chart">
              <svg viewBox="0 0 400 100" style={{ width: '100%', height: 'auto' }}>
                <defs>
                  <linearGradient id="weightAreaGrad" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="0%" stopColor="#43e97b" stopOpacity="0.3" />
                    <stop offset="100%" stopColor="#43e97b" stopOpacity="0" />
                  </linearGradient>
                </defs>
                {(() => {
                  const data = health.weight.history;
                  const min = Math.min(...data) - 1;
                  const max = Math.max(...data) + 1;
                  const range = max - min;
                  const points = data.map((v, i) => ({
                    x: (i / (data.length - 1)) * 380 + 10,
                    y: 90 - ((v - min) / range) * 80,
                  }));
                  const linePath = points.map((p, i) => `${i === 0 ? 'M' : 'L'}${p.x},${p.y}`).join(' ');
                  const areaPath = `${linePath} L${points[points.length - 1].x},95 L${points[0].x},95 Z`;
                  return (
                    <>
                      <path d={areaPath} fill="url(#weightAreaGrad)" />
                      <path d={linePath} fill="none" stroke="#43e97b" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" />
                      {points.map((p, i) => (
                        <circle key={i} cx={p.x} cy={p.y} r="3" fill="#43e97b" stroke="var(--color-surface)" strokeWidth="2" />
                      ))}
                    </>
                  );
                })()}
              </svg>
            </div>
          </div>
        </div>

        {/* Wellness Score & Vitals */}
        <div className="span-6">
          <div className="glass-card glass-card--no-hover animate-fade-in-up" style={{ animationDelay: '0.2s', opacity: 0 }}>
            <div className="section-header">
              <h3 className="section-title"><Activity size={18} /> Wellness Score</h3>
            </div>
            <div className="health__wellness">
              <div className="health__wellness-ring">
                <ProgressRing
                  size={130}
                  strokeWidth={10}
                  progress={health.wellness.score}
                  color="#43e97b"
                  label={health.wellness.score}
                  sublabel="Score"
                  fontSize="2rem"
                />
              </div>
              <div className="health__wellness-metrics">
                <div className="health__wellness-metric">
                  <span className="text-muted">Mood</span>
                  <span className="health__wellness-emoji">
                    {health.wellness.mood === 'great' ? '😊' : health.wellness.mood === 'good' ? '🙂' : '😐'}
                  </span>
                </div>
                <div className="health__wellness-metric">
                  <span className="text-muted">Energy</span>
                  <div className="health__wellness-bar">
                    <div className="health__wellness-bar-fill" style={{ width: `${health.wellness.energy}%`, background: 'var(--gradient-coral)' }} />
                  </div>
                  <span className="text-stat" style={{ fontSize: '0.8rem' }}>{health.wellness.energy}%</span>
                </div>
                <div className="health__wellness-metric">
                  <span className="text-muted">Stress</span>
                  <div className="health__wellness-bar">
                    <div className="health__wellness-bar-fill" style={{ width: `${health.wellness.stress}%`, background: health.wellness.stress < 50 ? 'var(--color-success)' : 'var(--gradient-coral)' }} />
                  </div>
                  <span className="text-stat" style={{ fontSize: '0.8rem' }}>{health.wellness.stress}%</span>
                </div>
              </div>
            </div>

            <div className="health__vitals">
              <div className="health__vital-card">
                <Thermometer size={16} style={{ color: 'var(--color-tertiary)' }} />
                <div>
                  <span className="text-muted" style={{ fontSize: '0.7rem' }}>Temp</span>
                  <span className="text-stat">{health.vitals.temperature}°F</span>
                </div>
              </div>
              <div className="health__vital-card">
                <Activity size={16} style={{ color: 'var(--color-coral)' }} />
                <div>
                  <span className="text-muted" style={{ fontSize: '0.7rem' }}>BP</span>
                  <span className="text-stat">{health.vitals.bloodPressure.systolic}/{health.vitals.bloodPressure.diastolic}</span>
                </div>
              </div>
              <div className="health__vital-card">
                <Wind size={16} style={{ color: 'var(--color-blue)' }} />
                <div>
                  <span className="text-muted" style={{ fontSize: '0.7rem' }}>SpO₂</span>
                  <span className="text-stat">{health.vitals.oxygenLevel}%</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
