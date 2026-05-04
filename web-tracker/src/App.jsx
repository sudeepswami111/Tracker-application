import React, { useEffect } from 'react';
import { MapComponent } from './components/MapComponent';
import { StatsPanel } from './components/StatsPanel';
import { TrackerControls } from './components/TrackerControls';
import { useGeolocation } from './hooks/useGeolocation';
import { useRunTracker } from './hooks/useRunTracker';
import { useStore } from './store/useStore';
import { Moon, Sun } from 'lucide-react';

function App() {
  const { theme, toggleTheme } = useStore();
  
  // Initialize Global Trackers
  useGeolocation();
  useRunTracker();

  // Apply Dark Mode Class to HTML
  useEffect(() => {
    if (theme === 'dark') {
      document.documentElement.classList.add('dark');
    } else {
      document.documentElement.classList.remove('dark');
    }
  }, [theme]);

  return (
    <div className={`flex flex-col md:flex-row h-screen w-full overflow-hidden ${theme === 'dark' ? 'bg-slate-900 text-white' : 'bg-slate-50 text-slate-900'}`}>
      
      {/* Theme Toggler (Floating) */}
      <button 
        onClick={toggleTheme}
        className="absolute top-4 right-4 z-50 p-3 rounded-full glass-card hover:scale-105 transition-transform"
      >
        {theme === 'dark' ? <Sun className="w-6 h-6 text-yellow-400" /> : <Moon className="w-6 h-6 text-slate-700" />}
      </button>

      {/* Map Area */}
      <div className="relative flex-1 md:w-2/3 lg:w-3/4 h-[60vh] md:h-full">
        <MapComponent />
      </div>

      {/* Side / Bottom Panel */}
      <div className="flex flex-col md:w-1/3 lg:w-1/4 h-[40vh] md:h-full bg-white dark:bg-slate-900 z-20 shadow-2xl md:border-l border-slate-200 dark:border-slate-800">
        
        {/* Stats Section */}
        <div className="flex-1 overflow-y-auto">
          <StatsPanel />
        </div>

        {/* Controls Section */}
        <div className="p-4 bg-slate-50 dark:bg-slate-800/50 border-t border-slate-200 dark:border-slate-700">
          <TrackerControls />
        </div>
      </div>
      
    </div>
  );
}

export default App;
