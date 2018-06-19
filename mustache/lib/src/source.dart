import 'import.dart';

abstract class SourceMixin {
  String get source;

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

  String getSourceText(int start, int end) => sourceGetText(source, start, end);
}

String sourceGetText(String source, int start, int end) {
  return source.substring(start, end);
}
