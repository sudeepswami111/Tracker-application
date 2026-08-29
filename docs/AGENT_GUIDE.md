# Agent Guide: LifePulse Health Tracker

This document provides a high-level architectural overview of the LifePulse project to help AI agents navigate and modify the codebase efficiently.

## 🚀 Tech Stack
- **Framework:** Flutter (Dart)
- **State Management:** Provider
- **Backend:** Supabase (Auth, Realtime Chat, Social)
- **Persistence:** Hive (Local caching), SharedPreferences
- **Hardware Integration:** BLE (flutter_blue_plus) for smartwatches, pedometer for step tracking.
- **Maps:** flutter_map with latlong2.

## 📂 Core Directory Structure
- `lib/models/`: Data schemas (Chat, Friend, Weather).
- `lib/providers/`: Business logic and state (App, Auth, Running, Health, Watch, Weather).
- `lib/services/`: External integrations (Supabase, BLE, Notifications, Weather API).
- `lib/screens/`: Feature-specific UI entry points.
- `lib/widgets/`: Reusable UI components (Glassmorphism design language).
- `lib/theme/`: Centralized styling (Colors, Spacing, AppTheme).

## 🏗️ Architecture & Data Flow
The app follows a **Service-Provider-UI** pattern:
1. **Services** handle raw data fetching (e.g., `WatchConnectionManager` talks to BLE).
2. **Providers** consume services, manage local state, and notify listeners (e.g., `WatchMetricsProvider` updates the UI when heart rate changes).
3. **AppProvider** acts as a global coordinator for navigation, notifications, and cross-cutting features.

## 🔑 Key Abstractions (God Nodes)
- `AppProvider`: Coordinates the overall app state, streaks, and navigation.
- `AppColors` / `AppTheme`: The visual identity (dark-mode focused, vibrant accents).
- `AppShell`: The main navigation wrapper hosting the `GlassNavBar`.

## 📍 Feature Map
- **Dashboard:** `dashboard_screen.dart` - Overview of metrics, greetings, and daily plans.
- **Running:** `running_screen.dart` - Live GPS tracking, map view, and workout stats.
- **Health:** `health_screen.dart` - Wearable data visualization (Metric Rings).
- **Social:** `community_screen.dart` & `dm_chat_screen.dart` - Friends, feed, and messaging.
- **Focus:** `study_screen.dart` - Pomodoro timer and productivity tracking.

## 🛠️ Development Notes
- **UI Style:** Uses a "Glassmorphism" aesthetic with `GlassCard` and `GlassNavBar`.
- **Icons:** Standardized on `LucideIcons`.
- **Database:** Supabase schema is defined in `supabase_schema.sql`.
- **Knowledge Graph:** A detailed architecture graph is available in `graphify-out/`. Use `graphify query "<question>"` for deep architectural insights.

---
*Generated for AI Agents to provide instant context.*
