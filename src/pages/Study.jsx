import React, { useState, useEffect, useRef } from 'react';
import { BookOpen, Flame, Clock, Target, Trophy, Play, Pause, RotateCcw, Plus, X, BarChart3 } from 'lucide-react';
import { useApp } from '../context/AppContext.jsx';
import ProgressRing from '../components/ProgressRing.jsx';
import './Study.css';

export default function Study() {
  const { state, dispatch, addToast } = useApp();
  const { study } = state;
  const [showModal, setShowModal] = useState(false);
  const [newSession, setNewSession] = useState({ subject: 'Mathematics', duration: 30 });
  const [timerSeconds, setTimerSeconds] = useState(study.focusTimer.duration);
  const timerRef = useRef(null);

  // Focus Timer
  useEffect(() => {
    if (study.focusTimer.isRunning) {
      timerRef.current = setInterval(() => {
        setTimerSeconds(prev => {
          if (prev <= 1) {
            dispatch({ type: 'TOGGLE_FOCUS_TIMER' });
            dispatch({
              type: 'UPDATE_FOCUS_TIMER',
              payload: { sessionsCompleted: study.focusTimer.sessionsCompleted + 1 },
            });
            addToast('success', 'Focus session complete! Great work! 🎯');
            return study.focusTimer.duration;
          }
          return prev - 1;
        });
      }, 1000);
    } else {
      clearInterval(timerRef.current);
    }
    return () => clearInterval(timerRef.current);
  }, [study.focusTimer.isRunning]);

  const formatTimer = (secs) => {
    const m = Math.floor(secs / 60);
    const s = secs % 60;
    return `${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}`;
  };

  const resetTimer = () => {
    dispatch({ type: 'UPDATE_FOCUS_TIMER', payload: { isRunning: false } });
    setTimerSeconds(study.focusTimer.duration);
  };

  const handleAddSession = () => {
    const colors = ['#6c5ce7', '#00d2d3', '#ff6b6b', '#feca57', '#f093fb', '#43e97b'];
    dispatch({
      type: 'ADD_STUDY_SESSION',
      payload: {
        id: Date.now(),
        subject: newSession.subject,
        duration: newSession.duration,
        color: colors[Math.floor(Math.random() * colors.length)],
        startTime: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
      },
    });
    addToast('success', `${newSession.subject} session logged! 📚`);
    setShowModal(false);
  };

  const timerProgress = ((study.focusTimer.duration - timerSeconds) / study.focusTimer.duration) * 100;

  return (
    <div className="study-page" id="study-page">
      <div className="page-header">
        <h1>Study Tracker</h1>
        <p>Track your learning and build consistency</p>
      </div>

      <div className="dashboard-grid">
        {/* Streak */}
        <div className="span-4">
          <div className="glass-card glass-card--no-hover animate-fade-in-up study__streak-card" style={{ opacity: 0 }}>
            <div className="study__streak-flame">🔥</div>
            <div className="study__streak-count">{study.streak.current}</div>
            <span className="study__streak-label">Day Streak</span>
            <div className="study__streak-meta">
              <div>
                <span className="text-muted">Longest</span>
                <span className="text-stat"> {study.streak.longest} days</span>
              </div>
            </div>
            <div className="study__streak-bar">
              <div
                className="study__streak-bar-fill"
                style={{ width: `${(study.streak.current / study.streak.longest) * 100}%` }}
              />
            </div>
          </div>
        </div>

        {/* Focus Timer */}
        <div className="span-4">
          <div className="glass-card glass-card--no-hover animate-fade-in-up" style={{ animationDelay: '0.05s', opacity: 0 }}>
            <div className="section-header">
              <h3 className="section-title"><Target size={18} /> Focus Timer</h3>
              <span className="badge badge--primary">{study.focusTimer.sessionsCompleted} done</span>
            </div>
            <div className="study__timer-display">
              <ProgressRing
                size={160}
                strokeWidth={8}
                progress={timerProgress}
                color={study.focusTimer.isRunning ? '#6c5ce7' : 'var(--color-outline-variant)'}
                label={formatTimer(timerSeconds)}
                sublabel={study.focusTimer.isRunning ? 'Focus time' : 'Ready'}
                fontSize="1.75rem"
              />
            </div>
            <div className="study__timer-controls">
              <button
                className="btn btn-primary"
                onClick={() => dispatch({ type: 'TOGGLE_FOCUS_TIMER' })}
                id="focus-timer-btn"
              >
                {study.focusTimer.isRunning ? <Pause size={16} /> : <Play size={16} />}
                {study.focusTimer.isRunning ? 'Pause' : 'Start'}
              </button>
              <button className="btn btn-glass" onClick={resetTimer}>
                <RotateCcw size={16} /> Reset
              </button>
            </div>
          </div>
        </div>

        {/* Today's Summary */}
        <div className="span-4">
          <div className="glass-card glass-card--no-hover animate-fade-in-up" style={{ animationDelay: '0.1s', opacity: 0 }}>
            <div className="section-header">
              <h3 className="section-title"><Clock size={18} /> Today</h3>
              <button className="btn btn-glass" onClick={() => setShowModal(true)} style={{ padding: '6px 12px' }}>
                <Plus size={14} />
              </button>
            </div>
            <div className="study__today-total">
              <span className="study__today-hours">{(study.today.totalMinutes / 60).toFixed(1)}</span>
              <span className="text-muted">hours studied</span>
            </div>
            <div className="study__today-sessions">
              {study.today.sessions.map(session => (
                <div key={session.id} className="study__session-item">
                  <div className="study__session-dot" style={{ background: session.color }} />
                  <div className="study__session-info">
                    <span className="study__session-subject">{session.subject}</span>
                    <span className="study__session-time">{session.startTime}</span>
                  </div>
                  <span className="study__session-duration">{session.duration} min</span>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* Subject Progress */}
        <div className="span-6">
          <div className="glass-card glass-card--no-hover animate-fade-in-up" style={{ animationDelay: '0.15s', opacity: 0 }}>
            <div className="section-header">
              <h3 className="section-title"><BarChart3 size={18} /> Subject Progress</h3>
            </div>
            <div className="study__subjects">
              {study.subjects.map(subject => (
                <div key={subject.name} className="study__subject-item">
                  <div className="study__subject-header">
                    <div className="study__subject-dot" style={{ background: subject.color }} />
                    <span className="study__subject-name">{subject.name}</span>
                    <span className="study__subject-hours">{subject.hours}h</span>
                    <span className="study__subject-pct">{subject.progress}%</span>
                  </div>
                  <div className="study__subject-bar">
                    <div
                      className="study__subject-fill"
                      style={{ width: `${subject.progress}%`, background: subject.color }}
                    />
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* Weekly Heatmap */}
        <div className="span-6">
          <div className="glass-card glass-card--no-hover animate-fade-in-up" style={{ animationDelay: '0.2s', opacity: 0 }}>
            <div className="section-header">
              <h3 className="section-title">📊 Study Heatmap</h3>
            </div>
            <div className="study__heatmap">
              {study.weeklyHeatmap.map((week, wi) => (
                <div key={wi} className="study__heatmap-row">
                  <span className="study__heatmap-label">W{wi + 1}</span>
                  {week.map((val, di) => {
                    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                    const intensity = val / 4;
                    return (
                      <div
                        key={di}
                        className="study__heatmap-cell"
                        style={{
                          background: val === 0
                            ? 'rgba(255,255,255,0.03)'
                            : `rgba(108, 92, 231, ${0.2 + intensity * 0.6})`,
                        }}
                        title={`${days[di]}: ${val} hours`}
                      >
                        {wi === 0 && <span className="study__heatmap-day">{days[di]}</span>}
                      </div>
                    );
                  })}
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* Milestones */}
        <div className="span-12">
          <div className="glass-card glass-card--no-hover animate-fade-in-up" style={{ animationDelay: '0.25s', opacity: 0 }}>
            <div className="section-header">
              <h3 className="section-title"><Trophy size={18} /> Milestones & Achievements</h3>
            </div>
            <div className="study__milestones">
              {study.milestones.map(milestone => (
                <div
                  key={milestone.id}
                  className={`study__milestone ${milestone.achieved ? 'study__milestone--achieved' : ''}`}
                >
                  <span className="study__milestone-icon">{milestone.icon}</span>
                  <span className="study__milestone-title">{milestone.title}</span>
                  {milestone.achieved ? (
                    <span className="badge badge--success">Achieved</span>
                  ) : (
                    <div className="study__milestone-progress">
                      <div className="study__milestone-bar">
                        <div
                          className="study__milestone-fill"
                          style={{ width: `${milestone.progress}%` }}
                        />
                      </div>
                      <span className="study__milestone-pct">{milestone.progress}%</span>
                    </div>
                  )}
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>

      {/* Add Session Modal */}
      {showModal && (
        <div className="modal-overlay" onClick={() => setShowModal(false)}>
          <div className="modal-content" onClick={e => e.stopPropagation()}>
            <div className="modal-header">
              <h2>Log Study Session</h2>
              <button className="btn-icon" onClick={() => setShowModal(false)}><X size={18} /></button>
            </div>
            <div className="form-group">
              <label className="form-label">Subject</label>
              <select
                className="form-input form-select"
                value={newSession.subject}
                onChange={e => setNewSession(p => ({ ...p, subject: e.target.value }))}
              >
                {study.subjects.map(s => (
                  <option key={s.name}>{s.name}</option>
                ))}
              </select>
            </div>
            <div className="form-group">
              <label className="form-label">Duration (minutes)</label>
              <input
                type="number"
                className="form-input"
                value={newSession.duration}
                onChange={e => setNewSession(p => ({ ...p, duration: +e.target.value }))}
              />
            </div>
            <button className="btn btn-primary w-full" onClick={handleAddSession} style={{ marginTop: 'var(--spacing-md)' }}>
              <Plus size={16} /> Log Session
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
