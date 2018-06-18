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
        expect(parse(" "), [new TextNode(" ")]);
        expect(parse(" {{"), [new TextNode(" ")]);
        expect(parse("{{}}"), []);
      });

      test('variable_node', () {
        expect(parse("{{a}}"), [new VariableNode("a")]);
        expect(parse("{{a"), [new VariableNode("a")]);
        expect(parse("{{ "), []);
      });

      test('no_escape_variable_node', () {
        expect(parse("{{{a}}}"), [new NoEscapeVariableNode("a")]);
        expect(parse("{{{a"), [new NoEscapeVariableNode("a")]);
        expect(parse("{{{ "), []);
      });

      test('amp_variable_node', () {
        expect(parse("{{&a}}"), [new NoEscapeVariableNode("a")]);
        expect(parse("{{&a"), [new NoEscapeVariableNode("a")]);
        expect(parse("{{& "), []);
      });

      test('comment_node', () {
        expect(parse("{{!c}}"), [new CommentNode("c")]);
        expect(parse("{{!c"), [new CommentNode("c")]);
        expect(parse("{{!"), []);
      });

      test('section_node', () async {
        expect(parse("{{#section}}{{/section"),
            [new SectionNode(new VariableNode("section"))]);
      });
      test('multi_section', () async {
        expect(parse("{{#s1}}{{#s2}}{{/s1}}"), [
          new SectionNode(new VariableNode("s1"))
            ..nodes.add(new SectionNode(new VariableNode("s2")))
        ]);
      });

      test('partial_node', () {
        expect(parse("{{>c}}"), [new PartialNode("c")]);
        expect(parse("{{>c"), [new PartialNode("c")]);
        expect(parse("{{>"), []);
      });
    });

    group('variable', () {
      test('spaces', () {
        expect(parse("{{ a }}"), [new VariableNode("a")]);
      });
      test('spaces_no_escape', () {
        expect(parse("{{{ a }}}"), [new NoEscapeVariableNode("a")]);
      });
    });
    group('lines', () {
      test('pre_space', () {
        expect(parse(" {{a}}"), [new TextNode(" "), new VariableNode("a")]);
      });
    });
    group('sections', () {
      test('inner_section', () async {
        expect(parse("{{#s1}}{{#s2}}{{/s2{{/s1}}"), [
          new SectionNode(new VariableNode("s1"))
            ..nodes.add(new SectionNode(new VariableNode("s2")))
        ]);
      });
    });
  });
}
