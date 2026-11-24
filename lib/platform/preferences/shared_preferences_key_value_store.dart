import 'package:shared_preferences/shared_preferences.dart';

import 'key_value_store.dart';

class SharedPreferencesKeyValueStore implements KeyValueStore {
  SharedPreferencesKeyValueStore(this._preferences);

  factory SharedPreferencesKeyValueStore.create() {
    return SharedPreferencesKeyValueStore(SharedPreferences.getInstance());
  }

  final Future<SharedPreferences> _preferences;

  @override
  Future<String?> getString(String key) async =>
      (await _preferences).getString(key);

  @override
  Future<void> setString(String key, String value) async {
    await (await _preferences).setString(key, value);
  }
}
