@TestOn('vm')
library;

import 'dart:io';

import 'package:path/path.dart';
import 'package:process_run/shell.dart';
import 'package:test/test.dart';

void main() {
  test('usage error exit code', () async {
    var testDir = join('.dart_tool', 'tekartik_mustache_cli', 'exit_code');
    await Directory(testDir).create(recursive: true);
    var dataPath = join(testDir, 'data.json');
    await File(dataPath).writeAsString('{"a": "b"}');

    Future<int> runCli(List<String> arguments) async {
      var result = await runExecutableArguments(dartExecutable!, [
        'run',
        join('lib', 'bin', 'mustache_cli.dart'),
        ...arguments,
      ]);
      return result.exitCode;
    }

    // The template is missing: a usage error, not a success.
    expect(await runCli([dataPath]), 64);
    expect(await runCli(['--help']), 0);
  }, timeout: const Timeout(Duration(minutes: 2)));
}
