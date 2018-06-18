import 'package:tekartik_mustache/src/scanner.dart';
import 'package:test/test.dart';

main() {
  group('scanner', () {
    group('node', () {
      test('equals', () {
        expect(new TextScannerNode("text"), new TextScannerNode("text"));
        expect(new TextScannerNode(null), new TextScannerNode(null));
        expect(new TextScannerNode(null), isNot(new TextScannerNode("text")));
        expect(
            new TextScannerNode("other"), isNot(new TextScannerNode("text")));
      });
    });
    group('basic', () {
      test('none', () async {
        expect(scan(null), null);
        expect(scan(""), []);
      });

      test('text_node', () async {
        expect(scan(" "), [new TextScannerNode(" ")]);
        expect(scan(" {{"), [new TextScannerNode(" ")]);
        expect(scan("{{}}"), []);
        expect(scan("{{ }}"), []);
      });

      test('mustache_node', () async {
        expect(scan("{{a}}"), [new MustacheScannerNode("a")]);
        expect(scan("{{a"), [new MustacheScannerNode("a")]);
        expect(scan("{{ a }}"), [new MustacheScannerNode("a")]);
      });

      test('no_escape_mustache_node', () async {
        expect(scan("{{{ }}}"), [new MustacheScannerNode("{ }")]);
        expect(scan("{{{ }}"), [new MustacheScannerNode("{ }}")]);
        expect(scan("{{{ a }}}"), [new MustacheScannerNode("{ a }")]);
      });

      test('mix_node', () async {
        expect(scan(" {{a}}"),
            [new TextScannerNode(" "), new MustacheScannerNode("a")]);
        expect(scan("{{a}} "),
            [new MustacheScannerNode("a"), new TextScannerNode(" ")]);
      });

      /*
    test('one_var', () async {
      expect(await render("{{var}}", {"var": "value"}), "value");
    });
    */
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

    group('lines', () {
      test('nl', () async {
        expect(await scan("\n"), [new TextScannerNode("\n")]);
        expect(await scan("\n\n"),
            [new TextScannerNode("\n"), new TextScannerNode("\n")]);
      });
      test('crnl', () async {
        expect(await scan("\r\n"), [new TextScannerNode("\r\n")]);
        expect(await scan("\r\n\r\n"),
            [new TextScannerNode("\r\n"), new TextScannerNode("\r\n")]);
      });
    });

    group('delimiters', () {
      test('new_delimiter', () async {
        var scanner = new Scanner('{{=[ ]=}}');
        scanner.scan();
        expect(scanner.delimiter.open, '[');
        expect(scanner.delimiter.close, ']');
        expect(scanner.delimiter.isDefault, false);
      });
      test('new_delimiter_node', () async {
        expect(
            await scan('{{=[ ]=}}[nodex]'), [new MustacheScannerNode("nodex")]);
      });
    });
  });
}
