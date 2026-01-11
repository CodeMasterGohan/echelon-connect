## 2024-01-10 - Performance Optimization in DashboardScreen
**Learning:** Watching a large state object (like `bleManagerProvider`) in a high-level widget (like `DashboardScreen`) causes the entire widget tree to rebuild whenever *any* part of that state changes. In this case, metric updates (happening ~1/sec) were causing the entire `Scaffold`, `AppBar`, and background to rebuild unnecessarily.
**Action:** Always use `ref.watch(provider.select((s) => s.property))` when a widget only needs a specific part of the state. For high-frequency updates, extract the consuming widget into a separate leaf widget (e.g., `ConnectedDashboardView`) so that rebuilds are isolated to the smallest possible subtree.

## 2026-01-10 - PipOverlay Over-Broad State Watching

**Learning:** The `PipOverlay` widget watches entire `bleManagerProvider` but only uses `currentMetrics`. This causes unnecessary rebuilds when connection state, discovered devices, or other unrelated state changes occur. The `DashboardScreen` already uses `.select()` pattern correctly as a reference.

**Action:** Apply the same `.select()` pattern to `PipOverlay` and other similar widgets (`WorkoutsListScreen`, `IdleDashboardView`) to reduce rebuilds.
