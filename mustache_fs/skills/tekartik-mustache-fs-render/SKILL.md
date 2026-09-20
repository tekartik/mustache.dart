---
name: tekartik-mustache-fs-render
description: >-
  Use when rendering Mustache template files from a file system in Dart with
  tekartik_mustache_fs: renderFile(fs, path, {values, yamlPath, jsonPath}) over
  an fs_shim FileSystem (fileSystemIo, newFileSystemMemory), relative {{>
  partial }} includes resolved against the including file, and
  fileSystemStorage(bucket) from mustache_storage.dart to render templates
  stored in a tekartik_firebase_storage Bucket.
---

# Rendering template files (tekartik_mustache_fs)

`tekartik_mustache_fs` glues `tekartik_mustache` to an `fs_shim` `FileSystem`:
one call renders a template file, its `{{> partial }}` includes are read as
files relative to the file that includes them, and the values can come from a
yaml or json file. The same code runs on the real file system, on an in memory
one, or on a Google Cloud Storage bucket.

## Guidelines

* Dependencies (git only, not on pub.dev); `fs_shim` comes from pub.dev:
  ```yaml
  dependencies:
    tekartik_mustache_fs:
      git:
        url: https://github.com/tekartik/mustache.dart
        path: mustache_fs
    fs_shim: any
  ```
* Imports: `package:tekartik_mustache_fs/mustache_fs.dart` exports exactly one
  function, `renderFile`; `package:tekartik_mustache_fs/mustache_storage.dart`
  exports `renderFile` and `fileSystemStorage`. The `FileSystem` type and the
  implementations come from `fs_shim`:
  `package:fs_shim/fs_io.dart` (`fileSystemIo`, VM only),
  `package:fs_shim/fs_memory.dart` (`newFileSystemMemory()`, everywhere, ideal
  in tests), `package:fs_shim/fs.dart` for the `FileSystem` type alone.
* `Future<String?> renderFile(FileSystem fs, String path, {Map<String, dynamic>?
  values, String? yamlPath, String? jsonPath})` reads `path` through `fs`,
  renders it and returns the result. The values are taken from `values` when it
  is not null, otherwise from `yamlPath` (parsed with `package:yaml`), else
  from `jsonPath` (a json object), else there are none: passing `values` makes
  `yamlPath` and `jsonPath` ignored, and `yamlPath` wins over `jsonPath`. The
  yaml/json document must be a map.
* Partials: `{{> other }}` is read as a file. A relative name is resolved
  against the directory of the file that includes it (with `fs.path`, so `/`
  on the memory and storage file systems and the platform separator on io),
  and the resolution chains: a partial included from `sub1/file2` resolves its
  own relative includes against `sub1/`. A missing partial file throws whatever
  the file system throws (a `FileSystemException` on io), it is not silently
  empty. Spaces inside the tag (`{{> other }}`) are trimmed.
* The template syntax and the values semantics are entirely
  `tekartik_mustache`'s (escaping with `{{var}}` vs `{{{var}}}`, sections,
  inverted sections, lambdas as values): see the `tekartik-mustache-render`
  skill of the `tekartik_mustache` package. This package adds only the file
  resolution, there is no lambda or partial callback parameter here.
* Google Cloud Storage: `fileSystemStorage(bucket)` (from
  `mustache_storage.dart`) adapts a `Bucket` of
  `package:tekartik_firebase_storage/storage.dart` to a `FileSystem`, so the
  templates can live in a bucket. It is a flat view: directories are virtual
  and always "created", `supportsLink` and `supportsFileLink` are false, and
  paths always use `/`. Only `tekartik_firebase_storage` is a real dependency;
  the implementation (`tekartik_firebase_storage_fs`, `..._node`, ...) is
  chosen by the app.
* Testing: use `newFileSystemMemory()`, write the templates with
  `fs.file(path).writeAsString(...)` and `fs.directory(dir).create(recursive:
  true)` before rendering; the package's own tests define a `fsTest(FileSystem
  fs)` suite that they run on memory and on a local storage bucket.
* Anti-patterns: passing a `dart:io` `File`/`Directory` (this API is `fs_shim`
  only); using `fileSystemIo` in web code; expecting `values` and `yamlPath` to
  be merged; expecting an absolute os path to work on the memory or storage
  file system.

## Examples

### Render a template file from the real file system

```dart
import 'package:fs_shim/fs_io.dart';
import 'package:tekartik_mustache_fs/mustache_fs.dart';

Future<void> main() async {
  var text = await renderFile(
    fileSystemIo,
    'template/index.html',
    values: {'title': 'Hello', 'items': [
      {'name': 'one'},
      {'name': 'two'},
    ]},
  );
  print(text);
}
```

### Values from a yaml (or json) file

```dart
import 'package:fs_shim/fs_io.dart';
import 'package:tekartik_mustache_fs/mustache_fs.dart';

Future<String?> build(String template) async {
  // values.yaml: "title: Hello"
  return await renderFile(
    fileSystemIo,
    template,
    yamlPath: 'values.yaml',
  );
  // or: jsonPath: 'values.json' (used only when values and yamlPath are null)
}
```

### Relative includes, in memory (a test)

```dart
import 'package:fs_shim/fs_memory.dart';
import 'package:tekartik_mustache_fs/mustache_fs.dart';
import 'package:test/test.dart';

void main() {
  test('nested relative partials', () async {
    var fs = newFileSystemMemory();
    var path = fs.path;
    await fs.directory(path.join('sub1', 'sub2')).create(recursive: true);
    await fs.file('index.html').writeAsString('[{{> sub1/file2 }}]');
    // Resolved against sub1/, the directory of file2.
    await fs.file(path.join('sub1', 'file2')).writeAsString('{{> sub2/file3 }}');
    await fs.file(path.join('sub1', 'sub2', 'file3')).writeAsString('{{name}}');

    expect(
      await renderFile(fs, 'index.html', values: {'name': 'content'}),
      '[content]',
    );
  });
}
```

### Templates stored in a storage bucket

```dart
import 'package:tekartik_firebase_storage/storage.dart';
import 'package:tekartik_mustache_fs/mustache_storage.dart';

Future<String?> renderFromBucket(Bucket bucket, String path) async {
  var fs = fileSystemStorage(bucket);
  return await renderFile(fs, path, yamlPath: 'values.yaml');
}
```
