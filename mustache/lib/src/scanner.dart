import 'package:tekartik_mustache/src/node.dart';
import 'package:tekartik_mustache/src/source.dart';

import 'import.dart';

String openDelimiterDefault = "{{";
String closeDelimiterDefault = "}}";

String noEscapeDelimiter = "{";
int noEscapeDelimiterLength = noEscapeDelimiter.length;

var defaultNoEscapeDelimiterRegExp = RegExp("\{");
var defaultNoEscapeCloseDelimiterRegExp = RegExp("\}\}\}");
var nlRegExp = RegExp('\\n');

class ScannerDelimiter {
  final String open;
  final String close;
  RegExp openRegExp;
  RegExp closeRegExp;
  bool isDefault;

  ScannerDelimiter(this.open, this.close) {
    openRegExp = RegExp(RegExp.escape(open));
    closeRegExp = RegExp(RegExp.escape(close));
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
}

class MustacheScannerNode extends ScannerNode
    with SourceMixin
    implements SourceContent {
  @override
  final String source;
  @override
  final int start;
  @override
  final int end;

  final ScannerDelimiter delimiter;

  MustacheScannerNode(
      this.source, this.start, this.end, this.delimiter, String text)
      : super(text);
  MustacheScannerNode.withText(String text)
      : source = null,
        start = null,
        end = null,
        delimiter = null,
        super(text);
}

// Scan by line
class Scanner extends Object with SourceMixin {
  @override
  final String source;

  Scanner(this.source) : end = source.length;

  // set before the opening delimited
  int outerStart;
  int index = 0;
  final int end;
  ScannerDelimiter delimiter = DefaultScannerDelimiter();

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
        outerStart = index;
        return TextScannerNode(getSourceText(start, index));
      }
    }

    if (end == -1) {
      end = this.end;
      index = end;
      outerStart = index;
    } else {
      // Found!
      atOpenDelimiter = true;

      // Trim whitespaces

      end += start;
      outerStart = end;
      index = outerStart + delimiter.open.length;

      if (end == start) {
        return null;
      }
    }
    return TextScannerNode(getSourceText(start, end));
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

      void _skipWhitespaces() {
        while (true) {
          var chr = getChar(index);
          if (isInlineWhitespace(chr)) {
            index++;
          }
          break;
        }
      }

      _skipWhitespaces();

      var sb = StringBuffer();
      while (true) {
        var chr = getChar(index++);
        if (isInlineWhitespace(chr)) {
          break;
        }
        sb.write(chr);
      }
      var openDelimiter = sb.toString();

      _skipWhitespaces();

      sb = StringBuffer();
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
      delimiter = ScannerDelimiter(openDelimiter, closeDelimiter);

      // 2018-06-19 keep it doe handling standalone later
      // Skip it from result
      // return null;
    }

    // index is the outer end
    return MustacheScannerNode(source, outerStart, index, delimiter,
        sourceGetText(source, start, end));
  }

  final List<ScannerNode> nodes = [];
}

List<ScannerNode> scan(String source) {
  if (source == null) {
    return null;
  }
  var scanner = Scanner(source);
  scanner.scan();
  return scanner.nodes;
}
