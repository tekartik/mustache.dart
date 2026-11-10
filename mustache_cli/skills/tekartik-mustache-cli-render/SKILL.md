---
name: tekartik-mustache-cli-render
description: >-
  Use when rendering a Mustache template file from the command line or from a
  build script with tekartik_mustache_cli: the mustacheMain(arguments) entry
  point of package:tekartik_mustache_cli/mustache_cli.dart, the ready made
  package:tekartik_mustache_cli/bin/mustache_cli.dart executable, its
  "<yaml_or_json> <template>" argument order and its --out/-o, --help/-h,
  --version/-v options.
---

# Mustache command line renderer (tekartik_mustache_cli)

`tekartik_mustache_cli` is a one command wrapper over `tekartik_mustache_fs`:
it reads a json or yaml data file and a template file from the real file
system, renders the template with that data and writes the result to stdout or
to a file.

## Guidelines

* Dependency (git only, not on pub.dev). It is a tool, so a `dev_dependencies`
  entry is usually the right place:
  ```yaml
  dev_dependencies:
    tekartik_mustache_cli:
      git:
        url: https://github.com/tekartik/mustache.dart
        path: mustache_cli
  ```
* The package exports a single symbol from
  `package:tekartik_mustache_cli/mustache_cli.dart`:
  `Future mustacheMain(List<String> arguments)`. It is `dart:io` based (VM or
  Flutter native only).
* There is no `bin/` directory in the package, so `dart run
  tekartik_mustache_cli` does not work. To get a command in your own package,
  create a `bin/mustache_cli.dart` that re-exports
  `package:tekartik_mustache_cli/bin/mustache_cli.dart` (that library is a
  `main` calling `mustacheMain`), then run `dart run
  <your_package>:mustache_cli ...`. Anywhere else, just call `mustacheMain`
  with the argument list yourself.
* Arguments: `mustache_cli <yaml_or_json> <template>` - **data file first,
  template second**. Options: `-o, --out <file>` (write there instead of
  stdout), `-h, --help`, `-v, --version`. Anything but exactly two positional
  arguments prints the usage on stderr and exits with code 64 (usage error;
  `--help` and `--version` exit 0).
* The data file extension picks the parser (`.json` json, `.yaml` / `.yml`
  yaml); if it fails or the extension is something else, the other format is
  tried too, so an extensionless file still works. The decoded document must be
  a map, otherwise the command writes `source data is not a map` on stderr and
  throws.
* The template is rendered by `renderFile` of `tekartik_mustache_fs` on
  `fileSystemIo`, so `{{> partial }}` includes are read as files relative to
  the template that includes them, and the whole `tekartik_mustache` syntax
  applies (see the `tekartik-mustache-render` skill of the `tekartik_mustache`
  package for `{{var}}` vs `{{{var}}}`, sections, inverted sections).
* Without `--out` the result is printed with `stdout.writeln`, adding a
  trailing newline; with `--out` it is written verbatim with `writeAsString`
  (the parent directory must already exist).
* `mustacheMain` calls `exit()` for `--help`, `--version`, a usage error and
  when rendering returns null (exit code 1): never call it from a server or a
  test you expect to survive. In that case call `renderFile(fileSystemIo, template, values:
  ...)` from `tekartik_mustache_fs` directly.
* Anti-patterns: passing the template before the data file; expecting a
  `--values` style option (there is none, only a data file); expecting the
  missing output directory to be created.

## Examples

### Expose the command in your own package

```dart
// bin/mustache_cli.dart of your package: `dart run <your_package>:mustache_cli`
export 'package:tekartik_mustache_cli/bin/mustache_cli.dart';
```

### Run it

```bash
# data file first, template second
dart run my_package:mustache_cli data.json template/index.html

# write to a file instead of stdout
dart run my_package:mustache_cli config.yaml template/index.html -o build/index.html
```

### Call it from a build script

```dart
import 'package:path/path.dart';
import 'package:tekartik_mustache_cli/mustache_cli.dart';

Future<void> main() async {
  var dir = join('example', 'basic');
  await mustacheMain([
    join(dir, 'data.json'),
    join(dir, 'index.html'),
    '--out',
    join('.local', 'index.html'),
  ]);
}
```

### Render in process instead (no exit calls)

```dart
import 'package:fs_shim/fs_io.dart';
import 'package:tekartik_mustache_fs/mustache_fs.dart';

/// Same rendering as the command, but returns the text and never exits.
Future<String?> renderTemplate(String dataPath, String templatePath) async {
  return await renderFile(fileSystemIo, templatePath, jsonPath: dataPath);
}
```
