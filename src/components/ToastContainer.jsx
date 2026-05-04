import React from 'react';
import { X, CheckCircle, AlertTriangle, Info, Flame } from 'lucide-react';
import { useApp } from '../context/AppContext.jsx';

const iconMap = {
  success: CheckCircle,
  error: AlertTriangle,
  info: Info,
  streak: Flame,
};

const colorMap = {
  success: 'var(--color-success)',
  error: 'var(--color-error)',
  info: 'var(--color-primary)',
  streak: 'var(--color-tertiary)',
};

export default function ToastContainer() {
  const { state, dispatch } = useApp();

  return (
    <div className="toast-container">
      {state.toasts.map(toast => {
        const Icon = iconMap[toast.type] || Info;
        return (
          <div key={toast.id} className={`toast toast--${toast.type}`}>
            <Icon size={18} style={{ color: colorMap[toast.type], flexShrink: 0 }} />
            <span style={{ fontSize: '0.85rem', flex: 1 }}>{toast.message}</span>
            <button
              className="btn-icon"
              onClick={() => dispatch({ type: 'REMOVE_TOAST', payload: toast.id })}
              style={{ width: 28, height: 28 }}
            >
              <X size={14} />
            </button>
          </div>
        );
      })}
    </div>
  );
}
