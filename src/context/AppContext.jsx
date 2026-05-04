import React, { createContext, useContext, useReducer, useEffect, useCallback } from 'react';

const AppContext = createContext(null);

// Demo data generators
const generateWeeklyData = () => {
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return days.map(day => ({
    day,
    fitness: Math.floor(Math.random() * 60 + 30),
    running: Math.floor(Math.random() * 40 + 10),
    study: Math.floor(Math.random() * 50 + 20),
    steps: Math.floor(Math.random() * 8000 + 4000),
    calories: Math.floor(Math.random() * 500 + 200),
  }));
};

const generateMonthlyData = () => {
  return Array.from({ length: 30 }, (_, i) => ({
    day: i + 1,
    value: Math.floor(Math.random() * 100 + 20),
  }));
};

const initialState = {
  theme: 'dark',
  user: {
    name: 'Alex',
    avatar: null,
    joinDate: '2025-01-15',
    level: 12,
    xp: 2840,
    xpToNext: 3500,
  },
  notifications: [],
  toasts: [],

  // Dashboard stats
  dashboard: {
    steps: { current: 12450, goal: 15000, unit: 'steps' },
    calories: { current: 2340, goal: 3000, unit: 'kcal' },
    distance: { current: 8.2, goal: 10, unit: 'km' },
    sleep: { current: 7.5, goal: 8, unit: 'hrs' },
    water: { current: 2.1, goal: 3, unit: 'L' },
    studyHours: { current: 4.5, goal: 6, unit: 'hrs' },
  },

  // Fitness
  fitness: {
    todayCalories: 2340,
    todayDuration: 75,
    todayExercises: 4,
    weeklyGoal: 5,
    weeklyCompleted: 3,
    bodyWeight: [82, 81.5, 81.8, 81.2, 80.9, 80.5, 80.2, 79.8, 80.1, 79.5, 79.2, 79.0, 78.8, 78.5],
    bmi: 24.1,
    workouts: [
      { id: 1, type: 'Running', duration: 35, calories: 420, intensity: 'High', time: '7:00 AM', icon: 'running' },
      { id: 2, type: 'Weight Training', duration: 45, calories: 380, intensity: 'Medium', time: '8:00 AM', icon: 'dumbbell' },
      { id: 3, type: 'Yoga', duration: 30, calories: 150, intensity: 'Low', time: '6:00 PM', icon: 'heart' },
      { id: 4, type: 'Cycling', duration: 40, calories: 350, intensity: 'High', time: '5:00 PM', icon: 'bike' },
    ],
    weeklyData: generateWeeklyData(),
  },

  // Running
  running: {
    isTracking: false,
    currentRun: {
      distance: 0,
      duration: 0,
      pace: '0:00',
      calories: 0,
      speed: 0,
      routePath: [],
    },
    history: [
      { id: 1, date: '2026-05-03', distance: 5.2, duration: '28:45', pace: '5:32', calories: 320, route: 'Central Park Loop' },
      { id: 2, date: '2026-05-01', distance: 8.1, duration: '45:20', pace: '5:36', calories: 510, route: 'Riverside Path' },
      { id: 3, date: '2026-04-29', distance: 3.5, duration: '19:15', pace: '5:30', calories: 215, route: 'Neighborhood Run' },
      { id: 4, date: '2026-04-27', distance: 10.0, duration: '56:40', pace: '5:40', calories: 640, route: 'Lake Circuit' },
      { id: 5, date: '2026-04-25', distance: 6.3, duration: '34:50', pace: '5:32', calories: 395, route: 'Hill Training' },
    ],
    personalRecords: {
      fastest5K: '24:30',
      fastest10K: '52:15',
      longestRun: '21.5 km',
      mostCalories: '1,240 kcal',
    },
    monthlyDistance: [32, 45, 38, 52, 41, 48, 55, 60, 42, 58, 50, 65],
    weeklyData: generateWeeklyData(),
  },

  // Health
  health: {
    heartRate: {
      current: 72,
      resting: 62,
      max: 185,
      zones: [
        { name: 'Rest', min: 50, max: 70, color: '#4facfe', time: '14h' },
        { name: 'Fat Burn', min: 70, max: 120, color: '#43e97b', time: '6h' },
        { name: 'Cardio', min: 120, max: 160, color: '#feca57', time: '3h' },
        { name: 'Peak', min: 160, max: 200, color: '#ff6b6b', time: '1h' },
      ],
    },
    sleep: {
      hours: 7.5,
      quality: 82,
      deep: 2.1,
      light: 3.8,
      rem: 1.6,
      awake: 0.3,
      weeklyData: [7.2, 6.8, 7.5, 8.1, 7.0, 7.8, 7.5],
    },
    water: {
      current: 6,
      goal: 8,
      history: [8, 6, 7, 8, 5, 7, 6],
    },
    weight: {
      current: 78.5,
      target: 75,
      history: [82, 81.5, 81, 80.5, 80, 79.5, 79.2, 79, 78.8, 78.5],
      bmi: 24.1,
    },
    wellness: {
      score: 85,
      mood: 'great',
      energy: 78,
      stress: 32,
    },
    vitals: {
      bloodPressure: { systolic: 120, diastolic: 80 },
      temperature: 98.4,
      oxygenLevel: 98,
    },
  },

  // Study
  study: {
    streak: { current: 15, longest: 28, isActive: true },
    today: {
      totalMinutes: 270,
      sessions: [
        { id: 1, subject: 'Mathematics', duration: 120, color: '#6c5ce7', startTime: '9:00 AM' },
        { id: 2, subject: 'Computer Science', duration: 90, color: '#00d2d3', startTime: '11:30 AM' },
        { id: 3, subject: 'English Literature', duration: 60, color: '#ff6b6b', startTime: '2:00 PM' },
      ],
    },
    focusTimer: {
      isRunning: false,
      duration: 25 * 60,
      elapsed: 0,
      type: 'work',
      sessionsCompleted: 3,
    },
    subjects: [
      { name: 'Mathematics', hours: 45, progress: 72, color: '#6c5ce7' },
      { name: 'Computer Science', hours: 38, progress: 65, color: '#00d2d3' },
      { name: 'English Literature', hours: 22, progress: 48, color: '#ff6b6b' },
      { name: 'Physics', hours: 30, progress: 55, color: '#feca57' },
      { name: 'History', hours: 15, progress: 35, color: '#f093fb' },
    ],
    weeklyHeatmap: [
      [3, 2, 4, 1, 3, 0, 2],
      [2, 4, 3, 2, 1, 3, 1],
      [4, 3, 2, 4, 2, 1, 3],
      [1, 2, 3, 3, 4, 2, 0],
    ],
    milestones: [
      { id: 1, title: '7-Day Streak', achieved: true, icon: '🔥', date: '2026-04-20' },
      { id: 2, title: '100 Hours Studied', achieved: true, icon: '📚', date: '2026-04-28' },
      { id: 3, title: 'Early Bird (5 AM session)', achieved: true, icon: '🌅', date: '2026-05-01' },
      { id: 4, title: '30-Day Streak', achieved: false, icon: '💎', progress: 50 },
      { id: 5, title: '500 Hours Studied', achieved: false, icon: '🏆', progress: 30 },
    ],
    weeklyData: generateWeeklyData(),
    monthlyData: generateMonthlyData(),
  },

  // Streaks
  streaks: {
    fitness: { current: 12, longest: 45, lastActive: '2026-05-04' },
    running: { current: 5, longest: 21, lastActive: '2026-05-03' },
    health: { current: 8, longest: 30, lastActive: '2026-05-04' },
    study: { current: 15, longest: 28, lastActive: '2026-05-04' },
  },

  // Achievements
  achievements: [
    { id: 1, title: 'Early Bird', description: 'Complete a workout before 7 AM', icon: '🌅', unlocked: true, date: '2026-04-15' },
    { id: 2, title: 'Marathoner', description: 'Run 42.2 km total', icon: '🏃', unlocked: true, date: '2026-04-22' },
    { id: 3, title: 'Deep Work Master', description: '4+ hour study session', icon: '🧠', unlocked: true, date: '2026-04-28' },
    { id: 4, title: 'Hydration Hero', description: 'Meet water goal 7 days straight', icon: '💧', unlocked: true, date: '2026-05-01' },
    { id: 5, title: 'Iron Will', description: '30-day fitness streak', icon: '💪', unlocked: false, progress: 40 },
    { id: 6, title: 'Speed Demon', description: 'Run 5K under 22 minutes', icon: '⚡', unlocked: false, progress: 85 },
    { id: 7, title: 'Night Owl', description: 'Study past midnight 5 times', icon: '🦉', unlocked: false, progress: 60 },
    { id: 8, title: 'Perfect Week', description: 'Meet all goals for 7 days', icon: '⭐', unlocked: false, progress: 71 },
  ],

  // Goals
  goals: {
    daily: [
      { id: 1, title: 'Walk 15,000 steps', progress: 83, category: 'fitness' },
      { id: 2, title: 'Drink 8 glasses of water', progress: 75, category: 'health' },
      { id: 3, title: 'Study for 6 hours', progress: 75, category: 'study' },
      { id: 4, title: 'Run 5 km', progress: 100, category: 'running' },
      { id: 5, title: 'Sleep 8 hours', progress: 94, category: 'health' },
    ],
  },

  // AI Insights
  insights: [
    { id: 1, type: 'positive', message: 'Your running pace improved by 3% this week! Keep it up! 🏃‍♂️' },
    { id: 2, type: 'suggestion', message: 'Try adding a morning stretch routine to improve your flexibility score.' },
    { id: 3, type: 'warning', message: 'Your sleep duration has been below target for 3 days. Consider an earlier bedtime.' },
    { id: 4, type: 'positive', message: 'Study streak milestone: 15 days! You\'re building incredible consistency! 🔥' },
  ],
};

function appReducer(state, action) {
  switch (action.type) {
    case 'TOGGLE_THEME':
      return { ...state, theme: state.theme === 'dark' ? 'light' : 'dark' };

    case 'ADD_TOAST':
      return { ...state, toasts: [...state.toasts, { id: Date.now(), ...action.payload }] };

    case 'REMOVE_TOAST':
      return { ...state, toasts: state.toasts.filter(t => t.id !== action.payload) };

    case 'UPDATE_STAT': {
      const { section, key, value } = action.payload;
      return {
        ...state,
        [section]: {
          ...state[section],
          [key]: typeof state[section][key] === 'object'
            ? { ...state[section][key], ...value }
            : value,
        },
      };
    }

    case 'ADD_WORKOUT':
      return {
        ...state,
        fitness: {
          ...state.fitness,
          workouts: [action.payload, ...state.fitness.workouts],
          todayCalories: state.fitness.todayCalories + action.payload.calories,
          todayDuration: state.fitness.todayDuration + action.payload.duration,
          todayExercises: state.fitness.todayExercises + 1,
        },
      };

    case 'ADD_RUN':
      return {
        ...state,
        running: {
          ...state.running,
          history: [action.payload, ...state.running.history],
        },
      };

    case 'TOGGLE_RUN_TRACKING':
      return {
        ...state,
        running: {
          ...state.running,
          isTracking: !state.running.isTracking,
        },
      };

    case 'UPDATE_CURRENT_RUN':
      return {
        ...state,
        running: {
          ...state.running,
          currentRun: { ...state.running.currentRun, ...action.payload },
        },
      };

    case 'ADD_WATER':
      return {
        ...state,
        health: {
          ...state.health,
          water: {
            ...state.health.water,
            current: Math.min(state.health.water.current + 1, 12),
          },
        },
        dashboard: {
          ...state.dashboard,
          water: {
            ...state.dashboard.water,
            current: +(state.dashboard.water.current + 0.25).toFixed(2),
          },
        },
      };

    case 'ADD_STUDY_SESSION':
      return {
        ...state,
        study: {
          ...state.study,
          today: {
            ...state.study.today,
            totalMinutes: state.study.today.totalMinutes + action.payload.duration,
            sessions: [...state.study.today.sessions, action.payload],
          },
        },
      };

    case 'TOGGLE_FOCUS_TIMER':
      return {
        ...state,
        study: {
          ...state.study,
          focusTimer: {
            ...state.study.focusTimer,
            isRunning: !state.study.focusTimer.isRunning,
          },
        },
      };

    case 'UPDATE_FOCUS_TIMER':
      return {
        ...state,
        study: {
          ...state.study,
          focusTimer: {
            ...state.study.focusTimer,
            ...action.payload,
          },
        },
      };

    case 'INCREMENT_STEPS':
      return {
        ...state,
        dashboard: {
          ...state.dashboard,
          steps: {
            ...state.dashboard.steps,
            current: state.dashboard.steps.current + action.payload,
          },
        },
      };

    case 'SIMULATE_LIVE_DATA': {
      const heartVariation = Math.floor(Math.random() * 6) - 3;
      return {
        ...state,
        health: {
          ...state.health,
          heartRate: {
            ...state.health.heartRate,
            current: Math.max(55, Math.min(100, state.health.heartRate.current + heartVariation)),
          },
        },
        dashboard: {
          ...state.dashboard,
          steps: {
            ...state.dashboard.steps,
            current: state.dashboard.steps.current + Math.floor(Math.random() * 15 + 5),
          },
          calories: {
            ...state.dashboard.calories,
            current: state.dashboard.calories.current + Math.floor(Math.random() * 3),
          },
        },
      };
    }

    default:
      return state;
  }
}

export function AppProvider({ children }) {
  const [state, dispatch] = useReducer(appReducer, initialState);

  // Apply theme
  useEffect(() => {
    document.documentElement.setAttribute('data-theme', state.theme);
  }, [state.theme]);

  // Simulate live data updates
  useEffect(() => {
    const interval = setInterval(() => {
      dispatch({ type: 'SIMULATE_LIVE_DATA' });
    }, 3000);
    return () => clearInterval(interval);
  }, []);

  // Toast auto-dismiss
  useEffect(() => {
    if (state.toasts.length > 0) {
      const timer = setTimeout(() => {
        dispatch({ type: 'REMOVE_TOAST', payload: state.toasts[0].id });
      }, 4000);
      return () => clearTimeout(timer);
    }
  }, [state.toasts]);

  const addToast = useCallback((type, message) => {
    dispatch({ type: 'ADD_TOAST', payload: { type, message } });
  }, []);

  return (
    <AppContext.Provider value={{ state, dispatch, addToast }}>
      {children}
    </AppContext.Provider>
  );
}

export function useApp() {
  const context = useContext(AppContext);
  if (!context) throw new Error('useApp must be used within AppProvider');
  return context;
}
