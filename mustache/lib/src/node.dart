// Node must match exact class
abstract class Node {
  final String text;

  Node(this.text);

  @override
  int get hashCode => text?.hashCode ?? 0;

  @override
  bool operator ==(other) {
    if (other.runtimeType == runtimeType) {
      return other.text == text;
    }
    return false;
  }

  @override
  String toString() {
    return '$runtimeType: $text';
  }
}
