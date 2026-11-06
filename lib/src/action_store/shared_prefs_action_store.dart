import 'dart:convert';

import 'package:matomo_tracker/src/action_store/memory_action_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A [MemoryActionStore] that mirrors its actions to [SharedPreferences], so
/// they survive app restarts.
///
/// Ids are not persisted: they are reassigned in order on each app launch.
class SharedPrefsActionStore extends MemoryActionStore {
  static const kActions = 'matomo_actions';

  /// The key of the queue stored as a single JSON string by older versions.
  static const kLegacyQueue = 'matomo_persistent_queue';

  late final Future<SharedPreferences> _prefs = _load();

  Future<SharedPreferences> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final legacy = prefs.getString(kLegacyQueue);
    final actions = [
      if (legacy != null)
        for (final action in jsonDecode(legacy) as List) jsonEncode(action),
      ...?prefs.getStringList(kActions),
    ];
    for (final action in actions) {
      await super.add(action);
    }
    if (legacy != null) {
      await prefs.setStringList(kActions, actions);
      await prefs.remove(kLegacyQueue);
    }
    return prefs;
  }

  // shortcut: rewrites the whole list on every change, implement your own
  // ActionStore on a database if the queue gets large.
  Future<void> _save(SharedPreferences prefs) =>
      prefs.setStringList(kActions, actions.toList());

  @override
  Future<void> add(String action) async {
    final prefs = await _prefs;
    await super.add(action);
    await _save(prefs);
  }

  @override
  Future<List<({int id, String action})>> read({
    required int afterId,
    required int limit,
  }) async {
    await _prefs;
    return super.read(afterId: afterId, limit: limit);
  }

  @override
  Future<int?> maxId() async {
    await _prefs;
    return super.maxId();
  }

  @override
  Future<void> remove(List<int> ids) async {
    final prefs = await _prefs;
    await super.remove(ids);
    await _save(prefs);
  }

  @override
  Future<void> clear() async {
    final prefs = await _prefs;
    await super.clear();
    await prefs.remove(kActions);
  }
}
