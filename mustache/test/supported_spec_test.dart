@TestOn('vm')
library;

import 'dart:io';

import 'package:path/path.dart';
import 'package:test/test.dart';

import 'run_spec.dart' as run_spec;

void main() {
  run_spec.skipAll = false;
  var supported = [
    'interpolation',
    'sections',
    'inverted',
    'comments',
    'partials',
    'delimiters',
    '~lambdas',
  ];
  // ignore: deprecated_member_use,deprecated_member_use_from_same_package
  run_spec.filterFileBasenames = supported;
  test('supported spec files exist', () {
    // A wrong name ('lambdas') used to skip the file silently.
    for (var name in supported) {
      expect(File(join('test', 'spec', '$name.yml')).existsSync(), isTrue);
    }
  });
  run_spec.main();
}
