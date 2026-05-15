# 🌦️ Weather Accuracy Improvement — LifePulse

## The Problem

The weather details in LifePulse differ from the phone's native weather app (The Weather Channel). This is partly **expected** (different data sources always vary slightly), but some gaps are fixable. This document explains why the differences occur and lays out a clear plan to improve accuracy.

---

## Why the Differences Exist (Root Cause Analysis)

| Issue | Current Behaviour | Why It Happens |
|---|---|---|
| **AQI mismatch** | App shows 22, phone shows 65 | App uses Indian NAQI; phone uses US AQI / generic global index |
| **"Clear Sky" vs "Haze"** | Different condition labels | Open-Meteo codes only on cloud cover; phone app factors visibility & particulates |
| **Forecast discrepancy (Thunderstorm vs Sunny)** | App shows Saturday Thunderstorm; phone shows Sunny | Different weather models disagree on convective instability |
| **Location name mismatch** | App shows "Waghodia", phone shows "Limda" | Different reverse-geocoding databases pick different sub-area names |
| **Temperature accuracy** | Minor differences possible | Open-Meteo uses global models (GFS/ECMWF); phone app uses IBM's private station network |

> **Verdict:** AQI discrepancy and condition label are the two most user-visible and most fixable issues. The forecast divergence and location name are inherent to different data providers and not fully solvable without switching APIs.

---

## Improvement Plan

---

### Phase 1 — Your Responsibilities (No Code Changes Needed)

These are things **you (Sudeep) should decide** before giving work to the developer.

#### 1.1 — Decide on the AQI Standard to Display
Currently the app calculates **Indian NAQI (National Air Quality Index)**, which correctly gives a low score (22) for mildly polluted air. The phone shows **65 on a different scale**.

**You need to decide:**
- Option A: Keep Indian NAQI (22) — correct for Indian users, but confusing when compared to phone apps
- Option B: Show **both** — Indian NAQI for fitness advice + a note saying "Indian Standard"
- Option C: Switch to the same AQI scale as The Weather Channel (US AQI / AQICN global index)

> **Recommendation:** Keep Indian NAQI but add a label like `AQI (IN) 22` with a small tooltip explaining the Indian standard. This is already partially done in the UI.

#### 1.2 — Decide on Condition Description Granularity
The app shows "Clear Sky" because Open-Meteo's weather code is 0 (no clouds). But visibility is low due to haze — which is an air quality / visibility metric, not a cloud cover metric.

**You need to decide:**
- Option A: Keep current simple labels ("Clear Sky", "Partly Cloudy")
- Option B: Combine weather code + AQI/visibility to show richer labels like "Clear but Hazy"

> **Recommendation:** Option B — combine the existing AQI data (already fetched) with the weather code label.

#### 1.3 — Decide on the Forecast Data Source
Open-Meteo is free and good but sometimes diverges from phone apps on short-range forecasts. If accuracy is a top priority:

**You need to decide:**
- Option A: Stay with Open-Meteo (free, already integrated)
- Option B: Switch to **OpenWeatherMap** (free tier available, closer to what most phone apps use)
- Option C: Switch to **WeatherAPI.com** (free tier, very accurate for India, includes "haze" condition label natively)

> **Recommendation:** Evaluate **WeatherAPI.com** — it has a free tier (1M calls/month), natively supports "Haze" condition codes, and its India data tends to match local phone apps more closely.

---

### Phase 2 — What Antigravity (Developer) Should Do

Once you've made the decisions in Phase 1, share this document with Antigravity and ask them to implement the following:

---

#### Phase 2A — AQI Label Fix (Quick Win, 1–2 hours)

**File:** `lib/widgets/weather_widgets.dart` and `lib/screens/dashboard_screen.dart`

**Task:**
- Add a small label/tooltip next to the AQI badge that says **"IN Standard"** or **"Indian NAQI"**
- This immediately explains to the user why the number differs from their phone app
- No API changes needed — the calculation is already correct

**Prompt to give Antigravity:**
> In `weather_widgets.dart` and wherever the AQI badge is rendered, add a small subtitle or tooltip below/beside the AQI number that says "Indian NAQI Standard". This should be a small text widget, styled in a muted/secondary color, so users understand this uses the Indian National Air Quality Index and not the US AQI used by most phone weather apps.

---

#### Phase 2B — "Hazy" Condition Label (Quick Win, 1–2 hours)

**File:** `lib/services/weather_service.dart` → weather code to label mapping
**File:** `lib/models/weather_model.dart` → `getConditionText()` or similar

**Task:**
- After fetching AQI data, if the AQI (Indian NAQI) is above 100 **and** the weather code is 0 (Clear Sky), override the condition label to **"Clear but Hazy"**
- If AQI > 150, label it **"Hazy"** outright

**Prompt to give Antigravity:**
> In `weather_service.dart`, after both the weather data and AQI data are fetched, add a post-processing step to refine the condition label. If the weather code maps to "Clear Sky" (code 0) but the calculated Indian NAQI is above 100, change the displayed condition string to "Clear but Hazy". If NAQI > 150, use "Hazy". This logic should run before the `WeatherModel` is constructed and cached. The condition string should be stored as a field in `WeatherModel` so the UI can display it directly.

---

#### Phase 2C — Hourly Forecast Index Fix (Medium, 2–3 hours)

**File:** `lib/services/weather_service.dart`

**Current Bug:** The hourly forecast always fetches index `0–23` from the Open-Meteo response, which are the first 24 entries starting from midnight of the current day — not the next 24 hours from now.

**Task:**
- Find the current hour's index in the `hourly['time']` list
- Slice from the current hour index, not from index 0
- This fixes the situation where morning data shows stale overnight forecasts

**Prompt to give Antigravity:**
> In `weather_service.dart`, the hourly forecast loop currently iterates `for (int i = 0; i < 24; i++)`. This always starts from index 0 (midnight of today), not the current hour. Fix this by finding the index in `hourly['time']` whose `DateTime` matches or is closest to `DateTime.now()`, then slicing 24 entries from that index onward. Make sure the slice doesn't overflow the array (Open-Meteo returns 168 hours, so there is enough data).

---

#### Phase 2D — Smarter Location Name (Medium, 1–2 hours)

**File:** `lib/services/weather_service.dart` → reverse geocoding block

**Current Behaviour:** Uses Flutter's `geocoding` package which picks the `locality` field — sometimes a sub-district like "Waghodia" rather than the nearest known town "Limda".

**Task:**
- Prefer `subLocality` → `locality` → `subAdministrativeArea` in that priority order
- Or, use the **Open-Meteo geocoding API** (free) to reverse-lookup the name, which often gives more recognisable locality names

**Prompt to give Antigravity:**
> In `weather_service.dart`, update the reverse geocoding logic to prefer `placemarks.first.subLocality` first if it is non-null and non-empty, then fall back to `locality`, then `subAdministrativeArea`, then `administrativeArea`. This tends to return the more locally recognisable area name. Also add a null/empty string check before using each field.

---

#### Phase 2E — (Optional) Switch to WeatherAPI.com (Large, 4–6 hours)

Only do this if Open-Meteo accuracy is still unsatisfactory after Phases 2A–2D.

**Task:**
- Register for a free API key at [weatherapi.com](https://www.weatherapi.com)
- Refactor `WeatherService` to call WeatherAPI's `/current.json` and `/forecast.json` endpoints
- Map WeatherAPI's condition codes to the app's existing condition label system
- WeatherAPI natively returns "Haze", "Mist", "Thundery outbreaks" etc., making condition labels far more accurate
- Store the API key in `.env` alongside the existing Supabase keys

**Prompt to give Antigravity:**
> Refactor `lib/services/weather_service.dart` to use **WeatherAPI.com** instead of Open-Meteo. The API key should be stored in `.env` as `WEATHER_API_KEY` and loaded via `flutter_dotenv` (already in the project). Use the `/v1/current.json` endpoint for current conditions and `/v1/forecast.json?days=7` for the 7-day forecast. Map WeatherAPI's `condition.text` directly to the condition label shown in the UI (no custom mapping needed — it already returns human-readable strings like "Haze", "Partly cloudy", "Thundery outbreaks in nearby"). For AQI, WeatherAPI also returns `air_quality` in the response (pass `&aqi=yes`) — use its `us-epa-index` for a secondary display and continue using the Indian NAQI calculation from the existing `_calculateIndianAqi()` method for the fitness advice card. Preserve all existing `WeatherModel` fields and the Hive caching logic.

---

## Summary Checklist

### You (Sudeep) — Decisions Before Handoff
- [ ] Decide: Keep Indian NAQI or switch to US AQI or show both?
- [ ] Decide: Add "Clear but Hazy" combined label?
- [ ] Decide: Stay on Open-Meteo or switch to WeatherAPI.com?

### Antigravity — Implementation Phases
- [ ] **Phase 2A** — Add "Indian NAQI Standard" label to AQI badge
- [ ] **Phase 2B** — Add Hazy condition label when AQI is high but sky is clear
- [ ] **Phase 2C** — Fix hourly forecast to start from current hour, not midnight
- [ ] **Phase 2D** — Improve location name using subLocality priority
- [ ] **Phase 2E** *(Optional)* — Migrate to WeatherAPI.com for better India accuracy

---

## Quick Reference: Files Antigravity Will Touch

| File | Phase |
|---|---|
| `lib/widgets/weather_widgets.dart` | 2A |
| `lib/services/weather_service.dart` | 2B, 2C, 2D, 2E |
| `lib/models/weather_model.dart` | 2B, 2E |
| `.env` | 2E |

---

*Document prepared for LifePulse v1.0.0 — May 2026*
