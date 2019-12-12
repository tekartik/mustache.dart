@TestOn('vm')
library tekartik_mustache.supported_spec_test;

import 'package:test/test.dart';

import 'run_spec.dart' as run_spec;

void main() {
  run_spec.skipAll = false;
  // ignore: deprecated_member_use,deprecated_member_use_from_same_package
  run_spec.filterFileBasenames = [
    'interpolation',
    'sections',
    'inverted',
    'comments',
    'partials',
    'delimiters',
    'lambdas',
  ];
  run_spec.main();
}
