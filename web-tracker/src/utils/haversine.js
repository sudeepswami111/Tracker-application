/**
 * Calculates the distance between two points on the Earth's surface using the Haversine formula.
 * @param {number[]} point1 - [longitude, latitude]
 * @param {number[]} point2 - [longitude, latitude]
 * @returns {number} Distance in kilometers
 */
export function calculateDistance(point1, point2) {
  if (!point1 || !point2) return 0;
  
  const [lon1, lat1] = point1;
  const [lon2, lat2] = point2;

  const R = 6371; // Earth's radius in kilometers
  const dLat = (lat2 - lat1) * (Math.PI / 180);
  const dLon = (lon2 - lon1) * (Math.PI / 180);
  
  const a = 
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(lat1 * (Math.PI / 180)) * Math.cos(lat2 * (Math.PI / 180)) * 
    Math.sin(dLon / 2) * Math.sin(dLon / 2);
    
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  const distance = R * c; // Distance in km
  
  return distance;
}
