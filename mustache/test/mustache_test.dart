import 'package:tekartik_mustache/mustache.dart';
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

  group('comments', () {
    test('lines', () async {
      expect(await render(" {{!comment}}\n", null), "");
    });
    test('no_single_on_line', () async {
      expect(await render("a{{!comment}}\n", null), "a\n");
    });
  });
  group('variable', () {
    test('escape', () async {
      expect(await render("{{var}}", {"var": "&"}), "&amp;");
    });
    test('spaces', () async {
      expect(await render("{{ var }}", {"var": "&"}), "&amp;");
    });
    test('no_escape', () async {
      expect(await render("{{{var}}}", {"var": "&"}), "&");
    });
    test('spaces_no_escape', () async {
      expect(await render("{{{ var }}}", {"var": "&"}), "&");
    });
    test('surrounding', () async {
      expect(await render(" {{var}} ", {"var": "value"}), " value ");
    });
    test('dotted', () async {
      expect(
          await render("{{var.sub}}", {
            "var": {"sub": "value"}
          }),
          "value");
    });
  });
  group('section', () {
    test('true', () async {
      expect(await render('{{#s}}value{{/s}}', {'s': true}), "value");
    });
    test('spaces', () async {
      expect(await render('{{#s}} {{/s}}', {'s': true}), " ");
      expect(await render('{{#s}}\n{{/s}}', {'s': true}), "\n");
      expect(await render('{{#s}} \n {{/s}}', {'s': true}), " \n ");
    });
    test('inverted_valse', () async {
      expect(await render('{{^s}}value{{/s}}', {'s': false}), "value");
    });
    test('simple_map', () async {
      expect(
          await render('{{#s}}{{var}}{{/s}}', {
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
    test('nested_map', () async {
      expect(
          await render('{{#s1}}{{#s2}}{{var}}{{/s2}}{{/s1}}', {
            's1': {'var': 'value'},
            's2': {}
          }),
          "value");
    });
    test('context_precendence', () async {
      expect(
          await render('{{#a}}{{b.c}}{{/a}}', {
            'a': {'b': {}},
            'b': {'c': 'ERROR'}
          }),
          "");
    });
  });
}
