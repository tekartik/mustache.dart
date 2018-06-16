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
    /*
    test('one_var', () {
      var output = parse('_{{var}}_').renderString({"var": "bob"});
      expect(output, equals('_bob_'));
    });
    test('Comment', () {
      var output = parse('_{{! i am a\n comment ! }}_').renderString({});
      expect(output, equals('__'));
    });
    */
  });

  group('section', () {
    test('true', () async {
      expect(await render('{{#s}}value{{/s}}', {'s': true}), "value");
    });
    test('simple_map', () async {
      expect(
          await render('{{#s}}{{var}}{{/ss}}', {
            's': {'var': 'value'}
          }),
          "value");
    });
  });
}
