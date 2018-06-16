import 'package:tekartik_mustache/src/node.dart';

String openDelimiter = "{{";
int openDelimiterLength = openDelimiter.length;
String closeDelimiter = "}}";
int closeDelimiterLength = closeDelimiter.length;

var openDelimiterRegExp = new RegExp("\{\{");
var closeDelimiterRegExp = new RegExp("\}\}");

abstract class ScannerNode extends Node {
  ScannerNode(int start, int end) : super(start, end);
}

class TextScannerNode extends ScannerNode {
  TextScannerNode(int start, int end) : super(start, end);

  @override
  int get hashCode => super.hashCode;

  @override
  bool operator ==(other) {
    return other is TextScannerNode && super == (other);
  }

  @override
  String toString() {
    return "TextScanner ${super.toString()}";
  }
}

class MustacheScannerNode extends ScannerNode {
  MustacheScannerNode(int start, int end) : super(start, end);

  @override
  int get hashCode => super.hashCode;

  @override
  bool operator ==(other) {
    return other is MustacheScannerNode && super == (other);
  }

  @override
  String toString() {
    return "Mustache ${super.toString()}";
  }
}

class Scanner {
  final String source;

  Scanner(this.source) : end = source.length;

  int index = 0;
  final int end;

  bool get atEnd => index == end;

  void scan() {
    while (!atEnd) {
      ScannerNode node = scanOpen();
      if (node != null) {
        nodes.add(node);
      }
      if (!atEnd) {
        node = scanClose();
        if (node != null) {
          nodes.add(node);
        }
      }
    }
  }

  TextScannerNode scanOpen() {
    int start = index;
    int end = source.substring(start).indexOf(openDelimiterRegExp);
    if (end == -1) {
      end = this.end;
      index = end;
    } else {
      end += start;
      index = end + openDelimiterLength;
      if (end == start) {
        return null;
      }
    }
    return new TextScannerNode(start, end);
  }

  MustacheScannerNode scanClose() {
    int start = index;
    int end = source.substring(start).indexOf(closeDelimiterRegExp);
    if (end == -1) {
      end = this.end;
      index = end;
    } else {
      end += start;
      index = end + closeDelimiterLength;
      if (end == start) {
        return null;
      }
    }
    return new MustacheScannerNode(start, end);
  }

  final List<ScannerNode> nodes = [];
}

List<ScannerNode> scan(String source) {
  if (source == null) {
    return null;
  }
  var scanner = new Scanner(source);
  scanner.scan();
  return scanner.nodes;
}
