import 'package:tekartik_mustache/src/parser.dart';
import 'package:test/test.dart';

main() {
  group('parser', () {
    group('basic', () {
      test('none', () async {
        expect(await parse(null), null);
        expect(await parse(""), []);
      });

      test('text_node', () async {
        expect(await parse(" "), [new TextNode(0, 1)]);
        expect(await parse(" {{"), [new TextNode(0, 1)]);
        expect(await parse("{{}}"), []);
      });

      test('variable_node', () async {
        expect(await parse("{{a}}"), [new VariableNode(2, 3)]);
        expect(await parse("{{ "), [new VariableNode(2, 3)]);
      });

      test('comment_node', () async {
        expect(await parse("{{!c}}"), [new CommentNode(3, 4)]);
        expect(await parse("{{!"), [new CommentNode(3, 3)]);
      });

      test('section_node', () async {
        expect(await parse("{{#section}}{{/section"),
            [new SectionNode(new VariableNode(3, 10))]);
      });
      test('multi_section', () async {
        expect(await parse("{{#s1}}{{#s2}}{{/s1}}"), [
          new SectionNode(new VariableNode(3, 5))
            ..nodes.add(new SectionNode(new VariableNode(10, 12)))
        ]);
      });
    });
  });
}
