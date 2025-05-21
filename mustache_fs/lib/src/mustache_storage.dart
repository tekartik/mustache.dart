import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:fs_shim/fs.dart';
import 'package:fs_shim/fs_none.dart';
import 'package:path/path.dart';
import 'package:tekartik_common_utils/byte_utils.dart';
import 'package:tekartik_firebase_storage/storage.dart' as storage;

import 'fs_shim_import.dart';

class FileSystemStorage with FileSystemMixin {
  final storage.Bucket bucket;

  FileSystemStorage(this.bucket);

  @override
  Directory directory(String? path) => DirectoryStorage(this, path!);

  @override
  File file(String? path) {
    var storageFile = bucket.file(path!);
    return FileStorage(this, path, storageFile);
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
    with FileMixin
    implements File {
  final storage.File nativeInstance;

  FileStorage(super.fs, super.path, this.nativeInstance);

  @override
  Future<Uint8List> readAsBytes() async {
    var list = await nativeInstance.readAsBytes();
    return list;
  }

  @override
  Future<File> writeAsBytes(
    List<int> bytes, {
    FileMode mode = FileMode.write,
    bool flush = false,
  }) async {
    await nativeInstance.writeAsBytes(asUint8List(bytes));
    return this;
  }

  @override
  Future<File> writeAsString(
    String contents, {
    FileMode mode = FileMode.write,
    Encoding encoding = utf8,
    bool flush = false,
  }) async {
    await nativeInstance.writeAsString(contents);
    return this;
  }
}

class DirectoryStorage extends FileSystemEntityStorage
    with DirectoryMixin
    implements Directory {
  DirectoryStorage(super.fs, super.path);

  @override
  Future<Directory> create({bool recursive = false}) async {
    // there is no directory so it is always created
    return this;
  }
}

abstract class FileSystemEntityStorage extends Object
    with FileSystemEntityMixin
    implements FileSystemEntity {
  @override
  final FileSystem fs;

  @override
  final String path;

  FileSystemEntityStorage(this.fs, this.path);
}

FileSystem fileSystemStorage(storage.Bucket bucket) =>
    FileSystemStorage(bucket);
