//import 'package:tekartik_build_utils/cmd_run.dart';
import 'package:tekartik_build_utils/common_import.dart';

Future testMustache() async {
  var dir = 'mustache';
  await runCmd(PubCmd(pubGetArgs())..workingDirectory = dir);
  await runCmd(DartAnalyzerCmd(['lib', 'test'])..workingDirectory = dir);
  await runCmd(PubCmd(pubRunTestArgs(platforms: ['vm', 'chrome']))
    ..workingDirectory = dir);
}

Future testMustacheCli() async {
  var dir = 'mustache_cli';
  await runCmd(PubCmd(pubGetArgs())..workingDirectory = dir);
  await runCmd(DartAnalyzerCmd(['bin', 'lib', 'test'])..workingDirectory = dir);
  await runCmd(
      PubCmd(pubRunTestArgs(platforms: ['vm']))..workingDirectory = dir);
}

Future testMustacheFs() async {
  var dir = 'mustache_fs';
  await runCmd(PubCmd(pubGetArgs())..workingDirectory = dir);
  await runCmd(DartAnalyzerCmd(['lib', 'test'])..workingDirectory = dir);
  await runCmd(
      PubCmd(pubRunTestArgs(platforms: ['vm']))..workingDirectory = dir);
}

Future main() async {
  await testMustache();
  await testMustacheCli();
  await testMustacheFs();
}
