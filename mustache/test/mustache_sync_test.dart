// ignore_for_file: inference_failure_on_collection_literal

import 'package:tekartik_mustache/mustache_sync.dart';
import 'package:test/test.dart';

void main() {
  group('basic', () {
    test('none', () async {
      expect(render('_', {}), '_');
    });

    test('two_vars', () async {
      expect(render('{{var1}} {{var2}}', {'var1': '1', 'var2': 2}), '1 2');
    });
    test('two_partials', () async {
      expect(
          render('{{>p1}} {{>p2}}', {},
              lambda: (name) => {'p1': '1', 'p2': '2'}[name]),
          '1 2');
    });
  });
}
