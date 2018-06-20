import 'dart:async';
import 'dart:convert';

import 'package:fs_shim/fs.dart';
import 'package:path/src/context.dart';
import 'package:tekartik_firebase/storage.dart' as storage;
import 'package:path/path.dart';

class FileSystemStorage extends FileSystemNope {
  final storage.Bucket bucket;

  FileSystemStorage(this.bucket);
  @override
  Directory directory(String path) => new DirectoryStorage(this, path);

  @override
  File file(String path) {
    var storageFile = bucket.file(path);
    if (storageFile != null) {
      return new FileStorage(this, path, storageFile);
    }
    return null;
  }

  @override
  String get name => "storage";

  @override
  Context get pathContext => url;

  @override
  bool get supportsFileLink => false;

  @override
  bool get supportsLink => false;
}

class FileStorage extends FileSystemEntityStorage
    with FileNope
    implements File {
  final storage.File nativeInstance;

  FileStorage(FileSystem fs, String path, this.nativeInstance)
      : super(fs, path);

  @override
  Future<List<int>> readAsBytes() async {
    return await nativeInstance.download();
  }

  @override
  Future<File> writeAsBytes(List<int> bytes,
      {FileMode mode: FileMode.write, bool flush: false}) async {
    await nativeInstance.save(bytes);
    return this;
  }

  @override
  Future<File> writeAsString(String contents,
      {FileMode mode: FileMode.write,
      Encoding encoding: utf8,
      bool flush: false}) async {
    await nativeInstance.save(contents);
    return this;
  }
}

class DirectoryStorage extends FileSystemEntityStorage
    with DirectoryNope
    implements Directory {
  DirectoryStorage(FileSystem fs, String path) : super(fs, path);

  @override
  Future<Directory> create({bool recursive: false}) async {
    // there is no directory so it is always created
    return this;
  }
}

abstract class FileSystemEntityStorage extends Object
    with FileSystemEntityNope
    implements FileSystemEntity {
  @override
  final FileSystem fs;

  @override
  final String path;

  FileSystemEntityStorage(this.fs, this.path);
}

class FileSystemNope implements FileSystem {
  @override
  Directory directory(String path) => throw UnsupportedError("directory");

  @override
  File file(String path) => throw UnsupportedError("file");

  @override
  Future<bool> isDirectory(String path) =>
      throw UnsupportedError("isDirectory");

  @override
  Future<bool> isFile(String path) => throw UnsupportedError("isFile");

  @override
  Future<bool> isLink(String path) => throw UnsupportedError("isLink");

  @override
  Link link(String path) => throw UnsupportedError("link");

  @override
  String get name => "storage";

  @override
  Directory newDirectory(String path) => directory(path);

  @override
  File newFile(String path) => file(path);

  @override
  Link newLink(String path) => link(path);

  @override
  Context get pathContext => url;

  @override
  bool get supportsFileLink => false;

  @override
  bool get supportsLink => false;

  @override
  Future<FileSystemEntityType> type(String path, {bool followLinks: true}) =>
      throw UnsupportedError("type");
}

abstract class FileNope implements File {
  @override
  File get absolute => throw UnsupportedError("absolute");

  @override
  Future<File> copy(String newPath) => throw UnsupportedError("copy");

  @override
  Future<File> create({bool recursive: false}) =>
      throw UnsupportedError("create");

  @override
  Stream<List<int>> openRead([int start, int end]) =>
      throw UnsupportedError("openRead");

  @override
  StreamSink<List<int>> openWrite(
          {FileMode mode: FileMode.write, Encoding encoding: utf8}) =>
      throw UnsupportedError("openWrite");

  @override
  Future<List<int>> readAsBytes() => throw UnsupportedError("readAsBytes");

  @override
  Future<String> readAsString({Encoding encoding: utf8}) async {
    var bytes = await readAsBytes();
    return utf8.decode(bytes);
  }

  @override
  Future<File> writeAsBytes(List<int> bytes,
          {FileMode mode: FileMode.write, bool flush: false}) =>
      throw UnsupportedError("writeAsBytes");

  @override
  Future<File> writeAsString(String contents,
      {FileMode mode: FileMode.write,
      Encoding encoding: utf8,
      bool flush: false}) async {
    return await writeAsBytes(utf8.encode(contents), mode: mode, flush: flush);
  }
}

abstract class FileSystemEntityNope implements FileSystemEntity {
  @override
  Future<FileSystemEntity> delete({bool recursive: false}) =>
      throw UnsupportedError("delete");

  @override
  Future<bool> exists() => throw UnsupportedError("exists");

  @override
  bool get isAbsolute => throw UnsupportedError("isAbsolute");

  @override
  Directory get parent => throw UnsupportedError("parent");

  @override
  String get path => throw UnsupportedError("path");

  @override
  Future<FileSystemEntity> rename(String newPath) =>
      throw UnsupportedError("rename");

  @override
  Future<FileStat> stat() => throw UnsupportedError("stat");

  @override
  FileSystem get fs => throw UnsupportedError("fs");
}

abstract class DirectoryNope implements Directory {
  @override
  Directory get absolute => throw UnsupportedError("Directory.absolute");

  @override
  Future<Directory> create({bool recursive: false}) =>
      throw UnsupportedError("Directory.create");

  @override
  Stream<FileSystemEntity> list(
          {bool recursive: false, bool followLinks: true}) =>
      throw UnsupportedError("Directory.list");
}

FileSystem fileSystemStorage(storage.Bucket bucket) =>
    new FileSystemStorage(bucket);
