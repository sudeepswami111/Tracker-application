import React from 'react';
import { useStore } from '../store/useStore';
import { Clock, Activity, Zap, Flame, MapPin } from 'lucide-react';

export function StatsPanel() {
  const { runData } = useStore();

  const formatTime = (seconds) => {
    const hrs = Math.floor(seconds / 3600);
    const mins = Math.floor((seconds % 3600) / 60);
    const secs = seconds % 60;
    if (hrs > 0) {
      return `${hrs}:${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
    }
    return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
  };

  const formatPace = (paceMinutes) => {
    if (!paceMinutes || paceMinutes === 0 || !isFinite(paceMinutes)) return "0:00";
    const mins = Math.floor(paceMinutes);
    const secs = Math.floor((paceMinutes - mins) * 60);
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  };

  return (
    <div className="flex flex-col gap-4 p-4 lg:p-6 h-full overflow-y-auto glass-card">
      <div className="flex items-center justify-between mb-2">
        <h2 className="text-2xl font-bold tracking-tight">Current Run</h2>
        <Activity className="w-6 h-6 text-blue-500 dark:text-[var(--color-neon-cyan)]" />
      </div>

      <div className="grid grid-cols-2 gap-4 lg:grid-cols-1 xl:grid-cols-2">
        {/* Distance Card */}
        <div className="bg-white/50 dark:bg-slate-800/50 p-4 rounded-2xl border border-slate-200 dark:border-slate-700 shadow-sm flex flex-col">
          <div className="flex items-center gap-2 text-slate-500 dark:text-slate-400 mb-1">
            <MapPin className="w-4 h-4" />
            <span className="text-sm font-medium uppercase tracking-wider">Distance</span>
          </div>
          <div className="flex items-baseline gap-1">
            <span className="text-4xl font-extrabold">{runData.distance.toFixed(2)}</span>
            <span className="text-lg font-medium text-slate-500 dark:text-slate-400">km</span>
          </div>
        </div>

        {/* Duration Card */}
        <div className="bg-white/50 dark:bg-slate-800/50 p-4 rounded-2xl border border-slate-200 dark:border-slate-700 shadow-sm flex flex-col">
          <div className="flex items-center gap-2 text-slate-500 dark:text-slate-400 mb-1">
            <Clock className="w-4 h-4" />
            <span className="text-sm font-medium uppercase tracking-wider">Time</span>
          </div>
          <div className="flex items-baseline gap-1">
            <span className="text-4xl font-extrabold">{formatTime(runData.duration)}</span>
          </div>
        </div>

        {/* Pace Card */}
        <div className="bg-white/50 dark:bg-slate-800/50 p-4 rounded-2xl border border-slate-200 dark:border-slate-700 shadow-sm flex flex-col">
          <div className="flex items-center gap-2 text-slate-500 dark:text-slate-400 mb-1">
            <Activity className="w-4 h-4" />
            <span className="text-sm font-medium uppercase tracking-wider">Avg Pace</span>
          </div>
          <div className="flex items-baseline gap-1">
            <span className="text-3xl font-extrabold">{formatPace(runData.pace)}</span>
            <span className="text-sm font-medium text-slate-500 dark:text-slate-400">/km</span>
          </div>
        </div>

        {/* Speed Card */}
        <div className="bg-white/50 dark:bg-slate-800/50 p-4 rounded-2xl border border-slate-200 dark:border-slate-700 shadow-sm flex flex-col">
          <div className="flex items-center gap-2 text-slate-500 dark:text-slate-400 mb-1">
            <Zap className="w-4 h-4" />
            <span className="text-sm font-medium uppercase tracking-wider">Speed</span>
          </div>
          <div className="flex items-baseline gap-1">
            <span className="text-3xl font-extrabold">{runData.speed.toFixed(1)}</span>
            <span className="text-sm font-medium text-slate-500 dark:text-slate-400">km/h</span>
          </div>
        </div>

        {/* Calories Card */}
        <div className="bg-white/50 dark:bg-slate-800/50 p-4 rounded-2xl border border-slate-200 dark:border-slate-700 shadow-sm flex flex-col col-span-2 lg:col-span-1 xl:col-span-2">
          <div className="flex items-center gap-2 text-slate-500 dark:text-slate-400 mb-1">
            <Flame className="w-4 h-4 text-orange-500" />
            <span className="text-sm font-medium uppercase tracking-wider">Calories</span>
          </div>
          <div className="flex items-baseline gap-1">
            <span className="text-3xl font-extrabold">{Math.floor(runData.calories)}</span>
            <span className="text-sm font-medium text-slate-500 dark:text-slate-400">kcal</span>
          </div>
        </div>
      </div>
    </div>
  );
}
