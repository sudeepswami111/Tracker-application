import React from 'react';
import { NavLink, useLocation } from 'react-router-dom';
import { LayoutDashboard, Dumbbell, MapPin, Heart, BookOpen, Flame } from 'lucide-react';
import { useApp } from '../context/AppContext.jsx';
import './Sidebar.css';

const navItems = [
  { path: '/', icon: LayoutDashboard, label: 'Dashboard' },
  { path: '/fitness', icon: Dumbbell, label: 'Fitness' },
  { path: '/running', icon: MapPin, label: 'Running' },
  { path: '/health', icon: Heart, label: 'Health' },
  { path: '/study', icon: BookOpen, label: 'Study' },
];

export default function Sidebar() {
  const { state } = useApp();
  const location = useLocation();

  const totalStreak = Object.values(state.streaks).reduce((sum, s) => sum + s.current, 0);

  return (
    <aside className="sidebar" id="sidebar">
      <div className="sidebar__brand">
        <div className="sidebar__logo">
          <div className="sidebar__logo-icon">
            <Flame size={24} />
          </div>
          <span className="sidebar__logo-text">LifePulse</span>
        </div>
      </div>

      <nav className="sidebar__nav">
        {navItems.map(item => (
          <NavLink
            key={item.path}
            to={item.path}
            className={({ isActive }) => `sidebar__link ${isActive ? 'sidebar__link--active' : ''}`}
            id={`nav-${item.label.toLowerCase()}`}
          >
            <item.icon size={20} />
            <span>{item.label}</span>
            {item.label !== 'Dashboard' && (
              <span className="sidebar__streak-badge">
                <Flame size={12} />
                {state.streaks[item.label.toLowerCase()]?.current || 0}
              </span>
            )}
          </NavLink>
        ))}
      </nav>

      <div className="sidebar__footer">
        <div className="sidebar__user-card glass-card glass-card--no-hover">
          <div className="sidebar__user-avatar">
            {state.user.name.charAt(0)}
          </div>
          <div className="sidebar__user-info">
            <span className="sidebar__user-name">{state.user.name}</span>
            <span className="sidebar__user-level">Level {state.user.level}</span>
          </div>
        </div>
        <div className="sidebar__xp-bar">
          <div
            className="sidebar__xp-fill"
            style={{ width: `${(state.user.xp / state.user.xpToNext) * 100}%` }}
          />
        </div>
        <span className="sidebar__xp-text">{state.user.xp} / {state.user.xpToNext} XP</span>
      </div>
    </aside>
  );
}
