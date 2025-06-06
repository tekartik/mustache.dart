import 'dart:async';
import 'dart:convert';

import 'package:args/args.dart';
import 'package:fs_shim/fs_io.dart';
import 'package:path/path.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:tekartik_mustache_fs/mustache_fs.dart';
import 'package:yaml/yaml.dart';

const String versionFlag = 'version';
const String helpFlag = 'help';
const String optionOut = 'out';

final version = Version(0, 1, 0);

var fs = fileSystemIo;

Future mustacheMain(List<String> arguments) async {
  var parser = ArgParser();
  parser.addFlag(versionFlag, abbr: 'v', help: 'Version');
  parser.addFlag(helpFlag, abbr: 'h', help: 'Help');
  parser.addOption(optionOut, abbr: 'o', help: 'Destination file');
  var result = parser.parse(arguments);

  void printUsage() {
    print('mustache_cli <yaml_or_json> <template>');
    print(parser.usage);
    exit(0);
  }

  if (result[helpFlag] == true) {
    printUsage();
  }
  if (result[versionFlag] == true) {
    print('version $version');
    exit(0);
  }

  final outFilePath = result[optionOut] as String?;
  var rest = result.rest;
  if (rest.length != 2) {
    printUsage();
  }

  var dataFilePath = rest[0];
  var templateFilePath = rest[1];
  var dataExtension = extension(dataFilePath).toLowerCase();
  Object? data;

  final canBeJson = dataExtension == '.json';
  final canBeYaml = dataExtension == '.yaml' || dataExtension == '.yml';

  Object? exception;
  var dataContent = await fs.file(dataFilePath).readAsString();

  void tryDecode(dynamic Function(String encoded) decode) {
    try {
      data = decode(dataContent);
    } catch (e) {
      exception ??= e;
    }
  }

  void tryJson() => tryDecode(json.decode);
  void tryYaml() => tryDecode(loadYaml);

  if (canBeJson) {
    tryJson();
  } else if (canBeYaml) {
    tryYaml();
  }

  // failing try everything
  if (data == null) {
    if (!canBeJson) {
      tryJson();
    }

    if (data == null && !canBeYaml) {
      tryYaml();
    }
  }

  if (data is! Map) {
    stderr.writeln('source data is not a map');
    throw exception ?? StateError('source data not a map');
  }

  var mustacheResult = await renderFile(
    fs,
    templateFilePath,
    values: (data as Map).cast<String, dynamic>(),
  );
  if (mustacheResult != null) {
    if (outFilePath != null) {
      await fs.file(outFilePath).writeAsString(mustacheResult);
    } else {
      print(mustacheResult);
    }
  } else {
    stderr.writeln(
      "Failed to render file '$templateFilePath' with data from file '$dataFilePath'",
    );
    exit(1);
  }
}
