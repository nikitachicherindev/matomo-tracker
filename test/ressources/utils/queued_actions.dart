import 'dart:convert';

import 'package:matomo_tracker/matomo_tracker.dart';

/// Returns the actions waiting in the [tracker]'s action store, oldest first.
Future<List<Map<String, String>>> queuedActions(MatomoTracker tracker) async {
  final stored = await tracker.actionStore.read(afterId: 0, limit: 1 << 30);
  return [
    for (final (:action, id: _) in stored)
      Map<String, String>.from(jsonDecode(action) as Map),
  ];
}
