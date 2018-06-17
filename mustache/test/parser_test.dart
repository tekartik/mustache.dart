import 'package:tekartik_mustache/src/parser.dart';
import 'package:test/test.dart';

main() {
  group('parser', () {
    group('basic', () {
      test('none', () async {
        expect(parse(null), null);
        expect(parse(""), []);
      });

      test('text_node', () {
        expect(parse(" "), [new TextNode(0, 1)]);
        expect(parse(" {{"), [new TextNode(0, 1)]);
        expect(parse("{{}}"), []);
      });

      test('variable_node', () {
        expect(parse("{{a}}"), [new VariableNode(2, 3)]);
        expect(parse("{{a"), [new VariableNode(2, 3)]);
        expect(parse("{{ "), []);
      });

      test('no_escape_variable_node', () {
        expect(parse("{{{a}}}"), [new NoEscapeVariableNode(3, 4)]);
        expect(parse("{{{a"), [new NoEscapeVariableNode(3, 4)]);
        expect(parse("{{{ "), []);
      });

      test('amp_variable_node', () {
        expect(parse("{{&a}}"), [new NoEscapeVariableNode(3, 4)]);
        expect(parse("{{&a"), [new NoEscapeVariableNode(3, 4)]);
        expect(parse("{{& "), []);
      });

      test('comment_node', () {
        expect(parse("{{!c}}"), [new CommentNode(3, 4)]);
        expect(parse("{{!c"), [new CommentNode(3, 4)]);
        expect(parse("{{!"), []);
      });

      test('section_node', () async {
        expect(parse("{{#section}}{{/section"),
            [new SectionNode(new VariableNode(3, 10))]);
      });
      test('multi_section', () async {
        expect(parse("{{#s1}}{{#s2}}{{/s1}}"), [
          new SectionNode(new VariableNode(3, 5))
            ..nodes.add(new SectionNode(new VariableNode(10, 12)))
        ]);
      });

      test('partial_node', () {
        expect(parse("{{>c}}"), [new PartialNode(3, 4)]);
        expect(parse("{{>c"), [new PartialNode(3, 4)]);
        expect(parse("{{>"), []);
      });
    });

    group('variable', () {
      test('spaces', () {
        expect(parse("{{ a }}"), [new VariableNode(3, 4)]);
      });
      test('spaces_no_escape', () {
        expect(parse("{{{ a }}}"), [new NoEscapeVariableNode(4, 5)]);
      });
    });
    group('lines', () {
      test('pre_space', () {
        expect(parse(" {{a}}"), [new TextNode(0, 1), new VariableNode(3, 4)]);
      });
    });
    group('sections', () {
      test('inner_section', () async {
        expect(parse("{{#s1}}{{#s2}}{{/s2{{/s1}}"), [
          new SectionNode(new VariableNode(3, 5))
            ..nodes.add(new SectionNode(new VariableNode(10, 12)))
        ]);
      });
    });
  });
}
