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

  group('lines', () {
    test('empty_line', () async {
      expect(await render("\n", null), "\n");
    });
    test('empty_lines', () async {
      expect(await render("\n\n", null), "\n\n");
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
    test('missing_variable', () async {
      expect(await render("{{var}}", {"var": null}), "");
      expect(await render("{{var}}", null), "");
    });
    test('missing_var_standalone', () async {
      // variable cannot be standalone
      expect(await render("{{var}}\n", null), "\n");
    });
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

  group('partial', () {
    test('simple_partial', () async {
      expect(await render('{{>partial}}', null, partial: (String _) => "value"),
          "value");
    });
    test('partial_var', () async {
      expect(
          await render('{{>partial}}', {"var": "value"},
              partial: (String _) => "{{var}}"),
          "value");
    });
    test('sub_partial_var', () async {
      expect(
          await render('{{>p1}}', {"var": "value"}, partial: (String partial) {
            switch (partial) {
              case 'p1':
                return '{{>p2}}';
              case 'p2':
                return "{{var}}";
            }
          }),
          "value");
    });
    test('ending crlf', () async {
      // from spec
      // "\r\n" should be considered a newline for standalone tags.'
      expect(
          await render('{{>p}}\r\n|', null, partial: (String _) => '>'), ">|");
    });
    test('partial_no_previous_line', () async {
      // from spec
      // Standalone tags should not require a newline to precede them.
      expect(await render('  {{>p}}\n>', null, partial: (String _) => '>\n>'),
          "  >\n  >>");
    });
    test('partial_no_previous_line', () async {
      // from spec
      // Standalone tags should not require a newline to precede them.
      expect(await render('  {{>p}}\n>', null, partial: (String _) => '>\n>'),
          "  >\n  >>");
    });
    test('partial_data_before', () async {
      // from spec
      // Whitespace should be left untouched.
      expect(await render('| {{>p}}\n', null, partial: (String _) => '>\n>'),
          "| >\n>\n");
    });

    test('partial_data_before', () async {
      // from spec
      // Whitespace should be left untouched.
      expect(await render('| {{>p}}\n', null, partial: (String _) => '>\n>'),
          "| >\n>\n");
    });

    test('partial_data_before_2', () async {
      // from spec
      // Whitespace should be left untouched.
      expect(
          await render(' {{data}} {{>p}}\n', {'data': '|'},
              partial: (String _) => '>\n>'),
          " | >\n>\n");
    });

    /*
    - name: Inline Indentation
    desc: Whitespace should be left untouched.
    data: { data: '|' }
    template: "  {{data}}  {{> partial}}\n"
    partials: { partial: ">\n>" }
    expected: "  |  >\n>\n"
    */
  });

  group('lambdas', () {
    test('simple_lambda', () async {
      expect(
          await render("{{f}}", {
            "f": (String name) {
              // expected name
              expect(name, "f");
              return "value";
            }
          }),
          "value");
    });

    test('var_lambda', () async {
      expect(await render("{{f}}", {"f": (_) => "{{var}}", "var": "value"}),
          "value");
    });

    test('lambda_section', () async {
      expect(
          await render("{{#f}}inner{{/f}}", {
            "f": (String name) {
              // expected name
              expect(name, "inner");
              return "value";
            }
          }),
          "value");
    });

    test('lambda_raw_section', () async {
      expect(
          await render("{{#f}}{{x}}{{/f}}", {
            "f": (String name) {
              // expected name
              expect(name, "{{x}}");
              return "value";
            }
          }),
          "value");
    });
  });

  group('delimiters', () {
    test('simple_delimiter', () {});
  });
}
