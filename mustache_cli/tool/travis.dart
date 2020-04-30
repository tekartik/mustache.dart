import 'package:process_run/shell.dart';
import 'package:pub_semver/pub_semver.dart';

Future main() async {
  var shell = Shell();

  await shell.run('''
# Analyze code
dartanalyzer --fatal-warnings --fatal-infos .
pub run test -p vm
''');

  // Formatting change int 2.9 with hashbang first line
  if (dartVersion >= Version(2, 9, 0, pre: '0')) {
    await shell.run('dartfmt -n --set-exit-if-changed .');
  }
}
