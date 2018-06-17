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
    test('single_line', () async {
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
    test('var_space_before', () async {
      expect(await render(" {{var}}", {"var": "value"}), " value");
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
    test('section_space_before', () async {
      expect(await render(' {{#s}}{{/s}}', {'s': true}), " ");
    });
    test('section_space_after', () async {
      expect(await render('{{#s}}{{/s}} ', {'s': true}), " ");
    });
    test('space_inner', () async {
      expect(await render('{{#s}} {{/s}}', {'s': true}), " ");
    });
    test('space_line_feed_inner', () async {
      expect(await render('{{#s}} \n{{/s}}', {'s': true}), " \n");
    });
    test('end_space_inner', () async {
      expect(await render('{{#s}}\n {{/s}}', {'s': true}), "");
    });
    test('space_line_feed_space_inner', () async {
      expect(await render('{{#s}} \n {{/s}}', {'s': true}), " \n");
    });
    test('space_before_inner', () async {
      expect(await render(' {{#s}} {{/s}}', {'s': true}), "  ");
    });
    test('space_everywhere', () async {
      expect(await render(' {{#s}} {{/s}} ', {'s': true}), "   ");
    });
    test('space_char_after', () async {
      expect(await render('{{#s}}\n {{/s}}a', {'s': true}), " a");
    });
    test('spaces', () async {
      expect(await render('{{#s}} {{/s}}', {'s': true}), " ");
      expect(await render('{{#s}} {{/s}}\n', {'s': true}), " \n");
    });
    test('multi_section', () async {
      expect(
          await render(' {{#s}} {{/s}} {{#s}} {{/s}} ', {'s': true}), "     ");
    });
    test('inner_comment', () async {
      expect(await render('{{#s}} {{!comment}}{{/s}}\n', {'s': true}), " \n");
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
    test('standalone_lines', () async {
      expect(await render('{{#s}}\n{{/s}}', {'s': true}), "");
    });
    test('standalone_lines_indented', () async {
      expect(await render(' {{#s}}\n {{/s}}', {'s': true}), "");
    });

    test('implicit_string', () async {
      expect(
          await render('{{#list}}{{.}}{{/list}}', {
            'list': ["value"]
          }),
          "value");
    });
  });
}
