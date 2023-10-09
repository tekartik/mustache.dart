import 'import.dart';

abstract mixin class SourceMixin {
  String? get source;

  String getChar(int index) {
    return source!.substring(index, index + 1);
  }

  int trimStart(int start) {
    while (start < source!.length && isInlineWhitespace(getChar(start))) {
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

  String getSourceText(int start, int end) =>
      sourceGetText(source!, start, end);
}

String sourceGetText(String source, int start, int? end) {
  return source.substring(start, end);
}

abstract class SourceContent {
  factory SourceContent(String source, int start, int end) =>
      _SourceContent(source, start, end);

  String? get source;

  int? get start;

  int? get end;
}

class _SourceContent implements SourceContent {
  @override
  final String source;
  @override
  final int start;
  @override
  final int end;

  _SourceContent(this.source, this.start, this.end);
}
