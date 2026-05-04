import React from 'react';
import { NavLink } from 'react-router-dom';
import { LayoutDashboard, Dumbbell, MapPin, Heart, BookOpen } from 'lucide-react';
import './MobileNav.css';

const navItems = [
  { path: '/', icon: LayoutDashboard, label: 'Home' },
  { path: '/fitness', icon: Dumbbell, label: 'Fitness' },
  { path: '/running', icon: MapPin, label: 'Run' },
  { path: '/health', icon: Heart, label: 'Health' },
  { path: '/study', icon: BookOpen, label: 'Study' },
];

export default function MobileNav() {
  return (
    <nav className="mobile-nav" id="mobile-nav">
      {navItems.map(item => (
        <NavLink
          key={item.path}
          to={item.path}
          className={({ isActive }) => `mobile-nav__link ${isActive ? 'mobile-nav__link--active' : ''}`}
          end={item.path === '/'}
        >
          <item.icon size={20} />
          <span>{item.label}</span>
        </NavLink>
      ))}
    </nav>
  );
}
