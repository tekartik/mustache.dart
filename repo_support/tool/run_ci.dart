import 'package:dev_build/package.dart';
import 'package:path/path.dart';

Future main() async {
  for (var dir in [
    'mustache',
    'mustache_cli',
    'mustache_fs',
  ]) {
    await packageRunCi(join('..', dir));
  }
}
