# photo_copier

An Android app for copying photos and videos from external storage devices (SD cards via TF card readers, USB drives) to your device or a selected destination directory.

## Features

- **Browse external storage** — reads TF cards, USB drives, and other OTG-connected media
- **File listing** — main screen shows all files on the mounted external storage
- **Advanced filters**:
  - Date range (between two dates, after a date, before a date)
  - File extension (JPEG, HEIC, MP4, MOV, PNG, RAF, ARW, etc. — dynamically aggregated from current directory contents)
  - File size (larger than N MiB)
- **Multi-select** — single-tap or long-press to select files; select all in filtered view
- **Copy to** — copies selected files to a user-chosen destination directory; last-used directory is remembered
- **Conflict resolution** — if a file with the same name already exists at the destination:
  - Shows source vs. destination size and modification date side-by-side
  - User can choose: Overwrite or Skip
  - Option to apply the same choice to all remaining conflicts
- **Resume interrupted copies** — if external storage is disconnected mid-copy, the remaining (and failed) file list is persisted; a **Retry** button resumes once the device is reconnected
- **Copy history** — view past copy sessions (successes and failures); failed sessions have a **Retry** button
- **Thumbnail toggle** — show/hide thumbnails to reduce I/O pressure on slow external media

## Non-goals

- Image editing
- Cloud sync

## Requirements

- Android 8.0+ (API 26+)
- OTG support on the host device (for USB/TF card readers)

## Setup

```bash
# Install dependencies
flutter pub get

# Run on connected Android device
flutter run

# Build APK
flutter build apk --release
```

## License

MIT — see [LICENSE](LICENSE)
