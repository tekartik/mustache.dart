import 'package:tekartik_mustache/src/node.dart';
import 'package:tekartik_mustache/src/source.dart';

import 'import.dart';

String openDelimiterDefault = "{{";
String closeDelimiterDefault = "}}";

String noEscapeDelimiter = "{";
int noEscapeDelimiterLength = noEscapeDelimiter.length;

var defaultNoEscapeDelimiterRegExp = new RegExp("\{");
var defaultNoEscapeCloseDelimiterRegExp = new RegExp("\}\}\}");
var nlRegExp = new RegExp('\\n');

class ScannerDelimiter {
  final String open;
  final String close;
  RegExp openRegExp;
  RegExp closeRegExp;
  bool isDefault;

  ScannerDelimiter(this.open, this.close) {
    openRegExp = new RegExp(RegExp.escape(open));
    closeRegExp = new RegExp(RegExp.escape(close));
    isDefault = open == openDelimiterDefault && close == closeDelimiterDefault;
  }
}

class DefaultScannerDelimiter extends ScannerDelimiter {
  DefaultScannerDelimiter()
      : super(openDelimiterDefault, closeDelimiterDefault);
}

abstract class ScannerNode extends Node {
  ScannerNode(String text) : super(text);
}

class TextScannerNode extends ScannerNode {
  TextScannerNode(String text) : super(text);

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
  MustacheScannerNode(String text) : super(text);

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



// Scan by line
class Scanner extends Object with SourceMixin {
  final String source;

  Scanner(this.source) : end = source.length;

  int index = 0;
  final int end;
  ScannerDelimiter delimiter = new DefaultScannerDelimiter();

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
    int end = text.indexOf(delimiter.openRegExp);

    /*
    // We split by lines
    // \r\n
    int crnlEnd = text.indexOf(crnlRegExp);
    if (crnlEnd != -1) {
      if (end == -1 || crnlEnd < end) {
        index = start + crnlEnd + crnlLength;
        return new TextScannerNode(start, index);
      }
    }
    */
    // \n
    int nlEnd = text.indexOf(nlRegExp);
    if (nlEnd != -1) {
      if (end == -1 || nlEnd < end) {
        index = start + nlEnd + nlLength;
        return new TextScannerNode(getSourceText(start, index));
      }
    }

    if (end == -1) {
      end = this.end;
      index = end;
    } else {
      // Found!
      atOpenDelimiter = true;

      // Trim whitespaces

      end += start;
      index = end + delimiter.open.length;

      if (end == start) {
        return null;
      }
    }
    return new TextScannerNode(getSourceText(start, end));
  }

  MustacheScannerNode scanClose() {
    int start = index;
    var text = source.substring(start);

    bool defaultNoEscape = false;
    int end;

    // handle triple escape only for default delimiters
    if (delimiter.isDefault) {
      // Are we in a triple escape mode?
      defaultNoEscape = text.startsWith(defaultNoEscapeDelimiterRegExp);
    }
    end = source.substring(start).indexOf(defaultNoEscape
        ? defaultNoEscapeCloseDelimiterRegExp
        : delimiter.closeRegExp);
    if (end == -1) {
      end = this.end;
      index = end;
    } else {
      // include the no escape delimited
      if (defaultNoEscape) {
        end++;
      }
      end += start;
      index = end + delimiter.close.length;

      // trim
      while (isInlineWhitespace(getChar(start))) {
        start++;
      }
      while (isInlineWhitespace(getChar(end - 1))) {
        end--;
      }

      if (end <= start) {
        return null;
      }
    }

    // Handle delimiter change...
    if (getChar(start) == '=' && getChar(end - 1) == '=') {
      int index = start + 1;

      _skipWhitespaces() {
        while (true) {
          var chr = getChar(index);
          if (isInlineWhitespace(chr)) {
            index++;
          }
          break;
        }
      }

      _skipWhitespaces();

      var sb = new StringBuffer();
      while (true) {
        var chr = getChar(index++);
        if (isInlineWhitespace(chr)) {
          break;
        }
        sb.write(chr);
      }
      var openDelimiter = sb.toString();

      _skipWhitespaces();

      sb = new StringBuffer();
      while (true) {
        if (index >= end) {
          break;
        }
        var chr = getChar(index++);
        if (isInlineWhitespace(chr)) {
          break;
        }
        if (chr == '=') {
          break;
        }

        sb.write(chr);
      }
      var closeDelimiter = sb.toString();
      delimiter = new ScannerDelimiter(openDelimiter, closeDelimiter);

      // Skip it from result
      return null;
    }
    return new MustacheScannerNode(getSourceText(start, end));
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
