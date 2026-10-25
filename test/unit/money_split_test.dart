import 'package:birga/services/calculations/money_split.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('splitEqually', () {
    test('120 000 between four roommates is 30 000 each', () {
      final shares = splitEqually(120000, [
        'aziz',
        'madina',
        'sardor',
        'dilnoza',
      ]);
      expect(shares, {
        'aziz': 30000,
        'madina': 30000,
        'sardor': 30000,
        'dilnoza': 30000,
      });
    });

    test('remainder goes one soʻm at a time to the first participants', () {
      final shares = splitEqually(100000, ['a', 'b', 'c']);
      expect(shares, {'a': 33334, 'b': 33333, 'c': 33333});
      expect(sumShares(shares), 100000);
    });

    test('total always reconciles exactly', () {
      for (var total = 1; total < 500; total += 7) {
        for (var n = 1; n <= 6; n++) {
          final ids = List.generate(n, (i) => 'm$i');
          final shares = splitEqually(total, ids);
          expect(sumShares(shares), total, reason: '$total / $n');
          final values = shares.values.toList();
          final spread =
              values.reduce((a, b) => a > b ? a : b) -
              values.reduce((a, b) => a < b ? a : b);
          expect(spread, lessThanOrEqualTo(1));
        }
      }
    });

    test('is deterministic for the same input', () {
      expect(
        splitEqually(10, ['x', 'y', 'z']),
        splitEqually(10, ['x', 'y', 'z']),
      );
    });

    test('single participant carries the whole amount', () {
      expect(splitEqually(45000, ['solo']), {'solo': 45000});
    });

    test('rejects no participants and non-positive totals', () {
      expect(() => splitEqually(1000, []), throwsArgumentError);
      expect(() => splitEqually(0, ['a']), throwsArgumentError);
      expect(() => splitEqually(-5, ['a']), throwsArgumentError);
    });
  });

  group('validateCustomSplit', () {
    test('accepts shares that add up to the total', () {
      expect(
        validateCustomSplit(210000, {
          'a': 60000,
          'b': 45000,
          'c': 60000,
          'd': 45000,
        }),
        isNull,
      );
    });

    test('rejects shares that do not add up', () {
      expect(
        validateCustomSplit(100000, {'a': 50000, 'b': 40000}),
        SplitError.sumMismatch,
      );
      expect(
        validateCustomSplit(100000, {'a': 60000, 'b': 50000}),
        SplitError.sumMismatch,
      );
    });

    test('rejects empty, missing and non-positive shares', () {
      expect(validateCustomSplit(100, {}), SplitError.noParticipants);
      expect(
        validateCustomSplit(100, {'a': 100, 'b': null}),
        SplitError.missingShare,
      );
      expect(
        validateCustomSplit(100, {'a': 100, 'b': 0}),
        SplitError.nonPositiveShare,
      );
    });

    test('unallocatedAmount reports what is left to assign', () {
      expect(unallocatedAmount(100000, {'a': 30000, 'b': null}), 70000);
      expect(unallocatedAmount(100000, {'a': 70000, 'b': 40000}), -10000);
    });
  });
}
