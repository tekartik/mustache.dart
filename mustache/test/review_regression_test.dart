import 'package:tekartik_mustache/mustache.dart';
import 'package:test/test.dart';

/// Regressions found in the 2026-11-09 review (async and sync renderers).
void main() {
  group('regression', () {
    test('empty partial', () async {
      for (var template in ['a{{>p}}b', 'a\n{{>p}}\nb']) {
        var expected = template
            .replaceAll('{{>p}}\n', '')
            .replaceAll('{{>p}}', '');
        expect(
          await render(template, {}, partial: (_, _) => ''),
          expected,
          reason: template,
        );
        expect(
          mustacheRenderSync(template, {}, lambda: (_) => ''),
          expected,
          reason: template,
        );
      }
    });

    test('inverted section of a lambda', () async {
      var values = <String, Object?>{'lambda': (String text) => 'x'};
      expect(await render('<{{^lambda}}y{{/lambda}}>', values), '<>');
      expect(mustacheRenderSync('<{{^lambda}}y{{/lambda}}>', values), '<>');
      // The section itself still calls it.
      expect(await render('<{{#lambda}}y{{/lambda}}>', values), '<x>');
      expect(mustacheRenderSync('<{{#lambda}}y{{/lambda}}>', values), '<x>');
    });
  });
}
