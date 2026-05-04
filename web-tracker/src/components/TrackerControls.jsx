import React from 'react';
import { useStore } from '../store/useStore';
import { Play, Square, Pause } from 'lucide-react';

export function TrackerControls() {
  const { isRunning, isPaused, startRun, stopRun, pauseRun, resumeRun } = useStore();

  return (
    <div className="flex items-center justify-center gap-6 p-6 glass-card rounded-t-3xl md:rounded-3xl max-w-md mx-auto w-full backdrop-blur-xl">
      {!isRunning ? (
        <button
          onClick={startRun}
          className="flex flex-col items-center justify-center w-24 h-24 rounded-full bg-blue-600 hover:bg-blue-500 dark:bg-[var(--color-neon-cyan)] dark:hover:bg-cyan-400 text-white dark:text-slate-900 shadow-lg shadow-blue-500/30 transition-transform active:scale-95"
        >
          <Play className="w-10 h-10 ml-1" fill="currentColor" />
          <span className="font-bold uppercase tracking-wider text-xs mt-1">Start</span>
        </button>
      ) : (
        <>
          {isPaused ? (
            <button
              onClick={resumeRun}
              className="flex flex-col items-center justify-center w-20 h-20 rounded-full bg-emerald-500 hover:bg-emerald-400 text-white shadow-lg transition-transform active:scale-95"
            >
              <Play className="w-8 h-8 ml-1" fill="currentColor" />
            </button>
          ) : (
            <button
              onClick={pauseRun}
              className="flex flex-col items-center justify-center w-20 h-20 rounded-full bg-amber-500 hover:bg-amber-400 text-white shadow-lg transition-transform active:scale-95"
            >
              <Pause className="w-8 h-8" fill="currentColor" />
            </button>
          )}

          <button
            onClick={stopRun}
            className="flex flex-col items-center justify-center w-24 h-24 rounded-full bg-rose-600 hover:bg-rose-500 text-white shadow-lg shadow-rose-500/30 transition-transform active:scale-95"
          >
            <Square className="w-8 h-8" fill="currentColor" />
            <span className="font-bold uppercase tracking-wider text-xs mt-1">Stop</span>
          </button>
        </>
      )}
    </div>
  );
}
