import 'package:tekartik_mustache/src/node.dart';
import 'package:tekartik_mustache/src/scanner.dart';
import 'package:collection/collection.dart';
import 'source.dart';

class Source extends Object with SourceMixin {
  final String source;
  final List<ParserNode> nodes = [];

  String startDelimiter = '{{';

  Source(this.source);

  void addNode(ParserNode node) {
    nodes.add(node);
  }

  void parse() {
    var scannerNodes = scan(source);

    for (var scannerNode in scannerNodes) {
      int start = scannerNode.start;
      int end = scannerNode.end;
      if (scannerNode is TextScannerNode) {
        addNode(new TextNode(start, end));
      } else if (scannerNode is MustacheScannerNode) {
        String firstChar = source.substring(start, start + 1);
        switch (firstChar) {
          case '!':
            addNode(new CommentNode(start + 1, end));
            break;
          case '#':
            addNode(new SectionStartNode(start + 1, end));
            break;
          case '^':
            addNode(new SectionStartNode(start + 1, end, inverted: true));
            break;
          case '/':
            addNode(new SectionEndNode(start + 1, end));
            break;
          default:
            addNode(new VariableNode(start, end));
        }
      }
    }

    // Merge in sections
    var newNodes = <ParserNode>[];
    var sectionNodes = <SectionNode>[];

    _addNode(ParserNode node) {
      var sectionNode = sectionNodes.length > 0 ? sectionNodes.last : null;
      if (sectionNode != null) {
        sectionNode.add(node);
      } else {
        newNodes.add(node);
      }
    }

    for (var node in nodes) {
      if (node is SectionStartNode) {
        var sectionNode = new SectionNode(
            new VariableNode(node.start, node.end),
            inverted: node.inverted);
        _addNode(sectionNode);
        sectionNodes.add(sectionNode);
      } else if (node is SectionEndNode) {
        var variableNode = new VariableNode(node.start, node.end);
        var variable = getVariableName(variableNode);
        // Find the section opened from the top of the stack
        for (int i = sectionNodes.length - 1; i >= 0; i--) {
          var sectionNode = sectionNodes[i];
          if (getVariableName(sectionNode.variable) == variable) {
            // truncate of the first found
            sectionNodes = sectionNodes.sublist(0, i);
            break;
          }
        }
      } else {
        _addNode(node);
      }
    }

    nodes
      ..clear()
      ..addAll(newNodes);
  }
}

abstract class ParserNode extends Node {
  ParserNode(int start, int end) : super(start, end);
}

class VariableNode extends ParserNode {
  VariableNode(int start, int end) : super(start, end);

  @override
  int get hashCode => super.hashCode;

  @override
  bool operator ==(other) {
    return other is VariableNode && super == (other);
  }

  @override
  String toString() {
    return "Variable ${super.toString()}";
  }
}

class CommentNode extends ParserNode {
  CommentNode(int start, int end) : super(start, end);

  @override
  int get hashCode => super.hashCode;

  @override
  bool operator ==(other) {
    return other is CommentNode && super == (other);
  }

  @override
  String toString() {
    return "Comment ${super.toString()}";
  }
}

class TextNode extends ParserNode {
  TextNode(int start, int end) : super(start, end);

  @override
  int get hashCode => super.hashCode;

  @override
  bool operator ==(other) {
    return other is TextNode && super == (other);
  }

  @override
  String toString() {
    return "Text ${super.toString()}";
  }
}

class SectionNode extends ParserNode {
  final VariableNode variable;
  final bool inverted;
  final List<ParserNode> nodes = [];
  SectionNode(this.variable, {this.inverted}) : super(null, null);

  void add(ParserNode node) {
    nodes.add(node);
  }

  @override
  int get hashCode => variable.hashCode;

  @override
  bool operator ==(other) {
    if (other is SectionNode) {
      if (other.variable == variable) {
        if (const ListEquality().equals(other.nodes, nodes)) {
          return true;
        }
      }
    }
    return false;
  }

  @override
  String toString() {
    return "Section: ${variable} ${nodes}";
  }
}

class SectionStartNode extends ParserNode {
  final bool inverted;
  SectionStartNode(int start, int end, {this.inverted}) : super(start, end);
}

class SectionEndNode extends ParserNode {
  SectionEndNode(int start, int end) : super(start, end);
}

List<ParserNode> parse(String text) {
  if (text == null) {
    return null;
  }
  var source = new Source(text);
  source.parse();
  return source.nodes;
}
