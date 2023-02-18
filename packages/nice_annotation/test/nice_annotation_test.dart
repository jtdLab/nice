import 'package:nice_annotation/nice_annotation.dart';
import 'package:test/test.dart';

void main() {
  group('Nice', () {
    test('()', () {
      expect(Nice(), isNotNull);
    });

    test('nice', () {
      expect(nice, isA<Nice>());
    });
  });
}
