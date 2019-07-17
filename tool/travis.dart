import 'package:process_run/shell.dart';

Future main() async {
  var shell = Shell();

  for (var dir in [
    'mustache',
    'mustache_fs',
    'mustache_cli',
  ]) {
    shell = shell.pushd(dir);
    await shell.run('''
    
    pub get
    dart tool/travis.dart
    
''');
    shell = shell.popd();
  }
}
