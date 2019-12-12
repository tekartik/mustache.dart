import 'dart:io';

import 'package:path/path.dart';
import 'package:test/test.dart';
import 'package:tekartik_mustache_cli/mustache_cli.dart';

void main() {
  group('basic', () {
    test('out_file', () async {
      var testDir = join('.dart_tool', 'tekartik_mustache_cli', 'out_file');
      try {
        await Directory(testDir).delete(recursive: true);
      } catch (_) {}
      try {
        await Directory(testDir).create(recursive: true);
      } catch (_) {}
      var srcPath = join(testDir, 'index.html');
      var srcData = join(testDir, 'data.json');
      var outPath = join(testDir, 'out.html');

      await File(srcPath).writeAsString('''<h1>{{header}}</h1>
{{#bug}}
{{/bug}}

{{#items}}
{{#first}}
<li><strong>{{name}}</strong></li>
{{/first}}
{{#link}}
<li><a href="{{url}}">{{name}}</a></li>
{{/link}}
{{/items}}

{{#empty}}
<p>The list is empty.</p>
{{/empty}}''');

      await File(srcData).writeAsString('''{
  "header": "Colors",
  "items": [
    {"name": "red", "first": true, "url": "#Red"},
    {"name": "green", "link": true, "url": "#Green"},
    {"name": "blue", "link": true, "url": "#Blue"}
  ],
  "empty": false
}''');

      var outFile = File(outPath);
      expect(outFile.existsSync(), isFalse);
      await mustacheMain([srcData, srcPath, '--out', outPath]);
      expect(await outFile.readAsString(), '''<h1>Colors</h1>

<li><strong>red</strong></li>
<li><a href="#Green">green</a></li>
<li><a href="#Blue">blue</a></li>

''');
    });
  });
}
