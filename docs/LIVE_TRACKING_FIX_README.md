# Live Running Tracking Fix — Gemini 3.1 Pro High Prompt

## Goal

Fix the Live Running / Live Tracking screen in the Flutter fitness app.

Currently, only the workout duration/timer is working.

Not working:

- Pace stays `--:-- /km`
- Distance stays `0.00 km`
- Heart Rate stays `-- bpm`
- Live running/walking route line is not showing on the map

---

## Copy-Paste Prompt for Gemini 3.1 Pro High

```text
You are an expert senior Flutter engineer specializing in live GPS tracking, Flutter Map, Health Connect, wearable health data, distance calculation, pace calculation, map polylines, and production fitness app debugging.

Fix the Live Running / Live Tracking screen in my Flutter fitness app.

CURRENT ISSUE:
The timer/duration is working, but these are still not working:
1. Pace stays `--:-- /km`
2. Distance stays `0.00 km`
3. Heart Rate stays `-- bpm`
4. Live running/walking line/polyline is not showing on the map

Antigravity found the exact technical reasons:

1. Heart Rate issue:
`fetchHealthData()` in `WatchConnectionManager` tries to fetch Heart Rate, SpO2, Blood Pressure, Steps, and Sleep inside one single try-catch block.

Health Connect throws an exception when reading BLOOD_PRESSURE:
`BLOOD_PRESSURE to read record type class android.health.connect.datatype`

Because Blood Pressure fails, the whole try-catch block aborts early and returns null for everything, including Heart Rate. So Heart Rate stays `-- bpm`.

2. Distance / Pace / Live Line issue:
The GPS filter is too strict:

if (p.accuracy > 30) return;

and distance filter:

distFromLast >= 2.0

When testing indoors, GPS accuracy can be 50–100 meters. Because accuracy is worse than 30 meters, all GPS points are ignored. Since points are ignored:
- `_gpsRoute` never receives points
- polyline is not drawn
- distance never updates
- pace never updates

3. UI crash/freezing issue:
There is a Flutter error:

setState() or markNeedsBuild() called during build

In `running_screen.dart`, `FlutterMap` has `onPositionChanged` calling:

setState(() {
  _mapRotation = rot;
});

`FlutterMap` can fire `onPositionChanged` while the widget is still building. Calling setState during build causes framework exceptions and breaks the screen updates.

GOAL:
Fix all 3 root causes properly.

The final result must be:
- Duration continues working
- Distance updates from GPS movement
- Pace updates based on distance and duration
- Live route polyline appears on map
- Heart Rate shows real value if available
- Heart Rate shows `-- bpm` if unavailable
- Health Connect Blood Pressure failure must not break Heart Rate fetching
- No `setState() called during build` error
- App should work better for indoor testing and outdoor real GPS tracking

FILES TO INSPECT:
- `running_screen.dart`
- `live_run_screen.dart`
- `watch_connection_manager.dart`
- `health_service.dart`
- `watch_metrics_provider.dart`
- `running_provider.dart`
- any live tracking provider/service
- any map widget using FlutterMap
- any Health Connect fetch method
- AndroidManifest.xml
- pubspec.yaml

PART 1 — FIX HEALTH CONNECT HEART RATE FAILURE

Problem:
Blood Pressure fetch failure is breaking all health data fetches.

Required fix:
Separate every Health Connect metric fetch into its own safe try-catch.

Do NOT fetch all health metrics in one giant try-catch.

Change from this bad pattern:

try {
  heartRate = await fetchHeartRate();
  spO2 = await fetchSpO2();
  bloodPressure = await fetchBloodPressure();
  steps = await fetchSteps();
  sleep = await fetchSleep();
} catch (e) {
  return null;
}

To this safe pattern:

final heartRate = await _safeFetchHeartRate();
final spO2 = await _safeFetchSpO2();
final bloodPressure = await _safeFetchBloodPressure();
final steps = await _safeFetchSteps();
final sleep = await _safeFetchSleep();

Each metric should fail independently.

Example:

Future<int?> _safeFetchHeartRate() async {
  try {
    return await fetchHeartRate();
  } catch (e, st) {
    debugPrint('Heart rate fetch failed: $e');
    return null;
  }
}

Future<BloodPressureData?> _safeFetchBloodPressure() async {
  try {
    return await fetchBloodPressure();
  } catch (e, st) {
    debugPrint('Blood pressure fetch failed: $e');
    return null;
  }
}

Expected:
If Blood Pressure fails, Heart Rate should still load.

Also:
- Do not show fake `0 bpm`
- Use nullable int: `int? heartRate`
- UI should display: `heartRate == null ? '--' : heartRate.toString()`

PART 2 — FIX HEALTH CONNECT PERMISSIONS

Check Health Connect permissions separately.

If Blood Pressure permission is missing:
- do not crash
- skip blood pressure
- continue fetching heart rate

Before reading each record type:
- check if permission is granted if the package supports it
- otherwise catch permission exception safely

Required behavior:
- Heart Rate permission denied → only heart rate unavailable
- Blood Pressure permission denied → only blood pressure unavailable
- One metric failure must not break other metrics

PART 3 — FIX GPS ACCURACY FILTER

Current strict filter:

if (p.accuracy > 30) return;

This blocks indoor testing and weak GPS.

Improve it with adaptive accuracy filtering.

Use different thresholds:

const double idealAccuracyMeters = 30;
const double fallbackAccuracyMeters = 100;

Rules:
1. If accuracy <= 30m: accept point normally.
2. If accuracy > 30m and <= 100m: accept point but mark GPS status as “Low accuracy”.
3. If accuracy > 100m: ignore point and show “Waiting for better GPS...”.

Suggested logic:

bool _isAcceptableGpsPoint(Position p, Position? last) {
  if (p.accuracy <= 30) return true;
  if (p.accuracy <= 100) return true;
  return false;
}

Also show GPS status:
- GPS Ready
- Low GPS Accuracy
- Waiting for GPS

PART 4 — FIX DISTANCE FILTER

Current distance filter may be too strict:

distFromLast >= 2.0

Keep it, but make sure first point is added.

Required behavior:
- First valid GPS point should always be added to `_gpsRoute`
- Do not calculate distance for first point
- From second point onward, calculate segment distance

Example:

if (_lastPosition == null) {
  _lastPosition = position;
  _gpsRoute.add(LatLng(position.latitude, position.longitude));
  notifyListeners();
  return;
}

final segmentMeters = Geolocator.distanceBetween(
  _lastPosition!.latitude,
  _lastPosition!.longitude,
  position.latitude,
  position.longitude,
);

if (segmentMeters >= 1.5) {
  totalDistanceMeters += segmentMeters;
  _gpsRoute.add(LatLng(position.latitude, position.longitude));
  _lastPosition = position;
  notifyListeners();
}

For indoor testing, allow smaller movement threshold: 1.5m to 2m.

PART 5 — FIX LIVE POLYLINE

Make sure `_gpsRoute` or `liveRoutePoints` is connected to the map polyline layer.

If using FlutterMap:

PolylineLayer(
  polylines: [
    if (_gpsRoute.length >= 2)
      Polyline(
        points: _gpsRoute,
        color: Colors.cyanAccent,
        strokeWidth: 5,
      ),
  ],
)

Important:
- Polyline should only require at least 2 points
- Line color must be visible on dark map
- Stroke width should be 5 or 6
- PolylineLayer must be above TileLayer
- State update must happen after adding GPS points

Add debug logs:

debugPrint('GPS route points: ${_gpsRoute.length}');
debugPrint('Total distance: $totalDistanceMeters');

PART 6 — FIX DISTANCE UI

Distance UI should read from the same state variable that GPS updates.

Example:

final distanceKm = totalDistanceMeters / 1000;

Display:

distanceKm.toStringAsFixed(2)

Make sure:
- GPS updates `totalDistanceMeters`
- UI reads `totalDistanceMeters`
- no duplicate stale distance variable exists
- notifyListeners/setState is called after update

PART 7 — FIX PACE CALCULATION

Pace should calculate only after enough movement.

Rules:
- if distance < 0.01 km, show `--:--`
- otherwise:

final distanceKm = totalDistanceMeters / 1000;
final paceSecondsPerKm = elapsedSeconds / distanceKm;

Format:

String formatPace(double secondsPerKm) {
  if (secondsPerKm.isNaN || secondsPerKm.isInfinite || secondsPerKm <= 0) {
    return '--:--';
  }

  final minutes = secondsPerKm ~/ 60;
  final seconds = (secondsPerKm % 60).round();

  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}

Display: `05:30 /km`

PART 8 — FIX setState CALLED DURING BUILD

Problem code:
`FlutterMap.onPositionChanged` calls setState directly.

Bad:

onPositionChanged: (position, hasGesture) {
  setState(() {
    _mapRotation = rot;
  });
}

Fix:
Use post-frame callback or avoid setState if value has not changed.

Safe version:

onPositionChanged: (position, hasGesture) {
  final rot = position.rotation ?? 0.0;

  if ((_mapRotation - rot).abs() < 0.1) return;

  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) return;
    setState(() {
      _mapRotation = rot;
    });
  });
}

Even better:
- Do not update `_mapRotation` unless actually needed
- Avoid frequent setState from map callbacks
- Use ValueNotifier if appropriate

Also check every map callback for unsafe setState during build.

PART 9 — FIX LOCATION STREAM

Ensure location stream actually starts when live run starts.

Required:
- use `Geolocator.getPositionStream`
- store subscription
- cancel on dispose/end run
- do not only call `getCurrentPosition`

Example:

_positionSub = Geolocator.getPositionStream(
  locationSettings: const LocationSettings(
    accuracy: LocationAccuracy.bestForNavigation,
    distanceFilter: 2,
  ),
).listen(
  _onPositionUpdate,
  onError: (e) {
    debugPrint('GPS stream error: $e');
  },
);

If `bestForNavigation` is problematic on Android, use:

AndroidSettings(
  accuracy: LocationAccuracy.high,
  distanceFilter: 2,
  intervalDuration: Duration(seconds: 2),
)

PART 10 — FIX PAUSE/RESUME

When paused:
- do not add GPS points
- do not add distance
- do not update pace
- duration pause behavior should remain as currently implemented

When resumed:
- reset `_lastPosition` to current position or next valid position
- prevent jump distance after pause

PART 11 — IMPROVE GPS TESTING UX

Because indoor testing may not produce real movement, add visible GPS messages.

If no route points after 10 seconds:

Waiting for movement...
GPS accuracy may be low indoors.
Try walking outdoors for better tracking.

If accuracy > 30:

Low GPS accuracy: 65m
Distance may update slowly.

PART 12 — HEART RATE UI

Current UI shows `-- bpm`, which is okay when no data exists.

But make sure:
- it does not show `0 bpm`
- it has source status:
  - Health Connect
  - Watch
  - No data

Example UI:

HEART RATE
-- bpm
No data

If heart rate exists:

HEART RATE
72 bpm
Health Connect

PART 13 — DEBUG LOGS REQUIRED

Add clear logs.

For Health:

Fetching health data...
Heart rate fetch started
Heart rate value: 72
Blood pressure fetch failed: permission denied
SpO2 fetch result: null
Health data fetch completed

For GPS:

Tracking started
Location permission: granted
GPS stream started
GPS point received: lat=..., lng=..., accuracy=...
GPS accepted: true
Segment distance: 2.4m
Total distance: 24.5m
Route points count: 12
Pace: 06:12

For Map:

Polyline points rendered: 12
Map rotation updated safely

PART 14 — EXPECTED FINAL RESULT

After the fix:

1. Heart Rate:
- Blood Pressure failure does not block Heart Rate
- Heart Rate displays if available
- If no data, shows `-- bpm`
- No fake 0 bpm

2. Distance:
- GPS movement updates distance
- Indoors with weak GPS shows warning instead of silently ignoring all points
- Outdoors works accurately

3. Pace:
- stays `--:--` until enough distance exists
- then updates correctly

4. Live Line:
- route points are added
- polyline appears on the map
- line is clearly visible

5. UI:
- no `setState() called during build` error
- map does not freeze
- tracking screen remains responsive

Generate complete Flutter/Dart fixes for:
- `WatchConnectionManager.fetchHealthData`
- individual safe health metric fetches
- GPS position stream logic
- adaptive GPS accuracy filtering
- distance calculation
- pace calculation
- live polyline drawing
- safe map setState handling
- UI no-data states
- debug logs
```

---

## Quick Testing Checklist

After Gemini/Claude updates the code, test these:

- [ ] Start outdoor run
- [ ] Location permission is granted
- [ ] GPS status is visible
- [ ] Duration starts
- [ ] First GPS point is added
- [ ] Route points count increases while moving
- [ ] Distance increases after movement
- [ ] Pace appears after distance is available
- [ ] Live route line appears on map
- [ ] Pause stops adding distance
- [ ] Resume continues safely
- [ ] Heart rate does not show fake `0 bpm`
- [ ] Blood pressure failure does not break heart rate
- [ ] No `setState() called during build` error

---

## Notes

For accurate testing, walk outdoors for at least 1–2 minutes. Indoor GPS can be weak and may not produce reliable distance updates.

If Health Connect has no heart-rate data, the app should show:

```text
-- bpm
No data
```

It should not show:

```text
0 bpm
```
