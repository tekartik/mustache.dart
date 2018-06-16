import 'package:tekartik_mustache/src/node.dart';
import 'package:tekartik_mustache/src/parser.dart';

abstract class SourceMixin {
  String get source;

  String getText(Node node) {
    return textAtNode(source, node);
  }

  String getVariableName(VariableNode node) => getText(node);
}
