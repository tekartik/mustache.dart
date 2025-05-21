// ignore_for_file: inference_failure_on_collection_literal

import 'package:tekartik_mustache/src/scanner.dart';
import 'package:test/test.dart';

// Mustache node
ScannerNode mn(String text) => MustacheScannerNode.withText(text);

ScannerNode tn(String? text) => TextScannerNode(text);

void main() {
  group('scanner', () {
    group('node', () {
      test('equals', () {
        expect(tn('text'), tn('text'));
        expect(tn(null), tn(null));
        expect(tn(null), isNot(tn('text')));
        expect(tn('other'), isNot(tn('text')));
      });
    });
    group('basic', () {
      test('none', () async {
        expect(scan(null), null);
        expect(scan(''), []);
      });

      test('text_node', () async {
        expect(scan(' '), [tn(' ')]);
        expect(scan(' {{'), [tn(' ')]);
        expect(scan('{{}}'), []);
        expect(scan('{{ }}'), []);
      });

      test('mustache_node', () async {
        expect(scan('{{a}}'), [mn('a')]);
        expect(scan('{{a'), [mn('a')]);
        expect(scan('{{ a }}'), [mn('a')]);
      });

      test('no_escape_mustache_node', () async {
        expect(scan('{{{ }}}'), [mn('{ }')]);
        expect(scan('{{{ }}'), [mn('{ }}')]);
        expect(scan('{{{ a }}}'), [mn('{ a }')]);
      });

      test('mix_node', () async {
        expect(scan(' {{a}}'), [tn(' '), mn('a')]);
        expect(scan('{{a}} '), [mn('a'), tn(' ')]);
      });

      /*
    test('one_var', () async {
      expect(await render('{{var}}', {'var': 'value'}), 'value');
    });
    */
      /*
    test('one_var', () {
      var output = parse('_{{var}}_').renderString({'var': 'bob'});
      expect(output, equals('_bob_'));
    });
    test('Comment', () {
      var output = parse('_{{! i am a\n comment ! }}_').renderString({});
      expect(output, equals('__'));
    });
    */
    });

    group('lines', () {
      test('nl', () async {
        expect(scan('\n'), [tn('\n')]);
        expect(scan('\n\n'), [tn('\n'), tn('\n')]);
      });
      test('crnl', () async {
        expect(scan('\r\n'), [tn('\r\n')]);
        expect(scan('\r\n\r\n'), [tn('\r\n'), tn('\r\n')]);
      });
    });

    group('delimiters', () {
      test('new_delimiter', () async {
        var scanner = Scanner('{{=[ ]=}}');
        scanner.scan();
        expect(scanner.delimiter!.open, '[');
        expect(scanner.delimiter!.close, ']');
        expect(scanner.delimiter!.isDefault, false);
      });
      test('new_delimiter_node', () async {
        expect(scan('{{=[ ]=}}[nodex]'), [mn('=[ ]='), mn('nodex')]);
      });
      test('new_delimiter_section', () async {
        expect(scan('{{=| |=}} |#s| |data| |/s|'), [
          mn('=| |='),
          tn(' '),
          mn('#s'),
          tn(' '),
          mn('data'),
          tn(' '),
          mn('/s'),
        ]);
      });
    });
  });
}
