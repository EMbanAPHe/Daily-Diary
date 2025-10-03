// lib/storage/diary_storage.dart
import 'dart:async';

/// Logical path segments like ["2025","10","03.md"].
/// Implementations map them to storage.
abstract class DiaryStorage {
  Future<void> pickRoot();                 // system folder picker
  Future<bool> hasRoot();                  // do we have a persisted tree URI?
  Future<void> setRoot(String uri);        // restore a persisted URI

  Future<void> ensureDirs(List<String> segments);
  Future<String?> readText(List<String> segments);
  Future<void> writeText(List<String> segments, String content);
}
