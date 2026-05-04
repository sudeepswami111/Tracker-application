import React from 'react';
import './StatCard.css';

export default function StatCard({
  icon: Icon,
  label,
  value,
  unit,
  progress,
  color = 'var(--color-primary-container)',
  gradient,
  trend,
  children,
  delay = 0,
  onClick,
}) {
  const percentage = progress != null ? Math.min(Math.round(progress), 100) : null;

  return (
    <div
      className="stat-card glass-card animate-fade-in-up"
      style={{ animationDelay: `${delay}ms` }}
      onClick={onClick}
      role={onClick ? 'button' : undefined}
      tabIndex={onClick ? 0 : undefined}
    >
      <div className="stat-card__header">
        <div className="stat-card__icon" style={{ background: gradient || color }}>
          {Icon && <Icon size={18} />}
        </div>
        {trend && (
          <span className={`stat-card__trend ${trend > 0 ? 'stat-card__trend--up' : 'stat-card__trend--down'}`}>
            {trend > 0 ? '↑' : '↓'} {Math.abs(trend)}%
          </span>
        )}
      </div>

      <div className="stat-card__value">
        <span className="stat-card__number">{value}</span>
        {unit && <span className="stat-card__unit">{unit}</span>}
      </div>

      <span className="stat-card__label">{label}</span>

      {percentage != null && (
        <div className="stat-card__progress">
          <div className="stat-card__progress-bar">
            <div
              className="stat-card__progress-fill"
              style={{
                width: `${percentage}%`,
                background: gradient || color,
              }}
            />
          </div>
          <span className="stat-card__progress-text">{percentage}%</span>
        </div>
      )}

      {children}
    </div>
  );
}
