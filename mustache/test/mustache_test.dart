import 'package:tekartik_mustache/src/mustache.dart';
import 'package:test/test.dart';

main() {
  group('basic', () {
    test('none', () async {
      expect(await render(null, null), null);
      expect(await render(null, {}), null);
      expect(await render(null, {"test": "value"}), null);

      expect(await render("_", null), "_");
      expect(await render("_", {}), "_");
    });

    test('one_var', () async {
      expect(await render("{{var}}", {"var": "value"}), "value");
    });

    test('one_comment', () async {
      expect(await render("{{!comment}}", null), "");
    });

    test('false_section', () async {
      expect(await render("{{#s}}{{/s}}", null), "");
    });
  });

  group('section', () {
    test('true', () async {
      expect(await render('{{#s}}value{{/s}}', {'s': true}), "value");
    });
    test('inverted_valse', () async {
      expect(await render('{{^s}}value{{/s}}', {'s': false}), "value");
    });
    test('simple_map', () async {
      expect(
          await render('{{#s}}{{var}}{{/ss}}', {
            's': {'var': 'value'}
          }),
          "value");
    });
    test('simple_list', () async {
      expect(
          await render('{{#s}}{{var}}{{/ss}}', {
            's': [
              {'var': 'value1'},
              {'var': 'value2'}
            ]
          }),
          "value1value2");
    });
  });
}
