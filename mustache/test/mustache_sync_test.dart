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
        render(
          '{{>p1}} {{>p2}}',
          {},
          lambda: (name) => {'p1': '1', 'p2': '2'}[name],
        ),
        '1 2',
      );
    });
  });

  group('regressions', () {
    test('empty string and 0 sections', () {
      for (var value in <Object?>['', 0, 0.0]) {
        // Used to throw an UnsupportedError
        expect(render('[{{#a}}x{{/a}}]', {'a': value}), '[]');
        // Used to render nothing
        expect(render('[{{^a}}x{{/a}}]', {'a': value}), '[x]');
      }
      for (var value in <Object?>['y', 1, -1]) {
        expect(render('[{{#a}}x{{/a}}]', {'a': value}), '[x]');
        expect(render('[{{^a}}x{{/a}}]', {'a': value}), '[]');
      }
    });
    test('lambda result in a nested context', () {
      // Used to render ''
      expect(
        render('{{#sub}}{{lambda}}{{/sub}}', {
          'planet': 'world',
          'sub': {'lambda': (Object? _) => '{{planet}}'},
        }),
        'world',
      );
    });
    test('delimiters padding', () {
      expect(render('|{{= @   @ =}}@x@|', {'x': 1}), '|1|');
      expect(render('|{{=  @ @=}}@x@|', {'x': 1}), '|1|');
    });
  });
}
