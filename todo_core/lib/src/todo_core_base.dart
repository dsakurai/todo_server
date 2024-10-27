
// Put public facing types in this file.

class Todo_node {

  final List<Todo_node> children; // Used for creating, e.g., a "Private" group
  String text;

  Map<String, Object?> to_map() {
    return {
      "children":  children,
      "text":    text,
    };
  }

  Todo_node(
    {
      this.text = "",
      children = const [],
    }): children = List.from(children);
}
