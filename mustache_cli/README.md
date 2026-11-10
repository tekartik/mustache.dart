# tekartik_mustache_cli

Render a [Mustache](https://mustache.github.io/) template file with the
values of a json or yaml file, from the command line or a build script. It
wraps `renderFile` of [tekartik_mustache_fs](../mustache_fs) on the real file
system (`dart:io`: Dart VM, not the web).

## Getting started

Not on pub.dev, add it as a git dependency (a tool: `dev_dependencies`):

```yaml
dev_dependencies:
  tekartik_mustache_cli:
    git:
      url: https://github.com/tekartik/mustache.dart
      path: mustache_cli
```

From a build script:

```dart
import 'package:tekartik_mustache_cli/mustache_cli.dart';

Future<void> main() async {
  // Data file first, template second.
  await mustacheMain(['data.json', 'index.html', '--out', 'build/index.html']);
}
```

As a command: the package has no `bin/`, so add a `bin/mustache_cli.dart` to
your package with
`export 'package:tekartik_mustache_cli/bin/mustache_cli.dart';`, then:

```bash
dart run my_package:mustache_cli data.json index.html -o build/index.html
```

## Usage

```
mustache_cli <yaml_or_json> <template>
-v, --[no-]version    Version
-h, --[no-]help       Help
-o, --out             Destination file
```

* The data file must hold a map; its extension picks json (`.json`) or yaml
  (`.yaml`, `.yml`), the other format is tried when that fails.
* Partials (`{{> name}}`) are files relative to the including template.
* Without `--out` the result goes to stdout followed by a new line.
* Exit codes: 0 on success and for `--help` / `--version`, 64 for a wrong
  number of arguments, 1 when the rendering returns nothing.

## Common pitfalls

* `mustacheMain` calls `exit()` (help, version, errors): in a server or a
  test, call `renderFile(fileSystemIo, template, values: ...)` of
  tekartik_mustache_fs instead.
* The `--out` parent folder must exist.
