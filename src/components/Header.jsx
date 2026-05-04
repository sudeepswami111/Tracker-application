import React from 'react';
import { Sun, Moon, Bell, Search } from 'lucide-react';
import { useApp } from '../context/AppContext.jsx';
import './Header.css';

export default function Header() {
  const { state, dispatch } = useApp();

  const getGreeting = () => {
    const hour = new Date().getHours();
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  };

  return (
    <header className="header" id="header">
      <div className="header__left">
        <h2 className="header__greeting">
          {getGreeting()}, <span className="text-primary">{state.user.name}</span> 👋
        </h2>
        <p className="header__subtitle">Here's your progress today</p>
      </div>

      <div className="header__right">
        <div className="header__search">
          <Search size={16} />
          <input
            type="text"
            placeholder="Search..."
            className="header__search-input"
            id="header-search"
          />
        </div>

        <button
          className="btn-icon"
          onClick={() => dispatch({ type: 'TOGGLE_THEME' })}
          aria-label="Toggle theme"
          id="theme-toggle"
        >
          {state.theme === 'dark' ? <Sun size={18} /> : <Moon size={18} />}
        </button>

        <button className="btn-icon header__notification-btn" aria-label="Notifications" id="notifications-btn">
          <Bell size={18} />
          <span className="header__notification-dot" />
        </button>

        <div className="header__avatar" id="user-avatar">
          {state.user.name.charAt(0)}
        </div>
      </div>
    </header>
  );
}
