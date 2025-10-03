// lib/storage/diary_storage.dart
// Drop-in interface for Storage Access Framework (SAF) backed storage.
//
// Path segments are logical pieces like ["2025","10","03.md"]. Implementations
// decide how to map them to real storage (SAF tree URIs).
import 'dart:async';

abstract class DiaryStorage {
  /// Prompts the user to pick a base folder (via the Android system picker) and persists access.
  Future<void> pickRoot();

  /// Returns true if a persisted root folder URI exists.
  Future<bool> hasRoot();

  /// (Re)sets a previously-known root folder URI (string form).
  Future<void> setRoot(String uri);

  /// Ensure that the directory structure for [segments] exists.
  Future<void> ensureDirs(List<String> segments);

  /// Read a UTF-8 text file at [segments]. Returns null if it doesn't exist.
  Future<String?> readText(List<String> segments);

  /// Write (replace) a UTF-8 text file at [segments].
  Future<void> writeText(List<String> segments, String content);
}
