# Performance Smoke Suite

This repo now includes a lightweight widget-level performance smoke suite for the major shell flows we have today.

## What It Covers

- Auth gate render for signed-out users
- Auth gate route time for returning trainee users
- Auth gate route time for returning trainer users
- Trainee main shell render
- Trainee radial menu open time
- Trainer main shell render
- Trainer clients tab switch
- Trainer radial menu open time

These tests are intentionally lightweight. They are meant to catch obvious regressions in render and navigation cost without requiring live Supabase data or device-specific camera flows.

## Test Files

- [`E:\StudioNew\repz-ar\repz\test\performance\auth_gate_performance_test.dart`](/E:/StudioNew/repz-ar/repz/test/performance/auth_gate_performance_test.dart)
- [`E:\StudioNew\repz-ar\repz\test\performance\main_page_performance_test.dart`](/E:/StudioNew/repz-ar/repz/test/performance/main_page_performance_test.dart)
- [`E:\StudioNew\repz-ar\repz\test\performance\main_page_visual_smoke_test.dart`](/E:/StudioNew/repz-ar/repz/test/performance/main_page_visual_smoke_test.dart)
- [`E:\StudioNew\repz-ar\repz\test\performance\performance_test_utils.dart`](/E:/StudioNew/repz-ar/repz/test/performance/performance_test_utils.dart)
- [`E:\StudioNew\repz-ar\repz\tool\run_performance_suite.ps1`](/E:/StudioNew/repz-ar/repz/tool/run_performance_suite.ps1)

## How To Run

Run the whole smoke suite:

```powershell
Set-Location E:\StudioNew\repz-ar\repz
powershell -ExecutionPolicy Bypass -File .\tool\run_performance_suite.ps1 -UpdateScreenshots
```

Run a single file:

```powershell
flutter test test/performance/auth_gate_performance_test.dart
flutter test test/performance/main_page_performance_test.dart
flutter test --update-goldens test/performance/main_page_visual_smoke_test.dart
```

To validate the visual screenshots without regenerating them:

```powershell
Set-Location E:\StudioNew\repz-ar\repz
powershell -ExecutionPolicy Bypass -File .\tool\run_performance_suite.ps1
```

## Notes

- The budgets are deliberately generous so the suite behaves like a regression alarm, not a micro-benchmark.
- These tests do not measure live Supabase latency yet.
- The PowerShell runner writes a Markdown report under `build/performance/` with captured timing lines and embedded screenshot links.
- Camera, pose detection, and object detection are still better covered with manual profiling because device and ML variance will make them noisy in CI.

## Good Next Additions

- Repository timing tests for trainer dashboard aggregation
- Staging-only backend smoke tests for plan assignment and schedule saves
- A real `integration_test` pass for end-to-end trainee and trainer journeys once we add more app-wide dependency injection
