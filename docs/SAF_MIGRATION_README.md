# Daily Diary — SAF Migration Drop-in

This folder contains files you can drag-and-drop into your GitHub repo to make
Daily Diary use Android's Storage Access Framework (SAF), which works on GrapheneOS.

## Files included

- `lib/storage/diary_storage.dart` — Storage interface
- `lib/storage/saf_storage.dart` — SAF-backed implementation (uses `saf` plugin)
- `lib/main.dart` — Minimal SAF-enabled app shell demonstrating read/write of `YYYY/MM/DD.md`
- `.github/workflows/android.yml` — Simple CI to build a release APK
- `patches/pubspec.snippet.yaml` — The dependencies you must add to your pubspec.yaml

## Steps

1. **Drag-and-drop** the `lib/` and `.github/` folders into your repo in the GitHub web UI (allow overwrite).
2. Open your repo's `pubspec.yaml` and add:
   ```yaml
   dependencies:
     saf: ^2.1.2
     shared_preferences: ^2.2.3
   ```
   (Keep other dependencies intact.)
3. Commit changes. Go to **Actions** and run **Android CI (SAF)**.
4. Download the APK artifact and install on your device.
5. First run: tap **Pick folder** and choose your diary root (e.g., `Obsidian_Vault`).
6. Create text and **Save**. Kill the app, reopen → the entry should load. No GrapheneOS storage crash.

## Notes

- Replace any old `File(...)` usage with the `DiaryStorage` API calls if you later re-introduce parts of the original UI.
- If you still see SELinux denials for system properties in logcat, remove any property probing code from other plugins or app init.
