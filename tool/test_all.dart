//import 'package:tekartik_build_utils/cmd_run.dart';
import 'package:tekartik_build_utils/common_import.dart';

Future testMustache() async {
  var dir = 'mustache';
  await runCmd(pubCmd(pubGetArgs())..workingDirectory = dir);
  await runCmd(dartanalyzerCmd(['lib', 'test'])..workingDirectory = dir);
  await runCmd(pubCmd(pubRunTestArgs(platforms: ['vm', 'chrome']))
    ..workingDirectory = dir);
}

Future testMustacheCli() async {
  var dir = 'mustache_cli';
  await runCmd(pubCmd(pubGetArgs())..workingDirectory = dir);
  await runCmd(dartanalyzerCmd(['bin', 'lib', 'test'])..workingDirectory = dir);
  await runCmd(
      pubCmd(pubRunTestArgs(platforms: ['vm']))..workingDirectory = dir);
}

Future testMustacheFs() async {
  var dir = 'mustache_fs';
  await runCmd(pubCmd(pubGetArgs())..workingDirectory = dir);
  await runCmd(dartanalyzerCmd(['lib', 'test'])..workingDirectory = dir);
  await runCmd(
      pubCmd(pubRunTestArgs(platforms: ['vm']))..workingDirectory = dir);
}

Future main() async {
  await testMustache();
  await testMustacheCli();
  await testMustacheFs();
}
