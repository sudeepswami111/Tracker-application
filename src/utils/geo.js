/**
 * Calculates the great-circle distance between two points on a sphere
 * using the Haversine formula.
 *
 * @param {Array} coord1 - [latitude, longitude] of point 1
 * @param {Array} coord2 - [latitude, longitude] of point 2
 * @returns {number} Distance in kilometers
 */
export function calculateDistance(coord1, coord2) {
  if (!coord1 || !coord2) return 0;
  
  const [lat1, lon1] = coord1;
  const [lat2, lon2] = coord2;
  
  const R = 6371; // Earth's radius in kilometers
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLon = (lon2 - lon1) * Math.PI / 180;
  
  const a = 
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) * 
    Math.sin(dLon / 2) * Math.sin(dLon / 2);
    
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  const distance = R * c;
  
  return distance;
}
