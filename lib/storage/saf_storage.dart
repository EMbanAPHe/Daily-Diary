// lib/storage/saf_storage.dart
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'diary_storage.dart';

/// MethodChannel-backed SAF implementation.
/// Android code is in MainActivity.kt under channel "daily_diary/saf".
class SafStorage implements DiaryStorage {
  static const _ch = MethodChannel('daily_diary/saf');
  static const _kRootKey = 'diary_tree_uri';
  String? _root;

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  @override
  Future<void> pickRoot() async {
    // Launches ACTION_OPEN_DOCUMENT_TREE on Android (handled in MainActivity)
    await _ch.invokeMethod('pickRoot');
    // Android will call back with 'onPicked' – handled by setMethodCallHandler below.
    _ensureHandlerInstalled();
  }

  @override
  Future<bool> hasRoot() async {
    if (_root != null) return true;
    final sp = await _prefs;
    _root = sp.getString(_kRootKey);
    if (_root != null) {
      await _ch.invokeMethod('setRoot', {'uri': _root});
      return true;
    }
    _ensureHandlerInstalled();
    return false;
  }

  @override
  Future<void> setRoot(String uri) async {
    _root = uri;
    final sp = await _prefs;
    await sp.setString(_kRootKey, _root!);
    await _ch.invokeMethod('setRoot', {'uri': _root});
  }

  void _ensureHandlerInstalled() {
    _ch.setMethodCallHandler((call) async {
      if (call.method == 'onPicked') {
        final uri = call.arguments as String?;
        if (uri != null) {
          _root = uri;
          final sp = await _prefs;
          await sp.setString(_kRootKey, _root!);
        }
      }
    });
  }

  void _assertReady() {
    if (_root == null) {
      throw StateError('No root set. Call hasRoot() then pickRoot() if needed.');
    }
  }

  @override
  Future<void> ensureDirs(List<String> segments) async {
    _assertReady();
    await _ch.invokeMethod('ensureDirs', {'segments': segments});
  }

  @override
  Future<String?> readText(List<String> segments) async {
    _assertReady();
    final res = await _ch.invokeMethod<String>('readText', {
      'segments': segments.sublist(0, segments.length - 1),
      'filename': segments.last,
    });
    return res;
  }

  @override
  Future<void> writeText(List<String> segments, String content) async {
    _assertReady();
    await _ch.invokeMethod('writeText', {
      'segments': segments.sublist(0, segments.length - 1),
      'filename': segments.last,
      'content': content,
    });
  }
}
