import 'package:tekartik_mustache/src/scanner.dart';
import 'package:test/test.dart';

main() {
  group('scanner', () {
    group('basic', () {
      test('none', () async {
        expect(await scan(null), null);
        expect(await scan(""), []);
      });

      test('text_node', () async {
        expect(await scan(" "), [new TextScannerNode(0, 1)]);
        expect(await scan(" {{"), [new TextScannerNode(0, 1)]);
        expect(await scan("{{}}"), []);
      });

      test('mustache_node', () async {
        expect(await scan("{{ }}"), [new MustacheScannerNode(2, 3)]);
        expect(await scan("{{ "), [new MustacheScannerNode(2, 3)]);
      });

      test('mix_node', () async {
        expect(await scan(" {{a}}"),
            [new TextScannerNode(0, 1), new MustacheScannerNode(3, 4)]);
        expect(await scan("{{a}} "),
            [new MustacheScannerNode(2, 3), new TextScannerNode(5, 6)]);
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
        expect(await scan("\n"), [new TextScannerNode(0, 1)]);
        expect(await scan("\n\n"), [new TextScannerNode(0, 1), new TextScannerNode(1, 2)]);
      });
      test('crnl', () async {
        expect(await scan("\r\n"), [new TextScannerNode(0, 2)]);
        expect(await scan("\r\n\r\n"), [new TextScannerNode(0, 2), new TextScannerNode(2, 4)]);
      });
    });
  });
}
