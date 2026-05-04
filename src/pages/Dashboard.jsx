import React from 'react';
import { Footprints, Flame, MapPin, Moon, Droplets, BookOpen, Trophy, Zap, TrendingUp, Target, Sparkles } from 'lucide-react';
import { useApp } from '../context/AppContext.jsx';
import StatCard from '../components/StatCard.jsx';
import ProgressRing from '../components/ProgressRing.jsx';
import WeeklyChart from '../components/WeeklyChart.jsx';
import './Dashboard.css';

export default function Dashboard() {
  const { state } = useApp();
  const { dashboard, streaks, achievements, goals, insights } = state;

  const statCards = [
    { icon: Footprints, label: 'Steps', value: dashboard.steps.current.toLocaleString(), unit: '', progress: (dashboard.steps.current / dashboard.steps.goal) * 100, gradient: 'var(--gradient-primary)', trend: 8 },
    { icon: Flame, label: 'Calories Burned', value: dashboard.calories.current.toLocaleString(), unit: 'kcal', progress: (dashboard.calories.current / dashboard.calories.goal) * 100, gradient: 'var(--gradient-coral)', trend: 5 },
    { icon: MapPin, label: 'Distance', value: dashboard.distance.current, unit: 'km', progress: (dashboard.distance.current / dashboard.distance.goal) * 100, gradient: 'var(--gradient-blue)', trend: 12 },
    { icon: Moon, label: 'Sleep', value: dashboard.sleep.current, unit: 'hrs', progress: (dashboard.sleep.current / dashboard.sleep.goal) * 100, gradient: 'var(--gradient-green)', trend: -3 },
    { icon: Droplets, label: 'Water Intake', value: dashboard.water.current, unit: 'L', progress: (dashboard.water.current / dashboard.water.goal) * 100, gradient: 'var(--gradient-secondary)', trend: 2 },
    { icon: BookOpen, label: 'Study Hours', value: dashboard.studyHours.current, unit: 'hrs', progress: (dashboard.studyHours.current / dashboard.studyHours.goal) * 100, gradient: 'var(--gradient-pink)', trend: 15 },
  ];

  const activeStreaks = [
    { name: 'Fitness', value: streaks.fitness.current, color: 'var(--color-coral)' },
    { name: 'Running', value: streaks.running.current, color: 'var(--color-teal)' },
    { name: 'Health', value: streaks.health.current, color: 'var(--color-green)' },
    { name: 'Study', value: streaks.study.current, color: 'var(--color-purple)' },
  ];

  return (
    <div className="dashboard" id="dashboard-page">
      <div className="page-header">
        <h1>Dashboard</h1>
        <p>Your daily life at a glance</p>
      </div>

      {/* Stats Grid */}
      <div className="stats-grid mb-lg">
        {statCards.map((card, i) => (
          <StatCard key={card.label} {...card} delay={i * 60} />
        ))}
      </div>

      {/* Main Content Grid */}
      <div className="dashboard-grid">
        {/* Weekly Activity Chart */}
        <div className="span-8">
          <div className="glass-card glass-card--no-hover animate-fade-in-up" style={{ animationDelay: '0.3s', opacity: 0 }}>
            <div className="section-header">
              <h3 className="section-title">Weekly Activity</h3>
              <div className="tabs" style={{ marginBottom: 0 }}>
                <button className="tab active">Fitness</button>
                <button className="tab">Study</button>
                <button className="tab">Steps</button>
              </div>
            </div>
            <WeeklyChart data={state.fitness.weeklyData} />
          </div>
        </div>

        {/* Streaks */}
        <div className="span-4">
          <div className="glass-card glass-card--no-hover animate-fade-in-up" style={{ animationDelay: '0.35s', opacity: 0 }}>
            <div className="section-header">
              <h3 className="section-title">🔥 Active Streaks</h3>
            </div>
            <div className="dashboard__streaks">
              {activeStreaks.map(streak => (
                <div key={streak.name} className="dashboard__streak-item">
                  <div className="dashboard__streak-info">
                    <span className="streak-flame">🔥</span>
                    <span className="dashboard__streak-name">{streak.name}</span>
                  </div>
                  <div className="dashboard__streak-count" style={{ color: streak.color }}>
                    {streak.value} <span className="dashboard__streak-label">days</span>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* Daily Goals */}
        <div className="span-4">
          <div className="glass-card glass-card--no-hover animate-fade-in-up" style={{ animationDelay: '0.4s', opacity: 0 }}>
            <div className="section-header">
              <h3 className="section-title"><Target size={18} /> Daily Goals</h3>
            </div>
            <div className="dashboard__goals">
              {goals.daily.map(goal => (
                <div key={goal.id} className="dashboard__goal-item">
                  <div className="dashboard__goal-header">
                    <span className="dashboard__goal-title">{goal.title}</span>
                    <span className={`badge ${goal.progress >= 100 ? 'badge--success' : 'badge--primary'}`}>
                      {goal.progress >= 100 ? '✓ Done' : `${goal.progress}%`}
                    </span>
                  </div>
                  <div className="dashboard__goal-bar">
                    <div
                      className="dashboard__goal-fill"
                      style={{
                        width: `${Math.min(goal.progress, 100)}%`,
                        background: goal.progress >= 100 ? 'var(--color-success)' : 'var(--color-primary-container)',
                      }}
                    />
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* AI Insights */}
        <div className="span-4">
          <div className="glass-card glass-card--no-hover animate-fade-in-up" style={{ animationDelay: '0.45s', opacity: 0 }}>
            <div className="section-header">
              <h3 className="section-title"><Sparkles size={18} /> AI Insights</h3>
            </div>
            <div className="dashboard__insights">
              {insights.map(insight => (
                <div key={insight.id} className={`dashboard__insight dashboard__insight--${insight.type}`}>
                  <span className="dashboard__insight-icon">
                    {insight.type === 'positive' ? '✨' : insight.type === 'suggestion' ? '💡' : '⚠️'}
                  </span>
                  <span className="dashboard__insight-text">{insight.message}</span>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* Achievements */}
        <div className="span-4">
          <div className="glass-card glass-card--no-hover animate-fade-in-up" style={{ animationDelay: '0.5s', opacity: 0 }}>
            <div className="section-header">
              <h3 className="section-title"><Trophy size={18} /> Achievements</h3>
            </div>
            <div className="dashboard__achievements">
              {achievements.slice(0, 6).map(badge => (
                <div
                  key={badge.id}
                  className={`dashboard__badge ${badge.unlocked ? 'dashboard__badge--unlocked' : ''}`}
                >
                  <span className="dashboard__badge-icon">{badge.icon}</span>
                  <span className="dashboard__badge-title">{badge.title}</span>
                  {!badge.unlocked && (
                    <div className="dashboard__badge-progress">
                      <div
                        className="dashboard__badge-bar"
                        style={{ width: `${badge.progress}%` }}
                      />
                    </div>
                  )}
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* Overall Progress Ring */}
        <div className="span-12">
          <div className="glass-card glass-card--no-hover animate-fade-in-up dashboard__overall" style={{ animationDelay: '0.55s', opacity: 0 }}>
            <div className="dashboard__overall-rings">
              <div className="dashboard__overall-ring">
                <ProgressRing size={120} progress={(dashboard.steps.current / dashboard.steps.goal) * 100} color="#6c5ce7" label={`${Math.round((dashboard.steps.current / dashboard.steps.goal) * 100)}%`} sublabel="Steps" />
              </div>
              <div className="dashboard__overall-ring">
                <ProgressRing size={120} progress={(dashboard.calories.current / dashboard.calories.goal) * 100} color="#ff6b6b" label={`${Math.round((dashboard.calories.current / dashboard.calories.goal) * 100)}%`} sublabel="Calories" />
              </div>
              <div className="dashboard__overall-ring">
                <ProgressRing size={120} progress={(dashboard.sleep.current / dashboard.sleep.goal) * 100} color="#43e97b" label={`${Math.round((dashboard.sleep.current / dashboard.sleep.goal) * 100)}%`} sublabel="Sleep" />
              </div>
              <div className="dashboard__overall-ring">
                <ProgressRing size={120} progress={(dashboard.water.current / dashboard.water.goal) * 100} color="#00d2d3" label={`${Math.round((dashboard.water.current / dashboard.water.goal) * 100)}%`} sublabel="Water" />
              </div>
              <div className="dashboard__overall-ring">
                <ProgressRing size={120} progress={(dashboard.studyHours.current / dashboard.studyHours.goal) * 100} color="#f093fb" label={`${Math.round((dashboard.studyHours.current / dashboard.studyHours.goal) * 100)}%`} sublabel="Study" />
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
