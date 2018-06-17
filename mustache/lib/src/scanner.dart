import 'package:tekartik_mustache/src/node.dart';

String openDelimiter = "{{";
int openDelimiterLength = openDelimiter.length;
String closeDelimiter = "}}";
int closeDelimiterLength = closeDelimiter.length;
String nl = '\n';
int nlLength = nl.length;
String crnl = '\r\n';
int crnlLength = crnl.length;

var openDelimiterRegExp = new RegExp("\{\{");
var closeDelimiterRegExp = new RegExp("\}\}");
var nlRegExp = new RegExp('\\n');
var crnlRegExp = new RegExp('\\r\\n');

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

  // To know if we scan an open mustache
  bool atOpenDelimiter = false;

  void scan() {
    while (!atEnd) {
      ScannerNode node = scanOpen();
      if (node != null) {
        nodes.add(node);
      }
      if (!atEnd && atOpenDelimiter) {
        node = scanClose();
        if (node != null) {
          nodes.add(node);
        }
      }
    }
  }

  TextScannerNode scanOpen() {
    atOpenDelimiter = false;

    int start = index;
    var text = source.substring(start);
    int end = text.indexOf(openDelimiterRegExp);

    // We split by lines
    // \r\n
    int crnlEnd = text.indexOf(crnlRegExp);
    if (crnlEnd != -1) {
      if (end == -1 || crnlEnd < end) {
        index = start + crnlEnd + crnlLength;
        return new TextScannerNode(start, index);
      }
    }
    // \n
    int nlEnd = text.indexOf(nlRegExp);
    if (nlEnd != -1) {
      if (end == -1 || nlEnd < end) {
        index = start + nlEnd + nlLength;
        return new TextScannerNode(start, index);
      }
    }

    if (end == -1) {
      end = this.end;
      index = end;
    } else {
      // Found!
      atOpenDelimiter = true;
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
