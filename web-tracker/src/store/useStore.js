import { create } from 'zustand';
import { persist } from 'zustand/middleware';

const initialRunData = {
  distance: 0,
  duration: 0,
  pace: 0,
  speed: 0,
  calories: 0,
  route: [], // Array of [lng, lat]
};

export const useStore = create(
  persist(
    (set) => ({
      // Theme State
      theme: 'dark',
      toggleTheme: () => set((state) => ({ theme: state.theme === 'dark' ? 'light' : 'dark' })),

      // Running State
      isRunning: false,
      isPaused: false,
      runData: initialRunData,
      runHistory: [],
      currentLocation: null,
      setCurrentLocation: (loc) => set({ currentLocation: loc }),

      // Actions
      startRun: () => set({ isRunning: true, isPaused: false, runData: initialRunData }),
      pauseRun: () => set({ isPaused: true }),
      resumeRun: () => set({ isPaused: false }),
      stopRun: () => set((state) => {
        // Save to history on stop
        const newHistory = [...state.runHistory, { ...state.runData, date: new Date().toISOString() }];
        return {
          isRunning: false,
          isPaused: false,
          runHistory: newHistory,
        };
      }),
      resetRun: () => set({ runData: initialRunData, isRunning: false, isPaused: false }),

      // Update Run Data (called dynamically during run)
      updateRunData: (newData) => set((state) => ({
        runData: { ...state.runData, ...newData },
      })),
      
      addRoutePoint: (point) => set((state) => ({
        runData: {
          ...state.runData,
          route: [...state.runData.route, point],
        }
      })),
    }),
    {
      name: 'running-tracker-storage', // unique name for local storage
      partialize: (state) => ({ runHistory: state.runHistory, theme: state.theme }), // Only persist history and theme
    }
  )
);
