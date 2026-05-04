import React, { useEffect, useRef } from 'react';

export default function ProgressRing({
  size = 100,
  strokeWidth = 8,
  progress = 0,
  color = 'var(--color-primary-container)',
  label,
  sublabel,
  fontSize = '1.25rem',
}) {
  const radius = (size - strokeWidth) / 2;
  const circumference = radius * 2 * Math.PI;
  const offset = circumference - (Math.min(progress, 100) / 100) * circumference;

  return (
    <div className="progress-ring" style={{ width: size, height: size }}>
      <svg width={size} height={size}>
        <circle
          className="progress-ring__track"
          cx={size / 2}
          cy={size / 2}
          r={radius}
          strokeWidth={strokeWidth}
        />
        <circle
          className="progress-ring__fill"
          cx={size / 2}
          cy={size / 2}
          r={radius}
          strokeWidth={strokeWidth}
          stroke={color}
          strokeDasharray={circumference}
          strokeDashoffset={offset}
          style={{
            filter: progress >= 100 ? `drop-shadow(0 0 8px ${color})` : 'none',
          }}
        />
      </svg>
      <div className="progress-ring__label">
        {label && <span style={{ fontSize, fontWeight: 700 }}>{label}</span>}
        {sublabel && (
          <span style={{ fontSize: '0.65rem', color: 'var(--color-on-surface-variant)', fontWeight: 500 }}>
            {sublabel}
          </span>
        )}
      </div>
    </div>
  );
}
