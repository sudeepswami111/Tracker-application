import React, { useEffect, useRef } from 'react';
import { MapContainer, TileLayer, Polyline, Marker, useMap } from 'react-leaflet';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import { useStore } from '../store/useStore';

// Custom Marker Icon for Live Location
const liveMarkerIcon = new L.DivIcon({
  className: 'live-location-marker',
  html: `<div class="w-4 h-4 bg-blue-500 border-2 border-white rounded-full shadow-[0_0_0_4px_rgba(59,130,246,0.3)] animate-pulse"></div>`,
  iconSize: [16, 16],
  iconAnchor: [8, 8]
});

// Component to handle auto-panning
function MapController({ center }) {
  const map = useMap();
  
  useEffect(() => {
    if (center) {
      map.setView(center, map.getZoom(), {
        animate: true,
        duration: 1.0
      });
    }
  }, [center, map]);

  return null;
}

export function MapComponent() {
  const { currentLocation, runData, theme } = useStore();

  if (!currentLocation) {
    return (
      <div className="absolute inset-0 flex items-center justify-center bg-gray-900/50 z-10 backdrop-blur-sm">
        <div className="text-white flex flex-col items-center">
          <div className="w-10 h-10 border-4 border-t-blue-500 border-gray-300 rounded-full animate-spin mb-4"></div>
          <p className="font-semibold tracking-wide">Acquiring GPS Signal...</p>
        </div>
      </div>
    );
  }

  // Convert [lng, lat] from store to [lat, lng] for Leaflet
  const leafletCenter = [currentLocation[1], currentLocation[0]];
  const leafletRoute = runData.route.map(pt => [pt[1], pt[0]]);

  // Select Tile URL based on theme
  const tileUrl = theme === 'dark' 
    ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
    : 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';

  const tileAttribution = theme === 'dark'
    ? '&copy; <a href="https://carto.com/attributions">CARTO</a>'
    : '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors';

  return (
    <div className="w-full h-full relative z-0">
      <MapContainer 
        center={leafletCenter} 
        zoom={16} 
        style={{ width: '100%', height: '100%', zIndex: 0 }}
        zoomControl={false}
      >
        <TileLayer
          url={tileUrl}
          attribution={tileAttribution}
        />
        
        {leafletRoute.length > 0 && (
          <Polyline 
            positions={leafletRoute} 
            color={theme === 'dark' ? '#00f3ff' : '#3b82f6'} 
            weight={6} 
            opacity={0.8}
            lineCap="round"
            lineJoin="round"
          />
        )}
        
        <Marker position={leafletCenter} icon={liveMarkerIcon} />
        
        <MapController center={leafletCenter} />
      </MapContainer>
    </div>
  );
}
