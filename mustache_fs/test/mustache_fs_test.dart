import 'package:tekartik_mustache_fs/mustache_fs.dart';
import 'package:test/test.dart';
import 'package:fs_shim/fs.dart';
import 'package:fs_shim/fs_memory.dart';

main() {
  var fs = newMemoryFileSystem();
  fsTest(fs);
}

fsTest(FileSystem fs) {
  var path = fs.pathContext;
  group('basic', () {
    test('one_file', () async {
      await fs.file("test").writeAsString("content");
      expect(await renderFile(fs, "test"), "content");
    });

    test('include_one_file', () async {
      await fs.file("test").writeAsString("{{> other}}");
      await fs.file("other").writeAsString("content");
      expect(await renderFile(fs, "test"), "content");
    });

    test('include_relative_file', () async {
      var subFilePath = path.join("sub", "other");
      await fs.file("test").writeAsString("{{> ${subFilePath} }}");
      await fs.directory(path.dirname(subFilePath)).create();
      await fs.file(subFilePath).writeAsString("content");
      expect(await renderFile(fs, "test"), "content");
    });

    test('include_from_sub_dir_relative_file', () async {
      var sub = fs.directory("sub");
      var file = fs.file(path.join(sub.path, "file"));
      var other = fs.file(path.join(sub.path, "other"));
      await sub.create();
      await file.writeAsString("{{> other }}");
      await other.writeAsString("content");
      expect(await renderFile(fs, file.path), "content");
    });

    test('nested_relative_file', () async {
      var sub1 = fs.directory("sub1");
      var sub2 = fs.directory(path.join(sub1.path, "sub2"));
      var file1 = fs.file("file1");
      var file2 = fs.file(path.join(sub1.path, "file2"));
      var file3 = fs.file(path.join(sub2.path, "file3"));
      await sub2.create(recursive: true);
      await file1.writeAsString("{{> ${file2.path} }}");
      await file2.writeAsString(
          "{{> ${path.join(path.basename(sub2.path), path.basename(file3.path))} }}");
      await file3.writeAsString("content");
      expect(await renderFile(fs, file1.path), "content");
    });

    test('nested_relative_file_twice', () async {
      var sub1 = fs.directory("sub1");
      var sub2 = fs.directory(path.join(sub1.path, "sub2"));
      var file1 = fs.file("file1");
      var file2 = fs.file(path.join(sub1.path, "file2"));
      var file3 = fs.file(path.join(sub2.path, "file3"));
      await sub2.create(recursive: true);
      await file1.writeAsString("{{> ${file2.path} }} {{> ${file2.path} }}");
      await file2.writeAsString(
          "{{> ${path.join(path.basename(sub2.path), path.basename(file3.path))} }}");
      await file3.writeAsString("content");
      expect(await renderFile(fs, file1.path), "content content");
    });
  });
}
