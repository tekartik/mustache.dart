abstract class Node {
  final int start;
  final int end;

  Node(this.start, this.end);

  @override
  int get hashCode => start;

  @override
  bool operator ==(other) {
    if (other is Node) {
      return other.start == start && other.end == end;
    }
    return false;
  }

  @override
  String toString() {
    return '[$start, $end]';
  }
}

String textAtNode(String source, Node node) {
  return source.substring(node.start, node.end);
}
