/// Stores the actions waiting to be dispatched to Matomo, one entry per
/// action.
///
/// Implement it to keep the queue in your own database and pass it as
/// `actionStore` to `MatomoTracker.initialize`. Each action is an opaque
/// JSON string.
abstract interface class ActionStore {
  /// Stores [action] under a new positive id, greater than every id stored
  /// before.
  Future<void> add(String action);

  /// Returns up to [limit] actions whose id is greater than [afterId], in
  /// ascending id order.
  Future<List<({int id, String action})>> read({
    required int afterId,
    required int limit,
  });

  /// The greatest stored id, or `null` if the store is empty.
  Future<int?> maxId();

  /// Removes the actions with the given [ids].
  Future<void> remove(List<int> ids);

  /// Removes all actions.
  Future<void> clear();
}
