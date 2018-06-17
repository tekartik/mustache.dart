@TestOn("vm")
library tekartik_mustache.supported_spec_test;

import 'package:test/test.dart';

import 'spec_test.dart' as _;

main() {
  _.skipAll = false;
  // ignore: deprecated_member_use
  _.filterFileBasenames = [
    'interpolation',
    'sections',
    'inverted',
    'comments',
    'partials'
  ];
  _.main();
}
