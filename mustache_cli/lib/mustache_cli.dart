import 'dart:convert';
import 'dart:io';
import 'package:args/args.dart';
import 'package:fs_shim/fs_io.dart';
import 'package:path/path.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:yaml/yaml.dart';
import 'package:tekartik_mustache_fs/mustache_fs.dart';

const String versionFlag = "version";
const String helpFlag = "help";
const String optionOut = "out";

final version = new Version(0, 1, 0);

var fs = fileSystemIo;

mustacheMain(List<String> arguments) async {
  var parser = new ArgParser();
  parser.addFlag(versionFlag, abbr: "v", help: "Version");
  parser.addFlag(helpFlag, abbr: "h", help: "Help");
  parser.addOption(optionOut, abbr: "o", help: "Destination file");
  var result = parser.parse(arguments);

  _usage() {
    print('mustach_cli <yaml_or_json> <template>');
    print(parser.usage);
    exit(0);
  }

  if (result[helpFlag] == true) {
    _usage();
  }
  if (result[versionFlag] == true) {
    print("version ${version}");
    exit(0);
  }

  String outFilePath = result[optionOut];
  var rest = result.rest;
  if (rest.length != 2) {
    _usage();
  }

  var dataFilePath = rest[0];
  var templateFilePath = rest[1];
  var dataExtension = extension(dataFilePath).toLowerCase();
  var data;

  bool canBeJson = dataExtension == ".json";
  bool canBeYaml = dataExtension == ".yaml" || dataExtension == ".yml";

  var exception;
  var dataContent = await fs.file(dataFilePath).readAsString();

  _try(dynamic decode(String encoded)) {
    try {
      data = decode(dataContent);
    } catch (e) {
      if (exception == null) {
        exception = e;
      }
    }
  }

  _tryJson() => _try(json.decode);
  _tryYaml() => _try(loadYaml);

  if (canBeJson) {
    _tryJson();
  } else if (canBeYaml) {
    _tryYaml();
  }

// failing try everything
  if (data == null) {
    if (!canBeJson) {
      _tryJson();
    }

    if (data == null && !canBeYaml) {
      _tryYaml();
    }
  }

  if (!(data is Map)) {
    stderr.writeln("source data is not a map");
    throw exception;
  }

  var mustacheResult = await renderFile(fs, templateFilePath,
      values: (data as Map).cast<String, dynamic>());
  if (mustacheResult != null) {
    if (outFilePath != null) {
      await fs.file(outFilePath).writeAsString(mustacheResult);
    } else {
      print(mustacheResult);
    }
  } else {
    stderr.writeln(
        "Failed to render file '$templateFilePath' with data from file '$dataFilePath'");
    exit(1);
  }
}
