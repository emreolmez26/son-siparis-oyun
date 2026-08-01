import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/save_data.dart';

abstract interface class SaveStore {
  Future<String?> read();
  Future<void> write(String value);
  Future<void> clear();
}

class SharedPreferencesSaveStore implements SaveStore {
  SharedPreferencesSaveStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _key = 'son_siparis_save_v1';
  final SharedPreferencesAsync _preferences;

  @override
  Future<String?> read() => _preferences.getString(_key);

  @override
  Future<void> write(String value) => _preferences.setString(_key, value);

  @override
  Future<void> clear() => _preferences.remove(_key);
}

class SaveService {
  SaveService({
    required SaveStore store,
    required this.knownUpgradeIds,
    required this.knownRecipeIds,
  }) : _store = store;

  final SaveStore _store;
  final Set<String> knownUpgradeIds;
  final Set<String> knownRecipeIds;
  Future<void> _pendingWrite = Future.value();

  Future<SaveData> load() async {
    try {
      final raw = await _store.read();
      if (raw == null || raw.isEmpty) return SaveData();
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return _recoverDefaults();
      }
      final data = SaveData.fromJson(
        decoded,
        knownUpgradeIds: knownUpgradeIds,
        knownRecipeIds: knownRecipeIds,
      );
      if (decoded['schemaVersion'] == null || decoded['schemaVersion'] == 1) {
        await saveChecked(data);
      }
      return data;
    } catch (error) {
      debugPrint('Save recovery: using safe defaults (${error.runtimeType}).');
      return _recoverDefaults();
    }
  }

  Future<SaveData> _recoverDefaults() async {
    final defaults = SaveData();
    try {
      await _store.write(jsonEncode(defaults.toJson()));
    } catch (error) {
      debugPrint('Save recovery write skipped (${error.runtimeType}).');
    }
    return defaults;
  }

  Future<void> save(SaveData data) {
    _pendingWrite = _pendingWrite.then((_) async {
      try {
        await _store.write(jsonEncode(data.toJson()));
      } catch (error) {
        debugPrint('Save write skipped safely (${error.runtimeType}).');
      }
    });
    return _pendingWrite;
  }

  Future<bool> saveChecked(SaveData data) async {
    var succeeded = false;
    _pendingWrite = _pendingWrite.then((_) async {
      try {
        await _store.write(jsonEncode(data.toJson()));
        succeeded = true;
      } catch (error) {
        debugPrint('Save write skipped safely (${error.runtimeType}).');
      }
    });
    await _pendingWrite;
    return succeeded;
  }

  Future<void> reset() async {
    try {
      await _pendingWrite;
      await _store.clear();
    } catch (error) {
      debugPrint('Save reset recovered safely (${error.runtimeType}).');
    }
  }
}
