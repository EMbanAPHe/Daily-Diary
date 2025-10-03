// lib/storage/saf_storage.dart
//
// SAF-backed implementation using the 'saf' Flutter plugin. This avoids legacy
// direct storage paths and works on GrapheneOS / modern Android (targetSdk 30+).
//
// Dependencies required in pubspec.yaml:
//   saf: ^2.1.2
//   shared_preferences: ^2.2.3
//
import 'dart:async';
import 'package:saf/saf.dart' as saf;
import 'package:shared_preferences/shared_preferences.dart';
import 'diary_storage.dart';

class SafStorage implements DiaryStorage {
  static const _kRootKey = 'diary_tree_uri';
  String? _root;

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  @override
  Future<void> pickRoot() async {
    // Opens Android's system folder picker (ACTION_OPEN_DOCUMENT_TREE)
    final isGranted = await saf.Saf.getDirectoryPermission(isDynamic: true);
    if (isGranted != true) return;

    final dir = saf.Saf.getDirectory();
    if (dir == null) return;

    _root = dir.path; // plugin stores a uri-like path internally
    final sp = await _prefs;
    await sp.setString(_kRootKey, _root!);
  }

  @override
  Future<void> setRoot(String uri) async {
    _root = uri;
    final sp = await _prefs;
    await sp.setString(_kRootKey, _root!);
  }

  @override
  Future<bool> hasRoot() async {
    if (_root != null) return true;
    final sp = await _prefs;
    _root = sp.getString(_kRootKey);
    return _root != null;
  }

  Future<saf.Saf> _openRoot() async {
    if (!await hasRoot()) {
      throw StateError('No root URI set. Call pickRoot() first.');
    }
    return saf.Saf(_root!);
  }

  @override
  Future<void> ensureDirs(List<String> segments) async {
    final root = await _openRoot();
    if (segments.isEmpty) return;
    var current = root;
    for (final seg in segments) {
      final sub = saf.Saf('${current.currentDirectoryPath}/$seg');
      await sub.cache(); // stage (ensures existence in cache); sync on write
      current = sub;
    }
  }

  @override
  Future<String?> readText(List<String> segments) async {
    final root = await _openRoot();
    if (segments.isEmpty) return null;

    final parts = [...segments];
    final filename = parts.removeLast();

    var dir = root;
    for (final seg in parts) {
      dir = saf.Saf('${dir.currentDirectoryPath}/$seg');
      await dir.cache();
    }
    await dir.cache();
    final files = await dir.getCachedFilesPath() ?? const <String>[];
    final match = files.firstWhere(
      (p) => p.endsWith('/$filename'),
      orElse: () => '',
    );
    if (match.isEmpty) return null;
    return await dir.readAsString(filename);
  }

  @override
  Future<void> writeText(List<String> segments, String content) async {
    final root = await _openRoot();
    if (segments.isEmpty) return;

    final parts = [...segments];
    final filename = parts.removeLast();

    var dir = root;
    for (final seg in parts) {
      dir = saf.Saf('${dir.currentDirectoryPath}/$seg');
      await dir.cache();
    }

    await dir.writeAsString(filename, content); // create or replace
    await dir.sync(); // push cached changes to source tree
  }
}
