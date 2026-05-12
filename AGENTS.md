# AGENTS.md — photo_copier

AI agent reference for contributing to this project.

## Project Overview

**photo_copier** is a Flutter Android app for browsing and copying photos/videos from external storage (SD cards, USB drives) to a user-chosen destination. It is NOT an image editor.

## Architecture

```
lib/
  main.dart               # App entry point
  app.dart                # MaterialApp root, theme, routing
  models/
    file_item.dart        # File metadata model (path, size, mtime, extension)
    copy_session.dart     # Represents a copy job (files, destination, status)
    copy_result.dart      # Per-file result (success/skipped/failed)
  providers/
    storage_provider.dart # Discovers mounted external storage volumes
    file_list_provider.dart # Filtered file listing (Riverpod/Provider)
    copy_provider.dart    # Copy state machine, resume logic
    history_provider.dart # Persistent copy history
    prefs_provider.dart   # SharedPreferences (last destination dir, thumbnail toggle)
  screens/
    file_list_screen.dart # Main screen: file browser + filter bar
    copy_progress_screen.dart # Live copy progress + conflict dialog
    history_screen.dart   # Copy history list
  widgets/
    file_tile.dart        # Individual file row (thumbnail optional)
    filter_sheet.dart     # Bottom sheet: date/extension/size filters
    conflict_dialog.dart  # Conflict resolution dialog
    thumbnail_widget.dart # Lazy-loaded thumbnail (respects toggle)
  services/
    storage_service.dart  # Queries Android StorageManager via platform channel
    copy_service.dart     # File copy logic, progress stream, resume support
    history_service.dart  # Persist/load copy history (Hive or SQLite)
  utils/
    file_utils.dart       # Extension grouping, size formatting, date helpers
```

## State Management

Use **Riverpod** (preferred) or `provider`. Keep business logic in providers/services, not in widgets.

## Key Dependencies (pubspec.yaml)

- `riverpod` / `flutter_riverpod` — state management
- `shared_preferences` — remember last destination dir and settings
- `hive` or `sqflite` — copy history persistence
- `file_picker` — destination directory picker
- `path_provider` — standard paths
- `permission_handler` — READ_EXTERNAL_STORAGE, WRITE_EXTERNAL_STORAGE, MANAGE_EXTERNAL_STORAGE
- `photo_manager` or manual `image` package — thumbnail generation
- `intl` — date formatting

## Android Permissions (AndroidManifest.xml)

Required:
```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE"/>
<!-- For OTG USB access -->
<uses-feature android:name="android.hardware.usb.host"/>
```

For Android 13+ use `READ_MEDIA_IMAGES`, `READ_MEDIA_VIDEO` instead.

## Commit Rules

- **One logical change per commit** — no bundling unrelated changes
- Format: `feat: <description>`, `fix: <description>`, `refactor: <description>`, `chore: <description>`
- Push each commit immediately after it is ready
- Never squash or rebase already-pushed commits without explicit instruction

## Key Behaviors to Implement

### File Listing
- List all files in the root of the external volume (flat list initially; subdirectory browsing is a stretch goal)
- Aggregate extensions from actual files for the filter chip list
- Sort by: date (newest first, default), name, size

### Filter Logic
- Date filter: `>= start AND <= end`, or `>= date`, or `<= date`
- Extension filter: multi-select from aggregated list
- Size filter: file size in bytes >= threshold_MiB * 1024 * 1024
- Filters are AND-combined

### Copy State Machine
```
IDLE → RUNNING → (CONFLICT?) → PAUSED_CONFLICT → RUNNING
                             → COMPLETED
                             → INTERRUPTED (storage disconnected)
                             → RESUMABLE
```

### Resume Logic
- On copy start, write a pending file list to local storage
- On each successful file, remove it from the pending list
- On interruption, persist remaining files + the failed file
- On retry: reload pending list, re-verify destination accessibility, resume

### Conflict Resolution Dialog
Show:
- Filename
- Source: size + last modified
- Destination: size + last modified
- Buttons: **Skip** | **Overwrite**
- Checkbox: "Apply to all remaining conflicts"

### History
- Each copy session is stored with: timestamp, source path, destination path, total files, succeeded count, failed files list
- Failed sessions show a **Retry** button that re-initiates copy for only the failed files

## Testing Notes
- Unit test filter logic (`file_utils_test.dart`)
- Unit test copy state machine (`copy_service_test.dart`)
- Widget test for conflict dialog rendering

## Out of Scope
- Image editing / viewing
- Cloud upload
- Desktop/iOS builds (Android only for now)
