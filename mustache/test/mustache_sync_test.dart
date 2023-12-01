// ignore_for_file: inference_failure_on_collection_literal

import 'package:tekartik_mustache/mustache_sync.dart';
import 'package:test/test.dart';

void main() {
  group('basic', () {
    test('none', () async {
      expect(render('_', {}), '_');
    });

    test('one_var', () async {
      expect(render('{{var}}', {'var': 'value'}), 'value');
    });
  });
}
