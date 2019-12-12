import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:fs_shim/fs.dart';
import 'package:path/path.dart';
import 'package:tekartik_firebase_storage/storage.dart' as storage;
import 'package:fs_shim/fs_none.dart';

class FileSystemStorage extends FileSystemNone {
  final storage.Bucket bucket;

  FileSystemStorage(this.bucket);
  @override
  Directory directory(String path) => DirectoryStorage(this, path);

  @override
  File file(String path) {
    var storageFile = bucket.file(path);
    if (storageFile != null) {
      return FileStorage(this, path, storageFile);
    }
    return null;
  }

  @override
  Context get path => url;

  @override
  String get name => 'storage';

  @override
  Context get pathContext => url;

  @override
  bool get supportsFileLink => false;

  @override
  bool get supportsLink => false;
}

class FileStorage extends FileSystemEntityStorage
    with FileNone
    implements File {
  final storage.File nativeInstance;

  FileStorage(FileSystem fs, String path, this.nativeInstance)
      : super(fs, path);

  @override
  Future<Uint8List> readAsBytes() async {
    var list = await nativeInstance.download();
    if (list is Uint8List) {
      return list;
    }
    return Uint8List.fromList(list);
  }

  @override
  Future<File> writeAsBytes(List<int> bytes,
      {FileMode mode = FileMode.write, bool flush = false}) async {
    await nativeInstance.save(bytes);
    return this;
  }

  @override
  Future<File> writeAsString(String contents,
      {FileMode mode = FileMode.write,
      Encoding encoding = utf8,
      bool flush = false}) async {
    await nativeInstance.save(contents);
    return this;
  }
}

class DirectoryStorage extends FileSystemEntityStorage
    with DirectoryNone
    implements Directory {
  DirectoryStorage(FileSystem fs, String path) : super(fs, path);

  @override
  Future<Directory> create({bool recursive = false}) async {
    // there is no directory so it is always created
    return this;
  }
}

abstract class FileSystemEntityStorage extends Object
    with FileSystemEntityNone
    implements FileSystemEntity {
  @override
  final FileSystem fs;

  @override
  final String path;

  FileSystemEntityStorage(this.fs, this.path);
}

FileSystem fileSystemStorage(storage.Bucket bucket) =>
    FileSystemStorage(bucket);
