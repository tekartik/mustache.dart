abstract class Node {
  final String text;

  Node(this.text);

  @override
  int get hashCode => text?.hashCode ?? 0;

  @override
  bool operator ==(other) {
    if (other is Node) {
      return other.text == text;
    }
    return false;
  }

  @override
  String toString() {
    return '$text';
  }
}
