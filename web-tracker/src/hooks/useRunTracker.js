import { useEffect, useRef } from 'react';
import { useStore } from '../store/useStore';
import { calculateDistance } from '../utils/haversine';

export function useRunTracker() {
  const { isRunning, isPaused, currentLocation } = useStore();
  const lastLocationRef = useRef(null);
  const timerRef = useRef(null);

  // Timer Effect
  useEffect(() => {
    if (isRunning && !isPaused) {
      timerRef.current = setInterval(() => {
        const { runData, updateRunData } = useStore.getState();
        updateRunData({ duration: runData.duration + 1 });
      }, 1000);
    } else {
      if (timerRef.current) clearInterval(timerRef.current);
    }

    return () => {
      if (timerRef.current) clearInterval(timerRef.current);
    };
  }, [isRunning, isPaused]);

  // Location Tracking Effect
  useEffect(() => {
    if (isRunning && !isPaused && currentLocation) {
      const { runData, addRoutePoint, updateRunData } = useStore.getState();
      
      // If it's the first point in the run
      if (runData.route.length === 0) {
        addRoutePoint(currentLocation);
        lastLocationRef.current = currentLocation;
        return;
      }

      // If we have a previous location, calculate distance
      if (lastLocationRef.current) {
        const dist = calculateDistance(lastLocationRef.current, currentLocation);
        
        // Only update if we moved a significant amount (e.g. > 5 meters) to avoid GPS jitter
        if (dist > 0.005) {
          addRoutePoint(currentLocation);
          const newTotalDistance = runData.distance + dist;
          
          // Calculate speed (km/h) and pace (min/km)
          const durationHours = runData.duration / 3600;
          const currentSpeed = durationHours > 0 ? (newTotalDistance / durationHours) : 0;
          const currentPace = currentSpeed > 0 ? (60 / currentSpeed) : 0;
          
          // Rough calorie calculation (approx 65 calories per km)
          const calories = newTotalDistance * 65;

          updateRunData({
            distance: newTotalDistance,
            speed: currentSpeed,
            pace: currentPace,
            calories: calories,
          });

          lastLocationRef.current = currentLocation;
        }
      }
    }
  }, [currentLocation, isRunning, isPaused]);
}
