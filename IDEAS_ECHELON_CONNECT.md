# Echelon Connect – Enhancement Ideas

**Echelon Connect** provides a "dark mode first," subscription-free dashboard for the Echelon EX-3 smart bike. Currently, it excels at providing real-time metrics (Power, Cadence, Resistance) and basic manual/preset control for riders who want to "just ride" or use third-party content (Peloton Digital, YouTube) on a separate screen. However, it currently lacks the tracking, structure, and personalization needed for serious training progression.

---

## High-Impact Feature Ideas

### Idea 1: Ride History & Analytics (Local Persistence)
**User problem**: After finishing a hard workout, the data vanishes. Users cannot track progress, see personal bests, or confirm if they are meeting weekly fitness goals.
**Proposed solution**:
*   Auto-save every completed workout to local storage (Hive).
*   Add a "History" tab showing a list of past rides with summaries (Date, Duration, Avg Power, Total Output).
*   Detail view for each ride showing simple graphs (Power/Cadence over time) and zone distribution.
*   "Personal Best" badges for max output in 20m/30m/45m/60m durations.
**Key screens / UI changes**:
*   **New "History" Screen**: List view of card items.
*   **Ride Detail Screen**: Summary stats at top, simple line charts below (using `fl_chart`), zone bar at bottom.
*   **Dashboard Update**: Show "Weekly Distance/Calorie" summary card on the idle screen.
**Technical notes**:
*   Extend `Hive` usage to store a full list of `WorkoutSession` objects (containing arrays of samples).
*   Create a repository layer for querying past rides (e.g., `HistoryRepository`).
*   Implement sampling (e.g., save metric snapshot every 5 seconds) to keep file sizes manageable.

### Idea 2: Power Zone Training (FTP-Based)
**User problem**: "Power" is just a number. Users don't know if 150W is easy or hard for *them*. Structured training requires zones (1–7) based on fitness level.
**Proposed solution**:
*   **User Profile**: Allow inputting an "FTP" (Functional Threshold Power) value in settings.
*   **Zone Visuals**: Color-code the Power metric tile dynamically (Blue=Recovery, Green=Endurance, Yellow=Tempo, etc.).
*   **Zone Bar**: Add a visual bar gauge showing exactly where the current effort sits within the zone.
*   **Time in Zone**: Track how many minutes were spent in each zone during the ride.
**Key screens / UI changes**:
*   **Settings Screen**: Add field for "FTP (Watts)".
*   **Live Dashboard**: Update Power tile background or text color based on zone. Add a small "Zone X" label.
**Technical notes**:
*   Create `UserProfile` model/provider (stores FTP, Weight, Age).
*   Refactor `MetricTile` to accept a `zoneColor` and `zoneLabel`.
*   Implement `PowerZoneCalculator` utility class.

### Idea 3: "Companion Mode" (Compact Media Overlay)
**User problem**: Users often watch Netflix, YouTube, or Peloton Digital on the *same* tablet running Echelon Connect. The current PiP mode is good, but sometimes a "sidebar" or "bottom bar" overlay is better for split-screen multitasking on Android.
**Proposed solution**:
*   **Compact Sidebar/Bottom Bar**: A high-contrast, slim UI mode that sits at the bottom or side of the screen, leaving 80% of the screen free for other apps (via Android split-screen or just a minimal layout).
*   **Media Controls**: If possible, integration to pause/play media, or at least big touch targets to control resistance without covering the video.
**Key screens / UI changes**:
*   **"Compact Mode" Toggle**: Button on dashboard to switch to a simplified layout.
*   **Layout**: Single row of metrics: [Power] [Cadence] [Resistance] [Time].
**Technical notes**:
*   Use `MediaQuery` to detect if the app is in a constrained window (split-screen).
*   Create a specialized `CompactDashboardWidget` that removes graphs and large icons.

### Idea 4: Workout Creator & Editor
**User problem**: Users can currently only see "Custom Workouts" but cannot create them inside the app (they seem to be hardcoded or external currently).
**Proposed solution**:
*   **In-App Creator**: Simple form to add steps: "Warmup 5m @ Z1", "Interval 3m @ Z4".
*   **Drag-and-Drop**: Reorder steps.
*   **Save/Edit**: Persist custom workouts to Hive.
**Key screens / UI changes**:
*   **"Create Workout" FAB**: On Workouts List screen.
*   **Editor Screen**: List of steps with "Add Step" button. Bottom sheet to configure Duration/Resistance/Cadence for each step.
**Technical notes**:
*   Reuse existing `Workout` and `WorkoutStep` models.
*   Add CRUD operations to `WorkoutStorage` service.

### Idea 5: "Just Ride" Scenic/Free Ride Mode
**User problem**: The grid of numbers is functional but boring for long endurance rides.
**Proposed solution**:
*   **Visualizer**: A simple moving abstract visualizer (like a waveform or road line) that moves faster with speed/cadence.
*   **Large Focus**: Ability to tap a metric (e.g., Power) and make it fullscreen, minimizing others.
**Key screens / UI changes**:
*   **Gesture support**: Tap metric -> expands to cover 60% of screen.
*   **Background**: Subtle animated gradient breathing with effort level.
**Technical notes**:
*   Enhance `DashboardScreen` state to track "focused metric".
*   Use Flutter animations for the background gradient based on Heart Rate or Power zone.

### Idea 6: Bluetooth Heart Rate Monitor Integration
**User problem**: Cardio effort is just as important as power output for many users, but the bike doesn't measure it. Users currently have to look at a separate watch or phone to see their HR.
**Proposed solution**:
*   **Dual BLE Connection**: Allow connecting to a heart rate monitor (Polar, Garmin, etc.) simultaneously with the bike.
*   **Unified Dashboard**: Display HR alongside Power and Cadence.
*   **Calorie Accuracy**: Use real HR data for far more accurate calorie burn estimation than the current power-based formula.
**Key screens / UI changes**:
*   **Scan Screen**: Split list into "Bikes" and "Heart Rate Monitors".
*   **Dashboard**: Add dedicated Heart Rate tile (Red color theme).
**Technical notes**:
*   Enhance `BleManager` to manage multiple peripheral connections.
*   Parse standard BLE Heart Rate Profile (0x180D).

### Idea 7: Data Export & Strava Integration
**User problem**: "If it's not on Strava, it didn't happen." Users want their hard work to be visible on their main fitness platform.
**Proposed solution**:
*   **Standard Files**: Export completed rides as `.FIT` or `.TCX` files which can be uploaded anywhere.
*   **Direct Integration**: "Upload to Strava" button in ride history (requires API key/auth).
**Key screens / UI changes**:
*   **History Detail**: Add "Share/Export" button in the app bar.
*   **Export Dialog**: Options for "Save to Files", "Share", "Upload to Strava".
**Technical notes**:
*   Use a library to generate `.fit` files.
*   Use `url_launcher` or a sharing plugin to handle file handoff.

### Idea 8: "Ghost Rider" Pacing
**User problem**: It is difficult to know if you are performing better than last time when riding a specific duration or distance.
**Proposed solution**:
*   **Ghost Overlay**: Select a past ride to compete against.
*   **Live Comparison**: Show a "+/-" time gap or power gap in real-time.
*   **Visual Pacer**: A small "ghost" icon on a progress bar indicating the previous effort's position.
**Key screens / UI changes**:
*   **Workout Setup**: Option to "Compete against previous" when starting a ride.
*   **Dashboard**: A small secondary bar or "Gap" metric tile (e.g., "-15s" in green means you are ahead).
**Technical notes**:
*   Requires `Ride History` to be implemented first.
*   Replay the saved sample data in sync with the current timer.

---

## Additional Metrics & Insights

| Metric | Why it matters | Data Needed | Where to Surface |
| :--- | :--- | :--- | :--- |
| **Output (kJ)** | Standard measure of total work; directly comparable to Peloton "Output." | Accumulate Power (Watts) / 1000 * Time (seconds). | Main Dashboard (replaces Calories or next to it). |
| **Average Power / Cadence** | Crucial for pacing steady-state rides. | Running average of session samples. | Secondary row on Dashboard; Summary screen. |
| **Normalized Power (NP)** | Better reflects physiological cost of variable riding (intervals) than simple average. | Rolling 30s average raised to 4th power (requires buffer). | Post-ride Summary details. |
| **Watts/kg** | The great equalizer for climbing/performance comparison. | Power / User Weight (kg). | Main Dashboard (small label under Power). |
| **TSS (Training Stress Score)** | Estimates ride severity based on duration & intensity vs FTP. | Power data + FTP from user profile. | Post-ride History list. |
| **% of FTP** | Easier to understand than raw watts for zone training. | Power / FTP * 100. | Gauge/Ring around Power metric. |

---

## Workout Modes and Flows

1.  **FTP Test (20 Minute)**
    *   **Flow**: 35m total. Warmup (10m) -> Isolation leg drills -> 5m Hard -> Recovery -> **20m Max Effort** -> Cooldown.
    *   **Logic**: Auto-calculate FTP at end (95% of 20m Avg Power) and prompt to save to profile.
2.  **Pyramid Intervals**
    *   **Flow**: Steps increase in intensity/duration and then decrease (e.g., 1m On, 1m Off, 2m On, 2m Off, 3m On... back down).
    *   **Logic**: Standard structured workout player.
3.  **Tabata (HIIT)**
    *   **Flow**: Classic 20s MAX / 10s REST x 8 rounds.
    *   **UI**: Giant countdown timer, background flashes Red (Work) / Green (Rest).
4.  **Cadence Ladder**
    *   **Flow**: Resistance stays constant. Cadence targets increase by 5 every minute (80 -> 85 -> 90 -> 95 -> 100 -> 105 -> 110).
    *   **Goal**: Train leg speed and smoothness.
5.  **Heart Rate Match** (Requires BLE HR Monitor integration)
    *   **Flow**: "Maintain Zone 2". Resistance doesn't auto-change, but UI prompts "Increase Resistance" if HR is too low, or "Spin Faster".
    *   **Note**: Needs HR integration first, but high value.

---

## UX & Performance Improvements

### In-Ride UI Clarity
*   **Zone Context**: Raw numbers are hard to process when hypoxic. Change the *entire tile background* color subtly for Power/HR zones so peripheral vision picks it up.
*   **Readability**: Increase contrast on "Label" text (currently muted grey, might be hard to read in bright rooms).
*   **Button Targets**: The +/- Resistance buttons are critical. Make them huge (or support volume rocker hardware buttons to change resistance!).

### Mobile / PWA Usability
*   **Orientation Lock**: Option to force Landscape on phones (dashboards often work best wide).
*   **Touch Responsiveness**: Debounce resistance taps slightly to prevent flooding the BLE command queue, but update UI immediately for perceived speed.

### Post-Ride Review
*   **Share Image**: Generate a shareable image (Instagram story format) with the route summary stats to social proof the workout.

### Performance & Refactoring
*   **BLE Throttling**: The bike might send data faster than 60fps refresh needed. Ensure `notify` listeners don't trigger heavy UI rebuilds on every packet if not changed.
*   **Repository Pattern**: Move Hive/Persistence logic out of Widgets and into a clean `Repository` layer accessed via Riverpod.
*   **State Separation**: Separate `BleManagerState` (connection) from `SessionState` (accumulated workout data) to make "History" cleaner.

---

## Prioritized Roadmap

### Now (Phase 1: Foundation & Persistence)
*   **Ride History**: Implement Hive storage for workouts. Save basic stats (Time, Dist, Cal, Avg Power).
*   **User Profile**: Create Settings page for Weight (for calories) and FTP.
*   **Avg Metrics**: Add Avg Power and Avg Cadence to the live dashboard.
*   **Impact**: High. Users finally get "credit" for their rides.
*   **Complexity**: Medium.

### Next (Phase 2: Structured Training & Connectivity)
*   **Workout Creator**: UI to build custom interval sets.
*   **Power Zones**: Color-coded UI based on the user's FTP.
*   **Heart Rate Integration**: Connect external BLE monitors.
*   **Data Export**: Enable .FIT file export for Strava.
*   **Impact**: High. Transforms app from "display" to "trainer."
*   **Complexity**: High.

### Later (Phase 3: Polish & Eco-system)
*   **Graphing**: Charts for post-ride analysis (using `fl_chart`).
*   **Ghost Rider**: Compare against previous bests.
*   **Shareable Stats**: Image generation.
*   **Impact**: Medium. "Nice to have" features for power users.
*   **Complexity**: High.

---

## AI Implementation Prompt

```markdown
You are an expert Flutter developer. Your goal is to implement the "Ride History & Analytics" feature for the Echelon Connect app, which is currently missing persistence.

**Context**:
- The app uses Riverpod for state and Hive for local storage.
- `WorkoutMetrics` currently holds live data but isn't saved.
- `Workout` exists for *definitions* but not *completed sessions*.

**Task**:
1.  **Data Model**: Create a new Hive model `WorkoutSession` in `lib/core/models/` to store completed ride data (startTime, duration, totalCalories, avgPower, maxPower, distance).
2.  **Repository**: Create `HistoryRepository` (Riverpod provider) to handle saving `WorkoutSession`s and retrieving the list of past rides.
3.  **Logic**: Modify `BleManagerNotifier.endWorkout()` to:
    - Calculate final averages/maxes.
    - Create a `WorkoutSession` object.
    - Call the repository to save it before resetting state.
4.  **UI**:
    - Create a new `HistoryScreen` (accessible from the home/scan view or a drawer) that lists past rides (Date + Summary).
    - Add a "History" button to the `DashboardScreen` (only visible when disconnected/idle).

**Constraints**:
- Use the existing `hive` and `flutter_riverpod` dependencies.
- Ensure the save operation is non-blocking.
- Follow the existing "Dark Mode" aesthetic (colors in `AppTheme`).
```
