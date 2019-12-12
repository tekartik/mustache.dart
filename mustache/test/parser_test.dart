import 'package:tekartik_mustache/src/parser.dart';
import 'package:test/test.dart';

void main() {
  group('parser', () {
    group('basic', () {
      test('none', () async {
        expect(parse(null), null);
        expect(parse(''), []);
      });

      test('text_node', () {
        expect(parse(' '), [TextNode(' ')]);
        expect(parse(' {{'), [TextNode(' ')]);
        expect(parse('{{}}'), []);
      });

      test('variable_node', () {
        expect(parse('{{a}}'), [VariableNode('a')]);
        expect(parse('{{a'), [VariableNode('a')]);
        expect(parse('{{ '), []);
      });

      test('no_escape_variable_node', () {
        expect(parse('{{{a}}}'), [NoEscapeVariableNode('a')]);
        expect(parse('{{{a'), [NoEscapeVariableNode('a')]);
        expect(parse('{{{ '), []);
      });

      test('amp_variable_node', () {
        expect(parse('{{&a}}'), [NoEscapeVariableNode('a')]);
        expect(parse('{{&a'), [NoEscapeVariableNode('a')]);
        expect(parse('{{& '), []);
      });

      test('comment_node', () {
        expect(parsePhase1('{{!c}}'), [CommentNode('c')]);
        expect(parsePhase1('{{!c'), [CommentNode('c')]);
        expect(parsePhase1('{{!'), []);
        expect(parsePhase2('{{!c}}'), []);
      });

      test('section_node', () async {
        expect(parse('{{#section}}{{/section'),
            [SectionNode(VariableNode('section'))]);
      });
      test('multi_section', () async {
        expect(parse('{{#s1}}{{#s2}}{{/s1}}'), [
          SectionNode(VariableNode('s1'))
            ..nodes.add(SectionNode(VariableNode('s2')))
        ]);
      });

      test('partial_node', () {
        expect(parse('{{>c}}'), [PartialNode('c')]);
        expect(parse('{{>c'), [PartialNode('c')]);
        expect(parse('{{>'), []);
      });
    });

    group('variable', () {
      test('spaces', () {
        expect(parse('{{ a }}'), [VariableNode('a')]);
      });
      test('spaces_no_escape', () {
        expect(parse('{{{ a }}}'), [NoEscapeVariableNode('a')]);
      });
    });
    group('lines', () {
      test('pre_space', () {
        expect(parse(' {{a}}'), [TextNode(' '), VariableNode('a')]);
      });
    });

    group('delimiter', () {
      test('standalone', () {
        expect(parse('{{=[ ]=}}'), []);
      });
      test('standlone_new_line', () {
        expect(parse('{{=[ ]=}}\n'), []);
      });
    });
    group('sections', () {
      test('section_space_before', () async {
        expect(parse(' {{#s}}{{/s}}'),
            [TextNode(' '), SectionNode(VariableNode('s'))]);
      });
      test('inner_section', () async {
        expect(parse('{{#s1}}{{#s2}}{{/s2{{/s1}}'), [
          SectionNode(VariableNode('s1'))
            ..nodes.add(SectionNode(VariableNode('s2')))
        ]);
      });
      test('space_line_feed_inner', () async {
        expect(parse('{{#s}} \n{{/s}}'),
            [SectionNode(VariableNode('s'))..nodes.add(TextNode(' \n'))]);
      });
    });

    group('comment', () {
      test('no_single_on_line', () async {
        expect(parse('a{{!comment}}\n'), [TextNode('a'), TextNode('\n')]);
      });
    });

    group('partial', () {
      test('partial_node_standalone', () {
        expect(parse('{{>c}}\n'), [PartialNode('c')]);
      });
    });
  });
}
