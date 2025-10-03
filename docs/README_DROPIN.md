# Daily Diary — SAF MethodChannel Drop‑in (GrapheneOS‑friendly)

This package lets you **drag & drop** files into your fork to migrate storage to
Android's **Storage Access Framework (SAF)** using a small **MethodChannel**.
No external plugins required.

## What’s inside

- `lib/storage/diary_storage.dart` — storage interface
- `lib/storage/saf_storage.dart` — Dart side of the MethodChannel
- `android/REPLACE_THIS_WITH_ACTUAL_PATH/MainActivity.kt` — Kotlin side (template)
- `lib/main.dart` — minimal SAF-enabled app shell (optional; overwrite to test quickly)

> You will **replace** your existing `MainActivity.kt` content with the file in this package,
> but you must **update the `package ...` line** to match your project.

---

## Step‑by‑step (browser‑only)

1) **Upload the `lib/` folder** via GitHub → *Add file → Upload files*.  
   - Allow it to **overwrite** existing files.

2) **Update `pubspec.yaml`** under `dependencies:` (remove any `saf:` plugin lines):
   ```yaml
   shared_preferences: ^2.2.3
   ```
   Keep your other deps (intl, file_picker, etc.).

3) **Find your package name and MainActivity path**
   - Open `android/app/src/main/AndroidManifest.xml`
   - At the top: `package="YOUR.PACKAGE.NAME"`
   - The Kotlin file is at:
     ```
     android/app/src/main/kotlin/<YOUR/PACKAGE/NAME REPLACED WITH SLASHES>/MainActivity.kt
     ```

4) **Overwrite `MainActivity.kt`**
   - Open the file above in the web editor.
   - Replace its contents with the `MainActivity.kt` from this drop‑in.
   - **Change the first line** to your real package, e.g.:
     ```
     package com.voklen.daily_diary
     ```

5) **Commit → Build**
   - Run your GitHub Action or locally:
     ```
     flutter pub get
     flutter build apk --release
     ```

6) **Test on your device**
   - First run → tap **Pick folder** (system file picker).
   - Save, kill app, reopen → the entry reloads without crashes.

If you want to keep your original UI, keep using `DiaryStorage` API calls:
- `ensureDirs([yyyy, mm])`
- `readText([yyyy, mm, '$dd.md'])`
- `writeText([yyyy, mm, '$dd.md'], text)`
