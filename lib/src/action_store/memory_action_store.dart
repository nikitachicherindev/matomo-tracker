import 'package:flutter/foundation.dart';
import 'package:matomo_tracker/src/action_store/action_store.dart';

/// An [ActionStore] that keeps the actions in memory only, so they are lost
/// when the app terminates.
class MemoryActionStore implements ActionStore {
  // Insertion order is id order, as ids only grow.
  final _actions = <int, String>{};
  int _lastId = 0;

  /// All stored actions, oldest first.
  @protected
  Iterable<String> get actions => _actions.values;

  @override
  Future<void> add(String action) async {
    _actions[++_lastId] = action;
  }

  @override
  Future<List<({int id, String action})>> read({
    required int afterId,
    required int limit,
  }) async {
    return [
      for (final MapEntry(:key, :value)
          in _actions.entries.where((entry) => entry.key > afterId).take(limit))
        (id: key, action: value),
    ];
  }

  @override
  Future<int?> maxId() async => _actions.isEmpty ? null : _actions.keys.last;

  @override
  Future<void> remove(List<int> ids) async {
    for (final id in ids) {
      _actions.remove(id);
    }
  }

  @override
  Future<void> clear() async => _actions.clear();
}
