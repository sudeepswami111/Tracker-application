import { useState, useEffect } from 'react';
import { useStore } from '../store/useStore';

export function useGeolocation() {
  const { setCurrentLocation, currentLocation } = useStore();
  const [error, setError] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!navigator.geolocation) {
      setError('Geolocation is not supported by your browser');
      setLoading(false);
      return;
    }

    const watchId = navigator.geolocation.watchPosition(
      (position) => {
        // Mapbox uses [lng, lat] format
        setCurrentLocation([position.coords.longitude, position.coords.latitude]);
        setLoading(false);
        setError(null);
      },
      (err) => {
        setError(err.message);
        setLoading(false);
      },
      {
        enableHighAccuracy: true,
        maximumAge: 0,
        timeout: 5000,
      }
    );

    return () => navigator.geolocation.clearWatch(watchId);
  }, []);

  return { currentLocation, error, loading };
}
