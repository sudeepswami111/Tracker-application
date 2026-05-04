import React, { useState } from 'react';
import { Flame, Clock, Dumbbell, TrendingDown, Plus, Activity, Bike, Heart as HeartIcon, X } from 'lucide-react';
import { useApp } from '../context/AppContext.jsx';
import StatCard from '../components/StatCard.jsx';
import ProgressRing from '../components/ProgressRing.jsx';
import WeeklyChart from '../components/WeeklyChart.jsx';
import './Fitness.css';

const workoutIcons = {
  running: Activity,
  dumbbell: Dumbbell,
  heart: HeartIcon,
  bike: Bike,
};

export default function Fitness() {
  const { state, dispatch, addToast } = useApp();
  const { fitness } = state;
  const [showModal, setShowModal] = useState(false);
  const [newWorkout, setNewWorkout] = useState({ type: 'Running', duration: 30, calories: 250, intensity: 'Medium' });

  const goalProgress = (fitness.weeklyCompleted / fitness.weeklyGoal) * 100;

  const handleAddWorkout = () => {
    dispatch({
      type: 'ADD_WORKOUT',
      payload: {
        id: Date.now(),
        ...newWorkout,
        time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
        icon: 'dumbbell',
      },
    });
    addToast('success', `${newWorkout.type} workout logged! +${newWorkout.calories} kcal 🔥`);
    setShowModal(false);
  };

  return (
    <div className="fitness-page" id="fitness-page">
      <div className="page-header">
        <h1>Fitness Tracker</h1>
        <p>Track your workouts and body metrics</p>
      </div>

      {/* Top Stats */}
      <div className="stats-grid mb-lg">
        <StatCard icon={Flame} label="Calories Burned" value={fitness.todayCalories.toLocaleString()} unit="kcal" gradient="var(--gradient-coral)" trend={5} delay={0} />
        <StatCard icon={Clock} label="Duration" value={fitness.todayDuration} unit="min" gradient="var(--gradient-primary)" trend={12} delay={60} />
        <StatCard icon={Dumbbell} label="Exercises" value={fitness.todayExercises} unit="done" gradient="var(--gradient-secondary)" delay={120} />
        <StatCard icon={TrendingDown} label="Weight" value={fitness.bodyWeight[fitness.bodyWeight.length - 1]} unit="kg" gradient="var(--gradient-green)" trend={-2} delay={180} />
      </div>

      <div className="dashboard-grid">
        {/* Weekly Goal */}
        <div className="span-4">
          <div className="glass-card glass-card--no-hover animate-fade-in-up fitness__goal-card" style={{ animationDelay: '0.2s', opacity: 0 }}>
            <h3 className="section-title" style={{ marginBottom: 'var(--spacing-md)', textAlign: 'center' }}>Weekly Goal</h3>
            <div style={{ display: 'flex', justifyContent: 'center' }}>
              <ProgressRing
                size={160}
                strokeWidth={12}
                progress={goalProgress}
                color="#6c5ce7"
                label={`${fitness.weeklyCompleted}/${fitness.weeklyGoal}`}
                sublabel="workouts"
                fontSize="1.5rem"
              />
            </div>
            <p className="text-center text-muted" style={{ marginTop: 'var(--spacing-md)', fontSize: '0.85rem' }}>
              {fitness.weeklyGoal - fitness.weeklyCompleted} more to hit your goal!
            </p>
          </div>
        </div>

        {/* Weekly Performance */}
        <div className="span-8">
          <div className="glass-card glass-card--no-hover animate-fade-in-up" style={{ animationDelay: '0.25s', opacity: 0 }}>
            <div className="section-header">
              <h3 className="section-title">Weekly Performance</h3>
            </div>
            <WeeklyChart data={fitness.weeklyData} />
          </div>
        </div>

        {/* Workout History */}
        <div className="span-8">
          <div className="glass-card glass-card--no-hover animate-fade-in-up" style={{ animationDelay: '0.3s', opacity: 0 }}>
            <div className="section-header">
              <h3 className="section-title">Today's Workouts</h3>
              <button className="btn btn-primary" onClick={() => setShowModal(true)} id="add-workout-btn">
                <Plus size={16} /> Log Workout
              </button>
            </div>
            <div className="fitness__workouts">
              {fitness.workouts.map((workout, i) => {
                const IconComp = workoutIcons[workout.icon] || Dumbbell;
                return (
                  <div key={workout.id} className="fitness__workout-card animate-fade-in-up" style={{ animationDelay: `${0.35 + i * 0.05}s`, opacity: 0 }}>
                    <div className="fitness__workout-icon" style={{ background: `var(--gradient-${workout.intensity === 'High' ? 'coral' : workout.intensity === 'Medium' ? 'primary' : 'green'})` }}>
                      <IconComp size={20} />
                    </div>
                    <div className="fitness__workout-info">
                      <span className="fitness__workout-type">{workout.type}</span>
                      <span className="fitness__workout-time">{workout.time}</span>
                    </div>
                    <div className="fitness__workout-stats">
                      <span className="fitness__workout-duration">{workout.duration} min</span>
                      <span className="fitness__workout-calories">{workout.calories} kcal</span>
                    </div>
                    <span className={`badge badge--${workout.intensity === 'High' ? 'coral' : workout.intensity === 'Medium' ? 'primary' : 'success'}`}>
                      {workout.intensity}
                    </span>
                  </div>
                );
              })}
            </div>
          </div>
        </div>

        {/* Body Metrics */}
        <div className="span-4">
          <div className="glass-card glass-card--no-hover animate-fade-in-up" style={{ animationDelay: '0.35s', opacity: 0 }}>
            <h3 className="section-title" style={{ marginBottom: 'var(--spacing-md)' }}>Body Metrics</h3>
            <div className="fitness__body-stats">
              <div className="fitness__body-stat">
                <span className="fitness__body-label">Current Weight</span>
                <span className="fitness__body-value">{fitness.bodyWeight[fitness.bodyWeight.length - 1]} kg</span>
              </div>
              <div className="fitness__body-stat">
                <span className="fitness__body-label">BMI</span>
                <span className="fitness__body-value">{fitness.bmi}</span>
              </div>
              <div className="fitness__body-stat">
                <span className="fitness__body-label">Weight Lost</span>
                <span className="fitness__body-value text-success">
                  -{(fitness.bodyWeight[0] - fitness.bodyWeight[fitness.bodyWeight.length - 1]).toFixed(1)} kg
                </span>
              </div>
            </div>
            <div className="fitness__weight-chart">
              <svg viewBox="0 0 280 80" className="fitness__sparkline">
                <defs>
                  <linearGradient id="weightGrad" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="0%" stopColor="#43e97b" stopOpacity="0.3" />
                    <stop offset="100%" stopColor="#43e97b" stopOpacity="0" />
                  </linearGradient>
                </defs>
                <path
                  d={(() => {
                    const min = Math.min(...fitness.bodyWeight);
                    const max = Math.max(...fitness.bodyWeight);
                    const range = max - min || 1;
                    const points = fitness.bodyWeight.map((v, i) => {
                      const x = (i / (fitness.bodyWeight.length - 1)) * 280;
                      const y = 75 - ((v - min) / range) * 65;
                      return `${x},${y}`;
                    });
                    return `M${points.join(' L')} L280,80 L0,80 Z`;
                  })()}
                  fill="url(#weightGrad)"
                />
                <path
                  d={(() => {
                    const min = Math.min(...fitness.bodyWeight);
                    const max = Math.max(...fitness.bodyWeight);
                    const range = max - min || 1;
                    const points = fitness.bodyWeight.map((v, i) => {
                      const x = (i / (fitness.bodyWeight.length - 1)) * 280;
                      const y = 75 - ((v - min) / range) * 65;
                      return `${x},${y}`;
                    });
                    return `M${points.join(' L')}`;
                  })()}
                  fill="none"
                  stroke="#43e97b"
                  strokeWidth="2"
                />
              </svg>
            </div>
          </div>
        </div>
      </div>

      {/* Add Workout Modal */}
      {showModal && (
        <div className="modal-overlay" onClick={() => setShowModal(false)}>
          <div className="modal-content" onClick={e => e.stopPropagation()}>
            <div className="modal-header">
              <h2>Log Workout</h2>
              <button className="btn-icon" onClick={() => setShowModal(false)}><X size={18} /></button>
            </div>
            <div className="form-group">
              <label className="form-label">Workout Type</label>
              <select
                className="form-input form-select"
                value={newWorkout.type}
                onChange={e => setNewWorkout(p => ({ ...p, type: e.target.value }))}
              >
                <option>Running</option>
                <option>Weight Training</option>
                <option>Yoga</option>
                <option>Cycling</option>
                <option>Swimming</option>
                <option>HIIT</option>
              </select>
            </div>
            <div className="form-group">
              <label className="form-label">Duration (minutes)</label>
              <input
                type="number"
                className="form-input"
                value={newWorkout.duration}
                onChange={e => setNewWorkout(p => ({ ...p, duration: +e.target.value }))}
              />
            </div>
            <div className="form-group">
              <label className="form-label">Calories Burned</label>
              <input
                type="number"
                className="form-input"
                value={newWorkout.calories}
                onChange={e => setNewWorkout(p => ({ ...p, calories: +e.target.value }))}
              />
            </div>
            <div className="form-group">
              <label className="form-label">Intensity</label>
              <select
                className="form-input form-select"
                value={newWorkout.intensity}
                onChange={e => setNewWorkout(p => ({ ...p, intensity: e.target.value }))}
              >
                <option>Low</option>
                <option>Medium</option>
                <option>High</option>
              </select>
            </div>
            <button className="btn btn-primary w-full" onClick={handleAddWorkout} id="submit-workout-btn" style={{ marginTop: 'var(--spacing-md)' }}>
              <Plus size={16} /> Add Workout
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
