import 'package:between_us/app/couple_space_guard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'ensureSpaceId returns the existing space without creating a new one',
    () async {
      var fetchCount = 0;
      var createCount = 0;
      final guard = CoupleSpaceGuard(
        fetchCurrentSpaceId: () async {
          fetchCount += 1;
          return 'space-existing';
        },
        createCoupleSpace: () async {
          createCount += 1;
          return 'space-created';
        },
      );

      final spaceId = await guard.ensureSpaceId();

      expect(spaceId, 'space-existing');
      expect(fetchCount, 1);
      expect(createCount, 0);
    },
  );

  test(
    'ensureSpaceId creates and caches a space when the user has none',
    () async {
      var fetchCount = 0;
      var createCount = 0;
      final guard = CoupleSpaceGuard(
        fetchCurrentSpaceId: () async {
          fetchCount += 1;
          return null;
        },
        createCoupleSpace: () async {
          createCount += 1;
          return 'space-created';
        },
      );

      final firstSpaceId = await guard.ensureSpaceId();
      final secondSpaceId = await guard.ensureSpaceId();

      expect(firstSpaceId, 'space-created');
      expect(secondSpaceId, 'space-created');
      expect(fetchCount, 1);
      expect(createCount, 1);
    },
  );

  test(
    'ensureSpaceId refetches after create failure and reuses the created space',
    () async {
      var fetchCount = 0;
      var createCount = 0;
      final guard = CoupleSpaceGuard(
        fetchCurrentSpaceId: () async {
          fetchCount += 1;
          return fetchCount >= 2 ? 'space-race-created' : null;
        },
        createCoupleSpace: () async {
          createCount += 1;
          throw StateError('user already belongs to an active couple_space');
        },
      );

      final spaceId = await guard.ensureSpaceId();

      expect(spaceId, 'space-race-created');
      expect(fetchCount, 2);
      expect(createCount, 1);
    },
  );
}
