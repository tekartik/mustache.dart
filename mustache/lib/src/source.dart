import 'package:tekartik_mustache/src/node.dart';
import 'package:tekartik_mustache/src/parser.dart';
import 'package:tekartik_mustache/src/scanner.dart';

abstract class SourceMixin {
  String get source;

  String getText(Node node) {
    return textAtNode(source, node);
  }

  String getVariableName(VariableNode node) => getText(node);

  String getChar(int index) {
    return source.substring(index, index + 1);
  }

  int trimStart(int start) {
    while (start < source.length && isInlineWhitespace(getChar(start))) {
      start++;
    }

    return start;
  }

  int trimEnd(int end) {
    while (end > 0 && isInlineWhitespace(getChar(end - 1))) {
      end--;
    }
    return end;
  }
}
