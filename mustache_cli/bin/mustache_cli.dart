#!/usr/bin/env dart

library tekartik_script.bin.mustache_cli;

import 'dart:async';

import 'package:tekartik_mustache_cli/mustache_cli.dart' as mustache_cli;

Future main(List<String> arguments) => mustache_cli.mustacheMain(arguments);
