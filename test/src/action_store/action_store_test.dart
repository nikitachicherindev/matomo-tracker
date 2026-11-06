import 'package:flutter_test/flutter_test.dart';
import 'package:matomo_tracker/src/action_store/memory_action_store.dart';
import 'package:matomo_tracker/src/action_store/shared_prefs_action_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('MemoryActionStore', () {
    test('it should page by id and remove only the given ids', () async {
      final store = MemoryActionStore();
      expect(await store.maxId(), isNull);

      for (final action in ['a', 'b', 'c']) {
        await store.add(action);
      }
      final first = await store.read(afterId: 0, limit: 2);
      expect(first.map((e) => e.action), ['a', 'b']);
      final rest = await store.read(afterId: first.last.id, limit: 2);
      expect(rest.map((e) => e.action), ['c']);
      expect(await store.maxId(), rest.last.id);

      await store.remove([for (final e in first) e.id]);
      expect(
        (await store.read(afterId: 0, limit: 10)).map((e) => e.action),
        ['c'],
      );

      await store.clear();
      expect(await store.maxId(), isNull);
    });
  });

  group('SharedPrefsActionStore', () {
    test('it should keep the actions across instances', () async {
      SharedPreferences.setMockInitialValues({});
      final store = SharedPrefsActionStore();
      await store.add('a');
      await store.add('b');
      final [first, _] = await store.read(afterId: 0, limit: 10);
      await store.remove([first.id]);

      final restored = SharedPrefsActionStore();
      expect(
        (await restored.read(afterId: 0, limit: 10)).map((e) => e.action),
        ['b'],
      );

      await restored.clear();
      expect(
        await SharedPrefsActionStore().read(afterId: 0, limit: 10),
        isEmpty,
      );
    });

    test('it should migrate the queue stored by older versions', () async {
      SharedPreferences.setMockInitialValues({
        SharedPrefsActionStore.kLegacyQueue: '[{"a":"1"},{"b":"2"}]',
      });
      final store = SharedPrefsActionStore();

      expect(
        (await store.read(afterId: 0, limit: 10)).map((e) => e.action),
        ['{"a":"1"}', '{"b":"2"}'],
      );
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey(SharedPrefsActionStore.kLegacyQueue), isFalse);
      expect(
          prefs.getStringList(SharedPrefsActionStore.kActions), hasLength(2));
    });
  });
}
